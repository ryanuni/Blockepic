local Container = _require('Container')
Global.Container = Container
--------------------------------------
local frame = {index = 0}
frame.update = function(self)
	frame.index = frame.index + 1
end
frame.get = function(self)
	return self.index
end
_G.CurrentFrame = function()
	return frame.index
end
_app:registerUpdate(frame, 1)
--------------------------------------
function string.split(input, delimiter, usepattern)
	local nopattern = not usepattern
	input = tostring(input)
	delimiter = tostring(delimiter)
	if delimiter == '' then return false end
	local pos, arr = 0, {}
	for st, sp in function() return string.find(input, delimiter, pos, nopattern) end do
		table.insert(arr, string.sub(input, pos, st - 1))
		pos = sp + 1
	end
	table.insert(arr, string.sub(input, pos))
	return arr
end
--------------- 打印助手 --------------- 
_Vector2.__tostring = function(self)
	return string.format('vec2:%.3f, %.3f', self.x, self.y)
end

_Vector3.__tostring = function(self)
	return string.format('vec3:%.3f, %.3f, %.3f %p', self.x, self.y, self.z, self)
end
local tmp_v3 = _Vector3.new()
_Vector3.equal2 = function(v1, v2)
	_Vector3.sub(v1, v2, tmp_v3)
	return tmp_v3:magnitude() < 0.0001
end
_Vector4.__tostring = function(self)
	return string.format('vec4:%.3f, %.3f, %.3f, %.3f', self.x, self.y, self.z, self.w)
end

_Matrix3D.__tostring = function(self)
	local t = Container:get(_Vector3)
	local r = Container:get(_Vector4)
	local s = Container:get(_Vector3)
	self:getTranslation(t)
	self:getRotation(r)
	self:getScaling(s)
	return '\ntrans:' .. t:__tostring() .. '\nrotate:' .. r:__tostring() .. '\nscale:' .. s:__tostring()
end

local tmpv1 = _Vector3.new()
local tmpv2 = _Vector3.new()
_AxisAlignedBox.__tostring = function(self)
	self:getCenter(tmpv1)
	self:getSize(tmpv2)
	return '\ncenter:' .. tmpv1:__tostring() .. '\nsize:' .. tmpv2:__tostring()
end

_G.printMat = function(mat)
	local v = Container:get(_Vector3)
	mat:getTranslation(v)
	local p = mat.parent
	print('withparent', v.x, v.y, v.z, p ~= nil)
	mat.parent = nil
	mat:getTranslation(v)
	print('self', v.x, v.y, v.z)
	mat.parent = p
	Container:returnBack(v)
end
_G.copyMat = function(dst, src)
	local pd = dst.parent
	local ps = src.parent
	src.parent = nil
	dst:set(src)
	src.parent = ps
	dst.parent = pd
end
_G.printVec3 = function(v)
	print(v.x, v.y, v.z)
end

local c = _Camera.new()
local cameratostring = c.__tostring

_G.printCamera = function(c)
	c = c or _rd.camera
	print('Camera', cameratostring(c))
	print('Eye', c.eye)
	print('Look', c.look)
	print('Up', c.up)
	print('Radius', c.radius)
	print('ortho', c.ortho)
end

_Camera.__tostring = function(self)
	return ('cam:%s\neye:%s\nlook:%s\nup:%s fov:%s radius:%s'):format(cameratostring(self), self.eye:__tostring(), self.look:__tostring(), self.up:__tostring(), tostring(self.fov), tostring(self.radius))
end

local dir_vec = _Vector3.new()
_Camera.dir = function(self)
	_Vector3.sub(self.look, self.eye, dir_vec)
	dir_vec:normalize()
	return dir_vec
end

local right_vec = _Vector3.new()
_Camera.right = function(self)
	_Vector3.sub(self.look, self.eye, right_vec)
	_Vector3.cross(self.up, right_vec, right_vec)
	right_vec:normalize()
	return right_vec
end

_G.copyAABB = function(dst, src)
	dst.min.x = src.min.x
	dst.min.y = src.min.y
	dst.min.z = src.min.z

	dst.max.x = src.max.x
	dst.max.y = src.max.y
	dst.max.z = src.max.z
end

------------------------------------------------------
if not _DrawBoard.new(1, 1).resize then
	_DrawBoard.resize = function(self, w, h)
		self.w = w
		self.h = h
	end
end
------------------------------------------------------
local dumpvisited

local function indented(level, ...)
	print(table.concat({('  '):rep(level), ...}))
