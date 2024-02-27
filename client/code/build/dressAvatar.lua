local Container = _require('Container')

local CONST_COUNT_AVATAR = 7
local DressAvatar = {}
Global.DressAvatar = DressAvatar
DressAvatar.timer = _Timer.new()

local defaultobj = {data = {name = 'defaultavatar', id = 0}, pindex = 0}
DressAvatar.updateList = function(self, movedata)
	self:clearAvatar()
	local oldavaid = self:getSelectedObject().id

	local oavas = {}
	for i, d in ipairs(self.Avatars) do
		local id = d.data.id or d.data.name
		oavas[id] = i
	end

	self.Avatars = {}
	local defaultAvatar = defaultobj
	local om = Global.ObjectManager
	for _, o in ipairs(om:getMyAvatars()) do
		if om:isSpecialAvatar(o) then
			defaultAvatar = {data = o, pindex = 0}
			break
		end
	end
	table.insert(self.Avatars, defaultAvatar)
	--print('defaultAvatar', defaultAvatar.data.name, defaultAvatar.data.id)

	local tempindex = 10
	for _, o in ipairs(om:getMyAvatars()) do
		if om:check_isNFT(o) or
			(om:check_isPublished(o) and not om:isSpecialAvatar(o) and not om:check_isLocal(o)) then
			-- 保持之前的位置
			local id = o.id or o.name
			local oindex = oavas[id]
			local pindex
			if oindex then
				pindex = oindex
			else
				pindex = tempindex
				tempindex = tempindex + 1
			end

			local data = {data = o, pindex = pindex}
			table.insert(self.Avatars, data)
		end
	end

	table.sort(self.Avatars, function(a, b)
		return a.pindex < b.pindex
	end)

	-- find selected
	self.rtdata.selected = 1
	for i, v in ipairs(self.Avatars) do
		if v.data.id == oldavaid then
			self.rtdata.selected = i
		end
	end
	Global.role:ChangeAvatar(self:getSelectedObject().name)

	if movedata then
		if movedata.showfirst then
			self:moveIndex(1 - self.rtdata.current)
		end
	end

	for i, v in ipairs(self.Avatars) do
		if v.data.id == Global.ObjectManager:getAvatarId() then
			self.rtdata.selected = i
		end
		Global.FileSystem:downloadData(v.data.datafile, nil, function()
			self:showAvatar(i)
		end)
	end

	self:flushState1()
	self:flushState2()
end

DressAvatar.setShowObject = function(self, obj)
	self.showobj = obj
end

DressAvatar.moveToObject = function(self)
	local obj = self.showobj
	self.showobj = nil
	if not obj then return end
	local name = obj.name
	for i, v in ipairs(self.Avatars) do
		if v.data.name == name then
			if i ~= self.rtdata.current then
				self:moveIndex(i - self.rtdata.current)
			end
			return
		end
	end
end

DressAvatar.updateAvatarPosition = function(self)
	self.avatarsPos = {}
	self.avatarEachTrans = {avatar = _Vector3.new(0, 0, 0), box = _Vector3.new(0, 0, 0)}
	local amat1 = Global.sen.graData:getMarker('marker1a')
	local amat2 = Global.sen.graData:getMarker('marker2a')
	local oritrans = Container:get(_Vector3)
	local dsttrans = Container:get(_Vector3)
	amat1:getTranslation(oritrans)
	amat2:getTranslation(dsttrans)
	_Vector3.sub(dsttrans, oritrans, self.avatarEachTrans.avatar)

	local mat1 = Global.sen.graData:getMarker('marker1')
	local mat2 = Global.sen.graData:getMarker('marker2')
	mat1:getTranslation(oritrans)
	mat2:getTranslation(dsttrans)
	_Vector3.sub(dsttrans, oritrans, self.avatarEachTrans.box)
	Container:returnBack(oritrans, dsttrans)

	for i = 1, CONST_COUNT_AVATAR do
		local amat = _Matrix3D.new() amat:identity() amat:mulRight(amat1)
		local mat = _Matrix3D.new() mat:identity() mat:mulRight(mat1)
		for j = 1, i - 1 do
			amat:mulTranslationRight(self.avatarEachTrans.avatar)
			mat:mulTranslationRight(self.avatarEachTrans.box)
		end
		table.insert(self.avatarsPos, {avatar = amat, box = mat})
	end
