B4A=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=13.4
@EndOfDesignText@
' cRenderer.bas
Sub Class_Globals
	Type RenderOptions(BackfaceCull As Boolean, DrawFaces As Boolean, DrawEdges As Boolean, DrawVerts As Boolean, SmoothShading As Boolean)
	Type RenderStats(TotalFaces As Int, CulledFaces As Int, DrawnFaces As Int, BuildMs As Int, RenderMs As Int)
	Type Ray(Origin As Vec3, Dir As Vec3)
	Type Hit(T As Double, FaceIndex As Int, U As Double, V As Double)
	Type FrameData(Verts As List, Faces As List, FaceN As List, Refl As List)
	
	Public Const MODE_RASTER As Int = 0
	Public Const MODE_RAYTRACE As Int = 1
	Public RENDER_MODE As Int = 0
	
	
	Private RT_W As Int, RT_H As Int
	Private Pixels() As Int
	Private MT_Pending As Int
	
	Private RT_Verts As List, RT_Faces As List, RT_FaceN As List, RT_Refl As List, RT_VertN As List, RT_CornerN As List
	Private RT_AlbR As List, RT_AlbG As List, RT_AlbB As List
	
	Private RT_CamPos As Vec3
	Private RT_Right As Vec3, RT_Up As Vec3, RT_Fwd As Vec3
	Private RT_TanHalf As Double, RT_Aspect As Double
	Private RT_LightDir As Vec3
	Public  RT_MaxDepth As Int = 2
	Public  RT_Eps As Double = 1e-3

	' Per-face acceleration (parallel to faces)
	Private FMinX As List, FMinY As List, FMinZ As List
	Private FMaxX As List, FMaxY As List, FMaxZ As List
	Private FCx As List,  FCy As List,  FCz As List
	Private FRL  As List
	' Near/Far plane (raster)
	Public NearZ As Double = 0.1
	Public FarZ As Double = 1000

	' cached for analytics
	Public LastStats As RenderStats
	
	Dim testTimer As Timer
	Dim backgroundColor As Int = Colors.black
	
End Sub

Public Sub Initialize
	testTimer.Initialize("timer", 50)
	
End Sub

' --- RASTER ---
Public Sub RenderRaster(cvs As Canvas, dstW As Int, dstH As Int, scene As cScene, opt As RenderOptions) As RenderStats
	
	Dim t0 As Long = DateTime.Now
	Dim FR As SceneFrame = scene.BuildFrame
	Dim t1 As Long = DateTime.Now

	Dim nV As Int = FR.Verts.Size, nF As Int = FR.Faces.Size
	Dim stats As RenderStats
	stats.TotalFaces = nF

	cvs.DrawColor(backgroundColor)

	' (You commented the early exit; leaving it as you had it)
	If nV = 0 Or nF = 0 Then
'		cvs.DrawText("No geometry", dstW/2, dstH/2, Typeface.DEFAULT_BOLD, 22, Colors.White, "CENTER")
	End If

	' camera basis
	Dim right As Vec3, upv As Vec3, fwd As Vec3
	Dim resultArr() As Vec3 = scene.Camera.Basis(right, upv, fwd)
	fwd = resultArr(0) : right = resultArr(1) : upv = resultArr(2)

	Dim aspect As Double = dstW / Max(1, dstH)
	Dim fovRad As Double = scene.Camera.FOV_Deg * cPI / 180
	Dim f As Double = 1 / Tan(fovRad/2)

		
	' project all verts
	Dim proj(nV*3) As Double    ' [sx, sy, cz]
	For i = 0 To nV - 1
		Dim w As Vec3 = FR.Verts.Get(i)
		Dim rel As Vec3 = Math3D.V3(w.X - scene.Camera.Pos.X, w.Y - scene.Camera.Pos.Y, w.Z - scene.Camera.Pos.Z)
		Dim cxx As Double = Math3D.Dot(rel, right)
		Dim cyy As Double = Math3D.Dot(rel, upv)
		Dim cz As Double = Math3D.Dot(rel, fwd)
		proj(i*3+2) = cz
		If cz >= NearZ And cz <= FarZ Then
			Dim ndcX As Double = (cxx * f / aspect) / cz
			Dim ndcY As Double = (cyy * f) / cz
			proj(i*3+0) = (ndcX * 0.5 + 0.5) * dstW
			proj(i*3+1) = (-ndcY * 0.5 + 0.5) * dstH
		Else
