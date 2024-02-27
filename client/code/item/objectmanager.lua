
--[[
	name做索引，但是查找是用name和id都可以
]]

local om = {
	ava_id = 0,
	objs = {},
	nfts = {},
	localObjs = {},
	callbacks = {},
	callbacks_one = {},
}
Global.ObjectManager = om

Global.SaveManager:RegisterOnAid('localObjs', function(d)
	om.objs = {}
	om.nfts = {}
	om.localObjs = d
	-- 去掉索引为home（老版本）的数据
	om.localObjs.home = nil
	for _, o in next, om.localObjs do
		om:upload(o)
	end
	om:getNft()
	om:init_logic_object()
end)
-- NFT ------------------------------------------------------------------------
om.getNft = function(self, func)
	local wallet = Global.Login:getWallet()
	if not wallet then return end

	Global.NFT:getMyNFTs(function(datas)
		local ds = {}
		for i, nft in ipairs(datas) do
			table.insert(ds, nft.metadatauri)
			self.nfts[nft.metadatauri] = {
				tokenid = nft.tokenid,
				contract = nft.contract,
				owner = wallet,
				metadatauri = nft.metadatauri,
			}
		end
		self:RPC_GetObjectsFromNFT(ds, func)
	end)
end
-- 基础功能 ------------------------------------------------------------------------
-- 创建/修改时，先扔到local
om.newLocal_home = function(self, o)
--	print('om.newLocal_home')
	local h = self:getHome()
	if h then
		o.title = h.title
	end
	self:atom_newLocal(o)
end
om.atom_newLocal = function(self, o, silent)
	local id = o.name
--	print('om.atom_newLocal', debug.traceback())
	self.localObjs[id] = self.localObjs[id] or {}
	local ld = self.localObjs[id]
	table.copy(ld, o)

	ld.modifytime = Global.Login:getServerTime()
	ld.creater = {
		aid = Global.Login:getAid(),
		name = Global.Login:getName()
	}
	ld.owner = ld.creater
	ld.datafile = {
		name = o.datafile,
		md5 = o.datafile_md5
	}

	if o.tag == 'object' or o.tag == 'avatar' or Global.isSceneType(o.tag) then
		ld.picfile = {
			name = o.picfile,
			md5 = o.picfile_md5
		}

		-- auto save's pic
		if not o.picfile then
			ld.picfile.name = "icon_unupload.png"
		end
	end

	if silent then
	else
		self:upload(ld)
	end
	self:save()
end
om.checkNFT = function(self, o)
	if self.nfts[o.name] then
		o.isNFT = true
		o.NFTContract = self.nfts[o.name].contract
		return
	end

	-- tmp
	if self:tmp_check_nft(o.title) then
		o.isNFT = true
		o.tmp_pending = true
	end
end
om.isNFTWithContract = function(self, o, contract)
	if o.isNFT and o.NFTContract and contract and string.lower(o.NFTContract) == string.lower(contract) then
		return true
	end

	return false
end
om.atom_newObj = function(self, o)
	local name = o.name
	self:checkNFT(o)

	local isnew = false
	local ld = self.localObjs[name]
	if ld then
		if ld.modifytime < o.modifytime then
			self.localObjs[name] = nil
			self:save()

			isnew = true
		else
			self:upload(ld)

			isnew = false
		end
	else
		local oo = self.objs[name]
		isnew = not table.compareTable(oo, o)
	end

	if isnew then
		self.objs[name] = o
	end

	print('om.atom_newObj', name, isnew, o, o.data1, self.objs[name])

	return isnew
end
-- 从服务器收到new/update
om.newObj = function(self, o)
--	print('om.newObj', o.id, o.tag, o.owner.aid, Global.Login:isMe(o.owner.aid))
	if self:atom_newObj(o) then
		self:dispatch(o, 'new')
	end
	self:dispatch_obj(o)
end
-- delete object
om.delObj = function(self, o)
	-- print('om.delObj', o.name, debug.traceback())
	self.objs[o.name] = nil
	self:dispatch(o, 'del')
end
om.delLocal = function(self, o)
	self.localObjs[o.name] = nil
	self:dispatch(o, 'del')
