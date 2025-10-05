B4A=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=13.4
@EndOfDesignText@
#IgnoreWarnings: 11, 9

Sub Class_Globals
	Type RenderOptions(BackfaceCull As Boolean, DrawFaces As Boolean, DrawEdges As Boolean, DrawVerts As Boolean, SmoothShading As Boolean, UseMaterialColors As Boolean, FaceColor As Int, EdgeColor As Int, VertexColor As Int, EdgeThickness As Float, VertexSize As Float, VoidColor As Int)
	Type WireframeOptions(BackfaceCull As Boolean, DrawFaces As Boolean, DrawEdges As Boolean, DrawVerts As Boolean, UseMaterialColors As Boolean, FaceColor As Int, EdgeColor As Int, VertexColor As Int, EdgeThickness As Float, VertexSize As Float, VoidColor As Int, ShowCamera As Boolean, ShowLights As Boolean, ShowModels As Boolean, ShowOriginAxes As Boolean)
	Type ScreenPoint(Success As Boolean, X As Float, Y As Float, Depth As Double)
	Type RenderStats(TotalFaces As Int, CulledFaces As Int, DrawnFaces As Int, BuildMs As Int, RenderMs As Int)
	Type Ray(Origin As Vec3, Dir As Vec3)
	Type Hit(T As Double, FaceIndex As Int, U As Double, V As Double)
	Type FrameData(Verts As List, Faces As List, FaceN As List, Refl As List)
	
	Public Const MODE_RASTER As Int = 0
	Public Const MODE_RAYTRACE As Int = 1
	Public Const MODE_PATHTRACE As Int = 2
	Public Const MODE_WIREFRAME As Int = 3
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
	Private RT_Scene As cScene
	Private RT_AreaLightSamples As Int = 4
	
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
	Public RayBackgroundColor As Int = Colors.Black
	Public PathBackgroundColor As Int = Colors.Black
	
	' ===== BVH (Bounding Volume Hierarchy) =====
	Private BVH_MinX As List, BVH_MinY As List, BVH_MinZ As List
	Private BVH_MaxX As List, BVH_MaxY As List, BVH_MaxZ As List
	Private BVH_Left  As List, BVH_Right As List
	Private BVH_First As List, BVH_Count As List
	Private BVH_Axis  As List                    ' split axis (0=x,1=y,2=z)
	Private BVH_TriIdx() As Int                  ' permutation of face indices
	Private BVH_Root As Int
	Private BVH_NodeCount As Int
	Private BVH_LeafMax As Int = 8
	Private BVH_Built As Boolean
	Public  UseBVH As Boolean = True

	Public RT_Stat_TriTests As Long, RT_Stat_AABBTests As Long, RT_Stat_BVHNodesVisited As Long
	
	' -------- Path Tracer state --------
	Private PT_W As Int, PT_H As Int
	Private PT_AccumR() As Double, PT_AccumG() As Double, PT_AccumB() As Double
	Private PT_SamplesAccum As Int
	Private PT_Frame As Long
	Private PT_UseDirectLight As Boolean = True   ' next-event estimation (shadow ray to light)
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

	backgroundColor = opt.VoidColor
	cvs.DrawColor(backgroundColor)
	
	Dim edgeDip As Float = Max(0.5, opt.EdgeThickness)
	Dim edgeWidth As Float = DipToCurrent(edgeDip)
	Dim vertDip As Float = Max(0.5, opt.VertexSize)
	Dim vertRadius As Float = DipToCurrent(vertDip)
	
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
	If useSmooth And opt.DrawFaces Then
		pix = Math3D.CreateIntArray(dstW * dstH)
		' clear to black (or whatever bg)
		For ii = 0 To pix.Length - 1
			pix(ii) = Colors.Black
		Next
	End If

	Dim lightDir As Vec3 = Math3D.V3(-1, -1, -1)
	
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
		Dim baseCol As Int 
		If opt.UseMaterialColors Then
			baseCol = Colors.RGB(60,160,255)
			Dim mi As Int = FR.FaceMat.Get(fi)
			If mi >= 0 And mi < scene.Materials.Size Then baseCol = scene.Materials.Get(mi).As(cMaterial).Albedo
		Else 
			baseCol = opt.FaceColor
		End If
		Dim ar As Double = Bit.And(Bit.ShiftRight(baseCol,16),255)/255.0
		Dim ag As Double = Bit.And(Bit.ShiftRight(baseCol, 8),255)/255.0
		Dim ab As Double = Bit.And(baseCol, 255)/255.0

		If useSmooth And opt.DrawFaces Then

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
			
			Dim intensity As Double = Max(0, Math3D.Dot(nWorld, Lm))
			Dim k As Double = 0.2 + 0.8 * intensity
			Dim fillCol As Int = Colors.RGB(Min(255, ar*255*k), Min(255, ag*255*k), Min(255, ab*255*k))

			If opt.DrawFaces Then 
				Dim p As Path
				p.Initialize(ax, ay)
				p.LineTo(bx, by)
				p.LineTo(cx, cy)
				cvs.DrawPath(p, fillCol, True, 0)
			End If
			
			If opt.DrawEdges Then
				Dim edgeColor As Int = Colors.ARGB(220, 40, 40, 40)
				cvs.DrawLine(ax, ay, bx, by, edgeColor, edgeWidth)
				cvs.DrawLine(bx, by, cx, cy, edgeColor, edgeWidth)
				cvs.DrawLine(cx, cy, ax, ay, edgeColor, edgeWidth)
			End If
			
			If opt.DrawVerts Then
				Dim vc As Int = Colors.Yellow
				cvs.DrawCircle(ax, ay, vertRadius, vc, True, 0)
				cvs.DrawCircle(bx, by, vertRadius, vc, True, 0)
				cvs.DrawCircle(cx, cy, vertRadius, vc, True, 0)
			End If
			
			drawn = drawn + 1
		End If
	Next

	If useSmooth And opt.DrawFaces Then
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

