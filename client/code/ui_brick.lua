local brickui = {}
Global.brickui = brickui
brickui.typestr = 'brickui'
brickui.showID = false

_dofile('cfg_items.lua')
-- 处理配置信息
local cfgitems = _G.cfg_items[1]
local cfgbricks = {}
for i, v in pairs(cfgitems) do
	if v.type == 'brick' then
		if not cfgbricks[v.quality] then
			cfgbricks[v.quality] = {}
		end
		table.insert(cfgbricks[v.quality], v)
	end
end

for i, bs in ipairs(cfgbricks) do
	table.sort(bs, function(a, b)
		return a.id < b.id
	end)
end

-- print(table.ftostring(cfgbricks))

_sys.asyncLoad = true
for _, v in ipairs(cfgbricks[1]) do
	local name = tostring(v.shape) .. '-display.bmp'
	_Image.new(name)
end

_gc()
_sys.asyncLoad = false

brickui.show = function(self, mode, hidefunc, params)
	Global.UI:slidein({Global.ui.bricklibrary, Global.ui.bricklib_back})

	Global.AddHotKeyFunc(_System.KeyESC, function()
		return self.ui.visible
	end, function()
		Global.ui.bricklib_back.click()
	end)

	if self.mode == mode and (not params or not params.forceupdate) then
		self:setVisible(true)
		self:refreshTypeList()

		-- if (self.ui.mainlist.visible and self.ui.mainlist.itemNum == 0) or (self.ui.mainlistsmall.visible and self.ui.mainlistsmall.itemNum == 0) then
		-- 	hidefunc()
		-- 	Notice(Global.TEXT.NOTICE_OBJECT_NONE_TO_ADD)
		-- end

		return
	end

	-- mode : buildbrick, buildhouse, repair, buildavatar
	self.mode = mode
	self.obj_clickfunc = params and params.obj_clickfunc
	self.showsmalllist = params and params.showsmalllist

	print('self.ui.show', self.showsmalllist)
	Global.ui.visible = true
	self.ui = Global.ui.bricklibrary
	self.bgui = Global.ui.bricklibrarybg

	-- list两头渐隐，数据格式：0xBRTL
	self.ui.labellist.alphaRegion = 0x00140014
	self.ui.mainlistsmall.alphaRegion = 0x14000500
	self.ui.mainlistsmall2.alphaRegion = 0x14000500
	self.ui.mainlist.alphaRegion = 0x14000500

	local clickpx, clickpy = 0, 0
	self.bgui.onMouseUp = function(args)
		clickpx, clickpy = args.mouse.x, args.mouse.y
	end

	self.bgui.click = function()
		-- local edge = 60
		-- if clickpx < self.ui._x - edge or clickpx > self.ui._x + self.ui._width + edge then
		-- 	hidefunc()
		-- 	_sys:vibrate(30)
		-- end
	end

	self.seltype = 1
	self.shapefilters = params and params.shapefilters
	self.disablefilters = params and params.disablefilters

	if self.mode == 'buildbrick' or self.mode == 'buildavatar' or self.mode == 'buildhouse' then
		self.showfilter = true
	elseif self.mode == 'repair' then
		self.showfilter = false
	else
		self.showfilter = false
	end

	self.kindfilter = 'all'
	self.noshowavatar = params and params.noshowavatar
	self.avatarkindfilter = 'all'
	self.hidelabelList = params and params.hidelabelList or self.mode == 'buildhouse'

	self.hidefunc = hidefunc

	--print('objectkindfilter', self.objectkindfilter)

	local objectkinds = {}
	if params and params.objectkinds then
		for k in pairs(params.objectkinds) do
			local v = Global.BuildBrickKinds[k]
			if v then
				if _sys:getGlobal('PCRelease') and v.releasehide then
				else
					objectkinds[k] = true
				end
			end
		end
	else
		for k, v in pairs(Global.BuildBrickKinds) do
			if not v.normalhide then
				if _sys:getGlobal('PCRelease') and v.releasehide then
				else
					objectkinds[k] = true
				end
			end
		end
	end

	self.objectkindfilter = 'all'
	self.objectkinds = objectkinds

	self:setVisible(true)
	if self.mode == 'buildhouse' or self.mode == 'showmywork' then
		--直接显示物件库
		self.ui.typelist.visible = false
		self.ui.typebg.visible = false
		self.seltype = 2
		self:refreshLabelList()
		Global.ObjectManager:listen('buildhouse', function()
			self:refreshLabelList()
		end)
	else
		if self.mode == 'showavatar' then
			self.seltype = 3
		elseif self.mode == 'buildscene' then
			self.seltype = 2
		end

		self.ui.typelist.visible = true
		self.ui.typebg.visible = true
		self:refreshTypeList()
	end

	_sys:vibrate(30)

	if self.mode == 'repair' and (self.ui.mainlist.visible and self.ui.mainlist.itemNum == 0) or (self.ui.mainlistsmall.visible and self.ui.mainlistsmall.itemNum == 0) then
		hidefunc()
		Notice(Global.TEXT.NOTICE_OBJECT_NONE_TO_ADD)
	end

	Global.ui.bricklib_back.click = function()
		hidefunc()
		_sys:vibrate(30)
	end
