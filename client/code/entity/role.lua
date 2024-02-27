local animaState = _dofile('anima.lua')
Global.DefaultRoleAnimaState = animaState

local Container = Global.Container
_sys:addPath('res/char')
_sys:addPath('res/movie')

local Role = {}
Role.animaStateClass = animaState
Global.Role = Role
_dofile('role_move.lua')
_dofile('role_move_sub.lua')
_dofile('role_logic.lua')
_dofile('role_chip.lua')

local mainBody = _dofile('mainBody.lua')

local facial_cfg = Global.EmojiCfg
local texcoords = {
	_Vector2.new(0, 0),
	_Vector2.new(0.5, 0),
	_Vector2.new(0, 0.5),
	_Vector2.new(0, 0),
}

Role.applyFacialExpression = function(self, a)
	if not facial_cfg[a] then return end
	if not self.faceinfo then self.faceinfo = {} end
	if self.faceinfo.exp == a then return end

	self.expimg = facial_cfg[a].icon and _Image.new(facial_cfg[a].icon) or nil
	if self.expimg then
		self.expimg.tick = os.now() + 3000
	end

	local s = facial_cfg[a].sound
	if s then
		local min, max = 3, 6
		if self == Global.role or self == Global.BuildBrick then
			min, max = 5, 20
		end

		local pos = Container:get(_Vector3)
		self.node.transform:getTranslation(pos)
		Global.Sound:play3D(facial_cfg[a].sound, pos, min, max)
		Container:returnBack(pos)
	end

	self.node.expimg = self.expimg

	if self.mb == nil or self.mb.facemesh == nil then return end
	local index = facial_cfg[a].indexes[1]

	self.faceinfo.exp = a
	self.faceinfo.index = index
	-- self.faceinfo.tick = 200
	self.mb.facemesh.material.UVOffset = texcoords[index]
	self.mb.facemesh.material.diffuseMap = _Image.new(facial_cfg[a].res)
end

local v = _Vector3.new()
----------------------------------------------------------------------------
Role.new_xl = function(data)
	local r = {}
	r.name = data.name
	r.aid = data.aid

	local node = Global.sen:add()
	r.node = node

	node.pickFlag = Global.CONSTPICKFLAG.ROLE
	node.isShadowCaster = true
	node.isShadowReceiver = true

	r.scale = _Matrix3D.new()
	node.transform = r.scale
	r.translation = _Matrix3D.new()
	r.rotation = _Matrix3D.new()
	r.scale.parent = r.rotation
	r.rotation.parent = r.translation

	r.mb = mainBody.new(r, true)
	r.mesh = r.mb.mesh
	r.size = _Vector3.new(1, 0.6, 1.2)

	r.animaState = Role.animaStateClass.new()
	r.animaState.onChange = function(s)
		r:onChangeState(s)
	end

	r.logic = {
		jumpState = 0,
		jumpLimit = 2,
		vxy = 0,
		vz = 0,
		speed = _Vector3.new(),
		outerdir = _Vector3.new(),
		dir = _Vector3.new(),
		zdis = 0,
		needAcc = false,
	}

	r.input_updater = Global.FrameSystem:NewInput()

	r.rtdata = {}

	r.attrs_readonly_keys = {}
	r.attrs = {
		MaxLife = 12,
		Life = 12,
		Score = 0,
		Rank = 1,
	}
	r.Speeds = {
		-- Default = { Dir = _Vector3.new(), Time = 0, FadeTime = 0 },
	}
	r.chip_object = Global.ChipObject.new(r)

	return r
end
Role.new = function()
	if Global.role then
		Global.role:release()
	end

	local r = Role.new_xl({
		name = Global.Login:getName(),
		aid = Global.Login:getAid(),
		avatarid = Global.ObjectManager:getAvatarId(),
	})

	setmetatable(r, {__index = Role})

	r:set_on_change(function(dir, j)
		local input = {dir = _Vector3.new()}
		input.dir:set(dir)
		input.jump = j
		Global.InputSender:input(input, Global.Login:getAid())
	end)

	r:setAvatarid(Global.ObjectManager:getAvatarId())

	r:createCCT()
	Global.role = r

	return r
