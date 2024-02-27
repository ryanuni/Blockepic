--Global.Achievement:new('introducebuildbrick')
--Global.Achievement:new('introducebuildanima')
--Global.Achievement:new('buildavatar')

-- Global.entry:goBuildBrick('test')
-- Global.entry:goBuildShape(749)
-- Global.entry:goBuildKnot(324)
-- Global.entry:goBuildBrick()

-- Global.entry:goBuildHouse()

-- Global.entry:goBuildAnima()
-- Global.entry:goBuildTransition()
-- Global.entry:goBuildRepair()
-- Global.entry:goRepair()

-- Global.entry:goBuildBrick('baoxiang')
-- do return end
-----------------------------------------------------------------------------------

local SupportVersion = {
-- local b = Global.sen:createBlock({shape = 'Iron Throne2'})
	['0.24.0131.1540'] = true, --1.0.7windows
	['0.24.0201.1808'] = true, --1.0.7mac
}

Global.InputSender:init()
-- Global.InputSender:start()
Global.FrameSystem:init()

if _sys:getGlobal('empty') then
	if _sys:getGlobal('xl') then
		Global.Achievement:new('fristbuildbrick')
	end
	Global.entry:goBuildBrick()
	return
end

if _sys:getGlobal('GENAVAPIC') then
elseif _sys:getGlobal('BuildTransition') then
	Global.entry:goBuildTransition()
elseif _sys:getGlobal('EnterMarioDungeon') then
	Global.entry:goLevel(_sys:getGlobal('EnterMarioDungeon'))
	if Global.dungeon then
		Global.dungeon:start()
	end
	Global.ui.back.visible = false
elseif _sys:getGlobal('AUTOTEST') == nil then
	if CHECK_VERSION and SupportVersion[_sys.version] ~= true then
		Global.FullScreenNotice:show(Global.TEXT.NOTICE_VESION_UPDATE, 0, function() end, function() end)
		return
	end

	UPLOAD_DATA('game_start', Version:getChannel())
	Global.TimeOfDayManager:init()

	if Version:isDemo() then
		-- 创建完再显示
		Global.debugFuncUI:show(false)
	end

	Global.Copyright:init(function()
		Global.Login:ConnectAndLogin()
	end)
end

_app['onResize'].on(_rd.w, _rd.h)
math.randomseed(_now(0))