end

brickui.setVisible = function(self, v)
	if self.ui then
		self.ui.visible = v
		self.bgui.visible = v
		Global.ui.bricklib_back.visible = v
	end
end
brickui.hide = function(self)
	Global.UI:slideout({Global.ui.bricklibrary, Global.ui.bricklib_back})
	Global.Timer:add('hideui', 150, function()
		Global.ObjectManager:listen('buildhouse')
		self:setVisible(false)
	end)
end

brickui.refreshTypeList = function(self)
	local list = self.ui.typelist
	local datas = Global.BuildBrickTypes

	if self.mode == 'repair' then
		datas = {datas.brick}
	elseif self.mode == 'buildavatar' or self.mode == 'buildbrick' or self.mode == 'buildhouse' then
		if _sys:getGlobal('PCRelease') then
			datas = {datas.brick, datas.object}
		else
			datas = {datas.brick, datas.object, datas.functions}
		end
	elseif self.mode == 'showavatar' then
		datas = {datas.avatar}
	elseif self.mode == 'buildscene' then
		if self.noshowavatar then
			datas = {datas.object}
		else
			if _sys:getGlobal('PCRelease') then
				datas = {datas.object, datas.avatar, datas.scene}
			else
				datas = {datas.object, datas.avatar, datas.scene, datas.functions}
			end
		end
	else
		datas = {datas.object}
	end

	local selitem = nil
	list.onRenderItem = function(index, item)
		item.disabled = false
		local data = datas[index]
		item.c1._icon = data.bgicon
		item.c2._icon = data.bgicon_sel
		-- item.selected = index == self.seltype
		item.index = data.sortindex
		item._sound = Global.SoundList['ui_click18']
		item.click = function()
			print('Select type:', data.sortindex)
			self.seltype = data.sortindex
			self:refreshLabelList()
			for i, v in ipairs(list:getChildren()) do
				v.sortingOrder = v == item and 100 or (10 - v.index)
			end
		end

		if self.seltype == data.sortindex then
			selitem = item
		end
	end

	list.itemNum = #datas

	if selitem then
		selitem.selected = true
		for i, v in ipairs(list:getChildren()) do
			v.sortingOrder = v == selitem and 100 or (10 - v.index)
		end
		self:refreshLabelList()
	end

	local uibasic = self.ui.onlybasic
	uibasic.click = function()
		self:refreshLabelList()
	end
end

function brickui.showlabelList(self, show)
	self.ui.labellist.visible = show
	self.ui.labelbg.visible = show
	self.ui.labeldesc.visible = false
end

