B4A=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=13.4
@EndOfDesignText@
' Class module: SceneItemRow
' A row for ScrollView: [ Label (left) | ... | Settings | Eye(Open/Closed) ]
' No Designer. No external libs required.

Sub Class_Globals
	' Public root view (add this to a ScrollView.Panel)
	Public panelmain As Panel

	' Children
	Private LblName As Label
	Private BtnSettings As ImageView
	Private BtnEye As ImageView
	Private ImgType As ImageView

	' Fallback text “icons” if bitmaps not provided
	Private FallbackSettings As Label
	Private FallbackEye As Label
	Private FallbackType As Label

	' Layout metrics
	Private Pad As Int = 10dip
	Private IconSize As Int = 22dip
	Private TypeIconSize As Int = 22dip
	Private RowHeight As Int = 48dip
	Private Gap As Int = 8dip

	' State
	Private mTitle As String
	Private mShown As Boolean = True
	Public Tag As Object
	Private ToggleEnabled As Boolean = True

	' Optional bitmaps for nicer icons
	Private BmpSettings As Bitmap
	Private BmpEyeOpen As Bitmap
	Private BmpEyeClosed As Bitmap
	Private BmpType As Bitmap
	' Colors
	Private ColorBg As Int = Colors.White
	Private ColorText As Int = Colors.Black
	Private ColorHint As Int = Colors.RGB(180,180,180)
	Private ColorPressed As Int = Colors.RGB(45,47,53)
	
	Dim callback As Object
	Dim eventname As String
	Private TypeIconText As String = ""
End Sub

Public Sub Initialize(cb As Object, event As String)
	
	callback = cb
	eventname = event
	
	panelmain.Initialize("row")
	panelmain.Color = ColorBg

	' Label
	LblName.Initialize("lbl")
	LblName.TextColor = ColorText
	LblName.TextSize = 16
	LblName.Gravity = Gravity.CENTER_VERTICAL
	panelmain.AddView(LblName, 0, 0, 0, 0)
	LblName.Typeface = Typeface.DEFAULT_BOLD

	' Icon imageviews (may remain empty if we use fallback text)
	BtnSettings.Initialize("btnSettings")
	BtnEye.Initialize("btnEye")
	ImgType.Initialize("")
	panelmain.AddView(BtnSettings, 0, 0, IconSize, IconSize)
	panelmain.AddView(BtnEye, 0, 0, IconSize, IconSize)
	panelmain.AddView(ImgType, 0, 0, TypeIconSize, TypeIconSize)

	' Fallback text icons (hidden when bitmaps are set)
	FallbackSettings.Initialize("btnSettings")
	FallbackSettings.Text = "⚙"
	FallbackSettings.TextSize = 18
	FallbackSettings.TextColor = ColorHint
	FallbackSettings.Gravity = Gravity.CENTER
	panelmain.AddView(FallbackSettings, 0, 0, IconSize, IconSize)

	FallbackEye.Initialize("btnEye")
	FallbackEye.Text = "👁" ' will switch to closed-look when hidden
	FallbackEye.TextSize = 18
	FallbackEye.TextColor = ColorHint
	FallbackEye.Gravity = Gravity.CENTER
	panelmain.AddView(FallbackEye, 0, 0, IconSize, IconSize)
	FallbackType.Initialize("")
	FallbackType.TextSize = 18
	FallbackType.TextColor = ColorHint
	FallbackType.Gravity = Gravity.CENTER
	panelmain.AddView(FallbackType, 0, 0, TypeIconSize, TypeIconSize)
End Sub

' Add to a parent with bounds (use ScrollView.Panel as parent)
Public Sub AddToParent(Parent As Panel, Left As Int, Top As Int, Width As Int)
	Parent.AddView(panelmain, Left, Top, Width, RowHeight)
	Relayout
	UpdateTypeIcon
	UpdateEyeIcon
End Sub

' Public API -----

Public Sub setTitle(t As String)
	mTitle = t
	LblName.Text = t
End Sub

Public Sub getTitle As String
	Return mTitle
End Sub

' Set your own icons (24dp-ish recommended)
Public Sub SetIcons(Settings As Bitmap, EyeOpen As Bitmap, EyeClosed As Bitmap)
	If Settings.IsInitialized Then BmpSettings = Settings
	If EyeOpen.IsInitialized Then BmpEyeOpen = EyeOpen
	If EyeClosed.IsInitialized Then BmpEyeClosed = EyeClosed
	ApplyIconBitmaps
End Sub

Public Sub SetShown(shown As Boolean)
	mShown = shown
	UpdateEyeIcon
	RaiseVisibilityChanged
End Sub

Public Sub SetShownWithoutEvent(shown As Boolean)
	If mShown = shown Then Return
	mShown = shown
	UpdateEyeIcon
End Sub

Public Sub SetToggleEnabled(enabled As Boolean)
	ToggleEnabled = enabled
	BtnEye.Enabled = enabled
	FallbackEye.Enabled = enabled
	BtnEye.Visible = enabled
	FallbackEye.Visible = enabled
	If enabled = False Then
		SetShownWithoutEvent(True)
	End If
	Relayout
End Sub

Public Sub IsShown As Boolean
	Return mShown
End Sub

' Optional cosmetics
Public Sub SetColors(Background As Int, Text As Int, Hint As Int)
	ColorBg = Background
	ColorText = Text
	ColorHint = Hint
	panelmain.Color = ColorBg
	LblName.TextColor = ColorText
	FallbackSettings.TextColor = ColorHint
	FallbackEye.TextColor = ColorHint
	FallbackType.TextColor = ColorHint
End Sub

Public Sub SetRowHeight(h As Int)
	RowHeight = h
	panelmain.Height = RowHeight
	Relayout
End Sub

