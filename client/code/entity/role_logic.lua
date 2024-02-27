
local Role = Global.Role
---------------------------------------
local STYLE = {
	NORMAL = 1,
	FAST = 2,
	COOL = 3,
}
Role.ai_prepare = function(self, func, aid)
	self.send_func = func
	self.aid = aid
	self.inputs = {}
	print('ai_prepare', self.send_func, self.aid)
	self.style = math.random(1, 3)
end
Role.ai_start = function(self)
	if not self.send_func then return end
	self.started = true
end
Role.ai_update = function(self, e)
	if not self.started then
		return
	end

	if not self.inputs then
		return
	end

	if self:ai_do_input() then
		return
	end

	if self:ai_land() then
		return
	end
	if self:ai_calc_dis() < -1 then
		self:ai_go_down()
	else
		self:ai_idle()
	end
end
Role.ai_idle = function(self)
	local p = math.random()
	-- print('ai_idle', p)
	if p < 0.05 then
		self:ai_wander()
	elseif p < 0.4 then
		self:ai_wander_2()
	else
		self:ai_wait()
	end
end
Role.ai_do_input = function(self)
	if #self.inputs == 0 then
		return false
	end

	local input = table.remove(self.inputs, 1)
	self.send_func(input.dir, self.aid)

	return true
end
Role.ai_stop = function(self)
	table.insert(self.inputs, {dir = {x = 0, y = 0, z = 0}})
end
Role.ai_move = function(self, v)
	table.insert(self.inputs, {dir = {x = v.x, y = v.y, z = v.z}})
end
Role.ai_go_left = function(self)
	self:ai_move({x = 0, y = -1, z = 0})
end
Role.ai_go_right = function(self)
	self:ai_move({x = 0, y = 1, z = 0})
end
local tmp_vec3 = _Vector3.new()
Role.ai_calc_dis = function(self)
	self:getPosition(tmp_vec3)
	local dis = _rd.camera.look.z - tmp_vec3.z

	return dis
end
----------------------------------------------------
Role.ai_wait = function(self)
	local t = math.random(9, 20)
	for i = 1, t do
		self:ai_stop()
	end
end
Role.ai_wander = function(self)
	local times = math.random(1, 2)
	for i = 1, times do
		local lr_times = math.random(-1, 1)
		for j = 1, 3 + lr_times do
			self:ai_go_left()
		end
		for j = 1, 3 - lr_times do
			self:ai_go_right()
		end
	end
	self:ai_stop()
end
local sweeps = {}
local sweep_dir = _Vector3.new(0, 0, -1)
local aabb = _AxisAlignedBox.new()
Role.ai_go_down = function(self)
	local cct = self.cct
	if not self.node.scene:physicsSweep(cct.actor, sweep_dir, 6, Global.CONSTPICKFLAG.NORMALBLOCK, sweeps) then
		return
	end

	local b = sweeps.actor.node.block
	if not b then return end

	-- find left / right
	b:getAABB(aabb)
	local left = aabb.min.y
	local right = aabb.max.y

	local dis = 0
	local dir = 0
	local pos = sweeps.pos.y
	local p = math.random()
	if p > 0.5 then
		dir = -1
		dis = math.abs(pos - left)
	else
		dir = 1
		dis = math.abs(pos - right)
	end

	local count = math.ceil(dis / (RUN_MAX * 20))
	for i = 1, count do
		self:ai_move({x = 0, y = dir, z = 0})
	end
	self:ai_stop()
end
Role.ai_wander_2 = function(self)
	local cct = self.cct
	if not self.node.scene:physicsSweep(cct.actor, sweep_dir, 10, Global.CONSTPICKFLAG.NORMALBLOCK, sweeps) then
		return
	end

	local b = sweeps.actor.node.block
	if not b then return end

	-- find left / right
	b:getAABB(aabb)
	local left = aabb.min.y
	local right = aabb.max.y

	local dis = 0
	local dir = 0
	local pos = sweeps.pos.y
	local p = math.random()
	if p > 0.5 then
		dir = -1
		dis = math.abs(pos - left)
	else
		dir = 1
		dis = math.abs(pos - right)
	end

	local count = math.ceil(dis / (RUN_MAX * 20))
	for i = 1, math.min(count, 2) do
		self:ai_move({x = 0, y = dir, z = 0})
	end
	self:ai_stop()
end
Role.ai_pick_ray = function(self, ori, dir)
	if not self.node.scene:physicsPick(ori, dir, 5, Global.CONSTPICKFLAG.NORMALBLOCK, sweeps) then
		-- for k, v in next, sweeps do
		-- 	print(k, v)
		-- end
		return
	end

	return true
end
local tmp_vec3_2 = _Vector3.new()
Role.ai_land = function(self)
	if not self:isInAir() then
		return
	end

	self:getPosition(tmp_vec3)
	tmp_vec3.z = tmp_vec3.z - 1
	if self:ai_pick_ray(tmp_vec3, sweep_dir) then
		if sweeps.distance > 0 then
			self:ai_idle()
			return true
		end
	end

	-- print('land 1--', self.cct.actor, sweeps.actor, sweeps.distance, sweeps.pos.z)

	tmp_vec3_2:set(0, -0.5, -1)
	if self:ai_pick_ray(tmp_vec3, tmp_vec3_2) then
		if sweeps.distance > 0 then
			for i = 1, 5 do
				self:ai_go_left()
			end
			self:ai_stop()
			return true
		end
	end

	tmp_vec3_2:set(0, -1.2, -1)
	if self:ai_pick_ray(tmp_vec3, tmp_vec3_2) then
		if sweeps.distance > 0 then
			for i = 1, 5 do
				self:ai_go_left()
			end
			self:ai_stop()
			return true
		end
	end

	-- print('land 2--', sweeps.distance, sweeps.pos.z)

	tmp_vec3_2:set(0, 0.5, -1)
	if self:ai_pick_ray(tmp_vec3, tmp_vec3_2) then
		if sweeps.distance > 0 then
			for i = 1, 5 do
				self:ai_go_right()
			end
			self:ai_stop()
			return true
		end
	end

	tmp_vec3_2:set(0, 1.2, -1)
	if self:ai_pick_ray(tmp_vec3, tmp_vec3_2) then
		if sweeps.distance > 0 then
			for i = 1, 5 do
				self:ai_go_right()
			end
			self:ai_stop()
			return true
		end
	end

	-- print('land none', sweeps.distance, sweeps.pos.z)

	return true
end
