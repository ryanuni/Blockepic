
local function float2string(x)
	return math.floatEqual(x, 0, 0.001) and 0 or string.format('%.4f', x)
end
local function float2string2(x)
	return math.floatEqual(x, 0, 0.001) and 0 or string.format('%.3f', x)
end
local function vec32string(v3)
	local str = '_Vector3.new(%s,%s,%s)'
	return string.format(str, float2string(v3.x), float2string(v3.y), float2string(v3.z))
end
local function vec42string(v3)
	local str = '_Vector4.new(%s,%s,%s,%s)'
	return string.format(str, float2string(v3.x), float2string(v3.y), float2string(v3.z), float2string(v3.w))
end

local function aabb2string(ab)
	local str = '_AxisAlignedBox.new(%s, %s)'
	local min, max = ab.min, ab.max
	return string.format(str, vec32string(min), vec32string(max))
end

-- local helpv31 = _Vector3.new()
-- local helpv32 = _Vector3.new()
-- local helpv4 = _Vector4.new()
local function mat2string(mat)
	local str = '_Matrix3D.new():setScaling(%s,%s,%s):mulRotationXRight(%s):mulRotationYRight(%s):mulRotationZRight(%s):mulTranslationRight(%s,%s,%s)'
	mat:formatMatrix()
	return string.format(str,
		float2string(mat.scaleX), float2string(mat.scaleY), float2string(mat.scaleZ),
		float2string(mat.rotationP), float2string(mat.rotationH), float2string(mat.rotationB),
		float2string2(mat.translationX), float2string2(mat.translationY), float2string2(mat.translationZ))
end

function _G.value2string(v, h)
	if type(v) == 'number' then
		return v
	elseif type(v) == 'boolean' then
		return v and 'true' or 'false'
	elseif type(v) == 'string' then
		return string.format('\'%s\'', v)
	elseif v.typestr == '_Vector3' then
		return vec32string(v)
	elseif v.typestr == '_Vector4' then
		return vec42string(v)
	elseif v.typestr == '_AxisAlignedBox' then
		return aabb2string(v)
	elseif v.typestr == '_Matrix3D' then
		return mat2string(v)
	elseif v.typestr == 'PivotMat' then
		return v:tostring()
	elseif v.typestr == 'LerpMaterial' then
		return v:tostring()
	elseif v.typestr == 'PaintInfo' then
		return v:tostring()
	elseif type(v) == 'table' then
		return table2string(v, h)
	end
end

function _G.table2string(tb, h)
	h = h or ''
	local h1 = h .. '\t'
	local strtb = {}
	for k, v in pairs(tb) do
		table.insert(strtb, formatkv2string(k, v, h1))
	end
	table.sort(strtb, function(a, b)
		return a < b
	end)

	table.insert(strtb, 1, '{\n')
	table.insert(strtb, h1 .. '}')

	local str = table.concat(strtb, '')
	return str
end

function _G.formatkv2string(k, v, h)
	h = h or ''
	local formatter = "%s\t%s = %s,\n"
	return string.format(formatter, h, type(k) ~= 'number' and k or '[' .. k .. ']', value2string(v, h))
end

local function formata2b(a, b, h)
	h = h or ''
	local formatter = "%s\t%s = %s,\n"
	return string.format(formatter, h, a, b)
end

local function writePfxsString(pfxs, head)
	head = head or ''
	local str = head .. 'pfxs = {\n'
	for i, v in ipairs(pfxs) do
		local s = head .. '\t' .. '{'
		s = s .. 'pfxname = \'' .. v.pfxname .. '\', '
		s = s .. 'translation = ' .. vec32string(v.translation) .. ', '
		s = s .. 'rotation = ' .. vec42string(v.rotation) .. ', '
		s = s .. 'scale = ' .. vec32string(v.scale) .. ', '
		s = s .. '},\n'
		str = str .. s
	end
	str = str .. head .. '\n},\n'

	return str
end

local function writeMarkerData(mdata, head)
	head = head or ''
	local str = formatkv2string('markerdata', mdata, head)
	return str
end

