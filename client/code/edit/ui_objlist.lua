
local function doSpecialEffect(list)
	local midx = list.posX + list.viewWidth / 2
	local children = list:getChildren()
	for k, v in pairs(children) do
		local dist = (midx - v._x - v._width / 2)
		dist = dist > 0 and dist or - dist
		local width = v._width
		if (dist > width) then
			v.pic._xscale = 100
			v.pic._yscale = 100
		else
			local ss = 1 + (1 - dist / width) * 0.3
			v.pic._xscale = ss * 100
			v.pic._yscale = ss * 100
		end
	end
end
local function initEditMenuList(list, data, objecttype)
	local function clearClickdata(item)
		if not item.clickdata then return end
		if item.clickdata.timer then
			item.clickdata.timer:stop()
		end

		if item.pic.oldscale then
			item.pic._xscale = item.pic.oldscale
			item.pic._yscale = item.pic.oldscale
		end

		item.clickdata = nil

		list.scrollable = true
	end

	local tempmat = _Matrix3D.new()
	local tempos = _Vector3.new()
	list.onRenderItem = function(index0, item)
		-- 跳过空道具
		if index0 == 1 or index0 == #data + 2 then return end

		local index = index0 - 1
		--item.title.text = _sys:getFileName(mesh.resname)
		local id = data[index].name
		local pic = tostring(id) .. '-display.bmp'
		item.pic._icon = 'img://' .. pic

		item.click = function()
			if PickChangeShape then
				local shapeid = data[index].name
				for i, b in ipairs(Global.editor.selectedBlocks) do
					b:setShape(shapeid)
				end
			end
		end

		item.onMouseDown = function(args)
			clearClickdata(item)
			local scalef = Global.UI:getScale()

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
				clickdata.invoked = true
				item.pic.oldscale = item.pic._xscale
				item.pic._xscale = item.pic.oldscale * 1.2
				item.pic._yscale = item.pic.oldscale * 1.2
				list.scrollable = false
				if item.clickdata then
					item.clickdata.timer:stop()
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

				local itemid = data[index].name
				Global.normalizePos(tempos, Block.getMoveStep(itemid))

				tempmat:setTranslation(tempos)
				if objecttype == 'block' then
					Global.editor.objectSelect:setCurrentChooseBlock(itemid, tempmat)
					Global.ui.controler.movebutton.onMouseDown(args)
					Global.ui:setControlerVisible(false)
				elseif objecttype == 'blockui' then
					local blockui = Global.editor.objectSelect:setCurrentChooseBlockUI(itemid)
					blockui:move(args.mouse.x, args.mouse.y)
					Global.ui.uicontroler.movebutton.onMouseDown(args)
				end
			end)

			item.clickdata = clickdata
		end
		item.onMouseUp = function(args)
			-- 显示调整位置UI
			if item.clickdata and item.clickdata.invoked then
				if objecttype == 'block' then
					Global.ui.controler.movebutton.onMouseUp(args)
				elseif objecttype == 'blockui' then
					Global.ui.uicontroler.movebutton.onMouseUp(args)
				end
			end
			clearClickdata(item)
		end
		item.onMouseMove = function(args)
			if not item.clickdata then return end
			if not item.clickdata.invoked then
				local scalef = Global.UI:getScale()
				local dx = math.abs(args.mouse.x * scalef - item.clickdata.x)
				local dy = math.abs(args.mouse.y * scalef - item.clickdata.y)
				if dx + dy > 20 then
					clearClickdata(item)
				end
			else
				if objecttype == 'block' then
					Global.ui.controler.movebutton.onMouseMove(args)
				elseif objecttype == 'blockui' then
					Global.ui.uicontroler.movebutton.onMouseMove(args)
				end
			end
		end
	end

	list.onScroll = function(self)
		doSpecialEffect(list)
	end

	--list.loop = true
	-- 前后各加一个空的道具栏
	list.itemNum = #data + 2
end

local ui = Global.ui
ui.editMenu.init = function()
	ui.editMenu.currentTime = 0
	ui.editMenu.downTime = 0

	local resname = _sys:getFileName(Global.sen.resname, true, false)
	if resname == 'guide.sen' then
		initEditMenuList(ui.editMenu.list1.list, Global.GuideFloors, 'block')
		ui.editMenu.list2.visible = false
		ui.editMenu.list3.visible = false
	else
		ui.editMenu.list2.visible = true
		ui.editMenu.list3.visible = true
		initEditMenuList(ui.editMenu.list1.list, Global.GetObjects('edit', 'floor'), 'block')
		initEditMenuList(ui.editMenu.list2.list, Global.GetObjects('edit', 'object'), 'block')
		initEditMenuList(ui.editMenu.list3.list, Global.GetObjects('edit', 'blockui'), 'blockui')
	end

	doSpecialEffect(ui.editMenu.list1.list)
	doSpecialEffect(ui.editMenu.list2.list)
end
ui.editMenu.currentTime = 0
ui.editMenu.downTime = 0
ui.editMenu.update = function(self, e)
	self.currentTime = self.currentTime + e
end
ui.editMenu.onItemClick = function(self)
	self.downTime = self.currentTime
end
ui.editMenu.isHoldClick = function(self)
	return self.currentTime - self.downTime > 1000
end
ui.refreshItemList = function(self)
	if ui.editMenu.list2.visible then
		initEditMenuList(ui.editMenu.list2.list, Global.GetObjects('edit', 'object'), 'block')
	end
end