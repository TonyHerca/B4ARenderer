B4A=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=13.4
@EndOfDesignText@
' cMesh.bas
#Region Imports
' Use Math3D.* utilities
#End Region

Sub Class_Globals
	Public Name As String = "Mesh"
	Public Verts As List     ' List(Math3D.Vec3)
	Public Faces As List     ' List(Math3D.Face)
	Public FaceN As List     ' List(Math3D.Vec3)
	Public FaceMat As List   ' List(Int) material index per face
	Public VertN As List
	Public CornerN As List
	
	' Transform
	Public Position As Vec3
	Public Rotation As Vec3  ' yaw (Y), pitch (X), roll (Z) in radians
	Public Scale As Double
	
	Public creaseDegs As Int = 60
	
	' Bounds
	Public MinY As Double, MaxY As Double
End Sub

Public Sub Initialize(n As String)
	Name = n
	Verts.Initialize : Faces.Initialize : FaceN.Initialize : FaceMat.Initialize : VertN.Initialize : CornerN.Initialize
	Position = Math3D.V3(0,0,0)
	Rotation = Math3D.V3(0,0,0)
	Scale = 1
	MinY = 0 : MaxY = 0
End Sub

Public Sub SetTRS(pos As Vec3, rot As Vec3, s As Double)
	Position = pos : Rotation = rot : Scale = s
End Sub

' --- OBJ loader from DirAssets (v + f only; triangulates ngons) ---
Public Sub LoadOBJFromAssets(FileName As String, MaterialIndex As Int)
	Verts.Clear : Faces.Clear : FaceN.Clear : FaceMat.Clear
	Dim tr As TextReader
	tr.Initialize(File.OpenInput(File.DirAssets, FileName))
	Dim line As String
	Do While True
		line = tr.ReadLine : If line = Null Then Exit
		line = line.Trim : If line.Length = 0 Then Continue
		If line.StartsWith("v ") Then
			Dim p() As String = Regex.Split("\s+", line)
			If p.Length >= 4 Then Verts.Add(Math3D.V3(p(1), p(2), p(3)))
		Else If line.StartsWith("f ") Then
			Dim raw() As String = Regex.Split("\s+", line)
			Dim idxs As List : idxs.Initialize
			For i = 1 To raw.Length - 1
				If raw(i).Length = 0 Then Continue
				Dim sp() As String = Regex.Split("/", raw(i))
				idxs.Add(sp(0) - 1)
			Next
			If idxs.Size >= 3 Then
				Dim a0 As Int = idxs.Get(0)
				For i = 1 To idxs.Size - 2
					Dim b0 As Int = idxs.Get(i)
					Dim c0 As Int = idxs.Get(i+1)
					Faces.Add(Math3D.F3(a0, b0, c0))
					FaceMat.Add(MaterialIndex)
				Next
			End If
		End If
	Loop
	tr.Close
	RecalcFaceNormals
	RecalcVertexNormals
	ComputeCornerNormalsSeamAware(60, 1e-6)
	UpdateYBounds
End Sub

Public Sub AddCube(size As Double, MaterialIndex As Int)
	Dim s As Double = size / 2
	' 8 verts
	Dim base As Int = Verts.Size
	Verts.AddAll(Array As Object( _
        Math3D.V3(-s,-s,-s), Math3D.V3(s,-s,-s), Math3D.V3(s,s,-s), Math3D.V3(-s,s,-s), _
        Math3D.V3(-s,-s, s), Math3D.V3(s,-s, s), Math3D.V3(s,s, s), Math3D.V3(-s,s, s)))
	' 12 tris
	Dim idx() As Int = Array As Int( _
        0,1,2, 0,2,3,  4,6,5, 4,7,6,  0,4,5, 0,5,1, _
        1,5,6, 1,6,2,  2,6,7, 2,7,3,  3,7,4, 3,4,0)
	For i = 0 To idx.Length - 1 Step 3
		Faces.Add(Math3D.F3(base+idx(i), base+idx(i+1), base+idx(i+2)))
		FaceMat.Add(MaterialIndex)
	Next
	RecalcFaceNormals
	RecalcVertexNormals
	ComputeCornerNormalsSeamAware(60, 1e-6)
	UpdateYBounds
