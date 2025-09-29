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
	Dim popoverObjectsSettings As PopoverPanelView
	
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

	Dim sldCameraTurnSpeed As SliderView = AddSliderToPopover(popoverCamSettings, "sldCamMoveSpeed")
'	sldCameraMoveSpeed.SetValue(Main.Scene.Camera.TurnSpeed, False)
	Dim sldCameraMoveSpeed As SliderView = AddSliderToPopover(popoverCamSettings, "sldCamMoveSpeed")
'	sldCameraMoveSpeed.SetValue(Main.Scene.Camera.MoveSpeed, True)
	Dim sldCameraFOV As SliderView = AddSliderToPopover(popoverCamSettings, "sldCamFov")
'	sldCameraFOV.SetValue(Main.Scene.Camera.FOV_Deg.As(Float), True)

	popoverObjectsSettings = CreatePopover("objectSettings")

	'render settings
'	popoverRenderSettings = CreatePopover("asd")
'	popoverRenderSettings.Title = "Viewport Settings"
'	Dim ToggleRenderMode As ButtonToggle
'	ToggleRenderMode.Initialize(Me, "togRenderMode")
'	ToggleRenderMode.AddButton("Wireframe", "OFF")
'	ToggleRenderMode.AddButton("Solid", "ON")
'	ToggleRenderMode.AddButton("Shaded", "OFF")
'	ToggleRenderMode.AddToParent(popoverRenderSettings.containerPanel.Panel, 5%x, 2%y, 90%x, 5%y)
'	popoverRenderSettings.containerPanel.Panel.Height = UI.Bottom(ToggleRenderMode.panelmain)

	Dim btnCameraSettings As Button
	btnCameraSettings.Initialize("CamSettings")
	panelmain.AddView(btnCameraSettings, 4dip, 4dip, 10%x, 10%x)
	btnCameraSettings.Background = UI.GetDrawable(Colors.White, btnCameraSettings.Height)
	btnCameraSettings.Text = "C" ' todo make panel with button and label and camera icon
	btnCameraSettings.Padding = Array As Int(0, 0, 0, 0)
	btnCameraSettings.TextSize = 30
	btnCameraSettings.Typeface = Typeface.DEFAULT_BOLD
	
	
	Dim btnRenderWire As Button
	btnRenderWire.Initialize("RenderWire")
	panelmain.AddView(btnRenderWire, UI.Right(btnCameraSettings) + 4dip, 4dip, 10%x, 10%x)
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
	
'	btnChangeRanderMode.Initialize("btnChange")
'	Dim btnwid As Int = joystickLook.pnl.left - UI.Right(joystickMove.pnl) - BigSpaceing*2
'	
'	panelmain.AddView(btnChangeRanderMode, UI.Right(joystickMove.pnl) + BigSpaceing, joystickMove.pnl.Top, btnwid, joystickMove.pnl.Height)
'	btnChangeRanderMode.Tag = 0
	
End Sub

Public Sub CamSettings_click
	If Not(popoverCamSettings.panelmain.Visible) Then
		popoverCamSettings.ShowPanel
	End If
	
End Sub

Sub btnChange_Click

	If Main.Timer.Enabled Then
		Main.Timer.Enabled = False
		CallSub(Main, "btnRaytrace_Click")
	Else 
		Main.Timer.Enabled = True
	End If
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
	If Not(popoverObjectsSettings.panelmain.Visible) Then
		popoverObjectsSettings.ShowPanel
	End If
End Sub

Sub RenderSolid_Click
	Main.Renderer.setRenderMode(0)
	CallSub(Main, "resetTimer")
End Sub

Sub RenderShaded_Click
	Main.Renderer.setRenderMode(1)
	CallSub(Main, "resetTimer")
	
'	CallSub(Main, "renderRaytraced")
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
	
	
	Log(popover.containerPanel.Panel.Height)
	Return newModelbar
End Sub

public Sub refreshObjectPopover
	popoverObjectsSettings.containerPanel.Panel.RemoveAllViews
	For Each obj As cModel In Main.Scene.Models
		Dim model As ModelBar = AddModelBarToPopover(popoverObjectsSettings, "objSettings")
		model.Title = obj.mesh.Name
		model.Tag = obj
	Next
End Sub

public Sub objSettings_VisibilityChanged(visible As Boolean)
	Dim modelB As ModelBar = Sender
	modelB.Tag.As(cModel).Visible = visible
	CallSub(Main, "resetTimer")
End Sub