' --- WIREFRAME ---
Public Sub RenderWireframe(cvs As Canvas, dstW As Int, dstH As Int, scene As cScene, opt As WireframeOptions) As RenderStats

	Dim t0 As Long = DateTime.Now
	Dim FR As SceneFrame = scene.BuildFrame
	Dim t1 As Long = DateTime.Now

	Dim nV As Int = FR.Verts.Size, nF As Int = FR.Faces.Size
	Dim stats As RenderStats
	stats.TotalFaces = nF

	cvs.DrawColor(opt.VoidColor)

	If nV = 0 Or nF = 0 Then
		LastStats = stats
		Return stats
	End If

	Dim edgeDip As Float = Max(0.5, opt.EdgeThickness)
	Dim edgeWidth As Float = DipToCurrent(edgeDip)
	Dim vertDip As Float = Max(0.5, opt.VertexSize)
	Dim vertRadius As Float = DipToCurrent(vertDip)

	Dim right As Vec3, upv As Vec3, fwd As Vec3
	Dim resultArr() As Vec3 = scene.Camera.Basis(right, upv, fwd)
	fwd = resultArr(0) : right = resultArr(1) : upv = resultArr(2)
	
	Dim aspect As Double = dstW / Max(1, dstH)
	Dim fovRad As Double = scene.Camera.FOV_Deg * cPI / 180
	Dim f As Double = 1 / Tan(fovRad/2)
	
	Dim proj(nV*3) As Double
	For i = 0 To nV - 1
		Dim w As Vec3 = FR.Verts.Get(i)
		Dim screen As ScreenPoint = ProjectWorldPoint(w, scene.Camera.Pos, right, upv, fwd, aspect, f, dstW, dstH)
		proj(i*3+0) = screen.X
		proj(i*3+1) = screen.Y
		proj(i*3+2) = screen.Depth
	Next

	If opt.ShowModels Then
		Dim sorter As List : sorter.Initialize
		For fi = 0 To nF - 1
			Dim fc As Face = FR.Faces.Get(fi)
			Dim fd As FaceDepth
			fd.Initialize
			fd.Z = (proj(fc.A*3+2) + proj(fc.B*3+2) + proj(fc.C*3+2)) / 3
			fd.I = fi
			sorter.Add(fd)
		Next
		sorter.SortType("Z", False)
		
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

			Dim nWorld As Vec3 = FR.FaceN.Get(fi)
			Dim wa As Vec3 = FR.Verts.Get(fce.A), wb As Vec3 = FR.Verts.Get(fce.B), wc As Vec3 = FR.Verts.Get(fce.C)
			Dim center As Vec3 = Math3D.V3((wa.X+wb.X+wc.X)/3, (wa.Y+wb.Y+wc.Y)/3, (wa.Z+wb.Z+wc.Z)/3)
			Dim viewDir As Vec3 = Math3D.Normalize(Math3D.SubV(center, scene.Camera.Pos))
			If opt.BackfaceCull And Math3D.Dot(nWorld, viewDir) >= 0 Then
				culled = culled + 1
				Continue
			End If

			Dim baseCol As Int
			If opt.UseMaterialColors Then
				baseCol = Colors.RGB(60,160,255)
				Dim mi As Int = FR.FaceMat.Get(fi)
				If mi >= 0 And mi < scene.Materials.Size Then
					Dim mat As cMaterial = scene.Materials.Get(mi)
					baseCol = mat.Albedo
				End If
			Else
				baseCol = opt.FaceColor
			End If

			If opt.DrawFaces Then
				Dim p As Path
				p.Initialize(ax, ay)
				p.LineTo(bx, by)
				p.LineTo(cx, cy)
				cvs.DrawPath(p, baseCol, True, 0)
			End If

			If opt.DrawEdges Then
				cvs.DrawLine(ax, ay, bx, by, opt.EdgeColor, edgeWidth)
				cvs.DrawLine(bx, by, cx, cy, opt.EdgeColor, edgeWidth)
				cvs.DrawLine(cx, cy, ax, ay, opt.EdgeColor, edgeWidth)
			End If

			If opt.DrawVerts Then
				cvs.DrawCircle(ax, ay, vertRadius, opt.VertexColor, True, 0)
				cvs.DrawCircle(bx, by, vertRadius, opt.VertexColor, True, 0)
				cvs.DrawCircle(cx, cy, vertRadius, opt.VertexColor, True, 0)
			End If

			drawn = drawn + 1
		Next

		stats.CulledFaces = culled
		stats.DrawnFaces = drawn
	End If

	' overlays
	Dim overlayStroke As Float = DipToCurrent(2)
	If opt.ShowOriginAxes Then
		Dim origin As Vec3 = Math3D.V3(0, 0, 0)
		Dim axisScale As Double = 1
		Dim sx As ScreenPoint = ProjectWorldPoint(origin, scene.Camera.Pos, right, upv, fwd, aspect, f, dstW, dstH)
		If sx.Success Then
			Dim axX As ScreenPoint = ProjectWorldPoint(Math3D.V3(axisScale, 0, 0), scene.Camera.Pos, right, upv, fwd, aspect, f, dstW, dstH)
			Dim axY As ScreenPoint = ProjectWorldPoint(Math3D.V3(0, axisScale, 0), scene.Camera.Pos, right, upv, fwd, aspect, f, dstW, dstH)
			Dim axZ As ScreenPoint = ProjectWorldPoint(Math3D.V3(0, 0, axisScale), scene.Camera.Pos, right, upv, fwd, aspect, f, dstW, dstH)
			If axX.Success Then cvs.DrawLine(sx.X, sx.Y, axX.X, axX.Y, Colors.Red, overlayStroke)
			If axY.Success Then cvs.DrawLine(sx.X, sx.Y, axY.X, axY.Y, Colors.Green, overlayStroke)
			If axZ.Success Then cvs.DrawLine(sx.X, sx.Y, axZ.X, axZ.Y, Colors.Blue, overlayStroke)
		End If
	End If

	If opt.ShowLights Then
		Dim lightSize As Float = DipToCurrent(6)
		For Each L As cLight In scene.Lights
			If L.Enabled = False Then Continue
			Dim base As Vec3
			If L.Kind = L.KIND_DIRECTIONAL Then
				Dim dir As Vec3 = Math3D.Normalize(Math3D.Mul(L.Direction, -1))
				base = Math3D.AddV(scene.Camera.Pos, Math3D.Mul(dir, 5))
			Else
				base = L.Position
			End If
			Dim sp As ScreenPoint = ProjectWorldPoint(base, scene.Camera.Pos, right, upv, fwd, aspect, f, dstW, dstH)
			If sp.Success Then
				cvs.DrawCircle(sp.X, sp.Y, lightSize, L.Color, True, 0)
				If L.Kind = L.KIND_DIRECTIONAL Then
					Dim tip As Vec3 = Math3D.AddV(base, Math3D.Normalize(Math3D.Mul(L.Direction, -1)))
					Dim spTip As ScreenPoint = ProjectWorldPoint(tip, scene.Camera.Pos, right, upv, fwd, aspect, f, dstW, dstH)
					If spTip.Success Then cvs.DrawLine(sp.X, sp.Y, spTip.X, spTip.Y, L.Color, overlayStroke)
				End If
			End If
		Next
	End If

	If opt.ShowCamera Then
		Dim cx As Float = dstW / 2, cy As Float = dstH / 2
		Dim half As Float = DipToCurrent(10)
		Dim thin As Float = DipToCurrent(2)
		cvs.DrawLine(cx - half, cy, cx + half, cy, Colors.White, thin)
		cvs.DrawLine(cx, cy - half, cx, cy + half, Colors.White, thin)
	End If

	Dim t2 As Long = DateTime.Now
	stats.BuildMs = t1 - t0
	stats.RenderMs = t2 - t1
	LastStats = stats
	Return stats
End Sub

' Projects a point from world to screen and returns whether it is inside the clip range
Private Sub ProjectWorldPoint(world As Vec3, camPos As Vec3, right As Vec3, upv As Vec3, fwd As Vec3, aspect As Double, f As Double, dstW As Int, dstH As Int) As ScreenPoint
	Dim res As ScreenPoint
	res.Initialize

	Dim rel As Vec3 = Math3D.V3(world.X - camPos.X, world.Y - camPos.Y, world.Z - camPos.Z)
	Dim cxx As Double = Math3D.Dot(rel, right)
	Dim cyy As Double = Math3D.Dot(rel, upv)
	Dim cz As Double = Math3D.Dot(rel, fwd)
	res.Depth = cz

	If cz < NearZ Or cz > FarZ Then Return res

	Dim ndcX As Double = (cxx * f / aspect) / cz
	Dim ndcY As Double = (cyy * f) / cz
	res.X = (ndcX * 0.5 + 0.5) * dstW
	res.Y = (-ndcY * 0.5 + 0.5) * dstH
	res.Success = True
	Return res
