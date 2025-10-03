B4A=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=13.4
@EndOfDesignText@
Sub Class_Globals
	Public panelmain As Panel
	
	Public buttonColor As Int = 0x55008EFF
	
	Public BigSpaceing As Int = 6dip
	Public SmallSpaceing As Int = 3dip
	Public ButtonSize As Int
	Public rounding As Float = 0.2
	
	'Global joystick state (updated on event, read each tick)
	Public gJoyXMove As Float ' -1..1 (left..right)
	Public gJoyYMove As Float ' -1..1 (up..down, screen coords)
	
	Public gJoyXLook As Float ' -1..1 (left..right)
	Public gJoyYLook As Float ' -1..1 (up..down, screen coords)
	
	Public gJoyXScale As Float ' -1..1 (left..right)
	Public gJoyYScale As Float ' -1..1 (up..down, screen coords)
	
	Dim popoverCamSettings As PopoverPanelView
	Dim popoverRenderSettings As PopoverPanelView
	Dim popoverObjectsList As PopoverPanelView
	Dim popoverObjectSettings As PopoverPanelView
	
	'model data
	Dim edtPosition As EditVec3Field
	Dim edtRotation As EditVec3Field
	Dim edtScale As EditVec3Field
	Dim edtAlbedo As EditVec3Field
	Dim sldReflect As SliderView
	Dim btnVisible As ToggleButton
	
	'camera data
	Dim sldCameraTurnSpeed As SliderView
	Dim sldCameraMoveSpeed As SliderView
	Dim sldCameraFOV As SliderView
End Sub

'Initializes the object. You can add parameters to this method if needed.
Public Sub Initialize
	panelmain.Initialize("")
End Sub

Public Sub build
	
	Dim joystickMove As JoyStickView
	joystickMove.Initialize(Me, "JSMove")
	joystickMove.AddToParent(panelmain, BigSpaceing, panelmain.Height - 166dip - BigSpaceing, 166dip, 166dip)
	
	Dim joystickLook As JoyStickView
	joystickLook.Initialize(Me, "JSLook")
	joystickLook.AddToParent(panelmain, panelmain.Width - 166dip - BigSpaceing, panelmain.Height - 166dip - BigSpaceing, 166dip, 166dip)

	popoverCamSettings = CreatePopover("asd")
	popoverCamSettings.Title = "Camera Settings"

	sldCameraTurnSpeed = AddSliderToPopover(popoverCamSettings, "sldCamMoveSpeed")
	sldCameraMoveSpeed = AddSliderToPopover(popoverCamSettings, "sldCamMoveSpeed")
	sldCameraFOV = AddSliderToPopover(popoverCamSettings, "sldCamFov")

	popoverObjectsList = CreatePopover("objectsList")
	popoverObjectSettings = CreatePopover("ObjectSettings")
	build_PopoverObjectSettings
	
