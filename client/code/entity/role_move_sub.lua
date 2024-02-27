local Role = Global.Role

Role.gravity_set = function(g)
	_G.G = g
end
Role.gravity_get = function()
	return _G.G
end

Role.isInAir = function(self)
	return _and(self.cct.collisionFlag, 4) == 0
end
Role.speedUp = function(self, b)
	self.logic.speedUp = b
end
Role.setJumpLimit = function(self, times)
	self.logic.jumpLimit = times
end