local LoginUI = {}
Global.LoginUI = LoginUI
local Container = _require('Container')
local state = {
	init = {'main', 'login', 'sign'},
	main = {'login', 'sign', 'enter', 'create', 'webpage'},
	login = {'main', 'create', 'enter'},
	sign = {'main', 'create'},
	create = {'main'},
	enter = {'main'},
	webpage = {'main', 'create', 'enter'}
}

local tips = {
	email = 'Email Address',
	password = 'Password',
	confirm = 'Confirm Password'
}

local inputs = {
	'email', 'password', 'confirm'
}

LoginUI.ClickSound = {
	{ui = 'login', sound = 'ui_click01'},
	{ui = 'sign', sound = 'ui_click01'},
	{ui = 'wallet', sound = 'ui_click01'},
	{ui = 'back', sound = 'ui_click02'},
	{ui = 'create', volume = 0},
	{ui = 'enter', sound = 'ui_click01'},
	{ui = 'finish', volume = 0},
}

LoginUI.init = function(self)
	if self.ui then
		return
	end

	self.ui = Global.UI:new('Login.bytes')
	self.ui.visible = false
	self.state = 'init'

	self.rtData = {
		email = nil,
		password = nil,
		confirm = nil,
	}

	local appversion = _sys.appVersion
	local versions = string.fsplit(appversion, '%.') or "0.0.0"

	local realversion = tonumber(versions[1]) * 100000 + tonumber(versions[2]) * 1000 + tonumber(versions[3])
	self.ui.version.text = string.sub(_sys.version, 5, 10) .. realversion

	-- 配置按钮声效
	for _, data in ipairs(self.ClickSound) do
		local ui = self.ui[data.ui]
		if ui then
			ui._sound = Global.SoundList[data.sound]
			ui._soundVolumeScale = data.volume or Global.SoundConfigsList[data.sound].volume
		end
	end

	self.ui.login.click = function()
		if self.state ~= 'main' then
			return
		end

		self:showLogin()
	end

	self.ui.sign.click = function()
		if self.state ~= 'main' then
			return
		end

		--- 处理注册界面注册按钮
		self.ui.sign.disabled = true
		if self.disable_main_mun == 0 then
			self.ui.sign.gray = false
		end

		local next = 'sign'
		self:goAndPlay(next)
	end

	self.ui.wallet.click = function()
		-- TODO. connect wallet.
		self:disableMainButton(true)
		Global.Wallet:loginByWallet()
	end

	self.ui.back.click = function()
		if self.disable_main_mun == 0 then
			--- 处理登陆界面登录按钮
			self.ui.login.disabled = false
			--- 处理注册界面注册按钮
			self.ui.sign.disabled = false
		end

		self:back()
	end

	self.ui.return_page.click = function()
		Global.Wallet:returnPage()
	end

	local prompttext = "Your name"
	local mcname = self.ui.nameinput.name
	mcname.text = prompttext
	local timer = _Timer.new()

	mcname.focusIn = function(e)
		self.ui.namenotice.text = ''
		if mcname.text == prompttext then
			mcname.text = ''
		end

		_sys:showKeyboard(mcname.text, "OK", e)
		_app:onKeyboardString(function(str)
			mcname.text = str
		end)
	end

	mcname.focusOut = function()
		_sys:hideKeyboard()
		if mcname.text == '' then
			mcname.text = prompttext
		end
	end

	local function createfunc()
		local str = self.ui.nameinput.name.text
		if str == prompttext then
			str = ''
		end

		str = string.gsub(str, '^[ \t]+', '')

		local len = string.len(str)
		local isfailed = len < 3 or len > 20 or (not Global.cFilter:checkName(str))
		if isfailed == true then
			Global.Sound:play('ui_error01')
			self.ui:gotoAndPlay('namenotice_shake')
		end
		if len < 3 then
			self.ui.namenotice.text = Global.TEXT.CREATE_NAME_LENGTH_MIN
			return
		end
		if len > 20 then
			self.ui.namenotice.text = Global.TEXT.CREATE_NAME_LENGTH_MAX
			return
		end

		if not Global.cFilter:checkName(str) then
			self.ui.namenotice.text = Global.TEXT.CREATE_NAME_INVALID
			return
		end

		Global.Sound:play('ui_click01')
		self.ui.create.disabled = true
		timer:start('disable', 2000, function()
			self.ui.create.disabled = false
			timer:stop('disable')
		end)

		local function success()
			if Version:isDemo() then
				Global.debugFuncUI:show(true)
			end
			Global.LoginUI:show(false)
			Global.gmm:syncGuideStep()
			Global.gmm:startMovie('newsignup')
			if _sys.os == 'win32' or _sys.os == 'mac' then
				Global.UI:changeDesignWH(1920 * 2, 1080 * 2)
			end
			-- Global.Leaderboard:getFameRank()
			Global.Leaderboard:getBlockBrawlRank()
			Global.Leaderboard:getNeverupRank()
		end

		local function onerror()
			self.ui:gotoAndPlay('namenotice_shake')
			Notice(Global.TEXT.CREATE_NAME_ERROR)
		end

		Global.Login:changeName(str, success, onerror)
	end
	self.ui.create.click = createfunc

	self.ui.enter.click = function()
		UPLOAD_DATA('login_enter')
		Global.LoginUI:show(false)
		Global.gmm:syncGuideStep()
		Global.gmm:startMovie('newlogin')
		if _sys.os == 'win32' or _sys.os == 'mac' then
			Global.UI:changeDesignWH(1920 * 2, 1080 * 2)
		end

		-- Global.Timer:add('onlinefame', Global.Fame.online * 1000, function()
		-- 	if Global.Login:isOnline() then
		-- 		Global.FameTask:doTask('online')
		-- 	end
		-- end)

	end

	for i, v in ipairs(inputs) do
		self.ui[v].tip.text = tips[v]
		self:bindInputMc(v)
	end

	self:flushInputTips()

	self.ui.finish.click = function()
		self:onFinishClick()
	end

	self.isH = _app:isScreenH()

	Global.UI:onDeviceOrientation(self.ui, function(oriH)
		if _sys.os == 'win32' or _sys.os == 'mac' then
			if not oriH and not _app:isScreenV() then
				return
			end
		else
			if self.isH == oriH then
				return
			end
		end
		self.isH = oriH
		self:goAndPlay(self.state)
		if self.state == 'create' or self.state == 'enter' then
			self:moveToCreateRoleCamera()
		else
			self:moveToLoginInCamera()
		end
	end)

	-- self.ui.wallet.disabled = true
	-- self.ui.sign.disabled = true

	self.disable_main_mun = 0
