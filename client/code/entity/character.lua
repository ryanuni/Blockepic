local character = {}

Global.Character = character
Global.Characters = {lobby = {}, room = {}}

character.defaultFont = _Font.new('Comic Sans MS', 45, 0, 0, 4, 100, true)
character.defaultFont.edgeColor = 0xff5b5b5b

character.new = function(data, flag)
	local o = {}
	setmetatable(o, {__index = character})

	o.name = data.name
	o.id = data.id
	o.flag = flag

	-- node ------------------------
	local node = Global.sen:add()
	o.node = node
	o.mb = Global.MainBody.new(o)
	o.mesh = o.mb.mesh

	node.isShadowCaster = true
	node.isShadowReceiver = true

	node.charactername = o.name

	o.movedata = {
		curpos = _Vector3.new(),
		tarpos = _Vector3.new(),
		curdir = _Vector3.new(0, -1, 0),
		needupdate = false,
	}

	if data.avatarid then
		o:setAvatarid(data.avatarid)
	end

	o:new_setPosition(data.pos, data.dir)
	o:playAnima(data.anima or 'idle')
	o:useSkill(data.skill)

	if data.anima == 'run' then -- 原地跑步动画
		o.movedata.needupdate = true
	end

	if not Global.Characters[flag] then Global.Characters[flag] = {} end
	Global.Characters[flag][o.id] = o

	return o
end

character.setAvatarid = Global.Role.setAvatarid
-- character.ChangeAvatar = Global.Role.ChangeAvatar

character.ChangeAvatar = function(self, shapeid)
	local anima = self.n_currentanima or 'idle'
	self.mb:xl_setAvatar(shapeid)
	self.n_currentanima = nil
	self:playAnima(anima)
end

character.ChangeAvatar_anima_pose = function(self, shapeid)
	self.n_currentanima = nil
	self.mb:xl_setAvatar(shapeid)

	local a = 'idle'
	if self.mb.block then
		self.mb.block:seekAnim(a, 1, false)
	else
		self.animas[a]:play()
		self.animas[a].current = 1
		self.animas[a]:pause()
	end
end

character.applyFacialExpression = Global.Role.applyFacialExpression

character.delFromScene = function(self)
	Global.sen:del(self.mb.node)
end

character.release = function(self)
	Global.Characters[self.flag][self.id] = nil

	if self.mb and self.mb.block then
		self.mb.block:stopAnim()
	end

	if self.avatar then
		self.avatar:Release()
	end
	self:delFromScene()
end

character.clearCharacter = function(flag)
	if not Global.Characters[flag] then return end
	for i, v in pairs(Global.Characters[flag]) do
		v:release()
	end

	Global.Characters[flag] = {}
end
------------------------------------------------------------------------------------------
local new_v = _Vector3.new()
character.new_setTarget = function(self, tar)
	self.movedata.needupdate = true
	self.movedata.tarpos:set(tar.x, tar.y, tar.z)

	_Vector3.sub(self.movedata.tarpos, self.movedata.curpos, new_v)
	self:new_faceTo(new_v)
end

character.turnTo = function(self, target, t)
	local tar = target:getPosition_const()
	local cur = self:getPosition_const()
	_Vector3.sub(tar, cur, new_v)
	self:new_faceTo(new_v)
end

character.new_update = function(self, e)
	if self.movedata.needupdate == false then return end
	if self.stopped then return end

	_Vector3.sub(self.movedata.tarpos, self.movedata.curpos, new_v)
	local dis = new_v:magnitude()
	if dis < 0.0001 then
		self:playAnima('idle')
		self.movedata.needupdate = false
	else
		if dis > RUN_MAX * e then
			new_v:scale(RUN_MAX * e)
			_Vector3.add(self.movedata.curpos, new_v, self.movedata.curpos)
		else
			self.movedata.curpos:set(self.movedata.tarpos)
		end

		self.mb.node.transform:mulTranslationRight(new_v)

		self:playAnima('run')
	end
end
character.new_setPosition = function(self, pos, dir)
	self.movedata.curpos:set(pos.x, pos.y, pos.z)
	self.movedata.tarpos:set(self.movedata.curpos)
	self.movedata.curdir:set(0, -1, 0)
	self.mb.node.transform:setTranslation(self.movedata.curpos)
	self:new_faceTo(dir)
end
character.getPosition_const = function(self)
	return self.movedata.curpos
end
character.new_faceTo = function(self, dir)
	new_v:set(dir.x, dir.y, 0)
	if new_v:magnitude() < 0.0001 then return end

	self.mb.node.transform:mulFaceToLeft(self.movedata.curdir, new_v, 200)
	self.movedata.curdir:set(new_v)
end
character.playAnima = function(self, a)
	if self.n_currentanima == a then return end
	if self.mb.block then
		self.mb.block:playAnim(a)
	else
		self.animas[a]:play()
	end
	self.n_currentanima = a
end

character.playSkillAnima = function(self, skill, index, perf)
	-- print('!!!!!!!!!!!!!!!!!playSkillAnima', self, skill, index, perf)
end

local pfxvec = _Vector3.new()

character.useSkill = function(self, skill) -- 使用技能
	if self.usingSkill == skill then return end
	local logicname = 'skill' .. self.id
	if skill and skill ~= '' then
		local cfg = Global.LobbySkills[skill]
		local sklcfg = cfg.animas[2]
		-- animares
		-- local res = sklcfg.res[math.random(1, #sklcfg.res)]
		-- self:playAnima(res)
		-- music
		if sklcfg.music then
			local music = sklcfg.music[math.random(1, #sklcfg.music)]
			Global.Sound:play3D(music, self:getPosition_const(), cfg.range, cfg.range * 2, logicname)
		end

		if sklcfg.pfx then
			local pfx = sklcfg.pfx.res[math.random(1, #sklcfg.pfx.res)]
			-- 
			local pos = self:getPosition_const()
			local dir = self.movedata.curdir:clone():normalize()

			_Vector3.add(pos, dir, pfxvec)
			-- print(pfx, logicname, pos, dir, pfxvec)
			local mat = _Matrix3D.new()
			local s = sklcfg.pfx.scale or 0.1
			pfxvec.z = pfxvec.z + 1
			mat:setScaling(s, s, s):mulTranslationRight(pfxvec)

			Global.sen.pfxPlayer:play(logicname, pfx, mat)

			if sklcfg.pfx.shape then
				s = 0.5
				pfxvec.z = pfxvec.z - 0.5
				local b = Global.sen:createBlock({shape = sklcfg.pfx.shape})
				b:enablePhysic(false)
				b.node.transform:setScaling(s, s, s):mulTranslationRight(pfxvec)
				self.pfxBlock = b
			end
		end
	else
		Global.Sound:stop(false, logicname)
		Global.sen.pfxPlayer:stop(logicname)
		if self.pfxBlock then
			Global.sen:delBlock(self.pfxBlock)
			self.pfxBlock = nil
		end
	end
	self.usingSkill = skill
end

character.endSkill = function(self, skill) -- 使用技能
	-- print('!!!!!!!!!!!!!!!!!endSkill',self, skill)
end

character.setAudienceTo = function(self, ch, skill) -- 看别人表演
	self.stopped = true
	self:turnTo(ch)
	Global.Timer:add(self.name .. skill, 1000, function()
		self.stopped = false
	end)
end

character.cancleAudience = function(self)
	-- print('!!!!!!!!!!!!!!!!!cancleAudience', self)
end

character.endAudienceTo = function(self, ch, skill)
	-- print('!!!!!!!!!!!!!!!!!endAudienceTo', self, ch, skill)
end