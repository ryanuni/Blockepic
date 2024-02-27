
local btnlist = {}
local funclist = {}
funclist.alpha1 = {
	'Reset', 'changescreen', 'debuginfo', 'ResetAccount', 'SkipGuide',
	'ClearCache', 'DumpCache', 'ShowKnots', 'timechange', 'ShowBrickID',
	'puzzle', 'playrepair', 'Skill', 'ERROR', 'enableShadow',
	'objectlimit', 'RepairAsset', 'newday', 'OpenAutoRepair', 'AddRepairProgress',
	'downloadObjects', 'ShowDelay'
}
funclist.demo = {
	'Reset', 'guide',
	'debuginfo',
	'buildbrick',
	'timechange',
	'changescreen',
	'speed',
	'StopBGM',
}
funclist.dev = {
	'Reset',
	'debuginfo', 'switchui',
	'changescreen',
}

for version, t in pairs(funclist) do
	for _, k in ipairs(t) do
		btnlist[k] = {title = k}
	end
end

local debugmap = {}
if Version:isDemo() then
	for _, v in ipairs(funclist.demo) do
		table.insert(debugmap, v)
	end
elseif Version:isAlpha1() then
	for _, v in ipairs(funclist.alpha1) do
		table.insert(debugmap, v)
	end
else
	for _, t in pairs(funclist) do
		for _, v in ipairs(t) do
			local added = false
			for _, vv in ipairs(debugmap) do
				if v == vv then
					added = true
					break
				end
			end

			if not added then
				table.insert(debugmap, v)
			end
		end
	end
end

local debugFuncUI = {}
Global.debugFuncUI = debugFuncUI
debugFuncUI.init = function(self)
	if self.ui then return end

	self.ui = Global.UI:new('Debugger.bytes', 'global')
	local main = self.ui.debuglist
	self.ui.debugbutton.click = function()
		main.visible = not main.visible
		self.ui.bg.visible = main.visible
	end
	main.closebutton.click = function()
		self:close()
	end

	local list = main.debug.debuglist
	list.enableAdaptiveSize = true
	local childclick = false
	list.click = function()
		if childclick then
			childclick = false
			return
		end
		self:close()
	end

	self:flush()
end
debugFuncUI.show = function(self, show)
	if (_sys.os ~= 'win32' and _sys.os ~= 'mac') and Version:isAlpha1() and not Global.Login:isGM() then
		return
	end
	if _sys:getGlobal('PCRelease') and not Global.Login:isGM() then
		return
	end

	self:init()
	self.ui.visible = show
end
debugFuncUI.close = function(self)
	self.ui.debugbutton.selected = false
	self.ui.debuglist.visible = false
	self.ui.bg.visible = false
end
debugFuncUI.flush = function(self)
	local list = self.ui.debuglist.debug.debuglist
	list.onRenderItem = function(idx, debugitem)
		local data = btnlist[debugmap[idx]]
		debugitem.title.text = data.title
		debugitem.click = function()
			data.click()
			self:close()
		end
	end
	list.itemNum = #debugmap
end
debugFuncUI.resize = function(self)
	if not self.ui then return end
	-- List的关联不知道为什么老不对，只能硬更新
	local mc = self.ui.debuglist.debug
	mc.debuglist._width = mc._width
	mc.debuglist._height = mc._height
end
----------------------------------------------------------------------------------
-- 重置按钮
btnlist.Reset.click = function()
	_Fairy.root._alpha = 100

	if _sys:fileExist2('home_flag.lv') then
		_sys:delFile('home.lv')
		_sys:delFile('home_flag.lv')
	end
	-- reset 删除本地建造
	if Version:isDemo() then
		_sys:delFile('create_demo.sen')
	end

	Global.SaveManager:Reset()
	_reset('code.lua')
end

btnlist.debuginfo.title = not _sys.showVersion and 'Debug Info On' or 'Debug Info Off'
btnlist.debuginfo.click = function()
	btnlist.debuginfo.title = _sys.showVersion and 'Debug Info On' or 'Debug Info Off'
	debugFuncUI:flush()
	_sys.showStat = not _sys.showStat
	_sys.showVersion = not _sys.showVersion
	Global.Debug:switch()
