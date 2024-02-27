_G.DrawHelper = {}

local axismat = _Matrix3D.new()
DrawHelper.drawPlane = function(center, masix, color, maxsize)
	local size = maxsize or 2
	local grid = 0.2
	local n = size / grid

	local x, y, z = center.x, center.y, center.z
	if masix.x == 1 then
		for i = -n, n do
			local x1 = i * grid + x
			if masix.y == 1 then
				_rd:draw3DLine(x1, y + size, z, x1, y - size, z, color)
			else
				_rd:draw3DLine(x1, y, z + size, x1, y, z - size, color)
			end
		end
	end

	if masix.y == 1 then
		for i = -n, n do
			local y1 = i * grid + y
			if masix.x == 1 then
				_rd:draw3DLine(x + size, y1, z, x - size, y1, z, color)
			else
				_rd:draw3DLine(x, y1, z + size, x, y1, z - size, color)
			end
		end
	end

	if masix.z == 1 then
		for i = -n, n do
			local z1 = i * grid + z
			if masix.x == 1 then
				_rd:draw3DLine(x + size, y, z1, x - size, y, z1, color)
			else
				_rd:draw3DLine(x, y + size, z1, x, y - size, z1, color)
			end
		end
	end

	axismat:setTranslation(center)
	_rd:pushMatrix3D(axismat)
	_rd:drawAxis(0.2)
	_rd:popMatrix3D()
end

DrawHelper.drawPlaneY = function(size, grid, z, c, c2)
	local w, h = 0, 0
	local camlength = _rd.camera.radius
	local lowview = camlength < 12
	local highview = camlength > 20

	if type(size) == 'number' then
		w = size
		h = size
		lowview = true
	else
		w = size.w
		h = size.h
		lowview = true
	end

	local color = c or 0xff92a2c1
	local color2 = c2 or c or 0xff92a2c1
	local nx = toint(w / grid)
	local ny = toint(h / grid)

	for i = -nx, nx do
		local x1 = i * grid
		if i == 0 then
			_rd:fill3DRect(x1, z, 0, 0, 0, h, 0.03, 0, 0, color2)
		elseif i % 4 == 0 then
			_rd:fill3DRect(x1, z, 0, 0, 0, h, 0.01, 0, 0, color2)
		elseif lowview or (i % 2 == 0 and highview == false) then
			_rd:draw3DLine(x1, z, h, x1, z, -h, color)
		end
	end

	for i = -ny, ny do
		local y1 = i * grid
		if i == 0 then
			_rd:fill3DRect(0, z, y1, w, 0, 0, 0, 0, 0.03, color2)
		elseif i % 4 == 0 then
			_rd:fill3DRect(0, z, y1, w, 0, 0, 0, 0, 0.01, color2)
		elseif lowview or (i % 2 == 0 and highview == false) then
			_rd:draw3DLine(w, z, y1, -w, z, y1, color)
		end
	end
end

DrawHelper.drawPlaneZ = function(size, grid, z, c, c2)
	local w, h = 0, 0
	local camlength = _rd.camera.radius
	local lowview = camlength < 12
	local highview = camlength > 20

	if type(size) == 'number' then
		w = size
		h = size
		lowview = true
	else
		w = size.w
		h = size.h
		lowview = true
	end

	local color = c or 0xff92a2c1
	local color2 = c2 or c or 0xff92a2c1
	local nx = toint(w / grid)
	local ny = toint(h / grid)

	for i = -nx, nx do
		local x1 = i * grid
		if i == 0 then
			_rd:fill3DRect(x1, 0, z, 0, h, 0, 0.03, 0, 0, color2)
		elseif i % 4 == 0 then
			_rd:fill3DRect(x1, 0, z, 0, h, 0, 0.01, 0, 0, color2)
		elseif lowview or (i % 2 == 0 and highview == false) then
			_rd:draw3DLine(x1, h, z, x1, -h, z, color)
		end
	end

	for i = -ny, ny do
		local y1 = i * grid
		if i == 0 then
			_rd:fill3DRect(0, y1, z, w, 0, 0, 0, 0.03, 0, color2)
		elseif i % 4 == 0 then
			_rd:fill3DRect(0, y1, z, w, 0, 0, 0, 0.01, 0, color2)
		elseif lowview or (i % 2 == 0 and highview == false) then
			_rd:draw3DLine(w, y1, z, -w, y1, z, color)
		end
	end
