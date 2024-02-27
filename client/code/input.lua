local input = {keys = {}, camera_dir = {}, funcs_camera = {} }
Global.InputManager = input

input.update_change = function(self, e)
	local function check_key(key)
		local isdown = _sys:isKeyDown(key)
		if self.keys[key] ~= isdown then
			self.keys[key] = isdown
			if isdown then
				self:onKeyDown(key)
			else
				self:onKeyUp(key)
			end

			self:onKeyChange(key)
		end
		self.keys[key] = isdown
	end

	for k, v in pairs(self.keys) do
		check_key(k)
	end
end

input.update_camera_change = function(self, e)
	if #self.funcs_camera == 0 then 
		return
	end

	local dir = _rd.camera:dir()
	if self.camera_dir.x == dir.x and self.camera_dir.y == dir.y then 
		return 
	end

	self.camera_dir.x = dir.x
	self.camera_dir.y = dir.y

	self:onCameraChange()
end

input.update = function(self, e)
	-- if Global.Operate:is_move_disabled() then
	if Global.SwitchControl:is_input_off() then
		return
	end

	self:update_camera_change(e)
	self:update_change(e)
end
-- new ------------------------------------------------
input.init = function(self)
	self.funcs_down = {}
	self.funcs_up = {}
	self.funcs_change = {}
	self.keys = {}
	self.camera_dir = {}
	self.funcs_camera = {}
end
input.onKeyDown = function(self, k)
	local funcs = self.funcs_down[k]
	if funcs then
		for i, v in ipairs(funcs) do
			v()
		end
	end
end
input.onKeyUp = function(self, k)
	local funcs = self.funcs_up[k]
	if funcs then
		for i, v in ipairs(funcs) do
			v()
		end
	end
end
input.onKeyChange = function(self, k)
	local funcs = self.funcs_change[k]
	if funcs then
		for i, v in ipairs(funcs) do
			v()
		end
	end

	for t, fs in next, self.funcs_change do
		if type(t) == 'table' then
			if t[k] then
				for i, v in ipairs(fs) do
					v()
				end
			end
		end
	end
end
input.onCameraChange = function(self)
	for i, v in ipairs(self.funcs_camera) do
		v()
	end
end
input.registerDown = function(self, k, func)
	local funcs = self.funcs_down[k]
	if not funcs then
		funcs = {}
		self.funcs_down[k] = funcs
		if type(k) == 'table' then
			for key in next, k do
				self.keys[key] = false
			end
		else
			self.keys[k] = false
		end
	end
	table.insert(funcs, func)
end
input.registerUp = function(self, k, func)
	local funcs = self.funcs_up[k]
	if not funcs then
		funcs = {}
		self.funcs_up[k] = funcs
		if type(k) == 'table' then
			for key in next, k do
				self.keys[key] = false
			end
		else
			self.keys[k] = false
		end
	end
	table.insert(funcs, func)
end
input.registerChange = function(self, k, func)
	local funcs = self.funcs_change[k]
	if not funcs then
		funcs = {}
		self.funcs_change[k] = funcs
		if type(k) == 'table' then
			for key in next, k do
				-- print('key', key)
				self.keys[key] = false
			end
		else
			self.keys[k] = false
		end
	end
	table.insert(funcs, func)
end

input.registerCameraChange = function(self, func)
	table.insert(self.funcs_camera, func)
end

_app:registerUpdate(input, 3)

