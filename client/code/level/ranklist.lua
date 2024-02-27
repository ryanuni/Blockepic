---------------------------------排行榜-----------------------------------
local leaderboard = {timer = _Timer.new()}

local Function = _require('Function')
local Container = _require('Container')

local loadBlockFunction = function(b, funcname)
	-- print('loadBlockFunction:', funcname)
	local data = _dofile(funcname)
	for i, v in ipairs(data or {}) do
		-- print(i, v)
		b:addFunction(Function.new(v))
	end
	b:loadActionFunctions(Global.sen)
	b:registerEvents()
	b:initEvents()
end

local RankBlocks = {
	brawl = {
		shape = 'Leaderboard1',
		blockname = 'rank',
		func = 'rank.func',
	},
	neverup = {
		shape = 'LeaderboardNever',
		blockname = 'neveruprank',
		func = 'neveruprank.func',
	},
}

leaderboard.initBlock = function(self)
	local cfg = RankBlocks[self.type]
	local block = Global.sen:getBlockByShape(cfg.shape)
	if not block then return end
	local meshes = _G.Block.getPaintMeshs(block.node.mesh)
	-- if #meshes < 2 then return end
	local m1 = meshes[1]
	-- local m2 = meshes[2]

	if self.block == block then
		return true
	end

	block:setName(cfg.blockname)
	loadBlockFunction(block, cfg.func)

	block.node.isShadowReceiver = false
	-- block.node.mesh.enableInstanceCombine = false
	-- block.node.mesh.material.isNoFog = true

	self.block = block

	m1.isInvisible = true
	-- m2.isInvisible = true

	-- m1.enableInstanceCombine = false
	-- m2.enableInstanceCombine = false

	local s = 7 / 4
	m1.transform:mulScalingLeft(s, s, 1)
	-- m2.transform:mulScalingLeft(s,s,1)

	_G.Block.getParentMesh(self.block.node.mesh, m1).isInvisible = true
	-- _G.Block.getParentMesh(self.block.node.mesh, m2).isInvisible = true

	if self.db then
		m1.material.diffuseMap = self.db
		m1.isInvisible = false
	end

	-- if self.fame_db then
	-- 	m2.material.diffuseMap = self.fame_db
	-- 	m2.isInvisible = false
	-- end

	m1.material.isAlpha = true
	m1.material.isDecal = true
	m1.material.isNoLight = true
	m1.material.isNoFog = true
	m1.material.isUseEnvironmentMap = false
	-- m1.material.isPBR = false

	-- m2.material.isAlpha = true
	-- m2.material.isDecal = true
	-- m2.material.isNoLight = true
	-- m2.material.isNoFog = true
	-- m2.material.isUseEnvironmentMap = false
	-- m2.material.isPBR = false

	self.mesh = m1
	-- self.fame_mesh = m2

	-- local fame_camera = Global.sen.graData:getCamera('brawl_rank')
	-- if not fame_camera then
	-- 	fame_camera = _Camera.new()
	-- 	fame_camera.eye = _Vector3.new(-5.4457,-9.5636,25.8392)
	-- 	fame_camera.look = _Vector3.new(-3.3846,-9.5467,26.2398)
	-- end
	-- self.fame_camera = fame_cam

	local cam = _Camera.new()
	cam.eye:set(Global.GameRankCameras.Rank.eye)
	cam.look:set(Global.GameRankCameras.Rank.look)

	local mat = block.node.transform
	mat:apply(cam.eye, cam.eye)
	mat:apply(cam.look, cam.look)

	self.camera = cam

	self.pfx1 = _Particle.new('wq_rongjie_xs.pfx')
	self.pfx2 = _Particle.new('wq_rongjie_cx.pfx')

	return true
end