End Sub

	Public Sub RecalcFaceNormals
	FaceN.Clear
	For i = 0 To Faces.Size - 1
		Dim f As Face = Faces.Get(i)
		Dim a As Vec3 = Verts.Get(f.A)
		Dim b As Vec3 = Verts.Get(f.B)
		Dim c As Vec3 = Verts.Get(f.C)
		Dim n As Vec3 = Math3D.Normalize(Math3D.Cross(Math3D.SubV(b,a), Math3D.SubV(c,a)))
		FaceN.Add(n)
	Next
End Sub

Public Sub RecalcVertexNormals
	VertN.Clear
	For i = 0 To Verts.Size - 1
		VertN.Add(Math3D.V3(0,0,0))
	Next
	For i = 0 To Faces.Size - 1
		Dim f As Face = Faces.Get(i)
		Dim a As Vec3 = Verts.Get(f.A)
		Dim b As Vec3 = Verts.Get(f.B)
		Dim c As Vec3 = Verts.Get(f.C)
		Dim e1 As Vec3 = Math3D.SubV(b, a)
		Dim e2 As Vec3 = Math3D.SubV(c, a)
		Dim n  As Vec3 = Math3D.Cross(e1, e2)   ' not normalized = 2*area * unitNormal
		' accumulate
		VertN.Set(f.A, Math3D.AddV(VertN.Get(f.A), n))
		VertN.Set(f.B, Math3D.AddV(VertN.Get(f.B), n))
		VertN.Set(f.C, Math3D.AddV(VertN.Get(f.C), n))
	Next
	For i = 0 To VertN.Size - 1
		VertN.Set(i, Math3D.Normalize(VertN.Get(i)))
	Next
End Sub

Private Sub UpdateYBounds
	If Verts.Size = 0 Then 
		MinY = 0
		MaxY = 0
		Return
	End If
	MinY = 1e9
	MaxY = -1e9
	For i = 0 To Verts.Size - 1
		Dim v As Vec3 = Verts.Get(i)
		If v.Y < MinY Then MinY = v.Y
		If v.Y > MaxY Then MaxY = v.Y
	Next
End Sub

' Get transformed world-space verts for this mesh
Public Sub WorldVerts As List
	Dim out As List : out.Initialize
	For i = 0 To Verts.Size - 1
		Dim p As Vec3 = Verts.Get(i)
		' scale -> rotate -> translate
		Dim ps As Vec3 = Math3D.Mul(p, Scale)
		Dim pr As Vec3 = Math3D.ApplyYawPitchRoll(ps, Rotation.X, Rotation.Y, Rotation.Z)
		out.Add(Math3D.AddV(pr, Position))
	Next
	Return out
End Sub

' Rotated normals (ignore translation, ignore scale sign for simplicity)
Public Sub WorldFaceNormals As List
	Dim out As List : out.Initialize
	For i = 0 To FaceN.Size - 1
		Dim n As Vec3 = FaceN.Get(i)
		Dim nr As Vec3 = Math3D.ApplyYawPitchRoll(n, Rotation.X, Rotation.Y, Rotation.Z)
		out.Add(Math3D.Normalize(nr))
	Next
	Return out
End Sub

' Swap B and C to reverse the face winding (and flip its stored normal)
Public Sub ReverseWindingFace(i As Int)
	If i < 0 Or i >= Faces.Size Then Return
	Dim f As Face = Faces.Get(i)
	Dim t As Int = f.B : f.B = f.C : f.C = t
	Faces.Set(i, f)
	If i >= 0 And i < FaceN.Size Then
		Dim n As Vec3 = FaceN.Get(i)
		FaceN.Set(i, Math3D.Mul(n, -1))
	End If
End Sub

' Reverse all faces in this mesh (useful if a whole mesh is inside-out)
Public Sub ReverseWindingAll
	For i = 0 To Faces.Size - 1
		ReverseWindingFace(i)
	Next
End Sub

