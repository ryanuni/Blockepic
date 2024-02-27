
local Camera = {}
local Container = _require('Container')
-- setmetatable(Camera, {__newindex = function(t, k, v)
-- 	local vv = v
-- 	if type(v) == 'function' then
-- 		if k ~= 'update' and k ~= 'use' and
-- 			k ~= 'blockFeet' and k ~= 'followRole' and
-- 			k ~= 'moveLook' and k ~= 'setblockRayOrigin'

-- 			then
-- 			vv = function(self, ...)
-- 				print(k, self, ..., debug.traceback())
-- 				return v(self, ...)
-- 			end
-- 		end
-- 	end
-- 	rawset(t, k, vv)
-- end})

Camera.new = function()
	local c = {}
	setmetatable(c, {__index = Camera})
	c.matLook = _Matrix3D.new()
	c.matRadius = _Matrix3D.new()

	-- 水平
	c.matH = _Matrix3D.new()
	-- 竖直
	c.matV = _Matrix3D.new()
	c.matCalc = _Matrix3D.new()

	c.camera = _Camera.new()
	c:reset()

	return c
end
Camera.clone = function(self)
	local c = Camera.new()
	for k, v in next, self do
		if type(v) == 'table' then
			if v.typeid == _Matrix3D.typeid or v.typeid == _Camera.typeid then
				c[k]:set(v)
			end
		else
--			print('[Camera.clone]', type(v), k)
			c[k] = v
		end
	end

	return c
end
Camera.print = function(self)
	printCamera(self.camera)
	local a = self.matV:getRotationY()
	print('DirV:' .. a)
	a = self.matH:getRotationZ()
	print('DirH:' .. a)
	print('fov:' .. self.camera.fov)
	print('minR,maxR,minV,maxV:', self.minRadius, self.maxRadius, self.minV, self.maxV)
end
-------------------------------------------
Camera.reset = function(self)
	self.matLook:identity()
	self.matRadius:identity()
	self.minRadius = 3
	self.maxRadius = 20
	self:scale(6)
	-- 水平
	self.matH:identity()
	-- 竖直
	self.matV:identity()
	self.matCalc:identity()
	-- 这样设置，由于设置了相机的block，在更新摄像机的时候会pick场景。而设置eye点、look点都会更新Camera，每帧有可能会被调用很多次，导致pick场景被执行非常多次，很卡。
	-- 所以设置eye、look等信息时，不根据blocker更新相机，而手动每帧调用一次。
	self.blockAutoUpdate = false
	self.camera.viewNear = 0.15
	self.camera.viewFar = 500
	self.camera.look:set(0, 0, 0)
	self.camera.eye:set(-6, 0, 0)
	self.camera.up:set(0, 0, 1)
	self:lockDirV(-1.4, 1.4)
	self.minZ = nil
end
Camera.lockZ = function(self, minz)
	self.minZ = minz
	if self.minZ then
		local look = Container:get(_Vector3)
		self.matLook:getTranslation(look)
		look.z = math.max(look.z, self.minZ)
		self:moveLook(look)
		Container:returnBack(look)
	end
end
Camera.push = function(self, d)
	self:update()
	local dir = Container:get(_Vector3)
	local look = self.camera.look
	_Vector3.sub(look, self.camera.eye, dir)
	dir:scale(d)
	if self.minZ then
		if look.z + dir.z < self.minZ then
			return
		end
	end
	_Vector3.add(look, dir, dir)
	self:moveLook(dir)
	Container:returnBack(dir)
end
Camera.scale = function(self, s, t)
	self:setTick(t)
	s = math.max(s, self.minRadius)
	s = math.min(s, self.maxRadius)
	s = -s
	local v = Container:get(_Vector3)
	self.matRadius:getTranslation(v)
	self.matRadius:mulTranslationRight(s - v.x, 0, 0, t)
	Container:returnBack(v)
