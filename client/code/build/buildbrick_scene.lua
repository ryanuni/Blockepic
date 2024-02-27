local Container = _require('Container')
local BuildBrick = _G.BuildBrick

BuildBrick.getBlocks = function(self, nbs, f)
	self.sen:getBlocksByFilter(nbs, function(b)
		return not b.isWall and not b.isdummyblock and not b.skipped and (not f or f(b))
	end)
end

BuildBrick.getAllBlocks = function(self, nbs, f)
	self.sen:getBlocksByFilter(nbs, function(b)
		return not b.isWall and (not f or f(b))
	end)
end

BuildBrick.getRootGroups = function(self, gs, bs, hastemp)
	local mode = hastemp and 'tempRoot' or 'root'
	if not bs then
		bs = {}
		self:getBlocks(bs)
	end

	local gs_hash = {}
	for i, b in ipairs(bs) do
		local g = b:getBlockGroup(mode)
		gs_hash[g] = true
	end

	for c in pairs(gs_hash) do
		table.insert(gs, c)
	end
end

BuildBrick.getGroups = function(self, gs, bs)
	if not bs then
		bs = {}
		self:getBlocks(bs)
	end

	local gs_hash = {}
	for i, b in ipairs(bs) do
		local g = b:getBlockGroup('tempRoot')
		g:getConnects(gs_hash, true)
	end

	for c in pairs(gs_hash) do
		table.insert(gs, c)
	end
end

BuildBrick.getAllGroups = function(self, gs)
	for _, g in pairs(self.BlockGroups) do if g:isValid() then
		table.insert(gs, g)
	end end
end

BuildBrick.addBlockToScene = function(self, data)
	local b = self.sen:createBlock(data)
	-- 自动分配分组
	b:getBlockGroup()

	self:findUncollidedPlace({b})
	return b
end

BuildBrick.findUncollidedPlace = function(self, nbs, ns, center, maxcount, checkfunc)
	local ab = Container:get(_AxisAlignedBox)
	Block.getAABBs(nbs, ab)
	ab:alignSizeZ(0.08)

	local pos = Container:get(_Vector3)
	if not center then
		center = _Vector3.new()
		self:getLookAtCenter(center, ab)
	end

	local step = 0.8
	center.x = math.floatRound(center.x, step)
	center.y = math.floatRound(center.y, step)
	-- center.z = math.floatRound(center.z, step)

	local pickflag = Global.CONSTPICKFLAG.NORMALBLOCK + Global.CONSTPICKFLAG.SELECTBLOCK

	-- 设置过滤flag
	for i, b in ipairs(nbs) do
		b.oldpickflag = b:getPickFlag()
		b:setPickFlag(Global.CONSTPICKFLAG.DUMMY)
	end

	if ns then
		if not self:findUncollidedPos(pos, ab, center, ns, pickflag, checkfunc, maxcount) then
			pos:set(center)
		end
	else
		local type1 = Global.dir2AxisType(Global.DIRECTION.RIGHT, Global.AXISTYPE.Z)
		local type2 = Global.dir2AxisType(Global.DIRECTION.LEFT, Global.AXISTYPE.Z)
		if not self:findUncollidedPos(pos, ab, center, {type1}, pickflag, checkfunc, maxcount) then
			if not self:findUncollidedPos(pos, ab, center, {type2}, pickflag, checkfunc, maxcount) then
				pos:set(center)
			end
		end
	end

	for i, b in ipairs(nbs) do
		b:setPickFlag(b.oldpickflag)
		b.oldpickflag = nil
	end

	local diff = ab:diffBottom(pos)
	for i, b in ipairs(nbs) do
		b.node.transform:mulTranslationRight(diff)
		b:formatMatrix()
	end

	Container:returnBack(ab, pos)
end

BuildBrick.clearSceneBlock = function(self, keepicon)
	local nbs = {}
	self:getBlocks(nbs)

	self:atom_block_del_s(nbs)

	if not keepicon then
		self:refreshModuleIcon()
	end

	self:clearGroups()
	self.showSkl = false
	self:clearParts()
