local Function = _require('Function')

local blockui = {}
Global.blockui = blockui
blockui.typestr = 'blockui'

blockui.new = function(data)
	local u = {}
	setmetatable(u, {__index = blockui})

	u.name = 'none'
	u.db = _DrawBoard.new(20, 20)

	u.data = {
		name = u.name,
		shape = shape or 1,
		material = material or 1,
		color = 1,
		roughness = 1,
		mtlmode = 1,
		center = {x = 0, y = 0},
	}
	u.functions = {}

	if data then
		u:load(data)

		u.name = u.data.name
		if not data.mtlmode then
			u.data.mtlmode = Global.MTLMODE.PAINT
		end
	end

	u.hr = _FairyManager.Left_Left
	u.vr = _FairyManager.Top_Top
	u.mode = 'Game'
	u.content = {}
	u:createWidget()

	return u
end

blockui.createWidget = function(self)
	self.widget = Global.ui:loadView('emptyui')
	self.widget.sortingOrder = -1000

	self:refresh()
	self.widget.owidth = self.widget._width
	self.widget.oheight = self.widget._height

	self.widget.onPress = function() end
	self.widget.onUp = function() end
	self.widget.onEditMouseDown = function()
	end
	self.widget.onEditMouseUp = function()
		if Global.ui.propertyEditor.visible then
			if Global.ui.propertyEditor.isLinking then
				Global.ui.propertyEditor:setCheckObject(self)
			end
		else
			if Global.editor.isMultiSelect then
				Global.editor:cmd_ctrlClickSelectUI(self)
			else
				Global.editor:cmd_clickSelectUI(self)
			end
		end
	end
	self.widget.onGameMouseDown = function()
		self.widget.pressed = true
		self.widget.onPress()
	end
	self.widget.onGameMouseUp = function()
		self.widget.pressed = false
		self.widget.onUp()
	end
	self:setMode(self.mode)
end

---------------------------------------
blockui.load = function(self, data)
	if data.name then
		self.data.name = data.name
	end
	if data.shape then
		self.data.shape = data.shape
	end
	if data.material then
		self.data.material = data.material
	end
	if data.color then
		self.data.color = data.color
	end
	if data.roughness then
		self.data.roughness = data.roughness
	end
	if data.mtlmode then
		self.data.mtlmode = data.mtlmode
	end
	if data.center then
		self.data.center.x = data.center.x
		self.data.center.y = data.center.y
	end
	for i, v in ipairs(data.functions or {}) do
		self:addFunction(Function.new(v))
	end
end
blockui.tostring = function(self, head)
	head = head or ''
	local s = self.data.space
	local p = self.data.physX
	local l = self.data.logic
	local shape = type(self.data.shape) == 'string' and ('\'' .. self.data.shape .. '\'') or self.data.shape
	local str = head .. '{\n'
	str = str .. head .. '\tindex = ' .. self.index .. ',\n'
	str = str .. head .. '\tname = \'' .. self.name .. '\',\n'
	str = str .. head .. '\tshape = ' .. shape .. ',\n'
	str = str .. head .. '\tmaterial = ' .. self.data.material .. ',\n'
	str = str .. head .. '\tcolor = ' .. self.data.color .. ',\n'
	str = str .. head .. '\troughness = ' .. self.data.roughness .. ',\n'
	str = str .. head .. '\tmtlmode = ' .. self.data.mtlmode .. ',\n'
	str = str .. head .. '\tcenter = {x = ' .. self.data.center.x .. ', y = ' .. self.data.center.y .. '},\n'
	str = str .. head .. '\tfunctions = {\n'
	for i, v in ipairs(self.functions) do
		str = str .. v:tostring(head .. '\t\t', 'blockui', self.index)
	end
	str = str .. head .. '\t},\n'
	str = str .. head .. '}'

	return str
end
blockui.removeWidget = function(self)
	self.widget:removeMovieClip()
	self.widget = nil
end
blockui.getIndexInfo = function(self, curtype, curid)
	return 'blockuiid = ' .. ((self.index == curid and curtype == 'blockui') and -1 or self.index)
