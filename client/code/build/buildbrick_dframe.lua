local Container = _require('Container')

local BuildBrick = _G.BuildBrick

local defaultDuration = 200
local durationStep = 200
local durationRate = 0.25

BuildBrick.initDfsUI = function(self)
	--if self.initDfsUIed then return end
	--self.initDfsUIed = true

	local ui = self.ui.dfs
	ui.play.click = function()
		if ui.play.selected then
			self:playDFrame()
		else
			self:stopDFrame()
		end
	end

	ui.all.click = function()
		self:stopDFrame()
		self:onSelectDFrame()
	end

	ui.copybutton.click = function()
		if not self.currentDframe then return end

		self:stopDFrame()
		local lf = self.currentDframe
		local f = self:cmd_frame_new(lf.time, lf.data)
	end

	ui.delbutton.click = function()
		if not self.currentDframe then return end
		self:stopDFrame()
		Confirm(Global.TEXT.CONFIRM_FRAME_DELETE, function()
			self:cmd_frame_del(self.currentDframe)
		end, function()
		end)
	end

	ui.frames.alphaRegion = 0x00140014
end

BuildBrick.initDfs = function(self, df, gs)
	if not df then
		df = {}
		df.name = 'df1'
		df.transitions = {}
	end

	--self.DfFrames = {}
	--self.DfBlocks = {}
	-- self.DFPlayer = DynamicEffect.new(df)

	-- 只加载一个
	--local dfdata = self.dynamicEffects and self.dynamicEffects[1]
	self:loadDfData(df, gs)
	-- 用于保存 : TODO
	-- if not dfdata then
	-- 	self.dynamicEffects = {}
	-- 	local df = {}
	-- 	df.name = 'df1'
	-- 	df.transitions = {}
	-- 	table.insert(self.dynamicEffects, df)
	-- end

	self:initDfsUI()
	self:refreshFrameList()
end

BuildBrick.getFrameByTime = function(self, time)
	for i, f in ipairs(self.DfFrames) do
		if f.time == time then
			return f
		end
	end
end

BuildBrick.getFrameData = function(self, f, b, attr)
	if not f then f = self.currentDframe end
	if not f then return end
	local data = f.data[b]
	return data and data[attr]
end

BuildBrick.getBlockValue_ByFrame = function(self, f, b, attr)
	if not f then f = self.currentDframe end

	if attr == 'material' then
		local data = f and f.data[b]
		if data and data[attr] then
			return data[attr]:saveToData()
		end

		return b:getMaterialBatch()
	end
end

BuildBrick.setFrameAttrValue = function(self, f, b, attr, value)
	if not f.data then f.data = {} end
	if not f.data[b] then f.data[b] = {} end

	local bdata = f.data[b]
	local curvalue = bdata[attr]
	local ftype, isobject = Global.fvalueType(value)
	if curvalue == nil then
		if ftype == 'PivotMat' or ftype == '_Matrix3D' then
			curvalue = PivotMat.new()
			curvalue:set(value)
			curvalue:formatMatrix()
		elseif ftype == 'LerpMaterial' then
			curvalue = LerpMaterial.new(value)
		elseif ftype == 'PaintInfo' then
			curvalue = PaintInfo.new(value)
		elseif ftype == '_Vector3' then
			curvalue = _Vector3.new(value)
		-- elseif ftype == '_Vector4' then
		-- 	curvalue = _Vector4.new(value)
		elseif not isobject then
			curvalue = value
		else
			print('setFrameAttrValue000', attr, ftype)
			curvalue = value
			assert(false)
		end

		bdata[attr] = curvalue
	else
		if ftype == 'PivotMat' or ftype == '_Matrix3D' then
			curvalue:set(value)
			curvalue:formatMatrix()
		elseif isobject then
			curvalue:set(value)
		else
			bdata[attr] = value
		end
	end

	-- print('setFrameAttrValue', f.time, attr, ftype, b, bdata[attr], isobject and value.tostring and value:tostring() or value)
end