end

BuildBrick.addBlock = function(self, shape, markerdata)
	local b = self:cmd_addBrick2(1, shape)
	if markerdata then
		local marker = BMarker.new(markerdata)
		marker:setBlock(b)
		b.markerdata = marker
		b:setAABBSkipped(true)
	end

	-- 音乐关卡添加积木自动设置为背景
	if self:isMusicMode('music_bg') and not self:isHelperDummy(b) then
		b.isDungeonBg = true
	end

	self:hideBricksUI()

	b:getBlockGroup()

	if self:isMusicMode('music_train') then
		self:setMusicDummy(b)

		local NS = {}
		if _rd.camera.look.y - _rd.camera.eye.y > 0 then
			NS = {Global.AXISTYPE.NX}
		else
			NS = {Global.AXISTYPE.X}
		end
		self:findUncollidedPlace({b}, NS, nil, nil, function(box, flag)
			if self.sen:boxPick(box, flag) then
				return true
			end
			if self:checkMusicCollision(box, 'runway') then
				return true
			end
			return false
		end)
	end

	return b
end

BuildBrick.switchAssets = function(self, brick)
	local module = Block.loadItemData(brick.name)
	if not module then
		self:hideBricksUI()
		return
	end

	if module.parts then
		local lastenablePart = self.enablePart
		self.enablePart = false
		local bs, gs = self:loadSceneFromModule(module)
		self.enablePart = lastenablePart

		local testparts = {'l_foot', 'l_upperarm', 'l_thing', 'l_calf', 'l_forearm', 'l_hand',
							'r_foot', 'r_upperarm', 'r_thing', 'r_calf', 'r_forearm', 'r_hand',
							'head', 'waist', 'chest'}
		local existPart = function(part)
			local result = false
			for _, v in pairs(testparts) do
				if part == v then
					result = true
					break
				end
			end

			return result
		end
		local curgs = {}

		local data = Part.getPartData(self.parttype)
		for i, k in ipairs(data.orders) do
			local part = module.parts[k]
			if type(part) == 'table' and part.group and existPart(k) == true then
				gs[part.group].canswitch = true
				local bs = {}
				gs[part.group]:getBlocks(bs)
				for _, b in pairs(bs) do
					b.canswitch = true
				end

				local v1 = _Vector3.new()
				_Vector3.add(part.partpos, module.center, v1)

				table.insert(curgs, {part = k, group = gs[part.group], rootpos = v1})
			end
		end

		local lastenablegroup = self.enableGroup
		self.enableGroup = true
		for i, b in pairs(bs) do
			if b.canswitch ~= true then
				self:atom_block_del(b)
			end
		end
		self.enableGroup = lastenablegroup

		for _, v in pairs(curgs) do
			if v.part == 'waist' then
				self:switchAsset0(v.group, v.part, v.rootpos, brick.name, brick.switchName)
			else
				self:switchAsset0(v.group, v.part, v.rootpos, '', '')
			end
		end
	else
		self:switchAsset(brick)
	end