'	render settings
	popoverRenderSettings = CreatePopover("asd")
	popoverCamSettings.panelmain.BringToFront 'for now popover is separate, should become a layout in objSettings maybe
	
	Dim btnRenderWire As Button
	btnRenderWire.Initialize("RenderWire")
	panelmain.AddView(btnRenderWire, 4dip, 4dip, 10%x, 10%x)
	btnRenderWire.Background = UI.GetDrawable(Colors.White, btnRenderWire.Height)
	btnRenderWire.Text = "W" ' todo make panel with button and label and camera icon
	btnRenderWire.Padding = Array As Int(0, 0, 0, 0)
	btnRenderWire.TextSize = 30
	btnRenderWire.Typeface = Typeface.DEFAULT_BOLD
	
	Dim btnRenderSolid As Button
	btnRenderSolid.Initialize("RenderSolid")
	panelmain.AddView(btnRenderSolid, UI.Right(btnRenderWire) + 4dip, 4dip, 10%x, 10%x)
	btnRenderSolid.Background = UI.GetDrawable(Colors.White, btnRenderSolid.Height)
	btnRenderSolid.Text = "S" ' todo make panel with button and label and camera icon
	btnRenderSolid.Padding = Array As Int(0, 0, 0, 0)
	btnRenderSolid.TextSize = 30
	btnRenderSolid.Typeface = Typeface.DEFAULT_BOLD
	
	
	
	Dim btnRenderShaded As Button
	btnRenderShaded.Initialize("RenderShaded")
	panelmain.AddView(btnRenderShaded, UI.Right(btnRenderSolid) + 4dip, 4dip, 10%x, 10%x)
	btnRenderShaded.Background = UI.GetDrawable(Colors.White, btnRenderShaded.Height)
	btnRenderShaded.Text = "R" ' todo make panel with button and label and camera icon
	btnRenderShaded.Padding = Array As Int(0, 0, 0, 0)
	btnRenderShaded.TextSize = 30
	btnRenderShaded.Typeface = Typeface.DEFAULT_BOLD
	

	Dim btnEnableSmoothShade As Button
	btnEnableSmoothShade.Initialize("enableSmoothShade")
	panelmain.AddView(btnEnableSmoothShade, UI.Right(btnRenderShaded) + 4dip, 4dip, 10%x, 10%x)
	btnEnableSmoothShade.Background = UI.GetDrawable(Colors.White, btnEnableSmoothShade.Height)
	btnEnableSmoothShade.Text = "M" ' todo make panel with button and label and camera icon
	btnEnableSmoothShade.Padding = Array As Int(0, 0, 0, 0)
	btnEnableSmoothShade.TextSize = 30
	btnEnableSmoothShade.Typeface = Typeface.DEFAULT_BOLD
	
	Dim btnenableBVH As Button
	btnenableBVH.Initialize("enableBVH")
	panelmain.AddView(btnenableBVH, UI.Right(btnEnableSmoothShade) + 4dip, 4dip, 10%x, 10%x)
	btnenableBVH.Background = UI.GetDrawable(Colors.green, btnenableBVH.Height)
	btnenableBVH.Text = "B" ' todo make panel with button and label and camera icon
	btnenableBVH.TextColor = Colors.White
	btnenableBVH.Padding = Array As Int(0, 0, 0, 0)
	btnenableBVH.TextSize = 30
	btnenableBVH.Typeface = Typeface.DEFAULT_BOLD
	

	Dim btnpathTrace As Button
	btnpathTrace.Initialize("renderPathTrace")
	panelmain.AddView(btnpathTrace, UI.Right(btnenableBVH) + 4dip, 4dip, 10%x, 10%x)
	btnpathTrace.Background = UI.GetDrawable(Colors.green, btnpathTrace.Height)
	btnpathTrace.Text = "P" ' todo make panel with button and label and camera icon
	btnpathTrace.TextColor = Colors.White
	btnpathTrace.Padding = Array As Int(0, 0, 0, 0)
	btnpathTrace.TextSize = 30
	btnpathTrace.Typeface = Typeface.DEFAULT_BOLD
	


	
'	dim focusCameraAtSomething ??
'	dim cameraRenderMode - ??? ?? ?? ?? 
	
'	object editiing -> ?
'   move, rotate, scale object
'	edit materials and colors
'	
	
'	Render Options
'   threads used?
'	light bounces
'	show hide object

End Sub

Sub JSMove_ValueChanged(Data As Map)
	gJoyXMove = Data.Get("X")     ' -1..1 (left..right)
	gJoyYMove = Data.Get("Y")     ' -1..1 (up..down)
	CallSub(Main, "resetTimer")
End Sub

Sub JSLook_ValueChanged(Data As Map)
	gJoyXLook = Data.Get("X")     ' -1..1 (left..right)
	gJoyYLook = Data.Get("Y")     ' -1..1 (up..down)
	CallSub(Main, "resetTimer")
End Sub

Sub sldCamTurnSpeed_ValueChanged(m As Map)
	Main.Scene.Camera.TurnSpeed = m.Get("Norm")/10
End Sub

Sub sldCamMoveSpeed_ValueChanged(m As Map)
	Main.Scene.Camera.MoveSpeed = m.Get("Norm")
End Sub

Sub sldCamFov_ValueChanged(m As Map)
	Main.Scene.Camera.FOV_Deg = m.Get("Value")
	CallSub(Main, "resetTimer")
End Sub

Sub RenderWire_Click
	If Not(popoverObjectsList.panelmain.Visible) Then
		popoverObjectsList.ShowPanel
	End If
End Sub

Sub RenderSolid_Click
	Main.Renderer.setRenderMode(0)
	CallSub(Main, "resetTimer")
End Sub

Sub RenderShaded_Click
	Main.Renderer.setRenderMode(1)
	CallSub(Main, "resetTimer")
End Sub


Sub enableSmoothShade_Click
	Main.Opt.SmoothShading = Not(Main.Opt.SmoothShading)
	CallSub(Main, "resetTimer")
End Sub

