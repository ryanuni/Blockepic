
_dofile('block_func.lua')

local Dungeon = {ui = nil}
Global.Dungeon_TEMP = Dungeon
_dofile('dungeon_ui.lua')
Global.Dungeon_TEMP = nil

---------------------------- DungeonGroup --------------------------------------
local DungeonGroup = {}
setmetatable(DungeonGroup, {__index = _G.LogicBlockGroup})
DungeonGroup.typestr = 'DungeonGroup'
_G.DungeonGroup = DungeonGroup

-- for k, v in pairs(_G.LogicBlockGroup) do
-- 	if type(v) == 'function' and k ~= 'new' then
-- 		DungeonGroup[k] = v
-- 	end
-- end

DungeonGroup.new = function(shapeid)
	local group = {}
	setmetatable(group, {__index = DungeonGroup})
	group.serialNum = GenSerialNum()
	group.children = {}
	group.data = {}
	group.funcs_enter = {}
	group.funcs_leave = {}
	group.funcs_contexts = {}
	--group.logic_names = {}
	group.chips_s = {}
	group.aabb = _AxisAlignedBox.new()

	-- group:load(shapeid)

	return group
end

DungeonGroup.getChildrenByhdGroup = function(self, group)
	local cs = {}
	for i, bindex in ipairs(group.blocks) do
		local c = self:getChild(bindex)
		if c:isValid() and not c.is_group then
			c = c:getChild(1)
		end

		table.insert(cs, c)
	end

	return cs
end

DungeonGroup.setAABBDirty = function(self)
	self.aabbDirty = true
end

DungeonGroup.updateAABB = function(self)
	local blocks = self:getBlocks()
	Block.getAABBs(blocks, self.aabb)
	self.aabbDirty = false
end

DungeonGroup.getAABB = function(self, forceupdate)
	if forceupdate or self.aabbDirty then
		self:updateAABB()
	end

	return self.aabb
end

local function is_group(data)
	local t = data and data.funcflags and data.funcflags.blocktype
	if Global.isSceneType(t) then return true end
end

local helpvec3 = _Vector3.new()
local tempvec3 = _Vector3.new()
local helpmat = _Matrix3D.new()
local helpab = _AxisAlignedBox.new()
DungeonGroup.initData = function(self, bdata)
	self.data = table.clone(bdata)
	-- print('initData', self.data, table.ftoString(bdata))
	self.aabb = _AxisAlignedBox.new()
	if not bdata.aabb then
		bdata.aabb = _AxisAlignedBox.new(_Vector3.new(-1,-1,-1), _Vector3.new(1,1,1))
		print('aabb error, load and save : ', bdata.shape)
	end

	_Vector3.add(bdata.aabb.min, self.data.space.translation, self.aabb.min)
	_Vector3.add(bdata.aabb.max, self.data.space.translation, self.aabb.max)

	self.aabbDirty = false
end

