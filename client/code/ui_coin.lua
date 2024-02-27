local function htmlNumber(number, font, w, h)
	local str = ''
	local l = _String.len(tostring(number))
	for i = 1, l do
		local c = _String.sub(number, i, i)
		str = str .. _G.genHtmlImg(font .. '_' .. c .. '.png', w, h)
	end
	return str
end

local cu = {}
Global.CoinUI = cu

cu.init = function(self)
	self.ui = Global.UI:new('Coin.bytes')
	self.ui.visible = false
	self.timer = _Timer.new()
	self.enablealpha = true
	self.ui.onSizeChange = function()
		self.ui.coin._y = 20 + Global.UI:safeArea_getUP()
		self.ui.fame._y = 30 + Global.UI:safeArea_getUP()
	end
end
cu:init()
cu.show = function(self, show)
	self.ui.visible = show
	if show then
		Global.Timer:add('flush_fame', 1500, function()
			Global.Login:flushFame()
		end)
	end

	if Global.Achievement:check('fristgetcoin') == false then return end
	local coin = Global.Login:getActiveness()
	if show and coin == nil then return end

	-- self.ui.coin.visible = false
	-- self.ui.coinnum.visible = false
	self.ui.coin._alpha = 100
	self.ui.coinnum._alpha = 100
end
cu.showFame = function(self, show)
	self.ui.fame.visible = show
	self.ui.famenum.visible = show
end
cu.showCoin = function(self, show)
	self.ui.coin.visible = show
	self.ui.coinnum.visible = show
end
cu.isShow = function(self)
	self.ui.coin._alpha = 100
	return self.ui.visible and self.ui.coin._alpha == 100
end
cu.flush = function(self)
	local coin = Global.Login:getActiveness()
	if coin then
		if self.coinnum and self.ui.visible then
			self.isFlushing = true
			-- self.ui._alpha = 100
			self.ui.coin._alpha = 100
			self.ui.coinnum._alpha = 100
			-- self:enableAlpha(false)
			local sub = math.abs(self.coinnum - coin)
			local time = math.min(math.ceil(sub / 4), 20)
			local index = 0
			local step = math.floor(sub / time)
			self.timer:start('change', 20, function()
				if index % 5 == 0 or index == time then
					if self.coinnum < coin then
						Global.Sound:play('ui_hint03')
						self.ui:gotoAndPlay('add')
					elseif self.coinnum > coin then
						Global.Sound:play('ui_hint02')
						self.ui:gotoAndPlay('lose')
					end
				end
				index = index + 1
				if self.coinnum < coin then
					self.ui.coinnum.text = math.min(self.coinnum + index * step, coin)
				else
					self.ui.coinnum.text = math.max(self.coinnum - index * step, coin)
				end
				if index > time then
					self.coinnum = coin
					self.ui.coinnum.text = Global.Login:getActiveness()
					self.timer:stop('change')
					-- self:enableAlpha(true)
					self.isFlushing = false
				end
			end)
		else
			self.coinnum = coin
			self.ui.coinnum.text = Global.Login:getActiveness()
		end
	end
	local fame = Global.Login:getFame()
	if fame then
		if self.famenum and self.ui.visible then
			self.isFlushingFame = true
			-- self.ui._alpha = 100
			-- self.ui.fame._alpha = 100
			-- self.ui.famenum._alpha = 100
			-- self:enableAlpha(false)
			local sub = fame - self.famenum
			local time = math.min(math.ceil(sub / 1), 20)
			local index = 0
			local step = math.floor(sub / time)
			self.timer:start('change', 20, function()
				if index % 5 == 0 or index == time then
					-- if self.famenum < fame then
						Global.Sound:play('ui_hint02')
						self.ui:gotoAndPlay('addfame')
					-- elseif self.famenum > fame then
					-- 	Global.Sound:play('ui_hint02')
					-- 	self.ui:gotoAndPlay('lose')
					-- end
				end
				index = index + 1
				-- if self.famenum < fame then
					self.ui.famenum.text = htmlNumber(math.min(self.famenum + index * step, fame), 'number_white', 40, 73)
					-- self.ui.famenum.text = math.min(self.famenum + index * step, fame)
				-- else
					-- self.ui.famenum.text = math.max(self.famenum - index * step, fame)
				-- end
				if index > time then
					self.famenum = fame
					self.ui.famenum.text = htmlNumber(Global.Login:getFame(), 'number_white', 40, 73)
					self.timer:stop('change')
					-- self:enableAlpha(true)
					self.isFlushingFame = false
				end
			end)
		else
			self.famenum = fame
			self.ui.famenum.text = htmlNumber(Global.Login:getFame(), 'number_white', 40, 73)
		end
	end
end
cu.enableAlpha = function(self, enable)
	self.enablealpha = enable
end
cu.updateAlpha = function(self, alpha)
	if self.enablealpha and not self.isFlushing then
		self.ui.coin._alpha = alpha
		self.ui.coinnum._alpha = alpha
	end
end

--- 常驻
cu.showPermanent = function(self)
	self:enableAlpha(false)
	self:show(true)
end
--- 跟随摇杆变化
cu.showDynamic = function(self)
	self:enableAlpha(true)
	self:show(true)
end
