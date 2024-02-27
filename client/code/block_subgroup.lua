local Container = _require('Container')

local BlockSubGroup = {}
BlockSubGroup.typestr = 'BlockSubGroup'
_G.BlockSubGroup = BlockSubGroup

BlockSubGroup.new = function(block, group)
	local g = {}
	g.name = group and group.name
	g.block = block
	g.index = group and group.index
	setmetatable(g, {__index = BlockSubGroup})
	g.blocks = group and group.blocks or {}
	g.data = group
	g.sgroups = group and group.sgroups

	if block and g.sgroups then
		local sgindexs = {}
		for i, sg in ipairs(g.sgroups) do
			table.insert(sgindexs, sg.index)
		end
	end

	return g
end

BlockSubGroup.enumMesh = function(self, f)
	if not f then return end
	for i, bi in ipairs(self.blocks) do
		local sub = self.block:getSubMesh(bi)
		if sub then
			f(sub, bi, i)
		end
	end
end

BlockSubGroup.getSubmeshes = function(self)
	local subs = {}
	for i, bi in ipairs(self.blocks) do
		local sub = self.block:getSubMesh(bi)
		table.insert(subs, sub)
	end

	return subs
end

BlockSubGroup.getShapes = function(self)
	local shapes = {}
	if self.block and self.sgroups then
		for i, sg in ipairs(self.sgroups) do
			self.block:getShapeBySGIndex(sg.index, shapes)
		end
	end
	return shapes
end

BlockSubGroup.getBlock = function(self)
	return self.block
end

BlockSubGroup.setName = function(self, name)
	self.name = name
end

BlockSubGroup.getTransform = function(self)
	if not self.transform then
		self.transform = _Matrix3D.new()
	end

	return self.transform
end

BlockSubGroup.getAABB = function(self)
	if not self.aabb then self.aabb = _AxisAlignedBox.new() end

	self.aabb:initBox()

	local ab2 = Container:get(_AxisAlignedBox)
	self:enumMesh(function(sub)
		ab2:set(sub:getBoundBox())
		_AxisAlignedBox.union(ab2, self.aabb, self.aabb)
	end)
	Container:returnBack(ab2)

	return self.aabb
end

-- 用于角色动画
BlockSubGroup.bindTransform = function(self, mat)
	self.bindmat = mat
	self:enumMesh(function(sub)
		sub.transform.parent = mat
	end)
end

BlockSubGroup.unbindTransform = function(self)
	self.bindmat = nil
	self:enumMesh(function(sub)
		sub.transform.parent = nil
	end)
end

------------------ DynamicEffect Transition ------------------
BlockSubGroup.getInitTransforms = function(self)
	local mats = {}
	self:enumMesh(function(sub)
		local mat = _Matrix3D.new()
		mat:set(sub.transform)
		table.insert(mats, mat)
	end)

	return mats
end

