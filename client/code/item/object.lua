
--[[
	物件管理
]]
_dofile('objectmanager.lua')

local objectbag = {
	curTypeIndex = 0,
	curSTypeIndex = 0,
	mode = 'edit' -- browser
}
Global.ObjectBag = objectbag
objectbag.timer = _Timer.new()

objectbag.init = function(self)
	if self.ui then return end

	self.tempui = {}

	self.ui = Global.ui.resourcelibrary
	self.ui.labeldesc.visible = false
	self.curTypeIndex = 1
	self.curSTypeIndex = 0

	-- list两头渐隐，数据格式：0xBRTL
	self.ui.labellist.alphaRegion = 0x00140014
	self.ui.mainlistsmall.alphaRegion = 0x14000500
	self.ui.mainlistsmall2.alphaRegion = 0x14000500
	self.ui.mainlist.alphaRegion = 0x14000500

	Global.UI:onDeviceOrientation(self.ui, function(oriH)
		self.ui._width = oriH and 1440 or 1020
		self.ui._x = (Global.ui._width - self.ui._width) / 2 + 60
		self.ui._y = (Global.ui._height - self.ui._height) / 2
		self.ui.mainlist.itemNum = self.ui.mainlist.itemNum
		self.ui.mainlistsmall.itemNum = self.ui.mainlistsmall.itemNum
		self.ui.mainlistsmall2.itemNum = self.ui.mainlistsmall2.itemNum

		self:show(false)
		self.timer:start('resetCapture', _app.elapse, function()
			self.timer:start('skip1', _app.elapse, function()
			self:show(true)
			self.timer:stop('skip1')
			end)
			self.timer:stop('resetCapture')
		end)
	end)
end

objectbag.close = function(self)
	Global.UI:slideout({self.ui})
	Global.Timer:add('hideui', 150, function()
		self:show(false)
	end)
end

objectbag.show = function(self, s)
	self:init()

	if s ~= self.ui.visible then
		if s then
			Global.UI:pushAndHide('normal')
			Global.ui._visible = true
			for i, v in ipairs (Global.ui:getChildren()) do
				table.insert(self.tempui, {u = v, visible = v.visible})
				v.visible = false
			end
		else
			Global.UI:popAndShow()
			for i, v in ipairs(self.tempui) do
				v.u.visible = v.visible
			end
			self.tempui = {}
		end
	end

	if s then
		local callback = function()
			Global.UI:slidein({self.ui})
			self.ui.visible = s
			Global.ui.resourcelibrarybg.visible = s
			Global.ui.reslib_back.visible = s
			if self.mode == 'browsercollect' then
				-- 注册collect改变时的回调
				Global.RegisterRemoteCbOnce('onGetObjectCollects', 'bagshow', function(objs)
					Global.downloadObjects(objs, nil, function()
						self:flush()
					end)

					return true
				end)
				RPC('GetObjectCollects', {})
			elseif self.mode == 'myblueprint' then
				-- Global.Blueprint:downloadMyBluePrints(nil, function()
				-- 	self:flush()
				-- end)
			end
			self:flush()
			Global.ObjectManager:listen('objectbag', function()
				self:flush()
			end)

			Global.AddHotKeyFunc(_System.KeyESC, function()
				return self.ui.visible
			end, function()
				self:close()
			end)
		end

		_G:holdbackScreen(self.timer, callback)
	else
		self.ui.visible = s
		Global.ui.resourcelibrarybg.visible = s
		Global.ui.reslib_back.visible = s
		Global.SwitchControl:set_render_on()
		Global.ObjectManager:listen('objectbag')
	end
end
local function setTitleIcon(item, upload)
	item._visible = upload ~= nil
	if upload then
		item._icon = upload
	end