end

DrawHelper.drawShadowZ = function(range, grid, z, c)
	local nx1 = math.floor(range.x1 / grid + 0.5) + 1
	local nx2 = math.floor(range.x2 / grid + 0.5)
	local ny1 = math.floor(range.y1 / grid + 0.5) + 1
	local ny2 = math.floor(range.y2 / grid + 0.5)
	local sx, sy = nx1 * grid, nx2 * grid
	for i = nx1, nx2 do
		local x1 = i * grid - grid / 2
		for j = ny1, ny2 do
			local y1 = j * grid - grid / 2
			_rd:fill3DRect(x1, y1, z, 0, grid / 4, 0, grid / 4, 0, 0, c)
		end
	end
end

local KnotSize = _Vector3.new(0.01, 0.01, 0.01)
local KnotAB = _AxisAlignedBox.new()
DrawHelper.drawKnot = function(v, color, mat)
	if not v then return end
	_Vector3.sub(v, KnotSize, KnotAB.min)
	_Vector3.add(v, KnotSize, KnotAB.max)
	if mat then
		KnotAB:mul(mat)
	end

	KnotAB:draw(color)
end

local min_vec = _Vector3.new()
local max_vec = _Vector3.new()
DrawHelper.drawMergeKnot = function(v1, v2, color, mat)
	DrawHelper.drawKnot(v1, color, mat)
	DrawHelper.drawKnot(v2, color, mat)
	_rd:draw3DLine(v1.x, v1.y, v1.z, v2.x, v2.y, v2.z, color)
	-- if not v1 or not v2 then return end
	-- min_vec.x = math.min(v1.x, v2.x)
	-- min_vec.y = math.min(v1.y, v2.y)
	-- min_vec.z = math.min(v1.z, v2.z)

	-- max_vec.x = math.max(v1.x, v2.x)
	-- max_vec.y = math.max(v1.y, v2.y)
	-- max_vec.z = math.max(v1.z, v2.z)
	-- _Vector3.sub(min_vec, KnotSize, KnotAB.min)
	-- _Vector3.add(max_vec, KnotSize, KnotAB.max)
	-- if mat then
	-- 	KnotAB:mul(mat)
	-- end

	-- KnotAB:draw(color)
end

local tempv3 = _Vector3.new()
DrawHelper.drawRay = function(ori, dir, l, color)

	_Vector3.mul(dir, l, tempv3)
	_Vector3.add(ori, tempv3, tempv3)

	_rd:draw3DLine(ori.x, ori.y, ori.z, tempv3.x, tempv3.y, tempv3.z, color)
end

local helpmesh = _Mesh.new('kbaoweikuan_01.msh')
local ab = helpmesh:getBoundBox()
helpmesh.transform:setScaling(1 / (ab.x2 - ab.x1), 1 / (ab.y2 - ab.y1), 1 / (ab.z2 - ab.z1))
local helpmat = _Matrix3D.new()
local helpvec = _Vector3.new()
local helpvec2 = _Vector3.new()

DrawHelper.drawCornnerBox = function(ab)
	ab:getSize(helpvec)
	helpmat:setScaling(helpvec)
	ab:getBottom(helpvec)
	helpmat:mulTranslationRight(helpvec)

	_rd:pushMatrix3D(helpmat)
	helpmesh:drawMesh()
	_rd:popMatrix3D()
end