Sub enableBVH_Click
	Main.Renderer.UseBVH = Not(Main.Renderer.UseBVH)
	If Main.Renderer.UseBVH Then
		Sender.As(Button).Color = Colors.Green
	Else
		Sender.As(Button).Color = Colors.Red
	End If
	CallSub(Main, "resetTimer")
End Sub

Sub renderPathTrace_Click
	CallSub(Main, "pathtrace")
End Sub


public Sub CreatePopover(event As String) As PopoverPanelView
	Dim newPopover As PopoverPanelView
	newPopover.Initialize
	newPopover.addToParent(panelmain)
	
	Return newPopover
End Sub

public Sub AddSliderToPopover(popover As PopoverPanelView, event As String) As SliderView
	
	Dim newSlider As SliderView
	newSlider.Initialize(Me, event)
	
	newSlider.AddToParent(popover.containerPanel.Panel, 0, popover.containerPanel.Panel.Height, 100%x, 10%y)
	popover.containerPanel.Panel.Height = UI.Bottom(newSlider.panelmain)
	
	
	Return newSlider
End Sub

public Sub AddModelBarToPopover(popover As PopoverPanelView, event As String) As ModelBar
	Dim newModelbar As ModelBar
	newModelbar.Initialize(Me, event)
	newModelbar.AddToParent(popover.containerPanel.Panel, 0, popover.containerPanel.Panel.Height, 100%x)
	popover.containerPanel.Panel.Height = UI.Bottom(newModelbar.panelmain)
	
	Return newModelbar
End Sub

public Sub refreshObjectPopover
	Dim container As Panel = popoverObjectsList.containerPanel.Panel
	container.RemoveAllViews
	container.Height = 0

	Dim cameraBar As ModelBar = AddModelBarToPopover(popoverObjectsList, "objectsList")
	cameraBar.Title = "Camera"
	cameraBar.TypeIcon = "📷"
	cameraBar.Tag = CreateMap("type": "camera", "ref": Main.Scene.Camera)
	cameraBar.SetToggleEnabled(False)

	Dim lightIndex As Int
	For lightIndex = 0 To Main.Scene.Lights.Size - 1
		Dim light As cLight = Main.Scene.Lights.Get(lightIndex)
		Dim lightBar As ModelBar = AddModelBarToPopover(popoverObjectsList, "objectsList")
		Dim lightName As String = light.Name
		If lightName.Length = 0 Then lightName = $"Light ${lightIndex + 1}"$
		lightBar.Title = lightName
		lightBar.TypeIcon = "💡"
		lightBar.Tag = CreateMap("type": "light", "ref": light)
		lightBar.SetShownWithoutEvent(light.Enabled)
	Next

	For Each obj As cModel In Main.Scene.Models
		Dim model As ModelBar = AddModelBarToPopover(popoverObjectsList, "objectsList")
		model.Title = obj.mesh.Name
		model.TypeIcon = "🧊"
		model.Tag = CreateMap("type": "model", "ref": obj)
		model.SetShownWithoutEvent(obj.Visible)
	Next
End Sub

public Sub objectsList_VisibilityChanged(visible As Boolean)
	Dim modelB As ModelBar = Sender
	Dim tagData As Object = modelB.Tag

	If tagData Is Map Then
		Dim data As Map = tagData
		Dim entryType As String = data.Get("type")
		Select entryType
			Case "model"
				Dim mdl As cModel = data.Get("ref")
				mdl.Visible = visible
			Case "light"
				Dim light As cLight = data.Get("ref")
				light.Enabled = visible
			Case "camera"
				Return
		End Select
	Else If tagData Is cModel Then
		tagData.As(cModel).Visible = visible
	End If

	CallSub(Main, "resetTimer")
End Sub

public Sub objectsList_SettingsClick
	Dim modelB As ModelBar = Sender
	Dim tagData As Object = modelB.Tag

	If tagData Is Map Then
		Dim data As Map = tagData
		Dim entryType As String = data.Get("type")
		Select entryType
			Case "model"
				Dim mdl As cModel = data.Get("ref")
				ApplyObjectDataToPopover(mdl)
				popoverObjectSettings.ShowPanel
			Case "camera"
				
				sldCameraTurnSpeed.SetValue(Main.Scene.Camera.TurnSpeed, False)
				sldCameraMoveSpeed.SetValue(Main.Scene.Camera.MoveSpeed, False)
				sldCameraFOV.SetValue(Main.Scene.Camera.FOV_Deg.As(Float), False)
				popoverCamSettings.ShowPanel
		End Select
		Return
	Else If tagData Is cModel Then
		ApplyObjectDataToPopover(tagData)
		popoverObjectSettings.ShowPanel
	End If
