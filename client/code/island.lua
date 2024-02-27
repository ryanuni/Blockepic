local Island = {disabled = false, timer = _Timer.new()}

local ui = Global.UI:new('Island.bytes', 'screen')
ui._visible = false

Global.Island = Island

Island.show = function(self, name)
	Global.UI:pushAndHide('normal')
	ui._visible = true
	ui.name.text = name
	ui.namebg._visible = name ~= ''

	ui.bg.click = function()
		if self.disabled then return end

		self:exit()
	end
end

Island.registerExit = function(self, func)
	self.onExit = func
end

Island.exit = function(self)
	if self.onExit then
		self.onExit()
		self.onExit = nil
	end
	Global.UI:popAndShow('normal')
	ui._visible = false
end

local nameui = Global.UI:new('IslandName.bytes', 'screen')
nameui._visible = false

Island.startEditName = function(self)
	Global.UI:pushAndHide('normal')
	nameui._visible = true
	local mcname = nameui.name
	local prompttext = 'An unknown'
	mcname.text = Global.sen.title or prompttext

	mcname.focusIn = function(e)
		nameui.namenotice.text = ''
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

	local function confirmfunc()
		local str = nameui.name.text
		if str == prompttext then
			str = ''
		end

		str = string.gsub(str, '^[ \t]+', '')

		local len = string.len(str)
		local isfailed = len < 3 or len > 20 or (not Global.cFilter:checkIslandName(str))
		if isfailed == true then
			Global.Sound:play('ui_error01')
		end
		if len < 3 then
			nameui.namenotice.text = Global.TEXT.CREATE_NAME_LENGTH_MIN
			return
		end
		if len > 20 then
			nameui.namenotice.text = Global.TEXT.CREATE_NAME_LENGTH_MAX
			return
		end

		if not Global.cFilter:checkIslandName(str) then
			nameui.namenotice.text = Global.TEXT.CREATE_NAME_INVALID
			return
		end

		Global.Sound:play('ui_click01')
		nameui.confirm.disabled = true
		local timer = _Timer.new()
		timer:start('disable', 2000, function()
			nameui.confirm.disabled = false
			timer:stop('disable')
		end)

		Global.RegisterRemoteCbOnce('onChangeHouse', 'ChangeTitle', function(obj)
			Global.sen.title = obj.title
			self:onEditName()
			self:exitName()
			return true
		end)
		RPC('House_UpdateObject', {Data = {title = str}, Browser = ''})
	end
	nameui.confirm.click = confirmfunc
end

Island.editName = function(self)
	_G:holdbackScreen(self.timer, function() self:startEditName() end)
end

Island.onEditName = function() end

Island.exitName = function(self)
	Global.UI:popAndShow('normal')
	Global.SwitchControl:set_render_on()
	nameui._visible = false
end