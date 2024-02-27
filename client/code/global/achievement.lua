--[[
	成就/解锁系统

	本质就是一堆字符串（成就）的记录，通过查是否存在（比如：shop_unlock）来决定后续逻辑走向

	对外
		ask(string)
			向服务器发送一个增加条目的请求
		check(string)
			检查是否获得string成就
		register(string, func)
			注册一个获得string成就时要做的func
			在获得新成就时会把新成就做一遍

	用法
		1.直接check判断
			if Global.Achievement:check('lobby_unlock') then
				...
			else
				...
			end
		2.注册回调
			-- 默认是空函数/功能不开启
			Global.Shop.Show = function()
			end
			-- 在获得shop_unlock时可以开启商店（重写Show方法）
			Global.Achievement:register('shop_unlock', function()
				Global.Shop.Show = function(self)
					...
				end
			end)
	引导
	第一次进小岛
		first_time_home
		bag_unlock
	完成平台跳跃游戏
		lobby_unlock
			大厅*
		shop_unlock
			商店
	第一次进大厅
		-- first_time_lobby
	第一次购买动作
		emotion_unlock
	第一次从大厅回家园
		first_time_home_from_lobby
	建造功能
		build1
		build2
		build3
]]
_dofile('cfg_achievement.lua')
local am = {data = {}, funcs = {}}
Global.Achievement = am

am.ask = function(self, a)
--	print('[Achievement.ask]', a)
	if self.data[a] then return end
	_G.RPC('AddAchievement', {State = a})
end
am.check = function(self, a)
--	print('[Achievement.check]', a, self.data[a])
	if a == 'build1' then return true end
	return self.data[a] ~= nil
end
am.checkorask = function(self, a, func)
	if am:check(a) then
		func()
	else
		am:register(a, func)
		am:ask(a)
	end
end
am.delete = function(self, a)
	self.data[a] = nil
end
am.clear = function(self)
	self.data = {}
end
am.new = function(self, a)
	assert(a ~= '')
	if self.data[a] then
		return
	end
--	print('[Achievement.new]', a)
	self.data[a] = true
end
am.onNew = function(self, a)
	if self.funcs[a] then
		self.funcs[a]()
	end
end
-- 获得成就a时，调用func
am.register = function(self, a, func)
	self.funcs[a] = func
end

am.getAchievementValue = function(self, id, index)
	local ca = cfg_achievement[1]
	local ac = ca[id] and ca[id].value
	if not ac then
		return
	end

	return index and ac[index] or ac[1]
end

------------------------------------------------------------------------

define.AddAchievementInfo{Result = false, Info = {}}
when{}
function AddAchievementInfo(Result, Info)
	if not Result then
		print('AddAchievementInfo err', Info.res)
		return
	end

	am:new(Info.res)
	am:onNew(Info.res)
end

define.GetAchievementInfo{Result = false, Info = {}}
when{}
function GetAchievementInfo(Result, Info)
	if not Result then
		print('GetAchievementInfo err')
		return
	end
	for i, a in ipairs(Info.res) do
		am:new(a)
	end
end

define.ClearAchievement{Result = false, Info = {}}
when{}
function ClearAchievement(Result, Info)
	am:clear()
end