B4A=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=13.4
@EndOfDesignText@
Sub Class_Globals
	Public panelmain As Panel
	Public backgroundPanel As Panel
	Public popupPanel As Panel
	Public handlePanel As Panel
	Public containerPanel As Panel
	
End Sub

'Initializes the object. You can add parameters to this method if needed.
Public Sub Initialize
	panelmain.Initialize("")
	backgroundPanel.Initialize("bg")
	popupPanel.Initialize("")
	handlePanel.Initialize("handle")
	containerPanel.Initialize("")
End Sub

public Sub addToParent(parent As Panel)
	parent.AddView(parent, 0, 0, parent.Width, parent.Height)
	
	panelmain.AddView(backgroundPanel, 0, 0, panelmain.Width, panelmain.Height)
	
	panelmain.AddView(popupPanel, 0, 50%y, panelmain.Width, panelmain.Height)
	
	
End Sub