end
BuildBrick.switchAsset0 = function(self, g, part, rootpos, switchPart, switchName)
	if not g or not part then return end
	local switchName = switchName
	local switchPart = switchPart
	local attachgroups = {}
	local gpart = self.parts[part]
	local canswitch = false

	if gpart and gpart.group ~= nil then
		local lastg = gpart.group
		if gpart.attachs and #gpart.attachs > 0 then
			table.fappendArray(attachgroups, gpart.attachs)
			for i = #gpart.attachs, 1, -1 do
				self:unattachPartGroup(gpart.attachs[i])
			end
		end

		self:unbindPartGroup(gpart)
		self:atom_group_select(lastg)
		self:atom_del()
		canswitch = true
	end

	if canswitch == false then return end

	-- 当前已有绑定的骨骼时再次加载骨骼不加载绑定信息
	local enablepart = self.enablePart
	if self.enablePart and self:hasBindPart() then
		self.enablePart = false
	end

	-- 找出父节点
	local pgs = {g}
	self.enablePart = enablepart

	if #pgs > 0 then
		self:atom_group_select_batch(pgs)
		local g = self:atom_group_merge_one()
		g:setLock(true)
		g:setDeadLock(true)
		g.switchName = switchName
		g.switchPart = switchPart

		if gpart then
			self:bindPartGroup(gpart, g)

			gpart.roottransform.ignoreParent = true
			local v1 = _Vector3.new()
			gpart.roottransform:getTranslation(v1)
			_Vector3.sub(rootpos, v1, v1)
			gpart.roottransform:mulTranslationRight(v1)
			gpart.roottransform.ignoreParent = false

			gpart.jointnode.transform:mulTranslationRight(-v1.x, -v1.y, -v1.z)
			-- for i, g in ipairs(gpart.attachs) do
			-- 	local nbs = {}
			-- 	g:getBlocks(nbs)
			-- 	for _, b in ipairs(nbs) do
			-- 		print('v1', _, v1)
			-- 		b.node.transform.ignoreParent = true
			-- 		b.node.transform:mulTranslationRight(v1)
			-- 		b.node.transform.ignoreParent = false
			-- 	end
			-- end
		end

		for i, ag in ipairs(attachgroups) do
			self:attachPartGroup(gpart, ag)
		end

		self:atom_select()
	end

	-- self:refreshModuleIcon()
	self:hideBricksUI()
	self:showTopButtons()
	self:hideSwitchUI(true)
end

BuildBrick.switchAsset = function(self, brick)
	local module = Block.loadItemData(brick.name)
	if not module then
		self:hideBricksUI()
		return
	end

	local switchName = brick.switchName
	local switchPart = brick.name
	local attachpart
	local part
	local canswitch = false
	local gs = {}
	self:getGroups(gs)
	for _, g in pairs(gs) do
		if g.switchName == switchName then
			local useattachpart = false
			local usepart = false
			if g.parent then
				local parent = g.parent
				if parent.attachpart then
					attachpart = parent.attachpart
					useattachpart = true
				end

				if parent.part then
					part = parent.part
					usepart = true
				end
			else
				if g.attachpart then
					attachpart = g.attachpart
					self:unattachPartGroup(g)
					useattachpart = true
				end

				if g.part then
					part = g.part
					self:unbindPartGroup(part)
					usepart = true
				end
			end

			if useattachpart == false and usepart == false then
				canswitch = false
			else
				self:atom_group_select(g)
				self:atom_del()
				canswitch = true
			end
		end
	end

	if canswitch == false then return end

	-- 当前已有绑定的骨骼时再次加载骨骼不加载绑定信息
	local enablepart = self.enablePart
	if self.enablePart and self:hasBindPart() then
		self.enablePart = false
	end

	local bs, gs = self:loadSceneFromModule(module)

	-- 找出父节点
	local pgs = {}
	for i, g in ipairs(gs) do
		if not g.parent then
			table.insert(pgs, g)
		end
	end

	self.enablePart = enablepart
	if #pgs > 0 then
		self:atom_group_select_batch(pgs)
		local g = self:atom_group_merge_one()
		g:setLock(true)
		g:setDeadLock(true)
		g.switchName = switchName
		g.switchPart = switchPart

		-- 从别人那获取的物品，不可解锁
		if brick.creater then
			if not Global.Login:isMe(brick.creater.aid) then
				g:setDeadLock(true)
			end
		end

		if attachpart then
			self:attachPartGroup(attachpart, g)
		end

		if part then
			self:bindPartGroup(part, g)
		end

		self:atom_select()
	end

	-- self:refreshModuleIcon()
	self:hideBricksUI()
	self:showTopButtons()
	self:hideSwitchUI(true)
end

