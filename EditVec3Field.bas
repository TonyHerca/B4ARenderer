B4A=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=13.4
@EndOfDesignText@
Sub Class_Globals
	Public panelmain As Panel
	
	Public lblTitle As Label
	
	Public lblX As Label
	Public lblY As Label
	Public lblZ As Label
	Public edtX As EditText
	Public edtY As EditText
	Public edtZ As EditText
	
	Public btnApply As CustomButton
	
	Public Callback As Object
	Public EventName As String
End Sub

'Initializes the object. You can add parameters to this method if needed.
Public Sub Initialize(cb As Object, event As String)
	Callback = cb
	EventName = event
	
	panelmain.Initialize("")
	
	lblTitle.initialize("")
	lblX.initialize("")
	lblY.initialize("")
	lblZ.initialize("")
	edtX.initialize("")
	edtY.initialize("")
	edtZ.initialize("")
	
	btnApply.initialize(Me, "btnApply")
	
End Sub

Public Sub AddToParent(parent As Panel, left As Int, top As Int, width As Int)
	Dim spacing As Int = 5dip
	
	parent.AddView(panelmain, left, top, width, 100dip)
	panelmain.AddView(lblTitle, spacing, spacing, panelmain.Width/3, 30dip)
	lblTitle.Text = "Title text"	
	lblTitle.Typeface = Typeface.DEFAULT_BOLD
	lblTitle.TextSize = 20
	
	Dim startLeft As Int = panelmain.Width/2
	panelmain.AddView(lblX, startLeft, spacing, 25dip, 25dip)
	panelmain.AddView(lblY, startLeft, spacing + UI.Bottom(lblX), 25dip, 25dip)
	panelmain.AddView(lblZ, startLeft, spacing + UI.Bottom(lblY), 25dip, 25dip)
	
	panelmain.AddView(edtX, UI.Right(lblX) + 5dip, spacing, panelmain.Width - (UI.Right(lblX) + 10dip) , 25dip)
	panelmain.AddView(edtY, UI.Right(lblY) + 5dip, spacing + UI.Bottom(lblX), panelmain.Width - (UI.Right(lblY) + 10dip), 25dip)
	panelmain.AddView(edtZ, UI.Right(lblZ) + 5dip, spacing + UI.Bottom(lblY), panelmain.Width - (UI.Right(lblZ) + 10dip), 25dip)
	lblX.Text = "X" : edtX.Text = "0"
	lblY.Text = "Y" : edtY.Text = "0" 
	lblZ.Text = "Z" : edtZ.Text = "0"
	
	
	edtY.Padding = Array As Int(2dip, 0, 0, 0)
	edtZ.Padding = Array As Int(2dip, 0, 0, 0)
	
	edtX.Background = UI.GetDrawableWithBorder(Colors.White, edtX.Height/6, 1dip, Colors.LightGray)
	edtY.Background = UI.GetDrawableWithBorder(Colors.White, edtY.Height/6, 1dip, Colors.LightGray)
	edtZ.Background = UI.GetDrawableWithBorder(Colors.White, edtZ.Height/6, 1dip, Colors.LightGray)
	
	lblX.Gravity = Gravity.CENTER : lblX.Typeface = Typeface.DEFAULT_BOLD : edtX.InputType = edtX.INPUT_TYPE_NUMBERS : edtX.Padding = Array As Int(2dip, 0, 0, 0)
	lblY.Gravity = Gravity.CENTER : lblY.Typeface = Typeface.DEFAULT_BOLD : edtY.InputType = edtY.INPUT_TYPE_NUMBERS : edtY.Padding = Array As Int(2dip, 0, 0, 0)
	lblZ.Gravity = Gravity.CENTER : lblZ.Typeface = Typeface.DEFAULT_BOLD : edtZ.InputType = edtZ.INPUT_TYPE_NUMBERS : edtZ.Padding = Array As Int(2dip, 0, 0, 0)
	
	btnApply.AddToParent(panelmain, spacing, panelmain.Height - 40dip - spacing)
	btnApply.BackgroundColor = Colors.White : btnApply.BorderColor = Colors.LightGray
	btnApply.TextColor = Colors.Black : btnApply.Text = "Apply"
	btnApply.BorderSize = 1dip : btnApply.PressColor = Colors.LightGray
'	
	panelmain.Color = Colors.white
	
End Sub

public Sub btnApply_Click
	If SubExists(Callback, EventName) Then
		CallSub2(Callback, EventName, Math3D.V3(edtX.Text, edtY.Text, edtZ.Text))
	End If
End Sub

public Sub SetVectorValues(v3 As Vec3)
	edtX.Text = v3.X
	edtY.Text = v3.Y
	edtZ.Text = v3.Z
End Sub

public Sub setTitle(str As String)
	lblTitle.text = str
End Sub