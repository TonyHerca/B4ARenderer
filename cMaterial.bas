B4A=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=13.4
@EndOfDesignText@
' cMaterial.bas
Sub Class_Globals
	Public id As Int = -1
	Public Name As String = "Default"
	Public Albedo As Int = Colors.RGB(60,160,255)
	Public Reflectivity As Double = 0.0 ' used by ray tracer
End Sub

Public Sub Initialize(n As String)
	Name = n
End Sub