end

Role.releaseCCT = function(self)
	Global.sen:delController(self.cct)
	self.cct = nil
end
Role.createCCT = function(self, n)
	if self.cct then return end
	n = n or self.mb.node

	self.cct = CreateCCT(Global.sen, n)

	self.cct:collisionGroup(0x2, 0xffff)
	self.cct:queryGroup(0x2, 0xffff)

	self.cct.role = self
end
Role.release = function(self)
	self:releaseCCT()
	if Global.sen then
		Global.sen:del(self.mb.node)
	end

	if self.currentAnima then
		self.currentAnima:stop()
	end

	if self.mb and self.mb.block then
		self.mb.block:stopAnim()
	end

	Global.role = nil
end
local mat = _Matrix3D.new()
Role.updateFace = function(self, direction, t)
	if self.mesh.dir.x == direction.x and self.mesh.dir.y == direction.y then
		return
	end
	-- 获取当前角度, 矫正
	mat:setFaceTo(0, -1, 0, direction.x, direction.y, 0)
	local a1 = self.rotation:getRotationZ()
	local a2 = mat:getRotationZ()
	-- 去掉剩余没做完的旋转
	self.rotation:setRotationZ(a1)

	-- 获取要转的角度
	local time = t or 200

	local da = a2 - a1
	if math.abs(da) > math.pi then
		da = da > 0 and (da - math.pi * 2) or (math.pi * 2 + da)
	end

	self.rotation:mulRotationZRight(da, time)
	self.mesh.dir:set(direction.x, direction.y, direction.z)
end
Role.turnTo = function(self, target, t)
	local cur = Container:get(_Vector3)
	local dir = Container:get(_Vector3)
	self:getPosition(cur)
	_Vector3.sub(target:getPosition_const(), cur, dir)
	self:updateFace(dir, t)
	Container:returnBack(cur, dir)
end
Role.Respawn = function(self, i)
	local sen = Global.sen

	local r = sen:getRespawnData(i)
	self:setPosition(r.pos)
	self:updateFace(r.dir, 0)

	self.animaState:changeAnima('idle')
	Global.SwitchControl:set_input_on()

	self.mb.mesh.pfxPlayer:play('wq_rongjie_cx.pfx')
	Global.Sound:play('anima_flash02')
end

Role.setAvatarid = function(self, avatarid)
	if avatarid == 0 then
		self:ChangeAvatar()
		return
	end

	local o = Global.ObjectManager:getObject_with_datafile(avatarid)
	if o then
		self:ChangeAvatar(o.name)
	end

	Global.ObjectManager:listen_obj_id(avatarid, 0, function(d, changed)
		if changed then
			self:ChangeAvatar(d.name)
		end
	end)
end

Role.ChangeAvatar = function(self, shapeid)
	local anima = self.currentAnimaName or 'idle'
	self.currentAnimaName = nil
	self.mb:xl_setAvatar(shapeid)
	self:playAnima(anima)
end

Role.onChangeState = function(self, s)
	self:updateFootPfx(not self.animaState:isJumping())
	self:playAnima(s)
end

Role.updateFootPfx = function(self, visible)
	if not self.ringpfx then return end
	if not self.ringpfx.blender then self.ringpfx.blender = _Blender.new() end
	if self.ringpfx.tempVisible ~= visible then
		-- change visible use blender for 100ms
		if visible then
			self.ringpfx.blender:blend(0x00ffffff, 0xffffffff, 100)
		else
			self.ringpfx.blender:blend(0xffffffff, 0x00ffffff, 100)
		end
		self.ringpfx.tempVisible = visible
	end
end

Role.movieStruggle = function(self)
	self.isFallStruggleOnce = true
