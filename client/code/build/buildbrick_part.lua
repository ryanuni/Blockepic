local Container = _require('Container')
local command = _require('Pattern.Command')
local BuildBrick = _G.BuildBrick

BuildBrick.getPartAABB = function(self, part, ab)
	if part.group then
		part.group:getAABB(ab, 'connect')
	else
		ab:set(part.bonenode.aabb)
		ab:mul(part.bonenode.transform)
	end
end
BuildBrick.getPartsAABB = function(self, ab)
	local ab1 = Container:get(_AxisAlignedBox)

	ab:initBox()
	for name, part in pairs(self.parts) do
		self:getPartAABB(part, ab1)
		_AxisAlignedBox.union(ab, ab1, ab)

		for i, g in ipairs(part.attachs) do
			g:getAABB(ab1, 'connect')
			_AxisAlignedBox.union(ab, ab1, ab)
		end
	end

	if not ab:isValid() then
		ab:initNull()
	end

	Container:returnBack(ab)
end

BuildBrick.getPartRoot = function(self)
	for name, part in pairs(self.parts) do
		local data = Part.getPartData(self.parttype)
		local cpart = data.parts[name]
		if not cpart.parent then
			return part
		end
	end
end

BuildBrick.applyGroupMat = function(self, p)
	assert(not p.isplaying)
	local nbs = {}
	self:getBindBlocks(p.group, nbs)
	for i, g in ipairs(p.attachs) do
		g:getBlocks(nbs)
	end

	for i, b in ipairs(nbs) do
		if not b:isDummy() then
			b:setDynamic(true)

			b.node.transform:unbindParent()
			b.node.transform:bindParent(p.transform)
		end
	end

	p.isplaying = true
end

BuildBrick.stopGroupMat = function(self, p)
	local nbs = {}
	self:getBindBlocks(p.group, nbs)
	for i, g in ipairs(p.attachs) do
		g:getBlocks(nbs)
	end

	for i, b in ipairs(nbs) do
		if not b:isDummy() then
			b:setDynamic(false)
			b.node.transform.parent = nil
			b.node.transform:bindParent(p.blocktransform)
		end
	end

	p.isplaying = false
end

BuildBrick.bindRolePart = function(self, animrole, ppart, part, slotdata, bonename, isroot)
	--print('bindrolepart', part.name, ppart and ppart.name, bonename)
	if ppart then
		animrole:addPart(ppart)
		animrole:addSlot(ppart, slotdata)
	end

	animrole:addPart(part)
	animrole:useSKlBone(part, bonename, slotdata, isroot)
end

BuildBrick.bindChildGroup = function(self, animrole, bones, index, pgroup, joint)
	if #joint == 0 then return end
	local slotmat = _Matrix3D.new()
	--slotmat:set(joint[1].node.transform)
	local s = joint[1]:getPhysicShapes()[1]
	slotmat:set(s.transform)
	slotmat:mulRight(joint[1].node.transform)

	local slotdata = {mat = slotmat}

	self:bindRolePart(animrole, pgroup, joint, slotdata, bones[index])
	for group in pairs(joint.connects) do if group ~= pgroup then
		self:bindRolePart(animrole, pgroup, group, slotdata, bones[index])

		-- for g in pairs(group.connects) do if g ~= joint then
		-- 	self:bindChildGroup(animrole, bones, index + 1, group, g)
		-- end end
	end end
end

BuildBrick.applyEmoji = Global.Block.applyEmoji

BuildBrick.applyAnim = function(self, animname, mat)
	if not self.parttype then return end
	self:stopAnim()

	local AM = Global.AnimationManager
	local animrole = AM:addRole(self)
	animrole:clear()
	animrole:bindSkl(self.parttype)

	-- 计算root点离地面的高度
	local minz = self:getRootZ_MinZ()
	for name, part in pairs(self.parts) do
		if part.group then
			local data = Part.getPartData(self.parttype)
			local cpart = data.parts[name]
			local bones = cpart.bones

			local ppart = part.ppart and part.ppart.group and part.ppart

			local slotmat = _Matrix3D.new()
			slotmat:set(part.jointnode.transform)
			local slotdata = {mat = slotmat}

			-- 增加特殊节点root用于处理骨骼的位移，只有root点上的位移有效
			local isroot = cpart.parent == nil
			if isroot then
				local vec = Container:get(_Vector3)
				part.jointnode.transform:getTranslation(vec)
				local rootz = math.max(vec.z - minz, 0)
				animrole:setRootz(rootz)
				Container:returnBack(vec)
			end

			local index = 1
			self:bindRolePart(animrole, ppart, part, slotdata, bones[index], isroot)
		end
	end

	animrole:refresh()

	for name, part in pairs(self.parts) do
		if part.group then
			self:applyGroupMat(part)
		end
	end
	local san = animrole:useAnima(animname, false)

--[[
	local e = Global.AnimationCfg[animname].emoji
	if e and san and not san.emoji_setted then
		-- print(e.name, e.tick)
		san.graEvent:addTag(e.name, e.tick / san.duration)
		san:onEvent(function(name)
			if name == e.name then
				self.node = self:getPartRoot()
				self:applyEmoji(name)
			end
		end, false)
		san.emoji_setted = true
	end
--]]
	animrole:playAnim(animname)
end