End Sub
' --- RAY TRACE hook ---
Public Sub RenderRaytrace(scene As cScene, Width As Int, Height As Int) As ResumableSub	
	RT_Stat_TriTests = 0 : RT_Stat_AABBTests = 0 : RT_Stat_BVHNodesVisited = 0
	RT_Scene = scene
	testTimer.Enabled = True
'	Log("starting raytrace")
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
	If UseBVH Then BuildBVH_FromRTFrame
	
	' ---- camera basis / constants ----
	Dim right As Vec3, upv As Vec3, fwd As Vec3
	Dim resultArr() As Vec3 = scene.Camera.Basis(right, upv, fwd)
	fwd = resultArr(0) : right = resultArr(1) : upv = resultArr(2)
	
	RT_Right = right : RT_Up = upv : RT_Fwd = fwd
	RT_CamPos = scene.Camera.Pos
	RT_Aspect = RT_W / Max(1, RT_H)
	RT_TanHalf = Tan(scene.Camera.FOV_Deg * cPI / 180 / 2)
	
	' ---- light ----
	RT_LightDir = Math3D.V3(-1, -2, -1)
	Dim li As Int
	For li = 0 To scene.Lights.Size - 1
		Dim L As cLight = scene.Lights.Get(li)
		If L.Enabled Then
			RT_LightDir = L.Direction
			Exit
		End If
	Next

	' ---- output buffer ----
	Pixels = Math3D.CreateIntArray(RT_W * RT_H)

	' ---- thread fan-out (fixed 4 threads, 8 stripes) ----
'	Dim threadCount As Int = 4
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
'	Log($"BVH nodes=${BVH_NodeCount} visited=${RT_Stat_BVHNodesVisited}  triTests=${RT_Stat_TriTests}  aabbTests=${RT_Stat_AABBTests}"$)
	If success Then
		testTimer.Enabled = False
		Dim bmp As Bitmap
		bmp.InitializeMutable(RT_W, RT_H)
		Dim jbmp As JavaObject = bmp
		jbmp.RunMethod("setPixels", Array As Object(Pixels, 0, RT_W, 0, 0, RT_W, RT_H))
'		Log("should return bitmap")
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
	Return ColorToVec3(RayBackgroundColor)
End Sub

Private Sub ColorToVec3(col As Int) As Vec3
	Dim r As Double = Bit.And(Bit.ShiftRight(col, 16), 255) / 255.0
	Dim g As Double = Bit.And(Bit.ShiftRight(col, 8), 255) / 255.0
	Dim b As Double = Bit.And(col, 255) / 255.0
	Return Math3D.V3(r, g, b)
End Sub

Private Sub TraceColor(r As Ray, depth As Int, v As List, f As List, fn As List, refl As List) As Vec3
	If depth > RT_MaxDepth Then Return Background(r.Dir)

'	Dim h As Hit = TraceRay(r, v, f)
	Dim h As Hit
	If UseBVH And BVH_Built Then
		h = TraceRay_BVH(r, v, f)
	Else
		h = TraceRay(r, v, f)
	End If
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
'		If AnyHitShadow(s, v, f, RT_Eps) Then lam = 0
		If AnyHitShadow_BVH(s, v, f, RT_Eps) Then lam = 0
	End If

	
	Dim base As Vec3 = Math3D.V3( _
	    RT_AlbR.Get(h.FaceIndex), _
	    RT_AlbG.Get(h.FaceIndex), _
	    RT_AlbB.Get(h.FaceIndex))
	
	Dim direct As Vec3 = RT_DirectLight(p, n, base, h.FaceIndex)

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

Private Sub BVH_ResetNodes
	BVH_MinX.Initialize : BVH_MinY.Initialize : BVH_MinZ.Initialize
	BVH_MaxX.Initialize : BVH_MaxY.Initialize : BVH_MaxZ.Initialize
	BVH_Left.Initialize  : BVH_Right.Initialize
	BVH_First.Initialize : BVH_Count.Initialize : BVH_Axis.Initialize
	BVH_NodeCount = 0
End Sub

Private Sub BVH_NewNode(minx As Double, miny As Double, minz As Double, maxx As Double, maxy As Double, maxz As Double, _
                        axis As Int, first As Int, cnt As Int, left As Int, right As Int) As Int
	BVH_MinX.Add(minx) : BVH_MinY.Add(miny) : BVH_MinZ.Add(minz)
	BVH_MaxX.Add(maxx) : BVH_MaxY.Add(maxy) : BVH_MaxZ.Add(maxz)
	BVH_Axis.Add(axis)
	BVH_First.Add(first) : BVH_Count.Add(cnt)
	BVH_Left.Add(left) : BVH_Right.Add(right)
	Dim id As Int = BVH_MinX.Size - 1
	Return id
End Sub

Private Sub BuildBVH_FromRTFrame
	Dim nF As Int = RT_Faces.Size
	If nF = 0 Then 
		BVH_Built = False
		Return
	End If
	
	BVH_ResetNodes
	' permutation 0..nF-1
	Dim arr(nF) As Int
	For i = 0 To nF - 1
		arr(i) = i
	Next
	BVH_TriIdx = arr

	BVH_Root = BVH_BuildNode(0, nF)
	BVH_NodeCount = BVH_MinX.Size
	BVH_Built = True
End Sub

