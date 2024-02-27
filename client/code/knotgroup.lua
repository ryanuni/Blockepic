
local __tostring = function(self)
	return string.format('[KnotGroup] self:%p, serialNum:%d', self, self.serialNum)
end

local KnotGroup = {}
_G.KnotGroup = KnotGroup
KnotGroup.new = function()
	local k = {}
	setmetatable(k, {__index = KnotGroup, __tostring = __tostring})
	k.knots = {}
	k.children = {}
	k.ksindexs = {}
	k.ks0 = {}
	k.ks1 = {}
	k.ks2 = {}
	k.dirty = false
	k.parent = nil
	k.serialNum = GenSerialNum()

	k.mat = nil
	k.bindmat = nil

	return k
end
--[[
KnotGroup.mul = function(self, mat)
	for i, k in ipairs(self.knots) do
		if not k:hasbind() then
			k:mul(mat)
		else
			k:setTransformDirty()
		end
	end

	for i, k in ipairs(self.ks0) do
		if not k:hasbind() then
			k:mul(mat)
		else
			k:setTransformDirty()
		end
	end

	for i, k in ipairs(self.ks1) do
		if not k:hasbind() then
			k:mul(mat)
		else
			k:setTransformDirty()
		end
	end

	for i, k in ipairs(self.ks2) do
		if not k:hasbind() then
			k:mul(mat)
		else
			k:setTransformDirty()
		end
	end
end

KnotGroup.bind = function(self, mat)
	for i, k in ipairs(self.knots) do
		if not k:isbasic() then
			k:bindParent(mat)
		else
			k:setTransformDirty()
		end
	end

	for i, k in ipairs(self.ks0) do
		if not k:isbasic() then
			k:bindParent(mat)
		else
			k:setTransformDirty()
		end
	end

	for i, k in ipairs(self.ks1) do
		if not k:isbasic() then
			k:bindParent(mat)
		else
			k:setTransformDirty()
		end
	end

	for i, k in ipairs(self.ks2) do
		if not k:isbasic() then
			k:bindParent(mat)
		else
			k:setTransformDirty()
		end
	end
end
--]]
KnotGroup.bind = function(self, mat)
	--print('KnotGroupbind', mat)
	for i, k in ipairs(self.knots) do
		if not k:isbind() then
			--print(' bindks1111', i, k)
			k:bindParent(mat)
		else
			k:setTransformDirty()
		end
	end

	for i, k in ipairs(self.ks0) do
		if not k:isbind() then
			--print(' bindks0', i, k)
			k:bindParent(mat)
		else
			k:setTransformDirty()
		end
	end
--[[
	for i, k in ipairs(self.ks1) do
		if not k:isbind() then
			--print(' bindks1', i, k)
			k:bindParent(mat)
		else
			k:setTransformDirty()
		end
	end

	for i, k in ipairs(self.ks2) do
		if not k:isbind() then
			--print(' bindks2', i, k)
			k:bindParent(mat)
		else
			k:setTransformDirty()
		end
	end
--]]
	self.bindmat = mat
end

KnotGroup.setDirty = function(self)
	for i, k in ipairs(self.knots) do
		k:setTransformDirty()
	end

	for i, k in ipairs(self.ks0) do
		k:setTransformDirty()
	end
	-- for i, k in ipairs(self.ks1) do
	-- 	k:setTransformDirty()
	-- end
	-- for i, k in ipairs(self.ks2) do
	-- 	k:setTransformDirty()
	-- end
end

KnotGroup.addKnots = function(self, knots)
	for i, k in ipairs(knots) do
		table.insert(self.knots, k)
	end

	self:updateKnots()
end

