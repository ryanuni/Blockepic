
local R = Global.Role
local B = Global.Block
local SG = _G.BlockSubGroup

local ENUM_COLLIDE_FACE = {
    Top = 1,
    Bottom = 2,
    Side = 3,
    All = 0,
    None = -1,
}
B.set_collide_face = function(self, dir)
    if dir == 'None' then
        self:enablePhysic(false)
    else
        self:enablePhysic(true)
        dir = ENUM_COLLIDE_FACE[dir]
        for _, v in ipairs(self.shapes) do
			v:collideFace(dir)
		end
    end
end
SG.set_collide_face = function(self, dir)
	print('!!!SG.set_collide_face', type)
	local b = self:getBlock()
	if not b then return end

	if dir == 'None' then
		b:enablePhysic(false)
	else
		b:enablePhysic(true)
		dir = ENUM_COLLIDE_FACE[dir]
		local shapes = self:getShapes()
		for _, v in ipairs(shapes) do
			v:collideFace(dir)
		end
	end
end
R.set_collide_face = function(self, dir)
    print('[NYI] cct collide face!', debug.traceback())
end
------------------------------------------------------------
local ENUM_COLLIDE_TYPE = {
    Object = 0x1,
    Player = 0x2,
    All = 0xffff,
    NoBlock = 0x8000,
}
B.set_collide_type = function(self, type, noblock)
--    print('!!!B.set_collide_type', type, noblock, self, debug.traceback())
    local id = ENUM_COLLIDE_TYPE.Object
    type = ENUM_COLLIDE_TYPE[type]
    if noblock then
        self:enablePhysic(false)
        self.tmp_xl_need_check_noblock = type
        self:enable_node_update(true)
    else
        self.tmp_xl_need_check_noblock = false
    end

    if type ~= 0 then
        for _, v in ipairs(self.shapes) do
            v:collisionGroup(id, type)
            v:queryGroup(id, type)
        end
    end
end
SG.set_collide_type = function(self, type, noblock)
	print('!!!SG.set_collide_type', type)
	local b = self:getBlock()
	if not b then return end
	local shapes = self:getShapes()
	local id = ENUM_COLLIDE_TYPE.Object
	type = ENUM_COLLIDE_TYPE[type]
    if noblock then
        for _, v in ipairs(shapes) do
            shapes.trigger = true
        end
        self.tmp_xl_need_check_noblock = type
        self:enable_node_update(true)
    else
        self.tmp_xl_need_check_noblock = false
    end

    if type ~= 0 then
        for _, v in ipairs(shapes) do
            v:collisionGroup(id, type)
            v:queryGroup(id, type)
        end
    end
end
R.set_collide_type = function(self, type, noblock)
    if not self.cct then
        self:createCCT()
    end

    local id = ENUM_COLLIDE_TYPE.Player
    type = ENUM_COLLIDE_TYPE[type]
    self.cct:collisionGroup(id, type)
    self.cct:queryGroup(id, type)
end
------------------------------------------------------------
local b_funcs = {}
b_funcs.Collide = function(b, params)
    local v = params[1].Value
    -- vs obj
    if _and(v, ENUM_COLLIDE_TYPE.Object) then
        b:enable_node_update(true)
    end
    -- vs cct
    if _and(v, ENUM_COLLIDE_TYPE.Player) then
        b:enable_collide_vs_cct_cb(true)
    end
end
local obj_vs_cct_cb = function(shape, cct, x, y, z, dx, dy, dz)
    local b = shape.actor.node.block
    assert(cct.role, 'cct.role is nil')
    b:do_collide(cct.role, shape, dx, dy, dz)
end
B.enable_collide_vs_cct_cb = function(self, e)
    if e then
        self.node.needUpdate = true
        for _, v in ipairs(self.shapes) do
            v:onCollisionWithController(obj_vs_cct_cb)
        end
    else
        self.node.needUpdate = false
        for _, v in ipairs(self.shapes) do
            v:onCollisionWithController()
        end
    end