end
blockui.refresh = function(self)
	self.rtdata = {available = true, state = ''}
	self:refreshMesh()
end

blockui.refreshCenter = function(self)
	local dw, dh = Global.UI:getDesignSize()
	local lw, lh = Global.UI:getSize()

	local centerx, centery = self.data.center.x, self.data.center.y
	self.widget:removeRelation(Global.ui, self.hr)
	self.widget:removeRelation(Global.ui, self.vr)
	if centerx <= dw / 3 then
		self.hr = _FairyManager.Left_Left
		self.widget._x = centerx - self.widget._width / 2
	elseif centerx >= dw / 3 * 2 then
		self.hr = _FairyManager.Right_Right
		self.widget._x = lw - (dw - centerx) - self.widget._width / 2
	else
		self.hr = _FairyManager.Center_Center
		self.widget._x = dw / 3 + (centerx - dw / 3) * (3 * lw - 2 * dw) / dw - self.widget._width / 2
	end
	self.widget:addRelation(Global.ui, self.hr)
	if centery <= dh / 3 then
		self.vr = _FairyManager.Top_Top
		self.widget._y = centery - self.widget._height / 2
	elseif centery >= dh / 3 * 2 then
		self.vr = _FairyManager.Bottom_Bottom
		self.widget._y = lh - (dh - centery) - self.widget._height / 2
	else
		self.vr = _FairyManager.Middle_Middle
		self.widget._y = dh / 3 + (centery - dh / 3) * (3 * lh - 2 * dh) / dh - self.widget._height / 2
	end
	self.widget:addRelation(Global.ui, self.vr)
end

blockui.move = function(self, dx, dy)
	local dw, dh = Global.UI:getDesignSize()
	local lw, lh = Global.UI:getSize()

	self.widget._x = self.widget._x + dx
	self.widget._y = self.widget._y + dy
	local centerx = self.widget._x + self.widget._width / 2
	local centery = self.widget._y + self.widget._height / 2
	if centerx <= dw / 3 then
		self.data.center.x = centerx
	elseif centerx >= lw - dw / 3 then
		self.data.center.x = dw - (lw - centerx)
	else
		self.data.center.x = (centerx - dw / 3) / (3 * lw - 2 * dw) * dw + dw / 3
	end

	if centery <= dh / 3 then
		self.data.center.y = centery
	elseif centery >= lh - dh / 3 then
		self.data.center.y = dh - (lh - centery)
	else
		self.data.center.y = (centery - dh / 3) / (3 * lh - 2 * dh) * dh + dh / 3
	end
	self:refreshCenter()
end

blockui.refreshMesh = function(self)
	local color = self:getColor()
	local roughness = self:getRoughness()
	local num = tonumber(self.content.number)
	if num then
		self.meshes = {}
		if num == 0 then
			table.insert(self.meshes, Block.getBlockMesh(self.data.shape, 10, self.data.material, color, roughness, self.data.mtlmode))
		end
		while num > 0 do
			local b = num % 10
			num = (num - b) / 10
			if b == 0 then b = 10 end
			table.insert(self.meshes, 1, Block.getBlockMesh(self.data.shape, b, self.data.material, color, roughness, self.data.mtlmode))
		end
	else
		self.meshes = {Block.getBlockMesh(self.data.shape, nil, self.data.material, color, roughness, self.data.mtlmode)}
	end

	Block.drawAsUI(Block, self.meshes, self.db, self.rtdata.state)
	self.widget.bg:loadMovie(self.db)
	self.widget._width = self.db.w
	self.widget._height = self.db.h
	self:refreshCenter()
end

blockui.getColor = function(self)
	return Block.convertColor(self.data.color)
end
blockui.setColor = function(self, c)
	self.data.color = c
	self:refreshMesh()
end

blockui.getRoughness = function(self)
	return self.data.roughness
end
blockui.setRoughness = function(self, r)
	self.data.roughness = r
	self:refreshMesh()
end

blockui.getMtlMode = function(self)
	return self.data.mtlmode
end
blockui.setMtlMode = function(self, mode)
	self.data.mtlmode = mode
	self:refreshMesh()
end

