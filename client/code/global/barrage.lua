local ob = {}

-- 默认的大小固定80 * 80
local defaultw = 80
local defaulth = 80
ob.genContentStr = function(self, content)
	local str = ''
	for i, v in ipairs(content) do
		str = str .. '{' .. v .. '}'
	end
	local final = string.gsub(str, "{(%w+)}", function(s)
		-- TODO: {表情} 的图标及适配
		local emoji = Global.EmojiCfg[s]
		if emoji then
			return genHtmlImg('img://' .. emoji.icon, defaultw, defaulth)
		else
			return ''
		end
	end)
	return final
end

local BarrageY = {20, 140, 260, 380}
local RowReserveLength = 320
local EACH_BARRAGE_TIME = 10 * 1000 -- ms
ob.new = function(parent, rowcount, content)
	if rowcount > 4 or rowcount < 1 then
		return
	end

	local o = {}
	setmetatable(o, {__index = ob})

	o.ui = parent:loadView('expcontent')

	o.ui.title.text = o:genContentStr(content)

	o.parenLength = parent._width
	o.ui._x = parent._width
	o.ui._y = BarrageY[rowcount]

	o.length = o.ui._width + RowReserveLength
	o.perMsStep = (o.length + parent._width) / EACH_BARRAGE_TIME

	o.id = _now(0.001)

	-- print("create one", table.ftoString(content), o.length, o.ui._x, o.ui._y, o.length + parent._width, EACH_BARRAGE_TIME, o.perMsStep)

	return o
end

ob.release = function(self)
	self.ui:removeMovieClip()
end

ob.update = function(self, e)
	self.ui._x = self.ui._x - self.perMsStep * e

	if self.ui._x < -self.length then
		self:release()
		return false
	else
		local outside = self.length - (self.parenLength - self.ui._x)
		outside = outside > 0 and outside or 0
		return true, outside
	end
end

local barrage = {}

Global.Barrage = barrage

local ONE_BARRAGE_ADD_TIME = 1000 --ms
local REFRESH_TIME = 5 * 1000 --ms

barrage.init = function(self)
	if self.ui then
		return
	end

	self.ui = Global.UI:new('Barrage.bytes')
	self.ui.visible = false

	self.barrages = {}
	self.nextIndex = 1
	self.needrefresh = false
	self.nextTorefresh = 0
	self.loop = true

	self.isplay = false
	self.BarrageItems = {}

	self.nextTimeToAdd = 0

	self.fourRowsX = {
		{
			id = 0,
			length = 0
		},
		{
			id = 0,
			length = 0
		},
		{
			id = 0,
			length = 0
		},
		{
			id = 0,
			length = 0
		},
	}
end

barrage.show = function(self, show, barrages)
	show = show == nil and true or show
	self:init()

	self.ui.visible = show
	if show then
		if barrages[1] then
			self:fillBarrages(barrages)
			Global.Timer:add('barrage', 300, function()
				Global.Sound:play('barrage')
			end)
		end

		-- 放入四条初始弹幕
		self:addNewBarrageItem()
		self:addNewBarrageItem()
		self:addNewBarrageItem()
		self:addNewBarrageItem()
		self.isplay = true
	else
		self:clear()
	end
end

barrage.onFinish = function() end

