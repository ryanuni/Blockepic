local Mario = {}
Global.Mario = Mario
Mario.timer = _Timer.new()

Mario.init = function(self, sen, players, mode)
	self.started = false
	self.tried = false
	self.sen = sen
	self.gamemode = mode or 'single'
	self.isSingle = self.gamemode == 'single'
	local me = {avatarid = 0}
	self.originz = self.sen.respawnpos.z
	self.mainPlayer = MarioPlayer.new(Global.role, me.name, 12)

	local datas = {}
	local data = {player = self.mainPlayer, aid = Global.Login:getAid(), changed = true}
	table.insert(datas, data)
	self.datas = datas

	Global.role.cct.enableControllerHit = false
	self:initGame()
	if sen then
		sen:useRDSetting()
	end

	Global.SwitchControl:set_input_off()
	if not self.isSingle then
		for i, v in ipairs(players) do
			self:addPlayer(v)
		end
		Global.role:set_on_change(function(pos, j)
			self:send_op('move', {
				dir = {
					x = pos.x,
					y = pos.y,
					z = pos.z
				},
				jump = j
			})
		end)
	end
end
Mario.send_op = function(self, act, data)
	Global.Room_New:DoOp({act = act, data = data})
end
Mario.initUI = function(self)
end

Mario.updateMainUI = function(self)
end

Mario.doOperation = function(self, data)
	if not data then return end
	local act = data.act
	if act == 'die' then
		if data.aid == Global.Login:getAid() then

		else
			local r = Global.EntityManager:get_role(data.aid)
			r:releaseCCT()
			r:playAnima('liedown')
		end
		-- self:doOperation_finish(data)
	elseif act == 'move' then
		local r = Global.EntityManager:get_role(data.aid)
		r:set_input(data.data)
	elseif act == 'input' then
--		print('====input', #data.data)
		for _, inputs in ipairs(data.data) do
			Global.FrameSystem:AddInput(inputs)
		end
	end
end

Mario.initGame = function(self)
	Global.dungeon:registerOverCallback(function()
		if Mario.isSingle then
			Mario:showFinish()
		end
	end)

	self.score = 0
end

Mario.prepare_to_start = function(self)
	self.timer:start('mario_start', 1, function()
		Global.ScreenEffect:showPfx('countdown')
		self.timer:stop('mario_start')
	end)
	local g = Global.Role.gravity_get()
	Global.Role.gravity_set(0)
	self.timer:start('prepare_to_start', 5000, function()
		Global.ScreenEffect:showPfx()
		Global.Role.gravity_set(g)
		Global.SwitchControl:set_input_on()
		Global.dungeon:start()
		self.started = true
		self.timer:stop('prepare_to_start')
	end)
end

Mario.addPlayer = function(self, player)
	if player.aid == Global.Login:getAid() then
		return
	end

	local r = Global.EntityManager:new_role(player)
	r.cct.position:set(Global.sen.respawnpos)
	r.cct.enableControllerHit = false
	r:updateFace(Global.sen.respawndir, 0)
	if Global.sen.setting.jumpLimit ~= nil then
		r:setJumpLimit(Global.sen.setting.jumpLimit)
	end
	if Global.sen.setting.needAcc ~= nil then
		r.logic.needAcc = Global.sen.setting.needAcc
	end

	local p = MarioPlayer.new(r, player.name)
	local data = {player = p, aid = player.aid, changed = true}
	table.insert(self.datas, data)
end

Mario.goBackShowRank = function(self, rank)
	if Global.GameState:isState('MARIO') then
		Global.Room_New:Leave()
		Global.entry:back(function()
			Global.MarioEntry:updateScoreUI(rank)
		end)
	else
		Global.MarioEntry:updateScoreUI(rank)
	end
end

local rank_str = {'1ST', '2ND', '3RD', '4TH'}
Mario.showFinish = function(self, rank)
	local win = false
	if rank then
		win = rank.rank < 4
	end

	self:updateMainUI()
	self.started = false

	if rank then
		rank.name = Global.Login:getName()
		rank.aid = Global.Login:getAid()
		self.rank = {[1] = rank}
	end

	Global.dungeon:over()
	Global.SwitchControl:set_input_off()
end

Mario.onDestory = function(self)
	-- TODO: delete

	for i, data in ipairs(self.datas) do
		data.player:destory()
	end

	self.datas = nil

	Global.Sound:stop()

	self.mainPlayer = nil
	self.mainBB = nil
	self.sen = nil

	Global.Role.animaStateClass = _dofile('anima.lua')
	_dofile('role_new_base.lua')
end
Mario.try_start = function(self)
	if self.tried then return end

	self.tried = true
	if self.isSingle then
		Global.Mario:prepare_to_start()
	else
		Global.InputSender:init()
		Global.FrameSystem:init()
		Global.Room_New:Ready()
	end
end
Mario.update = function(self, e)
	if not self.started then
		if Global.FrameSystem:GetFid() >= 3 then
			self:try_start()
		end
	end
	self:updateMainUI()
end

Mario.render = function(self)
end

Mario.update_single_record = function(self, s)
	Global.Room_New:Single_Record('Neverup_single', s)
end

local cameracontrol = {}
if _sys:isMobile() then
	cameracontrol.zoom = 2
end
Global.GameState:setupCallback({
	cameraControl = cameracontrol,
},
'MARIO')

Global.GameState:onEnter(function(...)
	Global.SwitchControl:set_input_off()
	Global.Mario:init(Global.sen, ...)
	Global.SwitchControl:set_cameracontrol_off()
	_app:registerUpdate(Global.Mario, 7)
	_rd.oldShadowBias = 0.0001
end, 'MARIO')

Global.GameState:onLeave(function()
	Global.SwitchControl:set_cameracontrol_on()
	Global.Mario:onDestory()
	_app:unregisterUpdate(Global.Mario)
	_rd.oldShadowBias = 0.0001
	Global.SwitchControl:set_input_on()
end, 'MARIO')