end

LoginUI.disableFinish = function(self, disable)
	--- 从变灰变为显示菊花
	self.ui.finish.disabled = disable
	self.ui.back.disabled = disable
	self.ui.finish.visible = not disable
	self.ui.back.visible = not disable

	if disable then
		self.ui.loading_login.visible = true
	else
		self.ui.loading_login.visible = false
	end
end

LoginUI.disableMainButton = function(self, disable)
	if disable then
		self.disable_main_mun = self.disable_main_mun + 1

		self.ui.wallet.disabled = disable
		self.ui.login.disabled = disable
		self.ui.sign.disabled = disable
		self.ui.finish.disabled = disable
		self.ui.back.disabled = disable

		self.ui.create.disabled = disable
		self.ui.enter.disabled = disable
	else
		self.disable_main_mun = self.disable_main_mun - 1
		if self.disable_main_mun < 0 then
			self.disable_main_mun = 0
		end

		if self.disable_main_mun == 0 then
			self.ui.wallet.disabled = disable
			--- 特殊兼容处理
			if self.state ~= 'login' then
				self.ui.login.disabled = disable
			else
				self.ui.login.gray = false
			end
			if self.state ~= 'sign' then
				self.ui.sign.disabled = disable
			else
				self.ui.sign.gray = false
			end
			self.ui.finish.disabled = disable
			self.ui.back.disabled = disable
			self.ui.create.disabled = disable
			self.ui.enter.disabled = disable
		end
	end
end

LoginUI.unconnectState = function(self, unconnect)
	--- 兼容没有登录ui的情况
	if not self.ui then
		return
	end

	if self.unconnect_state == unconnect then
		return
	end

	-- self.ui.unconnect.visible = unconnect
	self.unconnect_state = unconnect
	self:disableMainButton(unconnect)
end

LoginUI.onFinishClick = function(self)
	self:disableFinish(true)
	if self.state == 'sign' then
		if self:checkInputs('email', 'password', 'confirm') then
			Global.Login:signup('email', self.rtData.email, 'password', self.rtData.password)
		else
			self:disableFinish(false)
		end
	elseif self.state == 'login' then
		if self:checkInputs('email', 'password') then
			Global.Login:login('email', self.rtData.email, 'password', self.rtData.password)
		else
			self:disableFinish(false)
		end
	end

	Global.Sound:play('login_anima')
end

LoginUI.Success = function(self)
	Global.Sound:play('ui_click01')
end
LoginUI.Error = function(self, err)
	self:disableFinish(false)

	if self.state == 'sign' then
		self:showInputTip('email', err)
	elseif self.state == 'login' then
		self:showInputTip('password', err)
	end
	Global.Sound:play('ui_error01')
end

LoginUI.back = function(self)
	if self.state ~= 'sign' and self.state ~= 'login' and self.state ~= 'create' then
		return
	end

	local next = state[self.state][1]
	self:goAndPlay(next)
	self:cleanRtData()
	self:cleanInputMc()
	self:flushInputTips()
	self:cleanErr()