BuildBrick.addAsset = function(self, brick)
	local module = Block.loadItemData(brick.name)
	if not module then
		self:hideBricksUI()
		return
	end

	-- 当前已有绑定的骨骼时再次加载骨骼不加载绑定信息
	local enablepart = self.enablePart
	self.enablePart = false

	local enableTransition = self.enableTransition
	self.enableTransition = self:getBlockCount() == 0

	-- if self.enablePart and self:hasBindPart() then
	-- 	self.enablePart = false
	-- end

	local bs, gs = self:loadSceneFromModule(module)
	--local loadpart = self.enablePart and module.parts and next(module.parts)
	local haspart = self.enablePart and self:hasPart(module)
	local hasdf = self.enableTransition and self:hasDynamicEffect(module)

	-- 找出父节点
	local pgs = {}
	for i, g in ipairs(gs) do
		if not g.parent then
			table.insert(pgs, g)
		end
	end

	self.enablePart = enablepart
	self.enableTransition = enableTransition

	if not haspart and not hasdf then
		if #pgs > 0 then
			self:atom_group_select_batch(pgs)
			local g = self:atom_group_merge_one()
			if not g:isLeafNode() then
				g:setLock(true)
			end

			-- 从别人那获取的物品，不可解锁
			if brick.creater then
				if not Global.Login:isMe(brick.creater.aid) then
					g:setDeadLock(true)
				end
			end
		else
			self:atom_select(nil, bs)
		end

		self:findUncollidedPlace(bs)
	end

	if brick.state == 2 then
		self.state = 2
	end

	if self.enableSwitchPart then
		if self.ui and self.ui.switch then
			self.ui.switch.visible = brick.canswitch
		end

		local switchNames = {}
		for _, g in pairs(gs) do
			if g.switchName and g.switchName ~= '' then
				table.insert(switchNames, g.switchName)
			end
		end

		self.switchParts = switchNames
	end

	self:refreshSwitchUIList()
	self:refreshModuleIcon()
	self:hideBricksUI()
	self:showTopButtons()

	return bs, gs
end

-- TODO: use phyx sweep instead pick.
BuildBrick.pickScenePosition = function(self, x, y, flag, pickbox)
	local result = {}

	self.sen:pick(_rd:buildRay(x, y), flag, false, result)

	local c = self:getCameraControl()
	if not result.node or result.distance > c.maxRadius then
		local tempv3 = Container:get(_Vector3)
		updateCameraData()
		local cameraData = Global.cameraData
		if cameraData.masix.x == 0 then
			_rd:pickYZPlane(x, y, c.camera.look.x, tempv3)
		elseif cameraData.masix.y == 0 then
			_rd:pickXZPlane(x, y, c.camera.look.y, tempv3)
		elseif cameraData.masix.z == 0 then
			_rd:pickXYPlane(x, y, c.camera.look.z, tempv3)
		end

		Container:returnBack(tempv3)
		return tempv3.x, tempv3.y, tempv3.z
	end

	return result.x, result.y, result.z
end

BuildBrick.getPlacePosition = function(self, vec)
	local x, y = _rd.w / 6 * 5, _rd.h / 2
	local flag = Global.CONSTPICKFLAG.NORMALBLOCK + Global.CONSTPICKFLAG.SELECTBLOCK + Global.CONSTPICKFLAG.TERRAIN
	vec.x, vec.y, vec.z = self:pickScenePosition(x, y, flag, false)
	vec.x = normalizePos(vec.x, Global.MOVESTEP.BRICK)
	vec.y = normalizePos(vec.y, Global.MOVESTEP.BRICK)
	vec.z = normalizePos(vec.z, Global.MOVESTEP.TILE)
end

