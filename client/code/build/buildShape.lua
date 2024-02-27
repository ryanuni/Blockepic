-- 用于编辑生成积木的物理包围盒
local Container = _require('Container')
local BuildShape = {}
Global.BuildShape = BuildShape

BuildShape.init = function(self, shape)
	Global.sen.showPhysics = true
	-- if not self.actor then
	-- 	self.actor = Global.sen:addActor()
	-- end
	self.ui = Global.UI:new('BuildShape.bytes')
	self:initUI()
	self.shapes = {}
	self.selectedShape = nil
	self.pickshape = nil
	self.shapemesh = nil
	self.shapeid = nil
	self.operator = 'idle'

	self.downX, self.downY = 0, 0
	self:endOperator()

	Global.debugFuncUI.ui.debugbutton.visible = false

	-- local nodes = {}
	-- Global.sen:getNodes(nodes)

	-- for i, node in ipairs(nodes) do
	-- 	Global.sen:del(node)
	-- end

	Global.sen:delAllBlocks()

	if Global.sen.skyBox then
		Global.sen.skyBox.mesh.visible = false
	end

	self:load(shape)
end

BuildShape.load = function(self, id)
	print('!!!!!BuildShape.load', id)
	self:clearShape()

	self.shapeid = id
	if id then
		self.shapemesh = Block.getBlockMesh(id, nil, 1, 1, 1, 1)
		local sdata = nil

		local filename = 'cfg_phyxshapes.lua'
		if _sys:fileExist(filename) then
			local data = _dofile(filename)
			sdata = data[id]
		end
		if not sdata then
			local bd = Block.getBlockData(id)
			sdata = bd.shapes
		end

		if not sdata then
			local sd = Block.getHelperData(id)
			local box = sd.boxsize
			local boxcenter = sd.boxcenter
			local size = {box.x * 0.5, box.y * 0.5, box.z * 0.5}
			local offset = {boxcenter.x, boxcenter.y, boxcenter.z}

			sdata = {}
			table.insert(sdata, {size = size, offset = offset})
		end

		local v1 = Container:get(_Vector3)
		local v2 = Container:get(_Vector3)

		local factor = Global.editor.movefactor2 * 0.5
		local fmt_n = function(s)
			return math.floor(s / factor + 0.5) * factor
		end

		for i, v in ipairs(sdata) do
			v1:set(fmt_n(v.size[1]), fmt_n(v.size[2]), fmt_n(v.size[3]))
			v2:set(fmt_n(v.offset[1]), fmt_n(v.offset[2]), fmt_n(v.offset[3]))
			local shape = self:addShape(v1)
			shape.transform:setTranslation(v2)
		end

		Container:returnBack(v1, v2)
	end
end

BuildShape.onDestory = function(self)
	self.ui:removeMovieClip()
	self:endOperator()
	Global.sen.showPhysics = false
	--Global.sen:delActor(self.actor)
	self:clearShape()
	--self.actor = nil
	self.shapemesh = nil
	self.shapeid = nil
end

BuildShape.initUI = function(self)
	self.ui.delete.click = function()
		self:delShape()
	end
	self.ui.add.click = function()
		self:addShape({x = 0.1, y = 0.1, z = 0.1})
	end
end

BuildShape.addShape = function(self, size)
	local actor = Global.sen:addActor()

	local shape = actor:addShape(_PhysicsShape.Cube)
	shape.size = _Vector3.new(size.x, size.y, size.z)
	shape.queryFlag = Global.CONSTPICKFLAG.NORMALBLOCK

	table.insert(self.shapes, actor)
	self.selectedShape = actor
	return actor
end

BuildShape.copyShape = function(self)
	if not self.selectedShape then return end

	local s = self.selectedShape:getShape(0)

	local actor = Global.sen:addActor()
	local shape = actor:addShape(_PhysicsShape.Cube)
	shape.size = _Vector3.new(s.size.x, s.size.y, s.size.z)
	shape.queryFlag = Global.CONSTPICKFLAG.NORMALBLOCK
	table.insert(self.shapes, actor)

	actor.transform:set(self.selectedShape.transform)
	self.selectedShape = actor
	return actor
