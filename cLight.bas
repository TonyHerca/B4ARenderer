B4A=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=13.4
@EndOfDesignText@
' cLight.bas
Sub Class_Globals
	Public Direction As Vec3   ' for directional light; points FROM light to scene
	Public Color As Int = Colors.White
	Public Intensity As Double = 1.0
End Sub

Public Sub Initialize(dir As Vec3)
	Direction = Math3D.Normalize(dir)
End Sub
