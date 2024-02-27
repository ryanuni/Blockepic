local Container = _require('Container')
local ui = Global.ui

local function checkName(str)
	if str:find('\n') then return false end
	if str:find('\r') then return false end
	if str:find('\t') then return false end
	if str:len() > 50 then return false end
	return true
end

local profile = {}
profile.init = function(self)
	if self.ui then return end
	self.ui = Global.UI:new('Profile.bytes', 'screen')
	self.ui.visible = false
	-- self.ui = ui.profile
	self.ui.ok.click = function()
		local ok, err = Global.LoginUI:emailCheck(self.ui.email.input.text)
		if not ok then Notice(err) self.ui.email.input.text = '' end
		if not checkName(self.ui.discord.input.text) then Notice('Invalid Discord') self.ui.discord.input.text = '' end
		if not checkName(self.ui.twitter.input.text) then Notice('Invalid Twitter') self.ui.twitter.input.text = '' end
		if not checkName(self.ui.facebook.input.text) then Notice('Invalid Facebook') self.ui.facebook.input.text = '' end
		if not checkName(self.ui.instagram.input.text) then Notice('Invalid Instagram') self.ui.instagram.input.text = '' end

		if self.ui.email.input.text ~= '' then
			Global.Login:setEmail(self.ui.email.input.text)
		end

		Global.Login:setExtraInfo({
			discord = self.ui.discord.input.text ~= '' and self.ui.discord.input.text or nil,
			twitter = self.ui.twitter.input.text ~= '' and self.ui.twitter.input.text or nil,
			facebook = self.ui.facebook.input.text ~= '' and self.ui.facebook.input.text or nil,
			instagram = self.ui.instagram.input.text ~= '' and self.ui.instagram.input.text or nil,
		})

		self.ui.visible = false
		Global.SwitchControl:set_input_on()
		Global.SwitchControl:set_render_on()
		ui.profile_btn.visible = true
		Global.UI:popAndShow()
	end

	self.ui.close.click = function()
		Global.UI:slideout({self.ui})
		Global.Timer:add('hideui', 150, function()
			self.ui.visible = false
			Global.SwitchControl:set_input_on()
			Global.SwitchControl:set_render_on()
			ui.profile_btn.visible = true
			Global.UI:popAndShow()
		end)
	end
end

local function setinfo(ui, name, tip, input)
	ui.name.text = name
	ui.tip.text = (input == nil or input == '') and tip or ''
	ui.input.text = input

	ui.input.focusIn = function(e)
		_sys:showKeyboard(ui.input.text, "OK", e)
		ui.tip.visible = false
		_app:onKeyboardString(function(str)
			ui.input.text = str
			ui.input.focus = true
		end)
	end
	ui.input.focusOut = function()
		_sys:hideKeyboard()
		ui.tip.visible = ui.input.text == ''
	end
end

profile.setInfo = function(self, info)
	self.ui.id.text = string.format('Account ID #%.6d', info.id)
	setinfo(self.ui.wallet, 'Wallet Address', 'Please connect web3 wallet', info.wallet)
	setinfo(self.ui.email, 'Email Address', 'Please input email address here.', info.email)
	setinfo(self.ui.discord, 'Discord', '#', info.discord)
	setinfo(self.ui.twitter, 'Twitter', '@', info.twitter)
	setinfo(self.ui.facebook, 'Facebook', '@', info.facebook)
	setinfo(self.ui.instagram, 'Instagram', '@', info.instagram)
end

profile.showWin = function(self)
	Global.UI:pushAndHide('normal')
	local callback = function()
		self.ui.visible = true
		Global.SwitchControl:set_input_off()
		ui.profile_btn.visible = false

		local info = Global.Login:getExtraInfo()
		info.wallet = Global.Login:getWallet()
		info.email = Global.Login:getEmail()
		info.id = Global.Login:getAid()
		self:setInfo(info)
		self.ui.wallet.background.gray = true
		self.ui.wallet.input.textColor = '#ABA9AF'
	end
	if not self.timer then self.timer = _Timer.new() end
	_G:holdbackScreen(self.timer, callback)
end

profile.isInfoEmpty = function(self)
	local info = Global.Login:getExtraInfo()
	if info then
		return info.discord == nil and info.twitter == nil and info.facebook == nil and info.instagram == nil
	end
end

profile.show = function(self, show)
	ui.profile_btn.visible = show
	local clicked = Global.Achievement:check('clickprofile')
	if self:isInfoEmpty() == false then
		Global.Achievement:ask('clickprofile')
		clicked = true
	end
	if show and not clicked then
		-- play2Dpfx()
		ui.profilepfx.visible = true
		ui.profilepfx:playPfx('ui_zlp_cszz_01.pfx', 0, 0, 0.5, 0.5)
		print('play2Dpfx')
	else
		ui.profilepfx.visible = false
	end
end

ui.profile_btn.click = function()
	print('stop2Dpfx')
	ui.profilepfx.visible = false
	profile:showWin()
	Global.UI:slidein({profile.ui})
	if Global.Achievement:check('clickprofile') == false then
		Global.Achievement:ask('clickprofile')
	end
end

profile:init()
Global.ProfileUI = profile