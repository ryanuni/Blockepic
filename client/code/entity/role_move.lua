local Role = Global.Role

local tmp_vec3 = _Vector3.new()
local v3 = _Vector3.new()
local last_dir = _Vector3.new()
local last_jump = false
local function vdir()
	_Vector3.sub(_rd.camera.look, _rd.camera.eye, v3)
	v3:normalize()
	return v3
end
local function hdir()
	_Vector3.cross(_rd.camera.up, vdir(), v3)
	return v3
end
Role.set_on_change = function(self, f)
	self.on_dir_change = f
end
local keys = {}
Role.clear_move_event = function(self)
	keys = {}
end
Role.do_move_event = function(self, dir, go)
	keys[dir] = go
end
Role.keys_to_dir = function(self, v)
	v:set(0, 0, 0)

	if keys.UP then
		_Vector3.add(v, vdir(), v)
	end
	if keys.DOWN then
		_Vector3.sub(v, vdir(), v)
	end
	if keys.LEFT then
		_Vector3.sub(v, hdir(), v)
	end
	if keys.RIGHT then
		_Vector3.add(v, hdir(), v)
	end

	if Global.sen.setting.disableY then
		v.y = 0
	end
	if Global.sen.setting.disableX then
		v.x = 0
	end

	local jump = keys.JUMP
	if self.on_dir_change then
		if not _Vector3.equal(last_dir, v) or (jump ~= last_jump) then
			self.on_dir_change(v, jump)
			last_dir:set(v)
			last_jump = jump
		end
	end
end
Role.input_update_calc = function(self, e)
	if _G.FreeView then
		local dir = self.mb.dir
		local c = Global.CameraControl:get()
		c:moveLookD(dir:mul(0.02 * _rd.camera.radius))
		return
	end

	if Global.Operate.disableRole then return end
	if not self.cct then return end

	----------------------------------------------------
	self:keys_to_dir(tmp_vec3)
end
Role.fix_position = function(self)
	self:getPosition(tmp_vec3)
end
Role.update = function(self, e)
	if not Global.role.mb.node then return end
	Global.role.mb.node.visible = not Global.Operate.disableRole
	if Global.Operate.disableRole then return end
	if not self.cct then return end

	-- self:fix_position()

	Global.Role_Base_xl.calc_anima_state(self, e)

	if not Global.GameState:isState('DRESSUP') then
		-- 动画速度
		-- 比行进速度快0.5倍
		self.animas.run.speed = self.logic.vxy / RUN_MAX
	else
		self.animas.run.speed = 1
	end
	self:updateInOutHouse()
	self:updateObtainObject()

	self:update_collide()
end
Role.jump = function(self, light, ...)
	Global.Role_Base_xl.jump(self, light, ...)
end
Role.gethit = function(self)
	if Global.GameState:isState('GAME') then
		-- Global.Role_Base_xl.gethit(self)
	end
end

Role.set_input = function(self, data)
	self.input_updater:new_input(data)
end
Role.input_update_sub = function(self, input, e)
	if input.pos then
		self.cct.position:set(input.pos.x, input.pos.y, input.pos.z)
	end

	if input.jump then
		self:jump()
	end

	Global.Role_Base_xl.calc_input(self, input.dir, e)

	if self.outer_input then
		_Vector3.add(self.outer_input, self.cct.displacement, self.cct.displacement)
		self.outer_input:set(0, 0, 0)
	end

	if self.mb.dir.x == 0 and self.mb.dir.y == 0 then return end
	self:updateFace(self.mb.dir)
end
Role.input_update = function(self, e)
	if self.cct == nil then return end

	-- self.cct.position_last:set(self.cct.position)

	self.input_updater:update(e, self.input_update_sub, self)
end
--------------------------------------
Role.get_position_render = function(self, v)
	self.translation:getTranslation(v)
end
Role.set_position_render = function(self, v)
	self:get_position_render(tmp_vec3)
	_Vector3.sub(v, tmp_vec3, tmp_vec3)
	tmp_vec3.z = tmp_vec3.z - self.cct.contactOffset - self.cct.halfHeight
	self.translation:mulTranslationRight(tmp_vec3)
end
Role.update_render = function(self, e, lerp)
	if not self.cct then return end

	-- _Vector3.lerp(self.cct.position_last, self.cct.position, lerp, v3)
	-- self:set_position_render(v3)
	-- if self.cct.displacement.z < -20 then
	-- 	self:Respawn()
	-- else
		self:set_position_render(self.cct.position)
	-- end
end
-------------------------------------
Role.set_outer_input = function(self, v)
	self.outer_input = self.outer_input or _Vector3.new()
	self.outer_input:set(v)
end