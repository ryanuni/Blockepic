
local ui = Global.UI:new('Parkour.bytes')
Global.UIParkour = ui

_dofile('ui_joy.lua')
_dofile('ui_operate.lua')
ui.show = function(self, s)
	if not _sys:isMobile() then
		s = false
	end

	self.joy:show(s)
	self.jumpbutton.visible = s
	self.focusbutton.visible = s
	self.highspeedbutton.visible = s
	if Global.sen.setting.specialtype == 'homeparkour' then
		self.jumpbutton.visible = false
		self.focusbutton.visible = false
		self.highspeedbutton.visible = false
	end
end
ui.moveGuide = function(self)
	-- print('[UIParkour.moveGuide]')
	self.joy:show(true)
	self:gotoAndPlay('moveguide')
end
ui.jumpGuide = function(self)
	self.jumpbutton.visible = true
	self.focusbutton.visible = true
	self.highspeedbutton.visible = true
	self:gotoAndPlay('jumpguide')
end
