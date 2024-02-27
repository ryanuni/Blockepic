-- 用于编辑生成积木的物理包围盒
local Container = _require('Container')
local BuildKnot = {}
Global.BuildKnot = BuildKnot

BuildKnot.init = function(self, shape)
	local c = Global.CameraControl:new()
	c.minRadius = 1
	c.maxRadius = 40

	self.block = nil
	self.operator = 'idle'
	-- type1
	self.knots = {}

	local nodes = {}
	Global.sen:getNodes(nodes)
	for i, node in ipairs(nodes) do
		node.visible = false
	end

	if Global.sen.skyBox then
		Global.sen.skyBox.mesh.visible = false
	end

	local amb = Global.sen.graData:getLight('ambient')
	amb.color = _Color.White
	amb.darkAmbient = false
	self.sizefactor = 0.02

	self.pickKnot = nil
	self.selectedKnot = nil
	_sys.instanceNodesRender = false
	Global.debugFuncUI.ui.debugbutton.visible = false

	-- Global.editor.movefactor2 = 0.01

	_rd.postProcess = nil

	local blender = _Blender.new()
	blender:highlight(0x80808080)
	self.hiblender = blender

	Global.sen:onRender(function(n, e)
		if n.block then
			n.block:onRender(n.instanceMesh)
		elseif n.mesh then
			-- if n and n.blender then
			-- 	_rd:useBlender(n.blender)
			-- end

			if n.knot and self.selectedKnot == n.knot then
				_rd.edgeColor = _Color.Red
				_rd.edgeWidth = 2
				_rd.edge = true
				_rd.postEdge = true
			end

			if n.instanceMesh then
				n.instanceMesh:drawInstanceMesh()
			else
				n.mesh:drawMesh()
			end

			if _rd.edge then
				_rd.postEdge = false
				_rd.edge = false
			end

			-- if n and n.blender then
			-- 	_rd:popBlender()
			-- end
		end
	end)

	local knotData = {
		{type = KnotManager.PAIRTYPE.POINT, color = 0x80FF0000, desc = '普通节点'},
		{type = KnotManager.PAIRTYPE.POINTS, color = 0x80FF4500, desc = '普通节点阵列'},
		{type = KnotManager.PAIRTYPE.TUBE_FORHANDLE, color = 0x80008B00, desc = '定轴节点：轴'},
		{type = KnotManager.PAIRTYPE.HANDLE_WITHNORMAL, color = 0x802E8B57, desc = '定轴节点：爪子'},
		{type = KnotManager.PAIRTYPE.SPHERE_FORHANDLE, color = 0x8000008B, desc = '万向节点：球'},
		{type = KnotManager.PAIRTYPE.HANDLE, color = 0x8000BFFF, desc = '万向节点：爪子'},
		{type = KnotManager.PAIRTYPE.TUBE, color = 0x80008B00, desc = '管状节点'},
		{type = KnotManager.PAIRTYPE.TUBE_BLANK, color = 0x802E8B57, desc = '空心管状'},

		-- 21 - 40：区分形状的特殊连接(如圆弧与圆环的连接)
		{type = KnotManager.PAIRTYPE.POINT_SPE_P1_1, color = 0xFFE04B4B, desc = '圆1:圆弧'},
		{type = KnotManager.PAIRTYPE.POINT_SPE_P1_2, color = 0xFFDDDFE1, desc = '圆1:圆环'},

		-- 41 - 60：不区分形状的特殊连接(如三角边等)
		{type = KnotManager.PAIRTYPE.POINT_SPE_NP1, color = 0xFF1C85DB, desc = '斜边1'},
	}
	self.knotData = knotData

	self.typeKnotData = {}
	for i, v in ipairs(knotData) do
		self.typeKnotData[v.type] = i
	end

	self:loadFile()
	self:load(shape)
end

BuildKnot.onDestory = function(self)
	self:endOperator()
	self:delBlock()
	self.shapeid = nil
end

