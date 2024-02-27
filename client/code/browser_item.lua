
local om = Global.ObjectManager
local Browser = Global.Browser

local bi = {}
bi.tempCamera = _Camera.new()

bi.new = function(item)
	local i = {}
	local camera = Global.CameraControl:new()
	camera.minRadius = 2
	camera.maxRadius = 10
	local angle1, angle2 = 0.05, 1.4
	camera:lockDirV(angle1, angle2)
	camera:lockZ(0.2)
	i.camera = camera

	i.item = item
	item.visible = false
	i.scene = CreateSceneWithBlocks('browserbg.sen')

	i.floornode = nil
	local nodes = {}
	i.scene:getNodes(nodes)
	for _, v in ipairs(nodes) do
		if string.find(v.name, 'dimian_01') then
			i.floornode = v
		end
	end

	i.object = nil
	i.objects = nil
	i.beginTime = _tick()

	i.disabletime = 0

	setmetatable(i, {__index = bi})
	i:onSizeChange()
	i:init()

	return i
end
bi.onSizeChange = function(self)
	local w = math.max(self.item._width, 1)
	local h = math.max(self.item._height, 1)
	if self.db then
		self.db:resize(w, h)
	else
		self.db = _DrawBoard.new(w, h)
		self.db.postProcess = _rd.postProcess
	end
	self.item.rt:loadMovie(self.db)
end

bi.countViewTime = function(self)
	RPC('ViewObject', {ID = self.objectinfo.id, Time = _tick() - self.beginTime})
end

