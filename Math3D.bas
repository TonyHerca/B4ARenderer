B4A=true
Group=Default Group
ModulesStructureVersion=1
Type=StaticCode
Version=13.4
@EndOfDesignText@
' Math3D.bas (Code Module)
Sub Process_Globals
	Type Vec3(X As Double, Y As Double, Z As Double)
	Type Face(A As Int, B As Int, C As Int)
	Type FaceDepth(Z As Double, I As Int)
End Sub

' --- constructors
Public Sub V3(x As Double, y As Double, z As Double) As Vec3
	Dim v As Vec3 : v.Initialize : v.X=x : v.Y=y : v.Z=z : Return v
End Sub
Public Sub F3(a As Int, b As Int, c As Int) As Face
	Dim f As Face : f.Initialize : f.A=a : f.B=b : f.C=c : Return f
End Sub

' --- vector ops (copy your working ones here) ---
Public Sub AddV(a As Vec3, b As Vec3) As Vec3
	Return V3(a.X+b.X, a.Y+b.Y, a.Z+b.Z)
End Sub
Public Sub SubV(a As Vec3, b As Vec3) As Vec3
	Return V3(a.X-b.X, a.Y-b.Y, a.Z-b.Z)
End Sub
Public Sub Mul(a As Vec3, s As Double) As Vec3
	Return V3(a.X*s, a.Y*s, a.Z*s)
End Sub
Public Sub Dot(a As Vec3, b As Vec3) As Double
	Return a.X*b.X + a.Y*b.Y + a.Z*b.Z
End Sub
Public Sub Cross(a As Vec3, b As Vec3) As Vec3
	Return V3( a.Y*b.Z - a.Z*b.Y, a.Z*b.X - a.X*b.Z, a.X*b.Y - a.Y*b.X )
End Sub
Public Sub Len(a As Vec3) As Double
	Return Sqrt(Max(1e-12, a.X*a.X + a.Y*a.Y + a.Z*a.Z))
End Sub
Public Sub Normalize(a As Vec3) As Vec3 : Dim l As Double = Len(a)
	Return V3(a.X/l, a.Y/l, a.Z/l)
End Sub
	
	' yaw-pitch-roll (ZYX) – replace if you already have rotation helpers
Public Sub ApplyYawPitchRoll(v As Vec3, yaw As Double, pitch As Double, roll As Double) As Vec3
	Dim cy As Double = Cos(yaw), sy As Double = Sin(yaw)
	Dim cp As Double = Cos(pitch), sp As Double = Sin(pitch)
	Dim cr As Double = Cos(roll), sr As Double = Sin(roll)

	' R = Rz(roll)*Rx(pitch)*Ry(yaw) – tweak if you prefer another order
	Dim x1 As Double =  v.X*cy + v.Z*sy
	Dim y1 As Double =  v.Y
	Dim z1 As Double = -v.X*sy + v.Z*cy

	Dim x2 As Double =  x1
	Dim y2 As Double =  y1*cp - z1*sp
	Dim z2 As Double =  y1*sp + z1*cp

	Dim x3 As Double = x2*cr - y2*sr
	Dim y3 As Double = x2*sr + y2*cr
	Dim z3 As Double = z2

	Return V3(x3, y3, z3)
End Sub

Public Sub ARGB255(a As Int, r As Int, g As Int, b As Int) As Int
	If r<0 Then r=0 : If r>255 Then r=255
	If g<0 Then g=0 : If g>255 Then g=255
	If b<0 Then b=0 : If b>255 Then b=255
	Return Bit.Or(Bit.ShiftLeft(a,24), Colors.RGB(r,g,b))
End Sub

Public Sub CreateIntArray(n As Int) As Int()
	Dim a(n) As Int
	Return a
End Sub

public Sub AxisRotate(v As Vec3, axis As Vec3, ang As Double) As Vec3
	Dim c As Double = Cos(ang), s As Double = Sin(ang)
	Dim dotva As Double = Dot(v, axis)
	Dim term1 As Vec3 = Mul(v, c)
	Dim term2 As Vec3 = Mul(Cross(axis, v), s)
	Dim term3 As Vec3 = Mul(axis, (1 - c) * dotva)
	Return AddV(AddV(term1, term2), term3)
End Sub

public Sub CopyList(l As List) As List
	Dim newList As List
	newList.Initialize
	newList.AddAll(l)
	Return newList
End Sub

public Sub CopyVec3(v As Vec3) As Vec3
	Dim newV As Vec3
	newV.Initialize
	newV.X = v.X : newV.Y = v.Y : newV.Z = v.Z
	Return newV
End Sub