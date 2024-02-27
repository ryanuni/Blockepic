
local Container = _require('Container')
local temp_vec1 = _Vector3.new()

local ROOM = {
	registerEnter = function(self, func)
		if func then
			self.funcs_enter[#self.funcs_enter+1] = func
		else
			self.funcs_enter = {}
		end
	end,
	registerLeave = function(self, func)
		if func then
			self.funcs_leave[#self.funcs_leave+1] = func
		else
			self.funcs_leave = {}
		end
	end,
	onEnter = function(self, role)
		-- print('onEnter', role, self, #self.funcs_enter)
		for i, f in ipairs(self.funcs_enter) do
			print('role enter room', role, self)
			f(role)
		end
	end,
	onLeave = function(self, role)
		for i, f in ipairs(self.funcs_leave) do
			print('role leave room', role, self)
			f(role)
		end
	end,
	runChips = function(self, chipss)
		if chipss then
			print(debug.traceback())
		end
		BContext.RunChips(self, chipss or self.chips_s)
	end,
	getDirOffset = function(self, dir)
		dir = dir or 'b'
		if dir == 't' then
			return _Vector3.new(0,0,self.aabb.z2 - self.aabb.z1)
		elseif dir == 'b' then
			return _Vector3.new(0,0,self.aabb.z1 - self.aabb.z2)
		elseif dir == 'l' then
			return _Vector3.new(0,self.aabb.x1 - self.aabb.x2,0)
		elseif dir == 'r' then
			return _Vector3.new(0,self.aabb.x2 - self.aabb.x1,0)
		end
	end,

	get_value_by_logic_name = function(self, name)
		local v = {}
		for i, b in next, self.blocks do
			-- print('!!!', table.ftoString(r.logic_names), name)
			if b.logic_names[name] then
				v[#v+1] = b
			end
		end

		return v
		-- return #v > 1 and v or v[1]
	end,

	set_value_by_logic_name = function(self, name, value)

	end,

	attr_get = function(self, key)
		return self.attrs[key]
	end,

	attr_set = function(self, key, value)
		self.attrs[key] = value
	end,

	moveTranslation = function(self, dx, dy, dz, time, c)
		-- self.transform:mulTranslationRight(dx,dy,dz,time)
		-- self.bind_objs
		if self.bind_camera then
			local camera = Global.CameraControl:get()
			camera:moveLookD(_Vector3.new(dx, dy, dz), time, c)
		end

		for i, b in ipairs(self.blocks) do
			b:moveTranslation(dx, dy, dz, time, c)
		end
		self:updateAABB()
	end,

	updatePos = function(self, e)
		temp_vec1:set(0,0,0)
		if Global.AttrManager.calc_speed(self, temp_vec1, e) then
			self:moveTranslation(temp_vec1.x, temp_vec1.y, temp_vec1.z)
		end
	end,

	updateAABB = function(self)
		self.aabb = Block.getAABBs(self.blocks)
		self.aabb.x1 = self.aabb.min.x
		self.aabb.x2 = self.aabb.max.x
		self.aabb.y1 = self.aabb.min.y
		self.aabb.y2 = self.aabb.max.y
		self.aabb.z1 = self.aabb.min.z
		self.aabb.z2 = self.aabb.max.z

		self.width = self.aabb.x2 - self.aabb.x1
		self.height = self.aabb.z2 - self.aabb.z1
		self.offsetstart = self.aabb.z1
		self.offsetend = self.aabb.z2
		self.offset = _Vector3.new(self.aabb.x1, self.aabb.y1, self.aabb.z1)
		self.index = 0
	end,

	inside = function(self, pos)
		local aabb = self.aabb
		return pos.x > aabb.x1 and pos.x < aabb.x2 and
			   pos.y > aabb.y1 and pos.y < aabb.y2 and
			   pos.z > aabb.z1 and pos.z < aabb.z2
	end,

	get_distance = function(self, pos)
		return self.aabb:distance(pos)
	end,

	isBgRoom = function(self)
		return self.isBg
	end,

	getAABB = function(self, forceupdate)
		if forceupdate then
			self:updateAABB()
		end

		return self.aabb
	end,

	getUserAABB = function(self)
		return self.userAABB or self:getAABB(true)
	end,

	getBlock = function(self, index)
		return self.blocks[index]
	end,
	addBlock = function(self, block)
		table.insert(self.blocks, block)
	end,

	init_show = function(self)
		if self.inited_show then return end
		for i, block in ipairs(self.blocks) do
			if block.node.visible or block:isPhysic() then
				local visible, physic = block.node.visible, block:isPhysic()
				block:disablePhysicActor(false)
				block:setVisible(visible, physic)
			end
		end
		self.inited_show = true
	end,

	show = function(self, s)
		if s == self.is_show then return end
		self.is_show = s
		if s then
			for i, block in ipairs(self.blocks) do
				if block.node.oldNeedUpdate == nil then
					block.node.oldNeedUpdate = block.node.needUpdate
				end
				if block.oldVisible == nil then
					block.oldVisible = block.node.visible
				end
				if block.oldPhisic == nil then
					block.oldPhisic = block:isPhysic()
				end
				if block.node.visible or block:isPhysic() then
					block:disablePhysicActor(false)
				end
				block:setVisible(block.oldVisible, block.oldPhisic)
				block.node.needUpdate = block.node.oldNeedUpdate
			end
		else
			for i, block in ipairs(self.blocks) do
				if block.node.oldNeedUpdate == nil then
					block.node.oldNeedUpdate = block.node.needUpdate
				end
				if block.oldVisible == nil then
					block.oldVisible = block.node.visible
				end
				if block.oldPhisic == nil then
					block.oldPhisic = block:isPhysic()
				end
				block:setVisible(false)
				block.node.needUpdate = false
			end
		end
	end,

	active = function(self, a)
		if a == self.is_active then return end
		self.is_active = a
		if a then
			for i, block in ipairs(self.blocks) do
				if block.node.oldNeedUpdate == nil then
					block.node.oldNeedUpdate = block.node.needUpdate
				end
				block.node.needUpdate = block.node.oldNeedUpdate
			end
		else
			for i, block in ipairs(self.blocks) do
				if block.node.oldNeedUpdate == nil then
					block.node.oldNeedUpdate = block.node.needUpdate
				end
				block.node.needUpdate = false
			end
		end
	end,

	load = function(self)
		local sen = self.dungeon and self.dungeon.scene or Global.sen
		local data = self.data
		-- local shape = self.data.shape
		local mat = Container:get(_Matrix3D)
		if data.space then
			mat:loadFromSpace(data.space)
		end
		self.isBg = data.isDungeonBg

		self.blocks = {}

		local bdata
		if data.shape == '' then
			bdata = data
		else
			bdata = Block.loadItemData(data.shape)
		end

		local bs = bdata and bdata.blocks or {}
		for i, v in ipairs(bs) do
			local b = sen:createBlock(v)
			if data.space then
				b.node.transform:mulRight(mat)
			end
			table.insert(self.blocks, b)

			b:runChips()
			b:enableAutoAnima(true)
		end

		self:updateAABB()

		-- setbg
		if self.isBg then
			for i, b in ipairs(self.blocks) do
				b:enablePhysic(false)
				-- b:clearActorShape()
				-- b.node.noClip = true
				b.node.isShadowCaster = false
				b.node.isShadowReceiver = false
			end
		end

		if bdata and bdata.logicgroups then
			local gs = bdata.logicgroups
			-- 加载逻辑组
			for i, g in ipairs(bdata.logicgroups) do
				if g.name then
					for i, bindex in ipairs(g.blocks) do
						local b = self.blocks[bindex]
						if not b.logic_names then
							b.logic_names = {}
						end

						b.logic_names[g.name] = true
					end
				end
			end

			if bdata.chips_s and bdata.chips_s.groups then
				for i, chips_s in ipairs(bdata.chips_s.groups) do
					local g = gs[chips_s.group]
					for _, bindex in ipairs(g.blocks) do
						local b = self.blocks[bindex]
						b:runChips(chips_s)
					end
				end
			end
		else
			for i, ls in next, bdata and bdata.logic_names or {} do
				self.blocks[i].logic_names = table.clone(ls)
			end

			-- print('``````````````', bdata.block_chipss and table.ftoString(bdata.block_chipss))
			for i, css in next, bdata and bdata.block_chipss or {} do
				self.blocks[i]:runChips(css.chips_s)
			end
		end

		if data.markerdata then
			local mdata = data.markerdata
			local t = data.markerdata.type
			if t == 'camera' then
				self.dungeon:setupCamera(mat)
			elseif t == 'marker_start' then
				-- TODO get from rotation
				self.dungeon:addStartPoint(data.space.translation, _Vector3.new(1, 0, 0))
			end
		end

		if bdata.chips_s and bdata.chips_s.main and #bdata.chips_s.main > 0 then
			-- print('todo remove this.', debug.traceback())
			-- self:runChips(bdata.chips_s.main)
		end

		if bdata.funcflags and bdata.funcflags.userAABB then
			self.userAABB = _AxisAlignedBox.new(bdata.funcflags.userAABB)
		end

		Container:returnBack(mat)
	end,
	registerGameBegin = function(self, func)
		self.chip_gameBegin = func
	end
}

local Room = {}
Room.new = function(data, dungeon)
	local r = {
		dungeon = dungeon,
		elements = {},
		funcs_enter = {},
		funcs_leave = {},
		funcs_contexts = {},
		showbydis = true,
		data = data,
		logic_names = {},
		chips_s = {},
		attrs = {},
		sub_rooms = {},
		blocks = {}
	}
	setmetatable(r, {__index = ROOM})
	if data and data.shape then
		r:load()
		-- local bs = Global.sen:createSubBlocks(data)

		-- print('!!! bs', data.shape, #bs)

		-- r.aabb = Block.getAABBs(bs)
		-- r.aabb.x1 = r.aabb.min.x
		-- r.aabb.x2 = r.aabb.max.x
		-- r.aabb.y1 = r.aabb.min.y
		-- r.aabb.y2 = r.aabb.max.y
		-- r.aabb.z1 = r.aabb.min.z
		-- r.aabb.z2 = r.aabb.max.z

		-- r.width = r.aabb.x2 - r.aabb.x1
		-- r.height = r.aabb.z2 - r.aabb.z1
		-- r.offsetstart = r.aabb.z1
		-- r.offsetend = r.aabb.z2
		-- r.offset = _Vector3.new(r.aabb.x1, r.aabb.y1, r.aabb.z1)
		-- r.index = 0

		-- for i, b in next, bs do 
		-- 	b:runChips()
		-- end

		-- r.blocks = bs
	elseif data then
		for k, v in next, data do
			r[k] = v
		end
	end

	return r
end
Room.is_room = function(data)
	if data.shape ~= '' then
		local d = Block.loadItemData(data.shape)
		local t = d and d.funcflags and d.funcflags.blocktype
		if Global.isSceneType(t) then
			return true
		end
	end
end
Room.is_a_room = function(data) -- 有shape和普通block
	if not data.shape then return end

	for i, v in ipairs(data.blocks) do
		if v.shape ~= '' then
			local d = Block.loadItemData(v.shape)
			local t = d and d.funcflags and d.funcflags.blocktype
			if Global.isSceneType(t) then
				return false
			end
		end
	end

	return true
end

return Room
