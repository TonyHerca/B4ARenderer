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
	Dim popoverPresets As PopoverPanelView
	
	'model data
	Dim edtPosition As EditVec3Field
	Dim edtRotation As EditVec3Field
	Dim edtScale As EditVec3Field
	Dim edtAlbedo As EditVec3Field
	Dim sldReflect As SliderView
	Dim btnVisible As ToggleButton
	Dim btnDeleteModel As Button
	
	'camera data
	Dim sldCameraTurnSpeed As SliderView
	Dim sldCameraMoveSpeed As SliderView
	Dim sldCameraFOV As SliderView
	
	Dim txtPresetName As EditText
	Dim presetsListPanel As Panel
	Dim btnSavePreset As Button
	
	
	'todo most of these here can be removed from globals
	Dim btnRenderSettings As Button
	Dim spnRenderMode As Spinner
	Dim pnlRenderWire As Panel
	Dim pnlRenderSolid As Panel
	Dim pnlRenderRay As Panel
	Dim pnlRenderPath As Panel
	Dim chkSolidSmoothShading As CheckBox
	Dim chkSolidDrawFaces As CheckBox
	Dim chkSolidDrawEdges As CheckBox
	Dim chkSolidDrawVerts As CheckBox
	Dim chkSolidUseMaterialColors As CheckBox
	Dim txtSolidFaceColor As EditText
	Dim txtSolidEdgeColor As EditText
	Dim txtSolidVertexColor As EditText
	Dim txtSolidVoidColor As EditText
	Dim pnlSolidFaceColorPreview As Panel
	Dim pnlSolidEdgeColorPreview As Panel
	Dim pnlSolidVertexColorPreview As Panel
	Dim pnlSolidVoidColorPreview As Panel
	Dim sldSolidEdgeThickness As SliderView
	Dim sldSolidVertexSize As SliderView
	Dim chkWireBackfaceCull As CheckBox
	Dim chkWireDrawFaces As CheckBox
	Dim chkWireDrawEdges As CheckBox
	Dim chkWireDrawVerts As CheckBox
	Dim chkWireUseMaterialColors As CheckBox
	Dim chkWireShowCamera As CheckBox
	Dim chkWireShowLights As CheckBox
	Dim chkWireShowModels As CheckBox
	Dim chkWireShowAxes As CheckBox
	Dim txtWireFaceColor As EditText
	Dim txtWireEdgeColor As EditText
	Dim txtWireVertexColor As EditText
	Dim txtWireVoidColor As EditText
	Dim pnlWireFaceColorPreview As Panel
	Dim pnlWireEdgeColorPreview As Panel
	Dim pnlWireVertexColorPreview As Panel
	Dim pnlWireVoidColorPreview As Panel
	Dim sldWireEdgeThickness As SliderView
	Dim sldWireVertexSize As SliderView
	Dim spnRayResolution As Spinner
	Dim chkRayUseBVH As CheckBox
	Dim txtRayBounces As EditText
	Dim txtRayVoidColor As EditText
	Dim pnlRayVoidColorPreview As Panel
	Dim txtPathSamples As EditText
	Dim txtPathBounces As EditText
	Dim txtPathVoidColor As EditText
	Dim pnlPathVoidColorPreview As Panel
	Dim btnPathTraceRender As Button
	Dim renderSettingsUpdating As Boolean
	Dim renderResolutionValues As List
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
	
	popoverPresets = CreatePopover("presets")
	build_PopoverPresets
	popoverPresets.panelmain.BringToFront
	
'	render settings
	popoverRenderSettings = CreatePopover("renderSettings")
	build_PopoverRenderSettings
	popoverCamSettings.panelmain.BringToFront 'for now popover is separate, should become a layout in objSettings maybe
	popoverRenderSettings.panelmain.BringToFront
	
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
	
	btnRenderSettings.Initialize("btnRenderSettings")
	panelmain.AddView(btnRenderSettings, UI.Right(btnRenderShaded) + 4dip, 4dip, 20%x, 10%x)
	btnRenderSettings.Background = UI.GetDrawable(Colors.White, btnRenderSettings.Height)
	btnRenderSettings.Text = "Render"
	btnRenderSettings.Padding = Array As Int(0, 0, 0, 0)
	btnRenderSettings.TextSize = 20
	btnRenderSettings.Typeface = Typeface.DEFAULT_BOLD
	
	Dim btnPresets As Button
	btnPresets.Initialize("btnPresets")
	panelmain.AddView(btnPresets, UI.Right(btnRenderSettings) + 4dip, 4dip, 18%x, 10%x)
	btnPresets.Background = UI.GetDrawable(Colors.White, btnPresets.Height)
	btnPresets.Text = "Scenes"
	btnPresets.Padding = Array As Int(0, 0, 0, 0)
	btnPresets.TextSize = 20
	btnPresets.Typeface = Typeface.DEFAULT_BOLD

	Dim btnObjects As Button
	btnObjects.Initialize("btnObjects")
	panelmain.AddView(btnObjects, UI.Right(btnPresets) + 4dip, 4dip, 18%x, 10%x)
	btnObjects.Background = UI.GetDrawable(Colors.White, btnObjects.Height)
	btnObjects.Text = "Objects"
	btnObjects.Padding = Array As Int(0, 0, 0, 0)
	btnObjects.TextSize = 20
	btnObjects.Typeface = Typeface.DEFAULT_BOLD
	
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
	Main.Renderer.setRenderMode(Main.Renderer.MODE_WIREFRAME)
	UpdateRenderSettingsUI
	CallSub(Main, "resetTimer")
End Sub

Sub RenderSolid_Click
	Main.Renderer.setRenderMode(0)
	UpdateRenderSettingsUI
	CallSub(Main, "resetTimer")
End Sub

Sub RenderShaded_Click
	Main.Renderer.setRenderMode(1)
	UpdateRenderSettingsUI
	CallSub(Main, "resetTimer")
End Sub


Sub btnRenderSettings_Click
	UpdateRenderSettingsUI
	popoverRenderSettings.ShowPanel
End Sub

Sub spnRenderMode_ItemClick (Position As Int, Value As Object)
	If renderSettingsUpdating Then Return
	Dim mode As Int
	Select Position
		Case 0
			mode = Main.Renderer.MODE_RASTER
		Case 1
			mode = Main.Renderer.MODE_RAYTRACE
		Case 2
			mode = Main.Renderer.MODE_PATHTRACE
		Case 3
			mode = Main.Renderer.MODE_WIREFRAME	
		Case Else
			mode = Main.Renderer.MODE_RASTER
	End Select
	Main.Renderer.setRenderMode(mode)
	UpdateRenderModePanels(mode)
	CallSub(Main, "resetTimer")
End Sub

Sub chkSolidSmoothShading_CheckedChange(Checked As Boolean)
	If renderSettingsUpdating Then Return
	Main.Opt.SmoothShading = Checked
	UpdateSolidSettingsEnabled
	CallSub(Main, "resetTimer")
End Sub

Sub chkSolidUseMaterialColors_CheckedChange(Checked As Boolean)
	If renderSettingsUpdating Then Return
	Main.Opt.UseMaterialColors = Checked
	UpdateSolidSettingsEnabled
	CallSub(Main, "resetTimer")
End Sub

Sub chkSolidDrawFaces_CheckedChange(Checked As Boolean)
	If renderSettingsUpdating Then Return
	Main.Opt.DrawFaces = Checked
	CallSub(Main, "resetTimer")
End Sub

Sub chkSolidDrawEdges_CheckedChange(Checked As Boolean)
	If renderSettingsUpdating Then Return
	Main.Opt.DrawEdges = Checked
	CallSub(Main, "resetTimer")
End Sub

Sub chkSolidDrawVerts_CheckedChange(Checked As Boolean)
	If renderSettingsUpdating Then Return
	Main.Opt.DrawVerts = Checked
	CallSub(Main, "resetTimer")
End Sub

Sub txtSolidFaceColor_TextChanged (Old As String, New As String)
	If renderSettingsUpdating Then Return
	Dim parsed As Object = ParseColorOrNull(New)
	If parsed Is Int Then
		Dim color As Int = parsed
		Main.Opt.FaceColor = color
		If pnlSolidFaceColorPreview.IsInitialized Then pnlSolidFaceColorPreview.Color = color
		If Not(chkSolidUseMaterialColors.Checked) Then CallSub(Main, "resetTimer")
	End If
