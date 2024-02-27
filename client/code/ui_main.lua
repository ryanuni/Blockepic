
local ui = Global.UI:new('View1.bytes')
Global.ui = ui

local ClickSound = {
	{ui = 'bricklib_back', sound = 'ui_click16'},
	{ui = 'reslib_back', sound = 'ui_click16'},
	{ui = 'back', sound = 'ui_click16'},
}

for _, data in ipairs(ClickSound) do
	local ui = ui[data.ui]
	if ui then
		ui._sound = Global.SoundList[data.sound]
		ui._soundVolumeScale = data.volume or Global.SoundConfigsList[data.sound].volume
	end
end

for i, v in ipairs(ui:getChildren()) do
	v.sortingOrder = 1
end

_dofile('ui_edit_controller.lua')
_dofile('ui_edit_rolecontroller.lua')
_dofile('ui_profile.lua')
_dofile('ui_fame.lua')

_dofile('ui_functionedit.lua')
_dofile('ui_debuglist.lua')

_dofile('ui_objlist.lua')
_dofile('ui_coin.lua')
_dofile('musiclibrary.lua')
ui.interact = _dofile('ui_interact.lua')

ui.edit.visible = false
ui.edit.click = function()
	if Global.Operate.disableUi then
		ui.edit.selected = false
		return
	end

	if Global.GameState:isState('EDIT') then
		Global.GameState:changeState('GAME')
	elseif Global.GameState:isState('GAME') then
		Global.GameState:changeState('EDIT')
	end
end

ui.multibutton.click = function(self)
	Global.editor:setSelectState(ui.multibutton.selected)
end

ui.logicbutton.click = function(self)
	Global.editor.showRelation = ui.logicbutton.selected
	Global.editor:updateRelations()
end

ui.areabutton.click = function(self)
	Global.editor.dragSelect.enable = ui.areabutton.selected
end

ui.savebutton.click = function(self)
	Global.sen:saveLevel()

	Notice('Saved!')
end

ui.update = function(self, e)
	ui.editMenu:update(e)
	ui.propertyEditor:update(e)
end

ui.group.click = function(self)
	Global.editor:cmd_newGroup()

	ui.group._visible = false
	ui.ungroup._visible = true
end

ui.ungroup.click = function(self)
	local g = Global.sen:searchGroupByBlocks(Global.editor.selectedBlocks)

	if not g then return end

	Global.sen:delGroup(g)
	Global.editor:updateRelations()
	ui.group._visible = true
	ui.ungroup._visible = false
end

ui.copybutton.click = function(self)
	Global.editor:cmd_copy()
	Global.editor:cmd_paste()
end

ui.showEdit = function(self, show, open1, open2)
	if open2 == nil then
		open2 = open1
	end
	local isdungeon = Global.sen:isDungeon()
	local isguide = Global.sen:isGuide()
	self.visible = true
	-- self.edit.visible = show
	-- self.edit.selected = open1
	self.back.visible = isdungeon
	if self.back.visible then
		if show and not open1 then
			self.back.click = function()
				if Global.Operate.disableUi then return end

				Global.GameState:changeState('EDIT')
				ui.rolecontroller._visible = false
			end
		else
			self.back.click = function()
				Global.entry:back()
			end
		end
	end
	Global.ObjectBag.mode = 'edit'
	Global.ObjectBag:show(open1 and open2 and not isguide)
	self.exit.visible = isdungeon and not isguide and open1 and open2
	self.logicbutton.visible = isdungeon and not isguide and open1 and open2
	self.game.visible = open1 and open2
	self.editMenu.visible = open1 and isguide
	if self.editMenu.visible then
		self.editMenu.init()
	end
	self.multibutton.visible = open1 and not isguide
	self.areabutton.visible = open1 and not isguide
	-- self.savebutton.visible = open1
	self.roledb.visible = open1

	self.group.visible = false
	self.ungroup.visible = false
	self.copybutton.visible = false
	self.multibutton.selected = false
	self.areabutton.selected = Global.editor.dragSelect.enable
	self.logicbutton.selected = Global.editor.showRelation
	self.controler.editbutton.selected = false

	self:setControlerVisible(false)
	self:setUIControlerVisible(false)

	if Version:isAlpha1() == false then
		self.resourcelibrarybg.onMouseDown = function(args)
			self.resourcelibrarybg.enable = true
			ui:showEdit(true, true, false)
			local mouse = _sys:getRelativeMouse()
			Global.editor.dragSelect:onMouseDown(args.fid, mouse.x, mouse.y)
		end
		self.resourcelibrarybg.onMouseMove = function(args)
			if self.resourcelibrarybg.enable then
				local mouse = _sys:getRelativeMouse()
				Global.editor.dragSelect:onMouseMove(mouse.x, mouse.y)
			end
		end
		self.resourcelibrarybg.onMouseUp = function(args)
			if self.resourcelibrarybg.enable then
				local mouse = _sys:getRelativeMouse()
				if Global.editor.dragSelect:onMouseUp(args.fid, mouse.x, mouse.y) == false then
					Global.editor:onMouseUp(0, mouse.x, mouse.y)
				end
			end
			self.resourcelibrarybg.enable = false
		end
	end
	Global.ui.reslib_back.click = function()
		Global.ObjectBag:close()
	end
end

local eui = {}
eui.onEnter = function(self)
	Global.ui.visible = true
	Global.ui:showEdit(true, true)
end
eui.onLeave = function(self)
	Global.ui:showEdit(true, false)
end
Global.UIEdit = eui

return ui