BuildBrick.initFrameValue = function(self, b, attr)
	local frames = self:getDFFrames()
	for _, f in ipairs(frames) do
		if attr == 'alpha' then
			self:setFrameAttrValue(f, b, attr, 1)
		elseif attr == 'material' then
			self:setFrameAttrValue(f, b, attr, LerpMaterial.new(b:getMaterialBatch()))
		elseif attr == 'paint' then
			self:setFrameAttrValue(f, b, attr, b.data.paintInfo)
		elseif attr == 'transform' then
			self:setFrameAttrValue(f, b, attr, b:getCacheTransform() or b.node.transform)
		elseif attr == 'invisible' then
			self:setFrameAttrValue(f, b, attr, false)
		elseif attr == 'translation' then
			self:setFrameAttrValue(f, b, attr, _Vector3.new(0, 0, 0))
		elseif attr == 'rotation' then
			self:setFrameAttrValue(f, b, attr, _Vector4.new(0, 0, 1, 0))
		elseif attr == 'scale' then
			self:setFrameAttrValue(f, b, attr, _Vector3.new(1, 1, 1))
		end
	end
end

local helpmat = _Matrix3D.new()
local helpvec = _Vector3.new()
BuildBrick.loadDfData = function(self, data, gs)
	self.DfFrames = {}
	self.DfFrames[1] = {time = 0, data = {}, duration = defaultDuration}
	self.DfBlocks = {}

	-- 禁用以前的动画
	for _, t in ipairs(data.transitions) do
		if t.attr == 'translation' or t.attr == 'scale' or t.attr == 'rotation' then
			local df = {}
			df.name = 'df1'
			df.transitions = {}
			data = df
			break
		end
	end

	-- 添加frame
	for _, t in ipairs(data.transitions) do
		for _, f in ipairs(t.frames) do
			local frame = self:getFrameByTime(f.time)
			if not frame then
				frame = self:createDFFrame(f.time)
			end
		end
	end

	local pivot = _Vector3.new()
	for _, t in ipairs(data.transitions) do
		local g = gs and gs[t.group] or t.group
		if g then
			local bs = {}
			g:getBlocks(bs)

			for _, f in ipairs(t.frames) do
				local frame = self:getFrameByTime(f.time)
				-- if not frame then
				-- 	frame = self:createDFFrame(f.time)
				-- end

				for i, b in ipairs(bs) do
					if t.attr == 'transformDiff' then
						local value = PivotMat.new()
						value:set(f.value)
						-- 计算在轴心下的位置
						local mat = value:getMatrix()

						pivot:set(t.pivot)
						local p = value:getPivot()
						if p then
							mat:getTranslation(helpvec) -- 帧位移
							_Vector3.add(pivot, p, pivot)
						end
						mat:setPivot(pivot)
						mat.pivot = nil
						-- mat:apply(pivot, pivot)
						mat:mulLeft(b.node.transform)

						if p then
							helpmat:set(mat)
							helpmat:inverse()
							_Vector3.add(pivot, helpvec, pivot) -- 旋转点世界位置
							helpmat:apply(pivot, pivot)
							value:setPivot(pivot)
						end
						-- print('value', value)
						--self:setFrameAttrValue(frame, b, 'transform', value)
						-- if p then
						-- 	value:setPivot(pivot)
						-- end
						self:addDFFrameData(frame, 'transform', b, value)
					else
						self:addDFFrameData(frame, t.attr, b, f.value)
						--self:setFrameAttrValue(frame, b, t.attr, f.value)
					end
				end
			end
		end
	end

	if data.actions then
		for k, action in pairs(data.actions) do
			local frame = self:getFrameByTime(action.timeStart)
			frame.isActionLoop = action.isloop
			frame.actionType = action.type

			local frame2 = self:getFrameByTime(action.timeEnd)
			frame2.isActionStop = true
		end
	end

	--计算帧时长
	self:updateDFramesDuration()

	self.DFPlayer = DynamicEffect.new(data, nil, gs)
	-- print('self.DFPlayer', self.DFPlayer:tostring())
end

BuildBrick.applyDFMove = function(self, b, mat)
	if mat:isIdentity() then return end
	for i, f in ipairs(self.DfFrames) do
		local value = self:getFrameData(f, b, 'transform')
		if value then
			local mat0 = value:getMatrix()
			mat0:mulRight(mat)
			-- local pivot = value:getPivot()
			-- if pivot then
			-- 	mat:apply(pivot, pivot)
			-- end
		end
	end
end

