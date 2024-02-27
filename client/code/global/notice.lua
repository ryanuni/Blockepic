
local notice = {msg = {}}
local TIMEOUT = 5 * 1000
local COUNT = 2
notice.init = function(self)
	if self.ui then return end

	self.ui = Global.UI:new('Notice.bytes', 'global', true)
	self.ui.n1.visible = false
	if _sys:getGlobal('AUTOTEST') then
		self.ui.connecting.visible = false
	end

	Global.UI:onDeviceOrientation(self.ui, function(oriH)
		self.ui.n1._y = oriH and 62 or 200
	end)
end
notice.newMsg = function(self, msg)
	table.insert(self.msg, 1, {msg = msg, elapse = 0})
	if #self.msg > COUNT then
		self.msg[#self.msg] = nil
	end
	self:flush()
end
notice.flush = function(self)
	self:init()
	for i = 1, COUNT do
		local mc = self.ui['n' .. i + 1]
		if self.msg[i] then
			mc.visible = true
			mc.text.text = self.msg[i].msg
		else
			mc.visible = false
		end
	end
end
notice.specialupdate = function(self, e)
	local flag = false
	for i = #self.msg, 1, -1 do
		self.msg[i].elapse = self.msg[i].elapse + e
		if self.msg[i].elapse > TIMEOUT then
			self.msg[i] = nil
			flag = true
		end
	end

	if flag then
		self:flush()
	end
end
------------------------------------------------
_G.Tip = function(msg, icon)
	notice:flush()
	local mc = notice.ui.n1
	if msg then
		if icon then
			msg = genHtmlImg(icon) .. msg
		end
		mc.text.text = msg
		mc.visible = true
	else
		mc.visible = false
	end
end
_G.DownTip = function(msg, time)
	notice.ui.inputtip.visible = true
	notice.ui.inputtip.text.text = msg
	Global.Timer:add('showinputtip', time, function()
		notice.ui.inputtip.visible = false
	end)
end
_G.hideDownTip = function()
	notice.ui.inputtip.visible = false
end

-------------------------------------------------
_G.ShowConnecting = function(s)
	notice:init()
	notice.ui.connecting.visible = s
end
ShowConnecting(false)
-------------------------------------------------
_app:registerUpdate(notice)
_G.Notice = function(str)
	-- print('[Notice]', str)
	if str == nil or str == '' then
		print('[Notice] empty string', debug.traceback())
	end
	Global.Sound:play('ui_hint01')
	notice:newMsg(str)
end
define.NoticeMsg{Msg = ''}
when{}
function NoticeMsg(Msg)
	Notice(Msg)
end