leaderboard.init = function(self)
	if self.db then return true end
	if not self:initBlock() then return end

	self.db = _DrawBoard.new(700, 700)
	self.mesh.material.diffuseMap = self.db

	self.ui = {
		logo = {l = 0, t = 10, w = 700, h = 100},
		node = {
			l = 0, t = 5,
			w = 600, h = 50,
			icon = {l = 105, t = 5, w = 40, h = 40},
			myicon = {l = 100, t = 0, w = 50, h = 50},
			rank = {l = 100, t = 0, w = 50, h = 50},
			name = {l = 160, t = 0, w = 150, h = 50},
			data = {l = 300, t = 0, w = 250, h = 50},
			rank = {}
		},
	}

	self.font1 = _Font.new('Supersonic Rocketship', 25, 0, 0, 0, 0, true)
	self.font1.textColor = _Color.Black
	self.font2 = _Font.new('Supersonic Rocketship', 30, 0, 0, 3, 400)
	self.font2.textColor = _Color.Black
	self.font2.edgeColor = _Color.White
	self.font3 = _Font.new('Supersonic Rocketship', 35, 0, 0, 4, 400, true)
	self.font3.textColor = _Color.White
	self.font3.edgeColor = _Color.Black

	self.myfont1 = _Font.new('Supersonic Rocketship', 30, 0, 0, 0, 0, true)
	self.myfont1.textColor = _Color.Black
	self.myfont2 = _Font.new('Supersonic Rocketship', 35, 0, 0, 3, 400)
	self.myfont2.textColor = _Color.Black
	self.myfont2.edgeColor = _Color.White
	self.myfont3 = _Font.new('Supersonic Rocketship', 50, 0, 0, 5, 500, true)
	self.myfont3.textColor = 0xffffb700
	self.myfont3.edgeColor = _Color.Black

	self.rank_bg = _Image.new('rank_bg.png')
	self.myrank_bg = _Image.new('myrank_bg.png')

	self.rank_imgs = {
		_Image.new('rank_1.png'),
		_Image.new('rank_2.png'),
		_Image.new('rank_3.png'),
	}

	return true
end

-- data.my = { aid = 1, data = 0, rank = 1 }
-- data.ranks = { {}, {} }
leaderboard.drawnode = function(self, index, data)
	local isme = data.aid == Global.Login:getAid()
	local uinode = self.ui.node
	local l = uinode.l
	local t = uinode.t + uinode.h * (index + 1)
	local r = l + uinode.w
	local b = t + uinode.h
	local uiname = uinode.name
	local uidata = uinode.data
	local uiicon = uinode.icon
	local myicon = uinode.myicon
	local uirank = uinode.rank

	if index > 10 and data.rank > 11 then
		self.myfont2:drawText(l, t - 40, r, b, '.  .  .', _Font.hCenter)
	end

	if isme then
		local r = data.rank or index
		local offset = r > 999 and 12 or 0
		if r <= 3 then
			self.rank_imgs[r]:drawImage(l + uiicon.l - 5, t + uiicon.t - 5, l + uiicon.l + uiicon.w + 5, t + uiicon.t + uiicon.h + 5)
		else
			self.myrank_bg:drawImage(l + myicon.l - offset, t + myicon.t, l + myicon.l + myicon.w - offset, t + myicon.t + myicon.h)
			self.myfont1:drawText(l + myicon.l - 2 - offset, t + myicon.t, l + myicon.l + myicon.w - offset, t + myicon.t + myicon.h, r < 1001 and r or '1000 + ', _Font.hCenter + _Font.vCenter)
		end

		self.myfont2:drawText(l + uiname.l, t + uiname.t, l + uiname.l + uiname.w, t + uiname.t + uiname.h, Global.Login:getName(), _Font.vCenter)
		self.myfont3:drawText(l + uidata.l, t + uidata.t, l + uidata.l + uidata.w, t + uidata.t + uidata.h, data.data, _Font.hRight + _Font.vCenter)
	else
		if index <= 3 then
			self.rank_imgs[index]:drawImage(l + uiicon.l - 5, t + uiicon.t - 5, l + uiicon.l + uiicon.w + 5, t + uiicon.t + uiicon.h + 5)
		else
			self.rank_bg:drawImage(l + uiicon.l, t + uiicon.t, l + uiicon.l + uiicon.w, t + uiicon.t + uiicon.h)
			self.font1:drawText(l + uiicon.l - 2, t + uiicon.t, l + uiicon.l + uiicon.w, t + uiicon.t + uiicon.h, index, _Font.hCenter + _Font.vCenter)
		end

		self.font2:drawText(l + uiname.l, t + uiname.t, l + uiname.l + uiname.w, t + uiname.t + uiname.h, data.player.name, _Font.vCenter)
		self.font3:drawText(l + uidata.l, t + uidata.t, l + uidata.l + uidata.w, t + uidata.t + uidata.h, data.data, _Font.hRight + _Font.vCenter)
	end
