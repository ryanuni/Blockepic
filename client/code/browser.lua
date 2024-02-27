---@diagnostic disable: need-check-nil

local om = Global.ObjectManager
local Browser = {timer = _Timer.new(), objects = {}}
Global.Browser = Browser

local BrowserItem = _dofile('browser_item.lua')
-- 1 (3 1 2) 2 (1 2 3) 3 (2 3 1)
Browser.POSINDEX = {
	[1] = {3, 1, 2},
	[2] = {1, 2, 3},
	[3] = {2, 3, 1},
}

Browser.upPos = _Vector2.new()
Browser.midPos = _Vector2.new()
Browser.downPos = _Vector2.new()

Browser.ClickSound = {
	{ui = 'build', sound = 'ui_inte04'},
	{ui = 'delete', sound = 'build_del01'},
	{ui = 'deleteupload', sound = 'ui_click12'},
	{ui = 'upload', sound = 'ui_click11'},
	{ui = 'like', sound = 'ui_click13'},
	{ui = 'collect', sound = 'ui_click14'},
	{ui = 'buy', sound = 'ui_click15'},
	{ui = 'enter', volume = 0},
	{ui = 'back', volume = 0},
}

Browser.init_ui = function(self)
	if self.ui then
		return
	end

	self.ui = Global.UI:new('Browser.bytes')
	self.ui.onSizeChange = function()
		self:onSizeChange()
	end
	self.bitems = {
		BrowserItem.new(self.ui.item1),
		BrowserItem.new(self.ui.item2),
		BrowserItem.new(self.ui.item3),
	}
	-- 配置UI点击声效
	for _, item in ipairs(self.bitems) do
		item.index = _
		for _, data in ipairs(self.ClickSound) do
			local ui = item.item[data.ui]
			if ui then
				ui._sound = Global.SoundList[data.sound]
				ui._soundVolumeScale = data.volume or Global.SoundConfigsList[data.sound].volume
			end
		end
	end
	self.ui.back._soundVolumeScale = 0
	self.ui.back.click = function()
		local cb = function()
			if Global.GameState:isState('BUILDBRICK') then
				Global.BuildBrick:reuseCamera()
			end
		end

		if self.mode == 'browser' then
			if self.tag == 'house' and Global.Achievement:check('fristbrowserroom') == false then
				Global.gmm.browserroomdone = true
			end

			Global.Sound:play(self.tag == 'house' and 'browser_outhouse' or 'browser_outbrick')
			Global.entry:back(cb)
		elseif self.mode == 'buildbrick' or self.mode == 'buildscene' then
			Browser:leave()
			self.timer:start('showbag', _app.elapse + 10, function()
				Global.BuildBrick:onDClick()
				self.timer:stop('showbag')
			end)
		elseif self.mode == 'buildhouse' then
			Browser:leave()
			self.timer:start('showbag', _app.elapse + 10, function()
				Global.BuildHouse:onDClick()
				self.timer:stop('showbag')
			end)
		elseif self.mode == 'showavatar' then
			Browser:leave()
		else
			Global.entry:back(cb)
		end
	end

	self.ui.screenshot.click = function()
		local item = Browser:get_item()
		local objectinfo = item.objectinfo
		if objectinfo then
			-- Global.DressAvatarShot:show(objectinfo.name or objectinfo.id)
			Global.DressAvatarShot:show(objectinfo.id or objectinfo.name)
			Global.DressAvatarShot.onExit = function()
				local newo = Global.getObject(objectinfo.id or objectinfo.name)
				if newo then
					objectinfo.title = newo.title
					objectinfo.state = newo.state
					Browser:flushItemButton()
				end
			end
		end
	end

	self:init_match()