end
local v1 = _Vector3.new()
v1:set(0, 0, -1)
B.check_collision = function(self, speed)
    speed = speed or v1
    -- dir:set(speed)
    -- local step = dir:magnitude()
    -- dir:normalize()

    local sweeps = {}

    local flag = 0
    if self.tmp_xl_need_check_noblock then
        flag = self.tmp_xl_need_check_noblock
    end
    if self.node.scene:physicsOverlapMulti(self.actor, flag, sweeps) then
        for i, v in ipairs(sweeps) do
            local shape1 = self.shapes[v.shapeindex + 1]
            local shape2 = v.shape
            local target, shape
            if shape2.actor then
                target = shape2.actor.node.block
                shape = shape2
            else
                target = shape2.controller.role
            end

            self:do_collide(target, shape1, speed.x, speed.y, speed.z)
            if not target.aid then
                target:do_collide(self, shape, -speed.x, -speed.y, -speed.z)
            end
        end
    end
end
B.check_collision_overlap = function(self)
    local sweeps = {}

    if self.node.scene:physicsOverlapMulti(self.actor, 0xff, sweeps) then
        for i, v in ipairs(sweeps) do
            local shape1 = self.shapes[v.shapeindex + 1]
            local shape2 = v.shape
            local target, shape
            if shape2.actor then
                target = shape2.actor.node.block
                shape = shape2
            else
                target = shape2.controller.role
            end

			-- print('!!!check_collision_overlap', i, target)
            -- self:do_collide(target, shape1, sweeps.normal.x, sweeps.normal.y, sweeps.normal.z)
            -- target:do_collide(self, shape, -sweeps.normal.x, -sweeps.normal.y, -sweeps.normal.z)
            self:do_collide(target, shape1, 0, 0, 1)
            target:do_collide(self, shape, 0, 0, -1)
        end
    end
end
B.enable_node_update = function(self, e)
    if e then
        self.node.needUpdate = true
    else
        self.node.needUpdate = false
    end
end
B.init_event = function(self, event, params)
    if b_funcs[event] then
        b_funcs[event](self, params)
    end
end
SG.init_event = B.init_event
_G.DungeonGroup.init_event = B.init_event

SG.enable_node_update = function(self, e)
	if not self:getBlock() then return end
    if e then
        self:getBlock().node.needUpdate = true
    else
        self:getBlock().node.needUpdate = false
    end
end

SG.enable_collide_vs_cct_cb = function(self, e)
	local block = self:getBlock()
	if not block then return end

    if e then
        block.node.needUpdate = true
		local shapes = self:getShapes()
        for _, v in ipairs(shapes) do
            v:onCollisionWithController(obj_vs_cct_cb)
        end
    else
        block.node.needUpdate = false
		local shapes = self:getShapes()
        for _, v in ipairs(shapes) do
            v:onCollisionWithController()
        end
    end
end
------------------------------------------------------------
local funcs = {}
funcs.do_collide = function(o, target, shape, dx, dy, dz)
    if not o.rtdata.collision_data then
		o.rtdata.collision_data = {}
	end

	-- calc dir
	local p_type = 'Side'
	if dx == 0 and dy == 0 then
		if dz < 0 then
			p_type = 'Top'
		else
			p_type = 'Bottom'
		end
	end

    local key = 'counter_' .. p_type
	local cd = o.rtdata.collision_data
    if not cd[target] then
        cd[target] = {
            counter_Top = -1,
            counter_Bottom = -1,
            counter_Side = -1,
            shape = shape
        }
    end

    if cd[target][key] >= 0 then
        cd[target][key] = 1
        return
    end

    cd[target][key] = 1

    -- if o == Global.role then
    --     print('[do_collide]', p_type, o, target, dx, dy, dz)
    -- end

	if not o.chip_call_event then
		print('[NYI]self.chip_call_event is nil', debug.traceback())
		return
	end

	o:chip_call_event('Collide', target, p_type)

    if shape and shape.bind_subg then
		for obj in pairs(shape.bind_subg) do
			obj:chip_call_event('Collide', target, p_type)
		end
	end

    return true