end
if _sys:getGlobal('xl') then
	_sys.showStat = true
	Global.Debug:switch()
end

btnlist.switchui.title = 'Switch UI'
btnlist.switchui.click = function()
	Global.UI:switchGroup()
end

local skylightlist = {
	'Morning',
	'Noon',
	'Afternoon',
	'Evening'
}
local time = Global.SaveManager:Get('time')
local timer = _Timer.new()
local currenttime = time and math.ceil(time[1]) or 12
if currenttime >= 24 then
	currenttime = 0
end
btnlist.timechange.title = skylightlist[math.floor(currenttime / 6) + 1]
btnlist.timechange.click = function()
	Global.TimeOfDayManager:setCurrentTime(currenttime)
	-- Notice('Change from ' .. currenttime .. ' o\'clock')
	currenttime = currenttime + 6
	if currenttime >= 24 then
		currenttime = 0
	end
	btnlist.timechange.title = skylightlist[math.floor(currenttime / 6) + 1]
	debugFuncUI:flush()
	Global.TimeOfDayManager:start()
	timer:stop('spendtime')
	timer:start('spendtime', 10000, function()
		Global.TimeOfDayManager:stop()
		timer:stop('spendtime')
		Global.SaveManager:Set('time', {Global.TimeOfDayManager.curTime})
		Global.SaveManager:Save()
	end)
end

btnlist.buildbrick.title = 'Build Bricks'
btnlist.buildbrick.click = function()
	debugFuncUI:leaveFunc()
	Global.Guide:finish()
	Global.entry:goBuildBrick()
end

local function flushScreenText()
	btnlist.changescreen.title = _app:isScreenH() and 'Vertical screen' or 'Horizontal screen'
end
flushScreenText()
btnlist.changescreen.click = function()
	_app:changeScreen(_app:isScreenH() and 1 or 0)
	flushScreenText()
	debugFuncUI:flush()
end

btnlist.ResetAccount.title = 'ResetAccount'
btnlist.ResetAccount.click = function()
	debugFuncUI:leaveFunc()
	RPC('ResetAccount', {})
end

btnlist.SkipGuide.title = 'SkipGuide'
btnlist.SkipGuide.click = function()
	debugFuncUI:leaveFunc()
	Global.gmm:SkipGuide()
end

btnlist.DumpCache.title = 'DumpCache'
btnlist.DumpCache.click = function()
	Global.FileSystem:dump()
end

btnlist.ClearCache.title = 'ClearCache'
btnlist.ClearCache.click = function()
	Global.FileSystem:clearCache(true)
end

btnlist.ShowKnots.title = 'ShowKnots'
btnlist.ShowKnots.click = function()
	Global.showKnots = not Global.showKnots
end

btnlist.speed.title = 'Game Speed'
btnlist.speed.click = function()
	_app.speed = _app.speed / 2
	if _app.speed < 0.2 then
		_app.speed = 4
	end
	print(_app.speed)
end

btnlist.ShowBrickID.title = Global.brickui.showID and 'Hide Brick ID' or 'Show Brick ID'
btnlist.ShowBrickID.click = function()
	Global.brickui.showID = not Global.brickui.showID
	btnlist.ShowBrickID.title = Global.brickui.showID and 'Hide Brick ID' or 'Show Brick ID'
	debugFuncUI:flush()
	Global.brickui:refreshMainList()
end

btnlist.StopBGM.title = 'Stop BGM'
btnlist.StopBGM.click = function()
	Global.Sound:stop()
end

btnlist.Skill.title = 'FreeView'
btnlist.Skill.click = function()
	-- Global.ui.skill.visible = not Global.ui.skill.visible
	-- Global.role.skill_name = 'dance'
	-- _debug:testCrash()
	_G.FreeView = true
	local curcam = Global.CameraControl:get()
	curcam:followTarget()
	curcam:lockDirV(-3.14, 3.14)
	curcam:scale(1)
	_app:cameraControl({
		move = _System.MouseMiddle,
		rotate = _System.MouseRight,
	})
