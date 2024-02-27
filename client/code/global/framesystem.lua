
--[[
	逐帧调试

	Global.FrameSystem:Pause(true)
	local e = 20
	Global.InputSender:update(e)
	Global.FrameSystem:Update(e)
]]

local is = {inputs = {}, timer = _Timer.new()}
Global.InputSender = is
is.init = function(self)
	self.timer:stop()
	self.started = false
	self.frame_length = Global.FrameSystem:GetFrameLength()
	self.elapse_acc = 0
	self.delay_ms = 0

	self.fid = 0
end
is.start = function(self)
	-- print(debug.traceback())
	self.started = true
end
is.update = function(self, e)
	-- print('InputSender.update', e, self.started, self.elapse_acc)
	if not self.started then return end

	self.elapse_acc = self.elapse_acc + e
	local count = 0
	while self.elapse_acc >= self.frame_length do
		self.elapse_acc = self.elapse_acc - self.frame_length
		if self.delay_ms > 0 then
			local fid = self.fid
			local inputs = self.inputs
			self.timer:start('input' .. fid, self.delay_ms + count, function()
				self.timer:stop('input' .. fid)
				Global.FrameSystem:AddInput({inputs = inputs, fid = fid})
			end)
		else
			Global.FrameSystem:AddInput({inputs = self.inputs, fid = self.fid})
		end
		self.inputs = {}
		self.fid = self.fid + 1
		count = count + 1
	end
end
is.input = function(self, input, aid)
	if not self.started then return end

	self.inputs[aid] = input
end
is.set_delay = function(self, d)
	self.delay_ms = d
end

------------------------------------------------------------
local iu = {}
iu.new = function()
	local o = {}

	o.elapse_acc = 0
	o.current_dir = _Vector3.new(0, 0, 0)
	o.current_jump = false

	setmetatable(o, {__index = iu})

	return o
end
iu.new_input = function(self, data)
	self.input = data
end
--------------------------------------- frame_strict
iu.update_frame_strict = function(self, e, func, parent)
	local input = self.input
	if not input then
		input = {dir = self.current_dir, jump = self.current_jump}
	else
		self.current_dir:set(input.dir.x, input.dir.y, input.dir.z)
		input.dir = self.current_dir
		self.current_jump = input.jump
		self.input = nil
	end

	func(parent, input, e)
end
iu.update = function(self, e, func, parent)
	self:update_frame_strict(e, func, parent)
end
---------------------------------------
local ltimer = {list = {}}
ltimer.new = function(self, name, delay, func)
	assert(type(name) == 'string', name)
	local o = {}
	o.name = name
	o.acc = 0
	o.delay = delay
	o.func = func

	self.list[name] = o
end
ltimer.new2 = function(self, delay, func)
	local o = {}
	o.acc = 0
	o.delay = delay
	o.func = func

	table.insert(self.list, o)
end
ltimer.new_base = function(self, delay, func)
	local o = {}
	o.acc = 0
	o.delay = delay
	o.func = func
	self.base_timer = o
end
ltimer.update = function(self, e)
	if self.base_timer then
		local o = self.base_timer
		o.acc = o.acc + e
		if o.acc >= o.delay then
			o.acc = o.acc - o.delay
			o.func()
			self.base_timer = nil
			Global.FrameSystem.fid_diff = Global.FrameSystem:GetFid()
		end

		return
	end
	for _, o in next, self.list do
		o.acc = o.acc + e
		if o.acc >= o.delay then
			o.acc = o.acc - o.delay
			o.func()
			self.list[_] = nil
		end
	end
end
ltimer.del = function(self, name)
	self.list[name] = nil
end
ltimer.clear = function(self)
	self.list = {}
end
---------------------------------------

local lf = {}

Global.FrameSystem = lf
lf.NewInput = function(self)
	return iu.new()
end
-- 只有一个，存在的时候其他不走
lf.NewTimer_Base = function(self, delay, func)
	ltimer:new_base(delay, func)
end
lf.NewTimer = function(self, name, delay, func)
	ltimer:new(name, delay, func)
end
lf.NewTimer_NoName = function(self, delay, func)
	ltimer:new2(delay, func)
end
lf.RemoveTimer = function(self, name)
	ltimer:del(name)
end
--------------------------------------------------
lf.init = function(self, e)
	ltimer:clear()

	self:init2(e)

	self.paused = false
	self.is_logic_update_enabled = true
end
lf.init2 = function(self, e)
	self.fid = 0
	self.fid_diff = 0
	self.frame_length = e or 100
	self.frame_acc = 0

	self.fid_server = nil

	self.input_buffer = {}

	self.render_frame_length = 20
	self.render_frame_acc = -1
end
lf.GetFrameLength = function(self)
	return self.frame_length
end
lf.GetFid = function(self)
	return self.fid - self.fid_diff
end
lf.NextFrame = function(self)
--	print('NextFrame', self.fid)
	self.fid = self.fid + 1

	self:doUpdate(self.frame_length)