end
om.DeleteObject = function(self, o)
	if self:check_isLocal(o) then
		self:delLocal(o)
	else
		RPC("DeleteObject", {ID = o.id})
	end
end
-- 上传本地缓存
om.upload = function(self, o)
	print('om.upload')
	local data = {}
	table.copy(data, o)
	data.datafile = o.datafile.name
	data.datafile_md5 = o.datafile.md5
	if o.tag == 'house' then
		Global.xl_house_upload(data)
	else
		if o.picfile.name == "icon_unupload.png" then return end
		data.picfile = o.picfile.name
		data.picfile_md5 = o.picfile.md5
		
		Global.xl_object_upload(data)
	end
end
om.save = function(self)
	Global.SaveManager:Save()
end
-- 使用的时候（列表展示/加载物件/加载家……）
local sorttable = function(t)
	table.sort(t, function(a, b)
		if a.isNFT ~= b.isNFT then
			if a.isNFT then
				return true
			else
				return false
			end
		end
		if a.id and b.id then
			return a.id < b.id
		elseif a.id then
			return false
		elseif b.id then
			return true
		else
			return a.modifytime < b.modifytime
		end
	end)
end
-- 外部接口 -------------------------------------------------------------
om.getObject_with_datafile = function(self, id)
	local o = self:getObject(id)
	if o then
		if Global.FileSystem:new_fileExist(o.datafile.md5) then
			return o
		end
	end
end
om.get_object_data1 = function(self, o)
	return Global.GameInfo:get_game(o)
end
om.getObject = function(self, idorname)
	for _, o in next, self.localObjs do
		if o.id == idorname or o.name == idorname then
			return o
		end
	end

	for _, o in next, self.objs do
		if o.id == idorname or o.name == idorname then
			return o
		end
	end
end
om.getMyAvatars = function(self, editable)
	local tb = {}
	for n, o in next, self.localObjs do
		if o.tag == 'avatar' then
			table.insert(tb, o)
		end
	end

	for n, o in next, self.objs do
		if o.tag == 'avatar' then
			if o.isNFT then
				if not editable then
					table.insert(tb, o)
				end
			elseif Global.Login:isMe(o.owner.aid) then
				table.insert(tb, o)
			end
		end
	end

	local function votehelper(vote)
		local delindex = 0
		local haspick = false
		for i, v in ipairs(tb) do
			if v.id == vote.oid and v.datafile.md5 == vote.file.md5 and not v.isNFT then
				if vote.isuse then
					-- 已经被mint的，需要删除存在server上的object
					delindex = i
				else
					v.canMint = true
					v.mintInfo = {}
					v.mintInfo.id = vote.id
					v.mintInfo.wallet = vote.wallet
					v.mintInfo.metadata = vote.metadata
				end
				haspick = true
			end
		end

		if not haspick and not vote.isuse then
			-- 创建不能穿/删的fake avatar 用来mint
			local fake = {}
			fake.isfake = true
			fake.canMint = true
			fake.mintInfo = {}
			fake.mintInfo.id = vote.id
			fake.mintInfo.wallet = vote.wallet
			fake.mintInfo.metadata = vote.metadata
			fake.datafile = vote.file
			fake.id = 0
			fake.name = _sys:getFileName(vote.file.name, false, false)

			-- print("create fake vote", table.ftoString(fake))
			table.insert(tb, fake)
		else
			if delindex ~= 0 then
				local obj = tb[delindex]
				RPC('DeleteObject', {ID = obj.id})
				table.remove(tb, delindex)
			end
		end
	end

	if self.VoteResult then
		for i, v in ipairs(self.VoteResult) do
			votehelper(v)
		end
	end

	sorttable(tb)

	return tb
end
om.getAstronautAvatarCount = function(self)
	local n = 0
	for i, o in ipairs(self:getMyAvatars(false)) do
		if self:isNFTWithContract(o, Global.Contracts.astronaut) then
			n = n + 1
		end
	end
	return n
end

om.hasAstronautAvatar = function(self)
	for i, o in ipairs(self:getMyAvatars(false)) do
		if self:isNFTWithContract(o, Global.Contracts.astronaut) then
			return true
		end
	end
	return false
end

om.isSpecialAvatar = function(self, o)
	return string.find(o.name, 'object_firstavatar_')
end