end

leaderboard.updateUI = function(self, data)
	if not self:init() then return end
	if type(data) == 'string' then
		data = self.data and self.data[data] or {}
	end
	local mesh, db = self.mesh, self.db
	mesh.isInvisible = false
	_rd:useDrawBoard(db, _Color.Null)

	local nr = #data.ranks
	if nr < 10 and not data.my.rank then
		data.my.rank = nr + 1
		data.ranks[nr + 1] = {rank = data.my.rank, aid = Global.Login:getAid(), data = 0}
	end

	for i, v in ipairs(data.ranks) do
		self:drawnode(i, v)
	end

	if not data.my.rank then
		self:drawnode(11.5, {rank = 10000, aid = Global.Login:getAid(), data = 0})
	elseif data.my.rank > 10 then
		self:drawnode(11.5, data.my)
	end
	_rd:resetDrawBoard()
end

leaderboard.camera_focus = function(self, foucsin)
	if foucsin == self.foucsin then return end
	self.foucsin = foucsin
	if foucsin then
		Global.CameraControl:push()
		local curcam = Global.CameraControl:get()
		local cam = self.camera
		curcam:setCamera(cam, 300)
		curcam:followTarget()
		curcam.camera.blocker = nil
		Global.SwitchControl:set_freeze_on()
		Global.role:enterEdit()
		self.timer:start('disableRole', 200, function()
			Global.Operate.disableRole = true
			self.timer:stop('disableRole')
		end)
		Global.ui.interact:hide()
		Global.ui.goback.visible = true
		Global.ui.goback.click = function()
			self:camera_focus(false)
			Global.ui.goback.visible = false
		end
	else
		Global.CameraControl:pop(300)
		Global.CameraControl:get():followTarget('role')
		Global.CameraControl:get().camera:setBlocker(Global.sen, Global.CONSTPICKFLAG.NORMALBLOCK)
		Global.SwitchControl:set_freeze_off()
		Global.role:leaveEdit()
		Global.Operate.disableRole = false
		Global.ui.interact:refresh()
	end
end

leaderboard.setData = function(self, type, data)
	if not self.data then self.data = {} end
	self.data[type] = data
end

leaderboard.new = function(type)
	local lb = {}
	setmetatable(lb, {__index = leaderboard})
	lb.type = type
	return lb
end

Global.Leaderboard_fame = leaderboard.new('fame')
Global.Leaderboard_brawl = leaderboard.new('brawl')
Global.Leaderboard_neverup = leaderboard.new('neverup')

---------------------------------乱斗入口-----------------------------------
local blockbrawl = {timer = _Timer.new()}
Global.BlockBrawlEntry = blockbrawl

blockbrawl.initBlock = function(self)
	local block = Global.sen:getBlockByShape('Arcadegame')
	if not block then return end
	local mesh = _G.Block.getPaintMeshs(block.node.mesh)[1]
	if not mesh then return end
	local pmesh = _G.Block.getParentMesh(block.node.mesh, mesh)

	if self.block == block then
		return true
	end

	block:setName('brawl')
	loadBlockFunction(block, 'brawl.func')

	self.block = block
	self.mesh = mesh
	self.mesh.isInvisible = true

	local s = 6 / 5
	self.mesh.transform:mulScalingLeft(s, s, 1)

	local material = self.mesh.material
	material.isAlpha = true
	material.isDecal = true
	material.isNoLight = true
	material.isNoFog = true
	material.isUseEnvironmentMap = false
	material.emissive = 0xff0f0f1f
	material.emissivePower = 20.0
	material.power = 1.0

	pmesh.material.emissive = 0xff0f0f1f
	pmesh.material.emissivePower = 1.0
	pmesh.material.power = 1.0

	local cam = _Camera.new()
	cam.eye:set(Global.GameRankCameras.Npc.eye)
	cam.look:set(Global.GameRankCameras.Npc.look)

	local mat = block.node.transform
	mat:apply(cam.eye, cam.eye)
	mat:apply(cam.look, cam.look)

	self.camera = cam
	self.pfx1 = _Particle.new('wq_rongjie_xs.pfx')
	self.pfx2 = _Particle.new('wq_rongjie_cx.pfx')

	return true
end

