local FullScreenNotice = {}

local ui = Global.UI:new('FullScreenNotice.bytes', 'screen', true)
ui._visible = false

Global.FullScreenNotice = FullScreenNotice

FullScreenNotice.show = function(self, text, buttonnumber, clickfunc1, clickfunc2)
	ui._visible = true
	ui.notice.content.text = text
	-- 富文本 超链接点击逻辑
	ui.notice.content.onClickLink = function(hreftag)
		print("FullScreenNotice onClickLink", hreftag)
		local lastcursor = _app.cursor
		_app.cursor = 'hand'
		Global.Timer:add('cursor', 1000, function()
			_app.cursor = lastcursor
		end)
		if string.fstarts(hreftag, "http") then
			_sys:browse(hreftag)
		end
	end
	ui.button1.visible = false
	ui.button2.visible = false
	ui.button3.visible = false
	ui.button1.click = nil
	ui.button2.click = nil
	ui.button3.click = nil
	if buttonnumber == 1 then
		ui.button3.visible = true
		ui.button3.click = clickfunc1
	elseif buttonnumber == 2 then
		ui.button1.visible = true
		ui.button2.visible = true
		ui.button1.click = clickfunc1
		ui.button2.click = clickfunc2
	end
end

FullScreenNotice.hide = function(self)
	ui._visible = false
end
