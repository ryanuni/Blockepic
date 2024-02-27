_require('ExtendMesh')
_require('ExtendMaterial')
local Container = _require('Container')
_sys:addPath('toy')
_sys:addPath('images/quality')

_G.Block = {}

local KnotsData = _dofile('cfg_knots.lua')
Global.KnotsData = KnotsData

_dofile('cfg_blocks.lua')
Block.defaultAmbientLight = _AmbientLight.new()
Block.defaultAmbientLight.color = 0xffffffff
Block.defaultSkyLight = _SkyLight.new()
Block.defaultSkyLight.color = 0xffffffff
Global.PhyxShapes = _dofile('cfg_phyxshapes.lua')
_dofile('cfg_repair.lua')
_dofile('blueprint.lua')
_dofile('dynamicEffect.lua')

--Block.MaxBlockID = #_G.cfg_blocks[1]
Block.BrickIDs = {}
for id, v in pairs(_G.cfg_blocks[1]) do
	table.insert(Block.BrickIDs, id)
end

table.sort(Block.BrickIDs, function(a, b)
	return a < b
end)

Block.getBlockData = function(id)
	local blockdatas = _G.cfg_blocks[1]
	assert(blockdatas[id], 'block is not exist, id:' .. id)
	return blockdatas[id]
end

Block.HELPERDATA = {}

local clone_mesh = function(m)
	local nm = m:clone()
	nm.isAlphaFilter = m.isAlphaFilter
	nm.isDetail = m.isDetail
	nm.lodMesh = m.lodMesh and m.lodMesh:clone()
	return nm
end

local function encodeMeshRes(filename)
	local path = _sys:getPathName(filename)
	local resname = _sys:getFileName(filename, false, false)
	local ext = _sys:getExtention(filename)

	local ret = ''

	local encode = ''
	for i = 1, string.len(resname) do
		local c = string.byte(string.sub(resname, i, i))

		if c > 47 and c <= 57 then
			c = c + 49
		end

		encode = encode .. string.char(c)
	end

	if path and string.len(path) > 0 then
		ret = path .. '/' .. encode .. '.' .. ext
	else
		ret = encode .. '.' .. ext
	end

	return ret
end

local res_func = function(res)
	if _sys:getGlobal('PCPackage') then
		return encodeMeshRes(res)
	else
		return res
	end
end
local function initShapeData()
	local ab1 = Container:get(_AxisAlignedBox)
	local ab2 = Container:get(_AxisAlignedBox)
	for _, id in ipairs(Block.BrickIDs) do
		local v = Block.getBlockData(id)

		local boxsize = _Vector3.new()
		local boxcenter = _Vector3.new()
		if v.boxsize then
			boxsize.x, boxsize.y, boxsize.z = v.boxsize[1], v.boxsize[2], v.boxsize[3]
			boxcenter.x, boxcenter.y, boxcenter.z = v.boxcenter[1], v.boxcenter[2], v.boxcenter[3]
		else
			-- encode res.

			local res = res_func(v.res)

			local msh = _Mesh.new(res)
			local bb = msh:getBoundBox()

			boxsize.x = bb.x2 - bb.x1
			boxsize.y = bb.y2 - bb.y1
			boxsize.z = bb.z2 - bb.z1

			boxcenter.x = (bb.x2 + bb.x1) * 0.5
			boxcenter.y = (bb.y2 + bb.y1) * 0.5
			boxcenter.z = (bb.z2 + bb.z1) * 0.5
		end

		local shapes = {}
		if Global.PhyxShapes[id] then
			local datas = Global.PhyxShapes[id]
			for i, s in ipairs(datas) do
				local size = _Vector3.new()
				local offset = _Vector3.new()
				size.x = s.size[1]
				size.y = s.size[2]
				size.z = s.size[3]

				offset.x = s.offset[1]
				offset.y = s.offset[2]
				offset.z = s.offset[3]

				table.insert(shapes, {size = size, offset = offset})
			end
		else
			local size = _Vector3.new()
			local offset = _Vector3.new()
			_Vector3.mul(boxsize, 0.5, size)
			offset:set(boxcenter)
			table.insert(shapes, {size = size, offset = offset})
		end

		local knots = Global.KnotsData[id]
		local rotpivot = false
		if knots then
			for i, k in ipairs(knots) do if not k.subtype then
				if k.type == KnotManager.PAIRTYPE.HANDLE_WITHNORMAL
					or k.type == KnotManager.PAIRTYPE.TUBE_FORHANDLE
					or k.type == KnotManager.PAIRTYPE.HANDLE
					or k.type == KnotManager.PAIRTYPE.SPHERE_FORHANDLE
					or k.type == KnotManager.PAIRTYPE.TUBE
					or k.type == KnotManager.PAIRTYPE.TUBE_BLANK then
				local size = _Vector3.new()
				local offset = _Vector3.new()
				if k.pos2 then
					_Vector3.add(k.pos1, k.pos2, offset)
					_Vector3.mul(offset, 0.5, offset)

					size:set(0.02, 0.02, 0.02)
					local N = Global.getNearestAxisType(k.Normal)
					if N == Global.AXISTYPE.Z or N == Global.AXISTYPE.NZ then
						size.z = math.abs(k.pos2.z - k.pos1.z) / 2
					elseif N == Global.AXISTYPE.X or N == Global.AXISTYPE.NX then
						size.x = math.abs(k.pos2.x - k.pos1.x) / 2
					elseif N == Global.AXISTYPE.Y or N == Global.AXISTYPE.NY then
						size.y = math.abs(k.pos2.y - k.pos1.y) / 2
					end
				else
					offset:set(k.pos1)
					size:set(0.02, 0.02, 0.02)
				end

				k.index = i

				-- if k and k.rotpivot then
					rotpivot = true
				-- end
				table.insert(shapes, {size = size, offset = offset, jdata = k})
			end end
			end
		end
		local data = {
			boxsize = boxsize,
			boxcenter = boxcenter,
			shapes = shapes,
			rotpivot = rotpivot,
			brickcount = 1,
		}

		Block.addHelperData(id, nil, data)
	end

	Container:returnBack(ab1, ab2)
end

Block.getAABBs = function(bs, ab1)
	if not ab1 then ab1 = _AxisAlignedBox.new() end
	ab1:initBox()
	local ab2 = Container:get(_AxisAlignedBox)
	local n = 0
	for i, b in ipairs(bs) do
		if not b:getAABBSkipped() then
			b:getAABB(ab2)
			ab1.min.x = math.min(ab1.min.x, ab2.min.x)
			ab1.min.y = math.min(ab1.min.y, ab2.min.y)
			ab1.min.z = math.min(ab1.min.z, ab2.min.z)

			ab1.max.x = math.max(ab1.max.x, ab2.max.x)
			ab1.max.y = math.max(ab1.max.y, ab2.max.y)
			ab1.max.z = math.max(ab1.max.z, ab2.max.z)

			n = n + 1
		end
	end

	if n == 0 then
		--ab1:initNull()
		-- 都是marker时重新计算包围盒
		for i, b in ipairs(bs) do
			b:getAABB(ab2)
			_AxisAlignedBox.union(ab2, ab1, ab1)
		end
	end

	Container:returnBack(ab2)

	return ab1
end

Block.getShapeAABBs = function(bs, ab1, ignoreTransform)
	if #bs == 0 then
		ab1.min:set(0, 0, 0)
		ab1.max:set(0, 0, 0)
		return
	end

	ab1:initBox()
	local ab2 = Container:get(_AxisAlignedBox)
	local n = 0
	for i, b in ipairs(bs) do
		if not b:getAABBSkipped() then
			b:getShapeAABB(ab2, ignoreTransform)
			_AxisAlignedBox.union(ab2, ab1, ab1)
			n = n + 1
		end
	end

	if n == 0 then
		--ab1:initNull()
		-- 都是marker时重新计算包围盒
		for i, b in ipairs(bs) do
			b:getShapeAABB(ab2, ignoreTransform)
			_AxisAlignedBox.union(ab2, ab1, ab1)
		end
	end

	Container:returnBack(ab2)
end

Block.isAABBIntersect = function(ab1, ab2)
	local minx1 = ab1.min.x + 0.01
	local miny1 = ab1.min.y + 0.01
	local minz1 = ab1.min.z + 0.01
	local maxx1 = ab1.max.x - 0.01
	local maxy1 = ab1.max.y - 0.01
	local maxz1 = ab1.max.z - 0.01
	local minx2 = ab2.min.x + 0.01
	local miny2 = ab2.min.y + 0.01
	local minz2 = ab2.min.z + 0.01
	local maxx2 = ab2.max.x - 0.01
	local maxy2 = ab2.max.y - 0.01
	local maxz2 = ab2.max.z - 0.01
	return ((minx1 >= minx2 and minx1 <= maxx2) or (minx2 >= minx1 and minx2 <= maxx1)) and
		((miny1 >= miny2 and miny1 <= maxy2) or (miny2 >= miny1 and miny2 <= maxy1)) and
		((minz1 >= minz2 and minz1 <= maxz2) or (minz2 >= minz1 and minz2 <= maxz1))
end

-- 在场景中处理已被爆炸的blocks
local function afterBlast(block, time)
	if not block.rtdata.timer then
		block.rtdata.timer = _Timer.new()
	end

	block.rtdata.timer:start('blast1', time, function()
		block:changeTransparency(0, 0.5)
		block.rtdata.timer:stop('blast1')
	end)
	block.rtdata.timer:start('blast2', time + 500, function()
		block:setVisible(false)
		block.rtdata.timer:stop('blast2')
	end)
end

local function applyBlastForce(block, blastpos, blastrange, blasttime, showDetail)
	local translation = Container:get(_Vector3)
	block.node.transform:getTranslation(translation)
	local dir = translation:sub(blastpos)
	local m = dir:magnitude()
	if m < blastrange then
		-- 力的方向+衰减
		local coeff = (1.0 - m / blastrange) * 2000 * block.actor.mass
		if showDetail then
			coeff = coeff / 100
		end
		local force = Container:get(_Vector3)
		force:set(dir.x / m * coeff, dir.y / m * coeff, dir.z / m * coeff)

		block.actor.kinematic = false
		if showDetail then
			block.actor.isGravity = false
		end
		block:setPickFlag(Global.CONSTPICKFLAG.SELECTBLOCK)
		block.actor:addForce(force, translation)
		if not showDetail then
			afterBlast(block, blasttime)
		end
		Container:returnBack(force)
	end
	Container:returnBack(translation)
end

Block.blast = function(blocks, blastrange, blasttime, showDetail, shake, sound, rate)
	local aabbs = Block.getAABBs(blocks)
	local center = _Vector3.new()
	aabbs:getCenter(center)

	-- 摄像机摇晃,先快后慢
	if shake or shake == nil then
		_rd.camera:shake(0.1, 0.2, 500, _Camera.Quadratic)
	end
	if sound or sound == nil then
		Global.Sound:play('explode')
	end

	rate = rate or 0.5
	for i, v in ipairs(blocks) do
		if math.random() > rate and not showDetail then
			v:setVisible(false)
		else
			applyBlastForce(v, center, blastrange, blasttime, showDetail)
		end
	end