blockbrawl.init = function(self)
	if not self:initBlock() then return end

	if self.db then return true end
	self.db = _DrawBoard.new(600, 600)

	self.mesh.material.diffuseMap = self.db

	-- init ui, todo: load fairy
	self.ui = {
		logo = {},

		node = {
			l = 0, t = 60,
			w = 600, h = 60,
			rank = {l = 70, t = 0, w = 100, h = 60},
			name = {l = 160, t = 0, w = 370, h = 60},
			total = {l = 50, t = 200, w = 230, h = 100},
			score = {l = 320, t = 200, w = 230, h = 100},
		},
	}

	self.font1 = _Font.new('Half Bold Pixel-7', 60, 0, 0, 2, 100)
	self.font1.textColor = 0xffff8200
	self.font1.edgeColor = 0xfff0f0f0
	self.font1.offsetH = 2
	self.font1.offsetV = 2
	self.font2 = _Font.new('Half Bold Pixel-7', 40, 0, 0, 2, 100)
	self.font2.textColor = 0xff14b28e
	self.font2.edgeColor = 0xfff0f0f0
	self.font2.offsetH = 2
	self.font2.offsetV = 2
	self.font3 = _Font.new('Half Bold Pixel-7', 40, 0, 0, 2, 100)
	self.font3.textColor = 0xffff9000
	self.font3.edgeColor = 0xfff0f0f0
	self.font3.offsetH = 2
	self.font3.offsetV = 2
	self.font4 = _Font.new('Half Bold Pixel-7', 50, 0, 0, 0, 0)
	self.font4.textColor = 0xffffffff
	self.font5 = _Font.new('Half Bold Pixel-7', 60, 0, 0, 2, 100)
	self.font5.textColor = 0xff14b28e
	self.font5.edgeColor = 0xfff0f0f0
	self.font5.offsetH = 2
	self.font5.offsetV = 2

	return true
end

-- data = {{ name = '', score = 0 }}
blockbrawl.drawnode = function(self, index, data)
	local rank_str = {'1st', '2nd', '3rd', '4th'}
	-- local isme = data.aid == Global.Login:getAid()
	local w, h = self.db.w, self.db.h
	-- draw
	local uinode = self.ui.node
	local l = uinode.l
	local t = uinode.t + uinode.h * index
	local r = l + uinode.w
	local b = t + uinode.h
	local uirank = uinode.rank
	local uiname = uinode.name
	-- local uiscore = uinode.score
	self.font2:drawText(l + uirank.l, t + uirank.t, l + uirank.l + uirank.w, t + uirank.t + uirank.h, rank_str[data.rank or index], _Font.vCenter)
	self.font2:drawText(l + uiname.l, t + uiname.t, l + uiname.l + uiname.w, t + uiname.t + uiname.h, string.fclamp(data.name, 11), _Font.hRight + _Font.vCenter)
	-- self.font3:drawText(l + uiscore.l, t + uiscore.t, l + uiscore.l + uiscore.w,  t + uiscore.t + uiscore.h, data.score, _Font.hRight + _Font.vCenter)
end

blockbrawl.updateMatchTick = function(self)
	local c = self.current
	local t = self.total
	if not c then return end
	_rd:useDrawBoard(self.db, _Color.Null)
	self.font1:drawText(0, 0, 600, 280, ('Matching... %d/%d'):format(c, t), _Font.hCenter + _Font.vBottom)
	if not Global.ui.fullscreenpfx.visible then
		self.font4:drawText(0, 320, 600, 500, string.ftoTimeFormat(self.tick), _Font.hCenter)
	end
	_rd:resetDrawBoard()
end

blockbrawl.updateMatchUI = function(self, current, total)
	if not self:init() then return end
	self.mesh.isInvisible = false
	self.current = current
	self.total = total
	if current then
		if not self.tick then self.tick = 0 end
		self:updateMatchTick()
		self.timer:start('matching', 1000, function()
			self.tick = self.tick + 1
			self:updateMatchTick()
		end)
	else
		self.timer:stop('matching')
		_rd:useDrawBoard(self.db, _Color.Null)
		self.font4:drawText(0, 300, 600, 400, 'START GAME\n2023', _Font.hCenter + _Font.vBottom)
		_rd:resetDrawBoard()
		self.tick = nil
	end

	Global.ui.brawl_cancel.disabled = current and current == total
	Global.ui.brawl_cancel.visible = not not current
	Global.ui.brawl_ok.visible = false
