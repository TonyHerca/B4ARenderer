B4A=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=13.4
@EndOfDesignText@
' cScene.bas
Sub Class_Globals
	Type SceneFrame(Verts As List, Faces As List, FaceN As List, FaceMat As List, VertsN As List, CornerN As List)

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
	fr.Verts.Initialize : fr.Faces.Initialize : fr.FaceN.Initialize : fr.FaceMat.Initialize : fr.VertsN.Initialize : fr.CornerN.Initialize
	For Each m As cModel In Models
		If m.Visible = False Then Continue
		m.Mesh.ComputeCornerNormalsSeamAware(m.Mesh.creaseDegs, 1e-6)
		
		Dim base As Int = fr.Verts.Size
		Dim wv As List = m.WorldVerts
		Dim nrm As List = m.WorldFaceNormals
		Dim wn As List = m.WorldVertNormals
		Dim wcn As List = m.WorldCornerNormals
		' (optional) auto-lift above floor by mesh bounds if you want:
		' Dim liftY As Double = -m.Mesh.MinY + LiftAboveFloor
		' ... then add lift to each wv point ...
		For i = 0 To wv.Size - 1
			fr.Verts.Add(wv.Get(i))
			fr.VertsN.Add(wn.Get(i))
		Next
		For i = 0 To m.Mesh.Faces.Size - 1
			Dim f As Face = m.Mesh.Faces.Get(i)
			fr.Faces.Add(Math3D.F3(base+f.A, base+f.B, base+f.C))
			fr.FaceN.Add(nrm.Get(i))
			fr.FaceMat.Add(m.MatId)     ' single material per model (simple case)
		Next
		For i = 0 To wcn.Size - 1
			fr.CornerN.Add(wcn.Get(i))
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


Public Sub BuildPreset_CornellBox2
	Materials.Initialize
	Models.Initialize
	Lights.Initialize

	' Materials
	Dim mWhite As cMaterial
	mWhite.Initialize("White")
	mWhite.Albedo = Colors.RGB(200,200,200)
	mWhite.Reflectivity = 0
	mWhite.id = AddMaterial(mWhite)

	Dim mRed As cMaterial
	mRed.Initialize("Red")
	mRed.Albedo = Colors.RGB(200,40,40)
	mRed.Reflectivity = 0
	mRed.id = AddMaterial(mRed)

	Dim mGreen As cMaterial
	mGreen.Initialize("Green")
	mGreen.Albedo = Colors.RGB(40,180,40)
	mGreen.Reflectivity = 0
	mGreen.id = AddMaterial(mGreen)

	Dim mMirror As cMaterial
	mMirror.Initialize("Mirror")
	mMirror.Albedo = Colors.RGB(230,230,230)
	mMirror.Reflectivity = 0.6
	mMirror.id = AddMaterial(mMirror)

	' Room (no front wall), box from x∈[-1,1], y∈[0,2], z∈[-1,1]
	Dim meshFloor As cMesh
	meshFloor.Initialize("meshFloor")
	meshFloor.BuildPlaneXZ(2, 2, 0, 1, 1, 0)
	meshFloor.ReverseWindingAll
	meshFloor.RecalcFaceNormals
	meshFloor.RecalcVertexNormals
	meshFloor.ComputeCornerNormalsSeamAware(1, 0.000001)
	Dim mdlFloor As cModel = CreateModel("meshFloor", meshFloor, CopyMaterial(mWhite, mWhite.Name & "_Copy", True))
	mdlFloor.SetTRS(Math3D.V3(0,0,0), Math3D.V3(0,0,0), 1)
	AddModel(mdlFloor)
	
	Dim meshCeil As cMesh
	meshCeil.Initialize("meshCeiling")
	meshCeil.BuildPlaneXZ(2, 2, 2, 1, 1, 0)
	'    meshCeil.ReverseWindingAll
	meshCeil.RecalcFaceNormals
	meshCeil.RecalcVertexNormals
	meshCeil.ComputeCornerNormalsSeamAware(1, 0.000001)
	Dim mdlCeiling As cModel = CreateModel("meshCeiling", meshCeil, CopyMaterial(mWhite, mWhite.Name & "_Copy2", True))
	mdlCeiling.SetTRS(Math3D.V3(0,0,0), Math3D.V3(0,0,0), 1)
