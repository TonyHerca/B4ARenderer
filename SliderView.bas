B4A=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=13.4
@EndOfDesignText@
Sub Class_Globals
	Private mCallback As Object
	Private mEvent As String

	'Structure
	Public panelmain As Panel       'background; owns its own color
	Private pnlDraw As Panel       'transparent overlay we draw on
	Private cvs As Canvas
	Private gd As GestureDetector

	'Header views
	Private lbl As Label
	Private et As EditText

	'Geometry
	Private headerH As Int = 50dip
	Private pad As Int = 10dip
	Private trackTop As Float, trackBottom As Float
	Private trackLeft As Float, trackRight As Float
	Private trackH As Float = 10dip
	Private thumbR As Float = 11dip

	'Range / value
	Private vMin As Float = 0
	Private vMax As Float = 100
	Private vCur As Float = 50
	Private isPressed As Boolean

	'Style
	Public BaseColor As Int        = 0xFFFFFFFF 'panelmain.Color
	Private colTrack As Int        = 0xFFE0E0E0
	Private colTrackFill As Int    = 0xFF90CAF9
	Private colThumb As Int        = 0xFF1976D2
	Private colThumbRing As Int    = 0xFFFFFFFF
	Private colText As Int         = 0xFF212121
	
	'Geometry
'	Private headerH As Int = 30dip   ' <- was 36dip

End Sub

Public Sub Initialize(Callback As Object, EventName As String)
	mCallback = Callback
	mEvent = EventName

	'Base
	panelmain.Initialize("panelmain")
	panelmain.Color = BaseColor

	'Drawing overlay (transparent)
	pnlDraw.Initialize("pnlDraw")
	pnlDraw.Color = Colors.Transparent


	'Header views
	lbl.Initialize("")
	lbl.Text = "Slider"
	lbl.TextColor = colText
	lbl.TextSize = 14
	lbl.Gravity = Bit.Or(Gravity.LEFT, Gravity.CENTER_VERTICAL)

	et.Initialize("et")
	et.Text = ValueToString(vCur)
	et.TextColor = colText
	et.TextSize = 14
	et.Gravity = Bit.Or(Gravity.RIGHT, Gravity.CENTER_VERTICAL)
	et.SingleLine = True
	et.Enabled = True                 'editable

	et.InputType = et.INPUT_TYPE_DECIMAL_NUMBERS

	'Gestures on the DRAW PANEL (so EditText can still receive touches)
	gd.SetOnGestureListener(pnlDraw, "gd")
End Sub

'Add to a parent (Activity or Panel) without Designer
Public Sub AddToParent(Parent As Panel, Left As Int, Top As Int, Width As Int, Height As Int)
	Parent.AddView(panelmain, Left, Top, Width, Height)
	panelmain.Color = BaseColor

	' header (top bar)
	Dim mid As Int = Width / 2
	panelmain.AddView(lbl, pad, 0, mid - (2 * pad), headerH)
	panelmain.AddView(et,  mid, 0, Width - mid - pad, 50dip)

	' drawing panel fills the rest (under the header)
	panelmain.AddView(pnlDraw, 0, 100%y, Width, Height - headerH)
	cvs.Initialize(pnlDraw)
	et.BringToFront
	lbl.BringToFront

	Recalc
	Redraw
End Sub


'------------- Public API -------------
Public Sub SetTitle(t As String)
	lbl.Text = t
	Redraw
End Sub

Public Sub GetTitle As String
	Return lbl.Text
End Sub

Public Sub SetBaseColor(c As Int)
	BaseColor = c
	panelmain.Color = c
End Sub

Public Sub SetRange(MinVal As Float, MaxVal As Float)
	If MaxVal = MinVal Then MaxVal = MinVal + 1
	vMin = Min(MinVal, MaxVal)
	vMax = Max(MinVal, MaxVal)
	vCur = Clamp(vCur, vMin, vMax)
	UpdateValueText
	Redraw
End Sub

Public Sub GetMin As Float
	Return vMin
End Sub

Public Sub GetMax As Float
	Return vMax
End Sub

Public Sub SetValue(v As Float, Raise As Boolean)
	vCur = Clamp(v, vMin, vMax)
	UpdateValueText
	Redraw
	If Raise Then RaiseValueChanged
End Sub

Public Sub GetValue As Float
	Return vCur
End Sub

'Normalized 0..1
Public Sub GetNormalized As Float
	Return (vCur - vMin) / Max(vMax - vMin, 0.0001)
End Sub

'If you resize externally
Public Sub Recalc
    ' layout header again (in case of resize)
    Dim mid As Int = panelmain.Width / 2
    lbl.SetLayoutAnimated(0, pad, 0, mid - (2 * pad), headerH)
	et.SetLayoutAnimated(0,  mid, 0, panelmain.Width - mid - pad, headerH)
    et.BringToFront : lbl.BringToFront

    ' draw panel below header, fills remainder
	pnlDraw.SetLayout(0, headerH, panelmain.Width, panelmain.Height - headerH)

    ' track geometry is RELATIVE TO pnlDraw’s (0,0)
    trackLeft = pad
    trackRight = pnlDraw.Width - pad
    trackTop = 6dip               ' <- start a bit below top of pnlDraw
    trackBottom = trackTop + trackH

    Redraw
