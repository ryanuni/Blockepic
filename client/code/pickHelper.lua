local Container = _require('Container')

local PickHelper = {}
Global.PickHelper = PickHelper

Global.KNOTPICKMODE = {
	NONE = 0, -- 不用knot
	NORMAL = 1, -- 所有knot
	SPECIAL = 2, -- 特殊knot(爪子等)
}

local log = function(...)
	print(...)
end

PickHelper.init = function(self)
	self.dummyActor = nil

	-- initdata
	self.blocks = {}
	self.senblocks = {}
	self.senAABB = _AxisAlignedBox.new()
	self.oriAABB = _AxisAlignedBox.new()
	self.helpAABB = _AxisAlignedBox.new()
	self.absize = _Vector3.new()
	self.senabsize = _Vector3.new()

	-- pickdata
	-- self.findpos = _Vector3.new()
	-- self.pickpos = _Vector3.new()
	-- self.origin = _Vector3.new()
	-- self.dir = _Vector3.new()
	-- self.lastk1 = nil
	-- self.lastk2 = nil
	self:clearPickData()

	-- self.attachKnots = {}
	-- self.senKnots = {}
	-- self.blockKnots = {}
	self.tilesize = 4 * 4 * 0.2

	--self.bindknot = true
	-- self.pickMode = 'bindknot'
	self.optks = false

	local frustum = {}
	for i = 1, 8 do
		frustum[i] = _Vector3.new()
	end
	self.pickfrustum = frustum
end

PickHelper.setPickFlag = function(self, flag)
	self.pickflag = flag
end

PickHelper.getPickFlag = function(self)
	if self.pickflag then return self.pickflag end

	if Block.isBuildMode() then
		return Global.CONSTPICKFLAG.NORMALBLOCK + Global.CONSTPICKFLAG.TERRAIN + Global.CONSTPICKFLAG.BONE + Global.CONSTPICKFLAG.SELECTWALL
	else
		return Global.CONSTPICKFLAG.NORMALBLOCK
	end
end

PickHelper.attachBlocks = function(self, bs, ab, bindmat)
	self.bindBlocks = bs
	self.bindAABB = ab
	--self.bindmat = bindmat
	self.dirty = true
	self.sen = nil

	--if bs and #bs > 0 or bindmat then
		self.transform = bindmat
		self.sen = bs and bs[1] and bs[1].node.scene or Global.sen
	--end
end

