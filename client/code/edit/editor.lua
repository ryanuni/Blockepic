local command = _require('Pattern.Command')
local Container = _require('Container')

local editor = {
	data = {},
	command = command.new(),
	selectedBlocks = {},
	copyedBlocks = {},
	copyedBlockUIs = {},
	selection = {
		transform = _Matrix3D.new(),
	},
	editingGroup = nil,
	selectedBlockUIs = {},
	showRelation = false,
}

Global.MOVESTEP = {
	BRICK = 0,
	TILE = 1,
	GRID = 2,
	DUNGEON = 3,
}

editor.shapedelta = 0.004

-- 最小移动单元
editor.movefactor = 0.1
editor.movefactor2 = 0.1 / 5
editor.movefactor3 = 0.2
function _G.normalizePos(x, mode)
	-- return x
	local factor = mode == Global.MOVESTEP.GRID and 0.8 or (mode == Global.MOVESTEP.GRID and editor.movefactor3 or editor.movefactor)
	local m = math.floor(x / factor)
	local n = m * factor
	local frac = x - n

	local factor2 = mode == Global.MOVESTEP.TILE and editor.movefactor2 or factor
	frac = math.floor(frac / factor2 + 0.5) * factor2

	return n + frac
end

editor.rotstepNum = 24
editor.rotstep = 2 * math.pi / editor.rotstepNum

editor.objectSelect = _dofile('editor_objectSelect.lua')
editor.constructArea = _dofile('editor_constructArea.lua')

Global.editor = editor
local ui = _dofile('ui_main.lua')
editor.constructArea:loadRoleMovie()

editor.clearSelection = function(self)
	self:clearBlockSelection()
	self.selectedBlocks = {}
end
editor.indexSelectedBlock = function(self, b)
	for i, v in ipairs(self.selectedBlocks) do
		if v == b then
			return i
		end
	end
	return -1
end
editor.selectBlock = function(self, b, switch)
	if not b then return end

	self:clearBlockSelection()
	local index = self:indexSelectedBlock(b)
	if switch and index ~= -1 then
		table.remove(self.selectedBlocks, index)
	else
		table.insert(self.selectedBlocks, b)
	end
	self:setBlockSelection()
end
editor.clearBlockSelection = function(self)
	for i, b in ipairs (self.selectedBlocks) do
		b:setEditState()
		--b:updateSpace()
		b:setParent()
		b:formatMatrix()
	end
end
editor.setBlockSelection = function(self)
	for i, b in ipairs(self.selectedBlocks) do
		b:setEditState('selected')
	end
end
editor.updateSelectionTransform = function(self, mat)
	if mat then
		copyMat(self.selection.transform, mat)
		return
	end

	editor.static_building_calcTransform(self.selectedBlocks, self.selection.transform)
end

editor.setSelectionTranslation = function(self, vec)
	if not self.selection.transform then return end
	local attach = self.selection.transform
	Global.editor:cmd_transBegin(attach)
	Global.normalizePos(vec, Global.MOVESTEP.TILE)
	attach:setTranslation(vec)
	Global.editor:cmd_transEnd(attach)
end

editor.setIndicator = function(self)
	local aabb = Container:get(_AxisAlignedBox)

	Block.getAABBs(self.selectedBlocks, aabb)

	Global.ui.controler.movebutton:attachBlock(self.selection.transform, Global.MOVESTEP.BRICK, aabb, self.selectedBlocks)
	Global.ui.controler.planemovebutton:attachBlock(self.selection.transform, Global.MOVESTEP.BRICK)
	Global.ui.controler.rolatabutton:attachBlock(self.selection.transform)

	Container:returnBack(aabb)
end
editor.static_building_calcTransform = function(bs, mat)
	local vec = Container:get(_Vector3)
	local aabb = Container:get(_AxisAlignedBox)
	Block.getAABBs(bs, aabb)
	aabb:getCenter(vec)
	Global.normalizePos(vec, Global.MOVESTEP.TILE)
	mat:setTranslation(vec)

	Container:returnBack(vec, aabb)