end

DressAvatar.init = function(self)
	local c = Global.CameraControl:new()
	c.minRadius = 2
	c.maxRadius = 40

	Global.role:releaseCCT()

	if _sys:getGlobal('AUTOTEST') then
		self.showHelperAABB = true
	end

	Tip(Global.TEXT.TIP_DRESSAVATAR)

	local angle1, angle2 = 0.05, 1.4
	c:lockDirV(angle1, angle2)
	_rd.bgColor = _Color.Gray

	self:updateAvatarPosition()

	self.rtdata = {
		current = 1,
		selected = 1,
	}

	Global.Vote:getVoteResult(function(infos)
		Global.ObjectManager:updateVoteResult(infos)
	end)
	-- ui
	self.ui = Global.UI:new('DressAvatar.bytes')
	self:initUI()

	self.Avatars = {defaultobj}
	self.isShot = false
	--self:updateList({showfirst = true})
	self:updateList()
	Global.ObjectManager:listen('dressavatar', function()
		if self.isShot == false then
			self:updateList()
		end
	end)

	-- 刷新主角位置
	self:resetAvatarPos()

	self.bgpfx = Global.sen.pfxPlayer:play('dressavatarbg.pfx')
end

DressAvatar.enableShot = function(self, enable)
	self.isShot = enable
end

DressAvatar.onDestory = function(self)
	Global.ObjectManager:listen('dressavatar')
	-- clear avatar block
	self:clearAvatar()

	self.downX, self.downY = nil, nil
	Tip()
	self:hideUI()
	if self.ui then
		self.ui:removeMovieClip()
		self.ui = nil
		self.moduleItems = nil
	end
	if self.uiprop then
		self.uiprop:removeMovieClip()
		self.uiprop = nil
	end

	self.Avatars = {}
	self.bgpfx = nil
end

------------------ UI
DressAvatar.ClickSound = {
	{ui = 'module_del', sound = 'build_del01'},
}

DressAvatar.getAvatarIndexById = function(self, id)
	for i, v in ipairs(self.Avatars) do
		if v.data.id == id then
			return i
		end
	end
end

DressAvatar.updateUIPos = function(self)
	local vec = Container:get(_Vector3)
	self.avatarsPos[self.rtdata.current].box:getTranslation(vec)

	vec.y = vec.y - 0.6
	local x, y = Global.UI:Vector3ToPos(vec)
	self.ui.next_l._x = x - self.ui.next_l._width
	vec.y = vec.y + 2.5
	x, y = Global.UI:Vector3ToPos(vec)
	self.ui.next_r._x = x

	vec.y = vec.y - 1.2
	vec.z = vec.z - 2.0
	x, y = Global.UI:Vector3ToPos(vec)
	self.ui.addavatar._x = x
	self.ui.addavatar._y = y

	Global.sen.graData:getMarker('cha1'):getTranslation(vec)
	x, y = Global.UI:Vector3ToPos(vec)
	self.ui.module_dress._x = x
	--self.ui.addavatar._x = x
	Container:returnBack(vec)

	self.ui.visible = true
end