' Flip only the normals (does not change winding; affects culling & shading)
Public Sub FlipNormalsAll
	For i = 0 To FaceN.Size - 1
		Dim n As Vec3 = FaceN.Get(i)
		FaceN.Set(i, Math3D.Mul(n, -1))
	Next
End Sub

' Ensure every face normal roughly points toward a desired direction.
' If not, reverse that face’s winding.
Public Sub EnsureFacing(desired As Vec3)
	desired = Math3D.Normalize(desired)
	For i = 0 To Faces.Size - 1
		Dim n As Vec3 = FaceN.Get(i)
		If Math3D.Dot(n, desired) < 0 Then ReverseWindingFace(i)
	Next
End Sub


' Clear + add helpers
Public Sub ClearAll
	Verts.Clear : Faces.Clear : FaceN.Clear : FaceMat.Clear
	MinY = 0 : MaxY = 0
End Sub

Private Sub AddVRet(x As Double, y As Double, z As Double) As Int
	Verts.Add(Math3D.V3(x,y,z))
	Return Verts.Size - 1
End Sub

Private Sub AddTriIdx(a As Int, b As Int, c As Int, matIdx As Int)
	Faces.Add(Math3D.F3(a,b,c))
	FaceMat.Add(matIdx)
End Sub

' Plane in XZ at y = const, centered, normal = +Y
Public Sub BuildPlaneXZ(width As Double, depth As Double, y As Double, segX As Int, segZ As Int, matIdx As Int)
	ClearAll
	If segX < 1 Then segX = 1
	If segZ < 1 Then segZ = 1

	Dim x0 As Double = -width/2, z0 As Double = -depth/2
	Dim dx As Double = width / segX, dz As Double = depth / segZ

	' verts
	For zi = 0 To segZ
		For xi = 0 To segX
			Dim x As Double = x0 + xi*dx, z As Double = z0 + zi*dz
			AddVRet(x, y, z)
		Next
	Next

	' faces (CCW for +Y)
	Dim cols As Int = segX + 1
	For zi = 0 To segZ - 1
		For xi = 0 To segX - 1
			Dim v00 As Int = zi*cols + xi
			Dim v10 As Int = v00 + 1
			Dim v01 As Int = v00 + cols
			Dim v11 As Int = v01 + 1
			AddTriIdx(v00, v10, v11, matIdx)
			AddTriIdx(v00, v11, v01, matIdx)
		Next
	Next

	RecalcFaceNormals
	RecalcVertexNormals
	ComputeCornerNormalsSeamAware(60, 1e-6)
	UpdateYBounds
End Sub

' Plane in XY at z = const, centered, normal = +Z
Public Sub BuildPlaneXY(width As Double, height As Double, z As Double, segX As Int, segY As Int, matIdx As Int)
	ClearAll
	If segX < 1 Then segX = 1
	If segY < 1 Then segY = 1

	Dim x0 As Double = -width/2, y0 As Double = -height/2
	Dim dx As Double = width / segX, dy As Double = height / segY

	For yi = 0 To segY
		For xi = 0 To segX
			Dim x As Double = x0 + xi*dx, yy As Double = y0 + yi*dy
			AddVRet(x, yy, z)
		Next
	Next

	Dim cols As Int = segX + 1
	For yi = 0 To segY - 1
		For xi = 0 To segX - 1
			Dim v00 As Int = yi*cols + xi
			Dim v10 As Int = v00 + 1
			Dim v01 As Int = v00 + cols
			Dim v11 As Int = v01 + 1
			AddTriIdx(v00, v10, v11, matIdx) ' CCW seen from +Z
			AddTriIdx(v00, v11, v01, matIdx)
		Next
	Next

	RecalcFaceNormals
	RecalcVertexNormals
	ComputeCornerNormalsSeamAware(60, 1e-6)
	UpdateYBounds
End Sub