BuildKnot.loadFile = function(self)
	if self.Datas then return end

	self.Datas = {}
	local filename = 'cfg_knots.lua'
	if _sys:fileExist(filename) then
		local datas = _dofile(filename)
		for id, ks in pairs(datas) do
			self.Datas[id] = {}
			-- print('1111111loadFile', id)
			for i, k in ipairs(ks) do
				-- print('    loadFile', i, k.type)
				if k.subtype then
					if not k.size then
						k.size = {self.sizefactor, self.sizefactor, self.sizefactor}
					end
					local knot = Knot.new()
					knot:load(k)

					table.insert(self.Datas[id], knot)
				else
					local knot = Knot.new()
					knot:load2(k)
					table.insert(self.Datas[id], knot)
				end
			end

			self.Datas[id] = _G.KnotManager.combine(self.Datas[id])
			for i, k in ipairs(self.Datas[id]) do
				if k.type == KnotManager.PAIRTYPE.POINTS then
					local v = _Vector3.new()
					_Vector3.add(k.pos1, k.pos2, v)
					_Vector3.mul(v, 0.5, v)

					self:updatePos2WithTBN(k)
					self:updateNodeKnotPos(k, v)
				end
			end
		end
	end
end

BuildKnot.load = function(self, id)
	self.shapeid = id
	--self.knots = {}
	self:clearKnots()
	self:delBlock()

	if id then
		self:addBlock(id)
		local ks = self.Datas[id]
		for i, v in ipairs(ks or {}) do
			self:addKnot(v)
		end

		--self.Datas[id] = {}
	end
end

BuildKnot.save = function(self)
	if self.shapeid and next(self.knots) then
		--self:findPhyxShape()

		local filename = 'cfg_knots.lua'
		self.Datas[self.shapeid] = self.knots

		local saveData = function(id, ks)
			local s = '[' .. id .. '] = {\n'
			for i, k in ipairs(ks) do
				s = s .. '[' .. i .. '] = ' .. KnotManager.tostring(k) .. ',\n'
			end
			s = s .. '},\n'

			return s
		end

		local str = 'return {\n'
		for _, id in ipairs(Block.BrickIDs) do
			if self.Datas[id] then
				str = str .. saveData(id, self.Datas[id])
			end
		end
		str = str .. '}'

		local file = _File.new()
		file:create('code\\config\\' .. filename, 'utf-8')
		file:write(str)
		file:close()

		Notice('保存成功！！')
	end
end

BuildKnot.delBlock = function(self)
	if self.block then
		Global.sen:delBlock(self.block)
		self.block = nil
	end
end

local blockbl = _Blender.new()
blockbl:blend(0x88ffffff)
BuildKnot.addBlock = function(self, id)
	self.block = Global.sen:createBlock({shape = id})
	assert(self.block)

	if self.useblender then
		self.block.node.blender = blockbl
	end

	self.aabb = _AxisAlignedBox.new()
	self.block:getShapeAABB(self.aabb)
end

local Sphere = _mf:createSphere()
--Sphere.transform:mulTranslationRight(0, 0, 1)
Sphere.transform:mulScalingRight(0.02, 0.02, 0.02)
_mf:paintDiffuse(Sphere, _Color.Black)

BuildKnot.addKnot = function(self, knot)
	if not knot then
		local h = self.aabb.max.z + 0.2
		knot = Knot.new()
		knot.pos1:set(0, 0, h)
	end

	knot:setTransformDirty()

	if knot.type == KnotManager.PAIRTYPE.TUBE or knot.type == KnotManager.PAIRTYPE.TUBE_BLANK then
		local v = _Vector3.new()
		_Vector3.sub(knot.pos2, knot.pos1, v)
		knot.length = v:magnitude()
	end

	local node = Global.sen:add(Sphere)
	node.pickFlag = Global.CONSTPICKFLAG.JOINT
	node.knot = knot
	knot.node = node

	table.insert(self.knots, knot)
	self:updateKnotNode(knot)

	self:setSelect(knot)

	return knot
