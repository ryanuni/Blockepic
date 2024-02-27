local helpv3_1 = _Vector3.new()

local function registerFunc(name, f, dungeon, block, sub)
	if dungeon then _G.DungeonGroup[name] = f end
	if block then Global.Block[name] = f end
	if sub then _G.BlockSubGroup[name] = f end
end

local chip_register_event = function(self, event, params, func)
	-- print('chip_register_event', event, params)
	if not self.chip_object then
		self.chip_object = Global.ChipObject.new(self)
	end

	self.chip_object:register_event(event, params, func)
end
registerFunc('chip_register_event', chip_register_event, true, true, true)

local chip_call_event = function(self, event, ...)
	-- print('chip_call_event', debug.traceback(), event, es, ...)
	if not self.chip_object then
		return
	end

	self.chip_object:call_event(event, ...)
end
registerFunc('chip_call_event', chip_call_event, true, true, true)

local getHelperData = function(self)
	return self.hdata
end
registerFunc('getHelperData', getHelperData, true, true, false)

local getLogicGroups = function(self)
	local hdata = self:getHelperData()
	return hdata and hdata.subs.groups
end
registerFunc('getLogicGroups', getLogicGroups, true, true, false)

local getFuncflagValue = function(self, k)
	local hdata = self:getHelperData()
	return hdata.funcflags and hdata.funcflags[k]
end
registerFunc('getFuncflagValue', getFuncflagValue, true, true, false)

local getBChipss = function(self)
	local hdata = self:getHelperData()
	return hdata and hdata.chips_s
end
registerFunc('getBChipss', getBChipss, true, true, true)

local runChips = function(self, chipss)
	if not chipss then
		local chips_s = self:getBChipss()
		chipss = chips_s and chips_s.main
	end

	if chipss then
		-- print('runChips', self, chipss, table.ftoString(chipss), debug.traceback())
		BContext.RunChips(self, chipss)
	end
end
registerFunc('runChips', runChips, true, true, true)

local registerEnter = function(self, func, first)
	if func then
		if not self.funcs_enter then self.funcs_enter = {} end
		if not self.funcs_enter_first then self.funcs_enter_first = {} end
		local index = #self.funcs_enter + 1
		self.funcs_enter[index] = func
		self.funcs_enter_first[index] = first and {}
	else
		self.funcs_enter = {}
		self.funcs_enter_first = {}
	end
end
registerFunc('registerEnter', registerEnter, true, true, true)

