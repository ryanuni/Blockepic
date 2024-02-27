local SoundGroup = _require('SoundGroup')

_G.BContext = {}
_G.BChip = {}

local dir_config = {
    l = _Vector3.new(1, 0, 0),
    r = _Vector3.new(-1, 0, 0),
    t = _Vector3.new(0, 0, 1),
    b = _Vector3.new(0, 0, -1),
    lt = _Vector3.new(1, 0, 1),
    rt = _Vector3.new(-1, 0, 1),
    rb = _Vector3.new(-1, 0, -1),
    lb = _Vector3.new(1, 0, -1),
    o = _Vector3.new(0, 0, 0),

    op_map = {
        ['←'] = 'l',
        ['↖'] = 'lt',
        ['↑'] = 't',
        ['↗'] = 'rt',
        ['→'] = 'r',
        ['↘'] = 'rb',
        ['↓'] = 'b',
        ['↙'] = 'lb',
    },
}

local CHIP_RULES = {
    valid = {
        number = { number = true },
        vector = { number = true, vector = true },
        enum   = { number = true },
    },

    def_math_func = function(f_n_n, f_v_n, f_v_v) -- a + b
        return function(a, b)
            if is_num(a) then
                if is_num(b) then
                    return f_n_n(a, b)
                else
                    assert(false, 'invalid op', a, b)
                end
            elseif is_vec3(a) then
                if is_num(b) then
                    return f_v_n(a, b)
                elseif is_vec3(b) then
                    return f_v_v(a, b)
                else
                    assert(false, 'invalid op', a, b)
                end
            end
        end
    end,

    dir_cam_space = function(dir, usecam)
        if Global.dungeon:is_2D() then
            local d = CHIP_PARAM_CONFIG.direction[dir].value
            if not usecam then return d end
            -- do return d end

            local r = _Vector3.new()
            local u = _Vector3.new()

            local cam = _rd.camera
            _Vector3.mul(cam:right(), -d.x, r)
            _Vector3.mul(cam.up, d.z, u)

            return r:add(u)
        else
            local cfg = CHIP_PARAM_CONFIG.direction[dir]
            local d = cfg.v3d or cfg.value
            if not usecam then return d end

            local f = _Vector3.new()
            local r = _Vector3.new()
            local u = _Vector3.new()
            local cam = _rd.camera
            _Vector3.mul(cam:right(), -d.x, r)
            _Vector3.mul(cam:dir(), d.y, f)
            _Vector3.mul(cam.up, d.z, u)

            r.z = 0
            f.z = 0
            u.x = 0
            u.y = 0

            r:normalize()
            f:normalize()
            u:normalize()

            return r:add(f):add(u)
        end
    end,
}

local function normalize(vec)
    return vec:clone():normalize()
end

