
local debug = Global.Debug

local tick = 0
debug.beginProfile = function(self)
	print('[Global.Debug.beginProfile]')
	_debug:beginCallRecord(true, true)
	tick = _tick()
end
debug.endProfile = function(self)
	print('[Global.Debug.endProfile]')
	tick = _tick() - tick
	local rs = _debug:endCallRecord()
	local sumtime = 0
	local nrs = {}
	for i, r in ipairs(rs) do
		sumtime = sumtime + r.totaltime
		local found = false
		for ii, rr in ipairs(nrs) do
			if rr.name == r.name and rr.source == r.source and rr.line == r.line then
				found = true
				rr.totaltime = rr.totaltime + r.totaltime
				rr.count = rr.count + r.count
				break
			end
		end

		if found == false then
			nrs[#nrs + 1] = r
		end
	end
	print(string.format('RealTime:%.2f | CallTime:%.2f(%%%.2f)', tick, sumtime, sumtime / tick * 100))
	table.sort(nrs, function(a, b)
		return a.totaltime > b.totaltime
	end)
	for i, r in ipairs(nrs) do
		print(string.format('Percentage:%%%.2f | TotalTime:%.2f | AvgTime:%.2f | Count:%4d | From:%s(%s:%s)',
			r.totaltime / sumtime * 100,
			r.totaltime, r.totaltime / r.count, r.count,
			r.name, r.source, r.line)
		)
	end
end

debug.enableMonitor = function(self, enable)
	_debug.enableProfiler = enable
	_debug.enable = enable
	_debug.monitor = enable
end

debug.ticks = {}
debug.ticks_t = {}
local x, y = 10, 10
local temp = 0
debug.beginTick = function(self, name)
	if not self.ticks[name] then
		if x > _rd.w then
			x = 10
			y = y + 210
		end
		_debug:addMonitor(name, 100, x, y, 200, 200, function()
			return self.ticks[name]
		end)
		x = x + 210
		self.ticks[name] = 0
	end
	self.ticks_t[name] = _tick()
end

debug.addTick = function(self, name, v)
	local t = self.ticks[name]
	self.ticks[name] = t + (v or (_tick() - self.ticks_t[name]))
	self.ticks_t[name] = _tick()
end

