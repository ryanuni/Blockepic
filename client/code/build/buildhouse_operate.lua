local Container = _require('Container')

local BuildHouse = Global.BuildHouse

------------------------------ rot
local restrictionmat = _Matrix3D.new()
BuildHouse.rotBlockBegin = function(self, args, index, axis, delta, restriction)
	local rotbutton = Global.ui.controler.rolatabutton

	-- 旋转轴限制
	if restriction.enable and restriction.type == 2 then
		rotbutton:addRotdata(0, axis, delta, restriction.axis, true)
	else
		rotbutton:addRotdata(index, axis, delta, nil, true)
	end

	-- 旋转中心限制
	if restriction.enable and restriction.type == 2 or restriction.type == 3 then
		restrictionmat:setTranslation(restriction.pos)
		self:cmd_mat_update_begin(restrictionmat, 'rot')
	else
		self:cmd_mat_update_begin(nil, 'rot')
	end

	rotbutton.onMouseDown(args)
	Global.ui:setControlerVisible(false)
end

BuildHouse.rotBlockEnd = function(self, args)
	if Global.ui.controler.rolatabutton.onMouseUp(args) then
		-- 更新组的matrix
		--self:updateGroupRotData(self.rt_selectedGroups, self.rt_transform)

		self:cmd_mat_update_end()
		Global.ui.controler.rolatabutton:clearRotdata()

		return true
	end
end

BuildHouse.rotBlock = function(self, args)
	Global.ui.controler.rolatabutton.onMouseMove(args)

	self:checkBlocking(self.rt_selectedBlocks)
end

------------------------------ move
BuildHouse.onMovingBlock = function(self)
	self:showRotHint(false)
	self:showMovHint(false)
	self:showScaleHint(false)

	self.ui.module_del.visible = false
	self.ui.copybutton.visible = false
	self.ui.bottombg.visible = false
end

BuildHouse.moveBlock = function(self, movex, movey)
	-- 移动block
	local scalef = Global.UI:getScale()

	movex, movey = movex + self.movedx, movey + self.movedy
	local args = {mouse = {x = movex / scalef, y = movey / scalef}}

	local movebutton = self.isplanemove and Global.ui.controler.planemovebutton or Global.ui.controler.movebutton

	movebutton.onMouseMove(args)
	self:onMovingBlock()

	self:checkBlocking(self.rt_selectedBlocks)
end

local movemat = _Matrix3D.new()
BuildHouse.building_moveBegin = function(self, x, y)
	if not self.downX then return end
	if self.rt_moving then return end
	if self:atom_block_selectedNum() == 0 then return end
	if self:distance(x, y, self.downX, self.downY) <= self.movedelta then return end

	self.rt_moving = true
	local scalef = Global.UI:getScale()
	local args = {mouse = {x = self.downX / scalef, y = self.downY / scalef}}
	self.isplanemove = self.planemove and true or false
	local movebutton = self.isplanemove and Global.ui.controler.planemovebutton or Global.ui.controler.movebutton
	movebutton.onMouseDown(args)
	self.movedx, self.movedy = 0, 0

	Global.editor.static_building_setBlocksState(self.rt_selectedBlocks, 'moving')

	Global.normalizePos(self.rt_pos, Global.MOVESTEP.TILE)
	movemat:setTranslation(self.rt_pos)
	self:cmd_mat_update_begin(movemat)
end

BuildHouse.building_move_onMove = function(self, x, y)
	self:building_moveBegin(x, y)

	if not self.rt_moving then return end

	self.movedx, self.movedy = self.mdx, self.mdy
	self:moveBlock(x, y)

	return true
end

BuildHouse.building_move_onEnd = function(self, x, y)
	if not self.rt_moving then return end

	self.rt_moving = false
	local scalef = Global.UI:getScale()
	local args = {mouse = {x = x / scalef, y = y / scalef}, alert = false}
	local movebutton = self.isplanemove and Global.ui.controler.planemovebutton or Global.ui.controler.movebutton
	for i, b in next, self.rt_selectedBlocks do
		if b.isblocking2 then args.alert = b.isblocking2 break end
	end
	movebutton.onMouseUp(args)

	Global.editor.static_building_setBlocksState(self.rt_selectedBlocks, 'selected')
	if x == self.downX and y == self.downY then
		return false
	end

	self:cmd_mat_update_end()

	for i, b in next, self.rt_selectedBlocks do
		b.node.mesh.enableInstanceCombine = false
		local aabb = _AxisAlignedBox.new()

		b:getShapeAABB(aabb)
		print(aabb.min, aabb.max)
		local x = aabb.max.x - aabb.min.x
		local y = aabb.max.y - aabb.min.y
		local z = aabb.max.z - aabb.min.z
		local mat = _Matrix3D.new():setScaling(x * 1.2, y * 1.2, z):mulTranslationRight(0, 0, -z / 2)
		b.node.mesh.pfxPlayer:play('yanchen_001.pfx', mat)
		b.node.mesh.pfxPlayer:play('yanchen_002.pfx', mat)
		Global.Timer:add('fangzhipfx', 200, function()
			b.node.mesh.enableInstanceCombine = true
		end)
	end

	return true
end