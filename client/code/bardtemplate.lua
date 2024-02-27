local BardTemplate = {}
BardTemplate.timer = _Timer.new()
Global.BardTemplate = BardTemplate

BardTemplate.show = function(self)
	Global.UI:pushAndHide('normal')
	local callback = function()
		self.ui = self.ui or Global.UI:new('BardTemplate.bytes')
		self:updateList()
		Global.UI:slidein({self.ui})
		self.ui.visible = true

		-- print('self.ui', self.ui._width, self.ui._height, self.ui._xscale, self.ui._yscale)
	end
	_G:holdbackScreen(self.timer, callback)
end

BardTemplate.hide = function(self, slider)
	local hidefunc = function()
		Global.UI:popAndShow('normal')
		self.ui.visible = false
		Global.SwitchControl:set_render_on()
	end
	if slider then
		Global.UI:slideout({self.ui})
		Global.Timer:add('hideui', 150, function()
			hidefunc()
		end)
	else
		hidefunc()
	end
end

BardTemplate.updateList = function(self)
	local datas = {}
	local objs = Global.Objects
	for i, v in ipairs(objs) do
		if v.type == 'avatar' and v.mode == 'template' and v.template_icon then
			table.insert(datas, v)
		end
	end

	local list = self.ui.list

	local itemw = 0
	list.onRenderItem = function(index, item)
		local data = datas[index - 1]
		if index == 1 then
			item.desc1._icon = 'img://bardtemplate_font_blank.png'
			itemw = item._width
		else
			item.pic._icon = 'img://' .. data.template_icon
			item.desc1._icon = 'img://bardtemplate_font.png'
		end

		item.desc2.visible = false
		item.add.click = function()
			if index == 1 then
				Global.entry:goBuildAnima(nil, nil, 'newbard')
			else
				Global.entry:goBuildAnima(data.name, true, 'newbard')
			end

			self:hide()
		end
	end
	list.itemNum = #datas + 1

	if itemw ~= 0 then
		list._width = math.min((#datas + 1), 4) * itemw
	end

	self.ui.back.click = function()
		self:hide(true)
	end
end

--------------------------------------------------------------------
local LvTemplate = {}
LvTemplate.timer = _Timer.new()
Global.LvTemplate = LvTemplate

LvTemplate.show = function(self)
	Global.UI:pushAndHide('normal')
	local callback = function()
		self.ui = self.ui or Global.UI:new('BardTemplate.bytes')
		self:updateList()
		Global.UI:slidein({self.ui})
		self.ui.visible = true

		-- print('self.ui', self.ui._width, self.ui._height, self.ui._xscale, self.ui._yscale)
	end
	_G:holdbackScreen(self.timer, callback)
end

LvTemplate.hide = function(self, slider)
	local hidefunc = function()
		Global.UI:popAndShow('normal')
		self.ui.visible = false
		Global.SwitchControl:set_render_on()
	end
	if slider then
		Global.UI:slideout({self.ui})
		Global.Timer:add('hideui', 150, function()
			hidefunc()
		end)
	else
		hidefunc()
	end
end

LvTemplate.updateList = function(self)
	local datas
	if _sys:getGlobal('PCRelease') then
		datas = {
			{icon = 'dungeontemplate_icon5.png', shape = 'dungeon_template_main', istemplate = true, blocktype = 'scene', desc = '3D World'},
			{icon = 'dungeontemplate_icon6.png', shape = 'music_template', istemplate = true, blocktype = 'scene_music', desc = 'Music Parkour'},
			{icon = 'dungeontemplate_icon7.png', shape = 'music_dragon_0', istemplate = true, blocktype = 'scene_music', desc = 'Music Parkour'},
		}
	else
		datas = {
		{icon = 'dungeontemplate_icon1.png', desc = 'Build 3D World'},
		{icon = 'dungeontemplate_icon3.png', shape = 'dungeon_template_2d', istemplate = true, blocktype = 'scene_2D', desc = '2D Dungeon (Template)'},
		{icon = 'dungeontemplate_icon2.png', shape = 'dungeon_template_2d_blank', istemplate = true, blocktype = 'scene_2D', desc = '2D Dungeon'},
		{icon = 'dungeontemplate_icon5.png', shape = 'dungeon_template_3d', istemplate = true, blocktype = 'scene', desc = '3D Dungeon (Template)'},
		{icon = 'dungeontemplate_icon4.png', shape = 'dungeon_template_3d_blank', istemplate = true, blocktype = 'scene', desc = '3D Dungeon'},
		{icon = 'dungeontemplate_icon6.png', shape = 'music_template', istemplate = true, blocktype = 'scene_music', desc = 'Music Parkour'},
		{icon = 'dungeontemplate_icon7.png', shape = 'music_dragon_0', istemplate = true, blocktype = 'scene_music', desc = 'Music Parkour'},
		-- {icon = 'dungeontemplate_icon6.png', shape = 'music_xx_0', istemplate = true, blocktype = 'scene_music', desc = 'Music Parkour'},
		-- {icon = 'dungeontemplate_icon4.png', shape = 'dungeon_template_3d_blank', istemplate = true, blocktype = 'scene_music_sub'},
		}
	end
	-- local datas = {}
	-- table.insert(datas, {})
	-- table.insert(datas, {})

	local list = self.ui.list

	local itemw = 0
	list.onRenderItem = function(index, item)
		local data = datas[index]
		local w, h = item.pic._width, item.pic._height

		item.pic._icon = 'img://' .. data.icon
		item.bg.visible = false
		item.pic._width, item.pic._height = w, h
		item._width = w

		item.desc2.visible = true
		item.desc2.text = data.desc
		if index == 1 then
			itemw = item._width
		end

		item.add.click = function()
			Global.entry:goBuildScene(data.shape, data.istemplate, data.blocktype)
			self:hide()
		end
	end
	list.itemNum = #datas

	if itemw ~= 0 then
		list._width = math.min(#datas, 5) * itemw
	end

	self.ui.back.click = function()
		self:hide(true)
	end
end