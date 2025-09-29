B4A=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=13
@EndOfDesignText@
Sub Class_Globals
	Private panelmain As Panel
	Private lblText As Label
	Private lblIcon As Label
	Private btn As Button
	
	Private CallBack As Object
	Private EventName As String
	
	Private parentPanel As Panel
	
	Private ripple As RippleDrawable
	
	Private BgColor As Int = Colors.RGB(26,26,26)
	Private iPressColor As Int = 0x34FFFFFF
	
	'Border
	Private iBorderColor As Int = Colors.Gray
	Private iBorderRadius As Int = 20dip
	Private iBorderSize As Int = 2dip
	
	'Text
	Private fTextSize As Float = 16
	Private tfTextTypeFace As Typeface = Typeface.DEFAULT
	Private iTextColor As Int = Colors.White
	
	'Icon
	Private fIconSize As Float = 24
	Private tfIconTypeFace As Typeface = Typeface.MATERIALICONS
	Private iIconColor As Int = Colors.White
	
	'
	Private Spacing As Int = 24dip
End Sub

Public Sub Initialize(callb As Object, event As String)
	
	CallBack = callb
	EventName = event

	panelmain.Initialize("mainPnl")
	
	lblText.Initialize("")
	lblIcon.Initialize("")
	btn.Initialize("btn")
End Sub

Public Sub AddToParent(parent As Panel, l As Int, t As Int)
	parentPanel = parent
	
	parent.AddView(panelmain, l, t, 120dip, 40dip)
	
	BuildView
	
	ApplyStyle
End Sub

public Sub BuildView
	panelmain.AddView(btn, 0, 0, panelmain.Width, panelmain.Height)
	panelmain.AddView(lblText, 0, 0, panelmain.Width, panelmain.Height)
	panelmain.AddView(lblIcon, 0, -5dip, 50dip, 50dip)
'	18dip is height
'	40dip view height

	
	
'	icon center = X = 25dip
End Sub


public Sub ApplyStyle
	lblText.Typeface = tfTextTypeFace
	lblText.TextColor = iTextColor
	lblText.TextSize = fTextSize
	lblText.Text = "Button"
	lblText.Gravity = Gravity.CENTER
	
	lblIcon.Typeface = tfIconTypeFace
	lblIcon.TextColor = iIconColor
	lblIcon.TextSize = fIconSize
	lblIcon.Text = Chr(0xE145)
	lblIcon.Gravity = Gravity.CENTER
	lblIcon.Visible = False
	
	
	
	SetElevation(btn, 0)
	SetElevation(lblText, 1)
	SetElevation(lblIcon, 1)
	DrawView
	
End Sub

Private Sub mainPnl_Click
	'phantom click
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

public Sub ReadjustViews
	Private textWid As Int = MeasureTextWidth(lblText.Text, lblText.TextSize, lblText.Typeface)
	
	If lblIcon.Visible And Not(lblText.Visible) Then 
		panelmain.Width = panelmain.Height
		lblIcon.Left = panelmain.Width/2 - lblIcon.Width/2
		
	else if Not(lblIcon.Visible) And lblText.Visible Then
		panelmain.Width = textWid + Spacing*2
		lblText.Left = Spacing
	else if lblIcon.Visible And lblText.Visible Then
		panelmain.Width = textWid + Spacing*2 + 18dip
		lblText.Left = Spacing + 18dip
		lblIcon.Left = 25dip - lblIcon.Width/2
	Else 
		panelmain.Width = panelmain.Height
	End If
	
	btn.Width = panelmain.Width
	lblText.Width = textWid
End Sub

public Sub DrawView
	Private cd As ColorDrawable
	cd.Initialize2(BgColor, iBorderRadius, iBorderSize, iBorderColor)
	ripple.Initialize2(cd, iPressColor)
	
	btn.Background = ripple.Drawable
	
End Sub

' Background Color
Public Sub getBackgroundColor As Int
	Return BgColor
