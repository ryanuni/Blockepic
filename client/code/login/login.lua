
local login = {rtdata = {aid = -1}, cTime = 0, sTime = 0}
login.data = Global.SaveManager:Register('login')
_dofile('login_ui.lua')
_dofile('cfg_gm.lua')

Global.Login = login
-----------------------------------------------------
local function cb_alpha1()
	-- Global.House:initHouse()
	-- if Global.Login.name == '' then
	-- 	Global.Sound:stop()
	-- 	Global.LoginUI:showIntroduce()
	-- else
		-- Global.LoginUI:showEnter()
	-- end
	if Global.Login.name == '' then
		Global.LoginUI:showCreate()
	else
		Global.LoginUI:showEnter()
	end
end
local function cb_normal()
	Global.LoginUI:show(false)
	if Global.Login.name == '' then
		Global.entry:goCreateRole()
	else
		local gohome
		if Version:isDemo() then
			Global.debugFuncUI:show(true)
			local home = Global.SaveManager:Get('home')
			gohome = home and home[1]
		else
			gohome = Global.Achievement:check('done_guide')
		end

		if gohome then
			Global.entry:goHome()
		else
			Global.entry:goGuide()
		end
	end
end
local function onsuccesscb()
	Global.ObjectManager:RPC_GetObjects(function()
		if Version:isAlpha1() then
			cb_alpha1()
		else
			cb_normal()
		end
		Global.Wallet:stopBrowser()
	end)
	RPC("GetBlueprints", {})
	RPC('GetObjectCollects')
	RPC("GetPortalProgressInfo", {})
	RPC("GetFameEarnInfo", {})
	-- Global.Leaderboard:getFameRank()
	Global.Leaderboard:getBlockBrawlRank()
	Global.Leaderboard:getNeverupRank()
end
login.ConnectAndLogin = function(self)
	_G.ShowConnecting(true)

	local t = 'guest'
	if Version:isAlpha1() then
		t = 'email'
		Global.Sound:play('bgm_login')
		Global.Sound:play('bgm_ambient1')
		Global.Sound:play('bgm_ambient2')
		Global.Sound:play('bgm_ambient3')
		Global.LoginUI:show(true)
	end

	if OnlyWalletConnect then
		t = 'wallet'
	end

	Global.Net:setOnconnectCallback(function()
		-- TODO:已登录短线重连逻辑
		RPC("SetClientVersion", {Version = _sys.version})
		if self.rtdata.logintype and self.rtdata.logindata then
			if self.rtdata.logintype == 'email' then
				Global.LoginUI:setLoginInput(self.rtdata.logindata, self.rtdata.loginexdata)
			end
			login:login(self.rtdata.logintype, self.rtdata.logindata, self.rtdata.loginextype, self.rtdata.loginexdata, true)
		elseif t == 'email' then
			if self.data[t] and self.data['password'] and OnlyWalletConnect == false then
				Global.LoginUI:showLogin(self.data[t], self.data['password'])
			else
				Global.LoginUI:showMain()
			end
		elseif t == 'wallet' then
			Global.LoginUI:showMain()
		else
			login:login(t)
		end
	end)
	Global.Net:connect()
end
login.ConnectAndDone = function(self, onconnect)
	Global.Net:setOnconnectCallback(onconnect)
	Global.Net:connect()
end
login.login = function(self, t, d, ext, exd, isreconnect)
	-- local isconnect = self:getAid() ~= -1
	isreconnect = isreconnect or false
	assert(t)
	if t == 'keycode' then
		if d == nil then
			d = self.data[t]
		end
	elseif t == 'guest' then
		if d == nil then
			d = self.data[t]
		end
	elseif t == 'email' and ext == 'password' then
		if d == nil then
			d = self.data[t]
		end
		if exd == nil then
			exd = self.data[ext]
		end
	end

	self.rtdata.logintype = t
	self.rtdata.logindata = d
	self.rtdata.loginextype = ext
	self.rtdata.loginexdata = exd

	local data = {
		type = t,
		[t] = d
	}
	if ext then
		data[ext] = string.md5(string.lower(d) .. exd)
	end

	UPLOAD_DATA('login_send', d)

	RPC('Login', {Data = data, IsReconnect = isreconnect})