local cornnermesh = _Mesh.new('kbaoweihe_01.msh')
cornnermesh.transform:setScaling(0.1, 0.1, 0.1)
cornnermesh.transform:mulRotationZLeft(-math.pi / 2)
cornnermesh.transform:mulTranslationRight(0.4, 0.4, 0)

local ab = cornnermesh:getBoundBox()
local corsize = _Vector3.new(ab.x2 - ab.x1, ab.y2 - ab.y1, ab.z2 - ab.z1)

local planemesh = _Mesh.new('kbaoweihe_02.msh')
local ab = planemesh:getBoundBox()
planemesh.transform:setScaling(1 / (ab.x2 - ab.x1), 1 / (ab.y2 - ab.y1), 1 / (ab.z2 - ab.z1))

-- local box = _mf:createCube()
-- box.isAlpha = true
-- box.isAlphaFilter = true
-- box.transform:setScaling(0.5, 0.5, 0.5)
-- _mf:paintDiffuse(box, 0x00ffffff)

local box = _mf:createCube()
box.isAlpha = true
box.isAlphaFilter = true
-- box.material = _Material.new('glass.mtl')
box.transform:setScaling(0.01, 0.01, 0.5)
box.ssaoReceiver = false

DrawHelper.drawEdgeBox = function(ab, blender)
	ab:getSize(helpvec)
	local sx, sy, sz = helpvec.x, helpvec.y, helpvec.z
	ab:getCenter(helpvec)
	local cx, cy, cz = helpvec.x, helpvec.y, helpvec.z

	local min, max = ab.min, ab.max

	-- local mtl = Block.getMaterial(8, color or 0xffffff00, 1, Global.MTLMODE.EMISSIVE)
	-- box.material = mtl

	local function drawLine(i, s, x, y, z)
		--helpmat:setScaling(1, 1, s)

		helpvec:set(x, y, z)
		local x1, y1, s1 = _G.projectWithSize(helpvec, 0.02)
		--helpmat:mulTranslationRight(x, y, z)
		helpmat:setTranslation(x, y, z)
		if i == 1 then
			helpmat:mulRotationYLeft(math.pi * 0.5)
		elseif i == 2 then
			helpmat:mulRotationXLeft(math.pi * 0.5)
		end

		-- 小于4(一半)像素时放大
		local xs = 1
		if s1 < 2 then
			xs = 2 / s1
		end
		helpmat:mulScalingLeft(xs, xs, s)

		_rd:pushMatrix3D(helpmat)
		if blender then _rd:useBlender(blender) end
		box:drawMesh()
		if blender then _rd:popBlender() end
		_rd:popMatrix3D()
	end

	for i = 1, 3 do
		if i == 1 then
			drawLine(i, sx, cx, min.y, min.z)
			drawLine(i, sx, cx, min.y, max.z)
			drawLine(i, sx, cx, max.y, min.z)
			drawLine(i, sx, cx, max.y, max.z)
		elseif i == 2 then
			drawLine(i, sy, min.x, cy, min.z)
			drawLine(i, sy, min.x, cy, max.z)
			drawLine(i, sy, max.x, cy, min.z)
			drawLine(i, sy, max.x, cy, max.z)
		else
			drawLine(i, sz, min.x, min.y, cz)
			drawLine(i, sz, min.x, max.y, cz)
			drawLine(i, sz, max.x, min.y, cz)
			drawLine(i, sz, max.x, max.y, cz)
		end
	end
end