End Sub

Sub txtSolidEdgeColor_TextChanged (Old As String, New As String)
	If renderSettingsUpdating Then Return
	Dim parsed As Object = ParseColorOrNull(New)
	If parsed Is Int Then
		Dim color As Int = parsed
		Main.Opt.EdgeColor = color
		If pnlSolidEdgeColorPreview.IsInitialized Then pnlSolidEdgeColorPreview.Color = color
		CallSub(Main, "resetTimer")
	End If
End Sub

Sub txtSolidVertexColor_TextChanged (Old As String, New As String)
	If renderSettingsUpdating Then Return
	Dim parsed As Object = ParseColorOrNull(New)
	If parsed Is Int Then
		Dim color As Int = parsed
		Main.Opt.VertexColor = color
		If pnlSolidVertexColorPreview.IsInitialized Then pnlSolidVertexColorPreview.Color = color
		CallSub(Main, "resetTimer")
	End If
End Sub

Sub sldSolidEdgeThickness_ValueChanged(m As Map)
	If renderSettingsUpdating Then Return
	Dim value As Float = m.Get("Value")
	Main.Opt.EdgeThickness = value
	CallSub(Main, "resetTimer")
End Sub

Sub sldSolidVertexSize_ValueChanged(m As Map)
	If renderSettingsUpdating Then Return
	Dim value As Float = m.Get("Value")
	Main.Opt.VertexSize = value
	CallSub(Main, "resetTimer")
End Sub

Sub txtSolidVoidColor_TextChanged (Old As String, New As String)
	If renderSettingsUpdating Then Return
	Dim parsed As Object = ParseColorOrNull(New)
	If parsed Is Int Then
		Dim color As Int = parsed
		Main.Opt.VoidColor = color
		If pnlSolidVoidColorPreview.IsInitialized Then pnlSolidVoidColorPreview.Color = color
		CallSub(Main, "resetTimer")
	End If
End Sub

Sub chkWireBackfaceCull_CheckedChange(Checked As Boolean)
	If renderSettingsUpdating Then Return
	Main.WireOpt.BackfaceCull = Checked
	CallSub(Main, "resetTimer")
End Sub

Sub chkWireUseMaterialColors_CheckedChange(Checked As Boolean)
	If renderSettingsUpdating Then Return
	Main.WireOpt.UseMaterialColors = Checked
	UpdateWireframeSettingsEnabled
	CallSub(Main, "resetTimer")
End Sub

Sub chkWireDrawFaces_CheckedChange(Checked As Boolean)
	If renderSettingsUpdating Then Return
	Main.WireOpt.DrawFaces = Checked
	CallSub(Main, "resetTimer")
End Sub

Sub chkWireDrawEdges_CheckedChange(Checked As Boolean)
	If renderSettingsUpdating Then Return
	Main.WireOpt.DrawEdges = Checked
	CallSub(Main, "resetTimer")
End Sub

Sub chkWireDrawVerts_CheckedChange(Checked As Boolean)
	If renderSettingsUpdating Then Return
	Main.WireOpt.DrawVerts = Checked
	CallSub(Main, "resetTimer")
End Sub

Sub chkWireShowModels_CheckedChange(Checked As Boolean)
	If renderSettingsUpdating Then Return
	Main.WireOpt.ShowModels = Checked
	CallSub(Main, "resetTimer")
End Sub

Sub chkWireShowCamera_CheckedChange(Checked As Boolean)
	If renderSettingsUpdating Then Return
	Main.WireOpt.ShowCamera = Checked
	CallSub(Main, "resetTimer")
End Sub

Sub chkWireShowLights_CheckedChange(Checked As Boolean)
	If renderSettingsUpdating Then Return
	Main.WireOpt.ShowLights = Checked
	CallSub(Main, "resetTimer")
End Sub

Sub chkWireShowAxes_CheckedChange(Checked As Boolean)
	If renderSettingsUpdating Then Return
	Main.WireOpt.ShowOriginAxes = Checked
	CallSub(Main, "resetTimer")
End Sub

Sub txtWireFaceColor_TextChanged (Old As String, New As String)
	If renderSettingsUpdating Then Return
	Dim parsed As Object = ParseColorOrNull(New)
	If parsed Is Int Then
		Dim color As Int = parsed
		Main.WireOpt.FaceColor = color
		If pnlWireFaceColorPreview.IsInitialized Then pnlWireFaceColorPreview.Color = color
		If Main.WireOpt.UseMaterialColors = False Then CallSub(Main, "resetTimer")
	End If
End Sub

Sub txtWireEdgeColor_TextChanged (Old As String, New As String)
	If renderSettingsUpdating Then Return
	Dim parsed As Object = ParseColorOrNull(New)
	If parsed Is Int Then
		Dim color As Int = parsed
		Main.WireOpt.EdgeColor = color
		If pnlWireEdgeColorPreview.IsInitialized Then pnlWireEdgeColorPreview.Color = color
		CallSub(Main, "resetTimer")
	End If
End Sub

Sub txtWireVertexColor_TextChanged (Old As String, New As String)
	If renderSettingsUpdating Then Return
	Dim parsed As Object = ParseColorOrNull(New)
	If parsed Is Int Then
		Dim color As Int = parsed
		Main.WireOpt.VertexColor = color
		If pnlWireVertexColorPreview.IsInitialized Then pnlWireVertexColorPreview.Color = color
		CallSub(Main, "resetTimer")
	End If
End Sub

Sub txtWireVoidColor_TextChanged (Old As String, New As String)
	If renderSettingsUpdating Then Return
	Dim parsed As Object = ParseColorOrNull(New)
	If parsed Is Int Then
		Dim color As Int = parsed
		Main.WireOpt.VoidColor = color
		If pnlWireVoidColorPreview.IsInitialized Then pnlWireVoidColorPreview.Color = color
		CallSub(Main, "resetTimer")
	End If
End Sub

Sub sldWireEdgeThickness_ValueChanged(m As Map)
	If renderSettingsUpdating Then Return
	Dim value As Float = m.Get("Value")
	Main.WireOpt.EdgeThickness = value
	CallSub(Main, "resetTimer")
End Sub

Sub sldWireVertexSize_ValueChanged(m As Map)
	If renderSettingsUpdating Then Return
	Dim value As Float = m.Get("Value")
	Main.WireOpt.VertexSize = value
	CallSub(Main, "resetTimer")
End Sub
Sub spnRayResolution_ItemClick (Position As Int, Value As Object)
	If renderSettingsUpdating Then Return
	If renderResolutionValues.IsInitialized = False Then Return
	If Position < 0 Or Position >= renderResolutionValues.Size Then Return
	Dim scale As Double = renderResolutionValues.Get(Position)
	Main.RaytraceResolutionScale = scale
	CallSub(Main, "resetTimer")
End Sub

Sub chkRayUseBVH_CheckedChange(Checked As Boolean)
	If renderSettingsUpdating Then Return
	Main.Renderer.UseBVH = Checked
	CallSub(Main, "resetTimer")
End Sub

Sub txtRayBounces_TextChanged (Old As String, New As String)
	If renderSettingsUpdating Then Return
	Dim trimmed As String = New.Trim
	If trimmed.Length = 0 Then Return
	If IsNumber(trimmed) = False Then Return
	Dim value As Int = Max(1, trimmed)
	Main.Renderer.RT_MaxDepth = value
	CallSub(Main, "resetTimer")
End Sub

Sub txtRayVoidColor_TextChanged (Old As String, New As String)
	If renderSettingsUpdating Then Return
	Dim parsed As Object = ParseColorOrNull(New)
	If parsed Is Int Then
		Dim color As Int = parsed
		Main.RaytraceVoidColor = color
		Main.Renderer.RayBackgroundColor = color
		If pnlRayVoidColorPreview.IsInitialized Then pnlRayVoidColorPreview.Color = color
		CallSub(Main, "resetTimer")
	End If
End Sub

Sub txtPathSamples_TextChanged (Old As String, New As String)
	If renderSettingsUpdating Then Return
	Dim trimmed As String = New.Trim
	If trimmed.Length = 0 Then Return
	If IsNumber(trimmed) = False Then Return
	Dim value As Int = Max(1, trimmed)
	Main.PathTraceSamples = value
	CallSub(Main, "resetTimer")
End Sub