' Recursively builds a BVH node over BVH_TriIdx[start .. start+count)
Private Sub BVH_BuildNode(start As Int, count As Int) As Int
	' compute node bbox + centroid bbox
	Dim minx As Double =  1e30, miny As Double =  1e30, minz As Double =  1e30
	Dim maxx As Double = -1e30, maxy As Double = -1e30, maxz As Double = -1e30
	Dim cxmin As Double =  1e30, cymin As Double =  1e30, czmin As Double =  1e30
	Dim cxmax As Double = -1e30, cymax As Double = -1e30, czmax As Double = -1e30

	For i = start To start + count - 1
		Dim fi As Int = BVH_TriIdx(i)
		Dim tminx As Double = FMinX.Get(fi), tminy As Double = FMinY.Get(fi), tminz As Double = FMinZ.Get(fi)
		Dim tmaxx As Double = FMaxX.Get(fi), tmaxy As Double = FMaxY.Get(fi), tmaxz As Double = FMaxZ.Get(fi)
		If tminx < minx Then minx = tminx
		If tminy < miny Then miny = tminy
		If tminz < minz Then minz = tminz
		If tmaxx > maxx Then maxx = tmaxx
		If tmaxy > maxy Then maxy = tmaxy
		If tmaxz > maxz Then maxz = tmaxz

		Dim ccx As Double = FCx.Get(fi), ccy As Double = FCy.Get(fi), ccz As Double = FCz.Get(fi)
		If ccx < cxmin Then cxmin = ccx
		If ccy < cymin Then cymin = ccy
		If ccz < czmin Then czmin = ccz
		If ccx > cxmax Then cxmax = ccx
		If ccy > cymax Then cymax = ccy
		If ccz > czmax Then czmax = ccz
	Next

	' leaf?
	If count <= BVH_LeafMax Then
		Return BVH_NewNode(minx,miny,minz, maxx,maxy,maxz, -1, start, count, -1, -1)
	End If

	' split axis = widest centroid extent
	Dim ex As Double = cxmax - cxmin, ey As Double = cymax - cymin, ez As Double = czmax - czmin
	Dim axis As Int = 0
	If ey > ex And ey >= ez Then 
		axis = 1 
	Else If ez > ex And ez >= ey Then 
		axis = 2
	End If

	' split by centroid midpoint
	Dim splitVal As Double
	If axis = 0 Then 
		splitVal = (cxmin + cxmax) / 2 
	Else If axis = 1 Then 
		splitVal = (cymin + cymax) / 2
	Else 
		splitVal = (czmin + czmax) / 2
	End If

	' partition BVH_TriIdx[start..start+count)
	Dim li As Int = 0, ri As Int = 0
	Dim leftIdx(count) As Int, rightIdx(count) As Int
	
	For i = start To start + count - 1
		Dim fi As Int = BVH_TriIdx(i)
		Dim cx As Double = FCx.Get(fi), cy As Double = FCy.Get(fi), cz As Double = FCz.Get(fi)
		Dim key As Double = IIf(axis = 0, cx, IIf(axis = 1, cy, cz))
		If key < splitVal Then
			leftIdx(li) = fi : li = li + 1
		Else
			rightIdx(ri) = fi : ri = ri + 1
		End If
	Next
	
	' fallback if degenerate split
	If li = 0 Or ri = 0 Then
		li = count / 2 : ri = count - li
		Dim k As Int = 0
		For i = 0 To li - 1
			leftIdx(i) = BVH_TriIdx(start + k) : k = k + 1
		Next
		For i = 0 To ri - 1
			rightIdx(i) = BVH_TriIdx(start + k) : k = k + 1
		Next
	End If
	
	' write back partitioned order
	Dim p As Int = start
	For i = 0 To li - 1
		BVH_TriIdx(p) = leftIdx(i) : p = p + 1
	Next
	Dim mid As Int = p
	For i = 0 To ri - 1
		BVH_TriIdx(p) = rightIdx(i) : p = p + 1
	Next
	
	' build children
	Dim leftNode As Int = BVH_BuildNode(start, li)
	Dim rightNode As Int = BVH_BuildNode(mid, ri)
	
	Return BVH_NewNode(minx,miny,minz, maxx,maxy,maxz, axis, -1, 0, leftNode, rightNode)
End Sub

Private Sub RayAABB_TNear(rox As Double, roy As Double, roz As Double, rdx As Double, rdy As Double, rdz As Double, _
                           minx As Double, miny As Double, minz As Double, maxx As Double, maxy As Double, maxz As Double) As Double
	RT_Stat_AABBTests = RT_Stat_AABBTests + 1
	Dim tmin As Double = 0, tmax As Double = 1e30, t1 As Double, t2 As Double, inv As Double

	' X
	If Abs(rdx) < 1e-12 Then
		If rox < minx Or rox > maxx Then Return 1e30
	Else
		inv = 1/rdx : t1 = (minx - rox) * inv : t2 = (maxx - rox) * inv
		If t1 > t2 Then 
			Dim tt As Double = t1 : t1 = t2 : t2 = tt
		End If
		If t1 > tmin Then tmin = t1
		If t2 < tmax Then tmax = t2
		If tmax < tmin Then Return 1e30
	End If
	' Y
	If Abs(rdy) < 1e-12 Then
		If roy < miny Or roy > maxy Then Return 1e30
	Else
		inv = 1/rdy : t1 = (miny - roy) * inv : t2 = (maxy - roy) * inv
		If t1 > t2 Then 
			Dim tt2 As Double = t1 : t1 = t2 : t2 = tt2
		End If
		If t1 > tmin Then tmin = t1
		If t2 < tmax Then tmax = t2
		If tmax < tmin Then Return 1e30
	End If
	' Z
	If Abs(rdz) < 1e-12 Then
		If roz < minz Or roz > maxz Then Return 1e30
	Else
		inv = 1/rdz : t1 = (minz - roz) * inv : t2 = (maxz - roz) * inv
		If t1 > t2 Then 
			Dim tt3 As Double = t1 : t1 = t2 : t2 = tt3
		End If
		If t1 > tmin Then tmin = t1
		If t2 < tmax Then tmax = t2
		If tmax < tmin Then Return 1e30
	End If
	If tmax < 0 Then Return 1e30
	If tmin < 0 Then tmin = 0
	Return tmin
End Sub

Private Sub TraceRay_BVH(r As Ray, v As List, f As List) As Hit
	Dim best As Hit : best.T = 1e30 : best.FaceIndex = -1
	If Not(BVH_Built) Then Return TraceRay(r, v, f) ' fallback
	
	Dim rox As Double = r.Origin.X, roy As Double = r.Origin.Y, roz As Double = r.Origin.Z
	Dim rdx As Double = r.Dir.X,    rdy As Double = r.Dir.Y,    rdz As Double = r.Dir.Z
	
	Dim stack As List : stack.Initialize
	stack.Add(BVH_Root)
	
	Do While stack.Size > 0
		Dim node As Int = stack.Get(stack.Size - 1)
		stack.RemoveAt(stack.Size - 1)
		RT_Stat_BVHNodesVisited = RT_Stat_BVHNodesVisited + 1

		Dim tnear As Double = RayAABB_TNear(rox,roy,roz, rdx,rdy,rdz, _
                        BVH_MinX.Get(node), BVH_MinY.Get(node), BVH_MinZ.Get(node), _
                        BVH_MaxX.Get(node), BVH_MaxY.Get(node), BVH_MaxZ.Get(node))
		If tnear >= best.T Then Continue ' node is further than current hit
		If tnear >= 1e29 Then Continue   ' miss

		Dim first As Int = BVH_First.Get(node)
		Dim cnt As Int = BVH_Count.Get(node)
		If first >= 0 Then
			' leaf
			For i = 0 To cnt - 1
				Dim fi As Int = BVH_TriIdx(first + i)
				' optional sphere/AABB quick reject (already culled by node)
				Dim fc As Face = f.Get(fi)
				Dim a As Vec3 = v.Get(fc.A), b As Vec3 = v.Get(fc.B), c As Vec3 = v.Get(fc.C)
				Dim h As Hit : h.T = best.T : h.FaceIndex = -1
				RT_Stat_TriTests = RT_Stat_TriTests + 1
				If IntersectTriangle(r, a,b,c, h) Then
					If h.T < best.T Then
						best = h : best.FaceIndex = fi
					End If
				End If
			Next
		Else
			' inner: visit near first (by tNear of child boxes)
			Dim l As Int = BVH_Left.Get(node), rr As Int = BVH_Right.Get(node)
			Dim tL As Double = RayAABB_TNear(rox,roy,roz, rdx,rdy,rdz, BVH_MinX.Get(l),BVH_MinY.Get(l),BVH_MinZ.Get(l), BVH_MaxX.Get(l),BVH_MaxY.Get(l),BVH_MaxZ.Get(l))
			Dim tR As Double = RayAABB_TNear(rox,roy,roz, rdx,rdy,rdz, BVH_MinX.Get(rr),BVH_MinY.Get(rr),BVH_MinZ.Get(rr), BVH_MaxX.Get(rr),BVH_MaxY.Get(rr),BVH_MaxZ.Get(rr))
			If tL > tR Then
				If tL < best.T Then stack.Add(l)
				If tR < best.T Then stack.Add(rr)
			Else
				If tR < best.T Then stack.Add(rr)
				If tL < best.T Then stack.Add(l)
			End If
		End If
	Loop
	Return best
