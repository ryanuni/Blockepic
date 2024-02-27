local bulletin = {
	Bulletins = {},
	ExtendFunc = {},
	DeleteFunc = {},
}

local Status = {
	Normal = 0,
	Read = 1,
	Done = 2,
}
Global.Bulletin = bulletin
bulletin.timer = _Timer.new()
bulletin.init = function(self)
	if self.ui then
		return
	end

	self.ui = Global.UI:new('Bulletins.bytes')
	self.ui.visible = false
	self.bb = self.ui.bulletinboard
	self.mail = self.ui.mail
	self.mail.visible = false
	self.list = self.bb.list
	-- 虚拟列表
	self.list.virtual = true
	self.ui.back.click = function()
		self:show(false)
		Global.gmm:askGuideStepCheckMail()
	end

	Global.UI:onDeviceOrientation(self.ui, function(oriH)
		-- refresh captureScreenImage
		self:show(false)
		self.timer:start('resetCapture', _app.elapse, function()
			self.timer:start('skip1', _app.elapse, function()
			self:show(true)
			self.timer:stop('skip1')
			end)
			self.timer:stop('resetCapture')
		end)
	end)
end

bulletin.show = function(self, show, holdback)
	show = show == nil and true or show
	self:init()

	if self.ui.visible == false and show then
		Global.UI:pushAndHide('normal')
	elseif self.ui.visible == true and show == false then
		Global.UI:popAndShow()
	end

	self.mail.visible = false
	if show then
		local callback = function()
			self.ui.visible = show
			self.ui.back.visible = show
			self.bb.visible = show
			Global.CoinUI:show(true)
			self:flush()
			-- 打开即阅读
			self:saveRead()
		end

		if holdback then
			callback()
		else
			_G:holdbackScreen(self.timer, callback)
		end
	else
		self.ui.visible = show
		self.ui.back.visible = show
		self.bb.visible = show
		Global.SwitchControl:set_render_on()
	end
end

bulletin.flushAndShowMail = function(self, data, content, hasgift)
	if not data then
		return
	end

	self.bb.visible = false
	self.ui.back.visible = false
	self.mail.visible = true
	self.mail.confirm.visible = not hasgift
	self.mail.getgift.visible = hasgift
	self.mail.delete.visible = true
	self.mail.delete.disabled = hasgift

	self.mail.content.content.text = content
	self.mail.content.content.onClickLink = function(hreftag)
		print("mail onClickLink", hreftag)
		if string.fstarts(hreftag, "http") then
			_sys:browse(hreftag)
		end
	end

	self.mail.confirm.click = function()
		self.mail.content.content.text = ''
		self:show(true, true)
	end
	self.mail.getgift.click = function()
		local achievements = data.achievements
		self:extend(data.time, function(buttetin, newachs)
			-- TODO: 关闭 做动作
			if buttetin.time == data.time then
				print("Extend Mail", table.ftoString(newachs))
			end
		end)
		-- 客户端直接返回，不等待服务器
		Global.gmm.checkmaildone = true
		self.mail.content.content.text = ''
		self:show(false)
	end
	self.mail.delete.click = function()
		self:del(data.time, function(buttetin)
			if buttetin.time == data.time then
				print("Delete Mail", data.time)
			end
		end)
		-- 客户端直接删除，不等待服务器
		self.Bulletins[data.time] = nil
		local index = 0
		for i, v in ipairs(self.Bulletins) do
			if v.time == data.time then
				index = i
				break
			end
		end

		if index > 0 then
			table.remove(self.Bulletins, index)
		end
		self:show(true, true)
		self.mail.content.content.text = ''
	end
end

--- 保存已阅读信息
bulletin.saveRead = function(self)
	local readlist = {}
	for i, v in ipairs(self.Bulletins) do
		if v.status == Status.Normal then
			table.insert(readlist, v)
		end
	end

	RPC("ReadBulletin", {Bulletins = readlist})
end

--- 检查是否已阅读
bulletin.checkNew = function(self)
	local hasnew = false
	for i, v in ipairs(self.Bulletins) do
		if v.status == Status.Normal then
			hasnew = true
		end
	end

	return hasnew
end

-- 默认的大小固定60 * 60
local defaultw = 60
local defaulth = 60
---@param str string "Sample: Pixie brought you {activeness}100 today"
bulletin.genNotice = function(self, str, activeness)
	if not str then
		return ''
	end
	if activeness and activeness ~= 0 then
		str = str .. ' {activeness}' .. activeness
	end
	local final = string.gsub(str, "{(.-)}", function(s)
		-- TODO: activeness 和 achievements 的图标及适配
		if s == 'activeness' then
			return genHtmlImg('ui://uleeqvg5h6l4sj', defaultw, defaulth)
		else
			local params = string.fsplit(s, ',')
			local obj = Global.GetObjectByAchievements(params)
			if obj then
				local name = tostring(obj.name) .. '-display.bmp'
				return genHtmlImg('img://' .. name, defaultw, defaulth)
			else
				return ''
			end
		end
	end)
	return final
end
bulletin.spliteByBreak = function(self, str)
	local index = string.find(str, '\n')
	local final = str
	if index then
		final = string.sub(str, 1, index)
	end
	return final