End Sub

public Sub build_PopoverRenderSettings
	popoverRenderSettings.Title = "Viewport Settings"
End Sub

public Sub build_PopoverObjectSettings
	popoverObjectSettings.Title = "Object Data"
	
	edtPosition.Initialize(Me, "edtPos")
	edtPosition.AddToParent(popoverObjectSettings.containerPanel.Panel, 0, 0, popoverObjectSettings.containerPanel.Width)
	edtPosition.Title = "Position"
	
	edtRotation.Initialize(Me, "edtRot")
	edtRotation.AddToParent(popoverObjectSettings.containerPanel.Panel, 0, UI.Bottom(edtPosition.panelmain), popoverObjectSettings.containerPanel.Width)
	edtRotation.Title = "Rotation"
	
	edtScale.Initialize(Me, "edtScl")
	edtScale.AddToParent(popoverObjectSettings.containerPanel.Panel, 0, UI.Bottom(edtRotation.panelmain), popoverObjectSettings.containerPanel.Width)
	edtScale.Title = "Scale"
	
	edtAlbedo.Initialize(Me, "edtAlbd")
	edtAlbedo.AddToParent(popoverObjectSettings.containerPanel.Panel, 0, UI.Bottom(edtScale.panelmain), popoverObjectSettings.containerPanel.Width)
	edtAlbedo.Title = "Albedo"
	
	sldReflect.Initialize(Me, "sldRefl")
	sldReflect.AddToParent(popoverObjectSettings.containerPanel.Panel, 0, UI.Bottom(edtAlbedo.panelmain), popoverObjectSettings.containerPanel.Width, 80dip)
	sldReflect.Title = "Reflectiveness"
	
	btnVisible.Initialize("btnVis")
	popoverObjectSettings.containerPanel.Panel.AddView(btnVisible, 0, UI.Bottom(sldReflect.panelmain), popoverObjectSettings.containerPanel.Width, 40dip)
	
	popoverObjectSettings.containerPanel.Panel.Height = UI.Bottom(btnVisible)
End Sub

Public Sub ApplyObjectDataToPopover(model As cModel)
	edtPosition.SetVectorValues(model.Position)
	edtRotation.SetVectorValues(model.Rotation)
	Dim scale As Vec3 = Math3D.V3(model.Scale, model.Scale, model.Scale) : edtRotation.SetVectorValues(scale) ' temp for now while scale is a bool
	edtAlbedo.SetVectorValues(Math3D.IntToRGB(model.Material.Albedo))
	sldReflect.SetRange(0, 1) : sldReflect.SetValue(model.Material.Reflectivity, False)
	btnVisible.Enabled = False ' prevent the event triggering here
	btnVisible.Checked = model.Visible
	btnVisible.Enabled = True
	
	edtPosition.Tag = model
	edtRotation.Tag = model
	edtScale.Tag = model
	edtAlbedo.Tag = model
	sldReflect.Tag = model
	btnVisible.Tag = model
End Sub

public Sub edtPos(value As Vec3)
	Sender.As(EditVec3Field).Tag.As(cModel).Position = value
	CallSub(Main, "resetTimer")
End Sub

public Sub edtRot(value As Vec3)
	Sender.As(EditVec3Field).Tag.As(cModel).Rotation = value
	CallSub(Main, "resetTimer")
End Sub

public Sub edtScl(value As Vec3)
	Sender.As(EditVec3Field).Tag.As(cModel).Scale = value.x
	CallSub(Main, "resetTimer")
End Sub

public Sub edtAlbd(value As Vec3)
	Sender.As(EditVec3Field).Tag.As(cModel).Material.Albedo = Math3D.ARGB255(255, value.X, value.Y, value.Z)
	CallSub(Main, "resetTimer")
End Sub

public Sub sldRefl_ValueChanged(m As Map)
	Dim value As Float = m.Get("Norm")
	Sender.As(SliderView).Tag.As(cModel).Material.Reflectivity = value
	CallSub(Main, "resetTimer")
End Sub

public Sub btnVis_CheckedChange(Checked As Boolean)
	If Not(Sender.As(ToggleButton).Enabled) Then Return
	Sender.As(ToggleButton).Tag.As(cModel).Visible = Checked
	CallSub(Main, "resetTimer")
End Sub