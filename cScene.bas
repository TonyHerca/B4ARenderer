B4A=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=13.4
@EndOfDesignText@
' cScene.bas
Sub Class_Globals
	Type SceneFrame(Verts As List, Faces As List, FaceN As List, FaceMat As List)
	
	Public Camera As cCamera
	Public Lights As List        ' List(cLight)
	Public Materials As List     ' List(cMaterial)
	Public Meshes As Map        ' List(cMesh)

	Public Models As List

	' convenience: a floor + back wall primitives as separate meshes
	Public FloorMesh As cMesh
	Public WallMesh As cMesh

	' lift meshes above floor slightly when aggregating
	Public LiftAboveFloor As Double = 0.02
End Sub

Public Sub Initialize
	Camera.Initialize
	Lights.Initialize : Materials.Initialize : Meshes.Initialize : Models.Initialize
	
	' default light
	Dim L As cLight
	L.Initialize(Math3D.V3(-1, -2, -1)) : Lights.Add(L)
	
	' default material 0
	Dim M0 As cMaterial : M0.Initialize("Default") : Materials.Add(M0)
	
'	' build floor + wall
'	FloorMesh.Initialize("Floor")
'	FloorMesh.AddCube(0, 0) ' just to init arrays; we'll override verts/faces next
'	FloorMesh.Verts.Clear : FloorMesh.Faces.Clear : FloorMesh.FaceN.Clear : FloorMesh.FaceMat.Clear
'	
'	' floor quad [-5..5]x[-5..3] at y=0
'	Dim x0=-5, x1=5, z0=-5, z1=3 As Double
'	FloorMesh.Verts.AddAll(Array As Object( _
'	Math3D.V3(x0,0,z0), Math3D.V3(x1,0,z0), Math3D.V3(x1,0,z1), Math3D.V3(x0,0,z1)))
'	FloorMesh.Faces.Add(Math3D.F3(0,1,2)) : FloorMesh.FaceMat.Add(0)
'	FloorMesh.Faces.Add(Math3D.F3(0,2,3)) : FloorMesh.FaceMat.Add(0)
'	FloorMesh.RecalcFaceNormals
'	Meshes.put(FloorMesh.Name, FloorMesh)
'	
'	' wall at z=-3, x in [-5..5], y in [0..5]
'	WallMesh.Initialize("BackWall")
'	WallMesh.Verts.AddAll(Array As Object( _
'        Math3D.V3(x0,0,-3), Math3D.V3(x1,0,-3), Math3D.V3(x1,5,-3), Math3D.V3(x0,5,-3)))
'	WallMesh.Faces.Add(Math3D.F3(0,2,1)) : WallMesh.FaceMat.Add(0)
'	WallMesh.Faces.Add(Math3D.F3(0,3,2)) : WallMesh.FaceMat.Add(0)
'	WallMesh.RecalcFaceNormals
'	Meshes.Put(WallMesh.Name, WallMesh)
'	
'	FloorMesh.EnsureFacing(Math3D.V3(0, 1, 0))
'	WallMesh.EnsureFacing(Math3D.V3(0, 0, 1))
End Sub

Public Sub AddMesh(m As cMesh)
	Meshes.Put(m.Name, m)
End Sub

Public Sub AddMaterial(mat As cMaterial) As Int
	Materials.Add(mat)
	Return Materials.Size - 1
End Sub

' Aggregate all meshes into a single frame (world transformed)
Public Sub BuildFrame As SceneFrame
	Dim fr As SceneFrame
	fr.Initialize
	fr.Verts.Initialize : fr.Faces.Initialize : fr.FaceN.Initialize : fr.FaceMat.Initialize
	
	For Each m As cModel In Models
		If m.Visible = False Then Continue
		
		Dim base As Int = fr.Verts.Size
		Dim wv As List = m.WorldVerts
		Dim nrm As List = m.WorldFaceNormals
		
		' (optional) auto-lift above floor by mesh bounds if you want:
		' Dim liftY As Double = -m.Mesh.MinY + LiftAboveFloor
		' ... then add lift to each wv point ...

		For i = 0 To wv.Size - 1
			fr.Verts.Add(wv.Get(i))
		Next
		For i = 0 To m.Mesh.Faces.Size - 1
			Dim f As Face = m.Mesh.Faces.Get(i)
			fr.Faces.Add(Math3D.F3(base+f.A, base+f.B, base+f.C))
			fr.FaceN.Add(nrm.Get(i))
			fr.FaceMat.Add(m.MatId)     ' single material per model (simple case)
		Next
	Next

	Return fr
End Sub

Public Sub addLight(dir As Vec3) As cLight 'TODO
	Dim newLight As cLight
	newLight.Initialize(dir)
	Lights.Add(newLight)
	Return newLight
End Sub

Public Sub AddModelCreate(name As String, mesh As cMesh, mat As cMaterial) As cModel
	Dim m As cModel
	m.Initialize(name, mesh, mat)
	m.MatId = mat.Id     ' renderer uses this to fetch albedo/reflectivity
	Models.Add(m)
	Return m
End Sub

Public Sub AddModel(m As cModel)
	Models.Add(m)
End Sub


Public Sub RemoveModel(m As cModel)
	Models.Removeat(Models.IndexOf(m))
End Sub

Public Sub FindModelByName(n As String) As cModel
	For Each m As cModel In Models
		If m.Name = n Then Return m
	Next
	Return Null
End Sub

public Sub CreateModel(name As String, mesh As cMesh, mat As cMaterial) As cModel
	Dim newModel As cModel
	newModel.Initialize(name, mesh, mat)
	Return newModel
End Sub

Public Sub CreateMesh(name As String) As cMesh
	Dim newMesh As cMesh
	newMesh.Initialize(name)
	Return newMesh
End Sub

Public Sub CreateMaterial(name As String, albedo As Int, reflectivity As Double) As cMaterial
	Dim newMaterial As cMaterial
	newMaterial.Initialize(name)
	newMaterial.Albedo = albedo
	newMaterial.Reflectivity = reflectivity
	newMaterial.id = AddMaterial(newMaterial)
	Return newMaterial
End Sub