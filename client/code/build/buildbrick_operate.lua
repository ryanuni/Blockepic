
local BuildBrick = _G.BuildBrick

------------------------------ rot
local restrictionmat = _Matrix3D.new()
BuildBrick.rotBlockBegin = function(self, args, index, axis, delta, restriction)
	local rotbutton = Global.ui.controler.rolatabutton

	-- 旋转轴限制
	if restriction.enable and restriction.type == 2 then
		rotbutton:addRotdata(0, axis, delta, restriction.axis, true)
	else
		rotbutton:addRotdata(index, axis, delta, nil, true)
	end

	-- 旋转中心限制
	if restriction.enable and (restriction.type == 2 or restriction.type == 3) then
		restrictionmat:setTranslation(restriction.pos)
		--print('!!!!!', restriction.pos)
		self:cmd_mat_update_begin(restrictionmat, 'rotpivot')
	else
		-- if restriction.enablepivot then
		-- 	restrictionmat:setTranslation(restriction.pivot)
		-- 	self:cmd_mat_update_begin(restrictionmat, 'rot')
		-- else
			self:cmd_mat_update_begin(nil, 'rot')
		--end
	end

	rotbutton.onMouseDown(args)
	Global.ui:setControlerVisible(false)
end

BuildBrick.rotBlockEnd = function(self, args)
	if Global.ui.controler.rolatabutton.onMouseUp(args) then
		-- 更新组的matrix
		--self:updateGroupRotData(self.rt_selectedGroups, self.rt_transform)

		self:cmd_mat_update_end()
		self:atom_group_knot_dirty()
		Global.ui.controler.rolatabutton:clearRotdata()

		if self.enableRepair then
			self:checkRepaired()
			self:onCheckRepair()
		end

		return true
	end
end

BuildBrick.rotBlock = function(self, args)
	Global.ui.controler.rolatabutton.onMouseMove(args)

	self:atom_group_dirty()
	if self.enableRepair then self:checkRepaired() end
end

------------------------------ move

BuildBrick.onMovingBlock = function(self)
	-- self:showFrequent(false)
	-- self:showRotHint(false)
	-- self:showMovHint(false)

	-- self.ui.multiselect.visible = false
	-- self:showMultiSelectPanel(false)
	-- self:setDelVisable(false)
	-- self.ui.graffiti_del.visible = false
	-- self.ui.copybutton.visible = false
	-- self.ui.bottombg.visible = false
	-- self.ui.lockbutton.visible = false
	-- self.ui.editmtl.visible = false
	-- self.ui.addasset.visible = false
	-- self.ui.mirror.visible = false
	-- self.ui.addpaint.visible = false
end

BuildBrick.moveBlock = function(self, x, y)
	-- 移动block
	local scalef = Global.UI:getScale()
	local mx, my = x / scalef, y / scalef

	local movebutton = self.isplanemove and Global.ui.controler.planemovebutton or Global.ui.controler.movebutton
	local args = {mouse = {x = (x + self.movedx) / scalef, y = (y + self.movedy) / scalef}}

	movebutton.onMouseMove(args)

	self:onMovingBlock()
	self:onMoveMusic()

	if not self.enableRepair then
		local w, h = _rd.w / scalef, _rd.h / scalef
		local rx, ry = toint(w / 16), toint(h / 16)
		local movex, movey
		if mx < rx then
			movex = mx - rx
		elseif mx > w - rx then
			movex = mx + rx - w
		end

		if my < ry then
			movey = my - ry
		elseif my > h - ry then
			movey = my + ry - h
		end

		if movex or movey then
			if movex then
				movex = math.clamp(movex, -100, 100)
			end

			if movey then
				movey = movey * 2
				movey = math.clamp(movey, -100, 100)
			end
			-- print('movex, movey', movex, movey)
			local s = 0.000015
			Global.CameraControl:moveLook(movex and - movex * s or 0, movey and movey * s or 0)
		end
	end

	-- 添加到module中
	-- self:checkBlockArea(Global.cross.x, Global.cross.y)

	if self.enableGroup then
		if #self.rt_selectedGroups > 0 then
			self:atom_group_dirty()
		else
			-- 处理module之间移动时没有group的问题
			if self.rt_selectedBlocks then
				for i, v in ipairs(self.rt_selectedBlocks) do
					local g = v:getBlockGroup()
					g:setDirty()
				end
			end
		end
	end

	self:checkMusicDummy()
	if self.enableRepair then self:checkRepaired() end
end

BuildBrick.onDummyBegin = function(self, blocks)
	if not self.dummyblocks then self.dummyblocks = {} end

	for i, b in ipairs(blocks) do
		b.oldpickflag = b:getPickFlag()
		b:setPickFlag(Global.CONSTPICKFLAG.DUMMY)
		table.insert(self.dummyblocks, b)
	end
end

