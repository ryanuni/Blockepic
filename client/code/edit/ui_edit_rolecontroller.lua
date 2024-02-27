local Container = _require('Container')
local ui = Global.ui

local emojiChat = {}
Global.EmojiChat = emojiChat

emojiChat.showUI = function(self)
	Tip()
	ui.expression.visible = true
	self:select('anima')
	emojiChat.syncSkillVisible()
end

-- 展示表情列表
local emojis = Global.emojis

emojiChat.initUI = function(self)
	local animlist = ui.expression.animlist

	animlist.alphaRegion = 0x14001400
	animlist.onRenderItem = function(index, item)
		if index <= #Global.Animas then
			item.pic._icon = Global.AnimationCfg[Global.Animas[index]].icon
			item.click = function()
				self:playAnima(Global.Animas[index])
			end
		end
	end

	animlist.itemNum = #Global.Animas

	local es = ui.expression.emojis

	es.alphaRegion = 0x14001400
	es.onRenderItem = function(index, item)
		if index <= #emojis then
			local e = emojis[index]

			item.pic1._icon = Global.EmojiCfg[e].icon
			item.pic2._icon = Global.EmojiCfg[e].icon_sel

			item.click = function()
				if self:playEmoji(e) then
					item.selected = false
				end
			end
		end
	end

	es.itemNum = #emojis

	animlist.visible = true
end

emojiChat.playAnima = function(self, anima)
	-- print(anima)
	Global.role:playAnima(anima)
end

local emojiclicktick = 0
local lastEmoji
emojiChat.playEmoji = function(self, emoji)
	if _tick() - emojiclicktick > 500 then
		Global.role:applyFacialExpression(emoji)
		emojiclicktick = _tick()
		lastEmoji = emoji
	else
		return lastEmoji ~= emoji
	end
end

emojiChat.select = function(self, t)
	local show = t == 'emoji'
	ui.expression.emojis.visible = show
	ui.expression.animlist.visible = not show

	ui.expression.emoji.selected = show
	ui.expression.anima.selected = not show
end

ui.expression.emoji.click = function()
	emojiChat:select('emoji')
end

ui.expression.anima.click = function()
	emojiChat:select('anima')
end

ui.expression.close.click = function()
	Tip(Global.TEXT.TIP_EMOJIS)
	ui.expression.visible = false
	emojiChat.syncSkillVisible()
end

ui.updataRoleControllerPos = function()
	if not Global.role or not Global.role.mb.node then return end
	local pos = Container:get(_Vector2)
	local transPos = Container:get(_Vector3)
	Global.role.mb.node.transform:getTranslation(transPos)
	_rd:projectPoint(transPos.x, transPos.y, transPos.z, pos)
	local x, y = Global.UI:UI2ScreenPos(pos.x, pos.y)
	ui.rolecontroller._x, ui.rolecontroller._y = x, y
	--ui.expression._x, ui.expression._y = 0, 0
	Container:returnBack(pos, transPos)
end

local function setFrontCameraVisible(v)
	ui.frontcamera.open._visible = not v
	ui.frontcamera.roledb._visible = v
	ui.frontcamera.back._visible = v
	Global.FERManager.visible = v
	if v then
		Global.FERManager:open()
	else
		Global.FERManager:close()
	end
end

ui.rolecontroller.hide = function(self)
	ui.rolecontroller._visible = false
	setFrontCameraVisible(false)
	ui.frontcamera._visible = false
end

ui.updataRoleState = function()
	ui.rolecontroller.name.text = Global.Login:getName()
	ui.rolecontroller.full.text = '100/100'
	ui.rolecontroller.energy.text = '100/100'
end

ui.rolecontroller.back.click = function()
	ui.rolecontroller._visible = false
	ui.frontcamera.open._visible = false
end

ui.rolecontroller.build.click = function()
	if Global.Operate.disableUi then return end

	Global.GameState:changeState('EDIT')
	ui.rolecontroller._visible = false
	setFrontCameraVisible(false)
	ui.frontcamera._visible = false
end

ui.rolecontroller.bag.click = function()
	if Global.Operate.disableUi then return end

	Global.Bag:show(true)
	ui.rolecontroller._visible = false
end

-- ui.back.click = function()
-- 	if Global.Operate.disableUi then return end

