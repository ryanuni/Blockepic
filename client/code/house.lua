local Container = _require('Container')
local Function = _require('Function')

local House = {}
Global.House = House
House.miniab = _AxisAlignedBox.new()
House.realab = _AxisAlignedBox.new()

House.ClickSound = {
	{ui = 'back', volume = 0},
}

Global.ExtendHousePrice = {}
Global.ExtendHouseCallBack = nil

House.loadHouseToSen = function(self, sen, house, finishfunc)
	self.ismine = house == nil
	if not house then house = Global.ObjectManager:getHome() end
	--[[
	--TODO:
	if self.ismine and self.sen and self.cachemd5 == (house and house.datafile_md5) then
		if finishfunc then
			finishfunc()
		end
		return
	end
	--]]

	--self.sen = sen
	-- self.cachemd5 = house and house.datafile_md5

	if not house then
		self:loadHouse('housedefault')
		self:setupEnv(house)
		if finishfunc then
			finishfunc()
		end
	else
		-- print(table.ftoString(house.datafile))
		local ffunc = function()
			self:loadHouse(house.name, house.title)
			self:setupEnv(house)
			if finishfunc then
				finishfunc()
			end
		end
		if isConnected() then
			Global.downloadWhole(house, ffunc)
		else
			ffunc()
		end
		self:changeBoardImage(house)
	end
end

House.changeBoardImage = function(self, house)
	local board = Global.sen:getBlockByShape('board')
	if board then
		board:changePaintImage(self:genBoardImage(house))
	end
end

House.genBoardImage = function(self, house)
	self.boarddb = self.boarddb or _DrawBoard.new(384, 256)
	self.boardfont = self.boardfont or _Font.new('Comic Sans MS', 50)
	self.boardfont.textColor = _Color.White
	self.defaultstar = self.defaultstar or _Image.new('boardstar.png')
	self.starimage = self.starimage or _Image.new('star.png')
	self.starimage.w = 64
	self.starimage.h = 64
	_rd:useDrawBoard(self.boarddb, _Color.Null)
	local tag = (house.housetag and house.housetag ~= '') and Global.totag(house.housetag) or ''
	local star = (house.housetag and house.housetag ~= '') and Global.tolevel(house.housetag) or 0
	local desc = (house.title and house.title .. '\n' or '') .. tag
	local images = {}
	local imageflags = {'\1', '\2', '\3', '\4', '\5', '\6', '\7', '\8'}
	for i = 1, star do
		if i == 1 then
			desc = desc .. '\n'
		end
		desc = desc .. imageflags[i]
		table.insert(images, self.starimage)
	end
	self.boardfont:drawText(0, 0, 384, 256, desc, _Font.hCenter + _Font.vCenter, unpack(images))
	_rd:resetDrawBoard()
	return desc ~= '' and _Image.new(self.boarddb) or self.defaultstar
end

House.initHouse = function(self, house, finishfunc)
	self:loadHouseToSen(Global.sen, house, function()
		if finishfunc then
			finishfunc()
		end
		if house and house.owner and not self.ismine then
			Global.gmm.onEvent('dooropen')
			Global.gmm.onEvent('showisland')
		end

		local fence = Global.sen:getBlockByShape('blocki_fence')
		if fence then
			fence.node.visible = false
			fence:enablePhysic(false)
		end
	end)

	for _, data in ipairs(self.ClickSound) do
		local ui = Global.ui[data.ui]
		if ui then
			ui._sound = Global.SoundList[data.sound]
			ui._soundVolumeScale = data.volume or Global.SoundConfigsList[data.sound].volume
		end
	end
end

House.getName = function(self)
	local name = 'housedefault'
	local h = Global.getMyHouse()
	if h then
		name = h.name
	end

	return name
end
House.loadBlockFunction = function(self, b, funcname)
	local data = _dofile(funcname)
	for i, v in ipairs(data or {}) do
		b:addFunction(Function.new(v))
	end
	b:loadActionFunctions(Global.sen)
	b:registerEvents()
	b:initEvents()