local strtb = {}
local function writeBlockString(b, head, skipsuffix)
	table.clear(strtb)
	head = head or ''
	local s = b.space
	local shape = type(b.shape) == 'string' and ('\'' .. b.shape .. '\'') or b.shape

	table.insert(strtb, head .. '{\n')

	table.insert(strtb, formata2b('shape', shape, head))
	table.insert(strtb, formata2b('subshape', (b.subshape or 0), head))
	table.insert(strtb, formata2b('material', b.material, head))
	table.insert(strtb, formata2b('color', b.color, head))
	table.insert(strtb, formata2b('roughness', (b.roughness or 1), head))
	table.insert(strtb, formata2b('mtlmode', b.mtlmode, head))

	if b.need ~= nil then
		table.insert(strtb, head .. '\tneed = ' .. tostring(b.need) .. ',\n')
	end

	if b.isDungeonBg ~= nil then
		table.insert(strtb, head .. '\tisDungeonBg = ' .. tostring(b.isDungeonBg) .. ',\n')
	end

	if b.pickFlag ~= nil then
		table.insert(strtb, head .. '\tpickFlag = ' .. tostring(b.pickFlag) .. ',\n')
	end

	-- if b.isrotDummy then
	-- 	table.insert(strtb, head .. '\tisrotDummy = ' .. tostring(b.isrotDummy) .. ',\n')
	-- end
	if b.markerdata then
		table.insert(strtb, writeMarkerData(b.markerdata, head))
	end
	if b.disablephyx then
		table.insert(strtb, head .. '\tdisablephyx = true,\n')
	end

	-- if b.forceMtlInvisible then
	-- 	table.insert(strtb, head .. '\tforceMtlInvisible = true,\n')
	-- end

	if s then
		table.insert(strtb, head .. '\tspace = {\n')
		table.insert(strtb, head .. '\t\tscale = ' .. vec32string(s.scale) .. ',\n')
		table.insert(strtb, head .. '\t\trotation = ' .. vec42string(s.rotation) .. ',\n')
		table.insert(strtb, head .. '\t\ttranslation = ' .. vec32string(s.translation) .. ',\n')
		table.insert(strtb, head .. '\t},\n')
	end

	if b.aabb then
		table.insert(strtb, head .. '\taabb = ' .. value2string(b.aabb) .. ',\n')
	end

	if b.paintInfo and b.paintInfo.resname ~= '' then
		local scale = b.paintInfo.scale
		local translation = b.paintInfo.translation
		local rotate = b.paintInfo.rotate
		local face = b.paintInfo.face
		local visible = b.paintInfo.visible
		table.insert(strtb, head .. '\tpaintInfo = {\n')
		table.insert(strtb, head .. '\t\tresname = \'' .. b.paintInfo.resname .. '\',\n')
		table.insert(strtb, head .. '\t\tscale = ' .. vec32string(scale) .. ',\n')
		table.insert(strtb, head .. '\t\ttranslation = ' .. vec32string(translation) .. ',\n')
		if rotate then
			table.insert(strtb, head .. '\t\trotate = ' .. vec42string(rotate) .. ',\n')
		end
		if face then
			table.insert(strtb, head .. '\t\tface = ' .. face .. ',\n')
		end

		if visible ~= nil then
			table.insert(strtb, head .. '\t\tvisible = ' .. tostring(visible) .. ',\n')
		end
		table.insert(strtb, head .. '\t},\n')
	end

	if b.pfxs and next(b.pfxs) then
		table.insert(strtb, writePfxsString(b.pfxs, head))
	end

	if skipsuffix then
		table.insert(strtb, head .. '}')
	else
		table.insert(strtb, head .. '},\n')
	end

	local str = table.concat(strtb, '')

	return str
end

Global.writeBlockString = function(b, center, keepshape)
	local data = Global.saveBlockData(b, center, keepshape)
	return writeBlockString(data, nil, true)
end

local strtb2 = {}
local function writeGroupString(g)
	local str = 'blocks = {'

	table.clear(strtb2)
	for i, v in ipairs(g.blocks) do
		table.insert(strtb2, v)
	end
	str = str .. table.concat(strtb2, ', ')
	str = str .. '}, '

	return str
end