end
Camera.scaleD = function(self, ds, t)
	self:setTick(t)
	local v = Container:get(_Vector3)
	self.matRadius:getTranslation(v)

	local dis
	if -ds - v.x < self.minRadius then
		dis = self.minRadius - (-ds - v.x)
		ds = -self.minRadius - v.x
	end
	if -ds - v.x > self.maxRadius then
		ds = -self.maxRadius - v.x
	end

	Container:returnBack(v)

	self.matRadius:mulTranslationRight(ds, 0, 0, t)
	if dis then
		self:push(dis)
	end
end
Camera.getScale = function(self)
	local v = Container:get(_Vector3)
	self.matRadius:getTranslation(v)
	local s = - v.x
	Container:returnBack(v)
	return s
end

Camera.moveLook = function(self, l, t, c)
	self:setTick(t)

	if self.minZ then
		l.z = math.max(l.z, self.minZ)
	end
	local v = Container:get(_Vector3)
	self.matLook:getTranslation(v)
	_Vector3.sub(l, v, v)
	self.matLook:mulTranslationRight(v, t)
	Container:returnBack(v)
	if c then
		self.matLook:applyCurve(Global.Curves[c])
	end
end
Camera.moveLookD = function(self, d, t, c)
	self:setTick(t)
	local v = Container:get(_Vector3)
	self.matLook:getTranslation(v)
	_Vector3.add(v, d, v)
	self:moveLook(v, t, c)
	Container:returnBack(v)
end

Camera.setblockRayOrigin = function(self, start)
	if not self.blockRayEnd then
		self.blockRayEnd = _Vector3.new()
	end

	local eye = self.camera.eye
	self.blockRayEnd.x = eye.x
	self.blockRayEnd.y = eye.y
	self.blockRayEnd.z = eye.z
	self.camera:setBlockRay(start, self.blockRayEnd)
end
Camera.lockDirH = function(self, min, max)
	self.minH = min
	self.maxH = max
end
Camera.moveDirH = function(self, a, t, c)
	self:setTick(t)
	local olda = self:getDirH()
	a = a + olda

	if self.maxH then
		if self.maxH > math.pi or self.minH < math.pi then
			local mid = (self.maxH + self.minH) / 2
			local ran = (self.maxH - self.minH) / 2
			local dis = math.clampRadius(a - mid)
			dis = math.min(dis, ran)
			dis = math.max(dis, -ran)
			a = dis + mid
		else
			-- todo 改成上面的
			if a > self.maxH then
				a = self.maxH
			elseif a < self.minH then
				a = self.minH
			end
		end
	end

	self.matH:mulRotationZRight(math.clampRadius(a - olda), t)
	if c then
		self.matH:applyCurve(Global.Curves[c])
	end
end
Camera.getDirH = function(self)
	return self.matH:getRotationZ()
end
Camera.lockDirV = function(self, min, max)
	self.minV = min
	self.maxV = max
end
Camera.moveDirV = function(self, a, t)
	self:setTick(t)
--	print('[Camera.moveDirV]', a, t)
	local olda = self:getDirV()
	a = a + olda

	if self.maxV then
		if a > self.maxV then
			a = self.maxV
		elseif a < self.minV then
			a = self.minV
		end
	end

	self.matV:mulRotationYRight(a - olda, t)
end
Camera.getDirV = function(self)
	return self.matV:getRotationY()
end
Camera.update = function(self)
	local v = Container:get(_Vector3)
	v:set(0, 0, 0)
	self.matCalc:set(self.matRadius)
	self.matCalc:mulRight(self.matV)
	self.matCalc:mulRight(self.matH)
	self.matCalc:apply(v, v)

	local look = Container:get(_Vector3)
	self.matLook:getTranslation(look)
	self.camera.look:set(look)
	_Vector3.add(v, look, v)
	self:blockFeet(v)
	self.camera.eye:set(v)

	Container:returnBack(v, look)
end
Camera.use = function(self)
	_rd.camera = self.camera
	-- 注意这里的update不是Camera.update,是_Camera.update!
	self.camera:update()