end

bulletin.flush = function(self)
	-- 重组array
	local datas = self.Bulletins

	self.list.onRenderItem = function(index, item)
		local data = datas[index]
		local final = ''
		local type = data.type
		local ismail = type == 'mail'
		if ismail then
			final = self:genNotice(data.contents)
		else
			final = self:genNotice(data.notice, data.activeness)
		end
		item.notice.text = self:spliteByBreak(final)
		item.notice.overflowElps = true

		if ismail then
			item.confirm.visible = false
			item.tomail.visible = true
		else
			item.confirm.visible = true
			item.tomail.visible = false
		end

		local done = data.status == Status.Done
		local hasgift = false
		if ismail then
			if done then
				item.icon._icon = "ui://uleeqvg5s1easu"
			else
				if data.activeness ~= 0 or data.achievements[1] then
					item.icon._icon = "ui://uleeqvg5s1east"
					hasgift = true
				else
					item.icon._icon = "ui://uleeqvg5s1easu"
				end
			end
		else
			item.icon._icon = "ui://uleeqvg5s1easw"
		end

		item.confirm.click = function()
			if type == 'notice' then
				item:gotoAndPlay('onpush')
				Global.Timer:add('clickitem', 500, function()
					if data.activeness ~= 0 then
						Global.RegisterRemoteCbOnce('onUpdateMyActivenessInfo', 'flush', function(active)
							Global.Login:changeActiveness(active, true)
							return true
						end)
					end
					self:extend(data.time)
				end)
			end
		end
		item.tomail.click = function()
			if type == 'mail' then
				item:gotoAndPlay('onpush')
				Global.Timer:add('clickitem', 500, function()
					self:flushAndShowMail(data, final, hasgift)
				end)
			end
		end
	end

	self.list.itemNum = #datas
	self.list:addSelection(1, true, true)
end

---拷贝 res 到 des
---
---@param self self
---@param des table
---@param res table
---@nodiscard
bulletin.copy = function(self, des, res)
	des.time = res.time
	des.aid = res.aid
	des.notice = res.notice
	des.activeness = res.activeness
	des.achievements = {}
	for i, v in ipairs(res.achievements or {}) do
		table.insert(des.achievements, v)
	end
	des.contents = res.contents
	des.type = res.type
	des.status = res.status
end

bulletin.check = function(self, time)
	if not time then
		return
	end

	for i, v in ipairs(self.Bulletins) do
		if v.time == time then
			return v
		end
	end

	return
end

bulletin.updateGuide = function(self)
	if Global.sen == nil then return end
	local block = Global.sen:getBlockByShape('bulletin')
	if block == nil then return end

	if Global.Achievement:check('checkmailfinish') and self:checkNew() then
		block:showGuide(true)
	else
		block:showGuide(false)
	end
end

bulletin.update = function(self, bulletins)
	local list = {}
	self.Bulletins = {}

	-- 按时间倒序排列
	table.sort(bulletins, function(a, b)
		return a.time > b.time
	end)

	for i, v in ipairs(bulletins) do
		if v.aid == Global.Login:getAid() then
			local data = {}
			self:copy(data, v)
			table.insert(self.Bulletins, data)
		end
	end

	-- print("update", table.ftoString(self.Bulletins))

	if self.ui and self.ui.visible then
		self:flush()
		-- 正在展示即阅读
		self:saveRead()
	end

	self:updateGuide()
end

bulletin.extend = function(self, time, callback)
	local b = self:check(time)
	if not b then
		return
	end

	if callback then
		self.ExtendFunc[time] = callback
	else
		self.ExtendFunc[time] = nil
	end

	RPC("ExtendBulletin", {Bulletin = b})
end

bulletin.add = function(self, notice, activeness, ismail, achievements, contents)
	-- RPC("AddBulletin", {PlayerId = Global.Login:getAid(), Notice = notice, Activeness = activeness, IsMail = ismail, Achievements = achievements, Contents = contents})
end

bulletin.del = function(self, time, callback)
	local b = self:check(time)
	if not b then
		return
	end

	if callback then
		self.DeleteFunc[time] = callback
	else
		self.DeleteFunc[time] = nil
	end

	RPC("DelBulletin", {Bulletin = b})
end

----------------------------------------------

define.UpdateBulletins{Bulletins = {}}
when{}
function UpdateBulletins(Bulletins)
	bulletin:update(Bulletins)
end

define.ExtendBulletinInfo{Result = false, Bulletin = {}, NewAchievements = {}}
when{}
function ExtendBulletinInfo(Result, Bulletin, NewAchievements)
	if Result then
		if bulletin.ExtendFunc[Bulletin.time] then
			bulletin.ExtendFunc[Bulletin.time](Bulletin, NewAchievements)
		end
	end
end

define.DeleteBulletinInfo{Result = false, Bulletin = {}}
when{}
function DeleteBulletinInfo(Result, Bulletin)
	if Result then
		if bulletin.DeleteFunc[Bulletin.time] then
			bulletin.DeleteFunc[Bulletin.time](Bulletin)
		end
	end
end