DrawHelper.drawCornnerBox2 = function(ab, blender)
	ab:getSize(helpvec)
	helpmat:setScaling(helpvec)
	ab:getBottom(helpvec)
	helpmat:mulTranslationRight(helpvec)
	_rd:pushMatrix3D(helpmat)
	if blender then _rd:useBlender(blender) end
	planemesh:drawMesh()
	if blender then _rd:popBlender() end
	_rd:popMatrix3D()

	ab:getSize(helpvec)

	local sx = math.min(helpvec.x / corsize.x * 0.25, 1)
	local sy = math.min(helpvec.y / corsize.y * 0.25, 1)
	local sz = math.min(helpvec.z / corsize.z * 0.25, 1)

	for i = 1, 8 do
		helpmat:setScaling(sx, sy, sz)
		if i == 1 then
			helpmat:mulScalingRight(1, 1, -1)
		elseif i == 2 then
			helpmat:mulScalingRight(1, -1, -1)
		elseif i == 3 then
			helpmat:mulScalingRight(-1, 1, -1)
		elseif i == 4 then
			helpmat:mulScalingRight(-1, -1, -1)
		elseif i == 5 then
			--helpmat:mulScalingRight(1, 1, 1)
		elseif i == 6 then
			helpmat:mulScalingRight(1, -1, 1)
		elseif i == 7 then
			helpmat:mulScalingRight(-1, 1, 1)
		elseif i == 8 then
			helpmat:mulScalingRight(-1, -1, 1)
		end

		ab:getPoint(i, helpvec)
		helpmat:mulTranslationRight(helpvec)

		_rd:pushMatrix3D(helpmat)
		if blender then _rd:useBlender(blender) end
		cornnermesh:drawMesh()
		if blender then _rd:popBlender() end
		_rd:popMatrix3D()
	end
end

local SHAPES = {
	_TYPE_RECTANGLE = 1,
}

local ORIGINS = {
	_TOPLEFT = 1,
	_TOPRIGHT = 2,
	_BOTTOMLEFT = 3,
	_BOTTOMRIGHT = 4,

	_TOP = 1,
	_BOTTOM = 2,
	_LEFT = 3,
	_RIGHT = 4,
}