'			Log($"${cz >= NearZ} | ${cz <= FarZ}"$)
			proj(i*3+0) = -10000 : proj(i*3+1) = -10000
		End If
	Next
	
	
	' depth sort
	Dim sorter As List : sorter.Initialize
	For fi = 0 To nF - 1
		Dim fc As Face = FR.Faces.Get(fi)
		Dim fd As FaceDepth
		fd.Initialize
		fd.Z = (proj(fc.A*3+2) + proj(fc.B*3+2) + proj(fc.C*3+2)) / 3
		fd.I = fi
		sorter.Add(fd)
	Next
	sorter.SortType("Z", False) ' far → near
	
	Dim useSmooth As Boolean = opt.SmoothShading

	Dim pix() As Int, bmp As Bitmap, jbmp As JavaObject
	If useSmooth Then
		pix = Math3D.CreateIntArray(dstW * dstH)
		' clear to black (or whatever bg)
		For ii = 0 To pix.Length - 1
			pix(ii) = Colors.Black
		Next
	End If

	' choose light
	Dim lightDir As Vec3
	If scene.Lights.Size > 0 Then
		Dim L As cLight = scene.Lights.Get(0)
		lightDir = L.Direction
	Else
		lightDir = Math3D.V3(-1,-1,-1)
	End If
	Dim Lm As Vec3 = Math3D.Normalize(Math3D.Mul(lightDir, -1))   ' surface->light

	
	' draw
	Dim culled As Int, drawn As Int
	For si = 0 To sorter.Size - 1
		Dim fd As FaceDepth = sorter.Get(si)
		Dim fi As Int = fd.I
		Dim fce As Face = FR.Faces.Get(fi)

		Dim za As Double = proj(fce.A*3+2), zb As Double = proj(fce.B*3+2), zc As Double = proj(fce.C*3+2)
		If za < NearZ Or zb < NearZ Or zc < NearZ Then Continue
		If za > FarZ Or zb > FarZ Or zc > FarZ Then Continue

		Dim ax As Float = proj(fce.A*3+0), ay As Float = proj(fce.A*3+1)
		Dim bx As Float = proj(fce.B*3+0), by As Float = proj(fce.B*3+1)
		Dim cx As Float = proj(fce.C*3+0), cy As Float = proj(fce.C*3+1)

		' backface cull (world space)
		Dim nWorld As Vec3 = FR.FaceN.Get(fi)
		Dim wa As Vec3 = FR.Verts.Get(fce.A), wb As Vec3 = FR.Verts.Get(fce.B), wc As Vec3 = FR.Verts.Get(fce.C)
		Dim center As Vec3 = Math3D.V3((wa.X+wb.X+wc.X)/3, (wa.Y+wb.Y+wc.Y)/3, (wa.Z+wb.Z+wc.Z)/3)
		Dim viewDir As Vec3 = Math3D.Normalize(Math3D.SubV(center, scene.Camera.Pos))
		If opt.BackfaceCull And Math3D.Dot(nWorld, viewDir) >= 0 Then 
			culled = culled + 1  
			Continue
		End If
		' material albedo
		Dim baseCol As Int = Colors.RGB(60,160,255)
		Dim mi As Int = FR.FaceMat.Get(fi)
		If mi >= 0 And mi < scene.Materials.Size Then baseCol = scene.Materials.Get(mi).As(cMaterial).Albedo
		Dim ar As Double = Bit.And(Bit.ShiftRight(baseCol,16),255)/255.0
		Dim ag As Double = Bit.And(Bit.ShiftRight(baseCol, 8),255)/255.0
		Dim ab As Double = Bit.And(baseCol, 255)/255.0

		If useSmooth Then
			' ----- GOURAUD: per-vertex color -> interpolate -----
			' material albedo
			Dim baseCol As Int = Colors.RGB(60,160,255)
			Dim mi As Int = FR.FaceMat.Get(fi)
			If mi >= 0 And mi < scene.Materials.Size Then baseCol = scene.Materials.Get(mi).As(cMaterial).Albedo
			Dim ar As Double = Bit.And(Bit.ShiftRight(baseCol,16),255)/255.0
			Dim ag As Double = Bit.And(Bit.ShiftRight(baseCol,8),255)/255.0
			Dim ab As Double = Bit.And(baseCol,255)/255.0

			' light (normalize once outside loop)
			' Dim Lm As Vec3 = Normalize(Mul(lightDir, -1))

			Dim idx As Int = fi * 3
			Dim aN As Vec3 = FR.CornerN.Get(idx + 0)
			Dim bN As Vec3 = FR.CornerN.Get(idx + 1)
			Dim cN As Vec3 = FR.CornerN.Get(idx + 2)
			Dim kAmb As Double = 0.1

			Dim lamA As Double = Max(0, Math3D.Dot(aN, Lm))
			Dim lamB As Double = Max(0, Math3D.Dot(bN, Lm))
			Dim lamC As Double = Max(0, Math3D.Dot(cN, Lm))
			Dim rA As Double = ar*(kAmb + (1-kAmb)*lamA), gA As Double = ag*(kAmb + (1-kAmb)*lamA), bA As Double = ab*(kAmb + (1-kAmb)*lamA)
			Dim rB As Double = ar*(kAmb + (1-kAmb)*lamB), gB As Double = ag*(kAmb + (1-kAmb)*lamB), bB As Double = ab*(kAmb + (1-kAmb)*lamB)
			Dim rC As Double = ar*(kAmb + (1-kAmb)*lamC), gC As Double = ag*(kAmb + (1-kAmb)*lamC), bC As Double = ab*(kAmb + (1-kAmb)*lamC)

			FillTriGouraud(pix, dstW, dstH, ax, ay, bx, by, cx, cy, rA,gA,bA, rB,gB,bB, rC,gC,bC)
			drawn = drawn + 1

		Else
			' ----- your existing flat draw -----
			Dim intensity As Double = Max(0, Math3D.Dot(nWorld, Lm))
			Dim k As Double = 0.2 + 0.8 * intensity
			Dim fillCol As Int = Colors.RGB(Min(255, ar*255*k), Min(255, ag*255*k), Min(255, ab*255*k))

			Dim p As Path
			p.Initialize(ax, ay)
			p.LineTo(bx, by)
			p.LineTo(cx, cy)
			If opt.DrawFaces Then cvs.DrawPath(p, fillCol, True, 0)
			If opt.DrawEdges Then
				Dim edgeColor As Int = Colors.ARGB(220, 40, 40, 40)
				cvs.DrawLine(ax, ay, bx, by, edgeColor, 2)
				cvs.DrawLine(bx, by, cx, cy, edgeColor, 2)
				cvs.DrawLine(cx, cy, ax, ay, edgeColor, 2)
			End If
			If opt.DrawVerts Then
				Dim vc As Int = Colors.Yellow
				cvs.DrawCircle(ax, ay, 3dip, vc, True, 0)
				cvs.DrawCircle(bx, by, 3dip, vc, True, 0)
				cvs.DrawCircle(cx, cy, 3dip, vc, True, 0)
			End If
			
			drawn = drawn + 1
		End If
	Next
	
	If useSmooth Then
		Dim bmp As Bitmap
		bmp.InitializeMutable(dstW, dstH)
		Dim jbmp As JavaObject = bmp
		jbmp.RunMethod("setPixels", Array As Object(pix, 0, dstW, 0, 0, dstW, dstH))

		Dim dst As Rect : dst.Initialize(0, 0, dstW, dstH)
		cvs.DrawBitmap(bmp, Null, dst)
	End If
	
	stats.CulledFaces = culled
	stats.DrawnFaces = drawn

	Dim t2 As Long = DateTime.Now
	stats.BuildMs = t1 - t0
	stats.RenderMs = t2 - t1
	LastStats = stats
	Return stats
