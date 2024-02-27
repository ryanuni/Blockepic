local AudioPlayer = {
	sources = {
		default = {},
		library = {},
	},
	AUDIO_STATE = {
		preparing = 1,
		playing = 2,
		stop = 3,
	}
}
Global.AudioPlayer = AudioPlayer

local AudioSource = _require('AudioSource')
local SoundGroup = _require('SoundGroup')

AudioPlayer.init = function(self, location, min, max)
	self.soundgroup = SoundGroup.new({
		mindistance = min or 2,
		maxdistance = max or 45,
	})
	self.location = location or _Vector3.new()

	-- 默认循环
	self.soundgroup:setLoop(false)
	self.state = self.AUDIO_STATE.stop

	-- 当前需要播的音乐资源
	self.curSource = nil
	self.cur2DSource = nil
end

AudioPlayer:init()

AudioPlayer.isInList = function(self, md5)
	for i, v in ipairs(self.sources.default) do
		if md5 == v:getFileMd5() then
			return 'default', i
		end
	end
	for i, v in ipairs(self.sources.library) do
		if md5 == v:getFileMd5() then
			return 'library', i
		end
	end

	return
end

AudioPlayer.initDefaultSources = function(self)
	self.sources.default = {}
	RPC('GetDefaultSources', {})
end

local default_data_list = {
	'name', 'file', 'class'
}

local default_data_file_list = {
	'md5', 'url', 'fid', 'name'
}

AudioPlayer.setVolume = function(self, volume)
	self.soundgroup.soundGroup.volume = volume
end

AudioPlayer.checkDefaultData = function(self, data)
	for _, key in ipairs(default_data_list) do
		if not data[key] then
			print('[AudioPlayer.checkDefaultData] error not exist', key)
			return false
		end
	end
	for _, key in ipairs(default_data_file_list) do
		if not data.file[key] then
			print('[AudioPlayer.checkDefaultData] error file not exist', key)
			return false
		end
	end

	return true
end

AudioPlayer.addDefaultSource = function(self, data)
	if not self:checkDefaultData(data) then
		return
	end

	data.type = AudioSource.SOURCE_TYPE.default
	local as = AudioSource.new(data)

	table.insert(self.sources.default, as)
end

AudioPlayer.getBlankSource = function(self)
	if not self.sources.blank then
		self.sources.blank = {}
	end

	if not self.sources.blank[1] then
		local data = {}
		data.type = AudioSource.SOURCE_TYPE.blank
		data.name = 'Blank'
		data.time = 0
		data.class = 'Blank'
		local as = AudioSource.new(data)
		table.insert(self.sources.blank, as)
	end

	return self.sources.blank[1]
end

AudioPlayer.getTypeClasses = function(self, type, addBlankMusic)
	local classes = {}
	local tempclasses = {}
	local musics = self.sources[type]
	for i, v in ipairs(musics) do
		local class = v:getClass()
		if tempclasses[class] == nil then
			table.insert(classes, class)
			tempclasses[class] = class
		end
	end

	return classes
end

AudioPlayer.getSourcesByType = function(self, type, class)
	local musics = self.sources[type]
	if class then
		local result = {}
		for i, v in ipairs(musics) do
			if v:getClass() == class then
				table.insert(result, v)
			end
		end
		return result
	else
		return musics
	end
end

AudioPlayer.getSourceByName = function(self, type, name)
	local musics = self.sources[type]
	for i, v in ipairs(musics) do
		if v:getName() == name then
			return v
		end
	end
end

AudioPlayer.setMute = function(self, mute)
	self.soundgroup.mute = mute
end

AudioPlayer.setCurrent2D = function(self, as)
	if self.cur2DSource == as then return end

	if self.state == self.AUDIO_STATE.playing then
		self:stop2D()
	end
	self.cur2DSource = as
end

-- 试听库中2d 音乐
AudioPlayer.play2D = function(self)
	if not self.cur2DSource then
		print('[AudioPlayer:playCurrent] cur2DSource not exist')
		return
	end

	if not self.cur2DSource:isReady() then
		print('[AudioPlayer:play] source not ready')
		return
	end

	if self.state == self.AUDIO_STATE.playing then
		return
	end

	self.state = self.AUDIO_STATE.playing
	self:playResource(self.cur2DSource:getFileName())
	self.cur2DSource:setState(AudioSource.SOURCE_STATE.playing)
