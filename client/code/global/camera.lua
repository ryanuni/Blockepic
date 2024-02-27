
--[[
	摄像机控制（与app_mouse.lua结合）
	主要操作：move、rotate、zoom

	摄像机管理
	new/get/push/pop

	跟随处理（自己实现回调）
	followTarget
]]

local Camera = _dofile('camera_base.lua')
local Container = _require('Container')
local os = _sys.os
local cc = {count = 0, pos = {}, funcs = {}, current = Camera.new(), stack = {}}
Global.CameraControl = cc
cc.onStart = function(self, x, y, fid, count)
	self.pos[fid] = {
		x = x, y = y,
		dx = 0, dy = 0,
	}
	self.count = self.count + 1
end
cc.onStop = function(self, x, y, fid, count)
	self.pos[fid] = nil
	self.count = self.count - 1
end
cc.onMove = function(self, x, y, fid, count)
	local p = self.pos[fid]
	if not p then return end

	p.dx = x - p.x
	p.dy = y - p.y
	p.x = x
	p.y = y

	if os == 'win32' or os == 'mac' then
		for k, f in next, self.funcs do
			if _sys:isKeyDown(k) then
				self[f](self, fid)
			end
		end
	else
		for c, f in next, self.funcs do
			if self.count == c then
				self[f](self, fid)
			end
		end
	end
end
------------------------------------------------------
cc.onDeviceOrientation = function(self, isH)
	if Global.SwitchControl:is_cameracontrol_off() or Global.House.currentSize == 1 then return end

	local r = self.current:getScale()

	if not self.current.maxRadiusH then
		self.current.maxRadiusH = self.current.maxRadius
		self.current.maxRadiusV = self.current.maxRadius * 2
	end

	if isH then
		if self.current.maxRadius ~= self.current.maxRadiusH then
			self.current.maxRadius = self.current.maxRadiusH
			self.current:scale(r / 2)
		end
	else
		if self.current.maxRadius ~= self.current.maxRadiusV then
			self.current.maxRadius = self.current.maxRadiusV
			self.current:scale(r * 2)
		end
	end
end
------------------------------------------------------
cc.rotateAtom = function(self, dx, dy)
	if Global.SwitchControl:is_cameracontrol_off() then return end

	local c = self.current
	c:moveDirH(dx)
	c:moveDirV(dy)
end
cc.CONST_SCALE_ROTATE = 0.005
cc.rotate = function(self, fid)
	local p = self.pos[fid]
	self:rotateAtom(p.dx * self.CONST_SCALE_ROTATE, p.dy * self.CONST_SCALE_ROTATE)
end
cc.rotate2 = function(self)
	if self.count ~= 2 then return end

	local dx1, dx2, dy1, dy2
	local _, p1 = next(self.pos)
	local __, p2 = next(self.pos, _)
	dx1 = p1.dx
	dy1 = p1.dy

	dx2 = p2.dx
	dy2 = p2.dy

	local dx, dy
	if dx1 > 0 then
		dx = math.max(dx1, dx2)
	else
		dx = math.min(dx1, dx2)
	end

	if dy1 > 0 then
		dy = math.max(dy1, dy2)
	else
		dy = math.min(dy1, dy2)
	end

	self:rotateAtom(dx * 0.001, dy * 0.001)

return true
end
cc.moveLook = function(self, dx, dy)
	local dir = Container:get(_Vector3)
	local vx = Container:get(_Vector3)
	local vy = Container:get(_Vector3)
	local move = Container:get(_Vector3)
	_Vector3.sub(_rd.camera.look, _rd.camera.eye, dir)
	_Vector3.cross(dir, _rd.camera.up, vx)
	vx:normalize()
	_Vector3.cross(vx, _rd.camera.up, vy)
	vy:normalize()

	local dis = dir:magnitude() * 0.7
	vx:scale(dx * dis / _rd.camera.viewNear)
	vy:scale(dy * dis / _rd.camera.viewNear)
	_Vector3.add(vx, vy, move)
	move.z = 0
	_Vector3.add(move, _rd.camera.look, move)
	self.current:moveLook(move)
	Container:returnBack(dir, vx, vy, move)
end

