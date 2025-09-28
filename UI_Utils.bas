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