DrawHelper.FillRadial90 = function(origin, amount, clockwise, lt, rb, shapes)
	local width = rb.x - lt.x
	local height = rb.y - lt.y

	if amount == 1 then
		local shape = {}
		shape.ps = {}

		shape.type = SHAPES._TYPE_RECTANGLE
		table.insert(shape.ps, _Vector2.new(lt.x, lt.y))
		table.insert(shape.ps, _Vector2.new(rb.x, rb.y))

		table.insert(shapes, shape)
		return
	end

	if origin == ORIGINS._TOPLEFT then
		if clockwise then
			local shape = {ps = {}}
			table.insert(shape.ps, lt)
			table.insert(shape.ps, _Vector2.new(rb.x, lt.y))

			local h = width * math.tan(math.pi / 2 * amount)
			if h > height then
				table.insert(shape.ps, rb)

				local shape2 = {ps = {}}
				local ratio = (h - height) / h
				table.insert(shape2.ps, lt)
				table.insert(shape2.ps, rb)
				table.insert(shape2.ps, _Vector2.new(lt.x + width * (1 - ratio), rb.y))

				table.insert(shapes, shape)
				table.insert(shapes, shape2)
			else
				table.insert(shape.ps, _Vector2.new(rb.x, lt.y + h))
				table.insert(shapes, shape)
			end
		else
			local shape = {ps= {}}
			table.insert(shape.ps, lt)

			table.insert(shape.ps, _Vector2.new(lt.x, rb.y))
			local v = math.tan(math.pi / 2 * (1.0 - amount))
			local h = width * v
			if v > height then
				local ratio = (h - height) / h
				table.insert(shape.ps, _Vector2.new(lt.x + width * (1.0 - ratio), rb.y))
				table.insert(shapes, shape)
			else
				table.insert(shape.ps, rb)

				local shape2 = {ps = {}}
				table.insert(shape2.ps, lt)
				table.insert(shape2.ps, rb)

				table.insert(shape2.ps, _Vector2.new(rb.x, lt.y + h))

				table.insert(shapes, shape)
				table.insert(shapes, shape2)
			end
		end
	elseif origin == ORIGINS._TOPRIGHT then
		if clockwise then
			local shape = {ps= {}}
			table.insert(shape.ps, _Vector2.new(rb.x, lt.y))

			table.insert(shape.ps, rb)
			local v = math.tan(math.pi / 2 * (1.0 - amount))
			local h = width * v
			if h > height then
				local ratio = (h - height) / h
				table.insert(shape.ps, _Vector2.new(lt.x + width * ratio, rb.y))

				table.insert(shapes, shape)
			else
				table.insert(shape.ps, _Vector2.new(lt.x, rb.y))

				local shape2 = {ps = {}}
				table.insert(shape2.ps, _Vector2.new(rb.x, lt.y))
				table.insert(shape2.ps, _Vector2.new(lt.x, rb.y))
				table.insert(shape2.ps, _Vector2.new(lt.x, lt.y + h))

				table.insert(shapes, shape)
				table.insert(shapes, shape2)
			end
		else
			local shape = {ps= {}}
			table.insert(shape.ps, _Vector2.new(rb.x, lt.y))
			table.insert(shape.ps, _Vector2.new(lt))

			local h = width * math.tan(math.pi / 2 * amount)
			if h > height then
				table.insert(shape.ps, _Vector2.new(lt.x, rb.y))

				local shape2 = {ps = {}}
				table.insert(shape2.ps, _Vector2.new(rb.x, lt.y))
				table.insert(shape2.ps, _Vector2.new(lt.x, rb.y))

				local ratio = (h - height) / h
				table.insert(shape2.ps, _Vector2.new(lt.x + width * ratio, rb.y))

				table.insert(shapes, shape)
				table.insert(shapes, shape2)
			else
				table.insert(shape.ps, _Vector2.new(lt.x, lt.y + h))
				table.insert(shapes, shape)
			end
		end
	elseif origin == ORIGINS._BOTTOMLEFT then
		if clockwise then
			local shape = {ps= {}}
			table.insert(shape.ps, _Vector2.new(lt.x, rb.y))
			table.insert(shape.ps, lt)

			local h = width * math.tan(math.pi / 2 * (1.0 - amount))
			if h > height then
				local ratio = (h - height) / h
				table.insert(shape.ps, _Vector2.new(lt.x + width * (1 - ratio), lt.y))

				table.insert(shapes, shape)
			else
				table.insert(shape.ps, _Vector2.new(rb.x, lt.y))

				local shape2 = {ps = {}}
				table.insert(shape2.ps, _Vector2.new(lt.x, rb.y))
				table.insert(shape2.ps, _Vector2.new(rb.x, lt.y))
				table.insert(shape2.ps, _Vector2.new(rb.x, rb.y - h))

				table.insert(shapes, shape)
				table.insert(shapes, shape2)
			end
		else
			local shape = {ps= {}}
			table.insert(shape.ps, _Vector2.new(lt.x, rb.y))
			table.insert(shape.ps, _Vector2.new(rb))

			local h = width * math.tan(math.pi / 2 * amount)
			if h > height then
				table.insert(shape.ps, _Vector2.new(rb.x, lt.y))

				local shape2 = {ps = {}}
				table.insert(shape2.ps, _Vector2.new(lt.x, rb.y))
				table.insert(shape2.ps, _Vector2.new(rb.x, lt.y))

				local ratio = (h - height) / h
				table.insert(shape2.ps, _Vector2.new(lt.x + width * (1 - ratio), lt.y))

				table.insert(shapes, shape)
				table.insert(shapes, shape2)
			else
				table.insert(shape.ps, _Vector2.new(rb.x, rb.y - h))
				table.insert(shapes, shape)
			end
		end
	elseif origin == ORIGINS._BOTTOMRIGHT then
		if clockwise then
			local shape = {ps= {}}
			table.insert(shape.ps, rb)
			table.insert(shape.ps, _Vector2.new(lt.x, rb.y))

			local h = width * math.tan(math.pi / 2 * amount)
			if h > height then
				table.insert(shape.ps, lt)

				local ratio = (h - height) / h
				local shape2 = {ps = {}}
				table.insert(shape2.ps, rb)
				table.insert(shape2.ps, lt)
				table.insert(shape2.ps, _Vector2.new(lt.x + width * ratio, lt.y))

				table.insert(shapes, shape)
				table.insert(shapes, shape2)
			else
				table.insert(shape.ps, _Vector2.new(lt.x, rb.y - h))
				table.insert(shapes, shape)
			end
		else
			local shape = {ps= {}}
			table.insert(shape.ps, rb)
			table.insert(shape.ps, _Vector2.new(rb.x, lt.y))

			local h = width * math.tan(math.pi / 2 * (1.0 - amount))
			if h > height then
				local ratio = (h - height) / h
				table.insert(shape.ps, _Vector2.new(lt.x + width * ratio, lt.y))
				table.insert(shapes, shape)
			else
				table.insert(shape.ps, lt)

				local shape2 = {ps = {}}
				table.insert(shape2.ps, rb)
				table.insert(shape2.ps, lt)
				table.insert(shape2.ps, _Vector2.new(lt.x, rb.y - h))

				table.insert(shapes, shape)
				table.insert(shapes, shape2)
			end
		end
	end