BuildBrick.updateSceneToFirstFrame = function(self)
	local f = self.DfFrames[1]
	if not f or not f.data then return end
	for b, bdata in pairs(f.data) do
		for attr, value in pairs(bdata) do
			if attr == 'alpha' then
				-- bdata[attr] = 1
			elseif attr == 'material' then
				bdata[attr]:set(LerpMaterial.new(b:getMaterialBatch()))
			elseif attr == 'paint' then
				bdata[attr]:set(b.data.paintInfo)
			elseif attr == 'transform' then
				if not bdata[attr] then
					bdata[attr]:set(b.node.transform)
				else
					local mat = _Matrix3D.new()
					local mat0 = bdata[attr]:getMatrix()
					mat:transformFromTo(mat0, b.node.transform)
					self:applyDFMove(b, mat)
				end
			elseif attr == 'invisible' then
				-- bdata[attr] = true
			elseif attr == 'translation' then
				-- bdata[attr] = _Vector3.new(0, 0, 0)
			elseif attr == 'rotation' then
				-- bdata[attr] = _Vector4.new(0, 0, 1, 0)
			elseif attr == 'scale' then
				-- bdata[attr] = _Vector3.new(1, 1, 1)
			end
		end
	end

	self:setTransitionDirty()
end

BuildBrick.showDfs_base = function(self, show)
	-- if self.ui.dfs.visible == show then return end
end

BuildBrick.showDfs = function(self, show)
	if self.ui.dfs.visible == show then return end

	-- 清空选中
	self:cmd_select_begin()
	self:cmd_select_end()
	self.ui.showtransition.button.selected = show
	if not self.dfDB then
		self.dfDB = _DrawBoard.new(1024, 1024, 0)
	end

	if not show then
		Global.UI:slideout({self.ui.dfs}, nil, '-y')
		self.timer:start('hidedf', 150, function()
			self:stopDFrame()
			self.ui.dfs.visible = show
			self.timer:stop('hidedf')
			self:showDisableBg(false)
			self:hideNormalUIs(false)
		end)

		return
	end

	Global.UI:slidein({self.ui.dfs}, nil, 'y')
	self:showPropList(false)
	self:hideNormalUIs(true)
	self:showTopButtons()
	self.ui.dfs.visible = show
	self:showDisableBg(true)

	if not self.DfFrames or not next(self.DfFrames) then
		self:initDfs()
	end

	local currframe = self.currentDframe
	if not currframe then
		self:updateSceneToFirstFrame()
	end

	for i, v in ipairs(self.DfFrames) do
		self:onSelectDFrame_base(v)
	end

	self:onSelectDFrame_base(currframe)

	Global.AddHotKeyFunc(_System.KeyESC, function()
		return Block.isBuildMode() and self.ui.dfs.visible
	end, function()
		self:showDfs(false)
	end)
end

BuildBrick.updateDFramesTime = function(self)
	local t = 0
	for i, f in ipairs(self.DfFrames) do
		f.time = i == 1 and 0 or (t + f.duration)
		t = f.time
	end
end

BuildBrick.updateDFramesDuration = function(self)
	for i = 1, #self.DfFrames do
		local f, lf = self.DfFrames[i], self.DfFrames[i - 1]
		f.duration = lf and f.time - lf.time or defaultDuration
	end
end

BuildBrick.copyFrameData = function(self, f, fdata)
	for b, data in pairs(fdata) do
		for attr, value in pairs(data) do
			self:setFrameAttrValue(f, b, attr, value)
		end
	end

	self:setTransitionDirty()
end

BuildBrick.insertDFFrame = function(self, time)
	local duration = defaultDuration
	local index = 0
	for i, v in ipairs(self.DfFrames) do
		if v.time > time then
			v.time = v.time + duration
		else
			index = i
		end
	end

	local f = {time = time + duration, data = {}, duration = duration}
	table.insert(self.DfFrames, index + 1, f)

	self:updateDFramesDuration()

	return f
end

BuildBrick.createDFFrame = function(self, time)
	local f
	if time then
		-- TODO: defaultDuration can be calculated
		f = {time = time, data = {}, duration = defaultDuration}
		local index = -1
		for i, v in ipairs(self.DfFrames) do
			if v.time == time then
				return f
			elseif v.time > time then
				index = i
				break
			end
		end

		if index ~= -1 then
			table.insert(self.DfFrames, index, f)
		else
			table.insert(self.DfFrames, f)
		end
	else
		f = {data = {}, duration = defaultDuration}
		table.insert(self.DfFrames, f)
		self:updateDFramesTime()
	end

	return f
end

BuildBrick.findLastActionFrame = function(self, frame)
	for i = #self.DfFrames, 1, -1 do
		local f = self.DfFrames[i]
		if f.time < frame.time then
			if f.isActionStop then
				return
			end
			if f.actionType then
				return f
			end
		end
	end
end