end

BuildShape.delShape = function(self)
	if not self.selectedShape then return end
	for i, v in ipairs(self.shapes) do
		if v == self.selectedShape then
			table.remove(self.shapes, i)
			--self.actor:delShape(v)
			Global.sen:delActor(v)
			self.selectedShape = nil
			return
		end
	end
end

BuildShape.clearShape = function(self)
	for i = #self.shapes, 1, -1 do
		local actor = self.shapes[i]
		Global.sen:delActor(actor)
		table.remove(self.shapes, i)
	end
	self.selectedShape = nil
	self.shapes = {}
end

BuildShape.scaleShape = function(self, scale)
	if not self.selectedShape then return end
	local shape = self.selectedShape:getShape(0)
	local size = shape.size
	-- print('scaleShape0:', scale.x, scale.y, scale.z)
	-- print('scaleShape1:', size.x, size.y, size.z)
	size.x = math.max(size.x + scale.x, 0.1 / 5)
	size.y = math.max(size.y + scale.y, 0.1 / 5)
	size.z = math.max(size.z + scale.z, 0.1 / 5)
	shape.size = size
	print('scaleShape2:', size.x, size.y, size.z)
end

-- BuildShape.scaleDShape = function(self, shape, scaled)
-- 	shape.size = scaled
-- end

BuildShape.beginOperator = function(self, op)
	assert(self.operator == 'idle', 'op1 :' .. self.operator .. ' op2:' .. op)
	self.operator = op
end

BuildShape.endOperator = function(self)
	self.operator = 'idle'
end

BuildShape.isOperator = function(self, op)
	return self.operator == op
end

BuildShape.onDClick = function(self, x, y)
end

BuildShape.onClick = function(self, x, y)
end

BuildShape.moveShapeBegin = function(self, shape, x, y)

	self:beginOperator('move')

	local button = Global.ui.controler.planemovebutton
	button:attachBlock(shape.transform, Global.MOVESTEP.TILE)
	local scalef = Global.UI:getScale()
	local args = {mouse = {x = x / scalef, y = y / scalef}}
	button.onMouseDown(args)
	Global.ui:setControlerVisible(false)
end
BuildShape.moveShape = function(self, shape, x, y)
	local scalef = Global.UI:getScale()
	local args = {mouse = {x = x / scalef, y = y / scalef}}
	local button = Global.ui.controler.planemovebutton
	button.onMouseMove(args)
end
BuildShape.moveShapeEnd = function(self, shape, x, y)
	local scalef = Global.UI:getScale()
	local args = {mouse = {x = x / scalef, y = y / scalef}}
	local button = Global.ui.controler.planemovebutton
	button.onMouseUp(args)
	button:attachBlock(nil)

	Global.editor:cmd_clickSelect()
	--Global.ui.controler.planemovebutton:attachBlock(nil, Global.MOVESTEP.TILE)
end

BuildShape.rotShapeBegin = function(self, shape, x, y)
	self:beginOperator('rot')

	local rotui = Global.ui.controler.rolatabutton
	rotui:attachBlock(shape.transform)

	local scalef = Global.UI:getScale()
	local args = {mouse = {x = x / scalef, y = y / scalef}}
	rotui.onMouseDown(args)
	Global.ui:setControlerVisible(false)
end
BuildShape.rotShape = function(self, shape, x, y)
	local scalef = Global.UI:getScale()
	local args = {mouse = {x = x / scalef, y = y / scalef}}
	Global.ui.controler.rolatabutton.onMouseMove(args)
end
BuildShape.rotShapeEnd = function(self, shape, x, y)
	local scalef = Global.UI:getScale()
	local args = {mouse = {x = x / scalef, y = y / scalef}}
	Global.ui.controler.rolatabutton.onMouseUp(args)
	Global.editor:cmd_clickSelect()
