local ob = {
	Callbacks = {},
	Barrages = {}
}
Global.ObjectBarrage = ob

ob.getBarragesByID = function(self, oid, callback, refresh)
	if self.Barrages[oid] and not refresh then
		if callback then
			callback(self.Barrages[oid])
		end
	else
		self.Callbacks[oid] = callback

		RPC("Get_Barrages", {ObjectID = oid})
	end
end

--TODO：移动到显示
ob.genEmojis = function(self, str)
	local final = string.gsub(str, "{(%w+)}", function(s)
	-- TODO: {表情} 的图标及适配
		local emoji = Global.EmojiCfg[s]
		if emoji then
			return genHtmlImg('img://' .. emoji.icon)
		else
			return ''
		end
	end)

	return final
end

ob.genTable = function(self, contract)
	local final = {}

	for word in string.gmatch(contract, "{(%w+)}") do
		table.insert(final, word)
	end

	return final
end

ob.getBarrages = function(self, oid, barrages)
	local callback = self.Callbacks[oid]

	-- 按时间倒序
	table.sort(barrages, function(a, b)
		return a.time > b.time
	end)

	local res = {}
	for i, v in ipairs(barrages) do
		if v.content then
			local content = self:genTable(v.content)
			table.insert(res, content)
		end
	end
	self.Barrages[oid] = res

	if callback then
		callback(res)
		self.Callbacks[oid] = nil
	end
end

ob.genContent = function(self, emojis)
	local final = ''
	for i, v in ipairs(emojis) do
		final = final .. '{' .. v .. '}'
	end

	return final ~= '' and final
end

---增加弹幕, 当前版本为emoji的集合
---@param oid int objectid
---@param emojis table
ob.addBarrage = function(self, oid, emojis)
	local content = self:genContent(emojis)
	if content then
		RPC("Create_Barrage", {ObjectID = oid, Content = content})

		self.Barrages[oid] = self.Barrages[oid] or {}
		table.insert(self.Barrages[oid], 1, emojis)

		return str
	end
end

----------------------------------------------------------

define.CreateBarrageInfo{Result = false, Info = {}}
when{}
function CreateBarrageInfo(Result, Info)
	if Result then
		print("CreateBarrageInfo", table.ftoString(Info))
	end
end

define.GetBarragesInfo{Result = false, Info = {}, ObjectID = 0}
when{}
function GetBarragesInfo(Result, Info, ObjectID)
	if Result then
		ob:getBarrages(ObjectID, Info)
	end
end