end
--[[
BuildKnot.formatKnotPos = function(self, k)
	if k.type == KnotManager.PAIRTYPE.POINT or k.type == KnotManager.PAIRTYPE.POINTS then
		local v = _Vector3.new()
		k.node.transform:getTranslation(v)

		local n = k.Normal
		if Global.isAxisSameLine(n, Global.AXIS.Z) or Global.isAxisSameLine(n, Global.AXIS.NZ) then
			k.tangentMode = Global.KNOTNORMALMODE.X
			k.binormalMode = Global.KNOTNORMALMODE.X
			v.x = math.floatRound(v.x, 0.1)
			v.y = math.floatRound(v.y, 0.1)
		elseif Global.isAxisSameLine(n, Global.AXIS.X) or Global.isAxisSameLine(n, Global.AXIS.NX) then
			if Global.isAxisSameLine(k.Tagent, Global.AXIS.Z) then
				
			elseif Global.isAxisSameLine(k.Tagent, Global.AXIS.Z) then

			end

			v.z = math.floatRound(v.x, 0.08)
			v.y = math.floatRound(v.y, 0.1)
			--k.tangentMode = Global.KNOTNORMALMODE.Z
			--k.binormalMode = Global.KNOTNORMALMODE.X
			--v.x = math.floatRound(v.x, 0.1)
			--v.y = math.floatRound(v.y, 0.1)
		elseif Global.isAxisSameLine(n, Global.AXIS.Y) or Global.isAxisSameLine(n, Global.AXIS.NY) then

		end
		-- if k:getTangentMode() == Global.KNOTNORMALMODE.X then

		-- end
	end
end
--]]
BuildKnot.delKnot = function(self, knot)
	knot = knot or self.selectedKnot
	if not knot then return end
	for i, v in ipairs(self.knots) do
		if v == knot then
			Global.sen:del(v.node)
			table.remove(self.knots, i)
			return
		end
	end
end

BuildKnot.clearKnots = function(self)
	for i, v in ipairs(self.knots) do
		Global.sen:del(v.node)
	end

	self.knots = {}
end

local selbl = _Blender.new()
selbl:blend(0xffffffff)
local temppos = _Vector3.new()

BuildKnot.updateKnotNode = function(self, k)
	if not k then return end

	local node = k.node
	if k.pos2 then
		_Vector3.add(k:getPos1(), k:getPos2(), temppos)
		_Vector3.mul(temppos, 0.5, temppos)
		node.transform:setTranslation(temppos)
	else
		node.transform:setTranslation(k:getPos1())
	end
end

BuildKnot.updateNodeKnotPos = function(self, k, mid)
	if k.pos2 then
		local center = _Vector3.new()
		_Vector3.add(k:getPos1(), k:getPos2(), center)
		_Vector3.mul(center, 0.5, center)
		_Vector3.sub(mid, center, mid)

		_Vector3.add(k.pos1, mid, k.pos1)
		_Vector3.add(k.pos2, mid, k.pos2)
		k:setTransformDirty()

		if k.type == KnotManager.PAIRTYPE.POINTS then
			k.tN, k.bN = KnotManager.calcTBNumber(k)
			k.ks = KnotManager.decomposeKnots(k)
		end
	else
		k.pos1:set(mid.x, mid.y, mid.z)
		k:setTransformDirty()
	end
end

BuildKnot.copyKnot = function(self)
	if not self.selectedKnot then return end
	local k = self.selectedKnot
	local knot = Knot.new(k)
	self:addKnot(knot)
	self:updateKnotNode(knot)
	self:setSelect(knot)
end

BuildKnot.updatePos2WithLength = function(self, k)
	local diff = _Vector3.new()
	_Vector3.mul(k.Normal, k.length, diff)

	if not k.pos2 then
		k.pos2 = _Vector3.new()
	end

	_Vector3.add(k.pos1, diff, k.pos2)
	k:setTransformDirty()
end

BuildKnot.updatePos2WithTBN = function(self, k)
	local diff = _Vector3.new()
	_Vector3.mul(k.Tangent, k:getTangentStep() * (k.tN - 1), diff)

	local diff2 = _Vector3.new()
	_Vector3.mul(k.Binormal, k:getBinormalStep() * (k.bN - 1), diff2)

	if not k.pos2 then
		k.pos2 = _Vector3.new()
	end

	_Vector3.add(k.pos1, diff, k.pos2)
	_Vector3.add(k.pos2, diff2, k.pos2)
	k:setTransformDirty()
end