end
-------------------------------------------------
Role.smoothBack = function(self)
	local camera = Global.CameraControl:get()
	local a = camera:prepareAngle(self.mb.mesh.dir)
	if math.abs(a) < 0.005 or math.abs(a - math.pi) < 0.005 or math.abs(a + math.pi) < 0.005 then
	elseif a > 0 then
		camera:moveDirH(0.01)
	elseif a < 0 then
		camera:moveDirH(-0.01)
	end
end
Role.focusBack = function(self, t, la)
	Global.CameraControl:get():turnToward(self.mb.mesh.dir, t or 200, 'lcc', la)
end
Role.focusFace = function(self, t)
	_Vector3.mul(self.mb.mesh.dir, -1, v)
	Global.CameraControl:get():turnToward(v, t or 200, 'lcc')
end
local dirV = _Vector3.new()
Role.rotateFace = function(self, a)
	local a1 = self.rotation:getRotationZ()
	-- 去掉剩余没做完的旋转
	self.rotation:setRotationZ(a1)

	self.rotation:mulRotationZRight(a)

	self.rotation:apply(0, -1, 0, dirV)
	self.mb.mesh.dir:set(dirV.x, dirV.y, dirV.z)
end
-------------------------------------------------
Role.setPosition = function(self, pos)
	if self.cct then
		self.cct.position:set(pos.x, pos.y, pos.z + self.cct.contactOffset + self.cct.halfHeight)
		self.cct.position_last:set(self.cct.position)
		self:set_position_render(self.cct.position)
	else
		self.translation:setTranslation(pos.x, pos.y, pos.z)
	end
end
Role.getPosition = function(self, vec)
	assert(vec)
	if self.cct then
		vec:set(self.cct.position)
		vec.z = vec.z - self.cct.contactOffset - self.cct.halfHeight
	else
		self.translation:getTranslation(vec)
	end
	return vec
end
local v_const = _Vector3.new()
Role.getPosition_const = function(self)
	return self:getPosition(v_const)
end
Role.getEyeHeight = function(self)
	return self.eyeHeight
end
Role.getAABB = function(self, aabb)
	self:getPosition(v)
	aabb.max:set(v.x + self.size.x / 2, v.y + self.size.y / 2, v.z + self.size.z)
	aabb.min:set(v.x - self.size.x / 2, v.y - self.size.y / 2, v.z)
end
-------------------------------------------------
Role.freeze = function(self, f)
	Global.Operate:disabled(f)
end
Role.takeShot = function(self)
	self:playAnima('shot')
	self.currentAnima.current = self.currentAnima.duration
	self:pauseAnima()
end
Role.pauseAnima = function(self)
	self.currentAnima.pause = true
end
Role.playAnima = function(self, a, freeze, onend)
	-- print(self, a, self.currentAnimaName, freeze, onend, debug.traceback())
	if self.currentAnimaName == a then return end
	
	if self.currentAnima then
		self.currentAnima:stop()
	end

	if not self.mb.block then
		self.animas[a]:play()
	else
		self.mb.block:playAnim(a)
	end

	if freeze then
		self:freeze(freeze)
	end

	self.currentAnima = self.animas[a]
	self.currentAnimaName = a
	self.currentAnima.onend = onend
end

Role.stopMoving = function(self)
	self.logic.vxy = 0
	self.animaState.state = 'idle'
end

