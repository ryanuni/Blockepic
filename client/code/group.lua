local Container = _require('Container')
local Function = _require('Function')

local group = {}
Global.group = group
group.typestr = 'group'

group.new = function(scene, data)
	if data == nil then
		data = {blocks = data, functions = {}}
	end
	if data.blocks == nil then
		data.blocks = {}
	end

	local blocks = {}
	for i, v in ipairs(data.blocks) do
		table.insert(blocks, scene:getBlock(v))
	end

	local g = {}
	setmetatable(g, {__index = group})

	g.datablocks = {}
	g:setBlocks(blocks, true)
	g.functions = {}
	g.rtdata = {available = true}
	g.boundBox = _AxisAlignedBox.new()

	for i, v in ipairs(data.functions) do
		g:addFunction(Function.new(v))
	end

	return g
end
group.refresh = function(self)
	self:setBlocks(self.datablocks, false)
end
group.tostring = function(self, head)
	head = head or ''
	local str = head .. '{\n'
	str = str .. head .. '\tindex = ' .. self.index .. ',\n'
	str = str .. head .. '\tblocks = {'
	for i, v in ipairs(self.blocks) do
		str = str .. v.index .. ', '
	end
	str = str .. '},\n'
	str = str .. head .. '\tfunctions = {\n'
	for i, v in ipairs(self.functions) do
		str = str .. v:tostring(head .. '\t\t', 'group', self.index)
	end
	str = str .. head .. '\t},\n'
	str = str .. head .. '}'
	return str
end
group.getIndexInfo = function(self, curtype, curid)
	return 'groupid = ' .. ((self.index == curid and curtype == 'group') and -1 or self.index)
end
group.addBlock = function(self, b, updatedata)
	if self:indexBlock(b) == -1 then
		table.insert(self.blocks, b)
	end
	if updatedata then
		self:addDataBlock(b)
	end
end
group.delBlock = function(self, b, updatedata)
	table.remove(self.blocks, self:indexBlock(b))

	if updatedata then
		self:delDataBlock(b)
	end
end
group.getBlocks = function(self)
	return self.blocks
end
group.setBlocks = function(self, bs, updatedata)
	self.blocks = {}
	for i, v in ipairs(bs) do
		table.insert(self.blocks, v)
	end
	if updatedata then
		self:setDataBlocks(bs)
	end
end

group.addDataBlock = function(self, b)
	if self:indexDataBlock(b) == -1 then
		table.insert(self.datablocks, b)
	end
end
group.delDataBlock = function(self, b)
	table.remove(self.datablocks, self:indexDataBlock(b))
end
group.setDataBlocks = function(self, bs)
	self.datablocks = {}
	for i, v in ipairs(bs) do
		table.insert(self.datablocks, v)
	end
end

group.indexDataBlock = function(self, b)
	if self.datablocks then
		for i, v in ipairs(self.datablocks) do
			if v == b then
				return i
			end
		end
	end

	return -1
end

group.setNeedUpdateBoundBox = function(self)
	self.needUpdateBoundBox = true
end

group.updateAABB = function(self)
	if self.needUpdateBoundBox then
		if #self.blocks == 0 then
			self.boundBox:initBox()
		else
			-- can not set aabb to self.boundbox
			local aabb = Block.getAABBs(self.blocks)
			self.boundBox.min.x = aabb.min.x
			self.boundBox.min.y = aabb.min.y
			self.boundBox.min.z = aabb.min.z
			self.boundBox.max.x = aabb.max.x
			self.boundBox.max.y = aabb.max.y
			self.boundBox.max.z = aabb.max.z
		end
	end

	self.needUpdateBoundBox = false
end

group.getAABB = function(self)
	-- check update time
	local time = _now()
	if self.needUpdateBoundBoxEndTime then
		self:setNeedUpdateBoundBox()
		if self.needUpdateBoundBoxEndTime < _now() + 1000 then
			self.needUpdateBoundBoxEndTime = nil
		end
	else
		self.needUpdateBoundBoxEndTime = nil
	end

	self:updateAABB()
	return self.boundBox
end

group.indexBlock = function(self, b)
	if self.blocks then
		for i, v in ipairs(self.blocks) do
			if v == b then
				return i
			end
		end
	end

	return -1