PickHelper.attach = function(self)
	if not self.dirty then return end

	self.dirty = false
	local bs = self.bindBlocks
	local ab = self.bindAABB

	if bs and #bs > 0 then
		if not self.knotGroup then
			self.knotGroup = KnotGroup.new()
		end

		if not self.senKnotGroup then
			self.senKnotGroup = KnotGroup.new()
		end

		--self.pickMode = Global.GameState:isState('BUILDBRICK') and 'bindknot' or 'tile'
		-- self.pickMode = 'tile'
		--self.transform = self.bindmat
		assert(self.transform)

		self.blocks = {}
		for i, b in ipairs(bs) do
			-- assert(b.node.transform.parent == self.transform)
			table.insert(self.blocks, b)
			self.blocks[b] = i
		end

		self.gmats = {}
		local kgs = {}

		local t1 = _tick()
		if self.knotMode == Global.KNOTPICKMODE.NORMAL then
			local gs = {}
			for i, b in ipairs(bs) do
				local g = b:getBlockGroup('root')
				gs[g] = true
			end

			for g in pairs(gs) do
				table.insert(kgs, g:getKnotGroup())
				table.insert(self.gmats, g.transform)
			end
			self.knotGroup:setChildren(kgs, true)
		elseif self.knotMode == Global.KNOTPICKMODE.SPECIAL then
			for i, b in ipairs(bs) do
				if b:hasSpecialKnot() then
					table.insert(kgs, b:getSpecialKnotGroup())
				end
			end
			self.knotGroup:setChildren(kgs, true)
		end

		-- 计算原始包围盒
		if ab then
			self.oriAABB.min:set(ab.min)
			self.oriAABB.max:set(ab.max)
			ab:getSize(self.absize)
		else
			Block.getAABBs(self.blocks, self.oriAABB)
			self.oriAABB:getSize(self.absize)
		end

		local vec = Container:get(_Vector3)
		self.transform:getTranslation(vec)
		_Vector3.sub(self.oriAABB.min, vec, self.oriAABB.min)
		_Vector3.sub(self.oriAABB.max, vec, self.oriAABB.max)

		local t2 = _tick()
		self:updateDummy()
		local t3 = _tick()

		self.senblocks = {}
		self.sen:getBlocksByFilter(self.senblocks, function(b)
			return not self.blocks[b] and b:hasPickFlag(self:getPickFlag())
		end)

		if self.knotMode == Global.KNOTPICKMODE.NORMAL then
			local senkgs = {}
			local gs = {}
			for i, b in ipairs(self.senblocks) do
				local g = b:getBlockGroup('root')
				gs[g] = true
			end

			for g in pairs(gs) do
				table.insert(senkgs, g:getKnotGroup())
			end
			self.senKnotGroup:setChildren(senkgs, true)
			self.senKnotGroup:setDirty()
		elseif self.knotMode == Global.KNOTPICKMODE.SPECIAL then
			local senkgs = {}
			for i, b in ipairs(self.senblocks) do
				if b:hasSpecialKnot() then
					table.insert(senkgs, b:getSpecialKnotGroup())
				end
			end

			print('#senkgs', senkgs)
			self.senKnotGroup:setChildren(senkgs, true)
			self.senKnotGroup:setDirty()
		end

		self.overlaps = {}
		Block.getAABBs(self.senblocks, self.senAABB)
		self.senAABB:getSize(self.senabsize)

		self:clearPickData()

		local t4 = _tick()

		-- log('attachBlocks', t2 - t1, t3 - t2, t4 - t3)
		Container:returnBack(vec)
	else
		self.blocks = nil
		self.senblocks = nil
		self:releaseDummy()
	end
end

PickHelper.updateDummy = function(self)
	if not self.sen.dummyActor then
		self.sen.dummyActor = self.sen:addActor()
	else
		self.sen.dummyActor:clearShapes()
	end

	self.dummyActor = self.sen.dummyActor

	-- block数量较少时使用精确的shape
	local trans = Container:get(_Vector3)
	local scale = Container:get(_Vector3)
	local vec = Container:get(_Vector3)
	local transform = Container:get(_Matrix3D)

	-- 需要保持blocks的parent.transform与dummyActor.transform一致
	self.transform:getTranslation(trans)

	-- 统计box
	local actors = {}
	-- local n1, n2 = 0, 0
	for i, b in ipairs(self.blocks) do
		local actordata = b:getActorsData() or {}
		scale:set(b.data.space.scale)
		for _, v in ipairs(actordata) do
			local bb = _AxisAlignedBox.new()

			v.box:getSize(vec)
			local sx, sy, sz = vec.x * 0.5, vec.y * 0.5, vec.z * 0.5
			bb.min:set(-sx, -sy, -sz)
			bb.max:set(sx, sy, sz)

			v.box:getCenter(vec)
			transform:setTranslation(vec)
			if v.rot then transform:mulRotationLeft(v.rot.x, v.rot.y, v.rot.z, v.rot.w) end
			--if scale.x ~= 1 then transform:mulScalingRight(scale) end
			transform:mulRight(b.node.transform)
			transform:mulTranslationRight(-trans.x, -trans.y, -trans.z)
			local rot
			if transform:hasRotation2() then
				rot = _Vector4.new()
				transform:getRotation(rot)
				transform:getTranslation(vec)
				transform:setScaling(scale)
				transform:mulTranslationRight(vec)
				-- n1 = n1 + 1
			end

			bb:mul(transform)

			table.insert(actors, {box = bb, rot = rot, jdata = v.jdata})
			-- n2 = n2 + 1
		end
	end

	-- 合并box
	local n = #actors
	if #actors > 1000 then
		actors = {}
		table.insert(actors, {box = self.oriAABB})
	elseif #actors > 100 then
		local data1 = {}
		local data2 = {}
		for i, v in ipairs(actors) do
			if not v.jdata and not v.rot then
				table.insert(data1, v)
			else
				table.insert(data2, v)
			end
		end
		Optimizer.MergeBoxs(data1, 'box')
		for i, v in ipairs(data1) do
			table.insert(data2, v)
		end
		actors = data2
	end

	--生成shape
	for i, v in ipairs(actors) do
		local shape = self.dummyActor:addShape(_PhysicsShape.Cube)
		v.box:getSize(vec)
		local sx, sy, sz = vec.x * 0.5, vec.y * 0.5, vec.z * 0.5
		shape.size = _Vector3.new(sx, sy, sz)
		shape.queryFlag = Global.CONSTPICKFLAG.DUMMY
		shape.trigger = true

		v.box:getCenter(vec)
		transform:setTranslation(vec)
		if v.rot then transform:mulRotationLeft(v.rot.x, v.rot.y, v.rot.z, v.rot.w) end
		shape.transform:set(transform)
	end
	self.dummyActor.kinematic = true

	self.actors = actors

	self.dummyActor.transform:setTranslation(trans)

	Container:returnBack(trans, scale, vec, transform)
