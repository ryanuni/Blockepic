
local ge = {events = {}}
Global.GameEvent = ge

ge.update = function(self, e)
	for i, v in ipairs(self.events) do
		if v.event.type == e.event.type then
			self.events[i] = e
			return
		end
	end

	table.insert(self.events, e)
end
ge.get = function(self, g)
	for i, v in ipairs(self.events) do
		if v.event.type == g then
			return v
		end
	end

	return {}
end
ge.get_eid = function(self, g)
	for i, v in ipairs(self.events) do
		if v.event.type == g then
			return v.event.id
		end
	end
end

define.UpdateEventInfo{Info = {}}
when{}
function UpdateEventInfo(Info)
	ge:update(Info)
	print("UpdateEventInfo", table.ftoString(Info))
end

------------------------------------------------------------
local gi = {info = {}}
Global.GameInfo = gi
gi.update = function(self, i)
	self.info = i
	for _, v in ipairs(self.info) do
		-- print(v.game, v.gid)
		Global.ObjectManager:newObj(v.object)
	end
end
gi.get_object = function(self, game)
	for i, v in ipairs(self.info) do
		if v.game == game then
			return Global.ObjectManager:getObject(v.gid)
		end
	end
end
gi.get_game = function(self, o)
	for i, v in ipairs(self.info) do
		if v.object.name == o.name then
			return v.game
		end
	end
end

define.GetGameInfo{Info = {}}
when{}
function GetGameInfo(Info)
	gi:update(Info)
end