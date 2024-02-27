
local ds = {}
local STATE = {
	NONE = 1,
	DOWN = 2,
}

local pos = {
	x = 0,
	y = 0,
	x2 = 0,
	y2 = 0,
}

ds.enable = _sys.os == 'win32' or _sys.os == 'mac'
ds.state = STATE.NONE
ds.render = function(self)
	if pos.x ~= pos.x2 and pos.y ~= pos.y2 then
		_rd:fillRect(pos.x, pos.y, pos.x2, pos.y2, 0x33ffffff)
	end
end
ds.ignore = function(self)
	return math.abs(pos.x - pos.x2) < 4 and math.abs(pos.y - pos.y2) < 4
end
ds.dragRect = function(self)
	local bs = Global.sen:getRenderingBlocks()

	local x1 = math.min(pos.x2, pos.x)
	local x2 = math.max(pos.x2, pos.x)
	local y1 = math.min(pos.y2, pos.y)
	local y2 = math.max(pos.y2, pos.y)

	local out = _Vector2.new()
	local v = _Vector3.new()
	for _, b in ipairs(bs) do
		local t = b.data.space.translation
		_rd:projectPoint(t.x, t.y, t.z, out)
		if out.x > x1 and out.x < x2 and out.y > y1 and out.y < y2 then
			b:setEditState('dragselect')
		else
			b:setEditState('undragselect')
		end
	end
end
ds.onMouseDown = function(self, b, x, y)
	if self.enable == false then return false end
	if b ~= 0 then return end
--	print('[ds.onMouseDown]', b, x, y)
	pos.x = x
	pos.y = y
	pos.x2 = x
	pos.y2 = y
	self.state = STATE.DOWN
end
ds.onMouseMove = function(self, x, y)
	if self.enable == false then return false end
	if self.state ~= STATE.DOWN then return false end
--	print('[ds.onMouseMove]', x, y)
	pos.x2 = x
	pos.y2 = y
	self:dragRect()

	return true
end
ds.onMouseUp = function(self, b, x, y)
	if self.enable == false then return false end
	if b ~= 0 then return false end
	self.state = STATE.NONE
	if self:ignore() then return false end

	local x1 = math.min(pos.x2, pos.x)
	local x2 = math.max(pos.x2, pos.x)
	local y1 = math.min(pos.y2, pos.y)
	local y2 = math.max(pos.y2, pos.y)

	local out = _Vector2.new()
	local v = _Vector3.new()
	local nbs = {}
	local bs = Global.sen:getAllBlocks()

	for _, b in ipairs(bs) do
		local t = b.data.space.translation
		_rd:projectPoint(t.x, t.y, t.z, out)
		if out.x > x1 and out.x < x2 and out.y > y1 and out.y < y2 then
			table.insert(nbs, b)
		end
	end

	Global.editor:cmd_dragSelect(nbs)

	pos.x = pos.x2
	pos.y = pos.y2

	return true
end

ds.exit = function(self)
	self.state = STATE.NONE
end

return ds