local function writeOverlapString(connects, overlaps, neighbors, head)
	local str = ''
	table.clear(strtb2)
	if connects and next(connects) then
		table.insert(strtb2, 'connects = {\n')
		for i, v in ipairs(connects) do
			table.insert(strtb2, '{b1 = ' .. v.b1)
			table.insert(strtb2, ',b2 = ' .. v.b2)
			table.insert(strtb2, ',s1 = ' .. v.s1)
			table.insert(strtb2, ',s2 = ' .. v.s2 .. '},\n')
		end
		table.insert(strtb2, '},\n')
	end

	if overlaps and next(overlaps) then
		table.insert(strtb2, 'overlaps = {\n')
		for i, v in ipairs(overlaps) do
			table.insert(strtb2, '{b1 = ' .. v.b1)
			table.insert(strtb2, ',b2 = ' .. v.b2 .. '},\n')
		end
		table.insert(strtb2, '},\n')
	end

	str = table.concat(strtb2, '')

	if neighbors and next(neighbors) then
		table.insert(strtb2, 'neighbors = {\n')
		for i, v in ipairs(neighbors) do
			table.insert(strtb2, '{b1 = ' .. v.b1)
			table.insert(strtb2, ',b2 = ' .. v.b2 .. '},\n')
		end
		table.insert(strtb2, '},\n')
	end

	str = table.concat(strtb2, '')
	return str
end

local function writeFuncflagsString(funcflags, head)
	head = head or ''

	local str = head .. 'funcflags = {\n'
	for fn, op in pairs(funcflags) do
		if op ~= nil then
			str = str .. head .. '\t' .. fn .. ' = ' .. value2string(op) .. ',\n'
		end
	end
	str = str .. head .. '},\n'

	return str
end

-- local function writePartsString(parts, head)
	-- local str = head .. 'parts = {\n'
	-- str = str .. head .. '\tbindbone = \'' .. parts.bindbone .. '\',\n'
	-- str = str .. head .. '\trootz = ' .. parts.rootz .. ',\n'
	-- if parts.disableBind then
	-- 	str = str .. head .. '\tdisableBind = true,\n'
	-- end

	-- for name, p in pairs(parts) do if type(p) == 'table' then
	-- 	local s = head .. '\t' .. name .. ' = {group = ' .. p.group .. ', '
	-- 	--s = s .. 'pos = _Vector3.new(' .. p.pos.x .. ',' .. p.pos.y .. ',' .. p.pos.z .. '),'
	-- 	s = s .. 'jointpos = ' .. vec32string(p.jointpos) .. ', '
	-- 	s = s .. 'partpos = ' .. vec32string(p.partpos) .. ', '
	-- 	if p.pgroup then
	-- 		s = s .. 'pgroup = ' .. p.pgroup .. ', '
	-- 	end
	-- 	if p.attachs and #p.attachs > 0 then
	-- 		s = s .. 'attachs = {'
	-- 		for i, v in ipairs(p.attachs) do
	-- 			s = s .. v .. ', '
	-- 		end
	-- 		s = s .. '},'
	-- 	end
	-- 	s = s .. '},\n'

	-- 	str = str .. s
	-- end end
	-- str = str .. head .. '},\n'

-- 	return str
-- end

local function writeRepairDelsString(dels, head)
	head = head or ''
	local str = head .. 'repair_dels = {\n'
	for i, v in ipairs(dels) do
		local s = head .. '\t' .. '{'
		s = s .. 'index = ' .. v.index .. ', '
		s = s .. '},\n'

		str = str .. s
	end
	str = str .. head .. '},\n'

	return str
end
local function writeRepairAddsString(adds, head)
	head = head or ''
	local str = head .. 'repair_adds = {\n'
	for i, v in ipairs(adds) do
		local s = head .. '\t' .. '{'

		if v.shape then
			local shape = type(v.shape) == 'string' and ('\'' .. v.shape .. '\'') or v.shape
			s = s .. 'shape = ' .. shape .. ', '
		end
		if v.bindGroup then
			s = s .. 'bindGroup = ' .. v.bindGroup .. ', '
		end

		if v.rot then
			s = s .. 'rot = ' .. vec42string(v.rot) .. ', '
		end

		s = s .. 'trans = ' .. vec32string(v.trans) .. ', '

		s = s .. '},\n'
		str = str .. s
	end
	str = str .. head .. '},\n'

	return str
end