BuildBrick.getLookAtCenter = function(self, center, ab, lookz)
	local z = lookz or self.sen.planeZ or 0
	local look = _rd.camera.look

	local sx = ab.max.x - ab.min.x
	local sy = ab.max.y - ab.min.y

	local nx = math.floor(sx / 0.2 + 0.5)
	local ny = math.floor(sy / 0.2 + 0.5)
	local dx = nx % 2 == 0 and 0 or 0.1
	local dy = ny % 2 == 0 and 0 or 0.1
	-- print('getLookAtCenter', look)

	if look.z >= z then
		center:set(look.x, look.y, z)
		-- center.x = normalizePos(center.x, Global.MOVESTEP.BRICK)
		-- center.y = normalizePos(center.y, Global.MOVESTEP.BRICK)
		center.x = math.floatRound(center.x - dx, 0.2) + dx
		center.y = math.floatRound(center.y - dy, 0.2) + dy
		center.z = normalizePos(center.z, Global.MOVESTEP.TILE)
		return
	end

	if _rd:pickXYPlane(look.x, look.y, z, center) then
		-- center.x = normalizePos(center.x, Global.MOVESTEP.BRICK)
		-- center.y = normalizePos(center.y, Global.MOVESTEP.BRICK)
		center.x = math.floatRound(center.x - dx, 0.2) + dx
		center.y = math.floatRound(center.y - dy, 0.2) + dy
		center.z = normalizePos(center.z, Global.MOVESTEP.TILE)
		return
	end

	center:set(0, 0, z)
end

local pickbox = _AxisAlignedBox.new()
BuildBrick.findUncollidedPos = function(self, pos, aabb, center, NS, pickflag, checkfunc, maxcount)
	local maxcount = maxcount or 20
	pickbox:set(aabb)
	pickbox:expand(0.1, 0.1, 0)

	-- 检测包围盒的最小高度，防止放在其他物件下面
	local minh = 5
	if pickbox.max.z - pickbox.min.z < minh then
		pickbox.max.z = pickbox.min.z + minh
	end

	local checkCollision
	if checkfunc then
		checkCollision = checkfunc
	else
		checkCollision = function(checkbox, flag)
			return self.sen:boxPick(checkbox, flag)
		end
	end

	local count = 0
	local function check(p)
		pickbox:alignBottom(p)
		count = count + 1

		if checkCollision then
			local r = checkCollision(pickbox, pickflag)
			--print('check', count, r, pickflag, p, pickbox.min, pickbox.max)
			return not r
		else
			return true
		end
	end

	if check(center) then
		pos:set(center)
		return true
	end

	if not NS then
		NS = {Global.AXISTYPE.X}
	end

	local NS1 = {}
	for i, N in ipairs(NS) do
		local axis = Global.typeToAxis(N)
		table.insert(NS1, axis)
	end

	local NS2 = {}
	if #NS > 1 then
		local typehash = {}
		for i, t in ipairs(NS) do
			typehash[t] = true
		end

		if typehash[Global.AXISTYPE.X] and typehash[Global.AXISTYPE.Y] then
			table.insert(NS2, {Global.AXIS.X, Global.AXIS.Y})
		end
		if typehash[Global.AXISTYPE.X] and typehash[Global.AXISTYPE.NY] then
			table.insert(NS2, {Global.AXIS.X, Global.AXIS.NY})
		end
		if typehash[Global.AXISTYPE.NX] and typehash[Global.AXISTYPE.Y] then
			table.insert(NS2, {Global.AXIS.NX, Global.AXIS.Y})
		end
		if typehash[Global.AXISTYPE.NX] and typehash[Global.AXISTYPE.NY] then
			table.insert(NS2, {Global.AXIS.NX, Global.AXIS.NY})
		end
	end

	local basel = 0.8
	local ln = 1
	local helppos = _Vector3.new()
	while count < maxcount do
		for i, axis in ipairs(NS1) do
			_Vector3.mul(axis, basel * ln, pos)
			_Vector3.add(center, pos, pos)

			if check(pos) then return true end
		end

		for _, ns in ipairs(NS2) do
			local axis1 = ns[1]
			local axis2 = ns[2]

			_Vector3.mul(axis1, basel * ln, helppos)
			_Vector3.add(center, helppos, helppos)
			for i = 1, ln do
				_Vector3.mul(axis2, basel * i, pos)
				_Vector3.add(helppos, pos, pos)

				if check(pos) then return true end
			end

			_Vector3.mul(axis2, basel * ln, helppos)
			_Vector3.add(center, helppos, helppos)
			for i = 1, ln - 1 do
				_Vector3.mul(axis1, basel * i, pos)
				_Vector3.add(helppos, pos, pos)
				if check(pos) then return true end
			end
		end

		ln = ln + 1
	end

	pos:set(center)
	return false
