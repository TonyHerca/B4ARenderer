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

Private Sub ResetCollectionsOnly
	Lights.Initialize
	Materials.Initialize
	Meshes.Initialize
	Models.Initialize
End Sub

Private Sub AddDefaultSceneElements
	Dim L As cLight
	L.Initialize(Math3D.V3(-1, -2, -1))
	Lights.Add(L)

	Dim M0 As cMaterial
	M0.Initialize("Default")
	M0.id = AddMaterial(M0)
End Sub

Public Sub Initialize
	Camera.Initialize
	Lights.Initialize : Materials.Initialize : Meshes.Initialize : Models.Initialize
	
	' default light
	Dim L As cLight
	L.Initialize(Math3D.V3(-1, -2, -1)) : Lights.Add(L)
	
	' default material 0
	Dim M0 As cMaterial : M0.Initialize("Default") : Materials.Add(M0)
	
End Sub

Public Sub CreateEmptyPreset
	Camera.Initialize
	ResetCollectionsOnly
	AddDefaultSceneElements
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

Public Sub BuildPreset_CowShowcase
	Camera.Initialize
	ResetCollectionsOnly

	' simple matte materials for the ground and imported mesh
	Dim groundMat As cMaterial = CreateMaterial("Ground", Colors.RGB(210, 205, 200), 0)
	Dim cowMat As cMaterial = CreateMaterial("Cow", Colors.RGB(235, 235, 235), 0)

	' gently lit floor
	Dim ground As cMesh
	ground.Initialize("Ground")
	ground.BuildPlaneXZ(8, 8, 0, 1, 1, groundMat.id)
	Dim groundModel As cModel = CreateModel("Ground", ground, groundMat)
	groundModel.SetTRS(Math3D.V3(0, 0, 0), Math3D.V3(0, 0, 0), 1)
	AddModel(groundModel)

	' import a sample OBJ from the assets folder
	Dim cowMesh As cMesh
	cowMesh.Initialize("CowMesh")
	cowMesh.LoadOBJFromAssets("cow.obj", cowMat.id)
	Dim cowModel As cModel = CreateModel("Cow", cowMesh, cowMat)
	cowModel.SetTRS(Math3D.V3(0, 1.2, 0), Math3D.V3(0, -cPI/2, 0), 0.12)
	AddModel(cowModel)

	' a warm key light to highlight the model
	Dim keyLight As cLight
	keyLight.Initialize(Math3D.V3(-0.35, -1, -0.35))
	keyLight.Name = "KeyLight"
	keyLight.Kind = keyLight.KIND_POINT
	keyLight.Position = Math3D.V3(2.5, 4, 3)
	keyLight.Intensity = 18
	keyLight.Color = Colors.RGB(255, 245, 230)
	Lights.Add(keyLight)

	' camera pulled back to frame the imported object
	Camera.Pos = Math3D.V3(0, 2.2, 6)
	Camera.Target = Math3D.V3(0, 1.2, 0)
	Camera.Up = Math3D.V3(0, 1, 0)
	Camera.FOV_Deg = 40
End Sub

Public Sub BuildPreset_CornellBox
	ResetCollectionsOnly

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
	L.Initialize(Math3D.v3(-0.5, -1, 0))
	L.Name = "CeilingRect"
	L.Kind = L.KIND_RECT
	L.Color = Colors.RGB(255, 250, 230)      ' warm-ish
	L.Intensity = 40.0
	L.Position = Math3D.V3(0, 1.95, 0)              ' center
	L.U = Math3D.V3(0.25, 0, 0)                     ' half-width along +X/-X
	L.V = Math3D.V3(0, 0, 0.18)                     ' half-height along +Z/-Z
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