' Plane in YZ at x = const, centered, normal = +X
Public Sub BuildPlaneYZ(height As Double, depth As Double, x As Double, segY As Int, segZ As Int, matIdx As Int)
	ClearAll
	If segY < 1 Then segY = 1
	If segZ < 1 Then segZ = 1

	Dim y0 As Double = -height/2, z0 As Double = -depth/2
	Dim dy As Double = height / segY, dz As Double = depth / segZ

	For zi = 0 To segZ
		For yi = 0 To segY
			Dim yy As Double = y0 + yi*dy, zz As Double = z0 + zi*dz
			AddVRet(x, yy, zz)
		Next
	Next

	Dim cols As Int = segY + 1
	For zi = 0 To segZ - 1
		For yi = 0 To segY - 1
			Dim v00 As Int = zi*cols + yi
			Dim v10 As Int = v00 + 1
			Dim v01 As Int = v00 + cols
			Dim v11 As Int = v01 + 1
			AddTriIdx(v00, v10, v11, matIdx) ' CCW seen from +X
			AddTriIdx(v00, v11, v01, matIdx)
		Next
	Next

	RecalcFaceNormals
	RecalcVertexNormals
	ComputeCornerNormalsSeamAware(60, 1e-6)
	UpdateYBounds
End Sub

Public Sub BuildCube(size As Double, matIdx As Int)
	ClearAll
	Dim s As Double = size/2

	' 8 verts
	Dim v0 As Int = AddVRet(-s,-s,-s)
	Dim v1 As Int = AddVRet( s,-s,-s)
	Dim v2 As Int = AddVRet( s, s,-s)
	Dim v3 As Int = AddVRet(-s, s,-s)
	Dim v4 As Int = AddVRet(-s,-s, s)
	Dim v5 As Int = AddVRet( s,-s, s)
	Dim v6 As Int = AddVRet( s, s, s)
	Dim v7 As Int = AddVRet(-s, s, s)

	' 12 tris (CCW outward)
	' -Z
	AddTriIdx(v0,v1,v2, matIdx) : AddTriIdx(v0,v2,v3, matIdx)
	' +Z
	AddTriIdx(v4,v6,v5, matIdx) : AddTriIdx(v4,v7,v6, matIdx)
	' -Y
	AddTriIdx(v0,v4,v5, matIdx) : AddTriIdx(v0,v5,v1, matIdx)
	' +Y
	AddTriIdx(v3,v2,v6, matIdx) : AddTriIdx(v3,v6,v7, matIdx)
	' +X
	AddTriIdx(v1,v5,v6, matIdx) : AddTriIdx(v1,v6,v2, matIdx)
	' -X
	AddTriIdx(v0,v3,v7, matIdx) : AddTriIdx(v0,v7,v4, matIdx)
	
	RecalcFaceNormals
	RecalcVertexNormals
	ComputeCornerNormalsSeamAware(60, 1e-6)
	UpdateYBounds
End Sub

Public Sub BuildUVSphere(radius As Double, seg As Int, rings As Int, matIdx As Int)
	ClearAll
	Log("adding sphere with index ->  " & matIdx)
	If seg < 3 Then seg = 3
	If rings < 2 Then rings = 2

	' verts (rings+1) * (seg+1) (duplicate seam)
	For r = 0 To rings
		Dim v As Double = r / rings     ' 0..1
		Dim phi As Double = v * cPI     ' 0..pi
		Dim sy As Double = Cos(phi)
		Dim sr As Double = Sin(phi)
		For s = 0 To seg
			Dim u As Double = s / seg       ' 0..1
			Dim theta As Double = u * 2*cPI
			Dim sx As Double = Cos(theta) * sr
			Dim sz As Double = Sin(theta) * sr
			AddVRet(radius*sx, radius*sy, radius*sz)
		Next
	Next

	Dim cols As Int = seg + 1
	For r = 0 To rings - 1
		For s = 0 To seg - 1
			Dim v00 As Int = r*cols + s
			Dim v10 As Int = v00 + 1
			Dim v01 As Int = v00 + cols
			Dim v11 As Int = v01 + 1
			' CCW outward
			AddTriIdx(v00, v10, v11, matIdx)
			AddTriIdx(v00, v11, v01, matIdx)
		Next
	Next

	RecalcFaceNormals
	RecalcVertexNormals
	ComputeCornerNormalsSeamAware(60, 1e-6)
	UpdateYBounds
