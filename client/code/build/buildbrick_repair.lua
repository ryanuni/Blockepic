local Container = _require('Container')
local command = _require('Pattern.Command')
local BuildBrick = _G.BuildBrick

BuildBrick.initRepairData = function(self)
	self.repair_dels = {}
	self.repair_adds = {}
	self.comboCount = 0
end

BuildBrick.isAddRepairBlock = function(self, b)
	local g = b:getBlockGroup('root')
	return self.repair_adds[g]
end

BuildBrick.getSortedBricks = function(self, g)
	if g.sortbricks then return g.sortbricks end

	local bs = {}
	g:getBlocks(bs)
	table.sort(bs, function(a, b)
		return a:getShape() < b:getShape()
	end)

	g.sortbricks = bs
	return g.sortbricks
end

BuildBrick.bindAddRepair = function(self, g, rg)
	assert(self.repair_adds[g])

	local rg1 = g.repairGroup
	-- print('bindAddRepair', rb1, rb, rb1 == rb)
	if rg1 and rg1 == rg then return end

	g.repairGroup = nil

	if rg1 then
		self:bindDelRepair(rg1, nil)
	end

	local nbs = {}
	g:getBlocks(nbs)
	for i, b in ipairs(nbs) do
		if rg then
			b:setIsRepairing(false)
			b:enableQuery(false)
			b.node.visible = false
		else
			b:setIsRepairing(true)
			b.node.visible = true
			b:enableQuery(true)
		end
	end

	if rg then
		g.repairGroup = rg
		self:bindDelRepair(rg, g)
	end
end

BuildBrick.bindDelRepair = function(self, g, rg)
	assert(self.repair_dels[g])
	local index = g.repairindex

	local rg1 = g.repairGroup
	-- print('bindDelRepair', rb1, rb, rb1 == rb)
	if rg1 and rg1 == rg then return end

	g.repairGroup = nil
	if rg1 then
		self:bindAddRepair(rg1, nil)
	end

	local nbs = {}
	g:getBlocks(nbs)
	for i, b in ipairs(nbs) do
		if rg then
			b:setNeedRepair(false, index)
			b.node.visible = true
			--b:setPickFlag(Global.CONSTPICKFLAG.NORMALBLOCK)
		else
			b:setNeedRepair(true, index)
			b:setPickFlag(Global.CONSTPICKFLAG.NONE)
		end
	end

	if rg then
		g.repairGroup = rg
		self:bindAddRepair(rg, g)
	end

	self:updateRepairPro()
end

BuildBrick.createAddRepair = function(self, g, center)
	local nbs = {}
	g:getBlocks(nbs)

	local ng = self:newGroup()
	ng.bindGroup = g
	for i, b in ipairs(nbs) do
		local nb = self.sen:cloneBlock2(b)
		ng:addChild(nb:getBlockGroup())
	end

	self:setAddRepair(ng)

	if center then
		ng:moveCenter(center)
		ng.initCenter = center
	end

	return ng
end

BuildBrick.setAddRepair = function(self, g)
	self.repair_adds[g] = true
	self:bindAddRepair(g, nil)

	self:refreshFrequent()

	local nbs = {}
	g:getBlocks(nbs)
	for i, b in ipairs(nbs) do
		b:enablePhysic(false)
	end
end