end
Camera.setCamera = function(self, c, t)
	-- print('setCamera', c.eye, c.look)
	self:setTick(t)
	t = t or 0
	self.camera.fov = c.fov
	self.camera.viewport = c.viewport
	self.camera.ortho = c.ortho
	self.camera.up = c.up
	self.camera.viewWidthScale = c.viewWidthScale
	self.camera.viewHeightScale = c.viewHeightScale
	self:scale(c.radius, t)

	self:moveLook(c.look, t)
	local v = Container:get(_Vector3)
	_Vector3.sub(c.look, c.eye, v)
	self:initMatH()
	local ah = self:prepareAngle(v)
	Container:returnBack(v)
	self:moveDirH(ah, t)

	local dz = c.eye.z - c.look.z
	local av = math.asin(dz / c.radius)
	local oldav = self.matV:getRotationY()
	self:moveDirV(av - oldav, t)
end
Camera.setUp = function(self, up)
	self.camera.up:set(up)
end
Camera.setEyeLook = function(self, e, l)
	local c = _Camera.new()
	c.eye:set(e)
	c.look:set(l)
	self:setCamera(c)
end

-- todo : 使用引擎提供的接口，camera里的tick和绑定在上面的curve.
Camera.setTick = function(self, tick)
	if tick and tick > 0 then self.endtick = os.now() + tick end
end

Camera.isAutoMoving = function(self)
	return self.endtick and self.endtick > os.now()
end
-------------------------------------------
Camera.initMatH = function(self)
	local mat = Container:get(_Matrix3D)
	local camx = self.camera.look.x - self.camera.eye.x
	local camy = self.camera.look.y - self.camera.eye.y

	mat:setFaceTo(6, 0, 0, camx, camy, 0)
	self.matH:set(mat)

	Container:returnBack(mat)
end

Camera.prepareAngle = function(self, dir)
	local mat = Container:get(_Matrix3D)
	local camx = self.camera.look.x - self.camera.eye.x
	local camy = self.camera.look.y - self.camera.eye.y

	-- 获取当前的角度，做一次set操作
	mat:setFaceTo(6, 0, 0, camx, camy, 0)

	-- 获取要转的角度
	mat:setFaceTo(camx, camy, 0, dir.x, dir.y, 0)
	local radian = mat:getRotationZ()

	Container:returnBack(mat)

	return radian
end
Camera.turnToward = function(self, dir, t, c, la)
	-- dir to angle
	local a = self:prepareAngle(dir)
	if la then
		-- 最大角度限制
		local absa = math.abs(a)
		if math.pi - absa < 0.000001 then
			return
		end

		if absa > la then
			a = a > 0 and la or -la
		end
	end
	self:moveDirH(a, t, c)
end
Camera.onWin = function(self, t, c, la)
	-- 平视
	local olda = self.matV:getRotationY()
	self:moveDirV(-olda, t, c)
	-- 近距离
	self:scale(6)
	-- 看头顶
	local look = _rd.camera.look:clone()
	look.z = look.z + 0.5
	self:moveLook(look, t, c)
end
Camera.setOrtho = function(self, o)
	self.camera.ortho = o
end
Camera.setViewScale = function(self, w, h)
	self.camera.viewWidthScale = w
	self.camera.viewHeightScale = h
end
---------------------------------------------
local blockstart = _Vector3.new()
Camera.followRole = function(self)
	if self:isAutoMoving() then return end
	local r = Global.role
	if not r then return end

	local dhl = self.dirH_limit
	if dhl and dhl < math.pi*2 then
		dhl = dhl / 2
		local mat = Container:get(_Matrix3D)
		mat:setFaceTo(6, 0, 0, r.mb.mesh.dir.x, r.mb.mesh.dir.y, 0)
		local radian = mat:getRotationZ()
		Container:returnBack(mat)
		self:lockDirH(radian - dhl, radian + dhl)
	end

	-- assert(r, 'no role in ' .. Global.sen.resname)
	local v = Container:get(_Vector3)

	r:get_position_render(v)
	v.z = v.z + r:getEyeHeight()

	blockstart.x = v.x
	blockstart.y = v.y
	blockstart.z = v.z

	-- TODO:影响进入场景效果
	-- if self.enableSlowDown and Global.GameState:isState('GAME') then
	-- 	-- 故意让摄像机慢一拍
	-- 	local curz = self.camera.look.z
	-- 	if math.abs(curz - v.z) > zLimit then
	-- 		-- 增速
	-- 		local deltaZ = curz - v.z
	-- 		local a1 = a * math.ceil(math.abs(deltaZ / zacc))
	-- 		local max = FALL_MAX * e
	-- 		a1 = a1 > max and max or a1
	-- 		if curz > v.z then
	-- 			local tmpz = curz - a1
	-- 			v.z = tmpz > v.z and tmpz or v.z
	-- 		else
	-- 			local tmpz = curz + a1
	-- 			v.z = tmpz > v.z and v.z or tmpz
	-- 		end
	-- 	end
	-- end

	-- look点不跟人，为了保证阻挡效果正确，只能将人的位置设置给camera，用于作block检测。
	self:setblockRayOrigin(blockstart)

	self:moveLook(v)
	Container:returnBack(v)
