local Container = _require('Container')

local LogicBlockGroup = {}
LogicBlockGroup.typestr = 'LogicBlockGroup'
_G.LogicBlockGroup = LogicBlockGroup

LogicBlockGroup.new = function(blocks)
	local group = {}
	setmetatable(group, {__index = LogicBlockGroup, __tostring = __tostring})
	group.serialNum = GenSerialNum()
	group.children = {}
	group.isTree = false
	group.name = nil

	if blocks then group:addBlocks(blocks) end

	return group
end

LogicBlockGroup.setName = function(self, name)
	self.name = name
end

LogicBlockGroup.getName = function(self)
	return self.name
end

LogicBlockGroup.setTag = function(self, tag)
	self.tag = tag
end

LogicBlockGroup.getTag = function(self)
	return self.tag
end

LogicBlockGroup.enumBlocks = function(self, f)
	for i, v in ipairs(self.children) do
		if v.typestr == 'block' then
			f(v)
		elseif v.typestr == 'LogicBlockGroup' or v.typestr == 'DungeonGroup' then
			v:enumBlocks(f)
		end
	end
end

LogicBlockGroup.getBlocks = function(self, bs)
	if not bs then bs = {} end
	self:enumBlocks(function(block)
		table.insert(bs, block)
	end)

	return bs
end

LogicBlockGroup.getChildren = function(self)
	return self.children
end

LogicBlockGroup.getChild = function(self, index)
	assert(self.children[index])

	return self.children[index]
end

LogicBlockGroup.addChild = function(self, b)
	table.insert(self.children, b)
end

LogicBlockGroup.delChild = function(self, b)
	for i, v in ipairs(self.children) do
		if v == b then
			table.remove(self.children, i)
			break
		end
	end
end

LogicBlockGroup.addChildren = function(self, bs)
	for i, v in ipairs(bs) do
		table.insert(self.children, v)
	end
end

LogicBlockGroup.delChildren = function(self, bs)
	for i, v in ipairs(bs) do
		self:delChild(v)
	end
end

LogicBlockGroup.setIndex = function(self, index)
	self.index = index
end

LogicBlockGroup.isValid = function(self)
	return #self.children > 0
end

LogicBlockGroup.saveBlocksToData = function(self, data)
	if not data then data = {} end

	data.name = self.name
	data.index = self.index
	data.tag = self.tag
	data.blocks = {}
	for i, b in ipairs(self.children) do
		if b.typestr == 'block' then
			if not b:isDummy() then
				table.insert(data.blocks, b.index)
			end
		end
	end

	table.sort(data.blocks, function(a, b) return a < b end)

	return data
end

------------------ basic function ------------------
local helpvec = _Vector3.new()
LogicBlockGroup.getTransform = function(self)
	if not self.transform then
		self.transform = _Matrix3D.new()
	end
	return self.transform
end

LogicBlockGroup.getAABB = function(self)
	if not self.aabb then self.aabb = _AxisAlignedBox.new() end
	local blocks = self:getBlocks()
	Block.getAABBs(blocks, self.aabb)

	return self.aabb
end
--[[
LogicBlockGroup.getUserAABB = function(self, aabb, ignoreTransform)
	if self.funcflags and self.funcflags.userAABB then
		local ab = self.funcflags.userAABB
		aabb.min:set(ab.min)
		aabb.max:set(ab.max)
		if not ignoreTransform then
			aabb:mul(self:getTransform())
		end
		return true
	end

	return false
end

LogicBlockGroup.getShapeAABB = function(self, aabb, ignoreTransform)
	local blocks = self:getBlocks()
	-- TODO:ignoreTransform
	Block.getShapeAABBs(blocks, aabb)
end

LogicBlockGroup.getShapeAABB0 = function(self, ab, nodemat, align)
	if nodemat then
		if not self:getUserAABB(ab, true) then
			self:getShapeAABB(ab, true)
		end

		ab:mul(nodemat)
	else
		if not self:getUserAABB(ab) then
			self:getShapeAABB(ab)
		end
	end

	if align then ab:alignSize(align) end
end

--]]
------------------ DynamicEffect Transition ------------------
LogicBlockGroup.getInitTransforms = function(self)
	local mats = {}

	local blocks = self:getBlocks()
	for i, b in ipairs(blocks) do
		local mat = _Matrix3D.new()
		mat:set(b.node.transform)
		table.insert(mats, mat)
	end

	return mats
end

LogicBlockGroup.bindTransforms = function(self, mats, pivot)
	-- assert(#self.blocks == #mats)

	local mat = self:getTransform()
	mat:identity()

	local blocks = self:getBlocks()
	for i, b in ipairs(blocks) do
		b.node.transform:set(mats[i])
		b.node.transform.parent = mat
	end

	self.pivot = pivot
	-- self.mats = mats
	-- print('LogicBlockGroup bindTransforms', self.pivot)
end

LogicBlockGroup.unbindTransforms = function(self)
	self:enumBlocks(function(b)
		b.node.transform:unbindParent()
	end)
end

local helpmat = _Matrix3D.new()
LogicBlockGroup.changeTransformDiff = function(self, value)
	local transform = self:getTransform()

	local mat, pivot
	if value.typestr == '_Matrix3D' then
		mat = value
	elseif value.typestr == 'PivotMat' then
		mat = value:getMatrix()
		pivot = value:getPivot()
	end

	mat:updateTransformValue()
	-- print('changeTransformDiff', pivot, self.pivot, mat)
	if mat:hasRotationOrScale() then
		if pivot then
			_Vector3.add(self.pivot, pivot, helpvec)
		else
			helpvec:set(self.pivot)
		end

		helpmat:setTranslation(-helpvec.x, -helpvec.y, -helpvec.z)
		helpmat:mulRotationXRight(mat.rotationP)
		helpmat:mulRotationYRight(mat.rotationH)
		helpmat:mulRotationZRight(mat.rotationB)
		helpmat:mulTranslationRight(helpvec.x, helpvec.y, helpvec.z)
		helpmat:mulTranslationRight(mat.translationX, mat.translationY, mat.translationZ)
		helpmat:mulScalingLeft(mat.scaleX, mat.scaleY, mat.scaleZ)

		transform:set(helpmat)
		-- print('helpmat', helpmat, transform)
	else
		transform:set(mat)
	end
end

LogicBlockGroup.changeTransform = function(self, value)
	local mat
	if value.typestr == '_Matrix3D' then
		mat = value
	elseif value.typestr == 'PivotMat' then
		mat = value:getMatrix()
	end

	self:enumBlocks(function(b)
		b.node.transform:set(mat)
	end)
end

LogicBlockGroup.changeInvisible = function(self, value)
	self:enumBlocks(function(b)
		b:setVisible(not value)
	end)
end

LogicBlockGroup.changeMaterial = function(self, value)
	self:enumBlocks(function(b)
		b:setMaterialBatch(value)
	end)
end

LogicBlockGroup.changePaint = function(self, value)
	self:enumBlocks(function(b)
		b:refreshPaint2(value)
	end)
end

LogicBlockGroup.changeAlpha = function(self, alpha, clearblend)
	self:enumBlocks(function(b)
		b:changeTransparency(alpha)
		if Block.isBuildMode() then
			b:setBuildVisiable(alpha ~= 0)
		else
			b:setVisible(alpha ~= 0)
		end
	end)
end

LogicBlockGroup.setPhysicEnable = function(self, enable)
	self:enumBlocks(function(b)
		b:setPhysicEnable(enable)
	end)
end

------------------ DynamicEffect Transition ------------------