blockui.getShape = function(self)
	return self.data.shape
end
blockui.setShape = function(self, s)
	self.data.shape = s
	self:refreshMesh()
end

blockui.getMaterial = function(self)
	return self.data.material
end
blockui.setMaterial = function(self, m)
	self.data.material = m
	self:refreshMesh()
end

blockui.setName = function(self, name)
	self.name = name
end

blockui.setEditState = function(self, state)
	local needrefresh = self.rtdata.state ~= state
	self.rtdata.state = state
	if needrefresh then
		self:refreshMesh()
	end
end

blockui.getBlocks = function(self)
	return {self}
end
-- 事件 ------------------------------------------------------------------
blockui.setMode = function(self, mode)
	self.mode = mode
	if mode == 'Game' then
		self.widget.onMouseDown = function()
			self.widget.onGameMouseDown()
		end
		self.widget.onMouseUp = function()
			self.widget.onGameMouseUp()
		end
	elseif mode == 'Edit' then
		self.widget.onMouseDown = function()
			self.widget.onEditMouseDown()
		end
		self.widget.onMouseUp = function()
			self.widget.onEditMouseUp()
		end
	end
end
blockui.update = function(self, e)
	if not self.rtdata.available then return end

	if self.widget.pressed then
		self.widget:onPress()
	end
end
blockui.registerAction = function(self, action)
	action:onRegister(self)
end
blockui.logoutAction = function(self, action)
	action:onLogout(self)
end
blockui.registerPress = function(self, func)
	self.widget.onPress = func
end
blockui.registerUp = function(self, func)
	self.widget.onUp = func
end
blockui.registerPushup = function(self, func)
end
blockui.registerDown = function(self, func)
end
blockui.registerTouch = function(self, func)
	self.widget.click = func
end
blockui.switchAvailable = function(self, available)
	self.rtdata.available = available
end
blockui.showHint = function(self)
end
blockui.playSound = function(self, soundGroup)
	if not self.rtdata.available then return end

	soundGroup:play()
end
blockui.setContent = function(self, key, value)
	self.content[key] = value
	if key == 'number' then
		self:refreshMesh()
		self.widget._visible = value ~= 'nil'
		local show = tonumber(value) == nil
		self.widget._width = show and self.widget.owidth or self.widget._width
		self.widget._height = show and self.widget.owidth or self.widget._height
		self.widget.label._visible = show
		self.widget.label.text = value
	end
end
blockui.getContent = function(self, key)
	return self.content[key]
end
blockui.getActions = function(self)
	local actions = {}
	for i, v in ipairs(self.functions) do
		for p, q in ipairs(v.actions) do
			table.insert(actions, q)
		end
	end
	return actions
end
blockui.registerEvents = function(self)
	for i, v in ipairs(self:getActions()) do
		v:onRegister(self)
	end
end
blockui.logoutEvents = function(self)
	for i, v in ipairs(self:getActions()) do
		v:onLogout(self)
	end
end
blockui.initEvents = function(self)
	for i, v in ipairs(self.functions) do
		if #v.sourceactions == 0 then
			v:trigger()
		end
	end
end
blockui.addFunction = function(self, f, index)
	index = index or #self.functions + 1
	if self:indexFunction(f) == -1 then
		f.owner = self
		table.insert(self.functions, index, f)
	end
end
blockui.delFunction = function(self, f)
	f.owner = nil
	f:delFromSourceActions()
	table.remove(self.functions, self:indexFunction(f))
end
blockui.indexFunction = function(self, f)
	for i, v in ipairs(self.functions) do
		if v == f then
			return i
		end
	end
	return -1
end
blockui.getFunction = function(self, id)
	return self.functions[id]
end
blockui.loadActionFunctions = function(self, scene)
	for i, v in ipairs(self:getActions()) do
		if not v.loadedFunctions then
			local functions = v.functions
			v.functions = {}
			for p, q in ipairs(functions) do
				if q.typestr ~= 'Function' then
					local object = scene:getObjectByIndexInfo({groupid = q.groupid, blockid = q.blockid, blockuiid = q.blockuiid}) or self
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

return blockui