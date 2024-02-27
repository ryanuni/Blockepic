---@diagnostic disable: redundant-parameter

--[[
	回调控制
	1.键盘
		delKeyDownEvents/addKeyDownEvents
		各个mode自己设置，自己清理
	2.鼠标/触摸
		可使用的是onClick/onDown/onMove/onUp
		大部分情况应该都用onClick，不需要其他3个（目前只有PC上的框选用到了后3个）
]]

_G.BEGIN_RECORD = function(type)
	if PMobileHelper then
		MH_beginRecord(type)
	end
end

_G.END_RECORD = function(type)
	if PMobileHelper then
		MH_endRecord(type)
	end
end

_G.captureScreen = _DrawBoard.new(_rd.w, _rd.h)
_G.captureBlurRatio = (_sys.os == 'ios' or _sys.os == 'mac') and 2 or 1.0 / 4.0

_G.holdbackScreen = function(self, timer, callback)
	if _sys.os == 'ios' or _sys.os == 'mac' then
		timer:start('capture', _app.elapse + 10, function()
			local lastAsyncShader = _sys.asyncShader
			_sys.asyncShader = false
			_rd:captureScreenToImage(_G.captureScreen)
			local dbs = {}
			dbs[1] = _G.captureScreen
			local dw = _G.captureScreen.w
			local dh = _G.captureScreen.h
			for i = 2, _G.captureBlurRatio + 1 do
				dw = dw * 0.5
				dh = dh * 0.5
				dbs[i] = _DrawBoard.new(dw, dh)
			end
			for i = 2, #dbs do
				local w = dbs[i].w
				local h = dbs[i].h
				_rd:useDrawBoard(dbs[i], _Color.Null)
				if dbs[i - 1] then dbs[i - 1]:drawImage(0, 0, w, h) end
				_rd:resetDrawBoard(true)
			end
			_mf:renderBlurToImage(dbs[#dbs], 10.0)
			_rd:useDrawBoard(_G.captureScreen, _Color.Null)
			dbs[#dbs]:drawImage(0, 0, _G.captureScreen.w, _G.captureScreen.h)
			_rd:resetDrawBoard(true)
			_sys.asyncShader = lastAsyncShader
			Global.SwitchControl:set_render_off()
			if callback then callback() end
			timer:stop('capture')
		end)
	else
		timer:start('capture', _app.elapse + 10, function()
			local lastAsyncShader = _sys.asyncShader
			_sys.asyncShader = false
			_rd:captureScreenToImage(_G.captureScreen)
			local dw = _G.captureScreen.w * _G.captureBlurRatio
			local dh = _G.captureScreen.h * _G.captureBlurRatio
			local reimg = _DrawBoard.new(dw, dh)
			_rd:useDrawBoard(reimg, _Color.Null)
			if _G.captureScreen then _G.captureScreen:drawImage(0, 0, dw, dh) end
			_rd:resetDrawBoard()
			_mf:renderBlurToImage(reimg, 10.0)
			_rd:useDrawBoard(_G.captureScreen, _Color.Null)
			if reimg then reimg:drawImage(0, 0, _G.captureScreen.w, _G.captureScreen.h) end
			_rd:resetDrawBoard()
			_sys.asyncShader = lastAsyncShader
			Global.SwitchControl:set_render_off()
			if callback then callback() end
			timer:stop('capture')
		end)
	end
end

Global.HotKeyFunc = {}
Global.AddHotKeyFunc = function(key, condition, func)
	if not Global.HotKeyFunc[key] then
		Global.HotKeyFunc[key] = {}
	end

	print('AddHotKeyFunc', key)

	local data = {condition = condition, func = func}
	table.insert(Global.HotKeyFunc[key], data)

	if #Global.HotKeyFunc[key] > 20 then
		table.remove(Global.HotKeyFunc[key], 1)
	end

	return data
end

Global.ReleaseHotKeyFunc = function(key, data)
	local funcs = Global.HotKeyFunc[key]
	if funcs then
		local index = table.findexOf(funcs, data)
		if index and index ~= -1 then
			table.remove(funcs, index)
		end
	end
end

Global.ClearHotKeyFunc = function()
	Global.HotKeyFunc = {}
end

local keydown = {}
_app:onKeyDown(function(k)
	Global.HotKey:hide()
	-- print('onKeyDown key', k, _sys:isKeyDown(_System.KeyCtrl), _sys:isKeyDown(_System.KeyShift))
	if keydown[k] then
		keydown[k].func()
	end
end)
_app.onKeyDown = function()
	assert(nil, '[_app.onKeyDown]不要重写')
end
_app.addKeyDown = function(self, k, func, retain)
	assert(keydown[k] == nil, '[_app.addKeyDown]有覆盖' .. k)
	keydown[k] = {k = k, func = func, retain = retain}
end
_app.addKeyDownEvents = function(self, tb, retain)
	for _, v in ipairs(tb) do
		if ENABLE_KEY or v.release then
			_app:addKeyDown(v.k, v.func, retain)
		end
	end
end
_app.delKeyDown = function(self, k)
	if keydown[k].retain then return end
	assert(keydown[k], '[_app.delKeyDown]没有配对？' .. k)

	keydown[k] = nil
end
_app.delKeyDownEvents = function(self, tb)
	tb = tb or keydown
	for _, v in pairs(tb) do
		_app:delKeyDown(v.k)
	end
end
----------------------------------------------------------
local keyup = {}
_app:onKeyUp(function(k)
	if keyup[k] then
		keyup[k].func()
	end
end)
_app.onKeyUp = function()
	assert(nil, '[_app.onKeyUp]不要重写')
end
_app.addKeyUp = function(self, k, func, retain)
	assert(keyup[k] == nil, '[_app.addKeyUp]有覆盖' .. k)
	keyup[k] = {k = k, func = func, retain = retain}
end
_app.addKeyUpEvents = function(self, tb, retain)
	for _, v in ipairs(tb) do
		if ENABLE_KEY or v.release then
			_app:addKeyUp(v.k, v.func, retain)
		end
	end
end
_app.delKeyUp = function(self, k)
	if keyup[k].retain then return end
	assert(keyup[k], '[_app.delKeyUp]没有配对？' .. k)
	keyup[k] = nil
end
_app.delKeyUpEvents = function(self, tb)
	tb = tb or keyup
	for _, v in pairs(tb) do
		_app:delKeyUp(v.k)
	end
end

_G.tempshowui = true
local showPhysicMode = 0
local kevents = {
	-- F5
	{
		k = 116,
		func = function()
			_Fairy.root._alpha = 100
			_reset(_sys:getGlobal('codefile'))
		end
	},
	-- F9
	{
		k = 120,
		func = function()
			if showPhysicMode == 0 then
				showPhysicMode = 1
				Global.sen.showPhysics = true
			elseif showPhysicMode == 1 then
				showPhysicMode = 2
				Global.sen.showPhysics = true
				_G.hideAllBlocks = true
			elseif showPhysicMode == 2 then
				showPhysicMode = 0
				Global.sen.showPhysics = false
				_G.hideAllBlocks = false
			end
		end
	},
	{
		k = _System.KeyTab,
		release = true,
		func = function()
			Global.HotKey:show()
		end
	},
	{
		k = _System.KeyESC,
		release = true,
		func = function()
			local data = Global.HotKeyFunc[_System.KeyESC]
			if data then
				for i = #data, 1, -1 do
					local v = data[i]
					if not v.condition or v.condition() then
						v.func()
						table.remove(data)
						break
					else
						table.remove(data)
					end
				end
			end
		end
	},
	-- F11
	{
		k = 122,
		func = function()
			if _sys:getGlobal('xl') then
				_dofile('test1.lua')
			else
				_G.tempshowui = not _G.tempshowui
				Global.UI:switchUIVisible(_G.tempshowui)
			end
		end
	},
	-- F12
	{
		k = 123,
		release = true,
		func = function()
			_dofile('test.lua')
		end
	},
	-- F1
	{
		k = 112,
		func = function()
			Global.Debug:beginProfile()
		end
	},
	-- F2
	{
		k = 113,
		func = function()
			Global.Debug:endProfile()
		end
	},
	-- F6
	{
		k = 117,
		func = function()
			Global.Debug:switchMode()
		end
	},
	-- F7
	{
		k = 118,
		func = function()
			Global.Debug:switchObjectTrace()
		end
	},
	-------------------------------------------
	{
		k = _System.KeyK,
		func = function()
			if Global.GameState:isState('GAME') == false then return end

			if _sys:isKeyDown(_System.KeyCtrl) then
				local filename = _sys:openFile("*.gra")
				local gra = _GraphicsData.new(filename)
				local orbits = {}
				gra:getOrbits(orbits)
				local eo, lo
				for i, v in ipairs(orbits) do
					if v.name == 'eye' then
						eo = v
					else
						lo = v
					end
				end
				_G.cameraorbit = {eye = eo, look = lo, start = false}
			end
			if _G.cameraorbit then
				_G.cameraorbit.eye.start = false
				_G.cameraorbit.eye.current = 0
				_G.cameraorbit.look.current = 0
			end
		end
	},
	{
		k = 114, -- F3
		func = function()
		end
	},
	{
		k = 115, -- F4
		func = function()
		end
	},
}

local kupevents = {
	{
		k = _System.KeyTab,
		release = true,
		func = function()
			Global.HotKey:hide()
		end
	},
}

_app:addKeyDownEvents(kevents, true)
_app:addKeyUpEvents(kupevents, true)

_dofile('app_mouse.lua')

----------------------------------------------------------------------------
-- 部分手机不支持，需要自己在java里实现
Global.appInited = false
local function initOrientationSet()
	if Global.appInited then
		return
	end

	Global.appInited = true

	_sys.screenOrientation = _System.ScreenOrientationSensorLandScape
end
local screen_h_w, screen_h_h, screen_v_w, screen_v_h
if _sys.os == 'win32' or _sys.os == 'mac' then
	if _sys:getGlobal('AUTOTEST') or _sys.isRetinaScreen then
		screen_h_w = 960
		screen_h_h = 540
		screen_v_w = 540
		screen_v_h = 960
	else
		screen_h_w = 1920
		screen_h_h = 1080
		screen_v_w = 1080 * 9 / 16
		screen_v_h = 1080
	end
	_rd.w = screen_h_w
	_rd.h = screen_h_h

	if not _sys:getGlobal('xl') then
		_sys:centerWindow()
	end
end
_app.isScreenH = function(self)
	return _rd.w > _rd.h
end
_app.isScreenV = function(self)
	return _rd.w < _rd.h
end
_app.changeScreen = function(self, dir)
	if (_sys.os == 'win32' or _sys.os == 'mac') then return end -- mac和win32上不调整窗口位置
	--if (_sys.os == 'win32' or _sys.os == 'mac') and dir ~= 1 then dir = 0 end
	if self.dir == dir then
		return
	end

	self.dir = dir
	if dir == 0 then
		-- 横屏
		if _sys.os == 'win32' or _sys.os == 'mac' then
			_rd.w = screen_h_w
			_rd.h = screen_h_h
			_sys:centerWindow()
		else
			_sys.screenOrientation = _System.ScreenOrientationSensorLandScape
		end
	elseif dir == 1 then
		-- 竖屏
		if _sys.os == 'win32' or _sys.os == 'mac' then
			_rd.w = screen_v_w
			_rd.h = screen_v_h
			_sys:centerWindow()
		else
			_sys.screenOrientation = _System.ScreenOrientationPortrait
		end
	else
		_sys.screenOrientation = _System.ScreenOrientationUnspecified
	end

	-- Global.UI:onDeviceOrientation()
end
_app.getScreen = function(self)
	return self.dir
end
_app.getInitScreenSize = function(self)
	local w = self:isScreenH() and screen_h_w or screen_v_w
	local h = self:isScreenH() and screen_h_h or screen_v_h
	return math.min(w / 1920, h / 1080)
end
----------------------------------------------------------------------------
local idlefunc = {}
local LV_MAX = 10
for i = 1, LV_MAX do
	idlefunc[i] = {}
end

Global.FrameToken = 0

_app:onIdle(function(e)

	Global.FrameToken = Global.FrameToken + 1
	-- for k in next, Global.Debug.ticks do
	-- 	Global.Debug.ticks[k] = 0
	-- end

	for i = 1, LV_MAX do
		local fs = idlefunc[i]
		for o in next, fs do
			-- Global.Debug:beginTick('idle_1')
			if o.specialupdate then
				o:specialupdate(e)
			end
			-- Global.Debug:addTick('idle_1')

			if Global.SwitchControl:is_render_on() then
				-- Global.Debug:beginTick('idle_2')
				if o.update then
					o:update(e)
				end
				-- Global.Debug:addTick('idle_2')
				-- Global.Debug:beginTick('idle_3')
				if o.render then
					o:render(e)
				end
				-- Global.Debug:addTick('idle_3')
			end
		end
	end

	if Global.SwitchControl:is_render_off() then
		if _G.captureScreen then
			_G.captureScreen:drawImage(0, 0, _rd.w, _rd.h)
		end
	end

	initOrientationSet()

	if PMobileHelper then
		PMobileHelper.set(_G.MH_CUSTOM_TYPE.FrameId, CurrentFrame())
		--PMobileHelper.set(_G.MH_CUSTOM_TYPE.RpcData, _G.getMobileHelperRpc())
		PMobileHelper.set(_G.MH_CUSTOM_TYPE.SceneName, Global.sen and Global.sen.name or 'unknow')
		MH_uploadCustomType()
	end
end)
_app.onIdle = function()
	assert(false, '不要重写')
end
_app.onUpdate = function(self, obj)
	self:registerUpdate(obj, 5)
end
local lastactive
_app:onActive(function(isActive)
	if lastactive ~= nil and lastactive == isActive then return end

	lastactive = isActive
	_sd.mute = not lastactive

	if isActive == false then
		if Global.BuildBrick then
			Global.BuildBrick:autoSave()
		end
	end

	if _sys:getGlobal('xl') then
		_sd.mute = true
	end
end)
_app.registerUpdate = function(self, obj, lv)
	assert(obj.update or obj.render or obj.specialupdate)
	lv = lv or 2
	local fs = idlefunc[lv]
	assert(fs)
	fs[obj] = true
end
_app.unregisterUpdate = function(self, obj)
	for i = 1, LV_MAX do
		local fs = idlefunc[i]
		if fs[obj] then
			fs[obj] = nil
			return
		end
	end
end
----------------------------------------
_app.setupCallback = function(self, cb)
	-- print('[_app.setupCallback]', cb)
	_app:clearMouse()
	_app:delKeyDownEvents()
	_app:delKeyUpEvents()
	_app:cameraControl()
	if cb then
		for k, v in next, cb do
			_app[k](_app, v)
		end
	end
end

---------------------------------------

local listenup = _Vector3.new(0, 0, 1)

local offsetMat = _Matrix3D.new():setTranslation(0, 0, -0.6)
local obj = {}
local times = 0
local cameras = {
	_Camera.new(),
	_Camera.new(),
	_Camera.new(),
	_Camera.new(),
	_Camera.new(),
}
cameras[1].eye:set(1.45, -28.46, 13.51)
cameras[1].look:set(0.86, -1.09, 7.67)
cameras[2].eye:set(-26.64, -2.12, 13.51)
cameras[2].look:set(0.86, -1.09, 7.67)
cameras[3].eye:set(1.73, 26.31, 13.51)
cameras[3].look:set(0.86, -1.09, 7.67)
cameras[4].eye:set(28.18, -1.39, 13.51)
cameras[4].look:set(0.86, -1.09, 7.67)
cameras[5].eye:set(0.99, 3.67, 35.27)
cameras[5].look:set(0.86, -1.09, 7.67)

obj.update = function(self, e)
	if not Global.FrameSystem:isPaused() then
		Global.InputSender:update(e)
		Global.FrameSystem:Update(e)
	end

	if not Global.sen then
		return
	end

	BEGIN_RECORD('mainUpdate')

	Global.sen:clearRenderingBlocks()

	-- 渲染
	Global.FERManager:render()

	if Global.filterNeededNode then
		times = times + 1
		_rd.camera:set(cameras[times])
	end

	BEGIN_RECORD('senRender')

	Global.AnimationManager:update()

	Global.sen:render(e)

	if _G.tempshowui then
		Global.sen:renderHint(e)
	end

	if Global.sen.drawTile then
		DrawHelper.drawPlaneZ(10, 0.2, -0.6)
		_rd:pushMatrix3D(offsetMat)
		_rd:drawAxis(0.6)
		_rd:popMatrix3D()
	end

	Global.PickHelper:renderHelper()

	END_RECORD('senRender')

	--Global.sen:clearRenderingBlocks()
	local nodes = {}
	Global.sen:getPickedNodes(nodes)
	for i, node in ipairs(nodes) do
		if node.block then
			Global.sen:addRenderingBlock(node.block)
			node.block:render(e)
			node:drawEmoji()
		end
	end

	-- if Global.showKnots then
	-- 	for i, b in ipairs(Global.sen.renderingBlocks) do
	-- 		local knots = b:getKnots()
	-- 		for _, v in ipairs(knots) do
	-- 			DrawHelper.drawKnot(v:getPos1(), v.type == 1 and _Color.Green or _Color.Blue)
	-- 		end
	-- 	end
	-- end

	--KnotManager.draw()

	if Global.filterNeededNode then
		local nodes = {}
		Global.sen:getQueryPickedNodes(nodes)
		for i, node in ipairs(nodes) do if node.block then
			Global.neededNodes[node] = true
		end end
		if times == 5 then
			Global.filterNeededNode = not Global.filterNeededNode
			_sys.showRedundance = not _sys.showRedundance
			_sys.showRedundantMesh = not _sys.showRedundantMesh
			local nodes = {}
			Global.sen:getNodes(nodes)
			for i, v in ipairs(nodes) do
				if v.block and Global.neededNodes[v] then
					v.need = true
				end
			end
			times = 0
		end
	end

	Global.ui.controler.planemovebutton:drawHelper()

	-- 声音更新
	if Global.role then
		local pos = Global.Container:get(_Vector3)
		Global.role:getPosition(pos)
		local dir = Global.role.mb.mesh.dir
		Global.Sound:updatePos(pos, dir, listenup)
		Global.Container:returnBack(pos)
	end

	Global.editor:update(e)
	Global.editor:render(e)

	if Block.isBuildMode() then -- TODO: 退出编辑时保证up和down对应
		if Global.ui.controler.movebutton:isMoving() or Global.ui.controler.planemovebutton:isMoving() then
			_rd:drawLine(Global.cross.x - 3, Global.cross.y, Global.cross.x + 2, Global.cross.y, _Color.Red)
			_rd:drawLine(Global.cross.x, Global.cross.y - 2, Global.cross.x, Global.cross.y + 3, _Color.Red)
		end
	end

	Global.Browser:render(e)

	END_RECORD('mainUpdate')
end
_app:registerUpdate(obj, 5)

----------表情识别---------------------
local Container = _require('Container')

local FrontCameraDisplay = {}
local frontcamera = _Camera.new()
local tempcamera = _Camera.new()
frontcamera.look:set(0, 0, 1.7)
frontcamera.eye:set(0, -2, 1.7)
local db = _DrawBoard.new(350, 350)

local mat = _Matrix3D.new()
local tempmat = _Matrix3D.new()
local vec = _Vector3.new()
local ret = _Vector2.new()
local c = _mf:createCube()
-- local plight = _PointLight.new()
local plight = _SkyLight.new()
plight.color = _Color.White
plight.pos = _Vector3.new(0, -4, 2)
plight.direction = _Vector3.new(0, 1, 0.1)
plight.range = 8
plight.power = 2
FrontCameraDisplay.render = function(self)
	-- local tempshadowcaster = Global.role.mb.mesh.node.isShadowCaster
	-- Global.role.mb.mesh.node.isShadowCaster = false

	-- print('nooice')
	tempcamera:set(_rd.camera)
	_rd:useDrawBoard(db, _Color.Null)

	local pos = Container:get(_Vector3)
	Global.role:getPosition(pos)
	local dir = Global.role.logic.dir -- Global.role.mb.mesh.dir
	-- todo front camera
	local eye = Container:get(_Vector3)
	_Vector3.add(pos, dir, eye)

	-- print(eye, pos)
	-- frontcamera.look:set(pos)
	-- frontcamera.eye:set(eye)

	_rd.camera:set(frontcamera)

	_rd:useLight(Global.sen.graData:getLight('ambient'))
	_rd:useLight(Global.sen.graData:getLight('skylight'))
	_rd:useLight(plight)

	copyMat(tempmat, Global.role.mb.mesh.transform)
	Global.role.mb.mesh.transform:set(mat)
	Global.role.mb.mesh:drawMesh()
	copyMat(Global.role.mb.mesh.transform, tempmat)

	-- Global.role.mb.mesh.transform:set(mat)
	-- Global.role.mb.mesh:drawMesh()
	-- c:drawMesh()
	-- Global.role.mb.mesh.skeleton:getBone('bip001 l hand', bone)
	-- bone:getTranslation(vec)
	-- _rd:projectPoint(vec.x, vec.y, vec.z, ret)

	_rd:popLight()
	_rd:popLight()
	_rd:popLight()
	_rd:resetDrawBoard()
	-- db:drawImage(_rd.w - db.w, 0, _rd.w, db.h)

	_rd.camera:set(tempcamera)

	Container:returnBack(pos, look)
	-- Global.role.mb.mesh.node.isShadowCaster = tempshadowcaster
end

FrontCameraDisplay.loadRoleMovie = function()
	Global.ui.frontcamera.roledb:loadMovie(db)
end

-- FacialExpressionRecognition
Global.FERManager = {
	state = '',
	tick = 0,

	init = function(self)
		FrontCameraDisplay.loadRoleMovie()
		if _app:isScreenH() then
			return Notice'Please switch to vertical screen.'
		end
		if _sys.os == 'win32' or _sys.os == 'mac' or self.inited then return end
		_sdk:command('TestSdk::cmd|init|')
		_sdk:command('TestSdk::cmd|checkPermission|')
	end,

	update = function(self, e)
		if _app:isScreenH() then return end
		if not self.inited or not Global.role or not self.visible then return end
		self:getState()

		self.tick = self.tick + e
		if self.tick > 1000 and self.laststate ~= self.state then
			self.tick = 0
			-- if self.state == 'Happy' or self.state == 'Angry' then
			--		Global.role:applyFacialExpression('happy')
			-- else
			--		Global.role:applyFacialExpression('neutral')
			-- end
			if self.state == 'Happy' then
				Global.role:playAnima('laugh')
			elseif self.state == 'Angry' then
				Global.role:playAnima('angry')
			else
				Global.role:playAnima('idle')
			end
			self.laststate = self.state
		end
	end,

	render = function(self)
		if Global.role and self.visible then
			FrontCameraDisplay.render()
		end
		-- if Global.role and Global.role.expimg and Global.role.expimg.tick > os.now() then
		-- 	local vec = Container:get(_Vector3)
		-- 	local point = Container:get(_Vector2)
		-- 	Global.role:getPosition(vec)
		-- 	_rd:projectPoint(vec.x, vec.y, vec.z + 1, point)
		-- 	local w = Global.role.expimg.w
		-- 	local h = Global.role.expimg.h
		-- 	Global.role.expimg:drawImage(point.x - w / 2, point.y - h / 2, point.x + w / 2, point.y + h / 2)
		-- 	Container:returnBack(vec, point)
		-- end
	end,

	getState = function(self)
		if self.inited then
			_sdk:command('TestSdk::cmd|getState')
		end

		return self.state
	end,

	open = function(self)
		if self.inited then
			_sdk:command('TestSdk::cmd|openCamera|')
		end
	end,

	close = function(self)
		if self.inited then
			_sdk:command('TestSdk::cmd|closeCamera|')
		end
	end,
}