BuildKnot.updateKnotData = function(self, k)
	local type = k.type
	if type == KnotManager.PAIRTYPE.POINTS then

		k.radius = 0.06
		if not k.tN or not k.bN then
			k.tN, k.bN = 2, 2
		end
		self:updatePos2WithTBN(k)

		local v = _Vector3.new()
		k.node.transform:getTranslation(v)
		self:updateNodeKnotPos(k, v)
	elseif type == KnotManager.PAIRTYPE.TUBE or type == KnotManager.PAIRTYPE.TUBE_BLANK then
		if not k.length then
			k.length = 0.2
			k.radius = 0.02
		end
		self:updatePos2WithLength(k)
		local v = _Vector3.new()
		k.node.transform:getTranslation(v)
		self:updateNodeKnotPos(k, v)
	else
		if type == KnotManager.PAIRTYPE.POINT then
			k.radius = 0.06
		end

		k.pos2 = nil
		local v = _Vector3.new()
		k.node.transform:getTranslation(v)
		self:updateNodeKnotPos(k, v)
	end
end

BuildKnot.changeRotPivot = function(self)
	if not self.selectedKnot then return end
	local k = self.selectedKnot
	k.rotpivot = not k.rotpivot
end

BuildKnot.changeKnotType = function(self)
	if not self.selectedKnot then return end
	local k = self.selectedKnot

	local index = self.typeKnotData[k.type]
	index = index + 1
	if index > #self.knotData then
		index = 1
	end
	local type = self.knotData[index].type
	k.type = type
	BuildKnot:updateKnotData(k)
end

BuildKnot.changeKnotN = function(self)
	if not self.selectedKnot then return end
	local k = self.selectedKnot

	local N = k:getNearestN()
	local n = N + 1
	if n > 6 then n = 1 end

	local mat = _Matrix3D.new()
	mat:setFaceTo(k:getNormal(), Global.typeToAxis(n))

	mat:apply(k.Normal, k.Normal)
	mat:apply(k.Tangent, k.Tangent)
	mat:apply(k.Binormal, k.Binormal)
	k:setTransformDirty()
	BuildKnot:updateKnotData(k)
end

local minrot = math.pi / 12
BuildKnot.changeKnotNormal = function(self, mode)
	if not self.selectedKnot then return end
	local k = self.selectedKnot

	local mat = _Matrix3D.new()
	if mode == Global.AXISTYPE.Z then
		mat:setRotationZ(minrot)
	elseif mode == Global.AXISTYPE.Y then
		mat:setRotationY(minrot)
	else
		mat:setRotationX(minrot)
	end
	--mat:setFaceTo(k:getNormal(), Global.typeToAxis(n))

	mat:apply(k.Normal, k.Normal)
	mat:apply(k.Tangent, k.Tangent)
	mat:apply(k.Binormal, k.Binormal)
	k:setTransformDirty()
	BuildKnot:updateKnotData(k)
end

BuildKnot.updateNodeKnotAxis = function(self, node)
	local k = node.knot
	local mat = node.transform
	mat:apply(k.Normal, k.Normal)
	mat:apply(k.Tangent, k.Tangent)
	mat:apply(k.Binormal, k.Binormal)
	k:setTransformDirty()
	BuildKnot:updateKnotData(k)
end

BuildKnot.changeKnotShowKind = function(self)
	if not self.selectedKnot then return end
	local k = self.selectedKnot
	--k.showKind = k.showKind == 1 and 2 or 1
end

BuildKnot.changeKnotTBMode = function(self, t)
	if not self.selectedKnot then return end
	local k = self.selectedKnot
	if k.type == KnotManager.PAIRTYPE.POINTS or k.type == KnotManager.PAIRTYPE.POINT then
		if t then
			k.tangentMode = k.tangentMode == Global.KNOTNORMALMODE.X and Global.KNOTNORMALMODE.Z or Global.KNOTNORMALMODE.X
		else
			k.binormalMode = k.binormalMode == Global.KNOTNORMALMODE.X and Global.KNOTNORMALMODE.Z or Global.KNOTNORMALMODE.X
		end
	end

	BuildKnot:updateKnotData(k)
end

