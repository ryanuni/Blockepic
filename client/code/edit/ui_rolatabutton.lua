local Container = _require('Container')
local ui = Global.ui
local rolatabutton = ui.controler.rolatabutton
local attach = nil
rolatabutton.onAttach = false
rolatabutton.stepn = 24
local oldX = 0
local oldY = 0

Global.rotfactor = 45
Global.rotfactor2 = 15
-- local movefactor = 45
-- local movefactor2 = 15

rolatabutton.attachBlock = function(self, transform)
	attach = transform
end

-- mode: 设置旋转轴 1:x, 2:y, 3:z, 0:固定轴
-- delta: 屏幕坐标转换成角度的比例 
-- axis: 旋转轴对应的屏幕方向
-- axisn: 固定轴旋转时固定轴的方向
local rotdata = nil
rolatabutton.addRotdata = function(self, mode, axis, delta, fixaxis, bystep)
	if not rotdata then rotdata = {} end
	if #rotdata >= 2 then return end
	table.insert(rotdata, {mode = mode, delta = delta, axis = axis, fixaxis = fixaxis, bystep = bystep})
end

rolatabutton.clearRotdata = function(self)
	rotdata = nil
end

local lockAxis = nil
local fixaxis = nil
local rotvec = _Vector4.new()
rolatabutton.onMouseDown = function(arg)
	local scalef = Global.UI:getScale()
	oldX = arg.mouse.x * scalef
	oldY = arg.mouse.y * scalef
	if attach then
		attach:updateTransformValue()
	end
	updateCameraData()

	lockAxis = nil
	fixaxis = nil
	rotvec.x, rotvec.y, rotvec.z, rotvec.w = 0, 0, 0, 0
	rolatabutton.isDowned = true
end