end
editor.static_building_selectBlocks = function(bs, select)
--	print('static_building_selectBlocks', select)
	local flag
	if select then
		flag = 'selected'
	end
	editor.static_building_setBlocksState(bs, flag)
end
editor.static_building_setBlocksState = function(bs, state)
	for i, b in ipairs(bs) do
		b:setEditState(state)
	end
end
editor.static_building_setupTransform = function(bs, mat)
	for i, b in ipairs(bs) do
		b:setParent(mat)
	end

	-- bind
	editor.static_building_bindController(bs, mat)
end
editor.static_building_bindController = function(bs, mat)
	local aabb = Container:get(_AxisAlignedBox)

	Block.getAABBs(bs, aabb)

	Global.ui.controler.movebutton:attachBlock(mat, Global.MOVESTEP.BRICK, aabb, bs)
	Global.ui.controler.planemovebutton:attachBlock(mat, Global.MOVESTEP.BRICK)
	Global.ui.controler.rolatabutton:attachBlock(mat)

	Container:returnBack(aabb)
end
editor.static_building_unsetTransform = function(bs)
	for i, b in ipairs(bs) do
		b:setParent()
		b:formatMatrix()
	end
end
editor.updateSelection = function(self, mat)
	if #self.selectedBlockUIs > 0 then
		self.selectedObject = #self.selectedBlockUIs == 1 and self.selectedBlockUIs[1] or nil
		ui:setUIControlerVisible(true)
		ui:setControlerVisible(false)
	else
		local count = #self.selectedBlocks

		local show = count > 0
		if show then
			self:updateSelectionTransform(mat)

			for i, b in ipairs(self.selectedBlocks) do
				b:setParent(self.selection.transform)
			end

			self:setIndicator()
		end
		self.selectedGroup = Global.sen:searchGroupByBlocks(self.selectedBlocks)
		local isguide = Global.sen:isGuide()
		if Global.GameState:isState('EDIT') then
			if self.selectedGroup then
				ui.group.visible = false and not isguide
				ui.ungroup.visible = true and not isguide
			else
				ui.group.visible = count > 1 and not isguide
				ui.ungroup.visible = false and not isguide
			end
			ui.copybutton.visible = show and not isguide
		end
		ui.controler.editgroup.visible = editor.editingGroup ~= nil or self.selectedGroup ~= nil

		self.selectedObject = count == 1 and self.selectedBlocks[1] or self.selectedGroup

		ui:setControlerVisible(count > 0)
		ui:setUIControlerVisible(false)
	end

	-- if Global.Build:isValid() then
	-- 	Global.Build:onSelectBlock()
	-- end
end

-- ctrl选择用
editor.selectBlockOperation = function(self, b)
	self:clearUISelection()
	self:selectBlock(b, true)

	self:updateSelection()
end
-- 清掉 选一[些]
editor.selectBlocksOperation = function(self, bs, mat)
	self:clearUISelection()
	self:clearSelection()

	for i, b in ipairs(bs) do
		table.insert(self.selectedBlocks, b)
	end

	self:setBlockSelection()
	self:updateSelection(mat)
end
editor.delBlocksOperation = function(self, bs)
	for i, b in ipairs(bs) do
		Global.sen:delBlock(b)
		table.remove(self.copyedBlocks, self:indexCopyedBlock(b))
	end

	self.selectedBlocks = {}
end
editor.delBlockUIsOperation = function(self, bus)
	self.copyedBlockUIs = {}
	for i = #bus, 1, -1 do
		Global.sen:delBlockUI(bus[i])
	end

	self.selectedBlocks = {}
end

editor.clearUISelection = function(self)
	self:clearBlockUISelection()
	self.selectedBlockUIs = {}
end

editor.selectBlockUI = function(self, bu, switch)
	if not bu then return end

	self:clearBlockUISelection()
	local index = self:indexSelectedBlockUIs(bu)
	if switch and index ~= -1 then
		table.remove(self.selectedBlockUIs, index)
	elseif index == -1 then
		table.insert(self.selectedBlockUIs, bu)
	end
	self:setBlockUISelection()