KnotGroup.setChildren = function(self, kgs, noopt)
	local t1 = _tick()
	self.children = kgs

	self.knots = {}
	self.ksindexs = {}
	for i, kg in ipairs(self.children) do
		--kg:AssertCollosion()

		local n = #self.knots
		table.fappendArray(self.knots, kg.ks0, function(k)
			return k:getType() == KnotManager.PAIRTYPE.POINTS or not k:isCollision()
		end)
		-- table.fappendArray(self.knots, kg.ks1)
		-- table.fappendArray(self.knots, kg.ks2)
		--print('setChildren', i, #self.knots, #kg.ks0, #kg.ks1, #kg.ks2)

		-- 记录索引信息
		local indexs = {}
		indexs.index = i
		indexs.i1 = n + 1
		indexs.i2 = #self.knots
		self.ksindexs[kg] = indexs

		kg.parent = self
	end

	local t2 = _tick()

	for i, k in ipairs(self.knots) do
		k:updateTransform()
	end

	local t3 = _tick()

	self:updateKnots(noopt)

	local t4 = _tick()
	-- print('setChildren', #self.knots, #self.ks0, t4 - t1, t2 - t1, t3 - t2, t4 - t3)
end

KnotGroup.addChildren = function(self, kgs, noopt)
	for i, kg in ipairs(kgs) do
		assert(not self.ksindexs[kg])

		kg.parent = self
		table.insert(self.children, kg)

		local n = #self.knots
		table.fappendArray(self.knots, kg.ks0, function(k)
			return k:getType() == KnotManager.PAIRTYPE.POINTS or not k:isCollision()
		end)
		-- table.fappendArray(self.knots, kg.ks1)
		-- table.fappendArray(self.knots, kg.ks2)

		-- 记录索引信息
		local indexs = {}
		indexs.index = #self.children
		indexs.i1 = n + 1
		indexs.i2 = #self.knots
		self.ksindexs[kg] = indexs
	end
	self:updateKnots(noopt)
end

KnotGroup.updateKnots = function(self, noopt)
	local ks0, ks1, ks2 = {}, {}, {}
	for i, k in ipairs(self.knots) do
		table.insert(ks0, k)
		--local showkind = k:getShowKind()
		-- if showkind == 0 then
		-- 	table.insert(ks0, k)
		-- elseif showkind == 1 then
		-- 	table.insert(ks1, k)
		-- elseif showkind == 2 then
		-- 	table.insert(ks2, k)
		-- end
	end

	if noopt then
		self.ks0 = ks0
		-- self.ks1 = ks1
		-- self.ks2 = ks2
	else
		self.ks0 = self:optimiseKnots(ks0)
		-- self.ks1 = self:optimiseKnots(ks1)
		-- self.ks2 = self:optimiseKnots(ks2)
	end

	-- self:AssertCollosion()
end

KnotGroup.AssertCollosion = function(self)
	for i, k in ipairs(self.ks0) do
		if k:isCollision() then
			print('AssertCollosion:', i, k:getPos1(), self, #self.ks0)
			assert(false)
		end
	end
end

KnotGroup.optimiseKnots = function(self, ks)
	if #ks == 0 then return {} end
	local t1 = _tick()
	-- print('optimiseKnots0', #ks)
	ks = _G.KnotManager.filterCollision(ks)

	local t2 = _tick()
	-- print('optimiseKnots1', #ks, t2 - t1)
	ks = _G.KnotManager.combine(ks)
	local t3 = _tick()
	-- print('optimiseKnots2', #ks, t3 - t2)

	return ks
end

-- 删除子后更新索引
KnotGroup.updateKsindexs_remove = function(self, index, i1, i2)
	local n = i2 - i1 + 1

	for v in pairs(self.ksindexs) do
		if v.i2 > i2 then
			v.i2 = v.i2 - n
			v.i1 = v.i1 - n
		end

		if v.index > index then
			v.index = v.index - 1
		end
	end
end

KnotGroup.removeChild = function(self, kgs)
	for i, kg in ipairs(kgs) do
		if self.ksindexs[kg] then
			local indexs = self.ksindexs[kg]

			table.remove(self.children, indexs.index)
			self.ksindexs[kg] = nil

			for ii = indexs.i2, indexs.i1, -1 do
				table.remove(self.knots, ii)
			end

			self:updateKsindexs_remove(indexs.index, indexs.i1, indexs.i2)
		end
	end
end

KnotGroup.getKnots = function(self, showkind, ks)
	-- if showkind == 1 then
	-- 	table.fappendArray(ks, self.ks0)
	-- 	table.fappendArray(ks, self.ks1)
	-- elseif showkind == 2 then
	-- 	table.fappendArray(ks, self.ks0)
	-- 	table.fappendArray(ks, self.ks2)
	-- else
	-- 	table.fappendArray(ks, self.ks0)
	-- 	table.fappendArray(ks, self.ks1)
	-- 	table.fappendArray(ks, self.ks2)
	-- end

	table.fappendArray(ks, self.ks0)
end

KnotGroup.getBasicKnots = function(self, ks_hash)
	for i, k in ipairs(self.ks0) do
		k:enumChildren(function(kk)
			ks_hash[kk] = true
		end)
	end
end

KnotGroup.getCollisions = function(self, ks_hash)
	for i, k in ipairs(self.ks0) do
		k:enumChildren(function(kk)
			kk:getCollisions(ks_hash)
		end)
	end
end

KnotGroup.clearCollisions = function(self)
	for i, k in ipairs(self.ks0) do
		k:enumChildren(function(kk)
			kk:clearCollisions()
		end)
	end
end

KnotGroup.clearOutCollisions = function(self)
	local ks_hash = {}
	self:getBasicKnots(ks_hash)

	for i, k in ipairs(self.ks0) do
		k:enumChildren(function(kk)
			kk:clearCollisions(ks_hash)
		end)
	end
end

