B4A=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=13.4
@EndOfDesignText@
'==== Class Module: JoystickView ====
'Requires: Gesture Detector library
'Gesture events used: _onDrag, _onTouch only

Sub Class_Globals
	Private mCallback As Object
	Private mEvent As String

	Public pnl As Panel
	Private cvs As Canvas
	Private gd As GestureDetector

	Private cx As Float, cy As Float
	Private baseR As Float
	Private stickR As Float
	Private maxMove As Float

	Private stickX As Float, stickY As Float
	Private isPressed As Boolean

	'colors
	Private colBase As Int = 0xFFE6E6E6
	Private colBaseRing As Int = 0xFFBDBDBD
	Private colStick As Int = 0xFF3F51B5
	Private colStickHL As Int = 0x803F51B5
	Private colAxis As Int = 0x40AAAAAA
	Private colArrow As Int = 0xFF9E9E9E
	Private colBG As Int = 0x00FFFFFF

	Private Dens As Float
End Sub

Public Sub Initialize(Callback As Object, EventName As String)
	mCallback = Callback
	mEvent = EventName

	pnl.Initialize("pnl")
	Dens = GetDeviceLayoutValues.Scale

	gd.SetOnGestureListener(pnl, "gd")
End Sub

Public Sub AddToParent(Parent As Panel, Left As Int, Top As Int, Width As Int, Height As Int)
	Parent.AddView(pnl, Left, Top, Width, Height)
	cvs.Initialize(pnl)
	
	Recalc
	Redraw
End Sub

Public Sub Recalc
	cx = pnl.Width / 2
	cy = pnl.Height / 2
	baseR = Min(pnl.Width, pnl.Height) * 0.47
	stickR = baseR * 0.35
	maxMove = baseR - stickR
	ResetToCenter
End Sub

Private Sub ResetToCenter
	stickX = cx
	stickY = cy
	If isPressed = False Then
		Redraw
		RaiseValueChanged
	Else
		Redraw
	End If
End Sub

'----------------- Gestures (fixed: avoid double updates) -----------------
Private Sub gd_onTouch(Action As Int, X As Float, Y As Float, MotionEvent As Object) As Boolean
	Select Action
		Case 0 'DOWN
			isPressed = True
			UpdateStickTo(X, Y, True)
			RaiseTouchState
			Return True
		Case 2 'MOVE
			'Absolute finger tracking (1:1)
			UpdateStickTo(X, Y, True)
			Return True
		Case 1 'UP
			isPressed = False
			ResetToCenter
			RaiseTouchState
			Return True
	End Select
	Return False
End Sub

'We keep the handler (required by your constraints) but DO NOT move the stick here.
Private Sub gd_onDrag(deltaX As Float, deltaY As Float, MotionEvent As Object)
	'No-op to prevent double movement. _onTouch(MOVE) handles tracking.
End Sub

'----------------- Core -----------------
Private Sub UpdateStickTo(xp As Float, yp As Float, FireEvent As Boolean)
	Dim dx As Float = xp - cx
	Dim dy As Float = yp - cy
	Dim dist As Float = Sqrt(dx*dx + dy*dy)

	If dist > maxMove Then
		Dim s As Float = maxMove / Max(dist, 0.0001)
		dx = dx * s
		dy = dy * s
	End If

	stickX = cx + dx
	stickY = cy + dy

	Redraw
	If FireEvent Then RaiseValueChanged
End Sub

'----------------- Drawing -----------------
Private Sub Redraw
	cvs.DrawColor(colBG)

	'base + ring
	cvs.DrawCircle(cx, cy, baseR, colBase, True, 0)
	cvs.DrawCircle(cx, cy, baseR, colBaseRing, False, 3dip)

	'crosshair
	cvs.DrawLine(cx - baseR*0.8, cy, cx + baseR*0.8, cy, colAxis, 2dip)
	cvs.DrawLine(cx, cy - baseR*0.8, cx, cy + baseR*0.8, colAxis, 2dip)

	'direction arrows
	DrawArrow(cx, cy - baseR*0.78, 0, -1)
	DrawArrow(cx + baseR*0.78, cy, 1, 0)
	DrawArrow(cx, cy + baseR*0.78, 0, 1)
	DrawArrow(cx - baseR*0.78, cy, -1, 0)

	'stick
	cvs.DrawCircle(stickX, stickY, stickR*1.15, colStickHL, True, 0)
	cvs.DrawCircle(stickX, stickY, stickR, colStick, True, 0)
	cvs.DrawCircle(stickX, stickY, stickR, 0xFFFFFFFF, False, 2dip)

	pnl.Invalidate
End Sub

Private Sub DrawArrow(ax As Float, ay As Float, dirx As Int, diry As Int)
	Dim p As Path
	Dim size As Float = baseR * 0.12
	Dim ox As Float = -diry
	Dim oy As Float = dirx

	Dim tipx As Float = ax + dirx * size
	Dim tipy As Float = ay + diry * size
	Dim blx As Float = ax - dirx * size * 0.6 + ox * size * 0.6
	Dim bly As Float = ay - diry * size * 0.6 + oy * size * 0.6
	Dim brx As Float = ax - dirx * size * 0.6 - ox * size * 0.6
	Dim bry As Float = ay - diry * size * 0.6 - oy * size * 0.6

	p.Initialize(blx, bly)
	p.LineTo(brx, bry)
	p.LineTo(tipx, tipy)
	cvs.DrawPath(p, colArrow, True, 0)
End Sub

'----------------- Readings -----------------
Public Sub GetNormalizedX As Float
	Return (stickX - cx) / Max(maxMove, 0.0001)
End Sub

Public Sub GetNormalizedY As Float
	Return (stickY - cy) / Max(maxMove, 0.0001)
End Sub

Public Sub GetStrength As Float
	Dim dx As Float = (stickX - cx)
	Dim dy As Float = (stickY - cy)
	Return Sqrt(dx*dx + dy*dy) / Max(maxMove, 0.0001)
End Sub

Public Sub GetAngleDeg As Float
	Dim dx As Float = (stickX - cx)
	Dim dy As Float = (stickY - cy)
	Return ATan2(dy, dx) * 180 / cPI
End Sub

'----------------- Events -----------------
Private Sub RaiseValueChanged
	If SubExists(mCallback, mEvent & "_ValueChanged") Then
		Dim m As Map
		m.Initialize
		m.Put("X", GetNormalizedX)      ' -1..1
		m.Put("Y", GetNormalizedY)      ' -1..1
		m.Put("Angle", GetAngleDeg)     ' degrees
		m.Put("Strength", GetStrength)  ' 0..1
		'Use CallSub2: one object payload (Map)
		CallSub2(mCallback, mEvent & "_ValueChanged", m)
	End If
End Sub

Private Sub RaiseTouchState
	If SubExists(mCallback, mEvent & "_TouchStateChanged") Then
		CallSub2(mCallback, mEvent & "_TouchStateChanged", isPressed)
	End If
End Sub