bi.init = function(self)
	local item = self.item
	local sx, sy, lx, ly, lt = 0, 0, 0, 0, 0
	local begin = false
	self.movemode = ''
	self.movetick = _tick() - 10000
	self.ticktimer = _Timer.new()
	local win32 = _sys.os == 'win32'
	self.rtfingers = {}
	self.rtfingercounts = 0
	item.rt.onMouseDown = function(args)
		if _sys:isKeyDown(_System.MouseRight) then return end
		self.rtfingercounts = self.rtfingercounts + 1
		self.rtfingers[args.fid] = {x = args.mouse.x, y = args.mouse.y, dx = 0, dy = 0}
		if self.rtfingercounts == 1 or win32 then
			lx, ly = args.mouse.x, args.mouse.y
			sx, sy = args.mouse.x, args.mouse.y
			if begin == true then return end
			lt = _tick()
			self.ticktimer:start('', 400, function()
				Browser:showCameraHint(true, args.mouse.x, args.mouse.y)
				self.movemode = 'camera'
				self.ticktimer:stop()
			end)
			begin = true
		elseif self.rtfingercounts == 2 then
			local _, p1 = next(self.rtfingers)
			local __, p2 = next(self.rtfingers, _)
			lt = _tick()
			self.movemode = 'camera'
			self.ticktimer:stop()
			begin = false
		end
	end
	item.rt.onMouseMove = function(args)
		if _sys:isKeyDown(_System.MouseRight) then return end
		if self.rtfingercounts == 1 or win32 then
			if begin == false then return end
			if self.movemode == '' and math.abs(args.mouse.x - sx) > 10 and math.abs(args.mouse.y - sy) < 10 then
				self.movemode = 'camera'
				Browser:showCameraHint(true, args.mouse.x, args.mouse.y)
				self.ticktimer:stop()
			elseif self.movemode == '' and math.abs(args.mouse.x - sx) < 10 and math.abs(args.mouse.y - sy) > 10 then
				self.movemode = 'movepage'
				self.ticktimer:stop()
			elseif self.movemode == 'camera' then
				local dx = args.mouse.x - lx
				self.camera:moveDirH(dx / 540 * math.pi)
				local dy = args.mouse.y - ly
				self.camera:moveDirV(dy / 540 * math.pi)
				Browser:showCameraHint(true, args.mouse.x, args.mouse.y)
			elseif self.movemode == 'movepage' then
				local dy = args.mouse.y - ly
				Browser:movePage(dy)
			end
			lx, ly = args.mouse.x, args.mouse.y
		elseif self.rtfingercounts == 2 then
			local pos = self.rtfingers[args.fid]
			pos.dx = args.mouse.x - pos.x
			pos.dy = args.mouse.x - pos.x
			pos.x = args.mouse.x
			pos.y = args.mouse.y

			local dx1, dx2, dy1, dy2
			local _, p1 = next(self.rtfingers)
			local __, p2 = next(self.rtfingers, _)
			dx1 = p1.dx
			dy1 = p1.dy

			dx2 = p2.dx
			dy2 = p2.dy
			if dx1 * dx2 < 0 or dy1 * dy2 < 0 then
				local w1, w2, h1, h2
				w1 = math.abs((p1.x - dx1) - (p2.x - dx2))
				h1 = math.abs((p1.y - dy1) - (p2.y - dy2))
				w2 = math.abs(p1.x - p2.x)
				h2 = math.abs(p1.y - p2.y)

				local d
				if math.abs(w1 - w2) > math.abs(h1 - h2) then
					d = w1 - w2
				else
					d = h1 - h2
				end
				self.camera:scaleD(self.camera:getScale() - d * 0.01 > 0 and d * 0.01 or 0)
			end
		end
	end
	item.rt.onMouseUp = function(args)
		if _sys:isKeyDown(_System.MouseRight) then return end
		if self.rtfingercounts == 0 then return end
		self.rtfingercounts = self.rtfingercounts - 1
		self.rtfingers[args.fid] = nil
		if self.rtfingercounts == 0 or win32 then
			Browser:showCameraHint(false)
			if begin == false then return end
			local lastindex = Browser.curIndex
			local dy = args.mouse.y - sy
			local speed = dy / (_tick() - lt)
			if self.movemode == 'movepage' then
				if speed > 0.6 or dy > item._height / 2 then
					self:countViewTime()
					Browser:moveUpPage()
				elseif speed < -0.6 or dy < - item._height / 2 then
					self:countViewTime()
					Browser:moveDownPage()
				end
				self.movetick = _tick() - 10000
				Browser:playPageMove(lastindex)

				Global.Timer:add('vibrate', 200, function()
					_sys:vibrate(30) -- movetime 手机震动
				end)
			elseif self.movemode == 'camera' then
				self.movetick = _tick()
			end
			sx, sy, lx, ly, lt = 0, 0, 0, 0, 0
			self.movemode = ''
			self.ticktimer:stop()
			begin = false
		elseif self.rtfingercounts == 1 then
			if begin == true then return end
			local _, nf = next(self.rtfingers)
			lx, ly = nf.x, nf.y
			sx, sy = nf.x, nf.y
			lt = _tick()
			begin = true
		end
	end

	-- tag
	item.tagslider.visible = false
	item.tagtitle.visible = false

	-- social
	if Browser.needmore and Browser.tag ~= 'scene_random' then
		item.logo.visible = true
		item.name.visible = true

		item.like.visible = true
		item.likenum.visible = true
		item.like.click = function()
			Global.RegisterRemoteCbOnce('onChangeLike', 'addLike', function(obj)
				self.objectinfo.like = obj.like
				item.like.selected = obj.like
				self.objectinfo.likenum = obj.likenum
				self.item.likenum.text = self.objectinfo.likenum
				return true
			end)

			if not self.objectinfo.like then
				RPC('AddObjectLike', {ObjectID = self.objectinfo.id})
			else
				RPC('DelObjectLike', {ObjectID = self.objectinfo.id})
			end

			_sys:vibrate(30)
		end

		item.collect.visible = true
		item.collectnum.visible = true
		item.collect.click = function()
			Global.RegisterRemoteCbOnce('onChangeCollect', 'addCollect', function(obj)
				self.objectinfo.collect = obj.collect
				item.collect.selected = obj.collect
				self.objectinfo.collectnum = obj.collectnum
				self.item.collectnum.text = self.objectinfo.collectnum
				return true
			end)

			if not self.objectinfo.collect then
				RPC('AddObjectCollect', {ObjectID = self.objectinfo.id})
			else
				RPC('DelObjectCollect', {ObjectID = self.objectinfo.id})
			end

			_sys:vibrate(30)
		end

		item.barrage.visible = true
		item.barrage.click = function()
			Global.BarrageEdit:show(true, self.objectinfo.id, function(barrage)
				if barrage[1] then
					if Global.Barrage.ui == nil or Global.Barrage.ui.visible == false then
						Global.Barrage:show(false)
						Global.Barrage:show(true, {barrage})
					else
						Global.Barrage:addtoNext(barrage)
					end
				end
			end)
		end

		item.played_pic.visible = true
		item.played_num.visible = true

		item.finished_pic.visible = true
		item.finished_num.visible = true

		item.scene_id.visible = true
	else
		item.logo.visible = false
		item.name.visible = false
		item.like.visible = false
		item.likenum.visible = false
		item.collect.visible = false
		item.collectnum.visible = false
		item.barrage.visible = false

		item.played_pic.visible = false
		item.played_num.visible = false

		item.finished_pic.visible = false
		item.finished_num.visible = false

		item.scene_id.visible = false
	end

	-- my
	item.delete.visible = false
	item.delete.click = function()
		Confirm('Confirm deletion?', function()
			om:DeleteObject(self.objectinfo)
			if Browser.mode == 'showavatar' then
				Browser:leave()
			else
				table.remove(Browser.objects, Browser.curIndex)
				if #Browser.objects == 0 then
					Global.entry:back()
				else
					Browser.curIndex = Browser.curIndex > #Browser.objects and #Browser.objects or Browser.curIndex
					Browser:init(Browser.objects, Browser.curIndex, Browser.needmore, Browser.tag, Browser.mode, Browser.buildmode)
				end
			end
		end, function()
			return
		end)
	end
	item.upload.visible = false
	item.upload.click = function()
		local pui = Browser.ui.confirmpublish
		pui.visible = true
		pui.taglist.visible = false
		pui.n19.visible = false
		local title_text = 'My Creation'
		if not self.objectinfo.title or self.objectinfo.title == '' then
		else
			title_text = self.objectinfo.title
		end
		pui.name.text = title_text
		pui.name.focusIn = function(e)
			_sys:showKeyboard(pui.name.text, "OK", e)
			_app:onKeyboardString(function(str)
				pui.name.text = str
				pui.name.focus = true
			end)
		end
		pui.name.focusOut = function()
			_sys:hideKeyboard()
		end
		pui.publish.click = function()
			local title = pui.name.text
			local name = title
			if name == 'My Creation' or name == '' or Global.cFilter:check(name) == false then
				Notice(Global.TEXT.NOTICE_BRICK_RENAME)
				return
			end

			if name == self.objectinfo.title then
				name = nil
			end

			pui.visible = false
			RPC('PublishObject', {ID = self.objectinfo.id, Title = name})
		end
		pui.cancel.click = function()
			pui.visible = false
		end

		-- Global.RegisterRemoteCbOnce('onUpdateSystemTags', 'gettags', function(tags)
		-- 	self.selectedTag = nil
		-- 	pui.taglist.onRenderItem = function(index, item)
		-- 		local tag = tags[index]
		-- 		item.name.text = Global.totag(tag)
		-- 		item.click = function()
		-- 			if self.selectedTag == tag then
		-- 				self.selectedTag = nil
		-- 				item.selected = false
		-- 			else
		-- 				self.selectedTag = tag
		-- 				item.selected = true
		-- 			end
		-- 		end
		-- 	end
		-- 	pui.taglist.itemNum = #tags

		-- 	return true
		-- end)

		-- RPC('GetSystemTags', {})
	end
	item.deleteupload.visible = false
	item.deleteupload.click = function()
		--- TODO: 中间是不是应该禁止操作?
		-- Global.RegisterRemoteCbOnce('onDeleteUploadObject', 'deleteupload', function(object)
		-- 	Notice(Global.TEXT.NOTICE_BRICK_WITHDRAWN)
		-- 	self.objectinfo.state = object.state
		-- 	self:syncButtonState()
		-- 	return true
		-- end)
		Confirm('Confirm to cancel publishing?',
		function()
			RPC('UnPublishObject', {ID = self.objectinfo.id})
		end)
	end
	item.build.visible = false
	item.build.click = function()
		local objectinfo = Browser.objects[Browser.curIndex]
		local istemplate = objectinfo.creater == nil or objectinfo.creater.aid == -1
		if Browser.tag == 'house' then
			Global.entry:goBuildHouse()
		else
			if om:check_isLocal(objectinfo) then
				Block.clearCaches(objectinfo.name)
				Block.addDataCache(objectinfo.name, _dofile(objectinfo.datafile.name))
			end
			Browser:leave()
			local isavatar = objectinfo.tag == 'avatar'
			if isavatar or Browser.buildmode == 'avatar' then
				Global.entry:goBuildAnima(objectinfo.name, istemplate)
			elseif Browser.buildmode == 'scene' then
				Global.entry:goBuildScene(objectinfo.name, istemplate, objectinfo.tag)
			else
				Global.entry:goBuildBrick(objectinfo.name, istemplate)
			end
			if om:check_isLocal(objectinfo) then
				Block.clearDataCache(objectinfo.name)
				Block.clearCaches(objectinfo.name)
			end
		end
	end

	-- play
	item.play1.visible = false
	item.play2.visible = false
	item.play4.visible = false
	if Browser.needmore then
		item.play1.click = function()
			local obj = Browser.objects[Browser.curIndex]
			Global.Room_New:Single_Game(self.objectinfo)
		end
		item.play2.click = function()
			local obj = Browser.objects[Browser.curIndex]
			Global.Room_New:Join_Game(obj, 2, 'platform_jump')
		end
		item.play4.click = function()
			local obj = Browser.objects[Browser.curIndex]
			Global.Room_New:Join_Game(obj, 4, 'platform_jump')
		end
	end

	-- mine / social
	item.preview.visible = false
	item.preview.click = function()
		local objectinfo = Browser.objects[Browser.curIndex]
		if om:check_isPublished(objectinfo) then
			RPC('UpdateObject_Scene', {Oid = objectinfo.id, Op = 'play'})
		end

		local func
		func = function()
			Global.entry:goDungeon(objectinfo, nil, {test = true, restart_func = func})
		end
		func()
	end
	if Browser.mode == 'browser' and Browser.tag == 'scene' and not Browser.needmore then
		item.preview.visible = true
	end

	item.buy.visible = false
	item.buy.click = function()
		Global.FileSystem:downloadData(self.objectinfo.picfile, nil, function()
			local achievement = ''
			local sobj = Global.getSystemObject(self.objectinfo.name)
			if sobj and sobj.achievements and #sobj.achievements == 1 then
				achievement = sobj.achievements[1]
			end
			Global.gmm:askGuideStepFristBuy(self.objectinfo, achievement)
			RPC('BuyItem', {Itemid = self.objectinfo.id, Achievement = achievement})
		end)
		item.buy.visible = false
	end

	item.enter.visible = false
	item.enter.click = function()
		local stack = Global.entry.stack[#Global.entry.stack]
		stack.param[1] = Browser.objects
		stack.param[2] = Browser.curIndex

		Global.Switcher:enable(false)
		Global.Sound:play('otherhouse_enter')
		Global.entry:goHome1(self.objectinfo)
		Global.Switcher:enable(true)

		-- 记录进入次数
		RPC("House_Visit", {ID = self.objectinfo.id})
	end

	-- add
	if Browser.mode == 'buildbrick' then
		item.add.visible = true
		item.add.click = function()
			Browser:leave()

			Global.BuildBrick:addAsset(self.objectinfo)
		end
	elseif Browser.mode == 'buildscene' then
		item.add.visible = true
		item.add.click = function()
			Browser:leave()

			Global.BuildBrick:addBlock(self.objectinfo.name)
		end
	elseif Browser.mode == 'buildhouse' then
		item.add.visible = true
		item.add.click = function()
			Browser:leave()

			Global.BuildHouse:addBlock(self.objectinfo.name)
		end
	elseif Browser.mode == 'showavatar' then
		item.add.visible = true
		item.add.click = function()
			Browser:leave()

			Global.RegisterRemoteCbOnce('onUploadObject', 'PublishObject', function(object)
				if next(object) then
					Notice(Global.TEXT.NOTICE_AVATAR_PUBLISHED)
					Global.DressAvatar:updateList()
					return true
				end
			end)
			RPC('PublishObject', {ID = self.objectinfo.id})
		end
	else
		item.add.visible = false
	end

	-- repair
	if Browser.mode == 'repair' then
		item.repair.visible = true
		item.repair.click = function()
			Browser:leave()

			Global.entry:goRepairBlueprint(self.objectinfo)
		end
	else
		item.repair.visible = false
	end
end

bi.setDisableTime = function(self, time)
	if time <= 0 then
		self.item.disabled = false
	else
		self.disabletime = time
		self.item.disabled = true
		self.item.gray = false
	end
end

bi.update = function(self, e)
	if Global.DressAvatarShot.isVisible() then return end
	if self.camera then
		self.camera:update()
	end
	if self.disabletime > 0 then
		self.disabletime = self.disabletime - e
	end
	if self.disabletime <= 0 then
		self:setDisableTime(0)
	end

	if self.object then
		self.object:update2(e)
		-- self.scene:update_blocks(e)
	end
end

bi.render = function(self, e)
	if Global.DressAvatarShot.isVisible() then return end
	if self.item._y <= -self.item._height or self.item._y >= self.item._height then return end

	local rw = Global.UI:safeArea_getRW()
	self.item.logo._x = self.item._width - self.item.logo._width - rw - 25
	local lw = Global.UI:safeArea_getLW()
	self.item.delete._x = lw + 40
	local up = Global.UI:safeArea_getUP()
	self.item.desc._y = 70 + up
	self.item.descbg._y = 72 + up
	-- self.item.build._y = up

	bi.tempCamera:set(_rd.camera)
	if not self.stopCameraRot and self.movemode == '' and _tick() - self.movetick > 10000 then
		self.camera:moveDirH(e / 5000)
	end

	if Global.EntryEditAnima.popingcam then
		self.camera:setEyeLook(_rd.camera.eye, _rd.camera.look)
	else
		self.camera:use()
	end

	local lastAsyncShader = _sys.asyncShader
	_sys.asyncShader = false
	_rd.worldUVScale = self.worldUVScale
	_rd:useDrawBoard(self.db, _Color.Gray)
	--if Browser.needBlust then
		self.scene:update(_app.elapse)
	--end
	self.scene:render(e)
	_rd:resetDrawBoard()
	_sys.asyncShader = lastAsyncShader

	_rd.camera:set(bi.tempCamera)
	if Browser.ui.visible == false then
		self.db:drawImage(0, 0, _rd.w, _rd.h)
	end
end

bi.flushModeButton = function(self)
	Browser.ui.screenshot.visible = false
end

bi.flushHouseButton = function(self, object)
	Browser.ui.screenshot.visible = false
	self.item.enter.visible = not Global.Login:isMe(object.owner.aid)
	self.item.enter.disabled = true
	Global.downloadWhole(object, function()
		if self.item then
			self.item.enter.disabled = false
		end
	end)

	self.item.desc.visible = true
	self.item.descbg.visible = true
	local desc = object.owner.name .. '\'s Room'
	if object.housetag and object.housetag ~= '' then
		desc = desc .. ' ' .. Global.totag(object.housetag)
		local star = Global.tolevel(object.housetag)
		for i = 1, star do
			desc = desc .. genHtmlImg('star.png', 48, 48)
		end
		print(desc)
	end
	self.item.desc.text = desc
end
bi.flushObjectButton = function(self, object)
	-- delete upload deleteupload
	if Browser.buildmode == 'nobuild' then
		self.item.delete.visible = false
		self.item.deleteupload.visible = false
		self.item.upload.visible = false
		return
	end
	local ismine = Global.Login:isMe(object.owner.aid)
	local ispublished = om:check_isPublished(object)
	local isavatar = object.tag == 'avatar'
	if isavatar then
		ispublished = false
	end
	local isdraft = om:check_isDraft(object)

	self.item.delete.visible = ismine and not ispublished and object.online
	if Global.ObjectManager:getAvatarId() == object.id then
		self.item.delete.disabled = true
	else
		self.item.delete.disabled = false
	end
	Global.FileSystem:downloadData(object.datafile, nil, function()
	end)

	if isavatar or isdraft then
		self.item.upload.visible = false
		self.item.deleteupload.visible = false
	else
		if ismine and Browser.buildmode == 'scene' then
			self.item.upload.visible = not ispublished
			self.item.deleteupload.visible = ispublished
		else
			self.item.upload.visible = false
			self.item.deleteupload.visible = false
		end
	end
end
bi.syncButtonState = function(self)
	if not self.objectinfo then return end

	local object = self.objectinfo
	if Browser.mode == 'showavatar' then
		self.item.delete.visible = true
	end
	if Browser.mode == 'buildhouse' or Browser.mode == 'buildbrick' or Browser.mode == 'buildscene' or Browser.mode == 'showavatar' then
		self:flushModeButton()

		local islocal = om:check_isLocal(object)
		self.item.add.disabled = islocal
	elseif Browser.mode == 'repair' then
		self:flushModeButton()

		local level = object.data and object.data.level or 1
		self.item.repair.visible = level <= #object
	else
		if Browser.tag == 'house' then
			self:flushHouseButton(object)
			if self.floornode then self.floornode.visible = false end
		else
			self:flushObjectButton(object)
			if self.floornode then self.floornode.visible = true end
		end
	end

	if object.title then
		self.item.desc.visible = true
		self.item.descbg.visible = true
		self.item.desc.text = object.title
	else
		self.item.desc.visible = false
		self.item.descbg.visible = false
	end

	if om:check_isTemplate(object) then
		self.item.logo.text = ''
		self.item.name.text = ''
	else
		self.item.logo.text = string.sub(object.owner.name, 1, 1)
		self.item.name.text = object.owner.name
	end

	if Browser.needmore then
		self.item.like.selected = object.like
		self.item.likenum.text = object.likenum
		self.item.collect.selected = object.collect
		self.item.collectnum.text = object.collectnum

		self.item.played_num.text = object.scene_play_times
		self.item.finished_num.text = object.scene_finish_times

		self.item.scene_id.text = '#' .. object.id

		self.item.play1.visible = true
		if om:is_never_scene(object) then
			self.item.play2.visible = false
			self.item.play4.visible = true
		elseif object.tag == 'scene_music' or object.id == 'music_random' then
			self.item.play2.visible = true
			self.item.play4.visible = false
		end
	end

	if Browser.needmore then
		self.item.build.visible = false
	elseif self.item.add.visible then
		if Global.BuildBrick.shapeid and object.name == Global.BuildBrick.shapeid then
			self.item.add.disabled = true
		else
			self.item.add.disabled = false
		end
		self.item.build.visible = false
	elseif Browser.mode == 'repair' then
		self.item.build.visible = false
	elseif om:check_isPublished(object) then
		self.item.build.visible = false
	elseif Browser.buildmode == 'nobuild' then
		self.item.build.visible = false
	else
		self.item.build.visible = true
	end

	if not Global.isSceneType(object.tag) then
		self.item.deleteupload.visible = false
		self.item.upload.visible = false
	end

	self.item.barrage.visible = false

	self:fix_bottom_button()
end
local btn_check_keys = {
	'preview',
	'add', 'build',
	'upload', 'deleteupload',
	'play1', 'play2', 'play4',
}
bi.fix_bottom_button = function(self)
	local mc = self.item
	local btns = {}

	for _, v in ipairs(btn_check_keys) do
		local btn = mc[v]
		if btn.visible then
			table.insert(btns, btn)
		end
	end

	local mc_w = 150
	local offset = 5
	local width = mc_w + (#btns - 1) * (mc_w + offset)
	local left = (mc._width - width) / 2
	for _, v in ipairs(btns) do
		v._x = left
		left = left + offset + mc_w
	end
end

bi.useDataFile = function(self, object)
	if Browser.needBlust then
		self.objects = self.scene:createBlockByCell({shape = object.name})

		local ab = Block.getAABBs(self.objects)
		for i, v in ipairs(self.objects) do
			v.node.transform:mulTranslationRight(0, 0, -ab.min.z)
		end
	else
		local objname = object.name
		if Browser.mode == 'repair' then
			local level = object.data and object.data.level or 1
			--print('aaa', level, table.ftoString(object))
			objname = object.data and object.data.datafile and object.data.datafile.name or (object[level] and object[level].name) or object.name
			objname = _sys:getFileName(objname, false, false)
		end

		self.object = self.scene:createBlock({shape = objname})
		local ab = _AxisAlignedBox.new()
		-- 把物件提到0平面以上，缩放来适应光和雾
		if object.tag == 'house' then
			local bs = Block.getHelperData(objname).subs.bs
			local find = false
			for i, sub in ipairs(bs) do
				if Global.HouseBases[sub.id] then
					local bb = sub.mesh:getBoundBox()
					ab.min:set(bb.x1, bb.y1, bb.z1)
					ab.max:set(bb.x2, bb.y2, bb.z2)
					find = true
					break
				end
			end

			if not find then
				self.object:getAABB(ab)
			end
		else
			self.object:getAABB(ab)
		end

		local size = _Vector3.new()
		ab:getSize(size)
		local scale = math.min(5 / size.x, 3 / size.y, 1.25 / size.z)
		self.object.node.transform:setScaling(scale, scale, scale)
		self.worldUVScale = scale

		ab:getCenter(size)
		_Vector3.mul(size, scale, size)

		local h = -ab.min.z * scale
		local offset = _Vector3.new(-size.x, -size.y, h + 0.01)
		self.object.node.transform:mulTranslationRight(offset)

		self.object:enableAutoAnima(true)
		self.object:invokeMarker()
		--self.object:applyAnim('animas', true)
		--self.object:playAnim('animas')
		--local hasdf = self.object:playDynamicEffect('df1')

		local df = self.object:getPlayingDf()
		self.stopCameraRot = not not df or Global.isSceneType(object.tag)

		-- ab:getCenter(size)
		-- _Vector3.mul(size, scale, size)
		-- self.camera:focus(size)
	end

	self:syncButtonState()
end

bi.changeObject = function(self, object, iscurrent)
	if not iscurrent then return end
	if not object then
		self.objectinfo = nil
		self.item.visible = false
		return
	end

	self.item.visible = true
	local skip_scene = false
	if self.objectinfo == nil then
	else
		if om:check_isTemplate(self.objectinfo) then
		else
			if self.objectinfo.datafile.md5 == object.datafile.md5 then
				skip_scene = true
			end
		end
	end

	self.objectinfo = object

	if object.creater == nil then
		local name = object.name
		local creater
		if om:check_isTemplate(object) then
			creater = {aid = -1, name = 'Blockepic'}
		else
			creater = {aid = Global.Login.rtdata.aid, name = Global.Login.name}
		end
		-- local creater = object.mode == 'template' and {aid = -1, name = 'Blockepic'} or {aid = Global.Login.rtdata.aid, name = Global.Login.name}
		local owner = object.owner
		if owner == nil then
			owner = creater
		end
		local index = object.index
		if Browser.mode == 'repair' then
			object.creater = creater
			object.owner = owner
		end
	else
		object.online = true
	end

	object.reviewprogress = object.reviewprogress or 999
	object.tags = object.tags or {}

	self:syncButtonState()

	if skip_scene then
		return
	end

	self.item.desc.visible = true
	self.item.descbg.visible = true
	self.item.desc.text = 'Loading...'

	self.scene:delAllBlocks()
	-- Camera初始化
	self.camera:setEyeLook(_Vector3.new(0, -4, 2.8), _Vector3.new(0, 0, 0))

	local function downloadfinish()
		if Global.isMultiObjectType(object.tag) then
			Global.downloadHousesNeededObjects({object}, function(p)
				if self.item then
					self.item.desc.text = string.format("%s%.2f%%", 'Loading...', p * 100)
				end
			end, function()
				Browser:useDataFile(object)
				--print('downloadfinish finisned')
			end)
		else
			Browser:useDataFile(object)
		end
	end

	if om:check_isLocal(object) or object.tag == 'scene_random' then
		downloadfinish()
	elseif Browser.mode == 'repair' then
		if object.data and object.data.datafile then
			Global.FileSystem:downloadData(object.data.datafile, nil, downloadfinish)
		else
			downloadfinish()
		end
	elseif object.datafile then
		Global.FileSystem:downloadData(object.datafile, nil, downloadfinish)
		if Browser.objects[Browser.curIndex] == object then
			RPC('BrowseNewObject', {ID = object.id})
		end
	else
		downloadfinish()
	end

	self.beginTime = _tick()
	self.movetick = _tick() - 10000
end

return bi