local CNUMBER = {
    type = 'CNUMBER',
    new = function(v)
        self.value = tonumber(v) or 0 -- tonumber('1%')
    end,

    __add = function(self, rhs)
        if rhs.type ~= 'CNUMBER' then return self end
        return CNUMBER.new(self.value + rhs.value)
    end,

    __sub = function(self, rhs)
        if rhs.type ~= 'CNUMBER' then return self end
        return CNUMBER.new(self.value - rhs.value)
    end,

    __mul = function(self, rhs)
        if rhs.type ~= 'CNUMBER' then return self end
        return CNUMBER.new(self.value * rhs.value)
    end,

    __div = function(self, rhs)
        if rhs.type ~= 'CNUMBER' then return self end
        return CNUMBER.new(self.value / rhs.value)
    end,
}

local CVECTOR = {
    type = 'CVECTOR',
    new = function(v)
        self.value = v or _Vector3.new() -- tonumber('1%')
    end,

    __add = function(self, rhs)
        if rhs.type == 'CNUMBER' then
            self.value:add(math.normalize(self.value):mul(rhs.value))
        elseif rhs.type == 'CVECTOR' then
            self.value:add(rhs.value)
        end

        return self
    end,

    __sub = function(self, rhs)
        if rhs.type == 'CNUMBER' then
            self.value:sub(math.normalize(self.value):mul(rhs.value))
        elseif rhs.type == 'CVECTOR' then
            self.value:sub(rhs.value)
        end

        return self
    end,

    __mul = function(self, rhs)
        if rhs.type == 'CNUMBER' then
            self.value:mul(rhs.value)
        elseif rhs.type == 'CVECTOR' then
            self.value:mul(rhs.value)
        end

        return self
    end,

    __div = function(self, rhs)
        if rhs.type == 'CNUMBER' then
            self.value:div(rhs.value)
        elseif rhs.type == 'CVECTOR' then
            self.value:div(rhs.value)
        end

        return self
    end,
}

local CENUM = {
    type = 'CENUM',
    new = function(v)
        self.value = v
    end,
    __add = function(self, rhs)
        -- rhs.value
    end,
}

local CARRAY = {}

--------------------------------- chip types ------------------------------

_G.is_a = function(role, type)
    if type == 'role' then
        return role == Global.role
    elseif type == 'character' then
        return role.id
    elseif type == 'object' then
        return not role.id
    end
end

_G.is_num = function(t)
    return type(t) == 'number'
end

_G.is_vec3 = function(t)
    return type(t) == 'table' and t.typeid == _Vector3.typeid
end

_G.is_enum = function(t)
end

_G.is_array = function(t)
    if type(t) ~= 'table' then return end

    for k, v in next, t do
        if type(k) ~= 'number' or k > #t then
            return false
        end
    end

    return true
end

_G.is_exp = function(t)
    return true
end

_G.is_ref = function(t)
    return type(t) == 'table' and t.isRef
end

_G.get_refv = function(t)
    if is_ref(t) then 
        return t:Get()
    else
        return t
    end
end

----------------------------------- Param Rules ------------------------------
_G.CHIP_PARAM_CONFIG = {
    options = {
        ALL = { 'number', 'direction', 'enum', 'formula', 'ms', 'time', 'func', 'condition', 'set', 'get', 'Gset', 'Gget' },
        NUM = { 'number', 'formula', 'func' },
        VEC = { 'direction', 'formula', 'func' },
        EXP = { 'number', 'enum', 'formula', 'get', 'Gget', 'func', 'condition' },
    },
}

CHIP_PARAM_CONFIG.number = {
    { name = 'Add', desc = '+' },
    { name = 'Sub', desc = '-' },
    { name = 'Mul', desc = '×' },
    { name = 'Div', desc = '÷' },
    { name = 'Set', desc = '=' },

    reset = function(data)
        data.Op = 'Set'
        data.Value = '0'
    end,

    get_desc = function(CFG, data)
        return CFG[data.Op].desc .. data.Value
    end,

    get_value = function(data)
        if not data.value then
            local percent = not not data.Value:find'%%$'
            local number = data.Value:sub(1, percent and -2 or -1)
            number = tonumber(number)
            if percent then number = number * 0.01 end
            data.value = number
        end
        return data.value
    end,
}

