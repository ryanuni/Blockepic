local Container = _require('Container')
local command = _require('Pattern.Command')

local BuildBrick = _G.BuildBrick

-- keepblock用于直接保存block对象
BuildBrick.clearGroups = function(self)
	if not self.BlockGroups then
		self.BlockGroups = {}
	end

	for _, g in pairs(self.BlockGroups) do
		g:clear()
	end

	self.BlockGroups = {}
end

BuildBrick.delGroup = function(self, group)
	local g = self.BlockGroups[group.serialNum]
	self.BlockGroups[group.serialNum] = nil

	if g then
		g:clear()
		return true
	end

	return false
end

BuildBrick.newGroup = function(self, isleaf)
	local g = BlockGroup.new(isleaf)
	self.BlockGroups[g.serialNum] = g
	return g
end

BuildBrick.changeSerialNum = function(self, g, serialNum)
	if g.serialNum == serialNum then
		return
	end
	self.BlockGroups[g.serialNum] = nil
	g.serialNum = serialNum
	self.BlockGroups[serialNum] = g
end

BuildBrick.getBySerialNum = function(self, serialNum)
	return self.BlockGroups[serialNum]
end

BuildBrick.saveGroupInfos = function(self, groups, groupinfos, keepblock)
	-- 添加group信息
	local index = 0
	for _, group in ipairs(groups) do if group:isValid() then
		index = index + 1
		group:setIndex(index)
	end end

	for _, group in ipairs(groups) do if group:isValid() then
		local g = {}
		group:save(g, keepblock)
		table.insert(groupinfos, g)
	end end
end

BuildBrick.loadGroupInfos = function(self, groupinfos, bs, loadserialnum)
	--加载group信息
	local groups = {}
	for i, g in ipairs(groupinfos or {}) do
		-- bs为nil时bindex直接当作加载block
		local group = BlockGroup.newWithData(g, bs, self)
		-- group:load(g, bs)
		table.insert(groups, group)

		if loadserialnum then
			self:changeSerialNum(group, g.serialNum)
		end
	end

	for i, g in ipairs(groupinfos or {}) do
		local group = groups[i]

		-- load children
		for _, gi in ipairs(g.children or {}) do
			group:addChild(groups[gi])
		end
	end

	return groups
end

local function updatelockIcon(lockbutton)
	lockbutton.lockgray.visible = false
	lockbutton.locked.visible = false
	lockbutton.lock.visible = false

	if lockbutton.selected then
		lockbutton.locked.visible = true
	else
		if lockbutton.disabled then
			lockbutton.lockgray.visible = true
		else
			lockbutton.lock.visible = true
		end
	end
end
BuildBrick.onGroupLock = function(self, group)
	if not group then return end

	local ab = group:getAABB()
	local vec = Container:get(_Vector3)
	local mat = _Matrix3D.new()
	ab:getCenter(vec)
	mat:setTranslation(vec)
	mat:mulScalingLeft(0.05, 0.05, 0.05)
	Container:returnBack(vec)
	local pfxname = group:isLock() and 'lr_suo_001.pfx' or 'lr_suo_002.pfx'
	local otherpfxname = group:isLock() and 'lr_suo_002.pfx' or 'lr_suo_001.pfx'
	self.sen.pfxPlayer:stop(otherpfxname, true)
	self.sen.pfxPlayer:play(pfxname, pfxname, mat)
	if group:isLock() then
		Global.Sound:play('build_lock01')
	else
		Global.Sound:play('build_lock02')
	end
	-- _sys:vibrate(50) -- 手机震动
	local lockbutton = self.ui.lockbutton
	self.ui.lockbutton.selected = group and group:isLock()
	updatelockIcon(self.ui.lockbutton)
end

BuildBrick.syncMultselectvisible = function(self)
	self.ui.multiselect.visible = true
	self.ui.multiselect.disabled = self:getBlockCount() == 0

	self.ui.bottombg.visible = true
	if self.hideNormalUI or self.showSkl or self.partopt ~= 'exit' or self.enableGraffiti or self:isMusicMode('music_main') then
		self.ui.multiselect.visible = false
		self.ui.bottombg.visible = false
	end
end