End Sub

' --- RAY TRACE hook ---
Public Sub RenderRaytrace(scene As cScene, Width As Int, Height As Int) As ResumableSub	
	testTimer.Enabled = True
	Log("starting raytrace")
	' ---- store size ----
	RT_W = Width : RT_H = Height
	
	' ---- build aggregated frame ----
	Dim fr As SceneFrame = scene.BuildFrame
	If fr.Faces.Size = 0 Then
		Dim empty As Bitmap
		empty.InitializeMutable(RT_W, RT_H)
		Return empty
	End If

	' ---- keep references (read-only during render) ----
	RT_Verts = fr.Verts
	RT_Faces = fr.Faces
	RT_FaceN = fr.FaceN
	RT_VertN = fr.VertsN
	RT_CornerN = fr.CornerN

	' per-face reflectivity from materials
	RT_Refl.Initialize
	For i = 0 To fr.Faces.Size - 1
		Dim matIdx As Int = fr.FaceMat.Get(i)
		Dim k As Double = 0
		If matIdx >= 0 And matIdx < scene.Materials.Size Then
			Dim M As cMaterial = scene.Materials.Get(matIdx)
			k = Max(0, Min(1, M.Reflectivity))
		End If
		RT_Refl.Add(k)
	Next
	RT_AlbR.Initialize : RT_AlbG.Initialize : RT_AlbB.Initialize
	For i = 0 To fr.Faces.Size - 1
		Dim matIdx As Int = fr.FaceMat.Get(i)
		Dim col As Int = Colors.RGB(60,160,255)   ' fallback
		If matIdx >= 0 And matIdx < scene.Materials.Size Then
			Dim M As cMaterial = scene.Materials.Get(matIdx)
			col = M.Albedo
		End If
		Dim r As Double = Bit.And(Bit.ShiftRight(col,16),255) / 255.0
		Dim g As Double = Bit.And(Bit.ShiftRight(col, 8),255) / 255.0
		Dim b As Double = Bit.And(col, 255) / 255.0
		RT_AlbR.Add(r) : RT_AlbG.Add(g) : RT_AlbB.Add(b)
	Next

	' ---- precompute accel (AABB + sphere) ----
	PrecomputeFaceAccel(RT_Verts, RT_Faces)

	' ---- camera basis / constants ----
	Dim right As Vec3, upv As Vec3, fwd As Vec3
	Dim resultArr() As Vec3 = scene.Camera.Basis(right, upv, fwd)
	fwd = resultArr(0) : right = resultArr(1) : upv = resultArr(2)
	
	RT_Right = right : RT_Up = upv : RT_Fwd = fwd
	RT_CamPos = scene.Camera.Pos
	RT_Aspect = RT_W / Max(1, RT_H)
	RT_TanHalf = Tan(scene.Camera.FOV_Deg * cPI / 180 / 2)
	
	' ---- light ----
	If scene.Lights.Size > 0 Then
		Dim L As cLight = scene.Lights.Get(0)
		RT_LightDir = L.Direction
	Else
		RT_LightDir = Math3D.V3(-1, -2, -1)
	End If

	' ---- output buffer ----
	Pixels = Math3D.CreateIntArray(RT_W * RT_H)

	' ---- thread fan-out (fixed 4 threads, 8 stripes) ----
	Dim threadCount As Int = 4
	Dim stripes As Int = 8
	Dim stripeH As Int = Ceil(RT_H / stripes)
	
	
	Dim s As Int = 0
	For stripe = 0 To stripes - 1
		
		Dim y0 As Int = stripe * stripeH
		Dim y1 As Int = Min(RT_H, y0 + stripeH)
		If y0 >= y1 Then Continue

		Dim args As Map : args.Initialize
		args.Put("y0", y0) : args.Put("y1", y1)
		Dim th As Thread
		th.Initialise("rt")
		th.Start(Me, "TraceStripe_BG", Array(args))