local registerLeave = function(self, func)
	if func then
		if not self.funcs_leave then self.funcs_leave = {} end
		self.funcs_leave[#self.funcs_leave + 1] = func
	else
		self.funcs_leave = {}
	end
end
registerFunc('registerLeave', registerLeave, true, true, true)

local onEnter = function(self, role)
	-- print('onEnter', role, self, #self.funcs_enter)
	if self.funcs_enter then
		for i, f in ipairs(self.funcs_enter) do
			local first = self.funcs_enter_first[i]
			if not first or not first[role] then 
				f(role) 
			end

			if first then
				first[role] = true
			end
		end
	end
end
registerFunc('onEnter', onEnter, true, true, true)

local onLeave = function(self, role)
	if self.funcs_leave then
		for i, f in ipairs(self.funcs_leave) do
			print('role leave room', role, self)
			f(role)
		end
	end
end
registerFunc('onLeave', onLeave, true, true, true)

local getDirOffset = function(self, dir)
	local ab = self:getAABB()
	dir = dir or 'b'
	if dir == 't' then
		return _Vector3.new(0, 0, ab.max.z - ab.min.z)
	elseif dir == 'b' then
		return _Vector3.new(0, 0, ab.min.z - ab.max.z)
	elseif dir == 'l' then
		return _Vector3.new(0, ab.min.x - ab.max.x, 0)
	elseif dir == 'r' then
		return _Vector3.new(0, ab.max.x - ab.min.x, 0)
	end
end
registerFunc('getDirOffset', getDirOffset, true, true, true)

local get_value_by_logic_name = function(self, name)
	if name == 'L_Pair' then
		return self.pairBlock
	end

	local groups = self:getLogicGroups()
	if groups then
		for i, g in ipairs(groups or {}) do
			if g.name == name then
				if self.typestr == 'DungeonGroup' then
					return self:getChildrenByhdGroup(g)
				elseif self.typestr == 'block' then
					return {self:getSubGroup(g)} -- 包装成一个组
				end
			end
		end
	end
end
registerFunc('get_value_by_logic_name', get_value_by_logic_name, true, true, false)

local attr_get = function(self, key)
	return self.attrs and self.attrs[key]
end
registerFunc('attr_get', attr_get, true, true, true)

local attr_set = function(self, key, value)
	if not self.attrs then self.attrs = {} end
	self.attrs[key] = value
end
registerFunc('attr_set', attr_set, true, true, true)

local Speed_get = function(self, key)
	return self.Speeds and self.Speeds[key]
end
registerFunc('Speed_get', Speed_get, true, true, true)

local Speed_set = function(self, key, value)
	if not self.Speeds then self.Speeds = {} end
	self.Speeds[key] = value
end
registerFunc('Speed_set', Speed_set, true, true, true)

local moveTranslation = function(self, dx, dy, dz, time, c)
	if self.isbind_camera then
		local camera = Global.CameraControl:get()
		camera:moveLookD(_Vector3.new(dx, dy, dz), time, c)
	end

	if self.typestr == 'LogicBlockGroup' or self.typestr == 'DungeonGroup' then
		for i, v in ipairs(self:getChildren()) do
			v:moveTranslation(dx, dy, dz, time, c)
		end
		self:setAABBDirty(true)
	elseif self.typestr == 'block' then
		self.node.transform:mulTranslationRight(dx, dy, dz, time)
		if c then
			self.node.transform:applyCurve(Global.Curves[c])
		end
		if not self.movedvec then self.movedvec = _Vector3.new() end
		self.movedvec:set(dx, dy, dz)

	elseif self.typestr == 'BlockSubGroup' then
	end
end
registerFunc('moveTranslation', moveTranslation, true, true, true)

local temp_vec1 = _Vector3.new()
local updatePos = function(self, e)
	temp_vec1:set(0, 0, 0)
	if Global.AttrManager.calc_speed(self, temp_vec1, e) then
		-- 移动之前先把block创建出来，因为实际移动的是子block.
		if self.fillData then
			self:fillData()
		end

		self:moveTranslation(temp_vec1.x, temp_vec1.y, temp_vec1.z)
	end

	if self.typestr == 'block' and self.movedvec and not math.floatEqualVector3(self.movedvec, Global.AXIS.ZERO) then
		self:update_role_pos(self.movedvec)
		self:check_collision(self.movedvec)
		self.movedvec:set(Global.AXIS.ZERO)
	elseif self.tmp_xl_need_check_noblock then
		self:check_collision()
	end
end
registerFunc('updatePos', updatePos, true, true, false)

-- TODO:
-- local getAABB = function(self)
-- end
local getInitAABB = function(self, aabb)
	local bd = self:getHelperData()
	if bd then
		aabb:initCenterAndSize(bd.boxcenter, bd.boxsize)
	else
		aabb:initNull()
	end
end
registerFunc('getInitAABB', getInitAABB, true, true, false)

local inside = function(self, pos)
	local aabb = self:getAABB()
	return aabb:checkInside(pos)
end
registerFunc('inside', inside, true, true, true)

local get_distance = function(self, pos)
	local aabb = self:getAABB()
	return aabb:distance(pos)
end
registerFunc('get_distance', get_distance, true, true, true)

local abmin = _Vector2.new()
local abmax = _Vector2.new()
local abmid = _Vector2.new()
local absize = _Vector2.new()
local aabbmid = _Vector3.new()
local aabbsize = _Vector3.new()
local get_distance_ratio = function(self, pos)
	local aabb = self:getAABB()
	_rd:projectPoint(aabb.min.x, aabb.min.y, aabb.min.z, abmin)
	_rd:projectPoint(aabb.max.x, aabb.max.y, aabb.max.z, abmax)
	
	abmin.x = abmin.x / _rd.w
	abmin.y = abmin.y / _rd.h
	abmax.x = abmax.x / _rd.w
	abmax.y = abmax.y / _rd.h
	
	_Vector2.add(abmin, abmax, abmid)
	_Vector2.sub(abmax, abmin, absize)
	
	abmid.x = abmid.x / 2 - 0.5
	abmid.y = abmid.y / 2 - 0.5
	
	aabb:getCenter(aabbmid)
	aabb:getSize(aabbsize)
	-- print('aabb', aabb.min, aabb.max, aabb)

	print('abmin:', aabb.min, abmin)
	print('abmax:', aabb.max, abmax)
	_rd:projectPoint(aabbmid.x, aabbmid.y, aabbmid.z, abmin)
	print('abmid:', aabbmid, abmin, abmid)
	print('absize:', aabbsize, absize)
	print('RRRRRRRRRRRRRRRRRRRRRR', (abmid.x * abmid.x + abmid.y * abmid.y), (absize.x * absize.x + absize.y * absize.y))
	local r = (abmid.x * abmid.x + abmid.y * abmid.y) / math.max((absize.x * absize.x + absize.y * absize.y), 0.5)
	return r
end

registerFunc('get_distance_ratio', get_distance_ratio, true, true, true)

local get_distance_ray = function(self, o, d)
	local aabb = self:getAABB()
	aabb:getCenter(aabbmid)
	aabb:getSize(aabbsize)
	local d2, t = math.p2ray(aabbmid, o, d)
	-- print('=============', math.sqrt(d2), _Vector3.dot(aabbsize, aabbsize), t, aabbmid, aabbsize)

	return d2 / math.max(_Vector3.dot(aabbsize, aabbsize) * 0.25, t * t)
end
registerFunc('get_distance_ray', get_distance_ray, true, true, true)

local isBgRoom = function(self)
	return self.isDungeonBg
end
registerFunc('isBgRoom', isBgRoom, true, true, false)

local registerGameBegin = function(self, func)
	self.chip_gameBegin = func
end
registerFunc('registerGameBegin', registerGameBegin, true, true, true)

local enableRoom = function(self, s)
	if self.isRoomEnabled == s then return end
	self.isRoomEnabled = s

	if self.typestr == 'DungeonGroup' then
		for i, v in ipairs(self:getChildren()) do
			v:enableRoom(s)
		end
	elseif self.typestr == 'block' then
		-- if self.node.oldNeedUpdate == nil then
			-- self.node.oldNeedUpdate = self.node.needUpdate
		-- end
		if self.oldVisible == nil then
			self.oldVisible = self.node.visible
		end
		if self.oldPhisic == nil then
			self.oldPhisic = self:isPhysic()
		end

		if s then
			if self.node.visible or self:isPhysic() then
				self:disablePhysicActor(false)
			end
			self:setVisible(self.oldVisible, self.oldPhisic)
			-- self.node.needUpdate = self.node.oldNeedUpdate
		else
			self:setVisible(false)
			-- self.node.needUpdate = false
		end
	end
end
registerFunc('enableRoom', enableRoom, true, true, false)

local activeRoom = function(self, s)
	if self.isRoomActived == s then return end
	self.isRoomActived = s

	if self.typestr == 'DungeonGroup' then
		for i, v in ipairs(self:getChildren()) do
			v:activeRoom(s)
		end
	elseif self.typestr == 'block' then
		if self.node.oldNeedUpdate == nil then
			self.node.oldNeedUpdate = self.node.needUpdate
		end

		if s then
			self.node.needUpdate = self.node.oldNeedUpdate
		else
			self.node.needUpdate = false
		end
	end
end
registerFunc('activeRoom', activeRoom, true, true, false)

------------------ loadDungeon ------------------

