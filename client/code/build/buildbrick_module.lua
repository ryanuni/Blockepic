local Container = _require('Container')
local command = _require('Pattern.Command')

_dofile('scenemodule.lua')
local SceneModule = Global.SceneModule

----------------------------
local BuildBrick = _G.BuildBrick
BuildBrick.postProcess = _PostProcess.new()
BuildBrick.postProcess.toneMapKeepAlpha = true

BuildBrick.getModule = function(self, subid)
	if not subid or subid == 0 then
		return self.modules
	else
		return self.modules.subs[subid]
	end
end

BuildBrick.newModule = function(self)
	-- 分配标志符
	return SceneModule.new()
end

-- BuildBrick.createModule = function(self)
-- 	-- 分配标志符
-- 	local module = self:newModule()
-- 	self.sindex = self.sindex + 1
-- 	module.sindex = self.sindex
-- 	self.modules.subs[module.sindex] = module

-- 	-- self:refreshModuleList()
-- 	return module
-- end

BuildBrick.addOverlapData = function(self, b, hbs, connects, overlaps, neighbors, cacheindexs, maxn)
	-- 去除重复的积木对
	local testNoRepeat = function(b1, b2)
		-- 跳过dummy的文件
		if b1:isDummy() or b2:isDummy() then return false end
		if not hbs[b1] or not hbs[b2] then return false end

		local i1, i2 = b1.index, b2.index
		local index = math.max(i1, i2) * maxn + math.min(i1, i2)
		-- print('testNoRepeat:', i1, i2, index, cacheindexs[index])
		if cacheindexs[index] then return false end
		cacheindexs[index] = true
		return true
	end

	for b1, conn in pairs(b.connects) do
		if testNoRepeat(conn.b1, conn.b2) then
			local si1, si2 = conn.b1:getPhysicShapeIndex(conn.s1), conn.b2:getPhysicShapeIndex(conn.s2)
			table.insert(connects, {b1 = conn.b1.index, b2 = conn.b2.index, s1 = si1, s2 = si2})
		end
	end

	for b1 in pairs(b.overlaps) do
		if testNoRepeat(b, b1) then
			table.insert(overlaps, {b1 = b.index, b2 = b1.index})
		end
	end

	for b1 in pairs(b.neighbors) do
		if testNoRepeat(b, b1) then
			table.insert(neighbors, {b1 = b.index, b2 = b1.index})
		end
	end
end

BuildBrick.saveOverlapInfo = function(self, bs, connects, overlaps, neighbors)
	local maxn = #bs
	local cacheindexs = {}
	local hbs = {}
	for i, b in ipairs(bs) do if not b:isDummy() then
		hbs[b] = true
	end end

	for i, b in ipairs(bs) do if not b:isDummy() then
		self:addOverlapData(b, hbs, connects, overlaps, neighbors, cacheindexs, maxn)
	end end
end

