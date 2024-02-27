local Container = _require('Container')
local BuildHouse = Global.BuildHouse

BuildHouse.getBlocks = function(self, nbs, f)
	self.sen:getBlocksByFilter(nbs, f)
end

BuildHouse.addBlockToScene = function(self, data)
	local b = self.sen:createBlock(data)

	-- 动态物件扔在准备区
	local ab = b:getShapeAABB2()
	local oldpickflag = b:getPickFlag()
	b:setPickFlag(Global.CONSTPICKFLAG.NONE)

	local pos = Container:get(_Vector3)
	self:findPlacePosition(ab, pos)

	b:setPickFlag(oldpickflag)

	local diff = ab:diffBottom(pos)
	b.node.transform:mulTranslationRight(diff)

	--print('addBlockToScene', pos, diff)
	b:updateSpace()

	Container:returnBack(pos)

	return b
end

BuildHouse.clearSceneBlock = function(self)
	local nbs = {}
	self:getBlocks(nbs)

	self:atom_block_del_s(nbs)
end

BuildHouse.addBlock = function(self, shape)
	local b = self:cmd_addBrick(shape)
	self:hideUI()
	self:atom_block_select_ex(b, nil, 0)
end

-- TODO: use phyx sweep instead pick.
BuildHouse.pickScenePosition = function(self, x, y, flag)
	local result = {}
	self.sen:pick(_rd:buildRay(x, y), flag, false, result)

	local c = Global.CameraControl:get()
	if not result.node then
		local tempv3 = Container:get(_Vector3)
		updateCameraData()
		local cameraData = Global.cameraData
		if cameraData.masix.x == 0 then
			_rd:pickYZPlane(x, y, _rd.camera.look.x, tempv3)
		elseif cameraData.masix.y == 0 then
			_rd:pickXZPlane(x, y, _rd.camera.look.y, tempv3)
		elseif cameraData.masix.z == 0 then
			_rd:pickXYPlane(x, y, _rd.camera.look.z, tempv3)
		end

		Container:returnBack(tempv3)
		return tempv3.x, tempv3.y, tempv3.z
	end

	return result.x, result.y, result.z
end

BuildHouse.getPlacePosition = function(self, vec, flag)
	local x, y = _rd.w / 2, _rd.h / 2
	vec.x, vec.y, vec.z = self:pickScenePosition(x, y, flag)
	--print('getPlacePosition1', vec)
	Global.normalizePos(vec, Global.MOVESTEP.TILE)
	--print('getPlacePosition2', vec)
end

BuildHouse.getLookAtCenter = _G.BuildBrick.getLookAtCenter
BuildHouse.findUncollidedPos = _G.BuildBrick.findUncollidedPos
BuildHouse.checkCollfunc = function(box, flag)
	local self = BuildHouse
	if not self.wallab:checkIntersect(box) then
		return true
	end

	if _and(flag, Global.CONSTPICKFLAG.TERRAIN) == 0 then
		flag = flag + Global.CONSTPICKFLAG.TERRAIN
	end

	-- 包围盒缩小一点防止与地面计算时的浮点误差
	local z = 0.04
	box.min.z = box.min.z + z

	if self.sen:boxPick(box, flag) then
		--local nodes = {}
		--self.sen:getPickedNodes(nodes)
		-- for i, v in ipairs(nodes) do
		-- 	local b = v.block
		-- 	if b then
		-- 		local vec = _Vector3.new()
		-- 		v.transform:getTranslation(vec)
		-- 		print('i', i, b:getShape(), vec)
		-- 	end
		-- end
		box.min.z = box.min.z - z
		return true
	end

	box.min.z = box.min.z - z

	return false
end

BuildHouse.findPlacePosition = function(self, ab, pos)
	local center = Container:get(_Vector3)
	self:getPlacePosition(center, Global.CONSTPICKFLAG.TERRAIN)

	local pickflag = Global.CONSTPICKFLAG.NORMALBLOCK + Global.CONSTPICKFLAG.SELECTBLOCK

	local NS = {Global.AXISTYPE.Y, Global.AXISTYPE.NY, Global.AXISTYPE.X, Global.AXISTYPE.NX}
	if not self:findUncollidedPos(pos, ab, center, NS, pickflag, self.checkCollfunc) then
		local box = Container:get(_AxisAlignedBox)
		box:set(ab)

		local len = 10
		local ori = Container:get(_Vector3)
		ori:set(center.x, center.y, center.z + len)

		local r = self.sen:sweepBox(box, ori, Global.AXIS.NZ, 20, pickflag + Global.CONSTPICKFLAG.TERRAIN)
		--assert(r)
		Global.normalizePos(pos, Global.MOVESTEP.TILE)

		box:getBottom(pos)
		Container:returnBack(box, ori)
		--print('sweepbox', pos)
	end
	--print('pos', pos)

	Container:returnBack(center)
end

local pickpos = _Vector3.new()
BuildHouse.scenepick = function(self, x, y, flag)
	local result = {}
	self.sen:pick(_rd:buildRay(x, y), flag, false, result)
	if result.node then
		pickpos:set(result.x, result.y, result.z)
	end
	return result.node, pickpos
end

-- BuildHouse.pick = function(self, x, y, flag)
-- 	local result = {}
-- 	if self.sen:physicsPick(_rd:buildRay(x, y), 100, flag, result) then
-- 		return result.actor and result.actor.node, result.pos
-- 	end
-- end

BuildHouse.checkBlocking = function(self, nbs)
	local checkbs = {}
	if not nbs then
		self:getBlocks(checkbs)
	else
		self:getBlocks(checkbs, function(b)
			return b.isblocking2
		end)

		for i, b in ipairs(nbs) do
			if not b.isblocking and not b.isblocking then
				table.insert(checkbs, b)
			end
		end
	end

	for i, b in ipairs(checkbs) do
		local shape = b:getShape()
		if not Global.HouseBases[shape] and not Global.HouseFloors[shape] then
			local ab = b:getShapeAABB2(true)
			if not self.wallab:checkIntersect(ab) then
				b:setIsblocking('block2', true)
			else
				b:setIsblocking('block2', false)
			end
		end
	end
end

--------------------------------------------