DressAvatar.initUI = function(self)
	-- 配置按钮声效
	self.ui.visible = false

	self.ui.onSizeChange = function()
		self:updateUIPos()
	end

	for _, data in ipairs(self.ClickSound) do
		local ui = self.ui[data.ui]
		if ui then
			ui._sound = Global.SoundList[data.sound]
			ui._soundVolumeScale = data.volume or Global.SoundConfigsList[data.sound].volume
		end
	end

	self.ui.goback.click = function()
		self.ui.goback.disabled = true
		self.timer:start('goback', 3000, function()
			if self.ui then
				self.ui.goback.disabled = false
			end
			self.timer:stop('goback')
		end)

		if Global.Achievement:check('wearavatar') == false then
			Global.gmm.wearavatardone = true
		end
		Global.entry:back()
	end

	self.ui.module_del.disabled = true
	self.ui.module_del.click = function()
		Confirm('Confirm remove from display case?', function()
			local o = self:getCurrentObject()
			Global.RegisterRemoteCbOnce('onDeleteUploadObject', 'unpublishObject', function(object)
				if next(object) then
					Notice(Global.TEXT.NOTICE_AVATAR_UNPUBLISHED)
					return true
					--self:updateList()
				end
			end)

			self.ui.module_dress.visible = false
			self.ui.module_del.visible = false
			RPC('UnPublishObject', {ID = o.id})
		end, function()
		end)
	end

	self.ui.module_dress.visible = false
	self.ui.module_dress.click = function()
		self.rtdata.selected = self.rtdata.current
		local d = self:getCurrentObject()

		RPC('UpdateAvatarid', {Data = d})

		self.ui.module_dress.visible = false
		self.ui.build.disabled = true
		self.ui.module_del.visible = false
	end

	self.ui.module_mint.visible = false
	self.ui.module_mint.click = function()
		local curobj = self:getCurrentObject()
		if curobj.canMint then
			if Global.Login:getWallet() == curobj.mintInfo.wallet then
				Global.Wallet:mintVote(curobj.mintInfo.id)
			else
				Notice(Global.TEXT.NOTICE_MINT_FAILED)
			end
		end
	end

	self.ui.previewanim.click = function()
		self.ui.animlist.visible = not self.ui.animlist.visible
		self:flushState2()
		--self.ui.module_dress.visible = not self.ui.module_dress.visible
	end

	self.ui.build.disabled = true
	self.ui.build.click = function()
		Global.entry:goBuildAnima(self:getCurrentObject().name, nil, 'editdress')
	end

	self.ui.addavatar.click = function()
		local callback = function()
			self.ui.visible = false
			Global.brickui:show('showavatar', function()
				self.ui.visible = true
				Global.SwitchControl:set_render_on()
				Global.brickui:hide()
			end)
		end
		_G:holdbackScreen(self.timer, callback)
	end

	local animitems = {}
	local animlist = self.ui.animlist
	local anims = Global.Animas
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
	self.animitems = animitems

	self.ui.next_r.click = function()
		self:moveIndex(1)
	end
	self.ui.next_l.click = function()
		self:moveIndex(-1)
	end

	self.ui.screenshot.click = function()
		for i, v in ipairs(self.avatarBoxes) do
			v.node.visible = false
		end
		for i, v in ipairs(self.Avatars) do
			if v.char then
				v.char.node.visible = false
			end
		end
		self.bgpfx.visible = false
		local roleanima = Global.role.currentAnimaName or nil
		Global.role:playAnima('shot')
		Global.DressAvatarShot:show(self:getSelectedObject().id, true)
		Global.DressAvatarShot.onExit = function()
			for i, v in ipairs(self.avatarBoxes) do
				v.node.visible = true
			end
			for i, v in ipairs(self.Avatars) do
				if v.char then
					v.char.node.visible = true
				end
			end
			self.bgpfx.visible = true
			Global.role:playAnima(roleanima or 'idle')
		end
	end

	self.avatarBoxes = {}
	for i = 1, CONST_COUNT_AVATAR do
		local b = Global.sen:createBlock({shape = 'Avatar_library0' .. i})
		Global.sen:delActor(b.actor)

		-- onfloor
		local ab = Container:get(_AxisAlignedBox)
		b:getAABB(ab)
		self.avatarsPos[i].box:mulTranslationRight(0, -0.7, -ab.min.z)
		Container:returnBack(ab)
		b.node.transform = self.avatarsPos[i].box

		table.insert(self.avatarBoxes, b)
	end

	local b = Global.sen:createBlock({shape = 'Avatar_seat'})
	Global.sen:delActor(b.actor)
	local mat = Global.sen.graData:getMarker('cha1')
	local ab = Container:get(_AxisAlignedBox)
	b:getAABB(ab)
	mat:mulTranslationRight(0, 0.55, -ab.min.z)
	Container:returnBack(ab)
	b.node.transform = mat
end
DressAvatar.getCurrentObject = function(self)
	return self.Avatars[self.rtdata.current] and self.Avatars[self.rtdata.current].data
end
DressAvatar.getSelectedObject = function(self)
	return self.Avatars[self.rtdata.selected].data