BuildKnot.scaleRadius = function(self, add)
	if not self.selectedKnot then return end
	local k = self.selectedKnot
	if k.type == KnotManager.PAIRTYPE.POINTS or k.type == KnotManager.PAIRTYPE.POINT then return end

	if add then
		k.radius = k.radius + BuildKnot.sizefactor
	else
		if k.radius > BuildKnot.sizefactor then
			k.radius = k.radius - BuildKnot.sizefactor
		end
	end

	BuildKnot:updateKnotData(k)
end

BuildKnot.scaleShape = function(self, add, mode)
	if not self.selectedKnot then return end
	local k = self.selectedKnot

	if k.type == KnotManager.PAIRTYPE.POINTS then
		if mode == 1 then
			if add then
				k.tN = k.tN + 1
			else
				if k.tN > 1 then
					k.tN = k.tN - 1
				end
			end
		else
			if add then
				k.bN = k.bN + 1
			else
				if k.bN > 1 then
					k.bN = k.bN - 1
				end
			end
		end
		self:updateKnotData(k)
	elseif k.type == KnotManager.PAIRTYPE.TUBE or k.type == KnotManager.PAIRTYPE.TUBE_BLANK then
		if add then
			k.length = k.length + BuildKnot.sizefactor
		else
			if k.length > BuildKnot.sizefactor then
				k.length = k.length - BuildKnot.sizefactor
			end
		end

		self:updateKnotData(k)
	end
end

BuildKnot.transKnot = function(self, dir)
	if not self.selectedKnot then return end
	local k = self.selectedKnot

	local diff = _Vector3.new()
	_Vector3.mul(dir, BuildKnot.sizefactor, diff)
	k.node.transform:mulTranslationRight(diff)

	k.node.transform:getTranslation(diff)
	self:updateNodeKnotPos(k, diff)
end

local operatedesc = [[
O 新加节点
B 拷贝节点
C 清除所有节点
Z 保存节点信息
del 删除当前选中

1 修改节点类型
2 修改节点法线方向
3 修改节点显示类型
4-5 切换切线长度
6-8 旋转法线(15°)
9 显示平面
0 积木透明显示
] 切换下一个积木
[ 切换上一个积木

W 增加y轴尺寸
S 减少y轴尺寸
D 增加x轴尺寸
A 减少x轴尺寸
E 增加半径
Q 减少半径
R 切换操作
P 设置成轴心
UP 向上移动
Down 向下移动
Left 向左移动
Right 向右移动
]]
--Enter 检查特殊节点是否有对应的物理形状
--G 自动生成普通节点

