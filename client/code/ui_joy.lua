local Container = _require('Container')
local ui = Global.UIParkour
local joyUI = ui.joy
local joystick_touch = joyUI.joystick_touch
local button = joyUI.joystick
local center = joyUI.joystick_center
joyUI._alpha = 60

local startX = 0
local startY = 0
local lastX = 0
local lastY = 0
local range = 200
local speed = 0.1
local timer = 0
local isMoving = false
local joydir = _Vector2.new(0, 0)
local dir = _Vector3.new(0, 0, 0)

local function updateJoyPos(x, y)
	button._x = x - button._width * 0.5 - joyUI._x
	button._y = y - button._height * 0.5 - joyUI._y
	startX = center._x + center._width * 0.5
	startY = center._y + center._height * 0.5

	local moveX = x - lastX
	local moveY = y - lastY

	lastX = x
	lastY = y

	local buttonX = button._x + moveX
	local buttonY = button._y + moveY

	joydir.x = buttonX + button._width * 0.5 - startX
	joydir.y = buttonY + button._height * 0.5 - startY

	local rad = math.atan2(joydir.y, joydir.x)
	local maxX = range * 0.5 * math.cos(rad)
	local maxY = range * 0.5 * math.sin(rad)

	if math.abs(joydir.x) > math.abs(maxX) then
		joydir.x = maxX
	end
	if math.abs(joydir.y) > math.abs(maxY) then
		joydir.y = maxY
	end
	buttonX = startX + joydir.x
	buttonY = startY + joydir.y
	if buttonX < 0 then
		buttonX = 0
	end

	button._x = buttonX - button._width * 0.5
	button._y = buttonY - button._height * 0.5
end

joystick_touch.onMouseDown = function(touch)
	if _sys:isKeyDown(_System.MouseRight) then
		return
	end

	ui:gotoAndPlay('joyon')
	isMoving = true
	button.visible = true
	button._alpha = 100
	center.visible = true
	center._alpha = 100

	lastX = touch.mouse.x
	lastY = touch.mouse.y
	updateJoyPos(touch.mouse.x, touch.mouse.y)
end

joystick_touch.onMouseMove = function(touch)
	if _sys:isKeyDown(_System.MouseRight) then
		return
	end

	updateJoyPos(touch.mouse.x, touch.mouse.y)
end

joystick_touch.onMouseUp = function(touch)
	if _sys:isKeyDown(_System.MouseRight) then
		return
	end

	button._x = center._x + center._width * 0.5 - button._width * 0.5
	button._y = center._y + center._height * 0.5 - button._height * 0.5

	joydir.x = 0
	joydir.y = 0

	ui:gotoAndPlay('joyoff')

	isMoving = false
end

joyUI.update = function(self, e)
	-- 控制显示时间
	if button.visible and isMoving == false then
		timer = timer + e
		if timer >= 10000 and timer < 13000 then
			button._alpha = 100 - (timer - 10000) / 30
			center._alpha = 100 - (timer - 10000) / 30
		elseif timer >= 13000 then
			button._alpha = 0
			center._alpha = 0
			button.visible = false
			center.visible = false
			timer = 0
		end
	else
		timer = 0
	end
	joyUI:updateCoinAlpha()

	local m = joydir:magnitude()
	m = m == 0 and 1 or m

	local forward, right, up, power = 0, 0, 0, 0
	forward = - joydir.y / m
	right = joydir.x / m

	local forwardAxis = Container:get(_Vector3)
	local rightAxis = Container:get(_Vector3)
	local upAxis = Container:get(_Vector3)

	upAxis:set(_rd.camera.up)

	_Vector3.sub(_rd.camera.look, _rd.camera.eye, forwardAxis)
	forwardAxis.z = 0
	forwardAxis:normalize()

	_Vector3.cross(upAxis, forwardAxis, rightAxis)

	_Vector3.mul(forwardAxis, forward, forwardAxis)
	_Vector3.mul(rightAxis, right, rightAxis)
	_Vector3.mul(upAxis, up, upAxis)

	_Vector3.add(forwardAxis, rightAxis, dir)
	_Vector3.add(dir, upAxis, dir)
	dir:normalize()

	_Vector3.mul(dir, e * speed, dir)

	Container:returnBack(forwardAxis)
	Container:returnBack(rightAxis)
	Container:returnBack(upAxis)
end

joyUI.getDir = function(self)
	return dir
end

joyUI.getJoyDir = function(self)
	return joydir
end

joyUI.show = function(self, s)
	joyUI.visible = s
	if s then
		button.visible = true
		button._alpha = 100
		center.visible = true
		center._alpha = 100
	end
end

joyUI.updateCoinAlpha = function(self)
	if joyUI.visible then
		Global.CoinUI:updateAlpha(button._alpha)
	end
end

joyUI.resize = function(self)
	if _app:isScreenH() then
		ui.joy._x = 140
	else
		ui.joy._x = ui._width / 2 - ui.joy._width / 2
	end
end

ui.onSizeChange = function()
	joyUI:resize()
end