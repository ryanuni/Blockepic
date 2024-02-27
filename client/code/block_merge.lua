local Optimizer = {}
_G.Optimizer = Optimizer

local defaultlimit = 0.015
Optimizer.errlimit = 0.015
Optimizer.datakey = nil
function Optimizer.isEqual(num1, num2)
	return math.abs(num1 - num2) < Optimizer.errlimit
end
local isEqual = Optimizer.isEqual

function Optimizer.isLess(num1, num2)
	return num1 < num2 and not isEqual(num1, num2)
end
local isLess = Optimizer.isLess

function Optimizer.isGreater(num1, num2)
	return num1 > num2 and not isEqual(num1, num2)
end
local isGreater = Optimizer.isGreater

local function box(t)
	return Optimizer.datakey and t[Optimizer.datakey] or t
end

function Optimizer.isBoxLessX(t1, t2)
	local box1, box2 = box(t1), box(t2)
	local min1, min2 = box1.min, box2.min
	if not isEqual(min1.z, min2.z) then return isLess(min1.z, min2.z) end
	if not isEqual(min1.y, min2.y) then return isLess(min1.y, min2.y) end
	if not isEqual(min1.x, min2.x) then return isLess(min1.x, min2.x) end

	local sz1, sz2 = box1.max.z - box1.min.z, box2.max.z - box2.min.z
	if not isEqual(sz1, sz2) then return isGreater(sz1, sz2) end

	local sy1, sy2 = box1.max.y - box1.min.y, box2.max.y - box2.min.y
	if not isEqual(sy1, sy2) then return isGreater(sy1, sy2) end

	local sx1, sx2 = box1.max.x - box1.min.x, box2.max.x - box2.min.x
	if not isEqual(sx1, sx2) then return isGreater(sx1, sx2) end
	return sx1 < sx2
end

function Optimizer.isBoxLessY(t1, t2)
	local box1, box2 = box(t1), box(t2)
	local min1, min2 = box1.min, box2.min
	if not isEqual(min1.z, min2.z) then return isLess(min1.z, min2.z) end
	if not isEqual(min1.x, min2.x) then return isLess(min1.x, min2.x) end
	if not isEqual(min1.y, min2.y) then return isLess(min1.y, min2.y) end

	local sz1, sz2 = box1.max.z - box1.min.z, box2.max.z - box2.min.z
	if not isEqual(sz1, sz2) then return isGreater(sz1, sz2) end

	local sx1, sx2 = box1.max.x - box1.min.x, box2.max.x - box2.min.x
	if not isEqual(sx1, sx2) then return isGreater(sx1, sx2) end

	local sy1, sy2 = box1.max.y - box1.min.y, box2.max.y - box2.min.y
	if not isEqual(sy1, sy2) then return isGreater(sy1, sy2) end
	return sy1 < sy2
end

function Optimizer.isBoxLessZ(t1, t2)
	local box1, box2 = box(t1), box(t2)

	local min1, min2 = box1.min, box2.min
	if not isEqual(min1.x, min2.x) then return isLess(min1.x, min2.x) end
	if not isEqual(min1.y, min2.y) then return isLess(min1.y, min2.y) end
	if not isEqual(min1.z, min2.z) then return isLess(min1.z, min2.z) end

	local sx1, sx2 = box1.max.x - box1.min.x, box2.max.x - box2.min.x
	if not isEqual(sx1, sx2) then return isGreater(sx1, sx2) end

	local sy1, sy2 = box1.max.y - box1.min.y, box2.max.y - box2.min.y
	if not isEqual(sy1, sy2) then return isGreater(sy1, sy2) end

	local sz1, sz2 = box1.max.z - box1.min.z, box2.max.z - box2.min.z
	if not isEqual(sz1, sz2) then return isGreater(sz1, sz2) end
	return sz1 < sz2
end

local AX = Global.AXISTYPE.X
local AY = Global.AXISTYPE.Y
local AZ = Global.AXISTYPE.Z
function Optimizer.sameBoxProject(face, t1, t2)
	local box1, box2 = box(t1), box(t2)

	if face == AX then
		return isEqual(box1.min.y, box2.min.y) and isEqual(box1.max.y, box2.max.y)
			and isEqual(box1.min.z, box2.min.z) and isEqual(box1.max.z, box2.max.z)
	elseif face == AY then
		return isEqual(box1.min.x, box2.min.x) and isEqual(box1.max.x, box2.max.x)
			and isEqual(box1.min.z, box2.min.z) and isEqual(box1.max.z, box2.max.z)
	elseif face == AZ then
		return isEqual(box1.min.x, box2.min.x) and isEqual(box1.max.x, box2.max.x)
			and isEqual(box1.min.y, box2.min.y) and isEqual(box1.max.y, box2.max.y)
	end
