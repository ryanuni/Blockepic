local Container = _require('Container')
local ui = Global.ui

local movebutton = ui.controler.movebutton
local planemovebutton = ui.controler.planemovebutton
local rolatabutton = ui.controler.rolatabutton
local editbutton = ui.controler.editbutton
local delbutton = ui.controler.delbutton
local editgroup = ui.controler.editgroup

_dofile('ui_movebutton.lua')
_dofile('ui_planemovebutton.lua')
_dofile('ui_rolatabutton.lua')

ui.setControlerVisible = function(self, visible)
	ui.controler.visible = visible
	editbutton.visible = Global.editor.selectedObject ~= nil
	ui.selectfocusbutton.visible = visible
end

ui.setUIControlerVisible = function(self, visible)
	ui.uicontroler.visible = visible
	ui.uicontroler.editbutton.visible = Global.editor.selectedObject ~= nil
end

editbutton.click = function(self)
	Global.ui.propertyEditor:setCurrentObject(Global.editor.selectedObject)
	Global.GameState:changeState('PROPERTYEDIT')
end

delbutton.click = function(self)
	Global.editor:cmd_delBlocks()
end

editgroup.click = function(self)
	Global.editor:cmd_editGroup(editgroup.selected)
end

ui.updataControlerPos = function(self)
	local pos = Container:get(_Vector2)
	local transPos = Container:get(_Vector3)
	Global.editor.selection.transform:getTranslation(transPos)
	_rd:projectPoint(transPos.x, transPos.y, transPos.z, pos)
	ui.controler._x, ui.controler._y = Global.UI:UI2ScreenPos(pos.x, pos.y)
	Container:returnBack(pos, transPos)
end

ui.selectfocusbutton.click = function(self)
	if not Global.editor.selection then return end
	local translation = Container:get(_Vector3)
	Global.editor.selection.transform:getTranslation(translation)
	Global.CameraControl:get():moveLook(translation, 300, 'editFocus')
	Container:returnBack(translation)
end

local deluibutton = ui.uicontroler.delbutton
local edituibutton = ui.uicontroler.editbutton
_dofile('ui_moveuibutton.lua')

edituibutton.click = function(self)
	Global.ui.propertyEditor:setCurrentObject(Global.editor.selectedObject)
	Global.GameState:changeState('PROPERTYEDIT')
end

deluibutton.click = function()
	Global.editor:cmd_delBlockUIs()
end

ui.updataUIControlerPos = function(self)
	local pos = Container:get(_Vector2)
	pos:set(0, 0)
	for i, v in ipairs(Global.editor.selectedBlockUIs) do
		pos.x = pos.x + v.widget._x + v.widget._width / 2
		pos.y = pos.y + v.widget._y + v.widget._height / 2
	end
	pos.x = pos.x / #Global.editor.selectedBlockUIs
	pos.y = pos.y / #Global.editor.selectedBlockUIs
	ui.uicontroler._x, ui.uicontroler._y = pos.x, pos.y
	Container:returnBack(pos)
end