BuildBrick.onDummyEnd = function(self, blocks)
	if not self.dummyblocks then return end

	for i, b in ipairs(self.dummyblocks) do
		b:setPickFlag(b.oldpickflag)
		b.oldpickflag = nil
	end

	self.dummyblocks = nil
end

local repairclipbox = _AxisAlignedBox.new()
repairclipbox.min:set(-14, -10, 0)
repairclipbox.max:set(14, 10, 20)

local movemat = _Matrix3D.new()
BuildBrick.building_moveBegin = function(self, x, y)
	if not self.downX then return end
	if self.rt_moving then return end
	if self:distance(x, y, self.downX, self.downY) <= self.movedelta then return end

	-- 执行点击
	self:cmd_select_end('move')
	if self:atom_block_selectedNum() == 0 then return end

	if (self:isSelectedMusicRunway() or self:isSelectedMusicPole()) and #self.rt_selectedBlocks == 1 then
		self:moveMusicBegin(self.rt_selectedBlocks[1])
	end

	if not self.enableBrickMat then
		self:showHint(true, 3, x, y)
		return
	end

	self.rt_moving = true

	if not self.movingMusic then
		Global.editor.static_building_setBlocksState(self.rt_selectedBlocks, 'moving')
	end

	Global.normalizePos(self.rt_pos, Global.MOVESTEP.TILE)
	movemat:setTranslation(self.rt_pos)
	self:cmd_mat_update_begin(movemat)

	-- 设置pick参数
	local PH = Global.PickHelper
	local pickflag = Global.CONSTPICKFLAG.NORMALBLOCK + Global.CONSTPICKFLAG.TERRAIN + Global.CONSTPICKFLAG.BONE + Global.CONSTPICKFLAG.SELECTWALL
	PH.lockY = nil
	if self.mode == 'buildscene' then
		PH.knotMode = Global.KNOTPICKMODE.NONE

		-- 有旋转节点时才使用
		if self.knotMode == Global.KNOTPICKMODE.SPECIAL then
			for i, b in ipairs(self.rt_selectedBlocks) do
				if b:hasSpecialKnot() then
					PH.knotMode = Global.KNOTPICKMODE.SPECIAL
					break
				end
			end
		end
		local ismusicsub = self:isMusicMode('music_train')
		local steps
		if (Global.BuildBrick:isSelectedHasDungeon() or ismusicsub) and PH.knotMode == Global.KNOTPICKMODE.NONE then
			steps = {0.8, 0.1}
		else
			steps = {0.1, 0.02}
		end
		PH.movesteps = steps

		if self.movingMusic then
			-- pickflag = Global.CONSTPICKFLAG.TERRAIN
			local floors = self:getMusicFloors()
			local floorshash = {}
			table.farray2Hash(floors, floorshash)

			local nbs = {}
			self:getBlocks(nbs, function(b)
				return not floorshash[b]
			end)

			self:onDummyBegin(nbs)
			PH.lockY = true
		elseif ismusicsub and self.rt_selectedBlocks[1] and self:isBarrierBlock(self.rt_selectedBlocks[1]) then
			--local poles = self:getMusicPoles()

			local nbs = {}
			self:getAllBlocks(nbs, function(b)
				return not self:isBarrierBlock(b) and not self:isFloorBlock(b)
			end)
			self:onDummyBegin(nbs)
		end
	else
		PH.knotMode = self.knotMode
		PH.movesteps = {0.02, 0.02}
	end

	PH:setPickFlag(pickflag)

	PH.clippedBox = nil
	if Global.BuildBrick.enableRepair or Global.GameState:isState('BLOCKBRAWL') then
		PH.clippedBox = repairclipbox
	end

	local scalef = Global.UI:getScale()
	local args = {mouse = {x = self.downX / scalef, y = self.downY / scalef}}
	self.isplanemove = self.planemove and true or false
	local movebutton = self.isplanemove and Global.ui.controler.planemovebutton or Global.ui.controler.movebutton
	movebutton.onMouseDown(args)
	self.movedx, self.movedy = 0, 0
end

BuildBrick.building_moveEnd = function(self, x, y)
	-- self:moveMusicPoleEnd()
	if not self.enableBrickMat then
		self:showHint(false)
	end

	if not self.rt_moving then return end

	self.rt_moving = false
	local scalef = Global.UI:getScale()
	local args = {mouse = {x = x / scalef, y = y / scalef}, nosound = false}
	args.nosound = self.noPutSound
	local movebutton = self.isplanemove and Global.ui.controler.planemovebutton or Global.ui.controler.movebutton
	movebutton.onMouseUp(args)

	self:moveMusicEnd()

	Global.editor.static_building_setBlocksState(self.rt_selectedBlocks, 'selected')
	if x == self.downX and y == self.downY then
		return false
	end

	self:cmd_mat_update_end()

	if self.isplanemove then
		self:atom_group_knot_dirty()
	end

	self:onDummyEnd()

	return true
end