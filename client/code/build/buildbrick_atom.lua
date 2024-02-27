local Container = _require('Container')

local bb = _G.BuildBrick
bb.atom_init_rt = function(self)
	self.rt_transform = _Matrix3D.new()
	self.rt_mode = 0
	self.rt_block = nil
	self.rt_pos = _Vector3.new()
	self.rt_selectedBlocks = {}
	self.rt_selectedGroups = {}
	--self.rt_selectedAABB = _AxisAlignedBox.new()
	self:atom_select()
end

bb.onDeleteBlock = function(self, b)
	if self.enableGroup then
		if self.enableRepair then
			self.repair_adds[b:getBlockGroup('root')] = nil
		end

		local g = b:getBlockGroup()
		self:atom_group_del({g})
	end

	b:updateSpace()
	if self:getParam('scenemode') == 'scene_music' then
		self:clearBlockToMusicModule(b)
	end

	self.sen:delBlock(b)
	self:delDynamicBlock(b)
	-- TODO: redo/undo
	if self.music_dummys and self.music_dummys[b] then
		self.music_dummys[b] = nil
	end

	if b.bindmoduleBlocks then
		for bindb in pairs(b.bindmoduleBlocks) do
			self.sen:delBlock(bindb)
		end
	end
end

bb.onAddBlock = function(self, b, isundo)
	if self.enableRepair then
		local g = b:getBlockGroup()
		self:setAddRepair(g)
		self:autoSetRepairRot(g)
	end
end

bb.atom_del = function(self)
	-- delete current selected

	if #self.rt_selectedGroups > 0 then
		for i, g in ipairs(self.rt_selectedGroups) do
			if g.attachpart then
				self:unattachPartGroup(g)
			end
			if self.enableRepair then
				self:removeAddRepair(g)
			end
		end
	end

	for i, b in ipairs(self.rt_selectedBlocks) do
		self:onDeleteBlock(b)
	end

	if #self.rt_selectedGroups > 0 then
		self:atom_group_del(self.rt_selectedGroups)
	end

	self:atom_select()

	self:onBrickChange()
end
-- 添加一块
bb.atom_block_add = function(self, data)
	local b = self:addBlockToScene(data)
	if self.enableRepair then
		local g = b:getBlockGroup()
		self:setAddRepair(g)
		self:autoSetRepairRot(g)
	end
	self:addToFrequent(data)
	self:onBrickChange()

	return b
end
bb.atom_block_add_b = function(self, b)
	self.sen:addBlockUndo(b)
	if self.enableRepair then
		local g = b:getBlockGroup()
		self:setAddRepair(g)
		self:autoSetRepairRot(g)
	end

	if b.bindmodule then
		self:loadMarkerBlocks(b, b.bindmodule)
	end

	if b.dfdata_recover then
		self:recoverBlockDfData(b)
	end

	self:onBrickChange()
end

bb.atom_block_del = function(self, b)
	self:onDeleteBlock(b)
	self:onBrickChange()
end
bb.atom_block_del_s = function(self, bs)
	for i, b in ipairs(bs) do
		self:onDeleteBlock(b)
	end

	self:onBrickChange()
end

-- 处理不同的情况下的选择积木
bb.atom_block_select_prepare = function(self, b, mode)
	if self:isMultiSelecting() then -- 多选模式
		-- 若b已经选中, 反选并且返回
		if self:atom_block_isSelected(b) then
			local g = b:getBlockGroup('tempRoot')
			local gs = {}
			for i, v in ipairs(self.rt_selectedGroups) do
				gs[v] = true
			end
			gs[g] = nil

			self:atom_group_select_batch(gs)

			self:atom_group_merge({g}, self.rt_selectedGroups)
			return false
		end
	elseif self.mode == 'repair' then -- 修复模式
		if self.repair_dels[b] then
			-- 长按已修复的积木时拆下修复, 否则不做进一步的而选中
			if b.repairGroup and mode == 1 then
				self.rt_block = b.repairGroup
				self:bindDelRepair(b, nil)
			else
				return false
			end
		end
	else
		self:atom_group_merge(self.rt_selectedGroups)
	end

	return true
