local KnotManager = {}
_G.KnotManager = KnotManager

local help_v3 = _Vector3.new()
local pos1_v3 = _Vector3.new()
local pos2_v3 = _Vector3.new()
local mat_help = _Matrix3D.new()

-------------------------------------------------------------

KnotManager.new_composeKnots = function(ks)
	local k0 = ks[1]
	local k = Knot.new()

	k.type = 0
	k.subtype = k0.subtype or 1

	k.N = k0.N or 1
	k.Normal = _Vector3.new()
	k.Normal:set(k0.Normal)

	-- 建立坐标系
	k.Tangent = _Vector3.new()
	k.Binormal = _Vector3.new()
	k.Tangent:set(k0.Tangent)
	k.Binormal:set(k0.Binormal)
	k.tangentMode = k0.tangentMode
	k.binormalMode = k0.binormalMode

	k.type = 0
	k.ks = ks
	table.sort(ks, function(a, b)
		local t1, b1 = a:getTBDepth()
		local t2, b2 = b:getTBDepth()
		return b1 < b2 or (b1 == b2 and t1 < t2)
	end)

	local k1, k9 = ks[1], ks[#ks]
	k.pos1 = _Vector3.new()
	k.pos2 = _Vector3.new()
	k.pos1:set(k1:getPos1())
	k.pos2:set(k9:getType() == 0 and k9:getPos2() or k9:getPos1())

	_Vector3.sub(k.pos2, k.pos1, help_v3)
	local tl = _Vector3.dot(help_v3, k.Tangent)
	local bl = _Vector3.dot(help_v3, k.Binormal)
	k.tN = toint(math.abs(tl) / Global.KNOTDISTANCE[k.tangentMode], 0.5)
	k.bN = toint(math.abs(bl) / Global.KNOTDISTANCE[k.binormalMode], 0.5)

	-- 设置showkind
	local showkind = nil
	for i, kk in ipairs(ks) do
		local type = kk:getType()
		assert(type == 0 or type == 1)

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
	k.showKind = showkind

	k.mat = nil
	k.bindblock = nil
	k:setTransformDirty()
end

KnotManager.copyBasicKnotData = function(data, k)
	data.type = k:getType()
	data.showKind = k:getShowKind()
	data.tangentMode = k:getTangentMode()
	data.binormalMode = k:getBinormalMode()
	data.radius = k:getRadius()

	data.Normal = _Vector3.new()
	data.Normal:set(k:getNormal())

	data.Tangent = _Vector3.new()
	data.Tangent:set(k:getTangent())

	data.Binormal = _Vector3.new()
	data.Binormal:set(k:getBinormal())

	data.pos1 = _Vector3.new()
	data.pos1:set(k:getPos1())

	if data.pos2 then
		data.pos2 = _Vector2.new()
		data.pos2:set(data.pos1:set(k:getPos1()))
	else
		data.pos2 = nil
	end
end

local helpv3_1 = _Vector3.new()
KnotManager.calcTBNumber = function(k)
	assert(k.type == KnotManager.PAIRTYPE.POINTS)

	_Vector3.sub(k:getPos2(), k:getPos1(), helpv3_1)
	local tl = _Vector3.dot(helpv3_1, k:getTangent())
	local bl = _Vector3.dot(helpv3_1, k:getBinormal())

	local tN = toint(math.abs(tl) / k:getTangentStep(), 0.5) + 1
	local bN = toint(math.abs(bl) / k:getBinormalStep(), 0.5) + 1

	return tN, bN
end
KnotManager.decomposeKnots = function(k)
	assert(k.type == KnotManager.PAIRTYPE.POINTS)

	local tN, bN = k.tN, k.bN

	local data = {}
	KnotManager.copyBasicKnotData(data, k)
	data.type = KnotManager.PAIRTYPE.POINT
	data.pos2 = nil

	local ks = {}
	for i = 1, bN do
		local bv = _Vector3.new()
		_Vector3.mul(k:getBinormal(), (i - 1) * k:getBinormalStep(), bv)
		_Vector3.add(bv, k:getPos1(), bv)

		for j = 1, tN do
			_Vector3.mul(k:getTangent(), (j - 1) * k:getTangentStep(), data.pos1)
			_Vector3.add(data.pos1, bv, data.pos1)

			local knot = Knot.new()
			knot:load2(data)
			table.insert(ks, knot)
		end
	end

	return ks
end

local function formata2b(a, b, h)
	local formatter = "%s%s = %s,"
	return string.format(formatter, h, a, b)
end
local function float2string(x)
	return string.format('%.6f', x)
end
local function vec32string(v3)
	local str = '_Vector3.new(%s,%s,%s)'
	return string.format(str, float2string(v3.x), float2string(v3.y), float2string(v3.z))
end

KnotManager.tostring = function(k)
	local type = k:getType()

	local hastb = type == KnotManager.PAIRTYPE.POINTS or type == KnotManager.PAIRTYPE.POINT

	local strtb = {}
	table.insert(strtb, '{')
	table.insert(strtb, formata2b('type', type, ''))
	table.insert(strtb, formata2b('showKind', k:getShowKind(), ''))
	table.insert(strtb, formata2b('tangentMode', hastb and k.tangentMode or Global.KNOTNORMALMODE.X, ''))
	table.insert(strtb, formata2b('binormalMode', hastb and k.binormalMode or Global.KNOTNORMALMODE.X, ''))
	table.insert(strtb, 'radius = ' .. float2string(k.radius) .. ',')
	table.insert(strtb, 'Normal = ' .. vec32string(k:getNormal()) .. ',')
	table.insert(strtb, 'Tangent = ' .. vec32string(k:getTangent()) .. ',')
	table.insert(strtb, 'Binormal = ' .. vec32string(k:getBinormal()) .. ',')

	table.insert(strtb, 'pos1 = ' .. vec32string(k:getPos1()) .. ',')
	if type == KnotManager.PAIRTYPE.POINTS or type == KnotManager.PAIRTYPE.TUBE or type == KnotManager.PAIRTYPE.TUBE_BLANK then
		table.insert(strtb, 'pos2 = ' .. vec32string(k:getPos2()) .. ',')
	end

	if k.rotpivot and (k.type == KnotManager.PAIRTYPE.HANDLE_WITHNORMAL or k.type == KnotManager.PAIRTYPE.TUBE_FORHANDLE
		or k.type == KnotManager.PAIRTYPE.HANDLE or k.type == KnotManager.PAIRTYPE.SPHERE_FORHANDLE
		or k.type == KnotManager.PAIRTYPE.TUBE or k.type == KnotManager.PAIRTYPE.TUBE_BLANK) then
			table.insert(strtb, 'rotpivot = ' .. value2string(k.rotpivot) .. ',')
	end

	table.insert(strtb, '}')
	local str = table.concat(strtb, '')
	return str
end

----------------------------------------------------------------------
-- N 带有明确的法线
-- N1 法线方向没有箭头
-- TB 带有明确的tangent和binormal
KnotManager.PAIRTYPE = {
	POINTS = 0,
	POINT = 1,

	HANDLE_WITHNORMAL = 2,
	TUBE_FORHANDLE = 3,

	HANDLE = 4,
	SPHERE_FORHANDLE = 5,

	TUBE = 6,
	TUBE_BLANK = 7,

	POINT_SPE_P1_1 = 21,
	POINT_SPE_P1_2 = 22,

	POINT_SPE_NP1 = 41,
}

KnotManager.SHAPETYPE = {
	POINT = 1,
	STICK = 2,
	RECT = 3,
}

KnotManager.NORMALTYPE = {
	DIRECTION = 1,
	NONE = 2,
	LINE = 3,
}

KnotManager.getShapeType = function(t)
	if t == KnotManager.PAIRTYPE.POINTS or t == KnotManager.PAIRTYPE.POINT then
		return KnotManager.SHAPETYPE.POINT
	elseif t == KnotManager.PAIRTYPE.HANDLE_WITHNORMAL or t == KnotManager.PAIRTYPE.TUBE_FORHANDLE then
		return KnotManager.SHAPETYPE.POINT
	elseif t == KnotManager.PAIRTYPE.HANDLE or t == KnotManager.PAIRTYPE.SPHERE_FORHANDLE then
		return KnotManager.SHAPETYPE.POINT
	elseif t == KnotManager.PAIRTYPE.TUBE or t == KnotManager.PAIRTYPE.TUBE_BLANK then
		return KnotManager.SHAPETYPE.STICK
	elseif t == KnotManager.PAIRTYPE.POINT_SPE_P1_1 or t == KnotManager.PAIRTYPE.POINT_SPE_P1_2 or t == KnotManager.PAIRTYPE.POINT_SPE_NP1 then
		return KnotManager.SHAPETYPE.POINT
	end
end

KnotManager.getShapeType2 = function(t)
	if t == KnotManager.PAIRTYPE.POINTS then
		return KnotManager.SHAPETYPE.RECT
	elseif t == KnotManager.PAIRTYPE.POINT then
		return KnotManager.SHAPETYPE.POINT
	elseif t == KnotManager.PAIRTYPE.HANDLE_WITHNORMAL or t == KnotManager.PAIRTYPE.TUBE_FORHANDLE then
		return KnotManager.SHAPETYPE.POINT
	elseif t == KnotManager.PAIRTYPE.HANDLE or t == KnotManager.PAIRTYPE.SPHERE_FORHANDLE then
		return KnotManager.SHAPETYPE.POINT
	elseif t == KnotManager.PAIRTYPE.TUBE or t == KnotManager.PAIRTYPE.TUBE_BLANK then
		return KnotManager.SHAPETYPE.STICK
	elseif t == KnotManager.PAIRTYPE.POINT_SPE_P1_1 or t == KnotManager.PAIRTYPE.POINT_SPE_P1_2 or t == KnotManager.PAIRTYPE.POINT_SPE_NP1 then
		return KnotManager.SHAPETYPE.POINT
	end
end

KnotManager.getPairTypes = function(t)
	if t == KnotManager.PAIRTYPE.POINTS or t == KnotManager.PAIRTYPE.POINT then
		return {KnotManager.PAIRTYPE.POINTS, KnotManager.PAIRTYPE.POINT}
	elseif t == KnotManager.PAIRTYPE.HANDLE_WITHNORMAL then
		return {KnotManager.PAIRTYPE.TUBE_FORHANDLE, KnotManager.PAIRTYPE.TUBE}
	elseif t == KnotManager.PAIRTYPE.TUBE_FORHANDLE then
		return {KnotManager.PAIRTYPE.HANDLE_WITHNORMAL}
	elseif t == KnotManager.PAIRTYPE.HANDLE then
		return {KnotManager.PAIRTYPE.SPHERE_FORHANDLE}
	elseif t == KnotManager.PAIRTYPE.SPHERE_FORHANDLE then
		return {KnotManager.PAIRTYPE.HANDLE}
	elseif t == KnotManager.PAIRTYPE.TUBE then
		return {KnotManager.PAIRTYPE.TUBE_BLANK, KnotManager.PAIRTYPE.HANDLE_WITHNORMAL}
	elseif t == KnotManager.PAIRTYPE.TUBE_BLANK then
		return {KnotManager.PAIRTYPE.TUBE}
	elseif t == KnotManager.PAIRTYPE.POINT_SPE_P1_1 then
		return {KnotManager.PAIRTYPE.POINT_SPE_P1_2}
	elseif t == KnotManager.PAIRTYPE.POINT_SPE_P1_2 then
		return {KnotManager.PAIRTYPE.POINT_SPE_P1_1}
	elseif t == KnotManager.PAIRTYPE.POINT_SPE_NP1 then
		return {KnotManager.PAIRTYPE.POINT_SPE_NP1}
	end
end

KnotManager.getNormalType = function(t)
	if t == KnotManager.PAIRTYPE.POINTS or t == KnotManager.PAIRTYPE.POINT then
		return KnotManager.NORMALTYPE.DIRECTION
	elseif t == KnotManager.PAIRTYPE.HANDLE_WITHNORMAL then
		return KnotManager.NORMALTYPE.LINE
	elseif t == KnotManager.PAIRTYPE.TUBE_FORHANDLE then
		return KnotManager.NORMALTYPE.LINE
	elseif t == KnotManager.PAIRTYPE.HANDLE then
		return KnotManager.NORMALTYPE.NONE
	elseif t == KnotManager.PAIRTYPE.SPHERE_FORHANDLE then
		return KnotManager.NORMALTYPE.NONE
	elseif t == KnotManager.PAIRTYPE.TUBE then
		return KnotManager.NORMALTYPE.LINE
	elseif t == KnotManager.PAIRTYPE.TUBE_BLANK then
		return KnotManager.NORMALTYPE.LINE
	elseif t == KnotManager.PAIRTYPE.POINT_SPE_P1_1 or t == KnotManager.PAIRTYPE.POINT_SPE_P1_2 or t == KnotManager.PAIRTYPE.POINT_SPE_NP1 then
		return KnotManager.NORMALTYPE.DIRECTION
	end
end

KnotManager.isSpecialType = function(t)
	if t == KnotManager.PAIRTYPE.HANDLE_WITHNORMAL or t == KnotManager.PAIRTYPE.TUBE_FORHANDLE then
		return true
	elseif t == KnotManager.PAIRTYPE.HANDLE or t == KnotManager.PAIRTYPE.SPHERE_FORHANDLE then
		return true
	elseif t == KnotManager.PAIRTYPE.TUBE or t == KnotManager.PAIRTYPE.TUBE_BLANK then
		return true
	end
end

KnotManager.splitKnots_ByShapeType = function(ks)
	local shapes = {}
	for i, k in ipairs(ks) do
		local t = KnotManager.getShapeType(k:getType())

		if not shapes[t] then
			shapes[t] = {}
		end

		table.insert(shapes[t], k)
	end

	return shapes
end

KnotManager.splitKnots_ByType = function(ks)
	local types = {}
	for i, k in ipairs(ks) do
		local t = k:getType()
		if t == KnotManager.PAIRTYPE.POINTS then
			t = KnotManager.PAIRTYPE.POINT
		end

		if not types[t] then
			types[t] = {}
		end

		table.insert(types[t], k)
	end

	return types
end

KnotManager.filterKnots_ByPairType = function(ks, type)
	local out = {}

	local ptypes = KnotManager.getPairTypes(type)
	for i, pt in ipairs(ptypes) do
		for _, k in ipairs(ks) do
			local t = k:getType()
			if t == pt then
				table.insert(out, k)
			end
		end
	end

	return out
end

KnotManager.splitKnots_ByNormal = function(ks, mergesameline)
	local ns = {}

	local rotks = {}
	for i, k in ipairs(ks) do
		if not k:isNormalRotation() then
			local N = k:getNearestN()
			if mergesameline then
				N = Global.toPositiveAxisType(N)
			end

			local normal = Global.typeToAxis(N)
			if not ns[normal] then
				ns[normal] = {}
			end

			table.insert(ns[normal], k)
		else
			table.insert(rotks, k)
		end
	end

	for i, k in ipairs(rotks) do
		local n = k:getNormal()

		local find = false
		for n1, tb in pairs(ns) do
			if math.floatEqualVector3(n1, n) or (mergesameline and Global.isAxisSameLine(n1, n)) then
				table.insert(tb, k)
				find = true
			end
		end

		if not find then
			ns[n] = {}
			table.insert(ns[n], k)
		end
	end

	return ns
end

KnotManager.splitKnots_ByDepth = function(ks, accuracy)
	table.sort(ks, function(a, b)
		return a:getDepth() < b:getDepth()
	end)

	local ks_depth = {}
	local function addData(i1, i2, depth)
		local data = {}
		data.depth = depth
		data.ks = {}
		for idx = i1, i2 do

			local k = ks[idx]
			table.insert(data.ks, ks[idx])
		end

		table.insert(ks_depth, data)
	end

	local ii = 1
	for i = 2, #ks do
		local k1 = ks[ii]
		local k2 = ks[i]
		if not math.floatEqual(k1:getDepth(), k2:getDepth(), accuracy) then
			addData(ii, i - 1, k1:getDepth())
			ii = i
		end
	end

	if ii <= #ks then
		local k1 = ks[ii]
		addData(ii, #ks, k1:getDepth())
	end

	return ks_depth
end

-- TBN: tangent/binormal/normal
KnotManager.splitKnots_SampeLineTangent = function(ks)
	local out = {}

	for i, k in ipairs(ks) do
		local t = k:getTangent()
		local b = k:getBinormal()
		local tmode = k:getTangentMode()
		local bmode = k:getBinormalMode()

		local find = false
		for _, data in ipairs(out) do
			local tmode1 = data.tangentMode
			local bmode1 = data.binormalMode
			local t1 = data.tangent
			if tmode == tmode1 and bmode == bmode1 and Global.isAxisSameLine(t, t1)
				or (tmode == bmode1 and bmode == tmode1 and Global.isAxisOrtho(t, t1)) then
				table.insert(data.ks, k)
				find = true
			end
		end

		if not find then
			local data = {}
			data.tangent = t
			data.tangentMode = tmode
			data.binormalMode = bmode
			data.ks = {}
			table.insert(data.ks, k)

			table.insert(out, data)
		end
	end

	return out
end

KnotManager.combineKnots_SameDepth_SameTangent = function(ks, tangent, tmode, bmode)
	local out = {}
	local k0 = ks[1]
	local depth = k0:getDepth()
	local normal = k0:getNormal()

	local sx, sy = Global.KNOTDISTANCE[tmode] / 2, Global.KNOTDISTANCE[bmode] / 2

	--_Vector3.mul(tangent, -1, help_v3)
	local rects = {}
	for i, k in ipairs(ks) do
		local kt = k:getTangent()
		local kb = k:getBinormal()

		local x1, y1, x2, y2 = k:getTBDepth()

		local negative, changeBT = false, false
		local dot = _Vector3.dot(kt, tangent)
		if math.floatEqual(dot, 1) then
		elseif math.floatEqual(dot, -1) then
			negative = false
		elseif math.floatEqual(dot, 0) then
			local dot2 = _Vector3.dot(kb, tangent)
			changeBT = true
			if math.floatEqual(dot2, -1) then
				negative = true
			end
		end

		if negative then
			x1, y1 = -x1, -y1
			if x2 and y2 then
				x2, y2 = -x2, -y2
			end
		end

		if changeBT then
			x1, y1 = y1, -x1
			if x2 and y2 then
				x2, y2 = y2, -x2
			end
		end

		if x2 and x2 < x1 then
			x1, x2 = x2, x1
		end

		if y2 and y2 < y1 then
			y1, y2 = y2, y1
		end

		local rect = {}
		rect.ks = {}
		table.insert(rect.ks, k)
		rect.x1, rect.y1 = x1 - sx, y1 - sy
		rect.x2, rect.y2 = (x2 or x1) + sx, (y2 or y1) + sy
		table.insert(rects, rect)
	end

	-- if #rects > 1 and math.floatEqualVector3(normal, Global.AXIS.Z) then
	-- 	for i, r in ipairs(rects) do
	-- 		local k = r.ks[1]
	-- 		print('rect', i, r.x1, r.x2, r.y1, r.y2, k:getNormal(), k:getPos1(), k:getDepth())
	-- 	end
	-- end

	Optimizer.MergeRect(rects, function(t1, t2)
		-- 记录合并的结果
		for i, k in ipairs(t2.ks) do
			table.insert(t1.ks, k)
		end
	end)

	for i, r in ipairs(rects) do
		if #r.ks == 1 then
			table.insert(out, r.ks[1])
		else
			pos1_v3:set(r.x1 + sx, r.y1 + sy, depth)
			pos2_v3:set(r.x2 - sx, r.y2 - sy, depth)
			mat_help:composeFromTN(normal, tangent)
			--mat_help:inverse()

			-- print('!1', #r.ks, pos1_v3, pos2_v3)
			-- print('!2', #r.ks, pos1_v3, pos2_v3)

			mat_help:apply(pos1_v3, pos1_v3)
			mat_help:apply(pos2_v3, pos2_v3)

			local k = Knot.new()
			k:loadFromChildren(r.ks, pos1_v3, pos2_v3)

			table.insert(out, k)
		end
	end

	return out
end

KnotManager.combineKnots_SameDepth = function(ks, depth)
	local out = {}

	local ks_tagent = KnotManager.splitKnots_SampeLineTangent(ks)
	for i, data in ipairs(ks_tagent) do
		--print('combineKnots_SameDepth', i, data.tangent, data.tangentMode, data.binormalMode)
		local ks1 = KnotManager.combineKnots_SameDepth_SameTangent(data.ks, data.tangent, data.tangentMode, data.binormalMode)
		table.fappendArray(out, ks1)
	end

	return out
end

KnotManager.combineKnots_SameNormal = function(ks, n)
	local out = {}

	local ks_depth = KnotManager.splitKnots_ByDepth(ks)
	for i, data in ipairs(ks_depth) do
		local oks = KnotManager.combineKnots_SameDepth(data.ks, data.depth)
		table.fappendArray(out, oks)
	end

	return out
end

KnotManager.combineKnots = function(ks)
	local out = {}
	local ns_out = {}

	local ns = KnotManager.splitKnots_ByNormal(ks)
	for n, tb in pairs(ns) do
		local knots = KnotManager.combineKnots_SameNormal(tb, n)
		table.fappendArray(out, knots)

		ns_out[n] = knots
	end

	return out, ns_out
end

KnotManager.combine = function(ks)
	local out = {}

	local ks1 = {}
	for i, k in ipairs(ks) do
		if k:canCombine() then
			table.insert(ks1, k)
		else
			table.insert(out, k)
		end
	end

	local merge_ks, ns = {}, {}
	if #ks1 > 0 then
		merge_ks, ns = KnotManager.combineKnots(ks1)
		table.fappendArray(out, merge_ks)
	end

	return out, merge_ks, ns
end

KnotManager.filterCollision_ByShape0_SameDepth = function(n, depth, ks)
	if #ks < 2 then
		return ks
	end

	local out = {}

	local proj = Global.buildProjectAxis(n)
	--print('projdata', n, projdata.Normal, projdata.Tangent, projdata.Binormal)
	--local rects = {}

	local t1 = _tick()

	local ps_sort = {}
	local addRectfunc = function(k)
		if not k:isCollision() then

			-- if k.type == KnotManager.PAIRTYPE.POINTS then
			-- 	assert(false)
			-- end
			local c = {}
			k:projectTo(proj, c)
			-- k:setCollision(false)
			-- assert(not k:isCollision())

			local p = {}

			local r = k:getRadius()
			p.x1 = c.t_depth1 - r
			p.y1 = c.b_depth1 - r
			p.x2 = c.t_depth1 + r
			p.y2 = c.b_depth1 + r
			p.x, p.y = c.t_depth1, c.b_depth1
			-- print('addRectfunc', r, c.t_depth1, c.b_depth1)

			p.k = k
			table.insert(ps_sort, p)
		end
	end

	for i, k in ipairs(ks) do
		-- k:setCollision(false)

		local ksn = k:getKsN()
		if ksn then
			local n1 = #ps_sort
			k:enumChildren(addRectfunc)
			for idx = n1 + 1, #ps_sort do
				local p = ps_sort[idx]
				p.pk = k
			end
		else
			addRectfunc(k)
		end
	end

	local t2 = _tick()

	Optimizer.filterCollisionRect(ps_sort)

--[[
	table.sort(ps_sort, function(a, b)
		return a.x1 < b.x1
	end)

	local function filterCollisionPoints(p)
		if p.k:isCollision() then return end
		-- local r = p.k:getRadius()
		--local x1, x2 = p.x - r, p.x + r
		--local y1, y2 = p.y - r, p.y + r

		local ps_x = {}
		for i, v in ipairs(ps_sort) do
			if v ~= p and not v.k:isCollision() then
				if v.x1 > p.x2 then break end

				if v.x1 >= p.x1 and v.x1 <= p.x2 or v.x2 >= p.x1 and v.x2 <= p.x2 then
					table.insert(ps_x, v)
				end
			end
		end

		table.sort(ps_x, function(a, b)
			return a.y1 < b.y1
		end)

		for i, v in ipairs(ps_x) do
			if v.y1 > v.y2 then break end

			if v.y1 >= p.y1 and v.y1 <= p.y2 or v.y2 >= p.y1 and v.y2 <= p.y2 then
				-- print('1111111', p.k.serialNum, p.k:getNormal(), p.k:getDepth(), p.pk and p.pk:getDepth(), depth, p == v, i, p.x, p.y, p.k:getPos1(), p.k.radius)
				-- print('2222222', v.k.serialNum, v.k:getNormal(), v.k:getDepth(), v.pk and v.pk:getDepth(), depth, p == v, i, v.x, v.y, v.k:getPos1(), v.k.radius)

				if p.pk and not math.floatEqual(p.pk:getDepth(), p.k:getDepth()) then
					local k1, k2 = p.pk, p.k
					print('pos', k1.pos1, k1.pos2, k2.pos1, k2.pos2)
					print('mat', k1.bindmat2, k1.bindmat, k2.bindmat2, k2.bindmat)
					assert(false)
				end
				v.k:addCollision(p.k)
				-- v.collision = true
				-- p.collision = true
				--v.k:setCollision(true)
				--p.k:setCollision(true)

				-- if v.pk then v.pk:setCollision(true) end
				-- if p.pk then p.pk:setCollision(true) end
			end
		end
	end

	for i, p in ipairs(ps_sort) do
		filterCollisionPoints(p)
	end
--]]
	local t3 = _tick()

	local removen, breakn = 0, 0

	for i, k in ipairs(ks) do
		if not k:isCollision() then
			table.insert(out, k)
		else
			removen = removen + 1

			local ksn = k:getKsN()
			if ksn then
				local kks = {}
				k:enumChildren(function(kk)
					if not kk:isCollision() then
						table.insert(kks, kk)
					end
				end)

				if #kks > 1 then
					local kks1 = KnotManager.combineKnots_SameDepth_SameTangent(kks, k:getTangent(), k:getTangentMode(), k:getBinormalMode())
					table.fappendArray(out, kks1)
					breakn = breakn + #kks1
				else
					for _, kk in ipairs(kks) do
						table.insert(out, kk)
					end

					breakn = breakn + #kks
				end
			end
		end
	end

	local t4 = _tick()
	-- print('removen', removen, breakn, #ps_sort, n, depth)

	if t4 - t1 > 100 then
		-- print('filterCollision_ByShape0_SameDepth', #ks, #ps_sort, n, t4 - t1, t2 - t1, t3 - t2, t4 - t3)
	end

	return out
end

KnotManager.filterCollision_ByShape0_LineNormal = function(n1, ks1, n2, ks2)
	local out = {}
	-- if not math.floatEqualVector3(n1, Global.AXIS.Y) and not math.floatEqualVector3(n1, Global.AXIS.NY) then
	-- 	table.fappendArray(out, ks1)
	-- 	table.fappendArray(out, ks2)
	-- 	return out
	-- end

	local depth_accuracy = 0.04
	local ks_depth1 = KnotManager.splitKnots_ByDepth(ks1, depth_accuracy)

	local ks_depth2 = {}
	if ks2 then
		ks_depth2 = KnotManager.splitKnots_ByDepth(ks2, depth_accuracy)
	end

	for i, v in ipairs(ks_depth1) do
		local depth = v.depth
		local vks1 = v.ks

		--print('filterCollision0', n1, v.depth, #v.ks)

		--local vks2 = nil
		for ii, vv in ipairs(ks_depth2) do
			local depth2 = -vv.depth
			if math.floatEqual(depth, depth2, depth_accuracy) then
				--vks2 = vv.ks
				table.fappendArray(vks1, vv.ks)

				table.remove(ks_depth2, ii)

				-- print('filterCollision1', n1, vv.depth, #vv.ks)
				break
			end
		end

		local ks0 = KnotManager.filterCollision_ByShape0_SameDepth(n1, depth, vks1)
		table.fappendArray(out, ks0)
	end

	for i, v in ipairs(ks_depth2) do
		-- print('filterCollision2', n2, v.depth, #v.ks)
		local ks0 = KnotManager.filterCollision_ByShape0_SameDepth(n2, v.depth, v.ks)
		table.fappendArray(out, ks0)
	end

	return out
end

KnotManager.filterCollision_ByShape0 = function(ks)
	local out = {}

	local ns = KnotManager.splitKnots_ByNormal(ks)
	--print('filterCollision_ByShape=============', ks)

	local nsignore = {}
	for n1 in pairs(ns) do
		--print('filterCollision_ByShape0', n1, #ns[n1], nsignore[n1])
		if not nsignore[n1] then
			local oppo_n = nil
			for n2 in pairs(ns) do
				if Global.isAxisOpposite(n1, n2) then
					nsignore[n2] = true
					oppo_n = n2
					break
				end
			end

			local ks0 = KnotManager.filterCollision_ByShape0_LineNormal(n1, ns[n1], oppo_n, oppo_n and ns[oppo_n])
			table.fappendArray(out, ks0)
		end
	end

	return out
end

KnotManager.filterCollision_ByShape = function(ks, shapetype)
	if shapetype == KnotManager.SHAPETYPE.POINT then
		return KnotManager.filterCollision_ByShape0(ks)
	else
		return ks
	end
end

KnotManager.filterCollision = function(ks)
	local out = {}

	--print('filterCollision', #ks)
	local shapes = KnotManager.splitKnots_ByShapeType(ks)
	for st, ks1 in pairs(shapes) do
	--	print('filterCollision1', st, #ks1)
		local ks2 = KnotManager.filterCollision_ByShape(ks1, st)
		table.fappendArray(out, ks2)
	end

	return out
end

----------------------------------------------

KnotManager.checkProjectPair_SamePType = function(t, ks1, ks2)
	local nortype = KnotManager.getNormalType(t)

	local ns_pks = {}
	if nortype == KnotManager.NORMALTYPE.NONE then
		local n = Global.AXIS.ZERO
		ns_pks[n] = {ks1 = ks1, ks2 = ks2}
	else
		local linenormal = nortype == KnotManager.NORMALTYPE.LINE
		local ns1 = KnotManager.splitKnots_ByNormal(ks1, linenormal)
		local ns2 = KnotManager.splitKnots_ByNormal(ks2, linenormal)

		for n1, nks1 in pairs(ns1) do
			for n2, nks2 in pairs(ns2) do
				if (linenormal and Global.isAxisSameLine(n1, n2)) or (not linenormal and Global.isAxisOpposite(n1, n2)) then
					ns_pks[n1] = {ks1 = nks1, ks2 = nks2}
					break
				end
			end
		end
	end

	return ns_pks
end

KnotManager.ProjectKnot_ByDir = function(k, projdata)
	local expandr = 0
	local c = {}
	k:projectTo(projdata.projmat, c)
	projdata.ks[k] = c

	local st = KnotManager.getShapeType2(k:getType())

	if st == KnotManager.SHAPETYPE.RECT then
		local ps = {}
		ps[1] = _Vector2.new(c.t_depth1, c.b_depth1)
		ps[2] = _Vector2.new()
		ps[3] = _Vector2.new(c.t_depth2, c.b_depth2)
		ps[4] = _Vector2.new()

		_Vector2.mul(c.t_dir, math.max(k:getTangentN() - 1, 0.5) * k:getTangentStep(), ps[2])
		_Vector2.add(ps[1], ps[2], ps[2])

		_Vector2.mul(c.b_dir, math.max(k:getBinormalN() - 1, 0.5) * k:getBinormalStep(), ps[4])
		_Vector2.add(ps[2], ps[4], ps[3])
		_Vector2.add(ps[1], ps[4], ps[4])

		local polygon1 = _Polygon.new()
		polygon1:setPoints(ps)

		-- local polygon2 = _Polygon.new()
		-- polygon2:setPoints(ps)

		local r = k:getRadius()
		polygon1:expand(r)

		-- local ps2 = {}
		-- polygon1:getPoints(ps2)
		-- print('!!!', k:getTangentN(), k:getBinormalN(), c.t_depth1, c.b_depth1, c.t_depth2, c.b_depth2, c.t_dir, c.b_dir)
		-- for i, v1 in ipairs(ps2) do
		-- 	print('~ps2', i, v1)
		-- end
		--polygon2:expand(r * 2)

		-- if math.floatEqualVector3(k:getNormal(), Global.AXIS.Z) then
		-- 	print('ProjectKnot_ByDir', projdata.dir, projdata.projmat.Normal, projdata.projmat.Tangent, projdata.projmat.Binormal)
		-- 	for i = 1, 4 do
		-- 		print(' ---', i, ps[i])
		-- 	end
		-- end

		c.polygon1 = polygon1 -- 处理矩形与矩形的碰撞
		--c.polygon2 = polygon2 -- 处理矩形与点的碰撞
		--c.ps = ps
		c.ksn = k:getKsN()
	end
end

KnotManager.getOriginPos_Stick = function(pp, p1, p2, o1, o2, pos)

end

local help_v1 = _Vector3.new()
local help_v2 = _Vector3.new()

KnotManager.getPos_Rect = function(k, n1, n2, vecs)
	--local f1, f2 = mathHelper.getLerpFactor_Vector2(ptdir, pbdir, pp)
	--local n1, n2 = toint(f1 / k:getTangentStep(), 0.5), toint(f2 / k:getBinormalStep(), 0.5)
	--print('getOriginPos_Rect', n1, n2, k:getTangentN(), k:getBinormalN(), f1, f2, ptdir, pbdir, pp)

	if n1 < 0 or n1 >= k:getTangentN() or n2 < 0 or n2 >= k:getBinormalN() then return end

	local pos = _Vector3.new()
	_Vector3.mul(k:getTangent(), n1 * k:getTangentStep(), help_v1)
	_Vector3.mul(k:getBinormal(), n2 * k:getBinormalStep(), help_v2)
	_Vector3.add(k:getPos1(), help_v1, pos)
	_Vector3.add(pos, help_v2, pos)
	table.insert(vecs, pos)

	return true
end

KnotManager.getOriginPos_Rect = function(k, pp, ptdir, pbdir, vecs)
	local f1, f2 = mathHelper.getLerpFactor_Vector2(ptdir, pbdir, pp)
	f1, f2 = f1 / k:getTangentStep(), f2 / k:getBinormalStep()

	local n1, n2 = toint(f1, 0.5), toint(f2, 0.5)
	if n1 < 0 or n1 >= k:getTangentN() or n2 < 0 or n2 >= k:getBinormalN() then return false end

	local ln1 = toint(f1, 0) ~= n1 and toint(f1, 0) or toint(f1, 1)
	local ln2 = toint(f2, 0) ~= n2 and toint(f2, 0) or toint(f2, 1)

	KnotManager.getPos_Rect(k, n1, n2, vecs)
	if ln1 ~= n1 then
		KnotManager.getPos_Rect(k, ln1, n2, vecs)
	end

	if ln2 ~= n2 then
		KnotManager.getPos_Rect(k, n1, ln2, vecs)
		if ln1 ~= n1 then
			KnotManager.getPos_Rect(k, ln1, ln2, vecs)
		end
	end

	-- 增加半格处的吸附
	if k:getTangentN() > 1 and k:getBinormalN() == 1 and k:getTangentMode() == Global.KNOTNORMALMODE.X then
		if ln1 ~= n1 then
			KnotManager.getPos_Rect(k, (n1 + ln1) * 0.5, n2, vecs)
		end
	elseif k:getTangentN() == 1 and k:getBinormalN() > 1 and k:getBinormalMode() == Global.KNOTNORMALMODE.X then
		if ln2 ~= n2 then
			KnotManager.getPos_Rect(k, n1, (n2 + ln2) * 0.5, vecs)
		end
	elseif k:getTangentN() > 1 and k:getBinormalN() > 1 and k:getBinormalMode() == Global.KNOTNORMALMODE.X and k:getTangentMode() == Global.KNOTNORMALMODE.X then
		if ln1 ~= n1 and ln2 ~= n2 then
			KnotManager.getPos_Rect(k, (n1 + ln1) * 0.5, (n2 + ln2) * 0.5, vecs)
		end
	end

	return true
end

local help_polygon = _Polygon.new()
KnotManager.checkProjectPair_SamePType_SameNormal = function(ktype, n, ks1, ks2, projdata)
	if #ks1 == 0 or #ks2 == 0 then return end

	local projdata_ks = projdata.ks
	local dir = projdata.dir
	--local projmatinv = projdata.projmatinv

	local expandr = 0.1
	--local cross1, cross2 = _Vector2.new(), _Vector2.new()
	local hvec = _Vector3.new()
	-- local crossv3 = _Vector3.new()
	local r_factor = math.abs(_Vector3.dot(n, dir))
	local function checkPair(k1, k2)
		local st1, st2 = KnotManager.getShapeType2(k1:getType()), KnotManager.getShapeType2(k2:getType())
		local c1, c2 = projdata_ks[k1], projdata_ks[k2]
		local r1 = math.max(k1:getRadius() * r_factor, 0.02)
		local r2 = math.max(k2:getRadius() * r_factor, 0.02)
		local r = r1 + r2
		if k1:hasRotData() or k2:hasRotData() then
			r = r + expandr
		end

		local swaped = false
		local swap = function()
			c1, c2 = c2, c1
			st1, st2 = st2, st1
			swaped = not swaped
		end

		if st2 < st1 then
			swap()
		end

		if st1 == KnotManager.SHAPETYPE.POINT and st2 == KnotManager.SHAPETYPE.POINT then
			local ds = mathHelper.DistanceSqr_Vector2(c1.t_depth1, c1.b_depth1, c2.t_depth1, c2.b_depth1)
			if ds < r * r then
				-- 计算相交点
				_Vector3.sub(k2:getPos1(), k1:getPos1(), hvec)

				-- print('point corss point', hvec)
				return {{d = math.sqrt(ds), movediff = hvec}}
			end
		elseif st1 == KnotManager.SHAPETYPE.POINT and st2 == KnotManager.SHAPETYPE.STICK then
			local d, factor = mathHelper.Distance_Segment_Vector2(c2.t_depth1, c2.b_depth1, c2.t_depth2, c2.b_depth2, c1.t_depth1, c1.b_depth1)
			if d and d < r then

				-- 计算相交点
				local k = not swaped and k2 or k1
				local cross = math.lerp(k:getPos1(), k:getPos2(), factor, 'vec3')
				if not swaped then
					_Vector3.sub(cross, k1:getPos1(), hvec)
				else
					_Vector3.sub(k2:getPos1(), cross, hvec)
				end

				return {{d = d, movediff = hvec}}
			end
		elseif st1 == KnotManager.SHAPETYPE.POINT and st2 == KnotManager.SHAPETYPE.RECT then
			if c2.polygon1:checkInside(c1.t_depth1, c1.b_depth1) then

				-- 计算相交点
				local k = not swaped and k2 or k1
				local pp = _Vector2.new(c1.t_depth1 - c2.t_depth1, c1.b_depth1 - c2.b_depth1)
				local crossv3s = {}
				if KnotManager.getOriginPos_Rect(k, pp, c2.t_dir, c2.b_dir, crossv3s) then
					--local proj = projdata.projmat

					local data = {}
					for i, crossv3 in ipairs(crossv3s) do
						local diff = _Vector3.new()
						if not swaped then
							_Vector3.sub(crossv3, k1:getPos1(), diff)
						else
							_Vector3.sub(k2:getPos1(), crossv3, diff)
						end

						-- 计算移动距离
						diff:project(dir, hvec)
						_Vector3.sub(diff, hvec, hvec)

						-- print('111111', hvec:magnitude(), diff)
						-- print('movediff', hvec:magnitude(), diff)
						table.insert(data, {d = hvec:magnitude(), movediff = diff})
					end

					return data
				end
			end
		elseif st1 == KnotManager.SHAPETYPE.STICK and st2 == KnotManager.SHAPETYPE.STICK then
			local l1 = mathHelper.DistanceSqr_Vector2(c1.t_depth1, c1.b_depth1, c1.t_depth2, c1.b_depth2)
			local l2 = mathHelper.DistanceSqr_Vector2(c2.t_depth1, c2.b_depth1, c2.t_depth2, c2.b_depth2)
			if l2 < l1 then
				swap()
			end

			local d1, f1 = mathHelper.Distance_Segment_Vector2(c2.t_depth1, c2.b_depth1, c2.t_depth2, c2.b_depth2, c1.t_depth1, c1.b_depth1)
			local d2, f2 = mathHelper.Distance_Segment_Vector2(c2.t_depth1, c2.b_depth1, c2.t_depth2, c2.b_depth2, c1.t_depth2, c1.b_depth2)
			local d = d1 or d2
			if d and d < r then
				-- 计算相交点
				local sk = not swaped and k2 or k1
				local cross = math.lerp(sk:getPos1(), sk:getPos2(), d1 and f1 or f2, 'vec3')
				if not swaped then
					_Vector3.sub(cross, d1 and k1:getPos1() or k1:getPos2(), hvec)
				else
					_Vector3.sub(d1 and k2:getPos1() or k2:getPos2(), cross, hvec)
				end

				-- print('stick cross stick', movediff)

				return {{d = d, movediff = hvec}}
			end
		elseif st1 == KnotManager.SHAPETYPE.STICK and st2 == KnotManager.SHAPETYPE.RECT then
			-- if c2.polygon:checkIntersect(c1.t_depth1, c1.b_depth1, c1.t_depth2, c1.b_depth2) then
			-- 	return 0
			-- end
		elseif st1 == KnotManager.SHAPETYPE.RECT and st2 == KnotManager.SHAPETYPE.RECT then
			if mathHelper.checkPolygonIntersect(c1.polygon1, c2.polygon1, help_polygon) then
				local ps = {}
				help_polygon:getPoints(ps)

				if #ps == 0 then return end

				-- 计算相交区域的中心点
				local crossv2 = _Vector2.new()
				for i, p in ipairs(ps) do
					_Vector2.add(crossv2, p, crossv2)
				end
				_Vector2.mul(crossv2, 1 / #ps, crossv2)

				--print('checkPolygonIntersect', #ps, crossv2)

				-- 计算矩形的移动
				local pp1 = _Vector2.new(crossv2.x - c1.t_depth1, crossv2.y - c1.b_depth1)
				local pp2 = _Vector2.new(crossv2.x - c2.t_depth1, crossv2.y - c2.b_depth1)
				--local k1_cross = _Vector3.new()
				--local k2_cross = _Vector3.new()
				local k1_crosss = {}
				local k2_crosss = {}
				if KnotManager.getOriginPos_Rect(k1, pp1, c1.t_dir, c1.b_dir, k1_crosss) and KnotManager.getOriginPos_Rect(k2, pp2, c2.t_dir, c2.b_dir, k2_crosss) then
					local data = {}
					for _, k1_cross in ipairs(k1_crosss) do
						for _, k2_cross in ipairs(k2_crosss) do
							local diff = _Vector3.new()
							_Vector3.sub(k2_cross, k1_cross, diff)
							--print('rect corss rect', k1_cross, k2_cross, movediff)

							-- 计算移动距离
							diff:project(dir, hvec)
							_Vector3.sub(diff, hvec, hvec)
							--return movediff:magnitude()
							table.insert(data, {d = hvec:magnitude(), movediff = diff})
						end
					end

					return data
				end
			end
		end

		return nil
	end

	local ks_pair = {}
	for _, k1 in ipairs(ks1) do
		for _, k2 in ipairs(ks2) do
			local data = checkPair(k1, k2)
			if data then
				for i, v in ipairs(data) do
					local p = {}
					p.k1 = k1
					p.k2 = k2
					p.type = ktype
					p.n = n
					p.d = v.d
					p.movediff = _Vector3.new()
					p.movediff:set(v.movediff)
					table.insert(ks_pair, p)
				end
			end
		end
	end

	return ks_pair
end

KnotManager.checkProjectPair = function(ks1, ks2, projdata)
	local out = {}
	local type_ks = KnotManager.splitKnots_ByType(ks1)
	for t, ks in pairs(type_ks) do
		local pt_ks = KnotManager.filterKnots_ByPairType(ks2, t)
		local n_pks = KnotManager.checkProjectPair_SamePType(t, ks, pt_ks)

		for n, data in pairs(n_pks) do
			--print('checkProjectPair', n, #data.ks1, #data.ks2)
			local ps = KnotManager.checkProjectPair_SamePType_SameNormal(t, n, data.ks1, data.ks2, projdata)
			if ps then
				table.fappendArray(out, ps)
			end
		end
	end

	return out
end
-------------------------------------------

KnotManager.drawKnot = function(k, c, ab)
	local type = k:getType()
	-- k:setTransformDirty()

	if type == KnotManager.PAIRTYPE.POINTS then
		-- DrawHelper.drawMergeKnot(k:getPos1(), k:getPos2(), _Color.Red)
		k:enumChildren(function(ck)
			if not ab or ab:checkInside(ck:getPos1()) then
				KnotManager.drawKnotTypeRect(ck, c)
			end
		end)
		-- KnotManager.drawKnotTypeRects(k, c)
	elseif type == KnotManager.PAIRTYPE.POINT then
		if not ab or ab:checkInside(k:getPos1()) then
			KnotManager.drawKnotTypeRect(k, c)
		end
	else
		if not ab or ab:checkInside(k:getPos1()) then
			KnotManager.drawKnotTypeSphere(k, c)
		end
	end
end

KnotManager.drawKnotWithAxis = function(k, c)
	local type = k:getType()
	-- k:setTransformDirty()

	if type == KnotManager.PAIRTYPE.POINTS then
		k:enumChildren(function(ck)
			KnotManager.drawKnotTypeRectWithAxis(ck, c)
		end)
	elseif type == KnotManager.PAIRTYPE.POINT or type == KnotManager.PAIRTYPE.POINT_SPE_P1_1
		or type == KnotManager.PAIRTYPE.POINT_SPE_P1_2 or type == KnotManager.PAIRTYPE.POINT_SPE_NP1 then
		KnotManager.drawKnotTypeRectWithAxis(k, c)
	elseif type == KnotManager.PAIRTYPE.TUBE or type == KnotManager.PAIRTYPE.TUBE_BLANK then
		KnotManager.drawKnotTypeCylinderWithAxis(k, c)
	else
		KnotManager.drawKnotTypeSphereWithAxis(k, c)
	end
end

local mat = _Matrix3D.new()
KnotManager.drawKnotTypeRects = function(k, c)
	-- k:setTransformDirty()

	local tN, bN = k.tN, k.bN
	for i = 1, bN do
		_Vector3.mul(k:getBinormal(), (i - 1) * k:getBinormalStep(), help_v1)
		_Vector3.add(help_v1, k:getPos1(), help_v1)

		for j = 1, tN do
			_Vector3.mul(k:getTangent(), (j - 1) * k:getTangentStep(), help_v2)
			_Vector3.add(help_v2, help_v1, help_v2)

			mat:composeFromTN(k:getNormal(), k:getTangent())
			mat:mulTranslationRight(help_v2)
			_rd:pushMatrix3D(mat)
			local z = 0.01
			local r = 0.05 -- k:getRadius()
			c = k:isCollision() and 0xff888888 or (c or Global.KNOTCOLOR)
			_rd:fill3DRect(0, 0, z, 0, r, 0, r, 0, 0, c)
			_rd:popMatrix3D()
		end
	end
end

KnotManager.drawKnotTypeRect = function(k, c)
	-- k:setTransformDirty()
	mat:composeFromTN(k:getNormal(), k:getTangent())
	mat:mulTranslationRight(k:getPos1())
	_rd:pushMatrix3D(mat)
	local z = 0.01
	local r = 0.05 -- k:getRadius()
	c = k:isCollision() and 0xff888888 or (c or Global.KNOTCOLOR)
	_rd:fill3DRect(0, 0, z, 0, r, 0, r, 0, 0, c)

	_rd:popMatrix3D()
end

local knotsphere = _mf:createSphere()
-- knotsphere.transform:setScaling(0.05, 0.05, 0.05)
local knotblend = _Blender.new()
KnotManager.drawKnotTypeSphere = function(k, c)
	-- k:setTransformDirty()
--	mat:composeFromTN(k:getNormal(), k:getTangent())
	mat:setTranslation(k:getPos1())
	--local r = k:getRadius()
	local r = 0.02
	mat:mulScalingLeft(r, r, r)
	_rd:pushMatrix3D(mat)
	c = c or Global.KNOTCOLOR
	knotblend:blend(c)
	_rd:useBlender(knotblend)
	knotsphere:drawMesh()
	_rd:popBlender()
	_rd:popMatrix3D()
end

-------------------------------------
local knotAxisX = _mf:createCylinder()
local kmat = knotAxisX.transform
kmat:setScaling(0.0025, 0.0025, 0.05)
kmat:mulTranslationRight(0, 0, 0.05)
kmat:mulFaceToRight(Global.AXIS.Z, Global.AXIS.X)

local knotAxisY = _mf:createCylinder()
local kmat = knotAxisY.transform
kmat:setScaling(0.0025, 0.0025, 0.05)
kmat:mulTranslationRight(0, 0, 0.05)
kmat:mulFaceToRight(Global.AXIS.Z, Global.AXIS.Y)

local knotAxisZ = _mf:createCylinder()
local kmat = knotAxisZ.transform
kmat:setScaling(0.0025, 0.0025, 0.1)
kmat:mulTranslationRight(0, 0, 0.1)
_mf:paintDiffuse(knotAxisZ, _Color.Red)

local blendmodex = _Blender.new()
blendmodex:blend(_Color.Yellow)
local blendmodey = _Blender.new()
blendmodey:blend(_Color.Green)

KnotManager.drawKnotTypeRectsWithAxis = function(k, c)
	-- k:setTransformDirty()

	local tN, bN = k.tN, k.bN
	for i = 1, bN do
		_Vector3.mul(k:getBinormal(), (i - 1) * k:getBinormalStep(), help_v1)
		_Vector3.add(help_v1, k:getPos1(), help_v1)

		for j = 1, tN do
			_Vector3.mul(k:getTangent(), (j - 1) * k:getTangentStep(), help_v2)
			_Vector3.add(help_v2, help_v1, help_v2)

			mat:composeFromTN(k:getNormal(), k:getTangent())
			mat:mulTranslationRight(help_v2)
			_rd:pushMatrix3D(mat)
			local z = 0.01
			local r = k:getRadius()
			c = c or Global.KNOTCOLOR
			_rd:fill3DRect(0, 0, z, 0, r, 0, r, 0, 0, c)
			knotAxisZ:drawMesh()

			_rd:useBlender(k.tangentMode == Global.KNOTNORMALMODE.X and blendmodex or blendmodey)
			knotAxisX:drawMesh()
			_rd:popBlender()

			_rd:useBlender(k.binormalMode == Global.KNOTNORMALMODE.X and blendmodex or blendmodey)
			knotAxisY:drawMesh()
			_rd:popBlender()
			_rd:popMatrix3D()
		end
	end
end

KnotManager.drawKnotTypeRectWithAxis = function(k, c)
	-- k:setTransformDirty()
	mat:composeFromTN(k:getNormal(), k:getTangent())
	mat:mulTranslationRight(k:getPos1())
	_rd:pushMatrix3D(mat)
	local z = 0.01
	local r = k:getRadius()
	c = c or Global.KNOTCOLOR
	_rd:fill3DRect(0, 0, z, 0, r, 0, r, 0, 0, c)
	knotAxisZ:drawMesh()

	_rd:useBlender(k.tangentMode == Global.KNOTNORMALMODE.X and blendmodex or blendmodey)
	knotAxisX:drawMesh()
	_rd:popBlender()

	_rd:useBlender(k.binormalMode == Global.KNOTNORMALMODE.X and blendmodex or blendmodey)
	knotAxisY:drawMesh()
	_rd:popBlender()

	_rd:popMatrix3D()
end

local knotsphere2 = _mf:createSphere()
knotsphere2.transform:setScaling(0.05, 0.05, 0.05)
KnotManager.drawKnotTypeSphereWithAxis = function(k, c)
	-- k:setTransformDirty()
	mat:composeFromTN(k:getNormal(), k:getTangent())
	mat:mulTranslationRight(k:getPos1())
	-- local r = k:getRadius()
	-- mat:mulScalingLeft(r, r, r)

	_rd:pushMatrix3D(mat)
	c = c or Global.KNOTCOLOR
	knotblend:blend(c)
	_rd:useBlender(knotblend)
	knotsphere2:drawMesh()
	_rd:popBlender()

	-- mat.ignoreScaling = true
	knotAxisZ:drawMesh()
	_rd:useBlender(blendmodex)
	knotAxisX:drawMesh()
	knotAxisY:drawMesh()
	_rd:popBlender()
	-- mat.ignoreScaling = false
	_rd:popMatrix3D()
end

local knotcylinder = _mf:createCylinder()
knotcylinder.transform:setScaling(1, 1, 0.5)
knotcylinder.transform:mulTranslationRight(0, 0, 0.5)

local knot_len = _Vector3.new()
KnotManager.drawKnotTypeCylinderWithAxis = function(k, c)
	-- k:setTransformDirty()
	mat:composeFromTN(k:getNormal(), k:getTangent())
	_Vector3.sub(k:getPos2(), k:getPos1(), knot_len)
	local r = k:getRadius()
	mat:mulScalingLeft(r, r, knot_len:magnitude())
	mat:mulTranslationRight(k:getPos1())
	_rd:pushMatrix3D(mat)
	c = c or Global.KNOTCOLOR
	knotblend:blend(c)
	_rd:useBlender(knotblend)
	knotcylinder:drawMesh()
	_rd:popBlender()

	mat.ignoreScaling = true
	knotAxisZ:drawMesh()
	mat.ignoreScaling = false
	_rd:popMatrix3D(mat)
end