'		Log("starting Thread")
		s = s + 1
		MT_Pending = MT_Pending + 1
	Next
	
	Wait For AllThreads_Done (success As Boolean, error As String)
	If success Then
		testTimer.Enabled = False
		Dim bmp As Bitmap
		bmp.InitializeMutable(RT_W, RT_H)
		Dim jbmp As JavaObject = bmp
		jbmp.RunMethod("setPixels", Array As Object(Pixels, 0, RT_W, 0, 0, RT_W, RT_H))
		Log("should return bitmap")
		Return bmp
	Else 
		testTimer.Enabled = False
		Log(success)
		Log(error)
		Return Null
	End If
	
End Sub

' Fills Pixels() for [y0, y1) using the stored RT_* state
Sub TraceStripe_BG(ArgsOBJ As Object)
	Dim args As Map = ArgsOBJ
	Dim y0 As Int = args.Get("y0"), y1 As Int = args.Get("y1")
	Dim W As Int = RT_W, H As Int = RT_H

	For y = y0 To y1 - 1
		Dim py As Double = (1 - ((y + 0.5)/H) * 2) * RT_TanHalf
		Dim rowOff As Int = y * W

		For x = 0 To W - 1
			Dim px As Double = (((x + 0.5)/W) * 2 - 1) * RT_Aspect * RT_TanHalf

			Dim dir As Vec3 = Math3D.Normalize( _
                Math3D.AddV( Math3D.AddV( Math3D.Mul(RT_Right, px), Math3D.Mul(RT_Up, py) ), RT_Fwd) )

			Dim r As Ray
			r.Origin = RT_CamPos
			r.Dir = dir

			Dim c As Vec3 =  TraceColor(r, 0, RT_Verts, RT_Faces, RT_FaceN, RT_Refl)
			Pixels(rowOff + x) = Colors.ARGB(255, c.X*255, c.Y*255, c.Z*255)
		Next
	Next