end
--------------------------------------------------------
local groupSelectedBlender = _Blender.new()
groupSelectedBlender:blend(0x80ffffff)
group.initSelectedEffect = function(self)
	if self.selectedEffect then return end
--	print('[group.initSelectedEffect]', self.selectedEffect)

	self.selectedEffect = {}

	local pfx = Global.sen.pfxPlayer:play('yj_anquan_yuan.pfx')
	self.selectedEffect.pfx = pfx

	local mesh = _mf:createCube()
	mesh.isAlpha = true
	mesh.isAlphaFilter = true
	local scale = 0.15
	mesh.transform:setScaling(scale, scale, scale)
	mesh.transform:mulTranslationRight(0, 0, scale)

	local node = Global.sen:add(mesh)
	node.pickFlag = Global.CONSTPICKFLAG.GROUPSELECT
	node.blender = groupSelectedBlender

	-- self = group self
	node.onPick1 = function()
		local ui = Global.ui
		if ui.propertyEditor.isLinking and ui.propertyEditor.targetobject == nil then
			ui.propertyEditor:setCheckObject(self)
		elseif ui.propertyEditor.isSelectingObject then
			ui.propertyEditor:setSelectObject(self)
		end
	end

	node.onPick = function()
		Global.editor:cmd_selectGroup(self)
	end

	self.selectedEffect.node = node
end
group.clearSelectedEffect = function(self)
	-- print('[group.clearSelectedEffect]', self.selectedEffect)
	Global.sen:del(self.selectedEffect.node)
	self.selectedEffect.pfx:stop(true)
	self.selectedEffect = nil
end
group.showSelectedEffect = function(self, show, pos)
	-- print('[group.showSelectedEffect]', show, pos)
	if not self.selectedEffect then
		self:initSelectedEffect()
	end

	self.selectedEffect.pfx.visible = show
	self.selectedEffect.node.visible = show
	if pos then
		self.selectedEffect.node.transform:setTranslation(pos.x, pos.y, pos.z + 1)
		self.selectedEffect.pfx.transform:setTranslation(pos)
	end
end
group.onUpdate = function(self)
	local aabb = self:getAABB()
	local center = Container:get(_Vector3)
	aabb:getCenter(center)

	local visible = false
	for p, q in ipairs(self.blocks) do
		if q.node.visible then
			visible = true
			break
		end
	end

	if visible then
		local distance = _Vector3.distance(_rd.camera.eye, center)
		local aabbSize = Container:get(_Vector3)
		aabb:getSize(aabbSize)

		local result = {}
		local ray = {}
		ray.x1 = center.x
		ray.y1 = center.y
		ray.z1 = center.z + aabbSize.z / 2 + 0.01

		ray.x2 = 0
		ray.y2 = 0
		ray.z2 = -1
		Global.sen:pick(ray, Global.CONSTPICKFLAG.NORMALBLOCK + Global.CONSTPICKFLAG.SELECTBLOCK, result)

		local blk = result.node and result.node.block
		-- Z value.
		local pickPos = Container:get(_Vector3)
		pickPos.x = result.x
		pickPos.y = result.y
		pickPos.z = result.z

		local targetPos = Container:get(_Vector3)
		if blk and aabb:checkInside(pickPos) then
			targetPos.x = result.x
			targetPos.y = result.y
			targetPos.z = result.z
		else
			targetPos:set(center)
			targetPos.z = center.z + aabbSize.z / 2
		end

		self:showSelectedEffect(true, targetPos)

		Container:returnBack(aabbSize)
		Container:returnBack(targetPos)
		Container:returnBack(pickPos)
	else
		self:showSelectedEffect(false)
	end

	Container:returnBack(center)
end
--------------------------------------------------------
group.registerAction = function(self, action)
	action:onRegister(self)
end
group.logoutAction = function(self, action)
	action:onLogout(self)
end
group.registerPress = function(self, func)
	for i, v in ipairs(self.blocks) do
		v:registerPress(func)
	end
end
group.registerUp = function(self, func)
	for i, v in ipairs(self.blocks) do
		v:registerUp(func)
	end
end
group.registerPushup = function(self, func)
	for i, v in ipairs(self.blocks) do
		v:registerPushup(func)
	end