end

btnlist.puzzle.title = 'Fireworks Skill'
btnlist.puzzle.click = function()
	Global.ui.skill.visible = not Global.ui.skill.visible
	Global.role.skill_name = 'fireworks'
	-- Global.entry:go('browserbg.sen', 'PUZZLE', 'puzzle01.plv')
end

btnlist.objectlimit.title = 'Unlock All Objects'
btnlist.objectlimit.click = function()
	if Global.TempCheckLimit then
		Global.CheckLimit = Global.TempCheckLimit
		Global.TempCheckLimit = nil
		btnlist.objectlimit.title = 'Unlock All Objects'
		debugFuncUI:flush()
	else
		Global.TempCheckLimit = Global.CheckLimit
		Global.CheckLimit = function() return true end
		btnlist.objectlimit.title = 'Lock Objects'
		debugFuncUI:flush()
	end
end

btnlist.RepairAsset.title = 'RepairAsset'
btnlist.RepairAsset.click = function()
	local name = 'White_Bathtub'
	local bp = cfg_blueprint[name]
	Global.Achievement:delete(bp.achievement_object)
	if Global.Achievement:check(bp.achievement_blueprint) then
		Global.Blueprint:update(name, 1, nil, function()
		end)
	else
		Global.Achievement:ask(bp.achievement_blueprint)
	end

	RPC("GetBlueprints", {})
end

btnlist.OpenAutoRepair.title = 'OpenAutoRepair'
btnlist.OpenAutoRepair.click = function()
	Global.OpenAutoRepair = not Global.OpenAutoRepair
	print('Global.OpenAutoRepair', Global.OpenAutoRepair)
end

btnlist.AddRepairProgress.title = 'AddRepairProgress'
btnlist.AddRepairProgress.click = function()
	local pft = Global.PortalFixTask
	pft.progress = pft.progress + 10
	pft.subprogress = 0
	pft:updateTotalProgress(true)
end

Global.debug_downloadobject_id = 44 --------id
btnlist.downloadObjects.title = 'Download Objects'
btnlist.downloadObjects.click = function()
	local data = Global.debug_downloadobject_id
	Global.ObjectManager:RPC_GetObjectsByAid(data, function(objs)
		if objs and objs[1] then
			Global.downloadObjects(objs, nil, function()
				print('downloadObjects success', data, objs[1].name, objs[1].datafile.name, objs[1].picfile.name)
			end)
		end
	end)
end

Global.showdelay = false
btnlist.ShowDelay.title = 'ShowDelay'
btnlist.ShowDelay.click = function()
	Global.showdelay = not Global.showdelay
end

_G.debugRepairIndex = 1
btnlist.playrepair.title = 'Play Repair'
btnlist.playrepair.click = function()
	local ds = _G.cfg_repair[_G.debugRepairIndex]
	if ds and ds[1] then
		Global.entry:goRepair(ds[1].file)
	end

	_G.debugRepairIndex = _G.debugRepairIndex + 1
	if _G.debugRepairIndex > 5 then
		_G.debugRepairIndex = 1
	end
end

btnlist.ERROR.title = 'ERROR'
btnlist.ERROR.click = function()
	error_test.b = c
end

btnlist.enableShadow.title = _G.useOldShadow and 'disableShadow' or 'enableShadow'
btnlist.enableShadow.click = function()
	-- _G.useOldShadow = not _G.useOldShadow
	_rd.enableShadowProjection = _sys.enableOldShadow
	_sys.enableOldShadow = not _sys.enableOldShadow
	for _, b in next, Global.sen:getAllBlocks() do
		b.node.isShadowCaster = _sys.enableOldShadow
	end

	btnlist.enableShadow.title = _sys.enableOldShadow and 'disableShadow' or 'enableShadow'
	debugFuncUI:flush()
	print(btnlist.enableShadow.title)
end

debugFuncUI:show(true)

define.ResetAccountFinish{}
when{}
function ResetAccountFinish()
	btnlist.Reset.click()
end