Sub txtPathBounces_TextChanged (Old As String, New As String)
	If renderSettingsUpdating Then Return
	Dim trimmed As String = New.Trim
	If trimmed.Length = 0 Then Return
	If IsNumber(trimmed) = False Then Return
	Dim value As Int = Max(1, trimmed)
	Main.PathTraceBounces = value
	CallSub(Main, "resetTimer")
End Sub

Sub txtPathVoidColor_TextChanged (Old As String, New As String)
	If renderSettingsUpdating Then Return
	Dim parsed As Object = ParseColorOrNull(New)
	If parsed Is Int Then
		Dim color As Int = parsed
		Main.PathTraceVoidColor = color
		Main.Renderer.PathBackgroundColor = color
		If pnlPathVoidColorPreview.IsInitialized Then pnlPathVoidColorPreview.Color = color
		CallSub(Main, "resetTimer")
	End If
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


Sub btnPresets_Click
	refreshPresetsPopover
	popoverPresets.ShowPanel
End Sub

Sub btnObjects_Click
	refreshObjectPopover
	popoverObjectsList.ShowPanel
End Sub

Sub presetSave_Click
	Dim name As String = txtPresetName.Text.Trim
	CallSub2(Main, "SaveScenePreset", name)
	txtPresetName.Text = Main.CurrentScenePresetName
	refreshPresetsPopover
	ToastMessageShow($"Preset saved as ${Main.CurrentScenePresetName}"$, False)
End Sub

Sub presetLoad_Click
	Dim btn As Button = Sender
	Dim presetName As String = btn.Tag
	If presetName = Null Then Return
	CallSub2(Main, "LoadScenePreset", presetName)
	txtPresetName.Text = Main.CurrentScenePresetName
	refreshPresetsPopover
	popoverPresets.HidePanel
End Sub

Sub presetDelete_Click
	Dim btn As Button = Sender
	Dim presetName As String = btn.Tag
	If presetName = Null Then Return
	CallSub2(Main, "DeleteScenePreset", presetName)
	If Main.ScenePresetLoaded = False Then txtPresetName.Text = ""
	refreshPresetsPopover
	ToastMessageShow($"Deleted preset ${presetName}"$, False)
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

	Dim padding As Int = 12dip
	Dim buttonHeight As Int = 44dip
	Dim labelHeight As Int = 24dip
	Dim top As Int = padding
	Dim fullWidth As Int = popoverObjectsList.containerPanel.Width - padding * 2

	Dim lblAddPrimitive As Label
	lblAddPrimitive.Initialize("")
	lblAddPrimitive.Text = "Add Primitive"
	lblAddPrimitive.TextColor = Colors.RGB(40, 40, 40)
	lblAddPrimitive.TextSize = 16
	lblAddPrimitive.Typeface = Typeface.DEFAULT_BOLD
	lblAddPrimitive.Gravity = Gravity.CENTER_VERTICAL
	container.AddView(lblAddPrimitive, padding, top, fullWidth, labelHeight)
	top = UI.Bottom(lblAddPrimitive) + SmallSpaceing
	container.Height = top

	Dim primitiveButtons As List
	primitiveButtons.Initialize2(Array As String("Cube", "Sphere", "Cylinder", "Cone", "Plane"))
	For Each primitiveName As String In primitiveButtons
		Dim btn As Button
		btn.Initialize("btnAddObject")
		btn.Text = $"Add ${primitiveName}"$
		btn.TextSize = 14
		btn.Typeface = Typeface.DEFAULT_BOLD
		btn.TextColor = Colors.White
		btn.Gravity = Gravity.CENTER
		btn.Tag = CreateMap("mode": "primitive", "value": primitiveName)
		btn.Background = UI.GetDrawable(Colors.RGB(55, 124, 253), buttonHeight)
		container.AddView(btn, padding, top, fullWidth, buttonHeight)
		top = top + buttonHeight + SmallSpaceing
	Next

	top = top + BigSpaceing
	container.Height = top

	Dim lblAddAsset As Label
	lblAddAsset.Initialize("")
	lblAddAsset.Text = "Add Model from Assets"
	lblAddAsset.TextColor = Colors.RGB(40, 40, 40)
	lblAddAsset.TextSize = 16
	lblAddAsset.Typeface = Typeface.DEFAULT_BOLD
	lblAddAsset.Gravity = Gravity.CENTER_VERTICAL
	container.AddView(lblAddAsset, padding, top, fullWidth, labelHeight)
	top = UI.Bottom(lblAddAsset) + SmallSpaceing
	container.Height = top

	Dim assetFiles As List = Callsub(Main, "ListAssetObjFiles")
	If assetFiles.IsInitialized And assetFiles.Size > 0 Then
		For Each fileName As String In assetFiles
			Dim displayName As String = fileName
			Dim dot As Int = displayName.LastIndexOf(".")
			If dot > 0 Then displayName = displayName.SubString2(0, dot)
			Dim btnAsset As Button
			btnAsset.Initialize("btnAddObject")
			btnAsset.Text = $"Add ${displayName}"$
			btnAsset.TextSize = 14
			btnAsset.Typeface = Typeface.DEFAULT_BOLD
			btnAsset.TextColor = Colors.White
			btnAsset.Gravity = Gravity.CENTER
			btnAsset.Tag = CreateMap("mode": "asset", "value": fileName)
			btnAsset.Background = UI.GetDrawable(Colors.RGB(45, 156, 86), buttonHeight)
			container.AddView(btnAsset, padding, top, fullWidth, buttonHeight)
			top = top + buttonHeight + SmallSpaceing
		Next
	Else
		Dim lblNoAssets As Label
		lblNoAssets.Initialize("")
		lblNoAssets.Text = "No OBJ assets found"
		lblNoAssets.TextColor = Colors.Gray
		lblNoAssets.Gravity = Gravity.CENTER_VERTICAL
		lblNoAssets.TextSize = 14
		container.AddView(lblNoAssets, padding, top, fullWidth, labelHeight)
		top = UI.Bottom(lblNoAssets) + SmallSpaceing
	End If

	top = top + BigSpaceing
	container.Height = top

	Dim lblSceneObjects As Label
	lblSceneObjects.Initialize("")
	lblSceneObjects.Text = "Scene Objects"
	lblSceneObjects.TextColor = Colors.RGB(40, 40, 40)
	lblSceneObjects.TextSize = 16
	lblSceneObjects.Typeface = Typeface.DEFAULT_BOLD
	lblSceneObjects.Gravity = Gravity.CENTER_VERTICAL
	container.AddView(lblSceneObjects, padding, top, fullWidth, labelHeight)
	top = UI.Bottom(lblSceneObjects) + SmallSpaceing
	container.Height = top

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
		model.Title = obj.Name
		model.TypeIcon = "🧊"
		model.Tag = CreateMap("type": "model", "ref": obj)
		model.SetShownWithoutEvent(obj.Visible)
	Next

	If container.Height < top Then container.Height = top
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

Sub btnAddObject_Click
	Dim btn As Button = Sender
	Dim tagData As Object = btn.Tag
	If tagData Is Map Then
		Dim data As Map = tagData
		Dim mode As String = data.Get("mode")
		Select mode
			Case "primitive"
				Dim primitive As String = data.Get("value")
				Dim newModel As cModel = CallSub2(Main, "AddPrimitiveObject", primitive)
				refreshObjectPopover
				If newModel <> Null Then
					ApplyObjectDataToPopover(newModel)
					popoverObjectSettings.ShowPanel
				End If
			Case "asset"
				Dim fileName As String = data.Get("value")
				Dim newAssetModel As cModel = CallSub2(Main, "AddAssetModel", fileName)
				refreshObjectPopover
				If newAssetModel <> Null Then
					ApplyObjectDataToPopover(newAssetModel)
					popoverObjectSettings.ShowPanel
				End If
		End Select
	End If
End Sub

Sub btnDeleteModel_Click
	Dim modelData As Object = btnDeleteModel.Tag
	If Not(modelData Is cModel) Then Return
	Dim mdl As cModel = modelData
	If CallSub2(Main, "RemoveModelFromScene", mdl) Then
		refreshObjectPopover
		popoverObjectSettings.HidePanel
	End If
End Sub