end

bb.atom_block_select_ex = function(self, b, pos, mode)
	--print('[atom_block_select_ex]', b, mode, debug.traceback())

	-- b必不为空且不能已选中
	--assert(b and not self:atom_block_isSelected(b))

	local bs = {}

	if self.enableGroup then
		local g
		if mode == 0 then
			g = self:decomposeGroupWithBackUp(b, 0)
		else
			g = self:decomposeGroupWithBackUp(b, 1)
		end

		if self:isMultiSelecting() then
			self:atom_group_batch_add(g)
		else
			self:atom_group_select(g)
		end
	else
		table.insert(bs, b)
		self:atom_block_select(bs)
	end
end
bb.atom_block_select = function(self, bs)
	Global.editor.static_building_selectBlocks(self.rt_selectedBlocks, false)
	bs = bs or {}
	Tip()
	self.rt_selectedBlocks = table.clone(bs)
	Global.editor.static_building_selectBlocks(self.rt_selectedBlocks, true)

	--Block.getShapeAABBs(bs, self.rt_selectedAABB)

	-- 选定绑定部位时, 禁用移动和旋转
	self.enableBrickMat = true
	for i, v in ipairs(bs) do
		if v.part or (v.bindTrain and (self:isPoleBlock(v) or self:isFloorBlock(v))) or self.logicEditing then
			self.enableBrickMat = false
			break
		end
	end

	if self.last_selected and self.enableGraffiti then
		self.enableGraffiti = false
	end
	--print('enableBrickMat', self.enableBrickMat)
end
bb.atom_block_bindTransform = function(self, mat)
	if mat then
		copyMat(self.rt_transform, mat)
	else
		-- calc transform by aabb center
		Global.editor.static_building_calcTransform(self.rt_selectedBlocks, self.rt_transform)
	end

	self:static_building_setupTransform()
end
bb.atom_block_unbindTransform = function(self, updatespace)
	--Global.editor.static_building_unsetTransform(self.rt_selectedBlocks)
	self:static_building_unsetTransform()
end

bb.static_building_setupTransform = function(self)
	-- if self.enableGroup then
	-- 	for i, g in ipairs(self.rt_selectedGroups) do
	-- 		local gmat = g:getTransform()
	-- 		gmat:bindParent(self.rt_transform)
	-- 	end

	-- 	for i, b in ipairs(self.rt_selectedBlocks) do
	-- 		local g = b:getBlockGroup()
	-- 		b:setParent(g:getTransform())
	-- 	end

	-- 	Global.editor.static_building_bindController(self.rt_selectedBlocks, self.rt_transform)
	-- else
		Global.editor.static_building_setupTransform(self.rt_selectedBlocks, self.rt_transform)
	--end
end

bb.static_building_unsetTransform = function(self)
	-- if self.enableGroup then
	-- 	for i, g in ipairs(self.rt_selectedGroups) do
	-- 		local gmat = g:getTransform()
	-- 		gmat:unbindParent()
	-- 	end

	-- 	for i, b in ipairs(self.rt_selectedBlocks) do
	-- 		b:setParent()
	-- 	end
	-- else
		Global.editor.static_building_unsetTransform(self.rt_selectedBlocks)
	-- end
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
bb.atom_block_setMaterial = function(self, b, data)
	b:setMaterialBatch(data)
