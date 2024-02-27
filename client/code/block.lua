local Container = _require('Container')
local Function = _require('Function')

_sys:addPath('toy')

local block = {}
Global.Block = block
block.typestr = 'block'

local selectedmtl = _Material.new('select_01.mtl')

_dofile('ui_blockchip.lua')
_dofile('knotManager.lua')
_dofile('block_meshs.lua')
_dofile('block_merge.lua')
_dofile('block_anima.lua')
_dofile('ui_brick.lua')
_dofile('knot.lua')
_dofile('knotgroup.lua')
_dofile('knotgroupManager.lua')
_dofile('block_group.lua')
_dofile('logicblockGroup.lua')
_dofile('block_subgroup.lua')
_dofile('bmarker.lua')

_dofile('block_chip.lua')

local helpvec = _Vector3.new()
block.setNodeActor = function(self, node, actor)
	self.node = node
	self.actor = actor
	actor.transform = node.transform
	actor.node = node
	node.actor = actor
	node.block = self
end

block.initNodeActor = function(self, node, actor)
	self:setNodeActor(node, actor)
	node.isShadowCaster = true
	node.isShadowReceiver = true

	node.needUpdate = false
	self:refreshAll()

	self:setPickFlag(Global.CONSTPICKFLAG.NORMALBLOCK)
end
block.new = function(node, actor, shape, data, enabledelayLoad)
	local b = {}
	setmetatable(b, {__index = block})

	b.serialNum = GenSerialNum()
	b.name = 'none'

	b.data = {
		name = b.name,
		shape = shape or 1,
		material = material or 1,
		color = 1,
		roughness = 1,
		mtlmode = 1,
		space = {
			scale = _Vector3.new(1, 1, 1),
			rotation = _Vector4.new(0, 0, 1, 0),
			translation = _Vector3.new(0, 0, 0),
		},
		physX = {
			-- ride on & slide
			disable = false,
			behaviorType = 3,
			kinematic = true,
			trigger = false,
		},
		logic = {
			visible = true,
		},
		paintInfo = PaintInfo.new(),
	}
	b.functions = {}
	b.bindpfxs = {}
	b.funcflags = {}
	b.content = {}
	b.rtdata = {available = true, transparency = 1.0, hitdata = {}, anchor = false, subshape = b.data.subshape, showHint = false, showEdge = false, showGuide = false}
	b.isdynamic = false
	b.overlaps = {}
	b.neighbors = {}
	b.connects = {}

	-- 设置对应flag的方法函数
	-- b.funcflagcbs = {}
	b.cmarkers = {}
	b.enableShapeDf = true

	if data then
		b:load(data)

		b.name = b.data.name
		b.needLoad = enabledelayLoad and b.data.needLoad
		if not data.mtlmode then
			b.data.mtlmode = Global.MTLMODE.PAINT
		end

		if data.markerdata then
			b:setMarker(data.markerdata)
		end
		if data.paintInfo then
			b.data.paintInfo = PaintInfo.new(data.paintInfo)
		end
	end

	--print('b.data.paintInfo', b.data.paintInfo and b.data.paintInfo.typestr)

	b:initNodeActor(node, actor)
	if data and data.iscaster ~= nil then b.node.isShadowCaster = data.iscaster end
	b.attrs = {
		-- Speed = _Vector3.new(0,0,0), -- speed
		InstaSpeed = _Vector3.new(),
	}

	b.aabb = _AxisAlignedBox.new()
	return b
end

---------------------------------------
local loadData
loadData = function(dst, src)
	for k, v in next, src do
		if type(v) == 'table' then
			if v.typeid == _Vector3.typeid then
				dst[k]:set(v)
			elseif v.typeid == _Vector4.typeid then
				dst[k].x = v.x
				dst[k].y = v.y
				dst[k].z = v.z
				dst[k].w = v.w
			else
				if dst[k] then
					loadData(dst[k], v)
				else
					dst[k] = v
				end
			end
		else
			dst[k] = v
		end
	end
end
block.load = function(self, data)
	loadData(self.data, data)
	for i, v in ipairs(data.functions or {}) do
		self:addFunction(Function.new(v))
	end
end

block.tostringForObject = function(self, head)
	head = head or ''
	local s = self.data.space
	local p = self.data.physX
	local l = self.data.logic
	local shape = type(self.data.shape) == 'string' and ('\'' .. self.data.shape .. '\'') or self.data.shape
	local str = head .. '{\n'
	str = str .. head .. '\tshape = ' .. shape .. ',\n'
	str = str .. head .. '\tsubshape = 0,\n'
	str = str .. head .. '\tmaterial = ' .. self.data.material .. ',\n'
	str = str .. head .. '\tcolor = ' .. self.data.color .. ',\n'
	str = str .. head .. '\troughness = ' .. self.data.roughness .. ',\n'
	str = str .. head .. '\tmtlmode = ' .. (self.data.mtlmode or 1) .. ',\n'
	str = str .. head .. '\tspace = {\n'
	str = str .. head .. '\t\tscale = _Vector3.new(' .. s.scale.x .. ',' .. s.scale.y .. ',' .. s.scale.z .. '),\n'
	str = str .. head .. '\t\trotation = _Vector4.new(' .. s.rotation.x .. ',' .. s.rotation.y .. ',' .. s.rotation.z .. ',' .. s.rotation.w .. '),\n'
	str = str .. head .. '\t\ttranslation = _Vector3.new(' .. s.translation.x .. ',' .. s.translation.y .. ',' .. s.translation.z .. '),\n'
	str = str .. head .. '\t},\n'
	str = str .. head .. '}'
	return str
end

block.tostring = function(self, head)
	head = head or ''
	local s = self.data.space
	local p = self.data.physX
	local l = self.data.logic
	local shape = type(self.data.shape) == 'string' and ('\'' .. self.data.shape .. '\'') or self.data.shape
	local str = head .. '{\n'
	str = str .. head .. '\tindex = ' .. self.index .. ',\n'
	str = str .. head .. '\tname = \'' .. self.name .. '\',\n'
	str = str .. head .. '\tshape = ' .. shape .. ',\n'
	if self.data.needLoad then
		str = str .. head .. '\tneedLoad = true,\n'
	end
	str = str .. head .. '\tmaterial = ' .. self.data.material .. ',\n'
	str = str .. head .. '\tcolor = ' .. self.data.color .. ',\n'
	str = str .. head .. '\troughness = ' .. self.data.roughness .. ',\n'
	str = str .. head .. '\tmtlmode = ' .. (self.data.mtlmode or 1) .. ',\n'
	str = str .. head .. '\tspace = {\n'
	str = str .. head .. '\t\tscale = _Vector3.new(' .. s.scale.x .. ',' .. s.scale.y .. ',' .. s.scale.z .. '),\n'
	str = str .. head .. '\t\trotation = _Vector4.new(' .. s.rotation.x .. ',' .. s.rotation.y .. ',' .. s.rotation.z .. ',' .. s.rotation.w .. '),\n'
	str = str .. head .. '\t\ttranslation = _Vector3.new(' .. s.translation.x .. ',' .. s.translation.y .. ',' .. s.translation.z .. '),\n'
	str = str .. head .. '\t},\n'
	str = str .. head .. '\tphysX = {\n'
	str = str .. head .. '\t\tbehaviorType = ' .. p.behaviorType .. ',\n'
	str = str .. head .. '\t\tkinematic = ' .. tostring(p.kinematic) .. ',\n'
	str = str .. head .. '\t\ttrigger = ' .. tostring(p.trigger) .. ',\n'
	str = str .. head .. '\t},\n'
	str = str .. head .. '\tlogic = {\n'
	str = str .. head .. '\t\tvisible = ' .. tostring(l.visible) .. ',\n'
	str = str .. head .. '\t},\n'
	str = str .. head .. '\tfunctions = {\n'
	for i, v in ipairs(self.functions) do
		str = str .. v:tostring(head .. '\t\t', 'block', self.index)
	end
	str = str .. head .. '\t},\n'

	-- check paint mesh.
	--[[
	if self.node and self.node.mesh then
		local paintmesh
		self.node.mesh:enumMesh('paint', true, function(msh)
			paintmesh = msh
		end)

		if paintmesh then
			local painttex = paintmesh.material.diffuseMap
			local scale = Container:get(_Vector3)
			paintmesh.transform:getScaling(scale)
			local translation = Container:get(_Vector3)
			paintmesh.transform:getTranslation(translation)

			local resname = _sys:getFileName(painttex.resname)
			str = str .. head .. '\tpaintInfo = {\n'
			str = str .. head .. '\t\tresname = \'' .. resname .. '\',\n'
			str = str .. head .. '\t\tscale = _Vector3.new(' .. scale.x .. ',' .. scale.y .. ',' .. scale.z .. '),\n'
			str = str .. head .. '\t\ttranslation = _Vector3.new(' .. translation.x .. ',' .. translation.y .. ',' .. translation.z .. '),\n'
			str = str .. head .. '\t},\n'

			Container:returnBack(scale, translation)
		end
	end
	--]]

	str = str .. head .. '}'

	return str
end
block.getIndexInfo = function(self, curtype, curid)
	return 'blockid = ' .. ((self.index == curid and curtype == 'block') and -1 or self.index)
end
block.resetSpace = function(self)
	local s = self.data.space
	self.node.transform:setScaling(s.scale)
	self.node.transform:mulRotationRight(s.rotation.x, s.rotation.y, s.rotation.z, s.rotation.w)
	self.node.transform:mulTranslationRight(s.translation)

	self:formatMatrix()

	-- if self.scaledirty then
	-- 	self:refreshActorShape()
	-- 	self.scaledirty = false
	-- end
end

block.addCacheTransform = function(self)
	self.cacheTransform = _Matrix3D.new()
	self.cacheTransform:set(self.node.transform)

	return self.cacheTransform
end

block.delCacheTransform = function(self)
	self.cacheTransform = nil
end

block.getCacheTransform = function(self)
	-- print('self.cacheTransform', self.cacheTransform, self.node.transform)
	return self.cacheTransform
end

block.getScene = function(self)
	return self.node and self.node.scene
end
block.refreshAll = function(self)
	if self.rtadd then
		self:getScene():delBlock(self)
		return
	end

	self:refreshShape()
	self:resetSpace()

	for k, v in next, self.data.physX do
		self.actor[k] = v
	end
	self:setVisible(self.data.logic.visible)
	self.rtdata = {available = true, transparency = 1.0, hitdata = {}, anchor = false, subshape = self.data.subshape, showHint = false, showEdge = false, showGuide = false}
end

block.playBindPfx = function(self, pfxname, submesh, mat)
	-- self.mesh.enableInstanceCombine = false

	local pfx
	if submesh then
		if mat then
			pfx = self.node.mesh.pfxPlayer:play(pfxname, mat)
		else
			pfx = self.node.mesh.pfxPlayer:play(pfxname)
		end
		pfx.transform.parent = submesh.transform
	else
		local sen = self:getScene()
		if not sen then return end

		if mat then
			pfx = sen.pfxPlayer:play(pfxname, mat)
		else
			pfx = sen.pfxPlayer:play(pfxname)
		end
		pfx.transform.parent = self.node.transform
	end

	table.insert(self.bindpfxs, {pfx = pfx, pfxname = pfxname})

	return pfx
end

block.stopBindPfx = function(self, pfxname)
	if self.bindpfxs then
		for i, v in ipairs(self.bindpfxs) do
			if pfxname == nil or v.pfxname == pfxname then
				v.pfx:stop(true)
			end
		end
	end

	self.bindpfxs = {}
end

block.hasBindPfx = function(self)
	return self.bindpfxs and #self.bindpfxs > 0
end

block.refresh = function(self)
	if self.rtadd then
		self:getScene():delBlock(self)
		return
	end

	if self.rtdata.subshape ~= self.data.subshape then
		self:refreshShape()
	end

	self:resetSpace()

	for k, v in next, self.data.physX do
		self.actor[k] = v
	end
	self:setVisible(self.data.logic.visible)
	self.rtdata = {available = true, transparency = 1.0, hitdata = {}, anchor = false, subshape = self.data.subshape, showHint = false, showEdge = false, showGuide = false}
end

block.isItem = function(self)
	return type(self.data.shape) == 'string'
end

block.independentMaterial = function(self)
	self.node.mesh:enumMesh('', true, function(mesh)
		if mesh.material then
			mesh.material = mesh.material:clone(false)
		end
	end)
