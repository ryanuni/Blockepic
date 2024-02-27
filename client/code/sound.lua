local SoundGroup = _require('SoundGroup')
--local sg = SoundGroup.new()

local Sound = {
	playingSounds = {},
}

Global.Sound = Sound

local init = function()
	_sd.minDistance = 5
	_sd.maxDistance = 20

	_sd.autoListener = false
end

local function getPlayingSound(kind)
	local sounds = Sound.playingSounds
	if sounds[kind] then
		return sounds[kind]
	end

	local ps = {}
	ps.sg = SoundGroup.new()
	Sound.playingSounds[kind] = ps

	return ps
end

init()

Sound.update = function(self)
	for kind, ps in next, self.playingSounds do
		for n, v in next, ps do if n ~= 'sg' then
			if os.now() - v.playtick > v.duration then
				local index = math.random(1, #v.sounds)
				if index == v.index then
					index = index % #v.sounds + 1
				end
				v.index = index
				local s = v.sounds[v.index]
				if v.vec then
					self:play3D(s.res, v.vec, s.min or v.min, s.max or v.max, kind)
				else
					self:play(s.res, kind)
				end

				v.playtick = os.now()
				if s.duration then
					v.duration = math.random(s.duration[1], s.duration[2])
				else
					local ps = getPlayingSound(kind)
					local resourceInfo = _sd:getSoundInfo(ps.sg.currentRes)
					v.duration = resourceInfo and resourceInfo.duration or 1000
					print(ps.sg.currentRes)
				end
				-- print('BGM:', n, v.index, v.duration, s.res)
			end
		end end
	end
end

Sound.updatePos = function(self, pos, dir, up)
	_sd:setListener(pos, dir, up)
end

Sound.play = function(self, type, kind)
	if not kind or kind == '' then kind = 'global' end
	local ps = getPlayingSound(kind)

	-- print('sound:', type, debug.traceback())
	local sound = Global.SoundConfigsList[type]
	if not sound then
		return print('no sound:', sound)
	end

	if sound.mix then
		local s = {}
		s.playtick = os.now()
		s.sounds = sound
		s.duration = -1
		--self.playingSounds[type] = s
		ps[type] = s
		return
	end

	-- print('play sound', type, sound.loop, sound.volume)
	local sg = ps.sg
	sg:setLoop(sound.loop)
	sg:setVolume(sound.volume)
	sg:changePlaySource(type)
	sg:play()
end

Sound.play3D = function(self, type, vec, min, max, kind)
	if not kind or kind == '' then kind = 'global' end
	local ps = getPlayingSound(kind)

	local sound = Global.SoundConfigsList[type]
	if not sound then
		return
	end

	if sound.mix then
		local s = {}
		s.playtick = os.now()
		s.sounds = sound
		s.duration = -1
		s.vec = vec
		s.min = min
		s.max = max
		ps[type] = s
		return
	end

	local sg = ps.sg
	sg.mindistance = min
	sg.maxdistance = max

	-- print('play 3d sound', type, sound.loop, sound.volume, min, max)
	-- print('play 3d sound pos', vec.x, vec.y, vec.z)

	sg:setLoop(sound.loop)
	sg:setVolume(sound.volume)
	sg:changePlaySource(type)

	sg:play(vec)
end

Sound.stop = function(self, type, kind)
	if not kind or kind == '' then kind = 'global' end
	local ps = getPlayingSound(kind)

	if type then
		ps[type] = nil
	else
		local sg = ps.sg
		sg:stop()
		Sound.playingSounds[kind] = nil
	end
end