BuildBrick.pauseAnim = function(self)
	local AM = Global.AnimationManager
	local animrole = AM:getRole(self)
	if not animrole then return end

	animrole:pauseAnim()
end

BuildBrick.stopAnim = function(self)
	local AM = Global.AnimationManager
	local animrole = AM:getRole(self)
	if not animrole then return end

	for name, part in pairs(self.parts) do
		if part.group then
			self:stopGroupMat(part)
		end
	end

	animrole:stopAnim()

	AM:delRole(self)
end

BuildBrick.pickBone = function(self, x, y)
	local node = self:scenepick(x, y, Global.CONSTPICKFLAG.BONE)
	return node and node.part
end

BuildBrick.pickJoint = function(self, x, y)
	for name, part in pairs(self.parts) do
		if part.jointpos then
			local pos = part.jointpos.pos
			local size = part.jointpos.size

			if x > pos.x - size and x < pos.x + size and y > pos.y - size and y < pos.y + size then
				return part
			end
		end
	end

	local node = self:scenepick(x, y, Global.CONSTPICKFLAG.JOINT)
	return node and node.part
end

local pickpos = _Vector3.new()
BuildBrick.pickPart = function(self, x, y)
	if not self.showSkl then return nil end

	local bonenode = self:scenepick(x, y, Global.CONSTPICKFLAG.BONE)
	return bonenode and (bonenode.block and bonenode.block.part or bonenode.part)
end

BuildBrick.getBoxCenterAlignJoint = function(self, part, ab)
	local data = Part.getPartData(self.parttype)
	local align = data.parts[part.name].jointalign

	local vec = Container:get(_Vector3)
	part.jointnode.transform:getTranslation(vec)

	local cx, cy, cz = Part.getBoxCenterAlignJoint(ab, align, vec)
	Container:returnBack(vec)

	return cx, cy, cz
end

BuildBrick.getBoxOffsetAlignJoint = function(self, part, ab)
	local center = Container:get(_Vector3)
	ab:getCenter(center)
	local cx, cy, cz = self:getBoxCenterAlignJoint(part, ab)
	Container:returnBack(center)

	return cx - center.x, cy - center.y, cz - center.z
end

BuildBrick.getBindBlocks = function(self, g, nbs)
	g:getBlocks(nbs, 'connect')
end

--local function attachBlocksPart(nbs, part)
local function bindBlocksParent(nbs, mode, part)
	--print('bindBlocksParent', part and part.name, mode, part and part.isplaying)

	for i, b in ipairs(nbs) do
		if not b:isDummy() then
			if mode == 'attach' then
				if part then
					local bstf = part.isplaying and part.transform or part.blocktransform
					b.node.transform:bindParent(bstf)
					b.part2 = part
					b.node.instanceGroup = part.name
				else
					b.node.transform:unbindParent()
					b.part2 = nil
					b.node.instanceGroup = ''
				end
			elseif mode == 'bind' then
				if part then
					assert(not part.isplaying)
					b.node.transform.parent = part.blocktransform
					b.part = part
					b:addPickFlag(Global.CONSTPICKFLAG.BONE)
					b:delPickFlag(Global.CONSTPICKFLAG.NORMALBLOCK)
					b:delPickFlag(Global.CONSTPICKFLAG.SELECTBLOCK)
					b.node.instanceGroup = part.name
				else
					b.part = nil
					b.node.transform.parent = nil
					b:delPickFlag(Global.CONSTPICKFLAG.BONE)
					b:addPickFlag(Global.CONSTPICKFLAG.NORMALBLOCK)
					b.node.instanceGroup = ''
				end

			end
		end
	end
end

BuildBrick.bindPartGroupData = function(self, part, g)
	local oldg = part.group
	if oldg == g then return end

	part.group = g

	if g then
		assert(not g.parent)
		g.part = part
	end
	if oldg then
		oldg.part = nil
	end
end

BuildBrick.unbindPartGroup = function(self, part)
	if not part.group then return end
	assert(not part.isplaying)

	--print('unbindPartGroup', part and part.name, part.group)

	local group = part.group
	local nbs = {}
	self:getBindBlocks(group, nbs)

	local ab1 = Container:get(_AxisAlignedBox)
	local ab2 = Container:get(_AxisAlignedBox)

	group:setDirty()
	self:getPartAABB(part, ab1)

	part.bonenode.visible = true
	bindBlocksParent(nbs, 'bind', nil)
	self:bindPartGroupData(part, nil)
	group:setDirty()

	-- 更新子部件位置
	self:getPartAABB(part, ab2)

	self:onChangePartAABBSize(part, ab1, ab2)
	self:updatePartBlocks()

	Container:returnBack(ab1, ab2)
end