end

local function applyBlastVForce(block, blastpos, blastrange, blasttime)
	local translation = Container:get(_Vector3)
	block.node.transform:getTranslation(translation)
	local dir = translation:sub(blastpos)
	local m = dir:magnitude()
	if m < blastrange then
		-- 力的方向+衰减
		local coeff = (1.0 - m / blastrange) * 2000 * block.actor.mass
		if showDetail then
			coeff = coeff / 100
		end
		local force = Container:get(_Vector3)
		force:set(0, 0, dir.z / m * coeff)

		block.actor.kinematic = false
		block:setPickFlag(Global.CONSTPICKFLAG.SELECTBLOCK)
		block.actor:addForce(force, translation)
		Container:returnBack(force)
	end
	Container:returnBack(translation)
end

local function applyBlastCForce(block, blastrange, blasttime)
	local translation = Container:get(_Vector3)
	translation:set(_rd.camera.eye)

	--TODO: 随机一个范围
	translation.x = translation.x + math.random(0, 10) / math.random(-3, 3) / 10.0
	translation.y = translation.y + math.random(0, 10) / math.random(-3, 3) / 10.0
	translation.z = translation.z + math.random(0, 10) / math.random(-3, 3) / 10.0

	local dir = translation:sub(_rd.camera.look)
	local m = dir:magnitude()
	if m < blastrange then
		-- 力的方向+衰减
		local coeff = (1.0 - m / blastrange) * 5000 * block.actor.mass
		local force = Container:get(_Vector3)
		force:set(dir.x / m * coeff, dir.y / m * coeff, dir.z / m * coeff)

		block.actor.kinematic = false
		block:setPickFlag(Global.CONSTPICKFLAG.SELECTBLOCK)
		block.actor:addForce(force, translation)
		Container:returnBack(force)

		Global.RenderEffect:glassBroken(_rd.postProcess, 200, 100)
	end
	Container:returnBack(translation)
end

Block.pushupblast = function(blocks, blastrange, blasttime, hideafterblast, rate)
	local aabbs = Block.getAABBs(blocks)
	local center = _Vector3.new()
	aabbs:getCenter(center)
	center.z = aabbs.min.z - 0.2

	rate = rate or 0.5
	for i, v in ipairs(blocks) do
		if math.random() > rate and not showDetail then
			Global.sen:delBlock(v)
		else
			applyBlastVForce(v, center, blastrange, blasttime, false, hideafterblast)
		end
	end
end

local function applyBlastVForce2(block, blastpos, blastrange)
	local translation = Container:get(_Vector3)
	block.node.transform:getTranslation(translation)

	local dir = translation:sub(blastpos)
	local m = dir:magnitude()
	if m < blastrange then
		-- 力的方向+衰减
		local coeff = (1.0 - m / blastrange) * 2000 * block.actor.mass * 3
		local force = Container:get(_Vector3)
		force:set(0, 0, dir.z / m * coeff)

		block.actor.isGravity = true
		block.actor.kinematic = false
		--block:setPickFlag(Global.CONSTPICKFLAG.SELECTBLOCK)
		block.actor:addLinearVelocity(_Vector3.new(0, 0, -force.z), true)
		block.actor:addForce(force, translation)
		Container:returnBack(force)
	end

	Container:returnBack(translation)
end