public Sub build_PopoverRenderSettings
	popoverRenderSettings.Title = "Render Settings"

	Dim content As Panel = popoverRenderSettings.containerPanel.Panel
	content.RemoveAllViews
	content.Color = Colors.Transparent

	Dim padding As Int = 12dip

	spnRenderMode.Initialize("spnRenderMode")
	content.AddView(spnRenderMode, padding, padding, popoverRenderSettings.containerPanel.Width - padding * 2, 40dip)
	spnRenderMode.AddAll(Array As String("Solid (Raster)", "Ray Trace", "Path Trace",  "Wireframe"))

	pnlRenderWire.Initialize("")
	pnlRenderWire.Color = Colors.Transparent
	content.AddView(pnlRenderWire, 0, spnRenderMode.Top + spnRenderMode.Height + padding, popoverRenderSettings.containerPanel.Width, 0)
	BuildWireRenderSettings(pnlRenderWire, padding)
	
	pnlRenderSolid.Initialize("")
	pnlRenderSolid.Color = Colors.Transparent
	content.AddView(pnlRenderSolid, 0, pnlRenderWire.Top, popoverRenderSettings.containerPanel.Width, 0)
	BuildSolidRenderSettings(pnlRenderSolid, padding)

	pnlRenderRay.Initialize("")
	pnlRenderRay.Color = Colors.Transparent
	content.AddView(pnlRenderRay, 0, pnlRenderSolid.Top, popoverRenderSettings.containerPanel.Width, 0)
	BuildRayTraceSettings(pnlRenderRay, padding)

	pnlRenderPath.Initialize("")
	pnlRenderPath.Color = Colors.Transparent
	content.AddView(pnlRenderPath, 0, pnlRenderSolid.Top, popoverRenderSettings.containerPanel.Width, 0)
	BuildPathTraceSettings(pnlRenderPath, padding)

	renderResolutionValues.Initialize2(Array As Object(1.0, 0.75, 0.5, 0.25, 0.1))

	UpdateRenderSettingsUI
End Sub

Private Sub BuildSolidRenderSettings(parent As Panel, padding As Int)
	parent.RemoveAllViews
	Dim top As Int = 0

	chkSolidSmoothShading.Initialize("chkSolidSmoothShading")
	chkSolidSmoothShading.Text = "Smooth Shading"
	chkSolidSmoothShading.TextSize = 16
	parent.AddView(chkSolidSmoothShading, padding, top, parent.Width - padding * 2, 40dip)
	top = top + 40dip + SmallSpaceing

	chkSolidUseMaterialColors.Initialize("chkSolidUseMaterialColors")
	chkSolidUseMaterialColors.Text = "Use Material Colors"
	chkSolidUseMaterialColors.TextSize = 16
	parent.AddView(chkSolidUseMaterialColors, padding, top, parent.Width - padding * 2, 40dip)
	top = top + 40dip + SmallSpaceing

	chkSolidDrawFaces.Initialize("chkSolidDrawFaces")
	chkSolidDrawFaces.Text = "Draw Faces"
	chkSolidDrawFaces.TextSize = 16
	parent.AddView(chkSolidDrawFaces, padding, top, parent.Width - padding * 2, 36dip)
	top = top + 36dip + SmallSpaceing

	chkSolidDrawEdges.Initialize("chkSolidDrawEdges")
	chkSolidDrawEdges.Text = "Draw Edges"
	chkSolidDrawEdges.TextSize = 16
	parent.AddView(chkSolidDrawEdges, padding, top, parent.Width - padding * 2, 36dip)
	top = top + 36dip + SmallSpaceing

	chkSolidDrawVerts.Initialize("chkSolidDrawVerts")
	chkSolidDrawVerts.Text = "Draw Vertices"
	chkSolidDrawVerts.TextSize = 16
	parent.AddView(chkSolidDrawVerts, padding, top, parent.Width - padding * 2, 36dip)
	top = top + 36dip + BigSpaceing

	Dim lblFace As Label
	lblFace.Initialize("")
	lblFace.Text = "Face Color (#RRGGBB)"
	lblFace.TextSize = 14
	lblFace.TextColor = Colors.Black
	parent.AddView(lblFace, padding, top, parent.Width - padding * 2, 20dip)
	top = top + 20dip + SmallSpaceing

	txtSolidFaceColor.Initialize("txtSolidFaceColor")
	StyleTextField(txtSolidFaceColor)
	parent.AddView(txtSolidFaceColor, padding, top, parent.Width - padding * 3 - 40dip, 36dip)
	pnlSolidFaceColorPreview.Initialize("")
	pnlSolidFaceColorPreview.Background = UI.GetDrawableWithBorder(Colors.White, 6dip, 1dip, Colors.LightGray)
	pnlSolidFaceColorPreview.Color = Colors.Black
	parent.AddView(pnlSolidFaceColorPreview, parent.Width - padding - 40dip, top, 40dip, 36dip)
	top = top + 36dip + SmallSpaceing

	Dim lblEdge As Label
	lblEdge.Initialize("")
	lblEdge.Text = "Edge Color (#RRGGBB)"
	lblEdge.TextSize = 14
	lblEdge.TextColor = Colors.Black
	parent.AddView(lblEdge, padding, top, parent.Width - padding * 2, 20dip)
	top = top + 20dip + SmallSpaceing

	txtSolidEdgeColor.Initialize("txtSolidEdgeColor")
	StyleTextField(txtSolidEdgeColor)
	parent.AddView(txtSolidEdgeColor, padding, top, parent.Width - padding * 3 - 40dip, 36dip)
	pnlSolidEdgeColorPreview.Initialize("")
	pnlSolidEdgeColorPreview.Background = UI.GetDrawableWithBorder(Colors.White, 6dip, 1dip, Colors.LightGray)
	pnlSolidEdgeColorPreview.Color = Colors.Black
	parent.AddView(pnlSolidEdgeColorPreview, parent.Width - padding - 40dip, top, 40dip, 36dip)
	top = top + 36dip + SmallSpaceing

	Dim lblVert As Label
	lblVert.Initialize("")
	lblVert.Text = "Vertex Color (#RRGGBB)"
	lblVert.TextSize = 14
	lblVert.TextColor = Colors.Black
	parent.AddView(lblVert, padding, top, parent.Width - padding * 2, 20dip)
	top = top + 20dip + SmallSpaceing

	txtSolidVertexColor.Initialize("txtSolidVertexColor")
	StyleTextField(txtSolidVertexColor)
	parent.AddView(txtSolidVertexColor, padding, top, parent.Width - padding * 3 - 40dip, 36dip)
	pnlSolidVertexColorPreview.Initialize("")
	pnlSolidVertexColorPreview.Background = UI.GetDrawableWithBorder(Colors.White, 6dip, 1dip, Colors.LightGray)
	pnlSolidVertexColorPreview.Color = Colors.Black
	parent.AddView(pnlSolidVertexColorPreview, parent.Width - padding - 40dip, top, 40dip, 36dip)
	top = top + 36dip + SmallSpaceing

	Dim lblSolidVoid As Label
	lblSolidVoid.Initialize("")
	lblSolidVoid.Text = "Void Color (#RRGGBB)"
	lblSolidVoid.TextSize = 14
	lblSolidVoid.TextColor = Colors.Black
	parent.AddView(lblSolidVoid, padding, top, parent.Width - padding * 2, 20dip)
	top = top + 20dip + SmallSpaceing

	txtSolidVoidColor.Initialize("txtSolidVoidColor")
	StyleTextField(txtSolidVoidColor)
	parent.AddView(txtSolidVoidColor, padding, top, parent.Width - padding * 3 - 40dip, 36dip)
	pnlSolidVoidColorPreview.Initialize("")
	pnlSolidVoidColorPreview.Background = UI.GetDrawableWithBorder(Colors.White, 6dip, 1dip, Colors.LightGray)
	pnlSolidVoidColorPreview.Color = Colors.Black
	parent.AddView(pnlSolidVoidColorPreview, parent.Width - padding - 40dip, top, 40dip, 36dip)
	top = top + 36dip + SmallSpaceing

	sldSolidEdgeThickness.Initialize(Me, "sldSolidEdgeThickness")
	sldSolidEdgeThickness.AddToParent(parent, padding, top, parent.Width - padding * 2, 80dip)
	sldSolidEdgeThickness.setTitle("Edge Thickness (dip)")
	top = UI.Bottom(sldSolidEdgeThickness.panelmain) + SmallSpaceing

	sldSolidVertexSize.Initialize(Me, "sldSolidVertexSize")
	sldSolidVertexSize.AddToParent(parent, padding, top, parent.Width - padding * 2, 80dip)
	sldSolidVertexSize.setTitle("Vertex Size (dip)")
	top = UI.Bottom(sldSolidVertexSize.panelmain) + padding

	parent.Height = top
