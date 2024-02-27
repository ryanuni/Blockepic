local Container = _require('Container')
local MarioPlayer = {}
_G.MarioPlayer = MarioPlayer
MarioPlayer.new = function(cha, name, lifes)
	local nuplayer = {}
	setmetatable(nuplayer, {__index = MarioPlayer})

	nuplayer.cha = cha

	nuplayer.name = name

	-- game logic
	nuplayer.isFinished = false

	return nuplayer
end

MarioPlayer.destory = function(self)
	self.cha:release()
end

MarioPlayer.getRole = function(self)
	return self.cha
end

MarioPlayer.isFinish = function(self)
	return self.isFinished
end

MarioPlayer.playAnima = function(self, anima)
	if not self.cha then return end
	self.cha:playAnima(anima)
end