End Sub

' Cylinder along Y, centered at origin, height h
Public Sub BuildCylinder(radius As Double, height As Double, seg As Int, capTop As Boolean, capBottom As Boolean, matIdx As Int)
	ClearAll
	If seg < 3 Then seg = 3
	Dim hy As Double = height/2

	' rings
	Dim baseStart As Int = Verts.Size
	For i = 0 To seg
		Dim t As Double = i / seg * 2*cPI
		Dim x As Double = Cos(t) * radius
		Dim z As Double = Sin(t) * radius
		AddVRet(x, -hy, z)  ' bottom ring
	Next
	Dim topStart As Int = Verts.Size
	For i = 0 To seg
		Dim t As Double = i / seg * 2*cPI
		Dim x As Double = Cos(t) * radius
		Dim z As Double = Sin(t) * radius
		AddVRet(x, hy, z)  ' top ring
	Next

	' side quads -> 2 triangles, CCW outward
	For i = 0 To seg - 1
		Dim b0 As Int = baseStart + i
		Dim b1 As Int = baseStart + i + 1
		Dim t0 As Int = topStart + i
		Dim t1 As Int = topStart + i + 1
		AddTriIdx(b0, b1, t1, matIdx)
		AddTriIdx(b0, t1, t0, matIdx)
	Next

	' caps
	If capTop Then
		Dim c As Int = AddVRet(0, hy, 0)
		For i = 0 To seg - 1
			Dim a As Int = topStart + i
			Dim b As Int = topStart + i + 1
			' CCW seen from +Y (outward)
			AddTriIdx(a, b, c, matIdx)
		Next
	End If
	If capBottom Then
		Dim c2 As Int = AddVRet(0, -hy, 0)
		For i = 0 To seg - 1
			Dim a As Int = baseStart + i
			Dim b As Int = baseStart + i + 1
			' CCW seen from -Y (outward) => reverse order
			AddTriIdx(b, a, c2, matIdx)
		Next
	End If

	RecalcFaceNormals
	RecalcVertexNormals
	ComputeCornerNormalsSeamAware(60, 1e-6)
	UpdateYBounds
End Sub

' Cone along Y, apex at +hy, base at -hy
Public Sub BuildCone(radius As Double, height As Double, seg As Int, capBase As Boolean, matIdx As Int)
	ClearAll
	If seg < 3 Then seg = 3
	Dim hy As Double = height/2

	' base ring
	Dim baseStart As Int = Verts.Size
	For i = 0 To seg
		Dim t As Double = i / seg * 2*cPI
		Dim x As Double = Cos(t) * radius
		Dim z As Double = Sin(t) * radius
		AddVRet(x, -hy, z)
	Next
	' apex
	Dim apex As Int = AddVRet(0, hy, 0)

	' sides (triangles), CCW outward
	For i = 0 To seg - 1
		Dim a As Int = baseStart + i
		Dim b As Int = baseStart + i + 1
		AddTriIdx(a, b, apex, matIdx)
	Next

	' base cap (outward is -Y)
	If capBase Then
		Dim c As Int = AddVRet(0, -hy, 0)
		For i = 0 To seg - 1
			Dim a As Int = baseStart + i
			Dim b As Int = baseStart + i + 1
			' CCW seen from -Y => reverse order
			AddTriIdx(b, a, c, matIdx)
		Next
	End If

	RecalcFaceNormals
	RecalcVertexNormals
	ComputeCornerNormalsSeamAware(60, 1e-6)
	UpdateYBounds
End Sub

