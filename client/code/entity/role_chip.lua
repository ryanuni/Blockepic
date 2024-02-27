
local Role = Global.Role

Role.chip_register_event = function(self, event, params, func)
	print('role:chip_register_event', event, params)
	self.chip_object:register_event(event, params, func)
end
Role.chip_call_event = function(self, event, ...)
	self.chip_object:call_event(event, ...)
end
Role.registerGameBegin = function(self, func)
	self.chip_object:register_event('GameBegin', nil, func)
end

Role.attr_add_life = function(self, dlife)
	if dlife == 0 then return end

	local maxlife = self:attr_get('MaxLife')
	local life = self:attr_get('Life')
	local newlife = life + dlife
	if newlife > maxlife then
		newlife = maxlife
	elseif newlife < 0 then
		newlife = 0
	end
	if life == newlife then
		return
	end

	self:attr_set('Life', newlife)

	if dlife > 0 then
		-- event addlife

	else
		-- event loselife
	end

	Global.dungeon:ui_update_life(self)

	-- 临时处理死
	if newlife == 0 and not self.is_dead then
		-- event die
		self:chip_call_event('Die')
		self.is_dead = true
		self:playAnima('liedown')
		self.cct = nil
	end
end
Role.attr_set_life = function(self, life)
	assert(type(life) == 'number')
	local oldlife = self:attr_get('Life')
	self:attr_add_life(life - oldlife)
end
Role.attr_set_maxlife = function(self, maxlife)
	assert(type(maxlife) == 'number')
	if self:attr_get('MaxLife') == maxlife then
		return
	end

	self:attr_set('MaxLife', maxlife)
	self:attr_set('Life', math.min(self:attr_get('Life'), maxlife))
	Global.dungeon:ui_update_life(self)
end
Role.attr_set_score = function(self, s)
	self:attr_set('Score', s)
	Global.dungeon:update_score(self)
end
Role.attr_get = function(self, key)
	return self.attrs[key]
end
Role.attr_set = function(self, key, value)
	if self.is_dead then
		print('[role.attr_set] dead return')
		return
	end
	if self.attrs_readonly_keys[key] then return end
	self.attrs[key] = value
end
Role.Speed_get = function(self, key)
	return self.Speeds[key]
end
Role.Speed_set = function(self, key, value)
	if self.is_dead then
		print('[role.Speed_set] dead return')
		return
	end
	self.Speeds[key] = value
end