end

editor.indexSelectedBlockUIs = function(self, bu)
	for i, v in ipairs(self.selectedBlockUIs) do
		if v == bu then
			return i
		end
	end
	return -1
end
editor.clearBlockUISelection = function(self)
	for i, v in ipairs(self.selectedBlockUIs) do
		v:setEditState()
	end
end
editor.setBlockUISelection = function(self)
	for i, v in ipairs(self.selectedBlockUIs) do
		v:setEditState('selected')
	end
end

-- ctrl选择用
editor.selectBlockUIOperation = function(self, bu)
	self:clearSelection()
	self:selectBlockUI(bu, true)

	self:updateSelection()
end
-- 清掉 选一[些]
editor.selectBlockUIsOperation = function(self, bus)
	self:clearSelection()
	self:clearUISelection()
	for i, v in ipairs(bus) do
		self:selectBlockUI(v)
	end
	self:updateSelection()
end
-- 具体操作 -------------------------------------------
editor.getSelectUndoFunction = function(self)
	local bs = {}
	for i, b in ipairs(self.selectedBlocks) do
		table.insert(bs, b)
	end

	local mat = _Matrix3D.new()
	copyMat(mat, self.selection.transform)
	local undo = function()
		self:selectBlocksOperation(bs, mat)
	end

	return undo
end
editor.cmd_clickSelect = function(self, b)
	-- UNDO
	local nbs = {b}
	local redo = function()
		self:selectBlocksOperation(nbs)
	end

	local undo = self:getSelectUndoFunction()
	self.command:add(redo, undo, '单选块')
--	print(debug.traceback())
end
editor.cmd_ctrlClickSelect = function(self, b)
	local redo = function()
		self:selectBlockOperation(b)
	end
	local undo = self:getSelectUndoFunction()
	self.command:add(redo, undo, '反选块')
end

editor.getSelectUIUndoFunction = function(self)
	local bus = {}
	for i, v in ipairs(self.selectedBlockUIs) do
		table.insert(bus, v)
	end

	local undo = function()
		self:selectBlockUIsOperation(bus)
	end

	return undo
end
editor.cmd_clickSelectUI = function(self, bu)
	-- UNDO
	local redo = function()
		self:selectBlockUIsOperation({bu})
	end

	local undo = self:getSelectUIUndoFunction()
	self.command:add(redo, undo, '单选UI块')
end
editor.cmd_ctrlClickSelectUI = function(self, bu)
	local redo = function()
		self:selectBlockUIOperation(bu)
	end
	local undo = self:getSelectUIUndoFunction()
	self.command:add(redo, undo, '反选UI块')
end

editor.cmd_dragSelect = function(self, bs)
	-- UNDO
	local redo = function()
		self:selectBlocksOperation(bs)
	end

	local undo = self:getSelectUndoFunction()
	self.command:add(redo, undo, '多选块')
--	print(debug.traceback())
end
editor.cmd_selectGroup = function(self, g)
	if not g then return end

	self:cmd_dragSelect(g:getBlocks())
end
editor.indexCopyedBlock = function(self, b)
	for i, v in ipairs(self.copyedBlocks) do
		if v == b then
			return i
		end
	end
	return -1
end
editor.cmd_copy = function(self)
	if #self.selectedBlocks > 0 then
		-- UNDO
		local oldcbs = {}
		for i, b in ipairs(self.copyedBlocks) do
			table.insert(oldcbs, b)
		end

		local redo = function()
			self.copyedBlocks = {}
			for i, b in ipairs(self.selectedBlocks) do
				table.insert(self.copyedBlocks, b)
			end
		end

		local undo = function()
			self.copyedBlocks = oldcbs
		end

		self.command:add(redo, undo, '复制块')
	elseif #self.selectedBlockUIs > 0 then
		self.copyedBlockUIs = {}
		for i, v in ipairs(self.selectedBlockUIs) do
			table.insert(self.copyedBlockUIs, v)
		end
	end
