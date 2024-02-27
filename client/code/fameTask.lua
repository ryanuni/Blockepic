local ft = {}
Global.FameTask = ft

--- 做任务, 目前只有 type:Fix_Portal
ft.doTask = function(self, type)
	-- if Global.ObjectManager:hasAstronautAvatar() == false then
		-- return
	-- end

	RPC('DoFameTask', {Type = type})
end

--------------------------------------------------------------------
--- 石碑数据获取
ft.getEarnInfo = function(self)
	RPC('GetFameEarnInfo', {})
end

--- 石碑fame接收到fame上
ft.obtainFameEarn = function(self)
	RPC('ObtainFames', {})
end

-------------------------------------------
-- 石碑数据更新
define.UpdateMyFameEarnInfo{Result = false, Info = {}}
when{}
function UpdateMyFameEarnInfo(Result, Info)
	--print('UpdateMyFameEarnInfo', Result, table.ftoString(Info.res), Info.behavior)
	if Result then
		Global.ObtainFame:updateFame(Info.res, Info.behavior)
	end
end

--------------------------------------------------------------------- 礼盒开启
ft.getFameGift = function(self)
	RPC('UpdateMyFameGift', {})
end

ft.openFameGift = function(self)
	Global.RegisterRemoteCbOnce('onOpenFameGift', 'openGift', function(num)
		Global.ui.interact:refresh()
		return true
	end)
	RPC('OpenMyFameGift', {})
end

---------------------
-- 礼物数据更新
define.UpdateMyFameGiftInfo{Result = false, Info = {}}
when{}
function UpdateMyFameGiftInfo(Result, Info)
	if Result then
		Global.fameUI:flushUI(Info.num)
	else
		Global.fameUI:flushUI()
	end

	Global.doRemoteCb('onOpenFameGift', Info.num)
	-- print(Result, table.ftoString(Info))
end