BuildBrick.findNextActionStop = function(self, frame)
	for i = 1, #self.DfFrames, 1 do
		local f = self.DfFrames[i]
		if f.time > frame.time then
			if f.actionType then
				return false
			elseif f.isActionStop then
					return true
				else
			end
		end
	end
end

BuildBrick.refreshDFIcon = function(self, frame)
	local item = frame.uiitem
	local dstimg = frame.dstimg
	if not dstimg or not item then return end

	local loadui = item.dragrect2
	local w, h = loadui.picload._width, loadui.picload._height
	local ui = loadui.picload:loadMovie(dstimg)
	if ui then
		ui._width = w
		ui._height = h
	end
end

local uiwidth = 130
BuildBrick.refreshDFrameItem = function(self, frame)
	local item = frame.uiitem
	local w = frame.duration * durationRate

	--item.dragrect._width = w
	local selected = self.currentDframe == frame
	item.selected = selected
	item._width = frame.time ~= 0 and w + uiwidth or uiwidth + 100
	item.add.visible = false
	item.addbg.visible = false
	item.del.visible = false
	-- item.del.visible = frame.time ~= 0 and selected
	item.dragrect.visible = true-- frame.time ~= 0
	-- item.dragrect2.visible = frame.time ~= 0
	item.dragrect2.visible = true
	item.dragrect2.selected = selected
	item.title.visible = true
	item.title.text = frame.time .. 'ms'

	local actionshow = not _sys:getGlobal('PCRelease')

	--local uiaction = item.actiontype
	-- uiaction.visible = not _sys:getGlobal('PCRelease')
	item.addaction.visible = actionshow and selected
	item.action.visible = actionshow and frame.actionType and true
	if item.action.visible then
		item.action._icon = 'img://' .. Global.DfActionType[frame.actionType].icon
	end

	local lastactionf = self:findLastActionFrame(frame)

	item.stopstate.visible = actionshow and frame.isActionStop and true

	item.state.visible = false
	if (lastactionf or frame.actionType) and not frame.isActionStop then
		if not self:findNextActionStop(frame) then
			item.state.visible = true
		end
	end

	self:refreshDFIcon(frame)
end

BuildBrick.refreshDFrameItems = function(self)
	for i, v in ipairs(self.DfFrames) do
		self:refreshDFrameItem(v)
	end

	self:updateFrameListSize()
end

BuildBrick.updateFrameListSize = function(self)
	local ui = self.ui.dfs
	local maxsize = 1600
	local w = durationStep * durationRate --uiwidth + durationStep * durationRate
	for i, v in ipairs(self.DfFrames) do
		w = w + v.uiitem._width
	end
	ui.frames._width = math.min(maxsize, w)
end