local math_op = {
    -- f_n_n, 
    -- f_v_n, 
    -- f_v_v

    add = CHIP_RULES.def_math_func(
        function(a, b) return a + b end,
        function(a, b) return a:add(normalize(a):mul(b)) end,
        function(a, b) return a:add(b) end
    ),

    sub = CHIP_RULES.def_math_func(
        function(a, b) return a - b end,
        function(a, b) return a:sub(normalize(a):mul(b)) end,
        function(a, b) return a:sub(b) end
    ),

    mul = CHIP_RULES.def_math_func(
        function(a, b) return a * b end,
        function(a, b) return a:mul(b) end,
        function(a, b) return _Vector3.new(a.x*b.x, a.y*b.y, a.z*b.z) end
    ),

    div = CHIP_RULES.def_math_func(
        function(a, b) return a / b end,
        function(a, b) return a:mul(1/b) end,
        function(a, b) return _Vector3.new(a.x/b.x, a.y/b.y, a.z/b.z) end
    ),

    dir = function(dir, usecam)
        return CHIP_RULES.dir_cam_space(dir, usecam)
    end,
}
local ParamProcesser
ParamProcesser = {
    op_number = function(input, param)
        local op = param.Op
        local v = CHIP_PARAM_CONFIG.number.get_value(param) or assert(false)
        if op == 'Add' then
            return math_op.add(input, v)
        elseif op == 'Sub' then
            return math_op.add(input, -v)
        elseif op == 'Mul' then
            return math_op.mul(input, v)
        elseif op == 'Div' then
            return math_op.mul(input, 1/v)
        elseif op == 'Set' then
            return v
        end
    end,

    op_direction = function(input, param)
        return math_op.dir(param.Value, param.Op == '')
        -- return dir_config[param.Value]
    end,

    op_enum = function(input, param)
        if type(input) == 'number' then
            -- todo _G.ParamProcesser
            -- return ParamProcesser.op_number(input, param)
        end

        local op = param.Op
        local v = param.Value

        if op == 'Add' then
            input[v] = true
        elseif op == 'Sub' then
            input[v] = false
        elseif op == 'Set' then
            input = {}
            input[v] = true
        end

        return input
    end,

    -- TODO bind obj.attr to context
    op_formula = function(input, param, ps)
        local op = param.Op
        local v = ps
        if op == 'Add' then
            return math_op.add(input, v)
        elseif op == 'Sub' then
            return math_op.sub(input, v)
        elseif op == 'Mul' then
            return math_op.mul(input, v)
        elseif op == 'Div' then
            return math_op.div(input, v)
        elseif op == 'Set' then
            return v
        end
    end,

    op_millis = function(input, t)
        return t
    end,
    op_time = function(input, t)
        return t
    end,

    op_func = function(input, param, ps)
        local f = _G.CHIP_PARAM_CONFIG.func[param.Value].func
        return f(input, ps)
    end,

    op_condition = function(input, param, ps)
        local op = _G.CHIP_PARAM_CONFIG.condition[param.Op].func
        return op(ps[1], ps[2])
    end,

    op_set = function(input, param)
        Global.AttrManager:Set(CHIP_PARAM_CONFIG.set.get_value(param), input)
        return 'skip_assignment'
    end,

    op_get = function(input, param)
        return Global.AttrManager:Get(CHIP_PARAM_CONFIG.get.get_value(param))
    end,

    op_Gset = function(input, param)
        Global.AttrManager:Set(CHIP_PARAM_CONFIG.set.get_value(param), input)
        return 'skip_assignment'
    end,

    op_Gget = function(input, param)
        return Global.AttrManager:Get(CHIP_PARAM_CONFIG.get.get_value(param))
    end,
}

ParamProcesser.op_process = function(value, param)
    local funcname = 'op_' .. param.Type -- op_number
    local func = ParamProcesser[funcname]
    assert(func)
    return func(value, param)
end

ParamProcesser.op_process_param = function(value, param)
    local funcname = 'op_' .. param.Type -- op_number
    local func = ParamProcesser[funcname]
    assert(func)

    local ps
    if param.sub_params then
        if param.Type == 'formula' then -- 公式按状态机计算
            ps = ParamProcesser.op_process_params(ps, param.sub_params)
        else -- func/condition 参数列表每个元素单独计算，再调用函数
            ps = {}
            for i, p in ipairs(param.sub_params) do
                local r = ParamProcesser.op_process_param(nil, p) -- nil????
                table.insert(ps, get_refv(r)) -- 这里没用引用，用的值，如果需要可以继续延后解引用操作
            end
        end
    end

    return func(value, param, ps)
end

ParamProcesser.op_process_params = function(v, params)
    for i, p in ipairs(params) do
        if is_ref(v) then
            local r = ParamProcesser.op_process_param(v:Get(), p)
            if r ~= 'skip_assignment' then -- 没有返回值
                if v.isReadOnly then
                    v = r
                elseif is_ref(r) then -- 取代当前引用 
                    -- v:Set(r:Get()) 同时设置给v?
                    v = r
                else
                    v:Set(r) -- nil/false/...
                end
            end
        else
            local r = ParamProcesser.op_process_param(v, p)
            if r ~= 'skip_assignment' then
                v = r
            end
        end
    end

    return get_refv(v)
end