brickui.refreshLabelList = function(self)
	self.ui.onlybasic.visible = false
	self.ui.litemode.visible = false

	print('refreshLabelList', self.seltype)
	if self.seltype == 1 then
		self.ui.onlybasic.visible = self.showfilter
		self.ui.litemode.visible = self.showfilter
		self:showlabelList(self.showfilter)

		local selitem = nil
		if self.showfilter then
			local list = self.ui.labellist
			local kinds = {}
			for k, v in pairs(Global.BrickType) do
				if Global.CheckLimit(v) then
					local datas = self:getFilterBricks(k)
					if datas[1] and #datas[1].bricks > 0 then
						table.insert(kinds, k)
					end
				end
			end
			table.sort(kinds, function(a, b)
				return Global.BrickType[a].sortindex < Global.BrickType[b].sortindex
			end)

			list.onRenderItem = function(index, item)
				local kind = kinds[index]
				local data = Global.BrickType[kind]
				item.c1._icon = data.icon
				item.c2._icon = data.icon_sel
				item._sound = Global.SoundList['ui_click17']
				item.click = function()
					self.kindfilter = kind
					self:refreshMainList()
				end

				if self.kindfilter == kind then
					selitem = item
				end
			end

			list.itemNum = #kinds

			if selitem then
				selitem.selected = true
				self:refreshMainList()
			end
		else
			self:refreshMainList()
		end
	elseif self.seltype == 2 then
		local showlabellist = not self.hidelabelList
		self:showlabelList(showlabellist)

		local selitem = nil
		local list = self.ui.labellist
		local kinds = {}
		for k in pairs(self.objectkinds) do
			local d = self:getfilterobject(k)
			local hasbrick = false
			for p, q in ipairs(d) do
				if #q.bricks > 0 then
					hasbrick = true
				end
			end
			if hasbrick then
				table.insert(kinds, k)
			end
		end
		table.sort(kinds, function(a, b)
			return Global.BuildBrickKinds[a].sortindex < Global.BuildBrickKinds[b].sortindex
		end)
		local find = false
		for i, k in ipairs(kinds) do
			if k == self.objectkindfilter then
				find = true
			end
		end
		if not find then self.objectkindfilter = kinds[1] or 'all' end

		list.onRenderItem = function(index, item)
			local kind = kinds[index]
			local data = Global.BuildBrickKinds[kind]
			item.c1._icon = data.icon
			item.c2._icon = data.icon_sel
			item._sound = Global.SoundList['ui_click17']
			item.click = function()
				self.objectkindfilter = kind
				self:refreshMainList()
			end

			if self.objectkindfilter == kind then
				selitem = item
			end
		end

		list.itemNum = #kinds

		if selitem then
			selitem.selected = true
		end
		self:refreshMainList()
	elseif self.seltype == 3 then
		self:showlabelList(false)
		self:refreshMainList()
	elseif self.seltype == 4 then
		self:showlabelList(false)
		self:refreshMainList()
	elseif self.seltype == 5 then
		self:showlabelList(false)
		self:refreshMainList()
	end
end
-------------------------------------------------------------------------------------
local itemw = 260
local itemh = 313
local hgap = 10
local wgap = 60

local sitemw = 183
local sitemh = 216
local shgap = 10
local swgap = 7

local sitemw2 = 150
local sitemh2 = 180
local shgap2 = 10
local swgap2 = 10

local bgs = {'1-1.png', '2-1.png', '3-1.png'}
local function clear_item(item1)
	item1.p.pfxPlayer:stopAll(true)
	item1.s._icon = ''
	item1.t._icon = ''
	item1.new.visible = false
	item1.res.visible = false
	item1.tagbg.visible = false
	item1.tagtitle.visible = false
	item1.tagtitle.text = ''
	item1.progress.visible = false
	item1.graymask.visible = false
	item1.c._icon = ''
	item1.desc.text = ''
	item1.click = function() end
	item1.bg._icon = 'img://alphabg.png'