End Sub

Sub timer_Tick
	Dim bmp As Bitmap
	bmp.InitializeMutable(RT_W, RT_H)
	Dim jbmp As JavaObject = bmp
	jbmp.RunMethod("setPixels", Array As Object(Pixels, 0, RT_W, 0, 0, RT_W, RT_H))
	CallSub2(Main, "DrawThisBitmap", bmp)
End Sub

' Decrements the countdown when a worker finishes its queued stripes
	
Sub rt_Ended(endedOK As Boolean, error As String) 'The thread has terminated. If endedOK is False error holds the reason for failure
	MT_Pending = MT_Pending - 1
'	Log("ended remaining : " & MT_Pending)
	If MT_Pending = 0 And endedOK Then
'		Log("SHould call OK")
		CallSub3(Me, "AllThreads_Done", endedOK, error)
	else if Not(endedOK) Then
'		Log("SHould call NOT OK")
		CallSub3(Me, "AllThreads_Done", endedOK, error)
	End If
End Sub

' ---------- Per-face acceleration (AABB + bounding sphere) ----------
Private Sub PrecomputeFaceAccel(v As List, f As List)
	FMinX.Initialize : FMinY.Initialize : FMinZ.Initialize
	FMaxX.Initialize : FMaxY.Initialize : FMaxZ.Initialize
	FCx.Initialize : FCy.Initialize : FCz.Initialize : FRL.Initialize
	
	For i = 0 To f.Size - 1
		Dim fc As Face = f.Get(i)
		Dim a As Vec3 = v.Get(fc.A)
		Dim b As Vec3 = v.Get(fc.B)
		Dim c As Vec3 = v.Get(fc.C)
		
		' AABB
		Dim minx As Double = Min(a.X, Min(b.X, c.X))
		Dim miny As Double = Min(a.Y, Min(b.Y, c.Y))
		Dim minz As Double = Min(a.Z, Min(b.Z, c.Z))
		Dim maxx As Double = Max(a.X, Max(b.X, c.X))
		Dim maxy As Double = Max(a.Y, Max(b.Y, c.Y))
		Dim maxz As Double = Max(a.Z, Max(b.Z, c.Z))
		FMinX.Add(minx) : FMinY.Add(miny) : FMinZ.Add(minz)
		FMaxX.Add(maxx) : FMaxY.Add(maxy) : FMaxZ.Add(maxz)
		
		' Bounding sphere: centroid + max distance to vertices
		Dim cx As Double = (a.X + b.X + c.X) / 3
		Dim cy As Double = (a.Y + b.Y + c.Y) / 3
		Dim cz As Double = (a.Z + b.Z + c.Z) / 3
		FCx.Add(cx) : FCy.Add(cy) : FCz.Add(cz)
		
		Dim ra2 As Double = (a.X-cx)*(a.X-cx) + (a.Y-cy)*(a.Y-cy) + (a.Z-cz)*(a.Z-cz)
		Dim rb2 As Double = (b.X-cx)*(b.X-cx) + (b.Y-cy)*(b.Y-cy) + (b.Z-cz)*(b.Z-cz)
		Dim rc2 As Double = (c.X-cx)*(c.X-cx) + (c.Y-cy)*(c.Y-cy) + (c.Z-cz)*(c.Z-cz)
		Dim r As Double = Sqrt(Max(ra2, Max(rb2, rc2)))
		FRL.Add(r)
	Next
End Sub

' ---------- Fast ray tests ----------
Private Sub RayHitsSphere(rox As Double, roy As Double, roz As Double, rdx As Double, rdy As Double, rdz As Double, _
                          cx As Double, cy As Double, cz As Double, rad As Double) As Boolean
	' Ray-sphere using quadratic discriminant (t >= 0)
	Dim ox As Double = rox - cx, oy As Double = roy - cy, oz As Double = roz - cz
	Dim b As Double = ox*rdx + oy*rdy + oz*rdz
	Dim c As Double = ox*ox + oy*oy + oz*oz - rad*rad
	If c < 0 Then Return True            ' origin inside sphere
	Dim disc As Double = b*b - c
	Return disc >= 0