BuildBrick.refreshFrameList = function(self)
	local ui = self.ui.dfs

	ui.frames.onRenderItem = function(index, item)
		local frame = self.DfFrames[index]
		if frame then
			frame.uiitem = item
			self:refreshDFrameItem(frame)
		end

		item.dragrect2.onMouseDown = function(args)
			self:stopDFrame()
			if frame then
				item.dragingData = {x = args.mouse.x, oldwidth = item.dragrect._width, listw = ui.frames._width}
			end
		end

		item.dragrect2.onMouseMove = function(args)
			local movedelta = 10
			if frame and item.dragingData then
				local data = item.dragingData
				local moved = data.moved or math.abs(args.mouse.x - data.x) > movedelta
				if moved then
					data.moved = true
					ui.frames.scrollable = false

					if _sys:isKeyDown(_System.KeyShift) or data.dragui then
						if not data.dragui then
							--local dragui = self.ui:loadMovie(frame.dstimg)
							local dragui = self.ui:loadView('dfbutton')
							local u = dragui.picload:loadMovie(frame.dstimg)
							u._width = item.dragrect2.picload._width
							u._height = item.dragrect2.picload._height
							dragui._x = args.mouse.x - ui._width / 2
							-- dragui._y = args.mouse.y - item._height / 2
							data.dragui = dragui
						end

						data.dragui._x = args.mouse.x - item._width / 2
						data.dragui._y = args.mouse.y - item._height / 2
					elseif frame.time ~= 0 then
						local extralw = ui.frames._width < ui._width and (ui.frames._width - data.listw) / 2 or 0
						local newwidth = data.oldwidth + (args.mouse.x - data.x) + extralw
						local minw = durationStep * durationRate
						newwidth = math.floatRound(newwidth, minw, 0)
						newwidth = math.max(minw, newwidth)
						frame.duration = newwidth / durationRate
						self:updateDFramesTime()
						self:refreshDFrameItems()
					end
				end
			end
		end

		item.dragrect2.onMouseUp = function(args)
			if frame and item.dragingData and item.dragingData.moved then
				local data = item.dragingData
				if data.dragui then
					local newindex = -1
					local scalef = Global.UI:getScale()
					local x = args.mouse.x * scalef
					for i, v in ipairs(self.DfFrames) do
						local u = v.uiitem
						local r = u:getMCRect()
						if x >= r.p1.x and x <= r.p2.x then
							newindex = i
						end
					end

					item.dragingData = nil
					ui.frames.scrollable = true
					data.dragui:removeMovieClip()

					print('newindex', index, newindex)
					if newindex ~= -1 then
						table.remove(self.DfFrames, index)
						table.insert(self.DfFrames, newindex, frame)
						self:updateDFramesTime()
						self:setTransitionDirty()
						self:refreshFrameList()
						self:onSelectDFrame(frame)
					end
				else
					item.dragingData = nil
					self:updateDFramesTime()
					ui.frames.scrollable = true

					self:refreshDFrameItems()
					self:setTransitionDirty()
				end
			end
		end

		item.dragrect2.click = function()
			self:stopDFrame()
			if frame then
				self:onSelectDFrame(frame)
			-- else
			-- 	self:onSelectDFrame(self.DfFrames[1])
			end
		end

		-- local uiaction = item.actiontype
		item.addaction.click = function()
			self:stopDFrame()
			local p = item.addaction:local2Global(0, 0)
			local isright = p.x < _rd.w / 2
			self:showFrameActionList(frame, isright)
		end

		item.state.click = function()
			self:stopDFrame()
			frame.isActionStop = true
			self:refreshDFrameItems()
			self:setTransitionDirty()
		end

		item.stopstate.click = function()
			self:stopDFrame()
			frame.isActionStop = false
			self:refreshDFrameItems()
			self:setTransitionDirty()
		end
	end
	ui.frames.itemNum = #self.DfFrames
	ui.play.disabled = #self.DfFrames <= 1

	self:updateFrameListSize()
	-- if not self.currentDframe then
	-- 	self:onSelectDFrame(self.DfFrames[1])
	-- end
end
BuildBrick.updateTransitionText = function(self)
	self.ui.showtransition.txt.visible = self.dfEditing
	if self.dfEditing then
		local index = table.findIndex(self.DfFrames, self.currentDframe)
		self.ui.showtransition.txt.text = '#' .. index
	end
end

BuildBrick.onSelectDFrame_base = function(self, frame)
	local ui = self.ui.dfs
	if frame then
		self.dfEditing = true
		ui.all.selected = false
		ui.copybutton.visible = true
		ui.delbutton.visible = true
		self.currentDframe = frame
		self:applyDFrame(frame)
		self:refreshDFrameItems()
	else
		self:stopDFrame()

		self.currentDframe = nil
		self:refreshDFrameItems()
		self.dfEditing = false
		self:goFristFrame()
		self.ui.dfs.all.selected = true
		ui.copybutton.visible = false
		ui.delbutton.visible = false
	end

	self:changeTranspanetMode(not self.isPlayingDframe)

	self:updateTransitionText()
end

BuildBrick.onSelectDFrame = function(self, frame)
	local index1 = table.findIndex(self.DfFrames, frame)
	local index2 = table.findIndex(self.DfFrames, self.currentDframe)

	print('onSelectDFrame', index1, index2)

	if not index1 and index2 then
		self:cmd_showDfs(false, index2) -- 关闭动画
	elseif index1 and not index2 then
		self:cmd_showDfs(true, index1) -- 开始动画
	else
		self:onSelectDFrame_base(frame) -- 动画切帧
	end
end

BuildBrick.isBlockDynamic = function(self, b)
	return self.DfBlocks and self.DfBlocks[b] and true
end

BuildBrick.addBlockAttrDynamic = function(self, b, attr)
	if not self.DfBlocks[b] then self.DfBlocks[b] = {} end
	if not self.DfBlocks[b][attr] then
		self.DfBlocks[b][attr] = true
		self:initFrameValue(b, attr)

		return true
	end
end

BuildBrick.enumDfBlocksAttr = function(self, f)
	if not self.DfBlocks then return end
	for b, attrs in pairs(self.DfBlocks) do
		for attr in pairs(attrs) do
			f(b, attr)
		end
	end