end

PickHelper.releaseDummy = function(self)
	if self.sen.dummyActor then
		self.sen:delActor(self.sen.dummyActor)
		self.dummyActor = nil
	end
end

PickHelper.isDummyOverlap = function(self, flag)
	flag = flag or self:getPickFlag()
	local overlayrets = {}
	return self.sen:physicsOverlapAny(self.dummyActor, flag, overlayrets)
end

local visv3 = _Vector3.new()
local visdir = _Vector3.new()
PickHelper.isDummyVisible = function(self, ori, pos)
	local picks = {}
	local flag = self:getPickFlag()
	for i = 1, 8 do
		self.oriAABB:getPoint(i, visv3)
		_Vector3.add(visv3, pos, visv3)

		_Vector3.sub(ori, visv3, visdir)
		local l = visdir:magnitude()
		visdir:normalize()

		if not self.sen:physicsPick(visv3, visdir, l, flag, picks) then
			return true
		end
	end

	return false
end

PickHelper.clearPickData = function(self)
	self.findpos = _Vector3.new()
	self.pickpos = _Vector3.new()
	self.sweeppos = _Vector3.new()
	self.origin = _Vector3.new()
	self.dir = _Vector3.new()
	self.lastk1 = nil
	self.lastk2 = nil
end

PickHelper.setAttachPosition = function(self, pos)
	self.transform:setTranslation(pos)
	-- _Vector3.add(self.oriAABB.min, pos, self.helpAABB.min)
	-- _Vector3.add(self.oriAABB.max, pos, self.helpAABB.max)
end
PickHelper.moveTransDiff = function(self, diff)
	if self.lockY then
		diff.x = 0
		diff.z = 0
	end

	self.transform:mulTranslationRight(diff)
	if self.gmats then
		for i, mat in ipairs(self.gmats) do
			mat:mulTranslationRight(diff)
		end
	end
end