End Sub

Private Sub AnyHitShadow_BVH(r As Ray, v As List, f As List, eps As Double) As Boolean
	If Not(BVH_Built) Then Return AnyHitShadow(r, v, f, eps) ' fallback

	Dim rox As Double = r.Origin.X, roy As Double = r.Origin.Y, roz As Double = r.Origin.Z
	Dim rdx As Double = r.Dir.X,    rdy As Double = r.Dir.Y,    rdz As Double = r.Dir.Z

	Dim stack As List : stack.Initialize
	stack.Add(BVH_Root)
	
	Do While stack.Size > 0
		Dim node As Int = stack.Get(stack.Size - 1)
		stack.RemoveAt(stack.Size - 1)

		Dim tnear As Double = RayAABB_TNear(rox,roy,roz, rdx,rdy,rdz, _
                        BVH_MinX.Get(node), BVH_MinY.Get(node), BVH_MinZ.Get(node), _
                        BVH_MaxX.Get(node), BVH_MaxY.Get(node), BVH_MaxZ.Get(node))
		If tnear >= 1e29 Then Continue

		Dim first As Int = BVH_First.Get(node)
		Dim cnt As Int = BVH_Count.Get(node)
		If first >= 0 Then
			For i = 0 To cnt - 1
				Dim fi As Int = BVH_TriIdx(first + i)
				Dim fc As Face = f.Get(fi)
				Dim a As Vec3 = v.Get(fc.A), b As Vec3 = v.Get(fc.B), c As Vec3 = v.Get(fc.C)
				Dim h As Hit : h.T = 1e30 : h.FaceIndex = -1
				RT_Stat_TriTests = RT_Stat_TriTests + 1
				If IntersectTriangle(r, a,b,c, h) Then
					If h.T > eps Then Return True
				End If
			Next
		Else
			Dim l As Int = BVH_Left.Get(node), rr As Int = BVH_Right.Get(node)
			' no need near-first for any-hit; but doing it can prune a bit
			Dim tL As Double = RayAABB_TNear(rox,roy,roz, rdx,rdy,rdz, BVH_MinX.Get(l),BVH_MinY.Get(l),BVH_MinZ.Get(l), BVH_MaxX.Get(l),BVH_MaxY.Get(l),BVH_MaxZ.Get(l))
			Dim tR As Double = RayAABB_TNear(rox,roy,roz, rdx,rdy,rdz, BVH_MinX.Get(rr),BVH_MinY.Get(rr),BVH_MinZ.Get(rr), BVH_MaxX.Get(rr),BVH_MaxY.Get(rr),BVH_MaxZ.Get(rr))
			If tL > tR Then
				stack.Add(l) : stack.Add(rr)
			Else
				stack.Add(rr) : stack.Add(l)
			End If
		End If
	Loop
	Return False
End Sub

' Reset accumulation when camera or scene changes
Public Sub PathReset
	PT_SamplesAccum = 0
	PT_Frame = PT_Frame + 1
End Sub

Private Sub EnsurePathBuffers(w As Int, h As Int)
	If PT_W <> w Or PT_H <> h Or PT_SamplesAccum = 0 Then
		PT_W = w
		PT_H = h
		Dim n As Int = w * h
		Dim i As Int

		Dim r(n) As Double
		Dim g(n) As Double
		Dim b(n) As Double
		PT_AccumR = r
		PT_AccumG = g
		PT_AccumB = b
		For i = 0 To n - 1
			PT_AccumR(i) = 0
			PT_AccumG(i) = 0
			PT_AccumB(i) = 0
		Next
		PT_SamplesAccum = 0
	End If
End Sub