end
editor.cmd_paste = function(self)
	if #self.copyedBlocks > 0 then
		local redo = function()
			-- 加block，改selection
			local bs = {}
			for i, b in ipairs(self.copyedBlocks) do
				local nb = Global.sen:cloneBlock(b)
				nb:move(0.2, 0, 0)
				table.insert(bs, nb)
			end
			self:updateRelations()
			self:selectBlocksOperation(bs)
		end

		local bs = {}
		for i, b in ipairs(self.selectedBlocks) do
			table.insert(bs, b)
		end
		local undo = function()
			-- 恢复selection
			self:delBlocksOperation(self.selectedBlocks)
			self:selectBlocksOperation(bs)
			self:updateRelations()
		end

		self.command:add(redo, undo, '粘贴块')
	elseif #self.copyedBlockUIs > 0 then
		local redo = function()
			-- 加block，改selection
			local bus = {}
			for i, v in ipairs(self.copyedBlockUIs) do
				local nu = Global.sen:cloneBlockUI(v)
				nu:move(10, 10)
				table.insert(bus, nu)
			end
			self:selectBlockUIsOperation(bus)
		end

		local bus = {}
		for i, v in ipairs(self.selectedBlockUIs) do
			table.insert(bus, v)
		end
		local undo = function()
			-- 恢复selection
			self:delBlockUIsOperation(self.selectedBlockUIs)
			self:selectBlockUIsOperation(bus)
		end

		self.command:add(redo, undo, '粘贴UI块')
	end
end

editor.cmd_addItem = function(self, shapeid, subshape)
	local data = {
		shape = shapeid,
		subshape = subshape,
	}

	local redo = function()
		return Global.sen:createBlock(data)
	end

	local undo = function(b)
		Global.sen:delBlock(b)
	end

	return self.command:add(redo, undo, '创建块')
end

-- local data = {
-- 	shape = shapeid,
-- 	subshape = subid,
-- 	material = mtlid or 1,
-- 	color = colorid or 1,
-- 	roughness = roughness or 1,
-- 	mtlmode = mtlmode or 1,
-- }
editor.cmd_addBlock = function(self, data)
	data.material = data.material or 1
	data.color = data.color or 1
	data.roughness = data.roughness or 1
	data.mtlmode = data.mtlmode or 1

	local redo = function()
		return Global.sen:createBlock(data)
	end

	local undo = function(b)
		Global.sen:delBlock(b)
	end

	return self.command:add(redo, undo, '创建块')
end
editor.cmd_delBlocks = function(self)
	if #self.selectedBlocks == 0 then return end

	local redo = function()
		for i, b in ipairs(self.selectedBlocks) do
			Global.sen:delBlock(b)
			table.remove(self.copyedBlocks, self:indexCopyedBlock(b))
		end

		self:selectBlocksOperation({})
		self:updateRelations()
	end

	local bs = {}
	for i, b in ipairs(self.selectedBlocks) do
		table.insert(bs, b)
	end

	local undo_add = function()
		for i, b in ipairs(bs) do
			Global.sen:addBlockUndo(b)
		end
	end
	local undo_select = self:getSelectUndoFunction()
	local undo = function()
		undo_add()
		undo_select()
		self:updateRelations()
	end

	self.command:add(redo, undo, '删除块')
end

editor.cmd_delBlockUIs = function(self)
	if self.selectedBlockUIs == 0 then return end

	local redo = function()
		self.copyedBlockUIs = {}
		for i = #self.selectedBlockUIs, 1, -1 do
			Global.sen:delBlockUI(self.selectedBlockUIs[i])
		end
		self.selectedBlockUIs = {}

		self:selectBlockUIsOperation({})
		self:updateRelations()
	end

	local bus = {}
	for i, v in ipairs(self.selectedBlockUIs) do
		table.insert(bus, v)
	end

	local undo_select = self:getSelectUIUndoFunction()
	local undo = function()
		for i, v in ipairs(bus) do
			Global.sen:addBlockUI(v)
		end
		undo_select()
		self:updateRelations()
	end

	self.command:add(redo, undo, '删除块')
