
local graffitibag = {
	curSelectIndex = 0,
}
Global.graffitiBag = graffitibag
graffitibag.timer = _Timer.new()
graffitibag.defaultname = 'graffiti'
graffitibag.defaultdbname = 'graffiti_db'
graffitibag.defaultext = 'bmp'
graffitibag.defaultnum = 100

graffitibag.init = function(self)
	if self.ui then return end

	self.tempui = {}

	self.ui = Global.ui.graffitilibrary
	self.bgui = Global.ui.bricklibrarybg
	Global.UI:onDeviceOrientation(self.ui, function(oriH)
		self.ui._width = oriH and 1440 or 1020
		self.ui._x = (Global.ui._width - self.ui._width) / 2 + 60
		self.ui._y = (Global.ui._height - self.ui._height) / 2
		self.ui.mainlist.itemNum = self.ui.mainlist.itemNum

		self:show(false)
		self.timer:start('resetCapture', _app.elapse, function()
			self.timer:start('skip1', _app.elapse, function()
			self:show(true)
			self.timer:stop('skip1')
			end)
			self.timer:stop('resetCapture')
		end)
	end)

	self.bgui.click = function()
	end

	Global.ui.reslib_back.click = function()
		Global.UI:slideout({self.ui, Global.ui.reslib_back}, nil, 'y')
		Global.Timer:add('hideui', 150, function()
			self:show(false)
		end)
	end

	self.graffitilist = {}
	for i = 1, self.defaultnum do
		local name = self.defaultname .. '_' .. i .. '.' .. self.defaultext
		if _G.showDBGraffiti then
			name = self.defaultdbname .. '_' .. i .. '.' .. self.defaultext
		end

		if _sys:fileExist(name) then
			table.insert(self.graffitilist, name)
		end
	end
end

graffitibag.show = function(self, s)
	self:init()
	if #self.graffitilist == 0 then
		Tip()
		s = false
	end

	if s ~= self.ui.visible then
		if s then
			Global.UI:pushAndHide('normal')
			Global.ui._visible = true
			for i, v in ipairs (Global.ui:getChildren()) do
				table.insert(self.tempui, {u = v, visible = v.visible})
				v.visible = false
			end
			if Global.Achievement:check('introducebuildsticker') == false then
				Global.Introduce:show('buildsticker')
				Global.Achievement:ask('introducebuildsticker')
			end
		else
			Global.UI:popAndShow()
			for i, v in ipairs(self.tempui) do
				v.u.visible = v.visible
			end
			self.tempui = {}
		end
	end

	if s then
		local callback = function()
			Global.UI:slidein({self.ui, Global.ui.reslib_back}, nil, 'y')
			self.ui.visible = s
			self.bgui.visible = s
			Global.ui.graffitilibrary.visible = s
			Global.ui.reslib_back.visible = s
			self:flush()

			Global.AddHotKeyFunc(_System.KeyESC, function()
				return self.ui.visible
			end, function()
				Global.ui.reslib_back.click()
			end)
		end

		_G:holdbackScreen(self.timer, callback)
	else
		self.ui.visible = s
		Global.ui.graffitilibrary.visible = s
		Global.ui.reslib_back.visible = s
		self.bgui.visible = s
		Global.SwitchControl:set_render_on()
		Global.ObjectManager:listen('objectbag')
	end
end

graffitibag.flush = function(self)
	if not self.ui then return end
	if self.ui.visible == false then return end

	local graffiticount = #self.graffitilist
	if graffiticount == 0 then
		return
	end

	self.ui.mainlist.alphaRegion = 0x14000500

	local itemNum = (math.floor(graffiticount / 8) + 1) * 8
	self.ui.mainlist.onRenderItem = function(index, item)
		if index < graffiticount + 1 then
			item.picload.visible = true
			item.window.visible = true
			item.graymask.visible = false
			local w, h = item.picload._width, item.picload._height
			local img = _Image.new(self.graffitilist[index])
			local ui = item.picload:loadMovie(img)
			ui._width = w
			ui._height = h

			item.click = function()
				self:show(false)
				Global.BuildBrick:addGraffitiToBlock(self.graffitilist[index], img.w, img.h)
			end
		else
			item.picload.visible = false
			item.window.visible = false
			item.graymask.visible = true
		end
	end

	self.ui.mainlist.itemNum = itemNum
end