CHIP_PARAM_CONFIG.direction = {
    { name = 'l', value = _Vector3.new(1, 0, 0), desc = '←' },
    { name = 'r', value = _Vector3.new(-1, 0, 0), desc = '→' },
    { name = 't', value = _Vector3.new(0, 0, 1), desc = '↑' },
    { name = 'b', value = _Vector3.new(0, 0, -1), desc = '↓' },
    { name = 'lt', value = _Vector3.new(1, 0, 1), desc = '↖' },
    { name = 'rt', value = _Vector3.new(-1, 0, 1), v3d = _Vector3.new(0,1,0), desc = '↗' },
    { name = 'rb', value = _Vector3.new(-1, 0, -1), desc = '↘' },
    { name = 'lb', value = _Vector3.new(1, 0, -1), v3d = _Vector3.new(0,-1,0), desc = '↙' },
    { name = 'o', value = _Vector3.new(0, 0, 0), desc = '-' },

    reset = function(data)
        data.Op = ''
        data.Value = 'o'
    end,

    get_desc = function(CFG, data)
        return CFG[data.Value].desc
    end,
}

CHIP_PARAM_CONFIG.enum = {
    { name = 'Add', desc = '+' },
    { name = 'Sub', desc = '-' },
    { name = 'Set', desc = '=' },

    reset = function(data)
        data.Op = 'Set'
        data.Value = ''
    end,

    get_desc = function(CFG, data)
        print(data.Op, data.Value)
        return CFG[data.Op].desc .. data.Value
    end,
}

CHIP_PARAM_CONFIG.formula = CHIP_PARAM_CONFIG.number
CHIP_PARAM_CONFIG.ms = CHIP_PARAM_CONFIG.number
CHIP_PARAM_CONFIG.time = CHIP_PARAM_CONFIG.number

