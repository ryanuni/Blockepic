local Container = _require('Container')
local BuildBrick = _G.BuildBrick

BuildBrick.updateMarkerTrainPos = function(self, block)
	local y = 0
	local vec = Container:get(_Vector3)
	for i, m in ipairs(block.bindmodules) do
		local ab = _AxisAlignedBox.new()
		ab:set(m:getInitAABB())
		ab:getBottom(vec)
		vec.y = ab.min.y

		if not m.disable then
			for b in pairs(m.train_bs) do
				local diff = m.train_movey
				b.node.transform:mulTranslationRight(-diff.x, -diff.y, -diff.z)
				b.node.transform:mulTranslationRight(-vec.x, y - vec.y, -vec.z)
			end
		end

		m.train_movey = _Vector3.new(-vec.x, y - vec.y, -vec.z)
		y = y + (ab.max.y - ab.min.y)
	end
end

BuildBrick.updateMarkerTrain = function(self, block)
	local mdata = block.markerdata
	if not mdata or mdata.type ~= 'marker_train' then return end

	-- print('updateMarkerTrain', mdata.name, debug.traceback())

	if block.bindmoduleBlocks then
		for v in pairs(block.bindmoduleBlocks) do
			self.sen:delBlock(v)
		end

		block.bindmoduleBlocks = nil
	end

	local allbs = {}
	local y = 0
	-- local ab = Container:get(_AxisAlignedBox)
	local vec = Container:get(_Vector3)
	local ms = {}
	for i, v in ipairs(mdata.trains or {}) do
		local m
		if v.module then
			if v.module.typestr == 'SceneModule' then
				m = v.module
			else
				m = Global.SceneModule.new(v.module)
			end
		elseif v.shape then
			local data0 = Block.loadItemData(v.shape)
			--m = Global.SceneModule.new(data)
			local data = {blocks = {}}
			table.insert(data.blocks, v)
			data.funcflags = data0.funcflags

			m = Global.SceneModule.new(data)
		end
		v.module = m

		table.insert(ms, m)
		if v.pickFlag == 0 then
			m.disable = true
			--m.pickFlag = v.pickFlag
		end
		local bs = self:dragModuleToScene(m)

		local ab = _AxisAlignedBox.new()
		ab:set(m:getInitAABB())
		ab:getBottom(vec)
		vec.y = ab.min.y

		-- b.node.transform:mulTranslationRight(-vec.x, y - vec.y, -vec.z)
		for _, b in ipairs(bs) do
			if v.pickFlag then
				b:setPickFlag(v.pickFlag)
			end
			b.node.transform:mulTranslationRight(-vec.x, y - vec.y, -vec.z)
			b.isdummyblock = true
			-- b.node.transform.parent = block.node.transform
			b.node.transform:mulRight(block.node.transform)
			b.bindTrain = block
			b.trainmodule = m
			-- b.traindata = v
			-- b.trainindex = i
			table.insert(allbs, b)
		end

		m.train_movey = _Vector3.new(-vec.x, y - vec.y, -vec.z)
		-- m.train_sizey = (ab.max.y - ab.min.y)
		m.train_bs = {}
		table.farray2Hash(bs, m.train_bs)
		-- ab.min.y = ab.min.y + y
		-- ab.max.y = ab.max.y + y
		-- ab:mul(block.node.transform)
		-- m:setAABB(ab)

		-- print('y', i, y, (ab.max.y - ab.min.y), value2string(ab))
		y = y + (ab.max.y - ab.min.y)
	end
	local bshash = {}
	table.farray2Hash(allbs, bshash)
	block.bindmoduleBlocks = bshash
	block.bindmodules = ms

	Container:returnBack(vec)

	print('updateMarkerTrain', block, #allbs)
end

BuildBrick.getMuduleByIndex = function(self, index, isrunray)
	local block = isrunray and self.train_runway or self.train_pole
	return block.bindmodules[index]
end

BuildBrick.getTrainBlocksByMudule = function(self, m, isrunray, bs)
	if not bs then bs = {} end
	local block = isrunray and self.train_runway or self.train_pole
	for b in pairs(block.bindmoduleBlocks) do
		if b.trainmodule == m then
			table.insert(bs, b)
		end
	end

	return bs
end

BuildBrick.isMusicMode = function(self, mode)
	return self:getParam('scenemode') == 'scene_music' and self.musicmode == mode
end

BuildBrick.goMusicMode = function(self, mode)
	self.musicmode = mode
	self:recoverPickState()
	self:cmd_select_begin()
	self:cmd_select_end()

	local nbs = {}
	self:getBlocks(nbs)
	if mode == 'music_bg' then
		for i, v in ipairs(nbs) do
			if (v.markerdata and v.markerdata.type == 'marker_train') then
				if v.bindmoduleBlocks then
					for b in pairs(v.bindmoduleBlocks) do
						--b.node.visible = false
						b:setVisibleAndQuery(false)
					end
				end
			else
				v:setVisibleAndQuery(true)
				--v.node.visible = true
			end
		end

		self:addBackClickCb('onlyback', function()
			self:goMusicMode('music_main')
		end)

		Global.AddHotKeyFunc(_System.KeyESC, function()
			return self.musicmode == 'music_bg'
		end, function()
			self:clickBackCb()
		end)

		self.knotMode = Global.KNOTPICKMODE.NONE
		self.enableDragSelect = true
	elseif mode == 'music_train' then
		for i, v in ipairs(nbs) do
			if (v.markerdata and v.markerdata.type == 'marker_train') then
				if v.bindmoduleBlocks then
					for b in pairs(v.bindmoduleBlocks) do
						--b.node.visible = true
						b:setVisibleAndQuery(true)
					end
				end
			else
				v:setVisibleAndQuery(false)
				--v.node.visible = false
			end
		end

		self.music_dummys = {}
		self:addBackClickCb('onlyback', function()
			self:goMusicMode('music_main')
			for b in pairs(self.music_dummys) do
				self:atom_block_del(b)
			end
			self.music_dummys = {}
		end)

		Global.AddHotKeyFunc(_System.KeyESC, function()
			return self.musicmode == 'music_train'
		end, function()
			self:clickBackCb()
		end)

		self.knotMode = Global.KNOTPICKMODE.SPECIAL
		self.enableDragSelect = false
	elseif mode == 'music_main' then
		for i, v in ipairs(nbs) do
			if (v.markerdata and v.markerdata.type == 'marker_train') then
				if v.bindmoduleBlocks then
					for b in pairs(v.bindmoduleBlocks) do
						b:setVisibleAndQuery(true)
					end
				end
			else
				v:setVisibleAndQuery(true)
				--v.node.visible = true
			end
		end

		self.knotMode = Global.KNOTPICKMODE.NONE
		self:camera_focus(nil, 1, 30)

		self.enableDragSelect = false
	end

	self.multiSelecting = false
	self.dragSelecting = false
	self:showMultiSelectPanel(false)
end

BuildBrick.setMusicDummy = function(self, b)
	if not self.music_dummys then
		self.music_dummys = {}
	end

	b.isdummyblock = true
	b.musicdummy = true
	self.music_dummys[b] = true
end

BuildBrick.clearBlockToMusicModule = function(self, b)
	if b.bindTrain then
		self:addBlockToMusicModule(b, nil, b.bindTrain)
		self.music_dummys[b] = nil
	end
end

BuildBrick.addBlockToMusicModule = function(self, b, m, train)
	local om = b.trainmodule
	if om and om == m then return end
	if om then
		om.train_bs[b] = nil
	end

	if m then
		m.train_bs[b] = true

		b.musicdummy = false
		self.music_dummys[b] = nil
		train.bindmoduleBlocks[b] = true
		b.bindTrain = train
	else
		b.musicdummy = true
		self.music_dummys[b] = true
		train.bindmoduleBlocks[b] = nil
		b.bindTrain = nil
	end

	b.trainmodule = m
end

BuildBrick.getMusicFloorShape = function(self)
	return self.musicFloorMode == 1 and 'music_floor1' or 'music_floor0'
end

BuildBrick.isBuildModeMusic = function(self)
	return self:getParam('scenemode') == 'scene_music'
end

BuildBrick.getMusicPoleShape = function(self)
	return 'music_steps'
end

BuildBrick.isFloorBlock = function(self, b)
	return b:getShape() == self:getMusicFloorShape()
end

BuildBrick.isPoleBlock = function(self, b)
	return b:getShape() == self:getMusicPoleShape()
end

local runwayHalfWidth = 4
BuildBrick.checkMusicCollision = function(self, ab, mode)
	local trainblock = mode == 'runway' and self.train_runway or self.train_pole
	local checkshape = mode == 'runway' and self:getMusicFloorShape() or self:getMusicPoleShape()

	local helpab = _AxisAlignedBox.new()
	for i, m in ipairs(trainblock.bindmodules) do if not m.disable then
		for bb in pairs(m.train_bs) do
			if bb:getShape() == checkshape then
				if mode == 'runway' then
					bb:getAlignedShapeAABB(helpab)
					-- print('helpab', value2string(helpab))
					local cx = (helpab.max.x + helpab.min.x) / 2
					helpab.min.x = cx - runwayHalfWidth
					helpab.max.x = cx + runwayHalfWidth

					-- print('helpab2', cx, value2string(helpab))
				else
					bb:getShapeAABB(helpab)
				end

				if ab:checkIntersect(helpab) then
					return m
				end
			end
		end
	end end

	return nil
end

BuildBrick.isBarrierBlock = function(self, b)
	local obj = Global.GetClientObject(b:getShape())
	return obj and (obj.stype == 'barrier' or obj.stype == 'decoration')
end

BuildBrick.isInstrumentBlock = function(self, b)
	local obj = Global.GetClientObject(b:getShape())
	return obj and (obj.stype == 'instrument' or obj.stype == 'piano' or obj.stype == 'harp' or obj.stype == 'guitar' or obj.stype == 'violin')
end

BuildBrick.getMusicFloors = function(self, nbs)
	if not nbs then
		nbs = {}
		for b in pairs(self.train_runway.bindmoduleBlocks) do
			table.insert(nbs, b)
		end
	end
	local bs = {}
	for _, b in ipairs(nbs) do
		if self:isFloorBlock(b) then
			table.insert(bs, b)
		end
	end

	return bs
end

BuildBrick.getMusicPoles = function(self, nbs)
	if not nbs then
		nbs = {}
		for b in pairs(self.train_pole.bindmoduleBlocks) do
			table.insert(nbs, b)
		end
	end

	local bs = {}
	for _, b in ipairs(nbs) do
		if self:isPoleBlock(b) then
			table.insert(bs, b)
		end
	end

	return bs
end

BuildBrick.checkMusicDummy = function(self)
	if not self:isMusicMode('music_train') or #self.rt_selectedBlocks == 0 then return end

	for _, b in ipairs(self.rt_selectedBlocks) do
		if not b.musicdummy and not b.bindTrain then return end

		local trainblock
		if self:isBarrierBlock(b) then
			trainblock = self.train_runway
		elseif self:isInstrumentBlock(b) then
			trainblock = self.train_pole
		end

		local ab = b:getShapeAABB2(true)
		local mode = trainblock == self.train_runway and 'runway' or 'pole'
		local m = self:checkMusicCollision(ab, mode)
		if m then
			self:addBlockToMusicModule(b, m, trainblock)
			-- print('checkMusicDummy checkdone', mode, m.index)
		else
			self:addBlockToMusicModule(b, nil, trainblock)
		end
	end
end

BuildBrick.isSelectedMusicRunway = function(self)
	if #self.rt_selectedBlocks == 0 then return false end

	for i, v in ipairs(self.rt_selectedBlocks) do
		if not self:isFloorBlock(v) then
			return false
		end
	end

	return true
end

BuildBrick.isSelectedMusicPole = function(self)
	if #self.rt_selectedBlocks == 0 then return false end

	for i, v in ipairs(self.rt_selectedBlocks) do
		if not self:isPoleBlock(v) then
			return false
		end
	end

	return true
end

BuildBrick.isSelectedMusicSpecial = function(self)
	for i, v in ipairs(self.rt_selectedBlocks) do
		if self:isPoleBlock(v) or self:isFloorBlock(v) or self:isInstrumentBlock(v) then
			return true
		end
	end

	return false
end

-- TODO:
BuildBrick.saveMusicData = function(self)
	local runway = self.train_runway
	local pole = self.train_pole

	for i, m in ipairs(runway.bindmodules) do
		if not m.disable then
			m.blocks = {}
			for b in pairs(m.train_bs) do
				local p = b.node.transform.parent
				b.node.transform:rebindParent(runway.node.transform)
				b.node.transform.parent = nil

				local data = Global.saveBlockData(b, m.train_movey)
				table.insert(m.blocks, data)

				b.node.transform.parent = runway.node.transform
				b.node.transform:rebindParent(p)
			end
		end
	end

	for i, m in ipairs(pole.bindmodules) do
		m.blocks = {}
		for b in pairs(m.train_bs) do
			local p = b.node.transform.parent
			b.node.transform:rebindParent(pole.node.transform)
			b.node.transform.parent = nil

			local data = Global.saveBlockData(b, m.train_movey)
			table.insert(m.blocks, data)

			b.node.transform.parent = pole.node.transform
			b.node.transform:rebindParent(p)
		end
	end
end

BuildBrick.getMusicPolesByRunwayIndex = function(self, index)
	if index == 1 then return end

	local start = (index - 2) * 8
	local pole_ms = self.train_pole.bindmodules
	local ms = {}
	for i = 1, 8 do
		local m = pole_ms[start + i]
		table.insert(ms, m)
	end

	return ms, start
end

-- TODO: save module
BuildBrick.updateMusicModuleIndex = function(self, ms)
	for i, m in ipairs(ms) do
		m.index = i
	end
end

BuildBrick.createMusicTrain = function(self, m, createmode)
	local t = {module = m:clone()}
	if createmode == 'newrunway' then
		t.module.blocks = {{shape = self:getMusicFloorShape()}}
	elseif createmode == 'newpole' then
		t.module.blocks = {{shape = self:getMusicPoleShape()}}
	end
	return t
end

BuildBrick.copyMusicRunway = function(self, bs, copy)
	self:saveMusicData()

	local runway = self.train_runway
	local pole = self.train_pole

	local runway_ms = runway.bindmodules
	self:updateMusicModuleIndex(runway_ms)
	self:updateMusicModuleIndex(pole.bindmodules)

	local movems = {}
	for _, b in ipairs(bs) do
		if self:isFloorBlock(b) and b.trainmodule then
			local m = b.trainmodule
			if m.index ~= 1 and m.index ~= #runway_ms then
				table.insert(movems, m)
			end
		end
	end
	if #movems == 0 then return end

	table.sort(movems, function(a, b)
		return a.index < b.index
	end)

	-- local runway_mdata = runway.markerdata
	local startindex = movems[#movems].index
	local copyindex = {}
	for i, m in ipairs(movems) do

		local t = self:createMusicTrain(m, not copy and 'newrunway')
		table.insert(runway.markerdata.trains, startindex + i, t)
		table.insert(copyindex, startindex + i)

		local pole_ms, sindex = self:getMusicPolesByRunwayIndex(m.index)
		if pole_ms then
			for ii, pm in ipairs(pole_ms) do
				local pt = self:createMusicTrain(pm, not copy and 'newpole')
				table.insert(pole.markerdata.trains, sindex + ii + 8 * #movems, pt)
			end
		end
	end

	self:updateMarkerTrain(runway)
	self:updateMarkerTrain(pole)
	self:updateMusicModuleIndex(runway.bindmodules)
	self:updateMusicModuleIndex(pole.bindmodules)

	local selbs = {}
	for i, index in ipairs(copyindex) do
		local m = self:getMuduleByIndex(index, true)
		self:getTrainBlocksByMudule(m, true, selbs)
		print('selbs', #selbs)
	end

	local gs = {}
	for i, b in ipairs(selbs) do
		-- print('bs', i, b)

		if self:isFloorBlock(b) then
			table.insert(gs, b:getBlockGroup())
		end
	end
	self:atom_group_select_batch(gs)
end

BuildBrick.delMusicRunway = function(self, bs)
	self:saveMusicData()

	local runway = self.train_runway
	local pole = self.train_pole

	local runway_ms = runway.bindmodules
	self:updateMusicModuleIndex(runway_ms)
	self:updateMusicModuleIndex(pole.bindmodules)

	local movems = {}
	for _, b in ipairs(bs) do
		if self:isFloorBlock(b) and b.trainmodule then
			local m = b.trainmodule
			if m.index ~= 1 and m.index ~= #runway_ms then
				table.insert(movems, m)
			end
		end
	end
	if #movems == 0 then return end

	table.sort(movems, function(a, b)
		return a.index > b.index
	end)

	for i, m in ipairs(movems) do
		table.remove(runway.markerdata.trains, m.index)

		local pole_ms, sindex = self:getMusicPolesByRunwayIndex(m.index)
		if pole_ms then
			for ii, pm in ipairs(pole_ms) do
				table.remove(pole.markerdata.trains, sindex + 1)
			end
		end
	end

	self:updateMarkerTrain(runway)
	self:updateMarkerTrain(pole)
	self:updateMusicModuleIndex(runway.bindmodules)
	self:updateMusicModuleIndex(pole.bindmodules)

	self:atom_group_select()
end

BuildBrick.copyMusicPole = function(self, bs, copy)
	-- assert(b:getShape() ~= 'music_steps' and b.trainmodule)
	self:saveMusicData()

	local pole = self.train_pole

	local pole_ms = pole.bindmodules
	self:updateMusicModuleIndex(pole_ms)

	local movems = {}
	for _, b in ipairs(bs) do
		if self:isPoleBlock(b) and b.trainmodule then
			local m = b.trainmodule
			table.insert(movems, m)
		end
	end
	print('copyMusicPole', #movems)
	if #movems == 0 then return end

	table.sort(movems, function(a, b)
		return a.index < b.index
	end)

	-- local n = #pole.markerdata.trains
	local startindex = movems[#movems].index
	local copyindex = {}
	for i, m in ipairs(movems) do
		local t = self:createMusicTrain(m, not copy and 'newpole')
		table.insert(pole.markerdata.trains, startindex + i, t)
		table.remove(pole.markerdata.trains)

		table.insert(copyindex, startindex + i)
	end

	self:updateMarkerTrain(pole)
	self:updateMusicModuleIndex(pole_ms)

	local selbs = {}
	for i, index in ipairs(copyindex) do
		local m = self:getMuduleByIndex(index, false)
		self:getTrainBlocksByMudule(m, false, selbs)
	end

	local gs = {}
	for i, b in ipairs(selbs) do
		if self:isPoleBlock(b) then
			table.insert(gs, b:getBlockGroup())
		end
	end
	self:atom_group_select_batch(gs)
end

BuildBrick.delMusicPole = function(self, bs)
	self:saveMusicData()

	local pole = self.train_pole

	local pole_ms = pole.bindmodules
	self:updateMusicModuleIndex(pole_ms)

	local movems = {}
	for _, b in ipairs(bs) do
		if self:isPoleBlock(b) and b.trainmodule then
			local m = b.trainmodule
			table.insert(movems, m)
		end
	end

	if #movems == 0 then return end

	table.sort(movems, function(a, b)
		return a.index > b.index
	end)

	local n = #pole.markerdata.trains
	for i, m in ipairs(movems) do
		table.remove(pole.markerdata.trains, m.index)

		local t = self:createMusicTrain(m, 'newpole')
		table.insert(pole.markerdata.trains, t)
	end

	self:updateMarkerTrain(pole)
	self:updateMusicModuleIndex(pole_ms)
	self:atom_group_select()
end

BuildBrick.setMusicTransparent = function(self, block, b, mode)
	block:setSkipped(b, mode)
	-- print('setMusicTransparent', block, skipped)
end

BuildBrick.moveMusciModuleToIndex = function(self, block, m, index)
	if m.index == index then return end
	local trains = block.markerdata.trains
	local ms = block.bindmodules

	local t = trains[m.index]
	table.remove(trains, m.index)
	table.insert(trains, index, t)

	table.remove(ms, m.index)
	table.insert(ms, index, m)

	if block == self.train_runway then
		local ptrains = self.train_pole.markerdata.trains
		local pms = self.train_pole.bindmodules
		self:updateMusicModuleIndex(pms)

		local pole_ms, sindex = self:getMusicPolesByRunwayIndex(m.index)
		local _, sindex2 = self:getMusicPolesByRunwayIndex(index)
		if pole_ms then
			local pole_ts = {}
			for ii, pm in ipairs(pole_ms) do
				table.remove(pms, sindex + 1)

				local pt = table.remove(ptrains, sindex + 1)
				table.insert(pole_ts, pt)
			end

			-- if index > m.index then
			-- 	sindex2 = sindex2 - #pole_ms
			-- end

			for ii, pm in ipairs(pole_ms) do
				table.insert(ptrains, sindex2 + ii, pole_ts[ii])
				table.insert(pms, sindex2 + ii, pm)
			end

			self:updateMusicModuleIndex(pms)
			self:updateMarkerTrainPos(self.train_pole)
		end
	end

	self:updateMusicModuleIndex(ms)
	self:updateMarkerTrainPos(block)

	return true
end

BuildBrick.moveMusicBegin = function(self, block)
	if self.movingMusic then return end

	self:saveMusicData()

	local runway = self.train_runway
	local pole = self.train_pole

	self:updateMusicModuleIndex(runway.bindmodules)
	self:updateMusicModuleIndex(pole.bindmodules)

	local m = block.trainmodule

	local movems = {}
	movems[m] = true

	if block.bindTrain == runway then
		local pole_ms, sindex = self:getMusicPolesByRunwayIndex(m.index)
		if pole_ms then
			for ii, pm in ipairs(pole_ms) do
				movems[pm] = true
			end
		end
	end

	local blocks = {}
	for b in pairs(runway.bindmoduleBlocks) do
		if b.trainmodule and movems[b.trainmodule] then
			local nb = self.sen:cloneBlock2(b)
			nb.isdummyblock = true
			nb.isWall = true
			table.insert(blocks, nb)
		end
	end

	for b in pairs(pole.bindmoduleBlocks) do
		if b.trainmodule and movems[b.trainmodule] then
			local nb = self.sen:cloneBlock2(b)
			table.insert(blocks, nb)
		end
	end

	self.music_dummyBlocks = blocks
	self.music_moveBlock = block
	self.movingMusic = true

	self:atom_block_select(blocks)

	for b in pairs(runway.bindmoduleBlocks) do
		if b.trainmodule and movems[b.trainmodule] then
			self:setMusicTransparent(b, true, 1)
		else
			self:setMusicTransparent(b, true)
		end
	end

	for b in pairs(pole.bindmoduleBlocks) do
		if b.trainmodule and movems[b.trainmodule] then
			self:setMusicTransparent(b, true, 1)
		else
			self:setMusicTransparent(b, true)
		end
	end
end

BuildBrick.moveMusicEnd = function(self)
	if not self.movingMusic then return end

	self:atom_block_select()
	for i, b in ipairs(self.music_dummyBlocks) do
		self.sen:delBlock(b)
	end

	local runway = self.train_runway
	local pole = self.train_pole
	for b in pairs(runway.bindmoduleBlocks) do
		self:setMusicTransparent(b, false)
	end
	for b in pairs(pole.bindmoduleBlocks) do
		self:setMusicTransparent(b, false)
	end

	self.music_dummyBlocks = nil
	self.movingMusic = false
	self.music_moveBlock = nil
end

BuildBrick.onMoveMusic = function(self)
	if not self.movingMusic then return end
	local runway = self.train_runway
	local pole = self.train_pole

	local block = self.music_moveBlock
	local pos = _Vector3.new()
	local y0 = 0
	for i, b in ipairs(self.music_dummyBlocks) do
		if (block.bindTrain == runway and self:isFloorBlock(b)) or (block.bindTrain == pole and self:isPoleBlock(b)) then
			b.node.transform:getTranslation(pos)
			y0 = pos.y
			break
		end
	end

	-- print('block.bindTrain == runway', block.bindTrain == runway)
	local ys = {}
	local mbs = block.bindTrain == runway and runway.bindmoduleBlocks or pole.bindmoduleBlocks
	for b in pairs(mbs) do
		if (block.bindTrain == runway and self:isFloorBlock(b)) or (block.bindTrain == pole and self:isPoleBlock(b)) then
			b.node.transform:getTranslation(pos)
			table.insert(ys, pos.y)
		end
	end

	table.sort(ys, function(a, b)
		return a < b
	end)

	local index = 1
	if y0 < ys[1] then
		index = 1
	elseif y0 > ys[#ys] then
		index = #ys
	else
		for i, y in ipairs(ys) do
			if y > y0 then
				local mid = (ys[i - 1] + y) / 2
				index = y0 > mid and i or i - 1
				break
			end
		end
	end

	-- for i, y in ipairs(ys) do
	-- 	print('y', i, y)
	-- end
	-- print('!!!y0', y0, index)

	if block.bindTrain == runway then
		self:moveMusciModuleToIndex(runway, block.trainmodule, index + 1)
	else
		self:moveMusciModuleToIndex(pole, block.trainmodule, index)
	end
end