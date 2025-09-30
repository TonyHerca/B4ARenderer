B4A=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=13.4
@EndOfDesignText@
Sub Class_Globals
	Public panelmain As Panel
	Public backgroundPanel As Panel
	
	Public popoverPanel As Panel
	Public header As Panel
	Public handlePanel As Panel
	Public namelabel As Label
	
	Public containerPanel As ScrollView
	
	Dim gdHandle As GestureDetector
	
	Dim animSpeed As Int = 170
End Sub

'Initializes the object. You can add parameters to this method if needed.
Public Sub Initialize
	panelmain.Initialize("")
	backgroundPanel.Initialize("bg")
	popoverPanel.Initialize("")
	header.Initialize("header")
	handlePanel.Initialize("")
	namelabel.Initialize("")
	containerPanel.Initialize2(0, "sv")
	
	gdHandle.SetOnGestureListener(header, "gd")
End Sub

'popoverPanel has 3 states 
' --- Hidden
' --- Half Extended
' --- Fully extended

public Sub addToParent(parent As Panel)
	parent.AddView(panelmain, 0, 0, parent.Width, parent.Height)
	
	panelmain.AddView(backgroundPanel, 0, 0, panelmain.Width, panelmain.Height)
	panelmain.AddView(popoverPanel, 0, 100%y, panelmain.Width, panelmain.Height)
	
	popoverPanel.AddView(header, 0, 0, popoverPanel.Width, 7%y)
	
	header.AddView(handlePanel, 50%x - 8%x, 1%y, 16%x, 0.5%y)
	header.AddView(namelabel, 0, 3%y, popoverPanel.Width, 24dip)
	
	popoverPanel.AddView(containerPanel, 0, header.Height, popoverPanel.Width, popoverPanel.Height/2 - header.Height)
	
	popoverPanel.Background = UI.GetDrawable(Colors.White, popoverPanel.Height*0.03)
	
	handlePanel.Background = UI.GetDrawable(Colors.Black, handlePanel.Height)
	namelabel.Gravity = Gravity.CENTER
	namelabel.TextSize = 20
	namelabel.Typeface = Typeface.DEFAULT_BOLD
	
	panelmain.Visible = False
End Sub

'full extend state = 0
'half extend state = 1
public Sub setContainerState(state As Int)
'	full extend = popoverPanel.height - header.height
'	half extend = popoverPanel.height/2 - header.height
	Select state
		Case 0 
			containerPanel.Height = popoverPanel.height - header.height
		Case 1
			containerPanel.Height = popoverPanel.height/2 - header.height
	End Select
End Sub

public Sub gd_onDrag(deltaX As Float, deltaY As Float, MotionEvent As Object)
	'todo For not extended height is disabled
	
	popoverPanel.Top = popoverPanel.Top + deltaY
	If popoverPanel.Top < 50%y Then
		popoverPanel.Top = 50%y
	End If
'	If popoverPanel.Top <= 50%y Then
'		setContainerState(0)
'	Else
'		setContainerState(1)
'	End If
End Sub

public Sub gd_onTouch(Action As Int, X As Float, Y As Float, MotionEvent As Object) As Boolean
	
	
	'todo fling event
	If Action = gdHandle.ACTION_UP Then
		If popoverPanel.Top > 75%y Then
			popoverPanel.SetLayoutAnimated(animSpeed, popoverPanel.Left, 100%y, popoverPanel.Width, popoverPanel.Height)
			CallDelayed(animSpeed, "HidePanel")
			
		else if popoverPanel.Top <= 75%y And popoverPanel.Top >= 25%y Then
			popoverPanel.SetLayoutAnimated(animSpeed, popoverPanel.Left, 50%y, popoverPanel.Width, popoverPanel.Height)
'			
'		else if popoverPanel.Top < 25%y Then
'			popoverPanel.SetLayoutAnimated(animSpeed, popoverPanel.Left, 0, popoverPanel.Width, popoverPanel.Height)
		End If
	End If
	
	Return True
End Sub

public Sub CallDelayed(after As Int, toCall As String)
	Sleep(after)
	CallSub(Me, toCall)
End Sub

public Sub HidePanel
	panelmain.Visible = False
End Sub

public Sub ShowPanel
	popoverPanel.Top = 100%y
	panelmain.Visible = True
	popoverPanel.SetLayoutAnimated(animSpeed, popoverPanel.Left, 50%y, popoverPanel.Width, popoverPanel.Height)
End Sub

public Sub bg_Touch (Action As Int, X As Float, Y As Float)
	backgroundPanel.Enabled = False
	popoverPanel.SetLayoutAnimated(animSpeed, popoverPanel.Left, 100%y, popoverPanel.Width, popoverPanel.Height)
	Sleep(animSpeed)
	panelmain.Visible = False
	backgroundPanel.Enabled = True
	
End Sub

public Sub setTitle(str As String)
	namelabel.Text = str
End Sub
