
--[[
	物件管理
]]

local musiclibrary = {
}
Global.MusicLibrary = musiclibrary
musiclibrary.timer = _Timer.new()

musiclibrary.init = function(self)
	if self.ui then return end

	self.ui = Global.UI:new('MusicLibrary.bytes', 'normal', true)
	self.ui.mainlist.alphaRegion = 0x14000500

	self.ui.back.click = function()
		local mode = self.mode
		Global.UI:slideout({self.ui})
		Global.Timer:add('hideui', 150, function()
			self:show(false)

			-- print('self.mode', self.mode, table.ftoString(Global.AudioPlayer.curSource))
			if mode == 'MyMusic' then
				local music = Global.AudioPlayer.curSource
				if Global.AudioPlayer.state == Global.AudioPlayer.AUDIO_STATE.stop then
					music = nil
				end
				if music then
					Global.AudioPlayer:uploadCurrentSource(function(result)
						if result then
							RPC('UpdateMyMusic', {Music = {name = music.file.name, md5 = music.file.md5}})
							RPC('UpdateMyMusicPlaying', {Playing = true})
						else
							print('[upload error]')
						end
					end)
				else
					RPC('UpdateMyMusicPlaying', {Playing = false})
				end
				Global.ui.interact.open.click()
			elseif mode == 'BGM' then
				local music = self.selectmusic
				if music.name == 'Blank' then
					music = nil
				end
				Global.BuildBrick:setBGM(music)
			end
		end)
	end

	Global.UI:onDeviceOrientation(self.ui, function(oriH)
		-- refresh captureScreenImage
		self:show(false)
		self.timer:start('resetCapture', _app.elapse, function()
			self.timer:start('skip1', _app.elapse, function()
			self:show(true)
			self.timer:stop('skip1')
			end)
			self.timer:stop('resetCapture')
		end)
	end)
end

musiclibrary.show = function(self, show, mode, selmusic, closecb)
	self.mode = mode
	self:init()

	if show then
		Global.UI:pushAndHide('normal')
	else
		Global.UI:popAndShow('normal')
		Tip()
	end

	if show then
		local callback = function()
			Global.UI:slidein({self.ui})
			self.ui.visible = show
			self.ui.back.visible = show
			self:flush()
			self:onSelectMusic(selmusic)

			Global.AddHotKeyFunc(_System.KeyESC, function()
				return self.ui.visible
			end, function()
				self:show(false)
			end)
		end
		_G:holdbackScreen(self.timer, callback)
	else
		self.ui.visible = show
		self.ui.back.visible = show
		local musics = Global.AudioPlayer:getSourcesByType('default')
		for i, v in ipairs(musics) do
			v.onStateChange = nil
		end
		Global.SwitchControl:set_render_on()
		if self.closecb then
			self.closecb()
			self.closecb = nil
		end
	end

	self.closecb = closecb
end

musiclibrary.onSelectMusic = function(self, music)
	local showselect = self.mode == 'BGM'
	if not showselect or not self.oitems then return end

	for i, oiten in ipairs(self.oitems) do
		oiten.selbg.visible = oiten.music == music
	end
	self.selectmusic = music
end

musiclibrary.flush = function(self)
	if self.ui == nil or self.ui.visible == false then return end

	local musicclasses = Global.AudioPlayer:getTypeClasses('default')
	local bgs = {'1-2.png', '2-2.png'}
	local itemh = 280
	local itemw = 330
	local hgap = 18
	local wgap = 8
	local linenum = 0
	self.ui.mainlist.tweenable = false
	local addblank = self.mode == 'BGM'
	local play2d = self.mode == 'BGM'
	local showselect = self.mode == 'BGM'
	if addblank then
		table.insert(musicclasses, 1, 'Blank')
	end

	self.oitems = {}
	self.ui.mainlist.onRenderItem = function(index, item)
		local class = musicclasses[index]
		local musics
		if class == 'Blank' then
			musics = {}
			local music = Global.AudioPlayer:getBlankSource()
			table.insert(musics, music)
		else
			musics = Global.AudioPlayer:getSourcesByType('default', class)
		end

		item.title.text = string.upper(class) .. '(' .. #musics .. ')'
		local num = math.floor((self.ui.mainlist._width + wgap) / (itemw + wgap))
		item.itemlist.onRenderItem = function(oindex, oitem)
			local music = musics[oindex]
			oitem.music = music
			table.insert(self.oitems, oitem)

			local function syncState()
				local state = music:getState()
				oitem.play.visible = false
				oitem.stop.visible = false
				oitem.download.visible = false
				oitem.downloading.visible = false
				if state == music.class.SOURCE_STATE.init then
					oitem.download.visible = true
				elseif state == music.class.SOURCE_STATE.preparing or (music.timer and music.timer.isdownloading) then
					oitem.downloading.visible = true
				elseif state == music.class.SOURCE_STATE.prepared then
					oitem.play.visible = true
				elseif state == music.class.SOURCE_STATE.playing then
					oitem.stop.visible = true
				end
			end
			syncState()

			oitem.play.click = function()
				if play2d then
					Global.AudioPlayer:setCurrent2D(music)
					Global.AudioPlayer:play2D()
				else
					Global.AudioPlayer:setCurrent(music)
					Global.AudioPlayer:playCurrent()
				end

				self:onSelectMusic(music)
			end
			oitem.stop.click = function()
				if play2d then
					Global.AudioPlayer:stop2D()
				else
					Global.AudioPlayer:stop()
				end

				self:onSelectMusic(music)
			end
			oitem.download.click = function()
				music:prepare()
				local curtime = 0
				oitem.downloading.bar.currentValue = 0
				music.timer = _Timer.new()
				music.timer.isdownloading = true
				music.timer:start('download', 20, function()
					curtime = curtime + 20
					if curtime >= 500 then
						curtime = 495
					end
					oitem.downloading.bar.currentValue = curtime / 500 * 100
					if curtime >= 495 then
						music.timer:stop('download')
						music.timer.isdownloading = false
						syncState()
					end
				end)

				self:onSelectMusic(music)
			end

			oitem.click = function()
				self:onSelectMusic(music)
			end

			music.onStateChange = syncState

			oitem.time.text = string.ftoTimeFormat(music.time or 0)
			oitem.name.text = music.name
			local bgindex = (linenum + math.ceil(oindex / num) - 1) % 2 + 1
			oitem.bg._icon = 'img://' .. bgs[bgindex]

			if not showselect then
				oitem.selbg.visible = false
			end
		end
		local line = math.ceil(#musics / num)
		item.itemlist.itemNum = #musics
		item.itemlist._height = line * (itemh + hgap)
		linenum = linenum + line
	end

	self.ui.mainlist.itemNum = #musicclasses
end