end

LoginUI.show = function(self, show)
	self:init()
	if self.ui.visible == show then return end

	if show then
		Global.entry:goLoginIn()
	else
		self:back()
	end

	self.ui.visible = show
	Global.gmm.onEvent('loginanima')
end

LoginUI.showMain = function(self)
	if not self.ui.visible then
		return
	end
	if self.state == 'init' then
		local next = state.init[1]
		self:goAndPlay(next)
	else
		self:back()
	end
end

LoginUI.showLogin = function(self, email, password, autologin)
	if not self.ui.visible then
		return
	end
	if self.state == 'login' then
		return
	end

	if self.unconnect_state then
		return
	else
		self:disableMainButton(false)
	end

	--- 处理登陆界面登录按钮
	self.ui.login.disabled = true
	if self.disable_main_mun == 0 then
		self.ui.login.gray = false
	end

	local next = 'login'
	self:goAndPlay(next)

	if email and password then
		-- self:executeInput('email', email)
		-- self:executeInput('password', password)
		self:setLoginInput(email, password)
		if autologin then
			self:disableFinish(true)

			self.ui:setTransitionHook(next, 'login_end', function()
				self.ui:setTransitionHook(next, 'login_end', function()
				end, 'autoLoginEnd')
				self:onFinishClick()
			end, 'autoLoginEnd')
		end
	end
end

local xoffset = 0.5
local yoffset = -0.5
local zoffset = 0.5

LoginUI.moveToLoginInCamera = function(self)
	local camera = Global.CameraControl:get()
	local ab = Container:get(_AxisAlignedBox)
	local vec = Container:get(_Vector3)
	Global.role:getAABB(ab)
	if self.isH then
		ab.min.x = ab.min.x + xoffset
		ab.max.x = ab.max.x + xoffset
	else
		ab.min.y = ab.min.y + yoffset
		ab.max.y = ab.max.y + yoffset
	end
	local w = 460
	local h = 700
	local sh = math.tan(camera.camera.fov / 2 / 180 * math.pi) * 2
	local s = _rd.w / 4 + self.ui.logo._width * Global.UI:getScale() / 4 - w / 2
	local a = sh / _rd.h * w
	local b = sh / _rd.h * s
	local c = sh / _rd.h * h
	local x = (ab.max.x + b / a)
	local y = (ab.max.y + ab.min.y) / 2 - 1 / a
	local z = ab.max.z + (sh / 2 - c) / 2 / a
	vec:set(x, y, z)
	camera:moveLook(vec)
	camera:update()
	Global.role:getPosition(vec)
	_Vector3.sub(camera.camera.eye, vec, vec)
	Global.role:updateFace(vec, 0)
	Container:returnBack(ab, vec)
end

LoginUI.moveToCreateRoleCamera = function(self, time)
	local camera = Global.CameraControl:get()
	local ab = Container:get(_AxisAlignedBox)
	local vec = Container:get(_Vector3)
	Global.role:getAABB(ab)
	if self.isH then
		ab.min.x = ab.min.x + xoffset
		ab.max.x = ab.max.x + xoffset
	else
		ab.min.y = ab.min.y + yoffset
		ab.max.y = ab.max.y + yoffset
		ab.min.z = ab.min.z + zoffset
		ab.max.z = ab.max.z + zoffset
	end
	local w = 550
	local h = 550
	local sh = math.tan(camera.camera.fov / 2 / 180 * math.pi) * 2
	local s = _rd.w / 4 + (self.ui.logo._width - 400) * Global.UI:getScale() / 4 - w / 2
	local a = sh / _rd.h * w
	local b = sh / _rd.h * s
	local c = sh / _rd.h * h
	local x = self.isH and (ab.max.x + b / a) or ((ab.max.x + ab.min.x) / 2)
	local y = (ab.max.y + ab.min.y) / 2 - 1 / a
	local z = ab.min.z
	vec:set(x, y, z + 0.6)
	camera:moveLook(vec, time)
	camera:update()
	Global.role:getPosition(vec)
	_Vector3.sub(camera.camera.eye, vec, vec)
	Global.role:updateFace(vec, 0)
	Container:returnBack(ab, vec)
end

LoginUI.showIntroduce = function(self)
	local nextfunc = function()
		Global.Sound:play('bgm_login')
		Global.Sound:play('bgm_ambient1')
		Global.Sound:play('bgm_ambient2')
		Global.Sound:play('bgm_ambient3')
		self:showCreate()
	end
	-- 5月版本不展示引导
	-- if Global.Achievement:check('introducbrief') == false then
	-- 	Global.Introduce.onExit = nextfunc
	-- 	Global.Introduce:show('brief')
	-- 	Global.Achievement:ask('introducbrief')
	-- else
		nextfunc()
	-- end