End Sub


'------------- Gesture Handling -------------
Private Sub gd_onTouch(Action As Int, X As Float, Y As Float, MotionEvent As Object) As Boolean
	Select Action
		Case 0 'DOWN
			isPressed = True
			UpdateFromPoint(X, Y, True)
			RaiseTouchState
			Return True
		Case 2 'MOVE
			UpdateFromPoint(X, Y, True) 'absolute tracking
			Return True
		Case 1 'UP
			isPressed = False
			UpdateFromPoint(X, Y, True)
			RaiseTouchState
			Return True
	End Select
	Return False
End Sub

'Keep present (per your constraint) but we track via onTouch to avoid double motion
Private Sub gd_onDrag(deltaX As Float, deltaY As Float, MotionEvent As Object)
	'No-op
End Sub

'------------- EditText UX -------------
Private Sub et_Click
	et.RequestFocus
End Sub

Private Sub et_EnterPressed
	CommitEtValue
End Sub

Private Sub et_FocusChanged(HasFocus As Boolean)
	If HasFocus = False Then
		CommitEtValue
	End If
End Sub

Private Sub CommitEtValue
	Dim s As String = et.Text
	If IsNumber(s) Then
		Dim v As Float = s
		SetValue(v, True)
	Else
		'restore last valid
		UpdateValueText
	End If
End Sub

'------------- Core -------------
Private Sub UpdateFromPoint(xp As Float, yp As Float, Fire As Boolean)
	Dim xclamp As Float = Clamp(xp, trackLeft, trackRight)
	Dim n As Float = (xclamp - trackLeft) / Max(trackRight - trackLeft, 0.0001) '0..1
	Dim v As Float = vMin + n * (vMax - vMin)
	If v <> vCur Then
		vCur = v
		UpdateValueText
		Redraw
		If Fire Then RaiseValueChanged
	Else
		Redraw
	End If
End Sub

Private Sub ValueToX(v As Float) As Float
	Dim n As Float = (v - vMin) / Max(vMax - vMin, 0.0001)
	Return trackLeft + n * (trackRight - trackLeft)
End Sub

Private Sub Clamp(v As Float, a As Float, b As Float) As Float
	If v < a Then Return a
	If v > b Then Return b
	Return v
End Sub

Private Sub UpdateValueText
	et.Text = ValueToString(vCur)
End Sub

Private Sub ValueToString(v As Float) As String
	Return NumberFormat2(v, 1, 2, 2, True)
End Sub

'------------- Drawing -------------
Private Sub Redraw
	'Only draw on the overlay; leave the base panel color intact
	cvs.DrawColor(Colors.Transparent)

	'Track background (rounded via capsule)
	DrawCapsule(trackLeft, trackTop, trackRight, trackBottom, colTrack)

	'Filled portion
	Dim xCur As Float = ValueToX(vCur)
	DrawCapsule(trackLeft, trackTop, xCur, trackBottom, colTrackFill)

	'Thumb
	Dim cy As Float = (trackTop + trackBottom) / 2
	cvs.DrawCircle(xCur, cy, thumbR * 1.15, 0x401976D2, True, 0)
	cvs.DrawCircle(xCur, cy, thumbR, colThumb, True, 0)
	cvs.DrawCircle(xCur, cy, thumbR, colThumbRing, False, 2dip)

	pnlDraw.Invalidate
End Sub

'Rounded horizontal pill via rect + end circles
Private Sub DrawCapsule(l As Float, t As Float, r As Float, b As Float, col As Int)
	Dim h As Float = Abs(b - t)
	Dim rad As Float = h / 2
	Dim cy As Float = (t + b) / 2
	Dim cx1 As Float = l + rad
	Dim cx2 As Float = r - rad
	If cx2 < cx1 Then cx2 = cx1

	Dim rc As Rect
	rc.Initialize(Round(cx1), Round(t), Round(cx2), Round(b))
	cvs.DrawRect(rc, col, True, 0)
	cvs.DrawCircle(cx1, cy, rad, col, True, 0)
	cvs.DrawCircle(cx2, cy, rad, col, True, 0)
End Sub

'------------- Events -------------
Private Sub RaiseValueChanged
	If SubExists(mCallback, mEvent & "_ValueChanged") Then
		Dim m As Map
		m.Initialize
		m.Put("Value", vCur)
		m.Put("Norm", GetNormalized)
		CallSub2(mCallback, mEvent & "_ValueChanged", m)
	End If
End Sub

Private Sub RaiseTouchState
	If SubExists(mCallback, mEvent & "_TouchStateChanged") Then
		CallSub2(mCallback, mEvent & "_TouchStateChanged", isPressed)
	End If
End Sub
