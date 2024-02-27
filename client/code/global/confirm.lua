local confirm = {}

confirm.init = function(self)
	if self.ui then
		return
	end

	self.ui = Global.UI:new('Confirm.bytes', 'global', true)
	self.ui.visible = false
end

confirm.genConfirm = function(self, str)
	-- TODO: activeness 的图标及适配
	local final = string.gsub(str, '{activeness}', genHtmlImg('ui://xovwx195eqhuc'))

	return final
end

confirm.newMsg = function(self, msg, cfunc, bfunc)
	self:init()

	if self.ui.visible then
		return
	end

	self.ui.Tip.text = self:genConfirm(msg)
	self.ui.visible = true

	self.ui.confirm.click = function()
		self.ui.visible = false

		if cfunc then
			cfunc()
		end
	end

	self.ui.cancel.click = function()
		self.ui.visible = false

		if bfunc then
			bfunc()
		end
	end
end

_G.Confirm = function(msg, cfunc, bfunc)
	confirm:newMsg(msg, cfunc, bfunc)
end