end
Browser.init = function(self, objects, currentindex, needmore, tag, mode, buildmode)
	--	print('Browser.init!!!!!!!!!!!!!', needmore, mode, tag, buildmode, debug.traceback())
	self.lastWorldUVScale = _rd.worldUVScale
	--print('Browser.init', objects, currentindex, needmore, tag, mode, table.ftoString(objects))
	if mode == 'buildbrick' or mode == 'repair' or mode == 'buildhouse' or mode == 'showavatar' or mode == 'buildscene' then
		--self.tempCamera = _rd.camera:clone()
		Global.CameraControl:push()
		self.tempCamera = true
		--else
		--self.tempCamera = nil
	end

	assert(tag)
	assert(mode)
	self.tag = tag
	self.mode = mode
	self.buildmode = buildmode
	self.needmore = needmore

	self:init_ui()

	currentindex = currentindex or 1
	self.objects = {}
	if self:on_get_data(objects) then
	else
		self.timer:start('exit', 0, function()
			self.ui.back.click()
			self.timer:stop('exit')
		end)
		return
	end

	if currentindex > #self.objects then
		currentindex = #self.objects
	end

	self.curIndex = currentindex
	self.curbitemIndex = (self.curIndex - 1) % 3 + 1
	self:syncBrowerItems()
	self:onSizeChange()

	if self.mode == 'browser' then
		om:listen('browserobjects', function(obj, op)
			self:on_update(obj, op)
		end)
	end
end
Browser.get_item = function(self)
	return self.bitems[self.POSINDEX[self.curbitemIndex][2]]
end
Browser.flushItemButton = function(self)
	if self.ui and self.ui.visible then
		for i, item in ipairs(self.bitems) do
			item:syncButtonState()
		end
	end
end

Browser.onSizeChange = function(self)
	local h = self.ui._height
	Browser.upPos:set(0, -h)
	Browser.midPos:set(0, 0)
	Browser.downPos:set(0, h)

	for i, v in ipairs(self.bitems or {}) do
		v:onSizeChange()
	end
	self:playPageMove()
end
Browser.on_get_data = function(self, objs)
	for i, v in ipairs(objs) do
		self:on_update_one(v)
	end

	return #self.objects > 0
end

Browser.on_update_one = function(self, o)
	if self.needmore then
		if not om:check_isPublished(o) then
			return
		end
	end

	if o.mode == 'template' then
	else
		if self.tag == 'scene' then
			if not Global.isSceneType(o.tag) then
				return
			end
		else
			if self.tag ~= o.tag then
				return
			end
		end

		if om:check_exist(o) then
			o = om:getObject(o.name)
		else
			return
		end
	end
	local found = false
	for i, v in ipairs(self.objects) do
		if v.name == o.name then
			self.objects[i] = o
			o.index = i
			found = true
			break
		end
	end

	if not found then
		table.insert(self.objects, o)
		o.index = #self.objects
	end

	return true
end
Browser.on_delete_one = function(self, o)
	local found = false
	for i, v in ipairs(self.objects) do
		if v.name == o.name then
			found = true
			table.remove(self.objects, i)
			break
		end
	end

	if not found then return end

	if #self.objects == 0 then
		self.timer:start('exit', 0, function()
			self.ui.back.click()
			self.timer:stop('exit')
		end)
	else
		return true
	end
end
Browser.on_update = function(self, o, op)
	local ret
	if op == 'del' then
		ret = self:on_delete_one(o)
	else
		ret = self:on_update_one(o)
	end

	if ret then
		self:syncBrowerItems()
	end
end
Browser.getCurrentObject = function(self)
	return self.objects[self.curIndex]
end

Browser.leave = function(self)
	self.bitems = {}
	if self.ui then
		self:show_waiting(false)
		Global.UI:del(self.ui)
		self.ui = nil
	end

	self.needBlust = nil
	Tip()
	if self.tempCamera then
		Global.CameraControl:pop()
		self.tempCamera = nil
	end
	Global.Barrage:show(false)
	om:listen('browserobjects')

	if Global.sen then
		resetSceneConfig(Global.sen)
	end

	_rd.worldUVScale = self.lastWorldUVScale
end

Browser.useDataFile = function(self, object)
	if om:check_isLocal(object) then
		Block.clearCaches(object.name)
		Block.addDataCache(object.name, _dofile(object.datafile.name))
	end

	local index = object.index
	if index <= self.curIndex + 1 and index >= self.curIndex - 1 and #self.bitems > 0 then
		local item = self.bitems[Browser.POSINDEX[self.curbitemIndex][2 + (index - self.curIndex)]]
		item:useDataFile(object)
	end

	if om:check_isLocal(object) then
		Block.clearDataCache(object.name)
		Block.clearCaches(object.name)
	end
end

