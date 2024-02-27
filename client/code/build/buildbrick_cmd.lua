
--[[
	todo:
		材质的undo
		module的undo
		骨骼的undo

		替换到线上
			和editor的cmd断开
		干掉building_
		干掉_reconstruct
]]
local BuildBrick = _G.BuildBrick
local Container = _require('Container')

-- 加块
BuildBrick.cmd_addBrick = function(self, blockdata, select)
	local redo = function(data)
		self:showPropList(false)
		local b
		if data then
			b = data.backup.bs[1]
			-- select依赖的是b，所以需要保证b是同一个
			self:atom_block_add_b(b)
			self:atom_useBackup(data.backup)
		else
			data = {}
			b = self:atom_block_add(blockdata)
			data.backup = self:atom_prepareBackup({b})
			data.select = select
			data.editdf = self.dfEditing
			data.currframe = data.editdf and self:getCurrentFrame()
		end

		if data.select then
			if self.enableGroup then
				self:atom_group_select(b:getBlockGroup('tempRoot'))
			else
				self:atom_block_select({b})
			end
		end

		if data.editdf then
			local frames = self:getDFFrames()
			for i, f in ipairs(frames) do
				self:addDFFrameDatas(f, 'alpha', {b}, f == data.currframe and 1 or 0)
			end

			self:updateCurrentDFrame()
		end

		self:refreshModuleIcon()
		return data
	end
	local undo = function(data)

		self:atom_block_del(data.backup.bs[1])
		self:refreshModuleIcon()
		self:showPropList(false)

		if data.select then
			self:atom_select()
		end

		self:updateCurrentDFrame()
	end

	return self:addCommand(redo, undo, 'addBrick', blockdata.shape)
end
BuildBrick.cmd_addBrick2 = function(self, quality, shape)
	local mtl = Global.BrickQuality[quality].mtls[1]
	local data = {shape = shape, assumeQuality = quality,
		material = mtl.material, mtlmode = mtl.mtlmode, color = mtl.color, roughness = mtl.roughness}

	local adddata = self:cmd_addBrick(data, true)
	return adddata.backup.bs[1]
end
-- 选中
	-- 拿到pickedblock
local selectundofunc
local timer = _Timer.new()
BuildBrick.cmd_select_begin = function(self, b, pos)
	if b then Global.Sound:play('build_pick01') end

	--local bs = table.clone(self.rt_selectedBlocks)
	local backup0 = self:atom_prepareBackup(self.rt_selectedBlocks)
	local mode = self.rt_mode

	self.rt_block = b
	self.cmd_selecting = true
	if pos then
		self.rt_pos:set(pos.x, pos.y, pos.z)
	else
		self.rt_pos:set(0, 0, 0)
	end

	selectundofunc = function()
		self.rt_mode = mode
		self:atom_useBackup(backup0, true)
		self:showPropList(false)
	end

	--print('cmd_select_begin', self.rt_mode)

	timer:start('', 500, function()
		self:cmd_selectHeavy()
		timer:stop()
	end)
end
BuildBrick.cmd_select_cancel = function(self)
	timer:stop()
end
-- return 0 : 点击空白 1: 普通点击 2: 长按
BuildBrick.cmd_select_end = function(self, endmode)
	if not self.cmd_selecting then return -1 end

	--print('cmd_select_end', self.rt_mode)

	local mode = self.rt_mode
	self:cmd_select_cancel()
	self.rt_mode = 0
	self.cmd_selecting = false

	if mode == 1 then
		-- 长按500ms后自动触发，不在end的时候处理
		-- self:cmd_selectHeavy()
		return 2
	elseif self.rt_block then
		self:cmd_selectLight(endmode)
		return 1
	elseif self.rt_selectedBlocks[1] then
		self:cmd_selectNull()
		return 0
	end

	return 0
end

