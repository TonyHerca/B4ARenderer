B4A=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=13.4
@EndOfDesignText@
' cLight.bas
Sub Class_Globals
	Public Const KIND_DIRECTIONAL As Int = 0
	Public Const KIND_POINT As Int = 1
	Public Const KIND_SPOT As Int = 2
	Public Const KIND_RECT As Int = 3     ' rectangular area (square is just equal U/V lengths)

        Public Name As String = "Light"
        Public Kind As Int = KIND_DIRECTIONAL
        Public Direction As Vec3   ' for directional light; points FROM light to scene
        Public Color As Int = Colors.White
        Public Intensity As Double = 1.0
        Public Position As Vec3      ' position for point/spot/rect
        Public Enabled As Boolean = True
	
	Public CosInner As Double = Cos(15 * cPI / 180)
	Public CosOuter As Double = Cos(20 * cPI / 180)

	' Rect area light half-vectors (center + U*sx + V*sy, with sx,sy ∈ [-1,1])
	Public U As Vec3
	Public V As Vec3
End Sub

Public Sub Initialize(dir As Vec3)
        Direction = Math3D.V3(0, -1, 0)
        Position = Math3D.V3(0, 0, 0)
        U = Math3D.V3(0, 0, 0)
        V = Math3D.V3(0, 0, 0)
        Enabled = True
End Sub


Public Sub Normal As Vec3
	Return Math3D.Normalize(Math3D.Cross(U, V))
End Sub

Public Sub Area As Double
	Return 4 * Math3D.Len(U) * Math3D.Len(V)   ' because U and V are half-sizes
End Sub