BuildBrick.isBlocksTransparent = function(self, bs, f)
	if not self.dfEditing then return false end
	local isalpha = true
	for i, b in ipairs(bs) do
		local alpha = self:getFrameData(f, b, 'alpha')
		if alpha ~= 0 then
			isalpha = false
			break
		end
	end
	return isalpha
end

BuildBrick.onSelectTrain = function(self)
	local uis = {'multiselect', 'lockbutton', 'copybutton', 'mirror', 'editmtl', 'addasset', 'selectmode', 'addpaint', 'graffiti_del'}

	self:showScaleHint(false)
	self:showMarkerHint(false)
	self:showFrequent(false)
	self:showRotHint(false)
	self:showMovHint(false)
	self:hideSwitchUI()

	self:setDelVisable(true)
	local x = self.ui.safearea_right._x
	for i, v in ipairs(uis) do
		local u = self.ui[v]
		u.visible = v == 'copybutton'
		if u and u.visible then
			u._x = x - u._width - 30
			x = u._x
		end
	end
end

BuildBrick.setDelVisable = function(self, show)
	self.ui.module_del.visible = show
	if show then
		if self.dfEditing then
			self.ui.module_del.bg.delbg.visible = false
			if self:isBlocksTransparent(self.rt_selectedBlocks) then
				self.ui.module_del.bg.backbg.visible = true
				self.ui.module_del.bg.alphabg.visible = false
			else
				self.ui.module_del.bg.backbg.visible = false
				self.ui.module_del.bg.alphabg.visible = true
			end
		else
			self.ui.module_del.bg.delbg.visible = true
			self.ui.module_del.bg.backbg.visible = false
			self.ui.module_del.bg.alphabg.visible = false
		end
	end
end