-- 	Global.GameState:changeState('EDIT')
-- 	-- setFrontCameraVisible(false)
-- 	ui.rolecontroller._visible = false
-- 	-- ui.frontcamera._visible = false
-- end

ui.game.click = function()
	if Global.sen:isHome() then
		Global.sen:saveLevel()
		_File.writeString('home_flag.lv', '', 'utf-8')
		Notice('Saved!')
	end
	Global.GameState:changeState('GAME')
end

ui.exit.click = function()
	Global.sen:saveLevel()
	Notice('Saved!')
	Global.GameState:changeState('GAME')
	Global.entry:goHome()
end

local pickroletimer = _Timer.new()
local beginpos = {x = 0, y = 0}
ui.roledb.onMouseDown = function(args)
	beginpos.x = args.mouse.x
	beginpos.y = args.mouse.y
	pickroletimer:start('pick', 500, function()
		ui:showEdit(true, true, true)
		pickroletimer:stop()
	end)
end

ui.roledb.click = function()
	pickroletimer:stop('pick')
end

ui.roledb.onMouseMove = function(args)
	if math.abs(beginpos.x - args.mouse.x) > 10 or math.abs(beginpos.y - args.mouse.y) > 10 then
		pickroletimer:stop('pick')
	end
end

ui.roledb.onMouseUp = function()
	beginpos.x = 0
	beginpos.y = 0
	pickroletimer:stop('pick')
end

ui.rolecontroller.expression.click = function()
	if Global.Operate.disableUi then return end
	ui.expression._visible = true
	ui.rolecontroller._visible = false
end

-- ui.expression.back.click = function()
-- 	ui.expression._visible = false
-- 	ui.rolecontroller._visible = true
-- end

local function setFacialExpressionIcon(ui, icon, anima)
	if anima then
		ui._icon = 'img://e' .. icon .. '.png'
		ui.click = function()
			Global.role:playAnima(anima)
		end
		-- ui.title.text = anima
	else
		ui._icon = 'img://eempty.png'
	end
end

local function refreshFacialExpression()
	local fs = {}
	for i, v in ipairs(Global.shop_items) do
		if v.type == 'emotion' and Global.Achievement:check(v.data[1]) then
			fs[#fs + 1] = v
		end
	end
	for i = 1, 8 do
		local v = fs[i]
		-- setFacialExpressionIcon(ui.expression['e' .. i], v and v.icon, v and v.name)
	end
end

local animas = {'laugh', 'angry', 'win'}
for i = 1, 8 do
	-- setFacialExpressionIcon(ui.expression['e' .. i], animas[i], animas[i])
end

ui.frontcamera.open.click = function()
	print('front camera')
	Global.FERManager:init()
	setFrontCameraVisible(true)
end

ui.frontcamera.back.click = function()
	setFrontCameraVisible(false)
	ui.frontcamera._visible = ui.rolecontroller._visible or ui.expression._visible
end

----------==================== 

local clicktick = 0
emojiChat.onClick = function(self, x, y)
	if Global.ui.interact.main.visible then return end
	local dt = _tick() - clicktick
	clicktick = _tick()

	if dt < 500 then --doubleclick 
		Global.EmojiChat:initUI()
		Global.EmojiChat:showUI()
		clicktick = 0
	end
end

-----------------------------

Global.ui.skill.pic1._icon = 'skill1.png'
Global.ui.skill.pic2._icon = 'skill1.png'

Global.ui.skill.click = function()
	if not Global.sen:isLobby() then return end
	-- isLobby
	-- local skillname = avatar.skill
	if Global.role.usingSkill then
		Global.role:endSkill()
	else
		Global.role:useSkill(Global.role.skill_name or 'dance')
	end
	Global.ui.skill.selected = not not Global.role.usingSkill
end

local avatar_skill = {
	dancer = 'dance',
	inventor = 'fireworks',
}

emojiChat.syncSkillVisible = function()
	if Global.role == nil then return end

	if Global.role.skill_name and
		(ui.expression.visible == false and Global.ui.interact.currentObject == nil) then
		Global.ui.skill.visible = true
	else
		Global.ui.skill.visible = false
	end
end

emojiChat.enableSkill = function(enable)
	local avatar = Global.ObjectManager:get_nft_ava_name()
	local skill = avatar_skill[avatar]

	if enable and skill then
		Global.role.skill_name = skill
	else
		Global.role.skill_name = nil
	end
	emojiChat:syncSkillVisible()
end