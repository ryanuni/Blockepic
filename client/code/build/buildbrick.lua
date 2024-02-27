--[[
	rt变量
		rt_mode		select模式（light/heavy）
		rt_block	pick的block
		rt_selectedBlocks	选中的bs
		rt_selectedGroups	选中的groups
		rt_transform		update时的父mat
	行为
		select
			light	短按
			heavy	长按，要拆分group
		update
			move
				moveBegin
				moveMove
				moveEnd
			rotate
				showui
		delete
		add
	交互
		onDown
			light、heavy（timer）
			moveBegin（onSelect）
		onMove
			moveMove
		onUp
			moveEnd
			showui（重复选择时）

]]
local Container = _require('Container')
local SoundGroup = _require('SoundGroup')

local BuildBrick = {}
_G.BuildBrick = BuildBrick
_dofile('cfg_switchpart.lua')
_dofile('buildbrick_tostring.lua')

_dofile('buildbrick_atom.lua')
_dofile('buildbrick_cmd.lua')
_dofile('buildbrick_camera.lua')
_dofile('buildbrick_debug.lua')

_dofile('buildbrick_group.lua')
_dofile('buildbrick_module.lua')
_dofile('buildbrick_part.lua')
_dofile('buildbrick_scene.lua')
_dofile('buildbrick_operate.lua')
_dofile('buildbrick_dframe.lua')

_dofile('buildbrick_repair.lua')
_dofile('buildbrick_music.lua')

local movedelta = 30
if _sys.os == 'win32' then
	movedelta = 3
elseif _sys.os == 'mac' then
	movedelta = 10
end

BuildBrick.movedelta = movedelta
BuildBrick.defaultImageSize = 256
BuildBrick.postProcess = _PostProcess.new()
BuildBrick.postProcess.bloom = false
BuildBrick.postProcess.dof = false
BuildBrick.postProcess.toneMapKeepAlpha = true

-- ui notice controller
BuildBrick.ObjectState = {
	Unknown = 0,
	Published = 1,
	Copied = 2,
	Draft = 4,
	NFT = 8,
	New = 16,
	Transitions = 32,
}

BuildBrick.stack = {}
local function isSameMtl(mtl1, mtl2)
	local materialKey = {
		'material', 'mtlmode', 'color', 'roughness'
	}

	for i, key in pairs(materialKey) do
		if mtl1[key] ~= mtl2[key] then
			return false
		end
	end

	return true
end

local BBKs = {}
local newindex = function(t, k, v)
	BBKs[k] = true

	rawset(t, k, v)
end

BuildBrick.new = function()
	local bb = {}
	--setmetatable(bb, {__index = BuildBrick})
	setmetatable(bb, {__index = BuildBrick, __newindex = newindex})

	return bb
end

BuildBrick.isBuildScene = function(self)
	return self.mode == 'buildscene'
end

--过场动画
BuildBrick.showInterlude = function(self, mode, isclose, cb)
	--print('!!!showInterlude', debug.traceback())
	local nodes = {}
	self.sen:getNodes(nodes)
	for i, n in ipairs(nodes) do
		--print('n.visible', i, n.visible)
		n.oldvisible = n.visible
		n.visible = false
	end

	local block
	if mode == 'buildscene' then
		block = self.sen:createBlock({shape = 'scene_table_animation'})
	elseif mode == 'buildanima' then
		block = self.sen:createBlock({shape = 'avatar_table_animation'})
	else
		block = self.sen:createBlock({shape = 'brick_table_animation'})
	end

	local h = -30.8
	block.node.transform:mulTranslationRight(0, 0, h)
	block:setPickFlag(Global.CONSTPICKFLAG.WALL)
	block.isdummyblock = true
	block.isWall = true
	self.initBlockCount = self.initBlockCount + 1
	local time = 1200

	local oldenableOpenLib = self.enableOpenLib
	local oldenableCamMove = self.enableCamMove
	self.enableOpenLib = false
	self.enableCamMove = false
	self.isshowInterlude = true

	local camera1 = _Camera.new()
	camera1.eye = _Vector3.new(0, -176.101, 94.078)
	camera1.look = _Vector3.new(0.000, 0.000, 0.200)

	local camera2 = _Camera.new()
	local cc = self:getCameraControl()
	-- local r = math.min(cc.camera:getScale(), 30)
	local r = math.min(cc:getScale(), 30)
	camera2.eye = _Vector3.new(0, -0.72, 0.45)

	--camera2.eye:mul(r)
	_Vector3.mul(camera2.eye, r, camera2.eye)
	print('r', r, camera2.eye)
	-- if self:getParam('scenemode') == 'scene_music' then
	-- 	camera2.eye = _Vector3.new(0, -18.0, 10.8)
	-- else
	-- 	camera2.eye = _Vector3.new(0, -9.0, 5.4)
	-- end
	camera2.look = _Vector3.new(0.000, 0.000, 0.200)

	local c = self:getCameraControl()
	c:setCamera(isclose and camera2 or camera1)
	c:update()

	local t1 = 400
	self.timer:start('showInterlude', t1, function()
		local cam2 = isclose and camera1 or camera2
		--local r2 = cam2.radius
		-- if #nbs > 0 and r1 > r2 then
		-- 	cam2:moveRadius(r1 - r2)
		-- end
		c:setCamera(cam2, time - t1)
		self.timer:stop('showInterlude')
	end)

	block:playDynamicEffect('df1', nil, isclose, function()
		for i, n in ipairs(nodes) do
			--print('n.oldvisible', i, n.oldvisible)
			n.visible = n.oldvisible
			n.oldvisible = nil
		end
		Global.sen:delBlock(block)
		self.initBlockCount = self.initBlockCount - 1

		self.enableOpenLib = oldenableOpenLib
		self.enableCamMove = oldenableCamMove
		self.isshowInterlude = false

		if cb then cb() end
	end)

	block:stopDynamicEffect(true)
end

BuildBrick.initData = function(self, mode, shapeid, params)
	-- print('initData', mode, shapeid, value2string(params))
	self.params = params
	if mode == 'buildanima' and shapeid == 'defaultavatar' then
		if not Global.ObjectManager:hasSpecialAvatar() then
			self:setParam('buildDefaultAvatar', true)
		end
	elseif self:getParam('autoBlueprint') and mode == 'buildrepair' and shapeid and shapeid ~= '' then
		self:setParam('buildrepairName', shapeid)
		self.buildrepairModules = {}
	end

	self.mode = mode
	self.enableOpenLib = true
	self.enablePart = false
	self.enableTransition = false
	self.enableGroup = true
	self.enableRepair = false
	self.enableCamMove = true
	self.disableGroupCombine = false

	self.enableAutoPlaneZ = false
	self.enableBrickMat = true
	self.enableSwitchPart = true
	self.showModuleList = false
	self.enableGraffiti = false
	self.showfuncflagui = false
	self.enableDragSelect = true
	self.noCenter = false
	self.partopt = 'exit'
	self.planeZ = 0

	self.groupStack = {}
	self.freqs = {}
	self.knotMode = Global.KNOTPICKMODE.NONE

	self:changeTranspanetMode(true)

	-- self:enableEditLv(false)
	self:createWalls()
	if mode == 'buildbrick' then
		self.enableTransition = true
		self.knotMode = Global.KNOTPICKMODE.NORMAL
		self:loadbglv('brick_table.lv')
	elseif mode == 'buildanima' then
		self.enablePart = true
		self.knotMode = Global.KNOTPICKMODE.NORMAL
		self:loadbglv('avatar_table.lv')
	elseif mode == 'buildscene' then
		self.enableTransition = false
		self.disableGroupCombine = true
		self.noCenter = true

		if self:getParam('scenemode') == 'scene_music' then
			self:loadbglv()
			self.checkmovehit = false
		else
			self:loadbglv('scene_table.lv')

			if _sys:getGlobal('PCRelease') then
			else
				local marker0 = _Vector3.new(1.9, -14, 0.02)
				local musicbox = self.sen:createBlock({shape = 'musicbox'})
				local ab = musicbox:getShapeAABB2()
				local diff = ab:diffBottom(marker0)
				musicbox.node.transform:mulTranslationRight(diff)
				musicbox.isWall = true
				musicbox.isdummyblock = true
				musicbox.ui_click_cb = function()
					print('click musicbox')
					musicbox:setShape('musicbox2')
					local ab = musicbox:getShapeAABB2(true)
					local diff = ab:diffBottom(marker0)
					musicbox.node.transform:mulTranslationRight(diff)

					local selmusic = self.bgmusic or Global.AudioPlayer:getBlankSource()
					Global.MusicLibrary:show(true, 'BGM', selmusic, function()
						musicbox:setShape('musicbox')
					end)
					-- Global.BlockChipUI:show('main', self.chips_s, function()
					-- 	musicbox:setShape('musicbox')
					-- end)
				end

				local marker1 = _Vector3.new(4.1, -14, 0.02)
				local role = self.sen:createBlock({shape = 'player1'})
				local ab = role:getShapeAABB2()
				local diff = ab:diffBottom(marker1)
				role.node.transform:mulTranslationRight(diff)
				role.isWall = true
				role.isdummyblock = true
				role.ui_click_cb = function()
					print('click role')
					role:setShape('player2')

					Global.BlockChipUI:show('main', self.chips_s.player, function()
						role:setShape('player1')
					end)
				end

				local marker2 = _Vector3.new(6.3, -14, 0.02)
				local dungeon = self.sen:createBlock({shape = 'dungeon1'})
				local ab = dungeon:getShapeAABB2()
				local diff = ab:diffBottom(marker2)
				dungeon.node.transform:mulTranslationRight(diff)
				dungeon.isWall = true
				dungeon.isdummyblock = true
				dungeon.ui_click_cb = function()
					print('click dungeon')
					dungeon:setShape('dungeon2')
					Global.BlockChipUI:show('main', self.chips_s.dungeon, function()
						dungeon:setShape('dungeon1')
					end)
				end

				self.initBlockCount = self.initBlockCount + 3
			end

		end

	elseif mode == 'buildrepair' or mode == 'repair' then
		self.enableRepair = true
		self.disableGroupCombine = true
		self.enableDragSelect = false
		-- self.enableAutoPlaneZ = false

		if mode == 'repair' then
			self.enableCamMove = false

			local ground_node = self.sen:getNode('ground')
			if ground_node then
				ground_node.actor = self.sen:addActor(_PhysicsActor.Cube)
				ground_node.actor.shapeSize = _Vector3.new(100, 100, 1)
				ground_node.mesh.isInvisible = true
			end
		end

		self:loadbglv('brick_table.lv')
	end

	if self.enableRepair then
		self:initRepairData()

		self.ondownfunc = self.ondown_editrepair
		self.onmovefunc = self.onmove_editrepair
		self.onupfunc = self.onup_editrepair
	else
		self.ondownfunc = self.ondown_editbrick
		self.onmovefunc = self.onmove_editbrick
		self.onupfunc = self.onup_editbrick
	end

	-- 修复模式与动画模式不显示阻挡
	if self.enableRepair or self.enablePart then
		Global.enableBlockingBlender = false
	else
		Global.enableBlockingBlender = true
	end

	self:initUI()
	self:load(shapeid)
	self:initCamera()
	self:showMultiSelectPanel(false)

	if not self.chips_s then self.chips_s = {player = {}, dungeon = {}, main = {}} end
	if not self.pairBlocks then self.pairBlocks = {} end

	-- TODO:special
	if self:getParam('istemplate') then
		-- 默认芯片
		--local p_chip = {}
		local p_chip = self.chips_s.player
		local gen_enum_tb = function(v)
			return {Op = 'Set', Type = 'enum', Value = v}
		end
		local gen_target_self_tb = function()
			return {
				params = {
					[1] = {Op = '', Type = 'get', Value = 'Self'}
				},
				target = 'Self'
			}
		end
		local gen_move_event = function(name, key, dir, value)
			return {
				Name = name,
				params = {
					[1] = gen_enum_tb(key),
				},
				Target = gen_target_self_tb(),
				sub_chips = {
					[1] = {
						Name = 'Move',
						params = {
							[1] = gen_enum_tb(dir),
							[2] = gen_enum_tb(value),
						},
						Target = gen_target_self_tb()
					}
				}
			}
		end
		local gen_jump_event = function(name, key)
			return {
				Name = name,
				params = {
					[1] = gen_enum_tb(key),
				},
				Target = gen_target_self_tb(),
				sub_chips = {
					[1] = {
						Name = 'Jump',
						Target = gen_target_self_tb()
					}
				}
			}
		end

		-- if self:getParam('scenemode') == 'scene' or self:getParam('scenemode') == 'scene_music' then
		-- 	table.insert(p_chip, {[1] = gen_move_event('ControlPush', 'KeyW', 'UP', 'true')})
		-- 	table.insert(p_chip, {[1] = gen_move_event('ControlRelease', 'KeyW', 'UP', 'false')})
		-- 	table.insert(p_chip, {[1] = gen_move_event('ControlPush', 'KeyS', 'DOWN', 'true'),})
		-- 	table.insert(p_chip, {[1] = gen_move_event('ControlRelease', 'KeyS', 'DOWN', 'false'),})
		-- end

		-- table.insert(p_chip, {[1] = gen_move_event('ControlPush', 'KeyA', 'LEFT', 'true'),})
		-- table.insert(p_chip, {[1] = gen_move_event('ControlRelease', 'KeyA', 'LEFT', 'false'),})
		-- table.insert(p_chip, {[1] = gen_move_event('ControlPush', 'KeyD', 'RIGHT', 'true'),})
		-- table.insert(p_chip, {[1] = gen_move_event('ControlRelease', 'KeyD', 'RIGHT', 'false'),})

		-- table.insert(p_chip, {[1] = gen_move_event('ControlPush', 'KeySpace', 'JUMP', 'true')})
		-- table.insert(p_chip, {[1] = gen_move_event('ControlRelease', 'KeySpace', 'JUMP', 'false')})
	end

	self.train_runway, self.train_pole = nil, nil
	if self:getParam('scenemode') == 'scene_music' then
		local nbs = {}
		self:getBlocks(nbs)
		for i, b in ipairs(nbs) do
			if self:getMarkerType(b) == 'marker_train' then
				b:setPickFlag(Global.CONSTPICKFLAG.NONE)
				--b.node.visible = false
				b:setVisible(false)
				if b.markerdata.name == 'runway' then
					self.train_runway = b
					self.musicFloorMode = 0
				elseif b.markerdata.name == 'runway1' then
					self.train_runway = b
					self.musicFloorMode = 1
				elseif b.markerdata.name == 'pole' then
					self.train_pole = b
				end
			end
		end

		self:goMusicMode('music_main')
	end

	self.oriMd5 = self:calcMd5()

	self:onBrickChange()
end

--param1, param2
BuildBrick.init = function(self, sen, shapeid, mode, params)
	local cc = Global.CameraControl:new()
	self.cc = cc

	self.sen = sen
	sen.BuildBrick = self
	_rd.bgColor = _Color.Gray

	self.dragSelect = _dofile('buildbrick_drag.lua')
	self.dragSelect:setOwner(self)

	if _sys:getGlobal('AUTOTEST') then
		self.showHelperAABB = true
	end

	Tip(Global.TEXT.TIP_BUILDBRICK)

	-- cc.minRadius = 2
	-- cc.maxRadius = 40
	-- local angle1, angle2 = 0.05, 1.4
	-- cc:lockDirV(angle1, angle2)

	self.sindex = 0
	-- _rd.postProcess.ssao = _sys.os == 'win32'
	-- self.curmodule = nil
	-- self.moduledbs = {}

	self:clearGroups()

	local nodes = {}
	self.sen:getNodes(nodes)
	self.initBlockCount = 0
	for i, v in ipairs(nodes) do
		if v.block then
		else
			v.isWallNode = true
		end
	end

	self.skylightdir = Block.defaultSkyLight.direction
	local skylight = self.sen.graData:getLight('skylight')
	if skylight then
		self.skylightdir = skylight.direction
	end

	-- ui
	self.ui = Global.UI:new('BuildBrick.bytes')
	if self ~= Global.BuildBrick then
		self.disableUI = true
		self.ui.visible = false
	end

	self.timer = _Timer.new()

	-- self.params = params
	-- if mode == 'buildanima' and shapeid == 'defaultavatar' then
	-- 	if not Global.ObjectManager:hasSpecialAvatar() then
	-- 		self:setParam('buildDefaultAvatar', true)
	-- 	end
	-- elseif self:getParam('autoBlueprint') and mode == 'buildrepair' and shapeid and shapeid ~= '' then
	-- 	self:setParam('buildrepairName', shapeid)
	-- 	self.buildrepairModules = {}
	-- end

	self.parts = {}
	self.freqs = {}
	self.freqdbs = {}
	-- self.materials = {{material = 1, color = 0xfffff1f1, roughness = 1, mtlmode = Global.MTLMODE.PAINT}}
	self.state = self.ObjectState.Unknown

	-- self.planeZ = 0
	self.userAABBLocked = false
	self.bgAABBLocked = false
	self.userAABB = _AxisAlignedBox.new()
	self.bgAABB = _AxisAlignedBox.new()

	self.oldedgeBias = _rd.edgeBias
	self.oldpostEdgeOutOnly = _rd.postEdgeOutOnly
	self.checkmovehit = true

	if _sys.os == 'win32' or _sys.os == 'mac' then
		self.mdx = 0
		self.mdy = 0
	else
		self.mdx = 0
		self.mdy = -150
	end

	Global.Sound:stop()

	Global.UI:onDeviceOrientation(self.ui, function(oriH)
		local lib = Global.ui.bricklibrary
		lib._width = oriH and 1440 or 1020
		lib._x = (Global.ui._width - lib._width) / 2
		lib._y = (Global.ui._height - lib._height) / 2
		if Global.brickui.ui then
			Global.brickui.ui.mainlist.itemNum = Global.brickui.ui.mainlist.itemNum
			Global.brickui.ui.mainlistsmall.itemNum = Global.brickui.ui.mainlistsmall.itemNum
			Global.brickui.ui.mainlistsmall2.itemNum = Global.brickui.ui.mainlistsmall2.itemNum
		end
	end)

	self.BrickColors = {}
	for i, v in pairs(Global.BrickColors) do
		table.insert(self.BrickColors, v)
	end

	self:initData(mode, shapeid, params)
	if not self.enableRepair then
		self:showInterlude(self.mode)
	end

	Global.BlockChipUI:init()

	if self.mode == 'repair' then
		UPLOAD_DATA('build_puzzle_begin')
	elseif self.mode == 'buildanima' then
		UPLOAD_DATA('build_bard_begin')
	elseif self.mode == 'buildbrick' then
		UPLOAD_DATA('build_brick_begin')
	end

	self:onBrickChange()
	self:startAutoSave()

	self:showTopButtons()
end

BuildBrick.getParam = function(self, key)
	if not self.params then return end
	return self.params[key]
end

BuildBrick.getParams = function(self)
	return self.params
end

BuildBrick.cloneParams = function(self)
	local params = {}
	for k, v in pairs(self.params or {}) do
		params[k] = v
	end

	return params
end

BuildBrick.setParam = function(self, key, value)
	if not self.params then self.params = {} end
	self.params[key] = value
end

BuildBrick.startAutoSave = function(self)
	local autosave_func
	autosave_func = function()
		self.timer:stop()
		-- 保存成功3分钟后保存下次，失败则30m后再次尝试
		if self:autoSave() then
			self.timer:start("autosave", 1000 * 60 * 3, autosave_func)
		else
			self.timer:start("autosave", 1000 * 30, autosave_func)
		end
	end

	self.timer:start("autosave", 1000 * 60 * 3, autosave_func)
end

BuildBrick.stopAutoSave = function(self)
	self.timer:stop("autosave")
end

BuildBrick.reuseCamera = function(self)
	local c = self:getCameraControl()
	Global.CameraControl:set(c)
end

BuildBrick.initCamera = function(self)
	local c = self:getCameraControl()
	c:reset()
	--c:scale(16)
	-- c.camera.fov = 20
	-- c:moveDirH(math.pi / 2)
	-- c:moveDirV(math.pi / 6)
	-- c:lockZ(0.2)
	-- c:update()
	-- c:use()

	c.camera.viewNear = 0.15
	_rd.oldShadowBias = 0.0001

	c.minRadius = 2
	if self.mode == 'buildscene' then
		c.maxRadius = 140
	else
		c.maxRadius = 40
	end

	c:scale(16)
	-- if self.mode == 'buildscene' and self:getParam('scenemode') == 'scene_2D' then
	-- 	c:moveLook(_Vector3.new(0, 0, 2))
	-- 	c:lockDirV(0, 0)
	-- 	c:lockDirH(-1.4, 1.4)
	-- 	-- c:lockDirH(0, 0)
	-- 	c.camera.fov = 45
	-- 	c:moveDirH(math.pi / 2)
	-- 	c:moveDirV(0)
	-- 	c:lockZ()
	-- 	c:update()
	-- 	c:use()
	-- else
		-- local angle1, angle2 = 0.05, 1.4
		-- c:lockDirV(angle1, angle2)
		c:lockDirH()

		c.camera.fov = 20
		c:moveDirH(math.pi / 2)
		c:moveDirV(math.pi / 6)
		-- c:lockZ(0.2)
		c:update()
		c:use()

		local nbs = {}
		self:getBlocks(nbs)
		if #nbs > 0 then
			local aabb = Container:get(_AxisAlignedBox)
			Block.getAABBs(nbs, aabb)
			local r = calcCameraRadius(c.camera, aabb)
			if self.enableRepair then
				r = r + 2
			end

			if self.mode == 'repair' then
				c:lockZ((aabb.max.z + aabb.min.z) / 2)
			end

			c:scale(r)
			c:use()
			Container:returnBack(aabb)
		end
	-- end
end

BuildBrick.getCameraControl = function(self)
	return self.cc
end

BuildBrick.onDestory = function(self)
	_Material.clearflowStack()
	self:clearGroups()
	self.showSkl = false
	self:clearParts()

	self.downX, self.downY = nil, nil
	_rd.edgeBias = self.oldedgeBias or 0
	_rd.postEdgeOutOnly = self.oldpostEdgeOutOnly or 0

	Block.clearDataCache(self.shapeid)

	Global.Sound:play('bgm_ambient1')
	Global.Sound:play('bgm_ambient2')
	Global.Sound:play('bgm_ambient3')

	Tip()
	self:hideBricksUI()
	if self.ui then
		--Global.UI:del(self.ui)
		self.ui:removeMovieClip()
		self.ui = nil
		self.moduleItems = nil
	end
	if self.uiprop then
		--Global.UI:del(self.uiprop)
		self.uiprop:removeMovieClip()
		self.uiprop = nil
	end

	self.showrot = false
	self.rotHintUIs = nil
	self.moveUI = nil
	self.moveUIs = nil

	self.timer:stop()

	for k in pairs(BBKs) do
		self[k] = nil
	end
