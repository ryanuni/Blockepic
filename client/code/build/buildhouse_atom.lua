
local Container = _require('Container')
local bb = Global.BuildHouse
bb.atom_init_rt = function(self)
	self.rt_transform = _Matrix3D.new()
	self.rt_mode = 0
	self.rt_block = nil
	self.rt_selectedBlocks = {}
	self.rt_pos = _Vector3.new()
end

bb.atom_del = function(self)
	-- delete current selected
	for i, b in ipairs(self.rt_selectedBlocks) do
		b.node.mesh.enableInstanceCombine = false
		b.node.mesh.pfxPlayer:play('shanchu_001.pfx')
		Global.Timer:add('delBlock', 200, function() 
			b.node.mesh.enableInstanceCombine = true
			self.sen:delBlock(b)
		end)
	end
	self:atom_block_select()
end
-- 删除一块
bb.atom_block_add = function(self, data)
	local b = self:addBlockToScene(data)

	return b
end
bb.atom_block_add_b = function(self, b)
	self.sen:addBlockUndo(b)
end
bb.atom_block_del = function(self, b)
	self.sen:delBlock(b)
end
bb.atom_block_del_s = function(self, bs)
	for i, b in ipairs(bs) do
		self.sen:delBlock(b)
	end
end
bb.atom_block_select_ex = function(self, b, pos, mode)
--	print('[atom_block_select_ex]', b, mode, debug.traceback())
	self.rt_mode = mode
	self.rt_block = b
	if pos then
		self.rt_pos:set(pos.x, pos.y, pos.z)
	else
		self.rt_pos:set(0, 0, 0)
	end

	local bs = {}
	table.insert(bs, b)
	self:atom_block_select(bs)
	self:onSelectBlock(b)
end
bb.atom_block_select = function(self, bs)
	Global.editor.static_building_selectBlocks(self.rt_selectedBlocks, false)
	bs = bs or {}
--	print('atom_block_select', bs, #bs)
	if #bs > 0 then
		Tip(Global.TEXT.TIP_BUILDHOUSE_BLOCK)
	else
		Tip()
	end
	self.rt_selectedBlocks = table.clone(bs)
	Global.editor.static_building_selectBlocks(self.rt_selectedBlocks, true)
end

bb.atom_block_copy = function(self, cres)
	for i, b in ipairs(self.rt_selectedBlocks) do
		b.index = i
	end

	cres.cblist = {}
	for i, b in ipairs(self.rt_selectedBlocks) do
		local nb = self.sen:cloneBlock2(b)
		nb:move(0.2, 0, 0)
		table.insert(cres.cblist, nb)
	end

	self:atom_block_select(cres.cblist)
	self:atom_block_bindTransform()
	if cres.pos then
		Global.normalizePos(cres.pos, Global.MOVESTEP.TILE)
		self.rt_transform:setTranslation(cres.pos)
	else
		local aabb = Container:get(_AxisAlignedBox)
		Block.getAABBs(self.rt_selectedBlocks, aabb)
		cres.pos = _Vector3.new()
		self:findPlacePosition(aabb, cres.pos)

		local diff = aabb:diffBottom(cres.pos)
		self.rt_transform:mulTranslationRight(diff)
		self.rt_transform:getTranslation(cres.pos)
		Container:returnBack(aabb)
	end
	self:atom_block_unbindTransform()

end
bb.atom_block_bindTransform = function(self, mat)
	if mat then
		copyMat(self.rt_transform, mat)
	else
		-- calc transform by aabb center
		Global.editor.static_building_calcTransform(self.rt_selectedBlocks, self.rt_transform)
	end

	Global.editor.static_building_setupTransform(self.rt_selectedBlocks, self.rt_transform)
end
bb.atom_block_unbindTransform = function(self)
	Global.editor.static_building_unsetTransform(self.rt_selectedBlocks)
end
bb.atom_block_selectedNum = function(self)
	return #self.rt_selectedBlocks
end
bb.atom_block_isSelected = function(self, b)
	if not b then
		return #self.rt_selectedBlocks == 0
	end

	for _, block in ipairs(self.rt_selectedBlocks) do
		if b == block then
			return true
		end
	end

	return false
end