-- 取消选中
BuildBrick.cmd_selectNull = function(self)
	assert(self.rt_mode == 0 and not self.rt_block and self.rt_selectedBlocks[1])

	local selectnullfunc = function(backup)
		self.rt_mode = 0
		if backup then
			self:atom_useBackup(backup, true)
		else
			self:atom_group_merge(self.rt_selectedGroups)

			self:atom_select()
			backup = self:atom_prepareBackup(self.rt_selectedBlocks)
		end

		self:showPropList(false)

		return backup
	end

	self:addCommand(selectnullfunc, selectundofunc, 'Select:null')

	return 0
end

-- 普通点击
BuildBrick.cmd_selectLight = function(self, mode)
	assert(self.rt_mode == 0 and self.rt_block)

	if self:atom_block_isSelected(self.rt_block) then
		if self:isMultiSelecting() and mode ~= 'move' then
			-- 需要反选，redo中执行(点击后直接移动不触发反选)
		else
			-- 同样的选择
			if mode == 'move' then
				return
			end

			if self.enableGroup then
				if #self.rt_selectedGroups == 1 then
					return
				end
			else
				if #self.rt_selectedBlocks == 1 then
					return
				end
			end
		end
	end

	local redo = function(backup)
		self.rt_mode = 0
		if backup then
			self:atom_useBackup(backup, true)
		else
			if self:atom_block_select_prepare(self.rt_block, 0) then
				self:atom_block_select_ex(self.rt_block, self.rt_pos, 0)
			end

			backup = self:atom_prepareBackup(self.rt_selectedBlocks)
		end

		return backup
	end

	self:addCommand(redo, selectundofunc, 'Select:light')
end
-- 长按(split & select)
BuildBrick.cmd_selectHeavy = function(self)
	if self.disableGroupCombine then return end
	if not self.cmd_selecting then return end

	self:cmd_select_cancel()

	--print('cmd_selectHeavy', self.rt_block)
	--长按空白
	if self.rt_block == nil then
		return
	end

	if self:atom_block_isSelected(self.rt_block) then
		if self:isMultiSelecting() then
			-- 需要反选，redo中执行
		else
			-- 同样的选择
			if self.rt_mode == 1 then
				return
			end
		end
	end

	local redo = function(backup)
		self.rt_mode = 1
		self:showPropList(false)
		if backup then
			self:atom_useBackup(backup, true)
		else
			if self:atom_block_select_prepare(self.rt_block, 1) then
				self:atom_block_select_ex(self.rt_block, self.rt_pos, 1)
			end
			backup = self:atom_prepareBackup(self.rt_selectedBlocks)
		end

		return backup
	end
	-- 拿到
	-- select group
	self:addCommand(redo, selectundofunc, 'Select:heavy')

	return true
end
-- 删块
BuildBrick.cmd_delBrick = function(self)
	if self:atom_block_selectedNum() == 0 then return end

	if self:isSelectedMusicRunway() then
		self:delMusicRunway(self.rt_selectedBlocks)
		return
	elseif self:isSelectedMusicPole() then
		self:delMusicPole(self.rt_selectedBlocks)
		return
	end

	-- 禁止删除物件
	if not self.enableOpenLib or not self.enableBrickMat then
		return
	end

	if self.enablePart then
		for i, b in ipairs(self.rt_selectedBlocks) do
			if b.part then
				Notice(Global.TEXT.NOTICE_DEL_FAILED)
				return
			end
		end
	end

	self:atom_group_expire_combine_backup()

	local backup = self:atom_prepareBackup(self.rt_selectedBlocks)
	local undo = function(data)
		-- add bs back

		if data.editdf then
			self:addDFFrameDatas(data.currframe, 'alpha', self.rt_selectedBlocks, data.alpha == 0 and 1 or 0)

			self:updateCurrentDFrame()
			self:onSelectGroup(self.rt_selectedGroups)
		else
			for i, b in ipairs(backup.bs) do
				self:atom_block_add_b(b)
			end

			self:atom_useBackup(backup, true)
		end

		self:showPropList(false)
		self:refreshModuleIcon()

		if self.enableRepair then
			self:checkRepaired()
			self:onCheckRepair()
		end

		self:updateCurrentDFrame()
	end

	local redo = function(data0)
		-- 删除时仅可能去掉箭头
		self:showPropList(false)

		local data = data0 or {}
		if not data0 then
			data.editdf = self.dfEditing
			if data.editdf then
				data.currframe = self:getCurrentFrame()
				data.alpha = self:isBlocksTransparent(self.rt_selectedBlocks, data.currframe) and 1 or 0
			end
		end

		if data.editdf then
			self:addDFFrameDatas(data.currframe, 'alpha', self.rt_selectedBlocks, data.alpha)

			self:updateCurrentDFrame()
			self:onSelectGroup(self.rt_selectedGroups)
		else
			self:atom_del()
		end

		self:refreshModuleIcon()

		return data
	end

	self:addCommand(redo, undo, 'Delbrick')