End Sub

Private Sub RayHitsAABB(rox As Double, roy As Double, roz As Double, rdx As Double, rdy As Double, rdz As Double, _
                        minx As Double, miny As Double, minz As Double, maxx As Double, maxy As Double, maxz As Double) As Boolean
	Dim INF As Double = 1e30
	Dim tx1, tx2, ty1, ty2, tz1, tz2 As Double

	If Abs(rdx) < 1e-9 Then
		If rox < minx Or rox > maxx Then Return False
		tx1 = -INF : tx2 = INF
	Else
		Dim invx As Double = 1 / rdx
		tx1 = (minx - rox) * invx : tx2 = (maxx - rox) * invx
		If tx1 > tx2 Then 
			Dim t As Double = tx1 : tx1 = tx2 : tx2 = t
		End If
	End If
	
	If Abs(rdy) < 1e-9 Then
		If roy < miny Or roy > maxy Then Return False
		ty1 = -INF : ty2 = INF
	Else
		Dim invy As Double = 1 / rdy
		ty1 = (miny - roy) * invy : ty2 = (maxy - roy) * invy
		If ty1 > ty2 Then 
			Dim t2 As Double = ty1 : ty1 = ty2 : ty2 = t2
		End If
	End If
	
	If Abs(rdz) < 1e-9 Then
		If roz < minz Or roz > maxz Then Return False
		tz1 = -INF : tz2 = INF
	Else
		Dim invz As Double = 1 / rdz
		tz1 = (minz - roz) * invz : tz2 = (maxz - roz) * invz
		If tz1 > tz2 Then 
			Dim t3 As Double = tz1 : tz1 = tz2 : tz2 = t3
		End If
	End If
	
	Dim tmin As Double = Max(0, Max(tx1, Max(ty1, tz1)))
	Dim tmax As Double = Min(Min(tx2, ty2), tz2)
	Return tmax >= tmin
End Sub

' ---------- Triangle intersection (Möller–Trumbore) ----------
Private Sub IntersectTriangle(r As Ray, a As Vec3, b As Vec3, c As Vec3, best As Hit) As Boolean
	Dim e1x As Double = b.X - a.X, e1y As Double = b.Y - a.Y, e1z As Double = b.Z - a.Z
	Dim e2x As Double = c.X - a.X, e2y As Double = c.Y - a.Y, e2z As Double = c.Z - a.Z

	Dim px As Double = r.Dir.Y*e2z - r.Dir.Z*e2y
	Dim py As Double = r.Dir.Z*e2x - r.Dir.X*e2z
	Dim pz As Double = r.Dir.X*e2y - r.Dir.Y*e2x
	Dim det As Double = e1x*px + e1y*py + e1z*pz
	If det > -1e-9 And det < 1e-9 Then Return False

	Dim invDet As Double = 1 / det
	Dim tx As Double = r.Origin.X - a.X, ty As Double = r.Origin.Y - a.Y, tz As Double = r.Origin.Z - a.Z
	Dim u As Double = (tx*px + ty*py + tz*pz) * invDet
	If u < 0 Or u > 1 Then Return False

	Dim qx As Double = ty*e1z - tz*e1y
	Dim qy As Double = tz*e1x - tx*e1z
	Dim qz As Double = tx*e1y - ty*e1x
	Dim v As Double = (r.Dir.X*qx + r.Dir.Y*qy + r.Dir.Z*qz) * invDet
	If v < 0 Or u + v > 1 Then Return False

	Dim t As Double = (e2x*qx + e2y*qy + e2z*qz) * invDet
	If t > 1e-6 And t < best.T Then
		best.T = t
		best.U = u
		best.V = v
		Return True
	End If
	Return False
End Sub