BuildBrick.bindPartGroup = function(self, part, group)
	assert(not part.isplaying)
	if group.parent then
		--assert(not group.parent)

		group:setParent(nil)
		group:clearOuterCONs()
		group:clearOuterCollisions()
		print('error group bind has parent')
	end

	--print('bindPartGroup', part and part.name, group)

	local ab1 = Container:get(_AxisAlignedBox)
	local ab2 = Container:get(_AxisAlignedBox)

	self:getPartAABB(part, ab1)

	-- joint单独移动的位置
	local ox, oy, oz = self:getBoxOffsetAlignJoint(part, ab1)
	--print('ox, oy, oz', ox, oy, oz)

	local nbs = {}
	self:getBindBlocks(group, nbs)
	Block.getAABBs(nbs, ab2)
	local cx, cy, cz = self:getBoxOffsetAlignJoint(part, ab2)

	local bstf = part.blocktransform
	bstf.parent = nil
	bstf:setTranslation(cx, cy, cz)
	bstf:mulTranslationRight(-ox, -oy, -oz)
	bstf:bindParent(part.roottransform)

	bindBlocksParent(nbs, 'bind', part)
	part.bonenode.visible = false
	self:bindPartGroupData(part, group)
	group:setDirty()

	-- 更新子部件位置
	self:getPartAABB(part, ab2)
	self:onChangePartAABBSize(part, ab1, ab2)
	self:updatePartBlocks()

	Container:returnBack(ab1, ab2)

	return group
end

BuildBrick.hasBindPart = function(self)
	for name, part in pairs(self.parts) do
		if part.group then
			return true
		end
	end

	return false
end

BuildBrick.clearAllAttaches = function(self)
	-- local bs1 = {}
	-- self:getBlocks(bs1, function(b) return b.part end)
	-- bindBlocksParent(bs1, 'bind', nil)

	-- local bs2 = {}
	-- self:getBlocks(bs2, function(b) return b.part2 end)
	-- bindBlocksParent(bs2, 'attach', nil)

	for name, part in pairs(self.parts) do
		self:bindPartGroupData(part, nil)

		for i, v in ipairs(part.attachs) do
			v.attachpart = nil
		end
		part.attachs = {}
	end
end

BuildBrick.addAttachPartData = function(self, part, g)
	assert(not g.attahpart)

	table.insert(part.attachs, g)
	g.attachpart = part
end

BuildBrick.unattachPartSubGroup = function(self, g)
	if g.attachpart then
		self:unattachPartGroup(g)
	end

	local r = g:getRoot()
	if not r.attachpart then return end

	local nbs = {}
	g:getBlocks(nbs)
	bindBlocksParent(nbs, 'attach', nil)
end

BuildBrick.unattachPartGroup = function(self, g)
	if not g.attachpart then return end
	assert(not g:getParent(true))

	local nbs = {}
	g:getBlocks(nbs)
	bindBlocksParent(nbs, 'attach', nil)

	local p = g.attachpart
	for i, v in ipairs(p.attachs) do
		if v == g then
			table.remove(p.attachs, i)
			break
		end
	end
	g.attachpart = nil

	self:onBrickChange()
end

BuildBrick.attachPartGroup = function(self, part, g)
	if not part.group then return end

	assert(not g.attachpart)

	--print('attachPartGroup', part.name, g)
	local nbs = {}
	g:getBlocks(nbs)
	bindBlocksParent(nbs, 'attach', part)

	table.insert(part.attachs, g)
	g.attachpart = part

	self:onBrickChange()
end

BuildBrick.clearParts = function(self)
	for name, part in pairs(self.parts or {}) do
		self.sen:del(part.bonenode)
		self.sen:del(part.jointnode)
	end

	self.parts = {}
end

BuildBrick.onChangePartAABBSize = function(self, part, ab1, ab2)
	local vec1 = Container:get(_Vector3)
	local vec2 = Container:get(_Vector3)
	local offset = Container:get(_Vector3)
	local center = Container:get(_Vector3)
	local size = Container:get(_Vector3)

	--中心点
	ab1:getCenter(vec1)
	ab2:getCenter(vec2)
	_Vector3.sub(vec2, vec1, center)
	-- print('onChangePartAABBSize center:', part.name, vec1, vec2, center)

	--包围盒半径
	ab1:getSize(vec1)
	ab2:getSize(vec2)
	_Vector3.sub(vec2, vec1, size)
	_Vector3.mul(size, 0.5, size)
	-- print('onChangePartAABBSize size:', part.name, vec1, vec2, center)

	local data = Part.getPartData(self.parttype)
	for i, pname in ipairs(data.orders) do
		local cfgpart = data.parts[pname]

		-- 更新子part的位置
		if cfgpart.parent == part.name then
			local align = cfgpart.palign
			if align == 'ct' then
				offset.x, offset.y, offset.z = center.x, center.y, center.z + size.z
			elseif align == 'cm' then --cm
				offset.x, offset.y, offset.z = center.x, center.y, center.z
			elseif align == 'cb' then -- ct
				offset.x, offset.y, offset.z = center.x, center.y, center.z - size.z
			elseif align == 'lb' then -- rb
				offset.x, offset.y, offset.z = center.x - size.x, center.y, center.z - size.z
			elseif align == 'rb' then -- lb
				offset.x, offset.y, offset.z = center.x + size.x, center.y, center.z - size.z
			elseif align == 'lt' then -- rb
				offset.x, offset.y, offset.z = center.x - size.x, center.y, center.z + size.z
			elseif align == 'rt' then -- lb
				offset.x, offset.y, offset.z = center.x + size.x, center.y, center.z + size.z
			else
				assert(false, align)
			end

			-- print('onChangePartAABBSize size:', pname, align, offset)
			local child = self.parts[pname]
			child.roottransform:mulTranslationRight(offset)
		end
	end

	Container:returnBack(vec1, vec2, offset, center, size)
end