end
lf.Update = function(self, e)
	if self.render_frame_acc == -1 then
		if self:has_input() then
			self.render_frame_acc = 0
		end
		return
	end
	self.render_frame_acc = self.render_frame_acc + e
	local time_acc = 0
	while self.render_frame_acc >= self.render_frame_length do
		-- print('render_frame_acc', self.render_frame_acc, #self.input_buffer)
		if self.frame_acc >= self.frame_length then
			self.frame_acc = 0
			self:next_input()
		end
		if self.frame_acc == 0 then
			if not self:has_input() then
				self.render_frame_acc = 0
				-- print('no input')
				return
			end

			if #self.input_buffer >= 2 then
				self.render_frame_acc = self.render_frame_acc + self.render_frame_length * #self.input_buffer
			end
		end
		self.render_frame_acc = self.render_frame_acc - self.render_frame_length
		self.frame_acc = self.frame_acc + self.render_frame_length
		time_acc = time_acc + self.render_frame_length

		self:use_input()
		self:doUpdate(self.render_frame_length)

		-- 不让追帧追太多，但是会帧间隔大的时候出现no input的情况（因为积攒的e多了）
		if time_acc > 100 then
			return
		end
	end
end
lf.Pause = function(self, p)
	self.paused = p
end
lf.isPaused = function(self)
	return self.paused
end
lf.AddInput = function(self, input)
	--print('[AddInput]', self.paused, input.fid, self.fid_server, #self.input_buffer)

	if input.fid == 0 then
		self.fid_server = 0
		self.fid = 0
		return
	end

	-- print('AddInput', input.fid, #self.input_buffer, debug.traceback())
	assert(input.fid == self.fid_server + 1)
	self.fid_server = input.fid

	self.input_buffer[#self.input_buffer + 1] = input.inputs
end
lf.has_input = function(self)
	return #self.input_buffer > 0
end
lf.next_input = function(self)
	table.remove(self.input_buffer, 1)
end
lf.use_input = function(self)
	local input = self.input_buffer[1]
	for aid, data in next, input do
		-- print('UseInput', aid, data.dir)
		local r
		if aid == Global.Login:getAid() then
			r = Global.role
		else
			r = Global.EntityManager:get_role(aid)
		end
		if r then
			r:set_input(data)
		end
	end
end
------------------------------------------------------------
local blockEye = _Vector3.new()
local function updateCameraOrbit(e)
	if _G.cameraorbit == nil then return end

	if _G.cameraorbit.eye.current == 0 and _G.cameraorbit.look.current == 0 and _G.cameraorbit.start == false then
		_G.cameraorbit.start = true
		Global.CameraControl:push()
		local camera = Global.CameraControl:get()
		camera:followTarget()
		return
	end

	if _G.cameraorbit.start == false then return end

	if _G.cameraorbit.eye.current == _G.cameraorbit.eye.finish and _G.cameraorbit.look.current == _G.cameraorbit.look.finish then
		_G.cameraorbit.start = false
		Global.CameraControl:pop()
	end
	_G.cameraorbit.eye:update(e)
	_G.cameraorbit.look:update(e)
	local camera = Global.CameraControl:get()
	camera:setEyeLook(_G.cameraorbit.eye.pos, _G.cameraorbit.look.pos)
end
lf.enable_logic = function(self, e)
	self.is_logic_update_enabled = e
end
lf.doUpdate = function(self, e)
	self.fid = self.fid + 1

	ltimer:update(e)

	if not self.is_logic_update_enabled then return end
	if not Global.sen then return end

	if Global.role then
		Global.role:input_update_calc(e)

		-- 表情
		Global.FERManager:update(e)
	end

	Global.EntityManager:input_update(e)

	Global.Sound:update()
	-- 模拟
	BEGIN_RECORD('senUpdate')
	Global.sen:updateLoadingBlocks(e)
	if (Global.dungeon == nil) or Global.dungeon:is_playing() then
		Global.sen:update(e)
	end
	Global.sen:update_blocks(e)
	Global.sen:updateBgPfx(e)
	Global.sen:updateBlockUIs(e)
	END_RECORD('senUpdate')

	-- 逻辑
	Global.EntityManager:update(e)

	updateCameraOrbit(e)

	if Global.dungeon then
		Global.dungeon:update(e)
	end

	if Global.role and Global.role.mb.mesh and Global.role.mb.node then
		_rd.camera:getBlockEye(blockEye)
		local translation = Global.Container:get(_Vector3)
		Global.role:getPosition(translation)
		local dis = _Vector3.distance(translation, blockEye)
		Global.Container:returnBack(translation)
		if dis < 1 then
			Global.role.mb.node.tooNearByCam = true
		else
			Global.role.mb.node.tooNearByCam = false
		end
	end

	Global.EntityManager:update_render(e, 1)
	Global.CameraControl:idle(e)

	if Global.dungeon then
		Global.dungeon:updateBgRooms(_rd.camera.look)
	end
end
