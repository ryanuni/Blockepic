local Copyright = {}

local ui = Global.UI:new('Copyright.bytes', 'screen')
ui._visible = false

Global.Copyright = Copyright

Copyright.init = function(self, onok)
	local p = Global.SaveManager:Get('copyright')
	if p and p.permitted then
		onok()
		return
	end
	ui._visible = true
	ui.notice.content.title.text = Global.TEXT.TIP_COPYRIGHTTITLE
	ui.notice.content.content.text = Global.TEXT.TIP_COPYRIGHT
	ui.notice.content.alphaRegion = 0x14000500
	ui.notice.premitted.disabled = true
	ui.notice.premitted.click = function()
		local p = Global.SaveManager:Register('copyright')
		p.permitted = true
		Global.SaveManager:Save(true)

		ui._visible = false
		_app:unregisterUpdate(Global.Copyright)

		onok()
	end
	ui.notice.refuse.click = function()
		ui.notice._visible = false
		_app:unregisterUpdate(Global.Copyright)
		_abort()
	end

	_app:registerUpdate(Global.Copyright, 7)
end

Copyright.update = function(self)
	if ui.notice.premitted.disabled == false then return end
	local content = ui.notice.content
	if content.position + content._height >= content.content._height - 20 then
		ui.notice.premitted.disabled = false
	end
end

