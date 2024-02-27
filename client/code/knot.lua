--[[
type1/subtype:
	type1 = 0 : type1 = 1的合并节点
	type1 = 1 : 最常见的凸起和凹陷，没有subtype限制, N代表突起/凹陷的防线
	type1 = 2 : 定轴旋转的节点，subtype = 1/2分别代表轴/爪子, N代表轴的方向
	type1 = 3 : 万象旋转的节点，subtype = 1/2分别代表旋转的球/爪子, N暂时无用
	type1 = 4 : 管状物件和管状空洞
--	type1 = 5 : 十字型条形物件和孔的节点
	
	type1 = 21 - 40 : 特殊点节点, 区分subtype
	type1 = 41 - 60 : 特殊点节点, 不区分subtype
--]]
local Container = _require('Container')

local function getType(type, subtype)
	if type == 0 then
		return KnotManager.PAIRTYPE.POINTS
	elseif type == 1 then
		return KnotManager.PAIRTYPE.POINT
	elseif type == 2 and subtype == 2 then
		return KnotManager.PAIRTYPE.HANDLE_WITHNORMAL
	elseif type == 2 and subtype == 1 then
		return KnotManager.PAIRTYPE.TUBE_FORHANDLE
	elseif type == 3 and subtype == 2 then
		return KnotManager.PAIRTYPE.HANDLE
	elseif type == 3 and subtype == 1 then
		return KnotManager.PAIRTYPE.SPHERE_FORHANDLE
	elseif type == 4 and subtype == 2 then
		return KnotManager.PAIRTYPE.TUBE_BLANK
	elseif type == 4 and subtype == 1 then
		return KnotManager.PAIRTYPE.TUBE
	else
		-- TODO: type > 21
	end

	return KnotManager.PAIRTYPE.POINT
end

local __tostring = function(self)
	return string.format('[Knot] self:%p, serialNum:%d', self, self.serialNum, self.type)
end

local Knot = {}
_G.Knot = Knot
Knot.new = function(data)
	local k = {}
	k.type = KnotManager.PAIRTYPE.POINT
	k.N = 1
	k.Normal = _Vector3.new(0, 0, 1)
	k.Tangent = _Vector3.new(1, 0, 0)
	k.Binormal = _Vector3.new(0, 1, 0)
	k.showKind = 0
	k.radius = 0.06 -- 0.07

	k.tangentMode = Global.KNOTNORMALMODE.X
	k.binormalMode = Global.KNOTNORMALMODE.X

	k.pos1 = _Vector3.new()
	k.pos2 = nil
	k.mat = nil
	k.bindblock = nil
	k.serialNum = GenSerialNum()
	k.collisions = {}
	k.rotpivot = data and data.rotpivot

	setmetatable(k, {__index = Knot, __tostring = __tostring})
	if data then
		if data.subtype then
			k:load(data)
		else
			k:load2(data)
		end
	end

	return k
end