end

local pickpos = _Vector3.new()
local pickpos2 = _Vector3.new()
local pickdis, pickdis2 = 0, 0
BuildBrick.scenepick = function(self, x, y, flag, pickbox)
	local result = {}
	self.sen:pick(_rd:buildRay(x, y), flag, pickbox, result)

	if result.node then
		pickpos:set(result.x, result.y, result.z)
		pickdis = result.distance
	end
	--print('BuildBrick.scenepick', x, y, flag, pickbox, result.node and result.node.pickFlag, pickpos)

	return result.node, pickpos, pickdis
end

BuildBrick.phyxpick = function(self, x, y, flag)
	local result = {}
	if self.sen:physicsPick(_rd:buildRay(x, y), 300, flag, result) then
		pickpos2:set(result.pos.x, result.pos.y, result.pos.z)
		pickdis2 = result.distance
		return result.actor, pickpos2, pickdis2
	end
end

local pickblockpos = _Vector3.new()
BuildBrick.pickBlock = function(self, x, y)
	--local flag = Global.CONSTPICKFLAG.NORMALBLOCK + Global.CONSTPICKFLAG.SELECTBLOCK
	local flag = Global.CONSTPICKFLAG.NORMALBLOCK + Global.CONSTPICKFLAG.SELECTBLOCK + Global.CONSTPICKFLAG.SELECTWALL
	if self.enablePart then
		flag = flag + Global.CONSTPICKFLAG.BONE
	end

	local node, pos, d1 = self:scenepick(x, y, flag)

	-- pick模型失败用包围盒再pick一次，用于增加手机上pick的容错
	-- if not node then
	-- 	node, pos, d1 = self:scenepick(x, y, flag, true)
	-- end

	if not node then return end

	pickblockpos:set(pos)

	-- 检测墙和地面是否阻挡
	-- local actor, pos2, d2 = self:phyxpick(x, y, Global.CONSTPICKFLAG.WALL + Global.CONSTPICKFLAG.TERRAIN)
	-- if actor and d2 < d1 then
	-- 	return
	-- end

	return node.block, pickblockpos
end
--------------------------------------------

BuildBrick.setPhysTest = function(self, b, f)
	local cnt = 0
	local shapes = b:getPhysicShapes()
	for _, v in ipairs(shapes) do
		local enablequery = not f or f(b, v)
		v.oldquery = v.query
		v.query = enablequery
		if enablequery then
			cnt = cnt + 1
		end
	end

	return cnt
end

BuildBrick.resetPhysTest = function(self, b, f)
	local shapes = b:getPhysicShapes()
	for _, v in ipairs(shapes) do
		v.query = v.oldquery
		v.oldquery = nil
	end
end

-- nbs：需要检测的block数组
-- excludes：nbs中需要排除block的hash，默认为空
-- mode: onlyconnect(只检测连接点), skipconnect(不检测连接点), 其他全检测
BuildBrick.beginPhysTest = function(self, nbs, f)
	local cnt = 0
	for b in pairs(nbs) do
		local shapes = b:getPhysicShapes()
		for _, v in ipairs(shapes) do if not f or f(b, v) then
			v.oldQueryFlag = v.queryFlag
			v.queryFlag = Global.CONSTPICKFLAG.SWEEPTEST
			cnt = cnt + 1
		end end
	end

	return cnt
end

BuildBrick.endPhysTest = function(self, nbs, f)
	for b in pairs(nbs) do
		local shapes = b:getPhysicShapes()
		for _, v in ipairs(shapes) do if not f or f(b, v) then
			v.queryFlag = v.oldQueryFlag
			v.oldQueryFlag = nil
		end end
	end
end

