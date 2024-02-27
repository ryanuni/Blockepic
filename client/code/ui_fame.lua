local Container = _require('Container')
local ui = Global.ui

Global.Fame_Gift_Level = {
	[1] = 5000,
	[2] = 10500,
	[3] = 16500,
	[4] = 23000,
	[5] = 30000,
}

local fame = {}
fame.timer = _Timer.new()
fame.init = function(self)
	if self.ui then return end
	self.ui = Global.UI:new('FameBag.bytes', 'screen')
	self.ui.visible = false

	local ui = self.ui.fameui
	ui.famelist.onRenderItem = function(index, item)
		item.count.text = 'X' .. index
		item.fnum.text = Global.Fame_Gift_Level[index]
		item.bgmine.visible = false
		item.bgother.visible = true
	end

	ui.famelist.itemNum = #Global.Fame_Gift_Level
	ui.confirm.disabled = true
	ui.confirm.click = function()
		Global.FameTask:openFameGift()
		self:show(false)
	end

	ui.cancel.click = function()
		self:show(false)
	end

	self.giftsnum = 0
end

fame.visible = function(self)
	return self.giftsnum ~= 0
end

fame.flushUI = function(self, tindex)
	self:init()

	if not tindex then tindex = 0 end
	local show = tindex ~= 0
	self.giftsnum = tindex
	if Global.sen then
		local giftb = Global.sen:getBlockByShape('gift')
		if giftb then
			giftb:setVisible(show, show)
		end
	end

	local ui = self.ui.fameui
	ui.confirm.disabled = tindex == 0
	ui.famelist.onRenderItem = function(index, item)
		item.count.text = 'X' .. index
		item.fnum.text = Global.Fame_Gift_Level[index]
		item.bgmine.visible = index == tindex
		item.bgother.visible = index ~= tindex
	end
	ui.famelist.itemNum = #Global.Fame_Gift_Level
end

fame.show = function(self, show)
	self:init()

	if show then
		Global.UI:pushAndHide('normal')
	else
		Global.UI:popAndShow()
		Tip()
	end

	if show then
		Global.FameTask:getFameGift()
		local callback = function()
			self.ui.visible = show
		end
		_G:holdbackScreen(self.timer, callback)
	else
		self.ui.visible = show
		Global.SwitchControl:set_render_on()
	end
end

Global.fameUI = fame