local draw_v3 = _Vector3.new()
PickHelper.render = function(self)

	if self.ks_pairs then
		local knots = {}
		for i, v in ipairs(self.ks_pairs) do
			knots[v.k1] = true
			knots[v.k2] = true

			-- local p = v.k1:getPos1()
			-- _Vector3.add(p, v.movediff, draw_v3)
			-- _rd:draw3DLine(p.x, p.y, p.z, draw_v3.x, draw_v3.y, draw_v3.z, _Color.Red)
		end

		-- for k in pairs(knots) do
		-- 	KnotManager.drawKnot(k)
		-- end

		-- if self.findv then
		-- 	local v = self.findv
		-- 	KnotManager.drawKnot(v.k1)
		-- 	KnotManager.drawKnot(v.k2)

		-- 	local p = v.k1:getPos1()
		-- 	_Vector3.add(p, v.movediff, draw_v3)
		-- 	_rd:draw3DLine(p.x, p.y, p.z, draw_v3.x, draw_v3.y, draw_v3.z, _Color.Green)
		-- end
	end

	-- for i, v in ipairs(self.attachKnots) do
	-- 	local k = v.knot
	-- 	log('1111', k.N, k.pos, k:getPos(), k.mat, k.bindmat)
	-- 	DrawHelper.drawKnot(k:getPos(), _Color.Purple)
	-- end

	-- if self.pp1 and self.pp2 then
	-- 	local bs = self:LineCross(self.pp1, self.pp2)
	-- 	_rd:draw3DLine(self.pp1.x, self.pp1.y, 0.05, self.pp2.x, self.pp2.y, 0.05, _Color.Red)
	-- 	for i, v in ipairs(bs) do
	-- 		local x, y, z = v.x * 0.2 + 0.1, v.y * 0.2 + 0.1, 0.02
	-- 		_rd:fill3DRect(x, y, z, 0.1, 0, 0, 0, 0.1, 0, _Color.Green)
	-- 	end
	-- end

	-- for i, v in ipairs(self.senKnots) do
	-- 	local k = v.knot
	-- 	DrawHelper.drawKnot(k:getPos1(), _Color.Green)
	-- end

	-- if self.projks2 then
	-- 	for xi, xs in pairs(self.projks2) do
	-- 		for yi, knots in pairs(xs) do
	-- 			for i, v in ipairs(knots) do
	-- 				local k = v.knot
	-- 				DrawHelper.drawKnot(k:getPos1(), _Color.Green)
	-- 			end
	-- 		end
	-- 	end
	-- end

	-- DrawHelper.drawKnot(self.findpos, _Color.Yellow)
	-- DrawHelper.drawRay(self.origin, self.dir, _Color.Red)

	-- for i = 1, 8 do
	-- 	self.oriAABB:getPoint(i, visv3)
	-- 	_Vector3.add(visv3, self.findpos, visv3)
	-- 	DrawHelper.drawKnot(visv3, _Color.Purple)

	-- 	_Vector3.sub(visv3, self.origin, visv3)
	-- 	visv3:normalize()

	-- 	DrawHelper.drawRay(self.origin, visv3, 20, _Color.Green)
	-- end

	-- for i = 1, 4 do
	-- 	local ori = self.pickfrustum[i]
	-- 	local t = self.pickfrustum[i + 4]
	-- 	_rd:draw3DLine(ori.x, ori.y, ori.z, t.x, t.y, t.z, _Color.Green)

	-- 	ori = self.pickfrustum[i]
	-- 	t = i < 3 and self.pickfrustum[i + 1] or self.pickfrustum[i - 2]
	-- 	_rd:draw3DLine(ori.x, ori.y, ori.z, t.x, t.y, t.z, _Color.Red)

	-- 	ori = self.pickfrustum[i + 4]
	-- 	t = i < 3 and self.pickfrustum[i + 5] or self.pickfrustum[i + 2]
	-- 	_rd:draw3DLine(ori.x, ori.y, ori.z, t.x, t.y, t.z, _Color.Red)
	-- end

	-- if self.lastk1 then
	-- 	DrawHelper.drawKnot(self.lastk1.knot:getPos1(), _Color.Red)
	-- end
	-- if self.lastk2 then
	-- 	DrawHelper.drawKnot(self.lastk2.knot:getPos1(), _Color.Red)
	-- end

	-- if self.helpAABB then
	-- 	self.helpAABB:draw(_Color.Green)
	-- end

	-- if Global.BuildHouse.innerWallab then
	-- 	Global.BuildHouse.innerWallab:draw(_Color.Red)
	-- end
