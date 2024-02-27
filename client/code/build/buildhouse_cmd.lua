local Container = _require('Container')
local BuildHouse = Global.BuildHouse
-- 加块
-- TODO: data -> id
BuildHouse.cmd_addBrick = function(self, id)
	local redo = function(b)
		self:showPropList(false)
		if b then
			-- select依赖的是b，所以需要保证b是同一个
			self:atom_block_add_b(b)
		else
			b = self:atom_block_add({shape = id})
		end
		return b
	end
	local undo = function(b)
		self:atom_block_del(b)
		self:showPropList(false)
	end

	return self:addCommand(redo, undo, 'addBrick')
end
-- 选中
	-- 拿到pickedblock
local selectlightfunc
local selectundofunc
local timer = _Timer.new()
BuildHouse.cmd_select_begin = function(self, b, pos)
	local bs = table.clone(self.rt_selectedBlocks)

	self.rt_block = b
	if pos then
		self.rt_pos:set(pos.x, pos.y, pos.z)
	else
		self.rt_pos:set(0, 0, 0)
	end

	local mode = self.rt_mode
	self.rt_mode = 0

	selectundofunc = function()
		self.rt_mode = mode
		self:atom_block_select(bs)
		self:showPropList(false)
	end
	selectlightfunc = function(nbs)
		if nbs then
			self.rt_mode = 0
			self:atom_block_select(nbs)
		else
			self:atom_block_select_ex(b, pos, 0)
			nbs = table.clone(self.rt_selectedBlocks)
		end

		if self.showProp then
			self:showPropList(self.rt_block ~= nil)
		end

		return nbs
	end

	-- 禁用长按
	-- timer:start('', 500, function()
	-- 	self:cmd_selectHeavy(b, pos)
	-- 	timer:stop()
	-- end)
end
BuildHouse.cmd_select_cancel = function(self)
	timer:stop()
	selectlightfunc = nil
end
-- return 0 : 错误 1: 同位置 2: 非同位置
BuildHouse.cmd_select_end = function(self)
	timer:stop()
	if not selectlightfunc then return 0 end

	if self:atom_block_isSelected(self.rt_block) and self.rt_mode == 0 then
		-- 同样的选择
		selectlightfunc = nil
		return 1
	end

	self:addCommand(selectlightfunc, selectundofunc, 'Select:light')
	selectlightfunc = nil

	return 2
end
-- 长按(split & select)
BuildHouse.cmd_selectHeavy = function(self, b, pos)
	selectlightfunc = nil
	timer:stop()

	if self:atom_block_isSelected(self.rt_block) and self.rt_mode == 1 then
		-- 同样的选择
		return
	end

	--长按空白
	if self.rt_pickedBlock == nil and self.rt_block == nil then
		return
	end

	local redo = function(bs)
		self:showPropList(false)
		if bs then
			self.rt_mode = 1
			self:atom_block_select(bs)
		else
			self:atom_block_select_ex(b, pos, 1)
			bs = table.clone(self.rt_selectedBlocks)
		end

		return bs
	end
	-- 拿到
	-- select group
	self:addCommand(redo, selectundofunc, 'Select:heavy')

	return true
end
-- 删块
BuildHouse.cmd_delBrick = function(self)
	if self:atom_block_selectedNum() == 0 then return end

	local bs = table.clone(self.rt_selectedBlocks)
	local undo = function()
		-- add bs back
		for i, b in ipairs(bs) do
			self:atom_block_add_b(b)
		end

		self:showPropList(false)
		self:atom_block_select(bs)
	end
	local redo = function()
		-- 删除时仅可能去掉箭头
		self:showPropList(false)
		self:atom_del()
		self:atom_block_select_ex()
	end

	self:addCommand(redo, undo, 'Delbrick')
end
-- 旋转/位移
-- mode : rot/move
local updateundofunc
-- b0 --bind-> b1m1(b0) --update-> b1m2 --unbind-> b2 m2
local updateinitmat = _Matrix3D.new()
local updatemode = ''
BuildHouse.cmd_mat_update_begin = function(self, mat, mode)
	if self:atom_block_selectedNum() == 0 then return end
	self:atom_block_bindTransform(mat)
	local mat1 = _Matrix3D.new()
	copyMat(mat1, self.rt_transform)

	-- redo 需要知道起始parent
	copyMat(updateinitmat, self.rt_transform)

	updatemode = mode
	-- 处理调出旋转轴之后移动隐藏
	self:showPropList(false)

	updateundofunc = function(mat2)
		self:atom_block_bindTransform(mat2)
		copyMat(self.rt_transform, mat1)
		self:atom_block_unbindTransform()

		if mode == 'rot' or mode == 'scale' then
			self:showPropList(true)
		else
			self:showPropList(false)
		end
	end
end
BuildHouse.cmd_mat_update_end = function(self)
	if self:atom_block_selectedNum() == 0 then return end

	local mat_init = _Matrix3D.new()
	copyMat(mat_init, updateinitmat)
	local mode = updatemode
	local redo = function(mat)
		if mat then
			self:atom_block_bindTransform(mat_init)
			copyMat(self.rt_transform, mat)
		else
			mat = _Matrix3D.new()
			copyMat(mat, self.rt_transform)
		end
		self:showPropList(false)
		self:atom_block_unbindTransform()

		return mat
	end

	self:addCommand(redo, updateundofunc, 'Update')
end

-- 复制
BuildHouse.cmd_copy = function(self)
	if not next(self.rt_selectedBlocks) then
		return
	end

	local bs = table.clone(self.rt_selectedBlocks)

	local function undo()
		-- del bs & gs, select bs & gs
		self:atom_block_del_s(self.rt_selectedBlocks)
		self:atom_block_select(bs)

		self:showPropList(false)
	end
	local function redo(bs2)
		if bs2 then
			for i, b in ipairs(bs2) do
				self:atom_block_add_b(b)
			end
			self:atom_block_select(bs2)
		else
			local cres = {}
			self:atom_block_copy(cres)
			bs2 = cres.cblist
		end

		self:showPropList(false)
		return bs2
	end

	self:addCommand(redo, undo, 'Copy')
end
