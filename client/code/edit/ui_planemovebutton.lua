local ui = Global.ui
local planemovebutton = ui.controler.planemovebutton
local attach = nil
local oldX = 0
local oldY = 0
local oldPos = _Vector3.new()
local tarPos = _Vector3.new()
local nowPos = _Vector3.new()
local tempPos = _Vector3.new()
local helpermasix = _Vector3.new()
local helpercenter = _Vector3.new()
local cross = _Vector2.new()
-- cross.x = -80
-- cross.y = -80
local Container = _require('Container')

local function initCrossPos(attachmat)
	if not attachmat then return end

	attachmat:getTranslation(oldPos)
	_rd:projectPoint(oldPos.x, oldPos.y, oldPos.z, cross)
	Global.cross.x, Global.cross.y = cross.x, cross.y
	planemovebutton:drawBegin(oldPos, Global.cameraData.masix)
end

local movefactor = Global.MOVESTEP.TILE
planemovebutton.attachBlock = function(self, transform, factor)
	attach = transform
	--movefactor = factor
	initCrossPos(attach)
end

local isMoving = false
planemovebutton.isMoving = function(self)
	return isMoving
end

planemovebutton.drawBegin = function(self, center, masix)
	helpermasix:set(masix)
	helpercenter:set(center)
end

planemovebutton.drawEnd = function(self)
	isMoving = false
end

planemovebutton.drawHelper = function(self)
	if not isMoving then return end

	DrawHelper.drawPlane(helpercenter, helpermasix, 0x80208020)
end

planemovebutton.onMouseDown = function(arg)
	local scalef = Global.UI:getScale()
	oldX = arg.mouse.x * scalef
	oldY = arg.mouse.y * scalef

	updateCameraData()
	initCrossPos(attach)
	isMoving = true
end

local frameindex = 0
planemovebutton.onMouseMove = function(arg)
	if frameindex == CurrentFrame() then return end
	frameindex = CurrentFrame()

	if attach then
		Global.isMovingIndicator = true
		ui:setControlerVisible(false)

		local scalef = Global.UI:getScale()
		local x = arg.mouse.x * scalef - oldX + cross.x
		local y = arg.mouse.y * scalef - oldY + cross.y
		Global.cross.x, Global.cross.y = x, y

		if helpermasix.x == 0 then
			_rd:pickYZPlane(x, y, oldPos.x, tarPos)
		elseif helpermasix.y == 0 then
			_rd:pickXZPlane(x, y, oldPos.y, tarPos)
		elseif helpermasix.z == 0 then
			_rd:pickXYPlane(x, y, oldPos.z, tarPos)
		end

		Global.normalizePos(tarPos, movefactor)
		attach:getTranslation(nowPos)

		_Vector3.sub(tarPos, nowPos, tempPos)
		attach:mulTranslationRight(tempPos)
	end
end

planemovebutton.onMouseUp = function(arg)
	if attach then
		Global.Sound:play('build_put')
		Global.Timer:add('vibrate', 25, function()
			_sys:vibrate(30) -- 手机震动
		end)
	end
	Global.isMovingIndicator = false

	planemovebutton:drawEnd()
end