BuildBrick.initParts = function(self)
	local data = Part.getPartData(self.parttype)

	for i, pname in ipairs(data.orders) do
		assert(not self.parts[pname])
		local cpart = data.parts[pname]

		local part = {}
		part.name = pname
		part.data = cpart

		self.parts[pname] = part

		local mesh = Part.getSubMesh(self.parttype, pname)
		-- _mf:paintDiffuse(mesh, cpart.color)
		local bonenode = self.sen:add(mesh)
		bonenode.pickFlag = Global.CONSTPICKFLAG.BONE
		bonenode.part = part
		bonenode.visible = false
		bonenode.blender = _Blender.new()

		local ab = _AxisAlignedBox.new()
		ab:set(mesh:getBoundBox())
		bonenode.aabb = ab

		part.bonenode = bonenode

		-- 创建连接节点
		--local sphere = Block.getBlockMesh(148, nil, 1, 1, 1, 1)
		local sphere = _mf:createSphere()
		sphere.transform:setScaling(0.1, 0.1, 0.1)

		local jointnode = self.sen:add(sphere)
		jointnode.pickFlag = Global.CONSTPICKFLAG.JOINT
		jointnode.blender = _Blender.new()
		jointnode.blender:blend(0x00ffffff) -- 更新位置但不显示
		jointnode.part = part
		part.jointnode = jointnode

		-- 关联transform
		part.roottransform = _Matrix3D.new()
		local ppname = data.parts[pname].parent
		if ppname then
			local ppart = self.parts[ppname]
			part.roottransform.parent = ppart.roottransform
			part.ppart = ppart
		end

		part.blocktransform = _Matrix3D.new()

		jointnode.transform.parent = part.roottransform
		bonenode.transform.parent = part.roottransform

		local cx, cy, cz = Part.getJointPos(ab, data.parts[pname].jointalign, 0.04)
		jointnode.transform:setTranslation(cx, cy, cz)
		jointnode.visible = false

		part.transform = _Matrix3D.new()
		part.attachs = {}
	end
end

BuildBrick.showPart = function(self, type, show)
	if self.showSkl == show then return end

	self.parttype = type
	if not next(self.parts) then self:initParts() end
	-- 清空选中
	self:cmd_select_begin()
	self:cmd_select_end()
	--self:atom_select()

	if show then
		if not self.partcamera then self.partcamera = _Camera.new() end
		Global.CameraControl:push()
		local cc = Global.CameraControl:get()

		local ab1 = Container:get(_AxisAlignedBox)
		local vec1 = Container:get(_Vector3)
		local vec2 = Container:get(_Vector3)

		self:getPartsAABB(ab1)
		ab1:getCenter(vec1)
		vec2:set(0, -0.5, 0.1)
		_Vector3.add(vec1, vec2, vec2)
		cc:setEyeLook(vec2, vec1)
		cc:update()
		cc:use()

		--ab1:expand(0.2, 0.2, 0.2)

		ab1:alignCenter(Global.AXIS.ZERO)
		local r = calcCameraRadius(_rd.camera, ab1)
		cc:scale(r)
		cc:use()
		self.partcamera:set(_rd.camera)
		Global.CameraControl:pop()
		Container:returnBack(ab1, vec1, vec2)
	end

	self:cmd_showpart(show, self.partcamera)

	self:onBrickChange()
end

BuildBrick.refreshPartList = function(self)
	if not self.partdbs then self.partdbs = {} end

	local gs = {}
	for _, g in pairs(self.BlockGroups) do if g:isValid() then
		if not g.parent and not g.part and not g.attachpart then
			g.count = g:getBlockCount(g)
			table.insert(gs, g)
		end
	end end

	table.sort(gs, function(a, b) return a.count > b.count end)

	local list = self.ui.partlist
	list.onRenderItem = function(i, item)
		local g = gs[i]
		if not self.partdb then
			self.partdb = _DrawBoard.new(1024, 1024, 0)
		end

		local bs = {}
		self:getBindBlocks(g, bs)
		self:captureBlocks(self.partdb, bs, true, false, function(db)
			local ui = item:loadMovie(db)
			ui._width = item._width
			ui._height = item._height

			local bbs = {}
			if not self.disableBindPart then
				Global.setupItemDragEffect(item, db, self.ui, self.ui.partlist, function(mx, my)
					for _, b in ipairs(bbs) do
						b:setSkipped(false)
					end

					if self.rt_selectedPart then
						self:cmd_part_bind(self.rt_selectedPart, g)
						self:showPartList(true)
					end
					self:setPickedPart()
				end, function(mx, my)
					local dui = item.clickdata.dragui
					local scalef = Global.UI:getScale()
					local x, y = (mx + self.mdx) * scalef, (my + self.mdy) * scalef
					local p = self:pickBone(x, y)
					self:setPickedPart(p)
					self.rt_selectedPart = p

					dui._alpha = p and 50 or 80
					dui._x = dui._x + self.mdx / scalef
					dui._y = dui._y + self.mdy / scalef
					--print('dui', dui._width, dui._height, ui._width, ui._height, item._width, item._height)
				end, function(mx, my)
					if not item.clickdata then return end

					self:getPartBlocks(nil, bbs)
					for _, b in ipairs(bbs) do
						b:setSkipped(true)
					end

					local dui = item.clickdata.dragui
					dui._width, dui._height = ui._width, ui._height
				end)
			end
		end)
	end

	list.itemNum = #gs

	return #gs