end

BuildBrick.clearDfData = function(self)
	self.DfFrames = {}
	self.DfFrames[1] = {time = 0, data = {}, duration = defaultDuration}
	self.DfBlocks = {}
	self.currentDframe = nil

	self:refreshFrameList()
end

BuildBrick.recoverBlockDfData = function(self, b)
	if not b.dfdata_recover then return end

	local frames = self.DfFrames
	for i, v in ipairs(b.dfdata_recover) do
		local f = frames[v.index]
		local data = v.data
		if f and data then
			for attr, value in pairs(data) do
				self:addDFFrameData(f, attr, b, value)
			end
		end
	end
end

BuildBrick.delDynamicBlock = function(self, b)
	if not self.DfBlocks or not self.DfBlocks[b] then return end

	local dfdata = {}
	for i, f in ipairs(self.DfFrames) do
		if f.data[b] then
			table.insert(dfdata, {index = i, data = f.data[b]})
		end
	end
	b.dfdata_recover = dfdata

	self.DfBlocks[b] = nil
	for i, f in ipairs(self.DfFrames) do
		f.data[b] = nil
	end

	if self:getBlockCount() == 0 then
		-- self:clearDfData()
	end

	self:setTransitionDirty()
end

BuildBrick.delDynamicBlockAttr = function(self, b, attr)
	if not self.DfBlocks or not self.DfBlocks[b] or not self.DfBlocks[b][attr] then return end

	self.DfBlocks[b][attr] = nil
	for i, f in ipairs(self.DfFrames) do
		f.data[b][attr] = nil
	end

	self:setTransitionDirty()
end