end

LoginUI.showCreate = function(self)
	local next = 'create'
	self:goAndPlay(next)
	self.ui.nameinput.name.disabled = false
	Global.gmm.onEvent('showmode2')
	self:moveToCreateRoleCamera(500)
end

LoginUI.showEnter = function(self)
	print("showEnter")
	local next = 'enter'
	self:goAndPlay(next)
	self.ui.nameinput.name.disabled = true
	self.ui.nameinput.name.text = Global.Login:getName()
	Global.gmm.onEvent('randomexpress')
	Global.gmm.onEvent('showmode2')
	self:moveToCreateRoleCamera(500)
end

LoginUI.showWebpage = function(self)
	local next = 'webpage'
	self:goAndPlay(next)
end

LoginUI.deleteWebpage = function(self)
	if self.state ~= 'webpage' then
		return
	end

	local next = 'main'
	self:goAndPlay(next)
end

LoginUI.setLoginInput = function(self, email, password)
	if not email or not password then
		return
	end

	self:executeInput('email', email)
	self:executeInput('password', password)
end

LoginUI.executeInput = function(self, name, text)
	local inputmc = self.ui[name].input
	inputmc.text = text
	self.rtData[name] = text
	-- print('executeInput', text, self.rtData[name])

	self:checkInputVaild(name)
	self:flushInputTip(name)
end

local function extendString(inputstr, id)
	if not inputstr or type(inputstr) ~= "string" or #inputstr <= 0 then
		return nil
	end
	local length = 0
	local i = 1
	local res
	while true do
		local curByte = string.byte(inputstr, i)
		local byteCount = 1
		if curByte > 239 then
			byteCount = 4
		elseif curByte > 223 then
			byteCount = 3
		elseif curByte > 128 then
			byteCount = 2
		else
			byteCount = 1
		end
		length = length + 1
		if length == id then
			res = string.sub(inputstr, i, i + byteCount - 1)
		end
		i = i + byteCount
		if i > #inputstr then
			break
		end
	end

	return length, res
end

LoginUI.findNextInput = function(self, name)
	local starti
	local endi
	for i, v in ipairs(inputs) do
		if v == name then
			starti = i + 1
			endi = i + #inputs - 1
			break
		end
	end
	if starti == nil or endi == nil then return end

	for i = starti, endi do
		local nexti = i
		nexti = i > #inputs and i - #inputs or i
		local nextinput = self.ui[inputs[nexti]]
		if nextinput and nextinput._visible then
			return nextinput
		end
	end
end

LoginUI.bindInputMc = function(self, name)
	local inputmc = self.ui[name].input
	if name ~= 'email' then
		inputmc.isPassword = true
		self.ui[name].showpassword.selected = false

		self.ui[name].showpassword.click = function()
			if self.ui[name].showpassword.selected then
				inputmc.isPassword = false
			else
				inputmc.isPassword = true
			end
		end
	end
	-- print('bindInputMc', inputmc)
	inputmc.focusIn = function(e)
		-- print('focusIn')
		self.ui[name].tip.visible = false
		_sys:showKeyboard(inputmc.text, "OK", e)
		_app:onKeyboardString(function(str)
			inputmc.text = str
			inputmc.focus = true
		end)
	end
	inputmc.focusOut = function()
		_sys:hideKeyboard()
		self:executeInput(name, self.rtData[name])
	end
	inputmc.textChange = function()
		if string.find(inputmc.text, '\t$') then
			inputmc.text = string.gsub(inputmc.text, '\t$', '')
			local nextinput = self:findNextInput(name)
			nextinput.input.focus = true
			return
		end
		local changestr = ''
		local inputstr_length = extendString(inputmc.text)
		if inputstr_length then
			for i = 1, inputstr_length do
				local length, inputstr = extendString(inputmc.text, i)
				if string.byte(inputstr) > 128 then
					changestr = changestr .. ' '
				else
					changestr = changestr .. inputstr
				end
			end
		end

		if name == 'email' then
			inputmc.text = string.gsub(inputmc.text, ' +', '')
		end
		self.rtData[name] = inputmc.text
		if name == 'password' or name == 'confirm' then
			inputmc.text = changestr
		end
	end
end
LoginUI.cleanInputMc = function(self)
	for i, v in ipairs(inputs) do
		local inputmc = self.ui[v].input
		inputmc.text = ''
		if v ~= 'email' then
			self.ui[v].showpassword.selected = false
			inputmc.isPassword = true
		end
	end
end

LoginUI.flushInputTip = function(self, name)
	local inputmc = self.ui[name].tip

	local data = self.rtData[name]
	if data == nil or data == '' then
		inputmc.visible = true
	else
		inputmc.visible = false
	end