Public Sub SetPadding(p As Int)
	Pad = p
	Relayout
End Sub

' Layout -----

Private Sub Relayout
	Dim w As Int = panelmain.Width
	Dim h As Int = panelmain.Height

	' Right to left: [ .. Label .. ][ Settings ][ Gap ][ Eye ]
	Dim rightX As Int = w - Pad
	Dim leftX As Int = Pad

	' Eye
	If ToggleEnabled Then
		BtnEye.SetLayout(rightX - IconSize, (h - IconSize) / 2, IconSize, IconSize)
		FallbackEye.SetLayout(BtnEye.Left, BtnEye.Top, IconSize, IconSize)
		rightX = BtnEye.Left - Gap
	Else
		BtnEye.SetLayout(rightX, (h - IconSize) / 2, 0, IconSize)
		FallbackEye.SetLayout(rightX, (h - IconSize) / 2, 0, IconSize)
	End If
	' Settings
	BtnSettings.SetLayout(rightX - IconSize, (h - IconSize) / 2, IconSize, IconSize)
	FallbackSettings.SetLayout(BtnSettings.Left, BtnSettings.Top, IconSize, IconSize)
	rightX = BtnSettings.Left - Gap

	' Type icon on the left
	Dim hasTypeIcon As Boolean = BmpType.IsInitialized Or TypeIconText.Length > 0
	If hasTypeIcon Then
		ImgType.SetLayout(leftX, (h - TypeIconSize) / 2, TypeIconSize, TypeIconSize)
		FallbackType.SetLayout(ImgType.Left, ImgType.Top, TypeIconSize, TypeIconSize)
		leftX = ImgType.Left + TypeIconSize + Gap
	Else
		ImgType.SetLayout(leftX, (h - TypeIconSize) / 2, 0, TypeIconSize)
		FallbackType.SetLayout(ImgType.Left, ImgType.Top, 0, TypeIconSize)
	End If
	
	' Label fills remaining space
	LblName.SetLayout(Pad*2 + IconSize, 0, rightX - Pad, h)
End Sub

Private Sub ApplyIconBitmaps
	Dim useImgs As Boolean = BmpSettings.IsInitialized Or BmpEyeOpen.IsInitialized Or BmpEyeClosed.IsInitialized

	If BmpSettings.IsInitialized Then BtnSettings.Bitmap = BmpSettings
	If BmpEyeOpen.IsInitialized And mShown Then BtnEye.Bitmap = BmpEyeOpen
	If BmpEyeClosed.IsInitialized And mShown = False Then BtnEye.Bitmap = BmpEyeClosed

	BtnSettings.Visible = useImgs
	BtnEye.Visible = useImgs

	FallbackSettings.Visible = Not(useImgs)
	FallbackEye.Visible = Not(useImgs)
End Sub


Private Sub UpdateTypeIcon
	Dim hasBitmap As Boolean = BmpType.IsInitialized
	Dim hasText As Boolean = TypeIconText.Length > 0

	If hasBitmap Then
		ImgType.Bitmap = BmpType
	End If

	ImgType.Visible = hasBitmap
	FallbackType.Visible = Not(hasBitmap) And hasText

	If hasText Then
		FallbackType.Text = TypeIconText
	End If

	Relayout
End Sub

Public Sub SetTypeIconBitmap(icon As Bitmap)
	If icon.IsInitialized Then
		BmpType = icon
	Else
		BmpType = Null
	End If
	UpdateTypeIcon
End Sub

Public Sub setTypeIcon(t As String)
	TypeIconText = t
	If t.Length = 0 Then
		BmpType = Null
	End If
	UpdateTypeIcon
End Sub

Public Sub getTypeIcon As String
	Return TypeIconText
End Sub

Private Sub UpdateEyeIcon
	If BtnEye.Visible Then
'		Log(mShown)
'		If mShown And BmpEyeOpen.IsInitialized Then BtnEye.Bitmap = BmpEyeOpen
'		If Not(mShown) And BmpEyeClosed.IsInitialized Then BtnEye.Bitmap = BmpEyeClosed
'	Else
		' fallback text
		FallbackEye.Text = IIf(mShown, "🐵", "🙈")
	End If
End Sub

' Events -----
' Raise: SceneItemRow_VisibilityChanged(Shown As Boolean, Tag As Object)
' Raise: SceneItemRow_SettingsClick(Tag As Object)

Private Sub RaiseVisibilityChanged
	If SubExists(callback, eventname & "_VisibilityChanged") Then
		CallSubDelayed2(callback, eventname & "_VisibilityChanged", mShown)
		' If you also want the Tag:
		' CallSubDelayed3(GetBA, "SceneItemRow_VisibilityChanged", mShown, Tag)
	End If
End Sub

Private Sub RaiseSettingsClick
	If SubExists(callback, eventname & "_SettingsClick") Then
		CallSubDelayed(callback, eventname & "_SettingsClick")
		' Or pass Tag:
		' CallSubDelayed2(GetBA, "SceneItemRow_SettingsClick", Tag)
	End If
End Sub

' Interaction -----

Private Sub btnEye_Click
	If ToggleEnabled = False Then Return
	mShown = Not(mShown)
	UpdateEyeIcon
	RaiseVisibilityChanged
End Sub

Private Sub btnSettings_Click
	' You said you'll open your panel manually—just raise an event hook
	RaiseSettingsClick
End Sub

Private Sub row_Touch (Action As Int, X As Float, Y As Float) As Boolean
	' (Optional) simple pressed effect on row tap (not the icon taps)
'	Select Action
'		Case panelmain.ACTION_DOWN
'			panelmain.Color = ColorPressed
'		Case panelmain.ACTION_UP
'			panelmain.Color = ColorBg
'	End Select
	Return False
End Sub
