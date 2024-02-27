local ui = Global.UIParkour
ui.jumpbutton.onMouseDown = function(self)
	if Global.Operate.disableUi then
		return
	end

	-- Global.role:jump()
end
ui.focusbutton.onMouseDown = function(self)
	if Global.Operate.disableUi then
		return
	end

	Global.role:focusBack()
end
ui.highspeedbutton.onMouseDown = function(self)
	if Global.Operate.disableUi then
		return
	end

	Global.role:speedUp(true)
end
ui.highspeedbutton.onMouseUp = function(self)
	if Global.Operate.disableUi then
		return
	end

	Global.role:speedUp(false)
end
