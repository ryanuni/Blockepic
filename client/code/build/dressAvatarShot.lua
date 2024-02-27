local Container = _require('Container')
local DressAvatarShot = {db = _DrawBoard.new(1, 1)}

DressAvatarShot.bgsettings = {
	{bg = 'bg1.png', cbg = 'cbg2.png', scbg = 'scbg2.png', fontcolor = '0xff351010'},
	{bg = 'bg2.png', cbg = 'cbg2.png', scbg = 'scbg2.png', fontcolor = '0xff351010'},
	{bg = 'bg3.png', cbg = 'cbg1.png', scbg = 'scbg1.png', fontcolor = '0xff003936'},
	{bg = 'bg4.png', cbg = 'cbg2.png', scbg = 'scbg2.png', fontcolor = '0xff351010'},
	{bg = 'bg5.png', cbg = 'cbg3.png', scbg = 'scbg3.png', fontcolor = '0xffffbb03'},
}

local ui = Global.UI:new('DressAvatarShot.bytes', 'screen', true)
ui.visible = false

Global.DressAvatarShot = DressAvatarShot

DressAvatarShot.timer = _Timer.new()

DressAvatarShot.isVisible = function(self)
	return ui.visible
end

DressAvatarShot.init = function(self)
	if self.scene then return end

	local scene = CreateSceneWithBlocks('avatar_room_01.sen')
	self.defaultScene = scene
end

DressAvatarShot.genMovie = function(self)
	-- self.db.w = ui.loader._width
	-- self.db.h = ui.loader._height
	self.db:resize(ui.loader._width, ui.loader._height)
	self.db.postProcess = _rd.postProcess

	_rd:useDrawBoard(self.db, _Color.Null)
	self.scene:render()
	_rd:resetDrawBoard()

	ui.loader:loadMovie(self.db)
end

DressAvatarShot.update = function(self)
	if ui.visible == false then return end

	self.scene:update()
end

DressAvatarShot.render = function(self)
	if ui.visible == false then return end

	_rd:useDrawBoard(self.db, _Color.Null)
	self.scene:render()
	_rd:resetDrawBoard()
end

