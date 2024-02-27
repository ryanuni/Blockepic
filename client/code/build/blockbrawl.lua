local BlockBrawl = {}
Global.BlockBrawl = BlockBrawl

BlockBrawl.init = function(self, sen, players, seed, countdown_second)
	self.started = false
	self.ui = self.ui or Global.UI:new('BlockBrawl.bytes')
	self.sen = sen

	-- 清空背景场景积木块
	if sen then
		sen:delAllBlocks()
	end

	local me = {avatarid = 0}
	local prs = {}

	-- 仅供测试使用
	if not players then
		table.insert(prs, {aid = 'template_beard'})
		table.insert(prs, {aid = 'template_astronaut'})
		table.insert(prs, {aid = 'template_boringape'})
	else
		for i, player in pairs(players) do
			if Global.Login:isMe(player.aid) then
				me = player
				me.index = i
			else
				player.index = i
				table.insert(prs, player)
			end
		end
	end

	local mainrole = Global.Character.new({
		id = Global.Login:getAid(),
		avatarid = me.avatarid,
		pos = {x = 0, y = 0, z = 0},
		dir = {x = 0, y = -1, z = 0},
	}, 'dress_avatar')
	mainrole:delFromScene()

	local mine = BlockBrawlPlayer.new(mainrole, CreateSceneInstance('repair.sen'), me.name, me.index, true)
	self.mainPlayer = mine
	self.mainBB = mine:getBB()
	local datas = {}
	local data = {player = mine, aid = Global.Login:getAid(), changed = true}
	table.insert(datas, data)
	self.datas = datas
	self.readyLauching = false
	self.randomseed = seed
	self.countdown_second = countdown_second

	self.timer = _Timer.new()

	-- TODO: 默认4个玩家
	for _, p in pairs(prs) do
		self:addPlayer(p)
	end

	self:initUI()

	self:initGame_sub1()

	if sen then
		sen:useRDSetting()
	end
end

BlockBrawl.initUI = function(self)
	if not self.datas or #self.datas < 4 then return end
	self.mainPlayer:loadUI(self.ui.player0)

	for i = 2, 4 do
		local pd = self.datas[i]
		local player = pd.player
		if player then
			local ui = self.ui['player' .. (i - 1)]
			player:loadUI(ui)

			ui.aim.visible = false
			ui.aim.click = function()
				local gd = self.mainPlayer:getGameData()
				local data = {}
				data.startIndex = gd.lanchStarIndex
				data.boxn = math.min(gd.index - gd.lanchStarIndex + 1, 3)
				data.aid = Global.Login:getAid()
				data.toaid = pd.aid
				Global.Sound:play('blockbrawl_rocket_launch')

				local datas = {act = 'BlocbBrawl_bomb', data = data}
				Global.Room_New:DoOp(datas)
				self.readyLauching = false
				self:updateLaunchState()
			end
		end
	end

	self:updateEnergyUI()

	local combo_ui = self.mainPlayer.ui.combo
	local repair_ui = self.ui.repairpro
	local back_ui = self.ui.back
	back_ui.visible = true
	back_ui.click = function()
		if self.isFinished == false then
			Global.Room_New:DoOp({act = 'quit', data = {}})
		end

		Global.Room_New:Leave()
		Global.entry:back(function()
			Global.SwitchControl:set_freeze_on()
			if self.currentRankData[1] then
				Global.BlockBrawlEntry:updateScoreUI(self.currentRankData)
			else
				Global.BlockBrawlEntry:updateMatchUI()
				Global.BlockBrawlEntry:camera_focus(false)
			end
		end)
	end

	local launch_ui = self.ui.launch
	launch_ui.click = function()
		self.readyLauching = not self.readyLauching
		self:updateLaunchState()
	end

	combo_ui.visible = true
	repair_ui.visible = false
	back_ui.visible = true
	launch_ui.visible = true
end