end
local function dumpval(level, name, value, limit)
	if debug.dumpForAutoTest then
		if type(value) == 'table' then
			if type(name) == 'string' then
				if name:find('table') and name:find(': 0x') then
					name = 'table'
				end
			end
		end
	end

	local index
	if type(name) == 'number' then
		index = string.format('[%d] = ', name)
	elseif type(name) == 'string' and (name == '__VARSLEVEL__' or name == '__ENVIRONMENT__' or name == '__GLOBALS__' or name == '__UPVALUES__' or name == '__LOCALS__') then
	--ignore these, they are debugger generated
		return
	elseif type(name) == 'string' and string.find(name, '^[_%a][_.%w]*$') then
		index = name .. ' = '
	else
		index = string.format('[%q] = ', tostring(name))
	end
	if type(value) == 'table' then
		if dumpvisited[value] then
			indented(level, index, string.format('ref%q;', dumpvisited[value]))
		else
			dumpvisited[value] = name
			if (limit or 0) > 0 and level + 1 >= limit then
				indented(level, index, tostring(dumpvisited[value]))
			else
				indented(level, index, '{  -- ', tostring(dumpvisited[value]))
				for n, v in pairs(value) do
					dumpval(level + 1, n, v, limit)
				end
				dumpval(level + 1, '.meta', getmetatable(value), limit)
				indented(level, '};')
			end
		end
	else
		if type(value) == 'string' then
			if string.len(value) > 40 then
				indented(level, index, '[[', value, ']];')
			else
				indented(level, index, string.format('%q', value), ';')
			end
		else
			indented(level, index, tostring(value), ';')
		end
	end
end

local function dumpvar(value, limit, name)
	dumpvisited = {}
	dumpval(0, name or tostring(value), value, limit)
	dumpvisited = nil
end

debug.dumpdepth = 5
debug.dumpForAutoTest = false

function _G.dump(v, depth)
	dumpvar(v, (depth or debug.dumpdepth) + 1, tostring(v))
end

-------------------fairy 富文本-------------------

---生成富文本img串
---
---@param icon string
---@param width string
---@param height string
---@param offsetx string
---@param offsety string
---@nodiscard
function _G.genHtmlImg(icon, width, height, offsetx, offsety)
	local w = width and string.format("width= '%s'", width) or ''
	local h = height and string.format("height= '%s'", height) or ''
	local offsetx = offsetx and string.format("offsetx= '%s'", offsetx) or ''
	local offsety = offsety and string.format("offsety= '%s'", offsety) or ''
	return string.format("<img src= '%s' %s %s %s %s/>", icon, w, h, offsetx, offsety)
end

------------------Timer-------------------------

local timerManager = {
	timers = {},
}

timerManager.addTimer = function(self)
	local timer = _Timer.new()
	table.insert(self.timers, timer)
	return timer
end

timerManager.removeTimer = function(self, timer)
	table.remove(self.timers, self:indexTimer(timer))
end

timerManager.indexTimer = function(self, timer)
	for i, v in ipairs(self.timers) do
		if v == timer then
			return i
		end
	end
	return -1
end

timerManager.add = function(self, name, delay, func)
	local timer = self:addTimer()
	timer:start(name, delay, function()
		timer:stop(name)
		self:removeTimer(timer)
		func()
	end)
end

Global.Timer = timerManager

---------------------------------------------------------

local soundManager = {
	sounds = {},
}

soundManager.addSound = function(self)
	local sound = _SoundGroup.new()
	table.insert(self.sounds, sound)
	return sound
end

soundManager.removeSound = function(self, sound)
	table.remove(self.sounds, self:indexSound(sound))
end

soundManager.indexSound = function(self, sound)
	for i, v in ipairs(self.sounds) do
		if v == sound then
			return i
		end
	end
	return -1
end

soundManager.play = function(self, name, duration)
	local sound = self:addSound()
	duration = duration or 100000
	sound:play(name)
	Global.Timer:add(name, duration + 1000, function()
		self:removeSound(sound)
	end)
end

Global.SoundManager = soundManager
----------------lua function override---------------------------------
--[[

local f = lua_getFunction(_rd, 'useDrawBoard')
lua_setFunction(_rd, 'useDrawBoard', function(self, ...)
	print(debug.traceback())
	f(_rd, ...)
end)

local m = _Mesh.new()
local f = lua_getFunction(m, 'clone')
lua_setFunction(m, 'clone', function(self, ...)
	local ret = f(self, ...)
	print(debug.traceback())
	return ret
end)

]]
_G.lua_getFunction = function(obj, name)
	local f = debug:getmetaread(obj)[name]
	if f == nil then
		error('No function named:' .. name)
	end
	return f
end
_G.lua_setFunction = function(obj, name, func)
	local mt = debug:getmetaread(obj)
	mt[name] = func
end

------------------------------------------------------------------
_G.traceback = function(p)
	if p then
		print(p, debug.traceback())
	else
		print(debug.traceback())
	end
end