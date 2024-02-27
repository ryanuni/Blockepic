local Container = _require('Container')

local debug = {visible = false}
Global.Debug = debug
_dofile('debug_profile.lua')
_dofile('debug_objectcount.lua')

local oldcount = 0
debug.gg = function()
	local newcount = collectgarbage('count')
	local ret = newcount - oldcount
	oldcount = newcount
	print('[LUA GC COUNT DIFF]', ret)
end

debug.infos = {
	matrix = {},
	vec3s = {},
	links = {},
	texts = {},
	Add = function(self, name, object, objectp)
		if not object then
			self.texts[#self.texts + 1] = name
		elseif object.typeid == _Matrix3D.typeid then
			self.matrix[name] = {o = object}
		elseif object.typeid == _Vector3.typeid and objectp then
			self.links[name] = {o1 = object, o2 = objectp}
		elseif object.typeid == _Vector3.typeid then
			self.vec3s[name] = {o = object}
		else
			self.texts[#self.texts + 1] = name
		end
	end,
	Clear = function(self)
		self.matrix = {}
		self.vec3s = {}
		self.links = {}
		self.texts = {}
	end
}

debug.render = function(self)
	if self.visible == false then return end

	local s = string.format("Mode:%s",
		Global.GameState.state.name)

	s = s .. '\nElapse:' .. Global.FrameSystem.render_frame_acc
	s = s .. '\nFrameBuffer:' .. (#Global.FrameSystem.input_buffer)

	if Global.role and Global.role.cct then
		s = s .. '\nCCT:' .. Global.role.cct.collisionFlag
	end

	local bo = Global.Browser:getCurrentObject()
	if bo then
		s = s .. string.format('\nBrowserObject:%s | %s', bo.id, bo.name)
	end

	if Global.editor.selectedGroup then
		s = s .. '\nGroupID:' .. Global.sen:indexGroup(Global.editor.selectedGroup)
	end

	for i, b in ipairs(Global.editor.selectedBlocks) do
		s = s .. '\nBlockID:' .. Global.sen:indexBlock(b)
		local vec = Container:get(_Vector3)
		b:getTransform():getTranslation(vec)
		s = s .. '\nmesh:' .. b.node.mesh.resname
		s = s .. '\nposition x:' .. vec.x .. ', y: ' .. vec.y .. ', z: ' .. vec.z
		Container:returnBack(vec)
	end

	local v = _rd.camera.eye
	s = s .. string.format('\nEye :%.2f, %.2f, %.2f', v.x, v.y, v.z)
	v = _rd.camera.look
	s = s .. string.format('\nLook:%.2f, %.2f, %.2f', v.x, v.y, v.z)
	v = _rd.camera.up
	s = s .. string.format('\nUp:%.2f, %.2f, %.2f', v.x, v.y, v.z)
	s = s .. string.format('\nFov:%.2f', _rd.camera.fov)

	_rd.font:drawText(_rd.w / 2, _rd.h / 2, s)

	local vec3 = Container:get(_Vector3)
	local vec2 = Container:get(_Vector2)
	for n, v in next, self.infos.matrix do
		_rd:pushMatrix3D(v.o)
		_rd:drawAxis(1)
		_rd:popMatrix3D()

		v.o:getTranslation(vec3)
		_rd:projectPoint(vec3.x, vec3.y, vec3.z, vec2)

		_rd.font:drawText(vec2.x, vec2.y, n)
	end
	for n, v in next, self.infos.vec3s do
		_rd:projectPoint(v.o.x, v.o.y, v.o.z, vec2)
		_rd.font:drawText(vec2.x, vec2.y, n)
	end
	for n, v in next, self.infos.links do
		_rd:draw3DLine(v.o1.x, v.o1.y, v.o1.z, v.o2.x, v.o2.y, v.o2.z, _Color.Green)
		_rd:projectPoint(v.o1.x, v.o1.y, v.o1.z, vec2)
		_rd.font:drawText(vec2.x, vec2.y, n)
	end

	local ty = 5
	for i = math.max(#self.infos.texts - 30, 1), #self.infos.texts do
		_rd.font:drawText(20, ty, self.infos.texts[i])
		ty = ty + 16
	end

	if Global.FERManager.inited then
		_rd.font:drawText(10, 10, Global.FERManager:getState())
	end

	Container:returnBack(vec3, vec2)
end

debug.switch = function(self)
	self.visible = not self.visible
	_debug.enable = self.visible
	if self.visible then
		_debug:registerRender(self, self.render)
	else
		_debug:registerRender(self)
	end
end

debug.monitor = false

local funcs = {}
_debug.registerRender = function(self, t, f)
	funcs[t] = f
end

local mh_server = _sys:getGlobal('mh_server')
if not mh_server then
	-- TODO：_debug:onRender与mobilehelper冲突
	_debug:onRender(function()
		for t, f in next, funcs do
			f(t)
		end
	end)
end