om.hasSpecialAvatar = function(self)
	for i, o in ipairs(self:getMyAvatars(false)) do
		if self:isSpecialAvatar(o) then
			return true
		end
	end
	return false
end

om.getMyDisplayAvatars = function(self)
	local tb = self:getMyAvatars(true)
	for i = #tb, 1, -1 do
		local o = tb[i]
		if self:isSpecialAvatar(o) or o.type == 'system' then
			table.remove(tb, i)
		end
	end

	return tb
end

-- 展示柜中的avatar数量
om.getDisplayAvatarsCount = function(self)
	local n = 1
	for _, o in ipairs(self:getMyAvatars()) do
		if self:check_isNFT(o) or
			(self:check_isPublished(o) and not self:isSpecialAvatar(o) and not om:check_isLocal(o)) then
			n = n + 1
		end
	end

	return n
end

om.getMyUnPublishedAvatars = function(self)
	local tb = {}
	for i, o in ipairs(self:getMyAvatars(true)) do
		--print('check_isPublished', i, o, o.state)
		if not self:check_isPublished(o) and not self:isSpecialAvatar(o) then
			table.insert(tb, o)
		end
	end

	return tb
end

om.updateVoteResult = function(self, result)
	self.VoteResult = result

	self:dispatch()
end
om.getPurchasedAvatars = function(self)
	local tb = {}

	for n, o in next, self.objs do
		if o.tag == 'avatar' and Global.Login:isMe(o.owner.aid) and Global.Login:isMe(o.creater.aid) == false then
			table.insert(tb, o)
		end
	end

	return tb
end
om.getPurchasedObjects = function(self)
	local tb = {}

	for n, o in next, self.objs do
		if o.tag == 'object' and Global.Login:isMe(o.owner.aid) and Global.Login:isMe(o.creater.aid) == false then
			table.insert(tb, o)
		end
	end

	return tb
end
om.isPurchasedObject = function(self, obj)
	for n, o in next, self.objs do
		if o.tag == 'object' and Global.Login:isMe(o.owner.aid) and Global.Login:isMe(o.creater.aid) == false and obj.id == o.hid then
			return true
		end
	end
	return false
end
om.getObjectByName = function(self, n)
	return self.localObjs[n] or self.objs[n]
end

om.getMyObjects = function(self)
	local tb = {}
	for n, o in next, self.localObjs do
		if o.tag == 'object' then
			table.insert(tb, o)
		end
	end

	for n, o in next, self.objs do
		if o.tag == 'object' and Global.Login:isMe(o.owner.aid) and Global.Login:isMe(o.creater.aid) then
			local found = false
			for _, oo in ipairs(tb) do
				if oo.id == o.id then
					found = true
					break
				end
			end
			if found == false then
				table.insert(tb, o)
			end
		end
	end

	sorttable(tb)

	return tb
end

om.getMyScenes = function(self)
	local tb = {}
	for n, o in next, self.localObjs do
		if Global.isSceneType(o.tag) then
			table.insert(tb, o)
		end
	end

	for n, o in next, self.objs do
		if Global.isSceneType(o.tag) and Global.Login:isMe(o.owner.aid) and Global.Login:isMe(o.creater.aid) then
			local found = false
			for _, oo in ipairs(tb) do
				if oo.id == o.id then
					found = true
					break
				end
			end
			if found == false then
				table.insert(tb, o)
			end
		end
	end

	sorttable(tb)

	return tb
end

local defaulthome = {name = 'housedefault'}
om.getHome = function(self)
--	print('om.getHome', self.localObjs.home, self.objs.home)
	for n, o in next, self.localObjs do
		if o.tag == 'house' then
			return o
		end
	end

	for n, o in next, self.objs do
		if o.tag == 'house' and Global.Login:isMe(o.owner.aid) then
			return o
		end
	end
	return defaulthome
end
om.getHouseByName = function(self, n)
--	print('om.getHouseByName', n)
	return self.localObjs[n] or self.objs[n]
end
-- debug -------------------------------------------------------------
om.debug_clearLocal = function(self)
	table.clear(self.localObjs)
	self:save()
