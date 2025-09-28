B4A=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=13.4
@EndOfDesignText@
' cCamera.bas
Sub Class_Globals
	Public Pos As Vec3
	Public Target As Vec3
	Public Up As Vec3
	Public FOV_Deg As Double = 60
	Public TurnSpeed As Float = 0.01
	Public MoveSpeed As Float = 0.1
	
End Sub

Public Sub Initialize
	Pos = Math3D.V3(0,0.8,2.6)
	Target = Math3D.V3(0,0.4,0)
	Up = Math3D.V3(0,1,0)
End Sub

Public Sub Basis(right As Vec3, upv As Vec3, fwd As Vec3) As Vec3()
	fwd = Math3D.Normalize(Math3D.SubV(Target, Pos))
	right = Math3D.Normalize(Math3D.Cross(fwd, Up))
	upv = Math3D.Cross(right, fwd)
	
	Return Array As Vec3(fwd, right, upv)
End Sub

Public Sub Dolly(dist As Double)
	Dim forward As Vec3 = Math3D.Normalize(Math3D.SubV(Target, Pos))
	Dim d As Vec3 = Math3D.Mul(forward, dist)
	Pos = Math3D.AddV(Pos, d)
	Target = Math3D.AddV(Target, d)
End Sub

Public Sub Truck(dist As Double)
	Dim forward As Vec3 = Math3D.Normalize(Math3D.SubV(Target, Pos))
	Dim right As Vec3 = Math3D.Normalize(Math3D.Cross(forward, Up))
	Dim d As Vec3 = Math3D.Mul(right, dist)
	Pos = Math3D.AddV(Pos, d)
	Target = Math3D.AddV(Target, d)
End Sub

Public Sub Pedestal(dist As Double)
	' Use re-orthoMath3d.Normalized up so it stays perpendicular
	Dim forward As Vec3 = Math3D.Normalize(Math3D.SubV(Target, Pos))
	Dim right As Vec3 = Math3D.Normalize(Math3D.Cross(forward, Up))
	Dim Up As Vec3 = Math3D.Cross(right, forward)
	Dim d As Vec3 = Math3D.Mul(Up, dist)
	Pos = Math3D.AddV(Pos, d)
	Target = Math3D.AddV(Target, d)
End Sub

' Pan/Tilt: rotate view around Pos (yaw around world up, pitch around camera right)
Public Sub PanTilt(yawRad As Double, pitchRad As Double)
	Dim f As Vec3 = Math3D.Normalize(Math3D.SubV(Target, Pos))
	Dim r As Vec3 = Math3D.Normalize(Math3D.Cross(f, Up))
	Dim u As Vec3 = Math3D.Cross(r, f)

	' rotate around u (pitch)
	f = Math3D.AddV(Math3D.Mul(f, Cos(pitchRad)), Math3D.Mul(u, Sin(pitchRad)))
	f = Math3D.Normalize(f)

	' rotate around world up (yaw) – or use camera u if you prefer
	Dim worldUp As Vec3 = Math3D.V3(0,1,0)
	f = Math3D.AddV(Math3D.Mul(f, Cos(yawRad)), Math3D.Mul(worldUp, Sin(yawRad) * Math3D.Dot(r, worldUp))) ' simple yaw
	' Better: rotate f around worldUp with a proper axis-angle; quick version:
	f = Math3D.AxisRotate(f, worldUp, yawRad)
    
	Target = Math3D.AddV(Pos, Math3D.Normalize(f))
	' Rebuild Up to avoid drift
	r = Math3D.Normalize(Math3D.Cross(f, worldUp))
	Up = Math3D.Normalize(Math3D.Cross(r, f))
End Sub