End Sub


Private Sub BuildWireRenderSettings(parent As Panel, padding As Int)
	parent.RemoveAllViews
	Dim top As Int = 0

	chkWireBackfaceCull.Initialize("chkWireBackfaceCull")
	chkWireBackfaceCull.Text = "Backface Cull"
	chkWireBackfaceCull.TextSize = 16
	parent.AddView(chkWireBackfaceCull, padding, top, parent.Width - padding * 2, 36dip)
	top = top + 36dip + SmallSpaceing

	chkWireUseMaterialColors.Initialize("chkWireUseMaterialColors")
	chkWireUseMaterialColors.Text = "Use Material Colors"
	chkWireUseMaterialColors.TextSize = 16
	parent.AddView(chkWireUseMaterialColors, padding, top, parent.Width - padding * 2, 36dip)
	top = top + 36dip + SmallSpaceing

	chkWireDrawFaces.Initialize("chkWireDrawFaces")
	chkWireDrawFaces.Text = "Draw Faces"
	chkWireDrawFaces.TextSize = 16
	parent.AddView(chkWireDrawFaces, padding, top, parent.Width - padding * 2, 36dip)
	top = top + 36dip + SmallSpaceing

	chkWireDrawEdges.Initialize("chkWireDrawEdges")
	chkWireDrawEdges.Text = "Draw Edges"
	chkWireDrawEdges.TextSize = 16
	parent.AddView(chkWireDrawEdges, padding, top, parent.Width - padding * 2, 36dip)
	top = top + 36dip + SmallSpaceing

	chkWireDrawVerts.Initialize("chkWireDrawVerts")
	chkWireDrawVerts.Text = "Draw Vertices"
	chkWireDrawVerts.TextSize = 16
	parent.AddView(chkWireDrawVerts, padding, top, parent.Width - padding * 2, 36dip)
	top = top + 36dip + SmallSpaceing

	chkWireShowModels.Initialize("chkWireShowModels")
	chkWireShowModels.Text = "Show Models"
	chkWireShowModels.TextSize = 16
	parent.AddView(chkWireShowModels, padding, top, parent.Width - padding * 2, 36dip)
	top = top + 36dip + SmallSpaceing

	chkWireShowCamera.Initialize("chkWireShowCamera")
	chkWireShowCamera.Text = "Show Camera Overlay"
	chkWireShowCamera.TextSize = 16
	parent.AddView(chkWireShowCamera, padding, top, parent.Width - padding * 2, 36dip)
	top = top + 36dip + SmallSpaceing

	chkWireShowLights.Initialize("chkWireShowLights")
	chkWireShowLights.Text = "Show Lights"
	chkWireShowLights.TextSize = 16
	parent.AddView(chkWireShowLights, padding, top, parent.Width - padding * 2, 36dip)
	top = top + 36dip + SmallSpaceing

	chkWireShowAxes.Initialize("chkWireShowAxes")
	chkWireShowAxes.Text = "Show Origin Axes"
	chkWireShowAxes.TextSize = 16
	parent.AddView(chkWireShowAxes, padding, top, parent.Width - padding * 2, 36dip)
	top = top + 36dip + BigSpaceing

	Dim lblWireFace As Label
	lblWireFace.Initialize("")
	lblWireFace.Text = "Face Color (#RRGGBB)"
	lblWireFace.TextSize = 14
	lblWireFace.TextColor = Colors.Black
	parent.AddView(lblWireFace, padding, top, parent.Width - padding * 2, 20dip)
	top = top + 20dip + SmallSpaceing

	txtWireFaceColor.Initialize("txtWireFaceColor")
	StyleTextField(txtWireFaceColor)
	parent.AddView(txtWireFaceColor, padding, top, parent.Width - padding * 3 - 40dip, 36dip)
	pnlWireFaceColorPreview.Initialize("")
	pnlWireFaceColorPreview.Background = UI.GetDrawableWithBorder(Colors.White, 6dip, 1dip, Colors.LightGray)
	pnlWireFaceColorPreview.Color = Colors.Black
	parent.AddView(pnlWireFaceColorPreview, parent.Width - padding - 40dip, top, 40dip, 36dip)
	top = top + 36dip + SmallSpaceing

	Dim lblWireEdge As Label
	lblWireEdge.Initialize("")
	lblWireEdge.Text = "Edge Color (#RRGGBB)"
	lblWireEdge.TextSize = 14
	lblWireEdge.TextColor = Colors.Black
	parent.AddView(lblWireEdge, padding, top, parent.Width - padding * 2, 20dip)
	top = top + 20dip + SmallSpaceing

	txtWireEdgeColor.Initialize("txtWireEdgeColor")
	StyleTextField(txtWireEdgeColor)
	parent.AddView(txtWireEdgeColor, padding, top, parent.Width - padding * 3 - 40dip, 36dip)
	pnlWireEdgeColorPreview.Initialize("")
	pnlWireEdgeColorPreview.Background = UI.GetDrawableWithBorder(Colors.White, 6dip, 1dip, Colors.LightGray)
	pnlWireEdgeColorPreview.Color = Colors.Black
	parent.AddView(pnlWireEdgeColorPreview, parent.Width - padding - 40dip, top, 40dip, 36dip)
	top = top + 36dip + SmallSpaceing

	Dim lblWireVert As Label
	lblWireVert.Initialize("")
	lblWireVert.Text = "Vertex Color (#RRGGBB)"
	lblWireVert.TextSize = 14
	lblWireVert.TextColor = Colors.Black
	parent.AddView(lblWireVert, padding, top, parent.Width - padding * 2, 20dip)
	top = top + 20dip + SmallSpaceing

	txtWireVertexColor.Initialize("txtWireVertexColor")
	StyleTextField(txtWireVertexColor)
	parent.AddView(txtWireVertexColor, padding, top, parent.Width - padding * 3 - 40dip, 36dip)
	pnlWireVertexColorPreview.Initialize("")
	pnlWireVertexColorPreview.Background = UI.GetDrawableWithBorder(Colors.White, 6dip, 1dip, Colors.LightGray)
	pnlWireVertexColorPreview.Color = Colors.Black
	parent.AddView(pnlWireVertexColorPreview, parent.Width - padding - 40dip, top, 40dip, 36dip)
	top = top + 36dip + SmallSpaceing

	Dim lblWireVoid As Label
	lblWireVoid.Initialize("")
	lblWireVoid.Text = "Void Color (#RRGGBB)"
	lblWireVoid.TextSize = 14
	lblWireVoid.TextColor = Colors.Black
	parent.AddView(lblWireVoid, padding, top, parent.Width - padding * 2, 20dip)
	top = top + 20dip + SmallSpaceing

	txtWireVoidColor.Initialize("txtWireVoidColor")
	StyleTextField(txtWireVoidColor)
	parent.AddView(txtWireVoidColor, padding, top, parent.Width - padding * 3 - 40dip, 36dip)
	pnlWireVoidColorPreview.Initialize("")
	pnlWireVoidColorPreview.Background = UI.GetDrawableWithBorder(Colors.White, 6dip, 1dip, Colors.LightGray)
	pnlWireVoidColorPreview.Color = Colors.Black
	parent.AddView(pnlWireVoidColorPreview, parent.Width - padding - 40dip, top, 40dip, 36dip)
	top = top + 36dip + SmallSpaceing

	sldWireEdgeThickness.Initialize(Me, "sldWireEdgeThickness")
	sldWireEdgeThickness.AddToParent(parent, padding, top, parent.Width - padding * 2, 80dip)
	sldWireEdgeThickness.setTitle("Edge Thickness (dip)")
	top = UI.Bottom(sldWireEdgeThickness.panelmain) + SmallSpaceing

	sldWireVertexSize.Initialize(Me, "sldWireVertexSize")
	sldWireVertexSize.AddToParent(parent, padding, top, parent.Width - padding * 2, 80dip)
	sldWireVertexSize.setTitle("Vertex Size (dip)")
	top = UI.Bottom(sldWireVertexSize.panelmain) + padding

	parent.Height = top
End Sub