end
group.registerDown = function(self, func)
	for i, v in ipairs(self.blocks) do
		v:registerDown(func)
	end
end
group.registerTouch = function(self, func)
	for i, v in ipairs(self.blocks) do
		v:registerTouch(func)
	end
end
group.registerApproach = function(self, action, func)
	for i, v in ipairs(self.blocks) do
		v:registerApproach(action, func)
	end
end
group.registerFarAway = function(self, action, func)
	for i, v in ipairs(self.blocks) do
		v:registerFarAway(action, func)
	end
end
group.switchAvailable = function(self, available)
	self.rtdata.available = available
	for i, v in ipairs(self.blocks) do
		v:switchAvailable(available)
	end
end
group.changeTransparency = function(self, transparency, time)
	if not self.transparencyBlender then
		self.transparencyBlender = _Blender.new()
	end
	for i, v in ipairs(self.blocks) do
		v:changeTransparency(transparency, time, self.transparencyBlender)
	end
end
group.registerPick = function(self, func)
	for i, v in ipairs(self.blocks) do
		v:registerPick(func)
	end
end
group.switchVisible = function(self, visible, physic)
	if not self.rtdata.available then return end

	for i, v in ipairs(self.blocks) do
		v:switchVisible(visible, physic)
	end
end
group.showHint = function(self, showhint, showedge)
	for i, v in ipairs(self.blocks) do
		v:showHint(showhint and i == 1, showedge)
	end
end
group.isIntersect = function(self, target)
	for i, v in ipairs(self.blocks) do
		if v.node.visible then
			local intersect, block = v:isIntersect(target)
			if intersect and self:indexBlock(block) == -1 then
				return true
			end
		end
	end
	return false
end
group.bomb = function(self, range, time)
	if not self.rtdata.available then return end

	Block.blast(self.blocks, range, time)
	self:switchAvailable(false)
end
group.startClock = function(self, clock)
	if not self.rtdata.available then return end
	clock:start()
end
group.getTransform = function(self)
	local vmax = Container:get(_Vector3)
	local vmin = Container:get(_Vector3)
	local blocks = self.blocks
	if #blocks == 0 then return end

	local frist = true
	local vec = Container:get(_Vector3)
	for i, v in ipairs(blocks) do
		if v.node.visible then
			if frist then
				v.node.transform:getTranslation(vmax)
				vmin:set(vmax)
				frist = false
			end
			v.node.transform:getTranslation(vec)
			vmax.x = math.max(vmax.x, vec.x)
			vmax.y = math.max(vmax.y, vec.y)
			vmax.z = math.max(vmax.z, vec.z)

			vmin.x = math.min(vmin.x, vec.x)
			vmin.y = math.min(vmin.y, vec.y)
			vmin.z = math.min(vmin.z, vec.z)
		end
	end

	vec.x = (vmax.x + vmin.x) / 2
	vec.y = (vmax.y + vmin.y) / 2
	vec.z = (vmax.z + vmin.z) / 2

	local mat = _Matrix3D.new()
	mat:setTranslation(vec)
	Container:returnBack(vmax, vmin, vec)
	return mat
end
group.playSound = function(self, soundGroup)
	if not self.rtdata.available then return end
	local mat = self:getTransform()
	local vec = Container:get(_Vector3)
	if mat then
		mat:getTranslation(vec)
		soundGroup:play(vec)
	else
		soundGroup:play()
	end
	if soundGroup.soundName == 'coin' then
		local pfx = _Particle.new('coin_001.pfx')
		pfx.transform:mulTranslationLeft(vec)
		self.node.mesh.pfxPlayer:play(pfx)
	end
	Container:returnBack(vec)
end
group.playPfx = function(self, pfxname, useblock, mat)
	if not self.rtdata.available then return end
	if #self.blocks == 0 then useblock = false end
	if useblock then
		self:stopPfx(pfxname, useblock)
		local minb = self.blocks[1]
		local mindis = minb:roleDistance()
		for i, b in ipairs(self.blocks) do
			local dis = b:roleDistance()
			if dis < mindis then
				mindis = dis
				minb = b
			end
		end

		minb:playPfx(pfxname, mat)
	else
		Global.sen.pfxPlayer:play(pfxname, pfxname, self:getTransform())
	end
