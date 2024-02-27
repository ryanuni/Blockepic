--[[
	临时处理的代码，在这里的东西
	留下，就是狗屎
]]

local wheel_enabled = true
_G.TEMP_WHEEL_CONTROL = function(e)
	wheel_enabled = e
end
_G.TEMP_WHEEL_ENABLED = function()
	return wheel_enabled
end

_G.TEMP_CREATE_ROLECCT = function()
	local needrolecct = Global.sen.setting.needrolecct
	if needrolecct then
		Global.role:createCCT()
		if Global.sen.setting.needAcc ~= nil then
			Global.role.logic.needAcc = Global.sen.setting.needAcc
		end
	end
end
_G.TEMP_SETUP_PARKOUR_UI = function()
	local specialtype = Global.sen.setting.specialtype
	local disableX = Global.sen.setting.disableX
	local disableY = Global.sen.setting.disableY
	if specialtype == 'parkour' then
		if not Global.UIParkour then
			_dofile('ui_parkour.lua')
		end

		local showui = not disableX and not disableY
		Global.UIParkour.visible = showui
		Global.UIParkour:show(showui)

		Global.GameState:setupCallback(TEMP_GAME_CALLBACK_PARKOUR, 'GAME')
	elseif specialtype == 'homeparkour' then
		if not Global.UIParkour then
			_dofile('ui_parkour.lua')
		end

		local showui = not disableX and not disableY
		Global.UIParkour.visible = showui
		Global.UIParkour:show(showui)

		Global.GameState:setupCallback(TEMP_GAME_CALLBACK_HOMEPARKOUR, 'GAME')
	end
end
_G.TEMP_SETUP_CAMERA = function()
	local camera = Global.CameraControl:get()
	local changecamera2D = Global.sen.setting.changecamera2D
	local camerarange = Global.sen.setting.camerarange
	local cameralook = Global.sen.setting.cameralook
	if changecamera2D then
		camera.maxRadius = 2000
		local camera3 = Global.sen.graData:getCamera('003')
		if camera3 then
			camera:setCamera(camera3)
			camera:update()
		end
		local camera2 = Global.sen.graData:getCamera('002')
		if camera2 then
			camera:setCamera(camera2, 1000)
		end
		Global.Timer:add('changecamera', 1000, function()
			camera:moveLookD(_Vector3.new(0, 1, 0), 500, 'scc')
		end)
		Global.Timer:add('runcamera', 1500, function()
			camera:setRoleArea(camerarange.x1, camerarange.y1, camerarange.x2, camerarange.y2)
			camera:followTarget('rolearea')
		end)
	end
	local camera2D = Global.sen.setting.camera2D
	if camera2D then
		camera.maxRadius = 2000
		local camera1 = Global.sen.graData:getCamera('001')
		if camera1 then
			camera:setCamera(camera1)
			camera:update()
		end
		if camerarange then
			Global.Timer:add('runcamera', 100, function()
				camera:setRoleArea(camerarange.x1, camerarange.y1, camerarange.x2, camerarange.y2)
				camera:followTarget('rolearea')
			end)
		end
	end
	if cameralook then
		camera:moveLook(cameralook)
	end
	local camfollowrole = Global.sen.setting.camfollowrole
	if camfollowrole then
		camera:followTarget('role')
	else
		if Global.role then
			Global.role.isFocusBack = false
		end
	end
	if Global.role then
		Global.role.cameraMoveToBack = Global.sen.setting.cammovetoback
	end
	print('TEMP_SETUP_CAMERA:', changecamera2D, camera2D, cameralook, camfollowrole, Global.sen.setting.cammovetoback)
end

_G.TEMP_BRWOSE_SCENE_INIT = function()
	local Function = _require('Function')
	local loadBlockFunction = function(b, data)
		-- print('loadBlockFunction:', funcname)
		-- local data = _dofile(funcname)
		for i, v in ipairs(data or {}) do
			b:addFunction(Function.new(v))
		end
		b:loadActionFunctions(Global.sen)
		b:registerEvents()
		b:initEvents()
	end

	local data = {
		[1] = {
			['actions'] = {
				[1] = {
					['data'] = {
						[1] = 'music_browse',
						[2] = 'music_random',
						[3] = 'music_favourite',
					},
					['type'] = 'modeui',
					['sound'] = 'ui_inte04',
					['volume'] = 1.0,
				},
			},
		},
		[2] = {
			['actions'] = {
				[1] = {
					['data'] = {
						[1] = 'hide',
					},
					['type'] = 'modeui',
				},
			},
		},
		[3] = {
			['actions'] = {
				[1] = {
					['data'] = {
						['arepeat'] = true,
						['distance'] = 1,
					},
					['functions'] = {
						[1] = {
							['blockid'] = -1,
							['functionid'] = 1,
						},
					},
					['type'] = 'ApproachAction',
				},
				[2] = {
					['data'] = {
						['arepeat'] = true,
						['distance'] = 1.2,
					},
					['functions'] = {
						[1] = {
							['blockid'] = -1,
							['functionid'] = 2,
						},
					},
					['type'] = 'FarAwayAction',
				},
			},
		},
		[4] = {
			['actions'] = {
				[1] = {
					['data'] = {
					},
					['type'] = 'HintAction',
				},
			},
		},
	}

	local block = Global.sen:getBlockByShape('MusicGame')
	if not block then return end

	block:setName('musicgame')
	loadBlockFunction(block, data)
end