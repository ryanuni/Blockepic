local Container = _require('Container')

local BlockGroup = {}
BlockGroup.typestr = 'BlockGroup'
_G.BlockGroup = BlockGroup
_G.BlockGroups = {}

local __tostring = function(self)
	return string.format('[group] swtichName %s, switchPart %s, serialNum:%d, index:%d, self:%p, cn:%d, bn:%d, lock:%d, p:%p', self.switchName, self.switchPart, self.serialNum, self.index or 0, self, #self.children, #self, self.islock and 1 or 0, self.parent)
--	return string.format('[group] index:%d, self:%p', self.serialNum or 0, self)
end

_G.SerialNumIndex = 0
function _G.GenSerialNum()
	_G.SerialNumIndex = _G.SerialNumIndex + 1
	return _G.SerialNumIndex
end

BlockGroup.new = function(isleaf)
	local group = {}
	setmetatable(group, {__index = BlockGroup, __tostring = __tostring})

	group.parent = nil
	group.isdirty = true
	-- group.rotData = {x = 0, y = 0, z = 0}
	group.index = nil
	group.serialNum = GenSerialNum()
	group.switchName = ''
	group.switchPart = ''
	group.transform = _Matrix3D.new()
	group.isleaf = isleaf

	group.children = {}
	group.islock = false
	group.islock2 = false
	group.isdeadlock = false

	return group
end

BlockGroup.getSerialNum = function(self)
	return self.serialNum
end

BlockGroup.setIndex = function(self, index)
	self.index = index
end

BlockGroup.getIndex = function(self)
	return self.index
end

BlockGroup.isValid = function(self)
	if self.isleaf then
		local b = self:getBlockNode()
		return b:isNodeValid()
	else
		return #self.children > 0 or self.isUsing
	end
end

BlockGroup.isLeafNode = function(self)
	return self.isleaf
end

BlockGroup.getFirstBrick = function(self)
	local nbs = {}
	self:getBlocks(nbs)
	return nbs[1]
end

BlockGroup.setDirty = function(self)
	local groups = {}
	self:getConnects(groups)

	for g in pairs(groups) do
		g.isdirty = true
	end
end

BlockGroup.getBlockNode = function(self)
	assert(self.isleaf)
	return self.block
end

BlockGroup.addBlock = function(self, b)
	assert(self.isleaf)

	self.block = b
	b.blockGroup = self

	-- local og = b.blockGroup
	-- if og and og == self then
	-- 	return
	-- end

	-- if og then
	-- 	og:removeBlock(b)
	-- end

	-- table.insert(self, b)
	-- b.blockGroup = self

	--b.node.transform:bindParent(self.transform)
	--self:setKnotCombineDirty()
end

-- BlockGroup.removeBlock = function(self, block)
-- 	for i, b in ipairs(self) do
-- 		if b == block then
-- 			table.remove(self, i)
-- 			--b.node.transform:unbindParent()
-- 			b.blockGroup = nil
-- 			self:setKnotCombineDirty()
-- 			return
-- 		end
-- 	end
-- end

BlockGroup.getBlocks = function(self, nbs, mode)
	if mode == 'connect' then
		local groups = {}
		self:getConnects(groups)
		for g in pairs(groups) do
			if g:isLeafNode() then
				table.insert(nbs, g:getBlockNode())
			end
		end
	elseif mode == 'onlyblock' then
		if self:isLeafNode() then
			table.insert(nbs, self:getBlockNode())
		end
	elseif mode == 'children' then
		if self:isLeafNode() then
			table.insert(nbs, self:getBlockNode())
		else
			for i, c in ipairs(self.children) do
				c:getBlocks(nbs, mode)
			end
		end
	else
		if self:isLeafNode() then
			table.insert(nbs, self:getBlockNode())
		else
			for i, c in ipairs(self.children) do
				if not c.isTempRoot then
					c:getBlocks(nbs, mode)
				end
			end
		end
	end
end

BlockGroup.getChildren = function(self)
	return self.children
end

BlockGroup.addChild = function(self, c)
	--assert(c.parent == nil)
	assert(not self.isleaf)

	if c.parent == self then return end

	if c.parent then
		if c.parent == self then return end
		c.parent:removeChild(c)
	end

	table.insert(self.children, c)
	c.transform:bindParent(self.transform)
	c.parent = self
	self:setKnotCombineDirty()
end

BlockGroup.removeChild = function(self, c)
	-- assert(not self.islock)
	assert(not self.isleaf)

	for i, v in ipairs(self.children) do
		if v == c then
			table.remove(self.children, i)
			c.transform:unbindParent()
			c.parent = nil
			self:setKnotCombineDirty()
			return true
		end
	end

	return false
end

BlockGroup.removeChildIndex = function(self, index)
	assert(not self.isleaf)

	local c = self.children[index]
	table.remove(self.children, index)
	c.transform:unbindParent()
	c.parent = nil
	self:setKnotCombineDirty()
end

BlockGroup.getParent = function(self, testTempRoot)
	if testTempRoot then
		return not self.isTempRoot and self.parent
	else
		return self.parent
	end
end

BlockGroup.getParents = function(self, ps)
	local p = self.parent
	while p do
		table.insert(ps, p)
		p = p.parent
	end
end

BlockGroup.isAnyParent = function(self, g)
	local p = g
	while p do
		if p == self then return true end
		p = p.parent
	end

	return false
end

BlockGroup.setParent = function(self, p)
	local op = self:getParent()

	-- p和op一样
	if op and op == p then
		return
	end

	if op then
		op:removeChild(self)
	end

	if p then
		p:addChild(self)
	end
end

BlockGroup.setBlender = function(self, blend, insname)
	local nbs = {}
	self:getBlocks(nbs)

	for i, b in ipairs(nbs) do
		b.node.blender = blend
		--b:setDefualtMtlWithAlphaFilter(blend, insname)
	end
end

BlockGroup.setLock = function(self, lock)
	--assert(not self.isleaf)

	-- 锁死后无法解锁
	if self:isDeadLock() and not lock then
		return
	end

	self.islock = lock
end
BlockGroup.isLock = function(self)
	return self.islock
end

BlockGroup.isStatic = function(self)
	return self:isLock() or self:isLeafNode() or self:isNamed() or self:isLock2()
end

BlockGroup.setLock2 = function(self, lock)
	--assert(not self.isleaf)
	self.lock2dirty = (not self.islock2 ~= not lock)
	self.islock2 = lock

	-- local bs = {}
	-- self:getBlocks(bs)
	-- for i, b in ipairs(bs) do
	-- 	b.oldmtl = b:getMaterial()
	-- 	b:setMaterial(Global.MtlBuildCorrect)
	-- 	b.node.mesh.material:useLerpState(2)
	-- 	b.node.instanceGroup = 'blink'
	-- end

	-- self.timer:start('repairmtl', 600, function()
	-- 	for i, b in ipairs(bs) do
	-- 		b:setMaterial(b.oldmtl)
	-- 		b.oldmtl = nil
	-- 		b.node.instanceGroup = ''
	-- 	end

	-- 	self.timer:stop('repairmtl')
	-- end)
end

BlockGroup.isLock2 = function(self)
	return self.islock2
end

BlockGroup.isLock2Dirty = function(self)
	return self.lock2dirty
end

BlockGroup.resetLock2Dirty = function(self)
	self.lock2dirty = false
end

-- 不可解锁的锁
BlockGroup.setDeadLock = function(self, lock)
	if lock then
		self:setLock(true)
	end

	self.isdeadlock = lock
end

BlockGroup.isDeadLock = function(self)
	return self.isdeadlock
end

BlockGroup.clearData = function(self)
	assert(not self.isleaf)

	-- self:setDeadLock(false)
	-- self:setLock(false)
	-- for i = #self, 1, -1 do
	-- 	local b = self[i]
	-- 	table.remove(self, i)
	-- 	b.blockGroup = nil
	-- end

	for i = #self.children, 1, -1 do
		local c = self.children[i]
		self:removeChildIndex(i)
	end

	self:setKnotCombineDirty()
end

BlockGroup.clear = function(self)
	self:setDeadLock(false)
	self:setLock(false)

	self:setParent(nil)
	if self.isleaf then
		-- donothing
	else
		for i = #self.children, 1, -1 do
			local c = self.children[i]
			self:removeChildIndex(i)
			c:clear()
		end
	end

	self:setKnotCombineDirty()
end

BlockGroup.getAABB = function(self, ab, mode)
	if self.isdirty or (not self.aabb) then
		self.aabb = self.aabb or _AxisAlignedBox.new()
		local nbs = {}
		self:getBlocks(nbs, mode)

		Block.getAABBs(nbs, self.aabb)
		self.isdirty = false
	end

	if ab then ab:set(self.aabb) end
	return self.aabb
end

BlockGroup.getKnotGroup = function(self)
	if not self:isValid() then
		return nil
	end

	if self:isLeafNode() then
		local b = self:getBlockNode()
		return b:getKnotGroup()
	end

	if not self.knotGroup then
		self.knotGroup = KnotGroup.new()
		self.isKnotCombineDirty = true
	end

	if self.isKnotCombineDirty then
		--local t1 = _tick()
		local kgs = {}

		for i, g in ipairs(self.children) do
			local kg = g:getKnotGroup()
			if kg then
				table.insert(kgs, kg)
			end
		end

		--local t2 = _tick()

		self.knotGroup:setChildren(kgs)
		self.knotGroup:bind(self.transform)

		--local t3 = _tick()
		--print('getKnotGroup bind', #kgs, t4 - t1, t2 - t1, t3 - t2, t4 - t3)

		-- local ks = {}
		-- self.knotGroup:getKnots(0, ks)
		-- for _, k in ipairs(ks) do
		-- 	if math.floatEqualVector3(k:getNormal(), Global.AXIS.Z) then
		-- 		print('============', _, k, k:getPos1(), k.bindmat2 or k.bindmat, k.pos1)
		-- 	end
		-- end

		self.isKnotCombineDirty = false
	end

	return self.knotGroup
end

BlockGroup.setKnotCombineDirty = function(self)
	self.isKnotCombineDirty = true
end

BlockGroup.getBlockCount = function(self)
	if self:isLeafNode() then
		return 1
	end

	local n = 0
	for i, c in ipairs(self.children) do
		n = n + c:getBlockCount()
	end

	return n
end

BlockGroup.getConnects = function(self, groups, skipparent)
	if not groups[self] then
		groups[self] = true

		if not skipparent then
			local p = self.parent
			if p then
				p:getConnects(groups)
			end
		end
		for i, g in pairs(self.children) do
			g:getConnects(groups)
		end
	end
end

BlockGroup.getChildrenCount = function(self)
	return self.children and #self.children or 0
end

BlockGroup.setNamed = function(self, named)
	self.isnamed = named
end

BlockGroup.isNamed = function(self)
	return self.isnamed
end

BlockGroup.mergeGroup = function(self, srcgroup)
	assert(not self:isStatic())
	assert(not srcgroup.parent or srcgroup.isTempRoot)
	srcgroup.isTempRoot = nil

	if srcgroup:isStatic() then
		self:addChild(srcgroup)
	else
		for i = #srcgroup.children, 1, -1 do
			local c = srcgroup.children[i]
			self:addChild(c)
		end
	end
end

BlockGroup.getTempRoot = function(self)
	local p = self
	while p.parent and not p.isTempRoot do
		p = p.parent
	end

	return p
end

BlockGroup.setTempRoot = function(self, temproot)
	self.isTempRoot = temproot
end

BlockGroup.getRoot = function(self)
	local p = self
	while p.parent do
		p = p.parent
	end

	return p
end

BlockGroup.getLockParent = function(self, inner)
	local p, c = self, nil

	if p.islock then
		c = p
		if inner then return c end
	end
	while p.parent and not p.isTempRoot do
		p = p.parent
		if p.islock then
			c = p
			if inner then return c end
		end
	end

	return c
end

BlockGroup.getLock2Parent = function(self, inner)
	local p, c = self, nil

	if p.islock2 then
		c = p
		if inner then return c end
	end
	while p.parent and not p.isTempRoot do
		p = p.parent
		if p.islock2 then
			c = p
			if inner then return c end
		end
	end

	return c
end

-- 清除group的连接信息
BlockGroup.clearCONs = function(self)
	local bs = {}
	self:getBlocks(bs)

	for i, b in ipairs(bs) do
		b:clearOverlaps()
		b:clearNeighbors()
		b:clearConnects()
	end
end

BlockGroup.clearOuterCONs = function(self, keepsbs)
	local bs = {}
	self:getBlocks(bs)

	--设置需要保留ONC
	local keeps = {}
	for i, b in ipairs(bs) do
		keeps[b] = true
	end

	if keepsbs then
		for i, b in ipairs(keepsbs) do
			keeps[b] = true
		end
	end

	for i, b in ipairs(bs) do
		b:clearOverlaps(keeps)
		b:clearNeighbors(keeps)
		b:clearConnects(keeps)
	end
end

BlockGroup.clearOuterCollisions = function(self)
	local kg = self:getKnotGroup()
	if kg then kg:clearOutCollisions() end
end

-- 获取group的外部的连接信息
BlockGroup.getOuterCONs = function(self, filterbs, bshash)
	local bs = {}
	self:getBlocks(bs)

	--设置需要保留ONC
	local hbs = {}
	for i, b in ipairs(bs) do
		hbs[b] = true
	end

	local connects = {}
	local overlaps = {}
	local neighbors = {}

	for i, block in ipairs(bs) do
		-- for b, data in pairs(block.connects) do
		-- 	if not hbs[b] and (not filterbs or filterbs[b]) then
		-- 		table.insert(connects, data)
		-- 		if bshash then bshash[b] = true end
		-- 	end
		-- end
		for b, data in pairs(block.overlaps) do
			if not hbs[b] and (not filterbs or filterbs[b]) then
				table.insert(overlaps, {b1 = block, b2 = b})
				if bshash then bshash[b] = true end
			end
		end
		for b, data in pairs(block.neighbors) do
			if not hbs[b] and (not filterbs or filterbs[b]) then
				table.insert(neighbors, {b1 = block, b2 = b})
				if bshash then bshash[b] = true end
			end
		end
	end

	return connects, overlaps, neighbors
end

BlockGroup.checkNullOuterCONs = function(self, filterbs)
	local c, o, n = self:getOuterCONs()
	if next(c) or next(o) or next(n) then
		return false
	end
	return true
end

-- 获取group的内部的连接信息
BlockGroup.getInnerCONs = function(self)
	local bs = {}
	self:getBlocks(bs)

	--设置需要保留CON
	local hbs = {}
	for i, b in ipairs(bs) do
		hbs[b] = true
	end

	local connects = {}
	local overlaps = {}
	local neighbors = {}

	for i, block in ipairs(bs) do
		for b, data in pairs(block.connects) do
			if hbs[b] then
				table.insert(connects, data)
			end
		end
		for b, data in pairs(block.overlaps) do
			if hbs[b] then
				table.insert(overlaps, {b1 = block, b2 = b})
			end
		end
		for b, data in pairs(block.neighbors) do
			if hbs[b] then
				table.insert(neighbors, {b1 = block, b2 = b})
			end
		end
	end

	return connects, overlaps, neighbors
end

local maxblockn, maxchildn = 16, 16
function _G.CombineGroupByCons(connects, overlaps, neighbors, checklock2)
	local function Combine(b1, b2)
		local r1, r2 = b1:getBlockGroup('tempRoot'), b2:getBlockGroup('tempRoot')

		-- b1和b2 已经在同一个组内
		if r1 == r2 then
			return
		end

		local rot1 = r1:isLeafNode() and r1:getBlockNode():hasRotKnot()
		local rot2 = r2:isLeafNode() and r2:getBlockNode():hasRotKnot()
		-- print('000000000', rot1, rot2, r1:isLock2(), r2:isLock2())

		local g
		if not r1:isStatic() then
			r1:mergeGroup(r2)
			g = r1
		elseif not r2:isStatic() then
			r2:mergeGroup(r1)
			g = r2
		else
			local b = r1:getFirstBrick()
			local bb = b and b.node.scene.BuildBrick

			g = bb:newGroup()
			g:addChild(r1)
			g:addChild(r2)
		end

		if checklock2 then
			if r2:isLock2() or rot1 or rot2 then
				g:setLock2(true)
				r2:setLock2(false)
			end
		end

		-- if r1:isLeafNode() and r1:getBlockNode():hasRotKnot() then
		-- 	g:setLock2(true)
		-- 	print('1111111111r1')
		-- end

		-- if r2:isLeafNode() and r2:getBlockNode():hasRotKnot() then
		-- 	print('1111111111r2')
		-- end
	end

	for i, v in ipairs(connects) do
		Combine(v.b1, v.b2)
	end
	for i, v in ipairs(overlaps) do
		Combine(v.b1, v.b2)
	end
	for i, v in ipairs(neighbors) do
		Combine(v.b1, v.b2)
	end
end

BlockGroup.CombineByCONs = function(self)
	local connects, overlaps, neighbors = self:getOuterCONs()

	CombineGroupByCons(connects, overlaps, neighbors, true)
end

BlockGroup.save = function(self, g, keepblock)
	g.islock = self.islock
	g.islock2 = self.islock2
	g.isdeadlock = self.isdeadlock
	g.index = self.index
	g.serialNum = self.serialNum
	g.switchName = self.switchName
	g.switchPart = self.switchPart
	g.isTempRoot = self.isTempRoot

--	if not self.transform:isIdentity() then
--		g.transform = _Matrix3D.new()
--		g.transform:set(self.transform)
--	end

	g.blocks = {}
	if self:isLeafNode() then
		local b = self:getBlockNode()
		table.insert(g.blocks, keepblock and b or b.index)
	else
		g.children = {}
		for i, c in ipairs(self.children) do
			if c:isValid() then
				assert(c.parent == self)
				table.insert(g.children, c.index)
			end
		end
	end
end

BlockGroup.newWithData = function(g, bs, bb)
	if #g.blocks == 1 and (not g.children or #g.children == 0) then
		local bindex = g.blocks[1]
		local b = bs and bs[bindex] or bindex

		local group = b:getBlockGroup()
		group:setParent()
		group:setTempRoot(g.isTempRoot)

		assert(group.isleaf)
--		group.switchName = g.switchName
--		group.switchPart = g.switchPart

		return group
	else
		local group = bb:newGroup()
		group:load(g, bs)
		return group
	end
end

BlockGroup.load = function(self, g, bs)
	assert(not self.parent)

	for _, bindex in ipairs(g.blocks) do
		if bs then
			-- 兼容错误的文件
			local block = bs[bindex]
			if block then
				self:addChild(block:getBlockGroup())
			end
		else
			self:addChild(bindex:getBlockGroup())
		end
	end
	self:setLock(g.islock)
	self:setLock2(g.islock2)
	self:setDeadLock(g.isdeadlock)
	self:setTempRoot(g.isTempRoot)

	self.switchName = g.switchName
	self.switchPart = g.switchPart

--	if g.transform then
--		self.transform:set(g.transform)
--	end
end

-- 组内子元素有缺失时需要重新更新
BlockGroup.recombine = function(self)
	if not self:isValid() then return end

	local p = self.parent

	-- 断开与外部的连接，并保存连接数据
	local oc, oo, on = {}, {}, {}
	if p then
		self:setParent(nil)
		oc, oo, on = self:getOuterCONs()
		self:clearOuterCONs()
	end

	local gs = self:regroup()
	--print('recombine', #gs)

	-- 重新建立与外部的连接
	for i, ds in ipairs(oc) do
		ds.b1:addConnects(ds.b2, ds.s2, ds.s1)
	end
	for i, v in ipairs(oo) do
		v.b1:addOverlaps(v.b2)
	end
	for i, v in ipairs(on) do
		v.b1:addNeighbors(v.b2)
	end

	if self:isLock2() and #gs > 0 then
		for i, g in ipairs(gs) do
			g:setLock2(true)
		end
	end

	CombineGroupByCons(oc, oo, on)
	-- for i, g in ipairs(gs) do
	-- 	g:CombineByCONs()
	-- end
end

BlockGroup.isIntegrated = function(self)
	assert(not self.parent)
	if self:isLeafNode() then return true end
	if #self.children == 0 then return true end

	local subs = {}
	local gs_hash = {}
	for i, g in ipairs(self.children) do
		g.isTempRoot2 = g.isTempRoot
		g.isTempRoot = true
		gs_hash[g] = -1
	end

	local bindgroup
	bindgroup = function(g, sub)
		assert(gs_hash[g])
		if gs_hash[g] ~= -1 then
			return
		end

		if not sub then
			sub = {}
			table.insert(subs, sub)
		end

		sub[g] = true
		gs_hash[g] = sub

		local obs = {}
		g:getOuterCONs(nil, obs)
		local gs = {}
		for b in pairs(obs) do
			local ng = b:getBlockGroup('tempRoot')
			gs[ng] = true
		end

		for ng in pairs(gs) do
			bindgroup(ng, sub)
		end
	end

	for i, g in ipairs(self.children) do
		bindgroup(g)
	end

	for i, g in ipairs(self.children) do
		g.isTempRoot = self.isTempRoot2
		g.isTempRoot2 = nil
	end

	return #subs == 1, subs
end

BlockGroup.regroup = function(self)
	assert(not self.parent)
	if self:isValid() then return {self} end

	local integrated, subs = self:isIntegrated()
	if integrated then
		return {self}
	end

	local b = self:getFirstBrick()
	local bb = b.node.scene.BuildBrick
	-- 无效的组
	if not bb then
		self:clear()
		return {self}
	end

	local subgs = {}
	for i, sub in ipairs(subs) do
		local subg = bb:newGroup()
		for g in pairs(sub) do
			subg:addChild(g)
		end

		table.insert(subgs, subg)
	end

	return subgs
end

------------------- 接口 --------------------

local helpmat = _Matrix3D.new()
BlockGroup.moveCenter = function(self, center)
	local c = _Vector3.new()
	local ab = self:getAABB()
	ab:getCenter(c)

	_Vector3.sub(center, c, c)
	local nbs = {}
	self:getBlocks(nbs)

	for i, b in ipairs(nbs) do
		b.node.transform:mulTranslationRight(c)
		b:formatMatrix()
	end
end

BlockGroup.getCenter = function(self, center)
	local ab = self:getAABB()
	ab:getCenter(center)
end

BlockGroup.getTransform = function(self)
	return self.transform
end
--[[
BlockGroup.getTransform2 = function(self)
	if not self.transform2 then
		self.transform2 = _Matrix3D.new()
	end
	return self.transform2

	--return self.transform
end

BlockGroup.setPivot = function(self, vec)
	local mat = self:getTransform2()
	mat:setPivot(vec)
end

BlockGroup.changeTranslation = function(self, vec)
	local mat = self:getTransform2()

	helpmat:set(mat)
	mat:changeTranslation(vec)
	helpmat:inverse()
	helpmat:mulRight(mat)

	-- TODO:效率测试
	local nbs = {}
	self:getBlocks(nbs)
	for i, b in ipairs(nbs) do
		b.node.transform:mulRight(helpmat)
		-- b:updateSpace()
	end
end

BlockGroup.changeScale = function(self, scale)
	local mat = self:getTransform2()

	helpmat:set(mat)
	mat:changeScale({x = scale, y = scale, z = scale})
	helpmat:inverse()
	helpmat:mulRight(mat)

	local nbs = {}
	self:getBlocks(nbs)
	for i, b in ipairs(nbs) do
		b.node.transform:mulRight(helpmat)
		-- b:updateSpace()
	end
end

BlockGroup.changeRotation = function(self, vec)
	local mat = self:getTransform2()

	helpmat:set(mat)
	mat:changeRotation(vec)
	helpmat:inverse()
	helpmat:mulRight(mat)

	local nbs = {}
	self:getBlocks(nbs)
	for i, b in ipairs(nbs) do
		b.node.transform:mulRight(helpmat)
		-- b:updateSpace()
	end
end

BlockGroup.changeTransform = function(self, value)
	assert(self.isleaf)

	local block = self:getBlockNode()

	if value.typestr == '_Matrix3D' then
		block.node.transform:set(value)
	elseif value.typestr == 'PivotMat' then
		block.node.transform:set(value:getMatrix())
	end
end

BlockGroup.changeInvisible = function(self, value)
	local nbs = {}
	self:getBlocks(nbs)
	for i, b in ipairs(nbs) do
		b:setVisible(not value)
	end
end

BlockGroup.changeMaterial = function(self, value)
	local nbs = {}
	self:getBlocks(nbs)
	for i, b in ipairs(nbs) do
		b:setMaterialBatch(value)
	end
end

BlockGroup.changePaint = function(self, value)
	local nbs = {}
	self:getBlocks(nbs)
	for i, b in ipairs(nbs) do
		b:refreshPaint2(value)
	end
end

BlockGroup.changeAlpha = function(self, alpha, clearblend)
	-- local nbs = {}
	-- self:getBlocks(nbs)
	-- for i, b in ipairs(nbs) do
	-- 	b:changeTransparency(alpha)
	-- end

	assert(self.isleaf)
	local block = self:getBlockNode()
	-- print('changeAlpha', alpha, Global.showTranspanetDummy)
	if alpha == 0 and Global.showTranspanetDummy then
		block:showTransparencyDummyMtl(true)
		block:setVisible(true)
	else
		block:showTransparencyDummyMtl(false)
		--block:changeTransparency(alpha, nil, nil, 'alpha' .. toint(alpha * 20))
		block:changeTransparency(alpha)
		block:setVisible(alpha ~= 0)
	end
end

BlockGroup.setPhysicEnable = function(self, enable)
	local block = self:getBlockNode()
	block:setPhysicEnable(enable)
end
--]]
