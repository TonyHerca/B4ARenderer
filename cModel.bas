B4A=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=13.4
@EndOfDesignText@
' cModel.bas
Sub Class_Globals
	Public Name As String
	Public Mesh As cMesh            ' shared geometry
	Public Material As cMaterial    ' shared material
	Public MatId As Int = 1       ' index in scene.Materials (for renderer lookups)

	' per-instance controls
	Public Visible As Boolean = True
	Public Position As Vec3
	Public Rotation As Vec3  ' yaw(X), pitch(Y), roll(Z) or your convention
	Public Scale As Double = 1.0

	' flags
	Public CastShadow As Boolean = True
	Public ReceiveShadow As Boolean = True
	Public Layer As Int = 0
	Public Tag As String            ' freeform
End Sub

Public Sub Initialize(n As String, мMesh As cMesh, mat As cMaterial)
	Name = n : Mesh = мMesh : Material = mat : matid = mat.id
End Sub

Public Sub SetTRS(pos As Vec3, rot As Vec3, s As Double)
	Position = pos : Rotation = rot : Scale = s
End Sub

' World-space vertices from shared mesh + this instance’s TRS
Public Sub WorldVerts As List
	Dim out As List : out.Initialize
	For i = 0 To Mesh.Verts.Size - 1
		Dim p As Vec3 = Mesh.Verts.Get(i)
		Dim ps As Vec3 = Math3D.Mul(p, Scale)
		Dim pr As Vec3 = Math3D.ApplyYawPitchRoll(ps, Rotation.X, Rotation.Y, Rotation.Z)
		out.Add(Math3D.AddV(pr, Position))
	Next
	Return out
End Sub

' Face normals rotated by this instance’s rotation
Public Sub WorldFaceNormals As List
	Dim out As List : out.Initialize
	For i = 0 To Mesh.FaceN.Size - 1
		Dim n As Vec3 = Mesh.FaceN.Get(i)
		Dim nr As Vec3 = Math3D.ApplyYawPitchRoll(n, Rotation.X, Rotation.Y, Rotation.Z)
		out.Add(Math3D.Normalize(nr))
	Next
	Return out
End Sub