end
om.debug_dump = function(self)
	local printobj = function(obj)
		print(obj.name, obj.id)
		if obj.datafile then
			print('\tdatafile', obj.datafile.name, obj.datafile.md5)
		end
		if obj.picfile then
			print('\tpicfile', obj.picfile.name, obj.picfile.md5)
		end
	end
	print('==== local ====')
	for _, o in next, self.localObjs do
		printobj(o)
		dump(o)
	end
	print('==== obj ====')
	for _, o in next, self.objs do
		printobj(o)
	end
end
-- 外部接口2 ----------------------------------------------------------------
om.check_exist = function(self, o)
	return self:getObject(o.name) ~= nil
end
om.check_isLocal = function(self, o)
	return self.localObjs[o.name] ~= nil
end
om.check_isNew = function(self, o)
	return _and(o.state, 16) > 0
end
om.check_isDraft = function(self, o)
	return _and(o.state, 4) > 0
end
om.check_isCopied = function(self, o)
	return _and(o.state, 2) > 0
end
om.check_isPublished = function(self, o)
	return _and(o.state, 1) > 0
end
om.check_isNFT = function(self, o)
	return o.isNFT
end
om.check_isTemplate = function(self, o)
	return o.mode == 'template'
end
-- 监听功能 ----------------------------------------------------------------
om.listen = function(self, k, v)
	self.callbacks[k] = v
end
om.dispatch = function(self, o, op)
	for k, v in next, self.callbacks do
		v(o, op)
	end
end
-- mode 0 data 1 pic 2 data&pic
om.listen_obj_id = function(self, id, mode, callback)
	local isnew = false
	if self:getObject(id) == nil then
		isnew = true
	end
	RPC('GetObject', {ID = id})
	local func = function(d)
		if mode == 0 then
			Global.FileSystem:downloadData(d.datafile, nil, function(success, changed)
				callback(d, isnew or changed)
			end)
		elseif mode == 1 then
			Global.FileSystem:downloadData(d.picfile, nil, function(success, changed)
				callback(d, isnew or changed)
			end)
		elseif mode == 2 then
			Global.FileSystem:downloadDatas({d.datafile, d.picfile}, nil, function(success, changed)
				callback(d, isnew or changed)
			end)
		end
	end

	self.callbacks_one[id] = self.callbacks_one[id] or {}
	table.insert(self.callbacks_one[id], func)
end
om.dispatch_obj = function(self, o)
	local id = o.id
	if not self.callbacks_one[id] then return end

	for _, f in ipairs(self.callbacks_one[id]) do
		f(o)
	end

	self.callbacks_one[id] = nil
end
-- 监听2 -------------------------------------------------------
om.objs_listen = {}
local function objs_callback(objs, mode, onp, onf)
	if mode == nil then
		onf()
		return
	end

	local fs = {}
	for i, o in ipairs(objs) do
		if mode == nil then
		elseif mode == 0 then
			table.insert(fs, o.datafile)
		elseif mode == 1 then
			table.insert(fs, o.picfile)
		elseif mode == 2 then
			table.insert(fs, o.datafile)
			table.insert(fs, o.picfile)
		end
	end

	Global.FileSystem:downloadDatas(fs, onp, onf)
end

om.listen_objs = function(self, objs, mode, onp, onf)
	objs_callback(objs, mode, onp, onf)
end

om.listen_objs_by_name = function(self, ns, mode, onp, onf)
	if not next(ns) then
		onf()
		return
	end

	self:RPC_GetObjectsByNames(ns, function(objs)
		objs_callback(objs, mode, onp, onf)
	end)
end

-- avatar相关 -----------------------------------------------------------------
om.isMyAvatar = function(self, id)
	local as = self:getMyAvatars()
	for i, v in ipairs(as) do
		if v.id == id then
			return true
		end
	end

	return false
end
om.setAvatarId = function(self, id)
	if not self:isMyAvatar(id) then
		if id ~= 0 then
			local data = {
				id = 0,
				name = 'defaultavatar',
			}
			RPC('UpdateAvatarid', {Data = data})
		end

		id = 0
	end
	self.ava_id = id

	if Global.role then
		Global.role:setAvatarid(id)
	end
end
om.getAvatarId = function(self)
	return self.ava_id
end

om.get_nft_ava_name = function(self)
	for _, o in next, self.objs do
		if o.id == self.ava_id then
			if o.isNFT then
				return o.title
			end
		end
	end
