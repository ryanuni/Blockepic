local Detector = {}
_G.Detector = Detector

local v3_1 = _Vector3.new()
local v3_2 = _Vector3.new()

local mat_1 = _Matrix3D.new()
local mat_2 = _Matrix3D.new()

local hpos = _Vector3.new()
local hmat = _Matrix3D.new()
Detector.checkPosVSActordata = function(self, pos, actordata)
	for _, v in ipairs(actordata) do
		if not v.rot then
			if v.box:checkInside(pos) then
				return true
			end
		else
			v.box:getCenter(hpos)
			-- 旋转包围盒到正常包围盒的矩阵
			hmat:setTranslation(-hpos.x, -hpos.y, -hpos.z)
			hmat:mulRotationRight(v.rot.x, v.rot.y, v.rot.z, -v.rot.w)
			hmat:mulTranslationRight(hpos)
			hmat:apply(pos, hpos)
			if v.box:checkInside(hpos) then
				return true
			end
		end
	end

	return false
end

local testshapesize = 0.015
Detector.checkKnotVSActordata = function(self, knot, actordata, actormat)
	if knot.type ~= 1 then return false end
	local pos, axis = v3_1, v3_2

	local s = testshapesize
	knot:getPos1(pos)
	knot:getAxisN(axis)

	_Vector3.mul(axis, s, axis)
	_Vector3.add(pos, axis, pos)

	if actormat then
		mat_1:set(actormat)
		mat_1:inverse()
		mat_1:apply(pos, pos)
	end

	return self:checkPosVSActordata(pos, actordata)
end

Detector.checkKnotVSBlocks = function(self, knot, blocks)
	if knot.type ~= 1 then return false end
	local pos, axis = v3_1, v3_2

	local s = testshapesize
	knot:getPos1(pos)
	knot:getAxisN(axis)

	_Vector3.mul(axis, s, axis)
	_Vector3.add(pos, axis, pos)

	for i, b in ipairs(blocks) do
		local ab = b:getShapeAABB2()
		if ab:checkInside(pos) then
			local actordata = b:getActorsData()

			mat_1:set(b.node.transform)
			mat_1:inverse()
			mat_1:apply(pos, v3_2)

			if self:checkPosVSActordata(v3_2, actordata) then
				return true
			end
		end
	end

	return false
end

------------------- 开始物理检测
Detector.beginPhysTest = function(self, nbs, f)
	local cnt = 0
	for b in pairs(nbs) do
		local shapes = b:getPhysicShapes()
		for _, v in ipairs(shapes) do if not f or f(b, v) then
			v.oldQueryFlag = v.queryFlag
			v.queryFlag = Global.CONSTPICKFLAG.SWEEPTEST
			cnt = cnt + 1
		end end
	end

	return cnt
end

Detector.endPhysTest = function(self, nbs, f)
	for b in pairs(nbs) do
		local shapes = b:getPhysicShapes()
		for _, v in ipairs(shapes) do if not f or f(b, v) then
			v.queryFlag = v.oldQueryFlag
			v.oldQueryFlag = nil
		end end
	end
end
------------------ 结束物理检测

local expandab = _AxisAlignedBox.new()
Detector.getBlocksNearByRoughly = function(self, bs, abs, helpdata)
	local hbs = {}
	for i, b in ipairs(bs) do
		hbs[b] = true
	end

	local nearbs = {}

	local habs, acount = {}, 0
	for i, b in ipairs(abs) do if not hbs[b] then
		habs[b] = true
		acount = acount + 1
	end end

	if helpdata and helpdata.aabb then
		expandab:set(helpdata.aabb)
	else
		Block.getAABBs(bs, expandab)
	end
	expandab:expand(0.1, 0.1, 0.1)

	-- 积木数量较少时直接使用包围盒判断
	local limitn = 10
	if acount <= limitn then
		for b in pairs(habs) do
			local ab = b:getShapeAABB2()
			if expandab:checkIntersect(ab) then
				table.insert(nearbs, b)
			end
		end
	else
		-- 积木数量较多时使用场景pick
		local flag = helpdata and helpdata.flag or Global.CONSTPICKFLAG.NORMALBLOCK + Global.CONSTPICKFLAG.TERRAIN + Global.CONSTPICKFLAG.BONE
		Global.sen:boxPick(expandab, flag)

		Global.sen:getPickedBlocks(nearbs, function(b)
			return habs[b]
		end)
	end

	return nearbs
end

-- check CONs and knot connect
Detector.checkBlocksVSBlocks = function(self, bs, abs)
	local bs1 = bs
	local bs2 = self:getBlocksNearByRoughly(bs, abs)

	if #bs1 > #bs2 then
		bs1, bs2 = bs2, bs1
	end

	-- local hbs1 = {}
	-- for i, b in ipairs(bs1) do
	-- 	hbs1[b] = true
	-- end

	-- local hbs2 = {}
	-- for i, b in ipairs(bs2) do
	-- 	hbs2[b] = true
	-- end

end