end
login.signup = function(self, t, d, ext, exd)
	if self:isOnline() then
		Notice('Already online.')
		return
	end

	assert(t)
	if t == 'email' and ext == 'password' then
		if d == nil then
			d = self.data[t]
		end
		if exd == nil then
			exd = self.data[ext]
		end
	else
		Notice('Sign up err.')
		return
	end

	self.rtdata.logintype = t
	self.rtdata.logindata = d
	self.rtdata.loginextype = ext
	self.rtdata.loginexdata = exd

	local data = {
		type = t,
		[t] = d
	}
	if ext then
		data[ext] = exd
	end

	UPLOAD_DATA('signup_send', d)
	RPC('SignUp', {Data = data})
end
login.logout = function(self, cleanrt)
	self:setAid(-1)
	if cleanrt then
		self.rtdata.logintype = nil
		self.rtdata.logindata = nil
		self.rtdata.loginextype = nil
		self.rtdata.loginexdata = nil
	end
end
login.isOnline = function(self)
	return self.rtdata.aid ~= -1
end
login.setAid = function(self, aid)
	if aid == self.rtdata.aid then
		return
	end

	self.rtdata.aid = aid
	Global.SaveManager:AidChange()
end
login.getAid = function(self)
	return self.rtdata.aid
end
login.isMe = function(self, aid)
	return self.rtdata.aid == aid
end
login.loginSuccess = function(self, aid, avatar, name, active, stime, wallet, avatarid, fame, email, extra_info)
	local isnew = true
	if aid == self:getAid() then
		isnew = false
	end
	self:setAid(aid)
	self:setServerTime(stime)
	local t = self.rtdata.logintype
	-- 登录为wallet 时，登陆完成才能拿到wallet地址
	if t == "wallet" then
		self.rtdata.logindata = wallet
	end
	local ext = self.rtdata.loginextype
	if t then
		if t == 'guest' then
			self.data[t] = aid
		else
			self.data[t] = self.rtdata.logindata
			if ext then
				self.data[ext] = self.rtdata.loginexdata
			end
		end
	end
	Global.SaveManager:Save(true)
	-- 开启xxx入口
	-- 重加载leveldata
	Global.SaveManager:LoadLevel(aid)
	-- 更新avatar
	if Global.myAvatar then
		Global.myAvatar:updateID(aid)
		Global.myAvatar:update(avatar)
	end

	-- 初始化 AudioPlayer 默认音乐列表
	Global.AudioPlayer:initDefaultSources()

	-- 更新名字
	self.name = name

	-- 更新拥有的activeness
	self.activeness = active
	Global.CoinUI:flush()

	-- 更新拥有的fame
	self.fame = fame or 0
	login:flushFame(true)

	-- 增加wallet地址
	self.wallet = wallet
	Global.ObjectManager:RPC_GetObjects(function()
		if wallet then
			Global.ObjectManager:getNft(function()
				Global.ObjectManager:setAvatarId(avatarid)
				Global.gmm.onEvent('showgramophone')
				Global.gmm.onEvent('showfamegift')
			end)
		else
			Global.ObjectManager:setAvatarId(avatarid)
			Global.gmm.onEvent('showgramophone')
		end
	end)

	-- 设置email
	self.email = email

	self.extra_info = extra_info

	-- 根据是否是gm, 判断debug按钮要不要添加
	if self:isGM() then
		Global.debugFuncUI:show(true)
	elseif self:checkGM(t, self.rtdata.logindata) then
		self:registerGM()
	end

	if isnew then
		onsuccesscb()
	end

	UPLOAD_DATA('login_success', Version:getChannel())
end
login.getName = function(self)
	return self.name
end
login.setName = function(self, n, c)
	self.name = n
	self.namecode = c
end
login.getEmail = function(self)
	return self.email
end
login.setEmail = function(self, e)
	self.email = e

	RPC('UpdateEmail', {Email = e})