end

LoginUI.flushInputTips = function(self)
	for i, v in ipairs(inputs) do
		self:flushInputTip(v)
	end
end

LoginUI.emailCheck = function(self, str)
	if not str then return false, Global.TEXT.CREATE_EMAIL_INVALID end
	if string.len(str) < 6 then return false, Global.TEXT.CREATE_EMAIL_INVALID end
	if string.len(str) > 150 then return false, Global.TEXT.CREATE_EMAIL_INVALID end
	if str:find(' ') then return false, Global.TEXT.CREATE_EMAIL_INVALID end

	local b, e = string.find(str or "", '@')
	local bstr = ""
	local estr = ""
	if b then
		bstr = string.sub(str, 1, b - 1)
		estr = string.sub(str, e + 1, -1)
	else
		return false, Global.TEXT.CREATE_EMAIL_INVALID
	end

	-- check the string before '@'
	-- local p1, p2 = string.find(bstr, "[%w_.]+")
	-- if (p1 ~= 1) or (p2 ~= string.len(bstr)) then return false, Global.TEXT.CREATE_EMAIL_INVALID end

	-- check the string after '@'
	if string.find(estr, "^[%.]+") then return false, Global.TEXT.CREATE_EMAIL_INVALID end
	if string.find(estr, "%.[%.]+") then return false, Global.TEXT.CREATE_EMAIL_INVALID end
	if string.find(estr, "@") then return false, Global.TEXT.CREATE_EMAIL_INVALID end
	if string.find(estr, "[%.]+$") then return false, Global.TEXT.CREATE_EMAIL_INVALID end

	local _, count = string.gsub(estr, "%.", "")
	if (count < 1) or (count > 3) then
		return false, Global.TEXT.CREATE_EMAIL_INVALID
	end

	return true
end

LoginUI.passwordCheck = function(self, str)
	if not str then
		return false, 'No password'
	end
	local inputstr_length = extendString(str)
	if not inputstr_length then
		return false, 'At least 6 characters'
	end
	if inputstr_length < #str or str:find(' ') then
		return false, 'Only support English alphanumeric'
	end
	if inputstr_length < 6 then
		return false, 'At least 6 characters'
	end
	if inputstr_length > 100 then
		return false, 'Use 100 characters or fewer for your password'
	end

	return true
end

LoginUI.confirmCheck = function(self, str)
	local password = self.rtData.password
	if password and password == str then
		return true
	end

	return false, 'Password not Match'
end

LoginUI.checkInputVaild = function(self, name)
	local inputmc = self.ui[name].err

	local data = self.rtData[name]
	local res, info = self[name .. 'Check'](self, data)
	if not res then
		inputmc.text = info
	else
		inputmc.text = ''
	end

	return res
end
LoginUI.showInputTip = function(self, name, info)
	local inputmc = self.ui[name].err
	if inputmc.visible then
		inputmc.text = info
	end
end

LoginUI.checkInputs = function(self, ...)
	local args = {...}
	local ok = true
	for _, v in ipairs(args) do
		local check = self:checkInputVaild(v)
		if not check then
			ok = false
		end
	end
	if ok == false then
		Global.Sound:play('ui_error01')
	end
	return ok
end

LoginUI.cleanErr = function(self)
	for i, v in ipairs(inputs) do
		local inputmc = self.ui[v]

		inputmc.err.text = ''
	end
end

LoginUI.cleanRtData = function(self)
	self.rtData.email = nil
	self.rtData.password = nil
	self.rtData.confirm = nil
end

--------------------------------------------------------------