end
funcs.update_collide = function(o)
    local cd = o.rtdata.collision_data
    if cd == nil then
        return
    end

    -- print('[update_collide]', o)
    for target, d in next, cd do
        -- if o == Global.role then
        --     print('[update_collide]', d.counter_Top, d.counter_Bottom, d.counter_Side, target)
        -- end
        if d.counter_Top == 0 then
            o:do_seperate(target, 'Top')
        elseif d.counter_Top == 1 then
            d.counter_Top = 0
        end
        if d.counter_Bottom == 0 then
            o:do_seperate(target, 'Bottom')
        elseif d.counter_Bottom == 1 then
            d.counter_Bottom = 0
        end
        if d.counter_Side == 0 then
            o:do_seperate(target, 'Side')
        elseif d.counter_Side == 1 then
            d.counter_Side = 0
        end
    end
end
funcs.do_seperate = function(o, target, p_type)
    -- if o == Global.role then
    --  print('[do_seperate]', p_type, o, target)
    -- end
    local cd = o.rtdata.collision_data[target]
    cd['counter_' .. p_type] = -1
    if cd.counter_Top == -1 and cd.counter_Bottom == -1 and cd.counter_Side == -1 then
        o.rtdata.collision_data[target] = nil
        -- if o == Global.role then
        --     print('[do_seperate] remove', target)
        -- end
    end

	o:chip_call_event('Seperate', target, p_type)

    local shape = cd.shape
	if shape and shape.bind_subg then
		for obj in pairs(shape.bind_subg) do
			obj:chip_call_event('Seperate', target, p_type)
		end
	end
end
------------------------------------------------------------
B.do_collide = function(self, target, shape, dx, dy, dz)
    funcs.do_collide(self, target, shape, dx, dy, dz)
end
B.update_collide = function(self)
	funcs.update_collide(self)
end
B.do_seperate = function(self, target, p_type)
	-- print('do_seperate', target, p_type)
	funcs.do_seperate(self, target, p_type)
end
------------------------------------------------------------
local r_funcs = {}
r_funcs.Collide = function(r, params)
    local v = params[1].Value
    -- vs obj
    if _and(v, ENUM_COLLIDE_TYPE.Object) then
        r:enable_node_update(true)
    end
    -- vs cct
    if _and(v, ENUM_COLLIDE_TYPE.Player) then
        r:enable_collide_vs_cct_cb(true)
    end
end
local cct_vs_cct_cb = function(cct1, cct2, x, y, z, dx, dy, dz)
    cct1.role:do_collide(cct2.role, nil, dx, dy, dz)
end
R.enable_collide_vs_cct_cb = function(self, e)
    if e then
        self.cct:onCollisionWithController(cct_vs_cct_cb)
    else
        self.cct:onCollisionWithController()
    end
end
local cct_vs_obj_cb = function(cct, shape, x, y, z, dx, dy, dz)
    local b = shape.actor.node.block
    cct.role:do_collide(b, nil, dx, dy, dz)
end
R.enable_node_update = function(self, e)
    if e then
        self.cct:onCollisionWithShape(cct_vs_obj_cb)
    else
        self.cct:onCollisionWithShape()
    end
end
R.init_event = function(self, event, params)
    if r_funcs[event] then
        r_funcs[event](self, params)
    end
end
------------------------------------------------------------
R.do_collide = function(self, target, shape, dx, dy, dz)
    funcs.do_collide(self, target, shape, dx, dy, dz)
end
R.update_collide = function(self)
    funcs.update_collide(self)
end
R.do_seperate = function(self, target, p_type)
    funcs.do_seperate(self, target, p_type)
end
------------------------------------------------------------
Global.TEMP_ROLE_NEW.init_event = R.init_event
Global.TEMP_ROLE_NEW.do_collide = R.do_collide
Global.TEMP_ROLE_NEW.do_seperate = R.do_seperate
Global.TEMP_ROLE_NEW.enable_node_update = R.enable_node_update
Global.TEMP_ROLE_NEW.enable_collide_vs_cct_cb = R.enable_collide_vs_cct_cb