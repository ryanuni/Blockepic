local Container = _require('Container')

local BlockBrawlPlayer = {}
_G.BlockBrawlPlayer = BlockBrawlPlayer

BlockBrawlPlayer.EDGE = {
	GREEN = 1,
	RED = 2,
	BLUE = 3,
}

BlockBrawlPlayer.RANK_TEXT = {
	'1st',
	'2nd',
	'3rd',
	'4th',
}

BlockBrawlPlayer.edges_color = {
	'ui_puzzle_green.pfx',
	'ui_puzzle_red.pfx',
	'ui_puzzle_blue.pfx',
}

local BBKs = {}
local newindex = function(t, k, v)
	BBKs[k] = true

	rawset(t, k, v)
end

BlockBrawlPlayer.new = function(cha, sen, name, bgindex, ismain)
	local bbplayer = {}
	--setmetatable(bbplayer, {__index = BlockBrawlPlayer})
	setmetatable(bbplayer, {__index = BlockBrawlPlayer, __newindex == newindex})

	bbplayer.cha = cha
	bbplayer.bbrole = BlockBrawlRole.new(cha)
	bbplayer.sen = sen
	bbplayer.buildbrick = BuildBrick.new()
	local index = (Global.BlockBrawl.datas and #Global.BlockBrawl.datas or 0) + 1
	if bgindex then
		index = bgindex
	end
	bbplayer.bgTexture = _Image.new(Global.RepairBGTextures[index], false, true)
	bbplayer.name = name

	-- game logic
	bbplayer.maxrepairs = 5
	bbplayer.currepairs = 0
	bbplayer.ismain = ismain or false
	bbplayer.isFinished = false
	bbplayer.playpropfx = false
	bbplayer.switchLevel = false
	bbplayer.disbaleRender = false

	bbplayer.timer = _Timer.new()
	-- if ismain then
	-- 	bbplayer.sen.showPhysics = true
	-- end

	local gd = {}
	gd.index = 1
	gd.repairs = {}
	gd.energy = 0
	gd.energyMode = 1
	gd.comboCount = 0
	gd.lanchStarIndex = 1
	bbplayer.gameData = gd

	return bbplayer
end

BlockBrawlPlayer.destory = function(self)
	if self.timer then
		self.timer:stop()
	end

	if self.buildbrick then
		self.buildbrick:onDestory()
		self.buildbrick = nil
	end

	self.cha:release()

	for k in pairs(BBKs) do
		self[k] = nil
	end
end

BlockBrawlPlayer.getRole = function(self)
	return self.cha
end

BlockBrawlPlayer.getBB = function(self)
	return self.buildbrick
end

BlockBrawlPlayer.getDB = function(self)
	return self.db
end

BlockBrawlPlayer.isFinish = function(self)
	return self.isFinished
end

BlockBrawlPlayer.getGameData = function(self)
	return self.gameData
end

BlockBrawlPlayer.playAnima = function(self, anima)
	if not self.cha then return end
	self.cha:playAnima(anima)
end

BlockBrawlPlayer.showFobbidance = function(self, t)
	if not self.ismain then return end
	local ui = self.ui.picload.fobbiden
	if t and t > _now() then
		self.buildbrick:disabledRepair(true)
		ui.time.text = string.ftoTimeFormat((t - _now()) / 1000 * 60)
		ui.visible = true
		self.fobbidtime = t
	else
		self.buildbrick:disabledRepair(false)
		ui.visible = false
		self.fobbidtime = nil
	end
end

BlockBrawlPlayer.setEnergyOpt = function(self, opt, rate)
	local gd = self:getGameData()
	if opt == 1 then -- 发射火箭
		gd.energyMode = 1
		gd.comboCount = 0
		gd.energy = 0
		gd.lanchStarIndex = gd.index -- TODO:
		self:playAnima('laugh2')

		self.buildbrick:clearComboCount()
		--self:updateEnergyUI()
	elseif opt == 2 then -- 被爆炸
		gd.energyMode = 1
		gd.comboCount = 0
		self.buildbrick:clearComboCount()
		if gd.energy ~= 100 then
			gd.energy = toint(gd.energy * rate, 0)
		end
		self:playAnima('liedown')
		--self:updateEnergyUI()
	end
end

BlockBrawlPlayer.updateEnergy = function(self)
	local gd = self:getGameData()
	local bb = self:getBB()

	local combo1 = gd.comboCount
	local combo2 = bb:getComboCount()
	--print('updateEnergy', combo1, combo2)

	local comboCounts = {0, 3, 6}
	local comboEnergys = {10, 15, 20}
	if combo2 == combo1 then
		-- 无效操作
		return false
	elseif combo2 == 0 then
		-- 放置错误
		gd.comboCount = 0
		gd.energyMode = gd.energy == 100 and #comboCounts + 1 or 1
		return true
	end

	gd.comboCount = combo2
	for m = #comboCounts, 1, -1 do
		local n = comboCounts[m]
		if combo2 >= n then
			local energy = gd.energy
			gd.energy = math.min(gd.energy + comboEnergys[m], 100)
			if gd.energy == 100 and energy ~= 100 and self.ismain then
				Global.Sound:play('blockbrawl_energyfull')
			end
			gd.energyMode = gd.energy == 100 and #comboCounts + 1 or m
			break
		end
	end

	return true
end

BlockBrawlPlayer.updateGameData = function(self, gd)
	if not self.ui then return end
	if gd then
		self.gameData = gd
	else
		gd = self.gameData
	end

	local ui = self.ui
	ui.rocketprocess.maxValue = 100
	ui.rocketprocess.currentValue = gd.energy

	if self.ismain then
		local step = (100 - gd.energy) / 100 * ui.rocketprocess._height
		ui.rocket._y = ui.rocketprocess._y + step - ui.rocket._height / 2
	end
end

BlockBrawlPlayer.updateRepairs = function(self, gs)
	if not gs and #gs == 0 then return end
	for _, g in pairs(gs) do
		self:setBlockRepaired(g)
	end
end

BlockBrawlPlayer.enterRepair = function(self, repair, creator)
	if not repair or not self.buildbrick then return end

	self.buildbrick:init(self.sen, nil, 'repair')
	-- self.buildbrick:initCamera()
	self:loadRepair(repair)
	-- local ground_node = self.sen:getNode('ground')
	-- ground_node.actor = self.sen:addActor(_PhysicsActor.Cube)
	-- ground_node.actor.shapeSize = _Vector3.new(100,100,1)
	-- ground_node.mesh.isInvisible = true

	local c = self.buildbrick:getCameraControl()
	--self:updateGameData(self:getGameData())
	self:updateProcessUI()

	if self.ismain == false then
		self.buildbrick:setDelRepairVisible(false)
	end

	if self.ismain then
		self.curcreatorui.name.text = creator
		self.curcreatorui.visible = creator ~= nil
	end
end

BlockBrawlPlayer.loadRepair = function(self, repair)
	self.buildbrick:load_block_only(repair)

	-- 调整摄像机
	local cc = self.buildbrick:getCameraControl()

	local nbs = {}
	self.buildbrick:getBlocks(nbs)
	local aabb = Container:get(_AxisAlignedBox)
	Block.getAABBs(nbs, aabb)
	--cc:lockZ((aabb.min.z + aabb.max.z) / 2)
	cc:moveLook(_Vector3.new(0, 0, (aabb.min.z + aabb.max.z) / 2))

	-- print('cc.camera0', cc.camera.radius)
	cc:scale(4)
	cc:update()
	-- print('cc.camera', cc.camera.radius, cc.camera, _rd.camera)
	local r = calcCameraRadius(cc.camera, aabb, self.db)
	r = r + 1
	cc:scale(r)
	cc:update()
	-- print('cccccc', r, cc.camera.radius, cc.camera, _rd.camera)
	Container:returnBack(aabb)
end

BlockBrawlPlayer.changeRepair = function(self, repair, creator, t, cb)
	if self.currepairs >= self.maxrepairs then return end

	local showcreator = creator ~= nil
	if not t then t = 0 end
	if self.ismain then
		Global.Sound:play('blockbrawl_win')
	end

	self.timer:start('changerepair', t, function()
		self:loadRepair(repair)

		self.currepairs = self.currepairs + 1
		self.playpropfx = true
		self.gameData.index = self.currepairs + 1
		self.buildbrick:setComboCount(self.gameData.comboCount)
		self:updateProcessUI()

		if not self.ismain then
			self.buildbrick:setDelRepairVisible(false)
		end

		if self.ismain then
			self:resetMainUI()
			self.curcreatorui.name.text = creator
			self.curcreatorui.visible = showcreator

			-- 切换DB后先画一帧
			self:render()
			self.disableRender = true
		end

		self.switchLevel = true
		if cb then
			cb()
		end
		self.timer:stop('changerepair')
	end)
end

BlockBrawlPlayer.showEdge = function(self, eindex, t)
	if not t then
		if self.timer then
			self.timer:stop('showedge')
		end
	end

	if self.ismain then
		self.ui.picload.edge:playPfx(self.edges_color[eindex], 0, 560, 20, 20)
	else
		self.ui.picload.edge:playPfx(self.edges_color[eindex], 0, 180, 10, 10)
	end
end

BlockBrawlPlayer.resetDBSize = function(self, w, h)
	if not self.db then return end
	if self.db.w == w and self.db.h == h then return end
	-- self.db.w = w
	-- self.db.h = h
	self.db:resize(w, h)

	self.db.bgDrawRect = _Rect.new(0, 0, w, h)

	if self.ismain and self.db2 then
		-- self.db2.w = w
		-- self.db2.h = h
		self.db2:resize(w, h)

		self.db2.bgDrawRect = _Rect.new(0, 0, w, h)
	end
end

BlockBrawlPlayer.update = function(self, e)
	self:updateMainUI()

	if self.fobbidtime then
		if self.fobbidtime > _now() then
			local ui = self.ui.picload.fobbiden
			ui.time.text = string.ftoTimeFormat((self.fobbidtime - _now()) / 1000 * 60)
		else
			self.fobbidtime = nil
			self:showFobbidance()
		end
	end
end

BlockBrawlPlayer.render = function(self, e)
	if not self.buildbrick.sen or self.disableRender then return end

	local current = Global.CameraControl:get()
	local c = self.buildbrick:getCameraControl()
	Global.CameraControl:set(c)

	self.buildbrick.sen:update()
	self.buildbrick.sen:useRDSetting()
	_rd:useDrawBoard(self.db, _Color.Null)
	self.buildbrick.sen:render()
	_rd:resetDrawBoard()

	Global.CameraControl:set(current)
end

BlockBrawlPlayer.loadUI = function(self, ui)
	if not ui then return end
	if ui._width == 0 or ui._height == 0 then return end
	if not self.db then
		self.db = _DrawBoard.new(ui._width, ui._height)
		self.db.bgTexture = self.bgTexture
		self.db.bgDrawRect = _Rect.new(0, 0, ui._width, ui._height)
		self.db.postProcess = _rd.postProcess:clone()

		if self.ismain then
			self.db2 = _DrawBoard.new(ui._width, ui._height)
			self.db2.bgTexture = self.bgTexture
			self.db2.bgDrawRect = _Rect.new(0, 0, ui._width, ui._height)
			self.db2.postProcess = _rd.postProcess:clone()
		end
	end
	self.ui = ui
	self.isSwitch = false
	self:resetDBSize(ui._width, ui._height)
	if self.ismain then
		ui.picload.pic1:loadMovie(self.db)
		ui.picload.pic2:loadMovie(self.db2)
		self.curcreatorui = ui.picload.creator1
	else
		ui.picload.pic:loadMovie(self.db)
	end

	ui.picload.edge._icon = nil
	local roleui = ui.role
	self.bbrole:loadUI(roleui)
	self:updateProcessUI()
	self:updateGameData()

	ui.rolename.text = self.name and ' ' .. self.name or ''
	ui.rolename.edgePower = 5

	self.ui.picload.fobbiden.time.edgePower = 100
end

BlockBrawlPlayer.switchDB = function(self)
	if self.ismain == false then return end
	self.isSwitch = not self.isSwitch
	local tmpdb = self.db
	self.db = self.db2
	self.db2 = tmpdb
	self.curcreatorui = self.isSwitch and self.ui.picload.creator2 or self.ui.picload.creator1
	tmpdb = nil
end

BlockBrawlPlayer.resetMainUI = function(self)
	if self.ismain == false then return end
	local ui1 = self.ui.picload.pic1
	local ui2 = self.ui.picload.pic2
	local cui1 = self.ui.picload.creator1
	local cui2 = self.ui.picload.creator2

	local div = 10
	-- 排序重置
	local onefisrt = ui1._x == 0
	if onefisrt then
		ui1._x = 0
		ui2._x = ui1._width + div
		cui1._x = 48
		cui2._x = cui1._x + ui1._width + div
	else
		ui2._x = 0
		ui1._x = ui2._width + div
		cui2._x = 48
		cui1._x = cui2._x + ui2._width + div
	end

	self.mainuistep = 0

	self:switchDB()
end

BlockBrawlPlayer.updateMainUI = function(self)
	if self.ismain == false or self.switchLevel == false then return end
	local ui1 = self.ui.picload.pic1
	local ui2 = self.ui.picload.pic2
	local cui1 = self.ui.picload.creator1
	local cui2 = self.ui.picload.creator2

	local time = 30
	local step = math.ceil((ui1._width + 10) / time)
	if self.mainuistep + step > ui1._width + 10 then
		step = ui1._width + 10 - self.mainuistep
		self.disableRender = false
		self.switchLevel = false
	end

	ui1._x = ui1._x - step
	ui2._x = ui2._x - step
	cui1._x = cui1._x - step
	cui2._x = cui2._x - step
	self.mainuistep = self.mainuistep + step
end

BlockBrawlPlayer.updateProcessUI = function(self)
	if not self.ui then return end
	local proui = self.ui.process
	for i = 1, self.maxrepairs do
		if i <= self.currepairs then
			proui['level' .. i]._icon = 'img://green_pro.png'
			if self.playpropfx and i == self.currepairs then
				proui['level' .. i]:playPfx('ui_puzzle_stage_01.pfx', -1, -1, 0.25, 0.25)
			end
		else
			proui['level' .. i]._icon = 'img://white_pro.png'
		end
	end
end

BlockBrawlPlayer.setBlockRepaired = function(self, gindex)
	local bb = self.buildbrick

	local addg, delg = bb:getRepairGroupByIndex(gindex)
	if addg and delg then
		bb:bindAddRepair(addg, delg)
	end
end

BlockBrawlPlayer.showVictory = function(self, rank, time)
	if self.isFinished then return end
	-- print('showVictory', rank, time, self.name, debug.traceback())
	self.currepairs = self.maxrepairs
	self.playpropfx = true
	self:updateProcessUI()
	self:showEdge(self.EDGE.BLUE)
	self:playAnima('applause')

	if self.ismain then
		Global.Sound:play('repair_win')
	end

	local ui = self.ui.picload.victory

	if rank then
		ui.rank._icon = 'img://' .. self.RANK_TEXT[rank] .. (self.ismain and '_big' or '') .. '.png'
	end

	if time then
		local min = math.floor(time / 60)
		local sec = time - min * 60
		ui.finishtime.text = string.format('%02d:%02d', min, sec)
		ui.finishtime.edgePower = 5
		ui.finishtime.visible = true
	else
		ui.finishtime.visible = false
	end

	ui.visible = true
	self.isFinished = true
	self.finishTick = _now()

	if self.ismain then
		self.timer:start('disableLaunch', 5000, function()
			Global.BlockBrawl:updateLaunchBtn('disabled')

			self.timer:stop('disableLaunch')
		end)
	end
end

BlockBrawlPlayer.onDown = function(self, b, x, y)
	_rd:usePickBoard(0, 0, self.db.w, self.db.h)
	self.buildbrick:onDown(b, x, y)
	_rd:resetPickBoard()
end

BlockBrawlPlayer.onMove = function(self, x, y, fid, count)
	_rd:usePickBoard(0, 0, self.db.w, self.db.h)
	self.buildbrick:onMove(x, y, fid, count)
	_rd:resetPickBoard()
end

BlockBrawlPlayer.onUp = function(self, b, x, y, fid, count)
	_rd:usePickBoard(0, 0, self.db.w, self.db.h)
	self.buildbrick:onUp(b, x, y, fid, count)
	_rd:resetPickBoard()
end