end
objectbag.flush = function(self)
	if not self.ui then return end
	if self.ui.visible == false then return end

	local types = Global.GetTypes(self.mode)
	if self.curTypeIndex > #types then
		self.curTypeIndex = 1
	end
	local typeitems = {}
	local visible = #types > 1
	self.ui.typelist._visible = visible
	self.ui.typebg._visible = visible
	self.ui.typelist.onRenderItem = function(index, item)
		table.insert(typeitems, item)
		local type = types[index]
		item.c1._icon = 'img://' .. type.icon .. '1.png'
		item.c2._icon = 'img://' .. type.icon .. '2.png'
		item.click = function()
			self.curSTypeIndex = 0
			self.curTypeIndex = index
			self:flush()
		end
	end
	local typenum = #types
	self.ui.typelist.itemNum = typenum
	for i = 1, typenum do
		typeitems[i].selected = i == self.curTypeIndex
	end

	-- TODO.暂时隐藏
	self.ui.labellist._visible = false
	self.ui.labelbg._visible = false
	local labelitems = {}
	self.ui.labellist.onRenderItem = function(index, item)
		table.insert(labelitems, item)
		local stype = types[self.curTypeIndex].stypes[index - 1]
		stype = stype or {desc = 'all', icon = 'all'}
		item.c1._icon = 'img://' .. stype.icon .. '1.png'
		item.c2._icon = 'img://' .. stype.icon .. '2.png'
		item.click = function()
			self.curSTypeIndex = index - 1
			self:flush()
		end
	end
	local labelnum = #types[self.curTypeIndex].stypes + 1
	self.ui.labellist.itemNum = labelnum
	for i = 1, labelnum do
		labelitems[i].selected = i - 1 == self.curSTypeIndex
	end

	local function clearClickdata(item)
		if not item.clickdata then return end
		if item.clickdata.timer then
			item.clickdata.timer:stop()
		end

		item.clickdata = nil
	end

	local stypes = types[self.curTypeIndex].stypes
	local cstypes = self.curSTypeIndex == 0 and stypes or {stypes[self.curSTypeIndex]}
	self.ui.mainlistsmall.visible = false
	self.ui.mainlistsmall2.visible = false
	self.ui.mainlist.visible = true
	self.ui.mainlist.tweenable = false
	local bgs = {'1-1.png', '2-1.png', '3-1.png'}
	local itemw = 260
	local itemh = 313
	local hgap = 10
	local wgap = 50
	local linenum = 0
	self.ui.mainlist.onRenderItem = function(index, item)
		local type = types[self.curTypeIndex].desc
		local stype = cstypes[index].desc
		local objects = {}
		if self.mode == 'myblueprint' then
			local bps = Global.Blueprint:getMyBluePrints()
			for name, bp in pairs(bps) do
				table.insert(objects, bp)
			end
		else
			objects = Global.GetObjects(self.mode, type, stype)
		end
		item.title.text = string.upper(stype) .. '(' .. #objects .. ')'
		local tempmat = _Matrix3D.new()
		local tempos = _Vector3.new()

		local num = math.floor((self.ui.mainlist._width + wgap) / (itemw + wgap))
		item.itemlist.onRenderItem = function(oindex, oitem)
			oitem.disabled = true
			oitem.number.text = ''
			oitem.c._icon = ''
			oitem.t._icon = ''
			oitem.s._icon = ''
			oitem.desc.text = ''
			oitem.new.visible = false
			oitem.tagbg.visible = false
			oitem.tagtitle.visible = false
			oitem.progress.visible = false
			oitem.graymask.visible = false
			oitem.tagtitle.text = ''
			oitem.onMouseDown = function()
			end
			oitem.onMouseUp = function()
			end
			oitem.onMouseMove = function()
			end
			if oindex > #objects then
				oitem.bg._icon = 'img://alphabg.png'
			else
				local obj = objects[oindex]
				if self.mode ~= 'myblueprint' and Global.ObjectManager:check_isLocal(obj) then
					oitem.disabled = false
					oitem.c._icon = obj.picfile.name
				-- 正常线上的
				elseif obj.picfile then
					Global.FileSystem:downloadData(obj.picfile, nil, function()
						if not oitem.c then return end
						oitem.c._icon = obj.picfile.name
					end)
					Global.FileSystem:downloadData(obj.datafile, nil, function()
						oitem.disabled = false
					end)
				-- 只读目录打进包的
				else
					local picfilename = obj.name .. '-display.bmp'
					oitem.c._icon = picfilename
					oitem.disabled = false
				end

				if obj.tag == 'avatar' then
					oitem.t._icon = 'img://' .. Global.ObjectIcons.dressavatar
				elseif obj.state and _and(obj.state, 32) > 0 then
					oitem.t._icon = 'img://' .. Global.ObjectIcons.dynamicEffect
				end

				oitem.desc.text = obj.title
				if obj.title == nil or obj.title == '' then
					-- scene type
					if obj.tag == 'scene' then
						oitem.desc.text = '3D Dungeon'
					elseif obj.tag == 'scene_2D' then
						oitem.desc.text = '2D Dungeon'
					elseif obj.tag == 'scene_music' then
						oitem.desc.text = 'Music Parkour'
					end
				end
				oitem.progress.visible = false
				oitem.graymask.visible = false
				if self.mode == 'myblueprint' then
					oitem.desc.text = obj.title or obj.name
					local level = obj.data and obj.data.level or 1
					local maxlevel = #obj
					local pro = toint((level - 1) / maxlevel * 100)

					oitem.progress.visible = true
					oitem.graymask.visible = true
					oitem.progress.txt.text = pro .. '%'
					oitem.progress.pro:gotoAndStop(pro)
				end

				oitem.new.visible = false

				if self.mode ~= 'myblueprint' then
					if _and(obj.state, 16) > 0 then
						oitem.new.visible = true
					end

					if Global.ObjectManager:check_isLocal(obj) then
						setTitleIcon(oitem.s, 'icon_unupload.png')
					elseif Global.ObjectManager:check_isDraft(obj) then
						setTitleIcon(oitem.s, 'icon_draft.png')
					elseif Global.ObjectManager:check_isCopied(obj) then
						setTitleIcon(oitem.s, 'icon_copied.png')
					elseif Global.ObjectManager:check_isPublished(obj) then
						setTitleIcon(oitem.s, 'icon_publish.png')
					else
						setTitleIcon(oitem.s, 'icon_upload.png')
					end
					oitem.number.text = 9999
				end

				if obj.tags and #obj.tags > 0 and ((_and(obj.state, 1) > 0 and obj.reviewprogress >= 100) or obj.picfile == nil) then
					oitem.tagbg.visible = true
					oitem.tagtitle.visible = true
					oitem.tagtitle.text = Global.totag(obj.tags[1])
				end

				oitem.onMouseDown = function(args)
					if Block.isBuildMode() then
						Global.BuildBrick:load(obj.name)
						Global.BuildBrick:hideBricksUI()
						self:show(false)
						return
					end
					if oitem.clicktime and _tick() - oitem.clicktime < 200 then
						if self.mode == 'edit' then
							Global.entry:goBuildBrick(obj.name)
						end
						return
					end
					clearClickdata(oitem)
					local scalef = Global.UI:getScale()

					oitem.clicktime = _tick()
					local clickdata = {
						-- 获取ui中鼠标的真实位置 TODO:使用逻辑分辨率？
						x = args.mouse.x * scalef,
						y = args.mouse.y * scalef,
						fid = args.mouse.id,
						time = _tick(),
						timer = _Timer.new(),
						invoked = false,
						oldpos = _Vector3.new(),
					}
					clickdata.timer:start('pressitem', 200, function()
						if Global.GameState:isState('EDIT') == false then return end

						Global.ui:showEdit(true, true, false)
						clickdata.invoked = true
						if oitem.clickdata then
							oitem.clickdata.timer:stop()
						end

						updateCameraData()
						local cameraData = Global.cameraData
						local look = _rd.camera.look
						if cameraData.masix.x == 0 then
							_rd:pickYZPlane(clickdata.x, clickdata.y, _rd.camera.look.x, tempos)
						elseif cameraData.masix.y == 0 then
							_rd:pickXZPlane(clickdata.x, clickdata.y, _rd.camera.look.y, tempos)
						elseif cameraData.masix.z == 0 then
							_rd:pickXYPlane(clickdata.x, clickdata.y, _rd.camera.look.z, tempos)
						end

						local itemid = obj.name
						Global.normalizePos(tempos, Block.getMoveStep(itemid))

						tempmat:setTranslation(tempos)
						if obj.type == 'object' or obj.type == 'floor' then
							Global.editor.objectSelect:setCurrentChooseBlock(itemid, tempmat)
							Global.ui.controler.movebutton.onMouseDown(args)
							Global.ui:setControlerVisible(false)
						elseif obj.type == 'blockui' then
							local blockui = Global.editor.objectSelect:setCurrentChooseBlockUI(itemid)
							blockui:move(args.mouse.x, args.mouse.y)
							Global.ui.uicontroler.movebutton.onMouseDown(args)
						end
					end)

					oitem.clickdata = clickdata
				end
				oitem.onMouseUp = function(args)
					-- 显示调整位置UI
					if oitem.clickdata and oitem.clickdata.invoked then
						if obj.type == 'object' or obj.type == 'floor' then
							Global.ui.controler.movebutton.onMouseUp(args)
						elseif obj.type == 'blockui' then
							Global.ui.uicontroler.movebutton.onMouseUp(args)
						end
					end
					clearClickdata(oitem)
				end
				oitem.onMouseMove = function(args)
					if not oitem.clickdata then return end
					if not oitem.clickdata.invoked then
						local scalef = Global.UI:getScale()
						local dx = math.abs(args.mouse.x * scalef - oitem.clickdata.x)
						local dy = math.abs(args.mouse.y * scalef - oitem.clickdata.y)
						if dx + dy > 20 then
							clearClickdata(item)
						end
					else
						if obj.type == 'object' or obj.type == 'floor' then
							Global.ui.controler.movebutton.onMouseMove(args)
						elseif obj.type == 'blockui' then
							Global.ui.uicontroler.movebutton.onMouseMove(args)
						end
					end
				end

				oitem.click = function(args)
					if self.mode == 'myblueprint' then
						Global.entry:goBrowser(objects, oindex, false, 'object', 'repair')
					elseif self.mode == 'browserminedress' then
						Global.entry:goBrowser(objects, oindex, false, 'avatar', 'browser', 'avatar')
					elseif self.mode == 'browserminescene' then
						Global.entry:goBrowser(objects, oindex, false, 'scene', 'browser', 'scene')
					elseif self.mode == 'browsercollectscene' then
						Global.entry:goBrowser(objects, oindex, true, 'scene', 'browser', 'scene')
					else
						Global.entry:goBrowser(objects, oindex, false, 'object', 'browser')
					end
				end

				local bgindex = (linenum + math.ceil(oindex / num) - 1) % 3 + 1
				oitem.bg._icon = 'img://' .. bgs[bgindex]
			end
		end
		local line = math.max(math.ceil(#objects / num), 1)
		item.itemlist.itemNum = line * num
		item.itemlist._height = line * (itemh + hgap)
		linenum = linenum + line
	end
	self.ui.mainlist.itemNum = #cstypes
end

objectbag.showObjects = function(self, show, mode)
	if mode ~= '' then
		self.mode = mode
	end
	self:show(show)

	if Version:isAlpha1() == false then
		Global.ui.resourcelibrarybg.onMouseDown = function()
			Global.ui.resourcelibrarybg.enable = true
		end
		Global.ui.resourcelibrarybg.onMouseMove = function() end
		Global.ui.resourcelibrarybg.onMouseUp = function()
			if Global.ui.resourcelibrarybg.enable then
				self:close()
			end
			Global.ui.resourcelibrarybg.enable = false
		end
	end
	Global.ui.reslib_back.click = function()
		self:close()
	end
end

--------------------------------------------------------------------
-- Object
--------------------------------------------------------------------
local houses = {}
Global.houses = houses

local function UpdateObjectsData(obj)
	Global.ObjectManager:newObj(obj)
end

Global.UpdateObjectsData = UpdateObjectsData

local function DeleteObjectsData(obj)
	Global.ObjectManager:delObj(obj)
end

Global.getObjectByName = function(shape)
	return Global.ObjectManager:getObjectByName(shape)
end

Global.getObject = function(idorname)
	return Global.ObjectManager:getObject(idorname)
end

Global.getObjectFromServer = function(id)
	RPC("GetObject", {ID = id})
end

Global.getHouseByName = function(shape)
	return Global.ObjectManager:getHouseByName(shape)
end

Global.getHouse = function(id)
	return Global.houses[id]
end

Global.getMyObjects = function()
	return Global.ObjectManager:getMyObjects()
end

Global.getPurchasedObjects = function()
	return Global.ObjectManager:getPurchasedObjects()
end

Global.getPurchasedAvatars = function()
	return Global.ObjectManager:getPurchasedAvatars()
end

Global.isPurchasedObject = function(object)
	local isp1 = Global.ObjectManager:isPurchasedObject(object)
	local isp2 = Global.isUnlockObject(object)
	return isp1 or isp2
end

Global.getSystemTag = function(object)
	if not object then
		return
	end

	if not object.tags then
		return
	end

	for i, v in ipairs(object.tags) do
		if string.fstarts(v, "$") then
			return v
		end
	end
end

Global.getMyHouse = function()
	return Global.ObjectManager:getHome()
end

Global.downloadObjects = function(objs, onprogress, onfinish, dataonly)
	local datas = {}
	for i, obj in ipairs(objs) do
		table.insert(datas, obj.datafile)
		if not dataonly then
			table.insert(datas, obj.picfile)
		end
	end
	Global.FileSystem:downloadDatas(datas, onprogress, onfinish)
end
Global.downloadWhole = function(obj, func, onprogress)
	Global.FileSystem:downloadData(obj.datafile, nil, function()
		Global.downloadHousesNeededObjects({obj}, onprogress, func)
	end)
end
Global.downloadHousesNeededObjects = function(houses, onprogress, onfinish)
	local objnames = {}
	for i, h in ipairs(houses) do
		local names = Block.getBlockNeedObjects(h.name)
		table.append(objnames, names)
	end

	local ns = {}
	for k in next, objnames do
		table.insert(ns, k)
	end

	if not next(ns) then
		onfinish()
		return
	end

	local om = Global.ObjectManager
	om:RPC_GetObjectsByNames(ns, function(objs)
		local sens = {}
		for i, o in ipairs(objs) do
			if Global.isMultiObjectType(o.tag) then
				table.insert(sens, o)
			end
		end
		if #sens == 0 then
			om:listen_objs(objs, 0, onprogress, onfinish)
		else
			--print('aaaaa', #sens)
			om:listen_objs(objs, 0, nil, function()
				Global.downloadHousesNeededObjects(sens, onprogress, onfinish)
			end)
		end
	end)

	--Global.ObjectManager:listen_objs_by_name(ns, 0, onprogress, onfinish)
end

Global.getRepairLevel = function(level)
	local repairlevels = _G.cfg_repair[level]
	if #repairlevels == 0 then return end
	local index = math.random(1, #repairlevels)
	return repairlevels[index], index
end

Global.randomNewRepairLevel = function(level, keys)
	local rl, index
	for n = 1, 10 do
		rl, index = Global.getRepairLevel(level)
		local lv = string.match(rl.file, 'new(%d+)-%d+')
		if not lv or not keys[lv] then
			if lv then keys[lv] = true end
			break
		end
	end

	return rl, index
end

define.CreateObject{Result = false, Info = {}, Browser = ''}
when{}
function CreateObject(Result, Info, Browser)
	if Result then
		print('CreateObject Success id :' .. table.ftoString(Info))

		UpdateObjectsData(Info)

		if Info.tag == 'house' then
			Global.doRemoteCb('onChangeHouse', Info)
		else
			Global.doRemoteCb('onChangeObject', Info)
		end
	else
		print('CreateObject Failed id :' .. table.ftoString(Info))
		if Info.tag ~= 'house' then
			Global.doRemoteCb('onChangeObjectErr', Info)
		end
	end
end

define.GetObject{Result = false, Info = {}}
when{}
function GetObject(Result, Info)
	if Result then
		-- print('获取物件成功 :' .. table.ftoString(Info))

		UpdateObjectsData(Info)

		if Info.tag == 'house' then
			Global.doRemoteCb('onChangeHouse', Info)
		else
			Global.doRemoteCb('onChangeObject', Info)
		end
	else
		print('GetObject Failed :' .. table.ftoString(Info))
		Global.doRemoteCb('onChangeHouseErr', Info)
		Global.doRemoteCb('onChangeObjectErr', Info)
	end
end

define.UpdateObject{Result = false, Info = {}, Browser = ''}
when{}
function UpdateObject(Result, Info, Browser)
	if Result then

		UpdateObjectsData(Info)

		if Info.tag == 'house' then
			Global.doRemoteCb('onChangeHouse', Info)
		else
			Global.doRemoteCb('onChangeObject', Info)
		end
	else
		print('UpdateObject Failed :' .. table.ftoString(Info))
		if Info.tag ~= 'house' then
			Global.doRemoteCb('onChangeObjectErr', Info)
		end
	end
end

define.DeleteObject{Result = false, Info = {}}
when{}
function DeleteObject(Result, Info)
	if Result then
		-- print('删除物件成功 :' .. table.ftoString(Info))
		DeleteObjectsData(Info)

		if Info.tag == 'house' then
			Global.doRemoteCb('onChangeHouse', Info)
		else
			Global.doRemoteCb('onChangeObject', Info)
		end
	else
		print('DeleteObject Failed :' .. table.ftoString(Info))
	end
end

define.BuyItemSuccess{Info = {}}
when{}
function BuyItemSuccess(Info)
	if Info.id then
		Notice(Global.TEXT.NOTICE_ITEM_BUY)
	end
end

define.UpdateSystemTags{Tags = {}}
when{}
function UpdateSystemTags(Tags)
	-- Global.doRemoteCb('onUpdateSystemTags', Tags)
end

define.UploadObjectInfo{Result = false, Info = {}}
when{}
function UploadObjectInfo(Result, Info)
	if Result then
		UpdateObjectsData(Info)
	end
	Global.doRemoteCb('onUploadObject', Info)
end

define.ChangeObjectNameInfo{Result = false, Info = {}}
when{}
function ChangeObjectNameInfo(Result, Info)
	if Result then
		UpdateObjectsData(Info)
	end
	Global.doRemoteCb('onChangeObjectName', Info)
end

define.UnPublishObjectInfo{Result = false, Info = {}}
when{}
function UnPublishObjectInfo(Result, Info)
	if Result then
		UpdateObjectsData(Info)
	end
	Global.doRemoteCb('onDeleteUploadObject', Info)
end

define.PublishObjectInfo{Result = false, Info = {}}
when{}
function PublishObjectInfo(Result, Info)
	if Result then
		UpdateObjectsData(Info)
	end
	Global.doRemoteCb('onUploadObject', Info)
end