-- 临时扩展shape以检查场景中的碰撞
local expandv3 = _Vector3.new(0.015, 0.015, 0.015)
local expandsize = 0.015
BuildBrick.expandBlockShape = function(self, block, f, axis)
	--if f and not f(block) then return end
	if block.expandshape then return end
	block.expandshape = true
	if axis == Global.AXISTYPE.X then
		expandv3.x, expandv3.y, expandv3.z = expandsize, 0, 0
	elseif axis == Global.AXISTYPE.Y then
		expandv3.x, expandv3.y, expandv3.z = 0, expandsize, 0
	elseif axis == Global.AXISTYPE.Z then
		expandv3.x, expandv3.y, expandv3.z = 0, 0, expandsize
	else
		expandv3.x, expandv3.y, expandv3.z = expandsize, expandsize, expandsize
	end

	local shapes = block:getPhysicShapes()
	for i, s in ipairs(shapes) do
		if not f or f(block, s) then
			if s.query then
				s.oldsize = s.size
				local newsize = _Vector3.new()
				_Vector3.add(s.size, expandv3, newsize)
				s.size = newsize
			end
		else
			if s.query then s.query = false end
		end
	end

	return true
end

BuildBrick.unexpandBlockShape = function(self, block, f, axis)
	--if f and not f(block) then return end
	if not block.expandshape then return end
	block.expandshape = false
	if axis == Global.AXISTYPE.X then
		expandv3.x, expandv3.y, expandv3.z = expandsize, 0, 0
	elseif axis == Global.AXISTYPE.Y then
		expandv3.x, expandv3.y, expandv3.z = 0, expandsize, 0
	elseif axis == Global.AXISTYPE.Z then
		expandv3.x, expandv3.y, expandv3.z = 0, 0, expandsize
	else
		expandv3.x, expandv3.y, expandv3.z = expandsize, expandsize, expandsize
	end
	local shapes = block:getPhysicShapes()
	for i, s in ipairs(shapes) do
		if not f or f(block, s) then
			if s.query then
				s.size = s.oldsize
				s.oldsize = nil
			end
		else
			s.query = true
		end
	end
end

BuildBrick.overlap = function(self, actor, flag, ret)
	if self.sen:physicsOverlap(actor, flag, ret) then
		--print('@@@@BuildBrick.overlap', ret.actor.node.block, ret.shape, ret.shapeindex)
		return ret.actor.node.block, ret.shape, ret.shapeindex
	end

	return nil
end

-- bs1 and bs2 is hash table
BuildBrick.checkConnectBlocks = function(self, bs1, bs2, out)
	local ret = {}
	local f = function(b, s) return s.jointdata end
	if self:beginPhysTest(bs2, f) > 0 then
		for b in pairs(bs1) do
			local cn = self:setPhysTest(b, f)
			if cn > 0 then
				if self.sen:physicsOverlapMulti(b.actor, Global.CONSTPICKFLAG.SWEEPTEST, ret) then
					for _, r in ipairs(ret) do
						local ob = r.actor and r.actor.node and r.actor.node.block
						if ob then
							local b1, b2, s1, s2 = b, ob, b:getShapeByShapeIndex(r.shapeindex), r.shape
							local connectdata = self:checkShapeConnectType(b1, b2, s1, s2)
							if connectdata then
								if not out[b] then out[b] = {} end
								table.insert(out[b], {b1 = b1, b2 = b2, s1 = s1, s2 = s2})
							end
						end
					end
				end
			end
			self:resetPhysTest(b, f)
		end

		self:endPhysTest(bs2, f)
	end
end

-- bs1 and bs2 is hash table
BuildBrick.checkOverlapBlocks = function(self, bs1, bs2, out)
	local ret = {}
	if self:beginPhysTest(bs2) > 0 then
		for b in pairs(bs1) do
			if self.sen:physicsOverlapMulti(b.actor, Global.CONSTPICKFLAG.SWEEPTEST, ret) then
				for _, r in ipairs(ret) do
					local b2 = r.actor and r.actor.node and r.actor.node.block
					if b2 then
						if not out[b] then out[b] = {} end
						table.insert(out[b], b2)
					end
				end
			end
		end

		self:endPhysTest(bs2)
	end