Public Sub ToPresetMap As Map
	Dim preset As Map
	preset.Initialize
	preset.Put("version", 1)

	Dim cameraMap As Map
	cameraMap.Initialize
	cameraMap.Put("position", Math3D.Vec3ToMap(Camera.Pos))
	cameraMap.Put("target", Math3D.Vec3ToMap(Camera.Target))
	cameraMap.Put("up", Math3D.Vec3ToMap(Camera.Up))
	cameraMap.Put("fovDeg", Camera.FOV_Deg)
	cameraMap.Put("moveSpeed", Camera.MoveSpeed)
	cameraMap.Put("turnSpeed", Camera.TurnSpeed)
	preset.Put("camera", cameraMap)

	Dim mats As List
	mats.Initialize
	For Each mat As cMaterial In Materials
		Dim m As Map
		m.Initialize
		m.Put("name", mat.Name)
		m.Put("albedo", mat.Albedo)
		m.Put("reflectivity", mat.Reflectivity)
		m.Put("id", mat.id)
		mats.Add(m)
	Next
	preset.Put("materials", mats)

	Dim lightsList As List
	lightsList.Initialize
	For Each l As cLight In Lights
		Dim lm As Map
		lm.Initialize
		lm.Put("name", l.Name)
		lm.Put("kind", l.Kind)
		lm.Put("direction", Math3D.Vec3ToMap(l.Direction))
		lm.Put("color", l.Color)
		lm.Put("intensity", l.Intensity)
		lm.Put("position", Math3D.Vec3ToMap(l.Position))
		lm.Put("enabled", l.Enabled)
		lm.Put("cosInner", l.CosInner)
		lm.Put("cosOuter", l.CosOuter)
		lm.Put("u", Math3D.Vec3ToMap(l.U))
		lm.Put("v", Math3D.Vec3ToMap(l.V))
		lightsList.Add(lm)
	Next
	preset.Put("lights", lightsList)

	Dim meshData As Map
	meshData.Initialize
	For Each mdl As cModel In Models
		If mdl.Mesh <> Null Then
			Dim meshName As String = mdl.Mesh.Name
			If meshData.ContainsKey(meshName) = False Then
				meshData.Put(meshName, MeshToPresetMap(mdl.Mesh))
			End If
		End If
	Next
	If Meshes.IsInitialized Then
		For Each k As String In Meshes.Keys
			If meshData.ContainsKey(k) = False Then
				Dim storedMesh As cMesh = Meshes.Get(k)
				If storedMesh <> Null Then meshData.Put(k, MeshToPresetMap(storedMesh))
			End If
		Next
	End If
	Dim meshList As List
	meshList.Initialize
	For Each key As String In meshData.Keys
		meshList.Add(meshData.Get(key))
	Next
	preset.Put("meshes", meshList)

	Dim modelsList As List
	modelsList.Initialize
	For Each mdl As cModel In Models
		Dim modelMap As Map
		modelMap.Initialize
		modelMap.Put("name", mdl.Name)
		Dim mdlMeshName As String = ""
		If mdl.Mesh <> Null Then mdlMeshName = mdl.Mesh.Name
		modelMap.Put("mesh", mdlMeshName)
		Dim mdlMaterialName As String = ""
		If mdl.Material <> Null Then mdlMaterialName = mdl.Material.Name
		modelMap.Put("material", mdlMaterialName)
		modelMap.Put("matId", mdl.MatId)
		modelMap.Put("visible", mdl.Visible)
		modelMap.Put("castShadow", mdl.CastShadow)
		modelMap.Put("receiveShadow", mdl.ReceiveShadow)
		modelMap.Put("layer", mdl.Layer)
		modelMap.Put("tag", mdl.Tag)
		modelMap.Put("position", Math3D.Vec3ToMap(mdl.Position))
		modelMap.Put("rotation", Math3D.Vec3ToMap(mdl.Rotation))
		Dim scl As Vec3
		scl.Initialize
		scl.X = mdl.Scale : scl.Y = mdl.Scale : scl.Z = mdl.Scale
		modelMap.Put("scale", Math3D.Vec3ToMap(scl))
		modelsList.Add(modelMap)
	Next
	preset.Put("models", modelsList)
	
	Return preset
End Sub

Private Sub MeshToPresetMap(mesh As cMesh) As Map
	Dim meshMap As Map
	meshMap.Initialize
	meshMap.Put("name", mesh.Name)
	meshMap.Put("creaseDegs", mesh.creaseDegs)
	meshMap.Put("position", Math3D.Vec3ToMap(mesh.Position))
	meshMap.Put("rotation", Math3D.Vec3ToMap(mesh.Rotation))
	Dim scl As Vec3
	scl.Initialize
	scl.X = mesh.Scale : scl.Y = mesh.Scale : scl.Z = mesh.Scale
	meshMap.Put("scale", Math3D.Vec3ToMap(scl))
	
	Dim verts As List
	verts.Initialize
	For Each v As Vec3 In mesh.Verts
		verts.Add(Math3D.Vec3ToMap(v))
	Next
	meshMap.Put("verts", verts)
	
	Dim faces As List
	faces.Initialize
	For Each f As Face In mesh.Faces
		faces.Add(Math3D.FaceToMap(f))
	Next
	meshMap.Put("faces", faces)

	Dim faceMat As List
	faceMat.Initialize
	For Each idx As Int In mesh.FaceMat
		faceMat.Add(idx)
	Next
	meshMap.Put("faceMat", faceMat)

	Return meshMap
