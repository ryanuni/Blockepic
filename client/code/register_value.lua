local registervalue = {
	NONE = 0,
	AX = 1,
	BX = 2,
	CX = 3,
	DX = 4,
	EX = 5,
	MINE = {SCORE = 6, STATUS = 7, POS = 8, DIR = 9},
	Memory = {0, 0, 0, 0, 0},
	Listeners = {},
}

registervalue.enumNum = 9
registervalue.numberOpinions = {
	{value = registervalue.None, displayName = 'None'},
	{value = registervalue.AX, displayName = 'Number1'},
	{value = registervalue.BX, displayName = 'Number2'},
	{value = registervalue.CX, displayName = 'Number3'},
	{value = registervalue.DX, displayName = 'Number4'},
	{value = registervalue.EX, displayName = 'Number5'},
	{value = registervalue.MINE.SCORE, displayName = 'Mine.score'},
	{value = registervalue.MINE.STATUS, displayName = 'Mine.status'},
	{value = registervalue.MINE.POS, displayName = 'Mine.pos'},
	{value = registervalue.MINE.DIR, displayName = 'Mine.dir'},
}

for i = 1, 7 do
	registervalue['P' .. i] = {SCORE = registervalue.enumNum + 1, STATUS = registervalue.enumNum + 2, POS = registervalue.enumNum + 3, DIR = registervalue.enumNum + 4}
	registervalue.enumNum = registervalue.enumNum + 4

	table.insert(registervalue.numberOpinions, {value = registervalue['P' .. i].SCORE, displayName = 'Player' .. i .. '.score'})
	table.insert(registervalue.numberOpinions, {value = registervalue['P' .. i].STATUS, displayName = 'Player' .. i .. '.status'})
	table.insert(registervalue.numberOpinions, {value = registervalue['P' .. i].POS, displayName = 'Player' .. i .. '.pos'})
	table.insert(registervalue.numberOpinions, {value = registervalue['P' .. i].DIR, displayName = 'Player' .. i .. '.dir'})
end

registervalue.reset = function(self)
	for i, v in ipairs(self.Memory) do
		self:setValue(i, 0)
	end

	self.Listeners = {}
end

registervalue.setValue = function(self, rx, value)
	if rx == registervalue.NONE then return end

	local ovalue = self.Memory[rx]
	self.Memory[rx] = value
	for _, l in pairs(self.Listeners[rx] or {}) do
		if l.onListenRegisterValue then
			l:onListenRegisterValue(rx, ovalue, value)
		end
	end
end

registervalue.getValue = function(self, rx)
	if rx == registervalue.NONE then return end

	if self.Memory[rx] == nil then
		self.Memory[rx] = 0
	end

	return self.Memory[rx]
end

registervalue.addListener = function(self, rx, listener)
	if rx == registervalue.NONE then return end

	if self.Listeners[rx] == nil then
		self.Listeners[rx] = {}
	end
	self.Listeners[rx][listener] = listener
end

registervalue.delListener = function(self, rx, listener)
	if rx == registervalue.NONE then return end

	if self.Listeners[rx] == nil then
		self.Listeners[rx] = {}
	end
	self.Listeners[rx][listener] = nil
end

registervalue.print = function(self)
	for i = 1, registervalue.enumNum do
		print(i, self.Memory[i])
	end
end

Global.RegisterValue = registervalue