DungeonGroup.fillData = function(self, bdata)
	if self.filled then return end
	self.filled = true

	if bdata then
		self.data = table.clone(bdata)
	else
		bdata = table.clone(self.data)
	end

	if not bdata.shape then return end
	self:setAABBDirty()

	local data, hdata
	if bdata.shape ~= '' then
		data = Block.loadItemData(bdata.shape)
		hdata = Block.getHelperData(bdata.shape)
		if not hdata then
			hdata = Block.loadHelperData(bdata.shape, 0, data, nil)
		end
	end
	self.hdata = hdata

	self.is_group = is_group(data)
	if self.is_group then
		for i, v in ipairs(data.blocks) do
			local g = DungeonGroup.new()
			if self.dungeon and self.dungeon:is_2D() and v.shape ~= '' then
				g:initData(v)
			else
				g:fillData(v)
			end

			self:addChild(g)

			if g.isgroup then
				g:runChips()
			end
		end
	else
		local b = Global.sen:createBlock(bdata)
		self:addChild(b)
		b:enableAutoAnima(true)
		b:runChips()
		--TODO: logicgroup
	end

	self.isDungeonBg = bdata.isDungeonBg
	self.markerdata = bdata.markerdata

	if bdata.space and self.is_group then
		helpmat:loadFromSpace(bdata.space)
	end

	self:enumBlocks(function(b)
		if bdata.space and self.is_group then
			-- print('fillData', value2string(bdata.space), value2string(helpmat))
			b.node.transform:mulRight(helpmat)
		end

		if self.isDungeonBg then
			b:setDynamic(true)
			b:enablePhysic(false)
			b:enableQuery(false)
			local dungeontype = Global.dungeon and Global.dungeon:getDungeonType()
			if dungeontype == 'scene_music' then
				b:clearActorShape()
			end
			b.node.isShadowCaster = false
			b.node.isShadowReceiver = false
			b.node.noClip = true
		end
	end)

	local groups = self.is_group and self:getLogicGroups()
	if groups then
		for i, g in ipairs(groups) do
			if g.tag == 'pair' then
				local ps = self:getChildrenByhdGroup(g)
				assert(#ps == 2, '#ps == 2')
				ps[1].pairBlock = ps[2]
				ps[2].pairBlock = ps[1]
			end
		end
	end

	local chips_main = hdata and hdata.chips_s and hdata.chips_s.main
	local chips_groups = hdata and hdata.chips_s and hdata.chips_s.groups
	local chips_player = hdata and hdata.chips_s and hdata.chips_s.player
	local chips_dungeon = hdata and hdata.chips_s and hdata.chips_s.dungeon

	if chips_groups then
		if self.is_group then
			for i, chips in ipairs(chips_groups) do
				local cs = self:getChildrenByhdGroup(chips.group)
				for _, c in ipairs(cs) do
					-- TODO:
					if self.dungeon then
						-- c:runChips(chips)
					else
						-- if not c.is_group then
						-- 	local b = c:getChild(1)
						-- 	if b then b:runChips(chips) end
						-- else
							c:runChips(chips)
						-- end
						-- local bs = c:getBlocks()
						-- for _, b in ipairs(bs) do
						-- 	b:runChips(chips)
						-- end
					end
				end
			end
		else
			-- subgroup run chips.
			local block = self:getChild(1)
			for i, chips in ipairs(chips_groups) do
				local subg = block:getSubGroup(chips.group)
				--print('subg', chips.group, value2string(chips))
				subg:runChips(chips)
			end
		end
	end

	local cs = self:getChildren()
	for i, g in ipairs(cs) do
		if g.markerdata then
			local t = g.markerdata.type
			local b0 = g:getChild(1)

			if t == 'camera' and self.dungeon then
				self.dungeon:setupCamera(b0.node.transform)
				if g.markerdata.bindblock then
					cs[g.markerdata.bindblock].isbind_camera = true
					self.dungeon.inner_data.disable_follow_camera = true
				end
				b0:setVisible(false, false)
			elseif t == 'marker_start' and self.dungeon then
				b0.node.transform:getTranslation(helpvec3)

				tempvec3:set(0, -1, 0)
				Global.getRotaionAxis(tempvec3, b0.node.transform, tempvec3)

				self.dungeon:addStartPoint(helpvec3, tempvec3)
				b0:setVisible(false, false)
			elseif t == 'marker_train' then
				local y = 0
				for _, v in ipairs(g.markerdata.trains or {}) do
					local subg = DungeonGroup.new()
					if v.moduleid then
						-- 使用临时shape
						local m = data.submodules[v.moduleid].module
						local tempshape = 'subm_' .. v.moduleid .. '_' .. bdata.shape .. _now(0.001)
						m.funcflags.blocktype = 'scene'
						m.funcflags.blockname = g.markerdata.name
						Block.addDataCache(tempshape, m)
						subg:fillData({shape = tempshape})
						Block.clearDataCache(tempshape)
					elseif v.shape then
						subg:fillData({shape = v.shape})
					end
					subg:getInitAABB(helpab)
					self:addChild(subg)

					helpab:getBottom(helpvec3)
					helpvec3.y = helpab.min.y

					helpmat:setTranslation(-helpvec3.x, y - helpvec3.y, -helpvec3.z)
					helpmat:mulRight(b0.node.transform)

					subg:enumBlocks(function(b)
						b.node.transform:mulRight(helpmat)

						-- if v.chips then
						-- 	print('!!!table.ftoString(chipss)', table.ftoString(v.chips))
						-- 	b:runChips(v.chips)
						-- end
					end)
					if v.chips then subg:runChips(v.chips) end

					y = y + (helpab.max.y - helpab.min.y)
				end
			end
		end
	end
end
_dofile('group_func.lua')

---------------------------- Dungeon --------------------------------------

Dungeon.new = function(shapeid)
	local dg = {}
	setmetatable(dg, {__index = Dungeon})
	Global.SwitchControl:set_input_off()

	Global.dungeon = dg
--	print(Global.dungeon, debug.traceback())

	dg.object_data = {
		camera = Global.CameraControl:get(),
	}

	dg.inner_data = {
		started = false,
		frame_count = 0,
		tried = false,
		send_func = nil,
		is_ended = false
	}

	Global.InputSender:init()
	Global.FrameSystem:Pause(true)

	-- dg.bgelements = {}
	-- dg.rooms = {}
	-- dg.realrooms = {}
	-- dg.currentRoom = nil
	-- dg.chips_s = {}
	-- dg.attrs = {}

	_G.load_dungeon = false
	dg:load(shapeid)

	dg:setupRoleMovement()
end
Dungeon.init = function(self, players, mode, randomseed, data)
	self.mode = mode or EMPTY
	if not players then
		players = {{aid = Global.Login:getAid()}}
	end
	for i, v in ipairs(players) do
		local p = Global.EntityManager:new_role(v)
		p.index = i

		p:setJumpLimit(1)
		p:Respawn(i)
	end

	if self.mode.online then
		local send_func = function(v, j, aid)
			Global.Room_New:DoOp({act = 'move', data = {
				dir = {
					x = v.x,
					y = v.y,
					z = v.z
				},
				jump = j
			}}, aid)
		end
		Global.role:set_on_change(function(v, j)
			send_func(v, j, Global.Login:getAid())
		end)
	end

	self:ui_show(self.mode.test)

	self:init_type()

	Global.SwitchControl:set_input_off()
end
Dungeon.set_players = function(self, players)
	self.inner_data.players = players
end
Dungeon.get_players = function(self)
	local ps = {}
	table.insert(ps, Global.role)
--	print('table insert o', Global.role, Global.role.life)
	for aid, p in next, Global.EntityManager:get_roles() do
		table.insert(ps, p)
--		print('table insert', p, p.life)
	end

	table.sort(ps, function(a, b)
		if not a.index or not b.index then
			return false
		end
		return a.index < b.index
	end)

	return ps
end

Dungeon.get_AllPlayers = Dungeon.get_players
Dungeon.get_Players = Dungeon.get_players
Dungeon.get_Children = function(self) return self.mainGroup:getChildren() end
Dungeon.get_Dungeons = Dungeon.get_Children

Dungeon.attr_get = function(self, key)
	local getfunc = Dungeon['get_'..key]
	if getfunc then return getfunc(self) end
	return self.mainGroup:attr_get(key)
	-- return self.attrs[key]
end
Dungeon.attr_set = function(self, key, value)
	local getfunc = Dungeon['get_'..key]
	local setfunc = Dungeon['set_'..key]
	if getfunc then -- readonly = getfunc only
		if setfunc then setfunc(value) end
		return
	end

	self.mainGroup:attr_set(key)
	--self.attrs[key] = value
end

Dungeon.get = function(self, v) -- todo remove this
	if v == "Players" then
		return self:get_players()
	elseif v == 'Children' then
		return self.mainGroup:getChildren()
	end
end

local offset = _Vector3.new()
Dungeon.copy_room = function(self, des_room, src_room, dir)
	-- local newdata = {}
	-- table.deep_clone(newdata, src_room.data)
	local newdata = table.clone(src_room.data)
	--move room to des_room pos
	newdata.space = table.clone(des_room.data.space)
	-- print('!!!copy_room', value2string(newdata))

	local g = DungeonGroup.new()
	g:initData(newdata)

	self.mainGroup:addChild(g)

	local offset = g:getDirOffset(dir)
	local pos = des_room.data.space.translation
	des_room.data.space.translation = pos:clone():add(offset)

	return g
end

Dungeon.setupCamera = function(self, mat)
	if self.camera_setted then return end
	self.camera_setted = true

	self.cam_look = _Vector3.new(0, 0, 0)
	self.cam_eye = _Vector3.new(0, 0, 1)
	mat:getTranslation(self.cam_eye)

	self.cam_dir = _Vector3.new(0, 1, 0)
	Global.getRotaionAxis(self.cam_dir, mat, self.cam_dir)

	_Vector3.add(self.cam_eye, self.cam_dir, self.cam_look)

	local vlook = _Vector3.new()
	local vdir = _Vector3.new(0, 20, 0)
	_Vector3.add(self.cam_eye, vdir, vlook)

	local camera = Global.CameraControl:get()
	camera:setEyeLook(self.cam_eye, vlook)
	camera:update()
	camera:use()

	-- TODO remove oldver
	Global.sen.setting.camera2D = false
	_rd.bgColor = 0xff3c6ad0
end

Dungeon.addStartPoint = function(self, pos, dir)
	if not self.startpoint_index then self.startpoint_index = 1 end
	self.scene:setRespawnPosDir(pos, dir, self.startpoint_index)
	self.startpoint_index = self.startpoint_index + 1
end

Dungeon.setupRoleMovement = function(self, jump)
	_dofile('neverup_role_move.lua')

	if not self.rolemovement then 
		self.rolemovement = {
			specialtype = 'parkour',
			enableControllerHit = true,
			needAcc = false,
			rolescale = 0.85,
			rolecctscale = 0.7,
			jumpLimit = 0,
			moveparam = {
				jumpheight = 2.5,
				jumptime = 400,
				runmax = 0.005,
				runmin = 0.005,
				runfadetime = 0,
				runforcefadetime = 0,
			}
		}
	else
		return
	end

	if self.rolemovement.enableControllerHit ~= nil then
		Global.sen.setting.enableRoleControllerHit = self.rolemovement.enableControllerHit
	end
	if self.rolemovement.specialtype ~= nil then
		Global.sen.setting.specialtype = self.rolemovement.specialtype
	end
	if self.rolemovement.disableX ~= nil then
		Global.sen.setting.disableX = self.rolemovement.disableX
	end
	if self.rolemovement.disableY ~= nil then
		Global.sen.setting.disableY = self.rolemovement.disableY
	end
	if self.rolemovement.jumpLimit ~= nil then
		Global.sen.setting.jumpLimit = self.rolemovement.jumpLimit
	end
	if self.rolemovement.needAcc ~= nil then
		Global.sen.setting.needAcc = self.rolemovement.needAcc
	end
	if self.rolemovement.rolescale ~= nil then
		Global.sen.setting.rolescale = self.rolemovement.rolescale
	end
	if self.rolemovement.rolecctscale ~= nil then
		Global.sen.setting.rolecctscale = self.rolemovement.rolecctscale
	end
	TEMP_SETUP_PARKOUR_UI()
	if self.rolemovement.moveparam ~= nil then
		local p = self.rolemovement.moveparam
		setRoleMoveParam(p.jumpheight, p.jumptime, p.runmax, p.runmin, p.runacctime, p.runfadetime, p.runforcefadetime)
	end
end

Dungeon.runChips = function(self)
	local hdata = self.mainGroup:getHelperData()

	local chips_groups = hdata and hdata.chips_s and hdata.chips_s.groups
	if chips_groups then
		for i, chips in ipairs(chips_groups) do
			local cs = self.mainGroup:getChildrenByhdGroup(chips.group)
			for _, c in ipairs(cs) do
				-- print('runChips', #cs, _)
				c:runChips(chips)
			end
		end
	end

	if hdata and hdata.chips_s and hdata.chips_s.dungeon then
		BContext.RunChips(self, hdata.chips_s.dungeon)
	end
end

Dungeon.get_value_by_logic_name = function(self, name)
	return self.mainGroup:get_value_by_logic_name(name)
end

Dungeon.set_value_by_logic_name = function(self, name, value)
	return self.mainGroup:set_value_by_logic_name(name, value)
end

Dungeon.init_type = function(self)
	local dtype = self:getDungeonType()
	-- camera
	local c = self.object_data.camera
	if dtype == 'scene' or dtype == 'scene_music' then
		c:followTarget('role')
		_app:cameraControl({rotate = _System.MouseRight})
		if dtype == 'scene_music' then
			c:lockDirV(math.pi/12, math.pi/3)
			c:lockDirH(math.pi/6, math.pi*5/6)
			Global.role:focusBack(0)
			-- c:followTarget('role', math.pi * 5/6)
			c:followRole()
			c:moveDirV(0,0)
			c:moveDirH(0,0)
			c:update()
			c:use()

			local fog = Global.sen.graData:getFog(1)
			fog.near = Global.MUSIC_VIEWFAR / 2 
			fog.far = Global.MUSIC_VIEWFAR
		end
	elseif dtype == 'scene_2D' then
		c:followTarget('role')
		--_app:cameraControl({move = _System.MouseMiddle, rotate = _System.MouseRight})
		TEMP_WHEEL_CONTROL(false)
	end

	if self.inner_data.disable_follow_camera then
		c:followTarget()
	end

	if dtype == 'scene_music' then
		_rd.postProcess.ssao = false
	end
end
Dungeon.is_2D = function(self)
	return self:getDungeonType() == 'scene_2D'
end
Dungeon.is_Music = function(self)
	return self:getDungeonType() == 'scene_music'
end
--[[
Dungeon.load_room = function(self, data, chips, logicnames)
	local r = Room.new(data, self)
	table.insert(self.realrooms, r)
	if chips then
		for i, v in ipairs(chips) do
			local t = {}
			table.deep_clone(t, v)
			table.insert(r.chips_s, t)
		end
	end
	if logicnames then
		r.logic_names = table.clone(logicnames)
	end

	return r
end

Dungeon.load_block_and_chip = function(self, data)
	local blocks = data.blocks
	local chips = data.block_chipss and data.block_chipss.chips_s or {}
	local logicnames = data.logic_names or {}
	-- 拼一个room出来，最顶层的非room部分整体当作一个room加载（加载写的太麻烦了）
	data.shape = ''
	data.blocks = {}
	data.block_chipss = {}
	data.logic_names = {}

	if data.logicgroups then
		local gs = data.logicgroups
		-- 加载逻辑组
		for i, g in ipairs(data.logicgroups) do
			if g.name then
				for i, bindex in ipairs(g.blocks) do
					if not logicnames[bindex] then
						logicnames[bindex] = {}
					end
					local logic_names = logicnames[bindex]
					logic_names[g.name] = true
				end
			end
		end

		if data.chips_s and data.chips_s.groups then
			for i, chips_s in ipairs(data.chips_s.groups) do
				local g = gs[chips_s.group]
				for _, bindex in ipairs(g.blocks) do
					chips[bindex] = chips_s
					--table.insert(chips[bindex].chips_s, chips_s)
				end
			end
		end

		data.logicgroups = nil
	end

	local camera_bind_room
	for i, b in ipairs(blocks) do
		if Room.is_room(b) or b.isDungeonBg then
			local r = self:load_room(b, chips[i], logicnames[i])
			r.bindex = i
		elseif b.shape == '' then
			if b.markerdata then
				local mdata = b.markerdata
				local t = mdata.type
				--print('mdata', t, mdata and mdata.trains and #mdata.trains)
				if t == 'marker_train' then
					local y = 0
					local ab = Container:get(_AxisAlignedBox)
					local vec = Container:get(_Vector3)
					local mat = Container:get(_Matrix3D)
					local mat2 = Container:get(_Matrix3D)
					if b.space then
						mat:loadFromSpace(b.space)
					end
					for _, v in ipairs(mdata.trains or {}) do
						local r = self:load_room({shape = v.shape}, v.chips or chips[i])
						r.bindex = i
						local ab = r:getInitAABB()
						ab:getBottom(vec)
						vec.y = ab.min.y
						mat2:setTranslation(-vec.x, y - vec.y, -vec.z)

						if b.space then mat2:mulRight(mat) end

						for _, bb in ipairs(r.blocks) do
							bb.node.transform:mulRight(mat2)
						end
						print('y', i, y, (ab.max.y - ab.min.y), value2string(ab), value2string(mat), b.space)

						y = y + (ab.max.y - ab.min.y)
					end

					Container:returnBack(mat, ab, vec, mat2)
				else
					if b.markerdata.bindblock then
						camera_bind_room = b.markerdata.bindblock
						self.inner_data.disable_follow_camera = true
					end

					self:load_room(b, chips[i])
				end
			end
		else
			table.insert(data.blocks, b)
			data.block_chipss[#data.blocks] = chips[i]
			data.logic_names[#data.blocks] = logicnames[i]
		end
	end

	if camera_bind_room then
		-- print('camera_bind_room', camera_bind_room, #self.realrooms)
		for i, r in ipairs(self.realrooms) do
			if r.bindex == camera_bind_room then
				r.bind_camera = true
				break
			end
		end
	end

	if #data.blocks > 0 then
		self:load_room(data)
	end
end
--]]
Dungeon.initBgRoomData = function(self)
	self.aabb = _AxisAlignedBox.new()
	self.aabb:initBox()
	local hasbg = false
	local cs = self.mainGroup:getChildren()
	for i, r in ipairs(cs) do
		if not r:isBgRoom() then
			_AxisAlignedBox.union(r:getAABB(), self.aabb, self.aabb)
		else
			hasbg = true
		end
	end
	self.aabb:alignSize(0.8)

	if hasbg then
		self.bgaabb = _AxisAlignedBox.new()
		local flag_ab = self.mainGroup:getFuncflagValue('bgAABB')
		-- print('flag_ab', value2string(flag_ab))
		if flag_ab then
			self.bgaabb:set(flag_ab)
		else
			for i, r in ipairs(cs) do
				if r:isBgRoom() then
					_AxisAlignedBox.union(r:getAABB(), self.bgaabb, self.bgaabb)
				end
			end
		end

		local type = self:getDungeonType()

		local movex, movey, movez = false, false, false
		local movenx, moveny, movenz = false, false, false
		if type == 'scene_2D' then
			movez, movenz = true, true
		elseif type == 'scene_music' then
			movey = true
		end

		local factors = {}
		local look = _rd.camera.look
		local min, max = self.aabb.min, self.aabb.max
		local bgmin, bgmax = self.bgaabb.min, self.bgaabb.max

		if movex and bgmax.x > look.x and max.x > look.x then
			factors[Global.AXISTYPE.X] = (max.x - bgmax.x) / (max.x - look.x)
		end
		if movenx and bgmin.x < look.x and min.x < look.x then
			factors[Global.AXISTYPE.NX] = (min.x - bgmin.x) / (min.x - look.x)
		end

		if movey and bgmax.y > look.y and max.y > look.y then
			factors[Global.AXISTYPE.Y] = (max.y - bgmax.y) / (max.y - look.y)
		end

		if moveny and bgmin.y < look.y and min.y < look.y then
			factors[Global.AXISTYPE.NY] = (min.y - bgmin.y) / (min.y - look.y)
		end

		print('!!!!!!', look.y, bgmax.y, bgmin.y, max.y, min.y)
		print('!!!factory', factors[Global.AXISTYPE.Y], factors[Global.AXISTYPE.NY])

		if movez and bgmax.z > look.z and max.z > look.z then
			local delta = 0
			if type == 'scene_2D' then
				local out = _Vector3.new()
				_rd:pickXZPlane(_rd.w / 2, 0, bgmin.y, out)
				delta = math.max(bgmax.z - out.z, 0)
			else
				delta = bgmax.z - look.z
			end
			factors[Global.AXISTYPE.Z] = 1 - (delta / (max.z - look.z))
		end

		if movenz and bgmin.z < look.z and min.z < look.z then
			local delta = 0
			if type == 'scene_2D' then
				local out = _Vector3.new()
				_rd:pickXZPlane(_rd.w / 2, _rd.h, bgmin.y, out)
				delta = math.min(bgmin.z - out.z, 0)
			else
				delta = bgmin.z - look.z
			end

			factors[Global.AXISTYPE.NZ] = 1 - (delta / (min.z - look.z))
		end
		self.movefactors = factors
		self.init_cam_look = _Vector3.new(look)
	end

	self.bgRoomInited = true
end

Dungeon.updateBgRooms = function(self, look)
	-- if not self.bgRoomInited then self:initBgRoomData() end
	if not self.bgRoomInited then return end

	if not self.bgcamera then
		self.bgcamera = _Camera.new()
		self.bgcamera:set(_rd.camera)
	end

	if not self.movefactors or not next(self.movefactors) then return end
	if not self.movediff then self.movediff = _Vector3.new(0, 0, 0) end
	if not self.movediff0 then self.movediff0 = _Vector3.new(0, 0, 0) end

	if look.x > self.init_cam_look.x and self.movefactors[Global.AXISTYPE.X] then
		self.movediff.x = (look.x - self.init_cam_look.x) * self.movefactors[Global.AXISTYPE.X]
	elseif look.x < self.init_cam_look.x and self.movefactors[Global.AXISTYPE.NX] then
		self.movediff.x = (look.x - self.init_cam_look.x) * self.movefactors[Global.AXISTYPE.NX]
	end

	if look.y > self.init_cam_look.y and self.movefactors[Global.AXISTYPE.Y] then
		self.movediff.y = (look.y - self.init_cam_look.y) * self.movefactors[Global.AXISTYPE.Y]
	elseif look.y < self.init_cam_look.y and self.movefactors[Global.AXISTYPE.NY] then
		self.movediff.y = (look.y - self.init_cam_look.y) * self.movefactors[Global.AXISTYPE.NY]
	end

	if look.z > self.init_cam_look.z and self.movefactors[Global.AXISTYPE.Z] then
		self.movediff.z = (look.z - self.init_cam_look.z) * self.movefactors[Global.AXISTYPE.Z]
	elseif look.z < self.init_cam_look.z and self.movefactors[Global.AXISTYPE.NZ] then
		self.movediff.z = (look.z - self.init_cam_look.z) * self.movefactors[Global.AXISTYPE.NZ]
	end

	-- if math.floatEqualVector3(self.movediff, self.movediff0) then return end

	_Vector3.sub(_rd.camera.look, self.movediff, self.bgcamera.look)
	_Vector3.sub(_rd.camera.eye, self.movediff, self.bgcamera.eye)
	--print('self.movediff', value2string(self.movediff))

	-- _rd.forceSkipRefreshSceneNode = true
	for i, r in ipairs(self.mainGroup:getChildren()) do
		if r:isBgRoom() then
			local blocks = r:getBlocks()
			for _, b in ipairs(blocks) do
				b:setRenderCamera(self.bgcamera)
			end
			-- r:moveTranslation(self.movediff.x - self.movediff0.x, self.movediff.y - self.movediff0.y, self.movediff.z - self.movediff0.z, 0)
		end
	end
	-- _rd.forceSkipRefreshSceneNode = false

	self.movediff0:set(self.movediff)
end

Dungeon.load = function(self, shape)
	-- local tick = _tick()
	-- self.scene = CreateScene(data.scenefile)
	self.scene = CreateScene('neverup.sen')
	-- self.bgm = data.bgmfile
	-- self.roomtype = data.roomtype
	-- self.randomroom = data.randomroom
	-- self.room_funcs = data.room_funcs
	-- self.showroomnum = data.showroomnum

	local nodes = {}
	self.scene:getNodes(nodes)
	for i, v in ipairs(nodes) do
		v.isShadowCaster = true
		v.isShadowReceiver = true
		if v.block == nil then
			v.visible = false
		end
		if v.actor then
			self.scene:delActor(v.actor)
		end
	end

	self.mainGroup = DungeonGroup.new()
	self.mainGroup.dungeon = self

	self.mainGroup:fillData({shape = shape})
	--local hdata = self.mainGroup:getHelperData()
	-- local chips_main = hdata and hdata.chips_s and hdata.chips_s.main
	-- local chips_player = hdata and hdata.chips_s and hdata.chips_s.player
	-- local chips_dungeon = hdata and hdata.chips_s and hdata.chips_s.dungeon

	local bgmusic = self.mainGroup:getFuncflagValue('bgmusic')
	if bgmusic then self:setBGM(bgmusic) end

	--local data = Block.loadItemData(shapeid)
--[[
	local data = Block.loadItemData(filename)
	if data then
		self.funcflags = data.funcflags

		if data.chips_s then
			table.deep_clone(self.chips_s, data.chips_s)
		end

		self:load_block_and_chip(data)

		if data.funcflags.bgmusic then
			self:setBGM(data.funcflags.bgmusic)
		end
	end
--]]

	self.isPlaying = false
	self.isPaused = false

	-- print('TTTTTTTTTTTTTTTTTTTTTTTT', _tick() - tick)
end

Dungeon.getDungeonType = function(self)
	return self.mainGroup:getFuncflagValue('blocktype') or 'scene'
end

Dungeon.is_paused = function(self)
	return self.isPaused
end

-- Dungeon.setRoomVisible = function(self, room, visible)
-- 	if room == nil or room.visible == visible then return end

-- 	room.visible = visible
-- 	for i, v in ipairs(room.elements) do
-- 		if v.block then
-- 			if visible then
-- 				assert(v.oldvisible ~= nil and v.oldphisic ~= nil)
-- 				v.block:setVisible(v.oldvisible, v.oldphisic)
-- 				v.block.backgroundtouchable = v.oldbackground
-- 				v.oldvisible = nil
-- 				v.oldphisic = nil
-- 				v.oldbackground = nil
-- 			else
-- 				v.oldvisible = v.block.node.visible
-- 				v.oldphisic = v.block:isPhysic()
-- 				v.oldbackground = v.block.backgroundtouchable
-- 				v.block:setVisible(false, false)
-- 				v.block.backgroundtouchable = false
-- 			end
-- 		end
-- 	end
-- end

-- Dungeon.setCurrentRoom = function(self, index)
-- 	if self.randomroom then return end

-- 	if self.currentRoom and self.currentRoom ~= self.rooms[index] then
-- 		self:setRoomVisible(self.currentRoom, false)
-- 	end
-- 	self.currentRoom = self.rooms[index]
-- 	self:setRoomVisible(self.currentRoom, true)
-- 	Global.CameraControl:get():setInsideArea(-0.4, (self.currentRoom.height - 1) * 0.8 + 0.4, self.currentRoom.width * 0.8 - 0.4, -0.4)
-- end

Dungeon.save = function(self, filename)
	-- TODO.
end

Dungeon.is_playing = function(self)
	return self.isPlaying
end
Dungeon.player_runChips = function(self)
	local hdata = self.mainGroup:getHelperData()
	local chips = hdata and hdata.chips_s and hdata.chips_s.player
	if chips then
		local ps = self:get_players()
		for i, p in ipairs(ps) do
			BContext.RunChips(p, chips)

			p:chip_call_event('GameBegin')
		end
	end
end
Dungeon.load_ready = function(self)
	print('[xxxxx]Dungeon load_ready', self)
	self:player_runChips()

	-- for i, r in ipairs(self.mainGroup:getChildren()) do
	-- 	r:runChips()
	-- end

	self:runChips()

	local bs = self.mainGroup:getBlocks()
	-- print('[xxxxx]Dungeon load_ready2', #bs)
	for i, b in ipairs(bs) do
		b.bbindex = i
		--print('!!', i, b.node.needUpdate)
	end
end
Dungeon.start = function(self)

	self.isPlaying = true
	Global.SwitchControl:set_input_on()
	Global.FrameSystem:enable_logic(true)

	self:playBGM()

	if self.onStartFunc then
		self.onStartFunc()
	end

	print('[xxxxx]Dungeon start', self)
	if self.chip_gameBegin then
		self.chip_gameBegin(self)
	end

	local cs = self.mainGroup:getChildren()
	for i, v in ipairs(cs) do
		if v.chip_gameBegin then
			v.chip_gameBegin()
		end
	end

	self:initBgRoomData()
end
Dungeon.over = function(self)
	if not self.isPlaying then return end
	self.isPlaying = false

	if self.mode.online then
		Global.KCP_Net:close()
	end

	if self.onOverFunc then
		self.onOverFunc()
	end

	self:ui_hide()
	Global.EntityManager:clear()
	Global.InputManager:init()
	Global.dungeon = nil

	-- TODOGG1 use chip
	Global.Role.animaStateClass = _dofile('anima.lua')
	_dofile('role_new_base.lua')
	_gc()
end

Dungeon.pause = function(self)
	if self.isPaused == true then return end

	self.isPaused = true
	Global.FrameSystem:Pause(true)
	Global.EntityManager:pause(true)

	self:pauseBGM()
	if self.onPauseFunc then
		self.onPauseFunc()
	end
end
Dungeon.show_pause_menu = function(self)
	if self.inner_data.is_ended then
		return
	end

	if self.mode.online then
	else
		self:pause()
	end

	self:ui_show_pause()
end

Dungeon.resume = function(self)
	if self.isPaused == false then return end

	self.isPaused = false

	Global.FrameSystem:Pause(false)
	Global.EntityManager:pause(false)
	self:resumeBGM()
	if self.onResumeFunc then
		self.onResumeFunc()
	end

	self:ui_show_game()
end
--------------------------------------------------------
Dungeon.restart = function(self)
	Global.entry:popStack()
	self:over()
	self.mode.restart_func()
end
--------------------------------------------------------
Dungeon.registerGameBegin = function(self, f)
	self.chip_gameBegin = f
end
--------------------------------------------------------

Dungeon.registerStartCallback = function(self, cb)
	self.onStartFunc = cb
end

Dungeon.registerOverCallback = function(self, cb)
	self.onOverFunc = cb
end

Dungeon.registerPauseCallback = function(self, cb)
	self.onPauseFunc = cb
end

Dungeon.registerResumeCallback = function(self, cb)
	self.onResumeFunc = cb
end

Dungeon.prepare_to_start = function(self)
	print('prepare to', self.mode.online)
	if self.mode.online then
	else
		Global.InputSender:start()
	end
	Global.FrameSystem:Pause(false)

	Global.FrameSystem:enable_logic(false)

	if _sys:getGlobal('xl') then

		self:start()

	else

		Global.ScreenEffect:showPfx('countdown')
		Global.FrameSystem:NewTimer_Base(5000, function()
			Global.ScreenEffect:showPfx()
			-- Global.Role.gravity_set(g)
			-- self.mainPlayer.showpfx:stop(true)
			-- Global.SwitchControl:set_input_on()
			self:start()
			-- for i, v in ipairs(self.players) do
			-- 	v:ai_start()
			-- 	v.showpfx:stop(true)
			-- end
		end)

	end
end
Dungeon.try_start = function(self)
	-- print('try_start', self.inner_data.started, self.inner_data.frame_count)
	if self.inner_data.tried then
		return
	end

	local data = self.inner_data
	data.frame_count = data.frame_count + 1
	if data.frame_count < 3 then
		return
	end

	data.tried = true

	if self.mode.online then
		Global.InputSender:init()
		Global.FrameSystem:init2()

		Global.KCP_Net:connect(function(net)
			print('connected kcp', net)
			Global.Room_New:Ready()
		end, function(net, data)
--			print('kcp recv', net)
			for _, inputs in ipairs(data) do
				Global.FrameSystem:AddInput(inputs)
			end
		end, function()
			print('kcp disconnect')
			Global.KCP_Net:close()
		end)
	else
		self:prepare_to_start()
	end
end

Dungeon.update = function(self, e)
	-- print('update', self.inner_data.started, self.inner_data.frame_count)

	self:try_start()

	local index
	local rolepos = Global.role:getPosition_const()
	local is_2d = self:is_2D() 
	local is_music = self:is_Music()

	local cs = self.mainGroup:getChildren()

	local camera = Global.CameraControl:get()
	local cam_dir = _rd.camera:dir()

	for i, r in ipairs(cs) do
		r:updatePos(e)

		-- room vs Global.role todo rooms vs players
		if not r:isBgRoom() and not index and r.funcs_enter and #r.funcs_enter > 0 and r:inside(rolepos) then
			index = i
		end

		-- todo use ray distance / camera frustum pick
		if is_2d then
			if r:isBgRoom() then
				r:activeRoom(true)
				r:enableRoom(true)
			else
				-- local dis = r:get_distance(_rd.camera.look)
				-- local dis = r:get_distance_ray(_rd.camera.eye, cam_dir)
				local disr = r:get_distance_ray(_rd.camera.eye, cam_dir)
				-- print('~~~~~~~~~~~~~dis', i, dis, disr)
				-- print('#############', dis < 12, disr < 0.25, dis < 20, disr < 1)

				if disr < 2 then
					r:fillData()
					r:activeRoom(true)
				else
					r:activeRoom(false)
				end
				if disr < 1 then
					r:enableRoom(true)
				else
					r:enableRoom(false)
				end
			end
		elseif is_music then
			if r:isBgRoom() then
				-- r:activeRoom(true)
				-- r:enableRoom(true)
			else
				local name = r.hdata and r.hdata.funcflags.blockname
				if name == 'pole' then -- 音乐杆子
					r:enableRoom(r:get_distance(rolepos) < Global.MUSIC_VIEWFAR)
				elseif name == 'runway' then -- 音乐跑道
					r:enableRoom(r:get_distance(rolepos) < Global.MUSIC_VIEWFAR)
				else
					-- r:activeRoom(false)
				end
			end
		end
	end

	--if self.bgRoomInited then
		self:updateBgRooms(_rd.camera.look)
	--end

	if self.lastRoomIndex ~= index then
		if self.lastRoomIndex then
			cs[self.lastRoomIndex]:onLeave(Global.role)
		end

		if index then
			-- print('!!!!!Dungeon Enter', index, cs[index].data.shape)
			cs[index]:onEnter(Global.role)
		end

		self.lastRoomIndex = index
	end

	self:ui_update_timer()
end

Dungeon.show_result = function(self, role, result)
	role.attrs_readonly_keys['Rank'] = true
	role.attrs_readonly_keys['Score'] = true

	if role == Global.role then
		self.inner_data.is_ended = true
		if not role.is_dead then
			if result == 'Win' then
				role:playAnima('win')
			else
				role:playAnima('sad')
			end
		end
		self:ui_show_result(result)
		self:stopBGM()
		role:clear_move_event()
		Global.SwitchControl:set_input_off()
		Global.FrameSystem:Pause(true)
		if self.mode.data1 == 'neverup' then
			Global.Room_New:Single_Record('Neverup_single', role:attr_get('Score'), self.mode.eid)
		end
		if self.mode.online then
			Global.Room_New:DoOp({act = 'finish'})
		end

		if not self.mode.test then
			if self.mode.obj then
				RPC('UpdateObject_Scene', {Oid = self.mode.obj.id, Op = 'finish'})
			end
		end
	end
end
--[[
Dungeon.addElement = function(self, e, room)
	room = room or self.currentRoom
	if self:indexElement(e) == -1 then
		table.insert(room.elements, e)
	end
end

Dungeon.indexElement = function(self, e, room)
	room = room or self.currentRoom
	for i, v in ipairs(room.elements) do
		if v == e then return i end
	end
	return -1
end

Dungeon.getElementByBlock = function(self, b, room)
	room = room or self.currentRoom
	for i, v in ipairs(room.elements) do
		if v.block == b then return v end
	end
end

Dungeon.delElement = function(self, e, room)
	room = room or self.currentRoom
	e:delBlock()
	table.remove(room.elements, self:indexElement(e))
end

Dungeon.createElement = function(self, data)
	local element = Global.ElementManager:createElement(self, data)
	self:addElement(element)
	return element
end

Dungeon.createBGElement = function(self, data)
	local element = Global.ElementManager:createElement(self, data)
	table.insert(self.bgelements, element)
	return element
end

Dungeon.getElements = function(self, elements)
	for i, v in ipairs(self.currentRoom.elements) do
		table.insert(elements, v)
	end
end
--]]
Dungeon.setBGM = function(self, name)
	if not name or name == nil then return end

	local music = Global.AudioPlayer:getSourceByName('default', name)
	music:prepare()
	--Global.AudioPlayer:setCurrent2D(music)
	self.bgm = music:getFileName()
end

Dungeon.playBGM = function(self)
	if self.bgm == nil then return end

	-- Global.AudioPlayer:play2D()

	self.bgmsound = self.bgmsound or _SoundGroup.new()
	self.bgmsound:stop()
	self.bgmsound:play(self.bgm, _SoundDevice.Loop)
end

Dungeon.stopBGM = function(self)
	if self.bgm == nil or self.bgmsound == nil then return end

	self.bgmsound:stop(_SoundDevice.FadeOut)
	-- Global.AudioPlayer:stop2D()
end

Dungeon.pauseBGM = function(self)
	if self.bgm == nil or self.bgmsound == nil then return end

	self.bgmsound.mute = true
	--Global.AudioPlayer:setMute(true)
end

Dungeon.resumeBGM = function(self)
	if self.bgm == nil or self.bgmsound == nil then return end

	self.bgmsound.mute = false
	--Global.AudioPlayer:setMute(false)
end

---------------------------------------------
Dungeon.doOperation = function(self, data)
	if not data then return end
	local act = data.act
	print('Dungeon.doOperation', act)
	if act == 'die' then
	elseif act == 'move' then
		local r = Global.EntityManager:get_role(data.aid)
		r:set_input(data.data)
	elseif act == 'input' then
		-- print('====input', data.data.fid)
		for _, inputs in ipairs(data.data) do
			Global.FrameSystem:AddInput(inputs)
		end
	elseif act == 'leader' then
		self:addAI(data.data.aid)
	end
end
---------------------------------------------
_G.CreateDungeon = function(shapeid)
	Dungeon.new(shapeid)
end

-- chip -----------------------------------------------------
Dungeon.update_score = function(self, p)
	self:ui_update_score(p)

	local ps = self:get_players()
	table.sort(ps, function(a, b)
		return a:attr_get('Score') > b:attr_get('Score')
	end)

	local score
	local rank = 1
	for i, v in ipairs(ps) do
		if v:attr_get('Score') ~= score then
			score = v:attr_get('Score')
			rank = i
		end
		v:attr_set('Rank', rank)
	end
end

return Dungeon