local function writeFrameString(fs, head)
	head = head or ''
	local str = head .. 'frames = {\n'
	for i, v in ipairs(fs) do
		local s = head .. '\t' .. '{'
		s = s .. 'time = ' .. v.time .. ', '
		if v.iskey then
			s = s .. 'iskey = true, '
		end
		if v.istween then
			s = s .. 'istween = true, '
		end

		s = s .. 'value = ' .. value2string(v.value) .. ', '

		s = s .. head .. '\t' .. '},\n'

		str = str .. s
	end
	str = str .. head .. '},\n'

	return str
end

local function writeTransitionString(ts, head)
	head = head or ''
	local str = head .. 'transitions = {\n'
	for i, v in ipairs(ts) do
		local s = head .. '\t' .. '{'
		s = s .. '\n' .. head .. '\t'
		s = s .. 'group = ' .. v.group .. ', '
		if v.duration then
			s = s .. 'duration = ' .. v.duration .. ', '
		end
		s = s .. 'attr = ' .. value2string(v.attr) .. ', '
		if v.localcenter then
			s = s .. 'localcenter = true, '
		end
		if v.pivot then
			s = s .. 'pivot = ' .. value2string(v.pivot) .. ', '
		end
		s = s .. '\n' .. writeFrameString(v.frames, head .. '\t')
		s = s .. head .. '\t' .. '},\n'

		str = str .. s
	end
	str = str .. head .. '},\n'

	return str
end

local function writeDynamicEffectsString(dfs, head)
	head = head or ''
	local str = head .. 'dynamicEffects = {\n'
	for i, v in ipairs(dfs) do
		local s = head .. '\t' .. '{'
		s = s .. '\n' .. head .. '\t'
		s = s .. 'name = ' .. value2string(v.name) .. ', '
		s = s .. '\n' .. writeTransitionString(v.transitions, head .. '\t')

		if v.actions then
			s = s .. formatkv2string('actions', v.actions, head)
		end
		s = s .. head .. '\t' .. '},\n'

		str = str .. s
	end
	str = str .. head .. '},\n'
	return str
end

local function writeBfuncEventString(events, head)
	head = head or ''
	local str = head .. 'events = {\n'
	for i, v in ipairs(events) do
		local s = head .. '\t' .. '{'
		s = s .. 'name = ' .. value2string(v.name) .. ', '
		s = s .. 'type = ' .. value2string(v.type) .. ', '
		s = s .. '},\n'

		str = str .. s
	end
	str = str .. head .. '\t' .. '},\n'

	return str
end

local function writeBfuncString(funcs, head)
	head = head or ''
	local str = head .. 'bfuncs = {\n'
	for i, v in ipairs(funcs) do
		local s = head .. '\t' .. '{'
		s = s .. '\n' .. head .. '\t'
		--s = s .. 'group = ' .. value2string(v.name) .. ', '
		s = s .. writeBfuncEventString(v.events, head .. '\t')
		s = s .. head .. '\t' .. '},\n'

		str = str .. s
	end
	str = str .. head .. '},\n'
	return str
end

local function writeParamsString(params, head)
	head = head or ''
	local str = head .. 'params = {'
	for i, v in ipairs(params or {}) do
		local s = head .. '\t' .. '{'
		s = s .. 'Type = ' .. value2string(v.Type) .. ', '
		s = s .. 'Op = ' .. value2string(v.Op) .. ', '
		s = s .. 'Value = ' .. value2string(v.Value) .. ', '
		if v.sub_params and #v.sub_params > 0 then
			s = s .. 'sub_' ..writeParamsString(v.sub_params)
		end
		s = s .. '},'

		str = str .. s
	end
	str = str .. head .. '\t' .. '},'

	return str
end

local function writeChipsString(chips, head)
	head = head or ''
	local str = ''
	for i, v in ipairs(chips) do
		local s = head .. '\t' .. '{'
		s = s .. 'Name = ' .. value2string(v.Name) .. ', '
		s = s .. 'Target = ' .. value2string(v.Target) .. ', '
		s = s .. writeParamsString(v.params)
		s = s .. '},\n'

		str = str .. s
	end
	-- str = str .. head .. '\t' .. '},\n'

	return str
end