end

BuildShape.pick = function(self, x, y)
	local result = {}
	local flag = Global.CONSTPICKFLAG.NORMALBLOCK
	if Global.sen:physicsPick(_rd:buildRay(x, y), 100, flag, result) then
		return result.actor
	end
end

BuildShape.onDown = function(self, b, x, y)
	if b ~= 0 then return end
	self.downX, self.downY = x, y

	local shape = self:pick(x, y)
	self.pickshape = shape
	if shape then
		self.selectedShape = shape
	end
	-- print('onDown:', self.pickshape, self.selectedShape)
end

BuildShape.onMove = function(self, x, y)
	if self:isOperator('idle') and self.downX then
		if self.pickshape then
			self:moveShapeBegin(self.pickshape, x, y)
		-- elseif self.selectedShape then
		-- 	self:rotShapeBegin(self.selectedShape, x, y)
		end
	end

	if self:isOperator('rot') then
		self:rotShape(self.selectedShape, x, y)
	elseif self:isOperator('move') then
		self:moveShape(self.pickshape, x, y)
	end
end

BuildShape.onUp = function(self, b, x, y)
	if b ~= 0 then return end

	-- print('onUp:', self.operator, self.pickshape, self.selectedShape)
	if self:isOperator('rot') and self.selectedShape then
		self:rotShapeEnd(self.selectedShape, x, y)
	elseif self:isOperator('move') then
		self:moveShapeEnd(self.pickshape, x, y)
	elseif self:isOperator('idle') then
		if not self.pickshape then
			self.selectedShape = shape
		end
	end

	self.pickshape = nil
	self:endOperator()
end

BuildShape.save = function(self)
	if self.shapeid and #self.shapes > 0 then
		local data = {}
		local filename = 'cfg_phyxshapes.lua'
		if _sys:fileExist(filename) then
			data = _dofile(filename)
		end

		local shapedata = {}
		local vec = Container:get(_Vector3)
		for i, s in ipairs(self.shapes) do
			local sdata = {}
			local shape = s:getShape(0)
			sdata.size = {shape.size.x, shape.size.y, shape.size.z}
			s.transform:getTranslation(vec)
			sdata.offset = {vec.x, vec.y, vec.z}
			table.insert(shapedata, sdata)
		end
		data[self.shapeid] = shapedata

		local saveData = function(id, sdata)
			local s = '[' .. id .. '] = {\n'
			for i, v in ipairs(sdata) do
				s = s .. '\t{'
				s = s .. 'size = {' .. v.size[1] .. ',' .. v.size[2] .. ',' .. v.size[3] .. '},'
				s = s .. 'offset = {' .. v.offset[1] .. ',' .. v.offset[2] .. ',' .. v.offset[3] .. '}'
				s = s .. '},\n'
			end
			s = s .. '},\n'

			return s
		end

		--print(table.ftoString(data))
		local str = 'return {\n'
		for _, id in ipairs(Block.BrickIDs) do
			if data[id] then
				str = str .. saveData(id, data[id])
			end
		end
		str = str .. '}'

		--_File.writeString(filename, str, 'utf-8')

		local file = _File.new()
		file:create('code\\config\\' .. filename, 'utf-8')
		file:write(str)
		file:close()

		Container:returnBack(vec)

		Notice('保存成功！！')
	end
end

local mshblend = _Blender.new()
mshblend:blend(0x66ffffff)
local addsizes = {0.1 / 5, 0.1}
local sizeindex = 1

local operatedesc = [[
O 新加节点
Z 保存节点信息
del 删除当前选中
W 增加y轴尺寸
S 减少y轴尺寸
D 增加x轴尺寸
A 减少x轴尺寸
E 增加y轴尺寸
Q 减少y轴尺寸
] 切换下一个积木
[ 切换上一个积木
]]