end

DrawHelper.FillRadial180 = function(origin, amount, clockwise, lt, rb, shapes)
	local width = rb.x - lt.x
	local height = rb.y - lt.y
	if origin == ORIGINS._TOP then
		if amount <= 0.5 then
			width = width / 2
			if clockwise then
				lt.x = lt.x + width
			else
				rb.x = rb.x - width
				amount = amount / 0.5
				DrawHelper.FillRadial90(clockwise and ORIGINS._TOPLEFT or ORIGINS._TOPRIGHT, amount, clockwise, lt, rb, shapes)
			end
		else
			width = width / 2

			local shape = {ps= {}}
			shape.type = SHAPES._TYPE_RECTANGLE
			table.insert(shape.ps, clockwise and _Vector2.new(rb) or _Vector2.new(lt))
			table.insert(shape.ps, clockwise and _Vector2.new(lt.x + width, lt.y) or _Vector2.new(lt.x + width, rb.y))
			table.insert(shapes, shape)

			if not clockwise then
				lt.x = lt.x + width
			else
				rb.x = lt.x - width
			end

			amount = (amount - 0.5) / 0.5
			DrawHelper.FillRadial90(clockwise and ORIGINS._TOPRIGHT or ORIGINS._TOPLEFT, amount, clockwise, lt, rb, shapes)
		end
	elseif origin == ORIGINS._BOTTOM then
		if amount <= 0.5 then
			width = width / 2
			if clockwise then
				rb.x = rb.x - width
			else
				lt.x = rb.x + width
			end
			amount = amount / 0.5
			DrawHelper.FillRadial90(clockwise and ORIGINS._BOTTOMRIGHT or ORIGINS._BOTTOMLEFT, amount, clockwise, lt, rb, shapes)
		else
			width = width / 2

			local shape = {ps = {}}
			shape.type = SHAPES._TYPE_RECTANGLE
			table.insert(shape.ps, clockwise and _Vector2.new(lt) or _Vector2.new(rb))
			table.insert(shape.ps, clockwise and _Vector2.new(lt.x + width, rb.y) or _Vector2.new(lt.x + width, lt.y))
			table.insert(shapes, shape)

			if not clockwise then
				rb.x = rb.x - width
			else
				lt.x = lt.x + width
			end
			amount = (amount - 0.5) / 0.5
			DrawHelper.FillRadial90(clockwise and ORIGINS._BOTTOMLEFT or ORIGINS._BOTTOMRIGHT, amount, clockwise, lt, rb, shapes)
		end
	elseif origin == ORIGINS._LEFT then
		if amount <= 0.5 then
			height = height / 2
			if clockwise then
				rb.y = rb.y - height
			else
				lt.y = lt.y + height
			end
			amount = amount / 0.5
			DrawHelper.FillRadial90(clockwise and ORIGINS._BOTTOMLEFT or ORIGINS._TOPLEFT, amount, clockwise, lt, rb, shapes)
		else
			height = height / 2

			local shape = {ps= {}}
			shape.type = SHAPES._TYPE_RECTANGLE
			table.insert(shape.ps, clockwise and _Vector2.new(lt) or _Vector2.new(rb))
			table.insert(shape.ps, clockwise and _Vector2.new(rb.x, lt.y + height) or _Vector2.new(lt.x, lt.y + height))
			table.insert(shapes, shape)

			if clockwise then
				lt.y = lt.y + height
			else
				rb.y = rb.y - height
			end
			amount = (amount - 0.5) / 0.5
			DrawHelper.FillRadial90(clockwise and ORIGINS._TOPLEFT or ORIGINS._BOTTOMLEFT, amount, clockwise, lt, rb, shapes)
		end
	elseif origin == ORIGINS._RIGHT then
		if amount <= 0.5 then
			height = height / 2
			if clockwise then
				lt.y = lt.y + height
			else
				rb.y = rb.y - height
			end
			amount = amount / 0.5
			DrawHelper.FillRadial90(clockwise and ORIGINS._TOPRIGHT or ORIGINS._BOTTOMRIGHT, amount, clockwise, lt, rb, shapes)
		else
			height = height / 2

			local shape = {ps= {}}
			shape.type = SHAPES._TYPE_RECTANGLE
			table.insert(shape.ps, clockwise and _Vector2.new(rb) or _Vector2.new(lt))
			table.insert(shape.ps, clockwise and _Vector2.new(lt.x, lt.y + height) or _Vector2.new(rb.x, lt.y + height))
			table.insert(shapes, shape)

			if clockwise then
				rb.y = rb.y - height
			else
				lt.y = lt.y + height
			end
			amount = (amount - 0.5) / 0.5
			DrawHelper.FillRadial90(clockwise and ORIGINS._BOTTOMRIGHT or ORIGINS._TOPRIGHT, amount, clockwise, lt, rb, shapes)
		end
	end