rolatabutton.onRotationDiff = function(dx, dy)
	local rotation = {x = 0, y = 0, z = 0, r = 0}
	fixaxis = nil
	if lockAxis then
		if rotdata then
			local diff = Container:get(_Vector2)
			diff:set(dx, dy)
			for i, v in ipairs(rotdata) do if lockAxis == v.mode then
				local rot = _Vector2.dot(diff, v.axis) / v.delta
				if v.bystep then
					rot = (rot > 0 and 1) or (rot < 0 and -1) or 0
				end

				if v.mode == Global.AXISTYPE.X then
					rotation.x = rot
				elseif v.mode == Global.AXISTYPE.Y then
					rotation.y = rot
				elseif v.mode == Global.AXISTYPE.Z then
					rotation.z = rot
				elseif v.mode == 0 then
					rotation.r = rot
					fixaxis = v.fixaxis
				end
			end end

			Container:returnBack(diff)
		else
			local dir = getCameraDataDiff(dx, dy, 15)
			if lockAxis == Global.AXISTYPE.X then
				rotation.x = dir.y == 0 and -dir.z or dir.y
			elseif lockAxis == Global.AXISTYPE.Y then
				rotation.y = dir.x == 0 and -dir.z or dir.x
			elseif lockAxis == Global.AXISTYPE.Z then
				rotation.z = dir.x == 0 and dir.y or dir.x
			end
		end
	else
		if rotdata then
			local diff = Container:get(_Vector2)
			diff:set(dx, dy)
			for i, v in ipairs(rotdata) do
				local rot = _Vector2.dot(diff, v.axis) / v.delta
				if v.bystep then
					rot = (rot > 0 and 1) or (rot < 0 and -1) or 0
				end
				if v.mode == Global.AXISTYPE.X then
					rotation.x = rot
				elseif v.mode == Global.AXISTYPE.Y then
					rotation.y = rot
				elseif v.mode == Global.AXISTYPE.Z then
					rotation.z = rot
				elseif v.mode == 0 then
					rotation.r = rot
					fixaxis = v.fixaxis
				end
			end
			-- 取最大值
			local abx, aby, abz, abr = math.abs(rotation.x), math.abs(rotation.y), math.abs(rotation.z), math.abs(rotation.r)
			local max = math.max(abx, aby, abz, abr)
			if max == abx then
				rotation.y, rotation.z, rotation.r = 0, 0, 0
			elseif max == aby then
				rotation.x, rotation.z, rotation.r = 0, 0, 0
			elseif max == abz then
				rotation.x, rotation.y, rotation.r = 0, 0, 0
			else
				rotation.x, rotation.y, rotation.z = 0, 0, 0
			end

			Container:returnBack(diff)
		else
			local dir = getCameraDataDiff(dx, dy, 15)
			if dir.x == 0 then
				rotation.z = math.abs(dir.y) > math.abs(dir.z) and dir.y or 0
				rotation.y = math.abs(dir.z) > math.abs(dir.y) and -dir.z or 0
			elseif dir.y == 0 then
				rotation.z = math.abs(dir.x) > math.abs(dir.z) and dir.x or 0
				rotation.x = math.abs(dir.z) > math.abs(dir.x) and -dir.z or 0
			elseif dir.z == 0 then
				rotation.y = math.abs(dir.x) > math.abs(dir.y) and dir.x or 0
				rotation.x = math.abs(dir.y) > math.abs(dir.x) and dir.y or 0
			end
		end
		-- 确定本次移动时要锁定的轴
		local e = 0.8
		if math.abs(rotation.x) > e then
			lockAxis = Global.AXISTYPE.X
		elseif math.abs(rotation.y) > e then
			lockAxis = Global.AXISTYPE.Y
		elseif math.abs(rotation.z) > e then
			lockAxis = Global.AXISTYPE.Z
		elseif math.abs(rotation.r) > e then
			lockAxis = 0
		end
	end

	--print('onMouseMove', lockAxis, rotation.x, rotation.y, rotation.z)

	local movefactor = Global.rotfactor
	local movefactor2 = Global.rotfactor2

	if fixaxis then
		local rr = math.floor(rotation.r) * movefactor2 * math.pi / 180
		if rr ~= rotvec.w then
			attach:setScaling(attach.scaleX, attach.scaleY, attach.scaleZ)
			attach:mulRotationZLeft(attach.rotationB)
			attach:mulRotationYLeft(attach.rotationH)
			attach:mulRotationXLeft(attach.rotationP)
			attach:mulRotationRight(fixaxis.x, fixaxis.y, fixaxis.z, rotvec.w)
			attach:mulRotationRight(fixaxis.x, fixaxis.y, fixaxis.z, rr - rotvec.w, 100)
			attach:mulTranslationRight(attach.translationX, attach.translationY, attach.translationZ)
			rotvec.w = rr
		end
	else
		local rx = math.floor(rotation.x) * movefactor * math.pi / 180
		local ry = math.floor(rotation.y) * movefactor * math.pi / 180
		local rz = math.floor(rotation.z) * movefactor * math.pi / 180
		if rx ~= rotvec.x or ry ~= rotvec.y or rz ~= rotvec.z then
			local e = 120
			attach:setScaling(attach.scaleX, attach.scaleY, attach.scaleZ)
			attach:mulRotationZLeft(attach.rotationB)
			attach:mulRotationYLeft(attach.rotationH)
			attach:mulRotationXLeft(attach.rotationP)

			attach:mulRotationZRight(rotvec.z)
			if rotvec.z ~= rz then
				attach:mulRotationZRight(rz - rotvec.z, e)
			end

			attach:mulRotationYRight(rotvec.y)
			if rotvec.y ~= ry then
				attach:mulRotationYRight(ry - rotvec.y, e)
			end

			attach:mulRotationXRight(rotvec.x)
			if rotvec.x ~= rx then
				attach:mulRotationXRight(rx - rotvec.x, e)
			end
			attach:mulTranslationRight(attach.translationX, attach.translationY, attach.translationZ)
			attach:applyCurve(Global.Curves.camera_rotate)
			rotvec.x, rotvec.y, rotvec.z = rx, ry, rz
		end
	end
end

rolatabutton.onMouseMove = function(arg)
	Global.isMovingIndicator = true
	ui:setControlerVisible(false)
	local scalef = Global.UI:getScale()
	local dx, dy = arg.mouse.x - oldX / scalef, arg.mouse.y - oldY / scalef

	rolatabutton.onRotationDiff(dx, dy)
end

rolatabutton.onMouseUp = function(arg)
	if not rolatabutton.isDowned then return end
	rolatabutton.isDowned = false
	Global.isMovingIndicator = false

	Global.Sound:play('ui_rotate')
	Global.Timer:add('vibrate', 25, function()
		_sys:vibrate(30) -- 手机震动
	end)

	if fixaxis then
		attach:setScaling(attach.scaleX, attach.scaleY, attach.scaleZ)
		attach:mulRotationZLeft(attach.rotationB)
		attach:mulRotationYLeft(attach.rotationH)
		attach:mulRotationXLeft(attach.rotationP)
		attach:mulRotationRight(fixaxis.x, fixaxis.y, fixaxis.z, rotvec.w)
		attach:mulTranslationRight(attach.translationX, attach.translationY, attach.translationZ)
	else
		attach:setScaling(attach.scaleX, attach.scaleY, attach.scaleZ)
		attach:mulRotationZLeft(attach.rotationB + rotvec.z)
		attach:mulRotationYLeft(attach.rotationH + rotvec.y)
		attach:mulRotationXLeft(attach.rotationP + rotvec.x)
		attach:mulTranslationRight(attach.translationX, attach.translationY, attach.translationZ)
	end
--	attach:updateTransformValue()

	return true
end