BuildBrick.onSelectGroup = function(self, gs)
	local g = gs and gs[1]
	local show = g and not self.hideNormalUI

	if self.movingMusic then show = false end

	local b1 = self.rt_selectedBlocks[1]

	if self.logicEditing then
		self.ui.logicpanel.visible = show

		local culling = false
		for i, b in ipairs(self.rt_selectedBlocks) do
			if b:isPhyxCulliing() then
				culling = true
				break
			end
		end
		self.ui.logicpanel.phyxcull.selected = culling

		self.ui.logicpanel.setbgbutton.disabled = not ( self:isBuildScene() and #self.rt_selectedBlocks == 1 )
		self.ui.logicpanel.setbgbutton.selected = b1 and b1.isDungeonBg

		show = false
	end

	if g and (self.mode == 'buildanima' or self.mode == 'buildbrick') and Global.Achievement:check('firstenterbuild') == false then
		Global.gmm.onEvent('showhotkeytip')
		Global.Achievement:ask('firstenterbuild')
	end

	if self:isSelectedMusicSpecial() then
		self:onSelectTrain()
		return
	end

	--print('onSelectGroup', debug.traceback())

	self:showScaleHint(show)
	self:showMarkerHint(show)
	self.ui.graffiti_del.visible = show and self.enableGraffiti
	if not show then
		self.enableGraffiti = false
	else
		show = show and not self.enableGraffiti
	end

	self.ui.lockbutton.visible = show and not self:isBuildScene()
	self.ui.lockbutton.selected = g and g:isLock() and #gs == 1
	self.ui.lockbutton.disabled = g and (g:isLeafNode() or g:isDeadLock()) and #gs == 1 or not self.enableBrickMat

	updatelockIcon(self.ui.lockbutton)

	self:syncMultselectvisible()
	if not self.ui.multiselect.visible then
		self:showMultiSelectPanel(false)
	end
	self.ui.editmtl.visible = show and not self:isBuildScene()

	local leaf = g and g:isLeafNode() and g:getBlockNode()
	self.ui.editmtl.disabled = show and leaf and leaf.markerdata and true
	self.ui.addasset.visible = false --show

	show = show and self.enableBrickMat
	self:setDelVisable(show)
	self.ui.copybutton.visible = show
	self.ui.mirror.visible = show and not self.dfEditing -- 编辑动画时禁止镜像操作

	local showaddpaint = false
	if self.rt_selectedBlocks and #self.rt_selectedBlocks == 1 and not self:isBuildScene() then
		local b = self.rt_selectedBlocks[1]
		if b and b.data.shape and not Block.isItemID(b.data.shape) then
			local faces = Block.getPaintFace(b.data.shape)
			showaddpaint = #faces > 0
		end
	end

	self.ui.addpaint.visible = show and showaddpaint

	self:showFrequent(not show and not self.enableGraffiti)

	self:showRotHint(show or self.enableGraffiti)
	self:showMovHint(show or self.enableGraffiti)
	self:hideSwitchUI()

	-- UI排列自动对齐
	local uis = {'multiselect', 'lockbutton', 'copybutton', 'mirror', 'editmtl', 'addasset', 'selectmode', 'addpaint', 'graffiti_del'}
	local x = self.ui.safearea_right._x
	for i, v in ipairs(uis) do
		local u = self.ui[v]
		if u and u.visible then
			u._x = x - u._width - 30
			x = u._x
		end
	end

	-- self:onSelectGroup_Transition(gs)
end

-- 清空产生的空组
BuildBrick.clearEmptyGroup = function(self)
	for _, g in pairs(self.BlockGroups) do
		if not g:isValid() then
			for i, v in ipairs(self.rt_selectedGroups) do
				if g == v then
					table.remove(self.rt_selectedGroups, i)
					break
				end
			end

			self:unattachPartGroup(g)
			self:delGroup(g)
			--print('clearEmptyGroup', g)
		elseif #g == 0 and #g.children == 1 then
			-- TODO：合并父与子
		end
	end
end

local timer1 = _Timer.new()
local function split_effect(group)
	local bs = {}
	group:getBlocks(bs)
	for i, b in ipairs(bs) do
		local c = _Curve.new() -- sin(x)

		c.type = _Curve.Hermite
		c:addPoint(_Vector2.new(0.0, 0))
		c:addPoint(_Vector2.new(0.3, 1))
		c:addPoint(_Vector2.new(0.5, 0))
		c:addPoint(_Vector2.new(0.7, -1))
		c:addPoint(_Vector2.new(1.0, 0))

		b.node.mesh.transform:mulScalingLeft(1.1, 1.1, 1.1, 150):applyCurve(c)
	end
	timer1:start('aabb', 150, function()
		group:setDirty()
		timer1:stop('aabb')
	end)

	Global.Sound:play('build_split')
	-- _sys:vibrate(50) -- 手机震动
end

BuildBrick.getAtomGroup = function(self, b)
	local g = b:getBlockGroup('lock')
	if g then return g end

	if not g then
		return b:getBlockGroup()
	end

	--g:setTempRoot(true)
	return g
end

BuildBrick.checkEnableOpenLib = function(self)
	self.enableOpenLib = true
	for i, v in ipairs(self.groupStack) do
		if v.part then
			self.enableOpenLib = false
		end
	end
end

BuildBrick.loadMarkerBlocks = function(self, block, module)
	local bs, g = self:dragModuleToScene(module)
	for _, b in ipairs(bs) do
		-- b.isWall = true
		b.isdummyblock = true
		b.node.transform.parent = block.node.transform
		b.bindblock = block
	end

	block.bindmodule = module

	local bshash = {}
	table.farray2Hash(bs, bshash)
	block.bindmoduleBlocks = bshash

	print('loadMarkerBlocks', block, module, #bs)
end

BuildBrick.pushMarkerBlocks = function(self, block)
	local m = block.bindmodule
	block.bindmodule = nil

	local mdata = self:saveModuleToData()

	local bindex = block.index

	self:initData('buildbrick')
	self:setModule(m)

	if not self.markerBlocks_Stack then self.markerBlocks_Stack = {} end
	table.insert(self.markerBlocks_Stack, {mdata = mdata, bindex = bindex})

	self:addBackClickCb('onlyback', function()
		self:cmd_select_begin()
		self:cmd_select_end()
		self:popMarkerBlocks()
	end)

	Global.AddHotKeyFunc(_System.KeyESC, function()
		return self.markerBlocks_Stack and #self.markerBlocks_Stack > 0
	end, function()
		self:clickBackCb()
	end)
end

BuildBrick.popMarkerBlocks = function(self)
	assert(#self.markerBlocks_Stack > 0)
	local sdata = self.markerBlocks_Stack[#self.markerBlocks_Stack]
	table.remove(self.markerBlocks_Stack)

	local m = self:getModule()
	-- print('popMarkerBlocks1111', m, table.ftoString(sdata.mdata.module))
	local nocenter = self.noCenter
	self.noCenter = true
	self:saveSceneToModule(m)
	self.noCenter = nocenter

	print('popMarkerBlocks', sdata.bindex, #sdata.mdata.module.submodules, #m.blocks)
	for i, v in ipairs(sdata.mdata.module.submodules) do
		if v.bindex == sdata.bindex then
			assert(false, 'v.bindex:' .. sdata.bindex)
		end
	end

	-- local om = sdata.mdata.module
	table.insert(sdata.mdata.module.submodules, {type = 'bind', bindex = sdata.bindex, module = m})
	--local block = om.blocks[sdata.bindex]
	--b.bindmodule = m

	-- print('popMarkerBlocks', b.bindmodule)
	self:loadModuleData(sdata.mdata)

	-- local bs = {}
	-- self:getBlocks(bs)
	-- local block
	-- for i, b in ipairs(bs) do
	-- 	if b.index == sdata.bindex then
	-- 		block = b
	-- 		break
	-- 	end
	-- end

	--print('popMarkerBlocks', sdata.bindex, #bs, block and block.markerdata, block and block.shape, m)
	--self:loadMarkerBlocks(block, m)
end

BuildBrick.pushGroup = function(self, g)
	--assert(g:isLock())

	--self:atom_group_select()

	table.insert(self.groupStack, g)
	self:atom_group_enter(g)

	--self:showTopButtons('enterGroup')
	self:checkEnableOpenLib()

	self:addBackClickCb('onlyback', function()
		self:cmd_select_begin()
		self:cmd_select_end()
		self:popGroup()
	end)

	Global.AddHotKeyFunc(_System.KeyESC, function()
		return self.groupStack and #self.groupStack > 0
	end, function()
		self:clickBackCb()
	end)
end

BuildBrick.popGroup = function(self)
	assert(#self.groupStack > 0)
	local g = self:getCurrentGroup()

	self:atom_group_leave()
	table.remove(self.groupStack)

	local curg = self:getCurrentGroup()
	self:atom_group_enter(curg)

	-- if curg then
	-- 	self:showTopButtons('enterGroup')
	-- else
	-- 	self:showTopButtons()
	-- end

	self:checkEnableOpenLib()

	return g
end

BuildBrick.getCurrentGroup = function(self)
	if #self.groupStack > 0 then
		return self.groupStack[#self.groupStack]
	end
end

BuildBrick.decomposeGroupWithBackUp = function(self, b, mode)
	local g
	if mode == 1 then
		g = self:getAtomGroup(b)
		g:setTempRoot(true)
		split_effect(g)
	elseif mode == 0 then
		g = b:getBlockGroup('tempRoot')
		g:setTempRoot(true)
	end

	--print('decomposeGroupWithBackUp', mode, g)

	return g
end

BuildBrick.expireRecombineBackup = function(self, gs)
	--print('expireRecombineBackup', g.isTempRoot)

	local ps = {}
	for i, g in ipairs(gs) do
		if g.isTempRoot then
			local p = g.parent
			g:setTempRoot(false)

			g:setParent(nil)
			g:clearOuterCONs()
			g:clearOuterCollisions()
			self:unattachPartSubGroup(g)

			if p then
				-- 重新计算group的连接关系，group可能会被拆分多个
				ps[p] = true
			end
		end
	end

	for p in pairs(ps) do
		local attachbs = {}
		local rt = p:getRoot()
		if rt.attachpart then
			self:unattachPartGroup(rt)
			rt:getBlocks(attachbs)
		end

		p:recombine()

		if rt.attachpart then
			local rs = {}
			for i, v in ipairs(attachbs) do
				local root = v:getBlockGroup('tempRoot')
				rs[root] = true
			end

			for r in pairs(rs) do
				self:attachPartGroup(p.attachpart, r)
			end
		end
	end
end

BuildBrick.useRecombineBackup = function(self, g)
	if g.isTempRoot then
		g:setTempRoot(false)
		return true
	end
	return false
end

BuildBrick.checkShapeConnectType = function(self, b1, b2, s1, s2)
	--print('checkShapeConnectType00:', s1, s2, s1 and s1.jointdata, s2 and s2.jointdata)

	if s1.jointdata and s2.jointdata then
		if self.knotMode == Global.KNOTPICKMODE.SPECIAL then
			local k1 = b1:getSpecialKnot(s1.bindex, s1.jointdata.index)
			local k2 = b2:getSpecialKnot(s2.bindex, s2.jointdata.index)
			if k1 and k2 then
				-- 初始化knot数据
				b1:getSpecialKnotGroup()
				b2:getSpecialKnotGroup()
				k1:setTransformDirty()
				k2:setTransformDirty()
				return k1:isRotPairs(k2)
			end
		else
			local k1 = b1:getKnot(s1.bindex, s1.jointdata.index)
			local k2 = b2:getKnot(s2.bindex, s2.jointdata.index)
			--print('checkShapeConnectType:', k1, k2, k1 and k2 and k1:isRotPairs(k2))

			if k1 and k2 then
				return k1:isRotPairs(k2)
			end
		end
	end
end

local expandab = _AxisAlignedBox.new()
BuildBrick.getGroupAndNearbyBlocks = function(self, group, nbs)
	if not nbs then
		nbs = {}
		self:getBlocks(nbs)
	end

	local gbs = {}
	group:getBlocks(gbs)
	local hbs = {}
	for i, b in ipairs(gbs) do
		hbs[b] = true
	end

	group:getAABB(expandab)
	expandab:expand(0.1, 0.1, 0.1)

	local nearbs = {}
	for i, b in ipairs(nbs) do if not hbs[b] then
		local ab = b:getShapeAABB2()
		if expandab:checkIntersect(ab) then
			table.insert(nearbs, b)
		end
	end end

	return gbs, nearbs
end

BuildBrick.updateGroupCONs = function(self, group, nbs)
	--assert(not group.parent and not group.part)

	local t1 = _tick()

	local gbs, tbs = self:getGroupAndNearbyBlocks(group, nbs)
	--print('tbs, gbs', #tbs, #gbs, #nbs)

	if #gbs == 0 then return end

	local connects, overlaps, neighbors = self:overlapBlocks(tbs, gbs)

	local function getbindpart()
		if not self.enablePart then return nil end

		local part2 = nil
		for b, bs in pairs(overlaps) do
			if b.part then return b.part end
			if b.part2 and not part2 then
				part2 = b.part2
			end
		end

		for b, bs in pairs(neighbors) do
			if b.part then return b.part end
			if b.part2 and not part2 then
				part2 = b.part2
			end
		end

		for b, ds in pairs(connects) do
			if b.part then return b.part end
			if b.part2 and not part2 then
				part2 = b.part2
			end
		end

		if part2 then
			return part2
		end
	end

	local bindpart = getbindpart()
	_G.getGroupSwitchPart = function(g)
		local name = ''
		if g.switchPart and g.switchPart ~= '' then
			return g.switchPart
		else
			local children = g:getChildren()
			if not children or #children == 0 then return name end
			for _, child in pairs(children) do
				name = getGroupSwitchPart(child)
				if name and name ~= '' then return name end
			end

			return ''
		end
	end

	local gpartname = getGroupSwitchPart(group)
	if gpartname ~= '' then
		for b, bs in pairs(overlaps) do
			local g = b:getBlockGroup('root')
			if getGroupSwitchPart(g) ~= '' then return end
		end
		for b, bs in pairs(neighbors) do
			local g = b:getBlockGroup('root')
			if getGroupSwitchPart(g) ~= '' then return end
		end
		for b, ds in pairs(connects) do
			local g = b:getBlockGroup('root')
			if getGroupSwitchPart(g) ~= '' then return end
		end
	end

	-- 使用part过滤碰撞积木
	local attachgs = {}
	local checkpart = function(b)
		if not self.enablePart then
			return true
		end
		if not bindpart then return true end

		if b.part then return false end
		if b.part2 and b.part2 ~= bindpart then
			return false
		end
		if b.part2 then
			local g = b:getBlockGroup('root')
			assert(g.attachpart)
			attachgs[g] = true
		end

		return true
	end

--	print('1111overlaps', table.fcount(overlaps))
	-- 更新block的连接数据
	for b, bs in pairs(overlaps) do
		if checkpart(b) then
			-- print('addOverlaps', b, bs[1])
			b:addOverlaps(bs)
		end
	end

	for b, bs in pairs(neighbors) do
		if checkpart(b) then
			-- print('addNeighbors', b, bs[1])
			b:addNeighbors(bs)
		end
	end

	for b, ds in pairs(connects) do
		if checkpart(b) then
			for _, data in ipairs(ds) do
				-- print('addConnects', data.b1, data.b2)
				data.b1:addConnects(data.b2, data.s2, data.s1)
			end
		end
	end

	local t2 = _tick()

	-- 解除attach的group，group更新后重新attach
	if bindpart then
		for g in pairs(attachgs) do
			self:unattachPartGroup(g)
		end
	end

	group:CombineByCONs()

	-- 重新attach
	if bindpart then
		local b = gbs[1]
		local r = b:getBlockGroup('root')

		local groups = {}
		r:getConnects(groups)
		for g in pairs(groups) do
			if not g.parent then
				self:attachPartGroup(bindpart, g)
			end
		end
	end
end

BuildBrick.recombineGroups = function(self, groups, skipgroups)
	if #groups == 0 then return end

	local skipbs = {}
	for i, g in ipairs(groups) do
		assert(not g.parent and not g.isTempRoot)
		g:clearOuterCONs() -- 删除多余信息，用于处理一下编辑错误的问题
		g:getBlocks(skipbs)
	end

	if skipgroups then
		for i, g in ipairs(skipgroups) do
			g:getBlocks(skipbs)
		end
	end

	local skipbs2 = {}
	for i, b in ipairs(skipbs) do
		skipbs2[b] = true
	end

	--print('recombineGroups', #skipbs, skipgroups and #skipgroups)

	local nbs = {}
	self:getBlocks(nbs, function(b)
		return not skipbs2[b]
	end)

	-- 更新连接关系
	for i, g in ipairs(groups) do
		assert(not g.parent and not g.isTempRoot)
		self:updateGroupCONs(g, nbs)
	end
end

BuildBrick.formatRotRestriction = function(self, connectdata, restriction)
	if connectdata then
		if connectdata.mode == 2 then
			if restriction then
				restriction.type = 2
				restriction.pos:set(connectdata.pos)
				restriction.axis:set(connectdata.axis)

				-- 标准化旋转轴，是旋转轴尽量指向y轴正方向
				local axis = restriction.axis
				if math.floatEqualVector3(axis, Global.AXIS.NX) or math.floatEqualVector3(axis, Global.AXIS.NY) or math.floatEqualVector3(axis, Global.AXIS.NZ) then
					_Vector3.mul(axis, -1, axis)
				elseif _Vector3.dot(axis, Global.AXIS.Y) < 0 then
					_Vector3.mul(axis, -1, axis)
				end
				print('!!!restriction,connectdata.mode == 2', restriction.type, restriction.axis, restriction.pos)
			end
			return true
		elseif connectdata.mode == 3 then
			if restriction then
				restriction.type = 3
				restriction.pos:set(connectdata.pos)
				print('!!!restriction,connectdata.mode == 3', restriction.type, restriction.pos)
			end
			return true
		end
	end
end

BuildBrick.checkGroupRotRestriction = function(self, groups, restriction)
	--if not group then return false end
	if #groups ~= 1 then
		return false
	end

	-- TODO: 处理多选时旋转轴的问题
	local gbs, tbs = self:getGroupAndNearbyBlocks(groups[1])

	local bs1, bs2 = {}, {}
	for i, b in ipairs(gbs) do
		bs1[b] = true
	end
	for i, b in ipairs(tbs) do
		bs2[b] = true
	end

	--重新检测连接情况
	local connects = {}
	self:checkConnectBlocks(bs2, bs1, connects)

	for b1, ds in pairs(connects) do
		for i, conn in ipairs(ds) do
			local connectdata = self:checkShapeConnectType(conn.b1, conn.b2, conn.s1, conn.s2)
			if self:formatRotRestriction(connectdata, restriction) then
				return true
			end
		end
	end

	return false
end