cc.move = function(self, fid)
	if Global.SwitchControl:is_cameracontrol_off() then return end

	local p = self.pos[fid]
	local dx = p.dx
	local dy = p.dy
	self:moveLook(dx * 0.001, -dy * 0.001)
end
cc.zoomAtom = function(self, d)
	if Global.SwitchControl:is_cameracontrol_off() then return end

	self.current:scaleD(d)
end
cc.zoom2 = function(self)
	if self.count ~= 2 then return end

	local dx1, dx2, dy1, dy2
	local _, p1 = next(self.pos)
	local __, p2 = next(self.pos, _)
	dx1 = p1.dx
	dy1 = p1.dy

	dx2 = p2.dx
	dy2 = p2.dy
	if dx1 * dx2 < 0 or dy1 * dy2 < 0 then
		-- zoom
		local w1, w2, h1, h2
		w1 = math.abs((p1.x - dx1) - (p2.x - dx2))
		h1 = math.abs((p1.y - dy1) - (p2.y - dy2))
		w2 = math.abs(p1.x - p2.x)
		h2 = math.abs(p1.y - p2.y)

		local d
		if math.abs(w1 - w2) > math.abs(h1 - h2) then
			d = w1 - w2
		else
			d = h1 - h2
		end
		local dis = math.max(self.current:getScale(), 5) * 0.2
		self:zoomAtom(-d * 0.01 * dis)

		return true
	end

	return false
end
cc.zoomAndRotate2 = function(self)
	if self:zoom2() then return end
	self:rotate2()
end
------------------------------------------------------
cc.new = function(self)
	self.current = Camera.new()
	return self.current
end
cc.get = function(self)
	return self.current
end
cc.push = function(self)
	local c = self.current:clone()
	table.insert(self.stack, self.current)
	self:set(c)
end
cc.pop = function(self, t)
	local c = table.remove(self.stack)
	if not c then
		print('[CameraControl.pop] stack empty')
		return
	end
	self:set(c, t)
end
cc.set = function(self, c, t)
	if t then
		local oldv = self.current:getDirV()
		local oldh = self.current:getDirH()
		local newv = c:getDirV()
		local newh = c:getDirH()
		local news = c:getScale()

		self.current:moveLook(c.camera.look, t)
		self.current:moveDirH(newh - oldh, t)
		self.current:moveDirV(newv - oldv, t)
		self.current:scale(news, t)
	else
		self.current = c
	end
	c:use()
end
------------------------------------------------------
_app.cameraControl = function(self, t)
	cc.funcs = {}
	TEMP_WHEEL_CONTROL(true)

	if t then
		if os == 'win32' then
			for f, k in next, t do
				cc.funcs[k] = f
			end
		else
			for f, c in next, t do
				if c == 2 then
					f = f .. tostring(c)
				end
				cc.funcs[c] = f
			end
		end
	end
end
------------------------------------------------------

local cameraData = {
	dir = _Vector3.new(),
	hvdir = _Vector3.new(),
	vvdir = _Vector3.new(),
	distance = 0,

	xasix = _Vector3.new(1, 0, 0),
	yasix = _Vector3.new(0, 1, 0),
	zasix = _Vector3.new(0, 0, 1),
	masix = _Vector3.new(1, 1, 1),
}
Global.cameraData = cameraData

function _G.updateCameraData()
	local dir = cameraData.dir
	local hvdir = cameraData.hvdir
	local vvdir = cameraData.vvdir
	local masix = cameraData.masix

	_Vector3.sub(_rd.camera.look, _rd.camera.eye, dir)
	cameraData.distance = _rd.camera.radius

	_Vector3.cross(_rd.camera.up, dir, hvdir)
	hvdir:normalize()
	_Vector3.cross(dir, hvdir, vvdir)
	vvdir:normalize()

	dir:normalize()
	local x = math.abs(dir.x)
	local y = math.abs(dir.y)
	local z = math.abs(dir.z)
	local max = math.max(x, y, z)
	masix:set(1, 1, 1)
	if max == x then
		_Vector3.sub(masix, cameraData.xasix, masix)
	elseif max == y then
		_Vector3.sub(masix, cameraData.yasix, masix)
	elseif max == z then
		_Vector3.sub(masix, cameraData.zasix, masix)
	end
end