end

local transvec = _Vector3.new()
local transab = _AxisAlignedBox.new()
PickHelper.renderHelper = function(self)
	if not self.ismoving then return end

	local isrepairing = Global.GameState:isState('BUILDBRICK') and Global.BuildBrick.enableRepair
	if isrepairing or self.knotMode == Global.KNOTPICKMODE.NONE then return end
	--if self.pickMode ~= 'bindknot' then
		--DrawHelper.drawCornnerBox(self.helpAABB)
	--end

	-- if self.tenknot then
	-- 	DrawHelper.drawKnot(self.tenknot:getPos1(), _Color.Red)
	-- 	DrawHelper.drawKnot(self.tenknot:getPos2(), _Color.Red)
	-- end

	self.transform:getTranslation(transvec)
	_Vector3.add(self.oriAABB.min, transvec, transab.min)
	_Vector3.add(self.oriAABB.max, transvec, transab.max)
	transab:expand(0.4, 0.4, 0.4)

	if self.senKnotGroup then
		local senks = {}
		self.senKnotGroup:getKnots(0, senks)

		for i, v in ipairs(senks) do
			KnotManager.drawKnot(v, self.ks_picked and self.ks_picked[v], transab)
		end
	end

	if self.knotGroup then
		local ks = {}
		self.knotGroup:getKnots(0, ks)
		for i, v in ipairs(ks) do
			v:setTransformDirty()
			KnotManager.drawKnot(v, self.ks_picked and self.ks_picked[v])
		end
	end
end

local function getBoundArea(p1, p2, p3, p4)
	local minx = math.min(p1.x, p2.x, p3.x, p4.x)
	local miny = math.min(p1.y, p2.y, p3.y, p4.y)
	local maxx = math.max(p1.x, p2.x, p3.x, p4.x)
	local maxy = math.max(p1.y, p2.y, p3.y, p4.y)
	return minx, miny, maxx, maxy
end

PickHelper.getPickedTerrainArea = function(self, ori, dir)
	if dir.z >= 0 then return end
	local maxdis = math.max(40, math.max(ori.z) * 4)
	local tenz = self.sen.planeZ or 0
	local l = -(ori.z - tenz) / dir.z
	-- 离地表太远时不考虑pick地表
	if l > maxdis then
		return
	end

	local ab = Container:get(_AxisAlignedBox)
	local pickpos = Container:get(_Vector3)
	local min = Container:get(_Vector3)
	local max = Container:get(_Vector3)

	_Vector3.mul(dir, l, pickpos)
	_Vector3.add(pickpos, ori, pickpos)
	_Vector3.add(self.oriAABB.min, pickpos, ab.min)
	_Vector3.add(self.oriAABB.max, pickpos, ab.max)
	ab:expand(0.2, 0.2, 0.2)

	min:set(ab.min)
	max:set(ab.max)
	local minx, miny, maxx, maxy = min.x, min.y, max.x, max.y

	local l2 = -(ori.z - tenz + self.oriAABB.min.z) / dir.z
	_Vector3.mul(dir, l2, pickpos)
	_Vector3.add(pickpos, ori, pickpos)
	_Vector3.add(self.oriAABB.min, pickpos, ab.min)
	_Vector3.add(self.oriAABB.max, pickpos, ab.max)
	ab:expand(0.2, 0.2, 0.2)

	minx, miny, maxx, maxy = getBoundArea(min, max, ab.min, ab.max)
	-- print('getPickedTerrainArea minx, miny, maxx, maxy', minx, miny, maxx, maxy)

	Container:returnBack(ab, pickpos, min, max)

	return minx, miny, maxx, maxy
end