local function writeChipssString(chipss, head)
	local str = head .. 'chips_s = ' .. value2string(chipss) .. ',\n'
	return str

	-- do
	-- 	local str = head .. 'chips_s = '..value2string(chipss)..',\n'
	-- 	return str
	-- end

	-- head = head or ''
	-- local str = head .. 'chips_s = {\n'
	-- for i, v in ipairs(chipss) do
	-- 	local s = head .. '\t' .. '{\n'
	-- 	s = s .. writeChipsString(v, head .. '\t')
	-- 	s = s .. head .. '\t' .. '},\n'

	-- 	str = str .. s
	-- end
	-- str = str .. head .. '},\n'
	-- return str
end

local function writeBlockChipss(bcsss, head)
	head = head or ''
	local str = head .. 'block_chipss = {\n'
	head = head .. '\t'
	for i, css in next, bcsss do
		str = str .. head .. '['.. i .. '] = {' .. writeChipssString(css, head) .. '},\n'
	end
	str = str .. head .. '},\n'
	return str
end

local function writeLogicNames(lnss, head)
	head = head or ''
	local str = head .. 'logic_names = {\n'
	for i, lns in next, lnss do
		local s = ''
		for name, value in next, lns do
			if value then
				s = s .. name .. ' = true,'
			end
		end
		if s ~= '' then
			str = str .. head .. '\t['.. i .. '] = {' .. s .. '},\n'
		end
	end
	str = str .. head .. '},\n'
	return str
end

local function writeChildrenString(g)
	local str = ''
	if g.children and next(g.children) then
		str = 'children = {'
		-- local num = #g.children

		table.clear(strtb2)
		for i, gi in ipairs(g.children) do
			table.insert(strtb2, gi)
			-- str = str .. gi .. (i < num and ', ' or '')
		end
		str = str .. table.concat(strtb2, ', ')
		str = str .. '}, '
	end

	return str
end

Global.writeModuleString = function(m, head)
	-- print('======1 Save Write', Global.Debug.gg())
	-- 保存block
	head = head or ''
	local datastr = head .. 'blocks = {\n'
	for i, b in ipairs(m.blocks) do
		datastr = datastr .. writeBlockString(b, head .. '\t')
	end
	datastr = datastr .. head .. '},\n'
	-- print('======1 Save Write2', Global.Debug.gg())
	-- 保存group
	if m.groups then
		table.clear(strtb)
		table.insert(strtb, head .. 'groups = {\n')
		-- datastr = datastr .. head .. 'groups = {\n'
		for i, g in ipairs(m.groups) do
			table.insert(strtb, head .. '\t[' .. i .. '] = {')
			table.insert(strtb, 'islock = ' .. (g.islock and 'true' or 'false') .. ',')
			if g.switchName and g.switchName ~= '' then
				table.insert(strtb, 'switchName = \'' .. g.switchName .. '\',')
			end
			if g.switchPart and g.switchPart ~= '' then
				table.insert(strtb, 'switchPart = \'' .. g.switchPart .. '\',')
			end

			if g.isdeadlock then
				table.insert(strtb, 'isdeadlock = true,')
			end
			table.insert(strtb, writeGroupString(g))
			table.insert(strtb, writeChildrenString(g))
			table.insert(strtb, '},\n')
		end

		table.insert(strtb, head .. '},\n')
		datastr = datastr .. table.concat(strtb, '')
	end

	if m.logicgroups and next(m.logicgroups) then
		datastr = datastr .. head .. 'logicgroups = ' .. value2string(m.logicgroups, head) .. ',\n '
	end

	-- print('======1 Save Write2.1', Global.Debug.gg())
	if m.connects or m.overlaps or m.neighbors then
		datastr = datastr .. writeOverlapString(m.connects, m.overlaps, m.neighbors, head)
	end
	if m.funcflags and next(m.funcflags) then
		datastr = datastr .. writeFuncflagsString(m.funcflags, head .. '\t')
	end
	-- print('======1 Save Write2.2', Global.Debug.gg())
	-- 保存part
	if m.parts and m.parts.bindbone then
		--datastr = datastr .. writePartsString(m.parts, head)
		datastr = datastr .. head .. 'parts = ' .. value2string(m.parts, head) .. ',\n '
	end
	-- print('======1 Save Write3', Global.Debug.gg())
	-- 保存repair
	if m.repair_dels and next(m.repair_dels) then
		if m.repair_version then
			datastr = datastr .. '\trepair_version = ' .. m.repair_version .. ',\n'
		end
		datastr = datastr .. writeRepairDelsString(m.repair_dels, head)
	end
	if m.repair_adds and next(m.repair_adds) then
		datastr = datastr .. writeRepairAddsString(m.repair_adds, head)
	end

	if m.dynamicEffects and #m.dynamicEffects > 0 then
		datastr = datastr .. writeDynamicEffectsString(m.dynamicEffects, head)
	end

	if m.bfuncs and #m.bfuncs > 0 then
		datastr = datastr .. writeBfuncString(m.bfuncs, head)
	end

	if m.chips_s and next(m.chips_s) then
		datastr = datastr .. writeChipssString(m.chips_s, head)
	end

	if m.block_chipss and next(m.block_chipss) then
		datastr = datastr .. writeBlockChipss(m.block_chipss, head)
	end

	if m.logic_names and next(m.logic_names) then
		datastr = datastr .. writeLogicNames(m.logic_names, head)
	end

	return datastr