local Hpos = {
	logo = {
		init = {x = -1, y = -1, time = 500, vis = {vtime = 500, v = true}, dx1 = -1, dx2 = 0, dx3 = -1, dy1 = 250, dy2 = -1, dy3 = -1},
		main = {x = -1, y = -1, time = 500, vis = {vtime = 500, v = true}, dx1 = -1, dx2 = 0, dx3 = -1, dy1 = 153, dy2 = -1, dy3 = -1},
		login = {x = -1, y = -1, time = 500, vis = {vtime = 500, v = true}, dx1 = -1, dx2 = 0, dx3 = -1, dy1 = 90, dy2 = -1, dy3 = -1},
		sign = {x = -1, y = -1, time = 500, vis = {vtime = 500, v = true}, dx1 = -1, dx2 = 0, dx3 = -1, dy1 = 90, dy2 = -1, dy3 = -1},
		create = {x = -1, y = -1, time = 500, vis = {vtime = 500, v = true}, dx1 = 232, dx2 = -1, dx3 = -1, dy1 = 232, dy2 = -1, dy3 = -1},
		enter = {x = -1, y = -1, time = 500, vis = {vtime = 500, v = true}, dx1 = 232, dx2 = -1, dx3 = -1, dy1 = 232, dy2 = -1, dy3 = -1},
		webpage = {x = -1, y = -1, time = 500, vis = {vtime = 500, v = true}, dx1 = -1, dx2 = 0, dx3 = -1, dy1 = 153, dy2 = -1, dy3 = -1},
	},
	des = {
		init = {x = -1, y = 715, time = 0},
		main = {},
		login = {},
		sign = {},
		create = {},
		enter = {},
		webpage = {}
	},
	progress = {
		init = {x = -1, y = 790, time = 0},
		main = {},
		login = {},
		sign = {},
		create = {},
		enter = {},
		webpage = {}
	},
	login = {
		init = {},
		main = {x = -1, y = 675, time = 500, vis = {vtime = 500, v = true}},
		login = {x = -1, y = 425, time = 0},
		sign = {},
		create = {},
		enter = {},
		webpage = {}
	},
	sign = {
		init = {},
		main = {x = -1, y = 792, time = 500, vis = {vtime = 500, v = true}},
		login = {},
		sign = {x = -1, y = 390, time = 0},
		create = {},
		enter = {},
		webpage = {}
	},
	wallet = {
		init = {},
		main = {x = -1, y = 520, time = 500, vis = {vtime = 500, v = true}},
		login = {},
		sign = {},
		create = {},
		enter = {},
		webpage = {}
	},
	loading = {
		init = {},
		main = {},
		login = {},
		sign = {},
		create = {},
		enter = {},
		webpage = {x = -1, y = 558, time = 0},
	},
	return_page = {
		init = {},
		main = {},
		login = {},
		sign = {},
		create = {},
		enter = {},
		webpage = {x = -1, y = 714, time = 0},
	},
	loading_txt = {
		init = {},
		main = {},
		login = {},
		sign = {},
		create = {},
		enter = {},
		webpage = {x = -1, y = 486, time = 0},
	},
	unconnect = {
		init = {},
		main = {x = -1, y = 450, time = 0, default = false},
		login = {},
		sign = {},
		create = {},
		enter = {},
		webpage = {},
	},
	email = {
		init = {},
		main = {},
		login = {x = -1, y = 581, time = 0, vis = {vtime = 500, v = true}},
		sign = {x = -1, y = 506, time = 0, vis = {vtime = 500, v = true}},
		create = {},
		enter = {},
		webpage = {}
	},
	password = {
		init = {},
		main = {},
		login = {x = -1, y = 702, time = 0, vis = {vtime = 500, v = true}},
		sign = {x = -1, y = 635, time = 0, vis = {vtime = 500, v = true}},
		create = {},
		enter = {},
		webpage = {}
	},
	confirm = {
		init = {},
		main = {},
		login = {},
		sign = {x = -1, y = 769, time = 0, vis = {vtime = 500, v = true}},
		create = {},
		enter = {},
		webpage = {}
	},
	finish = {
		init = {},
		main = {},
		login = {x = -1, y = 860, time = 0, vis = {vtime = 500, v = true}},
		sign = {x = -1, y = 900, time = 0, vis = {vtime = 500, v = true}},
		create = {},
		enter = {},
		webpage = {}
	},
	loading_login = {
		init = {},
		main = {},
		login = {x = -1, y = 800, time = 0, default = false},
		sign = {x = -1, y = 880, time = 0, default = false},
		create = {},
		enter = {},
		webpage = {}
	},
	back = {
		init = {},
		main = {},
		login = {x = -1, y = 860, time = 0, vis = {vtime = 500, v = true}},
		sign = {x = -1, y = 900, time = 0, vis = {vtime = 500, v = true}},
		create = {},
		enter = {},
		webpage = {}
	},
	nameinput = {
		init = {},
		main = {},
		login = {},
		sign = {},
		create = {x = -1, y = -1, time = 0, vis = {vtime = 500, v = true}, dx1 = 300, dx2 = -1, dx3 = -1, dy1 = -1, dy2 = 97, dy3 = -1},
		enter = {x = -1, y = -1, time = 0, vis = {vtime = 500, v = true}, dx1 = 300, dx2 = -1, dx3 = -1, dy1 = -1, dy2 = 97, dy3 = -1},
		webpage = {}
	},
	namenotice = {
		init = {},
		main = {},
		login = {},
		sign = {},
		create = {x = -1, y = -1, time = 0, vis = {vtime = 500, v = true}},
		enter = {x = -1, y = -1, time = 0, vis = {vtime = 500, v = true}},
		webpage = {}
	},
	create = {
		init = {},
		main = {},
		login = {},
		sign = {},
		create = {x = -1, y = -1, time = 0, vis = {vtime = 500, v = true}, dx1 = 561, dx2 = -1, dx3 = -1, dy1 = -1, dy2 = 259, dy3 = -1},
		enter = {},
		webpage = {}
	},
	enter = {
		init = {},
		main = {},
		login = {},
		sign = {},
		create = {},
		enter = {x = -1, y = -1, time = 0, vis = {vtime = 500, v = true}, dx1 = 561, dx2 = -1, dx3 = -1, dy1 = -1, dy2 = 259, dy3 = -1},
		webpage = {}
	}
}