local loadmat = _Matrix3D.new()
local MAT_IDENTITY = _Matrix3D.new()
Knot.load = function(self, data)
	-- self.type = data.type or 1
	-- self.subtype = data.subtype or 1

	self.type = getType(data.type or 1, data.subtype or 1)

	local N = data.N or 1
	self.Normal:set(Global.typeToAxis(N))

	-- 建立坐标系
	if data.N == Global.AXISTYPE.X then
		self.Tangent:set(Global.AXIS.Y)
		self.Binormal:set(Global.AXIS.Z)
	elseif data.N == Global.AXISTYPE.Y then
		self.Tangent:set(Global.AXIS.Z)
		self.Binormal:set(Global.AXIS.X)
	elseif data.N == Global.AXISTYPE.Z then
		self.Tangent:set(Global.AXIS.X)
		self.Binormal:set(Global.AXIS.Y)
	elseif data.N == Global.AXISTYPE.NX then
		self.Tangent:set(Global.AXIS.NZ)
		self.Binormal:set(Global.AXIS.NY)
	elseif data.N == Global.AXISTYPE.NY then
		self.Tangent:set(Global.AXIS.NX)
		self.Binormal:set(Global.AXIS.NZ)
	elseif data.N == Global.AXISTYPE.NZ then
		self.Tangent:set(Global.AXIS.NY)
		self.Binormal:set(Global.AXIS.NX)
	end

	-- 标记连接点间距
	if math.floatEqualVector3(self.Tangent, Global.AXIS.Z) or math.floatEqualVector3(self.Tangent, Global.AXIS.NZ) then
		self.tangentMode = Global.KNOTNORMALMODE.Z
	else
		self.tangentMode = Global.KNOTNORMALMODE.X
	end

	if math.floatEqualVector3(self.Binormal, Global.AXIS.Z) or math.floatEqualVector3(self.Binormal, Global.AXIS.NZ) then
		self.binormalMode = Global.KNOTNORMALMODE.Z
	else
		self.binormalMode = Global.KNOTNORMALMODE.X
	end

	self.showKind = data.showKind or 0

	self.pos1 = _Vector3.new(data.pos[1], data.pos[2], data.pos[3])
	self.radius = 0.06 -- 0.07

	if data.type == 0 then
		self.pos2 = _Vector3.new(data.pos2[1], data.pos2[2], data.pos2[3])
		self.tN = toint(math.abs(self.pos2.x - self.pos1.x) / Global.KNOTDISTANCE[self.tangentMode], 0.5) + 1
		self.bN = toint(math.abs(self.pos2.y - self.pos1.y) / Global.KNOTDISTANCE[self.binormalMode], 0.5) + 1

		--print('1111', self.tN, self.bN, data.pos2[1], data.pos2[2], data.pos2[3], data.pos[1], data.pos[2], data.pos[3])
	elseif data.type == 4 then
		self.pos2 = _Vector3.new()
		local len = data.size[3]
		_Vector3.mul(self.Normal, len, self.pos2)
		_Vector3.sub(self.pos1, self.pos2, self.pos1)

		_Vector3.mul(self.pos2, 2, self.pos2)
		_Vector3.add(self.pos1, self.pos2, self.pos2)
		self.radius = data.size[1]
	end

	self.mat = nil
	self.bindmat = nil

	-- add mat if knot has rx.
	if data.rx and data.ry and data.rz then
		local mat = _Matrix3D.new()
		mat:setRotationX(data.rx)
		mat:mulRotationYRight(data.ry)
		mat:mulRotationZRight(data.rz)
		self.mat = mat

		-- 计算旋转前的位置 TODO: remove it
		loadmat:set(mat)
		loadmat:inverse()
		loadmat:apply(self.pos1, self.pos1)
	end

	self:setTransformDirty()
end

Knot.load2 = function(self, data)
	self.type = data.type
	self.showKind = data.showKind or 0
	self.tangentMode = data.tangentMode or Global.KNOTNORMALMODE.X
	self.binormalMode = data.binormalMode or Global.KNOTNORMALMODE.X
	self.radius = data.radius or 0.6
	self.Normal:set(data.Normal)
	self.Tangent:set(data.Tangent)
	self.Binormal:set(data.Binormal)
	self.pos1:set(data.pos1)

	if data.pos2 then
		self.pos2 = _Vector3.new()
		self.pos2:set(data.pos2)
	else
		self.pos2 = nil
	end

	self.mat = nil
	self.bindblock = nil

	self:setTransformDirty()

	if self.type == 0 then
		self.tN, self.bN = KnotManager.calcTBNumber(self)

		if not data.skipDecompose then
			self.ks = KnotManager.decomposeKnots(self)
		end
	end

	-- if math.floatEqual(self.pos1.y, -0.7) then
	-- 	print('knew', self, debug.traceback())
	-- end
end