end

Global.saveBlock2String = function(data)
	-- print('======1 Save', Global.Debug.gg())
	local materials = data.materials
	local modules = data

	local str = 'return {\n'
	str = str .. '\tversion = ' .. modules.version .. ',\n'
	str = str .. '\tscale = ' .. modules.scale .. ',\n'
	str = str .. '\tdisableMaxBox = ' .. (modules.disableMaxBox and 'true' or 'false') .. ',\n'
	if modules.enableMinBox then
		str = str .. '\tenableMinBox = true,\n'
	end
	if modules.center then
		str = str .. '\tcenter = ' .. vec32string(modules.center) .. ',\n'
	end
	-- if modules.blocktype then
	-- 	str = str .. '\tblocktype = ' .. value2string(modules.blocktype) .. ',\n'
	-- end

	if modules.netobjects then
		local head = '\t'
		str = str .. head .. 'netobjects = ' .. value2string(modules.netobjects, head) .. ',\n '
	end

	-- print('======1 Save2', Global.Debug.gg())
	--写入子元件
	if modules.subs and next(modules.subs) then
		local substr = '\tsubs = {\n'
		for subid, m in pairs(modules.subs) do
			substr = substr .. '\t\t[' .. subid .. '] = {\n'

			if m.center then
				substr = substr .. '\t\t\tcenter = ' .. vec32string(m.center) .. ',\n'
			end

			local datastr = Global.writeModuleString(m, '\t\t\t')
			substr = substr .. datastr

			substr = substr .. '\t\t},\n'
		end
		substr = substr .. '\t},\n'

		str = str .. substr
	end

	if modules.submodules and #modules.submodules > 0 then
		local substr = '\tsubmodules = {\n'
		for i, subm in ipairs(modules.submodules) do
			local s = '\t\t' .. '{'
			s = s .. 'type = ' .. value2string(subm.type) .. ', '
			if subm.type == 'bind' then
				s = s .. 'bindex = ' .. subm.bindex .. ', '
			end
			local datastr = Global.writeModuleString(subm.module, '\t\t\t')
			s = s .. 'module = {\n' .. datastr .. '\t\t\t},\n '
			s = s .. '\t\t},\n'

			substr = substr .. s
		end
		substr = substr .. '\t},\n'
		str = str .. substr
	end

	-- print('======1 Save3', Global.Debug.gg())
	if materials and next(materials) then
		local mtlstr = '\tmaterials = {\n'
		for i, v in ipairs(materials) do
			local str = '\t{\n'
			str = str .. '\t\tmaterial = ' .. v.material .. ',\n'
			str = str .. '\t\tcolor = ' .. v.color .. ',\n'
			str = str .. '\t\troughness = ' .. v.roughness .. ',\n'
			str = str .. '\t\tmtlmode = ' .. v.mtlmode .. ',\n'
			str = str .. '\t},\n'
			mtlstr = mtlstr .. str
		end
		mtlstr = mtlstr .. '\t},\n'

		str = str .. mtlstr
	end
	-- print('======1 Save4', Global.Debug.gg())
	local datastr = Global.writeModuleString(modules, '\t')
	str = str .. datastr
	str = str .. '}'
	-- print('======1 Save End', Global.Debug.gg())
	return str
end
