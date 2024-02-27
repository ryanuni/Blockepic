
local bb = _G.BuildBrick
----------------------------------------------------
local movedata = {
	ismoving = false,
	disabled_axis = nil,
	v3_pre = _Vector3.new(),
	v3_cur = _Vector3.new(),
	v3_tmp = _Vector3.new(),
}
local camera_atom_move_get_pos = function(self, x, y)
	local node, pos = self:phyxpick(x, y, Global.CONSTPICKFLAG.TERRAIN)
	--print('getpos', node, x, y, pos)
	if not node then return end

	return pos
end
local camera_atom_move_begin = function(self, x, y)
	movedata.ismoving = true
	movedata.disabled_axis = nil
	local p = camera_atom_move_get_pos(self, x, y)
	if p then
		movedata.ismoving = true
		movedata.v3_pre:set(p)

		if bb.disableCamMoveDepth then
			local type = Global.dir2AxisType(Global.DIRECTION.UP, Global.AXISTYPE.Z)
			movedata.disabled_axis = Global.toPositiveAxisType(type)
		end
	else
		movedata.ismoving = false
	end
end
local camera_atom_move = function(self, x, y)
	if movedata.ismoving == false then return end

	local p = camera_atom_move_get_pos(self, x, y)
	if not p then return end
	-- get pos -> v3_1
	movedata.v3_cur:set(p)
	-- v3_1 sub v3_move
	_Vector3.sub(movedata.v3_pre, p, movedata.v3_tmp)

	-- 设置移动时的最大位移，防止pick到地面非常远处
	if movedata.disabled_axis then
		local maxAxis = movedata.v3_tmp:maxAxis()
		if movedata.disabled_axis == Global.AXISTYPE.X then
			if maxAxis == Global.AXISTYPE.X then return end
			movedata.v3_tmp.x = 0
		elseif movedata.disabled_axis == Global.AXISTYPE.Y then
			if maxAxis == Global.AXISTYPE.Y then return end
			movedata.v3_tmp.y = 0
		elseif movedata.disabled_axis == Global.AXISTYPE.Z then
			if maxAxis == Global.AXISTYPE.Z then return end
			movedata.v3_tmp.z = 0
		end
	end

	local maxdiff = not self:isBuildScene() and 0.25
	if maxdiff and movedata.v3_tmp:magnitude() > maxdiff then
		movedata.v3_tmp:normalize()
		_Vector3.mul(movedata.v3_tmp, maxdiff, movedata.v3_tmp)
		if movedata.disabled_axis == Global.AXISTYPE.X then
			movedata.v3_tmp.x = 0
		elseif movedata.disabled_axis == Global.AXISTYPE.Y then
			movedata.v3_tmp.y = 0
		elseif movedata.disabled_axis == Global.AXISTYPE.Z then
			movedata.v3_tmp.z = 0
		end
	end

	-- move
	local c = self:getCameraControl()
	c:moveLookD(movedata.v3_tmp)
	c:update()
	-- v3_move = v3_1
	p = camera_atom_move_get_pos(self, x, y)
	if p then
		movedata.v3_pre:set(p)
	end
end
local camera_atom_move_end = function()
	movedata.ismoving = false
end
----------------------------------------------------
local move_data = {
	v3 = _Vector3.new(),
	cdir = _Vector3.new(),
	hdir = _Vector3.new(),
	vdir = _Vector3.new(),
	move_dir2 = _Vector2.new(),
	move_dir3 = _Vector3.new(),
}
bb.camera_move_dir_begin = function(self, x, y)
	move_data.x = x
	move_data.y = y
end
bb.camera_move_dir = function(self, x, y)
	if self.enableCamMove == false then return end
	if not move_data.x then return end

	move_data.move_dir2.x = move_data.x - x
	move_data.move_dir2.y = y - move_data.y
	move_data.x = x
	move_data.y = y
end
bb.camera_move_dir_end = function(self)
	move_data.x = nil
	move_data.y = nil
	move_data.move_dir2:set(0, 0)