local CONTEXT = {
    funcss = {},
    REG = {
        dungeon = nil,
        attribute = nil,
        element = nil,
        self = nil,
        target = nil,
        direction = nil,
    },

    getFunc = function(self, i1, i2)
        return self.funcss[i1 or 1][i2 or 1]
    end,

    doFunc = function(self)
        for i, fs in ipairs(self.funcss) do
            if fs[1] then fs[1]:excute() end
        end
        --print('!!!! excute', #self.funcss)
    end,
}

CONTEXT.copy = function(self)
    local c = { funcss = {}, REG = {} }
    setmetatable(c, { __index = CONTEXT })
    c.funcss = self.funcss
    c.REG = self.REG
    c.cur_self = self.cur_self
    return c
end

BContext.new = function(obj, funcs)
    local c = { funcss = {}, REG = {} }
    setmetatable(c, { __index = CONTEXT })
    c.REG.dungeon = Global.dungeon
    c.REG.allplayers = Global.dungeon.players
    c.REG.scene = Global.sen
    c.REG.self = obj
    c.REG.funcs = funcs
    c.REG.target = nil
    c.cur_self = c.REG.self
    local fss = {}
    for fi, func in ipairs(funcs) do
        local fs = {}
        for i, bf in ipairs(func) do
            fs[#fs+1] = BChip.new(bf, c)
        end

        for i = 1, #fs - 1 do
            fs[i]:link(fs[i+1])
        end
        fss[#fss+1] = fs
    end

    c.funcss = fss
    
    return c
end

BContext.RunChips = function(obj, chipss)
    -- print('BContext.RunChips', obj, chipss)
    local css = chipss or (obj.chips_s and obj.chips_s.main)
    if not css or #css == 0 then return end
    if not obj.chip_contexts then obj.chip_contexts = {} end
    local c = BContext.new(obj, css)
    c:doFunc()

    table.insert(obj.chip_contexts, c)
end

-------------------------------------------------------------
local function collide_check_param(params, p_target, p_type)
    local p1 = params[1].Value
    -- print('collide_check_param', p1, params[2].Value, p_target.aid, p_type)

    if p1 == 'All' then
    elseif p1 == 'Player' then
        if not p_target.aid then
            return
        end
    elseif p1 == 'Object' then
        if p_target.aid then
            return
        end
    end
    
    local p2 = params[2].Value
    if p2 == 'All' then
    else
        if p2 ~= p_type then
            return
        end
    end

    return true
end

-- functions
local CHIP = {
    Context = nil,
    Next = nil,
    Prev = nil,

    Name = nil,
    Value = nil,
    params = nil,
    
    link = function(self, chip)
        self.Next = chip
        chip.Prev = self
    end,
    
    excute = function(self)
    --    print('!!!!!@@@@@@@@@@[execute]', self.Name, table.ftoString(self.params))
        self:select_target()
        if self.Name and self[self.Name](self) ~= 'skip' and self.Next then
            self.Next:excute()
        end
    end,

    select_target = function(self)
        if not self.ActTarget or type(self.ActTarget)~='table' then return end -- old version
        local context = self.Context
        Global.AttrManager:SetCurrentContext(context)
        local t = _G.CHIP_TARGETS[self.ActTarget.target](context)

        -- 这个结果是数组或obj
        -- print('context.cur_self', table.ftoString(self.ActTarget.params or {}), self.ActTarget.target, context.cur_self, context.REG.self, context.REG.target)
        context.cur_self = ParamProcesser.op_process_params(t, self.ActTarget.params or {})
    end,

    run_sub_chips = function(self, target)
        if self.sub_chips then
            self.SubContext = BContext.new(self.Context.cur_self, { self.sub_chips })
            self.SubContext.REG.target = target or self.Context.REG.target
            self.SubContext:doFunc()
        end
    end,

    GameBegin = function(self)
        local context = self.Context
        context.cur_self:registerGameBegin(function()
            print('[xxxxxxxxxxx]onstart', context.cur_self)
            self:run_sub_chips()
		end)
	end,

	Collision = function(self)
		print('Delete useless chip!!', debug.traceback())
	end,
	CollideType = function(self)
		local obj = self.Context.cur_self
        local type = self.params[1].Value
        local noblock = false
        if self.params[2] and self.params[2].Value == 'NoBlock' then
            noblock = true
        end
		if obj.typestr == 'DungeonGroup' then
			local bs = obj:getBlocks()
			for i, b in ipairs(bs) do
				b:set_collide_type(type, noblock)
			end
		else
			obj:set_collide_type(type, noblock)
		end
	end,
	CollideFace = function(self)
		local obj = self.Context.cur_self
		if obj.typestr == 'DungeonGroup' then
			local bs = obj:getBlocks()
			for i, b in ipairs(bs) do
				b:set_collide_face(self.params[1].Value)
			end
		else
			obj:set_collide_face(self.params[1].Value)
		end
	end,

	Collide = function(self)
		local context = self.Context
		local obj = context.cur_self

		local function cb(p_target, p_type)
			-- check param
            -- print('collide cb', debug.traceback())
            -- print('collide cb', obj, p_target, p_type)
			if collide_check_param(self.params, p_target, p_type) then
				context.REG.target = p_target
				self:run_sub_chips(p_target)
                -- print('~~~~ok', obj.attrs.Ground, obj.cct.collisionFlag)
			end
		end
		if obj.typestr == 'BlockSubGroup' then
			local shapes = obj:getShapes()
			for _, v in ipairs(shapes or {}) do
				if not v.bind_subg then v.bind_subg = {} end
				v.bind_subg[obj] = true
			end
			context.cur_self:chip_register_event('Collide', self.params, cb)
		elseif obj.typestr == 'DungeonGroup' then
			local bs = obj:getBlocks()
			for i, b in ipairs(bs) do
				b:chip_register_event('Collide', self.params, cb)
			end
		else
			context.cur_self:chip_register_event('Collide', self.params, cb)
		end
	end,

    Seperate = function(self)
        local context = self.Context
		local obj = context.cur_self

		local function cb(p_target, p_type)
            -- check param
            -- print('seperate cb', debug.traceback())
            -- print('seperate cb', obj, p_target, p_type)
            if collide_check_param(self.params, p_target, p_type) then
                context.REG.target = p_target
                self:run_sub_chips(p_target)
                -- print('~~~~ok', obj.attrs.Ground, obj.cct.collisionFlag)
            end
        end
	
		if obj.typestr == 'BlockSubGroup' then
			local shapes = obj:getShapes()
			for _, v in ipairs(shapes or {}) do
				if not v.bind_subg then v.bind_subg = {} end
				v.bind_subg[obj] = true
			end
			context.cur_self:chip_register_event('Seperate', self.params, cb)
		elseif obj.typestr == 'DungeonGroup' then
			local bs = obj:getBlocks()
			for i, b in ipairs(bs) do
				b:chip_register_event('Seperate', self.params, cb)
			end
		else
			context.cur_self:chip_register_event('Seperate', self.params, cb)
		end
    end,

    Wait = function(self)
        local t = ParamProcesser.op_process_param(0, self.params[1])
        Global.FrameSystem:NewTimer_NoName(t, function()
            if self.Context.REG.dungeon == Global.dungeon then
                self:run_sub_chips()
            end
        end)
    end,

    Interval = function(self)
        local function func()
            local t = ParamProcesser.op_process_param(0, self.params[1])
            Global.FrameSystem:NewTimer_NoName(t, function()
                if self.Context.REG.dungeon == Global.dungeon then
                    self:run_sub_chips()
                    func()
                end
            end)
        end
        func()
    end,

    Repeat = function(self)
        local context = self.Context
        local value = self.params[1] and self.params[1].Value -- 'chip number' type
        if is_array(context.cur_self) then
            local limit = 0
            for i, v in ipairs(context.cur_self) do
                self:run_sub_chips(v) -- todo self
                limit = limit + 1
                if value and limit >= value then
                    break
                end
            end
        elseif tonumber(value) then
            for i = 1, toint(value) do
                self:run_sub_chips() -- todo self
            end
        end
    end,

    When = function(self)
        -- if self.pre_condition_result then return end
        local v = ParamProcesser.op_process_params(nil, self.params)
        if v then
            self:run_sub_chips()
        end

        if self.Next and self.Next.Name == 'WhenNot' then
            self.Next.pre_condition_result = v
        end
    end,

    WhenNot = function(self)
        -- else / elseif todo: if elseif elseif... else end
        if self.pre_condition_result then return end
        local v = #self.params == 0 or ParamProcesser.op_process_params(nil, self.params)
        if v then
            self:run_sub_chips()
        end

        -- if self.Next and self.Next.Name == 'When' then
            -- self.Next.pre_condition_result = v
        -- end
    end,

    WhenAnd = function(self)
        local v = #self.params > 0
        for i, p in ipairs(self.params) do
            v = v and ParamProcesser.op_process_param(nil, p)
        end

        if v then
            self:run_sub_chips()
        end

        if self.Next and self.Next.Name == 'WhenNot' then
            self.Next.pre_condition_result = v
        end
    end,

    WhenOr = function(self)
        local v
        for i, p in ipairs(self.params) do
            v = v or ParamProcesser.op_process_param(nil, p)
        end

        if v then
            self:run_sub_chips()
        end

        if self.Next and self.Next.Name == 'WhenNot' then
            self.Next.pre_condition_result = v
        end
    end,

    Break = function(self)
        return 'skip'
    end,

    ControlPush = function(self)
        local context = self.Context
        local p1 = _System[self.params[1].Value]
        Global.InputManager:registerDown(p1, function()
--            print('down ----', self.params[1].Value, p1)
            self:run_sub_chips()
        end)
    end,
    ControlRelease = function(self)
        local context = self.Context
        local p1 = _System[self.params[1].Value]
        Global.InputManager:registerUp(p1, function()
--            print('up ----', self.params[1].Value, p1)
            self:run_sub_chips()
        end)
    end,
    InputChange = function(self)
        local context = self.Context
        if #self.params == 1 then
            if self.params[1].Value == 'CamDir' then
                Global.InputManager:registerCameraChange(function()
                    self:run_sub_chips()
                end)
            else
                Global.InputManager:registerChange(_System[self.params[1].Value], function()
                    self:run_sub_chips()
                end)
            end
        else
            local camdir
            local keys = {}
            for i, p in ipairs(self.params) do
                if p.Value == 'CamDir' then
                    camdir = true
                else
                    keys[_System[p.Value]] = true
                end
            end

            if camdir then
                Global.InputManager:registerCameraChange(function()
                    self:run_sub_chips()
                end)
            end

            if next(keys) then
                Global.InputManager:registerChange(keys, function()
                    self:run_sub_chips()
                end)
            end
        end
    end,
    Die = function(self)
        local context = self.Context
        context.cur_self:chip_register_event('Die', nil, function()
            self:run_sub_chips()
        end)
    end,

    Enter = function(self) -- role enter room, target == room
        local context = self.Context
        -- print('~~~~~~~~~~room enter register', context.cur_self, debug.traceback())
        context.cur_self:registerEnter(function(role)
            -- if not self.params or not self.params[1] or is_a(role, self.params[1].Value) then
            context.REG.target = role
            -- print('ENTER !!!!!!!!!!!!!')
            self:run_sub_chips(role)
            -- end
        end)
    end,

    FirstEnter = function(self) -- role enter room, target == room
        local context = self.Context
        context.cur_self:registerEnter(function(role)
            context.REG.target = role
            self:run_sub_chips(role)
        end, true)
    end,

    Leave = function(self) -- role enter room, target == room
        local context = self.Context
        -- assert(is_a(context.cur_self, 'room'))
        context.cur_self:registerLeave(function(role)
            -- if not self.params or not self.params[1] or is_a(role, self.params[1].Value) then
            context.REG.target = role
            self:run_sub_chips(role)
            -- end
        end)
    end,

    Move = function(self)
        local context = self.Context
        local role = context.cur_self
        if role ~= Global.role then
            return
        end
--        print('chip move', role, Global.role, self.params[1].Value, self.params[2].Value)
        local p2 = self.params[2].Value
        if p2 == 'true' then
            p2 = true
        else
            p2 = false
        end
        role:do_move_event(self.params[1].Value, p2)
    end,
    Jump = function(self)
        -- local context = self.Context
        -- Global.role:jump()
    end,

    Target = function(self)
        local context = self.Context
        context.cur_self = context.REG.target
    end,

    Self = function(self)
        local context = self.Context
        context.cur_self = context.REG.self
    end,

    SetGroup = function(self)
        -- REG.self is a room
        -- self.Value is a param.variable
        -- self.Context.REG.resource:add(self.Value, self.Context.REG.self)
        local r = BAttr.new('Groups', {})
        if not r[self.Value] then r[self.Value] = {} end
        local rr = r[self.Value]
        table.insert(rr, self.Context.REG.self)
    end,

    Copy = function(self)
        -- copybox

        local v
        -- Global.AttrManager:SetCurrentObj(self.Context.REG.dungeon)
        local dir = 'b'
        local si = 1
        if self.params[1].Type == 'direction' then
            dir = self.params[1].Value
            si = 2
        end
        for i = si, #self.params do
            v = ParamProcesser.op_process_param(v, self.params[i])
        end

        -- todo copy <dungeon><get L1><random>
        local new_room = self.Context.REG.dungeon:copy_room(self.Context.cur_self, v, dir)
        self.Context.REG.newObj = new_room

        -- self.Context.REG.newObj = v:clone()
        -- self.Context.REG.newObj = self.Context.cur_self:copy(v)
    end,

    This = function(self)
        Global.AttrManager:Set(CHIP_PARAM_CONFIG.set.get_value(self.params[1]), self.Context.cur_self)
    end,

    Attribute = function(self)
        local v = ParamProcesser.op_process_params(nil, self.params)
        Global.AttrManager:Set(CHIP_PARAM_CONFIG.set.get_value(self.params[1]), v)
    end,

    AttributeChange = function(self)
        Global.AttrManager:registerAttributeChange(CHIP_PARAM_CONFIG.set.get_value(self.params[1]), self.params[2].Value, function()
            self:run_sub_chips()
        end)
    end,

    Variable = function(self)
        local v = ParamProcesser.op_process_params(nil, self.params)
        Global.AttrManager:Set(CHIP_PARAM_CONFIG.set.get_value(self.params[1]), v)
    end,

    VariableChange = function(self) -- TODO varchange
        Global.AttrManager:registerAttributeChange(CHIP_PARAM_CONFIG.set.get_value(self.params[1]), self.params[2].Value, function()
            self:run_sub_chips()
        end)
    end,

    Score = function(self)
        local context = self.Context
        local role = context.cur_self
        local v = role:attr_get('Score')
        v = ParamProcesser.op_process_params(v, self.params)
        role:attr_set_score(v)
    end,

    Rank = function(self)
        local role = self.Context.cur_self
        local v = role:attr_get('Rank')
        v = ParamProcesser.op_process_params(v, self.params)
        role:attr_set('Rank', v)
    end,

    Life = function(self)
        local context = self.Context
        local role = context.cur_self
        
        local v = role:attr_get('Life')
        v = ParamProcesser.op_process_params(v, self.params)

        role:attr_set_life(v)
    end,
    MaxLife = function(self)
        local context = self.Context
        local role = context.cur_self

        local v = role:attr_get('MaxLife')
        v = ParamProcesser.op_process_params(v, self.params)

        role:attr_set_maxlife(v)
    end,
    Result = function(self)
        self.Context.REG.dungeon:show_result(self.Context.cur_self, self.params[1].Value)
    end,
    Pause = function(self)
        local context = self.Context
        if context.cur_self:is_paused() then
            context.cur_self:resume()
        else
            context.cur_self:show_pause_menu()
        end
    end,
    UI = function(self)
        local v = self.params[1].Value
        local op = self.params[1].Op
        local show = true
        if op == 'Add' then
        elseif op == 'Sub' then
            show = false
        end
        self.Context.REG.dungeon:set_ui(v, show)
    end,

    Speed = function(self)
        local context = self.Context
        local obj = context.cur_self
        -- print('!~~~~~~~~~~~', obj.typestr, self.params[1].Value, obj:Speed_get(self.params[1].Value))
        local Speed = obj:Speed_get(self.params[1].Value) or {}
        if self.params[2].Type == 'func' then
            if self.params[2].Value == 'Reserve' or self.params[2].Value == 'Reverse' then
                assert(Speed.Dir)
                ParamProcesser.op_func(Speed, self.params[2], nil)
                return
            end
        end

        -- Speed.bind_func = function()
            -- Speed.Dir = ParamProcesser.op_process_param(nil, self.params[2])
        -- end

        Speed.Dir = ParamProcesser.op_process_param(nil, self.params[2])
        Speed.LerpTime = ParamProcesser.op_process_param(nil, self.params[3])
        Speed.Time = ParamProcesser.op_process_param(nil, self.params[4])

        -- local v = obj:attr_get('Speed')
        -- v = ParamProcesser.op_process_params(v, self.params)
        -- print('Speed', self.params[1].Value, Speed.Dir, Speed.AccTime, Speed.Time)
        obj:Speed_set(self.params[1].Value, Speed)
    end,

    VerticalSpeedChange = function(self)
        local obj = self.Context.cur_self

        obj.onSpeedZ = function(dir)
            Global.AttrManager:Set(CHIP_PARAM_CONFIG.set.get_value(self.params[1]), dir)
            self:run_sub_chips()
        end
    end,

    Action = function(self)
		local obj = self.Context.cur_self
		local name = self.params[1].Value
		local block
		if obj.typestr == 'BlockSubGroup' then
			block = obj:getBlock()
		elseif obj.typestr == 'block' then
			block = obj
		end

		if block then
			if block:hasRoleAnima(name) then
				block:applyAnim(name)
				block:playAnim(name, true)
			else
				block:playDynamicEffect('df1', name)
			end
        else --if is_a(obj, 'character') then -- todo typestr = 'character'
            obj:playAnima(name)
		end
    end,

    PFX = function(self)
        local block = self.Context.cur_self
        local pfxdata = Global.Marker_PfxRess[self.params[1].Value]
        local mat
        if pfxdata.scale ~= 1 then
            mat = _Matrix3D.new()
            mat:setScaling(pfxdata.scale, pfxdata.scale, pfxdata.scale)
        end
        local pfx = block:playBindPfx(pfxdata.res, nil, mat)
        if self.params[1].Op == 'loop' then
            local emitters = {}
            pfx:getEmitters(emitters)
            for _, e in ipairs(emitters) do
                -- print('duration', e.duration, e.interval, e.lifeMin, e.lifeMax, e.delay)
                e.duration = -1
                if e.interval == 0 or e.interval == 0xffffffff then
                    e.interval = (e.lifeMax == 0 or e.lifeMax == 0xffffffff) and 100 or (e.lifeMax + 100)
                end
            end
        end
    end,

    SFX = function(self)
        local block = self.Context.cur_self
        print('block~~~~~~~~', block.typestr)
        -- local min, max = 3, 6
        -- if isRole then
        -- min, max = 5, 20
        -- end
        
        local sounddata = Global.Marker_SoundRess[self.params[1].Value]
        
        if not self.soundGroup then self.soundGroup = SoundGroup.new() end
        local sg = self.soundGroup
        
        sg.type = self.params[1].Op == 'loop' and _SoundDevice.Loop or 0
        sg.volume = sounddata.volume or 1
        sg.soundName = sounddata.res
        
        local soundpos = _Vector3.new()
        block.node.transform:getTranslation(soundpos)
        sg:play(soundpos)
    end,

    FaceTo = function(self)
		local obj = self.Context.cur_self
        local dir = ParamProcesser.op_process_params(nil, self.params)
        dir:normalize()
		obj:updateFace(dir, 200)
        -- obj.bindFaceFunc = function()
        --     local dir = ParamProcesser.op_process_params(nil, self.params)
        --     dir:normalize()
        --     obj:updateFace(dir)
        -- end
    end,
}

BChip.new = function(chipcfg, context)
    local c = {}
    setmetatable(c, {__index = CHIP})
    c.Name = chipcfg.Name
    c.ActTarget = chipcfg.Target
    c.params = chipcfg.params or {}
    c.sub_chips = chipcfg.sub_chips
    c.Context = context
    
    -- if chipcfg.sub_chips and #chipcfg.sub_chips > 0 then
    --     c.SubContext = BContext.new(context.cur_self, chipcfg.sub_chips)
    -- end

    return c
end