end

local helpmat = _Matrix3D.new()
-- 旋转/位移
-- mode : rot/move
local updateundofunc
-- b0 --bind-> b1m1(b0) --update-> b1m2 --unbind-> b2 m2
local updateinitmat = _Matrix3D.new()
local updatemode = ''
BuildBrick.cmd_mat_update_begin = function(self, mat, mode)
	if self:atom_block_selectedNum() == 0 then return end
	-- if mode ~= 'rot' and mode ~= 'rotpivot' then
		self:atom_group_expire_combine_backup()
	-- end

	self:atom_block_bindTransform(mat)
	local mat1 = _Matrix3D.new()
	copyMat(mat1, self.rt_transform)

	-- redo 需要知道起始parent
	copyMat(updateinitmat, self.rt_transform)

	updatemode = mode
	self:showPropList(false)

	-- 缓存位移前的矩阵，用于初始化动画中每帧的矩阵数据 TODO:优化
	if self.dfEditing then
		for i, b in ipairs(self.rt_selectedBlocks) do
			b:addCacheTransform()
		end
	end

	updateundofunc = function(data)
		local mat2 = data.mat
		self:showPropList(false)

		self:atom_block_bindTransform(mat2)
		copyMat(self.rt_transform, mat1)
		self:atom_group_dirty()

		self:atom_block_unbindTransform()

		if self.enableRepair then
			self:checkRepaired()
			self:onCheckRepair()
		end

		if data.editdf then
			local frame0 = data.editdf and data.currframe or self:getFirstFrame()
			self:addDFFrameDatas(frame0, 'transforms', self.rt_selectedBlocks, data.pivot, updatemode)
		end

		if data.editdf then self:updateCurrentDFrame() end

		self:refreshModuleIcon()
		self:checkMusicDummy()
	end
end

local helppivot = _Vector3.new()
local helpcenter = _Vector3.new()
BuildBrick.cmd_mat_update_end = function(self)
	if self:atom_block_selectedNum() == 0 then return end

	local mat_init = _Matrix3D.new()
	copyMat(mat_init, updateinitmat)
	local mode = updatemode

	local redo = function(data0)
		local data = data0 or {}
		if data0 then
			self:atom_block_bindTransform(mat_init)
			copyMat(self.rt_transform, data0.mat)
		else
			data.mat = _Matrix3D.new()
			copyMat(data.mat, self.rt_transform)
		end

		self:atom_block_unbindTransform()

		if not data0 then
			data.editdf = self.dfEditing
			if data.editdf then
				data.currframe = self:getCurrentFrame()

				local pivot
				if updatemode == 'rotpivot' then
					pivot = _Vector3.new()
					mat_init:getTranslation(pivot)
				end

				data.pivot = pivot
			end
		end

		if data.editdf then
			local frame0 = data.editdf and data.currframe or self:getFirstFrame()
			self:addDFFrameDatas(frame0, 'transforms', self.rt_selectedBlocks, data.pivot, updatemode)
		end

		if data.editdf then self:updateCurrentDFrame() end

		self:refreshModuleIcon()
		self:showPropList(false)
		self:atom_group_dirty()

		self:checkMusicDummy()

		return data
	end

	self:addCommand(redo, updateundofunc, 'Update')

	if self.dfEditing then
		for i, b in ipairs(self.rt_selectedBlocks) do
			b:delCacheTransform()
		end
	end