end

BuildBrick.showPartList = function(self, show)
	local ui = self.ui
	local list = ui.partlist
	local h = ui.animuis._height

	list.visible = show
	--ui.animuis._y = list._y + list._height - h
	if show then
		local n = self:refreshPartList()
		--if n > 0 then
			--ui.animuis._y = list._y - h
		--end
	end
end

-- part==nil 返回所有的part的blocks
BuildBrick.getPartBlocks = function(self, part, bs)
	if not part then
		for name, part in pairs(self.parts) do
			local g = part.group
			local attachs = part.attachs
			for _, attach in pairs(attachs) do
				self:getBindBlocks(attach, bs)
			end
			if g then self:getBindBlocks(g, bs) end
		end
	else
		local g = part.group
		local attachs = part.attachs
		for _, attach in pairs(attachs) do
			self:getBindBlocks(attach, bs)
		end
		if g then self:getBindBlocks(g, bs) end
	end
end

BuildBrick.updatePartBlocksVisible = function(self)
	local editing = self.partopt ~= 'exit'
	local bs = {}
	self:getBlocks(bs)
	for i, b in ipairs(bs) do
		if not b.part and not b.part2 then
			b.node.visible = not editing
		else
			b.node.visible = true
		end
		-- if not editing then
		-- 	b.node.blender = nil
		-- end
	end
end

BuildBrick.updatePartBlocks = function(self, part)
	local bs = {}
	self:getPartBlocks(part, bs)
	for i, b in ipairs(bs) do
		b.node.transform:mulTranslationRight(0, 0, 0)
		b:formatMatrix()
	end

	-- mulTranslationRight(0,0,0) 用于处理修改父后transform没有更新的问题
	if part then
		part.bonenode.transform:mulTranslationRight(0, 0, 0)
		part.jointnode.transform:mulTranslationRight(0, 0, 0)
		if part.group then
			part.group:setDirty()
			part.group:setKnotCombineDirty()
		end
	else
		for name, part in pairs(self.parts) do
			part.bonenode.transform:mulTranslationRight(0, 0, 0)
			part.jointnode.transform:mulTranslationRight(0, 0, 0)
			if part.group then
				part.group:setDirty()
				part.group:setKnotCombineDirty()
			end
		end
	end

	self:onBrickChange()
end

BuildBrick.showAnimuis = function(self, type)
	local animuis = self.ui.animuis

	if type == 'bind' then
		animuis.visible = true

		animuis.bindpart.selected = true
		animuis.movepart.selected = false

		animuis.movejoint.visible = false
		--animuis.resetmove.visible = false
	elseif type == 'movebone' then
		animuis.visible = true
		animuis.bindpart.selected = false
		animuis.movepart.selected = true

		animuis.movejoint.visible = true
		animuis.movejoint.selected = false
		--animuis.resetmove.visible = true
	elseif type == 'movejoint' then
		animuis.bindpart.selected = false
		animuis.movepart.selected = true

		animuis.movejoint.visible = true
		animuis.movejoint.selected = true
		--animuis.resetmove.visible = true
	elseif type == 'preview' then
		animuis.visible = false
	elseif type == 'exit' then
		animuis.visible = false
	end
end

BuildBrick.editPart = function(self, type)
	if self.partopt == type then return end

	if type ~= 'exit' and type ~= 'preview' then
		self:playAnimIndex(nil, false)
	end

	local ui = self.ui
	local animuis = ui.animuis
	self.partopt = type

	self.rt_selectedPart = nil
	self:setPickedPart()
	self:showMovPartHint(false)

	-- self.disableCamMoveDepth = type == 'bind'
	if type == 'bind' then -- 进入编辑动画界面
		self.ondownfunc = self.ondown_bindpart
		self.onmovefunc = self.onmove_bindpart
		self.onupfunc = self.onup_bindpart

		-- 显示part列表
		self:showPartList(true)
		ui.animlist.visible = false
		self:showAnimuis(type)

		-- 显示动画骨骼
		for name, part in pairs(self.parts) do
			part.jointnode.visible = false
			part.bonenode.visible = not part.group
		end

		local bs = {}
		self:getBlocks(bs)
		for i, b in ipairs(bs) do
			b.node.visible = not not (b.part or b.part2)
		end

		for name, part in pairs(self.parts) do
			self:setPartBlender(part, 'normal')
		end
	elseif type == 'exit' then -- 回到编辑积木操作
		self.ondownfunc = self.ondown_editbrick
		self.onmovefunc = self.onmove_editbrick
		self.onupfunc = self.onup_editbrick

		for name, part in pairs(self.parts) do
			part.jointnode.visible = false
			part.bonenode.visible = false
		end

		self:showPartList(false)
		ui.animlist.visible = false
		self:showAnimuis(type)

		-- ui.previewanim.selected = false

		for name, part in pairs(self.parts) do
			self:setPartBlender(part, 'partgroup')
		end
		local bs = {}
		self:getBlocks(bs)
		for i, b in ipairs(bs) do
			--b.node.blender = nil
			b.node.visible = true
		end
	elseif type == 'movebone' or type == 'movejoint' then -- 移动part
		self.jointediting = type == 'movejoint'
		self.ondownfunc = self.ondown_movepart
		self.onmovefunc = self.onmove_movepart
		self.onupfunc = self.onup_movepart

		for name, part in pairs(self.parts) do
			part.jointnode.visible = part.group and self.jointediting and name ~= 'waist' and self.rt_pickedpart == part
			part.bonenode.visible = not part.group and not self.jointediting
		end
		--ui.partlist.visible = false
		self:showPartList(false)
		ui.animlist.visible = false

		self:showAnimuis(type)

		for name, part in pairs(self.parts) do
			self:setPartBlender(part, self.jointediting and 'jointnormal' or 'normal')
		end
	elseif type == 'preview' then -- 预览动画效果
		self.ondownfunc = nil
		self.onmovefunc = nil
		self.onupfunc = nil

		self:showAnimuis(type)

		ui.animlist.visible = true
		self:showPartList(false)

		for name, part in pairs(self.parts) do
			part.jointnode.visible = false
			part.bonenode.visible = false

			self:setPartBlender(part, 'normal')
		end
	end

	self:ui_flush_undo()