local Vpos = {
	logo = {
		init = {x = -1, y = -1, time = 500, vis = {vtime = 500, v = true}, dx1 = -1, dx2 = 0, dx3 = -1, dy1 = 670, dy2 = -1, dy3 = -1},
		main = {x = -1, y = -1, time = 500, vis = {vtime = 500, v = true}, dx1 = -1, dx2 = 0, dx3 = -1, dy1 = 550, dy2 = -1, dy3 = -1},
		login = {x = -1, y = -1, time = 500, vis = {vtime = 500, v = true}, dx1 = -1, dx2 = 0, dx3 = -1, dy1 = 441, dy2 = -1, dy3 = -1},
		sign = {x = -1, y = -1, time = 500, vis = {vtime = 500, v = true}, dx1 = -1, dx2 = 0, dx3 = -1, dy1 = 441, dy2 = -1, dy3 = -1},
		create = {x = -1, y = -1, time = 500, vis = {vtime = 500, v = true}, dx1 = -1, dx2 = 0, dx3 = -1, dy1 = 70, dy2 = -1, dy3 = -1},
		enter = {x = -1, y = -1, time = 500, vis = {vtime = 500, v = true}, dx1 = -1, dx2 = 0, dx3 = -1, dy1 = 70, dy2 = -1, dy3 = -1},
		webpage = {x = -1, y = -1, time = 500, vis = {vtime = 500, v = true}, dx1 = -1, dx2 = 0, dx3 = -1, dy1 = 153, dy2 = -1, dy3 = -1},
	},
	des = {
		init = {x = -1, y = 1135, time = 0},
		main = {},
		login = {},
		sign = {},
		create = {},
		enter = {},
		webpage = {}
	},
	progress = {
		init = {x = -1, y = 1210, time = 0},
		main = {},
		login = {},
		sign = {},
		create = {},
		enter = {},
		webpage = {}
	},
	login = {
		init = {},
		main = {x = -1, y = 1085, time = 500, vis = {vtime = 500, v = true}},
		login = {x = -1, y = 746, time = 500, vis = {vtime = 500, v = true}},
		sign = {},
		create = {},
		enter = {},
		webpage = {}
	},
	sign = {
		init = {},
		main = {x = -1, y = 1194, time = 500, vis = {vtime = 500, v = true}},
		login = {},
		sign = {x = -1, y = 746, time = 500, vis = {vtime = 500, v = true}},
		create = {},
		enter = {},
		webpage = {}
	},
	wallet = {
		init = {},
		main = {x = -1, y = 925, time = 500, vis = {vtime = 500, v = true}},
		login = {},
		sign = {},
		create = {},
		enter = {},
		webpage = {}
	},
	loading = {
		init = {},
		main = {},
		login = {},
		sign = {},
		create = {},
		enter = {},
		webpage = {x = -1, y = 1013, time = 0},
	},
	return_page = {
		init = {},
		main = {},
		login = {},
		sign = {},
		create = {},
		enter = {},
		webpage = {x = -1, y = 1159, time = 0},
	},
	loading_txt = {
		init = {},
		main = {},
		login = {},
		sign = {},
		create = {},
		enter = {},
		webpage = {x = -1, y = 931, time = 0},
	},
	unconnect = {
		init = {},
		main = {x = -1, y = 931, time = 0, default = false},
		login = {},
		sign = {},
		create = {},
		enter = {},
		webpage = {},
	},
	email = {
		init = {},
		main = {},
		login = {x = -1, y = 883, time = 0, vis = {vtime = 500, v = true}},
		sign = {x = -1, y = 883, time = 0, vis = {vtime = 500, v = true}},
		create = {},
		enter = {},
		webpage = {}
	},
	password = {
		init = {},
		main = {},
		login = {x = -1, y = 1031, time = 0, vis = {vtime = 500, v = true}},
		sign = {x = -1, y = 1031, time = 0, vis = {vtime = 500, v = true}},
		create = {},
		enter = {},
		webpage = {}
	},
	confirm = {
		init = {},
		main = {},
		login = {},
		sign = {x = -1, y = 1179, time = 0, vis = {vtime = 500, v = true}},
		create = {},
		enter = {},
		webpage = {}
	},
	finish = {
		init = {},
		main = {},
		login = {x = -1, y = 1237, time = 0, vis = {vtime = 500, v = true}},
		sign = {x = -1, y = 1326, time = 0, vis = {vtime = 500, v = true}},
		create = {},
		enter = {},
		webpage = {}
	},
	loading_login = {
		init = {},
		main = {},
		login = {x = -1, y = 1237, time = 0, default = false},
		sign = {x = -1, y = 1326, time = 0, default = false},
		create = {},
		enter = {},
		webpage = {}
	},
	back = {
		init = {},
		main = {},
		login = {x = -1, y = 1249, time = 0, vis = {vtime = 500, v = true}},
		sign = {x = -1, y = 1338, time = 0, vis = {vtime = 500, v = true}},
		create = {},
		enter = {},
		webpage = {}
	},
	nameinput = {
		init = {},
		main = {},
		login = {},
		sign = {},
		create = {x = -1, y = -1, time = 0, vis = {vtime = 500, v = true}, dx1 = -1, dx2 = 0, dx3 = -1, dy1 = 350, dy2 = -1, dy3 = -1},
		enter = {x = -1, y = -1, time = 0, vis = {vtime = 500, v = true}, dx1 = -1, dx2 = 0, dx3 = -1, dy1 = 350, dy2 = -1, dy3 = -1},
		webpage = {}
	},
	namenotice = {
		init = {},
		main = {},
		login = {},
		sign = {},
		create = {x = -1, y = -1, time = 0, vis = {vtime = 500, v = true}},
		enter = {x = -1, y = -1, time = 0, vis = {vtime = 500, v = true}},
		webpage = {}
	},
	create = {
		init = {},
		main = {},
		login = {},
		sign = {},
		create = {x = -1, y = -1, time = 0, vis = {vtime = 500, v = true}, dx1 = -1, dx2 = 0, dx3 = -1, dy1 = -1, dy2 = -1, dy3 = 200},
		enter = {},
		webpage = {}
	},
	enter = {
		init = {},
		main = {},
		login = {},
		sign = {},
		create = {},
		enter = {x = -1, y = -1, time = 0, vis = {vtime = 500, v = true}, dx1 = -1, dx2 = 0, dx3 = -1, dy1 = -1, dy2 = -1, dy3 = 200},
		webpage = {}
	}
}