Private Sub BuildRayTraceSettings(parent As Panel, padding As Int)
	parent.RemoveAllViews
	Dim top As Int = 0

	Dim lblRes As Label
	lblRes.Initialize("")
	lblRes.Text = "Resolution"
	lblRes.TextSize = 14
	lblRes.TextColor = Colors.Black
	parent.AddView(lblRes, padding, top, parent.Width - padding * 2, 20dip)
	top = top + 20dip + SmallSpaceing

	spnRayResolution.Initialize("spnRayResolution")
	parent.AddView(spnRayResolution, padding, top, parent.Width - padding * 2, 40dip)
	spnRayResolution.AddAll(Array As String("100%", "75%", "50%", "25%", "10%"))
	top = top + 40dip + SmallSpaceing

	chkRayUseBVH.Initialize("chkRayUseBVH")
	chkRayUseBVH.Text = "Use BVH Acceleration"
	chkRayUseBVH.TextSize = 16
	parent.AddView(chkRayUseBVH, padding, top, parent.Width - padding * 2, 40dip)
	top = top + 40dip + SmallSpaceing

	Dim lblBounces As Label
	lblBounces.Initialize("")
	lblBounces.Text = "Ray Bounces"
	lblBounces.TextSize = 14
	lblBounces.TextColor = Colors.Black
	parent.AddView(lblBounces, padding, top, parent.Width - padding * 2, 20dip)
	top = top + 20dip + SmallSpaceing

	txtRayBounces.Initialize("txtRayBounces")
	StyleTextField(txtRayBounces)
	txtRayBounces.InputType = txtRayBounces.INPUT_TYPE_NUMBERS
	parent.AddView(txtRayBounces, padding, top, parent.Width - padding * 2, 36dip)
	top = top + 36dip + SmallSpaceing

	Dim lblRayVoid As Label
	lblRayVoid.Initialize("")
	lblRayVoid.Text = "Void Color (#RRGGBB)"
	lblRayVoid.TextSize = 14
	lblRayVoid.TextColor = Colors.Black
	parent.AddView(lblRayVoid, padding, top, parent.Width - padding * 2, 20dip)
	top = top + 20dip + SmallSpaceing

	txtRayVoidColor.Initialize("txtRayVoidColor")
	StyleTextField(txtRayVoidColor)
	parent.AddView(txtRayVoidColor, padding, top, parent.Width - padding * 3 - 40dip, 36dip)
	pnlRayVoidColorPreview.Initialize("")
	pnlRayVoidColorPreview.Background = UI.GetDrawableWithBorder(Colors.White, 6dip, 1dip, Colors.LightGray)
	pnlRayVoidColorPreview.Color = Colors.Black
	parent.AddView(pnlRayVoidColorPreview, parent.Width - padding - 40dip, top, 40dip, 36dip)
	top = top + 36dip + padding

	parent.Height = top
End Sub

Private Sub BuildPathTraceSettings(parent As Panel, padding As Int)
	parent.RemoveAllViews
	Dim top As Int = 0

	Dim lblSamples As Label
	lblSamples.Initialize("")
	lblSamples.Text = "Samples Per Pixel"
	lblSamples.TextSize = 14
	lblSamples.TextColor = Colors.Black
	parent.AddView(lblSamples, padding, top, parent.Width - padding * 2, 20dip)
	top = top + 20dip + SmallSpaceing

	txtPathSamples.Initialize("txtPathSamples")
	StyleTextField(txtPathSamples)
	txtPathSamples.InputType = txtPathSamples.INPUT_TYPE_NUMBERS
	parent.AddView(txtPathSamples, padding, top, parent.Width - padding * 2, 36dip)
	top = top + 36dip + SmallSpaceing

	Dim lblPathBounces As Label
	lblPathBounces.Initialize("")
	lblPathBounces.Text = "Ray Bounces"
	lblPathBounces.TextSize = 14
	lblPathBounces.TextColor = Colors.Black
	parent.AddView(lblPathBounces, padding, top, parent.Width - padding * 2, 20dip)
	top = top + 20dip + SmallSpaceing

	txtPathBounces.Initialize("txtPathBounces")
	StyleTextField(txtPathBounces)
	txtPathBounces.InputType = txtPathBounces.INPUT_TYPE_NUMBERS
	parent.AddView(txtPathBounces, padding, top, parent.Width - padding * 2, 36dip)
	top = top + 36dip + SmallSpaceing

	Dim lblPathVoid As Label
	lblPathVoid.Initialize("")
	lblPathVoid.Text = "Void Color (#RRGGBB)"
	lblPathVoid.TextSize = 14
	lblPathVoid.TextColor = Colors.Black
	parent.AddView(lblPathVoid, padding, top, parent.Width - padding * 2, 20dip)
	top = top + 20dip + SmallSpaceing

	txtPathVoidColor.Initialize("txtPathVoidColor")
	StyleTextField(txtPathVoidColor)
	parent.AddView(txtPathVoidColor, padding, top, parent.Width - padding * 3 - 40dip, 36dip)
	pnlPathVoidColorPreview.Initialize("")
	pnlPathVoidColorPreview.Background = UI.GetDrawableWithBorder(Colors.White, 6dip, 1dip, Colors.LightGray)
	pnlPathVoidColorPreview.Color = Colors.Black
	parent.AddView(pnlPathVoidColorPreview, parent.Width - padding - 40dip, top, 40dip, 36dip)
	top = top + 36dip + BigSpaceing

	btnPathTraceRender.Initialize("renderPathTrace")
	parent.AddView(btnPathTraceRender, padding, top, parent.Width - padding * 2, 44dip)
	btnPathTraceRender.Text = "Render Path Trace"
	btnPathTraceRender.Typeface = Typeface.DEFAULT_BOLD
	btnPathTraceRender.TextSize = 16
	btnPathTraceRender.TextColor = Colors.White
	btnPathTraceRender.Gravity = Gravity.CENTER
	btnPathTraceRender.Background = UI.GetDrawable(Colors.RGB(76, 175, 80), btnPathTraceRender.Height)
	top = top + 44dip + padding

	parent.Height = top
End Sub

Private Sub StyleTextField(et As EditText)
	et.TextSize = 16
	et.TextColor = Colors.Black
	et.Color = Colors.White
	et.SingleLine = True
	et.Padding = Array As Int(6dip, 0, 6dip, 0)
	et.Background = UI.GetDrawableWithBorder(Colors.White, 6dip, 1dip, Colors.LightGray)
End Sub