end

bb.camera_update = function(self)
	if self.enableCamMove == false then return end

	if #self.rt_selectedBlocks == 0 and (not _sys:isKeyDown(_System.KeyCtrl)) then
		if _sys:isKeyDown(_System.KeyA) then
			move_data.move_dir2.x = -1
		end
		if _sys:isKeyDown(_System.KeyD) then
			move_data.move_dir2.x = 1
		end
		if _sys:isKeyDown(_System.KeyW) then
			move_data.move_dir2.y = 1
		end
		if _sys:isKeyDown(_System.KeyS) then
			move_data.move_dir2.y = -1
		end
	end

	if move_data.move_dir2.x == 0 and move_data.move_dir2.y == 0 then
		return
	end

	move_data.move_dir2:normalize()

	move_data.move_dir3:set(0, 0, 0)
	-- calc hdir vdir
	_Vector3.sub(_rd.camera.look, _rd.camera.eye, move_data.cdir)
	move_data.cdir:normalize()

	_Vector3.cross(_rd.camera.up, move_data.cdir, move_data.hdir)
	move_data.hdir:normalize()

	_Vector3.cross(move_data.cdir, move_data.hdir, move_data.vdir)

	_Vector3.add(move_data.move_dir3, move_data.hdir:scale(move_data.move_dir2.x * 0.5), move_data.move_dir3)
	_Vector3.add(move_data.move_dir3, move_data.vdir:scale(move_data.move_dir2.y * 0.5), move_data.move_dir3)

	local c = self:getCameraControl()
	c:moveLookD(move_data.move_dir3, 200, 'fcc')

	move_data.move_dir2:set(0, 0)
end
----------------------------------------------------
local rotdata = {
	ismoving = false,
	x0 = -1,
	y0 = -1,
	step_H = math.pi / 4,
	step_V = 9999,
}
local camera_atom_rot_begin = function(self, x, y)
	rotdata.ismoving = true
	rotdata.x0 = x
	rotdata.y0 = y
end
local camera_atom_rot

if _sys:isMobile() then

camera_atom_rot = function(self, x, y)
	if not rotdata.ismoving then return end

	-- calc a
	local dx = x - rotdata.x0
	local dy = y - rotdata.y0
	local d = dx
	if math.abs(dx) < math.abs(dy) then
		d = -dy
	end

	local a = d * Global.CameraControl.CONST_SCALE_ROTATE * 3
	local n = math.floor(math.abs(a) / rotdata.step_H)
	if n == 0 then return end

	local sign = 1
	if a < 0 then
		sign = -1
	end
--	print('atom_rot', x - rotdata.x0, n, sign * n * rotdata.step_H)
	--local c = Global.CameraControl:get()
	local c = self:getCameraControl()
	c:moveDirH(sign * n * rotdata.step_H, 200, 'camera_rotate')

	rotdata.x0 = x
	rotdata.y0 = y
end

else

camera_atom_rot = function(self, x, y)
	if not rotdata.ismoving then return end

	-- calc a
	local dx = x - rotdata.x0
	local dy = y - rotdata.y0

	local c = self:getCameraControl()
	local ax = dx * Global.CameraControl.CONST_SCALE_ROTATE * 3
	local ay = dy * Global.CameraControl.CONST_SCALE_ROTATE
	c:moveDirH(ax, 200, 'camera_rotate')
	c:moveDirV(ay, 0, 'camera_rotate')

	rotdata.x0 = x
	rotdata.y0 = y
end

end

local camera_atom_rot_end = function()
	rotdata.ismoving = false
end
----------------------------------------------------
local flag = false
local ismove = false

bb.showHint = function(self, show, type, x, y)
	local hint = self.ui.camerahint
	hint.visible = show
	if show then
		hint.pic._icon = type == 1 and 'img://camera_rot.png' or type == 2 and 'img://camera_move.png'
			or type == 3 and 'img://movebrick_disabled.png'
		self:updateHint(x, y)
	end