end
-- 这个不对
editor.cmd_editGroup = function(self, editing)
	if editing then
		editor.editingGroup = self.selectedGroup
	elseif editing == false then
		local bs = {}
		for i, b in ipairs(self.selectedBlocks) do
			table.insert(bs, b)
		end
		self.editingGroup:setBlocks(bs, true)
		editor.editingGroup = nil
	end
end
editor.cmd_brushBlocks = function(self, axis, sign)
	if self.selectedBlocks == 0 then return end

	local redo = function()
		local aabb = Block.getAABBs(self.selectedBlocks)
		local trans = Container:get(_Vector3)
		trans[axis] = (aabb.max[axis] - aabb.min[axis]) * sign

		local bs = {}
		for i, b in ipairs(self.selectedBlocks) do
			local nb = Global.sen:cloneBlock(b)
			nb:move(trans.x, trans.y, trans.z)

			table.insert(bs, nb)
		end
		self:selectBlocksOperation(bs)
		Container:returnBack(trans)
	end

	local bs = {}
	for i, b in ipairs(self.selectedBlocks) do
		table.insert(bs, b)
	end

	local mat = _Matrix3D.new()
	copyMat(mat, self.selection.transform)
	local undo = function()
		self:delBlocksOperation(self.selectedBlocks)
		self:selectBlocksOperation(bs, mat)
	end

	self.command:add(redo, undo, '刷块')
end
local trans_undo
editor.cmd_transBegin = function(self, mat)
--	print('trans begin', debug.traceback())
	local oldmat = _Matrix3D.new()
	copyMat(oldmat, mat)
	trans_undo = function()
		copyMat(mat, oldmat)
		for i, b in ipairs(self.selectedBlocks) do
			b:updateSpace()
		end
		self:setIndicator()
	end
end
editor.cmd_transEnd = function(self, mat)
--	print('trans end', debug.traceback())
	local oldmat = _Matrix3D.new()
	copyMat(oldmat, mat)

	local redo = function()
		copyMat(mat, oldmat)
		for i, b in ipairs(self.selectedBlocks) do
			b:updateSpace()
		end
		self:setIndicator()
	end

	self.command:add(redo, trans_undo, '块空间编辑')
end
editor.cmd_linkToBlock = function(self, b)
end
editor.cmd_newGroup = function(self)
	local bs = {}
	for i, b in ipairs(self.selectedBlocks) do
		table.insert(bs, b)
	end

	local redo = function()
		local g = Global.group.new(Global.sen)
		g:setBlocks(bs, true)
		Global.sen:addGroup(g)

		return g
	end
	local undo = function(g)
		Global.sen:delGroup(g)
	end

	self.command:add(redo, undo, '新组')
end
editor.cmd_delGroup = function(self)

end
-------------------------------------------------------
editor.dragSelect = _dofile('editor_dragselect.lua')
editor.brush = _dofile('editor_brush.lua')
editor.isMultiSelect = false
-- 事件 -------------------------------
editor.update = function(self, e)
	ui:update(e)
	self:drawRelations(e)
end

editor.drawRelations = function(self, e)
	if Global.GameState:isState('EDIT') == false then return end
	if self.showRelation == false then return end

	for source, r in pairs(self.relations) do
		for target, v in pairs(r) do
			local x1, y1 = ui:get2DPosition(source)
			local x2, y2 = ui:get2DPosition(target)
			v.cur = v.cur + e / 1000
			v.cur = v.cur > 10 and 0 or v.cur
			_rd:drawBezierTransportCurve(x1, y1, x1 + 20, y1 + 20, x2 + 20, y2 + 20, x2, y2, v.cur / 10, 1, 0xff00ff00)
		end
	end
end