end

-- astronauts 脚上绑了一个特效点的名字叫：foot_jet_01.pfx
-- jump动画触发这个特效点播放rocket_jump.pfx
local pfx_replace_cfg = {
	['foot_jet_01.pfx'] = 'rocket_jump.pfx',
}

block.refreshPfx = function(self, show, pfxname)
	-- print('show', show, pfxname)
	local hdata = self:getHelperData()
	local subs = hdata and hdata.subs
	if subs then
		for i, bd in ipairs(subs.bs) do
			if bd.pfxs and #bd.pfxs > 0 then
				for _, v in ipairs(bd.pfxs) do
					local mat = _Matrix3D.new()
					mat:setScaling(v.scale)
					mat:mulRotationRight(v.rotation.x, v.rotation.y, v.rotation.z, v.rotation.w)
					mat:mulTranslationRight(v.translation)
					if pfx_replace_cfg[v.pfxname] then
						if pfxname then
							if show then
								self:playBindPfx(pfxname, self:getSubMesh(bd.index), mat)
							else
								self:stopBindPfx(pfxname)
							end
						end
					else
						self:playBindPfx(v.pfxname, self:getSubMesh(bd.index), mat)
					end
				end
			end
		end
	end
end

block.refreshMarkerData = function(self)
	for bindex, marker in pairs(self.cmarkers) do
		marker:enableMarker(false)
	end
	self.cmarkers = {}

	local hdata = self:getHelperData()
	local subs = hdata and hdata.subs
	if subs then
		for i, bd in ipairs(subs.bs) do
			if bd.markerdata then
				local marker = BMarker.new(bd.markerdata)
				marker:setBlock(self, bd.index)
				-- marker:enableMarker(true)
				self.cmarkers[bd.index] = marker
			end
		end
	end
end

block.invokeMarker = function(self)
	for bindex, marker in pairs(self.cmarkers) do
		if marker:getType() == 'marker_train' then
			local sub = self:getSubMesh(bindex)
			if sub then
				sub:clearSubMeshs()

				self:skipRefreshSceneNode(true)

				local ab = Container:get(_AxisAlignedBox)
				local vec = Container:get(_Vector3)

				local y = 0
				local data = nil
				for i, v in ipairs(marker.trains or {}) do
					local tempshape
					if v.moduleid then
						tempshape = 'subm_' .. v.moduleid .. '_' .. self:getShape() .. _now(0.001)
						if not data then data = Block.loadItemData(self:getShape()) end
						local m = data.submodules[v.moduleid].module
						Block.addDataCache(tempshape, m)
					end

					local shape = tempshape or v.shape
					local mesh = Block.getBlockMesh(shape)
					local bd = Block.getHelperData(shape, nil, true)

					ab:initCenterAndSize(bd.boxcenter, bd.boxsize)
					ab:getBottom(vec)
					vec.y = ab.min.y
					mesh.transform:mulTranslationRight(-vec.x, y - vec.y, -vec.z)
					y = y + (ab.max.y - ab.min.y)
					sub:addSubMesh(mesh)

					if tempshape then
						Block.clearDataCache(tempshape)
					end
				end

				self:skipRefreshSceneNode(false)

				Container:returnBack(ab, vec)
			end
		end
	end
end

block.getSubGroup = function(self, group)
	if not group then return end
	if not self.subgroups then self.subgroups = {} end

	local sub = self.subgroups[group]
	if not sub then
		-- local hdata = Block.getHelperData(self.data.shape, self.data.subshape)
		--local g = hdata.subs.groups[group]
		-- print('block.getSubGroup', group, group and table.ftoString(group))
		sub = BlockSubGroup.new(self, group)
		self.subgroups[group] = sub
	end

	return sub
end

block.refreshSubGroups = function(self)
	self.subgroups = {}
	if self.playingDf then
		self.playingDf:refreshGroup()
	end
end

local DummyMesh = _Mesh.new()
block.refreshMesh = function(self)
	local color = self:getColor()
	local roughness = self:getRoughness()

	if self.needLoad then
		self.node.mesh = DummyMesh
		return
	end

	self.node.mesh = Block.getBlockMesh(self.data.shape, self.data.subshape, self.data.material, color, roughness, self.data.mtlmode, self.data.paintInfo)

	self.mesh = self.node.mesh
	if self.data.paintInfo then
		self.node.isInsAlphaFilter = true
	end

	local hdata = Block.getHelperData(self.data.shape, self.data.subshape)
	self.hdata = hdata

	local subs = {}
	self.mesh:getSubMeshs(subs)
	self.submeshs = subs

	self:refreshPfx()
	self:refreshMarkerData()
	self:refreshSubGroups()
	-- self:refreshFuncflags(hdata.funcflags)
end

block.loadMeshData = function(self)
	if not self.needLoad then return false end

	_G.enableActorFile = true
	local t1 = _tick()
	self.needLoad = false
	self:refreshMesh()
	self:refreshActorShape()
	self:resetSpace()
	self:enablePhysic(self.physic)
	local t2 = _tick()
	print('loadMeshData:', self.data.shape, t2 - t1, CurrentFrame())
	_G.enableActorFile = false
	return true
end

block.getActorsData = function(self)
	return Block.getShapeActors(self.data.shape, self.data.subshape)
end

block.getActorScale = function(self)
	if not self.ActorScale then
		self.ActorScale = _Vector3.new(1, 1, 1)
	end

	return self.ActorScale
end

block.clearActorShape = function(self)
	self.shapes = self.shapes or {}
	if self.shapes then
		for i, v in ipairs(self.shapes) do
			self.actor:delShape(v)
		end

		self.shapes = {}
	end
end