' -------- Path Tracing (progressive) --------
Public Sub RenderPathTrace(scene As cScene, dstW As Int, dstH As Int, spp As Int, maxBounces As Int) As Bitmap
	' Build frame + RT state like your Whitted renderer
	Dim fr As SceneFrame = scene.BuildFrame
	If fr.Faces.Size = 0 Or fr.Verts.Size = 0 Then
		Dim empty As Bitmap
		empty.InitializeMutable(dstW, dstH)
		Return empty
	End If

	' Camera basis (robust)
	Dim camPos As Vec3 = scene.Camera.Pos
	Dim camTarget As Vec3 = scene.Camera.Target
	Dim camUp As Vec3 = scene.Camera.Up

	Dim fwd As Vec3 = Math3D.Normalize(Math3D.SubV(camTarget, camPos))
	If Math3D.Len(fwd) < 1e-6 Then
		fwd = Math3D.V3(0, 0, -1)
	End If
	Dim upCand As Vec3
	If Math3D.Len(camUp) < 1e-6 Then
		upCand = Math3D.V3(0, 1, 0)
	Else
		upCand = camUp
	End If
	Dim right As Vec3 = Math3D.Cross(fwd, upCand)
	If Math3D.Len(right) < 1e-6 Then
		If Abs(fwd.Y) > 0.9 Then
			upCand = Math3D.V3(0, 0, 1)
		Else
			upCand = Math3D.V3(0, 1, 0)
		End If
		right = Math3D.Cross(fwd, upCand)
	End If
	right = Math3D.Normalize(right)
	Dim upv As Vec3 = Math3D.Cross(right, fwd)

	Dim aspect As Double = dstW / Max(1, dstH)
	Dim fovRad As Double = scene.Camera.FOV_Deg * cPI / 180
	Dim invTan As Double = 1 / Tan(fovRad / 2)

	' Push RT data from frame
	RT_Verts = fr.Verts
	RT_Faces = fr.Faces
	RT_FaceN = fr.FaceN
	RT_CornerN = fr.CornerN                     ' smooth shading, per-corner
	' material data
	Dim i As Int
	RT_AlbR.Initialize : RT_AlbG.Initialize : RT_AlbB.Initialize
	RT_Refl.Initialize
	For i = 0 To fr.Faces.Size - 1
		Dim matIdx As Int = fr.FaceMat.Get(i)
		Dim col1 As Int = Colors.RGB(200, 200, 200)
		Dim kr As Double = 0
		If matIdx >= 0 And matIdx < scene.Materials.Size Then
			Dim M As cMaterial = scene.Materials.Get(matIdx)
			col1 = M.Albedo
			kr = Max(0, Min(1, M.Reflectivity))
		End If
		RT_AlbR.Add(Bit.And(Bit.ShiftRight(col1, 16), 255) / 255.0)
		RT_AlbG.Add(Bit.And(Bit.ShiftRight(col1, 8), 255) / 255.0)
		RT_AlbB.Add(Bit.And(col1, 255) / 255.0)
		RT_Refl.Add(kr)
	Next
	
	' Precompute triangle accel & BVH
	PrecomputeFaceAccel(RT_Verts, RT_Faces)
	UseBVH = True
	BuildBVH_FromRTFrame

	' Light (directional) from scene
	Dim haveLight As Boolean = False
	Dim Ldir As Vec3 = Math3D.V3(-1, -1, -1)
	Dim li As Int
	For li = 0 To scene.Lights.Size - 1
		Dim L As cLight = scene.Lights.Get(li)
		If L.Enabled Then
			Ldir = L.Direction
			haveLight = True
			Exit
		End If
	Next
	Dim LightToSurf As Vec3 = Math3D.Normalize(Math3D.Mul(Ldir, -1))  ' points from surface toward light

	EnsurePathBuffers(dstW, dstH)

	' Render SPP samples and accumulate
	Dim x As Int, y As Int, s As Int, idx As Int
	For y = 0 To dstH - 1
		For x = 0 To dstW - 1
			idx = y * dstW + x
			Dim seed As Int = HashSeed(x, y, PT_SamplesAccum, PT_Frame)

			For s = 0 To spp - 1
				' Subpixel jitter
				Dim jx As Double = RNGNext01(seed)
				Dim jy As Double = RNGNext01(seed)

				' Primary ray NDC -> camera space
				Dim px As Double = ((x + jx) / dstW) * 2 - 1
				Dim py As Double = 1 - ((y + jy) / dstH) * 2
				px = px * aspect
				Dim dirCam As Vec3 = Math3D.Normalize(Math3D.V3(px / invTan, py / invTan, 1))

				' To world
				Dim d As Vec3 = Math3D.Normalize(Math3D.V3( _
                    dirCam.X * right.X + dirCam.Y * upv.X + dirCam.Z * fwd.X, _
                    dirCam.X * right.Y + dirCam.Y * upv.Y + dirCam.Z * fwd.Y, _
                    dirCam.X * right.Z + dirCam.Y * upv.Z + dirCam.Z * fwd.Z))

				Dim ray As Ray
				ray.Origin = camPos
				ray.Dir = d

				Dim throughput As Vec3 = Math3D.V3(1, 1, 1)
				Dim col As Vec3 = Math3D.V3(0, 0, 0)

				Dim bounce As Int
				For bounce = 0 To maxBounces - 1
					Dim h As Hit = TraceRay_BVH(ray, RT_Verts, RT_Faces)
					If h.FaceIndex < 0 Then
						Dim miss As Vec3 = ColorToVec3(PathBackgroundColor)
						col = Math3D.AddV(col, Math3D.V3(throughput.X * miss.X, throughput.Y * miss.Y, throughput.Z * miss.Z))
						Exit
					End If

					' Hit point and shading normal (per-corner + barycentrics)
					Dim p As Vec3 = Math3D.V3( _
                        ray.Origin.X + ray.Dir.X * h.T, _
                        ray.Origin.Y + ray.Dir.Y * h.T, _
                        ray.Origin.Z + ray.Dir.Z * h.T)

					Dim fi As Int = h.FaceIndex
					Dim fc As Face = RT_Faces.Get(fi)
					Dim u As Double = h.U
					Dim v As Double = h.V
					Dim wB As Double = 1 - u - v

					Dim ci As Int = fi * 3
					Dim aN As Vec3 = RT_CornerN.Get(ci + 0)
					Dim bN As Vec3 = RT_CornerN.Get(ci + 1)
					Dim cN As Vec3 = RT_CornerN.Get(ci + 2)
					Dim n As Vec3 = Math3D.Normalize(Math3D.AddV(Math3D.AddV(Math3D.Mul(aN, wB), Math3D.Mul(bN, u)), Math3D.Mul(cN, v)))
					If Math3D.Dot(n, ray.Dir) > 0 Then
						n = Math3D.Mul(n, -1)
					End If

					' Material
					Dim base As Vec3 = Math3D.V3(RT_AlbR.Get(fi), RT_AlbG.Get(fi), RT_AlbB.Get(fi))
					Dim kRefl As Double = RT_Refl.Get(fi)

					' Direct light (next-event) to reduce noise
					If PT_UseDirectLight And haveLight Then
						Dim dl As Vec3 = PT_DirectLight(p, n, base, seed, scene)
						col = Math3D.AddV(col, Math3D.V3(throughput.X * dl.X, throughput.Y * dl.Y, throughput.Z * dl.Z))
					End If

					' Russian roulette (after a few bounces)
					If bounce >= 3 Then
						Dim q As Double = Clamp01(Luminance(throughput))
						Dim rStop As Double = RNGNext01(seed)
						If rStop > q Then
							Exit
						End If
						throughput = Math3D.V3(throughput.X / q, throughput.Y / q, throughput.Z / q)
					End If

					' Choose event: perfect mirror with prob kRefl, else diffuse
					Dim rPick As Double = RNGNext01(seed)
					If rPick < kRefl Then
						' Mirror reflection (delta lobe): throughput *= 1 (perfect energy-conserving mirror)
						Dim rdir As Vec3 = Math3D.Normalize(Reflect(ray.Dir, n))
						ray.Origin = Math3D.AddV(p, Math3D.Mul(n, RT_Eps))
						ray.Dir = rdir
						' continue to next bounce
					Else
						' Diffuse bounce: cosine-weighted hemisphere
						Dim tB As Vec3, bB As Vec3
						OrthoBasis(n, tB, bB)
						Dim u1 As Double = RNGNext01(seed)
						Dim u2 As Double = RNGNext01(seed)
						Dim ts As Vec3 = SampleCosHemisphere(u1, u2)
						Dim ndir As Vec3 = TangentToWorld(ts, tB, bB, n)

						' With cosine sampling: f = base/PI, pdf = cos/pi -> throughput *= base
						throughput = Math3D.V3(throughput.X * base.X, throughput.Y * base.Y, throughput.Z * base.Z)

						ray.Origin = Math3D.AddV(p, Math3D.Mul(n, RT_Eps))
						ray.Dir = ndir
					End If
				Next

				' Accumulate sample color
				PT_AccumR(idx) = PT_AccumR(idx) + col.X
				PT_AccumG(idx) = PT_AccumG(idx) + col.Y
				PT_AccumB(idx) = PT_AccumB(idx) + col.Z
			Next
		Next
	Next

	PT_SamplesAccum = PT_SamplesAccum + spp

	' Pack to bitmap (average)
	Dim pix(dstW * dstH) As Int
	Dim i2 As Int = 0
	Dim invS As Double = 1 / Max(1, PT_SamplesAccum)
	For i2 = 0 To pix.Length - 1
		Dim r As Double = PT_AccumR(i2) * invS
		Dim g As Double = PT_AccumG(i2) * invS
		Dim b As Double = PT_AccumB(i2) * invS
		pix(i2) = PackColor(r, g, b)
	Next

	Dim bmp As Bitmap
	bmp.InitializeMutable(dstW, dstH)
	Dim jbmp As JavaObject = bmp
	jbmp.RunMethod("setPixels", Array As Object(pix, 0, dstW, 0, 0, dstW, dstH))
	Return bmp
End Sub

' --- small math helpers (Vec3 versions you already use) ---
Private Sub OrthoBasis(n As Vec3, t As Vec3, b As Vec3)
	' Build tangent/bitangent orthonormal to n
	Dim a As Vec3
	If Abs(n.Z) < 0.999 Then
		a = Math3D.V3(0, 0, 1)
	Else
		a = Math3D.V3(0, 1, 0)
	End If
	t = Math3D.Normalize(Math3D.Cross(a, n))
	b = Math3D.Cross(n, t)
End Sub