End Sub

Public Sub setBackgroundColor(color As Int)
	BgColor = color
	DrawView
End Sub

' Press Color
Public Sub getPressColor As Int
	Return iPressColor
End Sub

Public Sub setPressColor(color As Int)
	iPressColor = color
	ripple.ChangePressedColor(color)
End Sub

' Border
Public Sub getBorderColor As Int
	Return iBorderColor
End Sub

Public Sub setBorderColor(color As Int)
	iBorderColor = color
	DrawView
End Sub

Public Sub getBorderRadius As Int
	Return iBorderRadius
End Sub

Public Sub setBorderRadius(radius As Int)
	iBorderRadius = radius
	DrawView
End Sub

Public Sub getBorderSize As Int
	Return iBorderSize
End Sub

Public Sub setBorderSize(size As Int)
	iBorderSize = size
	DrawView
End Sub

' Text
Public Sub getText As String
	Return lblText.Text
End Sub

Public Sub setText(text As String)
	lblText.Text = text
	ReadjustViews
End Sub

Public Sub getTextSize As Float
	Return fTextSize
End Sub

Public Sub setTextSize(size As Float)
	fTextSize = size
	lblText.TextSize = size
End Sub

Public Sub getTextTypeface As Typeface
	Return tfTextTypeFace
End Sub

Public Sub setTextTypeface(tf As Typeface)
	tfTextTypeFace = tf
	lblText.Typeface = tf
End Sub

Public Sub getTextColor As Int
	Return iTextColor
End Sub

Public Sub setTextColor(color As Int)
	iTextColor = color
	lblText.TextColor = color
End Sub

Public Sub getTextVisible As Boolean
	Return lblText.Visible
End Sub

Public Sub setTextVisible(vis As Boolean)
	lblText.Visible = vis
	ReadjustViews
End Sub

' Icon
Public Sub getIcon As String
	Return lblIcon.Text
End Sub

Public Sub setIcon(icon As String)
	lblIcon.Text = icon
	ReadjustViews
End Sub

Public Sub getIconSize As Float
	Return fIconSize
End Sub

Public Sub setIconSize(size As Float)
	fIconSize = size
	lblIcon.TextSize = size
End Sub

Public Sub getIconTypeface As Typeface
	Return tfIconTypeFace
End Sub

Public Sub setIconTypeface(tf As Typeface)
	tfIconTypeFace = tf
	lblIcon.Typeface = Typeface
End Sub

Public Sub getIconColor As Int
	Return iIconColor
End Sub

Public Sub setIconColor(color As Int)
	iIconColor = color
	lblIcon.TextColor = color
End Sub

Public Sub getIconVisible As Boolean
	Return lblIcon.Visible
End Sub

Public Sub setIconVisible(vis As Boolean)
	lblIcon.Visible = vis
	ReadjustViews
End Sub

Private Sub SetElevation(view As View, Elevation As Float)
	Private jo As JavaObject
	Private sdk As Phone
	jo = view
	If sdk.SdkVersion > 20 Then
		Private f As Float = Elevation
		jo.RunMethod("setElevation",Array As Object(f))
		jo.RunMethod("setStateListAnimator", Array(Null))
	End If
End Sub

Public Sub MeasureTextWidth(Text As String, Font1 As Float, tf As Typeface) As Int
	Private bmp As Bitmap
	bmp.InitializeMutable(2dip, 2dip)
	Private cvs As Canvas
	cvs.Initialize2(bmp)
	Return cvs.MeasureStringWidth(Text, tf, Font1)
End Sub

Private Sub btn_Click
	If SubExists(CallBack, $"${EventName}_Click"$) Then CallSub(CallBack, $"${EventName}_Click"$)
End Sub

Private Sub btn_LongClick
	If SubExists(CallBack, $"${EventName}_LongClick"$) Then CallSub(CallBack, $"${EventName}_LongClick"$)
End Sub