end

-- bs1 and bs2 is hash table
BuildBrick.expandAndCheckOverlapBlocks = function(self, bs1, bs2, out)
	local ret = {}
	if self:beginPhysTest(bs2) > 0 then
		for b in pairs(bs1) do
			if self:expandBlockShape(b, nil, Global.AXISTYPE.X) then
				if self.sen:physicsOverlapMulti(b.actor, Global.CONSTPICKFLAG.SWEEPTEST, ret) then
					for _, r in ipairs(ret) do
						local b2 = r.actor and r.actor.node and r.actor.node.block
						if b2 then
							if not out[b] then out[b] = {} end
							table.insert(out[b], b2)
						end
					end
				end
				self:unexpandBlockShape(b, nil, Global.AXISTYPE.X)
			end
			if self:expandBlockShape(b, nil, Global.AXISTYPE.Y) then
				if self.sen:physicsOverlapMulti(b.actor, Global.CONSTPICKFLAG.SWEEPTEST, ret) then
					for _, r in ipairs(ret) do
						local b2 = r.actor and r.actor.node and r.actor.node.block
						if b2 then
							if not out[b] then out[b] = {} end
							table.finsertWithoutRepeat(out[b], b2)
						end
					end
				end
				self:unexpandBlockShape(b, nil, Global.AXISTYPE.Y)
			end
			if self:expandBlockShape(b, nil, Global.AXISTYPE.Z) then
				if self.sen:physicsOverlapMulti(b.actor, Global.CONSTPICKFLAG.SWEEPTEST, ret) then
					for _, r in ipairs(ret) do
						local b2 = r.actor and r.actor.node and r.actor.node.block
						if b2 then
							if not out[b] then out[b] = {} end
							table.finsertWithoutRepeat(out[b], b2)
						end
					end
				end
				self:unexpandBlockShape(b, nil, Global.AXISTYPE.Z)
			end
		end

		self:endPhysTest(bs2)
	end
end

-- 检测组的碰撞，group：待检测的组，nbs：检测范围
BuildBrick.overlapBlocks = function(self, group, nbs)
	local bs1, bs2 = {}, {}
	for i, b in ipairs(group) do
		bs1[b] = true
	end
	for i, b in ipairs(nbs) do
		bs2[b] = true
	end

	--print('overlapBlocks:', table.fcount(bs1), table.fcount(bs2))
	-- 判断connect{}
	local connects = {}
	-- self:checkConnectBlocks(bs1, bs2, connects)
	-- for b in pairs(connects) do
	-- 	bs1[b] = nil
	-- end

	--print('connects:', table.fcount(bs1), table.fcount(connects))

	local overlaps = {}
	self:checkOverlapBlocks(bs1, bs2, overlaps)
	for b in pairs(overlaps) do
		bs1[b] = nil
	end

	--print('overlap:', table.fcount(bs1), table.fcount(overlaps))

	local neighbors = {}
	self:expandAndCheckOverlapBlocks(bs1, bs2, neighbors)

	--print('neighbor:', table.fcount(bs1), table.fcount(neighbors))

	return connects, overlaps, neighbors
end

BuildBrick.overlapBlocks2 = function(self, bs, nbs)
	local excludes = {}
	for i, b in ipairs(bs) do
		excludes[b] = true
	end

	if not nbs then
		nbs = {}
		self:getBlocks(nbs)
	end

	local bs2 = {}
	for i, b in ipairs(nbs) do if not excludes[b] then
		bs2[b] = true
	end end

	local overlaps = {}
	self:checkOverlapBlocks(excludes, bs2, overlaps)
	return overlaps

	-- local f2_3 = function(b, s) return not excludes[b] end

	-- -- 检测关节与关节连接
	-- local overlayblock, block, overlayshape, shape = self:checkoverlapBlocks2(excludes, nbs, f2_3)
	-- if overlayblock then return overlayblock, block, overlayshape, shape end

end