local helpscale = _Vector3.new()
block.refreshActorShape = function(self)
	local t1 = _tick()
	-- 重置shapes
	self.shapes = self.shapes or {}
	if self.shapes then
		for i, v in ipairs(self.shapes) do
			self.actor:delShape(v)
		end

		self.shapes = {}
	end

	-- 计算物理的包围盒
	local aabb = _AxisAlignedBox.new()
	aabb:initBox()
	self.shapesAABB = aabb

	self.shapesAABB2 = _AxisAlignedBox.new()
	self.isAABBDirty = true

	self.actor.mass = 0
	local actordata = self:getActorsData() or {}

	if self.data.physX.disable then
		self.shapesAABB:initNull()
		return
	end

	self.node.transform:getScaling(helpscale)

	-- 用于改变transform后更新actor
	local actorscale = self:getActorScale()
	actorscale:set(helpscale)

	local s = helpscale

	local mirrorx, mirrory, mirrorz = s.x < 0, s.y < 0, s.z < 0
	local ssx = math.abs(s.x)
	local ssy = math.abs(s.y)
	local ssz = math.abs(s.z)

	local center = Container:get(_Vector3)
	local size = Container:get(_Vector3)
	local mat = Container:get(_Matrix3D)

	local aabb2 = _AxisAlignedBox.new()
	for i, v in ipairs(actordata) do
		local shape = self.actor:addShape(_PhysicsShape.Cube)

		shape:collisionGroup(0x1, 0xffff)
		shape:queryGroup(0x1, 0xffff)

		shape.block = self
		shape.index = i
		shape.bindex = v.bindex
		shape.sgindex = v.sgindex

		v.box:getCenter(center)
		v.box:getSize(size)

		local sx, sy, sz = size.x * 0.5 * ssx, size.y * 0.5 * ssy, size.z * 0.5 * ssz
		shape.size = _Vector3.new(sx, sy, sz)

		mat:setTranslation(center)
		if v.rot then mat:mulRotationLeft(v.rot.x, v.rot.y, v.rot.z, v.rot.w) end
		if ssx ~= 1 then mat:mulScalingRight(ssx, ssy, ssz) end

		if mirrorx or mirrory or mirrorz then
			mat:mirrorXYZ(mirrorx, mirrory, mirrorz)
		end
		shape.transform:set(mat)

		shape.queryFlag = self.node.pickFlag
		if v.jdata then
			shape.jointdata = v.jdata
			shape.queryFlag = Global.CONSTPICKFLAG.KNOT
		end
		table.insert(self.shapes, shape)

		self.actor.mass = self.actor.mass + sx * sy * sz

		--计算形状的包围盒
		if not v.rot then
			_AxisAlignedBox.union(v.box, aabb, aabb)
		else
			aabb2:setWithRotation(v.box, v.rot)
			_AxisAlignedBox.union(aabb2, aabb, aabb)
		end
	end
	local t2 = _tick()
	if t2 - t1 > 20 then
		print('refreshActorShape:', t2 - t1, self:getShape(), #self.shapes)
	end
end

block.refreshShape = function(self, s)
	if s then
		self.data.shape = s
	end

	self:refreshMesh()
	self:refreshActorShape()
end

block.setPaintVisible = function(self, visible)
	if self.data.paintInfo then return end
	local md5 = self.data.paintInfo:md5()
	if md5 == 0 then return end

	local paints = self:getPaintMeshs()
	for i, v in ipairs(paints) do
		v.visible = visible
	end
end

block.refreshPaint = function(self, resname, face)
	self.data.paintInfo.resname = resname
	if face then self.data.paintInfo.face = face end
	self:refreshMesh()
end

block.refreshPaint2 = function(self, paint)
	if paint then
		--paint:saveToData(self.data.paintInfo)
		self.data.paintInfo:set(paint)
		self:refreshMesh()
	else
		self:clearPaintInfo()
	end
end

block.clearPaintInfo = function(self)
	self.data.paintInfo:set()
	self:refreshMesh()
end

block.refreshPaintFace = function(self, face)
	self.data.paintInfo.face = face

	self:resetPaintTransform(self.data.paintInfo)
	self:refreshMesh()
end

block.resetPaintTransform = function(self, paintinfo)
	if not paintinfo then return end
	paintinfo.translation:set(0, 0, 0)
	paintinfo.scale:set(1, 1, 1)
	paintinfo.rotate:set(0, 0, 0, 0)
end

-- block.refreshPaintFaceByZ = function(self, img)
-- 	if not self.node then return end
-- 	local axisZ = Container:get(_Vector3)
-- 	axisZ:set(0, 0, 1)
-- 	Global.getRotaionAxis(axisZ, self.node.transform, axisZ)

-- 	local face = Global.getNearestAxisType(axisZ)
-- 	self:refreshPaint(img, face)
-- end

block.getPaintMeshs = function(self)
	self:refreshPaintMeshs()

	return self.paintMeshs
end

block.refreshPaintMeshs = function(self)
	if not self.mesh then return end
	self.paintMeshs = Block.getPaintMeshs(self.mesh)
end

-- block.movePaint = function(self, dir, step)
-- 	local axis = Global.typeToAxis(Global.dir2AxisType(dir, Global.AXISTYPE.Z))
-- 	local stepvec = axis:mul(step)

-- 	Global.getRotaionAxisInverse(stepvec, self.node.transform, stepvec)

-- 	_Vector3.add(self.data.paintInfo.translation, stepvec, self.data.paintInfo.translation)
-- 	self:refreshMesh()
-- end

-- block.rotatePaint = function(self, r)
-- 	local face = self.data.paintInfo.face
-- 	local axis = Global.typeToAxis(Global.AXISTYPE.Z)
-- 	Global.getRotaionAxisInverse(axis, self.node.transform, axis)
-- 	local m = axis.x + axis.y + axis.z
-- 	if face == Global.AXISTYPE.Y or face == Global.AXISTYPE.NY then m = -m end
-- 	if m < 0 then r = -r end
-- 	local curr = self.data.paintInfo.rotate.w - r
-- 	self.data.paintInfo.rotate:set(axis, curr)
-- 	self:refreshMesh()
-- end

-- block.scalePaint = function(self, scale)
-- 	local face = self.data.paintInfo.face
-- 	if face == Global.AXISTYPE.X or face == Global.AXISTYPE.NX then
-- 		self.data.paintInfo.scale:set(1, scale, scale)
-- 	elseif face == Global.AXISTYPE.Y or face == Global.AXISTYPE.NY then
-- 		self.data.paintInfo.scale:set(scale, 1, scale)
-- 	elseif face == Global.AXISTYPE.Z or face == Global.AXISTYPE.NZ then
-- 		self.data.paintInfo.scale:set(scale, scale, 1)
-- 	end

-- 	self:refreshMesh()
-- end

block.changePaintImage = function(self, image)
	_G.Block.changePaintImage(self.mesh, image)
end

block.isDummy = function(self)
	return self.node and self.node.mesh and self.node.mesh.isDummy or self.isdummyblock
end

block.getPaintInfo = function(self)
	return self.data.paintInfo
end

block.getAssumeQuality = function(self)
	return self.data.assumeQuality or nil
end

block.getBrickCount = function(self)
	local bd = Block.getHelperData(self.data.shape, self.data.subshape)
	return bd.brickcount
end

block.getQuality = function(self)
	if self.data.material == 1 then
		return self.data.mtlmode == Global.MTLMODE.EMISSIVE and 4 or 1
	end

	for i, v in ipairs(Global.BrickQuality) do
		local mtls = v.mtls
		for ii, m in ipairs(mtls) do
			if m.material == self.data.material then
				return i
			end
		end
	end
end

block.getColor = function(self)
	return Block.convertColor(self.data.color)
end
block.setColor = function(self, c, norefresh)
	if self.data.color == c then return end

	if c then
		self.data.color = c
	end

	if not norefresh then
		self:refreshMesh()
	end
end

block.getRoughness = function(self)
	return self.data.roughness
end
block.setRoughness = function(self, r, norefresh)
	if self.data.roughness == r then return end

	if r then
		self.data.roughness = r
	end

	if not norefresh then
		self:refreshMesh()
	end
end

block.getMtlMode = function(self)
	return self.data.mtlmode
end
block.setMtlMode = function(self, mode, norefresh)
	if self.data.mtlmode == mode then return end

	self.data.mtlmode = mode

	if not norefresh then
		self:refreshMesh()
	end
end
block.getMaterial = function(self)
	return self.data.material
end
block.setMaterial = function(self, m, norefresh)
	if self.data.material == m then return end
	if m then
		self.data.material = m
	end

	if not norefresh then
		self:refreshMesh()
	end
end

block.getMaterialBatch = function(self)
	local mtl = {}
	mtl.color = self:getColor()
	mtl.roughness = self:getRoughness()
	mtl.mtlmode = self:getMtlMode()
	mtl.material = self:getMaterial()

	return mtl
end

block.setMaterialBatch = function(self, data)
	self:setMaterial(data.material, true)
	self:setMtlMode(data.mtlmode, true)
	self:setColor(data.color, true)
	self:setRoughness(data.roughness, true)

	self:refreshMesh()
end

block.getShape = function(self)
	return self.data.shape
end

block.setShape = function(self, s)
	self:refreshShape(s)
end
block.getSubShape = function(self)
	return self.data.subshape
end
block.setSubShape = function(self, s)
	if s then
		self.data.subshape = s
	end

	self:refreshMesh()
	self:refreshActorShape()
end

block.getBlockType = function(self)
	return self:getFuncflagValue('blocktype')
end

block.isDungeonBlock = function(self, withcopybox)
	local blocktype = self:getBlockType()
	return Global.isSceneType(blocktype) or (withcopybox and (self.markerdata and self.markerdata.type == 'copybox'))
end

block.setContent = function(self, key, value)
	if self.rtdata.available == false then return end
	self.content[key] = value
	if key == 'number' then
		local number = tonumber(value)
		if number then
			self.rtdata.subshape = number
			self.node.mesh = Block.getBlockMesh(self.data.shape, self.rtdata.subshape, self.data.material, self:getColor(), self:getRoughness(), self.data.mtlmode, self.data.paintInfo)
		end
	end
end
block.getContent = function(self, key)
	return self.content[key]
end
block.setName = function(self, name)
	self.name = name
end

block.hasMirror = function(self)
	local tf = self.node.transform
	tf:getScaling(helpvec)
	return helpvec.x < 0 or helpvec.y < 0 or helpvec.z < 0
end

block.onChangeScale = function(self)
	self:refreshActorShape()
end

block.formatMatrix = function(self)
	self.node.transform:formatMatrix()

	self.node.transform:getScaling(helpscale)
	local actorscale = self:getActorScale()
	if helpscale.x ~= actorscale.x or helpscale.y ~= actorscale.y or helpscale.z ~= actorscale.z then
		self:onChangeScale()
	end

	local scene = self:getScene()
	if scene then
		local groups = scene:getGroups()
		for i, v in ipairs(groups or {}) do
			if v:indexBlock(self) ~= -1 then
				v:setNeedUpdateBoundBox()
			end
		end
	end

	self.isAABBDirty = true
end

block.updateSpace = function(self)
	self:formatMatrix()

	local s = self.data.space
	local tf = self.node.transform

	tf:getScaling(s.scale)
	tf:getRotation(s.rotation)
	tf:getTranslation(s.translation)
end

_SceneNode.getAABB = function(self, aabb, mat)
	mat = mat or self.transform

	local ab = self.mesh:getBoundBox()
	local minPoint = Container:get(_Vector3)
	minPoint:set(ab.x1, ab.y1, ab.z1)
	local maxPoint = Container:get(_Vector3)
	maxPoint:set(ab.x2, ab.y2, ab.z2)
	mat:apply(minPoint, minPoint)
	mat:apply(maxPoint, maxPoint)

	aabb.min.x = math.min(minPoint.x, maxPoint.x)
	aabb.min.y = math.min(minPoint.y, maxPoint.y)
	aabb.min.z = math.min(minPoint.z, maxPoint.z)

	aabb.max.x = math.max(minPoint.x, maxPoint.x)
	aabb.max.y = math.max(minPoint.y, maxPoint.y)
	aabb.max.z = math.max(minPoint.z, maxPoint.z)
	Container:returnBack(minPoint, maxPoint)
end

_SceneNode.getAABBTop2DPoint = function(self, vec)
	local ab = Container:get(_AxisAlignedBox)
	if not self.Height then
		local aabb = self.mesh:getBoundBox()
		self.Height = aabb.z2 - aabb.z1 + 0.2
	end
	local p = Container:get(_Vector3)
	p:set(0, 0, self.Height)
	self.transform:apply(p, p)
	_rd:projectPoint(p.x, p.y, p.z, vec)

	Container:returnBack(ab)
end

local temp_vec1 = _Vector2.new()
local name_bg = _Image.new('name_bg.png')
local emoji_bg = _Image.new('emoji_bg.png')
local emoji_color = _Color.new(1, 1, 1, 1)
_SceneNode.drawEmoji = function(self)
	local showEmoji = self.expimg and self.expimg.tick > os.now()
	if showEmoji or self.charactername then
		self:getAABBTop2DPoint(temp_vec1)

		if self.charactername then
			name_bg:drawImage(temp_vec1.x - name_bg.w / 2, temp_vec1.y - name_bg.h / 2)
			Global.Character.defaultFont:drawText(temp_vec1.x, temp_vec1.y, self.charactername, _Font.hCenter + _Font.vCenter)
		end

		if showEmoji and (self.expimg.resname ~= '' or self.expimg.isDB) then
			local r = (self.expimg.tick - os.now()) / (self.expimg.duration or 3000)
			emoji_color.a = Global.Curves.fadeinout:getValue(r).y
			if not self.expimg.nobg then
				emoji_bg:drawImage(temp_vec1.x - emoji_bg.w / 2, temp_vec1.y - emoji_bg.h, temp_vec1.x + emoji_bg.w / 2, temp_vec1.y, emoji_color:toInt())
			end

			local lpos = temp_vec1.x - self.expimg.w / 2
			local tpos = temp_vec1.y - self.expimg.h
			local rpos = temp_vec1.x + self.expimg.w / 2
			local bpos = temp_vec1.y

			local maxw = rpos - lpos
			local maxh = bpos - tpos
			if self.expimg.resname:find('fame.png') then
				local rtick = self.expimg.tick
				local duration = 500
				local r = 0
				local t = rtick - os.now()
				if self.expimg.delay and t > duration then
					emoji_color.a = 1.0 - (t - duration) / self.expimg.delay
				else
					r = 1.0 - t / duration
					emoji_color.a = Global.Curves.fadeout:getValue(r).y
				end

				local ui = Global.CoinUI.ui
				local uix = ui.coin._x
				local uiy = ui.coin._y
				local uiw = ui.coin._width
				local uih = ui.coin._height

				lpos = lpos - (lpos - uix) * r
				tpos = tpos - (tpos - uiy) * r

				maxw = maxw - (maxw - uiw) * r
				maxh = maxh - (maxh - uih) * r
				rpos = lpos + maxw
				bpos = tpos + maxh
			end

			self.expimg:drawImage(lpos, tpos, rpos, bpos, emoji_color:toInt())
		end
	end
end

block.getAABB = function(self, aabb)
	self.node:getAABB(self.aabb)
	if aabb then
		aabb:set(self.aabb)
	end
	return self.aabb
end

block.setAABBSkipped = function(self, skip)
	self.isAABBSkipped = skip
end

block.getAABBSkipped = function(self)
	return self.isAABBSkipped
end

block.getShapeAABB = function(self, aabb, ignoreTransform)
	local ab = self.shapesAABB
	aabb.min:set(ab.min)
	aabb.max:set(ab.max)

	if not ignoreTransform then
		aabb:mul(self.node.transform)
	end
end

block.getShapeAABB2 = function(self, forceupdate)
	if self.isAABBDirty or forceupdate then
		self:getShapeAABB(self.shapesAABB2)
		self.isAABBDirty = false
	end

	return self.shapesAABB2
end

-- block.getInitAABB = function(self, aabb)
-- 	local bd = Block.getHelperData(self.data.shape)
-- 	aabb:initCenterAndSize(bd.boxcenter, bd.boxsize)

-- 	return false
-- end

block.getAlignedShapeAABB = function(self, ab, nodemat, align)
	self:getInitAABB(ab)
	ab:mul(nodemat or self.node.transform)

	if align then ab:alignSize(align) end
end

-- block CON and group
block.getBlockGroup = function(self, mode)
	if not self.blockGroup then
		local bb = self.node.scene.BuildBrick
		local g = bb:newGroup(true)
		g:addBlock(self)
	end

	local p = self.blockGroup
	if mode == 'root' then
		return p:getRoot()
	elseif mode == 'tempRoot' then
		return p:getTempRoot()
	elseif mode == 'lock' then
		return p:getLockParent()
	else
		return p
	end
end

block.addNeighbor = function(self, b)
	self.neighbors[b] = true
	b.neighbors[self] = true
end

block.delNeighbor = function(self, b)
	self.neighbors[b] = nil
	b.neighbors[self] = nil
end

block.addNeighbors = function(self, bs)
	for i, b in ipairs(bs) do
		self:addNeighbor(b)
	end
end

block.clearNeighbors = function(self, keeps)
	for b in pairs(self.neighbors) do
		if not keeps or not keeps[b] then
			self:delNeighbor(b)
		end
	end
end

block.addOverlap = function(self, b)
	self.overlaps[b] = true
	b.overlaps[self] = true

	self:checkBlocking()
	b:checkBlocking()
end

block.delOverlap = function(self, b)
	self.overlaps[b] = nil
	b.overlaps[self] = nil

	self:checkBlocking()
	b:checkBlocking()
end

block.addOverlaps = function(self, bs)
	for i, b in ipairs(bs) do
		self:addOverlap(b)
	end
end

block.clearOverlaps = function(self, keeps)
	for b in pairs(self.overlaps) do
		if not keeps or not keeps[b] then
			self:delOverlap(b)
		end
	end
end

block.addConnects = function(self, b1, s1, s0)
	self.connects[b1] = {b1 = self, b2 = b1, s1 = s0, s2 = s1}
	b1.connects[self] = {b1 = b1, b2 = self, s1 = s1, s2 = s0}
end

block.delConnects = function(self, b)
	self.connects[b] = nil
	b.connects[self] = nil
end

block.clearConnects = function(self, keeps)
	for b in pairs(self.connects) do
		if not keeps or not keeps[b] then
			self:delConnects(b)
		end
	end
end

-- block.refreshFuncflags = function(self, flags)
-- 	if not flags then return end
-- 	for k, v in pairs(flags) do
-- 		self:switchFuncflags(k, v)
-- 	end
-- end

-- block.switchFuncflags = function (self, funcname, value)
-- 	self.funcflags[funcname] = value
-- end

-- block.clearFuncflags = function(self)
-- 	self.funcflags = {}
-- end

-- block.updateFuncflags = function(self, e)
-- 	for fn, op in pairs(self.funcflags) do
-- 		if op ~= nil then
-- 			local func = self.funcflagcbs[fn]
-- 			if func then
-- 				func(op)
-- 			end
-- 		end
-- 	end
-- end

block.move = function(self, dx, dy, dz)
	self.data.space.translation.x = self.data.space.translation.x + dx
	self.data.space.translation.y = self.data.space.translation.y + dy
	self.data.space.translation.z = self.data.space.translation.z + dz
	self:resetSpace()
end
block.moveUp = function(self, dz)
	self:move(0, 0, dz)
end
block.setParent = function(self, p)
	if p then
		if not self.rtdata.isEditing then
			self.node.transform.parent = nil
		end

		-- local mat = Container:get(_Matrix3D)
		-- mat:set(p)
		-- mat:inverse()
		-- self.node.transform:mulRight(mat)
		--Container:returnBack(mat)

		--self.node.transform.parent = p
		self.node.transform:bindParent(p)
		self.rtdata.isEditing = true
	else
		self.node.transform:unbindParent()
		--if self.node.transform.parent then
			--self.node.transform.parent = nil
			--self:resetSpace()
		--end
		self.rtdata.isEditing = false
		--self.node.transform.parent = nil
	end
end
block.getBlocks = function(self)
	return {self}
end

block.updateFace = function(self, direction, time)
	local mat = Container:get(_Matrix3D)
	mat:setFaceTo(0, -1, 0, direction.x, direction.y, 0)
	local a1 = self.node.transform:getRotationZ()
	local a2 = mat:getRotationZ()
	local da = a2 - a1
	if math.abs(da) > math.pi then
		da = da > 0 and (da - math.pi * 2) or (math.pi * 2 + da)
	end
	self.node.transform:mulRotationZLeft(da, time)
	Container:returnBack(mat)
end
-- 角色是否在房间内
block.isInsideHouse = function(self)
	if not Global.role and not Global.House and not Global.House.miniab and not Global.House.realab then
		return false
	end

	local ab = Global.role.insideHouseOld and Global.House.realab or Global.House.miniab
	local miny = Global.role.insideHouseOld and ab.min.y or ab.min.y + 1
	local blockpos = Container:get(_Vector3)
	self.node.transform:getTranslation(blockpos)
	local inside = ab.min.x < blockpos.x and ab.max.x > blockpos.x and miny < blockpos.y and ab.max.y > blockpos.y
	Container:returnBack(blockpos)

	return inside
end
block.disablePhysicActor = function(self, disable)
	self.data.physX.disable = disable
	if disable == false and #self.shapes == 0 then
		self:refreshAll()
	end
end
-- 隐藏物理效果
block.enablePhysic = function(self, enable)
	if not enable then
		-- 取消物理效果
		for i, v in ipairs(self.shapes) do
			v.trigger = true
		end
		self.actor.kinematic = true
	else
		-- 还原物理效果
		for i, v in ipairs(self.shapes) do
			v.trigger = self.data.physX.trigger
		end
		self.actor.kinematic = self.data.physX.kinematic
	end
	self.physic = enable
end

block.isNodeValid = function(self)
	local sen = self.node and self.node.scene
	return not not sen
end

block.isPhysic = function(self)
	return self.physic
end

-- 隐藏地块
block.setVisible = function(self, visible, physic)
	self.node.visible = visible

	-- TODO:
	-- self.actor.isVisble = visible
	if visible then
		self:addPickFlag(Global.CONSTPICKFLAG.NORMALBLOCK)
	else
		self:delPickFlag(Global.CONSTPICKFLAG.NORMALBLOCK)
	end

	if physic == nil then
		physic = visible
	end
	self:enablePhysic(physic)
end

block.setVisibleAndQuery = function(self, visible)
	self.node.visible = visible
	self:enableQuery(visible)
end

block.setBuildVisiable = function(self, show)
	if show then
		self:showTransparencyDummyMtl(false)
		self:setVisible(true)
	else
		if Global.showTranspanetDummy then
			self:showTransparencyDummyMtl(true)
			self:setVisible(true)
		else
			self:showTransparencyDummyMtl(false)
			self:setVisible(false)
		end
	end
end

block.getBuildVisiable = function(self)
	if not self.node.visible or self.showDummyMtl then
		return false
	end

	return true
end

-- 地块与角色距离
block.roleDistance = function(self, norefresh)
	if not Global.role then
		return 99999999
	end
	local rolepos = Container:get(_Vector3)
	local blockpos = Container:get(_Vector3)

	-- TODO:会动的block需要每帧刷新
	if not norefresh or not self.rdbb then
		if not self.rdbb then
			self.rdbb = _AxisAlignedBox.new()
		end
		self:getAABB(self.rdbb)
	end

	local ab = self.rdbb
	Global.role:getPosition(rolepos)
	self.node.transform:getTranslation(blockpos)
	local x, y, z = 0, 0, 0
	if rolepos.x >= ab.max.x then
		x = ab.max.x
	elseif rolepos.x <= ab.min.x then
		x = ab.min.x
	else
		x = rolepos.x
	end
	if rolepos.y >= ab.max.y then
		y = ab.max.y
	elseif rolepos.y <= ab.min.y then
		y = ab.min.y
	else
		y = rolepos.y
	end
	if rolepos.z >= ab.max.z then
		z = ab.max.z
	elseif rolepos.z <= ab.min.z then
		z = ab.min.z
	else
		z = rolepos.z
	end
	blockpos:set(x, y, z)
	local dis = _Vector3.distance(rolepos, blockpos)
	dis = math.max(dis, 0.01)
	Container:returnBack(rolepos, blockpos)
	return dis
end

block.setMovement = function(self, mm)
	if mm then
		print(mm)
		self.movement = {dir = _Vector3.new()}
		self.movement.dir:set(mm.dir)
		self.movement.disableturnface = mm.disableturnface
		self.movement.curvetime = mm.curvetime
		self.movement.cv = mm.cv
		self:createCCT()
	else
		self.movement = nil
		self:releaseCCT()
	end
end

block.createCCT = function(self)
	if self.cct then return end
	Global.sen:delActor(self.actor)
	self.cct = CreateCCTByShape(Global.sen, self.node)
	self.cct.block = self
	local ab = Container:get(_AxisAlignedBox)
	self:getAABB(ab)
	self:moveTranslation(0, 0, (ab.max.z - ab.min.z) / 2, 0)
	self:updateSpace()
	local t = self.data.space.translation
	self.cct.position:set(t.x, t.y, t.z)
	self.cct.enableControllerHit = true

	self.cct:collisionGroup(0x1, 0xffff)
	self.cct:queryGroup(0x1, 0xffff)

	Container:returnBack(ab)
end

block.releaseCCT = function(self)
	Global.sen:delController(self.cct)
	self.cct = nil
end

block.updateMovement = function(self, e)
	if self.movement == nil or self.enableMovement ~= true or self.cct == nil then return end

	local flag = self.cct.collisionFlag

	local fall = false
	if _and(flag, 1) > 0 then
		_Vector3.mul(self.movement.dir, -1, self.movement.dir)
		if self.movement.disableturnface ~= true then
			self:updateFace(self.movement.dir, 200)
		end
	elseif _and(flag, 4) <= 0 then
		fall = true
	end

	if self.movement.curvetime then
		self.rtdata.cvz = self.rtdata.cvz or self.movement.cv
		if _and(flag, 2) > 0 then
			self.rtdata.cvz = -self.movement.cv
			self.rtdata.curvecurrent = 0
		elseif _and(flag, 4) > 0 then
			self.rtdata.cvz = self.movement.cv
			self.rtdata.curvecurrent = 0
		end
	end

	local v = Container:get(_Vector3)
	v:set(self.movement.dir)
	_Vector3.mul(v, e / 100, v)
	if self.rtdata.vz and self.rtdata.vz > 0 then
		-- zspeed
		local v0 = self.rtdata.vz
		local dis = v0 * e - 0.5 * G * e * e
		self.rtdata.vz = self.rtdata.vz - G * e
		if math.abs(self.rtdata.vz) > FALL_MAX then
			self.rtdata.vz = FALL_MAX * -1
		end
		v.z = dis
	elseif self.movement.curvetime then
		if self.rtdata.cvz > 0 then
			local c = self.rtdata.curvecurrent or 0
			c = c + e
			if c > self.movement.curvetime then
				self.rtdata.cvz = -self.movement.cv
				e = self.movement.curvetime - c
				c = 0
			end
			self.rtdata.curvecurrent = c
		end
		v.z = self.rtdata.cvz * e
	elseif fall then
		v.z = -0.2
	end
	self.cct:input(v)
	Container:returnBack(v)
	local p = self.cct.position
	local t = self.data.space.translation
	self:moveTranslation(p.x - t.x, p.y - t.y, p.z - t.z, 0)
	self:updateSpace()
end

block.updateCamera = function(self, e)
	if self.cameralook ~= true then return end

	local aabb = Container:get(_AxisAlignedBox)
	self:getAABB(aabb)
	local vec = Container:get(_Vector3)
	aabb:getCenter(vec)
	local camera = Global.CameraControl:get()
	camera:moveLook(vec)
	Container:returnBack(aabb, vec)
end

block.attr_get = function(self, key)
	return self.attrs[key]
end

block.attr_set = function(self, key, value)
	self.attrs[key] = value
end

-- local temp_vec1 = _Vector3.new()
-- block.updatePos = function(self, e)
-- 	temp_vec1:set(0,0,0)
-- 	if Global.AttrManager.calc_speed(self, temp_vec1, e) then
-- 		self:moveTranslation(temp_vec1.x, temp_vec1.y, temp_vec1.z)
-- 		self:update_role_pos(temp_vec1)
-- 		self:check_collision(temp_vec1)
-- 	end
-- end
-- 平台带着人走
local temp_vec3_1 = _Vector3.new()
block.update_role_pos = function(self, v)
	if not self.rtdata.collision_data then
		return
	end
	for target in next, self.rtdata.collision_data do
		if target.aid then
			target:set_outer_input(v)
		end
	end
end

block.updateTrack = function(self, e)
	--self:updatePos(e)
	if self.track == nil or self.track.enable == false then return end
	local track = self.track

	local data = track.data[track.currentIndex]
	local time = data and data.time or 0

	track.current = track.current + e

	while track.current >= time and time ~= -1 do
		track.currentIndex = track.currentIndex + 1
		if track.currentIndex > #track.data then
			if track.loop then
				track.currentIndex = 1
				for i, v in ipairs(track.data) do
					if v.move then
						if v.move.stepx then
							v.move.x = v.move.x + v.move.stepx
							if v.move.minx then
								v.move.x = math.max(v.move.x, v.move.minx)
							end
							if v.move.maxx then
								v.move.x = math.min(v.move.x, v.move.maxx)
							end
						end
						if v.move.stepy then
							v.move.y = v.move.y + v.move.stepy
							if v.move.miny then
								v.move.y = math.max(v.move.y, v.move.miny)
							end
							if v.move.maxy then
								v.move.y = math.min(v.move.y, v.move.maxy)
							end
						end
						if v.move.stepz then
							v.move.z = v.move.z + v.move.stepz
							if v.move.minz then
								v.move.z = math.max(v.move.z, v.move.minz)
							end
							if v.move.maxz then
								v.move.z = math.min(v.move.z, v.move.maxz)
							end
						end
					end
				end
			end
		end
		if track.current >= time then
			track.current = track.current - time
		end
		data = track.data[track.currentIndex]
		if data then
			time = data.time
			if data.visible ~= nil then
				self:setVisible(data.visible)
			end
		else
			time = -1
		end
	end
	data = track.data[track.currentIndex]
	if data then
		if data.move then
			local x = data.move.x * e / data.time
			local y = data.move.y * e / data.time
			local z = data.move.z * e / data.time
			self:moveTranslation(x, y, z)
		end
		if data.rotate then
			local r = data.rotate * e / data.time
			self.node.transform:mulRotationXLeft(r)
		end
	end
end

block.setTrack = function(self, track)
	if track.data == nil or #track.data == 0 then return end

	self.track = {data = {}, loop = track.loop, enable = true}
	if track.enable ~= nil then
		self.track.enable = track.enable
	end
	for i, v in ipairs(track.data) do
		local nv = {rotate = v.rotate, visible = v.visible, time = v.time, curve = v.curve}
		if v.move then
			nv.move = {}
			for p, q in pairs(v.move) do
				nv.move[p] = q
			end
		end
		self.track.data[i] = nv
	end
	self.track.current = 0
	self.track.currentIndex = 0
	self.node.needUpdate = true
end

block.enableTrack = function(self, enable)
	if self.track == nil then return end
	self.track.enable = enable
end

-- 事件 ------------------------------------------------------------------
block.rebound = function(self, z)
	self.rtdata.vz = VZ_INIT * z
end

-- real render
block.render = function(self, e)
	if self.updateDfByRender then
		if not self.df_invokeDistabce or self.df_invokeDistabce and self:roleDistance() < self.df_invokeDistabce then
			self:updateDynamicEffect(e)
		end
	end
end

block.update = function(self, e)
	if not self.rtdata.available then return end

	self.node.scene:add_update_block(self)

	self:updatePos(e)
	--self:updateTrack(e)
	self:updateMovement(e)

	self:updateCamera(e)

	if self.backgroundtouchable then
		local bab = Container:get(_AxisAlignedBox)
		self:getShapeAABB(bab)
		local ab = Container:get(_AxisAlignedBox)
		for i, v in pairs(Global.EntityManager.entitys) do
			if v.cct then
				v:getAABB(ab)
				if bab:checkIntersect(ab) then
					if self.rtdata.hitdata[v] == nil then
						self.rtdata.hitdata[v] = {}
					end
					self.rtdata.hitdata[v].isTouched = true
				end
			end
		end
		if Global.role.cct then
			Global.role:getAABB(ab)
			if bab:checkIntersect(ab) then
				if self.rtdata.hitdata[Global.role] == nil then
					self.rtdata.hitdata[Global.role] = {}
				end
				self.rtdata.hitdata[Global.role].isTouched = true
			end
		end

		-- local cs = Global.sen:getControllers()
		-- for i, v in ipairs(cs) do
		-- 	if v ~= Global.role.cct then
		-- 		v.block:getAABB(ab)
		-- 		if bab:checkIntersect(ab) then
		-- 			self.rtdata.isControllerTouched = true
		-- 			self.rtdata.touchedController = v
		-- 			break
		-- 		end
		-- 	end
		-- end
		Container:returnBack(bab, ab)
	end

	self:update_collide(e)
	for role, d in pairs(self.rtdata.hitdata) do
		local triggerd = false
		if d.isPushupOld and not d.isPushup then
			if self.onDown then
				self.onDown(role)
				triggerd = true
			end
		elseif not d.isPushupOld and d.isPushup then
			if self.onPushup then
				self.onPushup(role)
				triggerd = true
			end
		end

		if d.isPressedOld and not d.isPressed then
			if self.onUp then
				self.onUp(role)
				triggerd = true
			end
		elseif not d.isPressedOld and d.isPressed then
			if self.onPress then
				self.onPress(role)
				triggerd = true
			end
		end

		if d.isTouched and not d.isTouchedOld then
			if self.onTouch and triggerd == false then
				self.onTouch(role)
			end
			self.touchTick = e
		elseif not d.isTouched and d.isTouchedOld then
			if self.onDetach then
				self.onDetach(role)
			end
			self.touchTick = nil
		elseif d.isTouched and d.isTouchedOld then
			if self.touchTick then
				self.touchTick = self.touchTick + e
				if self.longTouchTime and self.onLongTouch and triggerd == false and self.touchTick >= self.longTouchTime then
					self.onLongTouch(role)
				end
			end
		-- 靠近且不接触
		end

		local controller = role
		if d.isControllerTouched and not d.isControllerTouchedOld then
			if self.onControllerTouch then
				self:onControllerTouch(controller.block)
			end
			if controller.block and controller.block.onControllerTouch then
				controller.block:onControllerTouch(self)
			end
		elseif not d.isControllerTouched and d.isControllerTouchedOld then
			if self.onControllerDetach then
				self:onControllerDetach(controller.block)
			end
			if controller.block and controller.block.onControllerDetach then
				controller.block:onControllerDetach(self)
			end
		end

		d.isPushupOld = d.isPushup
		d.isPushup = false
		d.isPressedOld = d.isPressed
		d.isPressed = false
		d.isTouchedOld = d.isTouched
		d.isTouched = false
		d.isControllerTouchedOld = d.isControllerTouched
		d.isControllerTouched = false
	end
	
	local isRenderred = self.frameToken == Global.FrameToken - 1
	if not isRenderred then return end

	local d = self.rtdata
	if self.node.visible and self.onApproachSuccess then
		self:onApproachSuccess()
		if d.isApproached and not d.isApproachedOld then
			if self.onApproach then
				self.onApproach()
			end
		end
	end
	if self.onFarAwaySuccess then
		self:onFarAwaySuccess()
		-- print('[Block.update]', d.isFarAway, d.isFarAwayOld)
		if d.isFarAway and not d.isFarAwayOld then
			if self.onFarAway then
				self.onFarAway()
			end
		end
	end
	d.isApproachedOld = d.isApproached
	d.isApproached = false
	d.isFarAwayOld = d.isFarAway
	d.isFarAway = false
end
block.update2 = function(self, e)
	if not self.updateDfByRender then
		self:updateDynamicEffect(e)
	end
end
block.syncShapeHit = function(self)
	-- print('sss', debug.traceback())
	if self.onPress or self.onUp or self.onTouch or self.onLongTouch or self.onDetach or self.onPushup or self.onDown or self.onControllerTouch or self.onControllerDetach then
		self.node.needUpdate = true
		for _, v in ipairs(self.shapes) do
			v:onCollisionWithController(function(shape, controller, x, y, z, dx, dy, dz)
				if controller.role == nil then
					if self.rtdata.hitdata[controller] == nil then
						self.rtdata.hitdata[controller] = {}
					end
					local hdata = self.rtdata.hitdata[controller]
					hdata.isControllerTouched = true
					return
				end

				if self.rtdata.hitdata[controller.role] == nil then
					self.rtdata.hitdata[controller.role] = {}
				end
				local hdata = self.rtdata.hitdata[controller.role]
				hdata.isTouched = true
				if dx == 0 and dy == 0 then
					if dz >= 0 then
						hdata.isPushup = true
					else
						hdata.isPressed = true
					end
				end
			end)
		end
	else
		self.node.needUpdate = false
		for _, v in ipairs(self.shapes) do
			v:onCollisionWithController()
		end
	end
end
block.registerAction = function(self, action)
	action:onRegister(self)
end
block.logoutAction = function(self, action)
	action:onLogout(self)
end
block.registerPress = function(self, func)
	self.onPress = func -- todo : addPushupEvent
	self:syncShapeHit()
end
block.registerUp = function(self, func)
	self.onUp = func
	self:syncShapeHit()
end
block.addPushupEvent = function(self, func)
	self.onPushups = self.onPushups or {}
	table.insert(self.onPushups, func)
	self:registerPushup(function(role)
		for i, v in ipairs(self.onPushups) do
			v(role)
		end
	end)
end
block.indexPushupEvent = function(self, func)
	for i, v in ipairs(self.onPushups) do
		if v == func then return i end
	end
	return -1
end
block.delPushupEvent = function(self, func)
	self.onPushups = self.onPushups or {}
	table.remove(self.onPushups, self:indexPushupEvent(func))
	if #self.onPushups == 0 then
		self:registerPushup()
	end
end
block.registerPushup = function(self, func)
	self.onPushup = func
	self:syncShapeHit()
end
block.addDownEvent = function(self, func)
	self.onDowns = self.onDowns or {}
	table.insert(self.onDowns, func)
	self:registerDown(function(role)
		for i, v in ipairs(self.onDowns) do
			v(role)
		end
	end)
end
block.indexDownEvent = function(self, func)
	for i, v in ipairs(self.onDowns) do
		if v == func then return i end
	end
	return -1
end
block.delDownEvent = function(self, func)
	self.onDowns = self.onDowns or {}
	table.remove(self.onDowns, self:indexDownEvent(func))
	if #self.onDowns == 0 then
		self:registerDown()
	end
end
block.registerDown = function(self, func)
	self.onDown = func
	self:syncShapeHit()
end
block.registerLongTouch = function(self, func, time)
	self.onLongTouch = func
	self.longTouchTime = time or 500
	self:syncShapeHit()
end
block.registerTouch = function(self, func)
	self.onTouch = func
	self:syncShapeHit()
end
block.registerDetach = function(self, func)
	self.onDetach = func
	self:syncShapeHit()
end
block.registerControllerTouch = function(self, func)
	self.onControllerTouch = func
	self:syncShapeHit()
end
block.registerControllerDetach = function(self, func)
	self.onControllerDetach = func
	self:syncShapeHit()
end
block.registerApproach = function(self, action, func)
	self.onApproach = func
	if self.onApproach then
		self.node.needUpdate = true
		self.onApproachSuccess = function(self)
			if self:roleDistance(true) <= action:getDistance() then
				self.rtdata.isApproached = true
			else
				self.rtdata.isApproached = false
			end
		end
	else
		self.node.needUpdate = false
		self.onApproachSuccess = nil
	end
end
block.registerFarAway = function(self, action, func)
	self.onFarAway = func
	if self.onFarAway then
		self.node.needUpdate = true
		self.onFarAwaySuccess = function(self)
			-- print('[block.onFarAwaySuccess]', self:roleDistance(), action:getDistance())
			if self:roleDistance(true) >= action:getDistance() then
				self.rtdata.isFarAway = true
			else
				self.rtdata.isFarAway = false
			end
		end
	else
		self.node.needUpdate = false
		self.onFarAwaySuccess = nil
	end
end
block.registerPick = function(self, func)
	self.onPick = func
end
block.switchAvailable = function(self, available)
	self.rtdata.available = available
end
block.switchAnchor = function(self, anchor)
	self.rtdata.anchor = anchor
end
block.showHint = function(self, showhint, showedge)
	self.rtdata.showHint = showhint -- todo 去掉这个属性
	self.rtdata.showEdge = showedge
	self.node.isInsPostEdge = false
	-- local oi = Global.ObjectIcons[self.data.shape]
	-- if oi then
		-- self.hintImage = _Image.new(oi)
	-- end
end

block.updateGuidePfx = function(self)
	if self.rtdata.showGuide == false or self.guidepfx == nil then return end
	local ab = Container:get(_AxisAlignedBox)
	local v1 = Container:get(_Vector3)
	self:getAABB(ab)
	v1:set((ab.min.x + ab.max.x) / 2, (ab.min.y + ab.max.y) / 2, ab.max.z + 0.1)
	self.guidepfx.transform:setTranslation(v1)
	local scalef = math.min(1.4 / self:roleDistance(), 0.14)
	self.guidepfx.transform:mulScalingLeft(scalef, scalef, scalef)
	Container:returnBack(ab, v1)
	self.guidepfx.visible = self.node.visible
end

block.showGuide = function(self, showguide)
	if self.rtdata.showGuide == showguide then return end
	self.rtdata.showGuide = showguide
	if showguide then
		self.guidepfx = self:playPfx('tanhao.pfx')
		-- Global.Sound:play('ui_inte02')
		self:updateGuidePfx()
	else
		self:stopPfx('tanhao.pfx', true)
		self.guidepfx = nil
	end
end

local dummymtl = {}
dummymtl.color = 0xffffffff
dummymtl.roughness = 1
dummymtl.mtlmode = Global.MTLMODE.PAINT
--dummymtl.material = 1
dummymtl.material = 25
local dummybl = _Blender.new()
dummybl:blend(0x88ffffff)

block.showTransparencyDummyMtl = function(self, show)
	if show then
		self.showDummyMtl = show
		if not self.defaultBl then
			self.defaultBl = _Blender.new()
			self.defaultBl:blend(0x11ffffff)
		end
		--self:setDefualtMtlWithAlphaFilter(dummybl, dummymtl, 'alphadummy')
	else
		self.showDummyMtl = false
		self.defaultBl = nil
		--self:setDefualtMtlWithAlphaFilter(nil)
	end
end

block.changeTransparency = function(self, alpha, time, transparencyBlender, groupname)
	if self.node then
		alpha = math.clamp(alpha, 0, 1)
		if transparencyBlender then
			self.node.blender = transparencyBlender
		else
			if not self.node.transparencyBl then
				self.node.transparencyBl = _Blender.new()
			end
			self.node.blender = self.node.transparencyBl
		end

		self.node.isInsAlphaFilter = true
		local n = toint(alpha * 0xff)
		self.node.instanceGroup = groupname or ('transparency_' .. n)
		if alpha == self.rtdata.transparency then
			return
		end

		-- unit is second.
		if time then
			local destcolor = math.min(255, toint(255 * alpha)) * 0x1000000 + 0x00ffffff
			local srccolor = math.min(255, toint(255 * self.rtdata.transparency)) * 0x1000000 + 0x00ffffff
			self.node.blender:blend(srccolor, destcolor, time and time * 1000)
		else
			local destcolor = math.min(255, toint(255 * alpha)) * 0x1000000 + 0x00ffffff
			self.node.blender:blend(destcolor)
		end
		self.rtdata.transparency = alpha
	end
end
block.switchVisible = function(self, visible, physic)
	if not self.rtdata.available then return end

	self:setVisible(visible, physic)
end
block.isIntersect = function(self, target)
	local ab1 = Container:get(_AxisAlignedBox)
	local ab2 = Container:get(_AxisAlignedBox)
	self:getAABB(ab1)
	local blocks = target and target:getBlocks() or self:getScene().blocks
	for i, v in ipairs(blocks) do
		if v ~= self and v.node.visible then
			v:getAABB(ab2)
			if Block.isAABBIntersect(ab1, ab2) then
				Container:returnBack(ab1, ab2)
				return true, v
			end
		end
	end
	Container:returnBack(ab1, ab2)
	return false
end
block.CountBlocks = function(self, dir, targetgroup)
	local ab = Container:get(_AxisAlignedBox)
	self:getAABB(ab)
	ab.min.x = math.min(ab.min.x, ab.min.x + dir.x)
	ab.min.y = math.min(ab.min.y, ab.min.y + dir.y)
	ab.min.z = math.min(ab.min.z, ab.min.z + dir.z)
	ab.max.x = math.max(ab.max.x, ab.max.x + dir.x)
	ab.max.y = math.max(ab.max.y, ab.max.y + dir.y)
	ab.max.z = math.max(ab.max.z, ab.max.z + dir.z)
	local pos = Container:get(_Vector3)
	targetgroup:setBlocks({}, false)
	for i, v in ipairs(self:getScene().blocks) do
		if v ~= self and v.node.visible then
			v.node.transform:getTranslation(pos)
			if ab:checkInside(pos) then
				targetgroup:addBlock(v, false)
			end
		end
	end
	Container:returnBack(ab, pos)
end
block.bomb = function(self, range, time)
	if not self.rtdata.available then return end

	Block.blast({self}, range, time)
	self:switchAvailable(false)
end
block.startClock = function(self, clock)
	if not self.rtdata.available then return end
	clock:start()
end
block.getTransform = function(self)
	return self.node.transform
end
block.getMesh = function(self)
	return self.node.mesh
end
block.playSound = function(self, soundGroup)
	if not self.rtdata.available then return end

	local vec = Container:get(_Vector3)
	self.node.transform:getTranslation(vec)
	soundGroup:play(vec)
	if soundGroup.soundName == 'coin' then
		local pfx = _Particle.new('coin_001.pfx')
		pfx.transform:mulTranslationLeft(vec)
		self:getScene().pfxPlayer:play(pfx)
	end
	Container:returnBack(vec)
end
block.playPfx = function(self, pfxname, pmat)
	if not self.rtdata.available then return end
	local mat = _Matrix3D.new()
	mat:set(self.node.transform)
	if self.pfxs == nil then
		self.pfxs = {}
	end

	if pmat then
		mat:mulLeft(pmat)
	end

	if self.pfxs[pfxname] then
		local pfx = self.pfxs[pfxname]
		if pfx.isAlive then
			return pfx
		else
			self:stopPfx(pfxname)
		end
	end

	self.node.mesh.enableInstanceCombine = false
	local pfx = self:getScene().pfxPlayer:play(pfxname, pfxname, mat)
	self.pfxs[pfxname] = pfx
	return pfx
end
block.stopPfx = function(self, pfxname, stopnow)
	if not self.rtdata.available then return end

	if self.pfxs and self.pfxs[pfxname] then
		self.pfxs[pfxname]:stop(stopnow)
		self.node.mesh.enableInstanceCombine = true
		self.pfxs[pfxname] = nil
	end
end
block.startMoveMent = function(self, movement)
	if not self.rtdata.available then return end
	self:setDynamic(true)
	movement:start()
end
-- block.moveTranslation = function(self, dx, dy, dz, time, c)
-- 	self.node.transform:mulTranslationRight(dx, dy, dz, time)
-- 	if c then
-- 		self.node.transform:applyCurve(Global.Curves[c])
-- 	end
-- end
block.getAnchorBlock = function(self)
	if self.rtdata.anchor then
		return self
	end
end
block.buttonPress = function(self, dir, time)
	Block.applyButtonEffect({self}, dir, time)
end
block.startRotateMent = function(self, rotatement)
	if not self.rtdata.available then return end
	rotatement:start()
end
block.moveRotation = function(self, dx, dy, dz, tr, time)
	self.node.transform:mulRotationLeft(dx, dy, dz, tr, time)
end
block.moveRotationRight = function(self, dx, dy, dz, tr, time)
	self.node.transform:mulRotationRight(dx, dy, dz, tr, time)
end
block.setTrophy = function(self, enabled)
	self:getScene().GameData:setTrophy(self, enabled)
end
block.getActions = function(self)
	local actions = {}
	for i, v in ipairs(self.functions) do
		for p, q in ipairs(v.actions) do
			table.insert(actions, q)
		end
	end
	return actions
end
block.registerEvents = function(self)
	for i, v in ipairs(self:getActions()) do
		v:onRegister(self)
	end
end
block.logoutEvents = function(self)
	for i, v in ipairs(self:getActions()) do
		v:onLogout(self)
	end
end
block.initEvents = function(self)
	for i, v in ipairs(self.functions) do
		if #v.sourceactions == 0 then
			v:trigger()
		end
	end
end
block.addFunction = function(self, f, index)
	index = index or #self.functions + 1
	if self:indexFunction(f) == -1 then
		f.owner = self
		table.insert(self.functions, index, f)
	end
end
block.delFunction = function(self, f)
	f.owner = nil
	f:delFromSourceActions()
	table.remove(self.functions, self:indexFunction(f))
end
block.indexFunction = function(self, f)
	for i, v in ipairs(self.functions) do
		if v == f then
			return i
		end
	end
	return -1
end
block.getFunction = function(self, id)
	return self.functions[id]
end
block.loadActionFunctions = function(self, scene)
	for i, v in ipairs(self:getActions()) do
		if not v.loadedFunctions then
			local functions = v.functions
			v.functions = {}
			for p, q in ipairs(functions) do
				if q.typestr ~= 'Function' then
					local object = scene:getObjectByIndexInfo({groupid = q.groupid, blockid = q.blockid}) or self
					v:addFunction(object:getFunction(q.functionid))
				else
					v:addFunction(q)
				end
			end
			v.loadedFunctions = true
		end
		v:loadObjects(self, scene)
	end
end
------------------------------------------------------------------------
block.hasPickFlag = function(self, flag)
	return _and(self.node.pickFlag, flag) ~= 0
end

block.getPickFlag = function(self)
	return self.node.pickFlag or 0
end
block.setPickFlag = function(self, flag)
	self.node.pickFlag = flag
	self:setQueryFlag(flag)
end
block.addPickFlag = function(self, flag)
	self.node.pickFlag = _or(self.node.pickFlag, flag)
	self:setQueryFlag(self.node.pickFlag)
end
block.delPickFlag = function(self, flag)
--	print('delflag', flag, self.node.pickFlag)
	self.node.pickFlag = _and(self.node.pickFlag, _not(flag))
--	print('delend', self.node.pickFlag)
	self:setQueryFlag(self.node.pickFlag)
end
block.setQueryFlag = function(self, flag)
	--self.node.pickFlag = flag
	for i, v in ipairs(self.shapes) do
		v.queryFlag = flag
	end
end

block.enableQuery = function(self, query)
	for i, v in ipairs(self.shapes) do
		v.query = query
	end
end
------------------------------------------------------------------------
block.setDynamic = function(self, dynamic)
	if dynamic ~= self.isdynamic then
		self.isdynamic = dynamic

		-- 发光材质与引导场景专用的材质不用关世界UV
		local mtl = self:getMtlMode()
		--print('setDynamic1', table.ftoString(self.data))
		if mtl ~= Global.MTLMODE.EMISSIVE and mtl ~= Global.MTLMODE.AMBIENT then
			local newmtl = dynamic and Global.MTLMODE.NOWORLDUV or Global.MTLMODE.PAINT
			if mtl ~= newmtl then
				self:setMtlMode(newmtl)
			end
		end
		--print('setDynamic2', table.ftoString(self.data))
	end
end

block.getPhysicShapes = function(self)
	return self.shapes
end

block.getPhysicShape = function(self, index)
	return self.shapes[index]
end

block.getShapeByShapeIndex = function(self, sindex)
	local s = self.actor:getShape(sindex)
	--print('getShapeByShapeIndex:', sindex, s, self:getPhysicShapeIndex(s), self:getShape(), #self.shapes, s.size)
	return s
end

-- block.getPhysicShapeMat = function(self, s, mat)
-- 	mat:set(s.transform)
-- 	mat:mulRight(self.node.transform)
-- end

block.getPhysicShapeIndex = function(self, s)
	for i, v in ipairs(self.shapes) do if v == s then
		return i
	end end

	return -1
end

block.getShapeByBIndex = function(self, bindex, shapes)
	for i, v in ipairs(self.shapes) do
		-- print('shape:', i, v.bindex, v.sindex, bindex, sindex)
		if v.bindex == bindex then
			table.insert(shapes, v)
		end
	end
end

block.getShapeBySGIndex = function(self, sgindex, shapes)
	for i, v in ipairs(self.shapes) do
		if v.sgindex == sgindex then
			table.insert(shapes, v)
		end
	end
end

block.getKnots = function(self)
	if self.knots then return self.knots end

	self.knots = {}
	local id = self:getShape()
	if not Block.isItemID(id) then
		local knotdata = Global.KnotsData[id]
		if knotdata then
			for index, v in ipairs(knotdata) do
				local knot = Knot.new(v)
				knot.knotindex = index
				--knot:bind(self)
				--knot:bind(self.node.transform)
				table.insert(self.knots, knot)
			end
		end
	else
		local sdata = Block.getHelperData(id)
		local mat = Container:get(_Matrix3D)

		--local n = 0
		--local t1 = _tick()
		for i, sub in ipairs(sdata.subs.bs) do
			local knotdata = Global.KnotsData[sub.id]
			if knotdata then
				for index, v in ipairs(knotdata) do
					local knot = Knot.new(v)
					knot.subindex = i
					knot.knotindex = index

					mat:loadFromSpace(sub.space)
					knot:mul(mat)

					--if not Detector:checkKnotVSActordata(knot, self:getActorsData()) then
						--knot:bind(self.node.transform)
						table.insert(self.knots, knot)
					--end
				end
			end
		end

		--local t2 = _tick()
		--local actordata = self:getActorsData()
		--print('updateKnots:', self.data.shape, #sdata.subs.bs, n, #self.knots, t2 - t1, #actordata)

		Container:returnBack(mat)
	end

	return self.knots
end

block.getKnotGroup = function(self)
	if not self.knotGroup then
		local kg = KnotGroup.new()
		local ks = self:getKnots()
		for i, k in ipairs(ks) do
			k:bind(self.node.transform)
		end
		kg:addKnots(ks)
		kg:bind(self.node.transform)
		self.knotGroup = kg
	end

	return self.knotGroup
end

block.getSpecialKnots = function(self)
	if self.specialknots then return self.specialknots end

	self.specialknots = {}
	local id = self:getShape()
	if not Block.isItemID(id) then
		local knotdata = Global.KnotsData[id]
		if knotdata then
			for index, v in ipairs(knotdata) do
				if KnotManager.isSpecialType(v.type) then
					local knot = Knot.new(v)
					knot.knotindex = index
					table.insert(self.specialknots, knot)
				end
			end
		end
	else
		local sdata = Block.getHelperData(id)
		local mat = Container:get(_Matrix3D)

		for i, sub in ipairs(sdata.subs.bs) do
			local knotdata = Global.KnotsData[sub.id]
			if knotdata then
				for index, v in ipairs(knotdata) do
					if KnotManager.isSpecialType(v.type) then
						local knot = Knot.new(v)
						knot.subindex = i
						knot.knotindex = index

						mat:loadFromSpace(sub.space)
						knot:mul(mat)
						table.insert(self.specialknots, knot)
					end
				end
			end
		end

		Container:returnBack(mat)
	end

	return self.specialknots
end

block.getSpecialKnotGroup = function(self)
	if not self.specialKnotGroup then
		local kg = KnotGroup.new()
		local ks = self:getSpecialKnots()
		for i, k in ipairs(ks) do
			k:bind(self.node.transform)
		end
		kg:addKnots(ks)
		kg:bind(self.node.transform)
		self.specialKnotGroup = kg
	end

	return self.specialKnotGroup
end

block.hasSpecialKnot = function(self)
	local ks = self:getSpecialKnots()
	return #ks > 0
end

block.resetKnots = function(self)
	self.knotGroup = nil
	self.specialKnotGroup = nil
end

block.getKnot = function(self, subindex, knotindex)
	if not self.knots then self:getKnots() end
	for i, v in ipairs(self.knots) do
		if v.subindex == subindex and v.knotindex == knotindex then
			return v
		end
	end
end

block.getSpecialKnot = function(self, subindex, knotindex)
	if not self.specialknots then self:getSpecialKnots() end
	for i, v in ipairs(self.specialknots) do
		if v.subindex == subindex and v.knotindex == knotindex then
			return v
		end
	end
end

block.getRotData = function(self)
	local shape = self:getShape()
	if Block.isItemID(shape) then
		local type = BMarker.shape2type(shape)
		if type ~= 'rot_circle' and type ~= 'rot_bar' then
			return
		end
	end

	--if Block.isItemID(self:getShape()) then return end
	-- self:getKnotGroup()
	local ks = self:getKnots()
	for i, k in ipairs(ks) do
		local rotdata = k:getRotData()
		if rotdata then
			return rotdata
		end
	end
end

block.hasRotKnot = function(self)
	local shape = self:getShape()
	if Block.isItemID(shape) then
		local type = BMarker.shape2type(shape)
		if type == 'rot_circle' and type == 'rot_bar' then
			return true
		end

		return false
	end

	-- self:getKnotGroup()
	local ks = self:getKnots()
	for i, k in ipairs(ks) do
		local rotdata = k:hasRotData()
		if rotdata then
			return true
		end
	end
end

block.getSubMesh = function(self, subindex)
	return self.submeshs[subindex]
end

block.setPhysicEnable = function(self, enable)
	enable = not not enable -- to bool
	self:enablePhysic(enable)

	if self.BMarker and self.BMarker:isMarkerEnabled() ~= enable then
		self.BMarker:enableMarker(enable)
	end
	if self.markerdata and self.markerdata:isMarkerEnabled() ~= enable then
		self.markerdata:enableMarker(enable)
	end
end

block.enableAutoAnima = function(self, isAutoAnimated, noshape, renderdf)
	if self.isAutoAnimated == isAutoAnimated then return end
	self.isAutoAnimated = isAutoAnimated

	if isAutoAnimated then
		local df = self:getDynamicEffectData()
		if df and Global.isDynamicEffectAuto(df) then
			self:enableShapeAffectByDF(not noshape)
			self:enableUpdateDfByRender(renderdf)
			self:playDynamicEffect('df1')
		end

		if self:hasRoleAnima('animas') then
			self:applyAnim('animas', true)
			self:playAnim('animas')
		end
	else
		self:stopDynamicEffect()
		self:stopAnim()
	end
end

block.getGroupBlocks = function(self, g, bis)
	for i, bi in ipairs(g.blocks) do
		table.insert(bis, bi)
	end
end

block.bindRolePart = function(self, animrole, ppart, part, slotdata, bonename, isroot)
	if ppart then
		animrole:addPart(ppart)
		animrole:addSlot(ppart, slotdata)
	end

	animrole:addPart(part)
	animrole:useSKlBone(part, bonename, slotdata, isroot)
end

block.skipRefreshSceneNode = function(self, skip)
	if skip then
		_rd.forceSkipRefreshSceneNode = true
	else
		_rd.forceSkipRefreshSceneNode = false
		self.node.mesh:refreshSceneNodeTransform()
	end
end

-- 暂时解绑mesh, 修改完transform后再重新绑定，提升效率
block.unbindMesh = function(self)
	local mesh = nil
	if self.node then
		mesh = self.node.mesh
		self.node.mesh = nil
	end

	return mesh
end

block.rebindMesh = function(self, mesh)
	if self.node then self.node.mesh = mesh end
end

block.hasRoleAnima = function(self, animname)
	local hdata = self:getHelperData()
	local subs = hdata and hdata.subs
	if not subs then return false end
	if not subs.parts or not next(subs.parts) then return false end

	return not not Global.AnimationCfg[animname]
end

block.applyAnim = function(self, animname, loop, avatarZ, useroot)
	local hdata = self:getHelperData()
	local subs = hdata and hdata.subs
	if not subs or not subs.parts or not next(subs.parts) then return end

	self:setDynamic(true)

	local AM = Global.AnimationManager
	local animrole = AM:getRole(self)

	if not animrole then
		local parts = subs.parts
		local bindtype = parts.bindbone or 'human'

		animrole = AM:addRole(self)
		animrole:clear()
		animrole:bindSkl(bindtype)

		local rootz = parts.rootz
		if avatarZ then rootz = avatarZ end
		animrole:setRootz(rootz)

		--local mesh = self:unbindMesh()
		_rd.forceSkipRefreshSceneNode = true

		local data = Part.getPartData(bindtype)

		self.roleparts = {}
		for name, part in pairs(parts.data) do
			local p = {}
			p.name = name
			p.logicgroup = part.logicGroup
			self.roleparts[name] = p
		end

		for name, part in pairs(parts.data) do
			local cpart = data.parts[name]
			local bones = cpart.bones

			local slotmat = Container:get(_Matrix3D)
			slotmat:setTranslation(part.jointpos)
			local slotdata = {mat = slotmat}

			local index = 1
			local isroot = cpart.parent == nil

			local pp = part.ppart and self.roleparts[part.ppart.name]
			local p = self.roleparts[part.name]
			self:bindRolePart(animrole, pp, p, slotdata, bones[index], isroot)
		end

		animrole:refresh()

		-- 绑定子模型的父矩阵
		for name, p in pairs(self.roleparts) do
			local group = self:getSubGroup(p.logicgroup)
			if group then
				group:bindTransform(p.transform)
			end
		end

		_rd.forceSkipRefreshSceneNode = false
		self.node.mesh:refreshSceneNodeTransform()
	end

	local san = animrole:useAnima(animname, loop, useroot)
	--san.speed = 0.1
	return san
end

block.getAllPartTransform = function(self)
	if not self.roleparts then return end
	local ret = {}
	for name, p in pairs(self.roleparts) do
		ret[p.name] = p.transform
	end

	return ret
end

block.seekAnim = function(self, animname, t, play)
	local hdata = self:getHelperData()
	local subs = hdata and hdata.subs
	if not subs or not subs.parts or not next(subs.parts) then return end

	local AM = Global.AnimationManager
	local animrole = AM:getRole(self)
	if not animrole then return end

	_rd.forceSkipRefreshSceneNode = true
	animrole:seek(animname, t, play)
	_rd.forceSkipRefreshSceneNode = false
	self.node.mesh:refreshSceneNodeTransform()
end

block.playAnim = function(self, animname, autoidle)
	local hdata = self:getHelperData()
	local subs = hdata and hdata.subs
	if not subs then return end

	self.node.Height = nil -- 重置身高

	local AM = Global.AnimationManager
	local animrole = AM:getRole(self)
	if not animrole then return end

	--local mesh = self:unbindMesh()
	_rd.forceSkipRefreshSceneNode = true
	local san = animrole:playAnim(animname, autoidle)
	_rd.forceSkipRefreshSceneNode = false
	self.node.mesh:refreshSceneNodeTransform()
	--if mesh then self:rebindMesh(mesh) end

	local bindtype = subs.parts.bindbone or 'human'

	if bindtype == 'human' then
		local e = Global.AnimationCfg[animname].emoji
		if e and san and not san.emoji_setted then
			-- print(e.name, e.tick)
			san.graEvent:addTag(e.name, e.tick / san.duration)
			san:onEvent(function(name)
				if name == e.name then
					-- print(name)
					self:applyEmoji(name)
				end
			end, false)
			san.emoji_setted = true
		end
	end

	return san
end

block.pauseAnim = function(self)
	local hdata = self:getHelperData()
	local subs = hdata and hdata.subs
	if not subs or not subs.parts or not next(subs.parts) then return end

	local AM = Global.AnimationManager
	local animrole = AM:getRole(self)
	if not animrole then return end

	return animrole:pauseAnim()
end

block.stopAnim = function(self)
	local hdata = self:getHelperData()
	local subs = hdata and hdata.subs
	if not subs or not subs.parts or not next(subs.parts) then return end

	local AM = Global.AnimationManager
	local animrole = AM:getRole(self)
	if not animrole then return end

	--local mesh = self:unbindMesh()
	_rd.forceSkipRefreshSceneNode = true
	-- 解除子模型的父矩阵
	for name, p in pairs(self.roleparts) do
		local group = self:getSubGroup(p.logicgroup)
		if group then
			group:unbindTransform(p.transform)
		end
	end

	_rd.forceSkipRefreshSceneNode = false
	self.node.mesh:refreshSceneNodeTransform()

	animrole:stopAnim()
	AM:delRole(self)
end

block.getAnimaSkl = function(self)
	local hdata = self:getHelperData()
	local subs = hdata and hdata.subs
	if not subs or not subs.parts or not next(subs.parts) then return end

	local AM = Global.AnimationManager
	local animrole = AM:getRole(self)
	if not animrole then return end
	return animrole.skl
end

block.setDynamicEffectSpeed = function(self, speed)
	self.dynamicEffectSpeed = speed or 1
	if self.playingDf then
		self.playingDf:setSpeed(self.dynamicEffectSpeed)
	end
end

block.getDynamicEffectData = function(self, name)
	name = name or 'df1'
	local hdata = self:getHelperData()
	local subs = hdata and hdata.subs
	if not subs or not subs.dynamicEffects then return end

	local df
	for i, v in ipairs(subs.dynamicEffects) do
		if v.name == name then
			df = v
			break
		end
	end

	if not df then return end

	return df
end

block.enableShapeAffectByDF = function(self, enable)
	self.enableShapeDf = enable
end

block.getShapeDfEnabled = function(self, enable)
	return self.enableShapeDf
end

block.enableUpdateDfByRender = function(self, enable)
	self.updateDfByRender = enable
end

block.playDynamicEffect = function(self, name, action, inverse, onstopcb)
	local hdata = self:getHelperData()
	local subs = hdata and hdata.subs
	if not subs or not subs.dynamicEffects then return end

	local df
	for i, v in ipairs(subs.dynamicEffects) do
		if v.name == name then
			df = v
			break
		end
	end

	if not df then return end

	if self.playingDf then
		-- if self.playingDf:getName() == name then
		-- 	return
		-- end

		self:stopDynamicEffect()
	end

	self.playingDf = DynamicEffect.new(df, self)
	self.playingDf:play(action, inverse, onstopcb)
	self.playingDf:setSpeed(self.dynamicEffectSpeed or 1)
	if not self.updateDfByRender then
		self.node.needUpdate = true
	end

	return true
end

block.stopDynamicEffect = function(self, stopuntilend)
	if not self.playingDf then return end

	self.playingDf:stop(stopuntilend)
end

block.getPlayingDf = function(self)
	return self.playingDf
end

block.updateDynamicEffect = function(self, e)
	if not self.playingDf then return end
	if not e then return end

	self.playingDf:update(e)
end

-- 编辑显示 ------------------------------------------------------------------
local blend_transparent = _Blender.new()
blend_transparent:blend(0x44ffffff)
local blender_empty = _Blender.new()
block.setEditState = function(self, state, keepflag)
--	print('setEditState', self, tostring(self.rtdata.state) .. ' -> ' .. tostring(state))
	if self.rtdata.state == 'selected' then
		if state == 'dragselect' or state == 'undragselect' then
			return
		end
	end

	self.rtdata.state = state

	if state == 'selected' then
		self.node.blender = blender_empty
		self.node.isInsPostEdge = true
		self.node.isInsAlphaFilter = false
		if not keepflag then
			self:delPickFlag(Global.CONSTPICKFLAG.NORMALBLOCK)
			self:addPickFlag(Global.CONSTPICKFLAG.SELECTBLOCK)
		end

		-- self.node.mesh.enableInstanceCombine = false
		-- if self.node.instanceGroup == '' then
		-- 	self.node.instanceGroup = 'editing'
		-- end
	elseif state == 'moving' then
		self.node.blender = blend_transparent
		self.node.isInsPostEdge = false
		self.node.isInsAlphaFilter = true
		if not keepflag then
			self:delPickFlag(Global.CONSTPICKFLAG.NORMALBLOCK)
			self:addPickFlag(Global.CONSTPICKFLAG.SELECTBLOCK)
		end

		-- self.node.mesh.enableInstanceCombine = false
		-- if self.node.instanceGroup == '' then
		-- 	self.node.instanceGroup = 'editing'
		-- end
	else
		self.node.blender = nil
		self.node.isInsPostEdge = false
		self.node.isInsAlphaFilter = false
		if not keepflag then
			self:delPickFlag(Global.CONSTPICKFLAG.SELECTBLOCK)
			self:addPickFlag(Global.CONSTPICKFLAG.NORMALBLOCK)
		end

		-- self.node.mesh.enableInstanceCombine = true
		-- if self.node.instanceGroup == 'editing' then
		-- 	self.node.instanceGroup = ''
		-- end
	end

	-- forcealphafilter
	if self.data.paintInfo then
		self.node.isInsAlphaFilter = true
	end

	if self.bindmoduleBlocks then
		for b in pairs(self.bindmoduleBlocks) do
			b:setEditState(state)
		end
	end
end

block.renderHint = function(self)
	self.node.isInsPostEdge = self == Global.ui.interact.currentObject
	if self.rtdata.showGuide and Global.GameState:isState('GAME') then
		local ab = Container:get(_AxisAlignedBox)
		local vec2 = Container:get(_Vector2)
		local center = Container:get(_Vector3)
		local v1 = Container:get(_Vector3)
		local v2 = Container:get(_Vector3)
		self:getAABB(ab)
		ab:getCenter(center)
		_rd:projectPoint(center.x, center.y, ab.max.z, vec2)
		_Vector3.sub(_rd.camera.look, _rd.camera.eye, v1)
		_Vector3.sub(center, _rd.camera.eye, v2)
		if v1:dot(v2) >= 0 then
			if self.rtdata.showGuide then
				self:updateGuidePfx()
			end
		end
		Container:returnBack(ab, vec2, center, v1, v2)
	end
end

block.checkBlocking = function(self)
	-- 禁用block检查
	-- self.isblocking = false
	-- if next(self.overlaps) then
	-- 	self.isblocking = true
	-- 	self.node.instanceGroup = 'blocking'
	-- else
	-- 	self.node.instanceGroup = ''
	-- end
end

block.setIsblocking = function(self, type, b)
	if type == 'block2' then
		self.isblocking2 = b
	else
		self.isblocking = b
	end
	self.node.instanceGroup = b and type or ''
end

block.setPhyxCulliing = function(self, b)
	if not Block.isBuildMode() then return end
	self.phyxCulliing = b
	self.node.instanceGroup = b and 'culling' or ''
end

block.isPhyxCulliing = function(self)
	return self.phyxCulliing
end

block.setMarker = function(self, mdata)
	local marker = BMarker.new(mdata)
	marker:setBlock(self)
	self.BMarker = marker
end

block.setDefualtMtlWithAlphaFilter = function(self, blender, mtlbatch, insgroup)
	if mtlbatch then
		if not self.mtlbatch then
			self.mtlbatch = self:getMaterialBatch()
		end

		self.node.instanceGroup = insgroup or ''
		self.node.isInsPostEdge = false
		self.node.isInsAlphaFilter = true
		self.node.blender = blender
		self.node.isShadowCaster = false
		self.node.isShadowReceiver = false
		self:setMaterialBatch(mtlbatch)
		self:setPaintVisible(false)
	else
		if self.mtlbatch then
			self:setMaterialBatch(self.mtlbatch)
			self.mtlbatch = nil
		end

		self.node.instanceGroup = insgroup or ''
		self.node.isInsPostEdge = false
		self.node.isInsAlphaFilter = false
		self.node.blender = nil
		self.node.isShadowCaster = true
		self.node.isShadowReceiver = true
		self:setPaintVisible(true)
	end

	if self.data.paintInfo then
		self.node.isInsAlphaFilter = true
	end
end

local skipmtl = {}
skipmtl.color = 0xff888888
skipmtl.roughness = 1
skipmtl.mtlmode = Global.MTLMODE.PAINT
skipmtl.material = 1

local skip_transparent = _Blender.new()
skip_transparent:blend(0x20ffffff)
local skip_transparent1 = _Blender.new()
skip_transparent1:blend(0x80ffffff)
block.setSkipped = function(self, skipped, mode)
	if self.skipped == skipped then return end
	self.skipped = skipped
	if skipped then
		self:setDefualtMtlWithAlphaFilter(mode == 1 and skip_transparent1 or skip_transparent, skipmtl, 'skip')

		self.oldpickflag0 = self:getPickFlag()
		self:setPickFlag(Global.CONSTPICKFLAG.NONE)
	else
		self:setDefualtMtlWithAlphaFilter(nil)
		self:setPickFlag(self.oldpickflag0 or Global.CONSTPICKFLAG.NORMALBLOCK)
		self.oldpickflag0 = nil
	end
end

local repairmtl = {}
repairmtl.color = 0xffffffff
repairmtl.roughness = 1
repairmtl.mtlmode = Global.MTLMODE.PAINT
repairmtl.material = Global.MtlAssembly

local repair_transparent = _Blender.new()
if _rd.alphaFilterCombine == false then
	repair_transparent:blend(0x88ffffff)
else
	repair_transparent:blend(0xffffffff)
end
block.setNeedRepair = function(self, need, index)
	if self.needrepair == need then return end
	self.needrepair = need

	if need then
		local insgroup = 'repair' .. (index or '')
		self:setDefualtMtlWithAlphaFilter(repair_transparent, repairmtl, insgroup)
	else
		self:setDefualtMtlWithAlphaFilter(nil)
	end

	-- if need then
	-- 	self.oldmaterial = self:getMaterial()
	-- 	self.oldcolor = self:getColor()
	-- 	self.oldmode = self:getMtlMode()
	-- 	self:setColor(0x80ffffff)
	-- 	self:setMaterial(25)
	-- 	self.node.instanceGroup = 'repair' .. (index or '')
	-- 	self:setMtlMode(Global.MTLMODE.PAINT)
	-- else
	-- 	if self.oldcolor then
	-- 		self:setColor(self.oldcolor)
	-- 		self:setMaterial(self.oldmaterial)
	-- 		self:setMtlMode(self.oldmode)
	-- 		self.oldcolor = nil
	-- 		self.oldmode = nil
	-- 		self.node.instanceGroup = ''
	-- 	end
	-- end
end

block.setIsRepairing = function(self, repairing)
	self.showRepairEdge = repairing
	self.node.instanceGroup = repairing and 'repairing' or ''
	self.node.isInsPostEdge = repairing
end

local bc = _Color.new(0x44880000)
bc.a = 0.75

local blockingbl2 = _Blender.new()
blockingbl2:blend(bc:toInt())

local repairbl = _Blender.new()
repairbl:blend(0x88ffffff)

local repairbl2 = _Blender.new()
repairbl2:blend(0xff147dff)
--Global.repairbl = repairbl

local cullingbl = _Blender.new()
cullingbl:highlight(0xffffff00)

block.applyEmoji = function(self, emoji)
	Global.Role.applyFacialExpression(self, emoji)
end

block.setRenderCamera = function(self, camera)
	self.rendercamera = camera
end

block.onRender = function(self, mesh)
	if _G.hideAllBlocks then return end

	self.frameToken = Global.FrameToken
	-- local AM = Global.AnimationManager
	-- local animrole = AM:getRole(self)
	-- if animrole then animrole:draw() end

	-- 选中actor更新数量过多巨卡, 先注释.
	-- if self.node.transform.parent then
	-- 	-- self.actor.transform = nil
	-- 	-- self.actor.transform = self.node.transform
	-- end

	local isSelected = self.rtdata.state == 'selected' or self.rtdata.state == 'dragselect' or self.rtdata.state == 'moving'
-- print(self, self.node, isSelected, debug.traceback())
	-- if not (self.isblocking2 or self.isblocking) and self.node.blender then
	-- 	_rd:useBlender(self.node.blender)
	-- 	if Global.Debug.visible then
	-- 		_rd:drawAxis(0.2)
	-- 	end
	-- end
	local pair = Global.GameState:isState('BUILDBRICK') and Global.BuildBrick.pairBlocks[self]
	local isPairSelected
	if pair and pair.rtdata.state == 'selected' then
		isSelected = true
		isPairSelected = true
	end

	local isrepairing = Global.GameState:isState('BUILDBRICK') and Global.BuildBrick.enableRepair or Global.GameState:isState('BLOCKBRAWL')
	local usePostEdge = isSelected or (self.node.isInsPostEdge and Global.GameState:isState('GAME') and _G.tempshowui)

	if isrepairing then
		if self.needrepair then
			_rd.edgeColor = 0xff2F3045
			_rd.edgeWidth = 5
			_rd.edge = true
			_rd.postEdge = true
		end
	else
		if usePostEdge then
			_rd.edgeColor = 0xff00AA00
			--_rd.edgeColor = 0xff00ff00
			_rd.edgeWidth = 5
			_rd.edge = true
			_rd.postEdge = true
		end
	end

	if self.phyxCulliing and Block.isBuildMode() and Global.enableBlockingBlender then
		_rd:useBlender(cullingbl)
	elseif not Global.filterNeededNode and (self.isblocking2 or self.isblocking) and Block.isBuildMode() and Global.enableBlockingBlender then
		_rd:useBlender(blockingbl2)
	-- elseif self.showRepairEdge then
	-- 	_rd:useBlender(repairbl2)
	-- elseif self.needrepair then
		-- _rd:useBlender(repairbl)
	elseif self.defaultBl then
		_rd:useBlender(self.defaultBl)
	elseif self.node.blender then
		_rd:useBlender(self.node.blender)
	end
	local m = mesh == nil and self.node.mesh or mesh
	if not self.isWall and Global.GameState:isState('BUILDBRICK') and m.material then
		if Global.BuildBrick.showProp then
			m.stick = m.stick or _tick()
			local duration = 1500
			local t = (_tick() - m.stick) % (duration * 2)
			_rd.edgeColor = _Color.lerp((t <= duration and _rd.edgeColor or 0xff111111), (t <= duration and 0xff111111 or _rd.edgeColor), (t <= duration and t or (t - duration)) / duration)
			-- m.material:cleanFlow()
		else
			m.stick = nil
			-- if isSelected then
			-- 	m.material:copyFlow(selectedmtl)
			-- else
			-- 	m.material:cleanFlow()
			-- end
		end
	end

	if self.rendercamera then
		_rd:pushCamera()
		_rd.camera = self.rendercamera
	end

	if _sys.instanceNodesRender == true and self.node.mesh.enableInstanceCombine then
		m:drawInstanceMesh()
	else
		m:drawMesh()
	end

	if self.rendercamera then
		_rd:popCamera()
	end

	if isrepairing then
		if self.needrepair then
			_rd.postEdge = false
			_rd.edge = false
		end
	else
		if usePostEdge then
			_rd.postEdge = false
			_rd.edge = false
		end
	end

	if self.phyxCulliing and Block.isBuildMode() and Global.enableBlockingBlender then
		_rd:popBlender()
	elseif not Global.filterNeededNode and (self.isblocking2 or self.isblocking) and Block.isBuildMode() and Global.enableBlockingBlender then
		_rd:popBlender()
	-- elseif self.showRepairEdge then
	-- 	_rd:popBlender()
	-- elseif self.needrepair then
		-- _rd:popBlender()
	elseif self.node.blender then
		_rd:popBlender()
	elseif self.defaultBl then
		_rd:popBlender()
	end

	-- local subs = Block.getHelperData(self.data.shape, self.data.subshape).subs
	-- if subs then
	-- 	local AM = Global.AnimationManager
	-- 	local animrole = AM:getRole(self)
	-- 	if animrole then animrole:draw() end
	-- end
end

return block