local center = _Vector3.new()
local masix = _Vector3.new()
local font = _Font.new('黑体', 20)
BuildKnot.render = function(self)
	font:drawText(0, 0, '形状id: ' .. self.shapeid)
	font:drawText(0, 30, '操作方式: ' .. (self.rotingKnot and '旋转' or '平移'))
	if self.aabb then
		local min, max = self.aabb.min, self.aabb.max
		font:drawText(10, 60, '包围盒:')
		font:drawText(30, 90, string.format('x: %.2f, %.2f', min.x, max.x))
		font:drawText(30, 120, string.format('y: %.2f, %.2f', min.y, max.y))
		font:drawText(30, 150, string.format('z: %.2f, %.2f', min.z, max.z))
	end

	if self.selectedKnot then
		local k = self.selectedKnot
		local index = self.typeKnotData[k.type]
		font:drawText(10, 180, '选中类型: ' .. self.knotData[index].desc)

		k.node.transform:getTranslation(center)
		font:drawText(10, 210, string.format('位置: %.2f, %.2f, %.2f', center.x, center.y, center.z))

		if k.type == KnotManager.PAIRTYPE.POINTS or k.type == KnotManager.PAIRTYPE.POINT then
			font:drawText(10, 240, string.format('切线单位: %.2f, 次法线单位: %.2f', k:getTangentStep(), k:getBinormalStep()))
			if k.type == KnotManager.PAIRTYPE.POINTS then
				font:drawText(10, 270, string.format('数量：%d x %d', k:getTangentN(), k:getBinormalN()))
			end
		elseif k.type == KnotManager.PAIRTYPE.TUBE or k.type == KnotManager.PAIRTYPE.TUBE_BLANK then
			font:drawText(10, 240, string.format('长度: %.2f', k.length))
		end

		if k.type == KnotManager.PAIRTYPE.HANDLE_WITHNORMAL or k.type == KnotManager.PAIRTYPE.TUBE_FORHANDLE
		or k.type == KnotManager.PAIRTYPE.HANDLE or k.type == KnotManager.PAIRTYPE.SPHERE_FORHANDLE
		or k.type == KnotManager.PAIRTYPE.TUBE or k.type == KnotManager.PAIRTYPE.TUBE_BLANK then
			font:drawText(10, 270, string.format('旋转轴心: %s', k.rotpivot and 'true' or 'false'))
		end
	end

	local haspovit = false
	for i, k in ipairs(self.knots) do
		local index = self.typeKnotData[k.type]
		local c = self.knotData[index].color

		if k == self.selectedKnot then
			_rd:useBlender(self.hiblender)
		end

		if k.rotpivot and (k.type == KnotManager.PAIRTYPE.HANDLE_WITHNORMAL or k.type == KnotManager.PAIRTYPE.TUBE_FORHANDLE
			or k.type == KnotManager.PAIRTYPE.HANDLE or k.type == KnotManager.PAIRTYPE.SPHERE_FORHANDLE
			or k.type == KnotManager.PAIRTYPE.TUBE or k.type == KnotManager.PAIRTYPE.TUBE_BLANK) then
			haspovit = true
		end

		KnotManager.drawKnotWithAxis(k, c)

		if k == self.selectedKnot then
			_rd:popBlender()
		end
	end

	if haspovit then
		font:drawText(10, 300, string.format('旋转辅助积木'))
	end

	_rd.font:drawText(20, 350, operatedesc)

	if self.showPlaneZ then
		DrawHelper.drawPlaneZ({w = 0.8, h = 0.8}, 0.2, 0.01)
	end

	_rd:drawAxis(1)
end

BuildKnot.beginOperator = function(self, op)
	assert(self.operator == 'idle', 'op1 :' .. self.operator .. ' op2:' .. op)
	self.operator = op
end

BuildKnot.endOperator = function(self)
	self.operator = 'idle'
end

BuildKnot.isOperator = function(self, op)
	return self.operator == op
end

BuildKnot.pick = function(self, x, y)
	local result = {}
	local flag = Global.CONSTPICKFLAG.JOINT
	Global.sen:pick(_rd:buildRay(x, y), flag, true, result)
	-- print('pick:', x, y, result.node)
	return result.node and result.node.knot
end

BuildKnot.setSelect = function(self, knot)
	--if self.selectedKnot == knot then return end
	local oldselect = self.selectedKnot
	self.selectedKnot = knot

	self:updateKnotNode(oldselect)
	self:updateKnotNode(self.selectedKnot)
end

BuildKnot.onDown = function(self, b, x, y)
	if b ~= 0 then return end
	local knot = self:pick(x, y)
	self.pickKnot = knot

	if knot then self:setSelect(knot) end
	-- print('selectedKnot:', self.selectedKnot)
end

BuildKnot.onUp = function(self, b, x, y)
	if b ~= 0 then return end

	if self:isOperator('rot') then
		self:rotKnotEnd(self.pickKnot, x, y)
	elseif self:isOperator('move') then
		self:moveKnotEnd(self.pickKnot, x, y)
	elseif self:isOperator('idle') then
		--if not self.pickKnot then
			--self.selectedKnot = shape
		--end
	end

	self.pickKnot = nil
	self:endOperator()
end

BuildKnot.onMove = function(self, x, y)
	if self:isOperator('idle') then
		if self.pickKnot then
			if self.rotingKnot then
				self:rotKnotBegin(self.pickKnot, x, y)
			else
				self:moveKnotBegin(self.pickKnot, x, y)
			end
		end
	end

	if self:isOperator('rot') then
		self:rotKnot(self.pickKnot, x, y)
	elseif self:isOperator('move') then
		self:moveKnot(self.pickKnot, x, y)
	end
end

BuildKnot.onClick = function(self, x, y)
end

BuildKnot.onDClick = function(self, x, y)
end