local diff = _Vector3.new()
function _G.getCameraDataDiff(dx, dy, d)
	local cameraData = Global.cameraData
	local dir = cameraData.dir

	d = d or cameraData.distance
	diff:set(0, 0, 0)
	local vec1 = Container:get(_Vector3)
	local vec2 = Container:get(_Vector3)
	_Vector3.mul(cameraData.vvdir, dy * -0.0007 * d, vec1)
	_Vector3.mul(cameraData.hvdir, dx * 0.0007 * d, vec2)
	_Vector3.add(diff, vec1, diff)
	_Vector3.add(diff, vec2, diff)
	diff.x = diff.x * cameraData.masix.x
	diff.y = diff.y * cameraData.masix.y
	diff.z = diff.z * cameraData.masix.z
	Container:returnBack(vec1, vec2)
	return diff
end

-- 根据包围盒设置合适的摄像机距离
-- 注：只考虑摄像机look点在原点
local tempcam = _Camera.new()
_G.calcCameraRadius = function(cam, aabb, db, extend)
	--if extend ~= nil then newaabb = aabb:mul(extend) else newaabb = aabb end
	local zaxis = Container:get(_Vector3)
	_Vector3.sub(cam.look, cam.eye, zaxis)
	zaxis:normalize()

	local r = cam.radius
	if cam ~= _rd.camera then
		tempcam:set(_rd.camera)
		_rd.camera:set(cam)
	end

	local radius = r
	if db then
		--_rd:useDrawBoard(camdb, _Color.Null)
		_rd:usePickBoard(0, 0, db.w, db.h)
	end

	local w = db and db.w or _rd.w
	local h = db and db.h or _rd.h
	local hw = w / 2
	local hh = h / 2

	local ret = Container:get(_Vector2)
	local p = Container:get(_Vector3)
	for i = 1, 8 do
		aabb:getPoint(i, p)
		_rd:projectPoint(p.x, p.y, p.z, ret)
		_Vector3.sub(p, cam.eye, p)

		if ret.x < 0 or ret.x > w then
			local w = math.abs(ret.x / hw - 1)
			local x = _Vector3.dot(p, zaxis)
			local nr = math.abs(w * x) + r - x
			radius = math.max(nr, radius)
		end
		if ret.y < 0 or ret.y > h then
			local w = math.abs(ret.y / hh - 1)
			local x = _Vector3.dot(p, zaxis)
			local nr = math.abs(w * x) + r - x
			radius = math.max(nr, radius)
		end
	end

	if db then _rd:resetPickBoard() end

	if radius > r then
		cam:moveRadius(radius - r)
	end

	if cam ~= _rd.camera then
		_rd.camera:set(tempcam)
	end

	Container:returnBack(zaxis, ret, p)

	--print('!!!!!!!calcCameraRadius:', radius > r and radius or r)
	return radius > r and radius or r
end

_G.projectWithSize = function(center, size)
	local v3_1 = Container:get(_Vector3)
	local v3_2 = Container:get(_Vector3)
	local v3_3 = Container:get(_Vector3)
	local v2_1 = Container:get(_Vector2)
	local v2_2 = Container:get(_Vector2)

	local dir = Container:get(_Vector3)
	_Vector3.sub(_rd.camera.look, _rd.camera.eye, dir)
	dir:normalize()

	v3_1:set(center)
	_Vector3.sub(v3_1, _rd.camera.eye, v3_2)
	v3_2:project(dir, v3_3)

	_Vector3.sub(v3_3, v3_2, v3_2)
	v3_2:normalize()

	_Vector3.mul(v3_2, size, v3_2)
	_Vector3.add(v3_2, v3_1, v3_2)

	_rd:projectPoint(v3_1.x, v3_1.y, v3_1.z, v2_1)
	_rd:projectPoint(v3_2.x, v3_2.y, v3_2.z, v2_2)
	_Vector2.sub(v2_2, v2_1, v2_2)
	local s = v2_2:magnitude()

	Container:returnBack(dir, v3_1, v3_2, v3_3, v2_1, v2_2)
	return v2_1.x, v2_1.y, s
end

cc.idle = function(self, e)
	local c = self.current
	if c.onIdle then
		c:onIdle(e)
	end

	c:update()
	c:use()
--	if c.Debug then
--		c:Debug()
--	end
end