BlockSubGroup.bindTransforms = function(self, mats, pivot)
	if #self.blocks ~= #mats then
		print('!!!Bind failed', self.block and self.block:getShape(), #self.blocks, #mats)
	end
	assert(#self.blocks == #mats)

	local mat = self:getTransform()
	mat:identity()

	self:enumMesh(function(sub, bi, i)
		sub.transform:set(mats[i])
		sub.transform.parent = mat
	end)

	self.pivot = pivot
	-- print('BlockSubGroup bindTransforms', self.pivot)

	local shapes = {}
	if self.block and self.sgroups then
		for i, sg in ipairs(self.sgroups) do
			self.block:getShapeBySGIndex(sg.index, shapes)
		end

		if self.block:getShapeDfEnabled() then
			for i, s in ipairs(shapes) do
				s.transform.parent = mat
			end
		end
	end
	self.shapes = shapes
end

BlockSubGroup.unbindTransforms = function(self)
	self:enumMesh(function(sub)
		sub.transform:unbindParent()
		-- sub.transform.parent = nil
	end)

	if self.block:getShapeDfEnabled() then
		for i, s in ipairs(self.shapes) do
			-- s.transform:unbindParent()
			--s.transform.parent = nil
		end
	end
end

local helpvec = _Vector3.new()
local helpmat = _Matrix3D.new()

BlockSubGroup.changeTransformDiff = function(self, value)
	local transform = self:getTransform()

	local mat, pivot
	if value.typestr == '_Matrix3D' then
		mat = value
	elseif value.typestr == 'PivotMat' then
		mat = value:getMatrix()
		pivot = value:getPivot()
	end

	mat:updateTransformValue()
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
	else
		transform:set(mat)
	end
end

BlockSubGroup.changeTransform = function(self, value)
	self:enumMesh(function(sub)
		if value.typestr == '_Matrix3D' then
			sub.transform:set(value)
		elseif value.typestr == 'PivotMat' then
			sub.transform:set(value:getMatrix())
		end
	end)
end

BlockSubGroup.changeInvisible = function(self, value)
	self:enumMesh(function(sub, bi)
		sub.visible = not value
	end)
end

BlockSubGroup.changeMaterial = function(self, value)
	local noinstance = value.mtlmode == Global.MTLMODE.EMISSIVE or not _G.enableInsMaterial
	local material = Block.getMaterial(value.material, value.color, value.roughness, value.mtlmode, not noinstance)

	if self.block.node and self.block.node.mesh then
		self.block.node.mesh.enableInstanceCombine = false
	end

	if Global.forceDFInstance then
		self.block.node.mesh.enableInstanceCombine = true
	end

	-- print('!!!changeMaterial', value.material)
	self:enumMesh(function(sub, bi)
		local paint = Block.getSubPaintMesh(sub)
		local paintmtl
		if paint then
			paintmtl = paint.material
		end
		sub.material = material
		sub.isInvisible = value.material == Global.MtlInvisible
		sub.materialColor = noinstance and _Color.White or Block.convertColor(value.color)
		sub.oldmaterialColor = nil
		if paint then
			paint.material = paintmtl
		end
	end)
end

BlockSubGroup.changePaint = function(self, paintinfo)
	-- print('changePaint', paintinfo:tostring(), paintinfo:md5())
	if self.block.node and self.block.node.mesh then
		self.block.node.mesh.enableInstanceCombine = false
	end

	if Global.forceDFInstance then
		self.block.node.mesh.enableInstanceCombine = true
	end

	local md5 = paintinfo:md5()
	-- print('md5', md5)
	self:enumMesh(function(sub)
		local paints = Block.getSubPaintMeshs(sub)
		local find = false
		for i, v in ipairs(paints) do
			if md5 ~= 0 and v.name:find(md5) then
				v.visible = true
				find = true
				-- print('paints', i)
			else
				v.visible = false
			end
		end

		if not find and md5 ~= 0 then
			Block.addPaintMesh(sub, paintinfo)
		end

		-- local paint = Block.getSubPaintMeshByPaintInfo(sub, paintinfo, true)
		-- print('paint', #paints, paint.visible)
		-- if paint then paint.visible = true end
	end)
end

local blendcolor = _Color.new(0xffffffff)
BlockSubGroup.changeAlpha = function(self, alpha, clearblend)
	if self.block.node and self.block.node.mesh then
		self.block.node.mesh.enableInstanceCombine = false
	end

	if Global.forceDFInstance then
		self.block.node.mesh.enableInstanceCombine = true
	end

	local useins = self.block.node.mesh.enableInstanceCombine

	-- TODO：instance
	if not useins then
		if not self.blender and not clearblend then
			self.blender = _Blender.new()
		elseif clearblend then
			self.blender = nil
		end

		if self.blender then
			blendcolor.a = alpha
			self.blender:blend(blendcolor:toInt())
		end
	end

	self:enumMesh(function(sub, bi)
		if not useins then
			sub.blender = self.blender
		else
			if not sub.oldmaterialColor then
				sub.oldmaterialColor = sub.materialColor
			end
			local c = _Color.new(sub.materialColor)
			c.a = alpha
			sub.materialColor = c
		end

		sub.visible = alpha ~= 0
	end)
end

BlockSubGroup.setPhysicEnable = function(self, enable)
	if self.enablephysic == enable then return end

	self.enablephysic = enable
	self:enumMesh(function(sub, bi)
		local marker = self.block.cmarkers[bi]
		if marker and marker:isMarkerEnabled() ~= enable then
			marker:enableMarker(enable)
		end
	end)

	for i, sg in ipairs(self.sgroups) do
		local shapes = {}
		self.block:getShapeBySGIndex(sg.index, shapes)
		for _, shape in ipairs(shapes) do
			shape.query = enable
		end
	end
end