Private Sub TraceRay(r As Ray, v As List, f As List) As Hit
	Dim best As Hit : best.T = 1e30 : best.FaceIndex = -1
	Dim rox As Double = r.Origin.X, roy As Double = r.Origin.Y, roz As Double = r.Origin.Z
	Dim rdx As Double = r.Dir.X,    rdy As Double = r.Dir.Y,    rdz As Double = r.Dir.Z
	
	For i = 0 To f.Size - 1
		' early rejects
		If Not(RayHitsSphere(rox,roy,roz, rdx,rdy,rdz, FCx.Get(i), FCy.Get(i), FCz.Get(i), FRL.Get(i))) Then Continue
		If Not(RayHitsAABB(rox,roy,roz, rdx,rdy,rdz, FMinX.Get(i),FMinY.Get(i),FMinZ.Get(i), FMaxX.Get(i),FMaxY.Get(i),FMaxZ.Get(i))) Then Continue

		Dim fc As Face = f.Get(i)
		Dim a As Vec3 = v.Get(fc.A)
		Dim b As Vec3 = v.Get(fc.B)
		Dim c As Vec3 = v.Get(fc.C)
		If IntersectTriangle(r, a, b, c, best) Then best.FaceIndex = i
	Next
	Return best
End Sub

Private Sub AnyHitShadow(r As Ray, v As List, f As List, eps As Double) As Boolean
	Dim rox As Double = r.Origin.X, roy As Double = r.Origin.Y, roz As Double = r.Origin.Z
	Dim rdx As Double = r.Dir.X,    rdy As Double = r.Dir.Y,    rdz As Double = r.Dir.Z

	For i = 0 To f.Size - 1
		If Not(RayHitsSphere(rox,roy,roz, rdx,rdy,rdz, FCx.Get(i), FCy.Get(i), FCz.Get(i), FRL.Get(i))) Then Continue
		If Not(RayHitsAABB(rox,roy,roz, rdx,rdy,rdz, FMinX.Get(i),FMinY.Get(i),FMinZ.Get(i), FMaxX.Get(i),FMaxY.Get(i),FMaxZ.Get(i))) Then Continue

		Dim fc As Face = f.Get(i)
		Dim a As Vec3 = v.Get(fc.A)
		Dim b As Vec3 = v.Get(fc.B)
		Dim c As Vec3 = v.Get(fc.C)

		Dim h As Hit : h.T = 1e30 : h.FaceIndex = -1
		If IntersectTriangle(r, a, b, c, h) Then
			If h.T > eps Then Return True
		End If
	Next
	Return False
End Sub

' ---------- Shading helpers ----------
Private Sub Reflect(dir As Vec3, n As Vec3) As Vec3
	Return Math3D.SubV(dir, Math3D.Mul(n, 2 * Math3D.Dot(dir, n)))
End Sub

Private Sub Background(d As Vec3) As Vec3
	' simple sky gradient
'	Dim t As Double = (d.Y + 1) * 0.5
'	Return Math3D.V3(0.05*(1-t)+0.5*t, 0.05*(1-t)+0.7*t, 0.08*(1-t)+1.0*t)
	Return Math3D.V3(0, 0, 0)
End Sub

Private Sub TraceColor(r As Ray, depth As Int, v As List, f As List, fn As List, refl As List) As Vec3
	If depth > RT_MaxDepth Then Return Background(r.Dir)

	Dim h As Hit = TraceRay(r, v, f)
	If h.FaceIndex = -1 Then Return Background(r.Dir)

	' hit point + face normal (flip to oppose the view ray)
	Dim p As Vec3 = Math3D.AddV(r.Origin, Math3D.Mul(r.Dir, h.T))
	
	Dim idx As Int = h.FaceIndex * 3
	Dim aN As Vec3 = RT_CornerN.Get(idx + 0)
	Dim bN As Vec3 = RT_CornerN.Get(idx + 1)
	Dim cN As Vec3 = RT_CornerN.Get(idx + 2)
	
	Dim w As Double = 1 - h.U - h.V
	Dim n As Vec3 = Math3D.Normalize( _
    Math3D.AddV( Math3D.AddV(Math3D.Mul(aN, w), Math3D.Mul(bN, h.U)), Math3D.Mul(cN, h.V)))
	If Math3D.Dot(n, r.Dir) > 0 Then n = Math3D.Mul(n, -1)

	' direct light with hard shadow
	Dim lam As Double = Max(0, Math3D.Dot(n, Math3D.Mul(RT_LightDir, -1)))
	If lam > 0 Then
		Dim s As Ray
		s.Origin = Math3D.AddV(p, Math3D.Mul(n, RT_Eps))
		s.Dir = Math3D.Mul(RT_LightDir, -1)
		If AnyHitShadow(s, v, f, RT_Eps) Then lam = 0
	End If

	' base bluish (swap to per-material if you like)
	Dim base As Vec3 = Math3D.V3( _
	    RT_AlbR.Get(h.FaceIndex), _
	    RT_AlbG.Get(h.FaceIndex), _
	    RT_AlbB.Get(h.FaceIndex))
	Dim direct As Vec3 = Math3D.V3( _
        base.X*(0.1 + 0.9*lam), _
        base.Y*(0.1 + 0.9*lam), _
        base.Z*(0.1 + 0.9*lam))
		
	

	' reflection mix
	Dim k As Double = refl.Get(h.FaceIndex)
	If k <= 0 Or depth = RT_MaxDepth Then Return direct

	Dim rr As Ray
	rr.Origin = Math3D.AddV(p, Math3D.Mul(n, RT_Eps))
	rr.Dir = Math3D.Normalize(Reflect(r.Dir, n))
	Dim rc As Vec3 = TraceColor(rr, depth+1, v, f, fn, refl)

	Return Math3D.V3( direct.X*(1-k) + rc.X*k, direct.Y*(1-k) + rc.Y*k, direct.Z*(1-k) + rc.Z*k )