end

---- temp

--------- nft
local ipfs_name = {
	dancer = "ipfs://",
	inventor = "ipfs://",
}

om.tmp_nft = {}
Global.SaveManager:RegisterOnAid('tmp_nft', function(d)
	om.tmp_nft = d
	-- tmp

	om:tmp_get_mint_nft()
end)
om.tmp_check_nft = function(self, n)
	return self.tmp_nft[n]
	-- ok
	-- pending
	-- nfted
end
om.tmp_get_mint_nft = function(self)
	local ns = {}
	for n in next, self.tmp_nft do
		table.insert(ns, ipfs_name[n])
	end
	RPC("GetObjectByNames", {Names = ns})
end
om.tmp_mint = function(self, n)
	if om.tmp_nft[n] then return end

	om.tmp_nft[n] = true
	self:save()
	RPC("GetObjectByNames", {Names = {ipfs_name[n]}})
end
--------- open share objects(debug)

local tmp_openshare_objects = {}
local tmp_openshare_func
om.tmp_get_open_share_objects = function(self, func)
	tmp_openshare_objects = {}
	tmp_openshare_func = func

	RPC("GetOpenshareObjects", {})
end

-- event ----------------------------------------------------------------
local event_key = 0
local event_cbs = {}
om.RPC_GetObjects = function(self, cb)
	event_key = event_key + 1
	RPC("GetObjects", {Key = event_key})
	if cb then
		event_cbs[event_key] = cb
	end
end
om.RPC_GetObjectsByAid = function(self, aid, cb)
	event_key = event_key + 1
	RPC("GetObjects2", {Aid = aid, Key = event_key})
	if cb then
		event_cbs[event_key] = cb
	end
end
om.RPC_GetObjectsByNames = function(self, ns, cb)
	event_key = event_key + 1
	RPC("GetObjectByNames", {Names = ns, Key = event_key})
	if cb then
		event_cbs[event_key] = cb
	end
end
om.RPC_GetObjectsFromNFT = function(self, ns, cb)
	event_key = event_key + 1
	RPC("GetObjectByNames", {Names = ns, Key = event_key})
	if cb then
		event_cbs[event_key] = cb
	end
end
define.GetObjects{Result = false, Info = {}, Key = 0}
when{}
function GetObjects(Result, Info, Key)
	if Result then
		for i, v in ipairs(Info) do
			om:newObj(v)
		end

		local obj = Info[1]
		if obj then
			if obj.tag == 'house' then
				Global.doRemoteCb('onChangeHouse', obj)
			else
				Global.doRemoteCb('onChangeObject', obj)
			end
		end

		local cb = event_cbs[Key]
		if cb then
			event_cbs[Key] = nil
			cb(Info)
		end
	else
		print('GetObjects Failed :' .. table.ftoString(Info))
	end
end

define.GetObjectsByOpenshare{Result = false, Info = {}, Finish = true}
when{}
function GetObjectsByOpenshare(Result, Info, Finish)
	if Result then
		print("GetObjectsByOpenshare", Result, Info, Finish)
		for i, v in ipairs(Info) do
			table.insert(tmp_openshare_objects, v)
		end

		if Finish and tmp_openshare_func then
			tmp_openshare_func(tmp_openshare_objects)
		end
	end
end
------------------------------------------
om.init_logic_object = function(self)
	local obj_random_never = {
		id = 'never_random',
		name = 'never_random',
		title = 'Random',
		tag = 'scene_random',
		state = 1,
		datafile = {
			name = 'itemlv_498.itemlv',
		},
		owner = {name = ''},
		mode = 'template',
	}
	om:newObj(obj_random_never)

	local obj_random_music = {
		id = 'music_random',
		name = 'music_random',
		title = 'Random',
		tag = 'scene_random',
		state = 1,
		datafile = {
			name = 'itemlv_498.itemlv',
		},
		owner = {name = ''},
		mode = 'template',
	}
	om:newObj(obj_random_music)
end
om.is_never_scene = function(self, o)
	if o.id == 'never_random' then
		return true
	end

	local g = Global.GameInfo:get_game(o)
	if g == 'neverup' or g == 'neverdown' then
		return true
	end
end