end

local jnodeimg1 = _Image.new('joint_point1.png')
local jnodeimg2 = _Image.new('joint_point2.png')
local line1 = _Image.new('joint_line1.png')
local line2 = _Image.new('joint_line2.png')
local mat2d = _Matrix2D.new()

BuildBrick.draw3DLine = function(self, img, pos1, pos2, size)
	img.h = size
	local v2_2 = Container:get(_Vector2)
	_Vector2.sub(pos1, pos2, v2_2)
	img.w = v2_2:magnitude()

	--v2_2:normalize()
	v2_2.x = v2_2.x / img.w
	v2_2.y = v2_2.y / img.w
	local r = v2_2.y > 0 and math.acos(v2_2.x) or -math.acos(v2_2.x)
	mat2d:setRotation(r)
	mat2d:mulTranslationRight(pos2.x, pos2.y)
	_rd:pushMatrix2D(mat2d)
	img:drawImage(0, - size / 2, _Color.White)
	_rd:popMatrix2D()

	Container:returnBack(v2_2)
end

BuildBrick.drawPart = function(self)
	if not self.enablePart then
		return
	end

	if self.partopt == 'movejoint' then
		local v3_1 = Container:get(_Vector3)
		local v2_2 = Container:get(_Vector2)

		local dir = Container:get(_Vector3)
		_Vector3.sub(_rd.camera.look, _rd.camera.eye, dir)
		dir:normalize()

		local imgposs = {}
		local data = Part.getPartData(self.parttype)
		for i, pname in ipairs(data.orders) do
			local p = self.parts[pname]

			p.jointnode.transform:getTranslation(v3_1)
			local x, y, s = _G.projectWithSize(v3_1, 0.05)
			imgposs[pname] = {size = s, pos = _Vector2.new(x, y)}
			p.jointpos = imgposs[pname]
		end

		for i, pname in ipairs(data.orders) do
			local p = self.parts[pname]
			local imgpos = imgposs[pname]
			local color = _Color.new(p.data.color)

			local ppname = data.parts[pname] and data.parts[pname].parent
			if ppname then
				local pimgpos = imgposs[ppname]
				local img = self.rt_selectedPart and (self.rt_selectedPart.name == pname or self.rt_selectedPart.name == ppname) and line2 or line1
				self:draw3DLine(img, pimgpos.pos, imgpos.pos, imgpos.size)

--[[
				img.h = imgpos.size

				_Vector2.sub(pimgpos.pos, imgpos.pos, v2_2)
				img.w = v2_2:magnitude()

				--v2_2:normalize()
				v2_2.x = v2_2.x / img.w
				v2_2.y = v2_2.y / img.w
				local r = v2_2.y > 0 and math.acos(v2_2.x) or -math.acos(v2_2.x)
				mat2d:setRotation(r)
				mat2d:mulTranslationRight(imgpos.pos.x, imgpos.pos.y)
				_rd:pushMatrix2D(mat2d)
				img:drawImage(0, - imgpos.size / 2, color)
				-- _rd:drawLine(0, 0, img.w, 0, _Color.Red)
				_rd:popMatrix2D()
				-- _rd:drawLine(pimgpos.pos.x, pimgpos.pos.y, imgpos.pos.x, imgpos.pos.y, _Color.Red)
--]]
			end
		end

		for i, pname in ipairs(data.orders) do
			local p = self.parts[pname]
			local imgpos = imgposs[pname]
			local color = _Color.new(p.data.color)

			local img = self.rt_selectedPart and self.rt_selectedPart.name == pname and jnodeimg2 or jnodeimg1
			img.w = imgpos.size * 2
			img.h = imgpos.size * 2
			img:drawImage(imgpos.pos.x - imgpos.size, imgpos.pos.y - imgpos.size, color)
		end

		Container:returnBack(dir, v3_1, v2_2)
	end
end

BuildBrick.ondown_bindpart = function(self, x, y)
	if self.disableBindPart then return end
	local p = self:pickPart(x, y)
	self.rt_selectedPart = p
	self:setPickedPart(p)
	if not p then return false end

	self:cmd_part_unbind_begin()
end

BuildBrick.onmove_bindpart = function(self, x, y)
end