End Sub


'0 - raster
'1 - raytrace
public Sub setRenderMode(mode As Int)
	RENDER_MODE = mode
End Sub

'Private Sub ColorToInt01(r As Double, g As Double, b As Double) As Int
'	Return Math3D.ARGB255(255, r*255, g*255, b*255)
'End Sub

Private Sub FillTriGouraud(pix() As Int, W As Int, H As Int, _
    ax As Float, ay As Float, bx As Float, by As Float, cx As Float, cy As Float, _
    rA As Double, gA As Double, bA As Double, rB As Double, gB As Double, bB As Double, rC As Double, gC As Double, bC As Double)

	Dim minx As Int = Floor(Min(ax, Min(bx, cx)))
	Dim maxx As Int = Ceil(Max(ax, Max(bx, cx)))
	Dim miny As Int = Floor(Min(ay, Min(by, cy)))
	Dim maxy As Int = Ceil(Max(ay, Max(by, cy)))
	If maxx < 0 Or maxy < 0 Or minx >= W Or miny >= H Then Return
	If minx < 0 Then minx = 0
	If miny < 0 Then miny = 0
	If maxx >= W Then maxx = W-1
	If maxy >= H Then maxy = H-1

	' Edge functions
	Dim A01 As Float = ay - by,  B01 As Float = bx - ax,  C01 As Float = ax*by - bx*ay
	Dim A12 As Float = by - cy,  B12 As Float = cx - bx,  C12 As Float = bx*cy - cx*by
	Dim A20 As Float = cy - ay,  B20 As Float = ax - cx,  C20 As Float = cx*ay - ax*cy

	Dim area As Float = (bx - ax)*(cy - ay) - (by - ay)*(cx - ax)
	If Abs(area) < 1e-6 Then Return
	Dim invArea As Double = 1.0 / area

	For y = miny To maxy
		Dim yc As Float = y + 0.5
		Dim w0 As Float = A12 * (minx + 0.5) + B12 * yc + C12
		Dim w1 As Float = A20 * (minx + 0.5) + B20 * yc + C20
		Dim w2 As Float = A01 * (minx + 0.5) + B01 * yc + C01
		Dim dw0dx As Float = A12, dw1dx As Float = A20, dw2dx As Float = A01

		Dim o As Int = y * W + minx
		For x = minx To maxx
			Dim inside As Boolean = (area > 0 And w0 >= 0 And w1 >= 0 And w2 >= 0) Or (area < 0 And w0 <= 0 And w1 <= 0 And w2 <= 0)
			If inside Then
				' barycentrics
				Dim l0 As Double = w0 * invArea
				Dim l1 As Double = w1 * invArea
				Dim l2 As Double = 1.0 - l0 - l1
				' interpolate color
				Dim r As Int = Min(255, (rA*l0 + rB*l1 + rC*l2) * 255)
				Dim g As Int = Min(255, (gA*l0 + gB*l1 + gC*l2) * 255)
				Dim b As Int = Min(255, (bA*l0 + bB*l1 + bC*l2) * 255)
				pix(o) = Math3D.ARGB255(255, r, g, b)
			End If
			w0 = w0 + dw0dx : w1 = w1 + dw1dx : w2 = w2 + dw2dx
			o = o + 1
		Next
	Next
End Sub
