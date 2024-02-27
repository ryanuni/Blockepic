
local co = {}
Global.ChipObject = co
----------------------------------------------------
co.new = function(host)
	local o = {}
	o.host = host
	o.events = {}
	setmetatable(o, {__index = co})
	return o
end
co.register_event = function(self, event, params, func)
	-- print('chip.register_event', event, params)
	if not self.events[event] then
		self.events[event] = {}
	end

	table.insert(self.events[event], func)

	self.host:init_event(event, params)
end
co.call_event = function(self, event, ...)
	local es = self.events[event]
	-- print('chip.call_event', event, es, ...)
	if not es then
		return
	end

	for _, e in ipairs(es) do
		e(...)
	end
end