end

blockbrawl.showPrepareUI = function(self, show)
	Global.ScreenEffect:showPfx(show and 'countdown')
	self:updateMatchTick()
end

blockbrawl.prepare_to_start = function(self, func)
	Global.SwitchControl:set_freeze_on()
	Global.Timer:add('blockbrawl_start', 1, function() -- 奇怪bug。
		Global.ScreenEffect:showPfx('countdown')
	end)
	self.timer:start('prepare_to_start', 4000, function()
		self.timer:stop('prepare_to_start')
		Global.ScreenEffect:showPfx()
		Global.SwitchControl:set_freeze_off()
		func()
	end)
end

blockbrawl.updateScoreUI = function(self, data)
	if not self:init() then return end
	self.mesh.isInvisible = false
	if data then
		_rd:useDrawBoard(self.db, _Color.Null)
		for i, v in ipairs(data) do
			self:drawnode(i, v)
			if v.aid == Global.Login:getAid() then
				local score = (v.score_after or 0) - (v.score_before or 0)
				self.myScore = {v.score_before or 0, score, score / 20, v.score_after}
			end
		end
		_rd:resetDrawBoard()
	elseif self.myScore then
		_rd:useDrawBoard(self.db, _Color.Null)
		self.font5:drawText(50, 200, 270, 330, self.myScore[1], _Font.hRight + _Font.vCenter)
		self.font3:drawText(320, 210, 600, 330, self.myScore[5] and self.myScore[5] or self.myScore[2] < 0 and self.myScore[2] or ('+' .. self.myScore[2]), _Font.vCenter)
		_rd:resetDrawBoard()
		
		if self.myScore[2] > 0 then
			self.timer:start('myscore', 50, function()
				self.timer:stop('myscore')
				self:updateScoreUI()
			end)
			self.myScore[1] = math.min(toint(self.myScore[1] + self.myScore[3]), self.myScore[4])
			self.myScore[2] = math.max(toint(self.myScore[2] - self.myScore[3]), 0)
			if self.myScore[2] == 0 then
				self.myScore[1] = self.myScore[4]
				self.myScore[5] = '+0'
			end

			Global.Sound:play('ui_hint03')
		elseif self.myScore[2] < 0 then
			self.timer:start('myscore', 50, function()
				self.timer:stop('myscore')
				self:updateScoreUI()
			end)
			self.myScore[1] = math.max(toint(self.myScore[1] + self.myScore[3]), self.myScore[4])
			self.myScore[2] = math.min(toint(self.myScore[2] - self.myScore[3]), 0)
			if self.myScore[2] == 0 then
				self.myScore[1] = self.myScore[4]
				self.myScore[5] = '-0'
			end
			
			Global.Sound:play('ui_hint02')
		else
			self.timer:stop('myscore')
			self.myScore = nil
		end
	else
		self:updateMatchUI()
		return true
	end
	Global.ui.brawl_cancel.visible = false
	Global.ui.brawl_ok.visible = true
	Global.ui.brawl_ok.click = function() --如果刚从乱斗场景出来，要记录进场景之前的相机
		if self:updateScoreUI() then
			self:camera_focus(false)
		end
	end

	if self.foucsin then
		Global.ui.interact:hide()
		local curcam = Global.CameraControl:get()
		curcam.camera.blocker = nil
		Global.ScreenEffect:dof(true, 2)
	end
end

blockbrawl.camera_focus = function(self, foucsin)
	if foucsin == self.foucsin then return end
	self.foucsin = foucsin
	if foucsin then
		Global.CameraControl:push()
		local curcam = Global.CameraControl:get()
		curcam:setCamera(self.camera, 300)
		curcam:followTarget()
		curcam.camera.blocker = nil
		Global.ScreenEffect:dof(true, 2)
		
		Global.SwitchControl:set_freeze_on()
		Global.ui.interact:hide()
		Global.ProfileUI:show(false)
		Global.CoinUI:show(false)
		-- Global.UI:pushAndHide('normal')
		if Global.role then
			Global.role:enterEdit()
		end

		Global.ui.brawl_cancel.visible = true
		Global.ui.brawl_cancel.click = function()
			self:camera_focus(false)
			Global.Room_New:Leave()
			self:updateMatchUI()
			self:showPrepareUI(false)
		end
	else
		Global.CameraControl:pop(300)
		Global.CameraControl:get():followTarget('role')
		Global.CameraControl:get().camera:setBlocker(Global.sen, Global.CONSTPICKFLAG.NORMALBLOCK)
		Global.ScreenEffect:dof(false)
		Global.SwitchControl:set_freeze_off()
		Global.ui.interact:refresh()
		Global.ProfileUI:show(true)
		Global.CoinUI:show(true)
		-- Global.UI:popAndShow('normal')
		if Global.role then
			Global.role:leaveEdit()
		end
	end