'	AddModel(mdlCeiling)

	Dim back As cMesh
	back.Initialize("Back")
	back.BuildPlaneXY(2, 2, -1, 1, 1, 0)
	back.ComputeCornerNormalsSeamAware(1, 0.000001)
	Dim mdlBack As cModel = CreateModel("Back", back, CopyMaterial(mWhite, mWhite.Name & "_Copy3", True))
	mdlBack.SetTRS(Math3D.V3(0,1,0), Math3D.V3(0,0,0), 1)
	AddModel(mdlBack)
	
	Dim leftw As cMesh
	leftw.Initialize("Left")
	leftw.BuildPlaneYZ(2, 2, -1, 1, 1, 0)
	leftw.ComputeCornerNormalsSeamAware(1, 0.000001)
	Dim mdlLeft As cModel = CreateModel("Left", leftw, mRed)
	mdlLeft.SetTRS(Math3D.V3(0,1,0), Math3D.V3(0,0,0), 1)
	AddModel(mdlLeft)
	
	Dim rightw As cMesh
	rightw.Initialize("Right")
	rightw.BuildPlaneYZ(2, 2, 1, 1, 1, 0)
	rightw.ReverseWindingAll
	rightw.RecalcFaceNormals
	rightw.RecalcVertexNormals
	rightw.ComputeCornerNormalsSeamAware(1, 0.000001)
	Dim mdlRight As cModel = CreateModel("Right", rightw, mGreen)
	mdlRight.SetTRS(Math3D.V3(0,1,0), Math3D.V3(0,0,0), 1)
	AddModel(mdlRight)
	' Objects
	Dim s1 As cMesh
	s1.Initialize("SphereWhite")
	s1.BuildUVSphere(0.35, 32, 16, mWhite.id)
	s1.ComputeCornerNormalsSeamAware(80, 0.000001)
	CreateModel("BallWhite", s1, mWhite)
	Dim mdlBallWhite As cModel = CreateModel("BallWhite", s1, mWhite)
	mdlBallWhite.SetTRS(Math3D.V3(-0.4, 0.35, -0.3), Math3D.V3(0,0,0), 1)
	AddModel(mdlBallWhite)

	Dim s2 As cMesh
	s2.Initialize("SphereMirror")
	s2.BuildUVSphere(0.35, 32, 16, mMirror.id)
	s2.ComputeCornerNormalsSeamAware(80, 0.000001)
	Dim mdlBallMirror As cModel = CreateModel("BallMirror", s2, mMirror)
	mdlBallMirror.SetTRS(Math3D.V3(0.45, 0.35, 0.2), Math3D.V3(0,0,0), 1)
	AddModel(mdlBallMirror)

	' Rectangular ceiling light (inside box, near y=1.95)
	Dim L As cLight
'	L.Initialize(Math3D.v3(-0.5, -1, 0))
'	L.Name = "CeilingRect"
'	L.Kind = L.KIND_RECT
'	L.Color = Colors.RGB(255, 250, 230)      ' warm-ish
'	L.Intensity = 40.0
'	L.Position = Math3D.V3(0, 1.95, 0)              ' center
'	L.U = Math3D.V3(0.25, 0, 0)                     ' half-width along +X/-X
'	L.V = Math3D.V3(0, 0, 0.18)                     ' half-height along +Z/-Z
	Lights.Add(L)


	' Camera
	Camera.Pos = Math3D.V3(0, 1.0, 2.8)
	Camera.Target = Math3D.V3(0, 1.0, 0)
	Camera.Up = Math3D.V3(0, 1, 0)
	Camera.FOV_Deg = 45
End Sub

public Sub CopyMaterial(material As cMaterial, newName As String, addToList As Boolean) As cMaterial
	Dim newMaterial As cMaterial
	newMaterial.Initialize(newName) 'Todo : AutoGenerate name like "_Copy", "_Copy(1)", "_Copy(2)" | Scan mats list and get names etc
'									 TOdo : maybe also track materials users like how many models use the same material / mesh also
	newMaterial.Albedo = material.Albedo
	newMaterial.Reflectivity = material.Reflectivity
	If addToList Then newMaterial.id = AddMaterial(newMaterial)
	Return newMaterial
End Sub

public Sub CopyMesh(mesh As cMesh, newName As String) As cMesh
	Dim newMesh As cMesh : newMesh.Initialize(newName)
	newMesh.creaseDegs = mesh.creaseDegs
	newMesh.CornerN = Math3D.CopyList(mesh.CornerN) : newMesh.VertN = Math3D.CopyList(mesh.VertN)
	newMesh.Verts = Math3D.CopyList(mesh.Verts) : newMesh.FaceMat = Math3D.CopyList(mesh.FaceMat)
	newMesh.FaceN = Math3D.CopyList(mesh.FaceN) : newMesh.Faces = Math3D.CopyList(mesh.Faces)
	newMesh.Position = Math3D.CopyVec3(mesh.Position) : newMesh.Rotation = Math3D.CopyVec3(mesh.Rotation)
	newMesh.Scale = mesh.Scale
	newMesh.MinY = mesh.MinY : newMesh.MaxY = mesh.MaxY
	Return newMesh
End Sub