local pfxvec = _Vector3.new()
Role.playSkillAnima = function(self, skill, index, perf)
	local cfg = Global.LobbySkills[skill]
	local sklcfg = perf and cfg.animas[index] or cfg.audience_animas[index]
	-- animares
	local res = sklcfg.res[math.random(1, #sklcfg.res)]
	self:playAnima(res)
	-- music
	if sklcfg.music then
		local music = sklcfg.music[math.random(1, #sklcfg.music)]
		Global.Sound:play3D(music, self:getPosition_const(), cfg.range, cfg.range * 2, skill)
	end

	if sklcfg.pfx then
		local pfx = sklcfg.pfx.res[math.random(1, #sklcfg.pfx.res)]

		local pos = self:getPosition_const()
		local dir = self.mesh.dir
		_Vector3.add(pos, dir:clone():normalize(), pfxvec)

		pfxvec.z = pfxvec.z + 1
		local mat = _Matrix3D.new()
		local s = sklcfg.pfx.scale or 0.01
		mat:setScaling(s, s, s):mulTranslationRight(pfxvec)

		Global.sen.pfxPlayer:play(skill, pfx, mat)

		if self.pfxBlock then
			Global.sen:delBlock(self.pfxBlock)
		end
		s = 0.5
		pfxvec.z = pfxvec.z - 0.5
		local b = Global.sen:createBlock({shape = sklcfg.pfx.shape})
		b:enablePhysic(false)
		b.node.transform:setScaling(s, s, s):mulTranslationRight(pfxvec)
		self.pfxBlock = b
	end

	return self.currentAnima.duration, sklcfg
end

Role.useSkill = function(self, skill, target) -- 使用技能
	if self.skill_enabled then return end
	if self.skillCD and self.skillCD > os.now() then return end
	self.skillCD = os.now() + (Global.LobbySkills[skill].cd or 5000)

	local duration, cfg = self:playSkillAnima(skill, 1, true)
	if cfg.turnto and target then
		self:turnTo(target)
	end

	Global.SwitchControl:set_input_off()
	self.animaState.able = false
	self:stopMoving()

	Global.Timer:add(skill, duration, function()

		self:playSkillAnima(skill, 2, true)
		RPC('UpdateLobbySkill', {Type = 'use', Skill = skill, Time = _now(0.001)})

		local dur = Global.LobbySkills[skill].duration
		if dur then
			Global.Timer:add(skill .. 'play', dur, function()
				self:endSkill()
			end)
		end

	end)

	self.skill_enabled = skill
	self.usingSkill = skill
end

Role.endSkill = function(self)
	if not self.usingSkill then return end
	local skill = self.usingSkill
	self.usingSkill = nil

	local duration = self:playSkillAnima(skill, 3, true)

	Global.SwitchControl:set_input_off()
	self.freetogo = false

	Global.Timer:add(skill, duration, function()
		Global.SwitchControl:set_input_on()
		self.animaState.able = true
		self.freetogo = true

		RPC('UpdateLobbySkill', {Type = 'end', Skill = skill, Time = _now(0.001)})

		Global.Sound:stop(false, skill)
		Global.sen.pfxPlayer:stop(skill)
		if self.pfxBlock then
			Global.sen:delBlock(self.pfxBlock)
			self.pfxBlock = nil
		end

		self.skill_enabled = nil
	end)
end

Role.setAudienceTo = function(self, ch, skill)
	if self.freetogo == false then return end
	Global.SwitchControl:set_input_off()
	self.animaState.able = false
	self.freetogo = false
	self:stopMoving()

	local duration, cfg = self:playSkillAnima(skill, 1, false)
	if cfg.turnto then
		self:turnTo(ch)
	end

	Global.Timer:add(skill, duration, function()
		self:playSkillAnima(skill, 2, false)
		self.audienceTo = ch
	end)

	Global.Timer:add(skill .. 'end', duration + 1500, function()
		self.freetogo = true
		Global.SwitchControl:set_input_on()
		self.animaState.able = true
	end)
end

Role.cancleAudience = function(self)
	if self.freetogo and self.audienceTo then
		RPC('UpdateLobbySkill', {Type = 'cancle', Time = _now(0.001)})
		self.audienceTo = nil
	end
end

Role.endAudienceTo = function(self, ch, skill)
	if self.audienceTo ~= ch then return end
	self:playSkillAnima(skill, 3, false)
	self.audienceTo = nil
end
-------------------------------------------------------------------
Role.pause = function(self, p)
	if self.currentAnima then
		self.currentAnima.speed = p and 0 or 1
	end
end
-------------------------------------------------------------------
local PFX_XS = 'wq_rongjie_xs.pfx'
local PFX_CX = 'wq_rongjie_cx.pfx'
local function onEvent(name, pfx)
	if name == 'end1' then
		Global.role.mb.mesh.pfxPlayer:play(PFX_CX)
	end
end

Role.enterEdit = function(self)
	if self.edit_pos == nil then
		self.edit_pos = _Vector3.new()
	end
	self:getPosition(self.edit_pos)
	self:releaseCCT()

	self.mb.mesh.pfxPlayer:stop()
	self.mb.mesh.pfxPlayer:play(PFX_XS)
	self.mb.mesh.pfxPlayer:onEvent(onEvent)
	self.animaState:changeAnima('float')
	Global.Sound:play('anima_flash01')
end
Role.leaveEdit = function(self)
	TEMP_CREATE_ROLECCT()
	if self.edit_pos then
		self:setPosition(self.edit_pos)
	end
	self.edit_pos = nil
	self.mb.mesh.pfxPlayer:onEvent(function() end)
	self.mb.mesh.pfxPlayer:play(PFX_CX)
	self.animaState:changeAnima('idle')
	Global.Sound:play('anima_flash02')
end

Role.changeTransparency = function(self)
	if self.mb.mesh.node then
		if not self.mb.mesh.node.blender then
			self.mb.node.blender = _Blender.new()
		end

		local alpha = Global.FERManager.visible and 0.5 or 1.0
		local destcolor = math.min(255, toint(255 * alpha)) * 0x1000000 + 0x00ffffff
		self.mb.node.blender:blend(destcolor)
	end
end

-- 角色是否在房间内
Role.isInsideHouse = function(self)
	if not Global.role and not Global.House and not Global.House.miniab and not Global.House.realab then
		return false
	end

	local ab = self.insideHouseOld and Global.House.realab or Global.House.miniab
	local miny = self.insideHouseOld and ab.min.y or ab.min.y + 1
	local rolepos = Container:get(_Vector3)
	Global.role:getPosition(rolepos)
	local inside = ab.min.x < rolepos.x and ab.max.x > rolepos.x and miny < rolepos.y and ab.max.y > rolepos.y
	Container:returnBack(rolepos)

	return inside
end

Role.updateInOutHouse = function(self)
	if self.onInsideHouse == nil and self.onOutsideHouse == nil then return end

	self.insideHouse = self:isInsideHouse()
	self.outsideHouse = not self.insideHouse

	if self.refreshTime then
		if self.onRefreshTime then
			self.onRefreshTime(self.insideHouse)
		end
	end

	if self.insideHouse and not self.insideHouseOld then
		if self.onInsideHouse then
			self:onInsideHouse()
		end
	end

	if self.outsideHouse and not self.outsideHouseOld then
		if self.onOutsideHouse then
			self:onOutsideHouse()
		end
	end

	self.insideHouseOld = self.insideHouse
	self.insideHouse = false
	self.outsideHouseOld = self.outsideHouse
	self.outsideHouse = false
	self.refreshTime = false
end

Role.updateObtainObject = function(self)
	if self.onObtainObject then
		self:onObtainObject()
	end
end

Role.setScale = function(self, scale, cctscale)
	cctscale = cctscale or scale
	self.scale:setScaling(cctscale, cctscale, cctscale)
	local oldh = self.cct.halfHeight
	UpdateCCT(self.cct, self.node)
	local newh = self.cct.halfHeight
	self.cct.position.z = self.cct.position.z + newh - oldh
	self.scale:setScaling(scale, scale, scale)
end

Role.setInstaSpeed = function(self, dir)
	self.logic.rebound = true
	self.logic.vxy = dir.x
	self.logic.vz = dir.z
end
