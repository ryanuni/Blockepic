local Moment = _dofile('Moment.lua')

local TimeOfDayManager = {}

-- setmetatable(TimeOfDayManager, {__newindex = function(t, k, v)
-- 	local vv = v
-- 	if type(v) == 'function' then
-- 		if k ~= 'update'
-- 			then
-- 			vv = function(self, ...)
-- 				print(k, self, ..., debug.traceback())
-- 				return v(self, ...)
-- 			end
-- 		end
-- 	end
-- 	rawset(t, k, vv)
-- end})

Global.TimeOfDayManager = TimeOfDayManager
TimeOfDayManager.moments = {}
TimeOfDayManager.paused = true
TimeOfDayManager.curTime = 0
TimeOfDayManager.enable = true
TimeOfDayManager.enableFog = true

local ONEDAY_ELAPSE = 40000

TimeOfDayManager.init = function(self)
	local time = Global.SaveManager:Get('time')
	self.curTime = time and time[1] or 12
end
TimeOfDayManager.config = function(self)
	-- load 4 sen of (0:00, 6:00, 12:00, 18:00)
	if Version:isAlpha1() then
		local resname = 'home_alpha1_'
		self:addSceneMoment(resname .. '0.sen')
		self:addSceneMoment(resname .. '6.sen')
		self:addSceneMoment(resname .. '12.sen')
		self:addSceneMoment(resname .. '18.sen')
		self:addSceneMoment(resname .. 'inside_0.sen')
		self:addSceneMoment(resname .. 'inside_6.sen')
		self:addSceneMoment(resname .. 'inside_12.sen')
		self:addSceneMoment(resname .. 'inside_18.sen')
	else
		self:addSceneMoment('home_0.sen')
		self:addSceneMoment('home_6.sen')
		self:addSceneMoment('home_12.sen')
		self:addSceneMoment('home_18.sen')
	end
end
TimeOfDayManager.setCurrentTime = function(self, cur, flag, onlyColor)
	if self.enable == false then return end
	self.curTime = cur or self.curTime
	local ci = math.floor(self.curTime / 6)
	local factor = math.fmod(self.curTime, 6) / 6
	ci = ci
	local ni = ci + 1
	ni = ni == 4 and 0 or ni
	local m
	if not flag then
		m = Moment.lerp(self.moments[ci * 6], self.moments[ni * 6], factor)
	else
		local last = flag .. ci * 6
		local next = flag .. ni * 6
		m = Moment.lerp(self.moments[last], self.moments[next], factor)
	end
	if Global.sen then m:apply(Global.sen, onlyColor) end

	if Global.sen.skyBox then
		local m = Global.sen.skyBox.mesh
		local mtl = m.material
		mtl.UVOffset.x = (Global.TimeOfDayManager.curTime - 6) / 24
	end
end

TimeOfDayManager.setCurrentTime1 = function(self, cur, flag, sen)
	if self.enable == false then return end
	self.curTime = cur or self.curTime
	local ci = math.floor(self.curTime / 6)
	local factor = math.fmod(self.curTime, 6) / 6
	ci = ci
	local ni = ci + 1
	ni = ni == 4 and 0 or ni
	local m
	if not flag then
		m = Moment.lerp(self.moments[ci * 6], self.moments[ni * 6], factor)
	else
		local last = flag .. ci * 6
		local next = flag .. ni * 6
		m = Moment.lerp(self.moments[last], self.moments[next], factor)
	end
	if sen then m:apply(sen) end
end

TimeOfDayManager.cancel = function(self, sen)
	if self.enable == false then return end
	if Global.sen then Global.sen:useBackupGraData() end
end

TimeOfDayManager.update = function(self, e)
	if self.paused then return end

	-- 单位小时
	self.curTime = self.curTime + e * 24 / ONEDAY_ELAPSE
	if self.curTime >= 24 then self.curTime = 0 end
	self:setCurrentTime(self.curTime)
end
TimeOfDayManager.reset = function(self, time)
	self.curTime = 0
end
TimeOfDayManager.start = function(self)
	self.paused = false
end
TimeOfDayManager.stop = function(self)
	self.paused = true
end
TimeOfDayManager.addSceneMoment = function(self, resname)
	if resname == '' then return end
	local name, moment = resname:match('(.+)_(.-)%.sen')
	local sen = _Scene.new(resname)
	local timeflag = tonumber(moment)
	if string.find(name, 'inside') then
		timeflag = 'inside' .. tonumber(moment)
	end
	self:addMoment(sen, timeflag)
	sen = nil
	_gc()
end
TimeOfDayManager.addMoment = function(self, sen, moment)
	local m = Moment.new(sen, moment)
	self.moments[moment] = m
end
TimeOfDayManager.debug = function(self)
	print(table.ftoString(self))
end

TimeOfDayManager:config()
_app:registerUpdate(TimeOfDayManager)