end

House.loadHouseData = function(self, sen, data)
	local obs = {}
	sen:getBlocksByFilter(obs, function(b)
		return b.ishouseblock
	end)

	for i = #obs, 1, -1 do
		sen:delBlock(obs[i])
	end

	local houseblock = Global.sen:getBlockByShape('House_skin')
	if houseblock then
		houseblock:getShapeAABB(self.miniab)
	end

	local bs = Global.loadBlocksFromHouse(data, self.sen)
	local housesize = 1

	for i, b in ipairs(bs) do
		b.insideFlag = true
		b:setVisible(false, false)
		local shape = b:getShape()
		if Global.HouseBases[shape] then
			b:getShapeAABB(self.realab)
			housesize = Global.HouseBases[shape]
		end
		if self.ismine then
			if Global.HouseNPC[shape] then
				local npcdata = Global.HouseNPC[shape]
				self:loadBlockFunction(b, npcdata.func)
			elseif Global.HouseBases[shape] then
				local c = Global.CameraControl:get()
				-- c:setBlockArea(self.miniab.min.x, self.miniab.max.x, 2.5, 5.5)
				c.minRadius = 2
				c.maxRadius = 6
			end
		end
		if b:getShape() == 'gramophone' then
			local vec = Container:get(_Vector3)
			b:getTransform():getTranslation(vec)
			Global.AudioPlayer:setLocation(vec)
			Container:returnBack(vec)
		end
		b.ishouseblock = true
	end
	self.currentSize = housesize

	local walls = {'mini_wall', 'small_wall', 'middle_wall', 'big_wall'}
	for k, v in next, sen.blocks do
		for _, name in next, walls do
			if v:getShape() == name then
				if name == walls[housesize] then
					v:setVisible(true)
				else
					v:setVisible(false)
				end
			end
		end
	end
end
House.loadHouse = function(self, name, title)
	local sen = self.sen or Global.sen

	local data = Block.loadItemData(name)
	if not data then
		data = Block.loadItemData('housedefault')
		print('!!!loadHouse error:', name)
	end

	sen.title = title
	self:loadHouseData(sen, data)
end

House.setupEnv = function(self, house)
	Global.AudioPlayer:stop()
	if house and house.musicfile then
		local audio = Global.AudioPlayer:createAudio(house.musicfile.name, house.musicfile)
		if audio then
			Global.AudioPlayer:setCurrent(audio)
			if house.playingmusic then
				Global.AudioPlayer:playCurrent()
			end
		end
	end

	-- camera mov
	if Global.EntryEditAnima.view_mode then
		local c = Global.CameraControl:get()
		c.maxRadius = 10
		c:update()
		-- c:use()
		-- print(c.camera.look, c.camera.eye)
		Global.CameraControl:push()
		c = Global.CameraControl:get()
		-- print(Global.EntryEditAnima.camera)
		c:setCamera(Global.EntryEditAnima.camera)
		c:update()
		-- c:use()
		-- print(c.camera.look, c.camera.eye)
		Global.CameraControl:pop(500)
	end
end

local function genConfirmString(cindex, tindex)
	if not cindex or not tindex then
		return
	end

	if cindex >= tindex then
		return
	end

	local price = 0
	for i = cindex, tindex - 1 do
		local next = i + 1
		price = price + Global.ExtendHousePrice[i .. 't' .. next]
	end

	local str = string.gsub(Global.TEXT.CONFIRM_EXPAND_HOUSE, '{price}', price)
	return str
end