-- BuildBrick.addGroupAttrDynamic = function(self, group, attr)
-- 	local md5 = group:md5()
-- 	if not self.DfGroups then self.DfGroups = {} end
-- 	if not self.DfGroups[md5] then self.DfGroups[md5] = {g = group, attrs = {}} end
-- 	local t = self.DfGroups[md5]
-- 	t.attrs[attr] = true
-- end
BuildBrick.addDFFrameDatas = function(self, f, attr, bs, value, mode)
	-- local logic = LogicBlockGroup.new(bs)
	-- self:addGroupAttrDynamic(logic, attr)
	-- print('addDFFrameDatas', #bs, value)

	for i, b in ipairs(bs) do
		if attr == 'transforms' then
			local pivot = value
			local pmat = PivotMat.new(b.node.transform)
			local pmat0 = self:getFrameData(f, b, 'transform')
			if mode == 'rot' or mode == 'rotpivot' then
				if pivot then
					helpmat:set(b.node.transform)
					helpmat:inverse()
					local p = _Vector3.new()
					p:set(pivot)
					helpmat:apply(p, p)
					pmat.pivot = p
				else
					pmat.pivot = nil
				end
			else
				pmat.pivot = pmat0 and pmat0.pivot
			end

			self:addDFFrameData(f, 'transform', b, pmat)
			--print('!!!mode', mode, pmat.pivot, pivot)
			--self:addDFFrameData(f, 'transform', b, PivotMat.new(b.node.transform, pivot))
		elseif attr == 'materials' then
			local lmtl = LerpMaterial.new(value[i])
			self:addDFFrameData(f, 'material', b, lmtl)
		else
			self:addDFFrameData(f, attr, b, value)
		end
	end
end

BuildBrick.addDFFrameData = function(self, f, attr, b, value)
	-- assert(f.iskey)
	--self.DfBlocks[b] = true

	local ret = self:addBlockAttrDynamic(b, attr)
	local bdata = f.data[b]
	local curvalue = bdata[attr]

	assert(curvalue ~= nil)

	self:setFrameAttrValue(f, b, attr, value)
	self:setTransitionDirty()

	return ret
end

BuildBrick.setTransitionDirty = function(self)
	self.DfTransitionDirty = true
end

BuildBrick.getMd5ValueFromFrame0 = function(self, b, attr, f1)
	local f0 = self.DfFrames[1]
	local v0 = self:getFrameData(f0, b, attr)
	local v1 = self:getFrameData(f1, b, attr)

	if attr == 'transform' then
		if f0 == f1 then
			return PivotMat.new(), 0
		else
			local pm = PivotMat.diffFromTo(v0, v1)
			-- print('getMd5ValueFromFrame0', b, pm:tostring())
			return pm, 't_' .. pm:md5()
		end
	elseif attr == 'alpha' then
		local md5 = 'a_' .. (v0 * 1000 + v1)
		return v1, md5
	elseif attr == 'material' then
		local md5 = 'm_' .. v1:md5() .. v0.color
		return v1, md5
	elseif attr == 'paint' then
		return v1, 'p_' .. v1:md5()
	end
end

BuildBrick.updateTranslations = function(self)
	local f0 = self.DfFrames[1]

	local bs = {}
	self:enumDfBlocksAttr(function(b, attr)
		for i = 1, #self.DfFrames do
			local f = self.DfFrames[i]
			local value, md5 = self:getMd5ValueFromFrame0(b, attr, f)

			-- 按block排序
			if not bs[b] then bs[b] = {} end
			if not bs[b][attr] then bs[b][attr] = {} end
			if not bs[b][attr][i] then
				bs[b][attr][i] = {value = value, md5 = md5}
			end
		end
	end)

	local ts = {}
	for b, v in pairs(bs) do
		for attr, vv in pairs(v) do
			local md5 = ''
			for fi, data in ipairs(vv) do
				md5 = md5 .. data.md5
			end

			if not ts[md5] then
				local t = {}
				t.group = LogicBlockGroup.new()
				t.frames = {}
				t.oldattr = attr
				if attr == 'transform' then
					t.attr = 'transformDiff'
				else
					t.attr = attr
				end
				ts[md5] = t

				-- 添加帧信息
				for fi, data in ipairs(vv) do
					local f = self.DfFrames[fi]

					local frame = {}
					frame.time = f.time
					frame.istween = true
					frame.value = data.value
					table.insert(t.frames, frame)
				end
			end

			local t = ts[md5]
			t.group:addChild(b)

			-- 报错检查
			if attr ~= t.oldattr then
				print('attr111', attr, t.oldattr, md5)
				assert(false)
			end

			local v0 = self:getFrameData(f0, b, t.oldattr)
			if v0 == nil then
				print('attr222', attr, t.oldattr, md5)
				assert(false)
			end
		end
	end

	return ts
end
BuildBrick.getFrameCenter = function(self, f, g, center, mats)
	local nbs = g:getBlocks()

	local ab1 = Container:get(_AxisAlignedBox)
	ab1:initBox()

	local ab2 = Container:get(_AxisAlignedBox)
	for i, b in ipairs(nbs) do
		local v0 = self:getFrameData(f, b, 'transform')
		local mat = v0:getMatrix()

		b.node:getAABB(ab2, mat)
		_AxisAlignedBox.union(ab2, ab1, ab1)
		if mats then table.insert(mats, mat) end
	end

	ab1:getCenter(center)

	Container:returnBack(ab1, ab2)
end
BuildBrick.updateTransitionByDFrames = function(self)
	if not self.DfTransitionDirty then return end

	local times = {}
	local actions = {}
	local action
	for i, f in ipairs(self.DfFrames) do
		table.insert(times, f.time)
		if f.actionType then
			if action then
				local lastf = self.DfFrames[i - 1]
				action.timeEnd = lastf.time
				actions[action.type] = action
			end
			action = {type = f.actionType, isloop = f.isActionLoop, timeStart = f.time}
		end

		if action and (f.isActionStop or i == #self.DfFrames) then
			action.timeEnd = f.time
			actions[action.type] = action
			action = nil
		end
	end

	local t1 = _tick()
	local ts = self:updateTranslations()
	local t2 = _tick()

	-- local df = self.dynamicEffects[1]
	-- df.transitions = {}
	-- df.actions = actions

	local transitions = {}
	local f0 = self.DfFrames[1]
	local helpscale = _Vector3.new()
	local helprot = _Vector3.new()
	local helptranslation = _Vector3.new()
	local helppivot = _Vector3.new()

	for md5, t in pairs(ts) do
		-- table.insert(df.transitions, t) -- 用于存储到文件
		local dft = DfTransition.new(t)

		-- 初始化mats
		if t.attr == 'transformDiff' then

			local initcenter = _Vector3.new()
			local mats = {}
			self:getFrameCenter(f0, t.group, initcenter, mats)
			dft:initGroupMatrix(mats, initcenter)

			-- 重组mat
			for ii, f in ipairs(t.frames) do
				local value = f.value
				local mat = value:getMatrix()
				local p = value:getPivot()

				if p then
					helpmat:set(mat)
					helpmat:inverse()
					helpmat:apply(p, p)

					helppivot:set(p)
					_Vector3.sub(p, initcenter, p)
				else
					helppivot:set(initcenter)
				end
				mat:decomposeWithPivot(helppivot, helpscale, helprot, helptranslation)
				mat:setTransformData(helptranslation.x, helptranslation.y, helptranslation.z,
					helprot.x, helprot.y, helprot.z, helpscale.x, helpscale.y, helpscale.z)

				--mat:composeWithPivotLerp(1, nil, helpscale, helprot, helptranslation)

				-- print('helpscale', ii, helpscale)
				-- print('helprot', ii, helprot)
				-- print('helptranslation', ii, helptranslation, pivot, value:getPivot())
				-- print('mat2222', ii, pivot, mat)
			end
		end

		table.insert(transitions, dft)
	end
	local t3 = _tick()
	print('updateTransition cost', t2 - t1, t3 - t2)
	print('updateTransitionByDFrames', #transitions, transitions[1] and #(transitions[1].frames))

	self.DFPlayer:setDuration(0)
	self.DFPlayer:setTransitions(transitions)
	self.DFPlayer:setActions(actions)

	--print('self.DFPlayer', self.DFPlayer:tostring())

	self.DfTransitionDirty = false
end

BuildBrick.updateCurrentDFrame = function(self)
	if self.currentDframe and self.dfEditing then
		self:setTransitionDirty()
		self:applyDFrame(self.currentDframe)
	end
end

BuildBrick.applyDFrame = function(self, f)
	--if not self.lastFrameTime then self.lastFrameTime = 0 end

	-- 记录node当前的位置
	-- if self.lastFrameTime == 0 then
	-- 	local nbs = {}
	-- 	self:getBlocks(nbs)
	-- 	for i, b in ipairs(nbs) do
	-- 		b:updateSpace()
	-- 	end
	-- end

	self:updateTransitionByDFrames()

	--print('applyDFrame', f.time, self.DFPlayer:tostring())
	print('applyDFrame', f.time)
	self.DFPlayer:setTick(f.time, true)

	-- self.lastFrameTime = f.time

	self:refreshModuleIcon()
end

BuildBrick.changeTranspanetMode = function(self, show)
	if Global.showTranspanetDummy == show then return end
	Global.showTranspanetDummy = show

	-- 隐藏的积木重置隐藏的效果
	local bs = {}
	self:getBlocks(bs, function(b)
		if not b:getBuildVisiable() then
			b:setBuildVisiable(false)
		end
	end)
end

BuildBrick.playDFrame = function(self)
	if self.isPlayingDframe then return end

	-- 清空选中
	-- self:cmd_select_begin()
	-- self:cmd_select_end()

	self:updateTransitionByDFrames()

	self.DFPlayer:setTick(0)
	self.DFPlayer:play()
--	self.DFPlayer:stop(true)

	self.isPlayingDframe = true

	self:changeTranspanetMode(false)

	local ui = self.ui.dfs
	-- ui.frames.hitTestDisable = true
	-- ui.all.hitTestDisable = true
	ui.play.selected = true
	-- self:showDisableBg(true)
	-- self:ui_flush_undo()
end

BuildBrick.stopDFrame = function(self)
	if not self.isPlayingDframe then return end
	self.isPlayingDframe = false

	self:updateTransitionByDFrames()
	self.DFPlayer:stop()

	self:changeTranspanetMode(true)

	if not self.currentDframe then
		self:onSelectDFrame_base()
	else
		self:onSelectDFrame_base(self.currentDframe)
	end

	local ui = self.ui.dfs
	-- ui.frames.hitTestDisable = false
	-- ui.all.hitTestDisable = false
	ui.play.selected = false
	-- self:showDisableBg(false)
	-- self:ui_flush_undo()

	local nbs = {}
	self:getBlocks(nbs)
	for i, b in ipairs(nbs) do
		if b.markerdata then
			b.markerdata:enableMarker(false)
		end
	end
end

BuildBrick.getFirstFrame = function(self, frame)
	return self.DfFrames[1]
end

BuildBrick.goFristFrame = function(self, frame)
	self:applyDFrame(self.DfFrames[1])
end

BuildBrick.isCurrentFirstFrame = function(self)
	assert(self.currentDframe)
	return self.currentDframe.time == 0
end

BuildBrick.getCurrentFrame = function(self)
	return self.currentDframe
end

BuildBrick.getDFFrames = function(self)
	return self.DfFrames
end