end

-- 测试模型是否可以合并，且返回合并后的范围
function Optimizer.testBoxMerge(face, t1, t2)
	if not Optimizer.sameBoxProject(face, t1, t2) then return nil end

	local box1, box2 = box(t1), box(t2)
	local min1, max1, min2, max2
	if face == AX then
		min1, max1, min2, max2 = box1.min.x, box1.max.x, box2.min.x, box2.max.x
	elseif face == AY then
		min1, max1, min2, max2 = box1.min.y, box1.max.y, box2.min.y, box2.max.y
	elseif face == AZ then
		min1, max1, min2, max2 = box1.min.z, box1.max.z, box2.min.z, box2.max.z
	end

	if isGreater(min1, max2) or isGreater(min2, max1) then return nil end

	return math.min(min1, min2), math.max(max1, max2)
end

-- local function vectostr(v)
-- 	return '{ x:' .. v.x .. ' y:' .. v.y .. ' z:' .. v.z .. '}'
-- end
-- local function dumpBoxs(boxes)
-- 	for i, v in ipairs(boxes) do
-- 		print(tostring(i) .. ' min:' .. vectostr(v.min) .. ' max:' .. vectostr(v.max))
-- 	end
-- end

function Optimizer.isRectLessX(t1, t2)
	if not isEqual(t1.y1, t2.y1) then return isLess(t1.y1, t2.y1) end
	if not isEqual(t1.x1, t2.x1) then return isLess(t1.x1, t2.x1) end

	local sy1, sy2 = t1.y2 - t1.y1, t2.y2 - t2.y1
	if not isEqual(sy1, sy2) then return isGreater(sy1, sy2) end

	local sx1, sx2 = t1.x2 - t1.x1, t2.x2 - t2.x1
	if not isEqual(sx1, sx2) then return isGreater(sx1, sx2) end
	return sx1 < sx2
end

function Optimizer.isRectLessY(t1, t2)

	if not isEqual(t1.x1, t2.x1) then return isLess(t1.x1, t2.x1) end
	if not isEqual(t1.y1, t2.y1) then return isLess(t1.y1, t2.y1) end

	local sx1, sx2 = t1.x2 - t1.x1, t2.x2 - t2.x1
	if not isEqual(sx1, sx2) then return isGreater(sx1, sx2) end

	local sy1, sy2 = t1.y2 - t1.y1, t2.y2 - t2.y1
	if not isEqual(sy1, sy2) then return isGreater(sy1, sy2) end

	return sy1 < sy2
end

function Optimizer.MergeBoxByFace(face, ts)
	local n = #ts

	if face == AX then
		table.sort(ts, Optimizer.isBoxLessX)
	elseif face == AY then
		table.sort(ts, Optimizer.isBoxLessY)
	elseif face == AZ then
		table.sort(ts, Optimizer.isBoxLessZ)
	end

	local index = 1
	while index < #ts do
		local t1 = ts[index]
		local cur = box(t1)
		local i = index + 1
		while i <= #ts do
			local t2 = ts[i]
			local minx, maxx = Optimizer.testBoxMerge(face, t1, t2)
			if not minx then break end

			-- 合并box
			if face == AX then
				cur.min.x, cur.max.x = minx, maxx
			elseif face == AY then
				cur.min.y, cur.max.y = minx, maxx
			elseif face == AZ then
				cur.min.z, cur.max.z = minx, maxx
			end
			table.remove(ts, i)

			-- 设置回调后处理合并操作
			if Optimizer.mergecb then
				Optimizer.mergecb(t1, t2)
			end
		end
		index = index + 1
	end

	return n - #ts
end