Private Sub UpdateRenderSettingsUI
	If popoverRenderSettings.IsInitialized = False Then Return
	If spnRenderMode.IsInitialized = False Then Return
	renderSettingsUpdating = True

	Dim mode As Int = Main.Renderer.RENDER_MODE
	If mode < 0 Then mode = 0
	If spnRenderMode.Size > mode Then
		spnRenderMode.SelectedIndex = mode
	Else If spnRenderMode.Size > 0 Then
		spnRenderMode.SelectedIndex = 0
		mode = 0
	End If
	If chkSolidSmoothShading.IsInitialized Then chkSolidSmoothShading.Checked = Main.Opt.SmoothShading
	If chkSolidUseMaterialColors.IsInitialized Then chkSolidUseMaterialColors.Checked = Main.Opt.UseMaterialColors
	If chkSolidDrawFaces.IsInitialized Then chkSolidDrawFaces.Checked = Main.Opt.DrawFaces
	If chkSolidDrawEdges.IsInitialized Then chkSolidDrawEdges.Checked = Main.Opt.DrawEdges
	If chkSolidDrawVerts.IsInitialized Then chkSolidDrawVerts.Checked = Main.Opt.DrawVerts
	If txtSolidFaceColor.IsInitialized Then txtSolidFaceColor.Text = FormatColor(Main.Opt.FaceColor)
	If pnlSolidFaceColorPreview.IsInitialized Then pnlSolidFaceColorPreview.Color = Main.Opt.FaceColor
	If txtSolidEdgeColor.IsInitialized Then txtSolidEdgeColor.Text = FormatColor(Main.Opt.EdgeColor)
	If pnlSolidEdgeColorPreview.IsInitialized Then pnlSolidEdgeColorPreview.Color = Main.Opt.EdgeColor
	If txtSolidVertexColor.IsInitialized Then txtSolidVertexColor.Text = FormatColor(Main.Opt.VertexColor)
	If pnlSolidVertexColorPreview.IsInitialized Then pnlSolidVertexColorPreview.Color = Main.Opt.VertexColor
	If txtSolidVoidColor.IsInitialized Then txtSolidVoidColor.Text = FormatColor(Main.Opt.VoidColor)
	If pnlSolidVoidColorPreview.IsInitialized Then pnlSolidVoidColorPreview.Color = Main.Opt.VoidColor
	If sldSolidEdgeThickness.IsInitialized Then
		sldSolidEdgeThickness.SetRange(0.5, 10)
		sldSolidEdgeThickness.SetValue(Main.Opt.EdgeThickness, False)
	End If
	If sldSolidVertexSize.IsInitialized Then
		sldSolidVertexSize.SetRange(0.5, 12)
		sldSolidVertexSize.SetValue(Main.Opt.VertexSize, False)
	End If

	If chkWireBackfaceCull.IsInitialized Then chkWireBackfaceCull.Checked = Main.WireOpt.BackfaceCull
	If chkWireUseMaterialColors.IsInitialized Then chkWireUseMaterialColors.Checked = Main.WireOpt.UseMaterialColors
	If chkWireDrawFaces.IsInitialized Then chkWireDrawFaces.Checked = Main.WireOpt.DrawFaces
	If chkWireDrawEdges.IsInitialized Then chkWireDrawEdges.Checked = Main.WireOpt.DrawEdges
	If chkWireDrawVerts.IsInitialized Then chkWireDrawVerts.Checked = Main.WireOpt.DrawVerts
	If chkWireShowModels.IsInitialized Then chkWireShowModels.Checked = Main.WireOpt.ShowModels
	If chkWireShowCamera.IsInitialized Then chkWireShowCamera.Checked = Main.WireOpt.ShowCamera
	If chkWireShowLights.IsInitialized Then chkWireShowLights.Checked = Main.WireOpt.ShowLights
	If chkWireShowAxes.IsInitialized Then chkWireShowAxes.Checked = Main.WireOpt.ShowOriginAxes
	If txtWireFaceColor.IsInitialized Then txtWireFaceColor.Text = FormatColor(Main.WireOpt.FaceColor)
	If pnlWireFaceColorPreview.IsInitialized Then pnlWireFaceColorPreview.Color = Main.WireOpt.FaceColor
	If txtWireEdgeColor.IsInitialized Then txtWireEdgeColor.Text = FormatColor(Main.WireOpt.EdgeColor)
	If pnlWireEdgeColorPreview.IsInitialized Then pnlWireEdgeColorPreview.Color = Main.WireOpt.EdgeColor
	If txtWireVertexColor.IsInitialized Then txtWireVertexColor.Text = FormatColor(Main.WireOpt.VertexColor)
	If pnlWireVertexColorPreview.IsInitialized Then pnlWireVertexColorPreview.Color = Main.WireOpt.VertexColor
	If txtWireVoidColor.IsInitialized Then txtWireVoidColor.Text = FormatColor(Main.WireOpt.VoidColor)
	If pnlWireVoidColorPreview.IsInitialized Then pnlWireVoidColorPreview.Color = Main.WireOpt.VoidColor
	If sldWireEdgeThickness.IsInitialized Then
		sldWireEdgeThickness.SetRange(0.5, 10)
		sldWireEdgeThickness.SetValue(Main.WireOpt.EdgeThickness, False)
	End If
	If sldWireVertexSize.IsInitialized Then
		sldWireVertexSize.SetRange(0.5, 12)
		sldWireVertexSize.SetValue(Main.WireOpt.VertexSize, False)
	End If
	
	If renderResolutionValues.IsInitialized = False Then renderResolutionValues.Initialize2(Array As Object(1.0, 0.75, 0.5, 0.25, 0.1))
	If spnRayResolution.IsInitialized And spnRayResolution.Size > 0 Then
		Dim scale As Double = Main.RaytraceResolutionScale
		Dim bestIdx As Int = 0
		Dim bestDiff As Double = 999
		Dim i As Int
		For i = 0 To renderResolutionValues.Size - 1
			Dim val As Double = renderResolutionValues.Get(i)
			Dim diff As Double = Abs(val - scale)
			If diff < bestDiff Then
				bestDiff = diff
				bestIdx = i
			End If
		Next
		If bestIdx >= 0 And bestIdx < spnRayResolution.Size Then spnRayResolution.SelectedIndex = bestIdx
	End If
	If chkRayUseBVH.IsInitialized Then chkRayUseBVH.Checked = Main.Renderer.UseBVH
	If txtRayBounces.IsInitialized Then txtRayBounces.Text = Main.Renderer.RT_MaxDepth
	If txtRayVoidColor.IsInitialized Then txtRayVoidColor.Text = FormatColor(Main.RaytraceVoidColor)
	If pnlRayVoidColorPreview.IsInitialized Then pnlRayVoidColorPreview.Color = Main.RaytraceVoidColor

	If txtPathSamples.IsInitialized Then txtPathSamples.Text = Main.PathTraceSamples
	If txtPathBounces.IsInitialized Then txtPathBounces.Text = Main.PathTraceBounces
	If txtPathVoidColor.IsInitialized Then txtPathVoidColor.Text = FormatColor(Main.PathTraceVoidColor)
	If pnlPathVoidColorPreview.IsInitialized Then pnlPathVoidColorPreview.Color = Main.PathTraceVoidColor

	renderSettingsUpdating = False

	UpdateSolidSettingsEnabled
	UpdateWireframeSettingsEnabled
	UpdateRenderModePanels(mode)
End Sub

Private Sub UpdateRenderModePanels(mode As Int)
	If spnRenderMode.IsInitialized = False Then Return
	Dim top As Int = spnRenderMode.Top + spnRenderMode.Height + 12dip
	If pnlRenderWire.IsInitialized Then
		pnlRenderWire.Top = top
		pnlRenderWire.Visible = (mode = Main.Renderer.MODE_WIREFRAME)
	End If
	If pnlRenderSolid.IsInitialized Then
		pnlRenderSolid.Top = top
		pnlRenderSolid.Visible = (mode = Main.Renderer.MODE_RASTER)
	End If
	If pnlRenderRay.IsInitialized Then
		pnlRenderRay.Top = top
		pnlRenderRay.Visible = (mode = Main.Renderer.MODE_RAYTRACE)
	End If
	If pnlRenderPath.IsInitialized Then
		pnlRenderPath.Top = top
		pnlRenderPath.Visible = (mode = Main.Renderer.MODE_PATHTRACE)
	End If

	Dim total As Int = top
	If pnlRenderWire.IsInitialized And pnlRenderWire.Visible Then
		total = top + pnlRenderWire.Height
	Else If pnlRenderSolid.IsInitialized And pnlRenderSolid.Visible Then
		total = top + pnlRenderSolid.Height
	Else If pnlRenderRay.IsInitialized And pnlRenderRay.Visible Then
		total = top + pnlRenderRay.Height
	Else If pnlRenderPath.IsInitialized And pnlRenderPath.Visible Then
		total = top + pnlRenderPath.Height
	End If

	If popoverRenderSettings.IsInitialized Then popoverRenderSettings.containerPanel.Panel.Height = total + 12dip
End Sub

Private Sub UpdateSolidSettingsEnabled
	If chkSolidSmoothShading.IsInitialized = False Then Return
	Dim allowExtras As Boolean = Not(chkSolidSmoothShading.Checked)
	If chkSolidDrawFaces.IsInitialized Then chkSolidDrawFaces.Enabled = allowExtras
	If chkSolidDrawEdges.IsInitialized Then chkSolidDrawEdges.Enabled = allowExtras
	If chkSolidDrawVerts.IsInitialized Then chkSolidDrawVerts.Enabled = allowExtras
	If sldSolidEdgeThickness.IsInitialized Then sldSolidEdgeThickness.panelmain.Enabled = allowExtras
	If sldSolidVertexSize.IsInitialized Then sldSolidVertexSize.panelmain.Enabled = allowExtras
	Dim allowFaceColor As Boolean = allowExtras And Not(chkSolidUseMaterialColors.Checked)
	If txtSolidFaceColor.IsInitialized Then txtSolidFaceColor.Enabled = allowFaceColor
	If pnlSolidFaceColorPreview.IsInitialized Then pnlSolidFaceColorPreview.Enabled = allowFaceColor
	If txtSolidEdgeColor.IsInitialized Then txtSolidEdgeColor.Enabled = allowExtras
	If pnlSolidEdgeColorPreview.IsInitialized Then pnlSolidEdgeColorPreview.Enabled = allowExtras
	If txtSolidVertexColor.IsInitialized Then txtSolidVertexColor.Enabled = allowExtras
	If pnlSolidVertexColorPreview.IsInitialized Then pnlSolidVertexColorPreview.Enabled = allowExtras
	If txtSolidVoidColor.IsInitialized Then txtSolidVoidColor.Enabled = True
	If pnlSolidVoidColorPreview.IsInitialized Then pnlSolidVoidColorPreview.Enabled = True
