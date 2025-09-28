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

	' Transform
	Public Position As Vec3
	Public Rotation As Vec3  ' yaw (Y), pitch (X), roll (Z) in radians
	Public Scale As Double

	' Bounds
	Public MinY As Double, MaxY As Double
End Sub

Public Sub Initialize(n As String)
	Name = n
	Verts.Initialize : Faces.Initialize : FaceN.Initialize : FaceMat.Initialize
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