function Optimizer.MergeBoxs(ts, key, limit, mergecb, maxn)
	Optimizer.datakey = key
	Optimizer.mergecb = mergecb
	Optimizer.errlimit = limit or defaultlimit

	maxn = maxn or 5
	local cn = 0

	local n = 1
	while n ~= 0 and cn < maxn do
		-- local t1 = _tick()
		n = Optimizer.MergeBoxByFace(AX, ts)
		n = n + Optimizer.MergeBoxByFace(AY, ts)
		n = n + Optimizer.MergeBoxByFace(AZ, ts)
		-- local t2 = _tick()
		-- print('cost:', cn, maxn, n, t2 - t1)
		cn = cn + 1
	end
end

function Optimizer.sameRectProject(face, t1, t2)
	if face == AX then
		return isEqual(t1.y1, t2.y1) and isEqual(t1.y2, t2.y2)
	elseif face == AY then
		return isEqual(t1.x1, t2.x1) and isEqual(t1.x2, t2.x2)
	end
end

-- 测试模型是否可以合并，且返回合并后的范围
function Optimizer.testRectMerge(face, t1, t2)
	if not Optimizer.sameRectProject(face, t1, t2) then return nil end

	local min1, max1, min2, max2
	if face == AX then
		min1, max1, min2, max2 = t1.x1, t1.x2, t2.x1, t2.x2
	elseif face == AY then
		min1, max1, min2, max2 = t1.y1, t1.y2, t2.y1, t2.y2
	end

	if isGreater(min1, max2) or isGreater(min2, max1) then return nil end

	return math.min(min1, min2), math.max(max1, max2)
end

function Optimizer.MergeRectByFace(face, ts)
	local n = #ts

	if face == AX then
		table.sort(ts, Optimizer.isRectLessX)
	elseif face == AY then
		table.sort(ts, Optimizer.isRectLessY)
	end

	local index = 1
	while index < #ts do
		local t1 = ts[index]
		--local cur = box(t1)
		local i = index + 1
		while i <= #ts do
			local t2 = ts[i]
			-- if face == AY then
			-- 	print('t1', t1.x1, t1.x2, t1.y1, t1.y2)
			-- 	print('t2', t2.x1, t2.x2, t2.y1, t2.y2)
			-- 	print('sameRectProject', Optimizer.sameRectProject(face, t1, t2), Optimizer.testRectMerge(face, t1, t2))
			-- end
			local minx, maxx = Optimizer.testRectMerge(face, t1, t2)
			if not minx then break end

			-- 合并box
			if face == AX then
				t1.x1, t1.x2 = minx, maxx
			elseif face == AY then
				t1.y1, t1.y2 = minx, maxx
			end
			table.remove(ts, i)

			-- 设置回调后处理合并操作
			if Optimizer.mergecb then
				Optimizer.mergecb(t1, t2)
			end
		end
		index = index + 1
	end

	return n - #ts
end

function Optimizer.MergeRect(rs, mergecb, maxn, limit)
	Optimizer.mergecb = mergecb
	Optimizer.errlimit = limit or defaultlimit

	maxn = maxn or 3
	local cn = 0

	local n = 1
	while n ~= 0 and cn < maxn do
		n = Optimizer.MergeRectByFace(AX, rs)
		n = n + Optimizer.MergeRectByFace(AY, rs)
		cn = cn + 1
	end
end

function Optimizer.isRectCollision(t1, t2)
	if t2.x1 < t1.x2 and t2.y1 < t1.y2 then return true end

	return false
end

function Optimizer.filterCollisionRect(ts)
	local n = #ts

	Optimizer.errlimit = defaultlimit
	table.sort(ts, Optimizer.isRectLessX)
	-- for i, v in ipairs(ts) do
	-- 	print('ts', i, v.x1, v.x2, v.y1, v.y2)
	-- end

	local index = 1
	while index < #ts do
		local t1 = ts[index]
		local i = index + 1

		local collision = false
		while i <= #ts do
			local t2 = ts[i]
			if Optimizer.isRectCollision(t1, t2) then
				--print('t1', index, t1.x1, t1.x2, t1.y1, t1.y2)
				--print('t2', i, t2.x1, t2.x2, t2.y1, t2.y2)
				table.remove(ts, i)
				t1.collision = true
				t2.collision = true

				t1.k:addCollision(t2.k)
				collision = true
			end

			if t2.y1 >= t1.y2 then
				break
			end
			i = i + 1
		end

		if collision then
			table.remove(ts, index)
		else
			index = index + 1
		end
	end

	--print('filterCollisionRect', n, #ts)
	return n - #ts
end