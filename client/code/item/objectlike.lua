local obj_likes = {}
local house_likes = {}
local obj_collects = {}
local house_collects = {}

local obj_recommands = {}
local house_recommands = {}

local function UpdateObjectLikes(obj)
	local id = obj.id
	if obj.tag == 'house' then
		if house_likes[id] then
			table.copy(house_likes[id], obj)
		else
			house_likes[id] = obj
		end
	else
		if obj_likes[id] then
			table.copy(obj_likes[id], obj)
		else
			obj_likes[id] = obj
		end
	end

	Global.UpdateObjectsData(obj)
end

local function DeleteObjectLikes(obj)
	if obj.tag == 'house' then
		house_likes[obj.id] = nil
	else
		obj_likes[obj.id] = nil
	end
end

local function UpdateObjectCollects(obj)
	local id = obj.id
	if obj.tag == 'house' then
		if house_collects[id] then
			table.copy(house_collects[id], obj)
		else
			house_collects[id] = obj
		end
	else
		if obj_collects[id] then
			table.copy(obj_collects[id], obj)
		else
			obj_collects[id] = obj
		end
	end

	Global.UpdateObjectsData(obj)
end

local function DeleteObjectCollects(obj)
	if obj.tag == 'house' then
		house_collects[obj.id] = nil
	else
		obj_collects[obj.id] = nil
	end
end

local function UpdateObjectRecommands(data)
	local obj = data[1]
	if obj and obj.tag == 'house' then
		table.clear(house_recommands)
		table.copy(house_recommands, data)
	else
		table.clear(obj_recommands)
		table.copy(obj_recommands, data)
	end

	for i, v in ipairs(data) do
		Global.UpdateObjectsData(v)
	end
end

Global.getHouseCollects = function()
	return house_collects
end

Global.getObjectCollects = function()
	return obj_collects
end

Global.getObjectRecommands = function()
	return obj_recommands
end

Global.getHouseRecommands = function()
	return house_recommands
end
------------------------------------------------

define.AddObjectLikeInfo{Result = false, Info = {}}
when{}
function AddObjectLikeInfo(Result, Info)
	if Result then
		Global.doRemoteCb('onChangeLike', Info.res)
	else
		print('add Like failed')
	end
end

define.DelObjectLikeInfo{Result = false, Info = {}}
when{}
function DelObjectLikeInfo(Result, Info)
	if Result then
		Global.doRemoteCb('onChangeLike', Info.res)
	else
		print('del Like failed')
	end
end

define.GetObjectLikesInfo{Result = false, Info = {}}
when{}
function GetObjectLikesInfo(Result, Info)
	if Result then
		for i, v in ipairs(Info.list) do
			UpdateObjectLikes(v)
		end

		local obj = Info.list[1]
		if obj and obj.tag == 'house' then
			Global.doRemoteCb('onGetHouseLikes', Info)
		else
			Global.doRemoteCb('onGetObjectLikes', Info)
		end
	else
		print('get Like failed')
	end
end

define.AddObjectCollectInfo{Result = false, Info = {}}
when{}
function AddObjectCollectInfo(Result, Info)
	if Result then
		UpdateObjectCollects(Info.res)
		Global.doRemoteCb('onChangeCollect', Info.res)
	else
		print('add Collect failed')
	end
end

define.DelObjectCollectInfo{Result = false, Info = {}}
when{}
function DelObjectCollectInfo(Result, Info)
	if Result then
		DeleteObjectCollects(Info.res)
		Global.doRemoteCb('onChangeCollect', Info.res)
	else
		print('del Collect failed')
	end
end

define.GetObjectCollectsInfo{Result = false, Info = {}}
when{}
function GetObjectCollectsInfo(Result, Info)
	if Result and type(Info.list) == 'table' then
		for i, v in ipairs(Info.list) do
			UpdateObjectCollects(v)
		end

		Global.doRemoteCb('onGetObjectCollects', Info.list)
	else
		print('get Collects failed')
	end
end

define.UpdateRecommandObjects{Result = false, Info = {}}
when{}
function UpdateRecommandObjects(Result, Info)
	if Result then
		UpdateObjectRecommands(Info)

		local obj = Info[1]
		if obj and obj.tag == 'house' then
			Global.doRemoteCb('onChangeHouseRecommand', Info)
		else
			Global.doRemoteCb('onChangeObjectRecommand', Info)
		end
	else
		print('get Recommands failed')
	end
end