end
Camera.followRoleInHouse = function(self)
	self:followRole()

	local look = Container:get(_Vector3)
	self.matLook:getTranslation(look)
	self:blockArea(look)
	self:moveLook(look)
	Container:returnBack(look)
end
Camera.setRoleArea = function(self, l, t, r, b)
	self.rolearea = {l = l, t = t, r = r, b = b}
end
Camera.setInsideArea = function(self, l, t, r, b)
	self.insidearea = {l = l, t = t, r = r, b = b}
end
Camera.followRoleInArea = function(self)
	local x1, x2, y1, y2 = self.rolearea.l, self.rolearea.r, self.rolearea.t, self.rolearea.b
	local o1 = _rd:buildRay(_rd.w * x1, _rd.h * y1)
	local o2 = _rd:buildRay(_rd.w * x2, _rd.h * y2)

	local rp = Container:get(_Vector3)
	rp:set(0, 0, 0)
	local rd = Container:get(_Vector3)
	rd:set(1, 0, 0)

	local p1 = Container:get(_Vector3)
	local d1 = Container:get(_Vector3)
	local r1 = Container:get(_Vector3)
	p1:set(o1.x1, o1.y1, o1.z1)
	d1:set(o1.x2, o1.y2, o1.z2)
	assert(d1.x * rd.x + d1.y * rd.y + d1.z * rd.z ~= 0)

	local m = ((rp.x - p1.x) * rd.x + (rp.y - p1.y) * rd.y + (rp.z - p1.z) * rd.z) / (rd.x * d1.x + rd.y * d1.y + rd.z * d1.z)
	r1:set(p1.x + d1.x * m, p1.y + d1.y * m, p1.z + d1.z * m)

	local p2 = Container:get(_Vector3)
	local d2 = Container:get(_Vector3)
	local r2 = Container:get(_Vector3)
	p2:set(o2.x1, o2.y1, o2.z1)
	d2:set(o2.x2, o2.y2, o2.z2)
	assert(d2.x * rd.x + d2.y * rd.y + d2.z * rd.z ~= 0)

	local m = ((rp.x - p2.x) * rd.x + (rp.y - p2.y) * rd.y + (rp.z - p2.z) * rd.z) / (rd.x * d2.x + rd.y * d2.y + rd.z * d2.z)
	r2:set(p2.x + d2.x * m, p2.y + d2.y * m, p2.z + d2.z * m)

	local rpos = Container:get(_Vector3)
	local dp = Container:get(_Vector3)
	Global.role:getPosition(rpos)
	dp:set(0, 0, 0)
	if rpos.y < r1.y then
		dp.y = rpos.y - r1.y
	elseif rpos.y > r2.y then
		dp.y = rpos.y - r2.y
	end
	if rpos.z < r2.z then
		dp.z = rpos.z - r2.z
	elseif rpos.z > r1.z then
		dp.z = rpos.z - r1.z
	end

	if (dp.y ~= 0 or dp.z ~= 0) and self.insidearea then
		local o3 = _rd:buildRay(0, 0)
		local o4 = _rd:buildRay(_rd.w, _rd.h)

		local p3 = Container:get(_Vector3)
		local d3 = Container:get(_Vector3)
		local r3 = Container:get(_Vector3)
		p3:set(o3.x1, o3.y1, o3.z1)
		d3:set(o3.x2, o3.y2, o3.z2)
		assert(d3.x * rd.x + d3.y * rd.y + d3.z * rd.z ~= 0)

		local m = ((rp.x - p3.x) * rd.x + (rp.y - p3.y) * rd.y + (rp.z - p3.z) * rd.z) / (rd.x * d3.x + rd.y * d3.y + rd.z * d3.z)
		r3:set(p3.x + d3.x * m, p3.y + d3.y * m, p3.z + d3.z * m)

		local p4 = Container:get(_Vector3)
		local d4 = Container:get(_Vector3)
		local r4 = Container:get(_Vector3)
		p4:set(o4.x1, o4.y1, o4.z1)
		d4:set(o4.x2, o4.y2, o4.z2)
		assert(d2.x * rd.x + d4.y * rd.y + d4.z * rd.z ~= 0)

		local m = ((rp.x - p4.x) * rd.x + (rp.y - p4.y) * rd.y + (rp.z - p4.z) * rd.z) / (rd.x * d4.x + rd.y * d4.y + rd.z * d4.z)
		r4:set(p4.x + d4.x * m, p4.y + d4.y * m, p4.z + d4.z * m)

		dp.y = math.max(self.insidearea.l - r3.y, dp.y)
		dp.y = math.min(self.insidearea.r - r4.y, dp.y)
		dp.z = math.min(self.insidearea.t - r3.z, dp.z)
		dp.z = math.max(self.insidearea.b - r4.z, dp.z)
		Container:returnBack(p3, d3, r3, p4, d4, r4)
	end

	if dp.y ~= 0 or dp.z ~= 0 then
		_Vector3.add(self.camera.look, dp, dp)
		self:moveLook(dp)
	end

	Container:returnBack(rp, rd, p1, d1, r1, p2, d2, r2, rpos, dp)

	-- _rd:draw3DLine(r1.x, r1.y, r1.z, r2.x, r2.y, r2.z, _Color.Red)