end
------------------------------------------------------
bb.atom_CONs_prepareBackup = function(self, bs)
	if not self.enableGroup then return end

	local connects = {}
	local overlaps = {}
	local neighbors = {}

	for i, block in ipairs(bs) do
		for b, data in pairs(block.connects) do
			table.insert(connects, data)
		end
		for b, data in pairs(block.overlaps) do
			table.insert(overlaps, {b1 = block, b2 = b})
		end
		for b, data in pairs(block.neighbors) do
			table.insert(neighbors, {b1 = block, b2 = b})
		end
	end

	local CONs = {
		connects = connects,
		overlaps = overlaps,
		neighbors = neighbors,
		bs = bs,
	}

	return CONs
end
bb.atom_CONs_use = function(self, connects, overlaps, neighbors)
	for i, data in pairs(connects) do
		data.b1:addConnects(data.b2, data.s2, data.s1)
	end
	for i, data in pairs(overlaps) do
		data.b1:addOverlap(data.b2)
	end
	for i, data in pairs(neighbors) do
		data.b1:addNeighbor(data.b2)
	end
end

bb.atom_CONs_useBackup = function(self, CONs)
	if not self.enableGroup then return end

	local bs = CONs.bs
	for i, b in ipairs(bs) do
		b:clearOverlaps()
		b:clearNeighbors()
		b:clearConnects()

		local kg = b:getKnotGroup()
		kg:clearCollisions()
	end

	self:atom_CONs_use(CONs.connects, CONs.overlaps, CONs.neighbors)
end
------------------------------------------------------

bb.atom_groups_prepareBackup = function(self, bs)
	if not self.enableGroup then return end

	-- TODO: tempRoot
	local gsinfo = {}
	local gs = {}
	self:getAllGroups(gs)
	self:saveGroupInfos(gs, gsinfo, true)

	gsinfo.selectedGroup = {}
	for i, g in ipairs(self.rt_selectedGroups) do
		assert(not g:getParent(true))
		table.insert(gsinfo.selectedGroup, g:getIndex())
	end

	gsinfo.groupStack = {}
	for i, g in ipairs(self.groupStack) do
		table.insert(gsinfo.groupStack, g:getIndex())
	end

	if self.edit_group then
		gsinfo.edit_group = self.edit_group:getIndex()
	end

	return gsinfo
end
bb.atom_groups_useBackup = function(self, gsinfo, partinfo, select)
	if not self.enableGroup then return end

	local gs = self:loadGroupInfos(gsinfo, nil, true)

	self:atom_part_useBackup(partinfo, gs)

	if select and #gsinfo.selectedGroup > 0 then
		local selgs = {}
		for i, gi in ipairs(gsinfo.selectedGroup) do
			local g = gs[gi]
			assert(not g:getParent(true))
			table.insert(selgs, g)
		end
		self:atom_group_select_batch(selgs)
	else
		self:atom_group_select()
	end

	self.groupStack = {}
	if #gsinfo.groupStack > 0 then
		for i, gi in ipairs(gsinfo.groupStack) do
			local g = gs[gi]
			table.insert(self.groupStack, g)
		end
	end

	self.edit_group = nil
	if gsinfo.edit_group then
		self.edit_group = gs[gsinfo.edit_group]
	end

	return gs
end

------------------------------------------------------
bb.atom_part_prepareBackup = function(self)
	if not self.enablePart then return end
	local partinfo = {}
	for name, part in pairs(self.parts) do
		partinfo[name] = {}
		partinfo[name].bind = part.group and part.group.index
		for i, g in ipairs(part.attachs) do
			table.insert(partinfo[name], g.index)
		end
	end

	return partinfo
end
bb.atom_part_useBackup = function(self, partinfo, gs)
	if not self.enablePart then return end

	self:clearAllAttaches()
	for name, part in pairs(self.parts) do
		local info = partinfo[name]
		if info then
			if info.bind then
				self:bindPartGroupData(part, gs[info.bind])
			end

			for i, gi in ipairs(info) do
				self:addAttachPartData(part, gs[gi])
			end
		end
	end
end