end
-- build双击出来的
brickui.refreshMain_type1_list = function(self, datas, bricks)
	local list = self.ui.mainlistsmall
	list.visible = true
	local linenum = 0
	_sys.asyncLoad = true
	list.onRenderItem = function(index, item)
		local data = datas[index]
		item.loader.icon = ''
		item.title.text = '.' .. string.upper(data.desc) .. '(' .. #data.bricks .. ')'
		local num = math.floor((list._width + swgap) / (sitemw + swgap))
		-- print('@@@@@@@@@@', num, list._width, swgap, sitemw)
		item.itemlist.onRenderItem = function(index1, item1)
			clear_item(item1)

			if index1 > #data.bricks then
				return
			end

			local data1 = data.bricks[index1]
			local brick = data1.index and bricks[data1.index] or data1.brick

			if brick.icon and brick.icon ~= '' then
				item1.c._icon = brick.icon
			else
				local pic = tostring(brick.shape) .. '-display.bmp'
				item1.c._icon = pic
			end

			-- local hd = Block.getHelperData(brick.shape)
			--if hd and hd.rotpivot or brick.dummy then
			if brick.t_icon then
				item1.t._icon = Global.ObjectIcons[brick.t_icon]
			end

			if data1.index then
				local bd = Block.getBlockData(brick.shape)
				item1.desc.text = bd.desc
			else
				item1.desc.text = brick.desc
			end

			if self.showID and data1.index then
				local bd = Block.getBlockData(brick.shape)
				item1.res.visible = true
				item1.res.text = bd.res
			end

			if brick.tags and #brick.tags > 0 and ((_and(brick.state, 1) > 0 and brick.reviewprogress >= 100) or _and(brick.state, 2) > 0 or brick.picfile == nil) then
				item1.tagbg.visible = true
				item1.tagtitle.visible = true
				item1.tagtitle.text = Global.totag(brick.tags[1])
			end

			item1._sound = ''
			item1._soundVolumeScale = 0
			item1.disabled = self.disablefilters and self.disablefilters[brick.shape]
			item1.click = function()
				Global.Sound:play('build_putdown')
				print('Choose brick:', brick.shape, 1, data1.count)

				if self.mode == 'buildbrick' or self.mode == 'buildavatar' or self.mode == 'repair' then
					if Block.isItemID(brick.shape) then
						if brick.markerdata then
							Global.BuildBrick:addBlock(brick.shape, brick.markerdata)
						else
							brick.name = brick.shape
							Global.BuildBrick:addAsset(brick)
						end
					else
						Global.BuildBrick:addBlock(brick.shape)
					end
				elseif self.mode == 'buildscene' then
					Global.BuildBrick:addBlock(brick.shape)
				elseif self.mode == 'buildhouse' then
					Global.BuildHouse:addBlock(brick.shape)
				else
					--TODO:
				end
			end
			local bgindex = (linenum + math.ceil(index1 / num) - 1) % 3 + 1
			item1.bg._icon = bgs[bgindex]
		end

		local line = math.ceil(#data.bricks / num)
		item.itemlist.itemNum = line * num
		item.itemlist._height = line * (sitemh + shgap)
		linenum = linenum + line
	end

	_sys.asyncLoad = false
	list.itemNum = #datas
end

function brickui.getFilterBricks(self, kindfilter)
	local bricks = cfgbricks[1]
	local datas = {}
	local kinds = {}

	local hasshapes = {}
	for i, v in ipairs(bricks) do
		if not self.shapefilters then
			local bd = Block.getBlockData(v.shape)
			local kind = bd.shape2
			if (Global.BrickType[kind] and Global.CheckLimit(Global.BrickType[kind])) and (kindfilter == 'all' or kindfilter == kind) then
				if not self.ui.onlybasic.selected or bd.isbasic then
					if not kinds[kind] then
						local sortindex = Global.BrickType[kind] and Global.BrickType[kind].sortindex
						assert(sortindex, 'kind not exist:' .. kind)
						table.insert(datas, {desc = kind, sortindex = sortindex, bricks = {}})
						kinds[kind] = #datas
					end
					local index = kinds[kind]
					table.insert(datas[index].bricks, {index = i, id = v.id, count = 0})

					for j, k in ipairs(Global.BrickRelated[v.shape] or {}) do
						table.insert(datas[index].bricks, {brick = k})
					end

					for j, k in ipairs(Global.BrickRotDummy[v.shape] or {}) do
						table.insert(datas[index].bricks, {brick = k})
					end
				end
			end
		elseif self.shapefilters and self.shapefilters[v.shape] then
			local bd = Block.getBlockData(v.shape)
			local kind = 'all'
			if #datas == 0 then
				table.insert(datas, {desc = kind, sortindex = 1, bricks = {}})
			end

			table.insert(datas[1].bricks, {index = i, id = v.id, count = 0})

			hasshapes[v.shape] = true
		end
	end

	if self.shapefilters then
		for shape in pairs(self.shapefilters) do
			if not hasshapes[shape] then
				print('!!!!!!!!!!!!缺少积木:', shape)
			end
		end
	end

	table.sort(datas, function(a, b)
		return a.sortindex < b.sortindex
	end)

	return datas, bricks
end

brickui.refreshMain_type1 = function(self)
	local datas, bricks = self:getFilterBricks(self.kindfilter)
	self:refreshMain_type1_list(datas, bricks)
end
local function setIcon_s(item, img)
	if img then
		img = img
	else
		img = ''
	end

	item.s._icon = img
end
brickui.refreshMain_type2_item = function(self, item1, brick, objs, curindex)
	local oi = Global.ObjectIcons[brick.name]
	if oi then
		item1.t._icon = oi
	elseif brick.tag == 'avatar' or brick.type == 'avatar' then
		item1.t._icon = Global.ObjectIcons.dressavatar
	elseif Global.isSceneType(brick.tag) then
		item1.t._icon = Global.ObjectIcons.scenetag
	else
		if brick.state and _and(brick.state, 32) > 0 then
			item1.t._icon = Global.ObjectIcons.dynamicEffect
		end
	end

	if brick.needguide then
		item1.p:playPfx('tanhao.pfx', 0, 0, 15, 15, 15, 'tanhao', false)
	end

	if brick.tags and #brick.tags > 0 and ((_and(brick.state, 1) > 0 and brick.reviewprogress >= 100) or _and(brick.state, 2) > 0 or brick.picfile == nil) then
		item1.tagbg.visible = true
		item1.tagtitle.visible = true
		item1.tagtitle.text = Global.totag(brick.tags[1])
	end

	item1.desc.text = brick.title
	if brick.icon and brick.icon ~= '' then
		item1.c._icon = brick.icon
	else
		if Global.ObjectManager:check_isLocal(brick) and brick.picfile then
			item1.c._icon = brick.picfile.name
			setIcon_s(item1, 'icon_unupload.png')
		elseif brick.picfile then
			Global.FileSystem:downloadData(brick.picfile, nil, function()
				if not item1.visible then
					-- 被切走之后，东西全是nil（感觉是释放了）
					return
				end
				item1.c._icon = brick.picfile.name
				if _and(brick.state, 16) > 0 then
					item1.new.visible = true
				end

				if _and(brick.state, 4) > 0 then
					setIcon_s(item1, 'icon_draft.png')
				elseif _and(brick.state, 2) > 0 then
					setIcon_s(item1, 'icon_copied.png')
				elseif _and(brick.state, 1) > 0 then
					setIcon_s(item1, 'icon_publish.png')
				else
					setIcon_s(item1, 'icon_upload.png')
				end
			end)
		else
			local pic = tostring(brick.name) .. '-display.bmp'
			item1.c._icon = pic
			-- if Global.Achievement:check('browse_' .. brick.name) == false then
			-- 	item1.new.visible = true
			-- end
		end
	end

	item1.disabled = false
	if Global.ObjectManager:check_isLocal(brick) then
		item1.disabled = true
	else
		if brick.datafile then
			-- download check
			item1.disabled = true
			Global.FileSystem:downloadData(brick.datafile, nil, function()
				item1.disabled = false
			end)
		end
	end

	if Global.BuildBrick.shapeid and brick.name == Global.BuildBrick.shapeid then
		item1.disabled = true
	end

	item1._soundVolumeScale = 0
	item1.click = function()
		-- 先不做限制,等blocking判断优化后再加.
		-- if _and(brick.state, Global.BuildBrick.ObjectState.Draft) == 0 then

		Global.Sound:play('build_putdown')
		if self.mode == 'showmywork' then
			return
		end

		if self.obj_clickfunc then
			self.obj_clickfunc(brick)
			if self.hidefunc then self.hidefunc() end
			return
		end

		local mode = self.mode
		if self.mode == 'buildbrick' or self.mode == 'buildavatar' then
			mode = 'buildbrick'
			if self.hidefunc then self.hidefunc() end
		elseif self.mode == 'repair' or self.mode == 'buildhouse' or self.mode == 'showavatar' or self.mode == 'buildscene' then
			if self.hidefunc then self.hidefunc() end
		else
			--TODO:
		end

		if (mode == 'buildbrick' or mode == 'buildscene') then
			local markertype = _G.BMarker.shape2type(brick.name) -- 处理特殊marker积木
			if markertype then
				Global.BuildBrick:addBlock(brick.name, {type = markertype})
				return
			end
		end

		local tag = brick.tag or brick.type
		if tag:find('scene') then
			tag = 'scene'
		end
		Global.Browser:init(objs, curindex, false, tag, mode)
		if brick.id then
			RPC('BrowseNewObject', {ID = brick.id})
		else
			Global.Achievement:ask('browse_' .. brick.name)
		end
	end
	-- end
end
brickui.refreshMain_type2_blueprint = function(self, item1, bp)
	item1.desc.text = bp.name
	local pic = tostring(bp.name) .. '-display.bmp'
	item1.c._icon = pic
	local level = bp.data and bp.data.level or 1
	local maxlevel = #bp
	local pro = toint((level - 1) / maxlevel * 100)

	item1.graymask.visible = true
	item1.progress.visible = true
	item1.progress.txt.text = pro .. '%'
	item1.progress.pro:gotoAndStop(pro)

	item1.disabled = true --self.mode == 'view'

	item1._soundVolumeScale = 0
	item1.click = function()
		Global.Sound:play('build_putdown')
		Global.entry:goRepairBlueprint(bp)
	end
end

brickui.refreshMain_type2_list = function(self, datas)
	local list = self.showsmalllist and self.ui.mainlistsmall2 or self.ui.mainlist
	local ih = self.showsmalllist and sitemh2 or itemh
	local iw = self.showsmalllist and sitemw2 or itemw
	local hg = self.showsmalllist and shgap2 or hgap
	local wg = self.showsmalllist and swgap2 or wgap

	list.visible = true
	local linenum = 0
	list.onRenderItem = function(index, item)
		local data = datas[index]
		item.loader.icon = ''
		item.title.text = '.' .. string.upper(data.name) .. '(' .. #data.bricks .. ')'
		local num = math.floor((list._width + wgap) / (iw + wg))
		-- print('&&&&&&&&&&&&&&&&', num, list._width, wgap, itemw)
		item.itemlist.onRenderItem = function(index1, item1)
			clear_item(item1)

			if index1 > #data.bricks then
				return
			end

			local brick = data.bricks[index1]
			local bp = Global.Blueprint:getBluePrint(brick.name)
			if bp then
				self:refreshMain_type2_blueprint(item1, bp)
			else
				self:refreshMain_type2_item(item1, brick, data.bricks, index1)
			end

			local bgindex = (linenum + math.ceil(index1 / num) - 1) % 3 + 1
			item1.bg._icon = bgs[bgindex]
		end

		local line = math.ceil(#data.bricks / num)
		item.itemlist.itemNum = line * num
		item.itemlist._height = line * (ih + hg)
		linenum = linenum + line
	end

	list.itemNum = #datas
end

brickui.getfilterobject = function(self, filter)
	local datas = {}
	local purchaseddatas = {}

	local om = Global.ObjectManager
	if filter == 'all' then
		local showavatar = self.mode ~= 'buildscene'
		if self.objectkinds['mine'] then
			local objs = Global:getMyObjects()
			if showavatar then
				local avatars = om:getMyDisplayAvatars(true)
				table.fappendArray(objs, avatars)
			end
			table.insert(datas, {name = 'mine', bricks = objs})
		end

		if self.objectkinds['purchased'] then
			local pobjs = Global:getPurchasedObjects()
			purchaseddatas = pobjs
		end

		for i, v in pairs(self.objectkinds) do
			if i ~= 'all' and i ~= 'mine' and i ~= 'functions' and (showavatar or i ~= 'avatar') then
				local objs = i ~= 'avatar' and Global.GetObjects('edit', 'object', i) or Global.GetObjects('edit', 'avatar')
				table.insert(datas, {name = i, bricks = objs})
			end
		end
	elseif filter == 'mine' then
		local objs = Global:getMyObjects()

		if self.mode ~= 'buildscene' then
			local avatars = om:getMyDisplayAvatars(true)
			table.fappendArray(objs, avatars)
		end
		-- local scenes = om:getMyScenes()
		-- table.fappendArray(objs, scenes)

		table.insert(datas, {name = 'mine', bricks = objs})
	elseif filter == 'purchased' then
		purchaseddatas = Global:getPurchasedObjects()
	else
		local objs = filter ~= 'avatar' and Global.GetObjects('edit', 'object', filter) or Global.GetObjects('edit', 'avatar')
		table.insert(datas, {name = filter, bricks = objs})
		purchaseddatas = Global:getPurchasedObjects()
	end

	local function gettypedata(type)
		for i, v in ipairs(datas) do
			if v.name == type then
				return v
			end
		end
	end
	for i = #purchaseddatas, 1, -1 do
		local v = purchaseddatas[i]
		if v.type and v.type ~= '' then
			local typedata = gettypedata(v.type)
			if typedata then
				table.insert(typedata.bricks, v)
				table.remove(purchaseddatas, i)
			else
				print('no object type', v.type, v.name)
			end
		end
	end
	table.insert(datas, {name = 'purchased', bricks = purchaseddatas})

	for i = #datas, 1, -1 do
		local data = datas[i]
		for j = #data.bricks, 1, -1 do
			local name = data.bricks[j].name
			if Global.ObjectIcons[name] and Global.sen and Global.sen:getBlockByShape(name) then
				table.remove(data.bricks, j)
			end
		end
		if #data.bricks == 0 then
			table.remove(datas, i)
		end
	end
	return datas
end

brickui.refreshMain_type2 = function(self)
	print('self.objectkindfilter', self.objectkindfilter)
	local datas = self:getfilterobject(self.objectkindfilter)

	table.sort(datas, function(a, b)
		return Global.BuildBrickKinds[a.name].sortindex < Global.BuildBrickKinds[b.name].sortindex
	end)

	self:refreshMain_type2_list(datas)
end

brickui.getfilteravatar = function(self, filter)
	local datas = {}
	if filter == 'mine' then
		table.insert(datas, {name = 'mine', bricks = Global.ObjectManager:getMyDisplayAvatars()})
	elseif filter == 'avatar' then
		table.insert(datas, {name = filter, bricks = Global.GetObjects('edit', 'avatar')})
	--elseif filter == 'purchased' then
		--purchaseddatas = Global:getPurchasedAvatars()
	end

	return datas
end

brickui.refreshMain_type3 = function(self)
	local datas = {}
	if self.mode == 'showavatar' then -- 只显示可未发布的avatar
		table.insert(datas, {name = 'all', bricks = Global.ObjectManager:getMyUnPublishedAvatars()})
	else
		table.insert(datas, {name = 'avatar', bricks = Global.GetObjects('edit', 'avatar')})
		table.insert(datas, {name = 'all', bricks = Global.ObjectManager:getMyDisplayAvatars()})
	end

	self:refreshMain_type2_list(datas)
end

brickui.refreshMain_type4 = function(self)
	local datas = {}
	table.insert(datas, {name = 'all', bricks = Global.ObjectManager:getMyScenes()})

	self:refreshMain_type2_list(datas)
end

brickui.refreshMain_type5 = function(self)
	local datas = {}

	local objs = Global.GetObjects('edit', 'object', 'functions')
	table.insert(datas, {name = 'all', bricks = objs})
	self:refreshMain_type2_list(datas)
end

brickui.refreshMainList = function(self)
	self.ui.mainlist.tweenable = false
	self.ui.mainlistsmall.tweenable = false
	self.ui.mainlistsmall2.tweenable = false
	self.ui.mainlist.visible = false
	self.ui.mainlistsmall.visible = false
	self.ui.mainlistsmall2.visible = false
	if self.seltype == 1 then
		self:refreshMain_type1()
	elseif self.seltype == 2 then
		self:refreshMain_type2()
	elseif self.seltype == 3 then
		self:refreshMain_type3()
	elseif self.seltype == 4 then
		self:refreshMain_type4()
	elseif self.seltype == 5 then
		self:refreshMain_type5()
	end
end