end
-----------------------------------------------------------
BuildBrick.getCurrCommand = function(self)
	local cmd = self:getModule().command
	return cmd
end

BuildBrick.clearCommand = function(self)
--	print('[clearCommand]')
	local cmd = self:getModule().command
	cmd:clear()
	self:ui_flush_undo()
end
BuildBrick.addCommand = function(self, redo, undo, des, des2)
	local cmd = self:getModule().command
	local ret = cmd:add(redo, undo, des)
	self:ui_flush_undo()

	self:addFameCommand(des, des2)
	return ret
end

-- redo/undo前的完成或取消当前未完成的操作
BuildBrick.cmdBefore = function(self)
	if self.moveX and self.moveY then
		self:building_moveEnd(self.moveX, self.moveY)
	end
end

BuildBrick.undo = function(self)
	self:cmdBefore()

	local cmd = self:getModule().command
	cmd:undo()
	self:ui_flush_undo()
end
BuildBrick.redo = function(self)
	self:cmdBefore()

	local cmd = self:getModule().command
	cmd:redo()
	self:ui_flush_undo()
end
BuildBrick.ui_flush_undo = function(self)
	local m = self:getModule()
	if not m then return end
	local cmd = self:getModule().command
	self.ui.btn_undo.visible = cmd:isUndoReady() and self:undoenabled()
	self.ui.btn_redo.visible = cmd:isRedoReady() and self:undoenabled()
end

BuildBrick.undoenabled = function(self)
	return self.partopt ~= 'preview' and self.mode ~= 'repair' and not self.hideNormalUI
end

local countedcommands = {
	['addBrick'] = true,
	['Delbrick'] = true,
	['Update'] = true,
	['SetMaterial'] = true,
	['Copy'] = true,
	['PartBind'] = true,
	['PartMove'] = true,
	['PartReset'] = true,
	['PartUnbind'] = true,
}

BuildBrick.getCommandCountsCount = function(self)
	if not self.operateKeys then return 0 end

	local count = 0
	for i, v in pairs(self.operateKeys) do
		count = count + 1
	end

	return count
end

BuildBrick.addFameCommand = function(self, des, deskey)
	if not self.enableGroup or not countedcommands[des] then return end

	if not self.operateKeys then
		self.operateKeys = {}
	end

	if des == 'PartBind' or des == 'PartMove' or des == 'PartReset' or des == 'PartUnbind' or des == 'addBrick' then
		local key = deskey .. '_' .. des
		if des == 'PartMove' then -- 区分移动部位和关节
			key = key .. (self.jointediting and 2 or 1)
		end

		self.operateKeys[key] = true
	else
		local addcount = 0
		for i, g in ipairs(self.rt_selectedGroups) do if g:isValid() then
			-- 一次操作的时候最多算3次
			addcount = addcount + 1
			if addcount > 3 then break end

			local key = nil
			if g:isLeafNode() then
				local b = g:getBlockNode()
				key = 'b' .. tostring(b) .. '_' .. des
			else
				key = 'g' .. g.serialNum .. '_' .. des
			end

			self.operateKeys[key] = true
		end end
	end

	--print('getCommandCountsCount', self:getCommandCountsCount())
end
-----------------------------------------------------------

Global.calcBrickCount = function(data)
	local brickcount = 0
	for i, b in ipairs(data.blocks) do
		if Block.isItemID(b.shape) then
			local bd = Block.getHelperData(b.shape, b.subshape, true)
			brickcount = brickcount + bd.brickcount
		else
			brickcount = brickcount + 1
		end
	end

	if data.subs then
		for _, m in pairs(data.subs) do
			for i, b in ipairs(m.blocks) do
				if not Block.isItemID(b.shape) then
					brickcount = brickcount + 1
				else
					local bd = Block.getHelperData(b.shape, b.subshape, true)
					brickcount = brickcount + bd.brickcount
				end
			end
		end
	end

	return brickcount
end

Global.calcHouseTag = function(data)
	local taglist = {}
	local shapelist = {}
	for i, b in ipairs(data.blocks) do
		if Block.isItemID(b.shape) and not shapelist[b.shape] then
			shapelist[b.shape] = true
			local bd = Global.getObjectByName(b.shape) or Global.GetClientObject(b.shape)
			if bd then
				local stag = Global.getSystemTag(bd)
				if stag then
					taglist[stag] = taglist[stag] or 0
					taglist[stag] = taglist[stag] + 1
				end
			end
		end
	end

	if data.subs then
		for _, m in pairs(data.subs) do
			for i, b in ipairs(m.blocks) do
				if Block.isItemID(b.shape) and not shapelist[b.shape] then
					local bd = Global.getObjectByName(b.shape) or Global.GetClientObject(b.shape)
					shapelist[b.shape] = true
					if bd then
						local stag = Global.getSystemTag(bd)
						if stag then
							taglist[stag] = taglist[stag] or 0
							taglist[stag] = taglist[stag] + 1
						end
					end
				end
			end
		end
	end

	local max = 0
	local tagnum = 0
	local tag
	for i, v in pairs(taglist) do
		if i ~= '$AllTheme' then
			tagnum = tagnum + 1
			max = v
			tag = i
		end
	end

	if tagnum == 1 and max >= 3 then
		local level = math.floor(max / 3)
		return tag .. '@' .. level
	end
end

BuildBrick.onChangePlaneZ = function(self, z)
	self.sen.planeZ = z

	local diffz = z - self.planeZ
	-- print('onChangePlaneZ', z, self.planeZ, diffz)
	local nodes = {}
	self.sen:getNodes(nodes)
	for i, v in ipairs(nodes) do
		if v.block and v.block.isWall or (not v.block and v.isWallNode) then
			v.transform:mulTranslationRight(0, 0, diffz)
		end
	end

	if self.sen.wallActors then
		for i, a in ipairs(self.sen.wallActors) do
			a.transform:mulTranslationRight(0, 0, diffz)
		end
	end

	if self.terrainpfx then
		self.terrainpfx.transform:mulTranslationRight(0, 0, diffz)
	end
end

BuildBrick.setPlaneZ = function(self, z)
	if z >= 0 then
		z = 0
	else
		-- print(z, math.floatRound(z, 0.08, 0))
		z = math.floatRound(z, 0.08, 0)
	end

	if self.planeZ ~= z then
		self:onChangePlaneZ(z)
		self.planeZ = z
	end
end