local font = _Font.new('黑体', 20)
BuildShape.render = function(self)
	font:drawText(10, 0, '形状id:' .. (self.shapeid or 0))

	if self.shapemesh then
		_rd:useBlender(mshblend)
		self.shapemesh:drawMesh()
		_rd:popBlender()
	end

	if self.selectedShape then
		local sx, sy, sz = 0, 0, 0
		for i, v in ipairs(self.shapes) do if v == self.selectedShape then
			local shape = self.selectedShape:getShape(0)
			local size = shape.size
			local ab = Container:get(_AxisAlignedBox)
			ab.min.x, ab.min.y, ab.min.z = -size.x, -size.y, -size.z
			ab.max.x, ab.max.y, ab.max.z = size.x, size.y, size.z
			--sx, sy, sz = size.x, size.y, size.z

			ab:mul(self.selectedShape.transform)
			ab:draw(_Color.Red)

			local min, max = ab.min, ab.max
			local x, y, z = (min.x + max.x) * 0.5, (min.y + max.y) * 0.5, (min.z + max.z) * 0.5
			font:drawText(10, 30, string.format('位置: %.2f, %.2f, %.2f', x, y, z))

			font:drawText(10, 60, '包围盒:')
			font:drawText(30, 90, string.format('x: %.2f, %.2f', min.x, max.x))
			font:drawText(30, 120, string.format('y: %.2f, %.2f', min.y, max.y))
			font:drawText(30, 150, string.format('z: %.2f, %.2f', min.z, max.z))

			Container:returnBack(ab)
		end end

		--font:drawText(0, 30, '尺寸' .. ' x: .. ' .. sx .. ', y: .. ' .. sy .. ', z: .. ' .. sz)
		--font:drawText(0, 30, '尺寸' .. ' x: .. ' .. sx .. ', y: .. ' .. sy .. ', z: .. ' .. sz)
	end

	-- local vec = Container:get(_Vector3)
	-- self.actor.transform:getTranslation(vec)
	-- if vec.x ~= 0 or vec.y ~= 0 or vec.z ~= 0 then
	-- 	print('vec error', vec)
	-- end
	-- Container:returnBack(vec)

	--_rd:drawAxis(0.2)

	_rd.font:drawText(20, 300, operatedesc)
end

BuildShape.sizefactor = 0.02
BuildShape.transShape = function(self, dir)
	if not self.selectedShape then return end

	local mat = self.selectedShape.transform
	-- local k = self.selectedShape

	local diff = _Vector3.new()
	_Vector3.mul(dir, BuildShape.sizefactor, diff)
	mat:mulTranslationRight(diff)
end