Browser.flushBrowserButton = function(self)
	local item = self:get_item()
	local object = item.objectinfo
	local istemplate = om:check_isTemplate(object)
	local ismine
	if istemplate then
		ismine = false
	else
		ismine = Global.Login:isMe(object.owner.aid)
	end

	Browser.ui.screenshot.visible = ismine and (object.tag == 'object' or object.tag == 'avatar')

	item.item.build.disabled = true
	item.item.preview.disabled = true
	Global.FileSystem:downloadData(object.datafile, nil, function()
		if Global.ObjectManager:getAvatarId() ~= object.id then
			if _sys.os == 'win32' or _sys.os == 'mac' then
				item.item.build.disabled = false
				item.item.preview.disabled = false
			end
		end
	end)

	--print('flushBrowserButton')
end
Browser.movePage = function(self, dy)
	for i, v in ipairs(self.bitems) do
		v.item._y = v.item._y + dy
	end
end

Browser.moveUpPage = function(self)
	if self.curIndex == 1 then return end
	self:move_page(-1)
end
Browser.move_page = function(self, di)
	self.curIndex = self.curIndex + di
	self.curbitemIndex = (self.curIndex - 1) % 3 + 1
	if self.tag == 'house' then
		Global.Sound:play('ui_showhouse')
	else
		Global.Sound:play('ui_showbrick')
	end
	self:syncBrowerItems()
end
Browser.moveDownPage = function(self)
	if self.curIndex == #self.objects then return end
	self:move_page(1)
	if self.needmore and self.curIndex >= #self.objects - 2 then
		self:ask_more_data()
	end
end

local movetime = 200
Browser.playPageMove = function(self, lindex)
	if lindex == nil then
		local order = Browser.POSINDEX[self.curbitemIndex]
		Global.UI.mmanager:addMovment(self.ui['item' .. order[1]], self.upPos, 0)
		Global.UI.mmanager:addMovment(self.ui['item' .. order[2]], self.midPos, 0)
		Global.UI.mmanager:addMovment(self.ui['item' .. order[3]], self.downPos, 0)
	elseif self.curIndex == lindex then
		local order = Browser.POSINDEX[self.curbitemIndex]
		Global.UI.mmanager:addMovment(self.ui['item' .. order[1]], self.upPos, movetime)
		Global.UI.mmanager:addMovment(self.ui['item' .. order[2]], self.midPos, movetime)
		Global.UI.mmanager:addMovment(self.ui['item' .. order[3]], self.downPos, movetime)
		self.bitems[order[1]]:setDisableTime(movetime)
		self.bitems[order[2]]:setDisableTime(movetime)
		self.bitems[order[3]]:setDisableTime(movetime)
	elseif self.curIndex < lindex then
		local order = Browser.POSINDEX[self.curbitemIndex - 1] or Browser.POSINDEX[3]
		Global.UI.mmanager:addMovment(self.ui['item' .. order[1]], self.downPos, movetime)
		Global.UI.mmanager:addMovment(self.ui['item' .. order[2]], self.upPos, 0)
		Global.UI.mmanager:addMovment(self.ui['item' .. order[3]], self.midPos, movetime)
		self.bitems[order[1]]:setDisableTime(movetime)
		self.bitems[order[3]]:setDisableTime(movetime)
	elseif self.curIndex > lindex then
		local order = Browser.POSINDEX[self.curbitemIndex + 1] or Browser.POSINDEX[1]
		Global.UI.mmanager:addMovment(self.ui['item' .. order[1]], self.midPos, movetime)
		Global.UI.mmanager:addMovment(self.ui['item' .. order[2]], self.downPos, 0)
		Global.UI.mmanager:addMovment(self.ui['item' .. order[3]], self.upPos, movetime)
		self.bitems[order[1]]:setDisableTime(movetime)
		self.bitems[order[3]]:setDisableTime(movetime)
	end
end
Browser.ask_more_data = function(self)
	if self.tag == 'house' then
		RPC('House_GetRecommendList')
	elseif self.tag == 'object' then
		RPC('GetRecommandObjects')
	elseif self.tag == 'scene' then
		RPC('GetSceneList')
	end
end

