B4A=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=13
@EndOfDesignText@
Sub Class_Globals
	Public panelmain As Panel
	
	Private CallBack As Object
	Private EventName As String

'	modes => multiple toggle 



'	 	  => single toggle
'	could return referance to button back to callback when being added 
	
	'
	Dim BTNList As List
	
	Dim Rounding As Int = 50dip
	Dim TextColor As Int = Colors.White
	Dim buttonColor As Int = Colors.black
'	Dim outlineColor As Int = 0xFFE8DEF8
	Dim outlineColor As Int = 0xFFF9F1E0
	Dim SelectedColor As Int = 0xFF5A4A2C
	
	Dim outlineThickness As Int = 1.5dip
	
	Dim ToggleMode As Int = 1
	Dim MODE_MultipleSelect = 1 As Int
	Dim MODE_SingleSelect = 2 as int
	
		
	Private BT_OUTLINE_COLOR As Int = 0xFFE8DEF8
	Private BT_COLOR_RIPPLE As Int = 0x41FFFFFF
	Private BT_COLOR_DR1 As Int = 0xff53475E
End Sub


Public Sub Initialize(callb As Object, event As String)
	CallBack = callb
	EventName = event
	panelmain.Initialize("mainPnl")
	BTNList.Initialize
	SetupThemeColors
End Sub

Public Sub AddToParent(parent As Panel, l As Int, t As Int, w As Int, h As Int)
	
	parent.AddView(panelmain, l, t, w, h)
'	panelmain.Color = Colors.Blue
	BuildView' diff system
End Sub


private Sub SetupThemeColors
	BT_OUTLINE_COLOR = 0xFFE8DEF8
	BT_COLOR_RIPPLE = 0x41FFFFFF
End Sub

public Sub AddButton(label As String, State As String)

	Dim mapButtonInfo As Map
	mapButtonInfo.Initialize
	mapButtonInfo.Put("Name", label)
	mapButtonInfo.Put("State", State)
	mapButtonInfo.Put("Position", BTNList.Size)
	
	BTNList.Add(mapButtonInfo)
	
	BuildView
End Sub

public Sub BuildView
	If BTNList.Size = 0 Then Return
	panelmain.RemoveAllViews
	Dim buttonWidth As Int = panelmain.Width/BTNList.Size
	Dim iteration As Int = 0
	
	For Each ButtonInfo As Map In BTNList
		
		Dim btn As Button
		btn.Initialize("button")
		
		panelmain.AddView(btn, (buttonWidth*iteration) - outlineThickness*iteration, 0, buttonWidth, panelmain.Height)
		btn.Padding = Array As Int(0, 0, 0, 0)
		btn.Text = ButtonInfo.Get("Name")
		btn.TextColor = TextColor
		btn.TextSize = 16
		
		Dim cd As ColorDrawable
		Dim ripple As RippleDrawable
		
		If ButtonInfo.Get("State") = "OFF" Then
'			
			cd.Initialize2(Colors.Black, Rounding, outlineThickness, BT_OUTLINE_COLOR)
			SetCornerRounding(cd, ButtonInfo.Get("Position"))
			ripple.Initialize2(cd, BT_COLOR_RIPPLE)
			btn.Background = ripple.Drawable
		Else
			cd.Initialize2(BT_COLOR_DR1, Rounding, outlineThickness, BT_OUTLINE_COLOR)
			SetCornerRounding(cd, ButtonInfo.Get("Position"))
			ripple.Initialize2(cd, BT_COLOR_RIPPLE)
			btn.Background = ripple.Drawable
			
		End If
	
		btn.Tag = ButtonInfo
		
		iteration = iteration + 1
	Next
End Sub

private Sub SetCornerRounding(cd As ColorDrawable, iteration As Int)
	If BTNList.Size = 1 Then
		setRoundedCorners(cd, Rounding, Rounding, Rounding, Rounding)
	else if iteration = 0 Then
		setRoundedCorners(cd, Rounding, 0, 0, Rounding)
	else if iteration = BTNList.Size - 1 Then
		setRoundedCorners(cd, 0, Rounding, Rounding, 0)
	Else
		setRoundedCorners(cd, 0, 0, 0, 0)
	End If
	
End Sub

Public Sub asview As Panel
	Return panelmain
End Sub

public Sub DestroyView
	panelmain.RemoveAllViews
	panelmain.RemoveView
End Sub

public Sub Show(vis As Boolean)
	If (panelmain.Visible = vis) Then Return
	panelmain.Visible = vis
End Sub

public Sub getLeft As Int
	Return panelmain.Left
End Sub

public Sub getTop As Int
	Return panelmain.Top
End Sub

public Sub getWidth As Int
	Return panelmain.Width
End Sub