end
-- 材质编辑
	-- 颜色
	-- 材质
local materialKey = {
	material = true,
	mtlmode = true,
	color = true,
	roughness = true,
}

BuildBrick.cmd_enter_group = function(self, g)
	local redo = function(data)
		if not data then
			data = {}
			data.group = g:getSerialNum()
			self:pushGroup(g)

			--self:atom_group_select()
		else
			local group = self:getBySerialNum(data.group)
			self:pushGroup(group)
		end

		return data
	end

	local undo = function()
		self:popGroup()
	end

	self:addCommand(redo, undo, 'enterGroup')
end

BuildBrick.cmd_leave_group = function(self)
	local redo = function()
		local g = self:popGroup()

		local data = {}
		data.group = g:getSerialNum()
		return data
	end

	local undo = function(data)
		local group = self:getBySerialNum(data.group)
		self:pushGroup(group)
	end

	self:addCommand(redo, undo, 'leaveGroup')
end

BuildBrick.cmd_enter_module = function(self, b)
	self:pushModuleStack(b)
end

BuildBrick.cmd_leave_module = function(self)
	self:popModuleStack()
end

BuildBrick.cmd_setMaterial = function(self, mode, mtldata)
	local bs
	-- 编辑时用的开关，用于只修改一个块的材质
	if self.enableBlockMaterial then
		bs = {self.rt_block}
	else
		bs = {}
		for i, b in ipairs(self.rt_selectedBlocks) do
			if not b.markerdata then
				table.insert(bs, b)
			end
		end
	end

	local ds = {}
	for i, b in ipairs(bs) do
		ds[i] = self:getBlockValue_ByFrame(nil, b, 'material')
		--local tb = {}
		--ds[i] = tb
		-- for k in pairs(materialKey) do
		-- 	tb[k] = b.data[k]
		-- end
	end

	local cds = {}
	if materialKey[mode] then
		-- 只修改一个属性, data为修改的值
		for i, b in ipairs(bs) do
			cds[i] = self:getBlockValue_ByFrame(nil, b, 'material')
			cds[i][mode] = mtldata
		end
	else
		-- 修改所有属性, data是mtl表
		for i, b in ipairs(bs) do
			cds[i] = mtldata
		end
	end

	local undo = function(data)
		if data.editdf then
			self:addDFFrameDatas(data.currframe, 'materials', bs, ds)

			self:updateCurrentDFrame()
		else
			for i, b in ipairs(bs) do
				self:atom_block_setMaterial(b, ds[i])
			end
		end
		self:refreshModuleIcon()
	end

	local redo = function(data0)
		local data = data0 or {}
		if not data0 then
			data.editdf = self.dfEditing
			if data.editdf then
				data.currframe = self:getCurrentFrame()
			end
		end

		if data.editdf then
			--for i, b in ipairs(bs) do
				-- self:initFrameValue(b, 'material')
			--	self:addDFFrameData(data.currframe, 'material', b, LerpMaterial.new(cds[i]))
			--end

			self:addDFFrameDatas(data.currframe, 'materials', bs, cds)
			self:updateCurrentDFrame()
		else
			for i, b in ipairs(bs) do
				self:atom_block_setMaterial(b, cds[i])
			end
		end
		self:refreshModuleIcon()

		return data
	end

	self:addCommand(redo, undo, 'SetMaterial')
end