DressAvatarShot.show = function(self, objid, isrole)
	if _rd.postProcess then
		_rd.postProcess.temptransparent = _rd.postProcess.transparent
		_rd.postProcess.transparent = true
		_rd.postProcess.tempssao = _rd.postProcess.ssao
		_rd.postProcess.ssao = false
	end

	local tempDisableCamera = Global.SwitchControl:get('cameracontrol')
	Global.SwitchControl:set_cameracontrol_off()
	local c = Global.CameraControl:get()
	self.ctarget = c.target

	local obj = Global.getObject(objid)

	local islocal = true

	if obj then
		islocal = Global.ObjectManager:check_isLocal(obj)
	else
		islocal = true
	end

	ui.tip.visible = false
	-- 提示点击退出
	-- self.timer:start('tip', 3000, function()
	-- 	if ui.visible then
	-- 		ui:gotoAndPlay('showtip')
	-- 	end
	-- 	self.timer:stop('tip')
	-- end)

	print("DressAvatarShot.show ", obj, objid, islocal)

	local shapeid = obj and obj.datafile and obj.datafile.name and _sys:getFileName(obj.datafile.name, false, false) or objid
	if isrole then
		self.scene = Global.sen
		self.block = nil
	else
		self.scene = self.defaultScene
		self.block = self.scene:createBlock({shape = shapeid})
		local ab = _AxisAlignedBox.new()
		self.block:getAABB(ab)
		local size = _Vector3.new()
		ab:getSize(size)

		self.defaultbb = {x = 2.0, z = 1.8}
		local scale = math.min(self.defaultbb.x / size.x, self.defaultbb.z / size.z)
		local mat2 = self.scene.graData:getMarker('cha1a')
		local trans = Container:get(_Vector3)
		local dir = Container:get(_Vector3)
		dir:set(0, -1, 0)
		local face = Container:get(_Vector3)
		local rotmat = Container:get(_Matrix3D)
		rotmat:setRotationZ(mat2:getRotationZ())
		rotmat:apply(dir, face)
		mat2:getTranslation(trans)
		local ab = Container:get(_AxisAlignedBox)
		self.block:getAABB(ab)
		self.block.node.transform:mulScalingLeft(scale, scale, scale)
		self.block:getAABB(ab)
		self.block.node.transform:mulTranslationRight(trans.x, trans.y, trans.z - ab.min.z)
		self.block:updateFace(face, 0)
		Container:returnBack(trans, dir, face, rotmat)

		self.block:applyAnim('shot')
		self.block:playAnim('shot')

		Global.CameraControl:push()
		local c = Global.CameraControl:get()
		c:reset()
		c:followTarget()
		c:setCamera(self.scene.graData:getCamera('camera2'))
		c:lockDirH(-math.pi, math.pi)
		c:lockDirV(-math.pi, math.pi)
		c:update()
		local ctarget = self.scene.graData:getCamera('camera1')
		c:setCamera(ctarget, 0)
		c:use()
	end

	self:genMovie()
	ui.visible = true
	_app:registerUpdate(DressAvatarShot, 7)
	ui.onSizeChange = function()
		if ui.visible == false then return end
		self:genMovie()
	end

	local name = Global.Login:getName()
	local address = Global.Login:getWallet()
	local roleid = Global.Login:getAid()

	local fileid = obj and obj.datafile and obj.datafile.fid
	local id
	if roleid and objid and fileid then
		id = roleid .. '_' .. objid .. '_' .. fileid
	end

	local extras = {ui.extra1, ui.extra2, ui.extra3, ui.extra4}
	local extratexts = {}
	local ei = Global.Login:getExtraInfo()
	if ei.discord then
		table.insert(extratexts, {icon = 'shot_discord.png', text = ei.discord})
	end
	if ei.twitter then
		table.insert(extratexts, {icon = 'shot_twitter.png', text = ei.twitter})
	end
	if ei.facebook then
		table.insert(extratexts, {icon = 'shot_facebook.png', text = ei.facebook})
	end
	if ei.instagram then
		table.insert(extratexts, {icon = 'shot_instagram.png', text = ei.instagram})
	end

	if obj then
		Tip(obj.title)
	else
		Tip()
	end

	local rnum = math.random(#self.bgsettings)
	local setting = self.bgsettings[rnum]
	local haveextra = false
	for i, u in ipairs(extras) do
		local extraitem = extratexts[i]
		u.text.text = extraitem and extraitem.text or ''
		u.icon._icon = u.text.text ~= '' and extraitem.icon or ''
		u.text.textColor = setting.fontcolor
		if u.text.text ~= '' then
			haveextra = true
		end
	end

	ui.bg._icon = setting.bg
	ui.namebg._icon = setting.cbg
	ui.namebg.visible = haveextra
	ui.snamebg._icon = setting.scbg
	ui.snamebg.visible = haveextra == false
	ui.name.textColor = setting.fontcolor

	ui.name.text = name
	ui.address.text = ''
	ui.id.text = id and 'ID: ' .. id or ''

	local time = os.utc(0.001)
	local curtime = {}
	_time(curtime, time, 0.001)
	ui.address.text = string.format('%04d.%02d.%02d %02d:%02d:%02d', curtime.year, curtime.month, curtime.day, curtime.hour, curtime.min, curtime.sec)

	ui.fg.click = function()
		ui.visible = false
		_app:unregisterUpdate(DressAvatarShot)
		if self.block then
			self.scene:delBlock(self.block)
			self.block = nil
			Global.CameraControl:pop()
			local c = Global.CameraControl:get()
			c:followTarget(self.ctarget)
		end
		if _rd.postProcess then
			_rd.postProcess.transparent = _rd.postProcess.temptransparent
			_rd.postProcess.ssao = _rd.postProcess.tempssao
			_rd.postProcess.temptransparent = nil
			_rd.postProcess.tempssao = nil
		end

		Global.SwitchControl:set('cameracontrol', tempDisableCamera)

		Tip()
		ui.rename._visible = false
		Global.DressAvatar:enableShot(false)

		self:onExit()
	end

	if not obj or Global.ObjectManager:isSpecialAvatar(obj) then
		print("ERROR: obj is nil")
		ui.share.visible = false
		Tip()
	else
		ui.share.visible = true
	end
	ui.share.click = function()
		print("clieck share")

		if not obj then
			print("ERROR: obj is nil")
			return
		end

		if obj and obj.title then
			self:shareAndJump()
		else
			ui.rename._visible = true
		end
	end

	if obj then
		ui.rename.name.text = obj.title == nil and '' or obj.title
	else
		ui.rename.name.text = ''
	end
	ui.rename.name.maxlength = 20
	ui.rename.name.focusIn = function(e)
		_sys:showKeyboard(ui.rename.name.text, "OK", e)
		_app:onKeyboardString(function(str)
			ui.rename.name.text = str
			ui.rename.name.focus = true
		end)
	end
	ui.rename.name.focusOut = function()
		_sys:hideKeyboard()
	end
	ui.rename.cancel.click = function()
		ui.rename._visible = false
	end
	ui.rename.publish.click = function()
		local resname = ui.rename.name.text

		local len = string.len(resname)
		if len < 3 then
			Notice(Global.TEXT.CREATE_NAME_LENGTH_MIN)
			return
		end
		if len > 20 then
			Notice(Global.TEXT.CREATE_NAME_LENGTH_MAX)
			return
		end
		if resname == '' then
			Notice(Global.TEXT.NOTICE_BRICK_RENAME)
			return
		end
		if Global.cFilter:check(resname) == false or resname:find(' ') then
			Notice(Global.TEXT.CREATE_NAME_INVALID)
			return
		end
		local obj_now = Global.getObject(objid)

		if obj_now then
			islocal = Global.ObjectManager:check_isLocal(obj_now)
		else
			islocal = true
		end

		-- print("ui.rename.publish.click ", obj_now, objid, islocal, obj.title, Global.ObjectManager:check_isLocal(obj_now))
		if not islocal then
			Global.DressAvatar:enableShot(true)
			ui.rename._visible = false
			--- TODO: 中间是不是应该禁止操作?
			Global.RegisterRemoteCbOnce('onChangeObjectName', 'uploadobject', function(object)
				if next(object) then
					obj_now.state = object.state
					obj_now.title = resname
					ui.rename.name.text = resname
					Tip(resname)
					self:shareAndJump()
					Global.DressAvatar:enableShot(false)

					return true
				end
			end)
			RPC('ChangeObjectName', {ID = obj.id, Title = resname})
		else
			ui.rename._visible = false
			--- todo: 本地存储一起上传

			obj_now.title = resname
			-- obj_now.state = obj_now.state or BuildBrick.ObjectState.Unknown
			-- obj_now.state = _or(obj_now.state, BuildBrick.ObjectState.Published)
			-- print("use local", resname, obj_now.title, obj_now.state)
			Global.ObjectManager:save()
			ui.rename.name.text = resname
			Tip(resname)
			self:shareAndJump()
		end
	end
end

DressAvatarShot.shareAndJump = function(self)
	ui.share.visible = false

	self.timer:start('showShare', _app.elapse, function()
		self.timer:start('showShare1', _app.elapse, function()
			_rd:captureScreenToImage(_G.captureScreen)
			local ret = _G.captureScreen:copyToClipBoard()
			if ret then
				_sys:browse("discord:///channels/976044109317935174/976087728590553148", true, true)
			else
				print("ERROR: copyToClipBoard failed")
			end

			ui.share.visible = true
			self.timer:stop('showShare1')
		end)
		self.timer:stop('showShare')
	end)
end

DressAvatarShot.showItem = function(self, name, shapeid, savename)
	if savename and self.isSaving then return false end
	if _rd.postProcess then
		_rd.postProcess.temptransparent = _rd.postProcess.transparent
		_rd.postProcess.transparent = true
		_rd.postProcess.tempssao = _rd.postProcess.ssao
		_rd.postProcess.ssao = false
	end

	local tempDisableCamera = Global.SwitchControl:get('cameracontrol')
	Global.SwitchControl:set_cameracontrol_off()

	self.scene = self.defaultScene
	self.block = self.scene:createBlock({shape = shapeid})
	local ab = _AxisAlignedBox.new()
	self.block:getAABB(ab)
	local size = _Vector3.new()
	ab:getSize(size)
	local scale = math.min(5 / size.x, 3 / size.y, 1.25 / size.z) * 0.75
	local mat2 = self.scene.graData:getMarker('cha1a')
	local trans = Container:get(_Vector3)
	local dir = Container:get(_Vector3)
	dir:set(0, -1, 0)
	local face = Container:get(_Vector3)
	local rotmat = Container:get(_Matrix3D)
	rotmat:setRotationZ(mat2:getRotationZ())
	rotmat:apply(dir, face)
	mat2:getTranslation(trans)
	local ab = Container:get(_AxisAlignedBox)
	self.block:getAABB(ab)
	self.block.node.transform:mulScalingLeft(scale, scale, scale)
	self.block:getAABB(ab)
	self.block.node.transform:mulTranslationRight(trans.x, trans.y, trans.z - ab.min.z)
	self.block:updateFace(face, 0)
	Container:returnBack(trans, dir, face, rotmat)

	self.block:applyAnim('shot')
	self.block:playAnim('shot')

	Global.CameraControl:push()
	local c = Global.CameraControl:get()
	c:setCamera(self.scene.graData:getCamera('camera2'))
	c:lockDirH(-math.pi, math.pi)
	c:lockDirV(-math.pi, math.pi)
	c:update()
	local ctarget = self.scene.graData:getCamera('camera1')
	c:setCamera(ctarget, 0)
	c:use()

	self:genMovie()
	ui.visible = true
	_app:registerUpdate(DressAvatarShot, 7)
	ui.onSizeChange = function()
		if ui.visible == false then return end
		self:genMovie()
	end

	local extras = {ui.extra1, ui.extra2, ui.extra3, ui.extra4}
	local extratexts = {}

	local rnum = math.random(#self.bgsettings)
	local setting = self.bgsettings[rnum]
	local haveextra = false
	for i, u in ipairs(extras) do
		local extraitem = extratexts[i]
		u.text.text = extraitem and extraitem.text or ''
		u.icon._icon = u.text.text ~= '' and extraitem.icon or ''
		u.text.textColor = setting.fontcolor
		if u.text.text ~= '' then
			haveextra = true
		end
	end

	ui.bg._icon = setting.bg
	print(ui.bg._icon)
	ui.namebg._icon = setting.cbg
	ui.namebg.visible = haveextra
	ui.snamebg._icon = setting.scbg
	ui.snamebg.visible = haveextra == false
	ui.name.textColor = setting.fontcolor

	ui.name.text = name
	ui.address.text = ''
	ui.id.text = ''

	ui.fg.click = function()
		ui.visible = false
		_app:unregisterUpdate(DressAvatarShot)
		self.scene:delBlock(self.block)
		self.block = nil
		Global.CameraControl:pop()
		if _rd.postProcess then
			_rd.postProcess.transparent = _rd.postProcess.temptransparent
			_rd.postProcess.ssao = _rd.postProcess.tempssao
			_rd.postProcess.temptransparent = nil
			_rd.postProcess.tempssao = nil
		end

		Global.SwitchControl:set('cameracontrol', tempDisableCamera)

		self:onExit()
	end

	ui.share.visible = false
	self.isSaving = true
	self.timer:start('showShare', _app.elapse, function()
		self.timer:start('showShare1', _app.elapse, function()
			_rd:captureScreenToImage(_G.captureScreen)
			if savename then
				_G.captureScreen:saveToFile(savename, _ModelFactory.ImageJpg)
				_app:unregisterUpdate(DressAvatarShot)
				self.scene:delBlock(self.block)
				self.block = nil
				DressAvatarShot.isSaving = false
			end
			_G.captureScreen:copyToClipBoard()

			self.timer:stop('showShare1')
		end)
		self.timer:stop('showShare')
	end)

	return true
end

DressAvatarShot:init()
DressAvatarShot.onExit = function() end