' Cosine-weighted hemisphere sample around +Z in tangent space
Private Sub SampleCosHemisphere(u1 As Double, u2 As Double) As Vec3
	Dim r As Double = Sqrt(u1)
	Dim theta As Double = 2 * cPI * u2
	Dim x As Double = r * Cos(theta)
	Dim y As Double = r * Sin(theta)
	Dim z As Double = Sqrt(Max(0, 1 - u1))
	Return Math3D.V3(x, y, z)
End Sub

' Map tangent-space dir to world using (t, b, n)
Private Sub TangentToWorld(ts As Vec3, t As Vec3, b As Vec3, n As Vec3) As Vec3
	Return Math3D.Normalize(Math3D.V3( _
        ts.X * t.X + ts.Y * b.X + ts.Z * n.X, _
        ts.X * t.Y + ts.Y * b.Y + ts.Z * n.Y, _
        ts.X * t.Z + ts.Y * b.Z + ts.Z * n.Z))
End Sub

Private Sub Luminance(c As Vec3) As Double
	Return 0.2126 * c.X + 0.7152 * c.Y + 0.0722 * c.Z
End Sub

Private Sub Clamp01(x As Double) As Double
	If x < 0 Then Return 0
	If x > 1 Then Return 1
	Return x
End Sub

Private Sub PackColor(r As Double, g As Double, b As Double) As Int
	Dim rr As Int = Min(255, Max(0, r * 255))
	Dim gg As Int = Min(255, Max(0, g * 255))
	Dim bb As Int = Min(255, Max(0, b * 255))
	Return Math3D.ARGB255(255, rr, gg, bb)
End Sub

' --- tiny deterministic RNG (xorshift32) ---
Private Sub HashSeed(x As Int, y As Int, s As Int, f As Long) As Int
	Dim z As Int = x * 1973
	z = Bit.Xor(z, y * 9277)
	z = Bit.Xor(z, s * 26699)
	z = Bit.Xor(z, Bit.And(f, 0x7FFFFFFF))
	If z = 0 Then z = 1
	Return z
End Sub

Private Sub RNGNext01(state As Int) As Double
	Dim x As Long = state
	x = Bit.Xor(x, Bit.ShiftLeft(x, 13))
	x = Bit.Xor(x, Bit.ShiftRight(x, 17))
	x = Bit.Xor(x, Bit.ShiftLeft(x, 5))
	state = Bit.And(x, 0x7FFFFFFF)
	Return (state Mod 65536) / 65536.0
End Sub

' Convert light color*intensity to linear RGB (0..1)
Private Sub LightRGB(L As cLight) As Vec3
	Dim r As Double = Bit.And(Bit.ShiftRight(L.Color, 16), 255) / 255.0
	Dim g As Double = Bit.And(Bit.ShiftRight(L.Color, 8), 255) / 255.0
	Dim b As Double = Bit.And(L.Color, 255) / 255.0
	Return Math3D.V3(r * L.Intensity, g * L.Intensity, b * L.Intensity)
End Sub

' Uniform sample on a rectangular area light: returns a point on the emitter surface
Private Sub SampleRect(L As cLight, u1 As Double, u2 As Double) As Vec3
	Dim sx As Double = u1 * 2 - 1
	Dim sy As Double = u2 * 2 - 1
	Return Math3D.AddV(Math3D.AddV(L.Position, Math3D.Mul(L.U, sx)), Math3D.Mul(L.V, sy))
End Sub

Private Sub RT_DirectLight(p As Vec3, n As Vec3, base As Vec3, faceIndex As Int) As Vec3
	Dim sum As Vec3
	sum = Math3D.V3(0, 0, 0)

	If RT_Scene = Null Then
		Return sum
	End If
	Dim i As Int
	For i = 0 To RT_Scene.Lights.Size - 1
		Dim L As cLight = RT_Scene.Lights.Get(i)
		If L.Enabled = False Then Continue
		Dim E As Vec3 = LightRGB(L)

		If L.Kind = l.KIND_DIRECTIONAL Then
			Dim wi As Vec3 = Math3D.Normalize(Math3D.Mul(L.Direction, -1))
			Dim lam As Double = Math3D.Dot(n, wi)
			If lam > 0 Then
				Dim sray As Ray
				sray.Origin = Math3D.AddV(p, Math3D.Mul(n, RT_Eps))
				sray.Dir = wi
				Dim blocked As Boolean = AnyHitShadow_BVH(sray, RT_Verts, RT_Faces, RT_Eps)
				If blocked = False Then
					' Lambert: base/π * E * cos
					Dim add As Vec3 = Math3D.V3(E.X * base.X * lam / cPI, E.Y * base.Y * lam / cPI, E.Z * base.Z * lam / cPI)
					sum = Math3D.AddV(sum, add)
				End If
			End If

		Else If L.Kind = l.KIND_POINT Then
			Dim toL As Vec3 = Math3D.SubV(L.Position, p)
			Dim d2 As Double = Math3D.Dot(toL, toL)
			If d2 > 1e-9 Then
				Dim d As Double = Sqrt(d2)
				Dim wi As Vec3 = Math3D.Mul(toL, 1 / d)
				Dim lam As Double = Math3D.Dot(n, wi)
				If lam > 0 Then
					Dim sray As Ray
					sray.Origin = Math3D.AddV(p, Math3D.Mul(n, RT_Eps))
					sray.Dir = wi
					Dim blocked As Boolean = AnyHitShadow_BVH(sray, RT_Verts, RT_Faces, RT_Eps)
					If blocked = False Then
						Dim invr2 As Double = 1 / d2
						Dim add As Vec3 = Math3D.V3(E.X * base.X * lam * invr2 / cPI, E.Y * base.Y * lam * invr2 / cPI, E.Z * base.Z * lam * invr2 / cPI)
						sum = Math3D.AddV(sum, add)
					End If
				End If
			End If

		Else If L.Kind = l.KIND_SPOT Then
			Dim toL As Vec3 = Math3D.SubV(L.Position, p)
			Dim d2 As Double = Math3D.Dot(toL, toL)
			If d2 > 1e-9 Then
				Dim d As Double = Sqrt(d2)
				Dim wi As Vec3 = Math3D.Mul(toL, 1 / d)
				Dim lam As Double = Math3D.Dot(n, wi)
				If lam > 0 Then
					Dim spotCos As Double = Math3D.Dot(Math3D.Normalize(Math3D.Mul(L.Direction, -1)), wi)
					If spotCos > L.CosOuter Then
						Dim t As Double
						If spotCos >= L.CosInner Then
							t = 1
						Else
							Dim s As Double = (spotCos - L.CosOuter) / Max(1e-6, (L.CosInner - L.CosOuter))
							t = s * s * (3 - 2 * s)
						End If
						Dim sray As Ray
						sray.Origin = Math3D.AddV(p, Math3D.Mul(n, RT_Eps))
						sray.Dir = wi
						Dim blocked As Boolean = AnyHitShadow_BVH(sray, RT_Verts, RT_Faces, RT_Eps)
						If blocked = False Then
							Dim invr2 As Double = 1 / d2
							Dim add As Vec3 = Math3D.V3(E.X * base.X * lam * invr2 * t / cPI, E.Y * base.Y * lam * invr2 * t / cPI, E.Z * base.Z * lam * invr2 * t / cPI)
							sum = Math3D.AddV(sum, add)
						End If
					End If
				End If
			End If

		Else If L.Kind = l.KIND_RECT Then
			' Soft shadows via multi-sample shadow rays
			Dim nL As Vec3 = L.Normal
			Dim area As Double = L.Area
			If area > 0 Then
				Dim seed As Int = HashSeed(faceIndex, i, 12345, 0)
				Dim s1 As Int
				Dim acc As Vec3
				acc = Math3D.V3(0, 0, 0)
				For s1 = 0 To RT_AreaLightSamples - 1
					Dim u1 As Double = RNGNext01(seed)
					Dim u2 As Double = RNGNext01(seed)
					Dim xL As Vec3 = SampleRect(L, u1, u2)

					Dim toL As Vec3 = Math3D.SubV(xL, p)
					Dim d2 As Double = Math3D.Dot(toL, toL)
					If d2 <= 1e-9 Then
						Continue
					End If
					Dim d As Double = Sqrt(d2)
					Dim wi As Vec3 = Math3D.Mul(toL, 1 / d)

					Dim lamS As Double = Math3D.Dot(n, wi)
					If lamS <= 0 Then
						Continue
					End If
					Dim lamL As Double = Math3D.Dot(nL, Math3D.Mul(wi, -1))
					If lamL <= 0 Then
						Continue
					End If

					Dim sray As Ray
					sray.Origin = Math3D.AddV(p, Math3D.Mul(n, RT_Eps))
					sray.Dir = wi
					Dim blocked As Boolean = AnyHitShadow_BVH(sray, RT_Verts, RT_Faces, RT_Eps)
					If blocked Then
						Continue
					End If

					' base/π * E * (cosS * cosL) * area / r^2
					Dim geom As Double = lamS * lamL * area / d2
					Dim add As Vec3 = Math3D.V3(E.X * base.X * geom / cPI, E.Y * base.Y * geom / cPI, E.Z * base.Z * geom / cPI)
					acc = Math3D.AddV(acc, add)
				Next
				Dim inv As Double = 1 / Max(1, RT_AreaLightSamples)
				sum = Math3D.AddV(sum, Math3D.Mul(acc, inv))
			End If
		End If
	Next

	Return sum