end
login.getExtraInfo = function(self)
	return self.extra_info
end
login.setExtraInfo = function(self, infos)
	for i, v in pairs(infos) do
		self.extra_info[i] = v
	end

	RPC('UpdateExtraInfo', {Info = infos})
end
login.changeName = function(self, name, onsuccess, onerr)
	if name == '' then
		return
	end

	self.OnChangeName = onsuccess
	self.OnChangeNameErr = onerr

	UPLOAD_DATA('login_changename_send', Version:getChannel())
	RPC('UpdateName', {Name = name})
end
login.getActiveness = function(self)
	return self.activeness
end
login.changeActiveness = function(self, active, flush)
	if self.activeness == active then return end

	local oldactivenesss = self.activeness
	self.activeness = active
	if flush then
		Global.CoinUI:flush()
		Global.gmm:clearObtainCoin()
		Global.Browser:flushItemButton()
	else
		Global.gmm:addObtainCoin(self.activeness - oldactivenesss)
	end
end
-- num 累加数值, 扣除时传负数
login.updateActiveness = function(self, num, flush)
	if num == 0 then
		print('login:updateActiveness 0 can not add')
		return
	end

	flush = flush or flush == nil
	Global.RegisterRemoteCbOnce('onUpdateMyActivenessInfo', 'flush', function(active)
		self:changeActiveness(active, flush)
		return true
	end)

	RPC('UpdateMyActiveness', {Activeness = num})
end

login.getMusic = function(self)
	return self.music
end
login.changeMusic = function(self, music)
	print('changeMusic', music)
	if self.music == music then return end
	self.music = music
end
login.getMusicPlaying = function(self)
	return self.musicplaying
end
login.changeMusicPlaying = function(self, musicplaying)
	if self.musicplaying == musicplaying then return end
	self.musicplaying = musicplaying
end

login.getFame = function(self)
	return self.fame
end
login.changeFame = function(self, fame, flush)
	if self.fame == fame then return end
	self.fame = fame
	login:flushFame()
end
login.flushFame = function(self, nowin)
	if Global.role and Global.GameState:isState('GAME') then
		if Global.CoinUI.famenum ~= self.fame then
			if not nowin then
				Global.SwitchControl:set_input_off()
				Global.role:playAnima('win', false, function()
					local img = _Image.new('fame.png')
					img.w = 150
					img.h = 150
					img.tick = os.now() + 800
					img.delay = 300
					img.nobg = true
					Global.role.node.expimg = img
					local aabb = Global.role.node.mesh:getBoundBox()
					local height = aabb.z2 - aabb.z1 + 0.5
					local mat = _Matrix3D.new()
					mat:set(Global.role.node.transform)
					mat:mulTranslationRight(0, 0, height, 0)
					Global.sen.pfxPlayer:play('ui_mybz_shanyixia.pfx', 'ui_mybz_shanyixia.pfx', mat)
					Global.Sound:play('showfame')
					Global.Timer:add('gmm_fame', 800, function()
						Global.role.node.expimg = nil
						Global.CoinUI:flush()
					end)
				end)
				Global.Sound:play('addfame')
				Global.Timer:add('winend', Global.role.currentAnima.duration - 60, function()
					Global.SwitchControl:set_input_on()
				end)
			else
				Global.CoinUI:flush()
			end
		end
	end
end
-- ms
login.setServerTime = function(self, st)
	assert(st, "Server time not exist")
	self.sTime = st
	self.cTime = _now(0.001)
end
login.getServerTime = function(self)
	local now = _now(0.001)

	return now - self.cTime + self.sTime
end
login.isGM = function(self)
	local value = Global.Achievement:getAchievementValue('GameMaster')
	return Global.Achievement:check(value)
end
login.registerGM = function(self)
	local value = Global.Achievement:getAchievementValue('GameMaster')
	Global.Achievement:register(value, function()
		Global.debugFuncUI:show(true)
	end)
	Global.Achievement:ask(value)
end
login.checkGM = function(self, type, data)
	if type ~= 'email' then
		return false
	end

	return GMList[data] and true or false
