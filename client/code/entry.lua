local Container = _require('Container')
_require('ExtendTable')
local entry = {stack = {}, donefuncs = {}}
Global.entry = entry

local entryEditAnima = {
	timer = _Timer.new()
}
Global.EntryEditAnima = entryEditAnima

entryEditAnima.cloneLook = function(self)
	if self.look == nil then
		self.look = _rd.camera.look:clone()
	end
end
entryEditAnima.clearLook = function(self)
	self.look = nil
end

entry.updateStack = function(self)
	local stack = self.stack[#self.stack]
	if Global.role and stack then
		local roledata = {pos = _Vector3.new(0, 0, 0), dir = _Vector3.new(0, 1, 0), isinside = false}
		Global.role:getPosition(roledata.pos)
		roledata.dir:set(Global.role.mb.mesh.dir)
		roledata.isinside = Global.role:isInsideHouse()
		stack.roledata = roledata
	end
	if stack and stack.pushedcamera == false then
		Global.CameraControl:push()
		stack.pushedcamera = true
	end
end
entry.pushStack = function(self)
	assert(self.level)

	table.insert(self.stack, {level = self.level, state = self.state, param = self.param, pushedcamera = false, roledata = nil, isswitch = self.isswitch})
	if #self.stack > 10 then
		table.remove(self.stack, 1)
	end
end

entry.popStack = function(self)
	return table.remove(self.stack)
end

entry.popStackAndCamera = function(self)
	local stack = self.stack[#self.stack - 1]
	assert(stack)
	if stack.pushedcamera then
		local tempcamera = _rd.camera:clone()
		Global.CameraControl:pop()
		local c = Global.CameraControl:get()
		c:setCamera(tempcamera)
		stack.pushedcamera = false
	end
	self:popStack()
end

entry.getLastState = function(self)
	return self.stack[#self.stack].state
end
local tmp_xl_change_stage = function(level, roledata, state, param)
	Global.GameState:changeState('INIT')
	initLevel(level, roledata)
	Global.GameState:changeState(state, table.unpack(param))

	if Global.dungeon then
		Global.dungeon:init(table.unpack(param))
		Global.dungeon:load_ready()
	end
end
entry.back = function(self, cb)
	local function dochange()
		local stack = self.stack[#self.stack - 1]
		assert(stack)

		if Global.gmm:checkGuideStep(true) then
			entryEditAnima.edit_mode = false
		end
		local editing = entryEditAnima.edit_mode
		local viewing = entryEditAnima.view_mode

		if editing then
			entryEditAnima.camera = _rd.camera:clone()
		end

		if viewing then
			local tempcamera = _rd.camera:clone()
			local c = Global.CameraControl:get()
			c:setCamera(entryEditAnima.camera:clone())
			c:update()
			Global.CameraControl:push()

			entryEditAnima.camera = tempcamera
			entryEditAnima.popingcam = true
			-- stack.pushedcamera = true
		end

		tmp_xl_change_stage(stack.level, stack.roledata, stack.state, stack.param)

		---- 
		if stack.pushedcamera then
			Global.CameraControl:pop()
			stack.pushedcamera = false
		end

		self:dospecial(stack.level, table.unpack(stack.param))
		if editing or viewing then -- TODO：重构camera动画
			-- if editing or viewing then
				local c = Global.CameraControl:get()
				c:setCamera(entryEditAnima.camera)
				c:update()

				Global.CameraControl:pop(700)

				Global.Timer:add('popcamera', 700, function()
					entryEditAnima.view_mode = false
					entryEditAnima.popingcam = false
					if viewing then Global.CameraControl:pop() end
				end)
			-- else
				-- Global.CameraControl:pop()
			-- end
			-- stack.pushedcamera = false
		end

		self:popStack()
	end

	local curstack = self.stack[#self.stack]
	if curstack.isswitch then
		Global.Switcher.onSwitch = function()
			dochange()
		end
		Global.Switcher.onOver = function()
			Global.gmm:syncGuideStep()
			Global.gmm:checkGuideStep()

			if cb then
				cb()
				cb = nil
			end
		end
		local type, subtype = Global.Switcher:getTypeAndSubType(curstack.state, curstack.param[4])
		Global.Switcher:show(true, type, subtype)
	else
		dochange()
		Global.gmm:syncGuideStep()
		Global.gmm:checkGuideStep()

		if cb then
			cb()
			cb = nil
		end
	end
end

entry.go = function(self, level, state, ...)
	local param = table.pack(...)
	local function dochange(isswitch)
		self:updateStack()

		tmp_xl_change_stage(level, nil, state, param)

		self:dospecial(level, table.unpack(param))
		self:doDoneFunc()
		self.level = level
		self.state = state
		self.param = param
		self.isswitch = isswitch
		self:pushStack()
	end

	local type, subtype = Global.Switcher:getTypeAndSubType(state, param[4])
	Global.Switcher:doSwitch(level, type, subtype, dochange)
end

entry.dospecial = function(self, level, ...)
	if Global.role then
		Global.role.onInsideHouse = nil
		Global.role.onOutsideHouse = nil
		Global.role.onObtainObject = nil
	end
	local special = Global.findSenName(level)
	if special == 'studio' then
		Global.CameraControl:get():turnToward(_Vector3.new(0, 1, 0), 0, 'lcc')
		Global.CameraControl:get():followTarget('rolehouse')
	elseif special == 'house1' then
		local c = Global.CameraControl:get()
		c:turnToward(_Vector3.new(0, 1, 0), 0, 'lcc')

		Global.Switcher.waitfinish = true
		Global.House:initHouse(..., function()
			Global.Switcher:playEndAnima()

			local bgpfx = Global.sen.pfxPlayer:play('buildhousebg.pfx')
			bgpfx.visible = false
			Global.sen.bgpfx = bgpfx

			if entryEditAnima.edit_mode then
				c:followTarget()
				Global.Operate.disableRole = true
				entryEditAnima.timer:start('leave', 200, function()
					Global.Operate.disableRole = false
					Global.role:leaveEdit()
					entryEditAnima.timer:stop('leave')
				end)
				entryEditAnima.timer:start('leave2', 700, function()
					local c = Global.CameraControl:get()
					c:followTarget('rolehouse')
					entryEditAnima.edit_mode = false
					entryEditAnima.timer:stop('leave2')
				end)
			else
				c:followTarget('rolehouse')
			end

			if entryEditAnima.view_mode then
				Global.role:leaveEdit()
			end

			for i, v in ipairs(Global.sen.blocks) do
				if v.insideFlag ~= true and v.node.visible and
				v.data.shape ~= 'gardendoor' and v.data.shape ~= 'rolestand' and
				v.data.shape ~= 'blocki' and v.data.shape ~= 'Broken_bridge' and
				v.data.shape ~= 'blocki_fence' then
					v.outsideFlag = true
				end
			end

			local showInsideHouse = function()
				if Global.sen and Global.sen.bgpfx then
					Global.sen.bgpfx.visible = true
				end
				for i, v in ipairs(Global.sen.blocks) do
					local isinside = v.insideFlag == true
					if isinside then
						v:setVisible(true, true)
					end
					local isoutside = v.outsideFlag == true
					if isoutside then
						v:setVisible(false, false)
					end
				end
			end
			local showOutsideHouse = function()
				if Global.sen and Global.sen.bgpfx then
					Global.sen.bgpfx.visible = false
				end
				for i, v in ipairs(Global.sen.blocks) do
					local isinside = v.insideFlag == true
					if isinside then
						v:setVisible(false, false)
					end
					local isoutside = v.outsideFlag == true
					if isoutside then
						v:setVisible(true, true)
					end
				end
			end

			Global.role.onRefreshTime = function(inside)
				if inside then
					Global.TimeOfDayManager:setCurrentTime(12, 'inside')
				else
					local curtime = _sys.currentTime
					local time = curtime.hour + curtime.minute / 60
					Global.TimeOfDayManager:setCurrentTime(time)
				end
			end
			Global.role.onInsideHouse = function()
				showInsideHouse()
				Global.gmm:syncBlockiVisible()
				if Global.TimeOfDayManager.enableInOutHouse then
					Global.TimeOfDayManager:setCurrentTime(12, 'inside')
				end
				Global.AudioPlayer:setVolume(1)
			end
			Global.role.onOutsideHouse = function()
				showOutsideHouse()
				Global.gmm:syncBlockiVisible()
				if Global.TimeOfDayManager.enableInOutHouse then
					local curtime = _sys.currentTime
					local time = curtime.hour + curtime.minute / 60
					Global.TimeOfDayManager:setCurrentTime(time)
				end
				Global.AudioPlayer:setVolume(0.3)
			end
			Global.role.onObtainObject = function()
				if Global.SwitchControl:is_render_off() or Global.House:isInMyHouse() == false then return end
				if Global.gmm:isPlayingObtainMovie() then return end
				if Global.gmm:hasObtainObjects() == false then return end
				if Global.gmm.checkmaildone then
					Global.gmm.onObtainMovieFinish = function()
						Global.gmm:askGuideStepCheckMail()
					end
					Global.gmm.checkmaildone = nil
				end
				Global.gmm:playObtainMovie()
			end

			local updateRolePosAvoidPushing = function()
				local rpos = Container:get(_Vector3)
				local roleaabb = Container:get(_AxisAlignedBox)
				local blockaabb = Container:get(_AxisAlignedBox)
				local intersect = true
				while intersect do
					intersect = false
					Global.role:getAABB(roleaabb)
					for i, v in ipairs(Global.sen.blocks) do
						if v.insideFlag and Global.HouseBases[v:getShape()] == nil then
							v:getAABB(blockaabb)
							if roleaabb:checkIntersect(blockaabb) then
								intersect = true
								Global.role:getPosition(rpos)
								rpos.z = rpos.z + blockaabb.max.z - roleaabb.min.z + 0.1
								Global.role:setPosition(rpos)
								break
							end
						end
					end
				end
				Container:returnBack(rpos, roleaabb, blockaabb)
			end

			if Global.role.tempisinside then
				showInsideHouse()
				updateRolePosAvoidPushing()
				Global.gmm:syncBlockiVisible()
				Global.role.tempisinside = nil
			end
			Global.sen:update()
			Global.ui.interact:refresh()
			Global.ui.interact:autoopen()
		end)
	elseif special == 'house2' then
		_rd.bgColor = _Color.Black

		local ca = Global.CameraControl:get()
		ca:lockDirV(0.05, 1.4)
		ca.minRadius = 2
		ca.maxRadius = 10
		ca.camera.viewFar = 5000
		ca.camera:setBlocker(Global.sen, Global.CONSTPICKFLAG.NORMALBLOCK)

		Global.fameUI:flushUI()
		Global.gmm.onEvent('showgramophone')
		Global.gmm.onEvent('playgramophone')
		Global.gmm.onEvent('floorhide')
		Global.gmm.onEvent('updatelocaltime')
		Global.gmm.onEvent('showfamegift')
		if Global.sen.skyBox then
			local mtl = Global.sen.skyBox.mesh.material
			mtl.isNoFog = true
			mtl.isNoLight = true
		end

		Global.PortalFixTask:initScene()
		Global.Leaderboard_brawl:initBlock()
		Global.Leaderboard_neverup:initBlock()
		Global.BlockBrawlEntry:initBlock()
		Global.BlockBrawlEntry:updateMatchUI()

		Global.NeverDownEntry:initBlock()
		Global.NeverDownEntry:updateMatchUI()

		Global.NeverUpEntry:initBlock()
		Global.NeverUpEntry:updateMatchUI()

		Global.MarioEntry:initBlock()
		Global.MarioEntry:updateMatchUI()

		Global.GOS1Entry:initBlock()

		TEMP_BRWOSE_SCENE_INIT()

		local updatedestroybrick = function(block)
			local vec = Container:get(_Vector3)
			block.node.transform:getTranslation(vec)
			if vec.z < 1 then
				Global.sen:delBlock(block)
			end
			Container:returnBack(vec)
		end

		for i, v in ipairs(Global.sen:getAllBlocks()) do
			local shape = v:getShape()
			if v.data.shape == 'brickcandestroy' then
				v:setPickFlag(Global.CONSTPICKFLAG.PHYSICALBLOCK)
				v:addPushupEvent(function()
					Global.SoundManager:play('destroybrick.mp3')
					v:buttonPress(_Vector3.new(0, 0, 0.2), 200)
					local t = _Vector3.new()
					v.node.transform:getTranslation(t)
					local objects = Global.sen:createBlockByCell({
						shape = v.data.shape,
						space = {
							scale = _Vector3.new(1, 1, 1),
							rotation = _Vector4.new(0, 0, 1, 0),
							translation = _Vector3.new(t.x, t.y, t.z),
						},
					})
					for p, q in ipairs(objects) do
						q.node.needUpdate = true
						q.update = updatedestroybrick
					end
					Block.pushupblast(objects, 3, 600, false, 0.4)
					table.insert(Global.sen.DestoryBlock, objects)
					if #Global.sen.DestoryBlock > 20 then
						local oldblocks = Global.sen.DestoryBlock[1]
						for i = #oldblocks, 1, -1 do
							Global.sen:delBlock(oldblocks[i])
						end
						table.remove(Global.sen.DestoryBlock, 1)
					end
					v:changeTransparency(0, 0)
					v:setVisible(false, false)
					Global.Timer:add('destroybrick', 5000, function()
						v:setVisible(true, true)
						v:changeTransparency(1, 0.3)
						v:setPickFlag(Global.CONSTPICKFLAG.PHYSICALBLOCK)
					end)
				end)
				v:addDownEvent(function()
					v:buttonPress(_Vector3.new(0, 0, -0.2), 200)
				end)
			end
		end
		Global.sen:update()
		Global.ui.interact:refresh()
		Global.ui.interact:autoopen()
	elseif special == 'house3' then
		_rd.bgColor = _Color.Black

		local ca = Global.CameraControl:get()
		ca:lockDirV(0.05, 1.4)
		ca.minRadius = 2
		ca.maxRadius = 10
		ca.camera.viewFar = 5000
		ca.camera:setBlocker(Global.sen, Global.CONSTPICKFLAG.NORMALBLOCK)
		-- if Global.sen.skyBox then
		-- 	local mtl = Global.sen.skyBox.mesh.material
		-- 	mtl.isNoFog = true
		-- 	mtl.isNoLight = true
		-- end

		Global.GOS1Entry:init(Global.sen)

		--只开主角阴影，用新阴影
		_sys.enableOldShadow = false
		_rd.enableShadowProjection = true
		for _, b in next, Global.sen:getAllBlocks() do
			b.node.isShadowCaster = false
		end

		Global.sen:update()
	elseif special == 'guide' then
		Global.role:focusBack(0)
		Global.Guide:init()
		Global.Guide:moveGuide()
	elseif special == 'checkpoint' then
		_G.RUN_MAX = 0.006
	elseif special == 'avatar_room' then
		Global.Switcher.onOver = function()
			local c = Global.CameraControl:get()
			c:setCamera(Global.sen.graData:getCamera('camera2'))
			c:lockDirH(-math.pi, math.pi)
			c:lockDirV(-math.pi, math.pi)
			c:update()
			local ctarget = Global.sen.graData:getCamera('camera1')
			c:setCamera(ctarget, 800)
			c:use()
			Global.Timer:add('movecamera', 1000, function()
				_rd.camera = ctarget
				Global.DressAvatar:updateUIPos()
				Global.DressAvatar:moveToObject()
				c:use()
			end)
		end
	end
end

entry.addDoneFunc = function(self, func)
	table.insert(self.donefuncs, 1, func)
end

entry.doDoneFunc = function(self)
	if #self.donefuncs == 0 then return end

	for i, v in ipairs(self.donefuncs) do
		v()
	end

	self.donefuncs = {}
end

entry.goLevel = function(self, l, ...)
	self:addDoneFunc(function()
		Global.ui:showEdit(false, false)
	end)
	self:go(l, 'GAME', ...)
end
entry.goEdit = function(self, l)
	self:addDoneFunc(function()
		Global.ui:showEdit(true, true)
		Global.sen:showTile(true)
	end)
	self:go(l, 'EDIT')
end
entry.goHome = function(self)
	if Version:isAlpha1() then
		self:goStudio()
		return
	end

	self:addDoneFunc(function()
		Global.ui:showEdit(Global.Achievement:check('build1'), false)
	end)
	self:goLevel('home.sen')
end
entry.goHome0 = function(self, house, islogin)
	self:addDoneFunc(function()
		if house then
			entryEditAnima.view_mode = true
			entryEditAnima.camera = _rd.camera:clone() -- from uibrowser's camera
		end
	end)
	self:addDoneFunc(function()
		if not islogin or islogin == false then
			local curtime = _sys.currentTime
			local time = curtime.hour + curtime.minute / 60
			Global.TimeOfDayManager:setCurrentTime(time)
		end
	end)
	self:addDoneFunc(function()
		Global.gmm:syncGuideStep()
	end)
	self:go('house1.sen', 'GAME', house)
end

entry.goHome1 = function(self, house, islogin)
	self:goHome2(house, islogin)
end

entry.goHome2 = function(self, house)
	self:addDoneFunc(function()
		if house then
			entryEditAnima.view_mode = true
			entryEditAnima.camera = _rd.camera:clone() -- from uibrowser's camera
		end
	end)
	self:go('house2.sen', 'GAME', house)
end
entry.goHome3 = function(self, house, islogin)
	self:go('house3.sen', 'GAME', house)
end
entry.goGuide = function(self)
	self:go('guide.sen', 'GAME')
end
entry.goStudio = function(self)
	self:go('studio.sen', 'GAME')
end
entry.goPark = function(self)
	self:go('park.sen', 'GAME')
end
entry.goCreateRole = function(self)
	self:go(Version:isAlpha1() and 'studio.sen' or 'guide.sen', 'GAME')
end
entry.goLoginIn = function(self)
	self:addDoneFunc(function()
		Global.gmm.onEvent('floorshow')
		Global.gmm.onEvent('disablepostprocess')
		-- 5月版本光影由场景决定，登录时使用固定光源，角色往下掉时恢复使用场景光源
		Global.gmm.onEvent('locklocaltime')
		Global.gmm.onEvent('disableinput')
		Global.gmm.onEvent('disablecamera')
		Global.gmm.onEvent('camerablockdisable')
		Global.gmm.onEvent('loginbegin')
		Global.gmm.onEvent('showmode1')
	end)
	self:goHome2(nil)
end
entry.goBuildBrick = function(self, objname, istemplate)
	-- self:addDoneFunc(function()
	-- 	Global.TimeOfDayManager:setCurrentTime(12)
	-- end)
	self:go('build.sen', 'BUILDBRICK', objname, 'buildbrick', {istemplate = istemplate})
end

entry.goBuildScene = function(self, objname, istemplate, mode)
	-- self:addDoneFunc(function()
	-- 	Global.TimeOfDayManager:setCurrentTime(12)
	-- end)
	self:go('build.sen', 'BUILDBRICK', objname, 'buildscene', {istemplate = istemplate, scenemode = mode or 'scene'})
end

entry.goBuildAnima = function(self, objname, istemplate, mode)
	-- self:addDoneFunc(function()
	-- 	Global.TimeOfDayManager:setCurrentTime(12)
	-- end)
	self:go('room_animal.sen', 'BUILDBRICK', objname, 'buildanima', {istemplate = istemplate, bardmode = mode})
end

-- entry.goBuildTransition = function(self, objname)
-- 	self:go('build.sen', 'BUILDBRICK', objname, 'buildtransition')
-- end

entry.goBuildRepair = function(self, objname, autoBlueprint)
	-- self:addDoneFunc(function()
	-- 	Global.TimeOfDayManager:setCurrentTime(12)
	-- end)
	-- 自动保存
	self:go('build.sen', 'BUILDBRICK', objname, 'buildrepair', {autoBlueprint = autoBlueprint})
end
entry.goRepair = function(self, objname, level)
	-- self:addDoneFunc(function()
	-- 	Global.TimeOfDayManager:setCurrentTime(12)
	-- end)
	self:go('repair.sen', 'BUILDBRICK', objname, 'repair', {repairlevel = level})
end
entry.goRepairBlueprint = function(self, bp)
	-- self:addDoneFunc(function()
	-- 	Global.TimeOfDayManager:setCurrentTime(12)
	-- end)

	--print('goRepairBlueprint:', table.ftoString(bp))
	local level = bp.data and bp.data.level or 1
	local objname = bp.data and bp.data.datafile and bp.data.datafile.name or bp[level] and bp[level].name
	self:go('repair.sen', 'BUILDBRICK', _sys:getFileName(objname, false, false), 'repair', {blueprint = bp})
end
entry.goBuildHouse = function(self)
	Global.role:enterEdit()
	entryEditAnima.edit_mode = true
	entryEditAnima.camera = _rd.camera:clone()
	entryEditAnima.timer:start('build', 150, function()
		self:go('room_1.sen', 'BUILDHOUSE')
		entryEditAnima.timer:stop('build')
	end)
end
entry.goBuildFunc = function(self, objname, level)
	self:go('build.sen', 'BUILDFUNC', objname, level)
end
entry.goBrowser = function(self, objects, index, needmore, type, mode, buildmode)
	self:go('browserbg.sen', 'BROWSER', objects, index, needmore, type, mode, buildmode)
end
entry.goBuildShape = function(self, id)
	self:go('build.sen', 'BUILDSHAPE', id)
end
entry.goBuildKnot = function(self, id)
	self:go('build.sen', 'BUILDKNOT', id)
end

entry.goBlockBrawl = function(self, players, seed, end_time)
	self:go('build.sen', 'BLOCKBRAWL', players, seed, end_time)
end
-- shapeid, players, mode, seed, data
entry.goDungeon = function(self, obj, players, mode, seed, data)
	mode.obj = obj
	self:go(obj.name, 'NEVERUP', players, mode, seed, data)
end
entry.goMario = function(self, mariodungeon, players, mode)
	self:go(mariodungeon, 'MARIO', players, mode)
end
entry.goAvatarRoom = function(self)
	entryEditAnima.timer:start('dress', 150, function()
		self:addDoneFunc(function()
			Global.TimeOfDayManager:setCurrentTime(12)
		end)
		self:go('avatar_room_01.sen', 'DRESSUP')
		entryEditAnima.timer:stop('dress')
	end)
end

local volumes = {
	room_1 = {volume = 0.3},
	house1 = {volume = 1},
	house2 = {volume = 1},
	browserbg = {volume = 0.3},
}

_G.initLevel = function(scenename, roledata)
	if Global.sen and _sys:getFileName(Global.sen.resname, false, false) == _sys:getFileName(scenename, false, false) then return end

	local volume = volumes[_sys:getFileName(scenename, false, false)]
	if volume then
		Global.AudioPlayer:setVolume(volume.volume)
	else
		Global.AudioPlayer:stop()
	end
	Global.UI:clearStack()
	Global.CameraControl:new()

	if Global.role then
		Global.role:release()
	end

	hideDownTip()
	Global.InputManager:init()
	Global.ui.interact:clear()
	Global.Barrage:show(false)

	Global.dungeon = nil
	setRoleMoveParam() -- 放在CreateDungeon前面，因为CreateDungeon里有可能会修改参数
	if _sys:getExtention(scenename) == 'sen' then
		_G.load_dungeon = false
		CreateScene(scenename, true)
		if Global.sen.setting.needrole then
			Global.Role.new()
			TEMP_CREATE_ROLECCT()
			Global.role:setJumpLimit(2)
			TEMP_SETUP_CAMERA()
			Global.role:Respawn()
			if roledata then
				Global.role:setPosition(roledata.pos)
				Global.role:updateFace(roledata.dir, 0)
				Global.role.tempisinside = roledata.isinside
				Global.role.insideHouseOld = roledata.isinside
				Global.role.refreshTime = true
			end
		end
	else
		_G.load_dungeon = true
		CreateDungeon(scenename)
	end
	TEMP_SETUP_PARKOUR_UI()

	--- 临时处理小岛 / gos chip
	if scenename == 'house2.sen' or scenename == 'house3.sen' then
		Global.InputManager:registerDown(_System.KeyA, function()
			Global.role:do_move_event("LEFT", true)
		end)
		Global.InputManager:registerUp(_System.KeyA, function()
			Global.role:do_move_event("LEFT", false)
		end)
		Global.InputManager:registerDown(_System.KeyD, function()
			Global.role:do_move_event("RIGHT", true)
		end)
		Global.InputManager:registerUp(_System.KeyD, function()
			Global.role:do_move_event("RIGHT", false)
		end)
		Global.InputManager:registerDown(_System.KeyW, function()
			Global.role:do_move_event("UP", true)
		end)
		Global.InputManager:registerUp(_System.KeyW, function()
			Global.role:do_move_event("UP", false)
		end)
		Global.InputManager:registerDown(_System.KeyS, function()
			Global.role:do_move_event("DOWN", true)
		end)
		Global.InputManager:registerUp(_System.KeyS, function()
			Global.role:do_move_event("DOWN", false)
		end)
		Global.InputManager:registerDown(_System.KeyLeft, function()
			Global.role:do_move_event("LEFT", true)
		end)
		Global.InputManager:registerUp(_System.KeyLeft, function()
			Global.role:do_move_event("LEFT", false)
		end)
		Global.InputManager:registerDown(_System.KeyRight, function()
			Global.role:do_move_event("RIGHT", true)
		end)
		Global.InputManager:registerUp(_System.KeyRight, function()
			Global.role:do_move_event("RIGHT", false)
		end)
		Global.InputManager:registerDown(_System.KeyUp, function()
			Global.role:do_move_event("UP", true)
		end)
		Global.InputManager:registerUp(_System.KeyUp, function()
			Global.role:do_move_event("UP", false)
		end)
		Global.InputManager:registerDown(_System.KeyDown, function()
			Global.role:do_move_event("DOWN", true)
		end)
		Global.InputManager:registerUp(_System.KeyDown, function()
			Global.role:do_move_event("DOWN", false)
		end)
		Global.InputManager:registerDown(_System.KeySpace, function()
			Global.role:do_move_event('JUMP', true)
		end)
		Global.InputManager:registerUp(_System.KeySpace, function()
			Global.role:do_move_event('JUMP', false)
		end)
	end
end