----------------------------------------
bb.atom_prepareBackup = function(self, bs)
	local backup = {}
	backup.gs = self:atom_groups_prepareBackup()
	backup.CONs = self:atom_CONs_prepareBackup(bs)
	backup.ps = self:atom_part_prepareBackup()
	backup.bs = table.clone(bs)

	return backup
end

bb.atom_useBackup = function(self, backup, select)
	--print('atom_useBackup', select)
	self:atom_CONs_useBackup(backup.CONs)
	local gs = self:atom_groups_useBackup(backup.gs, backup.ps, select)
	if not self.enablePart then
		self:atom_block_select(backup.bs)
	end
end

------------------------------------------------------
bb.atom_group_expire_combine_backup = function(self)
	if self.disableGroupCombine then return end

	self:expireRecombineBackup(self.rt_selectedGroups)
end

bb.atom_lock2_blink = function(self, blocks)
	local gs = {}
	self:getGroups(gs, blocks)

	-- 旋转轴闪烁
	local bs = {}
	for _, g in ipairs(gs) do
		--if g:isLock2() and g:isLock2Dirty() then
		if g:isLock2() then
			g:getBlocks(bs)
		end

		g:resetLock2Dirty()
	end

	-- if #bs > 0 then
	-- 	for i, b in ipairs(bs) do
	-- 		b.oldmtl = b:getMaterial()
	-- 		b:setMaterial(Global.MtlBuildCorrect)
	-- 		if b.node.mesh.material then
	-- 			b.node.mesh.material:useLerpState(2)
	-- 		end
	-- 		b.node.instanceGroup = 'blink'
	-- 	end

	-- 	self.timer:start('repairmtl', 600, function()
	-- 		for i, b in ipairs(bs) do
	-- 			b:setMaterial(b.oldmtl)
	-- 			b.oldmtl = nil
	-- 			b.node.instanceGroup = ''
	-- 		end

	-- 		self.timer:stop('repairmtl')
	-- 	end)
	-- end

	-- print('#############bs', #bs)
end

bb.atom_group_merge = function(self, gs, skipgroups)
	if not self.enableGroup then return end

	local nbs = {}
	for i, g in ipairs(gs) do
		g:getBlocks(nbs)
	end

	local gs2 = {}
	for i, g in ipairs(gs) do
		if not self:useRecombineBackup(g) then
			table.insert(gs2, g)
		end
	end

	-- if #gs > 0 then
	-- 	print('atom_group_merge', needcombind, #gs)
	-- end

	--print('disableGroupCombine', self.disableGroupCombine)
	if #gs2 > 0 and not self.disableGroupCombine then
		self:recombineGroups(gs2, skipgroups)
	end

	self:clearEmptyGroup()

	self:atom_lock2_blink(nbs)
end

bb.atom_group_merge_one = function(self)
	if #self.rt_selectedGroups == 0 then
		return
	end

	if #self.rt_selectedGroups == 1 then
		return self.rt_selectedGroups[1]
	end

	self:atom_group_expire_combine_backup()

	local p = self:newGroup()
	for i, g in ipairs(self.rt_selectedGroups) do
		p:addChild(g)
	end
	self:atom_group_select(p)

	return p
end

bb.atom_group_del = function(self, gs)
	if not self.enableGroup then return end

	for i, g in ipairs(gs) do
		g:clear()
	end
	self:clearEmptyGroup()
end

bb.atom_group_select = function(self, g, skipevent)
	if not self.enableGroup then return end

	local bs = {}
	if g then
		assert(not g:getParent(true))
		g:getBlocks(bs)
	end
	self:atom_block_select(bs)

	self.rt_selectedGroups = {g}

	if not skipevent then
		if self.enableRepair then
			self:onSelectRepairGroup(self.rt_selectedGroups)
		else
			self:onSelectGroup(self.rt_selectedGroups)
		end
	end
end
bb.atom_group_select_batch = function(self, gs)
	if not self.enableGroup then return end

	self.rt_selectedGroups = {}
	local bs = {}

	if next(gs) then
		-- 支持hash和数组
		if #gs > 0 then
			for i, g in ipairs(gs) do
				assert(not g:getParent(true))
				g:getBlocks(bs)
				table.insert(self.rt_selectedGroups, g)
			end
		else
			for g in pairs(gs) do
				assert(not g:getParent(true))
				g:getBlocks(bs)
				table.insert(self.rt_selectedGroups, g)
			end
		end
	end

	self:atom_block_select(bs)
	if self.enableRepair then
		self:onSelectRepairGroup(self.rt_selectedGroups)
	else
		self:onSelectGroup(self.rt_selectedGroups)
	end
end

bb.atom_group_batch_add = function(self, group)
	assert(not group:getParent(true))
	local gs = {}
	for i, g in ipairs(self.rt_selectedGroups) do
		gs[g] = true
	end

	gs[group] = true

	self:atom_group_select_batch(gs)
end

bb.atom_select = function(self, g, bs)
	if self.enableGroup then
		self:atom_group_select(g)
	else
		self:atom_block_select(bs)
	end
end

bb.atom_group_update = function(self)

end
bb.atom_group_lock = function(self, lock)
	if not self.enableGroup then return end

	assert(#self.rt_selectedGroups == 1)

	local g = self.rt_selectedGroups[1]
	g:setLock(lock)

	self:onGroupLock(g)
end
bb.atom_group_dirty = function(self)
	if not self.enableGroup then return end

	for i, g in ipairs(self.rt_selectedGroups) do
		g:setDirty()
	end
end

bb.atom_group_knot_dirty = function(self)
	if not self.enableGroup then return end

	for i, g in ipairs(self.rt_selectedGroups) do
		g:setKnotCombineDirty()
	end
end

bb.atom_group_copy = function(self, cres)
	if not self.enableGroup then return end

	local selgs = self.rt_selectedGroups

	local gs_hash = {}
	for i, g in ipairs(selgs) do
		assert(g)
		--assert(g:checkNullOuterCONs())
		assert(not g:getParent(true))
		g:getConnects(gs_hash, true)
	end

	local gs = {}
	for g in pairs(gs_hash) do
		table.insert(gs, g)
	end

	for i, b in ipairs(self.rt_selectedBlocks) do
		b.index = i
	end
	local groupinfos = {}
	self:saveGroupInfos(gs, groupinfos)

	local connects, overlaps, neighbors = {}, {}, {}
	self:saveOverlapInfo(self.rt_selectedBlocks, connects, overlaps, neighbors)

	-- 合并之前的选中
	self:atom_group_merge(self.rt_selectedGroups)

	cres.cblist = {}
	for i, b in ipairs(self.rt_selectedBlocks) do
		local nb = self.sen:cloneBlock2(b)
		--nb:move(0, 0.4, 0) 
		nb.node.transform:mulTranslationRight(0, 0.4, 0)
		nb:formatMatrix()
		if b.chips_s then
			nb.chips_s = {}
			table.deep_clone(nb.chips_s, b.chips_s)
		end
		if b.markerdata then
			local markerdata = {}
			b.markerdata:saveToData(markerdata)
			markerdata.bindblock = nil -- TODO: 处理bindblock的拷贝
			nb.markerdata = BMarker.new(markerdata)
			nb:setAABBSkipped(true)
			--self:loadMarkerBlocks(nb, b.bindmodule)
		end
		if b.bindmodule then -- TODO:
			-- local m = {}
			-- table.deep_clone(m, b.bindmodule)
			self:loadMarkerBlocks(nb, b.bindmodule)
		end

		if self:isMusicMode('music_train') then
			self:setMusicDummy(nb)
		end
		table.insert(cres.cblist, nb)
	end

	local ngs = self:loadGroupInfos(groupinfos, cres.cblist)
	self:loadOverlapInfo(cres.cblist, connects, overlaps, neighbors)

	local selgs2 = {}
	for i, g in ipairs(ngs) do
		g.isTempRoot = false
		if not g:getParent(true) then
			table.insert(selgs2, g)
		end
	end
	self:atom_group_select_batch(selgs2)
	for i, g in ipairs(self.rt_selectedGroups) do
		g:clearOuterCONs()
		g:clearOuterCollisions()
	end

	self:atom_block_bindTransform()
	if cres.pos then
		Global.normalizePos(cres.pos, Global.MOVESTEP.TILE)
		self.rt_transform:setTranslation(cres.pos)
	else
		cres.pos = _Vector3.new()
		local ab = _AxisAlignedBox.new()
		Block.getAABBs(cres.cblist, ab)
		local center = _Vector3.new()
		ab:getBottom(center)

		local pickflag = Global.CONSTPICKFLAG.NORMALBLOCK
		local type1 = Global.dir2AxisType(Global.DIRECTION.RIGHT, Global.AXISTYPE.Z)
		local type2 = Global.dir2AxisType(Global.DIRECTION.LEFT, Global.AXISTYPE.Z)
		if self:getParam('scenemode') == 'scene_music' then
			type1 = Global.AXISTYPE.NX
			type2 = Global.AXISTYPE.X
		end

		local collfunc = self.enableRepair and self:getRepairCollfunc() or nil
		if not self:findUncollidedPos(cres.pos, ab, center, {type1}, pickflag, collfunc) then
			self:findUncollidedPos(cres.pos, ab, center, {type2}, pickflag, collfunc)
		end
		local diff = ab:diffBottom(cres.pos)
		Global.normalizePos(cres.pos, Global.MOVESTEP.TILE)

		self.rt_transform:mulTranslationRight(diff)
		self.rt_transform:getTranslation(cres.pos)
	end
	self:atom_block_unbindTransform()
end

bb.setBlocksSkipped = function(self, nbs, skip)
	for i, b in ipairs(nbs) do
		b:setSkipped(skip)
		--b.skipped = skip
		--b.node.visible = not skip
	end
end

bb.atom_group_enter = function(self, g)
	if self.edit_group then
		self:atom_group_leave()
	end

	-- 回到主场景
	if not g then
		local nbs = {}
		self:getAllBlocks(nbs)
		self:setBlocksSkipped(nbs, false)
		return
	end

	assert(g:isLock())

	local nbs = {}
	self:getBlocks(nbs)
	self:setBlocksSkipped(nbs, true)

	local bs = {}
	g:getBlocks(bs, 'children')
	self:setBlocksSkipped(bs, false)

	self.edit_group = g
	g:clearData()
	g.isUsing = true
end

bb.atom_group_leave = function(self)
	if not self.edit_group then return end
	local g = self.edit_group
	self.edit_group = nil

	local gs = {}
	self:getRootGroups(gs)
	for i, c in ipairs(gs) do
		g:addChild(c)
	end
	g.isUsing = false
	g:setLock(true)

	-- print('atom_group_leave', g)

	return g
end
-------------------------------------------------------
bb.atom_paint_add = function(self, b, img)
	if self.dfEditing then
		--self:initFrameValue(b, 'paint')
		local currframe = self:getCurrentFrame()
		local paint = PaintInfo.new()
		paint:setPaintRes(img, nil, b.node.transform)
		-- print('paint', paint and paint.typestr)
		self:addDFFrameDatas(currframe, 'paint', {b}, paint)
		self:updateCurrentDFrame()
	else
		local paint = b.data.paintInfo
		paint:setPaintRes(img, nil, b.node.transform)
		b:refreshMesh()
	end
end

bb.atom_paint_del = function(self, b)
	if self.dfEditing then
		--self:initFrameValue(b, 'paint')
		local currframe = self:getCurrentFrame()
		local paint = PaintInfo.new()
		paint:set()
		self:addDFFrameDatas(currframe, 'paint', {b}, paint)
		self:updateCurrentDFrame()
	else
		local paint = b.data.paintInfo
		paint:set()
		b:refreshMesh()
	end
end

bb.atom_paint_move = function(self, b, dir, step)
	if self.dfEditing then
		local currframe = self:getCurrentFrame()
		local paint = self:getFrameData(currframe, b, 'paint')
		if not paint then paint = b.data.paintInfo end
		paint:movePaint(dir, step, b.node.transform)
		self:addDFFrameDatas(currframe, 'paint', {b}, paint)
		self:updateCurrentDFrame()
	else
		local paint = b.data.paintInfo
		paint:movePaint(dir, step, b.node.transform)
		b:refreshMesh()
	end
end

bb.atom_paint_rot = function(self, b, r)
	if self.dfEditing then
		local currframe = self:getCurrentFrame()
		local paint = self:getFrameData(currframe, b, 'paint')
		if not paint then paint = b.data.paintInfo end

		paint:rotatePaint(r, b.node.transform)
		self:addDFFrameDatas(currframe, 'paint', {b}, paint)
		self:updateCurrentDFrame()
	else
		local paint = b.data.paintInfo
		paint:rotatePaint(r, b.node.transform)
		b:refreshMesh()
	end
end

bb.atom_paint_scale = function(self, b, scale)
	if self.dfEditing then
		local currframe = self:getCurrentFrame()
		local paint = self:getFrameData(currframe, b, 'paint')
		if not paint then paint = b.data.paintInfo end
		paint:scalePaint(scale, b.node.transform)
		self:addDFFrameDatas(currframe, 'paint', {b}, paint)
		self:updateCurrentDFrame()
	else
		local paint = b.data.paintInfo
		paint:scalePaint(scale, b.node.transform)
		b:refreshMesh()
	end
end
-------------------------------------------------------
bb.atom_part_bind = function(self, g, part)
	assert(g)
	assert(part)
	--assert(not g.parent)

	self:bindPartGroup(part, g)
	if self.ui.partlist.visible then
		self:showPartList(true)
	end

	local editing = self.partopt ~= 'exit'
	if editing then
		local bs = {}
		self:getBindBlocks(g, bs)
		for i, b in ipairs(bs) do
			b.node.visible = true
		end
	end
end
bb.atom_part_unbind = function(self, part)
	assert(part.group)

	local g = part.group
	self:unbindPartGroup(part)
	if self.ui.partlist.visible then
		self:showPartList(true)
	end

	local editing = self.partopt ~= 'exit'
	if editing then
		local bs = {}
		self:getBindBlocks(g, bs)
		for i, b in ipairs(bs) do
			b.node.visible = false
		end
	end
end
bb.atom_part_setDirty = function(self)
	for n, p in pairs(self.parts) do
		if p.group then
			p.group:setDirty()
			p.group:setKnotCombineDirty()
		end

		if p.attachs then
			for i, g in ipairs(p.attachs) do
				g:setDirty()
				g:setKnotCombineDirty()
			end
		end
	end
end

bb.atom_camera_bind = function(self, bind, camera)
	if bind then
		Global.CameraControl:push()
		local cc = Global.CameraControl:get()
		if camera then
			cc:setCamera(camera)
			cc:update()
			cc:use()
		end
	else
		Global.CameraControl:pop()
	end

	self.cc = Global.CameraControl:get()
end

---------------- Frames ---------------------
bb.atom_frame_new = function(self, time, fdata)
	local f = self:insertDFFrame(time)
	self:copyFrameData(f, fdata)

	return f
end

bb.atom_frame_del = function(self, frame)
	local frames = self:getDFFrames()

	for i, f in ipairs(frames) do
		if f == frame then
			table.remove(frames, i)
			break
		end
	end

	if self.currentDframe == frame then
		self:onSelectDFrame(frames[1])
	end

	self:updateDFramesTime()
	self:setTransitionDirty()
end