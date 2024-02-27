--[[
	rt变量
		rt_block	pick的block
		rt_selectedBlocks	选中的bs
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

local BuildHouse = {}
Global.BuildHouse = BuildHouse
_dofile('buildhouse_atom.lua')
_dofile('buildhouse_cmd.lua')

-- _dofile('buildhouse_group.lua')
_dofile('buildhouse_module.lua')
_dofile('buildhouse_scene.lua')
_dofile('buildhouse_operate.lua')

local movedelta = 30
if _sys.os == 'win32' or _sys.os == 'mac' then movedelta = 3 end
BuildHouse.movedelta = movedelta

-- ui notice controller
BuildHouse.timer = _Timer.new()

BuildHouse.init = function(self, sen, objname)
	assert(objname == nil)
	local c = Global.CameraControl:new()
	c.minRadius = 2
	c.maxRadius = Global.HouseRadius[Global.House.currentSize]

	local angle1, angle2 = 0.05, 1.4
	c:lockDirV(angle1, angle2)

	self.sindex = 0
	Tip(Global.TEXT.TIP_BUILDHOUSE)

	if _sys.os == 'win32' or _sys.os == 'mac' then
		self.mdx = 0
		self.mdy = 0
	else
		self.mdx = -60
		self.mdy = -60
	end

	self.sen = sen
	self.sen.bgpfx = self.sen.pfxPlayer:play('buildhousebg.pfx')
	-- ui
	self.ui = Global.UI:new('BuildRoom.bytes')
	self:initUI()

	Global.UI:onDeviceOrientation(self.ui, function(oriH)
		local lib = Global.ui.bricklibrary
		lib._width = oriH and 1440 or 1020
		lib._x = (Global.ui._width - lib._width) / 2
		lib._y = (Global.ui._height - lib._height) / 2
		if Global.brickui.ui then
			Global.brickui.ui.mainlist.itemNum = Global.brickui.ui.mainlist.itemNum
		end
	end)

	--Global.editor.movefactor = 0.1 / 5
	-- blender
	self.bl_rothint = _Blender.new()
	self.bl_rothint:blend(0xddffffff)
	self.bl_rothint_hover = _Blender.new()
	self.bl_rothint_hover:blend(0x88ffffff)

	self.curmodule = nil
	self.wallab = _AxisAlignedBox.new()
	self.innerWallab = _AxisAlignedBox.new()

	self:load(Global.ObjectManager:getHome().name)

	self.ondownfunc = self.ondown_editbrick
	self.onmovefunc = self.onmove_editbrick
	self.onupfunc = self.onup_editbrick

	Global.enableBlockingBlender = true

	self.mode = 'buildhouse'
end

BuildHouse.onDestory = function(self)
	Block.clearDataCache(self.shapeid)

	Tip()
	self:hideUI()
	if self.ui then
		self.ui:removeMovieClip()
		self.ui = nil
	end
	self.sen.bgpfx = nil

	self.rotHintUIs = nil
	self.moveUI = nil
	self.moveUIs = nil
	self.showrot = false
	self.downX, self.downY = nil, nil
end
-----------------------------------------------------------

BuildHouse.clearCommand = function(self)
--	print('[clearCommand]')
	local cmd = self.curmodule.command
	cmd:clear()
	self:ui_flush_undo()
end
BuildHouse.addCommand = function(self, redo, undo, des)
	local cmd = self.curmodule.command
	local ret = cmd:add(redo, undo, des)
	self:ui_flush_undo()
	return ret
end
BuildHouse.undo = function(self)
	local cmd = self.curmodule.command
	cmd:undo()
	self:ui_flush_undo()
end
BuildHouse.redo = function(self)
	local cmd = self.curmodule.command
	cmd:redo()
	self:ui_flush_undo()
end
BuildHouse.ui_flush_undo = function(self)
	local cmd = self.curmodule.command
	self.ui.btn_undo.visible = cmd:isUndoReady()
	self.ui.btn_redo.visible = cmd:isRedoReady()
end
-----------------------------------------------------------
BuildHouse.load = function(self, id)
	-- clear old info
	Global.BuildHouse:clearSceneBlock()
	if self.shapeid then
		Block.clearDataCache(self.shapeid)
	end

	assert(id)
	self.shapeid = id
	local data = Block.loadItemData(self.shapeid)
	self:loadModulesFromData(data)

	-- 把shapeid和self.modules绑定起来
	Block.addDataCache(self.shapeid, self.modules)

	self:setModule(self:getModule(0))

	self.oriMd5 = self:calcMd5()
end
Global.calcObjectCount = function(data)
	local brickcount = 0
	local isObject = function(s)
		if Global.HouseBases[s] or Global.HouseWalls[s] or Global.HouseFloors[s] then
			return false
		end

		if Block.isItemID(s) then
			return true
		end
	end
	for i, v in ipairs(data.blocks) do
		if isObject(v.shape) then
			brickcount = brickcount + 1
		end
	end

	if data.subs then
		for _, m in pairs(data.subs) do
			for i, b in ipairs(m.blocks) do
				if isObject(b.shape) then
					brickcount = brickcount + 1
				end
			end
		end
	end

	return brickcount
end
Global.uploadHouse = function(housedata, housename, mode)
	local str = Global.saveBlock2String(housedata)

	local filename, filemd5 = Global.FileSystem:atom_newData('itemlv', str)
	local uniq_id = housename ~= 'housedefault' and housename or ('house_' .. Global.Login:getAid() .. '_' .. _now(0.001))
	-- 保存并上传服务器
	local data = {}
	data.name = uniq_id
	data.state = 1
	data.tag = 'house'
	data.desc1 = ''
	data.costs = {}
	data.datafile = filename
	data.datafile_md5 = filemd5
	data.mode = mode

	local findgramophone = false
	for i, v in ipairs(housedata.blocks) do
		if v.shape == 'gramophone' then
			findgramophone = true
			break
		end
	end
	if findgramophone == false then
		Global.AudioPlayer:stop()
		data.playingmusic = false
	end

	data.housetag = Global.calcHouseTag(housedata) or ''
	data.brickcount = Global.calcObjectCount(housedata)

	Global.ObjectManager:newLocal_home(data)
end
Global.xl_house_upload = function(data)
	Global.FileSystem:new_uploadFiles({data.datafile}, function(success)
		if not success then
			Notice(Global.TEXT.NOTICE_HOUSE_UPLOAD_FAILED)
			return
		end
		-- 增加监听回调，回调后注销
		Global.RegisterRemoteCbOnce('onChangeHouse', 'SaveObject', function(obj)
			-- print('onChangeHouse:', obj.name, data.name, browsertype)
			if obj.name == data.name then
				-- 上传成功后更新本地资源
				Global.FileSystem:downloadData(obj.datafile)

				Notice(Global.TEXT.NOTICE_HOUSE_SAVED)

				return true
			end
		end)

		RPC('House_UpdateObject', {Data = data})
	end)
end
BuildHouse.goBack = function(self, mode)
	if mode == 'Back' then
		Global.entry:back()
	elseif mode == 'Expand' then
		Global.entry:goHome1()
	end
end
BuildHouse.calcMd5 = function(self)
	return _sys:md5(Global.saveBlock2String(self.modules))
end
BuildHouse.save = function(self, mode)
	-- 先保存当前场景 再判断
	self:saveSceneToModule(self.curmodule)
	local newmd5 = self:calcMd5()
	if self.oriMd5 ~= newmd5 then
		Global.uploadHouse(self.modules, self.shapeid, mode)
	end
	self:goBack(mode)
end

BuildHouse.capture = function(self, width, height, camera, callback)
	-- 自动生成图片
	Global.FileSystem:atom_newPic(Global.House:getName(), {w = width, h = height, cam = camera}, callback)
end

BuildHouse.saveToFile = _G.BuildBrick.saveToFile
BuildHouse.distance = _G.BuildBrick.distance

BuildHouse.showHint = _G.BuildBrick.showHint
BuildHouse.updateHint = _G.BuildBrick.updateHint
BuildHouse.camera_down = _G.BuildBrick.camera_down
BuildHouse.camera_move = _G.BuildBrick.camera_move
BuildHouse.camera_up = _G.BuildBrick.camera_up
------------------ UI

BuildHouse.initUI = function(self)
	local ClickSound = {
		{ui = self.ui.itemscale.zoomin, sound = 'ui_scale'},
		{ui = self.ui.itemscale.zoomout, sound = 'ui_scale'},
	}

	-- 配置按钮声效
	for _, data in ipairs(ClickSound) do
		local ui = data.ui
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
	self.ui.goback.click = function()
		self.ui.goback.disabled = true
		self.timer:start('goback', 3000, function()
			if self.ui then
				self.ui.goback.disabled = false
			end
			self.timer:stop('goback')
		end)
		self:save('Back')
	end

	self.ui.view.visible = false

	self.ui.copybutton.click = function()
		if Global.ObjectIcons[self.rt_block.data.shape] then
			Notice(Global.TEXT.NOTICE_HOUSE_COPY_ERROR)
			return
		end
		self:cmd_copy()
	end

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

	self.ui.module_del.click = function()
		if self:atom_block_selectedNum() >= 8 then
			Confirm(Global.TEXT.CONFIRM_BRICK_DELETE, function()
				self:cmd_delBrick()
			end, function()
			end)
		else
			self:cmd_delBrick()
		end
	end

	self.ui.selectmode.visible = false
	self.planemove = self.ui.selectmode.selected
	self.ui.selectmode.click = function()
		self.planemove = self.ui.selectmode.selected
	end

	-- scalehint
	-- self.scaleicons = {
	-- 	{scale = 0.0625, icon = 'img://scale_1_16.png'},
	-- 	{scale = 0.125, icon = 'img://scale_1_8.png'},
	-- 	{scale = 0.25, icon = 'img://scale_1_4.png'},
	-- 	{scale = 0.5, icon = 'img://scale_1_2.png'},
	-- 	{scale = 1, icon = 'img://scale_1.png'},
	-- 	-- {scale = 2, icon = 'img://scale_2.png'},
	-- }
	self.scaleindex = 4

	local uiscale = self.ui.itemscale
	uiscale.zoomout.click = function()
		if next(self.rt_selectedBlocks) and self.scaleindex ~= 1 then
			local scale1 = Global.getScaleByIndex(self.scaleindex)
			self.scaleindex = self.scaleindex - 1
			local scale2 = Global.getScaleByIndex(self.scaleindex)

			self.ui.itemscale.text.text = scale2 * 100 .. '%'

			local ab1 = Container:get(_AxisAlignedBox)
			local ab2 = Container:get(_AxisAlignedBox)
			local b = self.rt_selectedBlocks[1]
			b:getShapeAABB(ab1)

			self:cmd_mat_update_begin(nil, 'scale')
			local scale = scale2 / scale1
			self.rt_transform:mulScalingLeft(scale, scale, scale)
			b:getShapeAABB(ab2)
			self.rt_transform:mulTranslationRight(0, 0, ab1.min.z - ab2.min.z)
			--print('zoomout', ab1.min.z, ab2.min.z)
			self:cmd_mat_update_end()

			Container:returnBack(ab1, ab2)
		end
	end
	uiscale.zoomin.click = function()
		if next(self.rt_selectedBlocks) and self.scaleindex < 4 then
			local scale1 = Global.getScaleByIndex(self.scaleindex)
			self.scaleindex = self.scaleindex + 1
			local scale2 = Global.getScaleByIndex(self.scaleindex)
			--self.ui.itemscale.icon._icon = self.scaleicons[self.scaleindex].icon
			self.ui.itemscale.text.text = scale2 * 100 .. '%'

			local ab1 = Container:get(_AxisAlignedBox)
			local ab2 = Container:get(_AxisAlignedBox)
			local b = self.rt_selectedBlocks[1]
			b:getShapeAABB(ab1)

			self:cmd_mat_update_begin(nil, 'scale')
			local scale = scale2 / scale1
			self.rt_transform:mulScalingLeft(scale, scale, scale)

			b:getShapeAABB(ab2)
			self.rt_transform:mulTranslationRight(0, 0, ab1.min.z - ab2.min.z)
			self:cmd_mat_update_end()

			--print('zoomin', ab1.min.z, ab2.min.z)
			Container:returnBack(ab1, ab2)
		end
	end
end

BuildHouse.hideUI = function(self)
	if BuildHouse.ui then BuildHouse.ui.visible = true end
	BuildHouse:showPropList(false)
	Global.brickui:hide()
	Global.SwitchControl:set_render_on()
end

BuildHouse.showPropList = function(self, show)
	self.showProp = show
	self:onSelectBlock(self.rt_selectedBlocks[1])
	if show == false then
		--self:showScaleHint(false)
		return
	end

	--self:showScaleHint(true)
end

BuildHouse.onSelectBlock = function(self, b)
	local show = not not b
	if b then
		local isNPC = Global.HouseNPC[b:getShape()]
		self.ui.module_del.visible = Global.Achievement:check('goouthouse')
		self.ui.copybutton.visible = not isNPC
		self.ui.bottombg.visible = not isNPC
	else
		self.ui.module_del.visible = false
		self.ui.bottombg.visible = false
		self.ui.copybutton.visible = false
	end

	self:showRotHint(show)
	self:showMovHint(show)
	self:showScaleHint(show)
end

BuildHouse.showScaleHint = function(self, show)
	self.ui.itemscale.visible = show
	if show then
		local b = self.rt_selectedBlocks[1]
		local vec = Container:get(_Vector3)
		b.node.transform:getScaling(vec)
		self.scaleindex = Global.findScaleIndex(vec.x)
		local scale = Global.getScaleByIndex(self.scaleindex)
		self.ui.itemscale.text.text = scale * 100 .. '%'
	end
end

BuildHouse.showBricks = function(self)
	Tip()

	Global.brickui:show('buildhouse',
	function()
		self:hideUI()
	end)
end

BuildHouse.checkGroupRotRestriction = function()
	return false
end

BuildHouse.showRotHint = _G.BuildBrick.showRotHint
BuildHouse.showMovHint = _G.BuildBrick.showMovHint
BuildHouse.renderRotDB = _G.BuildBrick.renderRotDB

BuildHouse.ondown_editbrick = function(self, x, y)
	local flag = Global.CONSTPICKFLAG.NORMALBLOCK + Global.CONSTPICKFLAG.SELECTBLOCK + Global.CONSTPICKFLAG.WALL + Global.CONSTPICKFLAG.TERRAIN
	local node, pos = self:scenepick(x, y, flag)

	local b
	if node then
		if _and(node.pickFlag, Global.CONSTPICKFLAG.NORMALBLOCK + Global.CONSTPICKFLAG.SELECTBLOCK) ~= 0 then
			b = node.block
		end
	end
	if b then
		self:cmd_select_begin(b, pos)
	else
		self:cmd_select_begin()
	end
end
BuildHouse.onmove_editbrick = function(self, x, y)
	return self:building_move_onMove(x, y)
end

BuildHouse.onDClick = function(self)
	if #self.rt_selectedBlocks > 0 then
		self:showPropList(true)
	else
		Tip()
		local callback = function()
			self.ui.visible = false
			self:showBricks()
		end
		_G:holdbackScreen(self.timer, callback)
	end
end
BuildHouse.onup_editbrick = function(self, x, y, dbclick)
	local selected = self:cmd_select_end()
	-- 长按的结束, 结束时直接认为下次是单击
	if self:building_move_onEnd(x, y) then
		return true
	elseif selected == 1 then
		-- 双击同一块, 点到块上呼出材质和旋转，点击空白 呼出 积木库
		if dbclick then
			self:onDClick()
		end
	end

	return false
end

local clickid = nil
BuildHouse.onDown = function(self, b, x, y)
	clickid = b
	if b ~= 0 then return end

	self.downX, self.downY = x, y
	if self.ondownfunc then
		self:ondownfunc(x, y)
	end
end

BuildHouse.onMove = function(self, x, y, fid)
	if self.rt_block == nil then
		self:camera_down(0, x, y)
		self:camera_move(x, y, fid)
		self:cmd_select_cancel()
	else
		if clickid ~= 0 then return end
		self:cmd_select_end()
		if self.onmovefunc then
			self:onmovefunc(x, y)
		end
	end
end

local clicktick = 0
local lastb
BuildHouse.onUp = function(self, b, x, y)
	local dt = 100000
	if lastb == b then
		dt = _tick() - clicktick
	end
	clicktick = _tick()
	lastb = b

	if self:camera_up() then
		clicktick = 0
		return
	end

	if b ~= 0 then return end

	local dbclick = false
	if dt < 500 then
		dbclick = true
	end

	if self.onupfunc and self:onupfunc(x, y, dbclick) then
		clicktick = 0
	end

	self.downX, self.downY = nil, nil
end

BuildHouse.drawPlaneZ = function(self, z)
	-- if self.rt_block and not Global.PickHelper.ismoving then
		-- local aabb = Container:get(_AxisAlignedBox)
		-- self.rt_block:getShapeAABB(aabb)
		-- aabb:draw(_Color.Black)
		-- Container:returnBack(aabb)
	-- end
end
BuildHouse.render = function(self)
	self:drawPlaneZ(0)
	self:renderRotDB()

	if self.showPickHelper then
		Global.PickHelper:render()
	end
end

local kevents = {
	{
		k = _System.KeyC,
		release = true,
		func = function()
			if _sys:isKeyDown(_System.KeyCtrl) then
				BuildHouse:cmd_copy()
			end
		end
	},
	{
		k = _System.KeyZ,
		release = true,
		func = function()
			if _sys:isKeyDown(_System.KeyCtrl) then
				BuildHouse:undo()
			end
		end
	},
	{
		k = _System.KeyY,
		release = true,
		func = function()
			if _sys:isKeyDown(_System.KeyCtrl) then
				BuildHouse:redo()
			end
		end
	},
	{
		k = _System.KeyDel,
		release = true,
		func = function()
			BuildHouse:cmd_delBrick()
		end
	},
	{
		k = _System.KeyW,
		release = true,
		func = function()
			if BuildHouse.moveUI == nil or BuildHouse.moveUI.visible == false then return end
			BuildHouse.moveUI.up.click()
		end
	},
	{
		k = _System.KeyA,
		release = true,
		func = function()
			if BuildHouse.moveUI == nil or BuildHouse.moveUI.visible == false then return end
			BuildHouse.moveUI.left.click()
		end
	},
	{
		k = _System.KeyD,
		release = true,
		func = function()
			if BuildHouse.moveUI == nil or BuildHouse.moveUI.visible == false then return end
			BuildHouse.moveUI.right.click()
		end
	},
	{
		k = _System.KeyS,
		release = true,
		func = function()
			if ENABLE_KEY and _sys:isKeyDown(_System.KeyCtrl) then
				BuildHouse:save()
			-- 	local openfilename = _sys:getFileName(_sys:saveFile('.itemlv'))
			-- 	if not openfilename or openfilename == '' then return end

			-- 	-- 先保存当前场景
			-- 	Global.BuildHouse:saveSceneToModule(Global.BuildHouse.curmodule)
			-- 	Global.BuildHouse:saveToFile(openfilename)
			-- 	local itemid = _sys:getFileName(openfilename, false, false)
			-- 	Global.Capture:addNode(itemid)
			else
				if BuildHouse.moveUI == nil or BuildHouse.moveUI.visible == false then return end
				BuildHouse.moveUI.down.click()
			end
		end
	},
	{
		k = _System.KeyLeft,
		release = true,
		func = function()
			if BuildHouse.rotHintUIs == nil or not BuildHouse.showrot then return end
			local btn = BuildHouse.rotHintUIs[3].btn1
			if btn.visible == false then return end

			local x = btn._x + btn._width / 2
			local y = btn._y + btn._height / 2
			btn.onMouseDown({mouse = {x = x, y = y}})
			btn.onMouseUp({mouse = {x = x, y = y}})
		end
	},
	{
		k = _System.KeyRight,
		release = true,
		func = function()
			if BuildHouse.rotHintUIs == nil or not BuildHouse.showrot then return end
			local btn = BuildHouse.rotHintUIs[3].btn2
			if btn.visible == false then return end

			local x = btn._x + btn._width / 2
			local y = btn._y + btn._height / 2
			btn.onMouseDown({mouse = {x = x, y = y}})
			btn.onMouseUp({mouse = {x = x, y = y}})
		end
	},
	{
		k = _System.KeyO,
		func = function()
			local filename = _sys:openFile('*.itemlv')
			local shapeid = _sys:getFileName(filename, false, false)
			Global.BuildHouse:load(shapeid)
		end
	},
	{
		k = _System.KeyP,
		func = function()
			local filename = _sys:openFile('*.itemlv')
			local shapeid = _sys:getFileName(filename, false, false)
			Global.sen:createBlock({shape = shapeid})
		end
	},
	{
		k = _System.KeyM,
		func = function()
			BuildHouse.ui.selectmode.visible = not BuildHouse.ui.selectmode.visible
		end
	},
	{
		k = _System.Key5,
		func = function()
			BuildHouse.showPickHelper = not BuildHouse.showPickHelper
		end
	},
	{
		k = _System.KeyE,
		func = function()
			Global.enableBlockingBlender = not Global.enableBlockingBlender
		end
	},
	{
		k = _System.KeyEnd,
		func = function()
			Global.BuildHouse:capture()
		end
	},
	{
		k = _System.KeyHome,
		func = function()
			local file = _File.new()
			file:create('camera.config', 'utf-8')
			file:write(_rd.camera:__tostring())
			file:close()
		end
	},
}
local cameracontrol = {}
if _sys:isMobile() then
	cameracontrol.zoom = 2
end
Global.GameState:setupCallback({
	addKeyDownEvents = kevents,
	onDown = function(b, x, y)
		BuildHouse:onDown(b, x, y)
	end,
	onMove = function(x, y, fid, count)
		if _sys.os ~= 'win32' and _sys.os ~= 'mac' then
			if BuildHouse.downX and BuildHouse.downY then
				local dx = math.abs(x - BuildHouse.downX)
				local dy = math.abs(y - BuildHouse.downY)
				if dx < 20 and dy < 20 then
					return
				end
			end
		end
		BuildHouse:onMove(x, y, fid)
	end,
	onUp = function(b, x, y)
		BuildHouse:onUp(0, x, y)
	end,
	onClick = function(x, y)
		if _sys.os == 'win32' or _sys.os == 'mac' then
			BuildHouse:onUp(0, x, y)
		end
	end,
	cameraControl = cameracontrol,
},
'BUILDHOUSE')

Global.GameState:onEnter(function(...)
	_app:changeScreen(0)
	Global.BuildHouse:init(Global.sen, ...)
	_app:registerUpdate(BuildHouse, 4)
	local c = Global.CameraControl:get()
	c:setCamera(Global.EntryEditAnima.camera)
	local oldv = c:getDirV()
	local oldh = c:getDirH()
	c:moveLook(_Vector3.new(0, 0, 1.2), 500)
	c:moveDirH(math.pi / 2 - oldh, 500)
	c:moveDirV(0.68 - oldv, 500)
	c:lockZ(1.2)
	c:use()

	local nbs = {}
	BuildHouse:getBlocks(nbs)
	if #nbs > 0 then
		local aabb = Container:get(_AxisAlignedBox)
		Block.getAABBs(nbs, aabb)
		local r = calcCameraRadius(_rd.camera, aabb)
		c:scale(r, 500)
		c:use()
		Container:returnBack(aabb)
	end

	_rd.camera.viewNear = 0.3
end, 'BUILDHOUSE')

Global.GameState:onLeave(function()
	BuildHouse:onDestory()
	_app:unregisterUpdate(BuildHouse)
end, 'BUILDHOUSE')