CHIP_PARAM_CONFIG.func = {
    { 
        name = 'Reserve', 
        check = { 'num', 'vec3' },
        func = function(x)
            if x and x.Dir then
                x.Dir:set(x.cur_speed)
                x.FadeTime = 0
                x.Time = -1
            end
            return x
        end,
    },
    { 
        name = 'Reverse', 
        check = { 'num', 'vec3' },
        func = function(x)
            if type(x) == 'table' and x.Dir then
                x.Dir = x.Dir:mul(-1)
                x.cur_speed = x.cur_speed:mul(-1)
                return x
            else
                return is_vec3(x) and x:mul(-1) or -x
            end
        end,
    },
    { 
        name = 'Random', 
        check = { 'num', 'array' },
        func = function(x)
            return is_num(x) and math.random(x) or x[math.random(1,#x)]
        end,
    },
    { 
        name = 'Count', 
        check = { 'array' },
        func = function(x)
            return #x
        end,
    },
    { 
        name = 'Round', 
        check = { 'num' },
        func = function(x)
            return toint(x+0.5)
        end,
    },
    { 
        name = 'RoundUp', 
        check = { 'num' },
        func = function(x)
            return math.ceil(x)
        end,
    },
    { 
        name = 'RoundDown', 
        check = { 'num' },
        func = function(x)
            return math.floor(x)
        end,
    },
    { 
        name = 'Max', 
        check = { 'num' },
        func = function(x, ps)
            x = x or ps[1]
            for i, p in ipairs(ps) do
                x = math.max(x, p)
            end
            return x
        end,
    },
    { 
        name = 'Min', 
        check = { 'num' },
        func = function(x, ps)
            x = x or ps[1]
            for i, p in ipairs(ps) do
                x = math.min(x, p)
            end
            return x
        end,
    },
    { 
        name = 'And', 
        check = { 'exp' },
        func = function(x, ps)
            for i, p in ipairs(ps) do
                if not p then 
                    return false 
                end
            end
            return #ps > 0
        end,
    },
    { 
        name = 'Or', 
        check = { 'exp' },
        func = function(x, ps)
            for i, p in ipairs(ps) do
                if p then 
                    return true
                end
            end
            return false
        end,
    },
    reset = function(data)
        data.Op = ''
        data.Value = ''
    end,
    get_desc = function(CFG, data)
        return data.Value
    end,
}

CHIP_PARAM_CONFIG.condition = {
    { name = 'E', func = function(a, b) return a == b end, desc = '==' },
    { name = 'NE', func = function(a, b) return a ~= b end, desc = '!=' },
    { name = 'G', func = function(a, b) return a > b end, desc = '>' },
    { name = 'GE', func = function(a, b) return a >= b end, desc = '>=' },
    { name = 'L', func = function(a, b) return a < b end, desc = '＜' },
    { name = 'LE', func = function(a, b) return a <= b end, desc = '＜=' },
    { name = 'IN', func = function(a, b) return table.find(b,a) end, desc = '∈' },
    { name = 'NI', func = function(a, b) return not table.find(b,a) end, desc = '!∈' },
    reset = function(data)
        data.Op = 'E'
        data.Value = ''
    end,
    get_desc = function(CFG, data)
        return CFG[data.Op].desc
    end,
}

CHIP_PARAM_CONFIG.set = {
    get_value = function(data)
        if not data.value then
            data.value = data.Value:split'%.'
        end
        return data.value
    end,
    get_desc = function(CFG, data)
        return 'set:' .. data.Value
    end,
    reset = function(data)
        data.Op = ''
        data.Value = ''
    end,
}

CHIP_PARAM_CONFIG.get = {}
CHIP_PARAM_CONFIG.get.get_value = CHIP_PARAM_CONFIG.set.get_value
CHIP_PARAM_CONFIG.get.get_desc = function(CFG, data) return data.Value end
CHIP_PARAM_CONFIG.get.reset = CHIP_PARAM_CONFIG.set.reset

CHIP_PARAM_CONFIG.Gset = CHIP_PARAM_CONFIG.set
CHIP_PARAM_CONFIG.Gget = CHIP_PARAM_CONFIG.get

for _, type_name in ipairs(CHIP_PARAM_CONFIG.options.ALL) do
    local CFG = CHIP_PARAM_CONFIG[type_name]
    for i, cfg in ipairs(CFG) do
        CFG[cfg.name] = cfg
    end
end

_G.CHIP_PARAM_RULES = {
    apply_chips = function(chip_cfg)
        chip_cfg.data = { Name = chip_cfg.Name, params = {}, Target = { target = 'Self', params = {{ Type = 'get', Op = '', Value = 'Self' }} } }
        for i, p in ipairs(chip_cfg.Params or EMPTY) do
            local param_data = {}
            local ops = _G.CHIP_PARAM_CONFIG.options[p]
            if ops then
                param_data.options = ops
            else
                param_data.Type = p
                _G.CHIP_PARAM_RULES.apply(param_data)
            end
            
            chip_cfg.data.params[i] = param_data
        end
    end,

    apply = function(param_data)
        if not param_data or not param_data.Type then return end
        if not param_data.Op or not param_data.Value then
            CHIP_PARAM_CONFIG[param_data.Type].reset(param_data)
        end

        if param_data.Type == 'formula' then
            param_data.sub_params = {}
        elseif param_data.Type == 'condition' then
            param_data.sub_params = {
                { options = 'EXP' },
                { options = 'EXP' },
            }
        elseif param_data.Type == 'func' then
        end
    end,

    apply_funcs = function(param_data)
        if param_data.Value == 'Max' or param_data.Value == 'Min' then
            param_data.sub_params = {
            }
        elseif param_data.Value == 'Add' or param_data.Value == 'Or' then
            param_data.sub_params = {
            }
        end
    end,

    get_desc = function(param_data)
        if not param_data then return '{}' end
        if not param_data.Type then return '?' end
        
        local CFG = CHIP_PARAM_CONFIG[param_data.Type]
        if not CFG then return '?'..param_data.Type end
        return CFG.get_desc(CFG, param_data) or '()'
    end
}

_G.CHIP_CONFIG = {
    Events = {
        {
            Name = 'Collide',
            Params = { 'enum', 'enum' },
            Desc = 'Trigger an event when a object collides it.',
            enums = {
                {'Player', 'Object', 'All'},
                {'Top', 'Bottom', 'Side', 'All'}
            }
        },
        {
            Name = 'Seperate',
            Params = { 'enum', 'enum' },
            Desc = 'Trigger an event when a object seperates.',
            enums = {
                {'Player', 'Object', 'All'},
                {'Top', 'Bottom', 'Side', 'All'}
            }
        },
        { Name = 'Enter',       Params = { 'enum' },        Desc = 'Trigger an event when enter.', },
        { Name = 'FirstEnter',  Params = { 'enum' },        Desc = 'Trigger an event when first time enter.', },
        { Name = 'Leave',       Params = { 'enum' },        Desc = 'Trigger an event when leave.', },
        { Name = 'Wait',        Params = { 'NUM' },         Desc = 'Wait.', },
        { Name = 'Interval',    Params = { 'NUM' },         Desc = 'Interval.', },
        { Name = 'Repeat',      Params = { 'NUM' },         Desc = 'Repeat.', },
        { Name = 'When',        Params = { 'condition' },   Desc = '参数判断为真时触发一次', },
        { Name = 'WhenNot',     Params = { },               Desc = '参数判断为假时触发一次', },
        { Name = 'WhenAnd',     Params = { },               Desc = '参数判断全真时触发一次', },
        { Name = 'WhenOr',      Params = { },               Desc = '参数判断一个真时触发一次', },
        { Name = 'Break',       Params = { },               Desc = '跳出当前序列', },
        { Name = 'AttributeChange', Params = { },           Desc = '属性改变时触发', },
        { Name = 'VariableChange', Params = { },            Desc = '变量改变时触发', },
        { Name = 'GameBegin',   Params = { },               Desc = 'Trigger an event when the game begins.', },
        {
            Name = 'ControlPush',
            Name2 = 'InputPress',
            Params = {'enum'},
            Desc = 'Key down',
            enums = {
                {'KeyW', 'KeyS', 'KeyA', 'KeyD', 'KeySpace'}
            }
        },
        {
            Name = 'ControlRelease',
            Name2 = 'InputRelease',
            Params = {'enum'},
            Desc = 'Key up',
            enums = {
                {'KeyW', 'KeyS', 'KeyA', 'KeyD', 'KeySpace'}
            }
        },
        {
            Name = 'InputChange',
            Params = {},
            Desc = 'Key change',
            -- enums = {
                -- {'KeyW', 'KeyS', 'KeyA', 'KeyD', 'KeySpace'}
            -- }
        },
        {
            Name = 'VerticalSpeedChange',
            Desc = 'Called when the speed z-direction changes.',
        },
        {
            Name = 'Die',
            Desc = 'Called when the character dies.',
        }
    },
    Attrs = {
        {
            Name = 'CollideType', Params = { 'enum' }, Desc = '',
            enums = {
                {'Player', 'Object', 'All'},
            }
        },
        {
            Name = 'CollideFace', Params = { 'enum' }, Desc = '',
            enums = {
                {'Top', 'Bottom', 'Side', 'All', 'None'}
            }
        },
        { Name = 'Speed', Params = { 'get', 'VEC', 'NUM', 'NUM' }, Desc = 'Speed of it.', },
        { Name = 'Life', Params = { 'NUM' }, Desc = 'Life of a character, dies when its 0.', },
        { Name = 'MaxLife', Params = { 'NUM' }, Desc = 'MaxLife of a character.', },
        { Name = 'Score', Params = { 'NUM' }, Desc = 'Score of a character.', },
        { Name = 'Rank', Params = { }, Desc = 'Rank of a character.', },
        { Name = 'Attribute', Params = { 'get' }, Desc = '', },
        { Name = 'Variable', Params = { 'Gget' }, Desc = '', },
        { Name = 'This', Params = {}, Desc = '',},
        { Name = 'Copy', Params = { 'direction', 'get' }, Desc = '', },
        {
            Name = 'Move',
            Params = {'enum', 'enum'},
            Desc = 'player move',
            enums = {
                {'LEFT', 'RIGHT', 'UP', 'DOWN', 'JUMP'},
                {'true', 'false'},
            }
        },
        {
            Name = 'Jump',
            Desc = 'dont use this',
        },
        {
            Name = 'Result',
            Desc = 'Set to show finish.',
            Params = {'enum'},
            enums = {
                {'Win', 'Lose', 'Draw'},
            }
        },
        {
            Name = 'Pause',
            Desc = 'Pause/Resume the game',
        },
        { Name = 'Action', Params = { 'get' }, Desc = '', },
        {
            Name = 'UI',
            Desc = 'Decide what to show',
            Params = {'enum'},
            enums = {
                {'Life', 'Score', 'Timer', 'TurnCount', 'Coin'},
            }
        },
    },
    Renders = {
        { Name = 'PFX', Params = { 'get' }, Desc = '', },
        { Name = 'SFX', Params = { 'get' }, Desc = '', },
        { Name = 'FaceTo', Params = { 'VEC' }, Desc = '', },
    },
}

local chiplist = {}
for k, v in next, CHIP_CONFIG do
    for index, vv in ipairs(v) do
        vv.Kind = k
        chiplist[vv.Name] = vv

		_G.CHIP_PARAM_RULES.apply_chips(vv)
    end
end

CHIP_CONFIG.chiplist = chiplist

_G.CHIP_TARGETS = {
    'Self',
    'Target',
    'Object',
    'New',
    'Selected',
    'Players',
    'AllPlayers',
    'Dungeons',
    'Children',
    'UserDefined',

    Self = function(context)
        return context.REG.self
    end,
    Target = function(context)
        return context.REG.target
    end,
    Object = function(context)
        --TODO 芯片所在的对象，如芯片在物件的一个零件中，则Object就是这个物件本身
        return context.REG.mainObj
    end,
    New = function(context)
        --TODO 逻辑序列中刚创建出来的新对象，即Copy的结果
        return context.REG.newObj
    end,
    Selected = function(context)
        --TODO 被选中的对象，至多只有一个
        return context.REG.selectedObj
    end,
    Dungeon = function(context)
        return context.REG.dungeon
    end,
    Players = function(context)
        --TODO 全体玩家所在的逻辑组（即默认打好的逻辑组），不含已经出局的玩家，单人游戏就是一个玩家
        -- return context.REG.cur_players
        local ps
        for i, p in ipairs(context.REG.players) do
            if not p.died then
                table.insert(ps, p)
            end
        end
        return ps
    end,
    AllPlayers = function(context)
        -- TODO 全体玩家所在的逻辑组，包含已经出局的玩家
        return context.REG.dungeon:attr_get('AllPlayers')
    end,
    Dungeons = function(context)
        return context.REG.dungeon:attr_get('Children')
    end,
    Children = function(context)
        -- TODO 对象的子逻辑组，从这个对象Copy出来的所有子对象
        return context.cur_self:attr_get('Children')
    end,
    UserDefined = function(context)
        -- 什么都不做，用参数决定
        return context.cur_self
    end,
}

_G.BLOCK_LOGIC_NAMES = {
    -- logic names
    { type = 'L_1', icon = 'img://logic_icon (1).png' },
    { type = 'L_2', icon = 'img://logic_icon (2).png' },
    { type = 'L_3', icon = 'img://logic_icon (3).png' },
    { type = 'L_4', icon = 'img://logic_icon (4).png' },
    { type = 'L_5', icon = 'img://logic_icon (5).png' },
    { type = 'L_6', icon = 'img://logic_icon (6).png' },
    { type = 'L_7', icon = 'img://logic_icon (7).png' },
    { type = 'L_8', icon = 'img://logic_icon (8).png' },
    { type = 'L_9', icon = 'img://logic_icon (9).png' },
    { type = 'L_10', icon = 'img://logic_icon (10).png' },
    { type = 'L_Pair', icon = 'img://logic_icon (10).png' },
    -- context REG
    { type = 'Self', icon = 'img://logic_icon (12).png' },
    { type = 'Target', icon = 'img://logic_icon (13).png' },
    { type = 'Object', icon = 'img://logic_icon (14).png' },
    { type = 'New', icon = 'img://logic_icon (15).png' },
    { type = 'Selected', icon = 'img://logic_icon (16).png' },
    { type = 'Players', icon = 'img://logic_icon (17).png' },
    { type = 'AllPlayers', icon = 'img://logic_icon (18).png' },
    { type = 'Dungeon', icon = 'img://logic_icon (19).png' },
    { type = 'Dungeons', icon = 'img://logic_icon (20).png' },
    { type = 'Children', icon = 'img://logic_icon (21).png' },
    { type = 'UserDefined', icon = 'img://logic_icon (22).png' },
    -- globals
    { type = 'G_AllPlayers', icon = 'img://logic_icon (11).png' },
    { type = 'G_Temp1', icon = 'img://logic_icon (11).png' },
    { type = 'G_Temp2', icon = 'img://logic_icon (11).png' },
    { type = 'G_Temp3', icon = 'img://logic_icon (11).png' },
    { type = 'G_P', icon = 'img://logic_icon (23).png' },
    -- keys
    { type = 'KeyUp', icon = 'img://keyUp.png' },
    { type = 'KeyDown', icon = 'img://keyDown.png' },
    { type = 'KeyLeft', icon = 'img://keyLeft.png' },
    { type = 'KeyRight', icon = 'img://keyRight.png' },
    { type = 'KeySpace', icon = 'img://keySpace.png' },
    { type = 'KeyW', icon = 'img://keyW.png' },
    { type = 'KeyA', icon = 'img://keyA.png' },
    { type = 'KeyS', icon = 'img://keyS.png' },
    { type = 'KeyD', icon = 'img://keyD.png' },
    { type = 'KeyJ', icon = 'img://keyJ.png' },
    { type = 'CamDir', icon = 'img://camera_rot.png' },
    -- attributes
    { type = 'Temp1', icon = 'img://icon_board_1.png' },
    { type = 'Temp2', icon = 'img://icon_board_1.png' },
    { type = 'Temp3', icon = 'img://logic_icon (25).png' },
    { type = 'Ground', icon = 'img://logic_icon (26).png' },
    { type = 'Speed1', icon = 'img://speed1.png' },
    { type = 'Speed2', icon = 'img://speed2.png' },
    { type = 'Speed3', icon = 'img://speed3.png' },
    { type = 'Rank', icon = 'img://icon_board_1.png' },
    { type = 'Life', icon = 'img://icon_barrage.png' },
    { type = 'Speed', icon = 'img://logic_icon (25).png' },
}

_G.BLOCK_LOGIC_G_NAMES = {
    { type = 'G_Var1', icon = 'img://logic_icon (11).png' },
    { type = 'G_Var2', icon = 'img://logic_icon (11).png' },
    { type = 'G_Var3', icon = 'img://logic_icon (11).png' },
    { type = 'G_Var4', icon = 'img://logic_icon (23).png' },
}

for i, cfg in ipairs(BLOCK_LOGIC_NAMES) do
    _G.BLOCK_LOGIC_NAMES[cfg.type] = cfg
end

for i, cfg in ipairs(BLOCK_LOGIC_G_NAMES) do
    _G.BLOCK_LOGIC_G_NAMES[cfg.type] = cfg
end

------------------------------------------------------------

local REFVALUE = {
    isRef = true,
    Get = function(self)
        return self.obj:attr_get(self.key)
    end,
    Set = function(self, v)
        self.obj:attr_set(self.key, v)
    end,
}

_G.RefValue = {}
RefValue.new = function(obj, key)
    -- print('RefValue', obj, key)
    -- assert(obj.attrs)
    local rv = { obj = obj, key = key }
    if key == 'G_AllPlayers' then
        rv.isReadOnly = true
    end
    setmetatable(rv, { __index = REFVALUE })
    return rv
end

local am = {
    attrs = {}, -- global vars
    listeners = {},

    attr_reset = function(self)
        self.attrs = {}
        self.listeners = {}
    end,
    attr_get = function(self, name)
        if name == 'G_AllPlayers' then
            return Global.dungeon:get_players()
        end
        return self.attrs[name]
    end,
    attr_set = function(self, name, value)
        if name == 'G_AllPlayers' then
            print('cant set readonly value:', name)
            return
        end

        self.attrs[name] = value
    end,
}

local function is_logic_name(name)
    return name:find'^L_' or name:find'^L%d' -- todo del
end

local function is_key_name(name)
    return name:find'^Key'
end

local function is_context_target(name)
    return CHIP_TARGETS[name]
end

local function is_global_name(name)
    return name:find'^G_'
end

am.SetCurrentListener = function(self, listener) -- context
    self.cur_listener = listener
    self.cur_listener.listening = {}
end

am.add_attr_to_listener = function(self, name)
    table.insert(self.cur_listener.listening, { self.cur_context.cur_self, name })
end

am.bind_to_listener = function(self, name)
    self.cur_listener.enable_listen = true
end

local function get_obj_by_name(obj, name)
    if is_logic_name(name) then
        return get_refv(obj):get_value_by_logic_name(name)
    elseif is_key_name(name) then
        return _sys:isKeyDown(_System[name])
    elseif is_context_target(name) then
        return CHIP_TARGETS[name](am.cur_context)
    elseif is_global_name(name) then
        return RefValue.new(am, name)
    else
        return RefValue.new(get_refv(obj), name)
    end
end

am.listen = function(self, RefV, func) 
    if not func then return end -- todo bind to context function() context:restart() end
    local obj = RefV.obj
    local name = RefV.key
    -- set obj nil when obj is deleted / bind func to obj not am
    if not self.listeners[obj] then self.listeners[obj] = {} end
    if not self.listeners[obj][name] then self.listeners[obj][name] = {} end
    table.insert(self.listeners[obj][name], func)
end

am.on_attr_change = function(self, RefV, value)
    local ls = self.listeners[RefV.obj] and self.listeners[RefV.obj][RefV.key]
    if not ls then return value end
    local tempname = { RefV.obj.tempname or 'G_P' }
    am:Set(tempname, value)
    for i, f in ipairs(ls) do
        f()
    end
    return get_refv(am:Get(tempname))
end

am.registerAttributeChange = function(self, names, tempname, func)
    local o = self.cur_context.cur_self
    for i, n in ipairs(names) do
        o = get_obj_by_name(o, n)
    end
    assert(is_ref(o), 'try to set a readonly value')
    o.tempname = tempname
    self:listen(o, func)
end

am.Get = function(self, names)
    local o = self.cur_context.cur_self
    for i, n in ipairs(names) do
        o = get_obj_by_name(o, n)
    end

    return o
end

am.Set = function(self, names, value)
    local o = self.cur_context.cur_self
    for i, n in ipairs(names) do
        o = get_obj_by_name(o, n)
    end

    -- print('SETSET', table.ftoString(names), value)

    assert(is_ref(o), 'try to set a readonly value')

    value = self:on_attr_change(o, value)
    o:Set(value)
end

am.SetCurrentContext = function(self, context)
    self.cur_context = context
end

--------------- temp -------------

local function valid_vec3(v)
    return v and not math.is_vec3_000(v)
end

am.calc_speed = function(obj, dir, e)
    if not obj.Speeds then return end
    local moving
    for k, s in next, obj.Speeds do if valid_vec3(s.Dir) then
        -- camera space dir
        -- if s.bind_func then
        --     s.bind_func()
        -- end

        local d = s.Dir
        if not s.cur_speed then
            s.cur_speed = _Vector3.new()
            s.cur_countdown = s.LerpTime
            s.cur_tick = 0
        end

        local ratio = 1 - s.cur_countdown / math.max(1, s.LerpTime)
        s.cur_speed = s.Dir:mul(ratio)
        _Vector3.add(dir, s.cur_speed:mul(e/1000), dir)
        moving = true

        s.cur_countdown = math.max(0, s.cur_countdown - e)
        s.cur_tick = s.cur_tick + e
        if s.Time ~= -1 and s.cur_tick > s.LerpTime + s.Time then
            s.Dir = nil
            s.cur_speed = nil
        end
    end end

    if obj.onSpeedZ then
        local sign = dir.z <= 0
        if obj.dirZ_sign ~= sign then
            obj.onSpeedZ(sign)
            obj.dirZ_sign = sign
        end
    end

    return moving
end

Global.AttrManager = am