Block.blast_project = function(blocks, blastrange, rate)
	local aabbs = Block.getAABBs(blocks)
	local center = _Vector3.new()
	aabbs:getCenter(center)
	center.z = aabbs.min.z - 0.2

	rate = rate or 0.5
	local n = 1
	for i, v in ipairs(blocks) do
		if math.random() > rate then
			v:enablePhysic(false)
			v.node.visible = false
			v.actor.isVisible = false
		else
			n = n + 1
			applyBlastVForce2(v, center, blastrange)
		end
	end

	-- print('blast_project', n / #blocks, rate, n, #blocks)
end

local restoreButton = function(block, direction, duration)
	local function disableblock()
		block.rtdata.available = true
		block.rtdata.timer:stop('button')
	end

	if not block.rtdata.timer then
		block.rtdata.timer = _Timer.new()
	end

	block.rtdata.timer:start('button', duration, disableblock)
end

Block.applyButtonEffect = function(blocks, direction, duration)
	for i, v in ipairs(blocks) do
		v.rtdata.available = false
	end
	-- 下降
	for i, v in ipairs(blocks) do
		v:moveTranslation(direction.x, direction.y, direction.z, duration, 'lcc')
		-- 计时还原
		restoreButton(v, direction, duration)
	end
end

-- item的名字就是lv中block shape的名字
Block.addItem = function(item)
	if not item then return end

	local hasexist = false
	for i, v in ipairs(Global.GetObjects('edit', 'object')) do
		if v.name == item then
			hasexist = true
		end
	end

	if not hasexist then
		table.insert(Global.Objects, {name = item, type = 'object', stype = 'other', mode = 'mine'})
	end
end

Block.addHelperData = function(shapeid, subshape, data)
	if Block.isItemID(shapeid) then
		if not Block.HELPERDATA[shapeid] then Block.HELPERDATA[shapeid] = {} end
		Block.HELPERDATA[shapeid][subshape] = data
	else
		Block.HELPERDATA[shapeid] = data
	end
end

Block.getHelperData = function(shapeid, subshape, loadIfnil)
	if Block.isItemID(shapeid) then
		subshape = subshape or 0
		local data = Block.HELPERDATA[shapeid] and Block.HELPERDATA[shapeid][subshape]
		if not data and loadIfnil then
			Block.getBlockMesh(shapeid, subshape)
			return Block.getHelperData(shapeid, subshape)
		end

		return data
	else
		return Block.HELPERDATA[shapeid]
	end
end

Block.isBuildMode = function()
	return Global.GameState:isState('BUILDBRICK')
		or Global.GameState:isState('BUILD')
		or Global.GameState:isState('BUILDSHAPE')
		or Global.GameState:isState('BUILDKNOT')
		or Global.GameState:isState('BUILDHOUSE')
		or Global.GameState:isState('BLOCKBRAWL')
		or Global.GameState:isState('BUILDFUNC')
end

Block.ItemCache = {}
Block.meshs = {}
Block.ShapeActors = {}
Block.ShapeBoxes = {}

Block.addDataCache = function(shapeid, data)
	Block.ItemCache[shapeid] = data
end

Block.clearDataCache = function(shapeid)
	Block.ItemCache[shapeid] = nil
end

Block.getDataCache = function(shapeid)
	return Block.ItemCache[shapeid]
end

Block.clearCaches = function(shapeid)
	--Block.ItemCache[shapeid] = nil
	Block.meshs[shapeid] = nil
	Block.ShapeActors[shapeid] = nil
	Block.ShapeBoxes[shapeid] = nil
	Block.HELPERDATA[shapeid] = nil
end

Block.Id2Filename = function(shapeid)
	local ext = _sys:getExtention(shapeid)

	local filename = shapeid
	if ext ~= 'lv' and ext ~= 'itemlv' and not shapeid:find'ipfs:' then
		filename = shapeid .. '.itemlv'
	end

	if not _sys:fileExist(filename) then
		local obj = Global.getObjectByName(shapeid)
		if obj then
			filename = obj.datafile.name
		else
			local house = Global.getHouseByName(shapeid)
			if house then
				filename = house.datafile.name
			else
				print('ERROR: Id2Filename failed, file is not exist', shapeid, filename)
				return
			end
		end
	end

	return filename
end

Block.loadItemData = function(shapeid)
	if Block.ItemCache[shapeid] then
		return Block.ItemCache[shapeid]
	end

	local filename = Block.Id2Filename(shapeid)
	if not filename then return end

	local data = _dofile(filename)
	if not data then print('ERROR: loadItemData failed, file data is not correct', shapeid, filename) end

	return data
end

Block.getBlockNeedObjects = function(shapeid)
	local objs = {}
	if not Block.isItemID(shapeid) then return objs end

	local data = Block.loadItemData(shapeid)
	if not data then return objs end

	local ress = {}
	if data.subs then
		for id, bs in pairs(data.subs) do
			for i, b in ipairs(bs) do
				if Block.isItemID(b.shape) and not ress[b.shape] and Global.isNetObject(b.shape) then
					ress[b.shape] = true
				end
			end
		end
	end

	local bs = data.blocks or data
	for i, b in ipairs(bs) do
		if Block.isItemID(b.shape) and not ress[b.shape] and Global.isNetObject(b.shape) then
			ress[b.shape] = true
		end
	end

	return ress
end

Block.isItemID = function(id)
	return type(id) == 'string'
end

Block.convertColor = function(color)
	-- 兼容颜色索引和颜色两种模式
	if color <= #Global.BrickColors then
		return Global.BrickColors[color]
	end

	return color
end

local glassblender = _Blender.new()
glassblender:blend(0x66ffffff)

Block.getMaterial = function(mtlid, colorid, roughness, mtlmode, useinstance)
	local mtlname = Global.MtlRess[mtlid]
	local color = Block.convertColor(colorid)

	local material
	if _G.RECORDMATERIAL then
		local name = string.format("%s,%s,%s,%s.mtl", mtlid, colorid, roughness, mtlmode)
		if _sys:fileExist(name) then
			material = _Material.new(name)
		end
	end

	if not material then
		if Global.Mtls[mtlname] then
			material = Global.Mtls[mtlname]:clone()
		else
			material = _Material.new(mtlname)
		end

		material:setRoughness(roughness)
		material.isLocalUV = false

		local isEmissive = mtlmode == Global.MTLMODE.EMISSIVE
		if useinstance and isEmissive == false then color = _Color.White end
		if mtlmode == Global.MTLMODE.PAINT then
			material.diffuse = color
			material.ambient = color
		elseif mtlmode == Global.MTLMODE.AMBIENT then
			material.ambient = color
			-- material.diffuse = _Color.White
		elseif mtlmode == Global.MTLMODE.EMISSIVE then
			material.emissive = color
			material.emissivePower = 20.0
			material.power = 1.0
		elseif mtlmode == Global.MTLMODE.NOWORLDUV then
			material.diffuse = color
			material.ambient = color
			material.isLocalUV = true
		end

		if _G.RECORDMATERIAL and _sys.os == "win32" then
			local name = string.format("%s,%s,%s,%s.mtl", mtlid, colorid, roughness, mtlmode)

			print("save mtl", name)
			material:save('./mtlRecord/' .. name)
			material = _Material.new(name)
		end
	end

	if mtlname == 'glass.mtl' or mtlname == 'airglass.mtl' then
		material.forceShadowCaster = true
	end
	material.mtlid = mtlid
	material.colorid = colorid
	material.roughness = roughness
	material.mtlmode = mtlmode
	return material
end

Block.setupMaterial = function(mesh, mtlid, colorid, roughness, mtlmode, normalmapid, paintinfo)
end

Block.addPaintMesh = function(m, paintInfo, autofill)
	if not paintInfo or not paintInfo.resname or paintInfo.resname == '' then return end

	if paintInfo and paintInfo.typestr ~= 'paintInfo' then
		paintInfo = PaintInfo.new(paintInfo)
	end

	local getfaceinstance = function()
		return {
			[1] = {pos = _Vector3.new(), normal = _Vector3.new(), uv = _Vector2.new()},
			[2] = {pos = _Vector3.new(), normal = _Vector3.new(), uv = _Vector2.new()},
			[3] = {pos = _Vector3.new(), normal = _Vector3.new(), uv = _Vector2.new()},
			[4] = {pos = _Vector3.new(), normal = _Vector3.new(), uv = _Vector2.new()}
		}
	end

	local rotateface = function(face, mat, translate)
		if not face or not mat then return end
		local target = getfaceinstance()
		for i, vertex in ipairs(face) do
			mat:apply(vertex.pos, target[i].pos)
			if translate then
				_Vector3.add(translate, target[i].pos, target[i].pos)
			end
			mat:apply(vertex.normal, target[i].normal)
			target[i].uv = vertex.uv
		end

		return target
	end

	local facelist = {}
	local aabb = m:getBoundBox(nil, true)
	local centerx = (aabb.x2 + aabb.x1) * 0.5
	local centery = (aabb.y2 + aabb.y1) * 0.5
	local centerz = (aabb.z2 + aabb.z1) * 0.5
	local sizex = aabb.x2 - aabb.x1
	local sizey = aabb.y2 - aabb.y1
	local sizez = aabb.z2 - aabb.z1

	local index = not paintInfo.face and 1 or paintInfo.face
	local image = _Image.new(paintInfo.resname, false, true)
	local maxsize = 0
	if index == Global.AXISTYPE.X or index == Global.AXISTYPE.NX then
		maxsize = math.min(sizey, sizez)
	elseif index == Global.AXISTYPE.Y or index == Global.AXISTYPE.NY then
		maxsize = math.min(sizex, sizez)
	elseif index == Global.AXISTYPE.Z or index == Global.AXISTYPE.NZ then
		maxsize = math.min(sizex, sizey)
	end

	local maxl = math.max(image.w, image.h) / maxsize * 2
	local w = image.w / maxl
	local h = image.h / maxl
	local defaultface = {
		[1] = {
			pos = _Vector3.new(-w, -h, 0),
			normal = _Vector3.new(0, 0, 1),
			uv = _Vector2.new(0, 0),
		},
		[2] = {
			pos = _Vector3.new(w, -h, 0),
			normal = _Vector3.new(0, 0, 1),
			uv = _Vector2.new(0, 1),
		},
		[3] = {
			pos = _Vector3.new(-w, h, 0),
			normal = _Vector3.new(0, 0, 1),
			uv = _Vector2.new(1, 0),
		},
		[4] = {
			pos = _Vector3.new(w, h, 0),
			normal = _Vector3.new(0, 0, 1),
			uv = _Vector2.new(1, 1),
		}
	}

	local facetrans = {
		[1] = _Vector2.new(centery, centerz),
		[2] = _Vector2.new(centerx, centerz),
		[3] = _Vector2.new(centerx, centery),
		[4] = _Vector2.new(centery, centerz),
		[5] = _Vector2.new(centerx, centerz),
		[6] = _Vector2.new(centerx, centery)
	}
	local mat = Container:get(_Matrix3D)
	table.insert(facelist, rotateface(defaultface, mat:setRotationY(math.pi / 2), _Vector3.new(0, centery, centerz)))
	table.insert(facelist, rotateface(defaultface, mat:setRotationX(-math.pi / 2), _Vector3.new(centerx, 0, centerz)))
	table.insert(facelist, rotateface(defaultface, mat:identity(), _Vector3.new(centerx, centery, 0)))
	table.insert(facelist, rotateface(defaultface, mat:setRotationY(-math.pi / 2), _Vector3.new(0, centery, centerz)))
	table.insert(facelist, rotateface(defaultface, mat:setRotationX(math.pi / 2), _Vector3.new(centerx, 0, centerz)))
	table.insert(facelist, rotateface(defaultface, mat:setRotationX(math.pi), _Vector3.new(centerx, centery, 0)))
	Container:returnBack(mat)

	local pickface = facelist[index]
	local lastpickface = {}
	local indexlist = {0, 1, 2, 2, 1, 3}
	if not autofill then
		local lockaxis
		local mat = Container:get(_Matrix2D)
		mat:identity()
		local scale = paintInfo.scale
		local trans = paintInfo.translation
		local rotate = paintInfo.rotate
		local locknormal = pickface[1].normal
		local vec41 = Container:get(_Vector4)
		local lt = Container:get(_Vector2)
		local rt = Container:get(_Vector2)
		local rb = Container:get(_Vector2)
		local lb = Container:get(_Vector2)
		local l, t, r, b
		if index == Global.AXISTYPE.Z or index == Global.AXISTYPE.NZ then
			l = aabb.x1 t = aabb.y1
			r = aabb.x2 b = aabb.y2

			lockaxis = index == 6 and aabb.z1 or aabb.z2
			lt:set(pickface[1].pos.x, pickface[1].pos.y)
			rt:set(pickface[4].pos.x, pickface[1].pos.y)
			rb:set(pickface[4].pos.x, pickface[4].pos.y)
			lb:set(pickface[1].pos.x, pickface[4].pos.y)

			if rotate and rotate.w ~= 0 then
				local trans1 = Container:get(_Vector2)
				trans1:set(facetrans[index])
				trans1 = trans1:mul(-1)
				mat:mulTranslationRight(trans1)
				mat:mulRotationRight(rotate.w)
				mat:mulTranslationRight(facetrans[index])
				Container:returnBack(trans1)
			end
			mat:mulTranslationRight(-centerx, -centery)
			mat:mulScalingRight(scale.x, scale.y)
			mat:mulTranslationRight(centerx, centery)
			mat:mulTranslationRight(trans.x, trans.y)
		elseif index == Global.AXISTYPE.X or index == Global.AXISTYPE.NX then
			l = aabb.y1 t = aabb.z1
			r = aabb.y2 b = aabb.z2

			lockaxis = index == 4 and aabb.x1 or aabb.x2
			rt:set(pickface[1].pos.y, pickface[1].pos.z)
			lt:set(pickface[4].pos.y, pickface[1].pos.z)
			lb:set(pickface[4].pos.y, pickface[4].pos.z)
			rb:set(pickface[1].pos.y, pickface[4].pos.z)

			if rotate and rotate.w ~= 0 then
				local trans1 = Container:get(_Vector2)
				trans1:set(facetrans[index])
				trans1 = trans1:mul(-1)
				mat:mulTranslationRight(trans1)
				mat:mulRotationRight(rotate.w)
				mat:mulTranslationRight(facetrans[index])
				Container:returnBack(trans1)
			end
			mat:mulTranslationRight(-centery, -centerz)
			mat:mulScalingRight(scale.y, scale.z)
			mat:mulTranslationRight(centery, centerz)
			mat:mulTranslationRight(trans.y, trans.z)
		elseif index == Global.AXISTYPE.Y or index == Global.AXISTYPE.NY then
			l = aabb.x1 t = aabb.z1
			r = aabb.x2 b = aabb.z2

			lockaxis = index == 5 and aabb.y1 or aabb.y2
			lt:set(pickface[1].pos.x, pickface[1].pos.z)
			rt:set(pickface[4].pos.x, pickface[1].pos.z)
			rb:set(pickface[4].pos.x, pickface[4].pos.z)
			lb:set(pickface[1].pos.x, pickface[4].pos.z)

			if rotate and rotate.w ~= 0 then
				local trans1 = Container:get(_Vector2)
				trans1:set(facetrans[index])
				trans1 = trans1:mul(-1)
				mat:mulTranslationRight(trans1)
				mat:mulRotationRight(rotate.w)
				mat:mulTranslationRight(facetrans[index])
				Container:returnBack(trans1)
			end
			mat:mulTranslationRight(-centerx, -centerz)
			mat:mulScalingRight(scale.x, scale.z)
			mat:mulTranslationRight(centerx, centerz)
			mat:mulTranslationRight(trans.x, trans.z)
		end

		vec41:set(l, t, r, b)
		local outs = {}
		outs = _rd:clipPolygon(mat, vec41, lt, rt, rb, lb)
		if not outs then return end
		for k, out in pairs(outs) do
			local vertex = {pos = _Vector3.new(), normal = _Vector3.new(), uv = _Vector2.new()}
			if index == Global.AXISTYPE.Z or index == Global.AXISTYPE.NZ then
				vertex.pos:set(out.x, out.y, lockaxis)
			elseif index == Global.AXISTYPE.X or index == Global.AXISTYPE.NX then
				vertex.pos:set(lockaxis, out.x, out.y)
			elseif index == Global.AXISTYPE.Y or index == Global.AXISTYPE.NY then
				vertex.pos:set(out.x, lockaxis, out.y)
			end

			local matinv = Container:get(_Matrix2D)
			local out1 = Container:get(_Vector2)
			out1:set(out.x, out.y)
			matinv:set(mat)
			matinv:inverse()
			matinv:apply(out1, out1)
			local u = (out1.x - lt.x) / (rt.x - lt.x)
			local v = (out1.y - lt.y) / (rb.y - lt.y)
			vertex.uv:set(u, v)
			vertex.normal:set(locknormal.x, locknormal.y, locknormal.z)
			table.insert(lastpickface, vertex)
			Container:returnBack(matinv, out1)
		end

		indexlist = {}
		local pn = #lastpickface
		for i = 2, pn - 1 do
			table.insert(indexlist, 0)
			table.insert(indexlist, i - 1)
			table.insert(indexlist, i)
		end

		Container:returnBack(mat, vec41, lt, rt, rb, lb)
	else
		lastpickface = pickface
	end

	local paintmesh = _mf:createDecal(lastpickface, indexlist, true)
	paintmesh.name = 'paint' .. paintInfo:md5()
	paintmesh.isAlphaFilter = true
	local material = _Material.new('blockpaint.mtl')
	material.diffuseMap = image
	-- material.isAlpha = true
	material.isDecal = true
	material.isClampTexture = true
	paintmesh.material = material

	if autofill then
		sizex = math.min(sizex, 0.4)
		sizey = math.min(sizey, 0.4)
		sizez = math.min(sizez, 0.4)
		local scalefactor = 0.95

		-- fill scale translation
		local facetranslist = {
			-- 左
			[1] = {
				scale = {
					x = 1.0,
					y = sizey * scalefactor,
					z = sizez * scalefactor
				},
				trans = {
					x = aabb.x2,
					y = centery,
					z = centerz
				}
			},
			-- 前
			[2] = {
				scale = {
					x = sizex * scalefactor,
					y = 1.0,
					z = sizez * scalefactor
				},
				trans = {
					x = centerx,
					y = aabb.y1,
					z = centerz
				}
			},
			-- 上
			[3] = {
				scale = {
					x = sizex * scalefactor,
					y = sizey * scalefactor,
					z = 1.0
				},
				trans = {
					x = centerx,
					y = centery,
					z = aabb.z2
				}
			},
			-- 右
			[4] = {
				scale = {
					x = 1.0,
					y = sizey * scalefactor,
					z = sizez * scalefactor
				},
				trans = {
					x = aabb.x1,
					y = centery,
					z = centerz
				}
			},
			-- 后
			[5] = {
				scale = {
					x = sizex * scalefactor,
					y = 1.0,
					z = sizez * scalefactor
				},
				trans = {
					x = centerx,
					y = aabb.y2,
					z = centerz
				}
			},
			-- 下
			[6] = {
				scale = {
					x = sizex * scalefactor,
					y = sizey * scalefactor,
					z = 1.0
				},
				trans = {
					x = centerx,
					y = centery,
					z = aabb.z1
				}
			},

		}

		local facetransform = facetranslist[index]
		local facescale = facetransform.scale
		local facetrans = facetransform.trans
		paintmesh.transform:mulScalingLeft(facescale.x, facescale.y, facescale.z)
		paintmesh.transform:mulTranslationRight(facetrans.x, facetrans.y, facetrans.z)

		paintInfo.scale:set(facescale.x, facescale.y, facescale.z)
		paintInfo.translation:set(facetrans.x, facetrans.y, facetrans.z)
	end

	-- 处理z-fighting
	local fightz = 0.002
	local fightzfaces = {
		[1] = _Vector3.new(fightz, 0, 0),
		[2] = _Vector3.new(0, fightz, 0),
		[3] = _Vector3.new(0, 0, fightz),
		[4] = _Vector3.new(-fightz, 0, 0),
		[5] = _Vector3.new(0, -fightz, 0),
		[6] = _Vector3.new(0, 0, -fightz)
	}

	local fightzvec = fightzfaces[index]
	paintmesh.transform:mulTranslationRight(fightzvec)

	if m.lodMesh then m.lodMesh:addSubMesh(paintmesh) end
	m:addSubMesh(paintmesh)

	--paintmesh.ignoreBoundBox = true

	-- if paintInfo.visible ~= nil then
	-- 	paintmesh.visible = paintInfo.visible
	-- end
	return paintmesh
end

Block.getSubPaintMeshs = function(sub, pms)
	if not pms then pms = {} end
	local submshs = {}
	sub:getSubMeshs(submshs)
	local n0 = #pms
	for _, v in pairs(submshs) do if v.name:find('paint') then
		table.insert(pms, v)
	end end

	return pms, #pms - n0
end

Block.getSubPaintMesh = function(sub)
	local pms = Block.getSubPaintMeshs(sub)
	for i, v in ipairs(pms) do if v.visible then
		return v
	end end
end

Block.getSubPaintMeshByPaintInfo = function(m, paintinfo, createifnull)
	local pms = Block.getSubPaintMeshs(m)
	local md5 = paintinfo:md5()
	if md5 == 0 then return end

	for i, v in ipairs(pms) do
		if v.name:find(md5) then
			return v
		end
	end

	if createifnull then
		return Block.addPaintMesh(m, paintinfo)
	end
end

Block.getPaintMeshs = function(m)
	local pms = {}
	local submshs = {}
	m:getSubMeshs(submshs)
	table.insert(submshs, m)
	for _, v in pairs(submshs) do
		Block.getSubPaintMeshs(v, pms)
	end

	return pms
end

-- TODO: find batter way
Block.getParentMesh = function(mesh, paintmesh)
	local submshs = {}
	mesh:getSubMeshs(submshs)
	table.insert(submshs, mesh)
	for _, v in pairs(submshs) do
		local mesh = Block.getSubPaintMesh(v)
		if mesh == paintmesh then
			return v
		end
	end
end

Block.changePaintImage = function(m, paintimage)
	local sms = {}
	m:getSubMeshs(sms)
	table.insert(sms, m)
	for i, v in ipairs(sms) do
		local paintmesh = Block.getSubPaintMesh(v)
		if paintmesh then
			paintmesh.material.diffuseMap = paintimage
		end
	end
end

Block.getBasicBlockMesh = function(shapeid, mtlid, colorid, roughness, mtlmode, paintInfo, useinstance)
	local bd = Block.getBlockData(shapeid)
	local mtlname = Global.MtlRess[mtlid]

	local res = res_func(bd.res)

	local m = _Mesh.new(res)
	m.isAlphaFilter = true
	--local name = _sys:getFileName(bd.res, false, false)
	--local ext = _sys:getExtention(bd.res)
	-- local lodname = name .. '_0.' .. ext
	-- if _sys:fileExist(lodname) then
	-- 	m.lodMesh = _Mesh.new(lodname)
	-- 	local bb = m:getBoundBox()
	-- 	local lodbb = m.lodMesh:getBoundBox()
	-- 	m.lodMesh.transform:mulTranslationLeft(bb.x1 - lodbb.x1, bb.y1 - lodbb.y1, bb.z1 - lodbb.z1)
	-- 	m.isDetail = true
	-- end

	-- TODO setupMaterial
	local index = Global.LightNormalReflect[shapeid]
	if index then
		local img = Global.lightNormalMaps[index]
		if img then
			m:setNormalLightMap(img)
		end
	end

	m.material = Block.getMaterial(mtlid, colorid, roughness, mtlmode, useinstance)

	if mtlname and mtlname:find'glass' then
		m.blender = glassblender
	end

	m.name = shapeid

	Block.addPaintMesh(m, paintInfo)

	return m
end

local function getGroupBlocks(g, bs, gs)
	if not g then return end
	if g.blocks then
		for i, b in ipairs(g.blocks) do
			table.insert(bs, b)
		end
	end

	if gs and g.children then
		for i, cindex in ipairs(g.children) do
			if gs[cindex] then
				getGroupBlocks(gs[cindex], bs, gs)
			else
				print('gs[cindex]', cindex, #gs)
			end
		end
	end
end

local loadGroupsData = function(data, groups)
	if not data or not data.groups then return end

	if data.logicgroups then
		for i, g in ipairs(data.logicgroups) do
			table.insert(groups, g)
		end
	else
		-- 为角色动画创建逻辑组
		for n, p in pairs(data.parts or {}) do if type(p) == 'table' then
			local g = {}
			g.blocks = {}
			getGroupBlocks(data.groups[p.group], g.blocks, data.groups)
			if p.attachs then
				for i, gi in ipairs(p.attachs) do
					getGroupBlocks(data.groups[gi], g.blocks, data.groups)
				end
			end
			table.insert(groups, g)

			p.logicGroup = #groups
		end end

		-- 为积木动画创建逻辑组
		local dfs = data.dynamicEffects
		if dfs then
			local gs = {}
			for _, df in ipairs(dfs) do
				for _, t in ipairs(df.transitions) do
					if not gs[t.group] then
						local g = {}
						g.blocks = {}
						getGroupBlocks(data.groups[t.group], g.blocks, data.groups)
						gs[t.group] = g
						table.insert(groups, g)
						g.tempindex = #groups
					end

					local g = gs[t.group]
					t.group = g.tempindex
				end
			end

			for gi, g in pairs(gs) do
				g.tempindex = nil
			end
		end

		-- 为积木创建逻辑组
		if data.logic_names and next(data.logic_names) then
			local gs = {}
			for bindex, names in pairs(data.logic_names) do
				for name, s in pairs(names) do if s then
					if not gs[name] then
						local g = {}
						g.name = name
						g.blocks = {}
						gs[name] = g
						table.insert(groups, g)
					end

					local g = gs[name]
					table.insert(g.blocks, bindex)
				end end
			end
		end

		-- 加载积木芯片
		if data.block_chipss and next(data.block_chipss) then
			local gs = {}
			for bindex, chips_s in pairs(data.block_chipss) do
				local str = value2string(chips_s)
				local md5 = _sys:md5(str)
				if not gs[md5] then
					local g = {}
					g.blocks = {}
					g.chips_s = chips_s
					gs[md5] = g
					table.insert(groups, g)
					chips_s.group = #groups
				end

				local g = gs[md5]
				table.insert(g.blocks, bindex)
			end

			if not data.chips_s then data.chips_s = {} end
			data.chips_s.groups = {}
			for md5, g in pairs(gs) do
				table.insert(data.chips_s.groups, g.chips_s)
				g.chips_s = nil
			end
		end
	end
end

local loadPartsData = function(data, groups, parts)
	if not data or not data.parts then return end

	local scale = data.scale or 1
	if data.parts then
		parts.bindbone = data.parts.bindbone or 'human'
		parts.rootz = data.parts.rootz or 0
	end

	local g2ps = {}
	local function getPart(g)
		if not g then return end

		if not g2ps[g] then
			g2ps[g] = {}
		end

		return g2ps[g]
	end

	for n, p in pairs(data.parts or {}) do if type(p) == 'table' then
		local part = getPart(p.group)
		part.name = n

		if p.pgroup then part.ppart = getPart(p.pgroup) end

		local pos = p.jointpos
		pos.x, pos.y, pos.z = pos.x * scale, pos.y * scale, pos.z * scale
		part.jointpos = pos

		part.logicGroup = groups[p.logicGroup]
	end end

	parts.data = {}
	for g, part in pairs(g2ps) do
		parts.data[part.name] = part
		print('g2ps', part.name, part.ppart and part.ppart.name, #(part.logicGroup.blocks))
	end
end

local loadDynamicEffectData = function(data, groups)
	if not data or not data.dynamicEffects then return end

	local dfs = data.dynamicEffects
	for _, df in ipairs(dfs) do
		for _, t in ipairs(df.transitions) do
			if type(t.group) == 'number' then
				t.group = groups[t.group]
			end
		end
	end

	return dfs
end

local loadBfuncData = function(data, groups)
	-- TODO: add group info
	return data and data.bfuncs
end

local loadBChipData = function(data, groups)
	-- TODO: add group info
	if data and data.chips_s and data.chips_s.groups then
		for i, chips in ipairs(data.chips_s.groups) do
			chips.group = groups[chips.group]
		end
	end

	return data and data.chips_s
end

local mat3d = _Matrix3D.new()
local addActorData = function(actors, shapes, mat, bindex)
	if not shapes then return end
	for _, s in ipairs(shapes) do
		mat3d:setTranslation(s.offset)

		if mat then mat3d:mulRight(mat) end

		local aabb = _AxisAlignedBox.new()
		aabb.min.x, aabb.min.y, aabb.min.z = -s.size.x, -s.size.y, -s.size.z
		aabb.max:set(s.size)

		local rot = nil
		if mat and mat:hasRotation2() then
			rot = _Vector4.new()
			mat3d:getRotation(rot)

			local trans = Container:get(_Vector3)
			mat3d:getTranslation(trans)
			mat3d:setTranslation(trans)
			Container:returnBack(trans)
		end
		aabb:mul(mat3d)

		table.insert(actors, {box = aabb, rot = rot, jdata = s.jdata, bindex = bindex})
	end
end

local shrinkActorData = function(actors)
	local d = Global.editor.shapedelta
	for i, v in ipairs(actors) do
		local min = v.box.min
		local max = v.box.max
		min.x, min.y, min.z = min.x + d, min.y + d, min.z + d
		max.x, max.y, max.z = max.x - d, max.y - d, max.z - d
	end

	return actors
end

local function getBlocksData(data, subshape)
	local blocks
	if subshape ~= 0 then
		blocks = data.subs and data.subs[subshape] and data.subs[subshape].blocks
	else
		blocks = data.blocks or data
	end

	return blocks or {}
end

local loadMeshFromData = function(mesh, actors, data, subshape, mtlmode, actormat)
	mesh.isAlphaFilter = true

	if not data then
		mesh.isDummy = true
		return false
	end

	local dynamic = mtlmode == Global.MTLMODE.NOWORLDUV

	local blocks = getBlocksData(data, subshape)
	local mat = Container:get(_Matrix3D)

	local scale = data.scale or 1
	for i, bd in ipairs(blocks) do
		if bd.need ~= false then
			-- 物件中的子物件，拼物件时生成
			local m
			local disablephyx = bd.disablephyx
			if bd.shape == '' then
				m = _Mesh.new()
				m.ignoreBoundBox = true
				disablephyx = true
			elseif Block.isItemID(bd.shape) then
				local basic = Block.getBlockMesh(bd.shape, bd.subshape, nil, nil, nil, mtlmode, bd.paintInfo)
				m = clone_mesh(basic)
			else
				local mtlmode1 = dynamic and Global.MTLMODE.NOWORLDUV or bd.mtlmode or Global.MTLMODE.PAINT
				if dynamic and bd.mtlmode == Global.MTLMODE.EMISSIVE then mtlmode1 = bd.mtlmode end
				local basic = Block.getBlockMesh(bd.shape, nil, bd.material, bd.color, bd.roughness or 1, mtlmode1, bd.paintInfo)
				m = clone_mesh(basic)
				m.materialColor = Block.convertColor(bd.color)
			end

			if bd.invisible then
				m.isInvisible = true
			end

			if m.isInvisible then
				if Global.isHideInvisibleActorMode() then
					disablephyx = true
				end
			end

			if not _G.GenMirrorMesh then
				mat:loadFromSpace(bd.space)
			else
				-- 生成镜像文件，特殊情况下使用
				local sc = bd.space.scale
				if sc.x >= 0 and sc.y >= 0 and sc.z >= 0 then
					mat:loadFromSpace(bd.space)
				else
					-- 生成镜像模型
					local mname = m.resname
					local fname = _sys:getFileName(mname, false, true)
					local mode, dstname = 0, nil
					if sc.x < 0 then
						dstname = fname .. '_mirrorx.msh'
						mode = 0
						sc.x = math.abs(sc.x)
					elseif sc.y < 0 then
						dstname = fname .. '_mirrory.msh'
						mode = 1
						sc.y = math.abs(sc.y)
					elseif sc.z < 0 then
						dstname = fname .. '_mirrorz.msh'
						mode = 2
						sc.z = math.abs(sc.z)
					end

					_mf:mirrorMesh(mname, dstname, mode)
					local nm = _Mesh.new(dstname)
					nm.materialColor = m.materialColor
					nm.isAlphaFilter = m.isAlphaFilter
					nm.isDetail = m.isDetail
					nm.lodMesh = m.lodMesh

					local normap = m:getNormalLightMap()
					if normap then
						nm:setNormalLightMap(normap)
					end
					nm.material = m.material
					nm.blender = m.name
					nm.name = m.name
					m = nm

					mat:loadFromSpace(bd.space)
				end
			end

			if scale ~= 1 then
				mat:mulScalingRight(scale, scale, scale)
			end

			m.transform:set(mat)
			mesh:addSubMesh(m)

			-- 添加actors
			if actors and not disablephyx then
				local shapes = {}
				if Block.isItemID(bd.shape) then
					local as = Block.getShapeActors(bd.shape, bd.subshape)
					if as and as.noshapes then
					else
						-- TODO: 当前使用物件包围盒代替精确的包围盒
						local hdata = Block.getHelperData(bd.shape, bd.subshape)
						shapes = hdata and hdata.shapes
					end
				else
					local hdata = Block.getHelperData(bd.shape, bd.subshape)
					shapes = hdata and hdata.shapes
				end

				local mat2
				if not actormat then
					mat2 = mat
				else
					mat2 = _Matrix3D.new()
					mat2:set(mat)
					mat2:mulRight(actormat)
				end
				addActorData(actors, shapes, mat2, i)
			end
		else
			-- 创建空mesh用于占位，否则子mesh的顺序不对
			local m = _Mesh.new()
			m.name = 'placeholder'
			m.ignoreBoundBox = true
			mesh:addSubMesh(m)
		end
	end

	Container:returnBack(mat)

	return true
end

-- local loadSubModuleData = function(data, submodule)
-- 	if not data or not data.submodules then return end
-- 	for i, v in ipairs(data.submodules) do
-- 		local mesh = _Mesh.new()
-- 		local actors = {}
-- 		loadMeshFromData(mesh, actors, v.module, 0, Global.MTLMODE.NOWORLDUV)
-- 		table.insert(submodule, {type = v.type, bindex = v.bindex, mesh = mesh, actors = shrinkActorData(actors)})
-- 	end
-- end

Block.getPaintFace = function(shapeid)
	local faces = {}
	local bd = Block.getBlockData(shapeid)
	if bd and bd.paintface then faces = bd.paintface end
	return faces
end

Block.loadHelperData = function(shapeid, subshape, data, mesh)
	local bs = {}
	local brickcount = 0
	if data then
		local blocks = getBlocksData(data, subshape)
		for i, bd in ipairs(blocks) do
			if bd.need ~= false then
				table.insert(bs, {id = bd.shape, index = i, space = bd.space, pfxs = bd.pfxs, markerdata = bd.markerdata})
				if Block.isItemID(bd.shape) then
					local hd = Block.getHelperData(bd.shape, bd.subshape)
					brickcount = brickcount + (hd and hd.brickcount or 0)
				else
					brickcount = brickcount + 1
				end
			else
				table.insert(bs, {id = bd.shape, index = i, space = bd.space, pfxs = nil})
			end
		end
	end
	-- 添加分组信息
	local groups = {}
	loadGroupsData(data, groups)

	-- 创建一个不交叉的积木分组, 可用于合并
	local bsgroup = {}
	for gindex, g in ipairs(groups) do
		g.index = gindex

		for _, bindex in ipairs(g.blocks) do
			if not bsgroup[bindex] then
				bsgroup[bindex] = {}
			end

			table.insert(bsgroup[bindex], gindex)
		end
	end

	local subgroups = {}
	for bindex, b in ipairs(bs) do
		local key = 'k'
		local gindexs = bsgroup[bindex]
		if gindexs then
			key = table.concat(gindexs, '|')
		end

		if not subgroups[key] then
			local sg = {}
			sg.gindexs = gindexs
			sg.blocks = {}
			subgroups[key] = sg

			if gindexs then
				for i, gi in ipairs(gindexs) do
					local g = groups[gi]
					if not g.sgroups then
						g.sgroups = {}
					end
					table.insert(g.sgroups, sg)
				end
			end
		end

		local sg = subgroups[key]
		table.insert(sg.blocks, bindex)
	end

	local sgroups = {}
	for key, sg in pairs(subgroups) do
		sg.index = #sgroups + 1
		table.insert(sgroups, sg)
	end

	-- print('sgroups', table.ftoString(bsgroup))

	-- 添加部位信息
	local parts = {}
	loadPartsData(data, groups, parts)

	-- 添加subModule信息
	-- local submodule = {}
	-- loadSubModuleData(data, submodule)

	-- 添加积木动画信息
	local dfs = loadDynamicEffectData(data, groups)
	local bfuncs = loadBfuncData(data, groups)
	local chips_s = loadBChipData(data, groups)

	-- TODO: 改成保存时计算
	local center, size = _Vector3.new(), _Vector3.new()
	local userAABB = data and data.funcflags and data.funcflags.userAABB
	if userAABB then
		userAABB:getCenter(center)
		userAABB:getSize(size)
	elseif mesh then
		local bb = mesh:getBoundBox()
		local sx = bb.x2 - bb.x1
		local sy = bb.y2 - bb.y1
		local sz = bb.z2 - bb.z1
		size:set(sx, sy, sz)

		local cx = (bb.x2 + bb.x1) * 0.5
		local cy = (bb.y2 + bb.y1) * 0.5
		local cz = (bb.z2 + bb.z1) * 0.5

		center:set(cx, cy, cz)
	end

	-- todo chipssss
	local hdata = {
		boxsize = size,
		boxcenter = center,
		shapes = {{size = _Vector3.new(size.x * 0.5, size.y * 0.5, size.z * 0.5), offset = _Vector3.new(center.x, center.y, center.z)}},
		brickcount = brickcount,
		boxes = {},
		funcflags = data and data.funcflags or {},
		subs = {bs = bs, groups = groups, sgroups = sgroups, parts = parts, dynamicEffects = dfs, bfuncs = bfuncs},
		chips_s = chips_s,
		-- submodule = submodule,
	}
	Block.addHelperData(shapeid, subshape, hdata)

	return hdata
end

Block.loadActorFromFile = function(shapeid, subshape, data)
	local mode = Global.isHideInvisibleActorMode() and 1 or 0
	if not Block.ShapeActors[shapeid] then
		Block.ShapeActors[shapeid] = {}
	end

	if not Block.ShapeActors[shapeid][subshape] then
		Block.ShapeActors[shapeid][subshape] = {}
	end

	local actors = data.actors
	if not actors or #actors == 0 then
		Block.ShapeActors[shapeid][subshape][mode] = {noshapes = true, {box = _AxisAlignedBox.new()}}
		return
	end

	Block.ShapeActors[shapeid][subshape][mode] = actors
end

Block.loadActorData = function(shapeid, subshape, data, actors, hdata)
	local mode = Global.isHideInvisibleActorMode() and 1 or 0
	if not Block.ShapeActors[shapeid] then
		Block.ShapeActors[shapeid] = {}
	end

	if not Block.ShapeActors[shapeid][subshape] then
		Block.ShapeActors[shapeid][subshape] = {}
	end

	if not data or not actors or #actors == 0 then
		Block.ShapeActors[shapeid][subshape][mode] = {noshapes = true, {box = _AxisAlignedBox.new()}}
		return
	end

	local disableMaxBox = data.disableMaxBox
	if actors then
		-- shape数量超过100时合并shape
		local bshapes = {}
		for i, v in ipairs(actors) do
			local bindex = v.bindex or -1
			if not bshapes[bindex] then
				bshapes[bindex] = {}
			end

			table.insert(bshapes[bindex], v)
		end

		local shapes = {}
		for i, sg in ipairs(hdata.subs.sgroups) do
			local sgshapes = {}
			for _, bindex in ipairs(sg.blocks) do
				if bshapes[bindex] then
					table.fappendArray(sgshapes, bshapes[bindex])
				end
			end

			local enableMinBox = data.enableMinBox
			if #sgshapes > 50 and not enableMinBox then
				local shapes1 = {}
				local shapes2 = {}
				for _, v in ipairs(sgshapes) do
					if not v.jdata and not v.rot then
						table.insert(shapes1, v)
					else
						table.insert(shapes2, v)
					end
				end
				-- local t1 = _tick()
				Optimizer.MergeBoxs(shapes1, 'box', 0.04)
				-- local t2 = _tick()
				--print('merge actors0:', shapeid, i, #shapes1, #shapes2, t2 - t1)
				table.fappendArray(shapes2, shapes1)
				sgshapes = shapes2

				if #sgshapes > 1000 and not disableMaxBox then
					print('merge actors:', shapeid, i, #sgshapes)
					enableMinBox = true
				end
			end

			if enableMinBox then
				local box = _AxisAlignedBox.new()
				box:initBox()
				for si, v in ipairs(sgshapes) do
					_AxisAlignedBox.union(v.box, box, box)
				end
				table.insert(shapes, {box = box, sgindex = i})
			else
				for si, v in ipairs(sgshapes) do
					v.sgindex = i
				end

				table.fappendArray(shapes, sgshapes)
			end
		end

		Block.ShapeActors[shapeid][subshape][mode] = shrinkActorData(shapes)
	end
end

local MTL_FLAG = {
	DYNAMIC = 0x1,
	BUILDMODE = 0x2,
	HIDEACTOR = 0x4,
}

Global.isShowInvisibleMtlMode = function()
	if Global.GameState:isState('BUILDBRICK') then
		local mode = Global.BuildBrick.mode
		return mode == 'buildbrick' or mode == 'buildanima'
			or (mode == 'buildscene' and Global.BuildBrick:getParam('scenemode') ~= 'scene_music')
	end
end

Global.isHideInvisibleActorMode = function()
	if Global.GameState:isState('BUILDBRICK') then
		return not Global.isShowInvisibleMtlMode()
	end
end

Block.getBlockMesh = function(shapeid, subshape, mtlid, colorid, roughness, mtlmode, paintInfo)
	if mtlid == Global.MtlInvisible then
		if Global.isShowInvisibleMtlMode() then
			mtlid = Global.MtlInvisibleShow
		end
	end

	if Block.isItemID(shapeid) then
		subshape = subshape or 0
		local mtlkey = 0
		if mtlmode == Global.MTLMODE.NOWORLDUV then mtlkey = mtlkey + MTL_FLAG.DYNAMIC end
		if Global.isShowInvisibleMtlMode() then mtlkey = mtlkey + MTL_FLAG.BUILDMODE end
		if Global.isHideInvisibleActorMode() then mtlkey = mtlkey + MTL_FLAG.HIDEACTOR end

		if not Block.meshs[shapeid] then Block.meshs[shapeid] = {} end
		if not Block.meshs[shapeid][mtlkey] then Block.meshs[shapeid][mtlkey] = {} end
		if not Block.meshs[shapeid][mtlkey][subshape] or _G.RECORDMATERIAL then
			local data = Block.loadItemData(shapeid)
			-- 添加actors
			local actors, actorfile
			if not Block.getShapeActors(shapeid, subshape) then
				if _G.enableActorFile then
					local af = shapeid .. '.actorf'
					if _sys:fileExist(af) then
						actorfile = _dofile(af)
					end
				end
				if not actorfile then
					actors = {}
				end
			end

			local mesh = _Mesh.new()
			if loadMeshFromData(mesh, actors, data, subshape, mtlmode) then
				-- 加载挂点
				if data and data.submodules then
					for i, v in ipairs(data.submodules) do
						if v.type == 'bind' then
							local sub = mesh:getSubMesh(v.bindex)
							if sub then
								sub.ignoreBoundBox = false
								local m = _Mesh.new()
								local as = {}
								loadMeshFromData(m, as, v.module, 0, mtlmode, sub.transform)
								if sub then sub:addSubMesh(m) end

								if actors then
									for _, a in ipairs(as) do
										a.bindex = v.bindex
										table.insert(actors, a)
									end
								end
							end
						end
					end
				end

				Block.addPaintMesh(mesh, paintInfo)
			else
				print('WARNING: shape is not exit, the object may be deleted', shapeid, subshape)
			end

			local mshfile
			if not Block.isBuildMode() then
				if data and data.funcflags and data.funcflags.useCombinedMesh or Global.CombineMeshs[shapeid] then
					mshfile = shapeid .. '.msh'
					if not _sys:fileExist(mshfile) then
						mshfile = nil
					end
				end
			end

			if mshfile then
				-- local tempmesh = mesh
				mesh = _Mesh.new(mshfile)
				local subs = {}
				mesh:getSubMeshs(subs)
				for i, sub in ipairs(subs) do
					-- setupMtl(sub) parse sub.name to mtl params
					if sub.name then
						local index = toint(sub.name)
						if index then
							local img = Global.lightNormalMaps[index]
							if img then
								sub:setNormalLightMap(img)
							end
						elseif sub.name ~= '' then
							local mtlps = sub.name:split(',')
							-- assert(#mtlps == 5)
							if #mtlps == 5 then
								for i = 1, 5 do mtlps[i] = math.trytoint(mtlps[i]) end
								-- print('~~~~~~~~~~~~~~~~~~~~~~mshfile', mshfile, mtlps[1], mtlps[2], mtlps[3], mtlps[4])
								sub.material = Block.getMaterial(mtlps[1], mtlps[2], mtlps[3], mtlps[4])
								local img = Global.lightNormalMaps[toint(mtlps[5])]
								if img then sub:setNormalLightMap(img) end
								
								local mtlname = Global.MtlRess[mtlps[1]]
								if mtlname and mtlname:find'glass' then
									sub.blender = glassblender
								end
								sub.isAlphaFilter = true
							end
						end
					end
				end

				-- TODO set mtl
				-- mesh.isStaticMesh = true
				-- mesh.BlocksMesh = tempmesh
			end

			mesh.name = shapeid
			Block.meshs[shapeid][mtlkey][subshape] = mesh

			-- 添加积木对应的分组/部位/动画等信息/积木数量等
			local hdata = Block.getHelperData(shapeid, subshape)
			if not hdata then
				hdata = Block.loadHelperData(shapeid, subshape, data, mesh)
			end

			-- if mesh.isStaticMesh then
				-- hdata.subs.dynamicEffects = nil
			-- end

			if actorfile then
				Block.loadActorFromFile(shapeid, subshape, actorfile)
			elseif actors then
				Block.loadActorData(shapeid, subshape, data, actors, hdata)
			end
		end

		local bmsh = Block.meshs[shapeid][mtlkey][subshape]
		local nmsh = clone_mesh(bmsh)
		return nmsh
	else
		if not Block.meshs[shapeid] then Block.meshs[shapeid] = {} end
		if not Block.meshs[shapeid][mtlid] then Block.meshs[shapeid][mtlid] = {} end
		if not Block.meshs[shapeid][mtlid][roughness] then Block.meshs[shapeid][mtlid][roughness] = {} end
		if not Block.meshs[shapeid][mtlid][roughness][mtlmode] then Block.meshs[shapeid][mtlid][roughness][mtlmode] = {} end
		if not Block.meshs[shapeid][mtlid][roughness][mtlmode][colorid] then Block.meshs[shapeid][mtlid][roughness][mtlmode][colorid] = {} end

		if paintInfo and paintInfo.resname == '' then paintInfo = nil end
		if paintInfo and paintInfo.typestr ~= 'paintInfo' then
			paintInfo = PaintInfo.new(paintInfo)
		end

		local paintInfoHash = paintInfo and paintInfo:md5() or 0
		local bd = Block.getBlockData(shapeid)
		local pf = 0
		if paintInfo and paintInfo.face then pf = paintInfo.face end
		local access = false
		if pf ~= 0 and bd and bd.paintface then
			for k, v in pairs(bd.paintface) do
				if v == pf then
					access = true
					break
				end
			end
		end

		if access == false then
			paintInfo = nil
		end

		local isEmissiveMode = mtlmode == Global.MTLMODE.EMISSIVE or _G.enableInsMaterial == false
		if isEmissiveMode then
			if not Block.meshs[shapeid][mtlid][roughness][mtlmode][colorid] then Block.meshs[shapeid][mtlid][roughness][mtlmode][colorid] = {} end
			if not Block.meshs[shapeid][mtlid][roughness][mtlmode][colorid][paintInfoHash] or _G.RECORDMATERIAL then
				local m = Block.getBasicBlockMesh(shapeid, mtlid, colorid, roughness, mtlmode, paintInfo, false)
				Block.meshs[shapeid][mtlid][roughness][mtlmode][colorid][paintInfoHash] = m
			end
		else
			if not Block.meshs[shapeid][mtlid][roughness][mtlmode][1] then Block.meshs[shapeid][mtlid][roughness][mtlmode][1] = {} end
			if not Block.meshs[shapeid][mtlid][roughness][mtlmode][1] then Block.meshs[shapeid][mtlid][roughness][mtlmode][1] = {} end
			if not Block.meshs[shapeid][mtlid][roughness][mtlmode][1][paintInfoHash] or _G.RECORDMATERIAL then
				local m = Block.getBasicBlockMesh(shapeid, mtlid, 1, roughness, mtlmode, paintInfo, true)
				Block.meshs[shapeid][mtlid][roughness][mtlmode][1][paintInfoHash] = m
			end
		end

		local bmsh = Block.meshs[shapeid][mtlid][roughness][mtlmode][(isEmissiveMode and colorid or 1)][paintInfoHash]
		local nmsh = clone_mesh(bmsh)
		nmsh.materialColor = isEmissiveMode and _Color.White or Block.convertColor(colorid)
		nmsh.material = bmsh.material
		if paintInfo then
			local sub1 = Block.getSubPaintMesh(bmsh)
			local sub2 = Block.getSubPaintMesh(nmsh)
			if sub2 and sub1 then
				sub2.material = sub1.material
			end
		end
		if nmsh.lodMesh then
			nmsh.lodMesh.materialColor = isEmissiveMode and _Color.White or Block.convertColor(colorid)
		end

		if mtlid == Global.MtlInvisible then
			nmsh.isInvisible = true
		end

		-- 添加actor
		if not Block.ShapeActors[shapeid] then
			local actors = {}
			local hdata = Block.getHelperData(shapeid)
			local shapes = hdata and hdata.shapes
			addActorData(actors, shapes)

			Block.ShapeActors[shapeid] = shrinkActorData(actors)
		end

		return nmsh
	end
end

function Block.getShapeActors(shapeid, subshape)
	if Block.isItemID(shapeid) then
		subshape = subshape or 0
		--assert(Block.ShapeActors[shapeid][subshape])
		local mode = Global.isHideInvisibleActorMode() and 1 or 0
		return Block.ShapeActors[shapeid] and Block.ShapeActors[shapeid][subshape][mode]
	else
		--assert(Block.ShapeActors[shapeid])
		return Block.ShapeActors[shapeid]
	end
end

function Global.saveActors2String(actors)
	local str = 'return {\n'
	str = str .. 'actors = {\n'
	for i, v in ipairs(actors) do
		local s = '\t' .. '{'
		s = s .. 'box = ' .. value2string(v.box) .. ', '
		if v.rot then
			s = s .. 'rot = ' .. value2string(v.rot) .. ', '
		end
		s = s .. '},\n'

		str = str .. s
	end
	str = str .. '\t' .. '},\n'
	str = str .. '}\n'

	return str
end

function Global.getNearestAxisType(axis)
	local abnx, abny, abnz = math.abs(axis.x), math.abs(axis.y), math.abs(axis.z)
	local isAxis = false
	if abnz > abnx and abnz > abny then
		isAxis = axis.x == 0 and axis.y == 0 and (axis.z == 1 or axis.z == -1)
		return axis.z > 0 and Global.AXISTYPE.Z or Global.AXISTYPE.NZ, isAxis
	elseif abny > abnx and abny > abnz then
		isAxis = axis.x == 0 and axis.z == 0 and (axis.y == 1 or axis.y == -1)
		return axis.y > 0 and Global.AXISTYPE.Y or Global.AXISTYPE.NY, isAxis
	else
		isAxis = axis.z == 0 and axis.y == 0 and (axis.x == 1 or axis.x == -1)
		return axis.x > 0 and Global.AXISTYPE.X or Global.AXISTYPE.NX, isAxis
	end
end

function Global.typeToAxis(N)
	if N == Global.AXISTYPE.X then
		return Global.AXIS.X
	elseif N == Global.AXISTYPE.Y then
		return Global.AXIS.Y
	elseif N == Global.AXISTYPE.Z then
		return Global.AXIS.Z
	elseif N == Global.AXISTYPE.NX then
		return Global.AXIS.NX
	elseif N == Global.AXISTYPE.NY then
		return Global.AXIS.NY
	elseif N == Global.AXISTYPE.NZ then
		return Global.AXIS.NZ
	end
end

local rotaxismat = _Matrix3D.new()
local rotaxisv4 = _Vector4.new()

function Global.getRotaionAxis(axis, mat, outvec)
	local m = rotaxismat
	local r = rotaxisv4
	mat:getRotation(r)
	m:setRotation(r)
	m:apply(axis, outvec)
end

function Global.getRotaionAxisInverse(axis, mat, outvec)
	local m = rotaxismat
	local r = rotaxisv4
	mat:getRotation(r)
	m:setRotation(r.x, r.y, r.z, -r.w)
	m:apply(axis, outvec)
end

local rotaxisv3 = _Vector3.new()
function Global.getRotaionAxisType(N, mat)
	if not mat:hasRotation() then return N end

	local axis = Global.typeToAxis(N)
	Global.getRotaionAxis(axis, mat, rotaxisv3)
	local axistype = Global.getNearestAxisType(rotaxisv3)
	return axistype
end

function Global.toPositiveAxisType(N1)
	return N1 > 3 and N1 - 3 or N1
end

function Global.isAxisTypeSameLine(N1, N2)
	return Global.toPositiveAxisType(N1) == Global.toPositiveAxisType(N2)
end

function Global.isAxisTypeOpposite(N1, N2)
	return (N1 > 3 and Global.toPositiveAxisType(N1) == N2) or (N2 > 3 and Global.toPositiveAxisType(N2) == N1)
end

function Global.isAxisSameLine(axis1, axis2)
	return math.floatEqual(math.abs(_Vector3.dot(axis1, axis2)), 1, 0.001)
end

function Global.isAxisOpposite(axis1, axis2)
	return math.floatEqual(_Vector3.dot(axis1, axis2), -1, 0.001)
end

function Global.isAxisOrtho(axis1, axis2)
	return math.floatEqual(math.abs(_Vector3.dot(axis1, axis2)), 0, 0.001)
end

-- normal must be normalized
function Global.buildProjectAxis(normal, tangent, binormal)
	if not tangent then
		tangent = _Vector3.new()
		if math.floatEqualVector3(normal, Global.AXIS.X) or math.floatEqualVector3(normal, Global.AXIS.NX) then
			tangent:set(Global.AXIS.Z)
		else
			tangent:set(Global.AXIS.X)
		end

		binormal = _Vector3.new()
		_Vector3.cross(normal, tangent, binormal)
		binormal:normalize()
		_Vector3.cross(binormal, normal, tangent)
		tangent:normalize()
	elseif not binormal then
		binormal = _Vector3.new()
		_Vector3.cross(normal, tangent, binormal)
		binormal:normalize()
		_Vector3.cross(binormal, normal, tangent)
		tangent:normalize()
	end

	local data = {}
	data.Normal = normal
	data.Tangent = tangent
	data.Binormal = binormal

	return data
end

function Global.rotationQuarter2D(v, isneg)
	local x, y = v.x, v.y
	if not isneg then
		v.x = -y
		v.y = x
	else
		v.x = y
		v.y = -x
	end

	return v
end

function Global.dir2Axis2D(dir, axisv3)
	-- local axisv3 = Container:get(_Vector3)
	_Vector3.sub(_rd.camera.look, _rd.camera.eye, axisv3)
	axisv3.z = 0
	axisv3:normalize()

	--Global.DIRECTION.UP, Global.DIRECTION.RIGHT, Global.DIRECTION.DOWN, Global.DIRECTION.LEFT
	if dir == Global.DIRECTION.UP then
		return axisv3
	elseif dir == Global.DIRECTION.DOWN then
		_Vector3.mul(axisv3, -1, axisv3)
		return axisv3
	elseif dir == Global.DIRECTION.LEFT then
		Global.rotationQuarter2D(axisv3, true)
		return axisv3
	elseif dir == Global.DIRECTION.RIGHT then
		Global.rotationQuarter2D(axisv3, false)

		return axisv3
	end
end

function Global.dir2AxisTypes(ignoreType)
	assert(ignoreType <= 3)

	local ts
	if ignoreType == Global.AXISTYPE.X then
		ts = {Global.AXISTYPE.Y, Global.AXISTYPE.Z, Global.AXISTYPE.NY, Global.AXISTYPE.NZ}
	elseif ignoreType == Global.AXISTYPE.Y then
		ts = {Global.AXISTYPE.X, Global.AXISTYPE.Z, Global.AXISTYPE.NX, Global.AXISTYPE.NZ}
	elseif ignoreType == Global.AXISTYPE.Z then
		ts = {Global.AXISTYPE.X, Global.AXISTYPE.Y, Global.AXISTYPE.NX, Global.AXISTYPE.NY}
	end

	local axisv3 = Container:get(_Vector3)
	local axisv2 = Container:get(_Vector2)
	local centerv2 = Container:get(_Vector2)
	centerv2:set(_rd.w / 2, _rd.h / 2)

	_Vector3.add(_rd.camera.look, Global.typeToAxis(ts[1]), axisv3)
	_rd:projectPoint(axisv3.x, axisv3.y, axisv3.z, axisv2)
	_Vector2.sub(axisv2, centerv2, axisv2)
	axisv2:normalize()

	local ds
	-- print('axisv2', axisv2)
	if math.abs(axisv2.y) > math.abs(axisv2.x) then
		if axisv2.y < 0 then
			-- print('!', 1)
			ds = {Global.DIRECTION.UP, Global.DIRECTION.RIGHT, Global.DIRECTION.DOWN, Global.DIRECTION.LEFT}
		else
			-- print('!', 2)
			ds = {Global.DIRECTION.DOWN, Global.DIRECTION.LEFT, Global.DIRECTION.UP, Global.DIRECTION.RIGHT}
		end
	else
		if axisv2.x > 0 then
			-- print('!', 3)
			ds = {Global.DIRECTION.RIGHT, Global.DIRECTION.DOWN, Global.DIRECTION.LEFT, Global.DIRECTION.UP}
		else
			-- print('!', 4)
			ds = {Global.DIRECTION.LEFT, Global.DIRECTION.UP, Global.DIRECTION.RIGHT, Global.DIRECTION.DOWN}
		end
	end

	-- 把对应的方向按照上下左右排列
	local types = {}
	for dir = 1, 4 do
		for i, d in ipairs(ds) do
			if d == dir then
				table.insert(types, ts[i])
				break
			end
		end
	end

	Container:returnBack(axisv3, axisv2, centerv2)
	return types
end

function Global.dir2AxisType(dir, ignoreType)
	local types = Global.dir2AxisTypes(ignoreType)
	return types[dir]
end

Block.getMoveStep = function(id, mat)
	return Global.MOVESTEP.TILE, Global.MOVESTEP.TILE, Global.MOVESTEP.TILE
end

Block.drawAsUI = function(self, meshes, db, state)
	if not meshes or not db then return end
	local camera2d = Container:get(_Camera)

	camera2d.eye:set(0, 10, 0)
	camera2d.look:set(0, 0, 0)
	camera2d.ortho = true
	camera2d.viewWidthScale = 1 / 400
	camera2d.viewHeightScale = 1 / 400

	local w, h = 0, 0
	local xs = {0}
	for i, v in ipairs(meshes) do
		local aabb = v:getBoundBox()
		v.aabb = aabb
		w = w + aabb.x2 - aabb.x1
		h = math.max(aabb.y2 - aabb.y1, h)
		table.insert(xs, (w - aabb.x2 - aabb.x1) / camera2d.viewWidthScale)
	end
	db:resize(math.max(w / camera2d.viewWidthScale, 1), math.max(h / camera2d.viewHeightScale, 1))
	-- db.w = math.max(w / camera2d.viewWidthScale, 1)
	-- db.h = math.max(h / camera2d.viewHeightScale, 1)

	_rd:pushCamera()
	_rd.camera = camera2d

	local lastAsyncShader = _sys.asyncShader
	_sys.asyncShader = false
	_rd:useDrawBoard(db, _Color.Null)
	for i, v in ipairs(meshes) do
		local paintmesh = v:getSubMesh(1)
		paintmesh = paintmesh and paintmesh:getSubMesh('paint')
		local dmap = paintmesh and paintmesh.material and paintmesh.material.diffuseMap
		if dmap then
			local sx = (dmap.w * db.h / dmap.h - (xs[i + 1] - xs[i])) / 2
			-- TODO useclip
			dmap:drawImage(xs[i] - sx, 0, xs[i + 1] + sx, db.h)
		end
	end
	_rd:resetDrawBoard()
	_sys.asyncShader = lastAsyncShader
	_rd:popCamera()

	Container:returnBack(camera2d)
end

Block.draw3DIcon = function(datas, db, scale, state, useplane, onfloor, lightdir, nocenter)
	if not datas or not db then return end

	local isSelected = state == 'selected'
	local camera2d = Container:get(_Camera)
	local abcenter = Container:get(_Vector3)
	local offsetmat = Container:get(_Matrix3D)
	local pmat = Container:get(_Matrix3D)
	local mat = Container:get(_Matrix3D)
	pmat:identity()
	Global.CameraControl:push()

	camera2d.look:set(0, 0, 0)
	if scale == nil then
		camera2d.eye:set(-0.5, -1, 1)
		_rd.camera:set(camera2d)

		local aabb = Container:get(_AxisAlignedBox)
		local vec = Container:get(_Vector3)
		if datas and datas[1] and datas[1].typestr == 'block' then
			Block.getAABBs(datas, aabb)
		elseif #datas == 0 then
			aabb.min.x, aabb.min.y, aabb.min.z = -1, -1, -1
			aabb.max.x, aabb.max.y, aabb.max.z = 1, 1, 1
		else
			aabb:initBox()

			local ab1 = Container:get(_AxisAlignedBox)
			for i, data in ipairs(datas) do
				local color = Block.convertColor(data.color)
				local mesh = Block.getBlockMesh(data.shape, data.subshape, data.material, color, data.roughness, data.mtlmode, data.paintInfo)
				local ab = mesh:getBoundBox()
				ab1.min:set(ab.x1, ab.y1, ab.z1)
				ab1.max:set(ab.x2, ab.y2, ab.z2)
				if data.space then
					local s = data.space
					mat:setRotation(s.rotation)
					mat:mulTranslationRight(s.translation)
					ab1:mul(mat)
				end
				_AxisAlignedBox.union(aabb, ab1, aabb)
			end
			Container:returnBack(ab1)
		end

		aabb:getCenter(abcenter)
		if onfloor == true then
			pmat:setTranslation(0, 0, -abcenter.z - 0.2)
		end

		if nocenter then
			vec:set(0, 0, 0)
		else
			vec:set(-abcenter.x, -abcenter.y, -abcenter.z)
		end
		offsetmat:setTranslation(vec)
		_AxisAlignedBox.offset(aabb, vec, aabb)
		calcCameraRadius(_rd.camera, aabb, db)
		Container:returnBack(aabb, vec)
	else
		camera2d.eye:set(scale * -0.5, scale * -1, scale)
		_rd.camera:set(camera2d)
	end

	local lastAsyncShader = _sys.asyncShader
	_sys.asyncShader = false
	_rd:useDrawBoard(db, _Color.Null)
	if lightdir then Block.defaultSkyLight.direction:set(lightdir) end
	_rd:useLight(Block.defaultAmbientLight)
	_rd:useLight(Block.defaultSkyLight)
	if isSelected then
		_rd.edgeColor = 0xff000000
		_rd.edgeWidth = 2
		_rd.edge = true
		_rd.postEdge = true
	end

	local tranz = 0.0
	local trans = Container:get(_Vector3)
	for i, data in ipairs(datas) do
		if data.typestr == 'block' then
			local isAnimaPart = false
			if Global.BuildBrick then isAnimaPart = Global.BuildBrick.mode == 'buildanima' end
			if isAnimaPart or data.node.visible then
				_rd:pushMulMatrix3DRight(data.node.transform)
				_rd:pushMulMatrix3DRight(offsetmat)
				data.node.transform:getTranslation(trans)
				tranz = math.min(tranz, trans.z)

				data.node.mesh:drawMesh()

				_rd:popMatrix3D()
				_rd:popMatrix3D()
			end
		else
			local s = data.space
			if s then
				mat:setRotation(s.rotation)
				mat:mulTranslationRight(s.translation)
				_rd:pushMulMatrix3DRight(mat)
			end

			local color = Block.convertColor(data.color)
			local mesh = Block.getBlockMesh(data.shape, data.subshape, data.material, color, data.roughness, data.mtlmode, data.paintInfo)
			mesh:drawInstanceMesh()

			if s then
				_rd:popMatrix3D()
			end
		end
	end
	if isSelected then
		_rd.postEdge = false
		_rd.edge = false
	end

	if useplane ~= false then
		local basePlane = _mf:createPlane()
		basePlane.transform:setScaling(1000, 1000, 1)
		pmat:mulTranslationRight(0, 0, tranz)
		_rd:pushMulMatrix3DRight(pmat)
		basePlane:drawMesh()
		_rd:popMatrix3D()
	end

	_rd:popLight()
	_rd:popLight()
	if lightdir then Block.defaultSkyLight.direction:set(0, 0, -1) end
	_rd:resetDrawBoard()
	_sys.asyncShader = lastAsyncShader
	Global.CameraControl:pop()

	Container:returnBack(camera2d, abcenter, offsetmat, mat, pmat, trans)
end

function Global.normalizePos(pos, mode)
	if type(pos) == 'number' then
		pos = normalizePos(pos, mode)
	else
		pos.x = normalizePos(pos.x, mode)
		pos.y = normalizePos(pos.y, mode)
		pos.z = normalizePos(pos.z, mode)
	end

	return pos
end

local defaultscalestep = 0.25
function Global.findScaleIndex(scale, step)
	local s = type(scale) == 'number' and scale or scale.x
	step = step or defaultscalestep
	local newscale = math.floatRound(s, step)
	return newscale / step
end

function Global.getScaleByIndex(index, step)
	step = step or defaultscalestep
	return index * step
end

local function getNearestNumber(n, step, accuracy)
	accuracy = accuracy or 0.01
	local newn = math.floatRound(n, step)
	return math.floatEqual(newn, n, accuracy) and newn or n

end
function Global.normalizeScale(scale, step)
	step = step or defaultscalestep
	if type(scale) == 'number' then
		return getNearestNumber(scale, step)
	else
		local x = getNearestNumber(scale.x, step)
		local y = getNearestNumber(scale.y, step)
		local z = getNearestNumber(scale.z, step)
		scale:set(x, y, z)
		return scale
	end
end

local rotfactor = 15 * math.pi / 180
function Global.normalizeRotation(rot, step)
	step = step or rotfactor
	if type(rot) == 'number' then
		return getNearestNumber(rot, step, 0.001)
	else
		local x = getNearestNumber(rot.x, step, 0.001)
		local y = getNearestNumber(rot.y, step, 0.001)
		local z = getNearestNumber(rot.z, step, 0.001)
		rot:set(x, y, z)
		return rot
	end
end

Global.checkFuncFlags = function(data, key)
	return data.funcflags and data.funcflags[key]
end

Global.isMultiObjectType = function(type)
	return type == 'house' or Global.isSceneType(type)
end

Global.isSceneType = function(type)
	return type == 'scene' or type == 'scene_2D' or type == 'scene_music' or type == 'scene_music_sub'
end

-- 先放这儿
Global.setupItemDragEffect = function(item, db, mainui, listui, doFun, moveFun, downFun)
	local function clearClickdata(item)
		if not item.clickdata then return end
		if item.clickdata.timer then
			item.clickdata.timer:stop()
		end

		if item.clickdata.dragui then
			item.clickdata.dragui:removeMovieClip()
		end

		item.clickdata = nil

		listui.visible = true
	end

	item.onMouseDown = function(args)
		-- 抄袭胖哥的结构.之前的实现在手机上有问题。
		local scalef = Global.UI:getScale()
		local clickdata = {
			-- 获取ui中鼠标的真实位置 TODO:使用逻辑分辨率？
			fid = args.mouse.id,
			time = _tick(),
			timer = _Timer.new(),
			invoked = false,
			oldpos = _Vector3.new(),
			mouseX = args.mouse.x * scalef,
			mouseY = args.mouse.y * scalef,
		}

		clickdata.timer:start('timer', 200, function()
			clickdata.timer:stop()
			local dragui = mainui:loadMovie(db)
			dragui._x = args.mouse.x - item._width / 2
			dragui._y = args.mouse.y - item._height / 2

			clickdata.dragui = dragui
			listui.visible = false
			clickdata.invoked = true

			if downFun then
				downFun(args.mouse.x, args.mouse.y)
			end
		end)

		item.clickdata = clickdata
	end

	item.onMouseMove = function(args)
		if not item.clickdata then return end
		if not item.clickdata.invoked then
			local scalef = Global.UI:getScale()
			local dx = math.abs(args.mouse.x * scalef - item.clickdata.mouseX)
			local dy = math.abs(args.mouse.y * scalef - item.clickdata.mouseY)
			if dx + dy > 20 then
				clearClickdata(item)
			end
		else
			item.clickdata.dragui._x = args.mouse.x - item._width / 2
			item.clickdata.dragui._y = args.mouse.y - item._height / 2

			if moveFun then
				moveFun(args.mouse.x, args.mouse.y)
			end
		end
	end

	item.onMouseUp = function(args)
		-- dress on cloth.
		if item.clickdata and item.clickdata.invoked then
			doFun(args.mouse.x, args.mouse.y)
		end

		clearClickdata(item)
	end
end

-- TODO. 先放这儿.
_sys:onDeviceOrientationChange(function(...)
	if not Global.sen then return end
	if not Global.sen.isMirrorSen then return end

	local nodes = {}

	Global.sen:getNodes(nodes)
	for i, v in next, nodes do
		if v.isMirrorNode then
			if v.mesh and v.mesh.material then
				local db = _DrawBoard.new(_rd.w, _rd.h)
				db.postProcess = _PostProcess.new()
				db.postProcess.bloom = false
				v.mesh.material.diffuseMap = db
			end
		end
	end
end)

-- 解决PC上改变窗口大小，镜面效果不对的bug.
_app:onResize(function(w, h)
	if not Global.sen then return end
	if not Global.sen.isMirrorSen then return end
	if w == 0 or h == 0 then return end

	local nodes = {}

	Global.sen:getNodes(nodes)
	for i, v in next, nodes do
		if v.isMirrorNode then
			if v.mesh and v.mesh.material then
				local db = _DrawBoard.new(w, h)
				db.postProcess = _PostProcess.new()
				db.postProcess.bloom = false
				v.mesh.material.diffuseMap = db
			end
		end
	end
end)

initShapeData()