end
login.setWallet = function(self, wallet)
	if not self:isOnline() then
		return
	end
	self.wallet = wallet

	RPC("UpdateWallet", {Wallet = wallet})

	Global.ObjectManager:getNft()
end
login.getWallet = function(self)
	return self.wallet
end
login.loginFailed = function(self, fmsg)
	-- Notice(Global.TEXT.NOTICE_LOGIN_FAILED)
	if OnlyWalletConnect then
		-- todo: 去除等待标志
		self:logout()
		Global.Wallet:stopBrowser()
		Global.LoginUI:show(true)
	else
		self:logout()
		Global.Wallet:stopBrowser()
		Global.LoginUI:show(true)
		if self.rtdata.logintype == 'email' then
			Global.LoginUI:showLogin()
			Global.LoginUI:Error(Global.TEXT.NOTICE_LOGIN_ERROR)
		end
	end

	if fmsg == 'Without_NFT' then
		local msg = [[0]]
		Global.FullScreenNotice:show(msg, 1, function()
			Global.FullScreenNotice:hide()
		end)
	end

	if fmsg == 'Version_Error' then
		Global.FullScreenNotice:show(Global.TEXT.NOTICE_VESION_UPDATE, 0, function() end, function() end)
	end
end
-----------------------------------------------------
define.GetLoginInfo{Info = {}}
when{}
function GetLoginInfo(Info)
	if Info.aid == -1 then
		login:loginFailed(Info.fmsg)
	else
		-- Notice(Global.TEXT.NOTICE_LOGIN_SUCCESS)
		login:loginSuccess(Info.aid, Info.avatar, Info.name, Info.active, Info.stime, Info.wallet, Info.avatarid, Info.fame, Info.email, Info.extra_info)
	end
end

define.SignUpInfo{Result = false, Info = {}}
when{}
function SignUpInfo(Result, Info)
	if not Result then
		Global.LoginUI:Error(Info.res)
	end
end

define.UpdateNameInfo{Result = false, Info = {}}
when{}
function UpdateNameInfo(Result, Info)
	if Result then
		login:setName(Info.name or Info.res, Info.namecode)
		if login.OnChangeName then
			login.OnChangeName(Info.res)
			UPLOAD_DATA('login_changename_success')
		end
	else
		if login.OnChangeNameErr then
			login.OnChangeNameErr(Info.res)
			UPLOAD_DATA('login_changename_error')
		end
	end
end

define.UpdateAvataridInfo{Result = false, Info = {}}
when{}
function UpdateAvataridInfo(Result, Info)
	if Result then
		Global.ObjectManager:setAvatarId(Info.res)
	end
end

define.UpdateMyActivenessInfo{Result = false, Info = {}}
when{}
function UpdateMyActivenessInfo(Result, Info)
	if Result then
		-- Notice('Change Activeness ' .. Info.res)
		if Global.hasRemoteCb('onUpdateMyActivenessInfo') then
			Global.doRemoteCb('onUpdateMyActivenessInfo', Info.res)
		else
			login:changeActiveness(Info.res, Info.res < login.activeness)
		end

		-- TODO: 商店里刷新商店的钱，先放在这里
		if Global.Shop and Global.Shop.ui and Global.Shop.ui.visible then
			Global.Shop:flushDeposit()
		end
	else
		print('Change Activeness Error')
	end
end

define.UpdateMyFameInfo{Result = false, Info = {}}
when{}
function UpdateMyFameInfo(Result, Info)
	if Result then
		login:changeFame(Info.res)
	else
		print('Change Fame Error')
	end
end

define.UpdateMyMusicInfo{Result = false, Info = {}}
when{}
function UpdateMyMusicInfo(Result, Info)
	if Result then
		dump(Info)
		login:changeMusic(Info.res.music)
		login:changeMusicPlaying(Info.res.musicplaying)
	else
		print('Change Music Error')
	end
end

define.Logout{Reason = ''}
when{}
function Logout(Reason)
	print('Logout ' .. Reason or '')

	login:logout()

	--TODO:最暴力的处理方式
	_reset('code.lua')
end