PickHelper.getTerrainKnot = function(self, minx, miny, maxx, maxy)
	if not minx then return end

	minx = math.floatRound(minx, 0.2, 0)
	miny = math.floatRound(miny, 0.2, 0)
	maxx = math.floatRound(maxx, 0.2, 1)
	maxy = math.floatRound(maxy, 0.2, 1)
	if minx >= maxx or miny >= maxy then return end

	-- print('getTerrainKnot minx, miny, maxx, maxy', minx, miny, maxx, maxy)

	local tenz = self.sen.planeZ or 0
	local pos1 = _Vector3.new(minx + 0.1, miny + 0.1, tenz)
	local pos2 = _Vector3.new(maxx - 0.1, maxy - 0.1, tenz)

	local data = {
		type = 0,
		Normal = Global.AXIS.Z,
		Tangent = Global.AXIS.X,
		Binormal = Global.AXIS.Y,
		pos1 = pos1,
		pos2 = pos2,
		skipDecompose = true
	}
	local tenKnot = Knot.new(data)
	return tenKnot
end

PickHelper.projectKnots = function(self, ori, dir)
	--[[
	local senks1, senks2 = {}, {}
	self.senKnotGroup:getKnots(1, senks1)
	self.senKnotGroup:getKnots(2, senks2)

	local ks1, ks2 = {}, {}
	self.knotGroup:getKnots(1, ks1)
	self.knotGroup:getKnots(1, ks2)

	local pair1 = KnotManager.checkProjectPair(senks1, ks1)
	local pair2 = KnotManager.checkProjectPair(senks1, ks2)
	local pair3 = KnotManager.checkProjectPair(senks2, ks1)
	local pair4 = KnotManager.checkProjectPair(senks2, ks2)
	--]]

	local t1 = _tick()
	local senks = {}
	self.senKnotGroup:getKnots(0, senks)
	local tenknot = self:getTerrainKnot(self:getPickedTerrainArea(ori, dir))
	if tenknot then
		table.insert(senks, tenknot)
	end
	self.tenknot = tenknot

	local ks = {}
	self.knotGroup:getKnots(0, ks)
	for i, k in ipairs(ks) do
		k:setTransformDirty()
	end

	local tangent = _Vector3.new(1, 2, 0)

	--dir:set(0, 0, -1) ---------
	--tangent:set(1, 0, 0) -----------

	local proj = Global.buildProjectAxis(dir, tangent)
	-- local proj_inv = _Matrix3D.new()
	-- proj_inv:set(proj)
	-- proj_inv:inverse()

	local projdata = {}
	projdata.projmat = proj
	--projdata.projmatinv = proj_inv
	projdata.dir = dir
	projdata.ks = {}

	for i, k in ipairs(senks) do
		KnotManager.ProjectKnot_ByDir(k, projdata)
	end
	for i, k in ipairs(ks) do
		KnotManager.ProjectKnot_ByDir(k, projdata)
	end

	local t2 = _tick()
	local ks_pairs = KnotManager.checkProjectPair(ks, senks, projdata)
	local t3 = _tick()
	for i, v in ipairs(ks_pairs) do
		v.dd = v.movediff:magnitude()
	end

	local function comparevec(a, b)
		return math.floatLess(a.z, b.z) or math.floatEqual(a.z, b.z) and
			(math.floatLess(a.y, b.y) or math.floatEqual(a.y, b.y) and math.floatLess(a.x, b.x))
	end

	table.sort(ks_pairs, function(a, b)
		return math.floatLess(a.dd, b.dd) or math.floatEqual(a.dd, b.dd) and comparevec(a.movediff, b.movediff)
	end)

	local oldn = #ks_pairs
	for i = #ks_pairs, 2, -1 do
		local p, pi = ks_pairs[i], ks_pairs[i - 1]
		if math.floatEqual(p.dd, pi.dd) and math.floatEqualVector3(p.movediff, pi.movediff) then
			table.remove(ks_pairs, i)
		end
	end

	local t4 = _tick()
	--log('projectKnots', t2 - t1, t3 - t2, t4 - t3)
	--log('projectKnots2', #ks_pairs, #ks, #senks)

--[[
	print('projectKnots', #senks, #ks, oldn - #ks_pairs, #ks_pairs)
	for i, v in ipairs(ks_pairs) do
		local k1 = v.k1
		local k2 = v.k2
		local n = v.n
		local d = v.d
		--print('i', i, d, n, k1:getType(), k2:getType(), k1:getPos1(), k2:getPos1())
		print('i', i, v.dd, k2:getPos1())
	end
]]
	return ks_pairs
end

local dummyPos = _Vector3.new()
local movepos = _Vector3.new()

-- local repairbox = _AxisAlignedBox.new()
-- repairbox.min:set(-14, -10, 0)
-- repairbox.max:set(14, 10, 20)

PickHelper.boxClipped = function(self, p, ori, dir)
	local dx, dy
	local outx, outy = _Vector3.new(), _Vector3.new()
	if dir.x ~= 0 then
		local paxis = _Vector3.new(dir.x < 0 and self.clippedBox.min.x or self.clippedBox.max.x, 0, 0)
		dx = mathHelper.Distance_Plane_Ray(paxis, ori, dir, outx)
	end

	if dir.y ~= 0 then
		local paxis = _Vector3.new(0, dir.y < 0 and self.clippedBox.min.y or self.clippedBox.max.y, 0)
		dy = mathHelper.Distance_Plane_Ray(paxis, ori, dir, outy)
	end

	if dx and dy then
		p:set(dx < dy and outx or outy)
	elseif dx then
		p:set(outx)
	elseif dy then
		p:set(outy)
	end

	-- print('boxClipped', dx, outx, p)
	-- print('boxClipped', dy, outy, p)
end

PickHelper.moveTry = function(self, ori, dir)
	local picks = {}
	local ret = self.sen:physicsPick(ori, dir, 100, self:getPickFlag(), picks)
	--print('moveTry', ret, ori, dir)
	if not ret then return end

	-- 记录pick之前的位置
	self.dummyActor.transform:setTranslation(ori)
	local sweeps = {}
	if not self.sen:physicsSweep(self.dummyActor, dir, 100, self:getPickFlag(), sweeps) then
		return
	end

	--print('moveTry', self:getPickFlag(), sweeps.shape.queryFlag)

	_Vector3.mul(dir, picks.distance, self.pickpos)
	_Vector3.add(ori, self.pickpos, self.pickpos)

	self.dir:set(dir)
	self.origin:set(ori)

	_Vector3.mul(dir, sweeps.distance, self.sweeppos)
	_Vector3.add(ori, self.sweeppos, self.sweeppos)

	-- 包围盒裁剪
	if self.clippedBox then
		if not self.clippedBox:checkInside(self.sweeppos) then
			self:boxClipped(self.sweeppos, ori, dir)
		end
	end

	self.dummyActor.transform:setTranslation(self.sweeppos)

	-- TEST
	self.transform:getTranslation(dummyPos)
	_Vector3.sub(self.sweeppos, dummyPos, movepos)

	--print('moveTry', self.knotMode, movepos, self:getPickFlag(), self.sweeppos)

	if self.knotMode == Global.KNOTPICKMODE.NONE then
		if self.movesteps then
			local step = _sys:isKeyDown(_System.KeyShift) and self.movesteps[2] or self.movesteps[1]
			movepos.x = math.floatRound(movepos.x, step)
			movepos.y = math.floatRound(movepos.y, step)
			-- movepos.z = math.floatRound(movepos.z, step)
		end

		self:moveTransDiff(movepos)

		return true
	else
		self:moveTransDiff(movepos)

		local ks_pairs = self:projectKnots(self.origin, self.dir)
		self.ks_pairs = ks_pairs
		self.ks_picked = {}

		-- print('ks_pairs', #ks_pairs)
		for i, v in ipairs(ks_pairs) do
			local k1 = v.k1
			local k2 = v.k2
			local type1, type2 = k1:getType(), k2:getType()
			local checkcross = (type1 == KnotManager.PAIRTYPE.POINT or type1 == KnotManager.PAIRTYPE.POINTS)
				and (type2 == KnotManager.PAIRTYPE.POINT or type2 == KnotManager.PAIRTYPE.POINTS)

			_Vector3.add(self.sweeppos, v.movediff, movepos)
			-- Global.normalizePos(movepos, Global.MOVESTEP.TILE)
			self.dummyActor.transform:setTranslation(movepos)

			if (not checkcross or not self:isDummyOverlap()) and self:isDummyVisible(ori, movepos) then
				--print('moveTry pos', i, v.n, k1:getPos1(), k2:getPos1())
				--print('moveTry diff', i, k1:getType(), k2:getType(), v.d, v.movediff)
				--self.transform:mulTranslationRight(v.movediff)
				self:moveTransDiff(v.movediff)
				--self.ks_picked[k1] = _Color.Yellow
				self.ks_picked[k2] = Global.KNOTCOLOR2

				-- self.findv = v
				return true
			end
		end

		if self.movesteps then
			local step = _sys:isKeyDown(_System.KeyShift) and self.movesteps[2] or self.movesteps[1]
			local x = math.floatRound(movepos.x, step)
			local y = math.floatRound(movepos.y, step)
			local z = movepos.z
			-- local z = math.floatRound(movepos.z, step)
			local alignvec = _Vector3.new(x - movepos.x, y - movepos.y, z - movepos.z)
			self:moveTransDiff(alignvec)
		end
	end

	-- self.findv = nil
	return true
end

PickHelper.moveBegin = function(self, x, y)
	--self.dummyActor.transform:set(self.transform)

	self.ismoving = true
end

PickHelper.moveTo = function(self, x, y)
	self:attach()

	local ray = _rd:buildRay(x, y)
	local ori = Container:get(_Vector3)
	local dir = Container:get(_Vector3)
	ori:set(ray.x1, ray.y1, ray.z1)
	dir:set(ray.x2, ray.y2, ray.z2)

	--self:clearPickData()
	local b = self:moveTry(ori, dir)

	Container:returnBack(dir, ori)

	return b
end

PickHelper.moveEnd = function(self, x, y)
	self.ismoving = false
end

-- PickHelper.getMoveData = function(self)
-- 	return self.moveData
-- end

PickHelper.clickMove = function(self, dir, step, checkhit, func)
	local ori = Container:get(_Vector3)
	local vec = Container:get(_Vector3)

	self.transform:getTranslation(ori)

	if not checkhit then
		_Vector3.mul(dir, step, vec)
		self.transform:mulTranslationRight(vec)
		Global.Sound:play('ui_default')

		if func then func(vec) end
	else
		self:attach()

		self.dummyActor.transform:setTranslation(ori)
		local sweeps = {}
		if not self.sen:physicsSweep(self.dummyActor, dir, step, self:getPickFlag(), sweeps) then
			_Vector3.mul(dir, step, vec)
			self:moveTransDiff(vec)
			Global.Sound:play('ui_default')
			if func then func(vec) end
		else
			_Vector3.mul(dir, sweeps.distance, vec)
			_Vector3.add(ori, vec, vec)
			self.dummyActor.transform:setTranslation(vec)
			Global.normalizePos(vec, Global.MOVESTEP.TILE)
			self:setAttachPosition(vec)
			if func then
				_Vector3.sub(vec, ori, vec)
				func(vec)
			end

			Global.Sound:play('build_put')
			Global.Timer:add('vibrate', 25, function()
				_sys:vibrate(30) -- 手机震动
			end)
		end
	end

	Container:returnBack(ori, vec)
end

PickHelper:init()