' Build per-corner normals using a crease angle (degrees).
' Faces meeting at a vertex are averaged only if angle(face_i, face_j) <= creaseDeg.
Public Sub ComputeCornerNormalsSeamAware(creaseDeg As Double, weldEps As Double)
	If FaceN.Size <> Faces.Size Then RecalcFaceNormals

	CornerN.Clear
	Dim V As Int = Verts.Size, Ff As Int = Faces.Size
	If V = 0 Or Ff = 0 Then Return

	Dim cosT As Double = Cos(creaseDeg * cPI / 180)

	' 1) For each vertex index, collect incident faces
	Dim facesAtVert As List : facesAtVert.Initialize
	For vi = 0 To V - 1
		Dim lst As List : lst.Initialize
		facesAtVert.Add(lst)
	Next
	For fi = 0 To Ff - 1
		Dim f As Face = Faces.Get(fi)
		Dim la As List = facesAtVert.Get(f.A) : la.Add(fi) : facesAtVert.Set(f.A, la)
		Dim lb As List = facesAtVert.Get(f.B) : lb.Add(fi) : facesAtVert.Set(f.B, lb)
		Dim lc As List = facesAtVert.Get(f.C) : lc.Add(fi) : facesAtVert.Set(f.C, lc)
	Next
	
	' 2) Area weights (optional but improves quality)
	Dim faceW As List : faceW.Initialize
	For fi = 0 To Ff - 1
		Dim f As Face = Faces.Get(fi)
		Dim a As Vec3 = Verts.Get(f.A)
		Dim b As Vec3 = Verts.Get(f.B)
		Dim c As Vec3 = Verts.Get(f.C)
		Dim w As Double = Math3D.Len(Math3D.Cross(Math3D.SubV(b,a), Math3D.SubV(c,a)))
		faceW.Add(w)
	Next
	
	' 3) Group vertex indices by 3D position (quantized by weldEps)
	Dim groups As Map : groups.Initialize    ' key -> List(of Int vertex indices)
	For vi = 0 To V - 1
		Dim p As Vec3 = Verts.Get(vi)
		Dim key As String = PosKey(p, weldEps)
		If groups.ContainsKey(key) = False Then
			Dim nl As List : nl.Initialize
			groups.Put(key, nl)
		End If
		Dim gl As List = groups.Get(key)
		gl.Add(vi)
		groups.Put(key, gl)
	Next
	
	' 4) For each face corner, average only faces at the *same position group*
	For fi = 0 To Ff - 1
		Dim f As Face = Faces.Get(fi)
		Dim nfi As Vec3 = FaceN.Get(fi)
		
		' A corner
		CornerN.Add( CornerNormalAtCorner(f.A, fi, nfi, facesAtVert, faceW, groups, weldEps, cosT) )
		' B corner
		CornerN.Add( CornerNormalAtCorner(f.B, fi, nfi, facesAtVert, faceW, groups, weldEps, cosT) )
		' C corner
		CornerN.Add( CornerNormalAtCorner(f.C, fi, nfi, facesAtVert, faceW, groups, weldEps, cosT) )
	Next
End Sub

Private Sub CornerNormalAtCorner(vi As Int, fi As Int, nfi As Vec3, _
                                 facesAtVert As List, faceW As List, groups As Map, weldEps As Double, cosT As Double) As Vec3
	Dim sum As Vec3 = Math3D.V3(0,0,0)

	' find the group (all vertex indices at the same 3D position)
	Dim p As Vec3 = Verts.Get(vi)
	Dim key As String = PosKey(p, weldEps)
	Dim samePos As List = groups.Get(key)

	' collect faces touching any vertex in the same-position group
	For Each vj As Int In samePos
		Dim lst As List = facesAtVert.Get(vj)
		For Each fj As Int In lst
			Dim nfj As Vec3 = FaceN.Get(fj)
			If Math3D.Dot(nfi, nfj) >= cosT Then
				sum = Math3D.AddV(sum, Math3D.Mul(nfj, faceW.Get(fj)))
			End If
		Next
	Next

	If Math3D.Len(sum) < 1e-9 Then Return nfi
	Return Math3D.Normalize(sum)
End Sub

' Quantize position to a grid cell (epsilon) to build stable map keys
Private Sub PosKey(p As Vec3, eps As Double) As String
	If eps <= 0 Then eps = 1e-6
	Dim qx As Long = Floor(p.X/eps + 0.5)
	Dim qy As Long = Floor(p.Y/eps + 0.5)
	Dim qz As Long = Floor(p.Z/eps + 0.5)
	Return qx & "|" & qy & "|" & qz
End Sub