End Sub

Private Sub UpdateWireframeSettingsEnabled
	If chkWireUseMaterialColors.IsInitialized = False Then Return
	Dim allowFaceColor As Boolean = Not(chkWireUseMaterialColors.Checked)
	If txtWireFaceColor.IsInitialized Then txtWireFaceColor.Enabled = allowFaceColor
	If pnlWireFaceColorPreview.IsInitialized Then pnlWireFaceColorPreview.Enabled = allowFaceColor
End Sub

Private Sub FormatColor(col As Int) As String
	Dim hex As String = Bit.ToHexString(Bit.And(col, 0x00FFFFFF))
	Do While hex.Length < 6
		hex = "0" & hex
	Loop
	Return "#" & hex.ToUpperCase
End Sub

Private Sub ParseColorOrNull(value As String) As Object
	Dim cleaned As String = value.Trim
	If cleaned.Length = 0 Then Return Null
	If cleaned.StartsWith("#") Then cleaned = cleaned.SubString(1)
	If cleaned.Length <> 6 Then Return Null
	Try
		Dim r As Int = Bit.ParseInt(cleaned.SubString2(0, 2), 16)
		Dim g As Int = Bit.ParseInt(cleaned.SubString2(2, 4), 16)
		Dim b As Int = Bit.ParseInt(cleaned.SubString2(4, 6), 16)
		Return Colors.ARGB(255, r, g, b)
	Catch
		Return Null
	End Try
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
	btnVisible.textOn = "Visible"
	btnVisible.textOff = "Visible"
	btnVisible.TextSize = 16
	btnVisible.Gravity = Gravity.CENTER
	popoverObjectSettings.containerPanel.Panel.AddView(btnVisible, 0, UI.Bottom(sldReflect.panelmain), popoverObjectSettings.containerPanel.Width, 40dip)

	btnDeleteModel.Initialize("btnDeleteModel")
	btnDeleteModel.Text = "Delete Object"
	btnDeleteModel.TextSize = 16
	btnDeleteModel.TextColor = Colors.White
	btnDeleteModel.Typeface = Typeface.DEFAULT_BOLD
	btnDeleteModel.Background = UI.GetDrawable(Colors.RGB(200, 50, 50), 44dip)
	btnDeleteModel.Gravity = Gravity.CENTER
	popoverObjectSettings.containerPanel.Panel.AddView(btnDeleteModel, 0, UI.Bottom(btnVisible) + SmallSpaceing, popoverObjectSettings.containerPanel.Width, 44dip)

	popoverObjectSettings.containerPanel.Panel.Height = UI.Bottom(btnDeleteModel)
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
	btnDeleteModel.Tag = model
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

Sub build_PopoverPresets
	popoverPresets.Title = "Scene Presets"

	Dim content As Panel = popoverPresets.containerPanel.Panel
	Dim padding As Int = 12dip

	txtPresetName.Initialize("txtPresetName")
	txtPresetName.InputType = txtPresetName.INPUT_TYPE_TEXT
	txtPresetName.SingleLine = True
	txtPresetName.TextSize = 16
	txtPresetName.TextColor = Colors.Black
	txtPresetName.Color = Colors.White
	txtPresetName.Hint = "Preset name"
	content.AddView(txtPresetName, padding, padding, popoverPresets.containerPanel.Width - padding * 2, 40dip)

	btnSavePreset.Initialize("presetSave")
	content.AddView(btnSavePreset, padding, UI.Bottom(txtPresetName) + SmallSpaceing, popoverPresets.containerPanel.Width - padding * 2, 44dip)
	btnSavePreset.Text = "💾 Save Current Scene"
	btnSavePreset.Typeface = Typeface.DEFAULT_BOLD
	btnSavePreset.TextSize = 16
	btnSavePreset.TextColor = Colors.White
	btnSavePreset.Gravity = Gravity.CENTER
	btnSavePreset.Background = UI.GetDrawable(Colors.RGB(0, 122, 255), btnSavePreset.Height)

	presetsListPanel.Initialize("")
	content.AddView(presetsListPanel, 0, UI.Bottom(btnSavePreset) + BigSpaceing, popoverPresets.containerPanel.Width, 0)
	refreshPresetsPopover
End Sub

Public Sub refreshPresetsPopover
	If popoverPresets.IsInitialized = False Then 
		Log("popover no init")
		Return
	End If
	Dim container As Panel = presetsListPanel
	container.RemoveAllViews
	Dim top As Int = 0
	Dim rowHeight As Int = 52dip
	Dim buttonWidth As Int = 74dip
	Dim buttonHeight As Int = 36dip
	Dim spacing As Int = 8dip
	Dim paddingRight As Int = 12dip

	Dim presets As List = CallSub(Main, "ListScenePresets")
	If Not(presets.IsInitialized) Then
		Return
	End If
	Dim highlightName As String = Main.CurrentScenePresetName
	If highlightName = Null Then highlightName = ""
	Dim highlight As Boolean = Main.ScenePresetLoaded And highlightName.Length > 0

	For Each presetName As String In presets
		
		Dim row As Panel
		row.Initialize("")
		container.AddView(row, 0, top, popoverPresets.containerPanel.Width, rowHeight)
		If highlight And presetName.ToLowerCase = highlightName.ToLowerCase Then
			row.Color = Colors.RGB(220, 235, 255)
		Else
			row.Color = Colors.White
		End If

		Dim deleteLeft As Int = row.Width - paddingRight - buttonWidth
		Dim loadLeft As Int = deleteLeft - spacing - buttonWidth

		Dim lbl As Label
		lbl.Initialize("")
		lbl.Text = presetName
		lbl.TextColor = Colors.Black
		lbl.TextSize = 16
		lbl.Typeface = Typeface.DEFAULT_BOLD
		lbl.Gravity = Gravity.CENTER_VERTICAL
		Dim labelWidth As Int = loadLeft - 16dip
		If labelWidth < 0 Then labelWidth = row.Width - 32dip
		row.AddView(lbl, 16dip, 0, labelWidth, rowHeight)

		Dim btnLoad As Button
		btnLoad.Initialize("presetLoad")
		btnLoad.Tag = presetName
		row.AddView(btnLoad, loadLeft, (rowHeight - buttonHeight) / 2, buttonWidth, buttonHeight)
		btnLoad.Text = "Load"
		btnLoad.TextSize = 14
		btnLoad.Typeface = Typeface.DEFAULT_BOLD
		btnLoad.TextColor = Colors.White
		btnLoad.Background = UI.GetDrawable(Colors.RGB(76, 175, 80), buttonHeight)

		Dim btnDelete As Button
		btnDelete.Initialize("presetDelete")
		btnDelete.Tag = presetName
		row.AddView(btnDelete, deleteLeft, (rowHeight - buttonHeight) / 2, buttonWidth, buttonHeight)
		btnDelete.Text = "Delete"
		btnDelete.TextSize = 14
		btnDelete.Typeface = Typeface.DEFAULT_BOLD
		btnDelete.TextColor = Colors.White
		btnDelete.Background = UI.GetDrawable(Colors.RGB(244, 67, 54), buttonHeight)

		top = top + rowHeight + 2dip
	Next

	If presets.Size > 0 Then top = top - 2dip

	If presets.Size = 0 Then
		Dim emptyLabel As Label
		emptyLabel.Initialize("")
		emptyLabel.Text = "No presets saved yet."
		emptyLabel.TextColor = Colors.Gray
		emptyLabel.Gravity = Gravity.CENTER
		emptyLabel.TextSize = 14
		container.AddView(emptyLabel, 0, top, popoverPresets.containerPanel.Width, 40dip)
		top = top + 40dip
	End If

	If Main.ScenePresetLoaded And highlightName.Length > 0 Then
		txtPresetName.Text = Main.CurrentScenePresetName
	Else
		txtPresetName.Text = ""
	End If

	If top < 0 Then top = 0
	container.Height = top
	popoverPresets.containerPanel.Panel.Height = presetsListPanel.Top + container.Height + 12dip
End Sub
