local SoundGroup = _require('SoundGroup')
local IntroduceSetting = {
	brief = {
		{
			image = 'introduce1.png',
			content = 'Blockepic is a colorful world built with bricks.',
			audio = 'introduce1',
		},
		{
			image = 'introduce2.png',
			content = 'Here, you can use bricks to create everything.',
			audio = 'introduce2',
		},
		{
			image = 'introduce3.png',
			content = 'Make your home beautiful, comfortable and varied.',
			audio = 'introduce3',
		},
		{
			image = 'introduce4.png',
			content = 'You can also create new avatars.',
			audio = 'introduce4',
		},
		{
			image = 'introduce5.png',
			content = 'And make many friends, together create a unique world with them.',
			audio = 'introduce5',
		},
	},
	showobject = {
		{
			image = 'introduce_showobject_1.png',
			content = '',
		},
		{
			image = 'introduce_showobject_2.png',
			content = '',
		},
		{
			image = 'introduce_showobject_3.png',
			content = '',
		},
		{
			image = 'introduce_showobject_4.png',
			content = '',
		},
	},
	buildbrick = {
		{
			image = 'introduce_buildbrick_1.png',
			content = '',
		},
		{
			image = 'introduce_buildbrick_2.png',
			content = '',
		},
		{
			image = 'introduce_buildbrick_3.png',
			content = '',
		},
		{
			image = 'introduce_buildbrick_4.png',
			content = '',
		},
		{
			image = 'introduce_buildbrick_5.png',
			content = '',
		},
	},
	buildanima = {
		{
			image = 'introduce_buildanima_1.png',
			content = '',
		},
		{
			image = 'introduce_buildanima_2.png',
			content = '',
		},
	},
	buildmaterial = {
		{
			image = 'introduce_buildmaterial_1.png',
			content = '',
		},
		{
			image = 'introduce_buildmaterial_2.png',
			content = '',
		},
	},
	buildsticker = {
		{
			image = 'introduce_buildsticker_1.png',
			content = '',
		},
		{
			image = 'introduce_buildsticker_2.png',
			content = '',
		},
	},
}
local Introduce = {disabled = false}

local ui = Global.UI:new('Introduce.bytes', 'screen')
ui._visible = false

Global.Introduce = Introduce

Introduce.show = function(self, name)
	Global.UI:pushAndHide('normal')
	ui._visible = true
	self.setting = IntroduceSetting[name]
	assert(self.setting, 'no setting: ' .. name)

	self.sg = SoundGroup.new()
	self.sg:setVolume(1)
	self:init()
	self:syncContent()
end

Introduce.init = function(self)
	self.curIndex = 1
	self.items = {}
	ui.ilist.onRenderItem = function(index, item)
		table.insert(self.items, item)
	end
	ui.ilist.itemNum = #self.setting

	ui.bg.click = function ()
		if self.curIndex >= #self.setting then
			self:exit()
		else
			self.curIndex = self.curIndex + 1
			self:syncContent()
		end
	end
end

Introduce.syncContent = function(self)
	local setting = self.setting[self.curIndex]
	for i, v in ipairs(self.items) do
		v.selected = i == self.curIndex
	end
	ui.content.text = setting.content
	if setting.content == nil or setting.content == '' then
		ui.next._y = ui._height - 130
	else
		ui.next._y = ui._height - 200
	end
	ui.bg.disabled = true
	ui.next.visible = false
	ui:gotoAndPlay('hideandshow')
	Global.Timer:add('hideandshow', 2000, function()
		ui.bg.disabled = false
		ui.next.visible = true
	end)
	Global.Timer:add('changeicon', 500, function()
		ui.loader._icon = 'img://' .. setting.image
	end)
	if setting.audio then
		self.sg:changePlaySource(setting.audio)
		self.sg:play()
	end
end

Introduce.exit = function(self)
	ui._visible = false
	ui.loader._icon = ''
	Global.UI:popAndShow('normal')
	self.sg:stop()
	self.sg = nil
	if self.onExit then
		self.onExit()
		self.onExit = nil
	end
end