local function changeHouse(house, expand, setstype)
	local name = house and house.name or 'housedefault'
	local data = Block.loadItemData(name)

	local names = {}
	for i, v in pairs(Global.HouseStyles) do
		names[i] = v.defualt
	end

	if data then
		local vdata, size, floorstype, wallstype

		local iindexs = {}
		for i, v in ipairs(data.blocks) do
			if Global.HouseWalls[v.shape] then
				local wall = Global.HouseWalls[v.shape]
				size, wallstype, vdata = wall.size, wall.type, v
				table.insert(iindexs, 1, i)
			elseif Global.HouseFloors[v.shape] then
				local floor = Global.HouseFloors[v.shape]
				size, floorstype, vdata = floor.size, floor.type, v
				table.insert(iindexs, 1, i)
			elseif Global.HouseBases[v.shape] then
				size, vdata = Global.HouseBases[v.shape], v
				table.insert(iindexs, 1, i)
			end
		end

		if expand then
			if size == #names then
				Notice(Global.TEXT.NOTICE_HOUSE_LARGEST)
				return
			end

			local str = genConfirmString(size, size + 1)
			if str then
				Global.CoinUI:showPermanent()
				Confirm(str, function()
					local function callback(res, info)
						if info.success then
							Global.Sound:play('build_expand01')

							local shapes = Global.getHouseNamesByStyles(size + 1, wallstype, floorstype)
							-- 删除之前的物件
							local cursen = false
							for i, ii in ipairs(iindexs) do
								local v = data.blocks[ii]
								table.remove(data.blocks, ii)
							end

							-- 增加新物件
							for i, shape in ipairs(shapes) do
								local v = {}
								table.copy(vdata, v)
								v.shape = shape
								v.space = vdata.space

								table.insert(data.blocks, 1, v)
							end

							Global.uploadHouse(data, name, 'Expand')

							-- 重新加载房子
							House:loadHouseData(Global.sen, data)
						else
							Notice(Global.TEXT.NOTICE_ITEM_BUY_NOT_ENOUGH)
						end

						Global.CoinUI:showDynamic()
					end

					Global.ExtendHouseCallBack = callback
					RPC("BuyExtendHouse", {CurSize = names[size], ToSize = names[size + 1]})
				end, function()
					Global.CoinUI:showDynamic()
				end)
			else
				Notice(Global.TEXT.NOTICE_EXPAND_ERROR)
			end
		elseif setstype then
			local shapes = Global.getHouseNamesByStyles(1, setstype, setstype)
			-- 删除之前的物件
			local cursen = false
			for i, ii in ipairs(iindexs) do
				table.remove(data.blocks, ii)

				-- local b = Global.sen:getBlockByShape(v.shape)
				-- if b then
				-- 	cursen = true
				-- 	Global.sen:delBlock(b)
				-- end
			end

			-- 增加新物件
			for i, shape in ipairs(shapes) do

				local v = {}
				table.copy(vdata, v)
				v.shape = shape
				v.space = vdata.space

				table.insert(data.blocks, 1, v)

				--if cursen then Global.sen:createBlock(v) end
			end

			Global.uploadHouse(data, name, 'Expand')
		end
	end
end

House.expandHouse = function(self)
	local house = Global.getMyHouse()
	if not house then
		changeHouse(nil, true)
	else
		Global.FileSystem:downloadData(house.datafile, nil, function()
			changeHouse(house, true)
			--changeHouse(house, false, 'white1')
		end)
	end
end

House.isInMyHouse = function(self)
	return Global.sen and _sys:getFileName(Global.sen.name, false, false) == 'house1' and self.ismine
end

House.isInOtherHouse = function(self)
	return Global.sen and _sys:getFileName(Global.sen.name, false, false) == 'house1' and self.ismine == false
end

-------------------------------------------------------------
define.HouseExtendPriceInfo{Result = false, Info = {}}
when{}
function HouseExtendPriceInfo(Result, Info)
	if Result then
		Global.ExtendHousePrice = Info
	end
end

define.BuyHouseExtend{Result = false, Info = {}}
when{}
function BuyHouseExtend(Result, Info)
	if Global.ExtendHouseCallBack then
		Global.ExtendHouseCallBack(Result, Info)
		Global.ExtendHouseCallBack = nil
	end
end