public Sub getHeight As Int
	Return panelmain.Height
End Sub

public Sub setLeft (Val As Int)
	panelmain.Left = Val
End Sub

public Sub setTop (Val As Int)
	panelmain.Top = Val
End Sub

public Sub setWidth (val As Int)
	panelmain.Width = val
End Sub

public Sub setHeight (val As Int)
	panelmain.Height = val
End Sub


public Sub setRoundedCorners(cd As ColorDrawable, tl As Int, tr As Int, br As Int, bl As Int)
	Dim jo As JavaObject = cd
	jo.RunMethod("setCornerRadii", Array(Array As Float(tl, tl, tr, tr, br, br, bl, bl)))
End Sub


public Sub button_click
	Dim btn As Button = Sender
	Dim btnInfo As Map = btn.Tag
	Dim cd As ColorDrawable
	Dim ripple As RippleDrawable
	
	If ToggleMode = MODE_MultipleSelect Then
		If btnInfo.Get("State") = "OFF" Then
'			Dim cd As ColorDrawable
'			Dim ripple As RippleDrawable
			
			btn.Tag.As(Map).Put("State", "ON")
			cd.Initialize2(BT_COLOR_DR1, Rounding, outlineThickness, BT_OUTLINE_COLOR)
			SetCornerRounding(cd, btnInfo.Get("Position"))
			ripple.Initialize2(cd, BT_COLOR_RIPPLE)
			btn.Background = ripple.Drawable
		Else
'			Dim cd As ColorDrawable
'			Dim ripple As RippleDrawable
			
			btn.Tag.As(Map).Put("State", "OFF")
			cd.Initialize2(Colors.Black, Rounding, outlineThickness, BT_OUTLINE_COLOR)
			SetCornerRounding(cd, btnInfo.Get("Position"))
			ripple.Initialize2(cd, BT_COLOR_RIPPLE)
			btn.Background = ripple.Drawable
		End If
	else if  ToggleMode = MODE_SingleSelect Then
		If btnInfo.Get("State") = "OFF" Then
			
			For Each btnOther As Button In panelmain.GetAllViewsRecursive
				Dim btnOtherInfo As Map = btnOther.Tag
				If btnOtherInfo.Get("Position") <> btnInfo.Get("Position") Then
					Dim cd As ColorDrawable
					Dim ripple As RippleDrawable
					
					btnOther.Tag.As(Map).Put("State", "OFF")
					cd.Initialize2(Colors.Black, Rounding, outlineThickness, BT_OUTLINE_COLOR)
					SetCornerRounding(cd, btnOtherInfo.Get("Position"))
					ripple.Initialize2(cd, BT_COLOR_RIPPLE)
			
					btnOther.Background = ripple.Drawable
				End If
			Next
		
			btn.Tag.As(Map).Put("State", "ON")
			cd.Initialize2(BT_COLOR_DR1, Rounding, outlineThickness, BT_OUTLINE_COLOR)
			SetCornerRounding(cd, btnInfo.Get("Position"))
			ripple.Initialize2(cd, BT_COLOR_RIPPLE)
			btn.Background = ripple.Drawable
			
			If SubExists(CallBack, EventName&"_ActiveChanged") Then
				CallSub2(CallBack, EventName&"_ActiveChanged", btnInfo.Get("Position"))
			End If
		Else
			''
			If SubExists(CallBack, EventName&"_ActiveChanged") Then
				CallSub2(CallBack, EventName&"_ActiveChanged", btnInfo.Get("Position"))
			End If
'			
'			btn.Tag.As(Map).Put("State", "OFF")
'			cd.Initialize2(Colors.Black, Rounding, outlineThickness, BT_OUTLINE_COLOR)
'			SetCornerRounding(cd, btnInfo.Get("Position"))
'			ripple.Initialize2(cd, BT_COLOR_RIPPLE)
'			btn.Background = ripple.Drawable
		End If
		
		
	End If
End Sub

Public Sub getActiveButtons As Int
'	IF MULTIPLE CAN BE SELECTER
'	Dim ActiveList As List
'	ActiveList.Initialize
'	For Each btn As View In panelmain.GetAllViewsRecursive
'		If btn Is Button Then
'			Dim btnInfo As Map = btn.tag
'			If btnInfo.Get("State") = "ON" Then
'				ActiveList.Add(btnInfo.Get("Position"))
'			End If
'		End If
'	Next
'	Return ActiveList

	' IF ONLY ONE CAN BE SELECTED
	For Each btn As View In panelmain.GetAllViewsRecursive
		If btn Is Button Then
			Dim btnInfo As Map = btn.tag
			If btnInfo.Get("State") = "ON" Then
				Return btnInfo.Get("Position")
			End If
		End If
	Next
	Return -1
End Sub