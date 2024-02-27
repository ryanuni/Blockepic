local DIS = 0.3
local SIZE = 0.05
local editor = Global.editor
local brush = {}
local rm = _RenderMethod.new()
local blender = _Blender.new()
blender:highlight(_Color.White)

local v = _Vector3.new()
local onClick = function(self)
	editor:cmd_brushBlocks(self.dir, self.value)

	self.node.transform:getTranslation(v)
	_rd.camera:focus(v)
end
brush.init = function(self)
	self.currentNode = nil
	-- 初始化箭头 * 6
	self.meshs = {}
	local m = _mf:createCone()
	_mf:paintDiffuse(m, _Color.Red)
	m.transform:setScaling(SIZE, SIZE, SIZE)
	m.transform:mulRotationYRight(math.pi / 2)
	m.dir = 'x'
	m.value = 1
	m.onClick = onClick
	self.meshs[1] = m

	m = _mf:createCone()
	_mf:paintDiffuse(m, _Color.Red)
	m.transform:setScaling(SIZE, SIZE, SIZE)
	m.transform:mulRotationYRight(-math.pi / 2)
	m.dir = 'x'
	m.value = -1
	m.onClick = onClick
	self.meshs[2] = m

	m = _mf:createCone()
	_mf:paintDiffuse(m, _Color.Green)
	m.transform:setScaling(SIZE, SIZE, SIZE)
	m.transform:mulRotationXRight(-math.pi / 2)
	m.dir = 'y'
	m.value = 1
	m.onClick = onClick
	self.meshs[3] = m

	m = _mf:createCone()
	_mf:paintDiffuse(m, _Color.Green)
	m.transform:setScaling(SIZE, SIZE, SIZE)
	m.transform:mulRotationXRight(math.pi / 2)
	m.dir = 'y'
	m.value = -1
	m.onClick = onClick
	self.meshs[4] = m

	m = _mf:createCone()
	_mf:paintDiffuse(m, _Color.Blue)
	m.transform:setScaling(SIZE, SIZE, SIZE)
	m.dir = 'z'
	m.value = 1
	m.onClick = onClick
	self.meshs[5] = m

	m = _mf:createCone()
	_mf:paintDiffuse(m, _Color.Blue)
	m.transform:setScaling(SIZE, SIZE, SIZE)
	m.transform:mulRotationXRight(math.pi)
	m.dir = 'z'
	m.value = -1
	m.onClick = onClick
	self.meshs[6] = m
end
brush.turnOn = function(self, aabb)
	for _, m in next, self.meshs do
		if m.node then
			break
		end

		local n = Global.sen:add(m)
		n.pickFlag = Global.CONSTPICKFLAG.NORMALBLOCK
		n.renderMethod = rm
	end

	local v = _Vector3.new()
	aabb:getCenter(v)
	local s = _Vector3.new()
	aabb:getSize(s)
	self.meshs[1].node.transform:setTranslation(v.x + s.x / 2 + DIS, v.y, v.z)
	self.meshs[2].node.transform:setTranslation(v.x - s.x / 2 - DIS, v.y, v.z)

	self.meshs[3].node.transform:setTranslation(v.x, v.y + s.y / 2 + DIS, v.z)
	self.meshs[4].node.transform:setTranslation(v.x, v.y - s.y / 2 - DIS, v.z)

	self.meshs[5].node.transform:setTranslation(v.x, v.y, v.z + s.z / 2 + DIS)
	self.meshs[6].node.transform:setTranslation(v.x, v.y, v.z - s.z / 2 - DIS)
end
brush.turnOff = function(self)
	for _, m in next, self.meshs do
		if m.node then
			Global.sen:del(m.node)
		end
	end

	self.currentNode = nil
end
brush.onMouseMove = function(self, x, y)
	local n = Global.sen:pickNode(x, y, Global.CONSTPICKFLAG.NORMALBLOCK)
	if self.currentNode == n then return end

	if self.currentNode then
		self.currentNode.blender = nil
	end

	if n then
		n.blender = blender
	end

	self.currentNode = n
end
brush.onMouseUp = function(self, x, y)
	self:onMouseMove(x, y)
	if not self.currentNode then return false end

	self.currentNode.mesh:onClick()

	return true
end

brush:init()

return brush