local scalevec = _Vector3.new()
local kevents = {
	{
		k = _System.KeyO,
		func = function()
			local size = Container:get(_Vector3)
			size:set(0.1, 0.1, 0.1)
			BuildShape:addShape(size)
			Container:returnBack(size)
		end
	},
	{
		k = _System.KeyB,
		func = function()
			BuildShape:copyShape()
		end
	},
	{
		k = _System.KeyC,
		func = function()
			if BuildShape.selectedShape then
				local sx, sy, sz = 0, 0, 0
				local pos = Container:get(_Vector3)
				BuildShape.selectedShape.transform:getTranslation(pos)
				local shape = BuildShape.selectedShape:getShape(0)
				local actor = BuildShape:addShape(shape.size)
				actor.transform:setTranslation(pos)
				Container:returnBack(pos)
			end
		end
	},
	{
		k = _System.KeyDel,
		func = function()
			BuildShape:delShape()
		end
	},
	{
		k = 221, -- ']'
		func = function()
			local cid = BuildShape.shapeid or 1
			for i, id in ipairs(Block.BrickIDs) do
				if cid == id and i < #Block.BrickIDs then
					local nid = Block.BrickIDs[i + 1]
					BuildShape:load(nid)

					--BuildShape:save()
				end
			end
		end
	},
	{
		k = 219, -- '['
		func = function()
			local cid = BuildShape.shapeid or 1
			for i, id in ipairs(Block.BrickIDs) do
				if cid == id and i > 1 then
					local nid = Block.BrickIDs[i - 1]
					BuildShape:load(nid)

					--BuildShape:save()
				end
			end
		end
	},
	{
		k = _System.KeyW,
		func = function()
			scalevec.x, scalevec.y, scalevec.z = 0, addsizes[sizeindex], 0
			BuildShape:scaleShape(scalevec)
		end
	},
	{
		k = _System.KeyS,
		func = function()
			scalevec.x, scalevec.y, scalevec.z = 0, -addsizes[sizeindex], 0
			BuildShape:scaleShape(scalevec)
		end
	},
	{
		k = _System.KeyA,
		func = function()
			scalevec.x, scalevec.y, scalevec.z = -addsizes[sizeindex], 0, 0
			BuildShape:scaleShape(scalevec)
		end
	},
	{
		k = _System.KeyD,
		func = function()
			scalevec.x, scalevec.y, scalevec.z = addsizes[sizeindex], 0, 0
			BuildShape:scaleShape(scalevec)
		end
	},
	{
		k = _System.KeyE,
		func = function()
			scalevec.x, scalevec.y, scalevec.z = 0, 0, addsizes[sizeindex]
			BuildShape:scaleShape(scalevec)
		end
	},
	{
		k = _System.KeyQ,
		func = function()
			scalevec.x, scalevec.y, scalevec.z = 0, 0, -addsizes[sizeindex]
			BuildShape:scaleShape(scalevec)
		end
	},
	{
		k = _System.KeyZ,
		func = function()
			if _sys:isKeyDown(_System.KeyCtrl) then
				BuildShape:save()
			end
		end
	},
	{
		k = _System.KeyUp,
		func = function()
			BuildShape:transShape(Global.AXIS.Z)
		end
	},
	{
		k = _System.KeyRight,
		func = function()
			local dir = Global.typeToAxis(Global.dir2AxisType(Global.DIRECTION.RIGHT, Global.AXISTYPE.Z))
			BuildShape:transShape(dir)
		end
	},
	{
		k = _System.KeyDown,
		func = function()
			BuildShape:transShape(Global.AXIS.NZ)
		end
	},
	{
		k = _System.KeyLeft,
		func = function()
			local dir = Global.typeToAxis(Global.dir2AxisType(Global.DIRECTION.LEFT, Global.AXISTYPE.Z))
			BuildShape:transShape(dir)
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
	onDown = function(b, x, y)
		BuildShape:onDown(b, x, y)
	end,
	onMove = function(x, y, fid, count)
		BuildShape:onMove(x, y)
	end,
	onUp = function(b, x, y)
		if _sys.os == 'win32' or _sys.os == 'mac' then
			BuildShape:onUp(b, x, y)
		else
			if _tick() - clicktick < 200 then
				BuildShape:onDClick(x, y)
			else
				BuildShape:onClick(x, y)
			end
			clicktick = _tick()
			BuildShape:onUp(0, x, y)
		end
	end,
	onClick = function(x, y)
		if _sys.os == 'win32' or _sys.os == 'mac' then
			if _tick() - clicktick < 200 then
				BuildShape:onDClick(x, y)
			else
				BuildShape:onClick(x, y)
			end
			clicktick = _tick()
			BuildShape:onUp(0, x, y)
		end
	end,
	cameraControl = cameracontrol
}, 'BUILDSHAPE')

Global.GameState:onEnter(function(...)
	_app:registerUpdate(Global.BuildShape, 7)
	local c = Global.CameraControl:get()
	c:scale(4)
	c:moveDirV(0.5)
	c:use()
	Global.BuildShape:init(...)
end, 'BUILDSHAPE')

Global.GameState:onLeave(function()
	BuildShape:onDestory()
	_app:unregisterUpdate(Global.BuildShape)
end, 'BUILDSHAPE')