end
bb.updateHint = function(self, x, y)
	local hint = self.ui.camerahint
	if not hint.visible then return end
	local scalef = Global.UI:getScale()
	x, y = x / scalef, y / scalef
	hint._x = x - hint._width * 0.5
	hint._y = y - hint._height - 60
end
bb.camera_down = function(self, b, x, y)
	if Global.SwitchControl:is_cameracontrol_off() then return end
	if flag then return end
	-- print('[Buildbrick.camera_down]', b, x, y, flag, debug.traceback())
	flag = true
	ismove = not (self.ui.rotatecamera.pushed or _sys:isKeyDown(_System.MouseRight))
	if ismove then
		if _sys:isKeyDown(_System.MouseMiddle) then
			if self.enableCamMove then
				self:showHint(true, 2, x, y)
				self:camera_move_dir_begin(x, y)
			end
		else
			camera_atom_move_begin(self, x, y)
		end
	else
		self:showHint(true, 1, x, y)
		camera_atom_rot_begin(self, x, y)
	end
end
bb.camera_move = function(self, x, y, fid)
	if Global.SwitchControl:is_cameracontrol_off() then return end
	if not flag then return end
	-- print('[Buildbrick.camera_move]', x, y, fid)
	self:updateHint(x, y)
	if ismove then
		if _sys:isKeyDown(_System.MouseMiddle) then
			self:camera_move_dir(x, y)
		else
			camera_atom_move(self, x, y)
		end
	else
		camera_atom_rot(self, x, y)
	end
end
bb.camera_up = function(self)
	if Global.SwitchControl:is_cameracontrol_off() then return end
	--print('[Buildbrick.camera_up]')
	local f = flag
	if ismove then
		if _sys:isKeyDown(_System.MouseMiddle) then
			if self.enableCamMove then
				self:camera_move_dir_end()
			end
		else
			camera_atom_move_end()
		end
	else
		camera_atom_rot_end()
	end

	flag = false
	self:showHint(false)

	return f
end
----------------------------------------------------
local Container = _require('Container')
local oldRadius
local CONST_DELTA_T = 200
local CONST_CURVE = 'camera_rotate'
bb.camera_focus = function(self, aabb, scale, minRadius, useMaxRadius)
	local radius = minRadius or 6
	local scale = scale or 1

	if not aabb then
		local nbs = {}
		self:getBlocks(nbs)
		if #nbs > 0 then
			aabb = Container:get(_AxisAlignedBox)
			Block.getAABBs(nbs, aabb)
		else
			return
		end
	end

	local ab = Container:get(_AxisAlignedBox)
	local scalemat = Container:get(_Matrix3D)
	ab:set(aabb)
	ab:alignCenter(Global.AXIS.ZERO)
	scalemat:setScaling(scale, scale, scale)
	ab:mul(scalemat)

	local center = Container:get(_Vector3)
	aabb:getCenter(center)

	local c = self:getCameraControl()

	local dir = Container:get(_Vector3)
	_Vector3.sub(c.camera.eye, c.camera.look, dir)
	dir:scale(radius)

	local cam = Container:get(_Camera)
	cam.look:set(Global.AXIS.ZERO)
	cam.eye:set(dir)
	cam.fov = c.camera.fov
	cam.viewNear = c.camera.viewNear
	cam.viewFar = c.camera.viewFar

	local r = calcCameraRadius(cam, ab)
	if useMaxRadius then
		r = math.max(c.camera.radius, r)
	else
		r = math.min(c.camera.radius, r)
	end

	-- move
	c:moveLook(center, CONST_DELTA_T, CONST_CURVE)
	if not oldRadius then
		oldRadius = c:getScale()
	end
	c:scale(r, CONST_DELTA_T, CONST_CURVE)

	Container:returnBack(ab, center, dir, cam, scalemat)
end
bb.camera_unfocus = function(self)
	if oldRadius then
		local c = self:getCameraControl()
		c:scale(oldRadius, CONST_DELTA_T, CONST_CURVE)
		oldRadius = nil
	end
end
