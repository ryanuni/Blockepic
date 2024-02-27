local ui = Global.ui
local movebutton = ui.controler.movebutton
local attach = nil
local attachaabb = _AxisAlignedBox.new()
local oldX = 0
local oldY = 0
local tarPos = _Vector3.new()
local nowPos = _Vector3.new()
local tempPos = _Vector3.new()
local cross = _Vector2.new()
local Container = _require('Container')
_dofile('pickHelper.lua')

Global.cross = _Vector2.new()
local movefactor = Global.MOVESTEP.TILE

local offset = _Vector3.new()
--local aabbsize = _Vector3.new()
function _G.calcPickOffset(picknor, aabbsize)
	offset:set(0, 0, 0)
	local abnx, abny, abnz = math.abs(picknor.x), math.abs(picknor.y), math.abs(picknor.z)
	if abnz > abnx and abnz > abny then
		offset.z = picknor.z < 0 and -aabbsize.z * 0.5 or aabbsize.z * 0.5
	elseif abny > abnx and abny > abnz then
		offset.y = picknor.y < 0 and -aabbsize.y * 0.5 or aabbsize.y * 0.5
	else
		offset.x = picknor.x < 0 and -aabbsize.x * 0.5 or aabbsize.x * 0.5
	end

	return offset
end

local function initCrossPos(attachmat)
	if not attachmat then return end

	local pos = Container:get(_Vector3)
	attachmat:getTranslation(pos)
	_rd:projectPoint(pos.x, pos.y, pos.z, cross)
	Global.cross.x, Global.cross.y = cross.x, cross.y
	Container:returnBack()
end

movebutton.attachBlock = function(self, transform, factor, aabb, bs)
	attach = transform

	self.rolez = 0
	--movefactor = factor

	attachaabb.min:set(aabb.min)
	attachaabb.max:set(aabb.max)
	initCrossPos(attach)

	-- TODO: 通用化
	Global.PickHelper:attachBlocks(bs, aabb, transform)
end

local isMoving = false
movebutton.isMoving = function(self)
	return isMoving
end

local rolePos = _Vector3.new()
movebutton.onMouseDown = function(arg)
	if isMoving then return end

	local scalef = Global.UI:getScale()
	oldX = arg.mouse.x * scalef
	oldY = arg.mouse.y * scalef

	updateCameraData()

	initCrossPos(attach)

	--Global.cross.x, Global.cross.y = oldX + cross.x, oldY + cross.y

	-- 计算人所在的平面
	if Global.role then
		Global.role:getPosition(rolePos)
		local diffz = 0.6
		movebutton.rolez = rolePos.z - diffz
	end

	Global.PickHelper:moveBegin()

	isMoving = true
end

local frameindex = 0
movebutton.onMouseMove = function(arg)
	if not isMoving then return end
	if frameindex == CurrentFrame() then return end
	frameindex = CurrentFrame()

	if attach then
		Global.isMovingIndicator = true
		ui:setControlerVisible(false)

		local scalef = Global.UI:getScale()
		local x = arg.mouse.x * scalef - oldX + cross.x
		local y = arg.mouse.y * scalef - oldY + cross.y
		--local x = arg.mouse.x * scalef + cross.x
		--local y = arg.mouse.y * scalef + cross.y
		Global.cross.x, Global.cross.y = x, y

		if not Global.PickHelper:moveTo(x, y) then
			local pickrole = false
			local threshold = 10
			if Global.role and _rd:pickXYPlane(x, y, movebutton.rolez, tarPos) then
				local dx = math.abs(rolePos.x - tarPos.x)
				local dy = math.abs(rolePos.y - tarPos.y)
				if dx * dx + dy * dy < 10 * 10 then
					pickrole = true
					local dz = (attachaabb.max.z - attachaabb.min.z) * 0.5
					tarPos.z = tarPos.z + dz
				end
			end
			if not pickrole then
				local cameraData = Global.cameraData
				if cameraData.masix.x == 0 then
					_rd:pickYZPlane(x, y, _rd.camera.look.x, tarPos)
				elseif cameraData.masix.y == 0 then
					_rd:pickXZPlane(x, y, _rd.camera.look.y, tarPos)
				elseif cameraData.masix.z == 0 then
					_rd:pickXYPlane(x, y, _rd.camera.look.z, tarPos)
				end
			end

			Global.normalizePos(tarPos, movefactor)
			attach:getTranslation(nowPos)

			_Vector3.sub(tarPos, nowPos, tempPos)
			attach:mulTranslationRight(tempPos)
		end
	end
end

movebutton.onMouseUp = function(arg)
	if attach then
		if not arg.nosound then
			if arg.alert == true then
				Global.Sound:play('explode')
			else
				Global.Sound:play('build_put')
			end
		end

		Global.Timer:add('vibrate', 25, function()
			_sys:vibrate(30) -- 手机震动
		end)

		isMoving = false
		Global.PickHelper:moveEnd()
	end

	Global.isMovingIndicator = false
end