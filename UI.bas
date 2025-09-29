B4A=true
Group=Default Group
ModulesStructureVersion=1
Type=StaticCode
Version=13.4
@EndOfDesignText@
'Code module
'Subs in this code module will be accessible from all modules.
Sub Process_Globals
	'These global variables will be declared once when the application starts.
	'These variables can be accessed from all modules.

End Sub

Public Sub SetRoundedCornersCD(cd As ColorDrawable, topleft As Int, topright As Int, bottomright As Int, bottomleft As Int)
	Log($"${topleft}, ${topright}, ${bottomright}, ${bottomleft}"$)
	Dim jo As JavaObject = cd
	jo.RunMethod("setCornerRadii", Array(Array As Float(topleft, topleft, topright, topright, bottomright, bottomright, bottomleft, bottomleft)))
End Sub

Public Sub Right(view As View) As Int 
	Return view.Left + view.Width
End Sub

Public Sub Bottom(view As View) As Int 
	Return view.Top + view.Height
End Sub

public Sub toRad(deg As Int) As Float
	Return (cPI/180) * deg
End Sub

public Sub toDeg(rad As Int) As Float
	Return (180/cPI) * rad
End Sub


public Sub GetDrawable(color As Int, roundC As Int) As ColorDrawable
	Dim cd As ColorDrawable
	cd.Initialize(color, roundC)
	Return cd
End Sub

public Sub GetDrawableWithBorder(color As Int, roundC As Int, borderWidth As Int, bordercolor As Int) As ColorDrawable
	Dim cd As ColorDrawable
	cd.Initialize2(color, roundC, borderWidth, bordercolor)
	Return cd
End Sub