local handleUIConfig = function(self)
	if OnlyWalletConnect then
		Hpos.login.login = {}
		Hpos.login.main = {}
		Hpos.sign.sign = {}
		Hpos.sign.main = {}
		Hpos.wallet.main = {x = -1, y = 625, time = 500, vis = {vtime = 500, v = true}}

		Vpos.login.login = {}
		Vpos.login.main = {}
		Vpos.sign.sign = {}
		Vpos.sign.main = {}
		Vpos.wallet.main = {x = -1, y = 1085, time = 500, vis = {vtime = 500, v = true}}
	end
end

handleUIConfig()

LoginUI.goAndPlay = function(self, type)
	self:init()
	if not self.ui.visible then
		return
	end

	local goto = state[self.state]
	local cango = 0
	for i, v in ipairs(goto) do
		if v == type then
			cango = 1
		end
	end

	-- 横竖切换, 初始化为静态不需要重新处理
	if type == self.state then
		if type == 'init' then
			return
		end
		cango = 2
	end

	if cango == 0 then
		return
	end

	local dolist = self.isH and Hpos or Vpos

	if cango == 1 then
		self.state = type
	end
	for item, events in pairs(dolist) do
		local pos = events[type]
		local it = self.ui[item]
		if not pos.x then
			if cango == 1 then
				it.visible = false
			end
		else
			local x, y = pos.x, pos.y
			if pos.dx1 and pos.dx1 ~= -1 then
				x = pos.dx1
			elseif pos.dx2 and pos.dx2 ~= -1 then
				x = self.ui._width / 2 - pos.dx2 - it._width / 2
			elseif pos.dx3 and pos.dx3 ~= -1 then
				x = self.ui._width - pos.dx3 - it._width
			elseif pos.x == -1 then
				x = it._x
			end
			if pos.dy1 and pos.dy1 ~= -1 then
				y = pos.dy1
			elseif pos.dy2 and pos.dy2 ~= -1 then
				y = self.ui._height / 2 + pos.dy2 - it._height / 2
			elseif pos.dy3 and pos.dy3 ~= -1 then
				y = self.ui._height - pos.dy3 - it._height
			elseif pos.y == -1 then
				y = it._y
			end
			if x ~= it._x or y ~= it._y then
				Global.UI.mmanager:addMovment(it, {x = x, y = y}, pos.time)
			end

			if cango == 1 and pos.default ~= false then
				if pos.vis then
					-- it.visible = not pos.vis.v
					Global.UI.vmanager:addVisible(it, pos.vis.v, pos.vis.vtime)
				else
					it.visible = true
				end
			end
		end
	end
end