barrage.addNewBarrageItem = function(self)
	local content = self.barrages[self.nextIndex]
	if not content then
		if self.loop then
			self.needrefresh = true
		else
			if #self.BarrageItems == 0 then
				self.onFinish()
			end
		end
		return
	end

	local canFill = {}
	for i = 1, 4 do
		if self.fourRowsX[i].length <= 0 then
			table.insert(canFill, i)
		end
	end

	if #canFill == 0 then
		return
	end

	local random = math.random(#canFill)
	local index = canFill[random]
	self.nextIndex = self.nextIndex + 1

	local one = ob.new(self.ui.area, index, content)

	table.insert(self.BarrageItems, one)
	self.fourRowsX[index].id = one.id
	self.fourRowsX[index].length = one.length
end

barrage.barrageItemUpdate = function(self, time)
	for i = #self.BarrageItems, 1, -1 do
		local item = self.BarrageItems[i]
		local inside, outlength = item:update(time)

		for _, row in ipairs(self.fourRowsX) do
			if row.id == item.id then
				if inside then
					row.length = outlength
				else
					row.length = 0
					row.id = 0
				end
			end
		end

		if not inside then
			table.remove(self.BarrageItems, i)
		end
	end
end

barrage.updateAndAdd = function(self, time, needAdd)
	self:barrageItemUpdate(time)
	if needAdd then
		self:addNewBarrageItem()
	end

	if self.needrefresh then
		self.nextTorefresh = self.nextTorefresh + time

		if self.nextTorefresh >= REFRESH_TIME then
			self.needrefresh = false
			self.nextTorefresh = 0
			self.nextIndex = 1
		end
	end
end

barrage.fillBarrages = function(self, barrages)
	self.barrages = {}
	table.deep_clone(self.barrages, barrages)
	self.nextIndex = 1
end

barrage.addtoNext = function(self, barrage)
	local new = {}
	table.deep_clone(new, barrage)
	table.insert(self.barrages, self.nextIndex, new)
end

barrage.pause = function(self, pause)
	if not self.ui then
		return
	end

	if pause then
		self.isplay = false
		self.ui.visible = false
	else
		self.isplay = true
		self.ui.visible = true
	end
end

barrage.clear = function(self)
	self.barrages = {}
	self.nextIndex = 1
	self.needrefresh = false
	self.nextTorefresh = 0

	self.isplay = false

	for i, item in ipairs(self.BarrageItems) do
		item:release()
	end
	self.BarrageItems = {}

	self.nextTimeToAdd = 0

	self.fourRowsX = {
		{
			id = 0,
			length = 0
		},
		{
			id = 0,
			length = 0
		},
		{
			id = 0,
			length = 0
		},
		{
			id = 0,
			length = 0
		},
	}
end

barrage.update = function(self, e)
	if not self.ui then
		return
	end

	if not self.ui.visible then
		return
	end

	if not self.isplay then
		return
	end

	local filltime = ONE_BARRAGE_ADD_TIME - self.nextTimeToAdd
	local lasttime = e - filltime
	if lasttime > 0 then
		local count = math.floor(lasttime / ONE_BARRAGE_ADD_TIME)
		self:updateAndAdd(filltime, true)
		for i = 1, count do
			self:updateAndAdd(ONE_BARRAGE_ADD_TIME, true)
		end
		self.nextTimeToAdd = lasttime - ONE_BARRAGE_ADD_TIME * count
		self:updateAndAdd(self.nextTimeToAdd)
	else
		self.nextTimeToAdd = self.nextTimeToAdd + e
		self:updateAndAdd(e)
	end
end

_app:registerUpdate(barrage)

-----------------------------------------------------------

local be = {}
Global.BarrageEdit = be

local MAX_EMOJI_CONTENT = 10

be.init = function(self)
	if self.ui then
		return
	end

	self.ui = Global.UI:new('BarrageEdit.bytes')
	self.ui.visible = false
	self.emojilist = {
		left = self.ui.lemojis,
		right = self.ui.remojis
	}
	-- 目前为emoji列表
	self.content = {}
	self.content_ui = self.ui.content.title
	self.curObject = 0

	self.CloseCallback = nil

	self.ui.close.click = function()
		self.content = {}
		self:show(false)
	end

	self.ui.delete.click = function()
		self:deleteLast()
	end

	self.ui.confirm.click = function()
		if self.content[1] then
			Global.ObjectBarrage:addBarrage(self.curObject, self.content)
		end
		self:show(false)
	end
end

be.show = function(self, show, obj, callback)
	show = show == nil and true or show
	self:init()

	if self.ui.visible == false and show then
		Global.UI:pushAndHide('normal')
		self.oscreen = _app:getScreen()
		_app:changeScreen(0)
	elseif self.ui.visible == true and show == false then
		Global.UI:popAndShow()
		_app:changeScreen(self.oscreen)
	end

	self.ui.visible = show

	if show then
		if not obj then
			print("BarrageEdit ERROR: show = true need obj")
			return
		else
			self.curObject = obj
		end

		self:flushList()
		if callback then
			self.CloseCallback = callback
		end
	else
		if self.CloseCallback then
			self.CloseCallback(self.content)
		end

		self:clear()
	end
	self:flush()
end

be.add = function(self, emoji)
	if not emoji then
		return
	end

	if #self.content >= MAX_EMOJI_CONTENT then
		return
	end

	table.insert(self.content, emoji)
	self:flush()
end

be.cleanContent = function(self)
	self.content = {}
	self:flush()
end

be.deleteLast = function(self)
	if not self.content[1] then
		return
	end

	table.remove(self.content, #self.content)
	self:flush()
end

be.clear = function(self)
	self:cleanContent()
	self.curObject = 0
	self.CloseCallback = nil
end

-- 默认的大小固定80 * 80
local defaultw = 80
local defaulth = 80
be.genContentStr = function(self)
	local str = ''
	for i, v in ipairs(self.content) do
		str = str .. '{' .. v .. '}'
	end
	local final = string.gsub(str, "{(%w+)}", function(s)
		-- TODO: {表情} 的图标及适配
		local emoji = Global.EmojiCfg[s]
		if emoji then
			return genHtmlImg('img://' .. emoji.icon, defaultw, defaulth)
		else
			return ''
		end
	end)
	return final
end

be.flush = function(self)
	self.content_ui.text = self:genContentStr()
	if self.content[1] then
		self.ui.delete.disabled = false
		self.ui.content.visible = true
	else
		self.ui.delete.disabled = true
		self.ui.content.visible = false
	end
end

local splitenum = 8
be.flushList = function(self)
	local left = self.emojilist.left
	local right = self.emojilist.right

	local ldata = {}
	local rdata = {}

	for i = 1, #Global.emojis do
		if i <= splitenum then
			table.insert(rdata, Global.emojis[i])
		else
			table.insert(ldata, Global.emojis[i])
		end
	end

	-- print('flushList', table.ftoString(ldata), table.ftoString(rdata))

	left.onRenderItem = function(index, item)
		local data = ldata[index]

		item.pic1._icon = "img://" .. Global.EmojiCfg[data].icon
		item.pic2._icon = "img://" .. Global.EmojiCfg[data].icon

		item.click = function()
			self:add(data)
		end
	end
	right.onRenderItem = function(index, item)
		local data = rdata[index]

		item.pic1._icon = "img://" .. Global.EmojiCfg[data].icon
		item.pic2._icon = "img://" .. Global.EmojiCfg[data].icon

		item.click = function()
			self:add(data)
		end
	end

	if ldata[1] then
		left.visible = true
		left.itemNum = #ldata
	else
		left.visible = false
	end

	if rdata[1] then
		right.visible = true
		right.itemNum = #rdata
	else
		right.visible = false
	end
end