end
group.stopPfx = function(self, pfxname, useblock)
	if not self.rtdata.available then return end
	if #self.blocks == 0 then useblock = false end
	if useblock then
		for i, b in ipairs(self.blocks) do
			b:stopPfx(pfxname)
		end
	else
		Global.sen.pfxPlayer:stop(pfxname)
	end
end
group.startMoveMent = function(self, movement)
	if not self.rtdata.available then return end
	movement:start()
end
group.moveTranslation = function(self, ...)
	-- 需要更新一段时间
	self:setNeedUpdateBoundBox()
	local x, y, z, time = ...
	self.needUpdateBoundBoxEndTime = _now() + (time or 0)
	for i, v in ipairs(self.blocks) do
		v:moveTranslation(...)
	end
end
group.getAnchorBlock = function(self)
	for i, v in ipairs(self.blocks) do
		if v:getAnchorBlock() then
			return v
		end
	end
end
group.buttonPress = function(self, dir, time)
	Block.applyButtonEffect(self.blocks, dir, time)
end
group.startRotateMent = function(self, rotatement)
	if not self.rtdata.available then return end
	rotatement:start()
end
group.moveRotation = function(self, ...)
	-- 需要更新一段时间
	self:setNeedUpdateBoundBox()
	local dx, dy, dz, tr, time = ...
	self.needUpdateBoundBoxEndTime = _now() + (time or 0)
	for i, v in ipairs(self.blocks) do
		v:moveRotation(...)
	end
end
group.moveRotationRight = function(self, ...)
	-- 需要更新一段时间
	self:setNeedUpdateBoundBox()
	local dx, dy, dz, tr, time = ...
	self.needUpdateBoundBoxEndTime = _now() + (time or 0)
	for i, v in ipairs(self.blocks) do
		v:moveRotationRight(...)
	end
end
group.setTrophy = function(self, enabled)
	for i, v in ipairs(self.blocks) do
		v:setTrophy(enabled)
	end
end
group.setContent = function(self, key, value)
	if self.rtdata.available == false then return end
	for i, v in ipairs(self.blocks) do
		v:setContent(key, value)
	end
end
group.getContent = function(self, key)
	local content = nil
	for i, v in ipairs(self.blocks) do
		if v.node.visible and content and content ~= v:getContent(key) then
			return nil
		end
		if content == nil then
			content = v:getContent(key)
		end
	end
	return content
end
group.getActions = function(self)
	local actions = {}
	for i, v in ipairs(self.functions) do
		for p, q in ipairs(v.actions) do
			table.insert(actions, q)
		end
	end
	return actions
end
group.registerEvents = function(self, events)
	for i, v in ipairs(self:getActions()) do
		v:onRegister(self)
	end
end
group.logoutEvents = function(self)
	for i, v in ipairs(self:getActions()) do
		v:onLogout(self)
	end
end
group.initEvents = function(self)
	for i, v in ipairs(self.functions) do
		if #v.sourceactions == 0 then
			v:trigger()
		end
	end
end
group.addFunction = function(self, f, index)
	index = index or #self.functions + 1
	if self:indexFunction(f) == -1 then
		f.owner = self
		table.insert(self.functions, index, f)
	end
end
group.delFunction = function(self, f)
	f.owner = nil
	f:delFromSourceActions()
	table.remove(self.functions, self:indexFunction(f))
end
group.indexFunction = function(self, f)
	for i, v in ipairs(self.functions) do
		if v == f then
			return i
		end
	end
	return -1
end
group.getFunction = function(self, id)
	return self.functions[id]
end
group.loadActionFunctions = function(self, scene)
	for i, v in ipairs(self:getActions()) do
		if not v.loadedFunctions then
			local functions = v.functions
			v.functions = {}
			for p, q in ipairs(functions) do
				if q.typestr ~= 'Function' then
					local object = scene:getObjectByIndexInfo({groupid = q.groupid, blockid = q.blockid}) or self
					v:addFunction(object:getFunction(q.functionid))
				else
					v:addFunction(q)
				end
			end
			v.loadedFunctions = true
		end
		v:loadObjects(self, scene)
	end
end

return group
