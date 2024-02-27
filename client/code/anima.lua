
local animaState = {}
animaState.stateMap = {
	init = {},
	idle = {
		jump = true,
		fall = true,
		run = true,
	},
	run = {
		jump = true,
		fall = true,
		idle = true,
	},
	jump = {
		jump2 = true,
		fall = true,
		run = true,
		idle = true,
	},
	fall = {
		idle = true,
		run = true,
		jump = true,
		jump2 = true,
	},
	jump2 = {
		fall = true,
	},
}
for s in next, animaState.stateMap do
	animaState.stateMap.init[s] = true
end
animaState.new = function()
	local s = {}
	s.state = 'init'
	s.able = true

	setmetatable(s, {__index = animaState})

	return s
end
animaState.update = function(self, zspeed, zdis, jstate, rstate)
	if Global.dungeon then return end
	if self.able == false then return end

	local nextstate = jstate == 0 and rstate or 'jump'

	if zspeed > 0 then
		nextstate = 'jump'
		if jstate == 2 then
			nextstate = 'jump2'
		end
	elseif zspeed < -0.003 then
		nextstate = 'fall'
	end

	if animaState.stateMap[self.state][nextstate] then
		self.state = nextstate
		self.onChange(nextstate)
	end
end
animaState.changeAnima = function(self, state)
	if self.able == false then return end

	if not animaState.stateMap[self.state][state] then
		return
	end

	self.state = state
	self.onChange(state)
end
animaState.onChange = function(self, s)
	print('onChange', s)
end

animaState.isJumping = function(self)
	return self.state == 'jump' or self.state == 'jump2' or self.state == 'fall'
end

return animaState