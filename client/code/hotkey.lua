local ui = Global.UI:new('HotKey.bytes', 'screen')
ui.visible = false

local HotKeySetting = {
	BUILDBRICK = 'BuildBrick',
}

local HotKey = {
	items = {}
}

Global.HotKey = HotKey

HotKey.clearItems = function(self)
	for i = #self.items, 1, -1 do
		self.items[i]:removeMovieClip()
	end
	self.items = {}
end

HotKey.addItem = function(self, hotkeytitle)
	local item = ui:loadView('htitem')
	item.key.text = hotkeytitle
	table.insert(self.items, item)
	return item
end

HotKey.show = function(self)
	self:clearItems()
	local state = Global.GameState.state
	local setting = Global[HotKeySetting[state.name]]
	if setting == nil then return end

	local sui = setting.ui
	if sui == nil or sui.visible == false then return end

	local hotkeys = state.callback and state.callback.addKeyDownEvents
	if hotkeys == nil then return end

	for i, v in ipairs(hotkeys) do
		for p, q in ipairs(v.ui or {}) do
			local u = sui
			for _, k in ipairs(q) do
				if u and u.visible then
					u = u[k]
				end
			end
			if u and u.visible and v.title and v.title ~= '' then
				local item = self:addItem(v.title)
				item.pairu = u
			end
		end
	end
	self:updateUIPos()
	ui.visible = true

	ui.onSizeChange = function()
		self:updateUIPos()
	end
	ui.bg.onMouseDown = function()
		self:hide()
	end
end

HotKey.updateUIPos = function(self)
	for _, item in ipairs(self.items) do
		local u = item.pairu
		local p = u:getMCRect().p1
		local x, y = Global.UI:UI2ScreenPos(p.x, p.y)
		item._x = x + u._width / 2
		item._y = y + u._height / 2
	end
end

HotKey.hide = function(self)
	if ui.visible == false then return end

	self:clearItems()
	ui.visible = false
	ui.onSizeChange = nil
end