end
DressAvatar.flushState1 = function(self)
	if self.ui then
		self.ui.next_l.visible = self.rtdata.current > 1
		--self.ui.next_r.visible = self.rtdata.current < math.min(#self.Avatars, 7)
		self.ui.next_r.visible = self.rtdata.current < 7
	end
end

DressAvatar.flushState2 = function(self)
	if self.ui then
		local s = self:getSelectedObject()
		local o = self:getCurrentObject()
		if not o then
			self.ui.build.visible = false
			self.ui.module_del.visible = false
			self.ui.module_dress.visible = false

			self.ui.module_mint.visible = false
			self.ui.addavatar.visible = true
			self.ui.screenshot.visible = false
			self.ui.previewanim.visible = false
		else
			self.ui.addavatar.visible = false
			self.ui.build.visible = true
			self.ui.screenshot.visible = true
			self.ui.previewanim.visible = true

			-- self.ui.build.disabled = true
			local om = Global.ObjectManager
			if o.id == 0 or om:isSpecialAvatar(o) or o.isNFT or s.id == o.id then
				self.ui.module_del.visible = false
			else
				self.ui.module_del.visible = true
			end
			if s.id == o.id then
				self.ui.module_dress.visible = false
			else
				self.ui.module_dress.visible = not self.ui.animlist.visible
			end
			if o.isfake then
				self.ui.module_dress.visible = false
				self.ui.module_del.visible = false
				self.ui.build.visible = false
			end

			if o.canMint then
				self.ui.module_mint.visible = true
			else
				self.ui.module_mint.visible = false
			end

			self.ui.module_dress.disabled = true
			self.ui.build.disabled = true
			if o.id == 0 then
				self.ui.build.disabled = s.id == o.id or (_sys.os ~= 'win32' and _sys.os ~= 'mac')
			end

			Global.FileSystem:downloadData(o.datafile, nil, function()
				self.ui.module_dress.disabled = false

				-- 默认化身不能编辑
				--if o.id == 0 or o.isNFT then
				if o.isNFT then
					self.ui.build.visible = false
				else
					self.ui.build.visible = true
					self.ui.build.disabled = s.id == o.id or (_sys.os ~= 'win32' and _sys.os ~= 'mac')
				end
			end)

			self.ui.module_del.disabled = o.isNFT or false
		end
	end
end
DressAvatar.moveIndex = function(self, di)
	self.rtdata.current = self.rtdata.current + di
	self:flushState1()

	self.ui.module_del.disabled = false
	self.ui.module_dress.visible = false
	self.ui.build.disabled = true

	local t = 200 + math.abs(di) * 200
	self.timer:start('movebox', t, function()
		self:flushState2()
		self.timer:stop('movebox')
	end)

	self:moveAvatarBox(-di, t)
end

DressAvatar.playAnimIndex = function(self, index, play)
	if self.selectedAnim then
		self.selectedAnim = nil
		Global.role:playAnima('idle')
	end

	local anims = Global.Animas

	if index and play then
		self.selectedAnim = index
		Global.role:playAnima(anims[index])
	end

	for i, u in ipairs(self.animitems) do
		u.selected = self.selectedAnim == i
	end
end

DressAvatar.hideUI = function(self)
	if DressAvatar.ui then DressAvatar.ui.visible = true end
	Global.SwitchControl:set_render_on()
end

DressAvatar.moveAvatarBox = function(self, step, t)
	local vec = Container:get(_Vector3)
	local bvec = Container:get(_Vector3)
	for i, k in ipairs(self.avatarsPos) do
		local transform = k.avatar
		local btransform = k.box
		_Vector3.mul(self.avatarEachTrans.avatar, step, vec)
		_Vector3.mul(self.avatarEachTrans.box, step, bvec)
		transform:mulTranslationRight(vec, t)
		btransform:mulTranslationRight(bvec, t)
	end
	Container:returnBack(vec, bvec)

	for i, box in ipairs(self.avatarBoxes) do
		local avatarPos = self.avatarsPos[i]
		local avatar = self.Avatars[i]
		if avatar and avatar.block then
			avatar.block.node.transform = avatarPos.avatar
		end
	end
end

DressAvatar.updateAvatarList = function(self)
	-- 重置Avatar
	if self.selectedAvatar == 0 then
		if self.avatarid ~= 0 then
			Global.role:setAvatarid(0)
			self.avatarid = 0
		end
		return
	end

	local avatar = self.Avatars[self.selectedAvatar]
	if avatar == nil then return end
	local objectinfo = Global.getObjectByName(avatar.data.name)
	local avatarid = objectinfo.id
	if avatarid == nil or self.avatarid == avatarid then return end
	if not Global.role then return end
	Global.role:setAvatarid(avatarid)
	self.avatarid = avatarid
end

DressAvatar.resetAvatarPos = function(self)
	local mat = Global.sen.graData:getMarker('cha1a')
	local vec3 = Container:get(_Vector3)
	local rotmat = Container:get(_Matrix3D)
	rotmat:setRotationZ(mat:getRotationZ())
	rotmat:apply(Global.role.mesh.dir, vec3)
	Global.role:updateFace(vec3, 0)
	mat:getTranslation(vec3)
	Global.role:setPosition(vec3)
	Container:returnBack(vec3, rotmat)
end

local nft_img = _Image.new("nft.png")
local nft_pending_img = _Image.new("nft_gray.png")
DressAvatar.update = function(self)
	if self.bgpfx == nil then return end
	local dir = Container:get(_Vector3)
	local vec2 = Container:get(_Vector2)
	local camera = Global.CameraControl:get()
	camera:update()
	_Vector3.sub(camera.camera.look, camera.camera.eye, dir)
	dir:normalize()
	_Vector3.mul(dir, 400, dir)
	_Vector3.add(dir, camera.camera.eye, dir)
	self.bgpfx.transform:setTranslation(dir)
	Container:returnBack(dir)

	for i, a in ipairs(self.Avatars) do
		local v = Container:get(_Vector3)
		if a.data.isNFT then
			local c = a.char
			if c then
				c.node.transform:getTranslation(v)
				_rd:projectPoint(v.x, v.y - 0.5, v.z + c.eyeHeight, vec2)
				
				if a.data.tmp_pending then
					nft_pending_img:drawImage(vec2.x - nft_pending_img.w/2, vec2.y - nft_pending_img.h/2)
					-- nft_pending_img:drawBillboard(v.x, v.y - 0.5, v.z + c.eyeHeight, 0.7, 0.7)
				else
					nft_img:drawImage(vec2.x - nft_img.w/2, vec2.y - nft_img.h/2)
					-- nft_img:drawBillboard(v.x, v.y - 0.5, v.z + c.eyeHeight, 0.7, 0.7)
				end
			end
		end
	end
	Container:returnBack(vec2)
end
DressAvatar.clearAvatar = function(self)
	for i = 1, #self.Avatars do
		if self.Avatars[i].char then
			self.Avatars[i].char:release()
			self.Avatars[i].char = nil
		end
	end

end
DressAvatar.showAvatar = function(self, index)
	if index > CONST_COUNT_AVATAR then
		return
	end

	local a = self.Avatars[index]
	local c = Global.Character.new({
		id = index,
		pos = {x = 0, y = 0, z = 0},
		dir = {x = 0, y = -1, z = 0},
	}, 'dress_avatar')

	a.char = c
	c:ChangeAvatar_anima_pose(a.data.name)
	c.node.transform = self.avatarsPos[index].avatar
end

DressAvatar.onDown = function(self, b, x, y)
	if b ~= 0 then return end

	self.downX, self.downY = x, y
	if self.ondownfunc then
		self:ondownfunc(x, y)
	end
end

DressAvatar.onMove = function(self, x, y, fid)
	if not Global.role or not self.downX then return end

	local deltax = x - self.downX
	self.downX = x
	deltax = -deltax * 0.01
	Global.role:rotateFace(deltax)
end

Global.GameState:setupCallback({
	onDown = function(b, x, y)
		DressAvatar:onDown(b, x, y)
	end,
	onMove = function(x, y, fid, count)
		if _sys.os ~= 'win32' then
			if DressAvatar.downX and DressAvatar.downY then
				local dx = math.abs(x - DressAvatar.downX)
				local dy = math.abs(y - DressAvatar.downY)
				if dx < 20 and dy < 20 then
					return
				end
			end
		end

		DressAvatar:onMove(x, y, fid)
	end,
},
'DRESSUP')

Global.GameState:onEnter(function(...)
	_app:changeScreen(0)
	Global.DressAvatar:init(...)
	Global.SwitchControl:set_cameracontrol_off()
	_app:registerUpdate(DressAvatar, 7)
end, 'DRESSUP')

Global.GameState:onLeave(function()
	DressAvatar:onDestory()
	Global.SwitchControl:set_cameracontrol_on()
	_app:unregisterUpdate(DressAvatar)
end, 'DRESSUP')