BuildKnot.moveKnotBegin = function(self, knot, x, y)
	self:beginOperator('move')

	local button = Global.ui.controler.planemovebutton
	button:attachBlock(knot.node.transform, Global.MOVESTEP.TILE)
	local scalef = Global.UI:getScale()
	local args = {mouse = {x = x / scalef, y = y / scalef}}
	button.onMouseDown(args)
	Global.ui:setControlerVisible(false)
end
BuildKnot.moveKnot = function(self, knot, x, y)
	local scalef = Global.UI:getScale()
	local args = {mouse = {x = x / scalef, y = y / scalef}}
	local button = Global.ui.controler.planemovebutton
	button.onMouseMove(args)
end
BuildKnot.moveKnotEnd = function(self, knot, x, y)
	local scalef = Global.UI:getScale()
	local args = {mouse = {x = x / scalef, y = y / scalef}}
	local button = Global.ui.controler.planemovebutton
	button.onMouseUp(args)
	button:attachBlock(nil)

	Global.editor:cmd_clickSelect()
	local v = _Vector3.new()
	knot.node.transform:getTranslation(v)
	self:updateNodeKnotPos(knot, v)
end

BuildKnot.rotKnotBegin = function(self, knot, x, y)
	self:beginOperator('rot')

	local button = Global.ui.controler.rolatabutton
	button:attachBlock(knot.node.transform)
	local scalef = Global.UI:getScale()
	local args = {mouse = {x = x / scalef, y = y / scalef}}
	button.onMouseDown(args)
	Global.ui:setControlerVisible(false)
end
BuildKnot.rotKnot = function(self, knot, x, y)
	local scalef = Global.UI:getScale()
	local args = {mouse = {x = x / scalef, y = y / scalef}}
	local button = Global.ui.controler.rolatabutton
	button.onMouseMove(args)
	-- print('rotKnot', x, y, knot.node.transform)
end
BuildKnot.rotKnotEnd = function(self, knot, x, y)
	local scalef = Global.UI:getScale()
	local args = {mouse = {x = x / scalef, y = y / scalef}}
	local button = Global.ui.controler.rolatabutton
	button.onMouseUp(args)
	button:attachBlock(nil)

	Global.editor:cmd_clickSelect()
	self:updateNodeKnotAxis(knot.node)
end