end

---------------------------------游戏积分排行榜-------------------------------------
local Ranklist = {}
Global.Ranklist = Ranklist

Ranklist.addScore = function(self, level, score, onsuccess, onfailed)
	self.onAddScore = onsuccess
	self.onAddScoreErr = onfailed

	RPC('AddScore', {Levelid = level, Score = score})
end

-- count : 前count名
Ranklist.getTopScores = function(self, level, count, onsuccess, onfailed)
	self.onGetTopScores = onsuccess
	self.onGetTopScoresErr = onfailed

	RPC('GetTopScores', {Levelid = level, Count = count})
end

define.AddScoreInfo{Result = false, Info = {}}
when{}
function AddScoreInfo(Result, Info)
	if Result then
		if Global.Ranklist.onAddScore then
			Global.Ranklist.onAddScore(Info.res)
		end
	else
		if Global.Ranklist.onAddScoreErr then
			Global.Ranklist.onAddScoreErr(Info.res)
		end
	end
end

define.GetTopScoresInfo{Result = false, Info = {}}
when{}
function GetTopScoresInfo(Result, Info)
	if Result then
		if Global.Ranklist.onGetTopScores then
			Global.Ranklist.onGetTopScores(Info.res, Info.me)
		end
	else
		if Global.Ranklist.onGetTopScoresErr then
			Global.Ranklist.onGetTopScoresErr(Info.res)
		end
	end
end

---------------------------------排行榜数据------------------------------------------
Global.Leaderboard = {}
-- 获取fame 排行榜信息
Global.Leaderboard.getFameRank = function(self)
	-- 第一次创建没名字
	if Global.Login:getName() == '' then return end
	RPC('LeaderBoardRank', {Type = "fame", Descending = true})
end
-- 获取blockbrawl 排行榜信息
Global.Leaderboard.getBlockBrawlRank = function(self)
	-- 第一次创建没名字
	if Global.Login:getName() == '' then return end
	RPC('LeaderBoardRank', {Type = "blockbrawl_event", Descending = true})
	RPC('LeaderBoardRank', {Type = "blockbrawl", Descending = true})
end
-- 获取 Neverup 排行榜信息
Global.Leaderboard.getNeverupRank = function(self)
	-- 第一次创建没名字
	if Global.Login:getName() == '' then return end
	RPC('LeaderBoardRank', {Type = "neverup_single_event", Descending = true})
	RPC('LeaderBoardRank', {Type = "neverup_single", Descending = true})
	-- RPC('LeaderBoardRank', {Type = "neverup_multi", Descending = true})
end

----------------------------
-- 通用排行榜
-- result 中包含类型， "fame"， "blockbrawl"
define.GetLeaderRankInfo{Result = false, Info = {}}
when{}
function GetLeaderRankInfo(Result, Info)
	-- print("GetLeaderRankInfo", Result, table.ftoString(Info))
	if Info.type == "fame" then
		Global.Leaderboard_fame:updateUI(Info)
	elseif Info.type == "blockbrawl" then
		Global.Leaderboard_brawl:setData('normal', Info)
		Global.Leaderboard_brawl:updateUI('normal')
	elseif Info.type == "blockbrawl_event" then
		Global.Leaderboard_brawl:setData('event', Info)
		Global.Leaderboard_brawl:updateUI('event')
	elseif Info.type == "neverup_single" then
		Global.Leaderboard_neverup:setData('single', Info)
		Global.Leaderboard_neverup:updateUI('single')
	elseif Info.type == "neverup_single_event" then
		Global.Leaderboard_neverup:setData('event', Info)
		Global.Leaderboard_neverup:updateUI('event')
	-- elseif Info.type == "neverup_multi" then
		-- Global.Leaderboard_neverup:setData('multi', Info)
		-- Global.Leaderboard_neverup:updateUI('multi')
	end
end