end

DrawHelper.FillRadial360 = function(origin, amount, clockwise, lt, rb, shapes)
	local width = rb.x - lt.x
	local height = rb.y - lt.y
	if origin == ORIGINS._TOP then
		if amount < 0.5 then
			amount = amount / 0.5
			width = width / 2

			if clockwise then
				lt.x = lt.x + width
			else
				rb.x = rb.x - width
			end

			DrawHelper.FillRadial180(clockwise and ORIGINS._LEFT or ORIGINS._RIGHT, amount, clockwise, lt, rb, shapes)
		else
			width = width / 2

			local shape = {ps= {}}
			shape.type = SHAPES._TYPE_RECTANGLE
			table.insert(shape.ps, clockwise and _Vector2.new(lt.x + width, lt.y) or _Vector2.new(lt.x + width, rb.y))
			table.insert(shape.ps, clockwise and _Vector2.new(rb) or _Vector2.new(lt))
			table.insert(shapes, shape)

			if not clockwise then
				lt.x = lt.x + width
			else
				rb.x = rb.x - width
			end

			amount = (amount - 0.5) / 0.5
			if amount ~= 0 then
				DrawHelper.FillRadial180(clockwise and ORIGINS._RIGHT or ORIGINS._LEFT, amount, clockwise, lt, rb, shapes)
			end
		end
	elseif origin == ORIGINS._BOTTOM then
		if amount < 0.5 then
				amount = amount / 0.5
				width = width / 2
				if clockwise then
					rb.x = rb.x - width
				else
					lt.x = lt.x + width
				end

				DrawHelper.FillRadial180(clockwise and ORIGINS._RIGHT or ORIGINS._LEFT, amount, clockwise, lt, rb, shapes)
			else
				width = width / 2

				local shape = {ps= {}}
				shape.type = SHAPES._TYPE_RECTANGLE
				table.insert(shape.ps, clockwise and _Vector2.new(lt) or _Vector2.new(rb))
				table.insert(shape.ps, clockwise and _Vector2.new(lt.x + width, rb.y) or _Vector2.new(lt.x + width, lt.y))
				table.insert(shapes, shape)

				if clockwise then
					lt.x = lt.x + width
				else
					rb.x = rb.x - width
				end

				amount = (amount - 0.5) / 0.5
				if amount ~= 0 then
					DrawHelper.FillRadial180(clockwise and ORIGINS._LEFT or ORIGINS._RIGHT, amount, clockwise, lt, rb, shapes)
				end
			end
	elseif origin == ORIGINS._LEFT then
		if amount < 0.5 then
			amount = amount / 0.5
			height = height / 2
			if clockwise then
				rb.y = rb.y - height
			else
				lt.y = lt.y + height
			end

			DrawHelper.FillRadial180(clockwise and ORIGINS._BOTTOM or ORIGINS._TOP, amount, clockwise, lt, rb, shapes)
		else
			height = height / 2

			local shape = {ps= {}}
			shape.type = SHAPES._TYPE_RECTANGLE
			table.insert(shape.ps, clockwise and _Vector2.new(lt) or _Vector2.new(rb))
			table.insert(shape.ps, clockwise and _Vector2.new(rb.x, lt.y + height) or _Vector2.new(lt.x, lt.y + height))
			table.insert(shapes, shape)

			if clockwise then
				lt.y = lt.y + height
			else
				rb.y = rb.y - height
			end

			amount = (amount - 0.5) / 0.5
			if amount ~= 0 then
				DrawHelper.FillRadial180(clockwise and ORIGINS._TOP or ORIGINS._BOTTOM, amount, clockwise, lt, rb, shapes)
			end
		end
	elseif origin == ORIGINS._RIGHT then
		if amount < 0.5 then
			height = height / 2
			if clockwise then
				lt.y = lt.y + height
			else
				rb.y = rb.y - height
			end

			amount = amount / 0.5
			if amount ~= 0 then
				DrawHelper.FillRadial180(clockwise and ORIGINS._TOP or ORIGINS._BOTTOM, amount, clockwise, lt, rb, shapes)
			end
		else
			height = height / 2

			local shape = {ps = {}}
			shape.type = SHAPES._TYPE_RECTANGLE
			table.insert(shape.ps, clockwise and _Vector2.new(rb) or _Vector2.new(lt))
			table.insert(shape.ps, clockwise and _Vector2.new(lt.x, lt.y + height) or _Vector2.new(rb.x, lt.y + height))
			table.insert(shapes, shape)

			if clockwise then
				rb.y = rb.y - height
			else
				lt.y = lt.y + height
			end

			amount = (amount - 0.5) / 0.5
			if amount ~= 0 then
				DrawHelper.FillRadial180(clockwise and ORIGINS._BOTTOM or ORIGINS._TOP, amount, clockwise, lt, rb, shapes)
			end
		end
	end
end

DrawHelper.drawFillRadialShapes = function(shapes, color)
	for i, shape in ipairs(shapes) do
		if shape.type == SHAPES._TYPE_RECTANGLE then
			local lt, rb = shape.ps[1], shape.ps[2]
			if lt and rb then
				_rd:fillRect(lt.x, lt.y, rb.x, rb.y, color)
			end
		elseif #shape.ps >= 3 then
			for pi = 1, #shape.ps - 2 do
				local p1, p2, p3 = shape.ps[pi], shape.ps[pi + 1], shape.ps[pi + 2]
				_rd:fillTriangle(p1.x, p1.y, p2.x, p2.y, p3.x, p3.y, color)
			end
		end
	end
end