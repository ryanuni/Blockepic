
local dd = {}
Global.Delay_Display = dd

dd.show = function(self, s)
	if self._show == s then
		return
	end

	self._show = s
	if s then
		_app:registerUpdate(self)
	else
		_app:unregisterUpdate(self)
	end
end
dd.update_data = function(self, d)
	self.text = nil
	for n, delay in next, d do
		if n ~= Global.Login:getName() then
			local s = n .. ' ' .. delay .. '\n'
			if self.text == nil then
				self.text = s
			else
				self.text = self.text .. s
			end
		end
	end

	if self.text then
		self:show(true)
	end
end
dd.render = function(self)
	local d = Global.KCP_Net:get_delay()
	if d == 0 then
		self:show(false)
		return
	end

	_rd.font:drawText(0, _rd.h - 100, 'Me ' .. d)

	if self.text then
		_rd.font:drawText(0, _rd.h - 80, self.text)
	end
end