End Sub

Private Sub PT_DirectLight(p As Vec3, n As Vec3, base As Vec3, seed As Int, scene As cScene) As Vec3
	Dim sum As Vec3
	sum = Math3D.V3(0, 0, 0)
	Dim i As Int
	For i = 0 To scene.Lights.Size - 1
		Dim L As cLight = scene.Lights.Get(i)
		If L.Enabled = False Then Continue
		Dim E As Vec3 = LightRGB(L)

		If L.Kind = l.KIND_DIRECTIONAL Then
			Dim wi As Vec3 = Math3D.Normalize(Math3D.Mul(L.Direction, -1))
			Dim lam As Double = Math3D.Dot(n, wi)
			If lam > 0 Then
				Dim sray As Ray
				sray.Origin = Math3D.AddV(p, Math3D.Mul(n, RT_Eps))
				sray.Dir = wi
				If AnyHitShadow_BVH(sray, RT_Verts, RT_Faces, RT_Eps) = False Then
					sum = Math3D.AddV(sum, Math3D.V3(E.X * base.X * lam / cPI, E.Y * base.Y * lam / cPI, E.Z * base.Z * lam / cPI))
				End If
			End If

		Else If L.Kind =l.KIND_POINT Then
			Dim toL As Vec3 = Math3D.SubV(L.Position, p)
			Dim d2 As Double = Math3D.Dot(toL, toL)
			If d2 > 1e-9 Then
				Dim d As Double = Sqrt(d2)
				Dim wi As Vec3 = Math3D.Mul(toL, 1 / d)
				Dim lam As Double = Math3D.Dot(n, wi)
				If lam > 0 Then
					Dim sray As Ray
					sray.Origin = Math3D.AddV(p, Math3D.Mul(n, RT_Eps))
					sray.Dir = wi
					If AnyHitShadow_BVH(sray, RT_Verts, RT_Faces, RT_Eps) = False Then
						Dim invr2 As Double = 1 / d2
						sum = Math3D.AddV(sum, Math3D.V3(E.X * base.X * lam * invr2 / cPI, E.Y * base.Y * lam * invr2 / cPI, E.Z * base.Z * lam * invr2 / cPI))
					End If
				End If
			End If

		Else If L.Kind = L.KIND_RECT Then
			' single sample per bounce (good variance with path tracing)
			Dim nL As Vec3 = L.Normal
			Dim area As Double = L.Area
			If area > 0 Then
				Dim u1 As Double = RNGNext01(seed)
				Dim u2 As Double = RNGNext01(seed)
				Dim xL As Vec3 = SampleRect(L, u1, u2)

				Dim toL As Vec3 = Math3D.SubV(xL, p)
				Dim d2 As Double = Math3D.Dot(toL, toL)
				If d2 > 1e-9 Then
					Dim d As Double = Sqrt(d2)
					Dim wi As Vec3 = Math3D.Mul(toL, 1 / d)
					Dim lamS As Double = Math3D.Dot(n, wi)
					If lamS > 0 Then
						Dim lamL As Double = Math3D.Dot(nL, Math3D.Mul(wi, -1))
						If lamL > 0 Then
							Dim sray As Ray
							sray.Origin = Math3D.AddV(p, Math3D.Mul(n, RT_Eps))
							sray.Dir = wi
							If AnyHitShadow_BVH(sray, RT_Verts, RT_Faces, RT_Eps) = False Then
								Dim geom As Double = lamS * lamL * area / d2
								sum = Math3D.AddV(sum, Math3D.V3(E.X * base.X * geom / cPI, E.Y * base.Y * geom / cPI, E.Z * base.Z * geom / cPI))
							End If
						End If
					End If
				End If
			End If

		Else If L.Kind = l.KIND_SPOT Then
			Dim toL As Vec3 = Math3D.SubV(L.Position, p)
			Dim d2 As Double = Math3D.Dot(toL, toL)
			If d2 > 1e-9 Then
				Dim d As Double = Sqrt(d2)
				Dim wi As Vec3 = Math3D.Mul(toL, 1 / d)
				Dim lam As Double = Math3D.Dot(n, wi)
				If lam > 0 Then
					Dim spotCos As Double = Math3D.Dot(Math3D.Normalize(Math3D.Mul(L.Direction, -1)), wi)
					If spotCos > L.CosOuter Then
						Dim t As Double
						If spotCos >= L.CosInner Then
							t = 1
						Else
							Dim s As Double = (spotCos - L.CosOuter) / Max(1e-6, (L.CosInner - L.CosOuter))
							t = s * s * (3 - 2 * s)
						End If
						Dim sray As Ray
						sray.Origin = Math3D.AddV(p, Math3D.Mul(n, RT_Eps))
						sray.Dir = wi
						If AnyHitShadow_BVH(sray, RT_Verts, RT_Faces, RT_Eps) = False Then
							Dim invr2 As Double = 1 / d2
							sum = Math3D.AddV(sum, Math3D.V3(E.X * base.X * lam * invr2 * t / cPI, E.Y * base.Y * lam * invr2 * t / cPI, E.Z * base.Z * lam * invr2 * t / cPI))
						End If
					End If
				End If
			End If
		End If
	Next
	Return sum
End Sub