BuildBrick.goBack = function(self, mode, obj)
	if mode == 'Browser' then
		local stack = Global.entry.stack[#Global.entry.stack]
		if obj then
			stack.param[1] = obj.name
			if stack.param[3] then
				stack.param[3].istemplate = false
			end
			local tag
			if Global.isSceneType(obj.tag) then
				tag = 'scene'
			else
				tag = obj.tag
			end
			Global.entry:goBrowser({obj}, 1, false, tag, 'browser', 'nobuild')
		else
			Notice('Scene is empty!')
		end
	elseif mode == 'Back' then
		local module = self:getModule(0)
		local bindpart = next(module.parts) and true
		if bindpart and self:getParam('bardmode') == 'newbard' then
			Global.entry:popStack()
			Global.DressAvatar:setShowObject(obj)
			Global.entry:goAvatarRoom()
		elseif bindpart and self:getParam('bardmode') == 'editdress' then
			Global.DressAvatar:setShowObject(obj)
			Global.entry:back()
		else
			Global.entry:back()
		end
	elseif mode == 'Dress' then
		if self.enablePart then
			Global.entry:goAvatarRoom()
		end
	end
end
BuildBrick.calcMd5 = function(self)
	local str = Global.saveBlock2String(self:getModule())
	return _sys:md5(str)
end
BuildBrick.uploadObject = function(self, isnew, browsertype, isauto)
	-- 没有local数据，且保存结果没变化，直接返回
	local islocal 
	local object = Global.getObjectByName(self.shapeid)
	if object then
		islocal = Global.ObjectManager:check_isLocal(object)
	end

	local newmd5 = self:calcMd5()

	local module = self:getModule(0)
	local bindpart = next(module.parts) and true

	--print('!!!!uploadObject', browsertype, self.oriMd5, newmd5)
	if self.oriMd5 == newmd5 then
		if isauto then
			print('[Auto]Object stays the same.')
			return
		elseif not islocal then
			print('Object stays the same.')
			return
		end
	end

	self.oriMd5 = newmd5

	-- 需要上传的情况
	local str = Global.saveBlock2String(self:getModule())
	local filename, filemd5 = Global.FileSystem:atom_newData('itemlv', str)
	--local filename, filemd5 = Global.FileSystem:atom_newData('itemlv', str)
	--local tempid = string.sub(filename, 1, -8)

	-- 保存并上传服务器
	local data = {}
	data.name = self.shapeid
	data.state = self.state
	data.openshare = self.openshare
	if isnew then
		data.state = _or(data.state, self.ObjectState.New)
	end

	local df = module.dynamicEffects and module.dynamicEffects[1]
	if Global.hasDynamicEffect(df) then
		data.state = _or(data.state, self.ObjectState.Transitions)
	else
		data.state = _and(data.state, _not(self.ObjectState.Transitions))
	end

	local isdraft = false
	--local bs = self.sen:getAllBlocks()
	-- for _, v in ipairs(bs) do
	-- 	if v.isblocking2 or v.isblocking then
	-- 		isdraft = true
	-- 		break
	-- 	end
	-- end
	if isdraft then
		data.state = _or(data.state, self.ObjectState.Draft)
	else
		data.state = _and(data.state, _not(self.ObjectState.Draft))
	end

	if self:isBuildScene() then
		local scenetype = self:getParam('scenemode')
		data.tag = scenetype or 'scene'
	else
		data.tag = bindpart and 'avatar' or 'object'
	end

	data.desc1 = ''
	data.costs = {}

	local om = Global.ObjectManager
	if object then
		data.id = object.id

		if data.tag == 'avatar' then
			if om:check_isPublished(object) then
				data.state = _or(data.state, self.ObjectState.Published)
			end
		end
	else
		if data.tag == 'avatar' then
			if om:getDisplayAvatarsCount() < 7 then
				data.state = _or(data.state, self.ObjectState.Published)
			end
		end
	end
	data.brickcount = Global.calcBrickCount(self:getModule())

	--if om:isSpecialAvatar(data) then
		--data.type = 'system'
		--data.state = _or(data.state, self.ObjectState.Published)
	--end

	data.datafile = filename
	data.datafile_md5 = filemd5
	Global.ObjectManager:atom_newLocal(data, true)
	local onCaptureSuccess = function(picname, picmd5)
		data.picfile = picname
		data.picfile_md5 = picmd5

		Global.ObjectManager:atom_newLocal(data, isauto)

		-- 需要清理整体cache
		-- Block.clearCaches(data.name)
	end

	print('uploadObject', self.shapeid, islocal, filename, filemd5)
	Global.FileSystem:atom_newPic(filename, {w = 1024, h = 1024, turnToward = not self:isBuildScene(), cameramode = (self:isBuildScene() and 1 or 0)}, onCaptureSuccess)
end
Global.xl_object_upload = function(data)
	Global.FileSystem:new_uploadFiles({data.datafile, data.picfile}, function(success)
		-- print('new_uploadFiles')
		if not success then
			Notice(Global.TEXT.NOTICE_BRICK_UPLOAD_FAILED)
			return
		end
		-- 增加监听回调，回调后注销
		Global.RegisterRemoteCbOnce('onChangeObject', 'SaveObject', function(obj)
			-- print('SaveObject:', obj.name, data.name)
			if obj.name == data.name then

				-- 上传成功后更新本地资源
				Global.FileSystem:downloadData(obj.datafile)
				Global.FileSystem:downloadData(obj.picfile)

				Notice(Global.TEXT.NOTICE_BRICK_SAVED)

				return true
			end
		end)

		RPC('UpdateObject', {Data = data})
	end)
end

-- 保存前退出编辑锁定组状态
BuildBrick.autoSaveBefore = function(self, g)
	if not self.enableGroup or not self:getCurrentGroup() then return end

	local gs = {}
	table.copy(gs, self.groupStack)
	while #self.groupStack > 0 do
		self:popGroup()
	end

	self.gsStack = gs
end

-- 保存后还原编辑锁定组状态
BuildBrick.autoSaveAfter = function(self, g)
	if self.gsStack then
		for i, g in ipairs(self.gsStack) do
			self:pushGroup(g)
		end

		self.gsStack = nil
	end
end

BuildBrick.autoSave = function(self)
	if _sys:getGlobal("AUTOTEST") then return end
	-- 编辑子界面时暂停自动保存
	if self.backClickStack and #self.backClickStack > 0 then return end

	if self.mode == "buildbrick" then
		if self.dfEditing or self.isPlayingDframe then return end
		if self.ui then
			self:autoSaveBefore()
			self:save(nil, nil, true)
			self:autoSaveAfter()
			return true
		end
	elseif self.mode == "buildanima" then
		if self.selectedAnim ~= nil or self.partopt ~= 'exit' then
			return false
		end

		if self.ui then
			self:autoSaveBefore()
			self:save(nil, nil, true)
			self:autoSaveAfter()
			return true
		end
	else
		-- 其他模式不用自动保存
		return true
	end
end
BuildBrick.save = function(self, browsertype, nbs, isauto)
	print('BuildBrick.save', self.shapeid, self:getParam('istemplate'), browsertype)
	if browsertype then
		-- local count = self:getCommandCountsCount()
		-- print('cmd count:', count)
		-- if count >= Global.Fame.block3 then
		-- 	Global.FameTask:doTask('block3')
		-- elseif count >= Global.Fame.block2 then
		-- 	Global.FameTask:doTask('block2')
		-- elseif count >= Global.Fame.block1 then
		-- 	Global.FameTask:doTask('block1')
		-- end
	end
	-- assert(browsertype == 'Back')
	-- 先保存当前场景 再判断
	self:saveSceneToModule(self:getModule(), nbs)

	local o = Global.getObjectByName(self.shapeid)
	local isnew = self:getParam('istemplate')

	-- 如果是空，做删除
	local m = self:getModule()
	if m:isBlank() then
		if isnew then
		elseif o then
			Global.ObjectManager:DeleteObject(o)
		end
	else
		self:uploadObject(isnew, browsertype, isauto)
	end

	if browsertype == 'Dress' or browsertype == 'Back' or browsertype == 'Browser' then
		self:goBack(browsertype, Global.getObjectByName(self.shapeid))
	elseif browsertype == 'godungeon' then

		local obj = Global.getObjectByName(self.shapeid)
	
		local stack = Global.entry.stack[#Global.entry.stack]
		--print('!!!stack.param', value2string(stack.param))
		stack.param[1] = obj.name
		if stack.param[3] then
			stack.param[3].istemplate = false
		end

		local func
		local name = self.shapeid
		func = function()
			Global.entry:goDungeon(obj, nil, {game = 'neverup', test = true, restart_func = func, eid = nil})
		end
		func()
	end

	return self.shapeid, m
end

BuildBrick.saveBlueprint = function(self)
	self:saveSceneToModule(self:getModule())

	local str = Global.saveBlock2String(self:getModule())
	local filename, filemd5 = Global.FileSystem:atom_newData('itemlv', str)

	local datafile = {}
	datafile.name = filename
	datafile.md5 = filemd5

	return datafile
end

BuildBrick.load_block_only = function(self, id)
	-- self:enableEditLv(false)

	self:clearSceneBlock()
	if self.shapeid then
		Block.clearDataCache(self.shapeid)
	end

	local data = Block.loadItemData(id)
	self:setModule(data)
	Block.addDataCache(self.shapeid, self:getModule())
	--self:refreshModuleList()
	-- self:refreshModuleIcon()
end

BuildBrick.setBGM = function(self, music)
	self.bgmusic = music
end

BuildBrick.loadFromObjectData = function(self, id)
	if id and not self:getParam('istemplate') then
		self.shapeid = id
	else
		self.shapeid = 'object_' .. Global.Login:getAid() .. '_' .. _now(0.001)
	end

	self.openshare = false
	local object = Global.getObjectByName(self.shapeid)
	if object then
		if _and(object.state, self.ObjectState.Copied) > 0 then
			self.state = _or(self.state, self.ObjectState.Copied)
		end
		if _and(object.state, self.ObjectState.Draft) > 0 then
			self.state = _or(self.state, self.ObjectState.Draft)
		end
		if _and(object.state, self.ObjectState.NFT) > 0 then
			self.state = _or(self.state, self.ObjectState.NFT)
		end

		if object.openshare then
			self.openshare = object.openshare
		end
	end

	print('loadFromObjectData', id, self.shapeid, Block.getDataCache(self.shapeid), object, object and Global.ObjectManager:check_isLocal(object))

	local data
	-- 有local的，优先用local
	if Block.getDataCache(self.shapeid) then
		data = Block.getDataCache(self.shapeid)
	elseif object then
		if Global.ObjectManager:check_isLocal(object) then
			Block.clearCaches(object.name)
			data = _dofile(object.datafile.name)
		else
			data = Block.loadItemData(self.shapeid)
		end
	else
		-- 物件
		if id then
			data = Block.loadItemData(id)
		end
	end

	return data
end

BuildBrick.isHelperDummy = function(self, b)
	if b.markerdata then return true end
end

BuildBrick.getMarkerType = function(self, b)
	return b.markerdata and b.markerdata.type
end

BuildBrick.load = function(self, id)
	-- self:enableEditLv(false)

	-- clear old info
	self:clearSceneBlock()
	if self.shapeid then
		Block.clearDataCache(self.shapeid)
	end

	local data = self:loadFromObjectData(id)

	-- 把shapeid和self.modules绑定起来
	self:setModule(data)
	Block.addDataCache(self.shapeid, self:getModule())

	if self.enableSwitchPart then
		local gs = data and data.groups or {}
		local switchNames = {}
		for _, g in pairs(gs) do
			if g.switchName and g.switchName ~= '' then
				table.insert(switchNames, g.switchName)
			end
		end

		if self.ui and self.ui.switch then
			self.ui.switch.visible = #switchNames > 0
		end
		self.switchParts = switchNames
		self:refreshSwitchUIList()
	end

	-- 应用动画第一帧的效果
	if self:hasDynamicEffect() then
		self:goFristFrame()
	end

	-- TODO: 废弃firstbuildavatar
	if self:getParam('buildDefaultAvatar') then
		self.shapeid = 'object_firstavatar_' .. Global.Login:getAid() .. '_' .. _now(0.001)
	end
end

BuildBrick.clearbglv = function(self, id)
	local nodes = {}
	self.sen:getNodes(nodes)
	for i = #nodes, 1, -1 do
		local v = nodes[i]
		if v.block and v.block.isWall then
			self.sen:delBlock(v.block)
		elseif not v.block then
		--elseif not v.block and v.pickFlag ~= Global.CONSTPICKFLAG.TERRAIN then
			self.sen:del(v)
		end
	end

	self:onBrickChange()
end

BuildBrick.loadbglv = function(self, id)
	self:clearbglv()

	self.initBlockCount = 0
	local data = id and _dofile(id)
	if data then
		for i, v in ipairs(data.blocks or {}) do
			local b = self.sen:createBlock(v)
			b:setPickFlag(Global.CONSTPICKFLAG.WALL)
			b.isWall = true
			b.isdummyblock = true
			b:independentMaterial()
			self.initBlockCount = self.initBlockCount + 1

			if self.enableAutoPlaneZ and self.planeZ < 0 then
				b.node.transform:mulTranslationRight(0, 0, self.planeZ)
			end
		end
	end
end

BuildBrick.createWalls = function(self)
	local sen = self.sen
	if sen.wallActors then
		for _, a in next, sen.wallActors do
			sen:delActor(a)
		end
	else
		sen.wallActors = {}
	end

	local s = 0.5
	local x = 999999
	local y = 999999

	-- floor
	local a = sen:addActor()
	a.transform:setTranslation(0, 0, -s)
	local shape = a:addShape(_PhysicsShape.Cube)
	shape.size = _Vector3.new(x, y, s)
	shape.queryFlag = Global.CONSTPICKFLAG.TERRAIN
	table.insert(sen.wallActors, a)

	if self.mode == 'buildscene' and self:getParam('scenemode') == 'scene_2D' then
		local a = sen:addActor()
		a.transform:setTranslation(0, s, 0)
		local shape = a:addShape(_PhysicsShape.Cube)
		shape.size = _Vector3.new(x, s, y)
		shape.queryFlag = Global.CONSTPICKFLAG.TERRAIN
		table.insert(sen.wallActors, a)
	end
end

BuildBrick.loadlvdata = function(self, id, only)
	self:clearSceneBlock()
	-- self:enableEditLv(true)

	local data
	if only then
		local n = id and id .. '.lv'
		data = n and _dofile(n)
	else
		data = self:loadFromObjectData(id)
		self:setModule()
		-- 把shapeid和self.modules绑定起来
		Block.addDataCache(self.shapeid, self:getModule())
	end

	if not data then return end

	self.sen:loadLevelData(data)
	self.sen:refreshLevel()
	self.sen:logoutEvents()
	self.sen:loadActionFunctions()

	self:onBrickChange()

	-- self.oriMd5 = self:calcMd5()
end

-- BuildBrick.saveLevel2String = function(self)
-- 	return self.sen:saveLevel2String()
-- end

BuildBrick.savelvdata = function(self, senname)
	if not senname or senname == '' then return end
	local n = senname and senname

	self.sen:saveLevel(n)
end

BuildBrick.getModuleStack = function(self, shapeid)
	if self.moduleStack and #self.moduleStack > 0 then
		return self.moduleStack[#self.moduleStack]
	end
end

BuildBrick.saveModuleToData = function(self)
	local data = {}
	data.shapeid = self.shapeid
	local module = self:newModule()
	self:saveSceneToModule(module)
	data.module = module
	data.command = self:getCurrCommand()
	data.params = self:cloneParams()
	data.md5 = self.oriMd5

	data.mode = self.mode

	Block.addDataCache(data.shapeid, data.module)

	return data
end

BuildBrick.loadModuleData = function(self, data)
	self.shapeid = nil
	self.curmodule = nil
	Block.addDataCache(data.shapeid, data.module)

	-- 二次加载时不重新生成名字
	local istemplate = data.params.istemplate
	data.params.istemplate = false
	self:initData(data.mode, data.shapeid, data.params)
	-- self:showInterlude(data.mode)
	data.params.istemplate = istemplate
	self.oriMd5 = data.md5
end

BuildBrick.pushModuleStack = function(self, b)
	-- ctrl+o 加载的物价临时隐藏直接编辑积木的功能
	-- if self:getParam('istemplate') then return end

	local data = self:saveModuleToData()
	if not self.moduleStack then self.moduleStack = {} end
	table.insert(self.moduleStack, data)

	-- 处理保存后shapeid变换的问题
	data.shapeid1 = b:getShape()
	-- local istemplate = self:getParam('istemplate')
	-- local o = Global.isSystemObject(data.shapeid1)
	-- print('data.shapeid1', data.shapeid1, Global.isNetObject(data.shapeid1))

	-- TODO: 本地物件禁止编辑？
	local params = {}
	if not Global.isNetObject(data.shapeid1) then
		params.istemplate = true
	end

	local blocktype = b:getBlockType()
	local mode = 'buildbrick'
	if Global.isSceneType(blocktype) then
		params.scenemode = blocktype
		mode = 'buildscene'
	end

	self.shapeid = nil
	self.curmodule = nil
	self:initData(mode, data.shapeid1, params)

	local func = function()
		self:cmd_select_begin()
		self:cmd_select_end()
		self:popModuleStack()
	end

	self:addBackClickCb('', func)
	Global.AddHotKeyFunc(_System.KeyESC, function()
		return self.moduleStack and #self.moduleStack > 0
	end, function()
		self:clickBackCb()
	end)

	self:showInterlude(data.mode, true, function()
		self:showInterlude(mode, false)
	end)
end

BuildBrick.popModuleStack = function(self)
	local data = self:getModuleStack()
	if not data then return end
	table.remove(self.moduleStack)

	local curmode = self.mode
	-- 保存当前模型
	local id, m = self:save()
	print('popModuleStack', data.shapeid1, id, data.shapeid)

	-- id 变换后修改module
	if data.trainindex then -- TODO:当前只支持一个火车积木
		-- for i, v in ipairs(data.module.blocks) do
		-- 	if v.markerdata and v.markerdata.trains then
		-- 		local t = v.markerdata.trains[data.trainindex]
		-- 		if t then t.shape = id end
		-- 	end
		-- end
	else
		if data.shapeid1 ~= id then
			for i, v in ipairs(data.module.blocks) do
				if v.shape == data.shapeid1 then
					v.shape = id
				end

				if v.markerdata and v.markerdata.trains then
					for _, t in ipairs(v.markerdata.trains) do
						if t.shape == data.shapeid1 then
							t.shape = id
						end
					end
				end
			end
		end
	end
	Block.addDataCache(id, m)

	self:loadModuleData(data)

	Block.clearDataCache(id)
	Block.clearDataCache(data.shapeid1)

	self:showInterlude(curmode, true, function()
		self:showInterlude(data.mode, false)
	end)
end

BuildBrick.saveToFile = function(self, filename)
	local str = Global.saveBlock2String(self:getModule())
	_File.writeString(filename, str, 'utf-8')
end
-----------------------------------------------------------
BuildBrick.distance = function(self, x1, y1, x2, y2)
	return math.abs(x1 - x2) + math.abs(y1 - y2)
end

BuildBrick.addDragTimer = function(self, x, y, time, func)
	if not self.drag_timer then
		self.drag_timer = {}
		self.drag_timer._timer = _Timer.new()
	end

	local t = self.drag_timer._timer
	self.drag_timer.x = x
	self.drag_timer.y = y
	t:stop()
	t:start('edit_block', time, function()
		func()
		self.drag_timer._timer:stop()
		self.drag_timer = nil
	end)
end

BuildBrick.cancelDragTimer = function(self)
	if self.drag_timer then
		self.drag_timer._timer:stop()
		self.drag_timer = nil
		return true
	end

	return false
end

-- 若有取消操作返回true
BuildBrick.onCancelDragTimer = function(self, movex, movey)
	if not self.drag_timer then return false end
	local d = self:distance(movex, movey, self.drag_timer.x, self.drag_timer.y)
	if d > movedelta then
		self:cancelDragTimer()
		return true
	end

	return false
end

------------------ UI
BuildBrick.ClickSound = {
	{ui = 'view', sound = 'ui_inte05'},
	{ui = 'copybutton', sound = 'build_copy01'},
	{ui = 'module_del', sound = 'ui_delete'},
	{ui = 'graffiti_del', sound = 'ui_delete'},
	{ui = 'lockbutton', sound = 'build_lock01', volume = 0},
}

BuildBrick.isMultiSelecting = function(self)
	return self.multiSelecting or _sys:isKeyDown(_System.KeyCtrl)
end

BuildBrick.showMultiSelectPanel = function(self, show)
	local panel = self.ui.multiSelectPanel
	panel.visible = show
	if self.enableDragSelect then
		panel.all.visible = true
		panel.drag.visible = true
		panel.add.visible = true
	else
		panel.all.visible = false
		panel.drag.visible = false
		panel.add.visible = true
	end

	local uims = self.ui.multiselect
	if self.multiSelecting then
		uims.sel_show.visible = false
		uims.sel_none.visible = false
		uims.sel_drag.visible = false
		uims.sel_multi.visible = true
	elseif self.dragSelecting then
		uims.sel_show.visible = false
		uims.sel_none.visible = false
		uims.sel_drag.visible = true
		uims.sel_multi.visible = false
	else
		uims.sel_show.visible = show
		uims.sel_none.visible = not show
		uims.sel_drag.visible = false
		uims.sel_multi.visible = false
	end
end

BuildBrick.getBlockCount = function(self)
	return self.sen:getBlockCount() - self.initBlockCount
end

BuildBrick.onBrickChange = function(self)
	local n = self:getBlockCount()
	--self.ui.view.disabled = (n == 0 and not self:getParam('buildDefaultAvatar')) or self:getParam('scenemode') == 'scene_music_sub'
	self.ui.view.disabled = (n == 0 and not self:getParam('buildDefaultAvatar'))
	self.ui.showtransition.button.disabled = n == 0

	if self.enablePart and self.partopt ~= 'exit' then
		if not self.userAABBLocked then
			self:getPartsAABB(self.userAABB)
		end
		self.bgAABB:initNull()
	else
		if not self.userAABBLocked then
			local nbs = {}
			self:getAllBlocks(nbs, function(b)
				return not b.isDungeonBg and not b.skipped
			end)
			-- print('userAABBLocked', #nbs, nbs[1] and nbs[1]:getShape(), nbs[2] and nbs[2]:getShape(), nbs[1] and value2string(nbs[1]:getShapeAABB2(true)), nbs[2] and value2string(nbs[2]:getShapeAABB2(true)))
			Block.getAABBs(nbs, self.userAABB)
		end

		if not self.bgAABBLocked then
			local bgnbs = {}
			self:getBlocks(bgnbs, function(b)
				return b.isDungeonBg
			end)
			Block.getAABBs(bgnbs, self.bgAABB)
		end
	end

	--print('onBrickChange', self.enablePart, self.partopt ~= 'exit', value2string(self.userAABB), value2string(self.bgAABB))

	if self.enableAutoPlaneZ then
		self:setPlaneZ(self.boundAABB.min.z)
	end
end

BuildBrick.pushBackStack = function(self, backui, backfunc)
	if not backui or not backfunc then return end
	local laststack = self.stack[#self.stack]
	-- 避免重复加
	if laststack and laststack.ui == backui and laststack.func == backfunc then return end
	table.insert(self.stack, {ui = backui, func = backfunc})
end

BuildBrick.popBackStack = function(self)
	return table.remove(self.stack)
end

BuildBrick.showTopButtons = function(self, mode)
	local uis = {'back', 'goback', 'view', 'preview', 'previewanim', 'showbone', 'switch', 'repairpro', 'showtransition', 'showBfunc'}

	for i, v in ipairs(uis) do
		local u = self.ui[v]
		if u then
			u.visible = false
		end
	end

	if not mode and self.enableGraffiti then
		mode = 'onlyback'
	end

	if not mode and self.backClickStack and #self.backClickStack > 0 then
		mode = self.backClickStack[#self.backClickStack].mode
	end

	if mode == 'onlyback' then
		self.ui.back.visible = true
	elseif mode == 'hideall' then
		-- show nothing
	else
		local showback = self.backClickStack and #self.backClickStack > 0
		self.ui.back.visible = showback
		self.ui.goback.visible = not showback

		if self.enableRepair then
			self.ui.repairpro.visible = true
		elseif self.enableTransition then
			self.ui.showtransition.visible = true
			self.ui.showBfunc.visible = true

			self.ui.view.visible = true
		else
			if self.enablePart then
				self.ui.showbone.visible = not self.disableBindPart
				self.ui.previewanim.visible = true
			end

			self.ui.view.visible = true
			self.ui.showBfunc.visible = true
		end

		if self.switchParts and #self.switchParts > 0 then
			self.ui.switch.visible = true
		end

		self.ui.preview.visible = self:isBuildScene()
	end

	if _sys:getGlobal('PCRelease') then
		self.ui.showBfunc.visible = false
	end

	-- UI排列自动对齐
	local x = self.ui.safearea_right._x
	for i, v in ipairs(uis) do
		local u = self.ui[v]
		if u and u.visible then
			u._x = x - u._width - 30
			x = u._x
		end
	end
end

BuildBrick.initUI = function(self)
	-- 配置按钮声效
	for _, data in ipairs(self.ClickSound) do
		local ui = self.ui[data.ui]
		if ui then
			ui._sound = Global.SoundList[data.sound]
			ui._soundVolumeScale = data.volume or Global.SoundConfigsList[data.sound].volume
		end
	end

	self.ui.btn_undo.click = function()
		self:undo()
	end
	self.ui.btn_redo.click = function()
		self:redo()
	end

	self.ui.goback.backbg.visible = self.enableRepair
	self.ui.goback.savebg.visible = not self.enableRepair
	self.ui.goback.click = function()
		self.ui.goback.disabled = true
		self.ui.view.disabled = true
		self.timer:start('goback', 3000, function()
			if self.ui then
				self.ui.goback.disabled = false
				self.ui.view.disabled = false
			end
			self.timer:stop('goback')
		end)

		if self.enableRepair then
			local bp = self:getParam('blueprint')
			if bp then
				local level = bp.data and bp.data.level or 1
				local maxlevel = #bp
				local datafile = self:saveBlueprint()

				Global.Blueprint:update(bp.name, level, datafile, function()
					Global.entry:back()
				end)
				return
			else
				Global.entry:back()
				return
			end
		end

		self:save('Back')

		--local n = self.sen:getBlockCount() - self.initBlockCount
		-- if self.openshare ~= true and n >= 20 and not self:isBuildScene() then
		-- 	Confirm(Global.TEXT.CONFIRM_OBJECT_SHARE, function()
		-- 		self.openshare = true
		-- 		self:save('Back')
		-- 	end, function()
		-- 		self.openshare = false
		-- 		self:save('Back')
		-- 	end)
		-- else
		-- 	self:save('Back')
		-- end

	end

	-- 引导时不显示预览按钮
	self.ui.victory.visible = false
	self.ui.modulelist.visible = self.showModuleList
	if self:getParam('buildDefaultAvatar') then
		self.ui.view.disabled = true
	end
	self:showTopButtons()

	self.ui.back.click = function()
		if self.enableGraffiti then
			self:cmd_select_begin()
			self:cmd_select_end()
		else
			self:clickBackCb()
		end
	end

	self.ui.view.disabled = true
	self.ui.view.click = function()
		self.ui.goback.disabled = true
		self.ui.view.disabled = true
		self.timer:start('goback', 3000, function()
			if self.ui then
				self.ui.goback.disabled = false
				self.ui.view.disabled = false
			end
			self.timer:stop('goback')
		end)

		self:save('Browser')
	end

	self.ui.preview.click = function()
		self:save('godungeon')
	end

	self.ui.lockbutton.click = function()
		self:cmd_merge_lock()
	end

	self.ui.copybutton.click = function()
		self:cmd_copy()
	end

	self.ui.editmtl.click = function()
		self:showPropList(true)
	end

	self.ui.logicpanel.phyxcull.click = function()
		for i, b in ipairs(self.rt_selectedBlocks) do
			b:setPhyxCulliing(self.ui.logicpanel.phyxcull.selected)
		end
	end

	self.ui.logicpanel.setbgbutton.click = function()
		for i, b in ipairs(self.rt_selectedBlocks) do
			b.isDungeonBg = self.ui.logicpanel.setbgbutton.selected
		end
	end

	self.ui.addasset.click = function()
		if #self.rt_selectedBlocks > 0 then
			local enablepart = self.enablePart
			local istemplate = self:getParam('istemplate')
			local shapeid = self.shapeid
			self.enablePart = false
			self:setParam('istemplate', true)
			self.shapeid = 'object_' .. Global.Login:getAid() .. '_' .. _now(0.001)

			self:save(nil, self.rt_selectedBlocks)

			self.enablePart = enablepart
			self:setParam('istemplate', istemplate)
			self.shapeid = shapeid
		end
	end

	self.ui.mirror.click = function()
		self:cmd_mat_update_begin(nil, 'mirror')
		local type = Global.dir2AxisType(Global.DIRECTION.RIGHT, Global.AXISTYPE.Z)

		if type == Global.AXISTYPE.X or type == Global.AXISTYPE.NX then
			self.rt_transform:mulScalingLeft(-1, 1, 1)
		else
			self.rt_transform:mulScalingLeft(1, -1, 1)
		end

		self:cmd_mat_update_end()

		self:atom_group_knot_dirty()

		-- TODO: updatespace
	end

	Global.graffitiBag:init()
	self.ui.addpaint.disabled = #Global.graffitiBag.graffitilist == 0
	self.ui.addpaint.click = function()
		local b = self.rt_selectedBlocks[1]
		if not b then return end

		local paintmeshs = b:getPaintMeshs()
		if #paintmeshs > 0 then
			self.enableGraffiti = true
			self:onSelectGroup(self.rt_selectedGroups)
		else
			Global.graffitiBag:show(true)
		end
	end

	self.ui.rotatecamera.visible = _sys:isMobile()
	self.ui.rotatecamera.onMouseDown = function(args)
		self.ui.rotatecamera.pushed = true
		self.ui.rotatecamera.visible = false
		self:camera_down(args.fid, args.mouse.x, args.mouse.y)
	end

	self.ui.rotatecamera.onMouseMove = function(args)
		self:camera_move(args.mouse.x, args.mouse.y, args.fid)
	end

	self.ui.rotatecamera.onMouseUp = function()
		self.ui.rotatecamera.visible = true
		self.ui.rotatecamera.pushed = false
		self:camera_up()
	end

	self.ui.graffiti_del.click = function()
		if self.enableGraffiti then
			local b = self.rt_selectedBlocks[1]
			if not b then return end
			--b:clearPaintInfo()
			self:atom_paint_del(b)
			self:cmd_select_begin()
			self:cmd_select_end()
		end
	end

	self.ui.module_del.click = function()
		local showconfirm = self:atom_block_selectedNum() >= 8 or self:isSelectedMusicRunway() or self:isSelectedMusicPole()
		if showconfirm then
			Confirm(Global.TEXT.CONFIRM_BRICK_DELETE, function()
				_Material.clearflowStack()
				self:cmd_delBrick()
			end, function()
			end)
		else
			_Material.clearflowStack()
			self:cmd_delBrick()
		end
	end

	self.ui.multiselect.click = function()
		--do return end
		if self.multiSelecting then
			self.multiSelecting = false
			self:showMultiSelectPanel(false)
		elseif self.dragSelecting then
			self.dragSelecting = false
			self:showMultiSelectPanel(false)
		else
			local showpanel = not self.ui.multiSelectPanel.visible
			self:showMultiSelectPanel(showpanel)
		end
	end

	self.ui.multiSelectPanel.all.click = function()
		if self.ui.disablebg.visible or not self.ui.multiSelectPanel.all.visible then return end

		print('MS all')
		self:atom_group_merge(self.rt_selectedGroups)

		self:showMultiSelectPanel(false)
		-- 当block没有group时创建block
		local bs = {}
		self:getBlocks(bs, function(b)
			return self:checkBlockPickable(b)
		end)
		local gs = {}
		for i, b in ipairs(bs) do
			local root = b:getBlockGroup('root')
			gs[root] = true
		end
		self:atom_group_select_batch(gs)
	end

	self.ui.multiSelectPanel.drag.click = function()
		print('drag selecting')
		self.dragSelecting = true
		self:showMultiSelectPanel(false)
	end

	self.ui.multiSelectPanel.add.click = function()
		print('multi selecting')
		self.multiSelecting = true
		self:showMultiSelectPanel(false)
	end

	self.planemove = self.ui.selectmode.selected
	self.ui.selectmode.visible = false
	self.ui.selectmode.click = function()
		self.planemove = self.ui.selectmode.selected
	end

	self.ui.showtransition.button.click = function()
		self:showDfs(self.ui.showtransition.button.selected)
	end
	self:updateTransitionText()

	self.ui.showBfunc.click = function()
		print('block logic func', self.ui.showBfunc.selected)

		self.logicEditing = self.ui.showBfunc.selected
		-- Global.BlockChipUI:refreshMainList(self.chips_s)
		-- Global.BlockChipUI:selectMainList(1)
	end

	self.ui.logicpanel.btn_chips.click = function()
		local bs = self.rt_selectedBlocks
		if not bs[1] then
			Global.BlockChipUI:show('main', self.chips_s.main)
		else
			local css
			for i, b in ipairs(bs) do
				if not css then css = b.chips_s end
			end
			if not css then css = {} end
			for i, b in ipairs(bs) do
				b.chips_s = css
			end
			Global.BlockChipUI:show('main', css)
		end
	end

	self.ui.logicpanel.btn_logic_group.click = function()
		-- todo show self.ui.logic_group
		if not self.rt_selectedBlocks[1] then return end
		self:showLogicGroupList(true)
	end

	self.switchParts = {}
	self:refreshSwitchUIList()

	if self.enablePart then
		-- 动画列表
		--local anims = {'idle', 'run', 'attack', 'dance'}
		-- local anims = _G.cfg_skls.human.order
		local anims = Global.Animas
		local animitems = {}
		local animlist = self.ui.animlist
		animlist.alphaRegion = 0x00140014

		animlist.onRenderItem = function(index, item)
			if index <= #anims then
				local icon = Global.AnimationCfg[anims[index]].icon
				item.pic1._icon = 'img://' .. icon
				item.click = function()
					self:playAnimIndex(index, self.selectedAnim ~= index)
				end
				table.insert(animitems, item)
			end
		end

		animlist.itemNum = #anims
		self.anims = anims
		self.animitems = animitems

		--TODO: 'human'
		-- 引导时不显示骨骼按钮
		self.ui.showbone.click = function()
			local show = self.ui.showbone.selected
			if not show and self.ui.bricklist then
				self.ui.bricklist.visible = #self.freqs > 0 and not self:isBuildScene()
			else
				self.ui.bricklist.visible = false
			end
			self.ui.modulelist._visible = not show and self.showModuleList

			self.ui.switch.disabled = show
			self.ui.switch.selected = false
			self.ui.switchlist.visible = false

			self:showPart('human', show)
			self:syncMultselectvisible()
		end

		self.ui.animuis.bindpart.click = function()
			-- if not self.showSkl then return end
			-- self:cmd_showmovepart()
			self:editPart('bind')
			self.ui.animuis.bindpart.selected = true
		end

		self.ui.animuis.movepart.click = function()
			-- self:editPart('movebone')
			self.ui.animuis.movepart.selected = true

			if self.ui.animuis.movejoint.selected then
				self:editPart('movejoint')
			else
				self:editPart('movebone')
			end
		end

		self.ui.animuis.movejoint.click = function()
			if self.ui.animuis.movejoint.selected then
				self:editPart('movejoint')
			else
				self:editPart('movebone')
			end
			--self.ui.animuis.movejoint.selected = true
		end

		self.ui.animuis.resetmove.click = function()
			if self.rt_selectedPart then
				self:cmd_part_reset(self.rt_selectedPart)
			end
		end

		local ui = self.ui
		self.ui.previewanim.click = function()
			if self.partopt ~= 'preview' then
				self.oldpartopt = self.partopt
				self:cmd_select_begin()
				self:cmd_select_end()
				self:editPart('preview')
				self:cmd_changeAnima()
			else
				self:editPart(self.oldpartopt)
			end

			ui.switch.disabled = ui.previewanim.selected
			ui.switch.selected = false
			ui.switchlist.visible = false
			self:syncMultselectvisible()
		end
	end

	local uiscale = self.ui.graffitiscale
	self:initScaleHint()

	local function changeScale(self, scale1, scale2)
		uiscale.text.text = scale2 * 100 .. '%'
		uiscale.inputtext.text = scale2 * 100
		self.curscale = scale2

		local b = self.rt_selectedBlocks[1]
		if self:isBuildScene() then
			local ab1 = Container:get(_AxisAlignedBox)
			local ab2 = Container:get(_AxisAlignedBox)
			b:getShapeAABB(ab1)

			self:cmd_mat_update_begin(nil, 'scale')
			local scale = scale2 / scale1
			self.rt_transform:mulScalingLeft(scale, scale, scale)
			b:getShapeAABB(ab2)
			self.rt_transform:mulTranslationRight(0, 0, ab1.min.z - ab2.min.z)
			--print('zoomout', ab1.min.z, ab2.min.z)
			self:cmd_mat_update_end()

			Container:returnBack(ab1, ab2)
		else
			-- b:scalePaint(scale2)
			self:atom_paint_scale(b, scale2)
		end
	end

	uiscale.zoomout.click = function()
		if next(self.rt_selectedBlocks) and self.scaleindex ~= 1 then
			local scale1 = self:getScaleByIndex(self.scaleindex)
			self.scaleindex = self.scaleindex - 1
			local scale2 = self:getScaleByIndex(self.scaleindex)
			changeScale(self, scale1, scale2)
		end
	end
	uiscale.zoomin.click = function()
		if next(self.rt_selectedBlocks) and self.scaleindex < self.maxscaleIndex then
			local scale1 = self:getScaleByIndex(self.scaleindex)
			self.scaleindex = self.scaleindex + 1
			local scale2 = self:getScaleByIndex(self.scaleindex)
			changeScale(self, scale1, scale2)
		end
	end

	uiscale.inputtext.onKeyDown = function(key)
		if key == _System.KeyReturn then
			local scale1 = self.curscale

			local scale2 = tonumber(uiscale.inputtext.text)
			if not scale2 then return end
			scale2 = math.clamp(scale2, 25, 100000) / 100

			if not scale2 or math.floatEqual(scale2, scale1) then return end
			self.scaleindex = self:findScaleIndex(scale2)
			changeScale(self, scale1, scale2)
		end
	end
end

BuildBrick.playAnimIndex = function(self, index, play)
	if self.selectedAnim then
		self.selectedAnim = nil
		self:stopAnim()
	end

	if index and play then
		self.selectedAnim = index
		local anim = self.anims[index]
		self:applyAnim(anim)
	end

	for i, u in ipairs(self.animitems) do
		u.selected = self.selectedAnim == i
	end
end

-- BuildBrick.checkBlockArea = function(self, x, y)
-- 	local uiadd = self.uiaddmodule
-- 	uiadd:setPageIndex('button', 0)
-- 	if self:inAddArea(x, y) then
-- 		uiadd:setPageIndex('button', 1)
-- 	end
-- end

BuildBrick.refreshSwitchUIList = function(self)
	-- local switchParts = {'beard_beard', 'beard_glasses', 'beard_hat'}
	if not self.enableSwitchPart or not self.switchParts or #self.switchParts == 0 then
		self.ui.switchlist.visible = false
		self.ui.switch.visible = false
		return
	end

	local preImgs = {}
	for k, name in pairs(self.switchParts) do
		local switchlist = _G.cfg_switchpart[name]
		if switchlist then
			if not preImgs[k] then preImgs[k] = {} end
			for _, n in pairs(switchlist) do
				table.insert(preImgs[k], 'img://' .. n .. '-display.bmp')
			end
		end
	end

	local switchNum = #self.switchParts
	local switchlist = self.ui.switchlist
	local switchItems = {}
	switchlist.visible = false
	switchlist.preImgIndex = 1
	switchlist.onRenderItem = function(index, item)
		if index <= switchNum then
			item.isselected = index == 1
			item.switchIndex = switchlist.preImgIndex
			item.img.pic._icon = preImgs[index][item.switchIndex]
			item.next_l.visible = item.isselected
			item.next_r.visible = item.isselected

			table.insert(switchItems, item)
		end
	end

	switchlist.itemNum = switchNum

	local resetUIState = function()
		for _, item in pairs(switchItems) do
			item.isselected = false
			item.next_l.visible = false
			item.next_r.visible = false
			item.img.selected = false
		end
	end
	for index, item in pairs(switchItems) do
		item.img.click = function()
			if item.isselected == false then
				resetUIState()
			else
				item.selectedindex = item.switchIndex
				local resname = _G.cfg_switchpart[self.switchParts[index]][item.switchIndex]
				self:switchAssets({name = resname, switchName = self.switchParts[index]})
			end

			item.isselected = true
			item.img.selected = true
			item.next_l.visible = item.isselected
			item.next_r.visible = item.isselected
		end

		local maxcount = #preImgs[index]
		item.next_r.click = function()
			if item.switchIndex == maxcount then item.switchIndex = 1 else item.switchIndex = item.switchIndex + 1 end
			item.img.pic._icon = preImgs[index][item.switchIndex]
			item.img:click()
		end

		item.next_l.click = function()
			if item.switchIndex == 1 then item.switchIndex = maxcount else item.switchIndex = item.switchIndex - 1 end
			item.img.pic._icon = preImgs[index][item.switchIndex]
			item.img:click()
		end
	end

	self.ui.switch.click = function()
		self:cmd_select_begin()
		self:cmd_select_end()
		self.ui.switchlist.visible = not self.ui.switchlist.visible
		if self.selectedAnim then
			self.selectedAnim = nil
			self:stopAnim()
		end
	end
end

BuildBrick.refreshFrequent = function(self)
	local list = self.ui.bricklist.brick_frequent

	-- 数量满足时禁用按钮
	local enablefilters = nil
	if self.enableRepair then
		enablefilters = self:getRepairShapeFilter()
	end

	list.onRenderItem = function(index, item)
		local data = self.freqs[index]
		-- item.pic._icon = data and 'img://' .. tostring(data.shape) .. '-display.bmp' or ''
		local rename = data and tostring(data.shape) .. '-display.bmp' or ''
		local img = _Image.new(rename, false, false)
		if data then
			local w, h = item.picload._width, item.picload._height
			local ui = item.picload:loadMovie(img)
			ui._width = w
			ui._height = h
		end

		item.disabled = enablefilters and not enablefilters[data.shape]
		item.click = function()
			if data then
				self:cmd_addBrick(data)
			end
		end
	end
	list.itemNum = #self.freqs
	list.scrollable = false
	self.ui.bricklist.visible = #self.freqs > 0 and not self:isBuildScene()

	list._height = #self.freqs * 155
end

BuildBrick.addToFrequent = function(self, oridata)
	local data = table.clone(oridata)
	data.space = nil

	local shapeid = data.shape
	assert(shapeid)

	local index = -1
	for i, v in ipairs(self.freqs) do
		if v.shape == shapeid and v.subshape == data.subshape then
			index = i
			break
		end
	end

	if index then table.remove(self.freqs, index) end
	table.insert(self.freqs, 1, data)
	if #self.freqs > 5 then table.remove(self.freqs, #self.freqs) end

	self:refreshFrequent()
end

BuildBrick.showFrequent = function(self, show)
	self.ui.bricklist.visible = show and #self.freqs > 0 and self.ui.showbone.selected == false and not self:isBuildScene()
end

--BuildBrick.setClickbackCb = function(self, callback, showTopButtons)
BuildBrick.addBackClickCb = function(self, topbuttonmode, callback)

	if not self.backClickStack then
		self.backClickStack = {}
	end

	table.insert(self.backClickStack, {cb = callback, mode = topbuttonmode})
	self:showTopButtons()

	-- if callback then
	-- 	self.ui.back.visible = true
	-- end
	-- self.clickback_Cb = callback
	-- if showTopButtons then
	-- 	self:showTopButtons()
	-- else
	-- 	self.ui.back.visible = true
	-- end
end

BuildBrick.clickBackCb = function(self)
	if not self.backClickStack or #self.backClickStack == 0 then return end

	local data = self.backClickStack[#self.backClickStack]
	table.remove(self.backClickStack)
	if data.cb then data.cb() end
	self:showTopButtons()
end

BuildBrick.showDisableBg = function(self, show, clickcb)
	self.ui.disablebg.visible = show

	if show then
		self.ui.disablebg.click = function()
			if clickcb then clickcb() end
		end
	end
end

BuildBrick.hideNormalUIs = function(self, hide, callback)
	self.hideNormalUI = hide

	if self.enableRepair then
		self:onSelectRepairGroup(self.rt_selectedBlocks)
	else
		self:onSelectGroup(self.rt_selectedGroups)
	end

	if hide then self:showTopButtons('hideall') else self:showTopButtons() end
	if hide then self:showFrequent(false) end

	self.ui.modulelist.visible = not hide and self.showModuleList
	if _sys:isMobile() then
		self.ui.rotatecamera.visible = not hide
	end

	self:ui_flush_undo()

	if callback then callback() end
end

BuildBrick.showPropList = function(self, show)
	self.showProp = show
	self:hideNormalUIs(self.showProp)
	-- if show then
	-- 	self.ui.dfs.visible = false
	-- end

	if self.mode == 'buildrepair' or self.mode == 'repair' then
		return
	end

	if show == false then
		if self.uiprop then
			self.uiprop._visible = false
		end
		return
	end

	local blocks = self.rt_selectedBlocks
	local block = blocks[1]
	-- local quality = block:getAssumeQuality() or block:getQuality()

	if self.uiprop == nil then
		self.uiprop = Global.UI:new('BuildBrickMaterial.bytes')

		local sounds = {
			{ui = 'record', sound = 'ui_click17'},
			{ui = 'samemtl', sound = 'ui_click19'},
			{ui = 'sameshape', sound = 'ui_click19'},
		}

		for _, data in ipairs(sounds) do
			local ui = self.uiprop[data.ui]
			if ui then
				ui._sound = Global.SoundList[data.sound]
				ui._soundVolumeScale = data.volume or Global.SoundConfigsList[data.sound].volume
			end
		end
	end
	Global.UI:slidein({self.uiprop}, nil, 'y')
	self.uiprop._visible = true
	local uiprop = self.uiprop
	local uimtls = uiprop.mtlplane.materials.materials
	local uicolors = uiprop.mtlplane.colors
	local uihsl = uiprop.mtlplane.hsl
	local uirslider = uiprop.mtlplane.rslider
	local uiback = uiprop.back
	uiprop.visible = true

	uimtls.alphaRegion = 0x14001400
	uicolors.alphaRegion = 0x14001400

	if Global.Achievement:check('introducebuildmaterial') == false then
		Global.Introduce:show('buildmaterial')
		Global.Achievement:ask('introducebuildmaterial')
	end

	-- 缓存框选状态
	self.olddragSelecting = self.dragSelecting
	self.dragSelecting = false

	local function getCommonMaterial()
		local mtl = self:getBlockValue_ByFrame(nil, block, 'material')
		if not Global.MtlSetting[mtl.material] then -- 容错处理，修改错误材质
			mtl.material = 1
		end
		for i, v in ipairs(blocks) do
			local bmtl = self:getBlockValue_ByFrame(nil, v, 'material')
			if not isSameMtl(mtl, bmtl) then
				return nil
			end
		end
		return mtl
	end

	local function updateMeshMaterial(data)
		data.meshmaterial = Block.getMaterial(data.material, data.color, data.roughness, data.mtlmode)
	end

	local function initCurMaterial()
		self.curmaterial = getCommonMaterial()
		if self.curmaterial then
			updateMeshMaterial(self.curmaterial)
		end
	end

	initCurMaterial()

	local function getCurrentMaterial()
		return self.curmaterial
	end

	local function updateCurrentMaterialID(mtl)
		local sm = getCurrentMaterial()
		if sm then
			sm.material = mtl
			updateMeshMaterial(sm)
		end
	end

	local function updateCurrentMaterialMode(mode)
		local sm = getCurrentMaterial()
		if sm then
			sm.mtlmode = mode
			updateMeshMaterial(sm)
		end
	end

	local function updateCurrentMaterialColor(color)
		local sm = getCurrentMaterial()
		if sm then
			sm.color = color
			updateMeshMaterial(sm)
		end
	end

	local function updateCurrentMaterialRoughness(roughness)
		local sm = getCurrentMaterial()
		if sm then
			sm.roughness = roughness
			updateMeshMaterial(sm)
		end
	end

	local function initRoughness()
		uirslider.deltaNum = self.disableDelta and 0 or 8
		local sm = getCurrentMaterial()
		if sm == nil then
			uirslider.maxValue = 1
			uirslider.value = 1
			uirslider.onChanged = function() end
			return
		end
		local roughnessmax = Global.MtlSetting[sm.material].roughnessmax
		local roughnessmin = Global.MtlSetting[sm.material].roughnessmin
		uirslider.maxValue = roughnessmax - roughnessmin
		uirslider.currentValue = sm.roughness - roughnessmin
		uirslider.onChanged = function()
			local value = uirslider.currentValue + roughnessmin
			updateCurrentMaterialRoughness(value)
		end

		uirslider.onMouseUp = function()
			self:cmd_setMaterial('roughness', uirslider.currentValue + roughnessmin)
		end
	end

	local function initColorList()
		local sm = getCurrentMaterial()
		local colors = sm and Global.MtlSetting[sm.material].colors or self.BrickColors
		local ucolors = sm and Global.MtlSetting[sm.material].ucolors or {}
		colors = #colors == 0 and self.BrickColors or colors
		self.currColorIndex = nil

		if not self.currColor then
			self.currColor = _Color.new()
		end

		local currH, currS, currL = 0, 0, 0
		local hdb, sdb, ldb
		local updatSliderBackground = function()
			local tempColor = _Color.new()
			local hslider = uihsl.hue
			if hdb == nil then
				hdb = _DrawBoard.new(hslider.bg._width, hslider.bg._height)
				hslider.bg:loadMovie(hdb)
				_rd:useDrawBoard(hdb, _Color.Null)
				local dw = 1 / (hslider.bg._height - 1)
				for i = 0, hslider.bg._height - 1 do
					tempColor:setHSL(dw * i, 1, 0.5)
					_rd:fillRect(0, i, hslider.bg._width, i + 1, tempColor:toInt())
				end
				_rd:resetDrawBoard()
			end

			local sslider = uihsl.saturation
			if sdb == nil then
				sdb = _DrawBoard.new(sslider.bg._width, sslider.bg._height)
				sslider.bg:loadMovie(sdb)
			end
			_rd:useDrawBoard(sdb, _Color.Null)
			local dw = 1 / (sslider.bg._height - 1)
			for i = 0, sslider.bg._height - 1 do
				tempColor:setHSL(currH, dw * i, 0.5)
				_rd:fillRect(0, i, sslider.bg._width, i + 1, tempColor:toInt())
			end
			_rd:resetDrawBoard()

			local lslider = uihsl.lightness
			if ldb == nil then
				ldb = _DrawBoard.new(lslider.bg._width, lslider.bg._height)
				lslider.bg:loadMovie(ldb)
			end
			_rd:useDrawBoard(ldb, _Color.Null)
			local dw = 1 / (lslider.bg._height - 1)
			for i = 0, lslider.bg._height - 1 do
				tempColor:setHSL(currH, 1, dw * i)
				_rd:fillRect(0, i, lslider.bg._width, i + 1, tempColor:toInt())
			end
			_rd:resetDrawBoard()
		end

		local updateSliderValues = function(c)
			local t
			if type(c) == 'number' then
				local color = _Color.new(c)
				t = color:getHSL()
			else
				t = c:getHSL()
			end

			currH, currS, currL = t.h, t.s, t.l
			uihsl.hue:setValue(t.h)
			uihsl.saturation:setValue(t.s)
			uihsl.lightness:setValue(t.l)
		end

		local function initSlider(slider, desc, minvalue, maxvalue)
			--slider.desc.text = desc
			slider.minValue0 = minvalue
			slider.maxValue = maxvalue - minvalue
			slider.deltaNum = self.disableDelta and 0 or 20

			slider.setValue = function(self, value)
				slider.currentValue = value - slider.minValue0
				--slider.tf.text = string.format('%.3f', value)
			end

			slider.onChanged = function()
				local value = slider.currentValue + slider.minValue0
				--slider.tf.text = string.format('%.3f', value)

				if slider == uihsl.hue then
					currH = value
				elseif slider == uihsl.saturation then
					currS = value
				elseif slider == uihsl.lightness then
					currL = value
				end

				self.currColor:setHSL(currH, currS, currL)
				updatSliderBackground()

				local colori = self.currColor:toInt()
				updateCurrentMaterialColor(colori)

				if self.currColorIndex then
					colors[self.currColorIndex] = colori
					ucolors[self.currColorIndex] = colori
					uicolors:updateItem(self.currColorIndex)
				end
			end

			slider.onMouseUp = function()
				self:cmd_setMaterial('color', self.currColor:toInt())
			end
		end

		uicolors.onRenderItem = function(index, item)
			item.pic.color = ucolors[index] or colors[index]
			item.pic2.color = ucolors[index] or colors[index]
			item._sound = Global.SoundList['build_pick02']
			item._soundVolumeScale = Global.SoundConfigsList['build_pick02'].volume
			item.click = function()
				--print('选择颜色:', index, colors[index])
				assert(#blocks > 0, 'error: invalid blocks')
				self.currColorIndex = index
				updateCurrentMaterialColor(colors[index])

				self:cmd_setMaterial('color', colors[index])

				updateCurrentMaterialColor(colors[index])
				updateSliderValues(colors[index])
				updatSliderBackground()
			end
		end

		initSlider(uihsl.hue, '色相', 0, 1)
		initSlider(uihsl.saturation, '饱和度', 0, 1)
		initSlider(uihsl.lightness, '亮度', 0, 1)
		updateSliderValues(block:getColor())
		updatSliderBackground()
		uicolors.itemNum = #colors
		if sm and #colors ~= 0 then
			local index = nil
			for i, c in ipairs(colors) do
				if c == sm.color then
					index = i
					break
				end
			end

			if index then
				uicolors:addSelection(index, true)
			end
		end
	end

	local function initMtlList()
		--local mtldescs = {'塑料', '金属', '大理石', '木板', '泥土', '砖块', '植物', '自发光'}
		local datas = {}
		for q = 1, #Global.BrickQuality do
			for i, v in ipairs(Global.BrickQuality[q].mtls) do
				if Global.CheckLimit(v) then
					table.insert(datas, {material = v.material, mtlmode = v.mtlmode, roughness = 1, color = v.color, m_icon = v.m_icon, m_icon1 = v.m_icon1, name = v.desc})
				end
			end
		end

		self.standardmaterials = datas
		uimtls.onRenderItem = function(index, item)
			local data = datas[index]
			updateMeshMaterial(data)
			item.bg1._icon = data.m_icon
			item.bg2._icon = data.m_icon1
			item.title.text = data.name
			item._sound = Global.SoundList['build_pick02']
			item._soundVolumeScale = 1.0
			item.click = function()
				updateCurrentMaterialID(data.material)
				updateCurrentMaterialMode(data.mtlmode)
				updateCurrentMaterialColor(data.color)
				initColorList()
				initRoughness()

				assert(#blocks > 0, 'error: invalid blocks')
				self:cmd_setMaterial('data', data, data.nbs)
			end
		end

		uimtls.itemNum = #datas

		local sm = getCurrentMaterial()
		if sm and #datas ~= 0 then
			local index = nil
			for i, mtl in ipairs(datas) do
				if mtl.material == sm.material then
					index = i
					break
				end
			end

			if index then
				uimtls:addSelection(index, true)
			end
		end
	end

	initMtlList()
	initColorList()
	initRoughness()

	uiprop.bg.click = function()
		Global.UI:slideout({self.uiprop}, nil, 'y')
		self.timer:start('hideui', 150, function()
			self.dragSelecting = self.olddragSelecting

			uiprop.visible = false
			self:cmd_select_begin()
			self:cmd_select_end()
			self:showPropList(false)
			-- self.ui.dfs.visible = self.dfEditing
			self.timer:stop('hideui')

		end)
	end

	Global.AddHotKeyFunc(_System.KeyESC, function()
		return Block.isBuildMode() and self.showProp
	end, function()
		uiprop.bg.click()
	end)

	self:pushBackStack(uiback, uiprop.bg.click)
	local showMaterialsMore = function(show)
		uirslider.visible = show
		uiprop.mtlplane.bg_l.visible = show
		uiprop.mtlplane.materials.visible = not show
		uiprop.mtlplane.materials_more.selected = show
	end

	uiprop.mtlplane.materials_more.click = function()
		showMaterialsMore(uiprop.mtlplane.materials_more.selected)
	end

	local showColorsMore = function(show)
		uihsl.visible = show
		uiprop.mtlplane.bg_r.visible = show
		uicolors.visible = not show
		uiprop.mtlplane.colors_more.selected = show
	end

	uiprop.mtlplane.colors_more.click = function()
		showColorsMore(uiprop.mtlplane.colors_more.selected)
	end

	showMaterialsMore(false)
	showColorsMore(false)

	local function ondown_recordmtl(self, x, y)
		local b, pos = self:pickBlock(x, y)
		if b then
			local mtl = self:getBlockValue_ByFrame(nil, b, 'material')
			updateCurrentMaterialID(mtl.material)
			updateCurrentMaterialMode(mtl.mtlmode)
			updateCurrentMaterialColor(mtl.color)

			assert(#blocks > 0, 'error: invalid blocks')
			self:cmd_setMaterial('data', mtl, mtl.nbs)

			initColorList()
			initRoughness()

			Global.Sound:play('ui_click03')
		end
	end
	self.propRecord = false
	local resetRecord = function()
		uiprop.mtlplane.visible = true
		uiprop.bg.visible = true
		self.ui.visible = true
		uiprop.record.selected = false
		self.ondownfunc = self.lastondownfunc
		self.onmovefunc = self.lastonmovefunc
		self.onupfunc = self.lastonupfunc
	end
	uiprop.record.click = function()
		uiprop.mtlplane.visible = not uiprop.mtlplane.visible
		uiprop.bg.visible = not uiprop.bg.visible
		self.ui.visible = self.propRecord
		self.propRecord = not self.ui.visible
		if self.propRecord == true then
			self.lastondownfunc = self.ondownfunc
			self.lastonmovefunc = self.onmovefunc
			self.lastonupfunc = self.onupfunc
			self.ondownfunc = ondown_recordmtl
			self.onmovefunc = nil
			self.onupfunc = nil
			self:pushBackStack(uiback, resetRecord)
		else
			self.ondownfunc = self.lastondownfunc
			self.onmovefunc = self.lastonmovefunc
			self.onupfunc = self.lastonupfunc
			self:popBackStack()
		end
	end

	local selected_bs = {}
	table.fappendArray(selected_bs, self.rt_selectedBlocks)
	local selected_hash = {}
	for i, b in ipairs(self.rt_selectedBlocks) do
		selected_hash[b] = true
	end

	local mtl_exblocks = {}
	local shape_exblocks = {}
	local initSameMtlBtn = function()
		local mtls = {}
		for i, b in ipairs(self.rt_selectedBlocks) do
			local mtl = self:getBlockValue_ByFrame(nil, b, 'material')
			local has = false
			for i, m in ipairs(mtls) do
				if isSameMtl(m, mtl) then
					has = true
					break
				end
			end

			if not has then
				table.insert(mtls, mtl)
			end
		end

		local bs = {}
		self:getAllBlocks(bs, function(b)
			if selected_hash[b] then return false end

			local mtl = self:getBlockValue_ByFrame(nil, b, 'material')
			for i, m in ipairs(mtls) do
				if isSameMtl(m, mtl) then
					return true
				end
			end
			return false
		end)

		mtl_exblocks = bs
		uiprop.samemtl.selected = false
		uiprop.samemtl.disabled = #bs == 0
	end

	local initSameShapeBtn = function()
		local shapes = {}
		for i, b in ipairs(self.rt_selectedBlocks) do
			local shape = b:getShape()
			shapes[shape] = true
		end

		local bs = {}
		self:getAllBlocks(bs, function(b)
			if selected_hash[b] then return false end
			local shape = b:getShape()
			return shapes[shape]
		end)

		shape_exblocks = bs
		uiprop.sameshape.selected = false
		uiprop.sameshape.disabled = #bs == 0
	end

	initSameMtlBtn()
	initSameShapeBtn()

	local function sel_mtl_shape()
		local bs = {}
		table.fappendArray(bs, selected_bs)
		if uiprop.samemtl.selected and uiprop.sameshape.selected then
			-- 需要去重
			local hash = {}
			for i, b in ipairs(mtl_exblocks) do
				hash[b] = true
			end
			for i, b in ipairs(shape_exblocks) do
				hash[b] = true
			end
			for b in pairs(hash) do
				table.insert(bs, b)
			end
		elseif uiprop.samemtl.selected then
			table.fappendArray(bs, mtl_exblocks)
		elseif uiprop.sameshape.selected then
			table.fappendArray(bs, shape_exblocks)
		end

		self.enableBrickMat = false
		self:atom_block_select(bs)
	end
	uiprop.samemtl.click = function()
		sel_mtl_shape()
	end

	uiprop.sameshape.click = function()
		sel_mtl_shape()
	end

	uiback.click = function()
		if #self.stack == 0 then return end
		local stack = self.stack[#self.stack]
		if stack then
			local ui = stack.ui
			local func = stack.func
			if ui.visible then
				func()
			end
		end

		self:popBackStack()
	end
end

BuildBrick.hideBricksUI = function(self)
	if self.ui then self.ui.visible = true end
	self:showPropList(false)
	Global.brickui:hide()
	Global.SwitchControl:set_render_on()
end

BuildBrick.showBricksUI = function(self, params)
	-- 编辑音乐关卡时只显示mywork
	if self:isMusicMode('music_bg') then
		if not params then
			params = {}
			params.hidelabelList = true
			params.objectkinds = {mine = true}
			params.noshowavatar = true
		end
		params.forceupdate = true
	elseif self:isMusicMode('music_train') then
		if not params then
			params = {}
			-- params.hidelabelList = true
			params.objectkinds = {all = true, instrument = true, barrier = true, decoration = true}
			params.noshowavatar = true
		end
		params.forceupdate = true
	elseif self.enableRepair then
		if not params then params = {} end
		params.forceupdate = true
	end

	Global.brickui:show(self.enableRepair and 'repair' or
		(self.mode == 'buildanima' and 'buildavatar' or self.mode == 'buildscene' and 'buildscene' or 'buildbrick'),
		function()
			self:hideBricksUI()
		end, params)
end

BuildBrick.hideSwitchUI = function(self, show)
	if show == nil then show = false end
	if not self.enableSwitchPart or self.switchParts and #self.switchParts == 0 then
		self.ui.switch.visible = false
		self.ui.switchlist.visible = false
		return
	end

	self.ui.switchlist.visible = show
	self.ui.switch.selected = show
end

BuildBrick.showMovHint = function(self, show)
	if not show then
		if self.moveUI then
			self.moveUI.visible = false
		end
		return
	end

	local movplaneuis = {'movePlane', 'movePlane1'}
	local h = self.ui._height
	if not self.moveUI or self.moveUI.enableGraffiti ~= self.enableGraffiti then
		local index = self.enableGraffiti == true and 2 or 1
		if not self.moveUIs then self.moveUIs = {} end
		if not self.moveUIs[index] then
			self.moveUIs[index] = self.ui:loadView(movplaneuis[index])
			local ui = self.moveUIs[index]
			ui.enableGraffiti = self.enableGraffiti
			self.moveUI = ui
			ui._width, ui._height = 400, 400
			ui._x, ui._y = self.ui.safearea_left._width, h / 2 - self.moveUI._width / 2
			ui:addRelation(self.ui.safearea_left, _FairyManager.Left_Right)
			ui:addRelation(self.ui, _FairyManager.Middle_Middle)

			ui.right._soundVolumeScale = 0.0
			ui.left._soundVolumeScale = 0.0
			ui.up._soundVolumeScale = 0.0
			ui.down._soundVolumeScale = 0.0

			if ui.checkhit then
				ui.checkhit.selected = self.checkmovehit
				ui.checkhit.click = function()
					self.checkmovehit = ui.checkhit.selected
				end
			end

			local clickfunc = function(btn)
				--local step = self.MinStep and 0.02 or 0.1

				local step = (self:isMusicMode('music_train') or self:isSelectedHasDungeon()) and (_sys:isKeyDown(_System.KeyShift) and 0.1 or 0.8)
					or (_sys:isKeyDown(_System.KeyShift) and 0.02 or 0.1)
				local axis
				if btn == Global.DIRECTION.RIGHT then
					axis = Global.typeToAxis(Global.dir2AxisType(Global.DIRECTION.RIGHT, Global.AXISTYPE.Z))
				elseif btn == Global.DIRECTION.LEFT then
					axis = Global.typeToAxis(Global.dir2AxisType(Global.DIRECTION.LEFT, Global.AXISTYPE.Z))
				elseif btn == Global.DIRECTION.UP then
					local c = self:getCameraControl()
					local dirv = c:getDirV()
					if dirv > math.pi * 0.25 and dirv < math.pi * 0.75 then
						axis = Global.typeToAxis(Global.dir2AxisType(Global.DIRECTION.UP, Global.AXISTYPE.Z))
					else
						axis = Global.AXIS.Z
					end
				elseif btn == Global.DIRECTION.DOWN then
					local c = self:getCameraControl()
					local dirv = c:getDirV()
					if dirv > math.pi * 0.25 and dirv < math.pi * 0.75 then
						axis = Global.typeToAxis(Global.dir2AxisType(Global.DIRECTION.DOWN, Global.AXISTYPE.Z))
					else
						axis = Global.AXIS.NZ
					end
				end

				if not axis then return end

				if self.enableGraffiti then
					if not self.rt_selectedBlocks[1] then return end
					-- self.rt_selectedBlocks[1]:movePaint(btn, step)
					self:atom_paint_move(self.rt_selectedBlocks[1], btn, step)
				else
					self:cmd_mat_update_begin(nil, 'move')
					Global.PickHelper:attachBlocks(self.rt_selectedBlocks, nil, self.rt_transform)
					local checkhit = true
					if ui.checkhit then
						checkhit = self.checkmovehit
					end

					Global.PickHelper:clickMove(axis, step, checkhit, function(vec)
						for i, g in ipairs(self.rt_selectedGroups) do
							g.transform:mulTranslationRight(vec)
						end
					end)
					self:cmd_mat_update_end()
					self:atom_group_knot_dirty()

					if self.checkBlocking then
						self:checkBlocking(self.rt_selectedBlocks)
					end
				end
			end

			ui.right.click = function()
				clickfunc(Global.DIRECTION.RIGHT)
			end
			ui.left.click = function()
				clickfunc(Global.DIRECTION.LEFT)
			end
			ui.up.click = function()
				clickfunc(Global.DIRECTION.UP)
			end
			ui.down.click = function()
				clickfunc(Global.DIRECTION.DOWN)
			end
		else
			self.moveUI = self.moveUIs[index]
		end
	end

	for _, ui in pairs(self.moveUIs) do
		ui.visible = false

		if ui.checkhit then
			ui.checkhit.selected = self.checkmovehit
		end
	end

	self.moveUI.visible = show
end

BuildBrick.initScaleHint = function(self, mode)
	--self.enableGraffiti and 'scaleGraffiti' or 'scaleBlock'
	if mode == 'scaleBlock' or mode == 'scalePfx' then
		local senscales = {0.25, 0.5, 0.75, 1, 1.5, 2, 4, 8, 16, 32, 64}
		if mode == 'scalePfx' then
			senscales = {0.25, 0.5, 0.75, 1, 1.5, 2, 4}
		end

		self.maxscaleIndex = #senscales

		self.getScaleByIndex = function(self, index)
			return senscales[index]
		end

		self.findScaleIndex = function(self, scale)
			local s = Global.normalizeScale(scale, 0.25)
			local index
			for i, v in ipairs(senscales) do
				if v == s then
					index = i
					break
				elseif v > s then
					index = i - 1
					break
				end
			end

			if not index then
				index = #self.maxscaleIndex
			end

			return index
		end
	else
		local scalestep = 0.125
		self.maxscaleIndex = 16
		self.getScaleByIndex = function(self, index)
			return Global.getScaleByIndex(index, scalestep)
		end

		self.findScaleIndex = function(self, scale)
			return Global.findScaleIndex(scale, scalestep)
		end
	end
end

BuildBrick.showFrameActionList = function(self, frame, isright)
	local show = not not frame
	local ui = self.ui.actionlist
	ui.visible = show
	if not show then return end

	local x = 250
	ui._x = isright and self.ui._width - ui._width - x or x
	ui:addRelation(self.ui, isright and _FairyManager.Right_Right or _FairyManager.Left_Left)
	ui.sortingOrder = 100

	ui.ispair.visible = false
	ui.isloop.visible = true

	ui.isloop.loop.selected = frame.isActionLoop
	ui.isloop.loop.click = function()
		frame.isActionLoop = ui.isloop.loop.selected
		self:setTransitionDirty()
	end

	local datas = Global.DfActionType
	ui.list.onRenderItem = function(index, item)
		local data = datas[index - 1]
		item.icon._icon = 'img://' .. (index == 1 and 'logic_del.png' or data.icon)
		item.selbg2.visible = false

		item.click = function()
			self:stopDFrame()
			if index == 1 then
				frame.actionType = nil
			else
				frame.actionType = data.type
			end
			self:refreshDFrameItems()
			self:setTransitionDirty()
		end
	end

	ui.list.itemNum = #datas + 1

	self:showDisableBg(true, function()
		self:showDisableBg(false)
		self:showFrameActionList()
	end)
end

BuildBrick.showXfXResList = function(self, bmarker, bindxfx, isright)
	local show = not not bindxfx
	local ui = self.ui.xfxlist
	ui.visible = show
	if not show then return end

	local x = 250
	ui._x = isright and self.ui._width - ui._width - x or x
	ui:addRelation(self.ui, isright and _FairyManager.Right_Right or _FairyManager.Left_Left)
	ui.sortingOrder = 100

	ui.tab1.visible = true
	ui.tab2.visible = false
	ui.isloop.visible = false
	ui.ispair.visible = false
	ui.sel_item.visible = true
	ui.play.visible = false

	--ui.isloop.loop.selected = bindxfx.loop
	-- ui.volume.maxValue = 100
	-- ui.volume.currentValue = toint(bindxfx.volume * 100)
	-- ui.tab1.title = 'Effect'
	-- ui.tab2.title = 'Sound'

	local function onselect_data(bindxfx)
		if not bindxfx then return end
		local datas = bindxfx.xfxtype == 'pfx' and Global.Marker_PfxRess or Global.Marker_SoundRess
		local data = datas[bindxfx.type]
		ui.sel_item.icon._icon = 'img://' .. data.icon
		self.sel_bindxfx = bindxfx
	end

	local showsfxList = function(xfxtype)
		local datas = xfxtype == 'pfx' and Global.Marker_PfxRess_Order or Global.Marker_SoundRess_Order
		ui.scale.visible = false -- xfxtype == 'pfx'
		ui.tab1.selected = xfxtype == 'sfx'
		ui.tab2.selected = xfxtype == 'pfx'
		-- ui.tab2.disabled = true
		--ui.volume.visible = xfxtype == 'sfx'
		ui.volume.visible = false
		ui.play.visible = xfxtype == 'sfx'
		ui.list.onRenderItem = function(index, item)
			local data = datas[index]
			item.icon._icon = 'img://' .. data.icon
			item.selbg2.visible = false

			item.click = function()
				bindxfx.xfxtype = xfxtype
				bindxfx.type = data.type

				local b = self.rt_selectedBlocks[1]
				if b then
					self:refreshMarkerXfxList(b)
				end

				bmarker:refreshXfx()

				onselect_data({xfxtype = xfxtype, type = data.type})
			end
		end

		ui.list.itemNum = #datas

		if not self.sel_bindxfx or self.sel_bindxfx.xfxtype ~= xfxtype then
			onselect_data({xfxtype = xfxtype, type = datas[1].type})
		else
			onselect_data({xfxtype = xfxtype, type = bindxfx.type})
		end
	end

	ui.tab1.click = function()
		showsfxList('sfx')
	end

	ui.tab2.click = function()
		showsfxList('pfx')
	end

	ui.play.click = function()
		if self.sel_bindxfx.xfxtype == 'sfx' then
			local data = Global.Marker_SoundRess[bindxfx.type]
			local sg = SoundGroup.new()
			sg.type = 0
			sg.volume = 1
			sg.soundName = data.res
			sg:play()
		end
	end
--[[
	ui.isloop.loop.click = function()
		bindxfx.loop = ui.isloop.loop.selected
		bmarker:refreshXfx()
	end

	ui.volume.onChanged = function()
		bindxfx.volume = ui.volume.currentValue / 100
	end

	self:initScaleHint('scalePfx')
	self.scaleindex = self:findScaleIndex(bindxfx.scale, self.maxscaleIndex)
	ui.scale.zoomout.click = function()
		if self.scaleindex ~= 1 then
			--local scale1 = self:getScaleByIndex(self.scaleindex)
			self.scaleindex = self.scaleindex - 1
			local scale2 = self:getScaleByIndex(self.scaleindex)
			bindxfx.scale = scale2
			--changeScale(self, scale1, scale2)

			ui.scale.text.text = scale2 * 100 .. '%'
			bmarker:refreshXfx()
		end
	end
	ui.scale.zoomin.click = function()
		if self.scaleindex < self.maxscaleIndex then
			self.scaleindex = self.scaleindex + 1
			local scale2 = self:getScaleByIndex(self.scaleindex)
			bindxfx.scale = scale2

			ui.scale.text.text = scale2 * 100 .. '%'
			bmarker:refreshXfx()
		end
	end
]]
	showsfxList(bindxfx.xfxtype)

	self:showDisableBg(true, function()
		self:showDisableBg(false)
		self:showXfXResList()
	end)
end

BuildBrick.refreshMarkerXfxList = function(self, b)
	local mdata = b.markerdata
	if not mdata.ress then
		mdata.ress = {}
	end
	local ress = mdata.ress
	local ui = self.ui.marker_xfx
	-- ui.play.selected = mdata:isMarkerEnabled()
	ui.play.click = function()
		--if ui.play.selected then
			mdata:resetXfx()
		-- else
		-- 	mdata:stopXfxs()
		-- end
	end

	local itemw = 0
	ui.list.onRenderItem = function(index, item)
		local data = ress[index]
		if itemw == 0 then
			itemw = item._width
		end
		if index == #ress + 1 then
			item.imgload._icon = 'img://button_add.png'
			item.del.visible = false
			item.click = function()
				local t = {}
				t.xfxtype = 'sfx'
				t.type = Global.Marker_SoundRess_Order[1].type
				t.loop = false
				t.scale = 1
				t.volume = 1
				table.insert(mdata.ress, t)
				mdata:refreshXfx()
				self:refreshMarkerXfxList(b)

				local p = item:local2Global(0, 0)
				local isright = p.x < _rd.w / 2
				self:showXfXResList(mdata, t, isright)
			end
		else
			item.del.visible = true
			local res = data.xfxtype == 'pfx' and Global.Marker_PfxRess[data.type] or Global.Marker_SoundRess[data.type]
			item.imgload._icon = 'img://' .. res.icon
			item.del.click = function()
				table.remove(mdata.ress, index)
				mdata:refreshXfx()
				Global.Timer:add('refreshMarkerXfxList', 0, function()
					self:refreshMarkerXfxList(b)
				end)
			end

			item.click = function()
				local p = item:local2Global(0, 0)
				local isright = p.x < _rd.w / 2
				self:showXfXResList(mdata, data, isright)
			end
		end
	end
	--print('mdata.ress', #ress, debug.traceback())
	ui.list.itemNum = #ress + 1
	ui.list._width = itemw * (#ress + 1)
end

BuildBrick.showMarkerHint = function(self, show)
	local uis = {'marker_camera', 'marker_xfx', 'xfxlist'}

	for i, key in ipairs(uis) do
		self.ui[key].visible = false
	end

	if #self.rt_selectedBlocks ~= 1 or not show then
		if self.lasteditmarkerdata then
			self.lasteditmarkerdata:enableMarker(false)
			self.lasteditmarkerdata = nil
		end
		return
	end
	local b = self.rt_selectedBlocks[1]
	local mdata = b.markerdata
	if not mdata then return end
	self.lasteditmarkerdata = mdata

	if mdata.type == 'camera' then
		local ui = self.ui.marker_camera
		ui.visible = true

		ui.usecamera.click = function()
			-- 清空选中
			self:cmd_select_begin()
			self:cmd_select_end()

			self:hideNormalUIs(true, function()
				self:showDisableBg(true)
				-- self.ui.back.visible = true
				Global.SwitchControl:set_cameracontrol_off()

				if not self.markercamera then
					self.markercamera = _Camera.new()
				end

				local cam = self.markercamera
				local vec = Container:get(_Vector3)
				b.node.transform:getTranslation(vec)
				cam.eye:set(vec)
				vec:set(0, 1, 0)
				Global.getRotaionAxis(vec, b.node.transform, vec)
				_Vector3.mul(vec, 0.1, vec)
				_Vector3.add(cam.eye, vec, cam.look)
				self:atom_camera_bind(true, cam)
				b.node.visible = false
				self.camerabinding = true
				-- print('cam.eye', cam.eye, cam.look, vec)
				-- local cc = Global.CameraControl:get()
				-- print('cc', cc.camera)
				self:addBackClickCb('onlyback', function()
					self.camerabinding = false
					b.node.visible = true
					self:atom_camera_bind()
					self:showDisableBg(false)
					self:hideNormalUIs(false)
					Global.SwitchControl:set_cameracontrol_on()
				end)

				Global.AddHotKeyFunc(_System.KeyESC, function()
					return self.camerabinding
				end, function()
					self:clickBackCb()
				end)
			end)
		end

		local function ondown_pickblock(self, x, y)
			local block = self:pickBlock(x, y)
			if block then
				mdata.bindblock = block
				Global.Sound:play('ui_click03')
			else
				mdata.bindblock = nil
			end
		end

		ui.bindcamera.selected = false
		ui.bindcamera.click = function()
			if ui.bindcamera.selected then
				self.lastondownfunc = self.ondownfunc
				self.lastonmovefunc = self.onmovefunc
				self.lastonupfunc = self.onupfunc
				self.ondownfunc = ondown_pickblock
				self.onmovefunc = nil
				self.onupfunc = nil

				self:hideNormalUIs(true, function()
					ui.visible = true
				end)
			else
				self.ondownfunc = self.lastondownfunc
				self.onmovefunc = self.lastonmovefunc
				self.onupfunc = self.lastonupfunc
				self:hideNormalUIs(false)
			end
		end
	elseif mdata.type == 'xfxs' then
		local ui = self.ui.marker_xfx
		ui.visible = true
		self:refreshMarkerXfxList(b)
	end
end

local b_pos = _Vector3.new()
local ui_pos = _Vector2.new()
local hintv1 = _Vector3.new()
local hintv2 = _Vector3.new()

local hint2v1 = _Vector2.new()
local hint2v2 = _Vector2.new()
local hintline = _Image.new('joint_line1.png')
BuildBrick.renderMarkerHint = function(self)
	local b = self.rt_selectedBlocks[1]
	if not b or not b.markerdata then return end

	local uis = {'marker_camera', 'marker_xfx'}
	local show = false
	for i, key in ipairs(uis) do
		local ui = self.ui[key]
		if ui.visible then
			show = true
			break
		end
	end

	if not show then return end

	local ab = b:getShapeAABB2(true)
	ab:getTop(b_pos)
	_rd:projectPoint(b_pos.x, b_pos.y, b_pos.z, ui_pos)
	local pos = self.ui:global2Local(ui_pos.x, ui_pos.y)

	for i, key in ipairs(uis) do
		local ui = self.ui[key]
		if ui.visible then
			ui._x = pos.x - ui._width / 2
			ui._y = pos.y - ui._height
		end
	end

	local mdata = b.markerdata
	if mdata.type == 'camera' and mdata.bindblock and mdata.bindblock:isNodeValid() then
		b.node.transform:getTranslation(hintv1)
		mdata.bindblock.node.transform:getTranslation(hintv2)

		local x1, y1, s1 = _G.projectWithSize(hintv1, 0.05)
		local x2, y2, s2 = _G.projectWithSize(hintv2, 0.05)
		hint2v1:set(x1, y1)
		hint2v2:set(x2, y2)
		self:draw3DLine(hintline, hint2v1, hint2v2, math.min(s1, s2))

		--_rd:draw3DLine(hintv1.x, hintv1.y, hintv1.z, hintv2.x, hintv2.y, hintv2.z, _Color.Red)
	end
end

BuildBrick.DrawHint = function(self)
	if #self.rt_selectedBlocks == 0 then return end

	if #self.rt_selectedBlocks == 1 and self.mode == 'buildscene' then
		local b = self.rt_selectedBlocks[1]
		if not b.markerdata and b:isDungeonBlock() then
			if not self.objhint then
				self.objhint = Block.getBlockMesh('locationnew')
			end
			_rd:pushMatrix3D(b.node.transform)
			self.objhint:drawMesh()
			_rd:popMatrix3D()
		end
	end
end

BuildBrick.showScaleHint = function(self, show)
	local b = self.rt_selectedBlocks[1]
	local uiscale = self.ui.graffitiscale
	uiscale.visible = show and (self.enableGraffiti or (self:isBuildScene() and b and not self:isMusicMode('music_train') and not self:isHelperDummy(b) and true))
	if uiscale.visible then
		self:initScaleHint(self.enableGraffiti and 'scaleGraffiti' or 'scaleBlock')
	end

	uiscale.inputtext.visible = false --self:isBuildScene() and b and false
	if self:isBuildScene() and b then
		local scale = Container:get(_Vector3)
		b.node.transform:getScaling(scale)
		if scale.x < 0 then
			scale.x = -scale.x
		end

		Global.normalizeScale(scale)
		self.scaleindex = self:findScaleIndex(scale.x)
		self.ui.graffitiscale.text.text = scale.x * 100 .. '%'
		uiscale.inputtext.text = scale.x * 100
		self.curscale = scale.x
	elseif self.enableGraffiti and b then
		local scale = b.data.paintInfo.scale
		self.scaleindex = self:findScaleIndex(scale.x)
		--local scale = self.getScaleByIndex(self.scaleindex)
		self.ui.graffitiscale.text.text = scale.x * 100 .. '%'
		self.curscale = scale.x
	end

	self:showTopButtons()
end

local rottimer = _Timer.new()

-- local selectBlocksCache = {}
-- BuildBrick.checkSelectChanged = function(self)
-- 	local maxn = math.max(#selectBlocksCache, #self.rt_selectedBlocks)
-- 	local changed = false
-- 	for i = 1, maxn do
-- 		local b1, b2 = selectBlocksCache[i], self.rt_selectedBlocks[i]
-- 		if b1 ~= b2 then
-- 			changed = true
-- 			break
-- 		end
-- 	end

-- 	if changed then
-- 		selectBlocksCache = {}
-- 		table.copy(selectBlocksCache, self.rt_selectedBlocks)
-- 	end

-- 	return changed
-- end

BuildBrick.showRotHint = function(self, show)
	self.showrot = show
	if not show then
		if self.rotHintUIs then
			for i, v in ipairs(self.rotHintUIs) do
				v.ui.visible = false
				v.btn1.visible = false
				v.btn2.visible = false
			end
		end
		return
	end

	if not self.rotHintUIs then
		self.rotHintUIs = {}
		self.rotHintMesh = _Mesh.new('arrow_01.msh')
		self.rotmtl_normal = _Material.new('arrow_01.mtl')
		self.rotmtl_hover = _Material.new('arrow_01_1.mtl')

		self.rotRestriction = {}
		self.rotRestriction.pos = _Vector3.new()
		self.rotRestriction.pivot = _Vector3.new()
		self.rotRestriction.axis = _Vector3.new()
		self.rotRestriction.enable = false

		local px = 250
		local w, h = self.ui._width - self.ui.safearea_right._width, self.ui._height
		local ps = {}
		table.insert(ps, {w - px - 100, h / 2 - 50})
		table.insert(ps, {w - px + 100, h / 2 - 50})
		table.insert(ps, {w - px, h / 2 + 150})

		for i = 1, #ps do
			local hint = {}
			local ui = self.ui:loadView('picloadhint')
			self.ui[i .. 'bg'] = ui
			ui._width, ui._height = 200, 200
			ui._x, ui._y = ps[i][1] - ui._width / 2, ps[i][2] - ui._height / 2
			ui:addRelation(self.ui.safearea_right, _FairyManager.Right_Left)
			ui:addRelation(self.ui, _FairyManager.Middle_Middle)

			hint.ui = ui
			hint.index = i
			hint.db = _DrawBoard.new(200, 200)
			hint.ui:loadMovie(hint.db)
			hint.axis = Container:get(_Vector2)
			hint.enable = self.mode ~= 'buildhouse' or i == 3
			table.insert(self.rotHintUIs, hint)
			ui.hitTestDisable = true

			local cx, cy = ui._x + ui._width / 2, ui._y + ui._height / 2
			local diff, s = 60, 60
			if i == 1 or i == 2 then
				local ccx, ccy = cx, cy - diff
				hint.rect1 = _Rect.new(ccx - s, ccy - s, ccx + s, ccy + s)
				ccy = cy + diff
				hint.rect2 = _Rect.new(ccx - s, ccy - s, ccx + s, ccy + s)
			else
				local ccx, ccy = cx - diff, cy
				hint.rect1 = _Rect.new(ccx - s, ccy - s, ccx + s, ccy + s)
				ccx = cx + diff
				hint.rect2 = _Rect.new(ccx - s, ccy - s, ccx + s, ccy + s)
			end

			local onDown = function(mx, my, index)
				--local scalef = Global.UI:getScale()
				--local mx, my = x / scalef, y / scalef
				-- if hint.rect1:inside(mx, my) then
				-- 	hint.hitx, hint.hity, hint.isrot = mx, my, 1
				-- elseif hint.rect2:inside(mx, my) then
				-- 	hint.hitx, hint.hity, hint.isrot = mx, my, 2
				-- end

				hint.hitx, hint.hity, hint.isrot = mx, my, index
			end

			local rotdata
			local onUp = function(mx, my)
				if not hint.isrot then return false end
				--local scalef = Global.UI:getScale()
				--local mx, my = x / scalef, y / scalef
				if self.enableGraffiti then
					local b = self.rt_selectedBlocks[1]
					if not b then return end
					local oneradius = math.pi / 180
					local r = hint.isrot == 1 and -oneradius * 15 or oneradius * 15
					-- b:rotatePaint(r)
					self:atom_paint_rot(b, r)
					hint.isrot = nil
				else
					Global.rotfactor = self:isSelectedHasDungeon() and 90 or (_sys:isKeyDown(_System.KeyShift) and 15 or 45)

					--if hint.isrot == 1 and hint.rect1:inside(mx, my) or hint.isrot == 2 and hint.rect2:inside(mx, my) then
						local arg = {mouse = {x = mx, y = my}}
						if rotdata then
							self:rotBlockEnd(arg)
							rottimer:stop()
							if rotdata.g then
								rotdata.g:setTempRoot(true)
								if rotdata.lockg then
									rotdata.lockg:useRecombineBackup()
								end
								self:atom_group_select(rotdata.g)
							end
							rotdata = nil
						end

						arg = {mouse = {x = hint.hitx, y = hint.hity}}
						arg.mouse.x, arg.mouse.y = hint.hitx, hint.hity

						local oldg, lockg
						if self.rotRestriction.enablegroup and #self.rt_selectedGroups == 1 then
							local g = self.rt_selectedGroups[1]
							self:useRecombineBackup(g)
							lockg = g:getLock2Parent(true)
							if lockg then
								lockg:setTempRoot(true)
							end
							self:atom_group_select(lockg or g:getRoot(), true)
							oldg = g
						end

						self:rotBlockBegin(arg, hint.index, hint.axis, 60, self.rotRestriction)

						local dx, dy = 0, 0
						if i == 1 or i == 2 then
							dy = hint.isrot == 1 and - 60 or 60
						else
							dx = hint.isrot == 1 and - 60 or 60
						end

						arg.mouse.x = arg.mouse.x + dx
						arg.mouse.y = arg.mouse.y + dy
						self:rotBlock(arg)

						local e = 150
						rotdata = {g = oldg, lockg = lockg}
						rottimer:start('rot', e, function()
							self:rotBlockEnd(arg)
							rottimer:stop()
							if rotdata and rotdata.g then
								rotdata.g:setTempRoot(true)
								-- if rotdata.lockg then
								-- 	rotdata.lockg:useRecombineBackup()
								-- end
								self:atom_group_select(rotdata.g)
							end
							rotdata = nil
						end)
						hint.isrot = nil
					--end
				end
			end

			local btn1 = self.ui:loadView('picloadhint')
			btn1._soundVolumeScale = 0.0
			self.ui[i .. 'btn1'] = btn1
			btn1._width, btn1._height = s * 2, s * 2
			btn1._x, btn1._y = hint.rect1.x1, hint.rect1.y1
			btn1:addRelation(self.ui.safearea_right, _FairyManager.Right_Left)
			btn1:addRelation(self.ui, _FairyManager.Middle_Middle)
			hint.btn1 = btn1
			btn1.onMouseDown = function(arg)
				onDown(arg.mouse.x, arg.mouse.y, 1)
			end
			btn1.onMouseUp = function(arg)
				onUp(arg.mouse.x, arg.mouse.y)
			end

			local btn2 = self.ui:loadView('picloadhint')
			btn2._soundVolumeScale = 0.0
			self.ui[i .. 'btn2'] = btn2
			btn2._width, btn2._height = s * 2, s * 2
			btn2._x, btn2._y = hint.rect2.x1, hint.rect2.y1
			btn2:addRelation(self.ui.safearea_right, _FairyManager.Right_Left)
			btn2:addRelation(self.ui, _FairyManager.Middle_Middle)
			hint.btn2 = btn2

			btn2.onMouseDown = function(arg)
				onDown(arg.mouse.x, arg.mouse.y, 2)
			end
			btn2.onMouseUp = function(arg)
				onUp(arg.mouse.x, arg.mouse.y)
			end
		end
	end

	if self.enableGraffiti then
		for i, v in ipairs(self.rotHintUIs) do
			v.enable = i == 3 and true or false
		end
	else
		for i, v in ipairs(self.rotHintUIs) do
			v.enable = true
		end
	end

	if self:isSelectedHasDungeon() and #self.rt_selectedBlocks ~= 1 then
		for i, v in ipairs(self.rotHintUIs) do
			v.enable = false
		end
	end

	if self.knotMode == Global.KNOTPICKMODE.NONE then
		self.rotRestriction.enable = false
		self.rotRestriction.enablegroup = false
		for i, v in ipairs(self.rotHintUIs) do
			v.ui.visible = v.enable
			v.btn1.visible = v.enable
			v.btn2.visible = v.enable
		end
	else
		-- 处理旋转时的旋转轴问题
		self.rotRestriction.enablegroup = false
		if self.enableGroup and self:checkGroupRotRestriction(self.rt_selectedGroups, self.rotRestriction) then
			self.rotRestriction.enable = true
			-- self.rotRestriction.enablepivot = false

			local axistype = Global.getNearestAxisType(self.rotRestriction.axis)
			local axisindex = Global.toPositiveAxisType(axistype)
			local type = self.rotRestriction.type
			for i, v in ipairs(self.rotHintUIs) do
				local vis = v.enable and (axisindex == i and type == 2 or type == 3)
				v.ui.visible = vis
				v.btn1.visible = vis
				v.btn2.visible = vis
			end
		else
			local rotdata
			if self.enableGroup and #self.rt_selectedBlocks == 1 then
				local b = self.rt_selectedBlocks[1]
				local g = b:getBlockGroup()
				if g.parent then
					rotdata = b:getRotData()
				end
			end

			if rotdata and self:formatRotRestriction(rotdata, self.rotRestriction) then
				self.rotRestriction.enable = true
				self.rotRestriction.enablegroup = true
				local axistype = Global.getNearestAxisType(self.rotRestriction.axis)
				local axisindex = Global.toPositiveAxisType(axistype)
				local type = self.rotRestriction.type
				for i, v in ipairs(self.rotHintUIs) do
					local vis = v.enable and (axisindex == i and type == 2 or type == 3)
					v.ui.visible = vis
					v.btn1.visible = vis
					v.btn2.visible = vis
				end
			else
				self.rotRestriction.enable = false
				for i, v in ipairs(self.rotHintUIs) do
					v.ui.visible = v.enable
					v.btn1.visible = v.enable
					v.btn2.visible = v.enable
				end
			end
		end
	end
	-- if self:checkSelectChanged() then
	-- 	self.rotRestriction.enablepivot = false
	-- end

	self:renderRotDB()
end

local xaxis2 = _Vector2.new(1, 0)
local rotcamera = _Camera.new()

BuildBrick.renderRotDB = function(self, index)
	if not self.showrot then return end

	local cam = _rd.camera
	local look = _rd.camera.look
	local vec1 = Container:get(_Vector3)

	local v2 = Container:get(_Vector2)
	local axisx = Container:get(_Vector2)
	local axisy = Container:get(_Vector2)
	local axisz = Container:get(_Vector2)

	v2:set(_rd.w / 2, _rd.h / 2)

	-- x/y/z轴投影朝向
	for i = 1, 3 do
		local axisv3 = i == 1 and Global.AXIS.X or i == 2 and Global.AXIS.Y or Global.AXIS.Z
		local axis = i == 1 and axisx or i == 2 and axisy or axisz
		_Vector3.add(look, axisv3, vec1)
		_rd:projectPoint(vec1.x, vec1.y, vec1.z, axis)
		_Vector2.sub(axis, v2, axis)
		axis:normalize()
	end

	-- 处理旋转时的滑动方向
	for i, v in ipairs(self.rotHintUIs) do
		if i == Global.AXISTYPE.X then
			v.axis:set(axisz)
		elseif i == Global.AXISTYPE.Y then
			v.axis:set(axisz)
		elseif i == Global.AXISTYPE.Z then
			v.axis:set(-1, 0)
		end
	end

	local function calcrot(v)
		local r = _Vector2.dot(v, xaxis2)
		return v.y > 0 and math.acos(r) or - math.acos(r)
	end

	local rx = calcrot(axisx)
	local ry = calcrot(axisy)
	local rz = calcrot(axisz)
	-- print('rot:', rx, ry, rz)

	_Vector3.sub(cam.eye, cam.look, vec1)
	vec1:normalize()
	_Vector3.mul(vec1, 0.9, vec1)
	local tempcamera = Container:get(_Camera)

	rotcamera.look:set(0, 0, 0)
	rotcamera.eye:set(vec1)
	rotcamera.viewNear = 0.1
	rotcamera.viewFar = 100

	tempcamera:set(_rd.camera)
	_rd:pushCamera()
	_rd.camera:set(rotcamera)

	local phi = rotcamera.phi
	for i, v in ipairs(self.rotHintUIs) do
		if v.enable then
			_rd:useDrawBoard(v.db, _Color.Null)
			local trans = self.rotHintMesh.transform
			trans:setScaling(3, 3, 3)
			--trans:mulTranslationRight(0, 0.1, 0)
			if i == 1 then
				trans:mulRotationYRight(math.pi / 2)
				--if ry > -math.pi / 2 and ry < math.pi / 2 then
				--	trans:mulRotationXRight(math.pi)
				--end
			elseif i == 2 then
				trans:mulRotationXRight(math.pi / 2)
				trans:mulRotationYRight(math.pi / 2)
				--if rx > math.pi / 2 or rx < -math.pi / 2 then
					trans:mulRotationYRight(math.pi)
				--end
			else
				trans:mulRotationZRight(phi - math.pi / 2)
			end

			if v.isrot then
				self.rotHintMesh.material = self.rotmtl_hover
			else
				self.rotHintMesh.material = self.rotmtl_normal
			end
			_rd:useLight(Block.defaultAmbientLight)
			_rd:useLight(Block.defaultSkyLight)

			--_rd:drawAxis(0.2)
			self.rotHintMesh:drawMesh()
			_rd:popLight()
			_rd:popLight()
			_rd:resetDrawBoard()

			-- local x, y = _rd.w / 2, _rd.h / 2
			-- _rd:drawLine(x, y, x + v.axis.x * 100, y + v.axis.y * 100,
			-- 	i == 1 and _Color.Green or i == 2 and _Color.Yellow or _Color.Red)

			-- local scalef = Global.UI:getScale()
			-- local x1, y1, x2, y2 = v.btn1._x, v.btn1._y, v.btn1._x + v.btn1._width, v.btn1._y + v.btn1._height
			-- x1, y1, x2, y2 = x1 * scalef, y1 * scalef, x2 * scalef, y2 * scalef
			-- _rd:fillRect(x1, y1, x2, y2, _Color.Red)

			-- x1, y1, x2, y2 = v.btn2._x, v.btn2._y, v.btn2._x + v.btn2._width, v.btn2._y + v.btn2._height
			-- x1, y1, x2, y2 = x1 * scalef, y1 * scalef, x2 * scalef, y2 * scalef
			-- _rd:fillRect(x1, y1, x2, y2, _Color.Green)
		end
	end

	_rd:popCamera()
	_rd.camera:set(tempcamera)

	Container:returnBack(vec1, v2, axisx, axisy, axisz, tempcamera)
end

BuildBrick.recoverPickState = function(self, x, y)
	if self.selectedWAll then
		self.selectedWAll:setEditState(nil, true)
		self.selectedWAll = nil
	end
end

BuildBrick.checkBlockPickable = function(self, b)
	local flag = Global.CONSTPICKFLAG.NORMALBLOCK + Global.CONSTPICKFLAG.SELECTBLOCK + Global.CONSTPICKFLAG.SELECTWALL
	if self.enablePart then
		flag = flag + Global.CONSTPICKFLAG.BONE
	end

	if not b:hasPickFlag(flag) then
		return false
	end

	if b.bindblock or b.ui_click_cb or b:hasPickFlag(Global.CONSTPICKFLAG.SELECTWALL) then -- 处理替代物品
		return false
	end

	if self:isMusicMode('music_main') then
		return false
	end

	return true
end

BuildBrick.ondown_editbrick = function(self, x, y)
	self:recoverPickState()

	local b, pos = self:pickBlock(x, y)
	if b and b.bindblock then -- 处理替代物品
		b = b.bindblock
	end

	if b and b.ui_click_cb then -- 把当前积木当做UI响应
		b.ui_click_cb()
		b = nil -- 当做没有选中
	end

	if b and b:hasPickFlag(Global.CONSTPICKFLAG.SELECTWALL) then
		b:setEditState('selected', true)
		self.selectedWAll = b
		b = nil
	end

	if b and self:isMusicMode('music_main') then
		b:setEditState('selected', true)
		self.selectedWAll = b
		b = nil
	end
	-- if b and b.bindTrain then
	-- 	self:onSelectTrain(b)
	-- 	return
	-- end

	print('ondown_editbrick', b, b and b:getPickFlag())

	if b then
		self:cmd_select_begin(b, pos)
	else
		self:cmd_select_begin()
	end
end
BuildBrick.onmove_editbrick = function(self, x, y)
	self:building_moveBegin(x, y)
	if not self.rt_moving then return end
	self.movedx, self.movedy = self.mdx, self.mdy
	self:moveBlock(x, y)

	return true
end

BuildBrick.onup_editbrick = function(self, x, y, dbclick)
	local selected = self:cmd_select_end()
	--print('onup_editbrick', selected, dbclick)
	-- 长按的结束, 结束时直接认为下次是单击
	if self:building_moveEnd(x, y) then
		return true
	elseif (selected == 0 or selected == 1) and self.last_selected == self.rt_block then
		-- 双击同一块, 点到块上呼出材质和旋转，点击空白 呼出 积木库
		if dbclick then
			Global.Sound:play('ui_click18')
			self:onDClick()
		end
	end

	self.last_selected = self.rt_block

	return false
end

BuildBrick.onDClick = function(self)

	if self:isMusicMode('music_main') then
		local b1 = self.selectedWAll
		if b1 then
			if b1.bindTrain or b1.bindmoduleBlocks then
				self:goMusicMode('music_train')
			else
				self:goMusicMode('music_bg')
			end

			local aabb = _AxisAlignedBox.new()
			b1:getAABB(aabb)
			self:camera_focus(aabb, 1, 12)
		end
		return
	end

	if #self.rt_selectedBlocks > 0 then
		local b1 = #self.rt_selectedBlocks == 1 and self.rt_selectedBlocks[1]
		if self.mode == 'buildbrick' and b1 and b1.markerdata and b1.markerdata.type == 'marker_blocks' then
			self:cmd_select_begin()
			self:cmd_select_end()
			self:cmd_enter_marker_blocks(b1)
		elseif self.enableGroup and not self.disableGroupCombine then
			local g = self.rt_selectedGroups[1]
			if g:isLock() and not g:isDeadLock() then
				self:cmd_select_begin()
				self:cmd_select_end()
				self:cmd_enter_group(g)
			end
		elseif self.mode == 'buildscene' and b1 and not self:isHelperDummy(b1) then
			local obj = Global.GetClientObject(b1:getShape())
			-- print('obj', obj and obj.stype2, b1:getShape())
			if obj and obj.stype2 and obj.stype2 ~= '' then
				local callback = function()
					self.ui.visible = false

					local params = {}
					params.hidelabelList = true
					params.objectkinds = {}
					params.objectkinds[obj.stype2] = true
					params.noshowavatar = true
					params.forceupdate = true
					params.showsmalllist = true
					params.obj_clickfunc = function(newobj)
						b1:setShape(newobj.name)
					end
					self:showBricksUI(params)
				end
				_G:holdbackScreen(self.timer, callback)
			elseif obj and obj.disableEdit then
			else
				if self:getParam('scenemode') ~= 'scene_music' then
					self:cmd_select_begin()
					self:cmd_select_end()
					self:cmd_enter_module(b1)
				end
			end
		end
	else
		Tip()
		if not self.enableOpenLib then return end
		local callback = function()
			self.ui.visible = false
			self:showBricksUI()
		end
		_G:holdbackScreen(self.timer, callback)
	end
end

local clickid = nil
BuildBrick.onDown = function(self, b, x, y)
	-- print('BuildBrick.onDown', b, x, y)
	clickid = b
	if b ~= 0 then return end

	-- 处理未处理的up事件
	if self.moveX and self.moveY and self.onupfunc then
		self:onupfunc(x, y, false)
		self.moveX, self.moveY = nil, nil
	end

	self.downX, self.downY = x, y
	if self.ondownfunc then
		self:ondownfunc(x, y)
	end
end

BuildBrick.onMove = function(self, x, y, fid, count)
	if clickid == 1 or clickid == 2 then
		self:building_moveEnd(x, y)
		self:camera_down(0, x, y)
		self:camera_move(x, y, fid)
		return
	end
	if self.rt_block == nil and self.rt_selectedPart == nil and not self.unbindingpart then
		if self.dragSelecting and clickid == 0 and (not count or count == 1) then

			--print('onMove!!!!!!!!!!', x, y, fid, count)
			self.dragSelect:onMouseDown(0, x, y)
			self.dragSelect:onMouseMove(x, y)
			return
		end

		self:camera_down(0, x, y)
		self:camera_move(x, y, fid)
		self:cmd_select_cancel()
	else
		if clickid ~= 0 then return end

		self.moveX, self.moveY = x, y
		if self.onmovefunc then
			self:onmovefunc(x, y)
		end
	end
end

local clicktick = 0
local lastb
BuildBrick.onUp = function(self, b, x, y, fid, count)
	local dt = 100000
	if lastb == b then
		dt = _tick() - clicktick
	end
	clicktick = _tick()
	lastb = b

	-- print('!!!!onUp', b, x, y, clickid, self:camera_up())

	if self:camera_up() then
		clicktick = 0
		return
	end

	if b ~= 0 then return end

	if self.rt_block == nil then
		if b == 0 and self.dragSelecting and self.dragSelect:onMouseUp(0, x, y) then
			local gs = self.dragSelect.gs
			for i, g in ipairs(gs) do
				g:setTempRoot(true)
			end
			self:atom_group_select_batch(gs)
			clicktick = 0
			return
		end
		-- self:camera_unfocus()
	end

	local dbclick = false
	if dt < 500 then
		dbclick = true
	end

	-- print('!!!!onUp2', b, x, y)
	if self.onupfunc and self:onupfunc(x, y, dbclick) then
		clicktick = 0
	end
	self.downX, self.downY = nil, nil
	self.moveX, self.moveY = nil, nil
end

BuildBrick.getDungeonAABB = function(self, b, ab)
	b:getAlignedShapeAABB(ab, nil, 0.8)
end

BuildBrick.isSelectedHasDungeon = function(self, bs)
	bs = bs or self.rt_selectedBlocks
	for i, b in ipairs(bs or {}) do
		if b:isDungeonBlock(true) then
			return true
		end
	end
end

local tipfont = _Font.new('Comic Sans MS', 40, 0, 0, 4, 100)
local drawAABB = _AxisAlignedBox.new()
local bgBlender = _Blender.new()
bgBlender:blend(0xffffff00)
local dungeonBlender = _Blender.new()
dungeonBlender:blend(0xff00ff00)
local redBlender = _Blender.new()
redBlender:blend(0xffff0000)

--TODO 111
BuildBrick.drawPlaneZ = function(self, z)
	local scene2D = self.mode == 'buildscene' and self:getParam('scenemode') == 'scene_2D'
	if self.mode == 'buildanima' then
		DrawHelper.drawPlaneZ({w = 6.4, h = 6.4}, 0.2, z, 0x40ffffff, 0x44ffffff)
		_rd:fill3DTriangle(-0.6, -3.2, z, 0.6, -3.2, z, 0, -4, z, 0x44ffffff)
	elseif scene2D then
		DrawHelper.drawPlaneY({w = 13.01, h = 19.21}, 0.2, z, 0x0Dffffff, 0x44ffffff)
		_rd:fill3DTriangle(-1.2, -3.2, z, 1.2, -3.2, z, 0, -4.4, z, 0x44ffffff)

	else
		DrawHelper.drawPlaneZ({w = 13.01, h = 9.61}, 0.2, z, 0x0Dffffff, 0x44ffffff)
		_rd:fill3DTriangle(-1.2, -3.2, z, 1.2, -3.2, z, 0, -4.4, z, 0x44ffffff)
	end

	if self.hideTerrain then
		_rd:drawAxis(0.6)
	end

	local gs = {}
	self:getGroups(gs)
	for i, g in ipairs(gs) do
		if not g:getParent(true) or g:isLock() then

			-- 处理dirty标记
			if g.isdirty or (not g.aabb) then
				g:getAABB()
			end
--[[
			if self.showHelperAABB then
				--local aabb = Container:get(_AxisAlignedBox)
				local aabb = drawAABB
				aabb:set(g:getAABB())

				local selgroups = {}
				for i, g in ipairs(self.rt_selectedGroups) do
					g:getConnects(selgroups)
				end

				local s = 0.003
				aabb.min.x, aabb.min.y, aabb.min.z = aabb.min.x - s, aabb.min.y - s, aabb.min.z - s
				aabb.max.x, aabb.max.y, aabb.max.z = aabb.max.x + s, aabb.max.y + s, aabb.max.z + s
				local color = _Color.Yellow
				if selgroups[g] then
					color = _Color.Red
				elseif g[1] and g[1].part then
					color = _Color.Green
				elseif g:isLock() then
					color = _Color.Black
				end
				aabb:draw(color)
				-- Container:returnBack(aabb)
			end
--]]
		end
	end

	if self.mode == 'buildscene' then
		local nbs = {}
		self:getBlocks(nbs)
		for i, b in ipairs(nbs) do
			if b:isDungeonBlock(true) then
				if b.isDungeonBg then
					self:getDungeonAABB(b, drawAABB)
					DrawHelper.drawEdgeBox(drawAABB, bgBlender)
				else
					self:getDungeonAABB(b, drawAABB)
					DrawHelper.drawEdgeBox(drawAABB, dungeonBlender)
				end
			-- elseif b.musicdummy then

			end
		end

		if self.music_dummys then
			for b in pairs(self.music_dummys) do
				b:getShapeAABB(drawAABB)
				DrawHelper.drawEdgeBox(drawAABB, redBlender)
			end
		end
	end

	if self.showHelperAABB then
		self.userAABB:draw(_Color.Red)
		self.bgAABB:draw(_Color.Yellow)
	end

	if Global.showKnots then
		for i, g in ipairs(gs) do
			if not g.parent then
				local kg = g:getKnotGroup()
				local ks = {}
				kg:getKnots(0, ks)
				for _, k in ipairs(ks) do
					KnotManager.drawKnot(k)
				end
			end
		end
	end

	if self.enableRepair then
		local cam = _rd.camera
		local v3 = _Vector3.new()
		_Vector3.sub(cam.eye, cam.look, v3)
		if v3:magnitude() > 15 then
			_rd.edgeBias = 0
		else
			_rd.edgeBias = 0.001
		end

		_rd.postEdgeOutOnly = true
		--print('v3', v3:magnitude(), v3)
	end

	if self.dragSelecting then
		self.dragSelect:render()
	end

	if self.edit_group then
		local nbs = {}
		self:getBlocks(nbs)
		local ab = Container:get(_AxisAlignedBox)
		Block.getAABBs(nbs, ab)
		ab:expand(0.1, 0.1, 0.1)
		ab.min.z = math.max(self.planeZ, ab.min.z)
		DrawHelper.drawCornnerBox2(ab)
		Container:returnBack(ab)
	end

	if self:isBuildScene() then
		--tipfont:drawText(0, 0, _rd.w, 300, '场景编辑中....', _Font.hCenter + _Font.vCenter)
	else
		if #self.rt_selectedBlocks > 0 and not self.enableRepair and not self.isPlayingDframe then
			local aabb = Container:get(_AxisAlignedBox)
			for i, v in ipairs(self.rt_selectedBlocks) do
				v:getAABB(aabb)
				local x1 = aabb.min.x
				local x2 = aabb.max.x
				local y1 = aabb.min.y
				local y2 = aabb.max.y
				local w = self.mode == 'buildanima' and 6.4 or 13.01
				local h = self.mode == 'buildanima' and 6.4 or 9.61
				x1 = x1 <= -w and -w or x1
				x1 = x1 >= w and w or x1
				x2 = x2 <= -w and -w or x2
				x2 = x2 >= w and w or x2
				y1 = y1 <= -h and -h or y1
				y1 = y1 >= h and h or y1
				y2 = y2 <= -h and -h or y2
				y2 = y2 >= h and h or y2
				if x1 < x2 and y1 < y2 then
					DrawHelper.drawShadowZ({x1 = x1, x2 = x2, y1 = y1, y2 = y2}, 0.1, z, 0xff888888)
				end
			end
			Container:returnBack(aabb)
		end
	end
	-- local animrole = Global.AnimationManager:getRole(self)
	-- if animrole then animrole:draw() end
end

BuildBrick.update = function(self, e)
	if self.DFPlayer then
		self.DFPlayer:update(e)
	end

	self:camera_update()
end
BuildBrick.render = function(self)
	if self.isshowInterlude then return end
	self:drawPlaneZ(self.planeZ + 0.005)
	--self:updateRotHint()
	self:renderRotDB()
	self:renderMarkerHint()
	self:DrawHint()

	self:drawPart()
	if self.showPickHelper then
		Global.PickHelper:render()
	end
end

BuildBrick.createPfxDummy = function(self, filename, bindblock, transform)
	local pfx = bindblock:playBindPfx(filename, nil, transform)
	return pfx
end

BuildBrick.stopPfxDummy = function(self, b)
	if not b:hasBindPfx() then return end
	b:stopBindPfx()
	return true
end

BuildBrick.rotPfxDummy = function(self, b, type)
	print('rotPfxDummy', b:hasBindPfx(), type)
	if not b:hasBindPfx() then return end
	local pfx = b.bindpfxs[#b.bindpfxs].pfx
	local mat = pfx.transform
	local p = mat.parent
	mat.parent = nil
	mat:updateTransformValue()
	if type == Global.AXISTYPE.Z then
		mat.rotationB = mat.rotationB + math.pi / 2
	elseif type == Global.AXISTYPE.Y then
		mat.rotationH = mat.rotationH + math.pi / 2
	elseif type == Global.AXISTYPE.X then
		mat.rotationP = mat.rotationP + math.pi / 2
	end

	mat:updateTransform()
	mat.parent = p
end

BuildBrick.movePfxDummy = function(self, b, diff)
	print('movePfxDummy', b:hasBindPfx(), diff)
	if not b:hasBindPfx() then return end
	local pfx = b.bindpfxs[#b.bindpfxs].pfx
	local mat = pfx.transform
	local p = mat.parent
	mat.parent = nil
	mat:updateTransformValue()
	mat.translationX = mat.translationX + diff.x
	mat.translationY = mat.translationY + diff.y
	mat.translationZ = mat.translationZ + diff.z
	mat:updateTransform()
	mat.parent = p
end

BuildBrick.scalePfxDummy = function(self, b, add)
	print('scalePfxDummy', b:hasBindPfx(), add)
	if not b:hasBindPfx() then return end
	local pfx = b.bindpfxs[#b.bindpfxs].pfx
	local mat = pfx.transform
	local p = mat.parent
	mat.parent = nil
	mat:updateTransformValue()
	local newscale
	if add then
		newscale = mat.scaleX + 0.125
		if newscale > 4 then newscale = 4 end
	else
		newscale = mat.scaleX - 0.125
		if newscale < 0.125 then newscale = 0.125 end
	end
	mat.scaleX, mat.scaleY, mat.scaleZ = newscale, newscale, newscale
	mat:updateTransform()
	mat.parent = p
end

BuildBrick.addGraffitiToBlock = function(self, img)
	if not self.rt_selectedBlocks or #self.rt_selectedBlocks == 0 or #self.rt_selectedBlocks > 1 then return end
	local b = self.rt_selectedBlocks[1]
	if b then
		self:atom_paint_add(b, img)
		local paintmeshs = b:getPaintMeshs()
		if #paintmeshs > 0 then
			self.enableGraffiti = true
			self:onSelectGroup(self.rt_selectedGroups)
		else
			self.enableGraffiti = false
			self:onSelectGroup()
		end
	else
		self.enableGraffiti = false
	end
end

-- BuildBrick.showFuncflaglistUI = function(self, show)
-- 	if not show then show = false end

-- 	local ui = self.ui.funclist
-- 	ui.onRenderItem = function(index, item)
-- 		item.flagname.text = self.FuncFlags[index].funcname
-- 		item.click = function()
-- 			self.FuncFlags[index].func()
-- 		end
-- 	end

-- 	ui.itemNum = #self.FuncFlags
-- 	self.ui.funclist.visible = show
-- 	self.showfuncflagui = show
-- end

BuildBrick.setBlockLogicGroup = function(self, b, group, state)
	if state then
		if not b.logic_names then b.logic_names = {} end
		b.logic_names[group] = true
	else
		if not b.logic_names then return end
		b.logic_names[group] = nil
	end
end

BuildBrick.showLogicGroupList = function(self, show)
	local ui = self.ui.actionlist
	ui.visible = show
	if not show then return end

	local bs = self.rt_selectedBlocks
	local aabb = Container:get(_AxisAlignedBox)
	Block.getAABBs(bs, aabb)
	aabb:getCenter(b_pos)
	_rd:projectPoint(b_pos.x, b_pos.y, b_pos.z, ui_pos)
	local isright = ui_pos.x < _rd.w / 2
	Container:returnBack(aabb)

	local x = 250
	ui._x = isright and self.ui._width - ui._width - x or x
	ui:addRelation(self.ui, isright and _FairyManager.Right_Right or _FairyManager.Left_Left)
	ui.sortingOrder = 100
	ui.isloop.visible = false
	ui.ispair.visible = true -- #bs == 2

	ui.ispair.loop.selected = #bs == 2 and self.pairBlocks[bs[1]] == bs[2]
	ui.ispair.loop.click = function()
		if #bs == 2 and self.pairBlocks[bs[1]] == nil and self.pairBlocks[bs[2]] == nil then
			self.pairBlocks[bs[1]] = bs[2]
			self.pairBlocks[bs[2]] = bs[1]
			ui.ispair.loop.selected = true
		else
			for i, b in ipairs(bs) do
				self.pairBlocks[b] = nil
			end
			ui.ispair.loop.selected = false
		end
	end

	local cfg_lgs = _G.BLOCK_LOGIC_NAMES
	ui.list.onRenderItem = function(index, item)
		local n = cfg_lgs[index].type
		item.icon._icon = cfg_lgs[index].icon

		local sel = true
		for _, b in ipairs(bs) do
			if not b.logic_names or not b.logic_names[n] then
				sel = false
				break
			end
		end
		item.selbg2.visible = sel

		item.click = function()
			item.selbg2.visible = not item.selbg2.visible
			local state = item.selbg2.visible
			for _, b in ipairs(bs) do
				self:setBlockLogicGroup(b, n, state)
			end
		end
	end

	ui.list.itemNum = #cfg_lgs

	self:showDisableBg(true, function()
		self:showDisableBg(false)
		self:showLogicGroupList()
	end)
end

-- see tool\saveItemlvToMesh\main.lua
local CombineItemToMesh = function(shapeid)
	local sen = _Scene.new'browserbg.sen'
	sen.groups = {}
	sen.blocks = {}
	sen.blockuis = {}
	for k, v in next, Global.Scene do
		sen[k] = v
	end

	local ei = _G.enableInsMaterial
	local rm = _G.RECORDMATERIAL
	local c = _sys.cache
	_G.enableInsMaterial = false
	_G.RECORDMATERIAL = true
	_sys.cache = false

	local block = sen:createBlock({shape = shapeid})
	local mesh = block.mesh
	local splitmeshs = {}
	local submeshs = {}
	mesh:getSubMeshs(submeshs)

	-- 材质分类可合并得模型
	for _, m in pairs(submeshs) do
		assert(m.material, 'must have mtl')
		if m.material then
			local mtlname = _sys:getFileName(m.material.resname, false, false)
			local normalmapid = Global.LightNormalReflect[toint(m.name)] or 'none'
			local mtlkey = mtlname .. ',' .. normalmapid

			if not splitmeshs[mtlkey] then splitmeshs[mtlkey] = {} end
			table.insert(splitmeshs[mtlkey], m)
		end
	end

	-- 合并子模型
	local result = {}
	for mtlkey, ms in pairs(splitmeshs) do
		local cm = #ms > 1 and _mf:combineMesh(ms) or ms[1] -- todo combine failed.
		cm.material = nil
		cm.name = mtlkey
		table.insert(result, cm)
	end

	-- 重组mesh
	mesh:clearSubMeshs()
	for _, m in pairs(result) do
		mesh:addSubMesh(m)
	end

	mesh:save('./mtlRecord/'..shapeid..'.msh')

	_G.enableInsMaterial = ei
	_G.RECORDMATERIAL = rm
	_sys.cache = C

	--todo check combined mesh valid. write version cfg
end

local bb = BuildBrick.new()
Global.BuildBrick = bb

BuildBrick.FuncFlags = {
	{funcname = '物理剔除:组(H)', func = function()
		if Global.rt_selectedBlocks then
			for i, v in ipairs(bb.rt_selectedBlocks) do
				local culling = v:isPhyxCulliing()
				v:setPhyxCulliing(not culling)
			end
		end
	end},
	{funcname = '物理剔除:块(J)', func = function()
		if bb.rt_block then
			local v = bb.rt_block
			local culling = v:isPhyxCulliing()
			v:setPhyxCulliing(not culling)
		end
	end},
}

local kevents = {
	{
		-- 拷贝
		k = _System.KeyC,
		title = 'Ctrl+C',
		ui = {{'copybutton'}},
		release = true,
		func = function()
			if _sys:isKeyDown(_System.KeyCtrl) then
				local self = bb
				if self.dfEditing and self.currentDframe and self.ui.dfs.visible then
					self.ui.dfs.copybutton.click()
				else
					self:cmd_copy()
				end
			end
		end
	},
	{
		-- 打印积木数量
		k = _System.KeyT, 
		func = function()
			print(Global.calcBrickCount(bb.modules))
		end
	},
	{
		k = _System.KeyL,
		func = function()
			for i, g in ipairs(bb.rt_selectedGroups) do
				g:setDeadLock(false)
			end
			bb:cmd_merge_lock()
		end
	},
	{
		-- 撤销
		k = _System.KeyZ,
		title = 'Ctrl+Z',
		ui = {{'btn_undo'}},
		release = true,
		func = function()
			if _sys:isKeyDown(_System.KeyCtrl) then
				bb:undo()
			end
		end
	},
	{
		-- 取消撤销
		k = _System.KeyY,
		title = 'Ctrl+Y',
		ui = {{'btn_redo'}},
		release = true,
		func = function()
			if _sys:isKeyDown(_System.KeyCtrl) then
				bb:redo()
			end
		end
	},
	{
		--删除
		k = _System.KeyDel,
		title = 'Delete',
		ui = {{'module_del'}, {'graffiti_del'}},
		release = true,
		func = function()

			local self = bb
			if self.dfEditing and self.currentDframe then
				self.ui.dfs.delbutton.click()
			else
				self.ui.module_del.click()
			end
		end
	},
	{
		k = _System.KeyW,
		title = 'W',
		ui = {{'movePlane', 'up'}, {'movePlane1', 'up'}},
		release = true,
		func = function()
			if #bb.rt_selectedBlocks > 0 then
				if bb.moveUI == nil or bb.moveUI.visible == false then return end
				bb.moveUI.up.click()
			end
		end
	},
	{
		k = _System.KeyA,
		title = 'A',
		ui = {{'movePlane', 'left'}, {'movePlane1', 'left'}},
		release = true,
		func = function()
			if _sys:isKeyDown(_System.KeyCtrl) then
				bb.ui.multiSelectPanel.all.click()
			else
				if #bb.rt_selectedBlocks > 0 then
					if bb.moveUI == nil or bb.moveUI.visible == false then return end
					bb.moveUI.left.click()
				end
			end
		end
	},
	{
		k = _System.KeyD,
		title = 'D',
		ui = {{'movePlane', 'right'}, {'movePlane1', 'right'}},
		release = true,
		func = function()
			if #bb.rt_selectedBlocks > 0 then
				if bb.moveUI == nil or bb.moveUI.visible == false then return end
				bb.moveUI.right.click()
			end
		end
	},
	{
		k = _System.KeyLeft,
		title = '←',
		ui = {{'3btn1'}},
		release = true,
		func = function()
			if bb.rotHintUIs == nil or not bb.showrot then return end
			local btn = bb.rotHintUIs[3].btn1
			if btn.visible == false then return end

			local x = btn._x + btn._width / 2
			local y = btn._y + btn._height / 2
			btn.onMouseDown({mouse = {x = x, y = y}})
			btn.onMouseUp({mouse = {x = x, y = y}})
		end
	},
	{
		k = _System.KeyRight,
		title = '→',
		ui = {{'3btn2'}},
		release = true,
		func = function()
			if bb.rotHintUIs == nil or not bb.showrot then return end
			local btn = bb.rotHintUIs[3].btn2
			if btn.visible == false then return end

			local x = btn._x + btn._width / 2
			local y = btn._y + btn._height / 2
			btn.onMouseDown({mouse = {x = x, y = y}})
			btn.onMouseUp({mouse = {x = x, y = y}})
		end
	},
	{
		k = _System.KeyUp,
		title = '↑',
		ui = {{'1btn1'}, {'2btn1'}},
		release = true,
		func = function()
			if bb.rotHintUIs == nil or not bb.showrot then return end
			local btn1, btn2 = bb.rotHintUIs[1].btn1, bb.rotHintUIs[2].btn1
			local btn
			if btn1.visible and btn2.visible then
				local cdirh = math.abs(Global.CameraControl.current:getDirH())
				btn = (cdirh > math.pi / 4 and cdirh < 3 * math.pi / 4) and btn1 or btn2
			elseif btn1.visible then
				btn = btn1
			elseif btn2.visible then
				btn = btn2
			end
			if not btn then return end

			local x = btn._x + btn._width / 2
			local y = btn._y + btn._height / 2
			btn.onMouseDown({mouse = {x = x, y = y}})
			btn.onMouseUp({mouse = {x = x, y = y}})
		end
	},
	{
		k = _System.KeyDown,
		title = '↓',
		ui = {{'1btn2'}, {'2btn2'}},
		release = true,
		func = function()
			if bb.rotHintUIs == nil or not bb.showrot then return end
			local btn1, btn2 = bb.rotHintUIs[1].btn2, bb.rotHintUIs[2].btn2
			local btn
			if btn1.visible and btn2.visible then
				local cdirh = math.abs(Global.CameraControl.current:getDirH())
				btn = (cdirh > math.pi / 4 and cdirh < 3 * math.pi / 4) and btn1 or btn2
			elseif btn1.visible then
				btn = btn1
			elseif btn2.visible then
				btn = btn2
			end
			if not btn then return end

			local x = btn._x + btn._width / 2
			local y = btn._y + btn._height / 2
			btn.onMouseDown({mouse = {x = x, y = y}})
			btn.onMouseUp({mouse = {x = x, y = y}})
		end
	},
	{
		--暂停
		k = _System.KeyF,
		func = function()
			if _sys:isKeyDown(_System.KeyCtrl) then
				local g = bb.rt_selectedGroups[1]
				if g then
					local center = _Vector3.new()
					local ab = g:getAABB()
					ab:getCenter(center)
					local c = bb:getCameraControl()
					c:moveLook(center)
				end
			else
				bb:pauseAnim()
			end
		end
	},
	{
		k = 191, -- '/'
		func = function()
			local self = bb
			self.disableDelta = not self.disableDelta
			print('解除颜色限制：', self.disableDelta)

			local uiprop = self.uiprop
			if uiprop then
				local uirslider = uiprop.mtlplane.rslider
				local uihsl = uiprop.mtlplane.hsl

				uirslider.deltaNum = self.disableDelta and 0 or 8
				uihsl.hue.deltaNum = self.disableDelta and 0 or 20
				uihsl.saturation.deltaNum = self.disableDelta and 0 or 20
				uihsl.lightness.deltaNum = self.disableDelta and 0 or 20
			end
		end
	},
	{
		--剔除动画保存
		k = _System.KeyG,
		func = function()
			local self = bb
			if _sys:isKeyDown(_System.KeyCtrl) then
				local savename = _sys:saveFile('.itemlv')
				if _sys:getExtention(savename) ~= 'itemlv' then savename = savename .. '.itemlv' end
				local openfilename = _sys:getFileName(savename)
				if not openfilename or openfilename == '' then return end

				-- 先保存当前场景
				local enablepart = self.enablePart
				self.enablePart = false
				self:saveSceneToModule(self:getModule())
				self:saveToFile(openfilename)
				local itemid = _sys:getFileName(openfilename, false, false)
				Global.Capture:addNode(itemid)
				self.enablePart = enablepart
			end
		end
	},
	{
		--保存
		k = _System.KeyS,
		title = 'S',
		ui = {{'movePlane', 'down'}, {'movePlane1', 'down'}},
		release = true,
		func = function()
			if ENABLE_KEY and _sys:isKeyDown(_System.KeyCtrl) and not _sys:isKeyDown(_System.KeyShift) then
				if bb:isBuildScene() then
					local savename = _sys:saveFile('.lv')
					local ext = _sys:getExtention(savename)
					local senname = _sys:getFileName(savename, true, false)
					if ext == 'lv' then
						bb:savelvdata(senname)
					else
						bb:autoSaveBefore()
						bb:saveSceneToModule(bb:getModule())
						bb:autoSaveAfter()
						bb:saveToFile(senname)
					end
				else
					if bb:getParam('autoBlueprint') and bb.mode == 'buildrepair' then
						local module = {
							version = 1,
							scale = 1,
							blocks = {},
							groups = {},
							parts = {},
						}
						bb:saveSceneToModule(module)

						for g in pairs(bb.repair_dels) do
							if not g.repairGroup then
								local bs = {}
								g:getBlocks(bs)
								bb:atom_block_del_s(bs)
							end
						end
						bb.repair_dels = {}
						for g in pairs(bb.repair_adds) do
							if not g.repairBlock then
								local bs = {}
								g:getBlocks(bs)
								bb:atom_block_del_s(bs)
							end
						end
						bb.repair_adds = {}

						local n = #module.blocks
						if n == 0 then
							local fs = {}
							local folder = 'res\\env\\repair'
							local repairName = bb.buildrepairName
							for i, m in ipairs(bb.buildrepairModules) do
								local f =repairName .. '_blueprint_' .. i
								--bb:saveToFile(filename)
								--local str = Global.saveBlock2String(m)
								_File.writeString(f .. '.itemlv', Global.saveBlock2String(m), 'utf-8', folder)
								table.insert(fs, f)
							end

							local str = repairName .. ' = {\n'
							for i, f in ipairs(fs) do
								str = str .. string.format('\t{name = \'%s\'},\n', f)
							end
							str = str .. string.format('\tachievement_blueprint = \'unlock_bp_%s\',\n', repairName)
							str = str .. string.format('\tachievement_object = \'unlock_%s\',\n', repairName)
							str = str .. string.format('\tname = \'%s\',\n', repairName)
							str = str .. '},\n'
							local filename = repairName .. '_blueprint.txt'
							_File.writeString(filename, str, 'utf-8', folder)
							Notice(string.format('保存蓝图(%s) : %d', repairName, #bb.buildrepairModules))
						else
							table.insert(bb.buildrepairModules, 1, module)
							Notice(string.format('保存蓝图步骤: %d 数量(%d)', #bb.buildrepairModules, n))
						end
						return
					end
					local savename = _sys:saveFile('.itemlv')
					if _sys:getExtention(savename) ~= 'itemlv' then savename = savename .. '.itemlv' end
					local openfilename = _sys:getFileName(savename)
					if not openfilename or openfilename == '' then return end

					-- 先保存当前场景
					bb:autoSaveBefore()
					bb:saveSceneToModule(bb:getModule())
					bb:autoSaveAfter()
					bb:saveToFile(openfilename)
					local itemid = _sys:getFileName(openfilename, false, false)
					Global.Capture:addNode(itemid, nil, nil, nil, nil, nil, nil, nil, true, nil, 0)
					--Global.Capture:addNode(itemid, nil, nil, nil, nil, nil, nil, nil, true, nil, 2)
					if Global.CombineItemToMesh then
						CombineItemToMesh(itemid)
					end
				end
			elseif ENABLE_KEY and _sys:isKeyDown(_System.KeyShift) and not _sys:isKeyDown(_System.KeyCtrl) then
				local exporter = _require('Exporter.SceneToMaxExporter')
				-- 保存成模型文件 但是子模型太多了
				local openfilename = _sys:getFileName(_sys:saveFile('.obj'))
				if openfilename == nil or openfilename == '' then return end

				local blocks = {}
				bb:getBlocks(blocks)
				print('#blocks', #blocks)

				local blockts = {}
				local blockgs = {}
				for i, v in ipairs(blocks) do
					local material = v:getMaterialBatch()
					if material then
						local mtlidts = blockts[material.material]
						if mtlidts == nil then
							mtlidts = {}
							blockts[material.material] = mtlidts
						end
						local coloridts = mtlidts[material.color]
						if coloridts == nil then
							coloridts = {}
							mtlidts[material.color] = coloridts
						end
						local roughnessts = coloridts[material.roughness]
						if roughnessts == nil then
							roughnessts = {}
							coloridts[material.roughness] = roughnessts
						end
						local mtlmodets = roughnessts[material.mtlmode]
						if mtlmodets == nil then
							local materialres = v.node.mesh.material
							table.insert(blockgs, {blocks = {}, mtl = materialres, name = material.material .. '_' .. material.color .. '_' .. material.roughness .. '_' .. material.mtlmode})
							mtlmodets = {index = #blockgs}
							roughnessts[material.mtlmode] = mtlmodets
						end
						table.insert(blockgs[mtlmodets.index].blocks, v)
					else
						print('shape', v.data.shape)
					end
				end

				local bnumber = 0
				local scene = _Scene.new()
				for _, g in ipairs(blockgs) do
					local combinegroup = {{}}
					local combineindex = 1
					local totalvertex = 0
					local mtl = g.mtl
					for i, v in ipairs(g.blocks) do
						local vertex = v.node.mesh:getVertexCount()
						totalvertex = totalvertex + vertex
						if totalvertex > 65535 then
							table.insert(combinegroup, {})
							combineindex = combineindex + 1
							totalvertex = vertex
						end
						v.node.mesh.temptransform = _Matrix3D.new()
						v.node.mesh.temptransform:set(v.node.mesh.transform)
						v.node.mesh.transform:mulLeft(v.node.transform)
						table.insert(combinegroup[combineindex], v.node.mesh)
						bnumber = bnumber + 1
					end
					for i, v in ipairs(combinegroup) do if v[1] then
						local m
						if #v > 1 then
							m = _mf:combineMesh(v)
							m.material = mtl
							scene:add(m)
						else
							m = v[1]
							m.material = mtl
							scene:add(v[1])
						end

						--material:save('./mtlRecord/' .. name)
						-- print('saveobj', _, i, m, m.material and m.material.resname, mtl and mtl.resname)
						-- m:enumMesh('', true, function(sub)
							-- print(' sub', sub, sub.material and sub.material.resname)
						-- end)
						m:save('./mtlRecord/m' .. _ .. '_' .. i .. '.msh')
					end end
				end
				print('block number:', bnumber)
				exporter:export(scene, _sys:getFileName(openfilename, false, false) .. '.obj')
				print('Node count', #exporter.exportNodes)
				while #exporter.exportNodes > 0 do
					exporter:onExporting()
				end

				for _, g in ipairs(blockgs) do
					for i, v in ipairs(g.blocks) do
						v.node.mesh.transform:set(v.node.mesh.temptransform)
						v.node.mesh.temptransform = nil
					end
				end
			else
				if #bb.rt_selectedBlocks > 0 then
					if bb.moveUI == nil or bb.moveUI.visible == false then return end
					bb.moveUI.down.click()
				end
			end
		end
	},
	{
		-- 打开物品，并拆分未积木块
		k = _System.KeyO,
		func = function()
			if _sys:isKeyDown(_System.KeyCtrl) then
				local filename = _sys:openFile('*.itemlv', '*.lv')
				local ext = _sys:getExtention(filename)
				if ext == 'itemlv' then
					local shapeid = _sys:getFileName(filename, false, false)
					bb:load_block_only(shapeid)
					bb.istemplate = true

					if bb:getParam('autoBlueprint') and bb.mode == 'buildrepair' and shapeid ~= '' then
						bb:setParam('buildrepairName', shapeid)
						bb.buildrepairModules = {}
					end
				else
					local senname = _sys:getFileName(filename, false, false)
					bb:loadlvdata(senname, true)
					bb.istemplate = true
				end
			end
		end
	},
	{
		-- 打开物品，并把当前物品打成一个组
		k = _System.KeyP,
		func = function()
			if _sys:isKeyDown(_System.KeyCtrl) then
				if not bb:isBuildScene() then
					local filename = _sys:openFile('*.itemlv', '*.lv')
					local ext = _sys:getExtention(filename)
					if ext == 'itemlv' then
						local shapeid = _sys:getFileName(filename, false, false)
						local data = Block.loadItemData(shapeid)
						if data then
							local nbs, g = bb:dragModuleToScene(data, true)
							if g then
								g:setLock(true)
							end
						end
					elseif ext == 'lv' then
						local senname = _sys:getFileName(filename, false, false)
						bb:loadbglv(senname.. '.lv')
					end
				else
					local filename = _sys:openFile('*.itemlv')
					local shapeid = _sys:getFileName(filename, false, false)
					--Global.sen:createBlock({shape = shapeid})
					bb:addBlock(shapeid)
				end
			end
		end
	},
	{
		-- 显示包围盒
		k = _System.Key0,
		func = function()
			Global.CombineItemToMesh = not Global.CombineItemToMesh
			print('Global.CombineItemToMesh', Global.CombineItemToMesh)
		end
	},
	{
		-- 显示包围盒
		k = _System.Key1,
		func = function()
			bb.showHelperAABB = not bb.showHelperAABB
		end
	},
	{
		-- 隐藏地表，且在保存时会取消物件居中的效果
		k = _System.Key2,
		func = function()
			bb.hideTerrain = not bb.hideTerrain
			bb.noCenter = bb.hideTerrain
			local nodes = {}
			Global.sen:getNodes(nodes)
			for i, node in ipairs(nodes) do
				if not node.block or (node.block and node.block.isWall) then
					node.visible = not bb.hideTerrain
				end
			end
		end
	},
	{
		-- 选中的组居中并放在地表下
		k = _System.Key3,
		func = function()
			local self = bb
			if self.rt_selectedGroups[1] then
				local aabb = self.rt_selectedGroups[1]:getAABB()
				local center = _Vector3.new()
				aabb:getCenter(center)

				self:cmd_mat_update_begin(nil, 'move')
				self.rt_transform:mulTranslationRight(-center.x, -center.y, -aabb.max.z)
				self:cmd_mat_update_end(nil, 'move')
			end
		end
	},
	{
		-- planeZ 开关
		k = _System.Key4,
		func = function()
			local self = bb
			-- self.enableAutoPlaneZ = not self.enableAutoPlaneZ
			-- if self.enableAutoPlaneZ then
			-- 	self:onBrickChange()
			-- else
			-- 	self:setPlaneZ(0)
			-- end

			self.knotMode = self.knotMode + 1
			if self.knotMode > 2 then
				self.knotMode = 0
			end

			print('self.knotMode', self.knotMode)
		end
	},
	{
		-- 调试功能，显示放置信息
		k = _System.Key5,
		func = function()
			bb.showPickHelper = not bb.showPickHelper
		end
	},
	{
		-- 删除包围盒外的积木(可通过调整s改变包围盒尺寸)
		k = _System.Key6,
		func = function()
			local ab = _AxisAlignedBox.new()
			local s = 40
			ab.min.x, ab.min.y, ab.min.z = -s, -s, -s
			ab.max.x, ab.max.y, ab.max.z = s, s, s
			local bs = {}
			bb:getBlocks(bs, function(b)
				if b.node then
					local pos = _Vector3.new()
					b.node.transform:getTranslation(pos)
					if not ab:checkInside(pos) then
						return true
					end
				end
			end)

			for i, v in ipairs(bs) do
				bb:atom_block_del(v)
			end

			bb:refreshModuleIcon()
		end
	},
	{
		-- 取消选中
		k = _System.Key7,
		func = function()
			-- print('========取消选中', #bb.rt_selectedBlocks)
			for i, b in ipairs(bb.rt_selectedBlocks) do
				--b:setPickFlag(Global.CONSTPICKFLAG.WALL)
				-- b:setPickFlag(Global.CONSTPICKFLAG.NONE)
			end
		end
	},
	{
		-- 固定包围盒
		k = _System.Key8,
		func = function()
			local self = bb
			self.userAABBLocked = not self.userAABBLocked
			if not self.userAABBLocked then self:onBrickChange() end
			print('包围盒锁定：', self.userAABBLocked)
		end
	},
	{
		-- 编辑动画时是否可以绑定部位
		k = _System.Key9,
		func = function()
			local self = bb
			self.disableBindPart = not self.disableBindPart
			self:showTopButtons()
			print('允许绑定：', not self.disableBindPart)
		end
	},
	{
		k = 189, -- '-'
		func = function()
			-- local self = bb
			-- for i, v in ipairs(bb.rt_selectedBlocks) do
			-- 	v.node.visible = false
			-- 	v.temphide = true
			-- end

			-- -- 打印隐藏数量
			-- local bn = 0
			-- local nbs = {}
			-- self:getBlocks(nbs)
			-- local gs = {}
			-- for i, v in ipairs(nbs) do
			-- 	if v.temphide then
			-- 		local g = v:getBlockGroup('root')
			-- 		gs[g] = true
			-- 		bn = bn + 1
			-- 	end
			-- end

			-- local gn = 0
			-- for g in pairs(gs) do
			-- 	gn = gn + 1
			-- end
			-- print('当前隐藏数量:', gn, bn)
		end
	},
	{
		k = 187, -- '='
		func = function()
			-- local self = bb
			-- local nbs = {}
			-- self:getBlocks(nbs)
			-- for i, v in ipairs(nbs) do
			-- 	if v.temphide then
			-- 		v.node.visible = true
			-- 		v.temphide = nil
			-- 	end
			-- end
		end
	},
	{
		k = _System.KeyM,
		func = function()
			if _sys:isKeyDown(_System.KeyCtrl) then
				local self = bb
				if not self.enablePart then return end
				-- 保持左右部件对称
				self:mirrorPart()
			else
				-- 显示/隐藏平移操作按钮
				bb.ui.selectmode.visible = not bb.ui.selectmode.visible
			end
		end
	},
	{
		-- 重新加载场景中的graData
		k = _System.KeyB,
		func = function()
			_sys.cache = false
			local sen = _Scene.new(Global.sen.resname)
			_sys.cache = true
			local ps = {}
			Global.sen.graData:getLights(ps)
			for i, v in ipairs(ps) do
				if v.typeid == _PointLight.typeid then
					Global.sen:delLight(v)
				end
			end
			sen.graData:getLights(ps)
			for i, v in ipairs(ps) do
				if v.typeid == _PointLight.typeid then
					sen:delLight(v)
				end
			end
			Global.sen.graData = sen.graData
			Global.sen.graData:getLights(ps)
			for i, v in ipairs(ps) do
				if v.typeid == _PointLight.typeid then
					Global.sen:addLight(v)
				end
			end
			Global.sen:useSkylightDirection()
		end
	},
	{
		-- 最小移动单位
		k = 229, -- ','
		func = function()
			bb.MinStep = not bb.MinStep
			Global.rotfactor = bb.MinStep and 15 or 45
			print('移动单位:', bb.MinStep and 0.02 or 0.1)
			print('旋转单位:', Global.rotfactor)
		end
	},
	{
		-- 显示/隐藏碰撞效果和物理的剔除效果
		k = _System.KeyE,
		release = true,
		func = function()
			if ENABLE_KEY and _sys:isKeyDown(_System.KeyCtrl) then
				Global.enableBlockingBlender = not Global.enableBlockingBlender
				print('显示相交E:', Global.enableBlockingBlender)
			else
				local c = bb.cc
				c:moveDirH(-math.pi / 4, 200, 'camera_rotate')
			end
		end
	},
	{
		-- 仅支持PC, 打开贴纸，将贴纸移动到可读目录下
		k = _System.KeyQ,
		release = true,
		func = function()
			if ENABLE_KEY and _sys:isKeyDown(_System.KeyCtrl) and _sys.os == 'win32' then
				local filename = _sys:openFile('*.bmp')
				local desname = Global.graffitiBag.resFolder .. _sys:getFileName(filename, true, false)
				_sys:copyFile(filename, desname)
				Global.graffitiBag:flush()
			else
				local c = bb.cc
				c:moveDirH(math.pi / 4, 200, 'camera_rotate')
			end
		end
	},
	{
		-- 单选材质开关
		k = _System.KeyR,
		func = function()
			if ENABLE_KEY and _sys:isKeyDown(_System.KeyCtrl) and _sys.os == 'win32' then
				local self = bb
				local bs = self.rt_selectedBlocks
				if not bs[1] then
					Global.BlockChipUI:show('main', self.chips_s.main)
				else
					local css
					for i, b in ipairs(bs) do
						if not css then css = b.chips_s end
					end
					if not css then css = {} end
					for i, b in ipairs(bs) do
						b.chips_s = css
					end
					Global.BlockChipUI:show('main', css)
				end
			else
				bb.enableBlockMaterial = not bb.enableBlockMaterial
				print('单选材质R', bb.enableBlockMaterial)
			end
		end
	},
	{
		k = _System.KeyH,
		func = function()
			local m = bb:getModule()
			m.disableMaxBox = not m.disableMaxBox
			print('m.disableMaxBox', m.disableMaxBox)
			--bb:showFuncflaglistUI(not bb.showfuncflagui)
			-- print('物理剔除:组(H):', bb.enablePhyxCulliing)
			-- if bb.rt_selectedBlocks then
			-- 	for i, v in ipairs(bb.rt_selectedBlocks) do
			-- 		local culling = v:isPhyxCulliing()
			-- 		v:setPhyxCulliing(not culling)
			-- 	end
			-- end
		end
	},
	-- {
	-- 	-- 剔除选中积木块的物理碰撞
	-- 	k = _System.KeyJ,
	-- 	func = function()
	-- 		print('物理剔除:块(J):', bb.enablePhyxCulliing)
	-- 		if bb.rt_block then
	-- 			local v = bb.rt_block
	-- 			local culling = v:isPhyxCulliing()
	-- 			v:setPhyxCulliing(not culling)
	-- 		end
	-- 	end
	-- },
}
local cameracontrol = {}
if _sys:isMobile() then
	cameracontrol.zoom = 2
end
Global.GameState:setupCallback({
	addKeyDownEvents = kevents,
	onDown = function(b, x, y)
		Global.BuildBrick:onDown(b, x, y)
	end,
	onMove = function(x, y, fid, count)
		if _sys.os ~= 'win32' and _sys.os ~= 'mac' then
			if Global.BuildBrick.downX and Global.BuildBrick.downY then
				local dx = math.abs(x - Global.BuildBrick.downX)
				local dy = math.abs(y - Global.BuildBrick.downY)
				if dx < 20 and dy < 20 then
					return
				end
			end
		end
		--print('onMove111111', x, y, fid, count)
		Global.BuildBrick:onMove(x, y, fid, count)
	end,
	onUp = function(b, x, y, fid, count)
		if fid and Global.BuildBrick.dragSelecting then
			return
		end

		Global.BuildBrick:onUp(0, x, y)
	end,
	onClick = function(x, y)
		if _sys.os == 'win32' or _sys.os == 'mac' then
			Global.BuildBrick:onUp(0, x, y)
		end
	end,
	onTouchMultiMove = function(x, y, fid, count)
		if Global.BuildBrick.dragSelecting and count == 2 and fid == 0 then
			if _sys.os ~= 'win32' and _sys.os ~= 'mac' then
				if Global.BuildBrick.downX and Global.BuildBrick.downY then
					local dx = math.abs(x - Global.BuildBrick.downX)
					local dy = math.abs(y - Global.BuildBrick.downY)
					if dx < 20 and dy < 20 then
						return
					end
				end
			end
			--print('onMove2222', x, y, fid, count)
			Global.BuildBrick:onMove(x, y, fid, count)
		end
	end,
	-- onTouchMultiDown = function(x, y, fid, count)
	-- 	if BuildBrick.dragSelecting and count == 2 then
	-- 		BuildBrick:onDown(b, x, y)
	-- 	end
	-- end,
	onTouchMultiUp = function(x, y, fid, count)
		if Global.BuildBrick.dragSelecting and count == 2 then
			Global.BuildBrick:onUp(0, x, y, fid, count)
		end
	end,
	cameraControl = cameracontrol,
},
'BUILDBRICK')

Global.GameState:onEnter(function(...)
	_app:changeScreen(0)
	Global.BuildBrick:init(Global.sen, ...)
	_app:registerUpdate(Global.BuildBrick, 7)

	_rd.oldShadowBias = 0.0001
	-- Global.BuildBrick:initCamera()

	if Global.BuildBrick.mode == 'buildbrick' and Global.Achievement:check('fristbuildbrick') == false then
		Global.Introduce:show('buildbrick')
		Global.Achievement:ask('fristbuildbrick')
	-- elseif Global.BuildBrick.mode == 'buildanima' and Global.Achievement:check('fristbuildanima') == false then
	-- 	Global.Introduce:show('buildanima')
	-- 	Global.Achievement:ask('fristbuildanima')
	end
	if Global.BuildBrick.mode == 'repair' then
		local bgs = Global.RepairBGTextures
		_rd.bgTexture = _Image.new(bgs[math.random(1, #bgs)], false, true)
		_rd.alphaFilterCombine = true
	end
end, 'BUILDBRICK')

Global.GameState:onLeave(function()
	Global.BuildBrick:onDestory()
	_app:unregisterUpdate(Global.BuildBrick)
	_rd.oldShadowBias = 0.0001
	_rd.bgTexture = nil
	_rd.alphaFilterCombine = false
end, 'BUILDBRICK')