BuildBrick.autoSetRepairRot = function(self, g)
	assert(self.repair_adds[g])
	for delg in pairs(self.repair_dels) do
		assert(delg:isLeafNode())
		--assert(delg:isOnlyOneBrick())
	end

	local b = g:getBlockNode()
	local dels, adds = {}, {}
	for delg in pairs(self.repair_dels) do if not delg.repairGroup then
		local delb = delg:getBlockNode()
		if delb:getShape() == b:getShape() then
			table.insert(dels, delb)
		end
	end end

	for addg in pairs(self.repair_adds) do if not addg.repairGroup then
		local addb = addg:getBlockNode()
		if addg:getShape() == b:getShape() then
			table.insert(adds, addb)
		end
	end end

	if #dels >= #adds then
		local cb = dels[#adds]
		local rot = Container:get(_Vector4)
		local trans = Container:get(_Vector3)
		cb.node.transform:getRotation(rot)

		local mat = b.node.transform
		mat:getTranslation(trans)
		mat:setRotation(rot)
		mat:mulTranslationRight(trans)
		b:formatMatrix()
		Container:returnBack(rot, trans)
	end
end

BuildBrick.removeAddRepair = function(self, g)
	if not self.repair_adds[g] then return end
	self:bindAddRepair(g, nil)
	self.repair_adds[g] = nil

	self:refreshFrequent()
end

BuildBrick.setDelRepair = function(self, g, i)
	self.repair_dels[g] = true
	g.repairindex = i
	self:bindDelRepair(g, nil)

	local nbs = {}
	g:getBlocks(nbs)
	for i, b in ipairs(nbs) do
		b:enablePhysic(false)
	end

	return g
end

BuildBrick.getDelRepair = function(self, index)
	for g in pairs(self.repair_dels) do
		if g.repairindex == index then
			return g
		end
	end
end

BuildBrick.getTotalRepairCount = function(self)
	local n = 0
	for g in pairs(self.repair_dels) do
		n = n + 1
	end

	return n
end

BuildBrick.getRepairedCount = function(self)
	local n = 0
	for g in pairs(self.repair_dels) do if g.repairGroup then
		n = n + 1
	end end

	return n
end

BuildBrick.getRepairedGroups = function(self)
	local gs = {}
	for g in pairs(self.repair_dels) do if g.repairGroup then
		table.insert(gs, g)
	end end

	return gs
end

BuildBrick.getComboCount = function(self)
	return self.comboCount
end

BuildBrick.setComboCount = function(self, count)
	self.comboCount = count
end

BuildBrick.clearComboCount = function(self)
	self.comboCount = 0
end

BuildBrick.setAddRepairVisible = function(self, show)
	if show == nil then return end

	for g in pairs(self.repair_adds) do
		local nbs = {}
		g:getBlocks(nbs)
		for _, b in pairs(nbs) do
			--b:setVisible(show)
			b.node.visible = false
		end
	end
end

BuildBrick.setDelRepairVisible = function(self, show)
	if show == nil then return end

	for g in pairs(self.repair_dels) do if not g.repairGroup then
		local nbs = {}
		g:getBlocks(nbs)
		for _, b in pairs(nbs) do
			--b:setVisible(show)
			b.node.visible = false
		end
	end end
end

BuildBrick.getRepairGroupByIndex = function(self, index)
	for g in pairs(self.repair_adds) do
		if g.bindGroup and g.bindGroup.repairindex == index then
			return g, g.bindGroup
		end
	end
end

local repair_v1 = _Vector3.new()
local repair_v2 = _Vector3.new()

local repair_v2_1 = _Vector2.new()
local repair_v2_2 = _Vector2.new()

local repair_accuracy_pos = 0.2
local repair_accuracy_pos2 = 30
local repair_accuracy = 0.2
local function compairAABB(ab1, ab2, checkpos)
	ab1:getSize(repair_v1)
	ab2:getSize(repair_v2)
	if not math.floatEqualVector3(repair_v1, repair_v2, repair_accuracy) then
		return false
	end

	if checkpos then
		ab1:getCenter(repair_v1)
		ab2:getCenter(repair_v2)
		if not math.floatEqualVector3(repair_v1, repair_v2, repair_accuracy_pos) then
			return false
		end
	end

	return true
end

local function markSameGroups(g1, g2)
	if not g1.samegroups then g1.samegroups = {} end
	if not g2.samegroups then g2.samegroups = {} end
	g1.samegroups[g2] = true
	g2.samegroups[g1] = true

	-- print('markSameGroups', g1, g2)
end

BuildBrick.markSameDelRepair = function(self, gs)
	local sortfunc = function(a, b)
		if a:getShape() < b:getShape() then return true end
		if a:getShape() == b:getShape() then
			local c1 = a:getColor()
			local c2 = b:getColor()
			local m1 = a:getMaterial()
			local m2 = b:getMaterial()

			return m1 < m2 or m1 == m2 and c1 < c2
		end
		return false
	end

	local hasmarkedSame = function(g1, g2)
		return g1.samegroups and g1.samegroups[g2]
	end

	local checkSame = function(g1, g2)
		local ab1 = g1:getAABB()
		local ab2 = g2:getAABB()
		if not compairAABB(ab1, ab2) then
			return false
		end

		local bs1, bs2 = {}, {}
		g1:getBlocks(bs1)
		g2:getBlocks(bs2)
		if #bs1 ~= #bs2 then return false end

		table.sort(bs1, sortfunc)
		table.sort(bs2, sortfunc)

		for i, b1 in ipairs(bs1) do
			local b2 = bs2[i]
			if b1:getShape() ~= b2:getShape() or b1:getMaterial() ~= b2:getMaterial()
				or b1:getColor() ~= b2:getColor() then
				return false
			end

			local r1 = b1.data.space.rotation
			local r2 = b2.data.space.rotation
			if not math.floatEqualVector4(r1, r2) then
				return false
			end
		end

		return true
	end

	for i = 1, #gs do
		local g1 = gs[i]
		for j = i + 1, #gs do
			local g2 = gs[j]
			if not hasmarkedSame(g1, g2) and checkSame(g1, g2) then
				markSameGroups(g1, g2)
			end
		end
	end
end

BuildBrick.checkRepair = function(self, delg, addg, checkpos)
	if addg.bindGroup then
		local bindg = addg.bindGroup
		if not (bindg == delg or delg.samegroups and delg.samegroups[bindg]) then
			return false
		end
	else
		local bs1, bs2 = self:getSortedBricks(delg), self:getSortedBricks(addg)
		if #bs1 ~= #bs2 then return false end

		for i, b1 in ipairs(bs1) do
			local b2 = bs2[i]
			if b1:getShape() ~= b2:getShape() then
				return false
			end
		end
	end

	local v1 = repair_v1
	local v2 = repair_v2

	local ab1 = delg:getAABB()
	local ab2 = addg:getAABB()
	-- print('repairAABB', ab1, ab2)
	if not compairAABB(ab1, ab2, checkpos) then
		return false
	end

	ab1:getCenter(v1)
	ab2:getCenter(v2)
	_rd:projectPoint(v1.x, v1.y, v1.z, repair_v2_1)
	_rd:projectPoint(v2.x, v2.y, v2.z, repair_v2_2)
	-- print('repair', repair_v2_1, repair_v2_2)

	local scale = math.max(_rd.h / Global.DesignH, 0.25)
	if not math.floatEqualVector2(repair_v2_1, repair_v2_2, repair_accuracy_pos2 * scale) then
		return false
	end

	return true
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

		b.node.mesh.transform:mulScalingLeft(1.2, 1.2, 1.2, 300):applyCurve(c)
	end
	timer1:start('aabb', 300, function()
		group:setDirty()
		timer1:stop('aabb')
	end)

	Global.Sound:play('repair_success7')
	-- _sys:vibrate(50) -- 手机震动
end

BuildBrick.checkRepaired = function(self, g, checkpos)
	local addg = g or self.rt_selectedGroups[1]
	if not addg or not self.repair_adds[addg] then return end

	self.noPutSound = false
	local binded = addg.repairGroup
	if binded and self:checkRepair(binded, addg, checkpos) then
		self.noPutSound = true
		return true
	end

	self:bindAddRepair(addg, nil)
	for delg in pairs(self.repair_dels) do if not delg.repairGroup then
		if self:checkRepair(delg, addg, checkpos) then
			self:bindAddRepair(addg, delg)
			-- if not binded then
				split_effect(delg)
				--Global.Sound:play('repair_success7')
			-- end
			self.noPutSound = true
			return true
		end
	end end

	return false
end

BuildBrick.clearRepaired = function(self)
	for addg in pairs(self.repair_adds) do if addg.repairGroup then
		self:bindAddRepair(addg, nil)

		if addg.initCenter then
			addg:moveCenter(addg.initCenter)
			addg:setDirty()
		end
	end end
end

BuildBrick.disabledRepair = function(self, b)
	self.repair_disabled = b

	-- if b then
	-- 	self:cmd_select_end()
	-- 	self:building_moveEnd(0, 0)
	-- end
end

BuildBrick.randomInvisable = function(self, bs, rate)
	for i, v in ipairs(bs) do
		if math.random() > rate then
			v:enablePhysic(false)
			v.node.visible = false
			v.actor.isVisible = false
		end
	end
end

BuildBrick.blastRepaired = function(self, shapeid, time1, bombindex, isme, cb)
	local module = Block.loadItemData(shapeid)
	if not module then return end

	local bs = self:dragModuleToScene(module)

	for i, b in ipairs(bs) do
		b.node.transform:mulRotationXRight(math.pi)
	end

	local ab = _AxisAlignedBox.new()
	Block.getAABBs(bs, ab)
	local vec = _Vector3.new()
	ab:getBottom(vec)

	local maxh = 0
	for g in pairs(self.repair_dels) do
		if g.repairGroup then
			local aabb = g:getAABB()
			maxh = math.max(maxh, aabb.max.z)
		end
	end

	for i, b in ipairs(bs) do
		b:setPickFlag(Global.CONSTPICKFLAG.PHYSICALBLOCK + Global.CONSTPICKFLAG.NORMALBLOCK)
		b.node.transform:mulTranslationRight(-vec.x, -vec.y, maxh - vec.z)
		b:formatMatrix()
	end

	local pos = _Vector3.new(0, 0, 10)
	for i, b in ipairs(bs) do
		b.node.transform:mulTranslationRight(pos)
	end

	for i, b in ipairs(bs) do
		b.node.transform:mulTranslationRight(0, 0, - pos.z, 300)
	end

	local maxcount = isme and 125 or 75
	self.timer:start('repairBlast', 300, function()
		for i, b in ipairs(bs) do
			b:resetSpace()
		end

		self:playRepairPfx('bomb')
		local pbs = {}
		self:getBlocks(pbs, function(b)
			return b.node.visible and b:hasPickFlag(Global.CONSTPICKFLAG.PHYSICALBLOCK)
		end)

		local oldcount = #pbs
		local keepcount = 2 * maxcount
		if oldcount > maxcount then
			self:randomInvisable(pbs, math.min(keepcount / oldcount, 1))
		end

		-- 修复的积木变为破碎
		local brokenbs = {}
		if bombindex ~= 0 then
			for g in pairs(self.repair_dels) do if g.repairGroup then
				local nbs = {}
				g:getBlocks(nbs)

				for i, b in ipairs(nbs) do
					local nb = self.sen:cloneBlock2(b)
					nb:setPickFlag(Global.CONSTPICKFLAG.PHYSICALBLOCK + Global.CONSTPICKFLAG.NORMALBLOCK)
					table.insert(brokenbs, nb)
				end
			end end

			self:clearRepaired()
		end

		local newcount = #bs + #brokenbs
		local rate = math.min(maxcount / newcount, 1)

		local c = self:getCameraControl()
		c.camera:shake(0.1, 0.2, 200, _Camera.Quadratic)
		-- if playsound then
			Global.Sound:play('blockbrawl_bomb')
		-- end
		Block.blast_project(bs, 10, rate)
		if #brokenbs then
			Block.blast_project(brokenbs, 10, rate)
		end
		table.fappendArray(bs, brokenbs)

		if cb then cb(bombindex) end

		self.timer:start('repairBlast3', time1, function()
			for i, b in ipairs(bs) do
				if b.node.visible then
					b:changeTransparency(0, 0.5)
				end
			end
			self.timer:stop('repairBlast3')
		end)
		self.timer:start('repairBlast4', time1 + 500, function()
			for i, b in ipairs(bs) do
				if b.node.scene and self.sen then -- b没有清除掉
					self:atom_block_del(b)
				end
			end

			self.timer:stop('repairBlast4')
		end)

		self.timer:stop('repairBlast')
	end)
end

BuildBrick.showVictory = function(self)
	local ui = self.ui
	local victory = self.ui.victory
	self:onSelectGroup()
	self:showPropList(false)
	self:onSelectRepairGroup()
	Tip()
	ui.btn_redo.visible = false
	ui.btn_undo.visible = false
	ui.modulelist.visible = false
	ui.bricklist.visible = false
	ui.multiselect.visible = false
	ui.bottombg.visible = false

	self:showTopButtons('hideall')

	if self.shapeid == 'repair_bridge' then
		Global.gmm.repairbridgedone = true
	end
	if self.shapeid == 'repair_work' then
		Global.gmm.repairworkdone = true
	end
	if self.shapeid == 'repair_TV' then
		Global.gmm.repairTVdone = true
	end
	if self:getParam('repairlevel') then
		Global.gmm.repairlevel = self:getParam('repairlevel')
	end

	if victory.visible then return end

	victory.visible = true
	local clickfunc = function()
		-- TODO:
		local bp = self:getParam('blueprint')
		if bp then
			local level = bp.data and bp.data.level or 1
			local maxlevel = #bp
			--print('update begin', table.ftoString(bp))
			Global.Blueprint:update(bp.name, level + 1, nil, function()
				if level < maxlevel then
					local nbp = Global.Blueprint:getBluePrint(bp.name)
					self:setParam('blueprint', nbp)

					local nlevel = nbp.data and nbp.data.level or 1

					local objname = nbp.data and nbp.data.datafile and nbp.data.datafile.name or nbp[nlevel].name

					self.freqs = {}
					self:initUI()
					self:load(_sys:getFileName(objname, false, false))
				else
					RPC("GetBlueprints", {})
					Global.entry:back()
				end
			end)
		else
			UPLOAD_DATA('build_puzzle_end')

			Global.DressAvatarShot:show(self.shapeid)
			Global.DressAvatarShot.onExit = function()
				Global.entry:back(function()
					Global.Timer:add('FameTask_doTask', 500, function()
						Global.PortalFixTask:addSubProgress()
						Global.FameTask:doTask('Fix_Portal')
					end)
				end)
			end
		end
	end
	victory.next.click = function()
		clickfunc()
	end
end

BuildBrick.getRepairShapeFilter = function(self)
	local ss = {}
	for g in pairs(self.repair_dels) do
		if not g:isLeafNode() then
			return ss
		end
	end

	for g in pairs(self.repair_adds) do
		if not g:isLeafNode() then
			return ss
		end
	end

	for g in pairs(self.repair_dels) do if not g.repairGroup then
		local b = g:getBlockNode()
		local shape = b:getShape()
		local n = ss[shape] or 0
		ss[shape] = n + 1
	end end

	-- print('--------1', table.ftoString(ss))
	for g in pairs(self.repair_adds) do if not g.repairGroup then
		local b = g:getBlockNode()
		local shape = b:getShape()
		if ss[shape] then
			ss[shape] = ss[shape] - 1
		end
	end end

	-- print('--------2', table.ftoString(ss))
	for shape, n in pairs(ss) do
		if n <= 0 then
			ss[shape] = nil
		end
	end

	-- print('--------3', table.ftoString(ss))

	return ss
end

-- 隐藏匹配上的addBlock以及设置delBlock可点击
BuildBrick.onCheckRepair = function(self, playsound)
	local incRepair, cur = false, 0
	for g in pairs(self.repair_dels) do
		if g.repairGroup then
			cur = cur + 1
			local rg = g.repairGroup

			local nbs = {}
			g:getBlocks(nbs)
			for _, b in ipairs(nbs) do
				local flag = b:getPickFlag()
				if flag == Global.CONSTPICKFLAG.NORMALBLOCK then
					break
				end

				incRepair = true
				b:setPickFlag(Global.CONSTPICKFLAG.NORMALBLOCK)
			end

			if incRepair then
				local bs2 = {}
				rg:getBlocks(bs2)
				for i, b in ipairs(bs2) do
					b.node.visible = false
				end
			end
		end
	end

	if incRepair and playsound then
		local index = math.random(1, 6)
		Global.Sound:play('repair_success' .. index)
	end

	if self.mode == 'repair' then
		local victory = true
		for delg in pairs(self.repair_dels) do if not delg.repairGroup then
			victory = false
		end end

		if victory then
			self:playRepairPfx('fixall')

			if not self.disableUI then
				Global.Sound:play('repair_win')
				self:showVictory()
			end
			return true
		end
	end
end

BuildBrick.onSelectRepairGroup = function(self, bs)
	local show = bs and #bs > 0
	-- self:showRotHint(show)
	-- self:showMovHint(show)

	if not self.enableOpenLib then return end

	self.ui.lockbutton.visible = false
	self:setDelVisable(show)
	self.ui.graffiti_del.visible = false
	self.ui.copybutton.visible = false
	self.ui.bottombg.visible = false

	self:showFrequent(not show)
	-- if show then
	-- 	local enablefilters = self:getRepairShapeFilter()
	-- 	self.ui.copybutton.disabled = not enablefilters[b:getShape()]
	-- end
end

BuildBrick.updateRepairPro = function(self)
	if not self.mode == 'repair' then return end
	local pro = self.ui.repairpro

	local cur, max = 0, 0
	for b in pairs(self.repair_dels) do
		max = max + 1
		if b.repairGroup then
			cur = cur + 1
		end
	end

	pro.cur.text = cur
	pro.max.text = max
end

local checkab = _AxisAlignedBox.new()
BuildBrick.getRepairCollfunc = function(self)
	local type = Global.dir2AxisType(Global.DIRECTION.UP, Global.AXISTYPE.Z)

	-- 扩展测试包围盒，防止物件落在修复物品后面
	local nbs = {}
	self:getBlocks(nbs, function(b)
		return not self.repair_adds[b]
	end)
	Block.getAABBs(nbs, checkab)

	local l = 2
	if type == Global.AXISTYPE.X then
		checkab.max.x = checkab.max.x + l
	elseif type == Global.AXISTYPE.Y then
		checkab.max.y = checkab.max.y + l
	elseif type == Global.AXISTYPE.NX then
		checkab.min.x = checkab.min.x - l
	elseif type == Global.AXISTYPE.NY then
		checkab.min.y = checkab.min.y - l
	end

	local checkCollision = function(checkbox, flag)
		if checkab:checkIntersect(checkbox) then
			return true
		end

		return self.sen:boxPick(checkbox, flag)
	end

	return checkCollision
end

BuildBrick.ondown_editrepair = function(self, x, y)
	if self.repair_disabled then return end
	local b, pos = self:pickBlock(x, y)

	if b then
		if self.mode == 'buildrepair' then
			local g = b:getBlockGroup('root')
			if self.repair_dels[g] then
				if g.repairGroup then
					local rg = g.repairGroup
					self:bindDelRepair(g, nil)
					b = rg:getFirstBrick()
				end
			elseif self.repair_adds[g] then
			else
				local n = 0
				for _ in pairs(self.repair_dels) do
					n = n + 1
				end
				local addg = self:createAddRepair(g)
				self:setDelRepair(g, n + 1)
				b = addg:getFirstBrick()
			end
		elseif self.mode == 'repair' then
			local g = b:getBlockGroup('root')
			if self.repair_dels[g] then
				b = nil
				-- if g.repairGroup then
				-- 	local rg = g.repairGroup
				-- 	self:bindDelRepair(g, nil)
				-- 	b = rg:getFirstBrick()
				-- end
			elseif self.repair_adds[g] then
			else
				if b:hasPickFlag(Global.CONSTPICKFLAG.PHYSICALBLOCK) then
					b.node.visible = false
				end

				b = nil
			end
		end

		self:cmd_select_begin(b, pos)
	else
		self:cmd_select_begin()
	end
end

BuildBrick.onmove_editrepair = function(self, x, y)
	if self.repair_disabled then return end

	self:building_moveBegin(x, y)

	if not self.rt_moving then return end

	self.movedx, self.movedy = self.mdx, self.mdy
	self:moveBlock(x, y)

	return true
end

BuildBrick.playRepairPfx = function(self, mode, b)
	if mode == 'success' then
	elseif mode == 'failed' then
	elseif mode == 'bomb' then
		local pfxplayer = self.sen.pfxPlayer
		local mat = _Matrix3D.new()
		mat:setTranslation(0, 0, 0)
		mat:setScaling(0.4, 0.4, 0.4)
		pfxplayer:play('ui_puzzle_rocket_boom_01.pfx', mat)
	elseif mode == 'fixall' then
		local pfxplayer = self.sen.pfxPlayer

		local maxh = 0
		for g in pairs(self.repair_dels) do
			local aabb = g:getAABB()
			maxh = math.max(maxh, aabb.max.z)
		end
		local mat = _Matrix3D.new()
		mat:setTranslation(0, 0, maxh - 1)
		pfxplayer:play('yanhua01.pfx', mat)
	end
end

BuildBrick.onRepairOperate = function(self, g, success)
	if success then
		self:playRepairPfx('success')

		local rg = g.repairGroup
		local bs = {}
		rg:getBlocks(bs)
		for i, b in ipairs(bs) do
			b.oldmtl = b:getMaterial()
			b:setMaterial(Global.MtlBuildCorrect)
			b.node.mesh.material:useLerpState(2)
			b.node.instanceGroup = 'blink'
		end

		self.timer:start('repairmtl', 600, function()
			for i, b in ipairs(bs) do
				b:setMaterial(b.oldmtl)
				b.oldmtl = nil
				b.node.instanceGroup = ''
			end

			self.timer:stop('repairmtl')
		end)
	else
		self:playRepairPfx('failed')
	end
end

BuildBrick.onup_editrepair = function(self, x, y, dbclick)
	if self.repair_disabled then
		self:cmd_select_end()
		self:building_moveEnd(x, y)
		return
	end

	local repaired = self:checkRepaired()
	if self.rt_selectedGroups[1] then
		if repaired then
			self.comboCount = self.comboCount + 1
			self:onRepairOperate(self.rt_selectedGroups[1], true)
		else
			self.comboCount = 0
			self:onRepairOperate(self.rt_selectedGroups[1], false)
		end
	end

	-- print('self.comboCount', self.comboCount)

	-- 长按的结束, 结束时直接认为下次是单击
	local selected = self:cmd_select_end()
	local ret = self:building_moveEnd(x, y)

	local showvic = repaired and self:onCheckRepair(true)
	if ret then
		-- 修复模式下如果当前物件已拼好，取消选中
		local g = self.rt_selectedGroups and self.rt_selectedGroups[1]
		if self.mode == 'repair' and g and self.repair_adds[g] and repaired then
			self:atom_select()
		end

		return true
	elseif (selected == 0 or selected == 1) and self.last_selected == self.rt_block then
		-- 双击同一块, 点到块上呼出材质和旋转，点击空白 呼出 积木库
		if dbclick then
			if #self.rt_selectedBlocks > 0 then
				-- self:showPropList(true)

				-- local ab = Container:get(_AxisAlignedBox)
				-- Block.getAABBs(self.rt_selectedBlocks, ab)
				-- self:camera_focus(ab, 1.5)
			else
				if not self.enableOpenLib then return end

				Tip()

				local enablefilters = self:getRepairShapeFilter()
				local showfilters = {}
				local disablefilters = {}

				for g in pairs(self.repair_dels) do
					local b = g:getFirstBrick()
					local shape = b:getShape()
					showfilters[shape] = true

					if not enablefilters[shape] then
						disablefilters[shape] = true
					end
				end

				local callback = function()
					self.ui.visible = false
					local params = {showfilters = showfilters, disablefilters = showfilters}
					self:showBricksUI(params)
				end
				_G:holdbackScreen(self.timer, callback)
			end
		end
	end

	self.last_selected = self.rt_block

	return false
end