Browser.syncBrowerItems = function(self)
	for i, cindex in ipairs(Browser.POSINDEX[self.curbitemIndex]) do
		self.bitems[cindex]:changeObject(self.objects[self.curIndex + i - 2], i == 2)
	end
	self:flushBrowserButton()
	Global.AudioPlayer:stop()
	local curObject = self.objects[self.curIndex]
	if not curObject then
		return
	end

	if curObject.musicfile then
		local audio = Global.AudioPlayer:createAudio(curObject.musicfile.name, curObject.musicfile)
		if audio then
			Global.AudioPlayer:setCurrent(audio)
			if curObject.playingmusic then
				Global.AudioPlayer:playCurrent()
			end
		end
	end
	-- if curObject then
	-- 	if curObject.id then
	-- 		Global.ObjectBarrage:getBarragesByID(curObject.id, function(barrages)
	-- 			if #barrages > 0 then
	-- 				Global.Barrage:show(false)
	-- 				Global.Barrage:show(true, barrages)
	-- 			else
	-- 				Global.Barrage:show(false)
	-- 			end
	-- 		end, false)
	-- 	end
	-- end
	-- self:render(0) -- TODO.
	-- self:print()
end

Browser.print = function(self)
	print('curIndex', self.curIndex)
	print('curbitemIndex', self.curbitemIndex)
	for i, cindex in ipairs(Browser.POSINDEX[self.curbitemIndex]) do
		print(cindex, self.curIndex + i - 2, self.bitems[cindex].item.visible)
	end
end

Browser.render = function(self, e)
	if self.ui then
		self.ui.back._y = Global.UI:safeArea_getUP()
		for i, v in ipairs(self.bitems) do
			v:update(e)
		end
		for i, v in ipairs(self.bitems) do
			v:render(e)
		end
	end
end

Browser.showCameraHint = function(self, show, x, y)
	self.ui.camera.visible = show
	if show then
		self:updateCameraHint(x, y)
	end
end

Browser.updateCameraHint = function(self, x, y)
	local camera = self.ui.camera
	if not camera.visible then return end
	camera._x = x - camera._width * 0.5
	camera._y = y - camera._height - 60
end

------------ match
Browser.init_match = function(self)
	-- waiting
	self.ui.bg.visible = false
	self.ui.waiting.visible = false
	self.ui.waiting.cancel.click = function()
		Global.Room_New:Leave()
		self:show_waiting(false)
	end

	-- result
	-- self.ui.result.ok.click = function()
	-- 	self:next_result()
	-- end
end
Browser.show_waiting = function(self, show, current, total)
	print('show_waiting', show, current, total, debug.traceback())
	if show then
		self.waiting_current = current
		self.waiting_total = total

		self.ui.bg.visible = true
		self.ui.waiting.visible = true
		self.ui.waiting.text_main.text = 'Matching...   ' .. current .. '/' .. total
		if not self.waiting_timer then
			self.waiting_timer = _Timer.new()
			self.waiting_timer.acc = 0
			self.ui.waiting.text_time.text = '00:00'
			self.waiting_timer:start('waiting', 1000, function()
				self.waiting_timer.acc = self.waiting_timer.acc + 1
				-- format time  xx:xx
				local t = self.waiting_timer.acc
				local m = math.floor(t / 60)
				local s = t % 60
				self.ui.waiting.text_time.text = string.format('%02d:%02d', m, s)
			end)
		end
	else
		self.ui.bg.visible = false
		self.ui.waiting.visible = false
		if self.waiting_timer then
			self.waiting_timer:stop()
			self.waiting_timer = nil
		end
	end
end
Browser.dec_waiting = function(self)
	self.waiting_current = self.waiting_current - 1
	self:show_waiting(true, self.waiting_current, self.waiting_total)
end
Browser.prepare_waiting = function(self)
	self.ui.waiting.text_main.text = 'Preparing...'
end
Browser.show_result = function(self, result)
	self.result_step = 0
end
Browser.next_result = function(self)
end

Global.GameState:onEnter(function(...)
	Browser:init(...)
	-- 5月版本不显示金币声望
	-- Global.CoinUI:show(true)
	Global.CoinUI:show(false)
	Global.ProfileUI:show(false)
	_app:onWheel(function(d)
		local item = Browser.bitems[Browser.curbitemIndex]
		if item then item.camera:scaleD(d * 0.5) end
	end)
	_app:changeScreen(2)
	-- 5月版本不展示引导
	-- if Browser.tag == 'object' and Browser.mode == 'browser' then
	-- 	if Global.Achievement:check('introduceshowobject') == false then
	-- 		Global.Introduce:show('showobject')
	-- 		Global.Achievement:ask('introduceshowobject')
	-- 	end
	-- end
end, 'BROWSER')

Global.GameState:onLeave(function()
	Browser:leave()
	-- Global.CoinUI:show(false)
	-- Global.CoinUI:show(true)
	_app:onWheel()
	_app:changeScreen(0)
end, 'BROWSER')
