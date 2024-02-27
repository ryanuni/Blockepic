local ui = Global.ui
local movebutton = ui.uicontroler.movebutton

local startpos = {x = 0, y = 0}
movebutton.onMouseDown = function(arg)
	startpos.x = arg.mouse.x
	startpos.y = arg.mouse.y
	ui:setUIControlerVisible(false)
end

movebutton.onMouseMove = function(arg)
	for i, v in ipairs(Global.editor.selectedBlockUIs) do
		v:move(arg.mouse.x - startpos.x, arg.mouse.y - startpos.y)
	end
	startpos.x = arg.mouse.x
	startpos.y = arg.mouse.y
end

movebutton.onMouseUp = function(arg)
	ui:setUIControlerVisible(true)
end