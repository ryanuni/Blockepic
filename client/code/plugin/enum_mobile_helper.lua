_debug.enableProfiler = true
--[[
    MobileHelper的自定义表头数据
    根据项目组情况自己改
]]

--表头数组
-- 表头数组两种填写方式：
-- 1是直接填表头字符串，用 PMobileHelper.set/update/add 等方法设置值， 如下例所示的 SceneId
-- 2是用 表头字符串=自定义获取数据方法这种方式， 如下例所示的 PosX
local _customTypes = {
	'mainUpdate',
	'senRender',
	'senUpdate',
	'roleUpdate',
}

local _customHeads = {
	'FrameId', --帧标记
	'SceneName', --当前场景
	--'UserDefined',
	-- 'useSkill', --使用技能
	-- 'crtEntity', --创建entity
	-- 'PlayAni',	--播动画次数
	-- 'initUI',  --初始化Ui
    Level = function()
        return Sdata and Sdata.pinfo and Sdata.pinfo.level or 0
    end
	-- 'SceneId',
	-- PosX = function()
	-- 	return 1
	-- end,
}

for i, v in ipairs(_customTypes) do
	table.insert(_customHeads, v)
end

_G.MH_CUSTOM_TYPE = {}  --上报时使用的枚举

-- 处理表头数组
local _tempHeads = {}
local idx = 0

-- 添加资源加载时间上报
_debug.enableResLoadProfiler = true
_debug.resLoadThreshold = 3 -- 加载时间超过改阈值的上报

local _logKeys = { 'LogResLoad'}
for i, key in ipairs(_logKeys) do
    idx = idx + 1
    MH_CUSTOM_TYPE[key] = idx

	local data = {}
    data.key = key
    data.getFunc = function()
		return _debug:log(_Debug[key])
	end
    table.push(_tempHeads, data)
end

-- 自定义数据上报
for k, v in pairs(_customHeads) do
    idx = idx + 1
    local data = {}
    local key, getFunc
    if type(v) == 'function' then
        key = k
        getFunc = v
    else
        key = v
    end
    MH_CUSTOM_TYPE[key] = idx
    data.key = key
    data.getFunc = getFunc              -- 可以自定义获取数据的方法，替换 MobileHelper 的 get 方法
    table.push(_tempHeads, data)
end

local Log = require('lib.lua.log')          -- 日志打印模块
Log.setPrinter(print)

_G.PMobileHelper = require('lib.mobile_helper')

--设置自定义表头
PMobileHelper.setCustomHead(_tempHeads)

PMobileHelper.setCaseDoneCfg('base', 'Level', 101)
--[[

统计的列子----------------------------------------------------------------
    local lastTime = PMobileHelper.now(0)
    执行要统计时间的代码段
    ......
    PMobileHelper.set(MH_CUSTOM_TYPE.GameIdle, PMobileHelper.now(0) - lastTime)
]]

local bs = {}
function _G.MH_beginRecord(type)
	if not PMobileHelper then return end
	if MH_CUSTOM_TYPE[type] then
		bs[type] = _now(0)
	end
end

local rs = {}
function _G.MH_endRecord(type)
	if not PMobileHelper then return end

	if MH_CUSTOM_TYPE[type] then
		if bs[type] then
			rs[type] = _now(0) - bs[type] + (rs[type] or 0)
		end
	end
end

function _G.MH_uploadCustomType()
	if not PMobileHelper then return end

	for i, type in ipairs(_customTypes) do
		local time = rs[type] or 0
		PMobileHelper.set(_G.MH_CUSTOM_TYPE[type], time / 1000)
	end

	table.clear(bs)
	table.clear(rs)
end