local scalevec = _Vector3.new()
local kevents = {
	{
		k = 221, -- ']'
		func = function()
			local cid = BuildKnot.shapeid or 1
			for i, id in ipairs(Block.BrickIDs) do
				if cid == id and i < #Block.BrickIDs then
					local nid = Block.BrickIDs[i + 1]
					BuildKnot:load(nid)
					--if not next(BuildKnot.knots) then
					--	BuildKnot:GenKnots()
					--end
					-- 自动保存
					--BuildKnot:save()
				end
			end
		end
	},
	{
		k = 219, -- '['
		func = function()
			local cid = BuildKnot.shapeid or 1
			for i, id in ipairs(Block.BrickIDs) do
				if cid == id and i > 1 then
					local nid = Block.BrickIDs[i - 1]
					BuildKnot:load(nid)
					--if not next(BuildKnot.knots) then
					--	BuildKnot:GenKnots()
					--end
					-- 自动保存
					--BuildKnot:save()
				end
			end
		end
	},
	{
		k = _System.KeyZ,
		func = function()
			BuildKnot:save()
		end
	},
	{
		k = _System.KeyC,
		func = function()
			BuildKnot:clearKnots()
		end
	},
	{
		k = _System.KeyG,
		func = function()
			--BuildKnot:GenKnots()
		end
	},
	{
		k = _System.KeyDel,
		func = function()
			BuildKnot:delKnot()
		end
	},
	{
		k = _System.KeyO,
		func = function()
			BuildKnot:addKnot()
		end
	},
	{
		k = _System.KeyB,
		func = function()
			BuildKnot:copyKnot()
		end
	},
	{
		k = _System.KeyReturn,
		func = function()
			--BuildKnot:findPhyxShape()
		end
	},

	{
		k = _System.KeyW,
		func = function()
			BuildKnot:scaleShape(true, 1)
		end
	},
	{
		k = _System.KeyS,
		func = function()
			BuildKnot:scaleShape(false, 1)
		end
	},
	{
		k = _System.KeyA,
		func = function()
			BuildKnot:scaleShape(false, 2)
		end
	},
	{
		k = _System.KeyD,
		func = function()
			BuildKnot:scaleShape(true, 2)
		end
	},
	{
		k = _System.KeyE,
		func = function()
			BuildKnot:scaleRadius(true)
		end
	},
	{
		k = _System.KeyQ,
		func = function()
			BuildKnot:scaleRadius(false)
		end
	},
	{
		k = _System.KeyP,
		func = function()
			BuildKnot:changeRotPivot()
		end
	},
	{
		k = _System.Key1,
		func = function()
			BuildKnot:changeKnotType()
		end
	},
	{
		k = _System.Key2,
		func = function()
			BuildKnot:changeKnotN()
		end
	},
	{
		k = _System.Key3,
		func = function()
			-- BuildKnot:changeKnotShowKind()
		end
	},
	{
		k = _System.Key4,
		func = function()
			BuildKnot:changeKnotTBMode(true)
		end
	},
	{
		k = _System.Key5,
		func = function()
			BuildKnot:changeKnotTBMode(false)
		end
	},
	{
		k = _System.Key6,
		func = function()
			BuildKnot:changeKnotNormal(Global.AXISTYPE.Z)
		end
	},
	{
		k = _System.Key7,
		func = function()
			BuildKnot:changeKnotNormal(Global.AXISTYPE.Y)
		end
	},
	{
		k = _System.Key8,
		func = function()
			BuildKnot:changeKnotNormal(Global.AXISTYPE.X)
		end
	},
	{
		k = _System.Key9,
		func = function()
			BuildKnot.showPlaneZ = not BuildKnot.showPlaneZ
		end
	},
	{
		k = _System.Key0,
		func = function()
			BuildKnot.useblender = not BuildKnot.useblender
			BuildKnot.block.node.blender = BuildKnot.useblender and blockbl or nil
		end
	},
	{
		k = _System.KeyUp,
		func = function()
			BuildKnot:transKnot(Global.AXIS.Z)
		end
	},
	{
		k = _System.KeyRight,
		func = function()
			local dir = Global.typeToAxis(Global.dir2AxisType(Global.DIRECTION.RIGHT, Global.AXISTYPE.Z))
			BuildKnot:transKnot(dir)
		end
	},
	{
		k = _System.KeyDown,
		func = function()
			BuildKnot:transKnot(Global.AXIS.NZ)
		end
	},
	{
		k = _System.KeyLeft,
		func = function()
			local dir = Global.typeToAxis(Global.dir2AxisType(Global.DIRECTION.LEFT, Global.AXISTYPE.Z))
			BuildKnot:transKnot(dir)
		end
	},
}
local cameracontrol = {}
if _sys.os == 'win32' or _sys.os == 'mac' then
	cameracontrol.rotate = _System.MouseRight
	cameracontrol.move = _System.MouseMiddle
else
	cameracontrol.rotate = 2
	cameracontrol.move = 1
end

local clicktick = 0
Global.GameState:setupCallback({
	addKeyDownEvents = kevents,
	cameraControl = cameracontrol,
	onDown = function(b, x, y)
		BuildKnot:onDown(b, x, y)
	end,
	onMove = function(x, y, fid, count)
		BuildKnot:onMove(x, y)
	end,
	onUp = function(b, x, y)
		BuildKnot:onUp(b, x, y)
	end,
	onClick = function(x, y)
		if _tick() - clicktick < 200 then
			BuildKnot:onDClick(x, y)
		else
			BuildKnot:onClick(x, y)
		end
		clicktick = _tick()
		BuildKnot:onUp(0, x, y)
	end,
}, 'BUILDKNOT')

Global.GameState:onEnter(function(...)
	_app:registerUpdate(Global.BuildKnot, 7)
	local c = Global.CameraControl:get()
	c:scale(2)
	c:moveDirV(0.5)
	c.camera.viewNear = 0.1
	c.camera.viewFar = 500
	c:use()
	Global.BuildKnot:init(...)
end, 'BUILDKNOT')

Global.GameState:onLeave(function()
	BuildKnot:onDestory()
	_app:unregisterUpdate(Global.BuildKnot)
end, 'BUILDKNOT')