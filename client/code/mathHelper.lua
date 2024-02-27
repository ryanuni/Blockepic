local mathHelper = {}
_G.mathHelper = mathHelper

local v2_1 = _Vector2.new()
local v2_2 = _Vector2.new()
local v3_1 = _Vector3.new()
local v3_2 = _Vector3.new()
mathHelper.DistanceSqr_Vector2 = function(x1, y1, x2, y2)
	return (x1 - x2) * (x1 - x2) + (y1 - y2) * (y1 - y2)
end

mathHelper.DistanceSqr_Vector3 = function(x1, y1, z1, x2, y2, z2)
	return (x1 - x2) * (x1 - x2) + (y1 - y2) * (y1 - y2) + (z1 - z2) * (z1 - z2)
end

mathHelper.Distance_Segment_Vector2 = function(x1, y1, x2, y2, x0, y0, crossrate)
	v2_2:set(x0 - x1, y0 - y1)

	v2_1:set(x2 - x1, y2 - y1)
	local seg_len = v2_1:magnitude()
	v2_1:normalize()

	local proj_len = _Vector2.dot(v2_2, v2_1)
	if proj_len > seg_len or proj_len < 0 then
		return false
	end

	_Vector2.mul(v2_1, proj_len, v2_1)

	_Vector2.sub(v2_2, v2_1, v2_1)
	local factor = proj_len / seg_len
	return v2_1:magnitude(), factor
end

mathHelper.getLerpFactor_Vector2 = function(p1, p2, p0)
	local x1, y1, x2, y2, x0, y0 = p1.x, p1.y, p2.x, p2.y, p0.x, p0.y
	assert(x1 * y2 - y1 * x2 ~= 0)

	local k1 = (x0 * y2 - y0 * x2) / (x1 * y2 - y1 * x2)
	local k2 = (x0 * y1 - y0 * x1) / (x2 * y1 - y2 * x1)
	return k1, k2
end

mathHelper.checkPolygonIntersect = function(polygon1, polygon2, cross_polygon)
	local a1 = math.abs(polygon1:getArea())
	local a2 = math.abs(polygon2:getArea())

	local p1, p2 = polygon1, polygon2
	if a1 < a2 then
		p1, p2 = polygon2, polygon1
	end

	local ps2 = {}
	p2:getPoints(ps2)

	-- local ps1 = {}
	-- p1:getPoints(ps1)
	-- for i, v1 in ipairs(ps1) do
	-- 	print('ps1', i, v1)
	-- end
	-- for i, v1 in ipairs(ps2) do
	-- 	print('ps2', i, v1)
	-- end
	-- print('================')

	local crossps = {}

	local intersect = false
	for i, v1 in ipairs(ps2) do
		local v2 = ps2[i + 1] or ps2[1]
		local cs = {1}
		if p1:checkInside(v1.x, v1.y) then
			intersect = true
			if not cross_polygon then
				break
			end

			table.insert(crossps, v1)
		end

		if p1:checkIntersect(v1.x, v1.y, v2.x, v2.y, cs) then
			intersect = true
			if not cross_polygon then
				break
			end

			for _, v in ipairs(cs) do
				table.insert(crossps, v)
			end
		end
	end

	if not intersect then
		return false
	end

	-- 返回相交的包围盒
	if cross_polygon then

		local ps1 = {}
		p1:getPoints(ps1)
		for i, v1 in ipairs(ps1) do
			if p2:checkInside(v1.x, v1.y) then
				table.insert(crossps, v1)
			end
		end
		-- print('checkPolygonIntersect2', #cps, #ps1, #ps2)
		-- for i, v in ipairs(cps) do
		-- 	print('cps', i, v)
		-- end
		cross_polygon:setPoints(crossps)
	end

	return true
end

mathHelper.Distance_Plane_Ray = function(axis, ori, dir, out)
	local pd = axis:magnitude()
	local pdir = v3_1
	_Vector3.mul(axis, 1 / pd, pdir)

	local cosa = _Vector3.dot(pdir, dir)
	if cosa <= 0 then return end

	local l = _Vector3.dot(pdir, ori)
	local d = pd - l
	if d < 0 then return end

	local rayl = d / cosa
	if out then
		_Vector3.mul(dir, rayl, out)
		_Vector3.add(out, ori, out)
	end
	return rayl
end