BuildBrick.loadOverlapInfo = function(self, bs, connects, overlaps, neighbors)
	if connects then
		for i, conn in ipairs(connects) do
			local b1, b2 = bs[conn.b1], bs[conn.b2]
			if b1 and b2 then
				local s1, s2 = b1:getPhysicShape(conn.s1), b2:getPhysicShape(conn.s2)
				if s1 and s2 then
					b1:addConnects(b2, s2, s1)
				end
			end
		end
	end

	if overlaps then
		for i, data in ipairs(overlaps) do
			local b1, b2 = bs[data.b1], bs[data.b2]
			if b1 and b2 then
				b1:addOverlap(b2)
			end
			-- if not b1 or not b2 then
			-- 	print('b1, b2:', i, #bs, data.b1, data.b2)
			-- end
		end
	end

	if neighbors then
		for i, data in ipairs(neighbors) do
			local b1, b2 = bs[data.b1], bs[data.b2]
			if b1 and b2 then
				b1:addNeighbor(b2)
			end
		end
	end
end

Global.saveBlockData = function(b, center, keepshape)
	b:updateSpace()
	local data = {}

	data.shape = b.markerdata and not keepshape and '' or b:getShape()
	data.subshape = b:getSubShape()
	data.color = b:getColor()
	data.roughness = b:getRoughness()
	data.material = b:getMaterial()
	data.mtlmode = b:getMtlMode()
	data.need = nil
	if b.node.need == false then
		data.need = false
	end

	data.isDungeonBg = b.isDungeonBg

	-- 保存不可选中物件的flag
	local flag = b:getPickFlag()
	if flag == Global.CONSTPICKFLAG.NONE or flag == Global.CONSTPICKFLAG.WALL
		or flag == Global.CONSTPICKFLAG.TERRAIN or flag == Global.CONSTPICKFLAG.SELECTWALL then
		data.pickFlag = flag
	end

	-- markerdata
	if b.markerdata then
		data.markerdata = {}
		b.markerdata:saveToData(data.markerdata)
	end

	data.disablephyx = b:isPhyxCulliing()
	-- data.forceMtlInvisible = b.data.forceMtlInvisible

	data.space = {}
	data.space.translation = _Vector3.new()
	data.space.scale = _Vector3.new()
	data.space.rotation = _Vector4.new()

	local bspace = b.data.space
	data.space.translation.x = bspace.translation.x - center.x
	data.space.translation.y = bspace.translation.y - center.y
	data.space.translation.z = bspace.translation.z - center.z

	data.space.scale.x = bspace.scale.x
	data.space.scale.y = bspace.scale.y
	data.space.scale.z = bspace.scale.z

	data.space.rotation.x = bspace.rotation.x
	data.space.rotation.y = bspace.rotation.y
	data.space.rotation.z = bspace.rotation.z
	data.space.rotation.w = bspace.rotation.w

	local pinfo = b:getPaintInfo()
	if pinfo.resname and pinfo.resname ~= '' then
		data.paintInfo = {}
		pinfo:saveToData(data.paintInfo)
	else
		data.paintInfo = nil
	end

	data.aabb = _AxisAlignedBox.new()
	b:getAABB(data.aabb) -- 带背景
	_Vector3.sub(data.aabb.min, data.space.translation, data.aabb.min)
	_Vector3.sub(data.aabb.max, data.space.translation, data.aabb.max)

	-- if b.bindpfxs and b.bindpfxs[1] then
	-- 	data.pfxs = {}
	-- 	for i, v in ipairs(b.bindpfxs) do
	-- 		local pfxdata = {}
	-- 		pfxdata.pfxname = v.pfxname
	-- 		pfxdata.translation = _Vector3.new()
	-- 		pfxdata.rotation = _Vector4.new()
	-- 		pfxdata.scale = _Vector3.new()
	-- 		local mat = v.pfx.transform
	-- 		local pmat = mat.parent
	-- 		mat.parent = nil
	-- 		mat:getRotation(pfxdata.rotation)
	-- 		mat:getScaling(pfxdata.scale)
	-- 		mat:getTranslation(pfxdata.translation)
	-- 		mat.parent = pmat
	-- 		table.insert(data.pfxs, pfxdata)
	-- 	end
	-- end

	return data
end

BuildBrick.getNeededLogicGroups = function(self, nbs)
	local logicgroups = {}
	-- 动画转换成逻辑组
	if self.enableTransition and Global.hasDynamicEffect(self.DFPlayer) then
		local dfplayer = self.DFPlayer
		local ts = dfplayer:getTransitions()
		for i, t in ipairs(ts) do
			if t.group then
				table.insert(logicgroups, t.group)
			end
		end
	end

	-- part转换为逻辑组
	if self.enablePart then
		for name, part in pairs(self.parts) do if part.group then
			local bs = {}
			part.group:getBlocks(bs)

			for i, g in ipairs(part.attachs) do
				if g.index then
					g:getBlocks(bs)
				end
			end

			local g = LogicBlockGroup.new()
			g:addChildren(bs)
			table.insert(logicgroups, g)
			part.logicGroup = g
		end end
	end

	-- 带有名字的逻辑组
	local gsname = {}
	for i, b in ipairs(nbs) do
		if b.logic_names then
			for name, s in pairs(b.logic_names) do if s then
				if not gsname[name] then
					local g = LogicBlockGroup.new()
					g.name = name
					gsname[name] = g
					table.insert(logicgroups, g)
				end

				local g = gsname[name]
				g:addChild(b)
			end end
		end
	end

	-- pair的
	gsname = {}
	for p1, p2 in next, self.pairBlocks do
		if not gsname[p1] then
			local g = LogicBlockGroup.new()
			g.tag = 'pair'
			g:addChild(p1)
			g:addChild(p2)
			
			table.insert(logicgroups, g)
			gsname[p2] = true
		end
	end

	-- 带芯片的逻辑组
	gsname = {}
	for i, b in ipairs(nbs) do
		if b.chips_s and next(b.chips_s) then
			local str = value2string(b.chips_s)
			local md5 = _sys:md5(str)
			-- print('i,b', i, md5, str)
			if not gsname[md5] then
				local g = LogicBlockGroup.new()
				g.chips_s = b.chips_s
				gsname[md5] = g
				table.insert(logicgroups, g)
			end

			local g = gsname[md5]
			g:addChild(b)
		end
	end

	return logicgroups
end

BuildBrick.getModuleObjects = function(self, module, objects)
	for i, b in ipairs(module.blocks) do
		if Global.isNetObject(b.shape) then
			objects[b.shape] = true
		end

		-- local marker = b.markerdata
		-- if marker then
		-- 	if marker.trains then
		-- 		for _, v in ipairs(marker.trains) do
		-- 			if v.shape and Global.isNetObject(v.shape) then
		-- 				objects[v.shape] = true
		-- 			end
		-- 		end
		-- 	end
		-- end
	end

	if module.submodules then
		for i, subm in ipairs(module.submodules) do
			self:getModuleObjects(subm.module, objects)
		end
	end
end

BuildBrick.saveSceneToModule = function(self, module, nbs)
	if self.enablePart then
		-- 保存时退出动画编辑界面
		if self.showSkl then
			self:showPart(self.parttype, false)
		end

		self:playAnimIndex(nil, false)
		self:editPart('exit')
	end

	if self.dfEditing then
		self:stopDFrame()
		self:onSelectDFrame()
		self:showDfs(false)
	else
		-- 更新全局修改到动画
		self:stopDFrame()
		if self:hasDynamicEffect() then
			self:updateSceneToFirstFrame()
		end
		self:showDfs(false)
	end

	if self:getParam('scenemode') == 'scene_music' then
		self:saveMusicData()
	end

	if not nbs then
		nbs = {}
		if not self.enableRepair then
			self:getBlocks(nbs)
		else
			self:getBlocks(nbs, function(b)
				return not self:isAddRepairBlock(b)
			end)
		end
	end

	--local sindex = module.sindex
	table.clear(module.blocks)
	table.clear(module.groups)
	table.clear(module.parts)

	--module.sindex = sindex

	local aabb = Container:get(_AxisAlignedBox)
	Block.getAABBs(nbs, aabb)

	if not module.center then
		module.center = _Vector3.new()
	end

	local bindpart = false
	if self.enablePart then
		for name, part in pairs(self.parts) do
			if part.group then
				bindpart = true
				break
			end
		end
	end

	if not self.noCenter then
		if bindpart then
			local vnbs = {}
			for i, b in ipairs(nbs) do
				if b.part or b.part2 then
					table.insert(vnbs, b)
				end
			end
			Block.getAABBs(vnbs, aabb)
		end

		aabb:getCenter(module.center)
		Global.normalizePos(module.center, Global.MOVESTEP.TILE)
		--保存物件贴地表
		--module.center.z = module.center.z + 0.2
	else
		module.center:set(0, 0, 0)
	end

	if not module.size then
		module.size = _Vector3.new()
	end
	aabb:getSize(module.size)

	-- 处理特效
	-- local pfxnbs = {}
	-- self:getBlocks(pfxnbs, function(b)
	-- 	return b.isdummyblock
	-- end)

	-- 添加block信息
	for i, b in ipairs(nbs) do if not b:isDummy() then
		b.index = i
	end end

	module.submodules = {}
	for i, b in ipairs(nbs) do if not b:isDummy() then
		-- 保存block的原始颜色信息
		local needrepair = b.needrepair
		if self.enableRepair and needrepair then
			b:setNeedRepair(false)
		end

		--未绑定的积木加了need=false标记
		if bindpart then
			if not b.part and not b.part2 then
				b.node.need = false
			end
		end

		if b.markerdata and b.markerdata.type == 'marker_train' then
			local mdata = b.markerdata
			for _, d in ipairs(mdata.trains or {}) do
				if d.module then
					table.insert(module.submodules, {type = 'trains', index = b.index, module = d.module})
					d.moduleid = #module.submodules
				end
			end
		end

		local data = Global.saveBlockData(b, module.center)
		table.insert(module.blocks, data)

		-- 保存挂点
		if b.bindmodule then
			table.insert(module.submodules, {type = 'bind', bindex = b.index, module = b.bindmodule})
		end

		if bindpart then
			if not b.part and not b.part2 then
				b.node.need = nil
			end
		end

		if self.enableRepair and needrepair then
			b:setNeedRepair(true)
		end
	end end

	if self.enableGroup then
		local gs = {}
		self:getGroups(gs, nbs)
		table.sort(gs, function(a, b)
			return a:getSerialNum() < b:getSerialNum()
		end)
		self:saveGroupInfos(gs, module.groups)

		-- 保存overlaps信息
		module.connects = {}
		module.overlaps = {}
		module.neighbors = {}
		self:saveOverlapInfo(nbs, module.connects, module.overlaps, module.neighbors)
	end

	-- 保存逻辑组
	module.logicgroups = {}
	local logicgroups = self:getNeededLogicGroups(nbs)
	for i, g in ipairs(logicgroups) do
		g:setIndex(i)

		local gd = {}
		g:saveBlocksToData(gd)
		table.insert(module.logicgroups, gd)
	end

	-- 保存flag信息
	module.funcflags = {}

	module.parts = {}
	if self.enablePart then
		-- Write parts
		local bindbone = false
		local rootz = 0

		for name, part in pairs(self.parts) do if part.group then
			if part.group.index then
				local ppart = part.ppart
				local pgroup = ppart and ppart.group

				local data = Part.getPartData(self.parttype)
				local cpart = data.parts[name]
				local isroot = cpart.parent == nil

				-- partpos记录part移动的差值, 
				local partpos = _Vector3.new()
				part.roottransform.ignoreParent = true
				part.roottransform:getTranslation(partpos)
				part.roottransform.ignoreParent = false
				_Vector3.sub(partpos, module.center, partpos)

				-- jointpos记录joint的最终值
				local jointpos = _Vector3.new()
				part.jointnode.transform:getTranslation(jointpos)
				-- 记录root点离地面的高度，用于处理跳跃等动画时的高度
				if isroot then rootz = math.max(jointpos.z - self:getRootZ_MinZ(), 0) end
				_Vector3.sub(jointpos, module.center, jointpos)

				local pdata = {group = part.group.index, logicGroup = part.logicGroup.index, pgroup = pgroup and pgroup.index, jointpos = jointpos, partpos = partpos, attachs = {}}
				for i, g in ipairs(part.attachs) do
					if g.index then
						table.insert(pdata.attachs, g.index)
					end
				end

				module.parts[name] = pdata

				bindbone = true
			else
				print('ERROR part has invalid group', name, part.group)
				assert(false)
			end
		end end
		if bindbone then
			module.parts.bindbone = self.parttype
			module.parts.rootz = rootz
			module.parts.disableBind = self.disableBindPart
		end
	end

	-- 保存修复信息
	module.repair_dels = {}
	module.repair_adds = {}
	if self.enableRepair then
		for g in pairs(self.repair_dels) do
			if self:getParam('blueprint') or not g.repairGroup then
				local data = {}
				data.index = g.index
				table.insert(module.repair_dels, data)
			end
		end

		for g in pairs(self.repair_adds) do
			if self:getParam('blueprint') or not g.repairGroup then
				local data = {}

				-- assert(g.bindGroup)
				if g.bindGroup then
					data.bindGroup = g.bindGroup.index
					local ab = g:getAABB()
					data.trans = _Vector3.new()
					ab:getCenter(data.trans)
				end
				table.insert(module.repair_adds, data)
			end
		end

		module.repair_version = 0x01
	end

	module.dynamicEffects = {}
	if self.enableTransition and Global.hasDynamicEffect(self.DFPlayer) then
		local df = {}
		self.DFPlayer:saveToData(df, module.center)
		table.insert(module.dynamicEffects, df)
	end

	module.bfuncs = {}
	if self.enableTransition and self.bfuncs and #self.bfuncs > 0 then
		for i, func in ipairs(self.bfuncs) do
			local f = {}
			--f.group = nil
			f.events = {}
			for _, e in ipairs(func.events) do
				table.insert(f.events, {name = e.name, type = e.type})
			end

			table.insert(module.bfuncs, f)
		end
	end

	module.chips_s = {}
	if self.chips_s and (self.chips_s.player and #self.chips_s.player > 0
			or self.chips_s.dungeon and #self.chips_s.dungeon > 0 or self.chips_s.main and #self.chips_s.main > 0) then
		table.deep_clone(module.chips_s, self.chips_s)
		module.chips_s.groups = nil
		--print('!!!!!!!!save', table.ftoString(self.chips_s), debug.traceback())
	end

	for i, g in ipairs(logicgroups) do if g.chips_s then
		if not module.chips_s.groups then
			module.chips_s.groups = {}
		end

		local chips_s = {}
		table.deep_clone(chips_s, g.chips_s)
		chips_s.group = g.index
		table.insert(module.chips_s.groups, chips_s)
	end end

	module.block_chipss = nil
	-- for i, b in ipairs(nbs) do
	-- 	if b.chips_s then
	-- 		module.block_chipss[i] = {}
	-- 		table.deep_clone(module.block_chipss[i], b.chips_s)
	-- 	end
	-- end

	-- TODO:
	-- module.logic_names = {}
	-- for i, b in ipairs(nbs) do
	-- 	if b.logic_names then
	-- 		module.logic_names[i] = {}
	-- 		table.deep_clone(module.logic_names[i], b.logic_names)
	-- 	end
	-- end

	local ff = module.funcflags
	if self.mode == 'buildscene' then
		ff.blocktype = self:getParam('scenemode') or 'scene'
	end

	if self.bgmusic and self.bgmusic.name ~= '' then
		ff.bgmusic = self.bgmusic.name
	end

	if self.userAABB then
		ff.userAABBLocked = self.userAABBLocked
		ff.userAABB = _AxisAlignedBox.new(self.userAABB)

		ff.bgAABBLocked = self.bgAABBLocked
		ff.bgAABB = _AxisAlignedBox.new(self.bgAABB)

		if module.center then
			_Vector3.sub(ff.userAABB.max, module.center, ff.userAABB.max)
			_Vector3.sub(ff.userAABB.min, module.center, ff.userAABB.min)
			_Vector3.sub(ff.bgAABB.max, module.center, ff.bgAABB.max)
			_Vector3.sub(ff.bgAABB.min, module.center, ff.bgAABB.min)
		end
	end

	if Global.CombineItemToMesh then
		ff.useCombinedMesh = true
	end

	-- 写入场景引用的物件
	local objects = {}
	self:getModuleObjects(module, objects)
	local objectsarray = {}
	table.fhash2Array(objects, objectsarray)
	module.netobjects = objectsarray

	Container:returnBack(aabb)

	-- 清除模型缓存
	Block.clearCaches(self.shapeid)
	print('Block.clearCaches: ', self.shapeid)
end

-- 把模块的每一个单元加入场景
BuildBrick.loadSceneFromModule = function(self, module)
	--加载block信息
	local bs = {}
	for i, v in ipairs(module.blocks) do
		-- markerdata 特殊加载
		local markerdata = v.markerdata
		if markerdata then
			v.shape = BMarker.type2shape(v.markerdata.type)
			v.markerdata = nil
		end
		local b = self.sen:createBlock(v)
		if markerdata then
			v.shape = ''
			v.markerdata = markerdata
		end

		b.index = i
		if module.center then
			b.node.transform:mulTranslationRight(module.center.x, module.center.y, module.center.z)
			b:formatMatrix()
		end

		if v.disablephyx then
			b:setPhyxCulliing(true)
		end

		b.isDungeonBg = v.isDungeonBg
		if v.pickFlag then
			b:setPickFlag(v.pickFlag)
		end

		-- 加载特效
		if v.pfxs then
			for _, vv in ipairs(v.pfxs) do
				local mat = _Matrix3D.new()
				mat:setScaling(vv.scale)
				mat:mulRotationRight(vv.rotation.x, vv.rotation.y, vv.rotation.z, vv.rotation.w)
				mat:mulTranslationRight(vv.translation)
				self:createPfxDummy(vv.pfxname, b, mat)
			end
		end

		table.insert(bs, b)
	end

	-- 加载绑定
	for i, v in ipairs(module.blocks) do
		if v.markerdata then
			local b = bs[i]
			local marker = BMarker.new(v.markerdata, bs)
			marker:setBlock(b)
			b.markerdata = marker
			b:setAABBSkipped(true)

			-- 创建火车
			if marker.type == 'marker_train' then
				local mdata = b.markerdata
				for _, d in ipairs(mdata.trains or {}) do
					if d.moduleid and module.submodules[d.moduleid] then
						d.module = module.submodules[d.moduleid].module
					end
				end

				self:updateMarkerTrain(b)
			end
		end
	end

	-- 第一次加载场景时模型放置在地面上
	if not module.center then
		local aabb = Container:get(_AxisAlignedBox)
		Block.getAABBs(bs, aabb)
		for i, b in ipairs(bs) do
			b.node.transform:mulTranslationRight(0, 0, -aabb.min.z)
			b:formatMatrix()
		end
		Container:returnBack(aabb)
	end

	local gs = {}
	if self.enableGroup then
		gs = self:loadGroupInfos(module.groups, bs)
		if not self.enablePart then
			for i, g in ipairs(gs) do
				g.switchPart = nil
				g.switchName = nil
			end
		end
		self:loadOverlapInfo(bs, module.connects, module.overlaps, module.neighbors)
	end

	local logicgroups
	if module.logicgroups then
		logicgroups = {}
		for i, v in ipairs(module.logicgroups) do
			local group = LogicBlockGroup.new()
			if v.name then group:setName(v.name) end
			if v.tag then group:setTag(v.tag) end
			for _, bindex in ipairs(v.blocks) do
				group:addChild(bs[bindex])
			end

			table.insert(logicgroups, group)
		end
	end

	-- 初始化knotgroup
	if self.mode == 'buildbrick' or self.mode == 'buildanima' then
		for i, g in ipairs(gs) do
			g:getKnotGroup()
		end
	end

	-- load part
	self.disableBindPart = false
	if self.enablePart and module.parts and next(module.parts) then
		self.parttype = module.parts.bindbone or 'human'
		self.disableBindPart = module.parts.disableBind

		if not next(self.parts) then self:initParts() end

		local data = Part.getPartData(self.parttype)

		local type1 = Global.dir2AxisType(Global.DIRECTION.LEFT, Global.AXISTYPE.Z)
		local type2 = Global.dir2AxisType(Global.DIRECTION.DOWN, Global.AXISTYPE.Z)
		local type3 = Global.dir2AxisType(Global.DIRECTION.RIGHT, Global.AXISTYPE.Z)
		local ns = {type1, type2, type3}

		local lookcenter = _Vector3.new(0, -3, 0)
		for i, pname in ipairs(data.orders) do
			local part = self.parts[pname]
			local p = module.parts[pname]
			if p then
				local group = gs[p.group]
				-- 增加绑定积木的初始位置，用于解绑时放置
				local nbs = {}
				group:getBlocks(nbs)
				self:findUncollidedPlace(nbs, ns, lookcenter)
			end
		end

		local v1 = Container:get(_Vector3)
		local v2 = Container:get(_Vector3)
		for i, pname in ipairs(data.orders) do
			local part = self.parts[pname]
			local p = module.parts[pname]
			if p then
				local group = gs[p.group]

				self:atom_part_bind(group, part)

				--移动transform
				v1:set(p.partpos)
				if module.center then _Vector3.add(v1, module.center, v1) end

				part.roottransform.ignoreParent = true
				part.roottransform:setTranslation(v1)
				part.roottransform.ignoreParent = false

				-- 移动jointnode.transform
				local gmat = part.jointnode.transform

				v1:set(p.jointpos)
				if module.center then _Vector3.add(v1, module.center, v1) end
				part.roottransform:getTranslation(v2)
				_Vector3.sub(v1, v2, v1)
				gmat.ignoreParent = true
				gmat:setTranslation(v1)
				gmat.ignoreParent = false

				if p.attachs then
					for i, gi in ipairs(p.attachs) do
						local g = gs[gi]
						self:attachPartGroup(part, g)
					end
				end
			end
		end

		Container:returnBack(v1, v2)

		--父矩阵更新时物理没有及时更新，这里重新更新一次
		for name, part in pairs(self.parts) do if part.group then
			local bs = {}
			part.group:getBlocks(bs, 'connect')
			for i, g in ipairs(part.attachs) do
				g:getBlocks(bs)
			end

			for i, b in ipairs(bs) do
				b.node.transform:mulTranslationRight(0, 0, 0)
			end
			part.jointnode.transform:mulTranslationRight(0, 0, 0)
			part.bonenode.transform:mulTranslationRight(0, 0, 0)
		end end

		self:editPart('exit')
	end

	-- 加载修复信息
	if self.enableRepair then
		self:initRepairData()

		if module.repair_version and module.repair_version > 0 then
			for i, v in ipairs(module.repair_adds or {}) do
				local g = gs[v.bindGroup]

				local addg = self:createAddRepair(g, v.trans)
				addg:setDirty()

				self:checkRepaired(addg, true)
			end

			if #bs < 1000 then
				self:markSameDelRepair(gs)
			end

			for i, v in ipairs(module.repair_dels or {}) do
				local g = gs[v.index]
				self:setDelRepair(g, i)
			end
		else
			for i, v in ipairs(module.repair_adds or {}) do
				local b = self.sen:createBlock({shape = v.shape})
				b.node.transform:setRotation(v.rot)
				b.node.transform:mulTranslationRight(v.trans)
				b:formatMatrix()
				local g = b:getBlockGroup()
				g:setDirty()
				self:setAddRepair(g)

				self:checkRepaired(g, true)
			end

			for i, v in ipairs(module.repair_dels or {}) do
				local b = bs[v.index]
				local g = b:getBlockGroup()
				self:setDelRepair(g, i)
			end
		end

		if self.mode == 'repair' and not next(self:getRepairShapeFilter()) then
			self.enableOpenLib = false
			--Tip(Global.TEXT.TIP_BUILDBRICK_FORBIDDENLIB)
			Tip()
		else
			self.enableOpenLib = true
			Tip(Global.TEXT.TIP_BUILDBRICK)
		end
	end

	if self.enableTransition then
		if module.dynamicEffects and module.dynamicEffects[1] then
			self:initDfs(module.dynamicEffects[1], logicgroups or gs)
		end
	end

	if self.enableTransition and module.bfuncs and #module.bfuncs > 0 then
		self.bfuncs = {}
		for i, func in ipairs(module.bfuncs) do
			local f = {}
			--f.group = nil
			f.events = {}
			for _, e in ipairs(func.events) do
				table.insert(f.events, {name = e.name, type = e.type})
			end

			table.insert(self.bfuncs, f)
		end
	end

	if module.chips_s then
		if logicgroups then
			self.chips_s = {}
			table.deep_clone(self.chips_s, module.chips_s)
			self.chips_s.groups = nil

			-- 创建一个空表
			if not self.chips_s.main then
				self.chips_s.main = {}
			end
			if not self.chips_s.dungeon then
				self.chips_s.dungeon = {}
			end
			if not self.chips_s.player then
				self.chips_s.player = {}
			end

			local groups = module.chips_s.groups
			if groups then
				for _, chips_s in ipairs(groups) do if #chips_s > 0 then
					local g = logicgroups[chips_s.group]
					local nbs = g:getBlocks()
					for i, b in ipairs(nbs) do
						b.chips_s = {}
						for _, chips in ipairs(chips_s) do
							local s = {}
							table.deep_clone(s, chips)
							table.insert(b.chips_s, s)
						end
					end
				end end
			end
		elseif module.chips_s.main then
			self.chips_s = {}
			table.deep_clone(self.chips_s, module.chips_s)
			self.chips_s.groups = nil
		else
			self.chips_s = {player = {}, dungeon = {}, main = {}}
			table.deep_clone(self.chips_s.main, module.chips_s)
		end
		-- print('!!!!!!!!load', table.ftoString(module.chips_s), debug.traceback())
	end

	if not logicgroups and module.block_chipss then -- TODO: to be deleted
		for index, css in next, module.block_chipss do
			bs[index].chips_s = {}
			if css.chips_s then
				table.deep_clone(bs[index].chips_s, css.chips_s)
			end
		end
	end

	if logicgroups then
		for i, g in ipairs(logicgroups) do
			local name = g:getName()
			if name and name ~= '' then
				for _, b in ipairs(g:getBlocks()) do
					if not b.logic_names then b.logic_names = {} end
					b.logic_names[name] = true
				end
			end
		end
	elseif module.logic_names then -- TODO: to be deleted
		for index, ns in next, module.logic_names do
			bs[index].logic_names = {}
			table.deep_clone(bs[index].logic_names, ns)
		end
	end

	-- load pairs
	if logicgroups then
		print('logicgroups', #logicgroups)
		self.pairBlocks = {}
		for i, g in ipairs(logicgroups) do
			local tag = g:getTag()
			print(i, tag, tag == 'pair')
			if tag == 'pair' then
				local ps = g:getBlocks()
				assert(#ps == 2, '#pair must be 2')
				self.pairBlocks[ps[1]] = ps[2]
				self.pairBlocks[ps[2]] = ps[1]
			end
		end
	end

	local ff = module.funcflags
	if ff and ff.bgmusic then
		local music = Global.AudioPlayer:getSourceByName('default', ff.bgmusic)
		if music then
			self:setBGM(music)
		end
	end

	if module.submodules then
		for i, subm in ipairs(module.submodules) do
			if subm.type == 'bind' then
				local b = bs[subm.bindex]
				self:loadMarkerBlocks(b, subm.module)
			end
		end
	end

	if ff and ff.userAABB then
		self.userAABBLocked = ff.userAABBLocked
		self.userAABB = _AxisAlignedBox.new(ff.userAABB)

		self.bgAABBLocked = ff.bgAABBLocked
		self.bgAABB = _AxisAlignedBox.new(ff.bgAABB)

		if module.center then
			_Vector3.add(self.userAABB.max, module.center, self.userAABB.max)
			_Vector3.add(self.userAABB.min, module.center, self.userAABB.min)
			_Vector3.add(self.bgAABB.max, module.center, self.bgAABB.max)
			_Vector3.add(self.bgAABB.min, module.center, self.bgAABB.min)
		end
	end

	self:showTopButtons()

	return bs, gs
end

BuildBrick.hasDynamicEffect = function(self)
	-- if not data.dynamicEffects or #data.dynamicEffects == 0 then return end
	-- local df = self.dynamicEffects[1]
	return Global.hasDynamicEffect(self.DFPlayer)
end

BuildBrick.hasPart = function(self, data)
	return data.parts and next(data.parts) and true
end

-- 把模块中的物件加到场景(不包括subs和part信息)
BuildBrick.dragModuleToScene = function(self, module, findpos, recursive)
	local nbs = {}
	local blocks = module.blocks or module
	local mat = Container:get(_Matrix3D)

	local haschild = false
	for i, v in ipairs(blocks) do
		if not recursive or type(v.shape) == 'number' then
			local b = self.sen:createBlock(v)
			if module.center then
				b.node.transform:mulTranslationRight(module.center.x, module.center.y, module.center.z)
			end
			table.insert(nbs, b)
		else
			haschild = true
			local snbs = self:dragModuleToScene(Block.loadItemData(v.shape), false, true)

			mat:setScaling(v.space.scale)
			local r = v.space.rotation
			mat:mulRotationRight(r.x, r.y, r.z, r.w)
			mat:mulTranslationRight(v.space.translation)
			if module.center then mat:mulTranslationRight(module.center) end

			for i, v in ipairs(snbs) do
				v.node.transform:mulRight(mat)
				table.insert(nbs, v)
			end
		end
	end
	Container:returnBack(mat)

	-- 设置分组, 加载子部件会导致分组错乱，暂时不加分组信息
	if not haschild then
		self:loadGroupInfos(module.groups, nbs)
		self:loadOverlapInfo(nbs, module.connects, module.overlaps, module.neighbors)
	end

	-- if findpos or x then
		-- if x and y then
		-- 	local ab = Container:get(_AxisAlignedBox)
		-- 	Block.getAABBs(nbs, ab)
		-- 	ab:alignSizeZ(0.08)
		-- 	local center = Container:get(_Vector3)
		-- 	local pos = Container:get(_Vector3)

		-- 	local flag = Global.CONSTPICKFLAG.NORMALBLOCK + Global.CONSTPICKFLAG.SELECTBLOCK + Global.CONSTPICKFLAG.TERRAIN
		-- 	local px, py, pz = self:pickScenePosition(x, y, flag, false)
		-- 	pos:set(px, py, pz)
		-- 	local diff = ab:diffBottom(pos)
		-- 	for i, b in ipairs(nbs) do
		-- 		b.node.transform:mulTranslationRight(diff)
		-- 		b:formatMatrix()
		-- 	end

		-- 	Container:returnBack(ab, center, pos)
		-- else
			-- self:findUncollidedPlace(nbs)
		-- end
	-- end

	if findpos then
		self:findUncollidedPlace(nbs)
	end

	local pg
	if self.enableGroup and not self.disableGroupCombine then
		-- 重新统计分组情况(为了兼容处理保存时未保存组信息的文件)
		local gs = {}
		local n = 0
		for i, b in ipairs(nbs) do
			local g = b:getBlockGroup('root')
			if not gs[g] then
				gs[g] = true
				n = n + 1
			end
		end

		-- 创建个新的父组把module节点包括进去
		if n > 1 then
			pg = self:newGroup()
			for g in pairs(gs) do
				g:setParent(pg)
			end
		else
			pg = next(gs)
		end
	end

	return nbs, pg
end

BuildBrick.setModule = function(self, m)
	local module = m and m.typestr == 'SceneModule' and m or SceneModule.new(m)
	self.modules = module

	self:loadSceneFromModule(module)
	-- self.curmodule = module
	-- TODO[module undo],切换rtdata
	self:atom_init_rt()
	self:ui_flush_undo()

	self:refreshModuleIcon()
	--self.oriMd5 = self:calcMd5()
end
--[[
BuildBrick.delModule = function(self, module)
	local subid = module.sindex
	-- 删除前把同步场景的信息到data
	self:saveSceneToModule(self.curmodule)

	if subid == 0 then
		table.clear(module.blocks)
		table.clear(module.groups)
	else
		self.modules.subs[subid] = nil
	end

	self:clearSceneBlock()

	if self.curmodule == module then
		self:setModule(self:getModule(0))
	else
		self:loadSceneFromModule(self.curmodule)
	end

	self:clearCommand()
	-- self:refreshModuleList()
	self:refreshModuleIcon()
end
--]]
-------------------------------------------- UI相关
BuildBrick.captureBlocks = function(self, db, datas, onfloor, nocenter, callback)
	if not callback then return end
	local outdb
	if #datas > 0 then
		self.onlyZdb = self.onlyZdb or _DrawBoard.new(1024, 1024, 0)
		self.onlyZdb.postProcess = self.postProcess
		Block.draw3DIcon(datas, self.onlyZdb, nil, nil, false, onfloor, self.skylightdir, nocenter)

		db.postProcess = _rd.postProcess
		Block.draw3DIcon(datas, db, nil, nil, true, onfloor, self.skylightdir, nocenter)
		db.postProcess = nil

		outdb = _mf:occlusionAlphaTexture(db, nil, nil, self.onlyZdb)
		local ratio = self.defaultImageSize / db.w
		if ratio ~= 1.0 then
			_mf:resizeFImage(outdb, ratio, ratio, function(img)
				callback(img)
			end)
		else
			callback(outdb)
		end
	else
		_rd:useDrawBoard(db, _Color.Null)
		_rd:resetDrawBoard()
		callback(db)
	end
end

BuildBrick.captureBlocksToDB = function(self, db, nbs, nocenter, cb)
	local asyncShader = _sys.asyncShader
	_sys.asyncShader = false
	local lastdepthOutline = _rd.postProcess.depthOutline
	local lastnormalOutline = _rd.postProcess.normalOutline
	local lastnormalOutlineRadius = _rd.postProcess.normalOutlineRadius
	local lastdepthOutlineBias = _rd.postProcess.depthOutlineBias
	if _sys.os == 'win32' then
		_rd.postProcess.depthOutline = true
		_rd.postProcess.depthOutlineBias = 0.1
	end
	_rd.postProcess.normalOutline = true
	_rd.postProcess.normalOutlineRadius = 0.99

	if not nbs then
		nbs = {}
		self:getBlocks(nbs)
	end

	self:captureBlocks(db, nbs, true, nocenter, function(dstimg)
		cb(dstimg)
		-- local w, h = loadui.picload._width, loadui.picload._height
		-- local ui = loadui.picload:loadMovie(dstimg)
		-- if ui then
		-- 	ui._width = w
		-- 	ui._height = h
		-- end

		-- if loadui.picload1 then
		-- 	w, h = loadui.picload1._width, loadui.picload1._height
		-- 	ui = loadui.picload1:loadMovie(dstimg)
		-- 	if ui then
		-- 		ui._width = w
		-- 		ui._height = h
		-- 	end
		-- end
	end)

	_rd.postProcess.depthOutline = lastdepthOutline
	_rd.postProcess.normalOutline = lastnormalOutline
	_rd.postProcess.normalOutlineRadius = lastnormalOutlineRadius
	_rd.postProcess.depthOutlineBias = lastdepthOutlineBias
	_sys.asyncShader = asyncShader
end

BuildBrick.refreshModuleIcon = function(self, index)
	if self.dfEditing and self.currentDframe and self.currentDframe.uiitem then
		local frame = self.currentDframe
		self:captureBlocksToDB(self.dfDB, nil, false, function(dstimg)
			frame.dstimg = dstimg
			self:refreshDFIcon(frame)
		end)
	end

	-- local nbs = {}
	-- if not index or index == self.curmoduleindex then
	-- 	self:getBlocks(nbs)
	-- 	index = self.curmoduleindex
	-- else
	-- 	local module = self:getModule(self.subids[index])
	-- 	nbs = module.blocks
	-- end
	-- local db = self.moduledbs[index]
	-- local ui = self.moduleItems[index]
	-- self:captureBlocksToDB(db, ui)

	self:onBrickChange()
end

--[[
BuildBrick.refreshModuleList = function(self)
	local subids = {[1] = 0}
	for id, v in pairs(self.modules.subs or {}) do
		table.insert(subids, id)
	end
	table.sort(subids, function(a, b)
		return a < b
	end)

	self.moduleNum = #subids

	local list = self.ui.modulelist.modules
	list.scrollable = true

	local moduleitems = {}
	list.onRenderItem = function(index, item)
		local module = self:getModule(subids[index])
		module.lindex = index
		-- item.picload.visible = true
		-- item.picload1.visible = true
		table.insert(moduleitems, item)

		-- 创建db缓存
		if not self.moduledbs[index] then
			self.moduledbs[index] = _DrawBoard.new(1024, 1024, 0)
		end

		item.click = function()
			-- self:setModule(module)
			-- self:refreshModuleList()
		end

		item.onMouseDown = function(arg)
			local scalef = Global.UI:getScale()
			local x, y = arg.mouse.x * scalef, arg.mouse.y * scalef
			item.add_success = false
			self:addDragTimer(x, y, 500, function()
				if module.sindex == 0 or module.sindex == self.curmodule.sindex then
					print('!!!drag main module is not allowed')
					return
				end

				-- select none
				self:cmd_select_begin()
				self:cmd_select_end()
				-- add
				local bs = self:cmd_dragModule(module, x, y)
				-- select bs
				self:atom_block_select(bs)
				-- set mouse pos
				self.downX = x
				self.downY = y

				item.add_success = true
				list.scrollable = false
			end)
		end

		item.onMouseMove = function(arg)
			local scalef = Global.UI:getScale()
			local x, y = arg.mouse.x * scalef, arg.mouse.y * scalef
			self:onCancelDragTimer(x, y)

			if item.add_success then
				self:onmove_editbrick(x, y)
			end
		end

		item.onMouseUp = function(arg)
			local scalef = Global.UI:getScale()
			local x, y = arg.mouse.x * scalef, arg.mouse.y * scalef
			self:cancelDragTimer()

			if item.add_success then
				self:building_moveEnd(x, y)
				self.downX = nil
				self.downY = nil

				self:delModule(module)
			end

			list.scrollable = true
		end
	end
	list.itemNum = #subids
	list._height = list.itemNum * 220
	self.subids = subids
	self.moduleItems = moduleitems

	-- add module
	self.ui.modulelist.add._visible = false -- 隐藏添加模块按钮
	self.ui.modulelist.add.click = function()
		self:setModule(self:createModule())
		self:refreshModuleList()
		self:refreshModuleIcon()
		-- 新建后拉到最底
		list.posY = 9999
	end
	self.uiaddmodule = self.ui.modulelist.add

	-- 更新选中模块
	self.curmoduleindex = nil
	for i, v in ipairs(moduleitems) do
		local module = self:getModule(subids[i])
		v.selected = self.curmodule == module
		if v.selected then
			self.curmoduleindex = i
		end
		self:refreshModuleIcon(i)
	end
end

BuildBrick.inAddArea = function(self, x, y)
	--local scalef = Global.UI:getScale()
	--x, y = x / scalef, y / scalef

	return self.uiaddmodule:hitTest(x, y)
end
--]]