BuildBrick.cmd_merge_lock = function(self)
	if #self.rt_selectedGroups == 0 then
		return
	end

	for i, g in ipairs(self.rt_selectedGroups) do
		if g.part or g.attachpart then
			Notice(NOTICE_BRICK_UNLOCK_FAILED)
			return
		end
	end

	if #self.rt_selectedGroups == 1 then
		self:cmd_lock()
		return
	end

	local backup0 = self:atom_prepareBackup(self.rt_selectedBlocks)

	local function undo()
		self:atom_useBackup(backup0, true)
		self:onGroupLock(self.rt_selectedGroups[1])
	end
	local function redo(backup)
		if backup then
			self:atom_useBackup(backup, true)
		else
			self:atom_group_merge_one()
			self:atom_group_lock(true)

			backup = self:atom_prepareBackup(self.rt_selectedBlocks)
		end
		self:onGroupLock(self.rt_selectedGroups[1])

		return backup
	end

	self:addCommand(redo, undo, 'mergelock')
end
-- 合体
-- 解体
-- 上锁
-- 解锁
BuildBrick.cmd_lock = function(self)
	if #self.rt_selectedGroups == 0 then
		return
	end

	assert(#self.rt_selectedGroups == 1)

	local g = self.rt_selectedGroups[1]

	if g:isDeadLock() then
		Notice(NOTICE_BRICK_UNLOCK_FAILED)
		return
	end

	local lock = not g:isLock()

	local function undo()
		if #self.rt_selectedGroups == 1 then
			self:atom_group_lock(not lock)
		else
			self:atom_group_merge_one()
			self:atom_group_lock(true)
			self:onGroupLock(self.rt_selectedGroups[1])
		end
	end
	local function redo()
		assert(#self.rt_selectedGroups == 1)

		self:atom_group_lock(lock)
		-- 解组后自动拆分
		local g = self.rt_selectedGroups[1]
		if not lock and not g.parent and g:getChildrenCount() > 0 then
			local gs = g:regroup()
			self:atom_group_select_batch(gs)
		end
	end

	self:addCommand(redo, undo, 'Lock')
end

-- 复制
BuildBrick.cmd_copy = function(self)
	if #self.rt_selectedBlocks == 0 then return end
	if self.enableGroup and #self.rt_selectedGroups == 0 then
		return
	end

	if self:isSelectedMusicRunway() then
		self:copyMusicRunway(self.rt_selectedBlocks, _sys:isKeyDown(_System.KeyShift))
		return
	elseif self:isSelectedMusicPole() then
		self:copyMusicPole(self.rt_selectedBlocks, _sys:isKeyDown(_System.KeyShift))
		return
	end

	if not self.enableOpenLib or not self.enableBrickMat then return end

	local backup0 = self:atom_prepareBackup(self.rt_selectedBlocks)

	local function undo(data)
		-- del bs & gs, select bs & gs、
		--local editdf = data and data.editdf or self.dfEditing
		self:atom_block_del_s(self.rt_selectedBlocks)
		self:atom_useBackup(backup0, true)

		self:showPropList(false)
		self:refreshModuleIcon()
	end
	local function redo(data)
		if data then
			local backup = data and data.backup
			for i, b in ipairs(backup.bs) do
				self:atom_block_add_b(b)
			end
			self:atom_useBackup(backup, true)
		else
			data = {}

			local cres = {}
			self:atom_group_copy(cres)
			local backup = self:atom_prepareBackup(cres.cblist)
			data.backup = backup

			data.editdf = self.dfEditing
			data.currframe = data.editdf and self:getCurrentFrame()
		end

		if data.editdf then

			local frames = self:getDFFrames()
			for _, f in ipairs(frames) do
				self:addDFFrameDatas(f, 'alpha', data.backup.bs, f == data.currframe and 1 or 0)
			end

			self:updateCurrentDFrame()
		end

		self:showPropList(false)
		self:refreshModuleIcon()
		return data
	end

	local d = self:addCommand(redo, undo, 'Copy')
	return d.bs
end
-- 增加module
-- 选中module
-- 放入module
-- BuildBrick.cmd_dragModule = function(self, module, x, y)
	-- local bs = self:dragModuleToScene(module, false, x, y)
	-- local undo = function()

	-- end
	-- local redo = function()
	-- end

	-- self:addCommand(redo, undo, 'DragModule')
	-- print('[cmd_dragModule] NYI')

	-- return bs
-- end
-- part ----------------------------------------------------------
BuildBrick.cmd_showpart = function(self, show, camera)
	local redo = function()
		self.showSkl = show
		self.ui.showbone.selected = show
		self:atom_camera_bind(show, camera)

		if self.partopt == 'preview' and self.showSkl then
			self.ui.previewanim.selected = false
			self.partopt = 'exit'
		end

		local opt = show and 'bind' or 'exit'
		if self.partopt ~= 'preview' then
			self.ui.animuis.visible = show
			self:editPart(opt)
		else
			self.oldpartopt = opt
		end
	end

	local undo = function()
		self.showSkl = not show
		self.ui.showbone.selected = not show
		self:atom_camera_bind(not show, camera)

		if self.partopt == 'preview' and self.showSkl then
			self.ui.previewanim.selected = false
			self.partopt = 'exit'
		end

		local opt = not show and 'bind' or 'exit'
		if self.partopt ~= 'preview' then
			self.ui.animuis.visible = not show
			self:editPart(not show and 'bind' or 'exit')
		else
			self.oldpartopt = opt
		end
	end

	self:addCommand(redo, undo, 'showPart')
end

BuildBrick.cmd_showmovepart = function(self)

	local f = function()
		local gomove = self.partopt == 'bind'
		self:editPart(gomove and 'movebone' or 'bind')
		--self.ui.animuis.bindpart.selected = gomove
		--self.ui.bindpart.title.text = gomove and '移动' or '绑定'
	end

	self:addCommand(f, f, 'showPart')
end

BuildBrick.cmd_changeAnima = function(self)
	local selectAnima = self.selectedAnim

	local redo = function(data)
		if not data then
			data = {}
		else
			self:playAnimIndex(selectAnima, true)
		end

		return data
	end

	local undo = function()
		local oldsel = self.selectedAnim
		self:playAnimIndex(selectAnima, true)
		selectAnima = oldsel
	end

	self:addCommand(redo, undo, 'showPreview')
end

BuildBrick.cmd_part_bind = function(self, p, g)
	if not p then return end
	local function undo(res)
		self:editPart('bind')
		self:atom_part_unbind(res.part)
	end
	local function redo()
		self:editPart('bind')
		self:atom_part_bind(g, p)

		return {part = p}
	end

	Global.Sound:play('bindpart')

	self:addCommand(redo, undo, 'PartBind', p.name)
end

local partundo
local unbindundo
local part_timer = _Timer.new()
BuildBrick.cmd_part_update_begin = function(self)
	if not self.rt_selectedPart then
		return
	end
	local p = self.jointediting and self.rt_selectedPart.jointnode or self.rt_selectedPart
	local mat = _Matrix3D.new()
	copyMat(mat, p.roottransform or p.transform)

	partundo = function(data)
		self:editPart(data.opt)

		if p.roottransform then
			copyMat(p.roottransform, mat)
		else
			copyMat(p.transform, mat)
		end

		self:atom_part_setDirty()
		self:onBrickChange()
	end
end
BuildBrick.cmd_part_update_end = function(self)
	if not partundo then
		return
	end

	if not self.rt_selectedPart then
		return
	end
	assert(self.partopt == 'movebone' or self.partopt == 'movejoint')

	local p = self.jointediting == 'joint' and self.rt_selectedPart.jointnode or self.rt_selectedPart
	local mat = _Matrix3D.new()
	copyMat(mat, p.roottransform or p.transform)

	local redo = function(data)
		if p.roottransform then
			copyMat(p.roottransform, mat)
		else
			copyMat(p.transform, mat)
		end
		self:atom_part_setDirty()

		self:onBrickChange()
		return {opt = data and data.opt or self.partopt}
	end

	self:addCommand(redo, partundo, 'PartMove', p.name)
end

BuildBrick.cmd_part_reset = function(self, p)
	local function undo(data)
		copyMat(p.roottransform, data.rootmat)
		copyMat(p.jointnode.transform, data.jnodemat)
	end

	local function redo()
		local rootmat = _Matrix3D.new()
		copyMat(rootmat, p.roottransform)

		local jnodemat = _Matrix3D.new()
		copyMat(jnodemat, p.jointnode.transform)

		self:resetPart(p)

		return{rootmat = rootmat, jnodemat = jnodemat}
	end

	self:addCommand(redo, undo, 'PartReset', p.name)
end

BuildBrick.cmd_part_unbind_begin = function(self)
	-- print('[cmd_part_unbind_begin]', self.rt_selectedPart)
	assert(self.rt_selectedPart)

	local part = self.rt_selectedPart
	if not part.group then
		return
	end

	self.unbindingpart = true

	part_timer:start('', 500, function()
		part_timer:stop()

		unbindundo = function(res)
			self:editPart('bind')

			local group = res.block:getBlockGroup('root')
			self:atom_part_bind(group, res.part)
		end

		local function redo(res)
			self:editPart('bind')

			local p = part
			if res then
				p = res.part
			end

			local g = part.group
			self:atom_part_unbind(part)

			-- 存一个block用于查找之前的group
			local nbs = {}
			self:getBindBlocks(g, nbs)
			local b = nbs[1]

			return {part = p, block = b}
		end

		self.rt_selectedPart = nil
		self:setPickedPart()
		self:addCommand(redo, unbindundo, 'PartUnbind', part.name)

		Global.Sound:play('unbindpart')
	end)
end

BuildBrick.cmd_part_unbind_end = function(self)
	part_timer:stop()
	self.unbindingpart = nil
end

-------------------------- DFFrames ----------------
BuildBrick.cmd_showDfs = function(self, show, index)
	local redo = function()
		if show then
			self:onSelectDFrame_base(self.DfFrames[index])
		else
			self:onSelectDFrame_base()
		end
	end

	local undo = function()
		if show then
			self:onSelectDFrame_base()
		else
			self:onSelectDFrame_base(self.DfFrames[index])
		end
	end

	self:addCommand(redo, undo, 'showDfs')
end

BuildBrick.cmd_frame_new = function(self, time, fdata)
	local function undo(data)
		self:atom_frame_del(data.frame)
		self:refreshFrameList()
		self:updateCurrentDFrame()
	end

	local function redo(data)
		local f = self:atom_frame_new(time, fdata)

		self:refreshFrameList()
		self:updateCurrentDFrame()
		self:onSelectDFrame(f)

		return {frame = f}
	end

	local data = self:addCommand(redo, undo, 'newframe')
	return data.frame
end

BuildBrick.cmd_frame_del = function(self, frame)
	local function undo(data)
		local f = data.frame
		self:atom_frame_new(f.time, f.data)

		self:refreshFrameList()
		self:updateCurrentDFrame()
		self:onSelectDFrame(f)
	end

	local function redo(data)
		self:atom_frame_del(frame)
		self:refreshFrameList()
		self:updateCurrentDFrame()

		return {frame = frame}
	end

	self:addCommand(redo, undo, 'delframe')
end

BuildBrick.cmd_enter_marker_blocks = function(self, b1)
	local redo = function()
		self:pushMarkerBlocks(b1)
	end

	local undo = function()
		self:popMarkerBlocks()
	end

	--self:addCommand(redo, undo, 'enter_marker_blocks')
	redo()
end