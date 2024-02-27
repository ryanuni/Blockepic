local pickroletimer = _Timer.new()
local beginpos = {x = 0, y = 0}

_G.GAME_CALLBACK = Version:isAlpha1() and
{
	onClick = function(x, y)
		if Global.sen:isHouse() then
			Global.EmojiChat:onClick(x, y)
		end
	end
}
or
{
	onClick = function(x, y)
		local block = Global.sen:pickBlock(x, y)
		if block and block.onPick then
			block:onPick()
		end
		pickroletimer:stop('role')
	end,
	onDown = function(btn, x, y)
		if btn ~= 0 then return end
		beginpos.x = x
		beginpos.y = y
		pickroletimer:start('role', 500, function()
			Global.ui:updataRoleState()
			Global.ui.rolecontroller._visible = true
			Global.ui.rolecontroller.build._visible = Global.sen:isHome() or Global.sen:isGuide()
			Global.ui.rolecontroller.expression._visible = not Global.sen:isGuide()
			Global.ui.frontcamera._visible = not Global.sen:isGuide()
			Global.ui.frontcamera.open._visible = true
			Global.ui.frontcamera.roledb._visible = false
			Global.ui.frontcamera.back._visible = false
			pickroletimer:stop()
		end)
	end,
	onMove = function(x, y)
		if math.abs(beginpos.x - x) > 10 or math.abs(beginpos.y - y) > 10 then
			pickroletimer:stop('role')
		end
	end,
	onUp = function(btn, x, y)
		beginpos.x = 0
		beginpos.y = 0
		pickroletimer:stop('role')
	end
}

Global.GameState:onEnter(function()
	if Global.GameState.oldStateName == 'EDIT' then
		Global.RegisterValue:reset()
		Global.sen:inGame()
	end

	-- _rd.camera:setBlocker(Global.sen, Global.CONSTPICKFLAG.NORMALBLOCK)
	_rd.camera.cameraLagSpeed = 5

	if Global.dungeon == nil then
		local c = Global.CameraControl:get()
		if c:getDirV() < 0.01 then
			c:moveDirV(math.pi / 6)
		end
	end

	if Global.dungeon == nil then
		Global.CoinUI:show(true)
		Global.ProfileUI:show(true)
	end

	-- print('enter', Global.sen.name)

end, 'GAME')

Global.GameState:onLeave(function()
	-- print('leave', Global.sen.name)

	Global.RegisterValue:reset()
	Global.CoinUI:show(false)
	Global.ProfileUI:show(false)
	-- _rd.camera.blocker = nil
	-- reset shadow
	_sys.enableOldShadow = true
	_rd.enableShadowProjection = false

end, 'GAME')