End Sub

Public Sub SavePresetToFile(Dir As String, FileName As String) As String
	Dim preset As Map = ToPresetMap
	Dim gen As JSONGenerator
	gen.Initialize(preset)
	Dim json As String = gen.ToPrettyString(2)
	File.WriteString(Dir, FileName, json)
	Return json
End Sub

Public Sub LoadPresetFromFile(Dir As String, FileName As String)
	Dim json As String = File.ReadString(Dir, FileName)
	Dim parser As JSONParser
	parser.Initialize(json)
	Dim data As Map = parser.NextObject
	LoadPresetFromMap(data)
End Sub

Public Sub LoadPresetFromMap(data As Map)
	Camera.Initialize
	ResetCollectionsOnly

	If data.ContainsKey("camera") Then
		Dim camMap As Map = data.Get("camera")
		If camMap <> Null And camMap.IsInitialized Then
			Camera.Pos = Math3D.MapToVec3(camMap.Get("position"))
			Camera.Target = Math3D.MapToVec3(camMap.Get("target"))
			Camera.Up = Math3D.MapToVec3(camMap.Get("up"))
			Camera.FOV_Deg = camMap.GetDefault("fovDeg", Camera.FOV_Deg)
			Camera.MoveSpeed = camMap.GetDefault("moveSpeed", Camera.MoveSpeed)
			Camera.TurnSpeed = camMap.GetDefault("turnSpeed", Camera.TurnSpeed)
		End If
	End If

	Dim materialByName As Map
	materialByName.Initialize
	If data.ContainsKey("materials") Then
		Dim mats As List = data.Get("materials")
		If mats <> Null And mats.IsInitialized Then
			For Each matMap As Map In mats
				If matMap.IsInitialized = False Then Continue
				Dim matName As String = matMap.GetDefault("name", "Material")
				Dim newMat As cMaterial
				newMat.Initialize(matName)
				newMat.Albedo = matMap.GetDefault("albedo", Colors.White)
				newMat.Reflectivity = matMap.GetDefault("reflectivity", 0)
				Materials.Add(newMat)
				newMat.id = Materials.Size - 1
				materialByName.Put(matName, newMat)
			Next
		End If
	End If

	If data.ContainsKey("lights") Then
		Dim lightsList As List = data.Get("lights")
		If lightsList <> Null And lightsList.IsInitialized Then
			For Each lm As Map In lightsList
				Dim l As cLight
				l.Initialize(Math3D.V3(0, -1, 0))
				If lm.IsInitialized Then
					l.Name = lm.GetDefault("name", l.Name)
					l.Kind = lm.GetDefault("kind", l.Kind)
					l.Direction = Math3D.MapToVec3(lm.Get("direction"))
					l.Color = lm.GetDefault("color", l.Color)
					l.Intensity = lm.GetDefault("intensity", l.Intensity)
					l.Position = Math3D.MapToVec3(lm.Get("position"))
					l.Enabled = lm.GetDefault("enabled", True)
					l.CosInner = lm.GetDefault("cosInner", l.CosInner)
					l.CosOuter = lm.GetDefault("cosOuter", l.CosOuter)
					l.U = Math3D.MapToVec3(lm.Get("u"))
					l.V = Math3D.MapToVec3(lm.Get("v"))
				End If
				Lights.Add(l)
			Next
		End If
	End If

	Dim meshByName As Map
	meshByName.Initialize
	If data.ContainsKey("meshes") Then
		Dim meshesList As List = data.Get("meshes")
		If meshesList <> Null And meshesList.IsInitialized Then
			For Each meshMap As Map In meshesList
				If meshMap.IsInitialized = False Then Continue
				Dim meshName As String = meshMap.GetDefault("name", "Mesh")
				Dim mesh As cMesh
				mesh.Initialize(meshName)
				mesh.creaseDegs = meshMap.GetDefault("creaseDegs", mesh.creaseDegs)
				mesh.Position = Math3D.MapToVec3(meshMap.Get("position"))
				mesh.Rotation = Math3D.MapToVec3(meshMap.Get("rotation"))
				If meshMap.ContainsKey("scale") Then
					Dim scaleVec As Vec3 = Math3D.MapToVec3(meshMap.Get("scale"))
					mesh.Scale = scaleVec.X
				End If

				Dim verts As List = meshMap.Get("verts")
				If verts <> Null And verts.IsInitialized Then
					For Each vMap As Map In verts
						mesh.Verts.Add(Math3D.MapToVec3(vMap))
					Next
				End If

				Dim faces As List = meshMap.Get("faces")
				If faces <> Null And faces.IsInitialized Then
					For Each fObj As Object In faces
						mesh.Faces.Add(Math3D.MapToFace(fObj))
					Next
				End If

				Dim fm As List = meshMap.Get("faceMat")
				If fm <> Null And fm.IsInitialized Then
					For Each idx As Object In fm
						Dim i As Int = idx
						mesh.FaceMat.Add(i)
					Next
				Else
					For i = 0 To mesh.Faces.Size - 1
						mesh.FaceMat.Add(0)
					Next
				End If

				mesh.RecalcFaceNormals
				mesh.RecalcVertexNormals
				mesh.ComputeCornerNormalsSeamAware(mesh.creaseDegs, 1e-6)
				UpdateMeshBounds(mesh)

				meshByName.Put(meshName, mesh)
				Meshes.Put(meshName, mesh)
			Next
		End If
	End If

	If data.ContainsKey("models") Then
		Dim modelsList As List = data.Get("models")
		If modelsList <> Null And modelsList.IsInitialized Then
			For Each mdlMap As Map In modelsList
				If mdlMap.IsInitialized = False Then Continue
				Dim meshName As String = mdlMap.GetDefault("mesh", "")
				Dim mesh As cMesh = Null
				If meshByName.ContainsKey(meshName) Then mesh = meshByName.Get(meshName)
				Dim matName As String = mdlMap.GetDefault("material", "")
				Dim mat As cMaterial = Null
				If materialByName.ContainsKey(matName) Then mat = materialByName.Get(matName)
				If mat = Null And Materials.Size > 0 Then mat = Materials.Get(0)
				If mat = Null Then
					Dim fallback As cMaterial
					fallback.Initialize("Default")
					Materials.Add(fallback)
					fallback.id = Materials.Size - 1
					mat = fallback
					materialByName.Put(fallback.Name, fallback)
				End If
				If mesh = Null Then Continue

				Dim mdl As cModel
				Dim mdlName As String = mdlMap.GetDefault("name", meshName)
				mdl.Initialize(mdlName, mesh, mat)
				mdl.MatId = Materials.IndexOf(mat)
				mdl.Visible = mdlMap.GetDefault("visible", True)
				mdl.CastShadow = mdlMap.GetDefault("castShadow", True)
				mdl.ReceiveShadow = mdlMap.GetDefault("receiveShadow", True)
				mdl.Layer = mdlMap.GetDefault("layer", 0)
				mdl.Tag = mdlMap.GetDefault("tag", "")
				mdl.Position = Math3D.MapToVec3(mdlMap.Get("position"))
				mdl.Rotation = Math3D.MapToVec3(mdlMap.Get("rotation"))
				If mdlMap.ContainsKey("scale") Then
					Dim scl As Vec3 = Math3D.MapToVec3(mdlMap.Get("scale"))
					mdl.Scale = scl.X
				End If
				Models.Add(mdl)
			Next
		End If
	End If

	' ensure material ids match list indices
	For i = 0 To Materials.Size - 1
		Dim mat As cMaterial = Materials.Get(i)
		mat.id = i
	Next

	If Materials.Size = 0 Then
		Dim defaultMat As cMaterial
		defaultMat.Initialize("Default")
		Materials.Add(defaultMat)
		defaultMat.id = 0
	End If

	If Lights.Size = 0 Then
		Dim defaultLight As cLight
		defaultLight.Initialize(Math3D.V3(-1, -2, -1))
		Lights.Add(defaultLight)
	End If
End Sub

Private Sub UpdateMeshBounds(mesh As cMesh)
	If mesh.Verts.Size = 0 Then
		mesh.MinY = 0
		mesh.MaxY = 0
		Return
	End If
	Dim minY As Double = 1e9
	Dim maxY As Double = -1e9
	For Each v As Vec3 In mesh.Verts
		If v.Y < minY Then minY = v.Y
		If v.Y > maxY Then maxY = v.Y
	Next
	mesh.MinY = minY
	mesh.MaxY = maxY
End Sub