BlockBrawl.doOperation = function(self, data)
	if not data then return end
	-- print('doOperation', data.act, table.ftoString(data))
	local act = data.act
	if act == 'updateRepairs' then
		self:updateRepairedBlocks(data)
	elseif act == 'nextRepair' then
		self:changeRepairLevel(data)
	elseif act == 'BlocbBrawl_bomb' then
		self:doOperation_bomb(data)
	elseif act == 'BlocbBrawl_bomb_disable' then
		self:doOperation_bomb_disable()
	elseif act == 'BlocbBrawl_bomb_enable' then

	elseif act == 'finish' then
		self:doOperation_finish(data)
	end
end

------------------ Update other players state functions ---------------------------------
BlockBrawl.updateRepairedBlocks = function(self, data)
	if not data then return end
	local rdata = data.data

	-- local pdata = self.datas[2]
	local pdata = self:getPlayerDataByAid(rdata.aid)
	if pdata and rdata then
		local player = pdata.player
		player:updateRepairs(rdata.repairgs)
		player:updateGameData(rdata.gameData)
		player:playAnima('nod')
		player:showEdge(BlockBrawlPlayer.EDGE.GREEN, 300)
		pdata.changed = true
	end
end

BlockBrawl.changeRepairLevel = function(self, data)
	if not data then return end
	local rdata = data.data

	-- local pdata = self.datas[2]
	local pdata = self:getPlayerDataByAid(rdata.aid)
	if pdata and rdata then
		local player = pdata.player
		local index = rdata.currepair
		local repair = self:getGameRepairName(index)
		if repair then
			player:changeRepair(repair.file, repair.creator, 3000)
			pdata.changed = true
			-- self:updateEnergyUI()
		end
	end
end

BlockBrawl.doOperation_finish = function(self, data)
	if not data then return end
	local rdata = data.data

	-- local pdata = self.datas[2]
	local pdata = self:getPlayerDataByAid(rdata.aid)
	if pdata then
		local player = pdata.player
		rdata.name = player.name
		player:showVictory(rdata.rank, rdata.time_second)
	end

	self.currentRankData[rdata.rank] = rdata

	if self.readyLauching then
		self:updateLaunchState()
	end
end
---------------------------------------------------------------------------------------

BlockBrawl.updateAimPos = function(self, x, y)
	local p = self.ui:global2Local(x, y)
	local aimui = self.ui.aimrocket
	aimui._x, aimui._y = p.x - aimui._width / 2, p.y - aimui._height / 2
end

BlockBrawl.showAimedPfx = function(self, pd, show)
	local player = pd.player
	local bb = player:getBB()
	local pfxplayer = bb.sen.pfxPlayer
	if show then
		local mat = _Matrix3D.new()
		mat:setScaling(0.4, 0.4, 0.4)
		pfxplayer:play('ui_puzzle_front_sight_01.pfx', 'ui_puzzle_front_sight_01.pfx', mat)
	else
		pfxplayer:stop('ui_puzzle_front_sight_01.pfx', true)
		pd.changed = true
	end
end

BlockBrawl.updateLaunchBtn = function(self, mode)
	local uis = {'rocket0', 'rocket1', 'rocket2', 'rocket3', 'cancel'}
	local btn = self.ui.launch
	for i, v in ipairs(uis) do
		btn[v].visible = false
	end
	btn.disabled = false

	if mode == 'disabled' then
		btn.rocket0.visible = true
		btn.disabled = true
		btn.mode = 'disabled'

		if self.launchpfx then
			self.launchpfx:stop(true)
			self.launchpfx = nil
		end

		if self.readyLauching then
			self.readyLauching = false
			self:updateLaunchState()
		end
	elseif mode == 'cancel' then
		btn.cancel.visible = true
		btn.mode = 'cancel'
		if self.launchpfx then
			self.launchpfx:stop(true)
			self.launchpfx = nil
		end
	else
		--self.ui_puzzle_rocket_button_01
		local gd = self.mainPlayer:getGameData()
		local boxn = math.min(gd.index - gd.lanchStarIndex + 1, 3)
		local newmode = 'rocket' .. boxn
		btn[newmode].visible = true
		if btn.mode ~= newmode and btn.mode ~= 'cancel' then
			btn:playPfx('ui_puzzle_rocket_button_01.pfx', -4, -4, 2, 2, 2)
		end

		if not self.launchpfx then
			self.launchpfx = btn:playPfx('ui_puzzle_rocket_button_02.pfx', -4, -4, 2, 2, 2)
		end

		btn.mode = newmode
	end