BuildBrick.onup_bindpart = function(self, x, y)
	if self.disableBindPart then return end

	self.rt_selectedPart = nil
	self:setPickedPart()
	self:cmd_part_unbind_end()
end

BuildBrick.showMovPartHint = function(self, show)
	if not show then
		if self.movePartUI then
			self.movePartUI.visible = false
			self.ui.animuis.resetmove.visible = false
		end
		return
	end

	local h = self.ui._height
	if not self.movePartUI then
		local ui = self.ui:loadView('movePlane')
		self.movePartUI = ui
		ui._width, ui._height = 400, 400
		ui._x, ui._y = 0, h / 2 - self.movePartUI._width / 2
		ui:addRelation(self.ui, _FairyManager.Left_Left)
		ui:addRelation(self.ui, _FairyManager.Middle_Middle)

		local clickfunc = function(btn)
			local step = _sys:isKeyDown(_System.KeyShift) and 0.02 or 0.1
			local axis
			if btn == Global.DIRECTION.RIGHT then
				axis = Global.typeToAxis(Global.dir2AxisType(Global.DIRECTION.RIGHT, Global.AXISTYPE.Z))
			elseif btn == Global.DIRECTION.LEFT then
				axis = Global.typeToAxis(Global.dir2AxisType(Global.DIRECTION.LEFT, Global.AXISTYPE.Z))
			elseif btn == Global.DIRECTION.UP then
				local c = self:getCameraControl()
				local dirv = c:getDirV()
				if dirv > math.pi * 0.25 and dirv < math.pi * 0.75 then
					axis = Global.typeToAxis(Global.dir2AxisType(Global.DIRECTION.UP, Global.AXISTYPE.Z))
				else
					axis = Global.AXIS.Z
				end
			elseif btn == Global.DIRECTION.DOWN then
				local c = self:getCameraControl()
				local dirv = c:getDirV()
				if dirv > math.pi * 0.25 and dirv < math.pi * 0.75 then
					axis = Global.typeToAxis(Global.dir2AxisType(Global.DIRECTION.DOWN, Global.AXISTYPE.Z))
				else
					axis = Global.AXIS.NZ
				end
			end

			if not axis then return end
			local part = self.rt_selectedPart
			if not part then return end

			local mat = self.jointediting and part.jointnode.transform or part.roottransform

			self:cmd_mat_update_begin(nil, 'move')
			Global.PickHelper:attachBlocks(nil, nil, mat)
			Global.PickHelper:clickMove(axis, step, false)
			self:cmd_mat_update_end()

			if self.checkBlocking then
				self:checkBlocking(self.rt_selectedBlocks)
			end
		end

		ui.right.click = function()
			clickfunc(Global.DIRECTION.RIGHT)
		end
		ui.left.click = function()
			clickfunc(Global.DIRECTION.LEFT)
		end
		ui.up.click = function()
			clickfunc(Global.DIRECTION.UP)
		end
		ui.down.click = function()
			clickfunc(Global.DIRECTION.DOWN)
		end

		ui.checkhit.visible = false
	end

	self.movePartUI.visible = show
	self.ui.animuis.resetmove.visible = show
end

BuildBrick.ondown_movepart = function(self, x, y)
	local p = self.jointediting and self:pickJoint(x, y) or self:pickPart(x, y)
	self.rt_selectedPart = p
	self:setPickedPart(p)

	self:showMovPartHint(not not p)

	if not p then return false end
	self:cmd_part_update_begin()
end

BuildBrick.onmove_movepart = function(self, x, y)
	if not self.rt_selectedPart then return end
	self:movePartBegin(x, y)

	self:movePart(x, y)
	self:atom_part_setDirty()
end

BuildBrick.onup_movepart = function(self, x, y)
	--self:setPickedPart()
	if not self.rt_selectedPart then return end
	--if not self.rt_partmoving then return end
	self:movePartEnd(x, y)
	self:cmd_part_update_end()
	--self.rt_selectedPart = nil

	if self.downX == x and self.downY == y then
		return
	end

	return true
end

BuildBrick.setPartBlender = function(self, part, mode)
	local data = Part.getPartData(self.parttype)
	local cpart = data.parts[part.name]
	local color = _Color.new(cpart.color)
	if mode == 'normal' then
		color.a = 0.75
		part.bonenode.blender:blend(color:toInt())
		--part.jointnode.blender:blend(color:toInt())
		if part.group then
			part.group:setBlender(nil)
		end
	elseif mode == 'partgroup' then
		if part.group then
			part.group:setBlender(nil)
		end
	elseif mode == 'hover' then
		color.a = 0.75
		part.bonenode.blender:highlight(color:toInt())
		--part.jointnode.blender:highlight(color:toInt())
		if part.group then
			part.group:setBlender(part.bonenode.blender, part.name)
		end
	elseif mode == 'jointnormal' then
		color.a = 0.75
		part.bonenode.blender:blend(color:toInt())
		--part.jointnode.blender:blend(color:toInt())
		if part.group then
			--part.group:setBlender(part.bonenode.blender, part.name)
			part.group:setBlender(nil)
		end
	elseif mode == 'jointhover' then
		color.a = 0.75
		part.bonenode.blender:highlight(color:toInt())
		--part.jointnode.blender:highlight(color:toInt())
		if part.group then
			part.group:setBlender(part.bonenode.blender, part.name)
		end
	end