end

AudioPlayer.stop2D = function(self)
	if self.state ~= self.AUDIO_STATE.playing then
		return
	end

	self.state = self.AUDIO_STATE.stop
	self.soundgroup:stop()
	if self.cur2DSource then
		self.cur2DSource:setState(AudioSource.SOURCE_STATE.prepared)
	end
	self.playinginfo = nil
end

AudioPlayer.setLocation = function(self, vec)
	self.location.x = vec.x
	self.location.y = vec.y
	self.location.z = vec.z
end

AudioPlayer.createAudio = function(self, name, file, class)
	local type, index = self:isInList(file.md5)
	if type and index then
		return self.sources[type] and self.sources[type][index]
	-- 他人的自定义音乐
	else
		local data = {}
		data.name = name
		data.file = file
		data.class = class or "unknown"
		if not self:checkDefaultData(data) then
			return
		end
		data.type = AudioSource.SOURCE_TYPE.default
		return AudioSource.new(data)
	end
end

AudioPlayer.setCurrent = function(self, as)
	if self.curSource == as then return end

	if self.state == self.AUDIO_STATE.playing then
		self:stop()
	end
	self.curSource = as
end

--- onfinish @return table file or nil
AudioPlayer.uploadCurrentSource = function(self, onfinish)
	if not self.curSource then
		print('[AudioPlayer:uploadCurrentSource] curSource not exist')
		if onfinish then
			onfinish()
		end
		return
	end

	self.curSource:upload(onfinish)
end

-- 3d 声音 , 没准备好需要先准备
AudioPlayer.playCurrent = function(self)
	if not self.curSource then
		print('[AudioPlayer:playCurrent] curSource not exist')
		return
	end

	if self.state == self.AUDIO_STATE.playing then
		return
	end

	if self.curSource:isReady() then
		self.state = self.AUDIO_STATE.playing
		self:playResource(self.curSource:getFileName(), self.location)
		self.curSource:setState(AudioSource.SOURCE_STATE.playing)
	else
		self.state = self.AUDIO_STATE.preparing
		self.curSource.onFinish = function()
			if self.curSource:isReady() then
				if self.state == self.AUDIO_STATE.preparing then
					self.state = self.AUDIO_STATE.playing
					self:playResource(self.curSource:getFileName(), self.location)
					self.curSource:setState(AudioSource.SOURCE_STATE.playing)
				end
			else
				print('[AudioPlayer.playCurrent] curSource prepare error')
			end
		end

		self.curSource:prepare()
	end
end

AudioPlayer.playResource = function(self, filename, location)
	self.playinginfo = {filename = filename, location = location}
	self.soundgroup:playResource(filename, location)
end

AudioPlayer.stop = function(self)
	if self.state ~= self.AUDIO_STATE.playing then
		return
	end

	self.state = self.AUDIO_STATE.stop
	self.soundgroup:stop()
	if self.curSource then
		self.curSource:setState(AudioSource.SOURCE_STATE.prepared)
	end
	self.playinginfo = nil
end

AudioPlayer.specialupdate = function(self, e)
	if self.playinginfo == nil then return end
	if self.soundgroup.soundGroup:isPlaying() == true then return end

	if self.playinginfo.tick then
		self.playinginfo.tick = self.playinginfo.tick + e
	else
		self.playinginfo.tick = e
	end

	if self.playinginfo.tick > 5000 then
		self.soundgroup:playResource(self.playinginfo.filename, self.playinginfo.location)
		self.playinginfo.tick = 0
	end
end

_app:registerUpdate(AudioPlayer, 7)

-------------------------------------------------------

define.SetDefaultSources{Sources = {}}
when{}
function SetDefaultSources(Sources)
	for i, v in ipairs(Sources) do
		-- print('SetDefaultSources', table.ftoString(v))
		AudioPlayer:addDefaultSource(v)
	end
end