end

BlockBrawl.updateLaunchState = function(self)
	if self.readyLauching then
		local n = 0
		for i, pd in ipairs(self.datas) do
			local player = pd.player
			if not player.ismain then
				if not player:isFinish() then
					n = n + 1

					if not player.ui.aim.visible then
						self:showAimedPfx(pd, true)
					end
				end

				player.ui.aim.visible = not player:isFinish()
			end
		end

		Global.BlockBrawl:updateLaunchBtn('cancel')

		-- 没有目标可选，取消发射
		if n == 0 then
			self.readyLauching = false
			self:updateLaunchState()
		end
	else
		for i, pd in ipairs(self.datas) do
			local player = pd.player
			if not player.ismain then
				if player.ui.aim.visible then
					self:showAimedPfx(pd, false)
				end
				player.ui.aim.visible = false
			end
		end

		Global.BlockBrawl:updateLaunchBtn()
	end

	self.ui.aimrocket.visible = self.readyLauching
	if self.readyLauching then
		local pos = _sys:getMousePos()
		self:updateAimPos(pos.x, pos.y)
	end
end

BlockBrawl.doOperation_bomb_disable = function(self, data)
	Notice(Global.TEXT.NOTICE_LUANCH_FAILED)
end

BlockBrawl.doOperation_bomb = function(self, data)
	if not data then return end
	local rdata = data.data

	local from = rdata.aid
	local myaid = Global.Login:getAid()
	-- self.lastlaunch_t = _now()

	-- 发射火箭端效果
	if from == myaid then
		self.mainPlayer:setEnergyOpt(1)
		self:updateEnergyUI()

		Global.Sound:play('blockbrawl_rocket_up')
		local bb = self.mainPlayer:getBB()
		local c = bb:getCameraControl()
		c.camera:shake(0.1, 0.2, 1000, _Camera.Quadratic)
	else
		local playerdata
		for i, pd in ipairs(self.datas) do
			if pd.aid == rdata.aid then
				playerdata = pd
			end
		end

		--player:updateGameData(rdata.gameData)

		Global.Sound:play('blockbrawl_rocket_up')
		local player = playerdata.player
		player.ui.rocketprocess.currentValue = 0
		player.ui:gotoAndPlay('launchrockt')

		local pfx = player.ui.launch:playPfx('ui_puzzle_rocket_smoke_01.pfx', 0, 0, 15, 15, 15, false, 'launchrockt', true)
		self.timer:start('stopRocketpfx', 2000, function()
			pfx:stop(true)
			self.timer:stop('stopRocketpfx')
		end)
		self.timer:start('resetRocket2', 6000, function()
			player.ui:gotoAndPlay('resetrocket')
			self.timer:stop('resetRocket2')
		end)

		if self.readyLauching then
			self.readyLauching = false
			self:updateLaunchState()
		end
	end

	-- 其他人的画面
	for i, pd in ipairs(self.datas) do
		--print('pd.aid ~= rdata.aid', i, rdata.toaid, pd.aid, rdata.aid, myaid, rdata.boxn)
		if pd.aid == rdata.toaid then
			local player = pd.player
			local bb = player:getBB()

			local isme = myaid == pd.aid
			if isme then
				-- TODO: camera shake
				-- self.disabledLaunch = true
				Global.ScreenEffect:showPfx('warning')
			end

			player:showEdge(BlockBrawlPlayer.EDGE.RED, 8000)
			--bb:disabledRepair(true)
			self:showAimedPfx(pd, true)
			pd.skipchanged = true

			local shaket = rdata.boxn == 1 and 6000 or rdata.boxn == 2 and 7000 or 8000
			self.timer:start('rocket_coming', 2000, function()
				if isme then
					Global.ScreenEffect:showPfx(false)
				end
				local c = bb:getCameraControl()
				if c then
					c.camera:shake(0.03, 0.05, shaket, _Camera.Quadratic)
				end

				self.timer:stop('rocket_coming')
			end)

			local fobbidt = shaket + _now()
			for ii = 1, rdata.boxn do
				local idx = ii
				local key = i .. '_bomb_' .. ii
				self.timer:start(key, 3000 + 500 * (ii - 1), function()
					if self.ui then
						-- 火箭到达后不显示特效
						if ii == rdata.boxn then
							self:showAimedPfx(pd, false)
						end

						if ii == 1 then
							local rate = rdata.boxn == 1 and 0.8 or rdata.boxn == 2 and 0.7 or 0.5
							player:setEnergyOpt(2, rate)
							--bb:disabledRepair(true)
							player:showFobbidance(fobbidt)
							if isme then
								-- 清空修复进度
								self.ui.repairpro.cur.text = 0
								self:updateEnergyUI()
							else
								-- bb:setDelRepairVisible(false)
								player:updateGameData()
							end
						end

						-- 拼完后bomb不影响已拼好的物件
						local bombindex = player:isFinish() and 0 or ii
						bb:blastRepaired('rocket', 10000, bombindex, isme, function()
							if not isme then
								bb:setDelRepairVisible(false)
							end
						end)
					end

					self.timer:stop(key)
				end)
			end

			self.timer:start('bombdone', shaket, function()
				player:playAnima('idle')
				pd.skipchanged = false
				self.timer:stop('bombdone')
			end)

			self.timer:start('disabledLaunch', 15000, function()
				pd.changed = true
				self.timer:stop('disabledLaunch')
			end)
		end
	end