end

BuildBrick.setPickedPart = function(self, part)
	if part == self.rt_pickedpart then return end

	if self.rt_pickedpart then
		self:setPartBlender(self.rt_pickedpart, self.jointediting and 'jointnormal' or 'normal')
		self.rt_pickedpart.jointnode.visible = false
	end

	if part then
		self:setPartBlender(part, self.jointediting and 'jointhover' or 'hover')
	end

	self.rt_pickedpart = part

	if self.jointediting and part and part.group and part.name ~= 'waist' then
		part.jointnode.visible = true
	end
end

BuildBrick.movePartBegin = function(self, downx, downy)
	if self.rt_partmoving then
		return
	end
	self.rt_partmoving = true

	local part = self.rt_selectedPart
	Global.ui.controler.planemovebutton:attachBlock(
		self.jointediting and part.jointnode.transform or part.roottransform, Global.MOVESTEP.TILE)

	local scalef = Global.UI:getScale()
	local args = {mouse = {x = downx / scalef, y = downy / scalef}}
	Global.ui.controler.planemovebutton.onMouseDown(args)
end

BuildBrick.movePartEnd = function(self, endx, endy)
	if not self.rt_partmoving then
		return
	end
	local scalef = Global.UI:getScale()
	local args = {mouse = {x = endx / scalef, y = endy / scalef}}
	Global.ui.controler.planemovebutton.onMouseUp(args)

	self.rt_partmoving = false
end

BuildBrick.movePart = function(self, movex, movey)
	if not self.rt_partmoving then
		return
	end
	local scalef = Global.UI:getScale()
	local args = {mouse = {x = movex / scalef, y = movey / scalef}}
	Global.ui.controler.planemovebutton.onMouseMove(args)
end

BuildBrick.resetPart = function(self, p)
	local cx, cy, cz = 0, 0, 0
	local ab = Container:get(_AxisAlignedBox)
	p.jointnode.transform.parent = nil

	if p.ppart then
		self:getPartAABB(p.ppart, ab)
		cx, cy, cz = Part.getJointPos(ab, p.data.palign, 0.04)

		p.jointnode.transform:setTranslation(cx, cy, cz)
	end

	self:getPartAABB(p, ab)
	local x, y, z = self:getBoxOffsetAlignJoint(p, ab)
	p.roottransform:mulTranslationRight(x, y, z)

	p.jointnode.transform:bindParent(p.roottransform)

	Container:returnBack(ab)
end

BuildBrick.getRootZ_MinZ = function(self)
	local pnames = {'l_foot', 'r_foot', 'l_calf', 'r_calf', 'l_thing', 'r_thing'}
	local ab = _AxisAlignedBox.new()
	ab:initBox()

	local find = false
	for i, pname in ipairs(pnames) do
		local part = self.parts[pname]
		if part.group then
			_AxisAlignedBox.union(ab, part.group:getAABB(), ab)

			for i, g in ipairs(part.attachs) do
				_AxisAlignedBox.union(ab, g:getAABB(), ab)
			end
			find = true
		end
	end

	if not find then
		for name, part in pairs(self.parts) do if part.group then
			_AxisAlignedBox.union(ab, part.group:getAABB(), ab)

			for i, g in ipairs(part.attachs) do
				_AxisAlignedBox.union(ab, g:getAABB(), ab)
			end
			find = true
		end end

		if not find then
			return 0
		end
	end

	return ab.min.z
end

---------------------------- 调试功能
BuildBrick.mirrorPart = function(self)
	if not self.enablePart then return end
	-- 保持左右部件对称
	local parts = {
		'l_upperarm',
		'r_upperarm',
		'l_forearm',
		'r_forearm',
		'l_hand',
		'r_hand',

		'l_thing',
		'r_thing',
		'l_calf',
		'r_calf',
		'l_foot',
		'r_foot',
	}

	local ab1 = _AxisAlignedBox.new()
	local ab2 = _AxisAlignedBox.new()

	local center1 = _Vector3.new()
	local center2 = _Vector3.new()
	local size1 = _Vector3.new()
	local size2 = _Vector3.new()

	local v1 = _Vector3.new()
	local v2 = _Vector3.new()

	for i = 1, #parts, 2 do
		local lname, rname = parts[i], parts[i + 1]
		local lpart, rpart = self.parts[lname], self.parts[rname]
		if lpart.group and rpart.group then
			self:getPartAABB(lpart, ab1)
			self:getPartAABB(rpart, ab2)

			ab1:getSize(size1)
			ab2:getSize(size2)
			if math.floatEqualVector3(size1, size2) then
				ab1:getCenter(center1)
				ab2:getCenter(center2)

				lpart.roottransform:getTranslation(v1)
				rpart.roottransform:getTranslation(v2)
				v1.x = - v1.x
				_Vector3.sub(v1, v2, v2)
				rpart.roottransform:mulTranslationRight(v2)

				lpart.jointnode.transform:getTranslation(v1)
				rpart.jointnode.transform:getTranslation(v2)
				v1.x = - v1.x
				_Vector3.sub(v1, v2, v2)
				rpart.jointnode.transform:mulTranslationRight(v2)

				self:atom_part_setDirty()
			else
				print(string.format('!!!部件%s - %s尺寸不一致:', lname, rname), size1, size2)
			end
		end
	end
end