end

Camera.followTarget = function(self, t, DirH_limit)
	self.target = t
	self.dirH_limit = DirH_limit
	self.onIdle = nil
	if t == 'role' then
		self.onIdle = self.followRole
	elseif t == 'rolehouse' then
		self.onIdle = self.followRoleInHouse
	elseif t == 'rolearea' then
		self.onIdle = self.followRoleInArea
	end

	if self.onIdle then
		assert(Global.role or Global.sen.setting.camfollowrole, 'no role in ' .. Global.sen.resname)
	end
end

Camera.focus = function(self, t, s)
	self.camera:focus(t, s)
end

Camera.blockFeet = function(self, eye)
	if self.target == 'role' and Global.role then
		local v = Global.role:getPosition_const()
		if eye.z < v.z then eye.z = v.z end
	end
end

Camera.setBlockArea = function(self, x1, x2, nearRadius, farRadius)
	self.block_area = {
		x1x2 = x2 - x1,
		lx = x1,
		rx = x2,
	}
	self.minRadius = nearRadius
	self.maxRadius = farRadius
end

Camera.blockArea = function(self, look)
	local ba = self.block_area
	if ba and self.minRadius > 0 then -- todo use enable
		local area22 = 1920 * self.maxRadius / self.camera.radius
		local f = 1 - (_rd.w * 1080) / (_rd.h * ba.x1x2 / 8 * area22)
		look.x = math.clamp(look.x, f * ba.lx, f * ba.rx)
	end
end

-------------------------------------------
if _sys.os == 'win32' or _sys.os == 'mac' then
	local oldlook = _Vector3.new()
	local diff = _Vector3.new()
	Camera.Debug = function(self)
		_Vector3.sub(self.camera.look, oldlook, diff)
		oldlook:set(self.camera.look)
		print('CameraDiff', diff)
		print('CameraLook', oldlook)
	end
end
-------------------------------------------

return Camera