editor.updateRelations = function(self)
	self.relations = {}
	if self.showRelation == false then return end
	local objects = {}
	for i, v in ipairs(Global.sen.blocks) do
		table.insert(objects, v)
	end
	for i, v in ipairs(Global.sen.groups) do
		table.insert(objects, v)
	end
	for i, v in ipairs(Global.sen.blockuis) do
		table.insert(objects, v)
	end
	for i, v in ipairs(objects) do
		for a, b in ipairs(v.functions) do
			for c, d in ipairs(b.sourceactions) do
				local source = d.owner.owner
				if source ~= v then
					if self.relations[source] == nil then
						self.relations[source] = {}
					end
					if self.relations[source][v] == nil then
						self.relations[source][v] = {cur = 0}
					end
				end
			end
		end
	end
	for i, v in ipairs(objects) do
		for a, b in ipairs(v:getActions()) do
			if b.targetobject and b.targetobject ~= v then
				if self.relations[v] == nil then
					self.relations[v] = {}
				end
				if self.relations[v][b.targetobject] == nil then
					self.relations[v][b.targetobject] = {cur = 0}
				end
			end
		end
	end
	-- for i, v in ipairs(objects) do
	-- 	for a, b in ipairs(v:getActions()) do
	-- 		local rts = {}
	-- 		for c, d in ipairs(b.functions()) do
	-- 			rts[d.owner] = {cur = 0}
	-- 		end
	-- 		if nect(rts) then
	-- 			self.relations[v] = rts
	-- 		end
	-- 	end
	-- end
end

editor.setSelectState = function(self, isMultiSelect)
	self.isMultiSelect = isMultiSelect
	if isMultiSelect == false then
		self:clearSelection()
		self:clearUISelection()
		self:updateSelection()
	end
end

editor.OnEnterEditMode = function(self)
	local groups = Global.sen:getGroups()
	for i, v in next, groups do
		-- 进编辑模式更新下包围盒，防止奇奇怪怪的bug.
		v:setNeedUpdateBoundBox()
	end
end

editor.OnLeaveEditMode = function(self)
	local groups = Global.sen:getGroups()
	for i, v in next, groups do
		v:showSelectedEffect(false)
	end
end

editor.render = function(self, e)
	if Global.GameState:isState('EDIT') or Global.GameState:isState('PROPERTYEDIT') then
		local groups = Global.sen:getGroups()
		if Global.isMovingIndicator then
			for i, v in next, groups do
				v:showSelectedEffect(false)
			end
		else
			for i, v in next, groups do
				v:onUpdate()
			end
		end
	end

	-- self.constructArea:constructAreaRender(e)

	if ui.rolecontroller then
		ui:updataRoleControllerPos()
	end

	if #self.selectedBlocks > 0 then
		ui:updataControlerPos()
	end

	if #self.selectedBlockUIs > 0 then
		ui:updataUIControlerPos()
	end

	self.dragSelect:render()
end

editor.selectGroup = function(self, g)
	if not g then return end

	self:cmd_dragSelect(g:getBlocks())
end
editor.onMouseUp_PropertyEdit = function(self, x, y)
	local node = Global.sen:pickNode(x, y, Global.CONSTPICKFLAG.NORMALBLOCK + Global.CONSTPICKFLAG.SELECTBLOCK + Global.CONSTPICKFLAG.GROUPSELECT)
	if node then
		if node.onPick1 then
			node:onPick1()
			return
		end
		if node.block and ui.propertyEditor.isLinking and ui.propertyEditor.targetobject == nil then
			ui.propertyEditor:setCheckObject(node.block)
		elseif ui.propertyEditor.isSelectingObject then
			ui.propertyEditor:setSelectObject(node.block)
		end
	end
end
editor.onMouseUp = function(self, b, x, y)
	if b ~= 0 then return end

	if self.dragSelect:onMouseUp(b, x, y) then
		return
	end

	local node = Global.sen:pickNode(x, y, Global.CONSTPICKFLAG.NORMALBLOCK + Global.CONSTPICKFLAG.SELECTBLOCK + Global.CONSTPICKFLAG.GROUPSELECT)
	if node then
		if node.onPick then
			node:onPick()
			return
		end

		local blk = node.block
		if blk then
			if Global.editor.isMultiSelect then
				self:cmd_ctrlClickSelect(blk)
			else
				self:cmd_clickSelect(blk)
			end

			return
		end
	end

	self:cmd_clickSelect()
end

_dofile('gamemode_edit.lua')
_dofile('gamemode_propertyedit.lua')

return editor