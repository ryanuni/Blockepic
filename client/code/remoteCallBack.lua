local remotecbs = {}

--支持的回调种类
local remoteTypes = {
	onGetObjectCollects = true,
	onChangeLike = true,
	onChangeCollect = true,
	onChangeObject = true,
	onChangeObjectErr = true,
	onChangeObjectRecommand = true,
	onChangeHouse = true,
	onChangeHouseErr = true,
	onChangeHouseRecommand = true,
	-- onUpdateSystemTags = true,
	onUploadObject = true,
	onChangeObjectName = true,
	onDeleteUploadObject = true,

	onOpenFameGift = true,

	onUpdateBlueprint = true,
	onGetBlueprints = true,

	onUpdateMyActivenessInfo = true,
}

for type in pairs(remoteTypes) do
	remotecbs[type] = {}
end

Global.RegisterRemoteCb = function(type, name, cb, filter, once)
	local cbs = remotecbs[type]
	assert(cbs, 'remote type is not exsit:' .. type)

	for i, v in ipairs(cbs) do
		if v.name == name then
			v.cb = cb
			v.filter = filter
			return
		end
	end

	table.insert(cbs, {name = name, cb = cb, filter = filter, once = once})
end

-- 使用once的时候cb必须有返回值
Global.RegisterRemoteCbOnce = function(type, name, cb, filter)
	Global.RegisterRemoteCb(type, name, cb, filter, true)
end

Global.UnregisterRemoteCb = function(type, name)
	local cbs = remotecbs[type]
	assert(cbs, 'remote type is not exsit:' .. type)
	for i, v in ipairs(cbs) do
		if v.name == name then
			table.remove(cbs, i)
			return
		end
	end
end

local enableRemote = true
Global.enableRemoteCb = function(enable)
	enableRemote = enable
end

Global.doRemoteCb = function(type, data, ...)
	if not enableRemote then return end

	local cbs = remotecbs[type]
	local removeindexs = {}
	for i, v in ipairs(cbs) do
		if not v.filter or v.filter(data, ...) then
			--once为true时根据cb结果判断是否成功
			if v.cb(data, ...) and v.once then
				table.insert(removeindexs, i)
			end
		end
	end

	for i = #removeindexs, 1, -1 do
		table.remove(cbs, removeindexs[i])
	end
end

Global.hasRemoteCb = function(type)
	return #remotecbs[type] > 0
end