local helpv3_1 = _Vector3.new()
Knot.loadFromChildren = function(self, ks, pos1, pos2)
	local k = ks[1]
	self.type = KnotManager.PAIRTYPE.POINTS
	--self.subtype = k.subtype or 1

	--self.N = k.N or 1
	self.Normal = _Vector3.new()
	self.Normal:set(k:getNormal())

	-- 建立坐标系
	self.Tangent = _Vector3.new()
	self.Binormal = _Vector3.new()
	self.Tangent:set(k:getTangent())
	self.Binormal:set(k:getBinormal())
	self.tangentMode = k.tangentMode
	self.binormalMode = k.binormalMode

	self.pos1 = _Vector3.new()
	self.pos2 = _Vector3.new()
	self.pos1:set(pos1)
	self.pos2:set(pos2)

	_Vector3.sub(self.pos2, self.pos1, helpv3_1)
	local tl = _Vector3.dot(helpv3_1, self.Tangent)
	local bl = _Vector3.dot(helpv3_1, self.Binormal)
	self.tN = toint(math.abs(tl) / Global.KNOTDISTANCE[self.tangentMode], 0.5) + 1
	self.bN = toint(math.abs(bl) / Global.KNOTDISTANCE[self.binormalMode], 0.5) + 1
	if #ks ~= self.tN * self.bN then
		-- print('loadFromChildren', self.tN, self.bN, #ks, tl, bl, self.pos2, self.pos1)
		--assert(false)
	end

	-- check showkind and pos
	local showkind = nil
	for i, kk in ipairs(ks) do
		if kk.showKind == 1 or kk.showKind == 2 then
			if not showkind then
				showkind = kk.showKind
			end

			assert(showkind == kk.showKind)
		end
	end

	if not showkind then
		showkind = 0
	end
	self.showKind = showkind

	self.ks = ks
	table.sort(self.ks, function(a, b)
		local t1, b1 = a:getTBDepth()
		local t2, b2 = b:getTBDepth()
		return b1 < b2 or (b1 == b2 and t1 < t2)
	end)

	self.mat = nil
	self.bindmat = nil

	-- if math.floatEqual(self.pos1.y, -0.7) then
	-- 	print('knew222222', self, debug.traceback())
	-- end

	self:setTransformDirty()
end

Knot.getShowKind = function(self)
	return self.showKind
end

Knot.setTransformDirty = function(self)
	self.transDirty = true

	if self.ks then
		for i, k in ipairs(self.ks) do
			k:setTransformDirty()
		end
	end
end

local temp_mat = _Matrix3D.new()
Knot.updateTransform = function(self)
	if not self.transDirty then
		return
	end

	-- mat没有旋转时合并mat和pos等信息
	if self.mat and not self.mat:hasRotation2() then
		self.mat:apply(self.pos1, self.pos1)
		--self.N = Global.getRotaionAxisType(self.N, self.mat)
		Global.getRotaionAxis(self.Normal, self.mat, self.Normal)

		if self.pos2 then
			self.mat:apply(self.pos2, self.pos2)
		end

		self.mat = nil
	end

	-- update cache
	local mat = temp_mat
	local bindmat = self.bindmat or self.bindmat2
	if self.mat then
		mat:set(self.mat)

		if bindmat then
			mat:mulRight(bindmat)
		end
	else
		if bindmat then
			mat:set(bindmat)
		else
			mat:identity()
		end
	end

	if not self.cache then
		local cache = {}
		cache.pos1 = _Vector3.new()
		cache.pos2 = _Vector3.new()
		cache.Normal = _Vector3.new()
		cache.Tangent = _Vector3.new()
		cache.Binormal = _Vector3.new()
		cache.N = 1
		cache.norot = true
		cache.depth = 0
		self.cache = cache
	end

	local cache = self.cache
	mat:apply(self.pos1, cache.pos1)
	if self.pos2 then
		mat:apply(self.pos2, cache.pos2)
	end

	Global.getRotaionAxis(self.Normal, mat, cache.Normal)
	Global.getRotaionAxis(self.Tangent, mat, cache.Tangent)
	Global.getRotaionAxis(self.Binormal, mat, cache.Binormal)

	cache.N, cache.norot = Global.getNearestAxisType(cache.Normal)
	cache.depth = _Vector3.dot(cache.Normal, cache.pos1) -- 深度

	cache.t_depth1 = _Vector3.dot(cache.Tangent, cache.pos1)
	cache.b_depth1 = _Vector3.dot(cache.Binormal, cache.pos1)
	if self.pos2 then
		cache.t_depth2 = _Vector3.dot(cache.Tangent, cache.pos2)
		cache.b_depth2 = _Vector3.dot(cache.Binormal, cache.pos2)
	end

	self.transDirty = false
end

Knot.mul = function(self, mat)
	if not self.mat then
		self.mat = mat:clone()
	else
		self.mat:mulRight(mat)
	end

	self:setTransformDirty()
end

-- for basic
Knot.bind = function(self, mat)
	self.bindmat = mat
	if self.ks then
		for i, k in ipairs(self.ks) do
			k:bind(mat)
		end
	end
	self:setTransformDirty()
end

Knot.isbasic = function(self, mat)
	return self.bindmat ~= nil
end

-- for none basic
Knot.bindParent = function(self, mat)
	if not self.bindmat2 then
		self.bindmat2 = _Matrix3D.new()
	end

	self.bindmat2:unbindParent()
	self.bindmat2:bindParent(mat)
	--print('bindParent', self.bindmat2, mat)
	self:setTransformDirty()

	-- if self.ks then
	-- 	local depth = self:getDepth()
	-- 	for i, k in ipairs(self.ks) do
	-- 		if not math.floatEqual(depth, k:getDepth()) then
	-- 			print('binderr', i, depth, k:getDepth(), self:getNormal(), k:getNormal(), self:getPos1(), k:getPos1())
	-- 			assert(false)
	-- 		end
	-- 	end
	-- end
end

Knot.isbind = function(self, mat)
	return self.bindmat2 ~= nil or self.bindmat ~= nil
end

-- Knot.bind = function(self, mat)
-- 	self.bindmat = mat
-- 	self:setTransformDirty()
-- end

Knot.addCollision = function(self, k)
	assert(self:getType() ~= KnotManager.PAIRTYPE.POINTS and k:getType() ~= KnotManager.PAIRTYPE.POINTS)

	self.collisions[k] = true
	k.collisions[self] = true
end

Knot.delCollision = function(self, k)
	if self.collisions[k] then
		self.collisions[k] = nil
		k.collisions[self] = nil
	end
end

Knot.clearCollisions = function(self, keeps_hash)
	for k in pairs(self.collisions) do
		if not keeps_hash or not keeps_hash[k] then
			self:delCollision(k)
		end
	end
end

Knot.getCollisions = function(self, ks_hash, ignore_hash)
	for k in pairs(self.collisions) do
		if not ignore_hash or not ignore_hash[k] then
			ks_hash[k] = true
		end
	end
end

Knot.isCollision = function(self)
	if self:getType() == KnotManager.PAIRTYPE.POINTS then
		for i, k in ipairs(self.ks) do
			if k:isCollision() then
				return true
			end
		end

		return false
	else
		return next(self.collisions) ~= nil
	end
end

Knot.canCombine = function(self)
	return self.type == KnotManager.PAIRTYPE.POINT or self.type == KnotManager.PAIRTYPE.POINTS
end

Knot.getNormal = function(self, forceupdate)
	if forceupdate then
		self:setTransformDirty()
	end

	self:updateTransform()

	return self.cache.Normal
end

Knot.getTangent = function(self, forceupdate)
	if forceupdate then
		self:setTransformDirty()
	end

	self:updateTransform()

	return self.cache.Tangent
end

Knot.getBinormal = function(self, forceupdate)
	if forceupdate then
		self:setTransformDirty()
	end

	self:updateTransform()

	return self.cache.Binormal
end

Knot.getTangentMode = function(self)
	return self.tangentMode
end

Knot.getBinormalMode = function(self)
	return self.binormalMode
end

Knot.getTangentN = function(self)
	return self.type == KnotManager.PAIRTYPE.POINTS and self.tN
end

Knot.getBinormalN = function(self)
	return self.type == KnotManager.PAIRTYPE.POINTS and self.bN
end

Knot.getKsN = function(self)
	return self.type == KnotManager.PAIRTYPE.POINTS and self.bN * self.tN
end

Knot.getTangentStep = function(self)
	return Global.KNOTDISTANCE[self.tangentMode]
end

Knot.getBinormalStep = function(self)
	return Global.KNOTDISTANCE[self.binormalMode]
end

Knot.enumChildren = function(self, f)
	if self.ks then
		for i, k in ipairs(self.ks) do
			if k.type == KnotManager.PAIRTYPE.POINTS then
				k:enumChildren(f)
			else
				f(k)
			end
		end
	else
		if self.type ~= KnotManager.PAIRTYPE.POINTS then
			f(self)
		end
	end
end

Knot.getNearestN = function(self, forceupdate)
	if forceupdate then
		self:setTransformDirty()
	end

	self:updateTransform()

	return self.cache.N
end

Knot.getDepth = function(self, forceupdate)
	if forceupdate then
		self:setTransformDirty()
	end

	self:updateTransform()

	return self.cache.depth
end

Knot.getTBDepth = function(self, forceupdate)
	if forceupdate then
		self:setTransformDirty()
	end

	self:updateTransform()

	local c = self.cache
	return c.t_depth1, c.b_depth1, c.t_depth2, c.b_depth2
end

Knot.isNormalRotation = function(self, forceupdate)
	if forceupdate then
		self:setTransformDirty()
	end

	self:updateTransform()

	return not self.cache.norot
end

Knot.getPos1 = function(self, forceupdate)
	if forceupdate then
		self:setTransformDirty()
	end

	self:updateTransform()

	return self.cache.pos1
end

Knot.getPos2 = function(self, forceupdate)
	if forceupdate then
		self:setTransformDirty()
	end

	self:updateTransform()

	return self.cache.pos2
end

Knot.getType = function(self)
	return self.type
end

Knot.getRadius = function(self)
	return self.radius
end

Knot.projectTo = function(self, projdata, out, forceupdate)
	--return self.type, self.subtype
	local pos1 = self:getPos1(forceupdate)

	out.depth = _Vector3.dot(projdata.Normal, pos1) -- 深度
	out.t_depth1 = _Vector3.dot(projdata.Tangent, pos1)
	out.b_depth1 = _Vector3.dot(projdata.Binormal, pos1)

	if self.pos2 then
		local pos2 = self:getPos2()
		out.t_depth2 = _Vector3.dot(projdata.Tangent, pos2)
		out.b_depth2 = _Vector3.dot(projdata.Binormal, pos2)

		if self.type == KnotManager.PAIRTYPE.POINTS then
			local T = self:getTangent()
			local B = self:getBinormal()

			local tx = _Vector3.dot(projdata.Tangent, T)
			local ty = _Vector3.dot(projdata.Binormal, T)
			out.t_dir = _Vector2.new(tx, ty)

			local bx = _Vector3.dot(projdata.Tangent, B)
			local by = _Vector3.dot(projdata.Binormal, B)
			out.b_dir = _Vector2.new(bx, by)

			-- local tstep = self:getTangentStep()
			-- local bstep = self:getBinormalStep()

			-- _Vector3.mul(T, tstep * self.tN, helpv3_1)
			-- _Vector3.add(helpv3_1, pos1, helpv3_1)
			-- out.t_depth12 = _Vector3.dot(projdata.Tangent, helpv3_1)
			-- out.b_depth12 = _Vector3.dot(projdata.Binormal, helpv3_1)

			-- _Vector3.mul(B, bstep * self.bN, helpv3_1)
			-- _Vector3.add(helpv3_1, pos1, helpv3_1)
			-- out.t_depth21 = _Vector3.dot(projdata.Tangent, helpv3_1)
			-- out.b_depth21 = _Vector3.dot(projdata.Binormal, helpv3_1)
		end
	end
end

local function addRotData(mode, pos, axis)
	local data = {}
	data.mode = mode
	data.pos = pos
	data.axis = axis
	return data
end

Knot.isRotPairs = function(self, k)
	local t, kt = self:getType(), k:getType()
	--print('isRotPairs', t, kt)
	local pts = KnotManager.getPairTypes(t)
	local find = false
	for i, v in ipairs(pts) do
		if v == kt then
			find = true
			break
		end
	end

	if not find then return end

	if t == KnotManager.PAIRTYPE.HANDLE_WITHNORMAL or t == KnotManager.PAIRTYPE.TUBE_FORHANDLE then
		if Global.isAxisSameLine(self:getNormal(), k:getNormal()) then
			return addRotData(2, self:getPos1(), self:getNormal())
		end
	elseif t == KnotManager.PAIRTYPE.HANDLE or t == KnotManager.PAIRTYPE.SPHERE_FORHANDLE then
		return addRotData(3, self:getPos1(), nil)
	elseif t == KnotManager.PAIRTYPE.TUBE or t == KnotManager.PAIRTYPE.TUBE_BLANK then
		if kt == KnotManager.PAIRTYPE.HANDLE_WITHNORMAL and Global.isAxisSameLine(self:getNormal(), k:getNormal()) then
			return addRotData(2, k:getPos1(), k:getNormal())
		end
	end
end

Knot.getRotData = function(self)
	local t = self:getType()
	-- if not self.rotpivot then return end
	if t == KnotManager.PAIRTYPE.HANDLE_WITHNORMAL or t == KnotManager.PAIRTYPE.TUBE_FORHANDLE then
		return addRotData(2, self:getPos1(true), self:getNormal(true))
	elseif t == KnotManager.PAIRTYPE.HANDLE or t == KnotManager.PAIRTYPE.SPHERE_FORHANDLE then
		return addRotData(3, self:getPos1(true), nil)
	elseif t == KnotManager.PAIRTYPE.TUBE or t == KnotManager.PAIRTYPE.TUBE_BLANK then
		return addRotData(2, self:getPos1(true), self:getNormal(true))
	end
end

Knot.hasRotData = function(self)
	local t = self:getType()
	-- if not self.rotpivot then return end
	if t == KnotManager.PAIRTYPE.HANDLE_WITHNORMAL or t == KnotManager.PAIRTYPE.TUBE_FORHANDLE then
		return true
	elseif t == KnotManager.PAIRTYPE.HANDLE or t == KnotManager.PAIRTYPE.SPHERE_FORHANDLE then
		return true
	elseif t == KnotManager.PAIRTYPE.TUBE or t == KnotManager.PAIRTYPE.TUBE_BLANK then
		return true
	end
end