end

BlockBrawl.playAnima = function(self, aid, anima)
	local data = self:getPlayerDataByAid(aid)
	if not data then return end
	data.player:playAnima(anima)
end

BlockBrawl.updateRepairLevel = function(self)
	if self.nextlevel == false or self.waitingEnter then return end
	if self.currepair == #self.gameRepairs then
		-- TODO: GAME OVER
		if self.isFinished == false then
			local data = {}
			data.aid = Global.Login:getAid()
			Global.Room_New:DoOp({act = 'finish', data = data})
			self.isFinished = true
		end
	else
		self.currepair = self.currepair + 1
		local repair = self:getGameRepairName(self.currepair)
		self.ui:gotoAndPlay('t0')
		if repair then self.mainPlayer:changeRepair(repair.file, repair.creator, 3000, function()
			BlockBrawl.waitingEnter = false
			BlockBrawl:updateRepairPro()
			BlockBrawl:updateEnergyUI(true)
		end) end
		self.waitingEnter = true

		local data = {}
		data.aid = Global.Login:getAid()
		data.currepair = self.currepair
		Global.Room_New:DoOp({act = 'nextRepair', data = data})
	end

	self.nextlevel = false
	self:updateRepairPro()
end

BlockBrawl.updateRepairPro = function(self)
	if not self.mainBB or self.waitingEnter then return end
	local max = self.mainBB:getTotalRepairCount()
	local cur = self.mainBB:getRepairedCount()
	local pro = self.ui.repairpro
	local curnum = tonumber(pro.cur.text)
	if curnum ~= cur then
		if Global.Room_New then
			local gs = self.mainBB:getRepairedGroups()
			local repairgs = {}
			for _, g in pairs(gs) do
				table.insert(repairgs, g.repairindex)
			end
			local data = {}
			data.aid = Global.Login:getAid()
			data.repairgs = repairgs
			data.gameData = self.mainPlayer:getGameData()
			Global.Room_New:DoOp({act = 'updateRepairs', data = data})
		end

		self.mainPlayer:playAnima('nod')
		self.mainPlayer:showEdge(BlockBrawlPlayer.EDGE.GREEN, 300)
	end
	pro.cur.text = cur
	pro.max.text = max
	self.nextlevel = cur == max
end