local kevents = {
	-- {
	-- 	k = _System.KeyESC,
	-- 	func = function()
	-- 		if Version:isAlpha1() then
	-- 			Global.debugFuncUI.ui.debugbutton.click()
	-- 		else
	-- 			Global.role:Respawn()
	-- 		end
	-- 	end
	-- },
	{
		k = 192,
		func = function()
			local blocki = Global.sen:getBlockByShape('blocki')
			if blocki then
				blocki:applyAnim('idle', true, nil, true)
				blocki:playAnim('idle')
				print('blocki', 'idle')
			end
		end
	},
	{
		k = _System.Key1,
		func = function()
			local blocki = Global.sen:getBlockByShape('blocki')
			if blocki then
				blocki:applyAnim('run', false, nil, true)
				blocki:playAnim('run')
				print('blocki', 'run')
			end
		end
	},
	{
		k = _System.Key2,
		func = function()
			local blocki = Global.sen:getBlockByShape('blocki')
			if blocki then
				blocki:applyAnim('liedown', true, nil, true)
				blocki:playAnim('liedown')
				print('blocki', 'liedown')
			end
		end
	},
	{
		k = _System.Key3,
		func = function()
			local blocki = Global.sen:getBlockByShape('blocki')
			if blocki then
				blocki:applyAnim('standup', false, nil, true)
				blocki:playAnim('standup')
				print('blocki', 'standup')
			end
		end
	},
	{
		k = _System.Key4,
		func = function()
			local blocki = Global.sen:getBlockByShape('blocki')
			if blocki then
				local cfg = Global.AnimationCfg.surprise or {loop = false, rootz = false}
				blocki:applyAnim('surprise', cfg.loop, nil, cfg.rootz)
				blocki:playAnim('surprise')
				print('blocki', 'surprise')
			end
		end
	},
	{
		k = _System.Key5,
		func = function()
			local blocki = Global.sen:getBlockByShape('blocki')
			if blocki then
				local cfg = Global.AnimationCfg.talktoself or {loop = false, rootz = false}
				blocki:applyAnim('talktoself', cfg.loop, nil, cfg.rootz)
				blocki:playAnim('talktoself')
				print('blocki', 'talktoself')
			end
		end
	},
	{
		k = _System.Key6,
		func = function()
			local blocki = Global.sen:getBlockByShape('blocki')
			if blocki then
				local cfg = Global.AnimationCfg.think or {loop = false, rootz = false}
				blocki:applyAnim('think', cfg.loop, nil, cfg.rootz)
				blocki:playAnim('think')
				print('blocki', 'think')
			end
		end
	},
	{
		k = _System.Key7,
		func = function()
			local blocki = Global.sen:getBlockByShape('blocki')
			if blocki then
				local cfg = Global.AnimationCfg.speechless or {loop = false, rootz = false}
				blocki:applyAnim('speechless', cfg.loop, nil, cfg.rootz)
				blocki:playAnim('speechless')
				print('blocki', 'speechless')
			end
		end
	},
	{
		k = _System.Key8,
		func = function()
			local blocki = Global.sen:getBlockByShape('blocki')
			if blocki then
				local cfg = Global.AnimationCfg.nod or {loop = false, rootz = false}
				blocki:applyAnim('nod', cfg.loop, nil, cfg.rootz)
				blocki:playAnim('nod')
				print('blocki', 'nod')
			end
		end
	},
	{
		k = _System.Key9,
		func = function()
			local blocki = Global.sen:getBlockByShape('blocki')
			if blocki then
				local cfg = Global.AnimationCfg.remember or {loop = false, rootz = false}
				blocki:applyAnim('remember', cfg.loop, nil, cfg.rootz)
				blocki:playAnim('remember')
				print('blocki', 'remember')
			end
		end
	},
	{
		k = _System.Key0,
		func = function()
			local blocki = Global.sen:getBlockByShape('blocki')
			if blocki then
				local cfg = Global.AnimationCfg.laugh2 or {loop = false, rootz = false}
				blocki:applyAnim('laugh2', cfg.loop, nil, cfg.rootz)
				blocki:playAnim('laugh2')
				print('blocki', 'laugh2')
			end
		end
	},
	{
		k = 189,
		func = function()
			local blocki = Global.sen:getBlockByShape('blocki')
			if blocki then
				local cfg = Global.AnimationCfg.give or {loop = false, rootz = false}
				blocki:applyAnim('give', cfg.loop, nil, cfg.rootz)
				blocki:playAnim('give')
				print('blocki', 'give')
			end
		end
	},
}

local cc_parkour = {}
if _sys.os == 'win32' or _sys.os == 'mac' then
	cc_parkour.rotate = _System.MouseRight
else
	cc_parkour.rotate = 1
	cc_parkour.zoomAndRotate = 2
end

_G.TEMP_GAME_CALLBACK_PARKOUR = {
	addKeyDownEvents = kevents,
	cameraControl = cc_parkour,
	onClick = GAME_CALLBACK.onClick,
	onDown = GAME_CALLBACK.onDown,
	onMove = GAME_CALLBACK.onMove,
	onUp = GAME_CALLBACK.onUp,
}

local cc_homeparkour = {}
if _sys.os == 'win32' or _sys.os == 'mac' then
else
	cc_homeparkour.zoom = 2
end

_G.TEMP_GAME_CALLBACK_HOMEPARKOUR = {
	addKeyDownEvents = kevents,
	cameraControl = cc_homeparkour,
	onClick = GAME_CALLBACK.onClick,
	onDown = GAME_CALLBACK.onDown,
	onMove = GAME_CALLBACK.onMove,
	onUp = GAME_CALLBACK.onUp,
}