BlockBrawl.BlockBrawl_initLvs = function(self, repairs)
	local lv_repairs = {}
	for i = 1, #repairs do
		local rdata = self:getGameRepairName(i)
		local data = Block.loadItemData(rdata.file)

		table.insert(lv_repairs, data and #data.repair_dels or 0)
	end

	-- for i, v in ipairs(lv_repairs) do
	-- 	print('BlockBrawl_initLvs', i, v)
	-- end

	local datas = {act = 'BlocbBrawl_initLvs', data = lv_repairs}
	Global.Room_New:DoOp(datas)
end

BlockBrawl.initGame_sub1 = function(self)
-- TODO:测试用默认值
	local repairs = {}

	local seed = self.randomseed
	if not seed then
		-- repairs = {2, 5, 6, 1, 10}
		repairs = {2, 1, 1, 1, 2}

		--math.randomseed(_now())
		--local keys = {}
		--for i = 1, 5 do
		--	local rl, index = Global.randomNewRepairLevel(i, keys)
		--	table.insert(repairs, index)
		--end
	else
		math.randomseed(seed)

		local keys = {}
		for i = 1, 5 do
			local rl, index = Global.randomNewRepairLevel(i, keys)
			table.insert(repairs, index)
		end
	end

	self.currentRankData = {}
	self.gameRepairs = repairs
	self.currepair = 1
	for _, data in ipairs(self.datas) do
		local player = data.player
		local repair = _G.cfg_repair[1][repairs[self.currepair]]
		player:enterRepair(repair.file, repair.creator)
	end

	local c = self.mainPlayer:getBB():getCameraControl()
	Global.CameraControl:set(c)

	self:updateRepairPro()
	self.ui.repairpro.visible = true
	self.isFinished = false
	self.waitingEnter = false
	Global.Sound:play('bgm_blockbrawl_mixed')

	self.mainPlayer.buildbrick:disabledRepair(true)
	Global.Room_New:Ready()
end
BlockBrawl.initGame = function(self)
	Global.SwitchControl:set_freeze_off()
	self.started = true
	self.due = _now() + self.countdown_second * 1000

	self.mainPlayer.buildbrick:disabledRepair(false)

	self:BlockBrawl_initLvs(self.gameRepairs)
end

BlockBrawl.addPlayer = function(self, player)
	assert(#self.datas > 0)
	local aid = player.aid or (#self.datas + 1)
	local c = Global.Character.new({
		id = aid,
		avatarid = player.avatarid or 0,
		pos = {x = 0, y = 0, z = 0},
		dir = {x = 0, y = -1, z = 0},
	}, 'dress_avatar')

	c:delFromScene()
	local p = BlockBrawlPlayer.new(c, CreateSceneInstance('repair.sen'), player.name, player.index, false)
	local data = {player = p, aid = aid, changed = true}
	table.insert(self.datas, data)
end

BlockBrawl.getRepairName = function(self, level, index)
	return _G.cfg_repair[level][index]
end

BlockBrawl.getGameRepairName = function(self, index)
	if not index or not self.gameRepairs then return end
	local level = index
	return _G.cfg_repair[level][self.gameRepairs[index]]
end

BlockBrawl.onDestory = function(self)
	-- TODO: delete

	self.timer:stop()
	-- _rd.postEdgeOutOnly = false
	for i, data in ipairs(self.datas) do
		data.player:destory()
	end

	self.datas = nil
	if self.ui then
		self.ui:removeMovieClip()
		self.ui = nil
	end

	Global.Sound:stop()

	self.mainPlayer = nil
	self.mainBB = nil
	self.sen = nil
end

BlockBrawl.update = function(self, e)
	if not self.started then return end
	self:updateRepairLevel()

	for _, data in pairs(self.datas) do
		local player = data.player
		player:update(e)
	end
end

BlockBrawl.goBackShowRank = function(self, rank)
	if Global.GameState:isState('BLOCKBRAWL') then
		Global.Room_New:Leave()
		Global.entry:back(function()
			Global.SwitchControl:set_freeze_on()
			Global.BlockBrawlEntry:updateScoreUI(rank)
		end)
	else
		Global.SwitchControl:set_freeze_on()
		Global.BlockBrawlEntry:updateScoreUI(rank)
	end
end

BlockBrawl.showFinish = function(self, rank)
	self.due = nil
	local win = not rank[4] or rank[4].aid ~= Global.Login:getAid()

	for _, p in pairs(rank) do
		local type = p.type
		local pdata = self:getPlayerDataByAid(p.aid)
		if pdata then
			local player = pdata.player
			if type == 'quit' or type == 'timeout' then
				player:showVictory(p.rank)
			end
		end
	end
	Global.ScreenEffect:showPfx(win and 'youwin' or 'youlose', function()
		BlockBrawl:goBackShowRank(rank)
		Global.ScreenEffect:showPfx(false)
	end)
end

-- local bombscond = 15000
BlockBrawl.render = function(self)
	if self.due then
		local countdown = (self.due - _now()) / 1000
		self.ui.gametime.text = string.ftoTimeFormat(math.max(5 * 60 - countdown, 0))
		if countdown < -3 then
			self.due = nil
			Global.ScreenEffect:showPfx('youlose', function()
				self.ui.back.click()
				Global.ScreenEffect:showPfx(false)
			end)
		end
	end

	for i, data in ipairs(self.datas) do
		local player = data.player

		-- 其他人的图片只有内容改变时渲染
		if i == 1 or (data.changed or ((data.skipchanged or self.readyLauching) and CurrentFrame() % 3 == 0)) then
			player:render()
			data.changed = false
		end

		if player.bbrole then
			self.sen:useRDSetting()
			player.bbrole:render()
		end
	end

	Global.CameraControl:set(self.mainBB:getCameraControl())
end

BlockBrawl.getPlayerDataByAid = function(self, aid)
	if not self.datas then return end
	for _, data in ipairs(self.datas) do
		if data.aid == aid then
			return data
		end
	end
end

BlockBrawl.setBlockRepaired = function(self, aid, gindex)
	local data = self:getPlayerDataByAid(aid)
	if not data or not data.player then return end
	data.player:setBlockRepaired(gindex)
end

BlockBrawl.Global2MainDBPoint = function(self, x, y)
	local uiwin = self.ui.player0
	local p = uiwin:global2Local(x, y)
	local xscale = _rd.w / _rd:getResolution3DWidth()
	local yscale = _rd.h / _rd:getResolution3DHeight()
	local uw = uiwin._width * xscale
	local uh = uiwin._height * yscale
	if p.x > 0 and p.y > 0 and p.x < uw and p.y < uh then
		local db = self.mainPlayer:getDB()
		local dbx = p.x / uiwin._width * db.w
		local dby = p.y / uiwin._height * db.h
		return dbx, dby
	end
end

BlockBrawl.onDown = function(self, b, x, y)
	if not self.mainPlayer or not self.ui then return end

	local dx, dy = self:Global2MainDBPoint(x, y)
	if dx and dy then self.mainPlayer:onDown(b, dx, dy) end
end

BlockBrawl.onMove = function(self, x, y, fid, count)
	if not self.mainPlayer then return end

	local dx, dy = self:Global2MainDBPoint(x, y)
	if dx and dy then self.mainPlayer:onMove(dx, dy, fid, count) end
end

BlockBrawl.onPostmove = function(self, x, y, fid, count)
	if self.readyLauching then
		self:updateAimPos(x, y)
	end
end

BlockBrawl.onUp = function(self, b, x, y, fid, count)
	if not self.mainPlayer then return end

	local dx, dy = self:Global2MainDBPoint(x, y)
	if dx and dy then self.mainPlayer:onUp(b, dx, dy, fid, count) end

	if self.mainPlayer:updateEnergy() then
		self:updateEnergyUI()
		self:updateRepairPro()
	end
end

BlockBrawl.updateEnergyUI = function(self, onlyupdatebox)
	local gd = self.mainPlayer:getGameData()

	if not onlyupdatebox then
		local imgs = {'', 'combo.png', 'fever.png', 'breakout.png'}
		local ui = self.mainPlayer.ui
		local combo = ui.combo
		if gd.energyMode == 1 then
			combo.visible = false
		else
			combo.visible = true

			ui:gotoAndPlay('t1')
			combo:playPfx('ui_puzzle_combo.pfx')
			combo._icon = 'img://' .. imgs[gd.energyMode]
		end

		self.mainPlayer:updateGameData(gd)
	end

	if self.currentProgressValue ~= gd.energy then
		self.mainPlayer.ui.rocketprocess:playPfx('ui_puzzle_rocket_xp.pfx')

		if gd.energy == 100 then
			self.mainPlayer:playAnima('remember')
		end
	end
	self.currentProgressValue = gd.energy

	local boxn = gd.index - gd.lanchStarIndex + 1
	local finishtick = self.mainPlayer:isFinish() and self.mainPlayer.finishTick
	local disabled = boxn == 0 or gd.energy ~= 100 or (finishtick and _now() - finishtick < 5000)
	Global.BlockBrawl:updateLaunchBtn(disabled and 'disabled' or '')
end

local cameracontrol = {}
if _sys:isMobile() then
	cameracontrol.zoom = 2
end
Global.GameState:setupCallback({
	--addKeyDownEvents = kevents, -- 需要选择性添加
	onDown = function(b, x, y)
		Global.BlockBrawl:onDown(b, x, y)
	end,
	onMove = function(x, y, fid, count)
	--[[
		if _sys.os ~= 'win32' and _sys.os ~= 'mac' then
			if Global.BlockBrawl.downX and Global.BlockBrawl.downY then
				local dx = math.abs(x - Global.BlockBrawl.downX)
				local dy = math.abs(y - Global.BlockBrawl.downY)
				if dx < 20 and dy < 20 then
					return
				end
			end
		end
	--]]
		Global.BlockBrawl:onMove(x, y, fid, count)
	end,
	onUp = function(b, x, y, fid, count)
		if fid and Global.BlockBrawl.dragSelecting then
			return
		end

		Global.BlockBrawl:onUp(0, x, y)
	end,
	onClick = function(x, y)
		if _sys.os == 'win32' or _sys.os == 'mac' then
			Global.BlockBrawl:onUp(0, x, y)
		end
	end,
	--[[
	onTouchMultiMove = function(x, y, fid, count)
		if Global.BuildBrick.dragSelecting and count == 2 and fid == 0 then
			if _sys.os ~= 'win32' and _sys.os ~= 'mac' then
				if Global.BuildBrick.downX and Global.BuildBrick.downY then
					local dx = math.abs(x - Global.BuildBrick.downX)
					local dy = math.abs(y - Global.BuildBrick.downY)
					if dx < 20 and dy < 20 then
						return
					end
				end
			end
			--print('onMove2222', x, y, fid, count)
			Global.BuildBrick:onMove(x, y, fid, count)
		end
	end,
	onTouchMultiUp = function(x, y, fid, count)
		if Global.BuildBrick.dragSelecting and count == 2 then
			Global.BuildBrick:onUp(0, x, y, fid, count)
		end
	end,--]]
	cameraControl = cameracontrol,
},
'BLOCKBRAWL')

Global.GameState:onEnter(function(...)
	if _sys.os == 'win32' or _sys.os == 'mac' then
		Global.UI:changeDesignWH(1920, 1080)
	end
	Global.BlockBrawl:init(Global.sen, ...)
	_app:registerUpdate(Global.BlockBrawl, 7)
	_rd.oldShadowBias = 0.0001
	_app:onPostmove(function(x, y, fid, count)
		Global.BlockBrawl:onPostmove(x, y, fid, count)
	end)

end, 'BLOCKBRAWL')

Global.GameState:onLeave(function()
	Global.BlockBrawl:onDestory()
	_app:unregisterUpdate(Global.BlockBrawl)
	_rd.oldShadowBias = 0.0001
	if _sys.os == 'win32' or _sys.os == 'mac' then
		Global.UI:changeDesignWH(1920 * 2, 1080 * 2)
	end
end, 'BLOCKBRAWL')