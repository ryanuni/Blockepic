_dofile'block_logic.lua'
local enablePrint = true

-- local ui = Global.ui
local temp_print = _G.print
local print = function(...)
	if enablePrint then
		temp_print(...)
	end
end

local function p_in_ui(p, u, is_child)
	local up = u:local2Global(0,0)
	-- if is_child then
		-- return p.x > 0 and p.y > 0 and p.x < u._width and p.y < u._height
	-- else
		return p.x > up.x and p.y > up.y and p.x < up.x + u._width and p.y < up.y + u._height
	-- end
end

local dragManager = {
	cur_drag_item = nil,
	temp_dragging_item = nil,
	drag_from = nil,
	drag_from_tick = 0,
	drag_to = nil,
	drag_to_tick = 0,
	cur_data = {},

	push = function(self, ui)
		print('~~~push!!!', ui, ui.target_text_bg)
		local d = self.cur_data
		if not d.pushing_item then return end
		-- d.delta_lt = ui:global2Local(d.pos_x, d.pos_y) -- ui已经被删除了
		d.delta_lt = { x = d.pos_x, y = d.pos_y } -- ui已经被删除了
		if not d.delta_lt then return end
		d.tick_st = _tick()
		assert(ui == d.pushing_item)
		d.pushing_item = nil
		if ui.onPush then
			ui.onPush(d.delta_lt)
		end
	end,

	drag = function(self, ui) -- check ui.parent_ui, ui.drag_data, ui.onDrag
		print('drag!!!', ui, ui._width, ui._height)
		local d = self.cur_data
		-- d.delta_lt = ui:global2Local(d.pos_x, d.pos_y)
		d.delta_lt = { x = d.pos_x, y = d.pos_y }

		-- ui要在onDrag里删除，提前获取ui属性
		d.drag_ui_w = ui._width
		d.drag_ui_h = ui._height
		d.drag_from = ui.parent_ui
		d.temp_dragging_item = ui.temp_dragging_item
		
		local data = ui.drag_data
		if ui.onDrag and not ui.onDrag(d.delta_lt) then return end

		-- 
		d.pushing_item = nil
		d.drag_data = {}
		-- ui删了，data拷贝给d.drag_data了
		table.deep_clone(d.drag_data, data)

		d.drag_from.scrollable = false

		print('drag out!!!', d.drag_data, d.drag_ui_w, d.drag_ui_h)
		-- create a temp ui load(ui.drag_data)
	end,

	pick = function(self, p, u)
		local index = 1
		local picked
		if u.vertical then
			-- local c = u:getChildren()
			-- for i = 1, #c - 1 do
			-- end
		else
			for i, v in ipairs(u:getChildren()) do
				if not picked and p_in_ui(p, v) then
					picked = v
				end
				local vx = v:local2Global(v._width, 0)
				-- if p.x > v._x + v._width then
				if p.x > vx.x then
					index = index + 1
				end
			end
		end

		return picked, index
	end,

	droppable = function(self, u)
		local d = self.cur_data
		local x, y = d.pos_x, d.pos_y
		-- local p = u:global2Local(x, y)
		-- local p = u:global2Local(x, y)
		local p = { x = x, y = y }
		local uw = u._width
		local uh = u._height

		-- print('~~~d.temp_dragging_item.position', x,y,d.temp_dragging_item)

		if d.temp_dragging_item then
			-- d.temp_dragging_item._x = x / 0.7 - d.delta_lt.x
			-- d.temp_dragging_item._y = y / 0.7 - d.delta_lt.y
			d.temp_dragging_item._x = x / 0.7 - d.temp_dragging_item._width / 2
			d.temp_dragging_item._y = y / 0.7 - d.temp_dragging_item._height / 2
		end

		-- todo find nearest intersect u
		if not p_in_ui(p, u, true) then
			-- delete d.drop_item from u
			if d.drop_item then
				print('delete d.drop_item from u')
				d.drop_item.visible = true
				d.drop_item.onDroppedOut()
				d.drop_item = nil
			end
			
			return false 
		end
		-- try drop
		-- insert data to u.data
		-- u:onDrop(p.x, p.y, d.drag_data)
		-- 
		-- if not d.drop_item then
			-- d.drop_item = u:addChild(...)

		-- TODO: 获取index，考虑drop_item刚加入时的情况，应该用两侧的判断
		if d.drop_item and p_in_ui(p, d.drop_item) then
			return true
		end

		local picked, index = self:pick(p, u)
		
		if d.drop_item then
			if u.tryDrop(picked, index, d.drag_data) then
				d.drop_item.visible = true
				d.drop_item.onDroppedOut()
				d.drop_item = nil

				-- 删除了占位item，重新pick
				picked, index = self:pick(p, u)
			end
		end
		
		if d.drop_item == nil then
			d.drop_item = u.onDrop(picked, index, d.drag_data)
			print('create drop item')
		end

		return true
	end,

	drop = function(self, ui)
		local d = self.cur_data
		print('drop!!!', ui, d.drag_item, d.drop_item)
		if not d.drag_data then return end
		d.drag_from.scrollable = true

		local droppable = false
		if d.drop_item then
		--     drop cur_drag_item to drag_to.temp
			-- move drag to drop
			-- d.drop_item:setData(d.drag_data)
			-- if d.drag_item.onDroppedOut then
			-- 	d.drag_item._width = d.drag_ui_w
			-- 	d.drag_item._height = d.drag_ui_h
			-- 	d.drag_item.visible = true
			-- 	d.drag_item.onDroppedOut()
			-- end

			d.drop_item.visible = true
		-- elseif d.drag_item.onDroppedOut then
		-- 	d.drag_item._width = d.drag_ui_w
		-- 	d.drag_item._height = d.drag_ui_h
		-- 	d.drag_item.visible = true
		-- 	d.drag_item.onDroppedOut()
		-- else
			-- drop cur_drag_item to drag_from.temp
			-- d.drag_item._width = d.drag_ui_w
			-- d.drag_item._height = d.drag_ui_h
			-- d.drag_item.visible = true
		end
		-- drag done : clear all temp objects
		if d.temp_dragging_item then
			d.temp_dragging_item.visible = false
			-- d.temp_dragging_item = nil
		end

		self.cur_data = {}

		-- Global.BlockChipUI:dumpData()
	end,

	update = function(self, e)
		local d = self.cur_data
		if d.pushing_item and _tick() - self.cur_data.tick_st > 500 then
			-- 鼠标一直不动的情况，不会触发mousemove里的push，在update里做
			print('~~~update', d.pushing_item, d.pushing_item.target_text_bg)
			self:push(d.pushing_item)
		end

		if not d.drag_data then return end
		
		local x, y = d.pos_x, d.pos_y
		local sw, sh = d.drag_ui_w, d.drag_ui_h

		-- draw dragging item
		-- _rd:drawRect(x - sw / 2, y - sh / 2, x + sw / 2, y + sh / 2, 0xffffff00)
		-- update2: drag_item.pos

		-- update3: picking droppable_ui
		for _, u in next, self.droppable_uis do
			if self:droppable(u) then
				-- self:try_drop(u)
				break
			end
		end

		-- update3: docking drag_item to drag_to.temp
	end,

	-- dragManager:add_draggable_ui(item)
	add_draggable_ui = function(self, ui, temp, parent)
		-- print('~~~add_draggable_ui', ui, ui.target_text_bg)
		ui.temp_dragging_item = temp
		ui.parent_ui = parent
		-- check ui.parent_ui, ui.drag_data, ui.onDrag
		ui.onMouseDown = function(args)
			self.cur_data.pos_sx = args.mouse.x * (_Fairy.root._xscale / 100)
			self.cur_data.pos_sy = args.mouse.y * (_Fairy.root._yscale / 100)
			self.cur_data.pos_x = self.cur_data.pos_sx
			self.cur_data.pos_y = self.cur_data.pos_sy

			self.cur_data.tick_st = _tick()
			self.cur_data.pushing_item = ui
			-- parent.scrollable = false
		end
		ui.onMouseMove = function(args)
			self.cur_data.pos_x = args.mouse.x * (_Fairy.root._xscale / 100)
			self.cur_data.pos_y = args.mouse.y * (_Fairy.root._yscale / 100)
			self.cur_data.pos_dx = self.cur_data.pos_x - self.cur_data.pos_sx
			self.cur_data.pos_dy = self.cur_data.pos_y - self.cur_data.pos_sy
			self.cur_data.tick_dt = _tick() - self.cur_data.tick_st

			-- print('dx_dy', self.cur_data.pos_dx, self.cur_data.pos_dy)
			
			if self.cur_data.drag_data then return end

			if self.cur_data.tick_dt > 500 then
				if math.abs(self.cur_data.pos_dx) < 10 and math.abs(self.cur_data.pos_dy) < 10 then
					-- pushing
					self:push(ui)
				else
					-- drag_begin
					self:drag(ui)
				end
			else
				-- parent.scrollable = true
				-- cancel
				-- self:cancel()
			end
		end
		
		ui.onMouseUp = function(args)
			print('UI drop', ui)
			self:drop(ui)
		end
		parent.onMouseUp = function(args)
			print('parent drop', parent)
			self:drop()
		end
	end,

	add_droppable_ui = function(self, ui)
		table.insert(self.droppable_uis, ui)
	end,

	reset = function(self)
		self.droppable_uis = {}
	end,
}

-- Global.dragManager = dragManager
_app:registerUpdate(dragManager)


-------------------------------------
local function select_btn(btn, sel)
	btn.selected_icon.visible = sel
end

local blockchip = {}
blockchip.init = function(self)
	if self.ui then return end
	self.ui = Global.UI:new('BlockChip.bytes', 'screen')
	self.ui.visible = false

	self.rtdata = {
		selected_chip_cfg = nil,
		selected_chip = nil,
	}

	self.ui.btn_undo.click = function()
		print('btn_undo')
	end
	self.ui.btn_redo.click = function()
		print('btn_redo')
	end
	self.ui.btn_block_chip.click = function()
		print('btn_block_chip')
	end
	self.ui.btn_group.click = function()
		print('btn_group')
	end
	self.ui.close.click = function()
		self.ui.visible = false

		print('Data:', table.ftoString(self.cur_chipss_data))

		-- Global.UI:slideout({self.ui})
		-- Global.Timer:add('hideui', 150, function()
		-- 	self.ui.visible = false
		-- 	Global.SwitchControl:set_input_on()
		-- 	Global.SwitchControl:set_render_on()
		-- 	-- ui.profile_btn.visible = true
			Global.UI:popAndShow()
		-- end)

		if self.closecb then
			print('close click', self.closecb)
			self.closecb()
			self.closecb = nil
		end
	end

	self.ui.click_back.click = function()
		print('show back')
		self:show('back')
	end

	self:initTypeList()

	-- self:refreshParamDetail_Nodes()
	self:initParamDetail_Number()
	self:initParamDetail_Direction()
	self:initParamDetail_SetGet('set')
	self:initParamDetail_SetGet('get')
	self:initParamDetail_SetGet('Gset')
	self:initParamDetail_SetGet('Gget')
	self:initParamDetail_Enum()
	self:initParamDetail_Formula()
	self:initParamDetail_Ms()
	self:initParamDetail_Time()
	self:initParamDetail_Func()
	self:initParamDetail_Condition()

	print('init', #self.cur_logic_enums, #self.cur_logic_names)
end

blockchip.show = function(self, stage, data, closecb)
	if data then -- call by buildbrick
		Global.UI:pushAndHide('normal')
	end
	--print('!!!!!!!!!!UIDATA', data and table.ftoString(data))

	self.ui.visible = true
	self.closecb = closecb or self.closecb
	if stage == 'back' then
		if self.show_stage == 'main' then
			-- assert(false)
			return
		elseif self.show_stage == 'lib' then
			stage = 'main'
		elseif self.show_stage == 'param' then
			stage = 'lib'
		else
			stage = 'main'
		end
	end

	if stage == 'main' then
		self.ui.mainlist.visible = true
		self.ui.chiplib.visible = false
		self.ui.chiplib.typelist.visible = false
		self.ui.chiplib.mainlist.visible = false
		self.ui.chiplib.bg.visible = false
		self.ui.chiplib.chiplist.visible = false
		self.ui.chip_params.visible = false

		if data then
			self:refreshMainList(data)
			self:selectMainList(1)
		else
			self:refreshMainList(self.cur_chipss_data)
			self:selectMainList(self.cur_chips_sel_index)
		end

	elseif stage == 'lib' then
		self.ui.mainlist.visible = false
		self.ui.chiplib.visible = true
		self.ui.chiplib.typelist.visible = true
		self.ui.chiplib.mainlist.visible = true
		self.ui.chiplib.bg.visible = true
		self.ui.chiplib.chiplist.visible = true
		self.ui.chip_params.visible = false
	elseif stage == 'param' then
		self.ui.mainlist.visible = false
		self.ui.chiplib.visible = true
		self.ui.chiplib.typelist.visible = false
		self.ui.chiplib.mainlist.visible = false
		self.ui.chiplib.bg.visible = false
		self.ui.chiplib.chiplist.visible = true
		self.ui.chip_params.visible = true
	end
	self.show_stage = stage

	
	dragManager:reset()


	-- Global.UI:pushAndHide('normal')
	-- local callback = function()
	-- 	self.ui.visible = true
	-- 	Global.SwitchControl:set_input_off()
	-- 	-- ui.profile_btn.visible = false
	-- end
	-- if not self.timer then self.timer = _Timer.new() end
	-- _G:holdbackScreen(self.timer, callback)
end

local ui_img_cfg = {
	Targets = {
		bgimg = 'img://chip_event.png',
	},
	Events = { 
		bgimg = 'img://chip_event.png',
		tabimg = {
			sortindex = 1,
			kind = 'Events',
			bgicon = 'chip_tab_events.png',
			bgicon_sel = 'chip_tab_events_sel.png',
		},
	},
	Attrs = { 
		bgimg = 'img://chip_attr.png',
		tabimg = {
			sortindex = 2,
			kind = 'Attrs',
			bgicon = 'chip_tab_attrs.png',
			bgicon_sel = 'chip_tab_attrs_sel.png',
		},
	},
	Renders = { 
		bgimg = 'img://chip_render.png',
		tabimg = {
			sortindex = 3,
			kind = 'Renders',
			bgicon = 'chip_tab_renders.png',
			bgicon_sel = 'chip_tab_renders_sel.png',
		},
	},
}

blockchip.showLib = function(self, kind)
	local uilib = self.ui.chiplib
	if kind == false then
		uilib.typelist.visible = false
		uilib.mainlist.visible = false
		return
	end

	uilib.visible = true
	uilib.typelist.visible = true
	uilib.mainlist.visible = true

	kind = kind or 'Events'

	if self.sel_lib_kind ~= kind then
		self.sel_lib_kind = kind
		return self:selectTypeList(kind)
	end

	if self.show_lib_kind == kind then return end
	self.show_lib_kind = kind

	local bgimg = ui_img_cfg[kind].bgimg
	local ui_chip_names = _G.CHIP_CONFIG[kind]


	uilib.mainlist.onRenderItem = function(index, item)
		local chip_cfg = ui_chip_names[index]
		-- local predata = 
		item.drag_data = chip_cfg.data -- { Name = chip_cfg.Name, Target = { target = 'Self' } }

		item.click = function()
			local data = {}
			table.deep_clone(data, chip_cfg.data)
			table.insert(self.cur_chips_data, data)
			self:refreshMainChipList()
		end
		item.bg._icon = bgimg
		item.icon._icon = chip_cfg.ui_icon
		item.name.text = chip_cfg.Name2 or chip_cfg.Name
		item.desc.text = chip_cfg.Desc

		item.onDrag = function()
			local temp = item.temp_dragging_item
			temp.bg._icon = item.bg._icon
			temp.icon._icon = item.icon._icon
			temp.name.text = item.name.text
			temp.desc.text = item.desc.text

			temp.visible = true
			item.visible = true
			print(item, 'onDrag')
			return true
		end
		
		item.onPush = function()
			print(item, 'onPush')
		end

		dragManager:add_draggable_ui(item, self.ui.chipnode_temp, uilib.mainlist)
	end

	uilib.mainlist.itemNum = #ui_chip_names
end

local cfg_chip_kinds = { 'Events', 'Attrs', 'Renders' }
blockchip.initTypeList = function(self)
	local list = self.ui.chiplib.typelist
	local datas = { ui_img_cfg.Events.tabimg, ui_img_cfg.Attrs.tabimg, ui_img_cfg.Renders.tabimg }
	self.ui_type_list = {}
	list.onRenderItem = function(index, item)
		item.disabled = false
		local data = datas[index]
		item.c1._icon = 'img://' .. data.bgicon
		item.c2._icon = 'img://' .. data.bgicon_sel
		item.index = data.sortindex
		item._sound = Global.SoundList.ui_click18
		item.click = function()
			print('Select type:', index, data.sortindex)
			self:selectTypeList(cfg_chip_kinds[index])
		end

		table.insert(self.ui_type_list, item)
	end

	list.itemNum = #datas
end

blockchip.selectTypeList = function(self, kind)
	for i, v in next, self.ui_type_list do
		if cfg_chip_kinds[i] == kind then
			v.sortingOrder = 100
			v.selected = true
		else
			v.sortingOrder = 10-i
			v.selected = false
		end
	end

	self.sel_lib_kind = kind 
	self:showLib(kind)
end

local function is_Event_Kind(data)
	return _G.CHIP_CONFIG.chiplist[data.Name].Kind == 'Events'
end

local function get_chip_pid(cs, chips)
	for i, c in ipairs(cs) do
		if c.data ~= 'Add' and c.data.sub_chips == chips then 
			return i
		end
	end

	return -1
end

local function expand_chips(cs, chips, depth)
	for i, chip in ipairs(chips) do
		-- print(i, table.ftoString(chip))
		if is_Event_Kind(chip) and not chip.sub_chips then
			chip.sub_chips = {}
		end

		local c = { data = chip, index = i, pid = get_chip_pid(cs, chips), depth = depth }

		table.insert(cs, c)
		if chip.sub_chips then
			expand_chips(cs, chip.sub_chips, depth + 1)
		end
	end

	if depth > 1 then
		local lastc = { pid = get_chip_pid(cs, chips), depth = depth, data = 'Add' }
		if #chips == 0 then lastc.firstp = true end
		table.insert(cs, lastc)
	end
end

blockchip.find_chip_parent = function(self, pid)
	if pid == -1 then 
		return self.cur_chips_data
	else
		return self.cur_chips_data_expand[pid].data.sub_chips
	end
end

blockchip.find_chip_index = function(self, data)
	for i, v in ipairs(self.cur_chips_data_expand) do
		if v.data == data then
			return i
		end
	end

	return -1
end

blockchip.find_chip_item = function(self, data)
	local uilist = self.ui.chiplib.chiplist.itemlist
	local index = self:find_chip_index(data)
	return uilist:getChildren()[index]
end

local function find_chip_temp(data, cs)
	for i, c in ipairs(cs) do
		if c.data == data then 
			return c, i
		end
	end

	assert(false)
end

local function get_target(t)
	return t.params and t.params[1] and t.params[1].Value or t.target
end

local function is_child_target(t)
	return get_target(t) == 'Children'
end

local function is_same_target(t1, t2) -- t1 = { target = '', params = {} }
	if not t1 or not t2 or t1.target ~= t2.target then
		return false
	elseif t1.target ~= 'UserDefined' then
		-- return true
	end

	return table.compareTable(t1.params, t2.params)
end

local function calc_chip_targets(chips, cs)
	local temp_tar
	local first_c
	for i, chip in ipairs(chips) do
		local c, cindex = find_chip_temp(chip, cs)
		if not is_same_target(temp_tar, chip.Target) then
			temp_tar = chip.Target

			if is_child_target(chip.Target) and first_c then
				first_c.tail_id = cs[cindex].tail_id or cindex
			elseif is_Event_Kind(chip) then
				temp_tar = nil
				first_c = nil
			else
				first_c = c
			end

			c.show_target = true
			-- print('!!!', i, cindex, chip.Target.target, chip.Name, first_c)
		else
			-- print('~~~', i, cindex, chip.Target.target, chip.Name, first_c, c.tail_id)
			if c.tail_id then
				-- if not is_Event_Kind(chip) then
					-- print('!!!', c.tail_id, chip.Name)
				-- end
				assert(is_Event_Kind(chip)) 
			end
			if first_c then
				first_c.tail_id = c.tail_id or cindex
			end
			c.show_target = false
		end

		if chip.sub_chips then
			calc_chip_targets(chip.sub_chips, cs)
		end
	end
end

-- tail_id: 框到那儿
local function calc_event_chip_width(cs)
	for i, c in ipairs(cs) do
		c.tail_id = nil
	end
	for i, c in ipairs(cs) do
		if c.data == 'Add' then
			cs[c.pid].tail_id = i
		end
	end
end


blockchip.calc_chipnode_bg_width = function(self)
	local uilist = self.ui.chiplib.chiplist.itemlist
	local chips = self.cur_chips_data
	local cs = self.cur_chips_data_expand
	local ui_items = uilist:getChildren()

	print('calc_chipnode_bg_width=============================')
	-- self:dumpData()
	calc_event_chip_width(cs)
	-- self:dumpData()
	calc_chip_targets(chips, cs)
	-- self:dumpData()

	-- rule : 第一个event隐藏self
	if cs[1] and is_Event_Kind(cs[1].data) and get_target(cs[1].data.Target) == 'Self' then
		cs[1].show_target = false
	end

	for i, item in ipairs(ui_items) do
		local c = cs[i]
		if c.show_target then
			item.target_text_bg.visible = true
			item.target_text.visible = true
			item._width = item.target_text_bg._width + item.chip._width
		elseif c.data ~= 'Add' then
			item.target_text_bg.visible = false
			item.target_text.visible = false
			item._width = item.chip._width
		else
			item._width = item.event_add._width
		end
	end

	local function get_width_from_to(i1, i2)
		local width = 0
		for i = i1, i2 do 
			width = width + ui_items[i]._width
		end
		return width
	end

	for i, item in ipairs(ui_items) do
		local c = cs[i]
		if c.tail_id then
			if is_Event_Kind(c.data) then
				item.target_bg.visible = false
				item.chip_bg.visible = true
				item.chip_bg._width = get_width_from_to(i + 1, c.tail_id) + 100 
			else
				item.chip_bg.visible = false
				item.target_bg.visible = true
				item.target_bg._width = get_width_from_to(i + 1, c.tail_id) + 220
			end
		else
			item.target_bg.visible = false
			item.chip_bg.visible = false
		end
	end
end

blockchip.dumpData = function(self)
	print('!!!!!!!!data:', table.ftoString(self.cur_chips_data))
	print('!!!!!!!!!expand:', table.ftoString(self.cur_chips_data_expand))
end

blockchip.refreshMainChipList = function(self)
	local uilist = self.ui.chiplib.chiplist.itemlist
	local chips_data = self.cur_chips_data
	-- print('!!!!!!', table.ftoString(self.cur_chips_data))
	local cs = {}
	expand_chips(cs, chips_data, 1)
	self.cur_chips_data_expand = cs
	-- print('cscscscs!!!!!!',table.ftoString(self.cur_chips_data_expand))
	
	uilist.onRenderItem = function(index, item)
		local c = cs[index]
		item.temp_chip_data = c

		if c.data ~= 'Add' then
			item.drag_data = c.data
			local chipitem = item.chip

			local chip_cfg = _G.CHIP_CONFIG.chiplist[c.data.Name]
			if is_Event_Kind(c.data) then
				item.target_bg.visible = false
				item.chip_bg.visible = true
			else
				item.target_bg.visible = true
				item.chip_bg.visible = false
			end
			chipitem.visible = true
			item.target_text_bg.visible = true
			item.target_text.visible = true

			item.target_text.text = get_target(c.data.Target)
			item.event_add.visible = false

			chipitem.del.visible = false
			chipitem.bg._icon = ui_img_cfg[chip_cfg.Kind].bgimg
			chipitem.icon._icon = chip_cfg.ui_icon
			chipitem.name.text = chip_cfg.Name2 or chip_cfg.Name
			chipitem.desc.text = chip_cfg.Desc
			chipitem.click = function()
				-- if self.show_stage ~= 'lib' then return end
				if chipitem.click_tick and os.now() - chipitem.click_tick < 500 then
					print('chipitem.click', index, c.data.Name)
					self:editChipParams(c.data)
				end
				chipitem.click_tick = os.now()
			end

			local targetitem = item.target_text_bg
			targetitem.click = function()
				if targetitem.click_tick and os.now() - targetitem.click_tick < 500 then
					-- print(index, c.data.Name, c.data.Target)
					if not c.data.Target then c.data.Target = { target = 'Self', params = { { Type = 'get', Op = '', Value = 'Self' } } } end
					self:editChipParams(c.data.Target)
				end
				targetitem.click_tick = os.now()
			end

			item.onDrag = function(p)
				-- 只有 chipitem 能拖动 targetitem 拖不动
				if not p_in_ui(p, chipitem) then return false end
				print('~~~onDrag', item, item.target_text_bg)

				local temp = item.temp_dragging_item
				temp.bg._icon = chipitem.bg._icon
				temp.icon._icon = chipitem.icon._icon
				temp.name.text = chipitem.name.text
				temp.desc.text = chipitem.desc.text
	
				temp.visible = true
				-- item.visible = false
				
				print(item, 'onDrag')
	
				-- 能拖动，把自己删除，把data拷贝给了tempitem
				item.onDroppedOut()
				return true
			end
			item.onDroppedOut = function()
				print('~~~onDroppedOut', item, item.target_text_bg, index)
				local p = self:find_chip_parent(c.pid)
				for i, v in ipairs(p) do
					if v == c.data then
						print('ok')
						table.remove(p, i)
						self:refreshMainChipList()

						-- print('~~~onDroppedOut END', item, item.target_text_bg)
						return
					end
				end
			end
			item.onPush = function(p)
				print('~~~onPush', item, item.target_text_bg)
				if item.target_text_bg.visible then return end
				if not p_in_ui(p, item.target_bg) then return end
				print('onPush ================', item.target_bg.text, c.data.target)
				-- show targetitem
				-- update size
				-- c.data.Target.target = 'Children'

				-- item.target_text.text = c.data.Target.target
				item.target_text_bg.visible = true
				item.target_text.visible = true
				item._width = item.target_text_bg._width + item.chip._width
				-- self:calc_chipnode_bg_width()

				return true
			end

			item.onDrop = nil

			dragManager:add_draggable_ui(item, self.ui.chipnode_temp, uilist)
		else
			item.target_bg.visible = false
			item.chip_bg.visible = false
			item.chip.visible = false
			item.target_text_bg.visible = false
			item.target_text.visible = false

			item.event_add.visible = true
			item.event_add._icon = ''
			-- item._width = item.event_add._width

			item.onDrag = function(p)
				return false
			end

			item.onDroppedOut = nil
			item.onPush = nil

			item.onDrop = function(data)
				print('item.onDrop', item, c.pid, self:find_chip_parent(c.pid))
				-- self:dumpData()
				table.insert(self:find_chip_parent(c.pid), data)
				self:refreshMainChipList()
				return self:find_chip_item(data)
			end

			-- item.click = nil
		end
	end

	uilist.itemNum = #cs

	self:calc_chipnode_bg_width()

	uilist.tryDrop = function(item, index, data)
		if item and item.onDrop then
			local parent = self:find_chip_parent(item.temp_chip_data.pid)
			if parent == data then
				print('11111111111111')
				return false
			end

			local lastone = parent[#parent]
			if lastone and lastone == data then 
				print('222222222222222')
				return false
			else
				print('333333333333333')
				return true
			end
		end

		local cs = self.cur_chips_data_expand
		local pre_chip = cs[index - 1]
		local parent, index
		if not pre_chip then
			
			print('所有最前')
			parent = self.cur_chips_data
			index = 1

			-- return parent[1] ~= data
		elseif pre_chip.data == 'Add' then
			
			print('event_add之后')
			local event_chip = cs[pre_chip.pid]
			local p_chip = self:find_chip_parent(event_chip.pid)
			parent = p_chip
			index = event_chip.index + 1
			
			if event_chip.data == data then
				print('event_add自己')
				return false
			end

		elseif is_Event_Kind(pre_chip.data) then
			print('event第一个子')
			parent = pre_chip.data.sub_chips
			index = 1

			-- return parent[1] ~= data
		else
			print('77777777777777777777')
			local p_chip = self:find_chip_parent(pre_chip.pid)
			parent = p_chip
			index = pre_chip.index + 1
		end

		print('index', index)

		if parent[index] == data then 
			print('8888888888888888')
			return false
		end

		if parent[index-1] == data then
			print('99999999999999999')
			-- return false
		end

		return true
	end

	uilist.onDrop = function(item, index, data)
		-- 1.drop 到了 Add上
		if item and item.onDrop then
			local d = item.onDrop(data)
			d.drop_index = index
			d.visible = false
			print('AAAAAAAAAAAAA')
			return d
		end
		-- 2.drop到了list上，或者挤到两个chip之间 都会有index
		local cs = self.cur_chips_data_expand
		local pre_chip = cs[index - 1]
		if not pre_chip then
			table.insert(self.cur_chips_data, 1, data)
			print('BBBBBBBBBBBBBBBBBBBB')
		elseif pre_chip.data == 'Add' then
			-- local event_chip = self:find_chip_parent(pre_chip.pid)
			local event_chip = cs[pre_chip.pid]
			local p_chip = self:find_chip_parent(event_chip.pid)
			table.insert(p_chip, event_chip.index + 1, data)
			print('CCCCCCCCCCCCCCCCC')
		elseif is_Event_Kind(pre_chip.data) then
			table.insert(pre_chip.data.sub_chips, 1, data)
			print('DDDDDDDDDDDDDDDD')
		else
			local p_chip = self:find_chip_parent(pre_chip.pid)
			table.insert(p_chip, pre_chip.index + 1, data)
			print('EEEEEEEEEEEEEEEEE')
		end

		self:refreshMainChipList()

		local item = self:find_chip_item(data)
	
		item.drop_index = index
		item.visible = false

		print('FFFFFFFFFFFFFFFFFFFFF')

		return item
	end

	dragManager:add_droppable_ui(uilist)
end  

blockchip.refreshChipList = function(self, uilist, chips_data)
	uilist.chips_data = chips_data

	uilist.onRenderItem = function(index, item)
		local chip_data = chips_data[index]
		local chip_cfg = _G.CHIP_CONFIG.chiplist[chip_data.Name]
		item.drag_data = chip_data
		item.click = function()
			-- if self.show_stage ~= 'lib' then return end
			if item.click_tick and os.now() - item.click_tick < 500 then
				print(index, chip_data.Name)
				self:editChipParams(chip_data)
			end
			item.click_tick = os.now()
		end
		if item.del then
			-- item.del.visible = self.show_stage == 'lib'
			item.del.click = function()
				table.remove(chips_data, index)
				self:refreshChipList(uilist, chips_data)
			end
		end
		item.bg._icon = ui_img_cfg[chip_cfg.Kind].bgimg
		-- TODO: 尺寸
		-- item.bg._width = 250 
		-- item.bg._height = 380
		item.icon._icon = chip_cfg.ui_icon
		item.name.text = chip_cfg.Name2 or chip_cfg.Name
		if item.desc then
			item.desc.text = chip_cfg.Desc
		end
		-- if index > 1 then
			-- print('item scale:', item._xscale, item._yscale)
			-- item._xscale = 95
			-- item._yscale = 95
			-- print('item scale2:', item._xscale, item._yscale)
		-- end
		item.onDrag = function()
			local temp = item.temp_dragging_item
			temp.bg._icon = item.bg._icon
			temp.icon._icon = item.icon._icon
			temp.name.text = item.name.text
			temp.desc.text = item.desc and item.desc.text or ''

			temp.visible = true
			-- item.visible = false
			
			print(item, 'onDrag')

			item.onDroppedOut()
			return true
		end
		item.onDroppedOut = function()
			print('onDroppedOut', item, index)
			table.remove(chips_data, index)
			self:refreshChipList(uilist, chips_data)
		end
		item.onPush = function()
			print(item, 'onPush')
		end

		-- dragManager:add_draggable_ui(item, self.ui.chipnode_temp, uilist)
	end

	uilist.itemNum = #chips_data
	
	uilist.onDrop = function(index, data)
		print('inserting', chips_data, index, data)
		table.insert(chips_data, index, data)
		-- print(table.ftoString(data), table.ftoString(chips_data))
		self:refreshChipList(uilist, chips_data)
		for i, v in ipairs(uilist:getChildren()) do
			print(i, v)
		end
		local item = uilist:getChildren()[index]
		item.visible = false
		item.drop_index = index
		return item
	end

	-- dragManager:add_droppable_ui(uilist)
end

blockchip.refreshMainList = function(self, chipss_data)
	local num = #chipss_data
	local uilist = self.ui.mainlist
	self.ui_chipss = {}
	self.cur_chipss_data = chipss_data
	uilist.onRenderItem = function(index, item)
		local chips_data = chipss_data[index]
		if chips_data then
			-- item.bg._icon = ''
			item.detaillist.visible = false
			item.detailbg.visible = false
			item.brieflist.visible = true
			item.briefbg.visible = true
			item.del.visible = false
			item.add.visible = false
			self:refreshChipList(item.detaillist, chips_data)
			self:refreshChipList(item.brieflist, chips_data)
			item.click = function()
				print('mainlist', index, item, item.selected)
				
				if item.click_tick and os.now() - item.click_tick < 500 then
				-- if item.temp_selected then
					-- self:refreshTypeList()
					self:show('lib')
					self:showLib('Events')
					-- self:refreshChipList(self.ui.chiplib.chiplist.itemlist, chips_data)
					self:selectMainList(index)
					self:refreshMainChipList()
					-- uilist.visible = false
				else
					self:selectMainList(index)
				end

				item.click_tick = os.now()
			end
			item.del.click = function()
				Confirm('Confirm deletion?', function() 
					table.remove(chipss_data, index)
					self:refreshMainList(chipss_data)
					self:selectMainList(math.max(1, index - 1))
				end, function() 
				end)
			end
			table.insert(self.ui_chipss, item)
		else
			item._height = item.brieflist._height
			item.detaillist.visible = false
			item.detailbg.visible = false
			item.brieflist.visible = false
			item.briefbg.visible = true
			item.del.visible = false
			item.add.visible = true
			item.add.click = function()
				table.insert(chipss_data, {})
				self:refreshMainList(chipss_data)
				self:selectMainList(index)
			end
		end
	end
	uilist.itemNum = num + 1
end

blockchip.selectMainList = function(self, index)
	for i, v in next, self.ui_chipss do
		if index == i then
			-- v.temp_selected = true
			-- print('sel', i, v, v.temp_selected)
			v.detaillist.visible = true
			v.detailbg.visible = true
			v.del.visible = true
			v.brieflist.visible = false
			v.briefbg.visible = false
			v._height = v.detaillist._height
			v._alpha = 100
		else
			-- v.temp_selected = false
			v.detaillist.visible = false
			v.detailbg.visible = false
			v.del.visible = false
			v.brieflist.visible = true
			v.briefbg.visible = true
			v._height = v.brieflist._height
			v._alpha = 75
		end
	end

	self.cur_chips_sel_index = index
	self.cur_chips_data = self.cur_chipss_data[index]
end

blockchip.updateChipParams_Target = function(self, chip_data)
	-- test data
	assert(chip_data.target)

	local ui = self.ui.chip_params.chip
	local uitar = ui.target
	local uilist = ui.target_list
	local ts = _G.CHIP_TARGETS

	local select_target = function()
		local t = chip_data.target
		uitar.btn.title.text = t
		for i, v in ipairs(uilist:getChildren()) do
			v.btn.selected = v.text.text == t
			v.btn.icon._icon = v.text.text == t and 'ui://n20the6gt50u2t' or 'ui://n20the6gt50u3l'
			select_btn(v.btn, v.text.text == t)
		end
	end

	uilist.onRenderItem = function(index, item)
		-- item.text.text = [[<img src='ui://xovwx195eqhuc' width = '100%' height = '100%'>Self]]
		item.btn.title.text = ts[index]
		item.btn.click = function()
			chip_data.target = ts[index]
			select_target()
			uilist.visible = false
			self:refreshMainChipList()
		end
	end

	uilist.itemNum = #ts

	uitar.btn.click = function()
		uilist.visible = not uilist.visible
	end

	select_target()
end

blockchip.editChipParams = function(self, chip_data)
	self.rtdata.selected_chip = chip_data
	self.rtdata.selected_chip_cfg = _G.CHIP_CONFIG.chiplist[chip_data.Name]
	
	chip_data.params = chip_data.params or {}
	self.rtdata.cur_chip_params = chip_data.params

	-- fade out other ui, slide in
	self:show('param')

	self.ui.chip_params.visible = true
	local uichip = self.ui.chip_params.chip
	-- local uilist = self.ui.chip_params.list
	-- local uidetail = self.ui.chip_params.detail
	-- local btntarget = self.ui.chip_params.btn_target
	uichip.target_list.visible = false

	if chip_data.target then
		uichip.target.visible = false
		
		uichip.bg._icon = ui_img_cfg['Targets'].bgimg
		uichip.name.text = ''
		uichip.desc.text = '...'

		self:updateChipParams_Target(chip_data)
	else
		uichip.target.visible = false

		local chip_cfg = _G.CHIP_CONFIG.chiplist[chip_data.Name]
	
		local bgimg = ui_img_cfg[chip_cfg.Kind].bgimg
		uichip.bg._icon = bgimg
		-- uilist.bg._icon = bgimg
		-- uidetail.bg._icon = bgimg
		-- uichip.icon._icon = chip_cfg.ui_icon
		uichip.name.text = chip_cfg.Name2 or chip_cfg.Name
		uichip.desc.text = chip_cfg.Desc
		uichip.click = function()
			print(chip_data.Name)
		end
	end

	if chip_data.Name == 'Action' then
		self.cur_logic_names = Global.DfActionType
	elseif chip_data.Name == 'PFX' then
		self.cur_logic_names = Global.Marker_PfxRess_Order
	elseif chip_data.Name == 'SFX' then
		self.cur_logic_names = Global.Marker_SoundRess_Order
	else
		self.cur_logic_names = _G.BLOCK_LOGIC_NAMES
	end

	self:refreshParamList()
	self:selectParamList(1)
end

local function get_pid(ps, params)
	for i, p in ipairs(ps) do
		if p.data ~= 'Add' and p.data.sub_params == params then 
			return i
		end
	end

	return -1
end

local function refresh_params_node(ps, id)
	local p = ps[id]
	if p.data.sub_params then p.data.expand = true end
	if p.pid ~= -1 then refresh_params_node(ps, p.pid) end
end

local function refresh_params_tree(ps, id)
	for i, p in ipairs(ps) do if p.data~='Add' then p.data.expand = nil end end
	refresh_params_node(ps, id)
end

local function expand_params(ps, params, depth)
	for i, param in ipairs(params) do
		local p = { data = param, index = i, pid = get_pid(ps, params), depth = depth }

		table.insert(ps, p)
		if param.sub_params and param.expand then
			expand_params(ps, param.sub_params, depth + 1)
		end
	end
	local lastp = { pid = get_pid(ps, params), depth = depth, data = 'Add' }
	if #params == 0 then lastp.firstp = true end
	table.insert(ps, lastp)
end

local function calc_sub_params_width(ps)
	for i = 1, #ps do
		if ps[i].index == 1 then
			for j = i + 1, #ps do
				if ps[i].depth == ps[j].depth and ps[j].data == 'Add' then
					ps[i].subs_count = j - i + 1
				end
			end
		end
	end
end

blockchip.find_param_parent = function(self, pid)
	if pid == -1 then 
		return self.rtdata.cur_chip_params
	else
		local ps = self.rtdata.cur_chip_params_data
		return ps[pid].data.sub_params
	end
end

blockchip.refreshParamList = function(self)
	local chip_params = self.rtdata.cur_chip_params
	local ps = {}
	expand_params(ps, chip_params, 1)
	calc_sub_params_width(ps)

	local num = #ps
	local uilist = self.ui.chip_params.list.list
	self.ui_chip_params = {}
	self.rtdata.cur_chip_params_data = ps
	uilist.onRenderItem = function(index, item)
		table.insert(self.ui_chip_params, item)

		local p = ps[index]
		item.drag_data = p.data

		if p.data ~= 'Add' then
			item.desc.text = _G.CHIP_PARAM_RULES.get_desc(p.data)
			-- item.desc.text = p.depth
			if item.desc.text == '' and p.data.Type then
				item.icon._icon = 'img://chip_' .. p.data.Type .. '.png'
			else
				item.icon._icon = ''
			end
			item.click = function()
				self:selectParamList(index)
			end

			if p.subs_count and p.depth > 1 then
				item.bg.visible = true
				item.bg._width = 250 - p.depth * 10
				item.bg._height = p.subs_count * 200 + 70
			else
				item.bg.visible = false
			end
		else
			item.desc.text = '＋'
			item.icon._icon = ''
			-- item.icon._icon = 'ui://n20the6gt50u2d'
			item.click = function()
				table.insert(self:find_param_parent(p.pid), {})
				self:refreshParamList()
				self:selectParamList(index)
			end
			-- item.bg.visible = false

			if p.firstp and p.depth > 1 then
				item.bg.visible = true
				item.bg._width = 250 - p.depth * 10
				item.bg._height = 265
			else
				item.bg.visible = false
			end
		end
	end
	uilist.itemNum = num
end

blockchip.selectParamList = function(self, index)
	local select_data = self.rtdata.cur_chip_params_data[index].data
	refresh_params_tree(self.rtdata.cur_chip_params_data, index)
	self:refreshParamList()
	for i, p in ipairs(self.rtdata.cur_chip_params_data) do
		if p.data == select_data then
			index = i
		end
	end

	self.rtdata.selected_param_index = index

	-- print(table.ftoString(self.cur_chip_params_data))
	for i, v in next, self.ui_chip_params do
		if index == i then
			-- v.gray = false
			select_btn(v, true)
		else
			-- v.gray = true
			select_btn(v, false)
		end
	end

	self.rtdata.cur_chip_param_index = index
	self.rtdata.cur_chip_param_data = self.rtdata.cur_chip_params_data[index].data
	self:refreshParamDetail()
	-- print('select END', table.ftoString(self.cur_chip_params_data))
end

local param_uis = {
	'number', 'direction', 'enum', 'formula',
	'ms', 'time', 'func', 'condition', 'set', 'get', 'Gset', 'Gget', 'nodes',
}

blockchip.refreshParamDetail_Nodes = function(self, options)
	local ops = _G.CHIP_PARAM_CONFIG.options[options or 'ALL'] or options
	local ui = self.ui.chip_params.detail.nodes.list
	ui.onRenderItem = function(index, item)
		local t = ops[index]
		item.desc.text = ''
		item.icon._icon = 'img://chip_' .. t .. '.png'
		item.click = function()
			self.rtdata.cur_chip_param_data.Type = t
			_G.CHIP_PARAM_RULES.apply(self.rtdata.cur_chip_param_data)
			self.rtdata.cur_chip_param_data.expand = true
			self:refreshParamList()
			self:refreshParamDetail()
		end
	end
	ui.itemNum = #ops
end

blockchip.updateParamNode = function(self)
	local index = self.rtdata.cur_chip_param_index
	local item = self.ui_chip_params[index]
	local data = item.drag_data
	if data == 'Add' then return end

	item.desc.text = _G.CHIP_PARAM_RULES.get_desc(data)
	if item.desc.text == '' and data.Type then
		item.icon._icon = 'img://chip_' .. data.Type .. '.png'
	else
		item.icon._icon = ''
	end
end

blockchip.initParamDetail_Number = function(self)
	local ui = self.ui.chip_params.detail.number

	local textLenMax = 10
	ui.positive = true
	ui.percent = false
	ui.number = ''

	local op_uis = {
		Add = 'n_add', 
		Sub = 'n_sub', 
		Mul = 'n_mul', 
		Div = 'n_div', 
		Set = 'n_set',
	}

	local function updateDisplay()
		local text = ui.number
		if not ui.positive then
			text = '-' .. text
		end
		if ui.percent then
			text = text .. '%'
		end
		ui.n_display.text = text

		if ui.param_data.Value ~= text then
			ui.param_data.Value = text
		end

		self:updateParamNode()
	end

	for i = 0, 9 do
		ui["n_" .. i].click = function()
			if string.len(ui.number) >= textLenMax then	return end
			if ui.number == '0' then ui.number = '' end
			ui.number = ui.number .. i
			updateDisplay()
		end
	end

	ui.n_AC.click = function()
		ui.positive = true
		ui.percent = false
		ui.number = '0'
		updateDisplay()
	end

	ui.n_dot.click = function()
		if ui.number:find"%." then return end
		if ui.number == "" then ui.number = '0' end
		ui.number = ui.number .. "."
		updateDisplay()
	end	

	ui.n_percent.click = function()
		ui.percent = not ui.percent
		updateDisplay()
	end

	ui.n_positive.click = function()
		ui.positive = not ui.positive
		updateDisplay()
	end

	local function select_op(op)
		for k, n in next, op_uis do
			ui[n].selected = op == k
			ui[n].icon._icon = op == k and 'img://chip_sbtn_sel.png' or 'img://chip_sbtn.png'
		end

		if ui.param_data.Op ~= op then
			ui.param_data.Op = op
		end

		self:updateParamNode()
	end

	for k, n in next, op_uis do
		ui[n].click = function()
			select_op(k)
		end
	end

	ui.updateData = function(data)
		ui.param_data = data
		assert(data.Type == 'number' and data.Op and data.Value)

		ui.positive = not data.Value:find'^-'
		ui.percent = not not data.Value:find'%%$'
		ui.number = data.Value:sub(ui.positive and 1 or 2, ui.percent and -2 or -1)

		updateDisplay()
		select_op(data.Op)
	end

	ui.n_display.text = ''
end

blockchip.initParamDetail_Direction = function(self)
	local ui = self.ui.chip_params.detail.direction
	local CFG = CHIP_PARAM_CONFIG.direction

	local function select_dir()
		for i, cfg in ipairs(CFG) do
			local uidir = ui['n_' .. cfg.name]
			if uidir then
				uidir.icon._icon = ui.param_data.Value == cfg.name and 'img://chip_mbtn_sel.png' or 'img://chip_mbtn.png'
			end
		end
		self:updateParamNode()
	end

	for i, cfg in ipairs(CFG) do
		local uidir = ui['n_' .. cfg.name]
		if uidir then
			uidir.click = function()
				ui.param_data.Value = cfg.name
				select_dir()
			end
		end
	end

	ui.usecam.click = function()
		ui.param_data.Op = ui.param_data.Op == 'no_use' and '' or 'no_use'
	end

	ui.reset.click = function()
		CHIP_PARAM_CONFIG.direction.reset(ui.param_data)
		select_dir()
	end

	ui.updateData = function(data)
		ui.param_data = data
		ui.usecam.title.text = 'camera space'
		ui.usecam.loop.selected = ui.param_data.Op == ''
		assert(data.Type == 'direction' and data.Op and data.Value)
		select_dir()
	end
end

blockchip.initParamDetail_SetGet = function(self, set_or_get)
	print(set_or_get)
	self.cur_logic_names = {}
	local ui = self.ui.chip_params.detail[set_or_get]
	local name_uis = { ui.n1, ui.n2, ui.n3, ui.n4 }
	local names = {}

	local function updateSelectedNames()
		local v = names[1] or ''
		name_uis[1].icon._icon = v ~= '' and self.cur_logic_names[v].icon or ''
		
		for i = 2, 4 do
			local n = names[i]
			if n and n ~= '' then
				v = v .. '.' .. n
				name_uis[i].icon._icon = self.cur_logic_names[n].icon
			else
				name_uis[i].icon._icon = ''
			end
		end

		ui.param_data.Value = v
		self:updateParamNode()
		if self.rtdata.selected_chip.target then self:refreshMainChipList() end
	end

	local function add_name(name)
		if #names >= 4 then return end
		table.insert(names, name)
		updateSelectedNames()
	end

	local function del_name(index)
		for i = index, 4 do
			names[i] = nil
		end
		updateSelectedNames()
	end

	for i = 1, 4 do
		name_uis[i].title.text = ''
		select_btn(name_uis[i], true)

		name_uis[i].click = function()
			del_name(i)
		end
	end

	local function selectName()
		for i, u in ipairs(ui.names_uiitems) do
			u.selbg.visible = ui.param_data.Value == u.logic_name_data
		end
		self:updateParamNode()
	end
	
	local function updateNames()
		local ns = self.cur_logic_names
		if #ns == 0 then
			ns = _G.BLOCK_LOGIC_NAMES
		end

		ui.names_uiitems = {}
		ui.names.onRenderItem = function(index, item)
			local n = ns[index].type
			item.icon._icon = ns[index].icon
			item.click = function()
				if ui.chip_name == 'Action' or ui.chip_name == 'PFX' or ui.chip_name == 'SFX' then
					ui.param_data.Value = n
					selectName()
				else
					add_name(n)
				end
			end

			item.logic_name_data = n

			table.insert(ui.names_uiitems, item)
		end

		ui.names.itemNum = #ns
	end

	ui.scale.click = function() -- TODO : see BuildBrick.showXfXResList
		print('ui.scale')
	end

	ui.volume.onChanged = function()
		print('ui.volume', ui.volume.currentValue / 100)
	end

	ui.isloop.click = function()
		ui.param_data.Op = ui.param_data.Op == 'loop' and '' or 'loop'
		print('ui.param_data.Op', ui.param_data.Op)
	end

	ui.updateData = function(data)
		ui.param_data = data
		local chip_data = self.rtdata.selected_chip
		if chip_data.Name == 'Action' then
			ui.n1.visible = false
			ui.n2.visible = false
			ui.n3.visible = false
			ui.n4.visible = false
			ui.scale.visible = false
			ui.volume.visible = false
			ui.isloop.visible = true
		elseif chip_data.Name == 'PFX' then
			ui.n1.visible = false
			ui.n2.visible = false
			ui.n3.visible = false
			ui.n4.visible = false
			ui.scale.visible = true
			ui.volume.visible = false
			ui.isloop.visible = true
		elseif chip_data.Name == 'SFX' then
			ui.n1.visible = false
			ui.n2.visible = false
			ui.n3.visible = false
			ui.n4.visible = false
			ui.scale.visible = false
			ui.volume.visible = true
			ui.isloop.visible = true
		else
			ui.n1.visible = true
			ui.n2.visible = true
			ui.n3.visible = true
			ui.n4.visible = true
			ui.scale.visible = false
			ui.volume.visible = false
			ui.isloop.visible = false
		end

		ui.chip_name = chip_data.Name
		ui.isloop.loop.selected = ui.param_data.Op == 'loop'
		ui.volume.maxValue = 100
		ui.volume.currentValue = 100

		assert(data.Type == set_or_get and data.Op and data.Value)
		names = CHIP_PARAM_CONFIG.set.get_value(data)
		for i, v in ipairs(names) do
			names[i] = v ~= '' and v or nil
		end
		
		if ui.chip_name == 'Action' or ui.chip_name == 'PFX' or ui.chip_name == 'SFX' then
			updateNames()
			selectName()
		else
			if  data.Type == 'Gget' or data.Type == 'Gset' then
				self.cur_logic_names = _G.BLOCK_LOGIC_G_NAMES
			end
			updateNames()
			updateSelectedNames()
		end
	end
end

blockchip.initParamDetail_Enum = function(self)
	self.cur_logic_enums = {}

	local ui = self.ui.chip_params.detail.enum

	local op_uis = {
		Add = 'n_add', 
		Sub = 'n_sub', 
		Set = 'n_set',
	}

	local function select_op()
		for op, un in next, op_uis do
			select_btn(ui[un], ui.param_data.Op == op)
		end
		self:updateParamNode()
	end

	for op, un in next, op_uis do
		ui[un].click = function()
			ui.param_data.Op = op
			select_op()
		end
	end

	local function select_enum()
		for i, u in ipairs(ui.enums_uiitems) do
			select_btn(u.btn, ui.param_data.Value == u.btn.title.text)
		end
		self:updateParamNode()
	end
	
	local function update_enums()
		local es
		if self.rtdata.selected_chip_cfg.enums then
			es = self.rtdata.selected_chip_cfg.enums[self.rtdata.selected_param_index]
		end

		if not es then
			es = {
				'All', 'None', 'OneWay', 'Players', 'NoBlock'
			}
		end

		ui.enums_uiitems = {}
		ui.list.onRenderItem = function(index, item)
			local e = es[index]

			item.btn.title.text = e

			item.click = function()
				ui.param_data.Value = e
				select_enum()
			end

			table.insert(ui.enums_uiitems, item)
		end

		ui.list.itemNum = #es
	end

	ui.updateData = function(data)
		ui.param_data = data
		assert(data.Type == 'enum' and data.Op and data.Value)
		update_enums()
		select_op()
		select_enum()
	end
end

blockchip.initParamDetail_Formula = function(self)
	local ui = self.ui.chip_params.detail.formula

	local op_uis = {
		Add = 'n_add', 
		Sub = 'n_sub', 
		Mul = 'n_mul', 
		Div = 'n_div', 
		Set = 'n_set',
	}

	local function select_op()
		for op, n in next, op_uis do
			ui[n].icon._icon = ui.param_data.Op == op and 'img://chip_sbtn_sel.png' or 'img://chip_sbtn.png'
		end

		self:updateParamNode()
	end

	for k, n in next, op_uis do
		ui[n].click = function()
			ui.param_data.Op = k
			select_op()
		end
	end

	ui.updateData = function(data)
		ui.param_data = data
		assert(data.Type == 'formula' and data.Op and data.Value)
		select_op()
	end
end

blockchip.initParamDetail_Ms = function(self)
	local ui = self.ui.chip_params.detail.ms

	local textLenMax = 10
	ui.number = ''

	local function updateDisplay()
		local text = ui.number
		ui.n_display.text = text

		ui.param_data.Value = text

		self:updateParamNode()
	end

	for i = 0, 9 do
		ui["n_" .. i].click = function()
			if string.len(ui.number) >= textLenMax then	return end
			if ui.number == '0' then ui.number = '' end
			ui.number = ui.number .. i
			updateDisplay()
		end
	end

	ui.n_AC.click = function()
		ui.number = '0'
		updateDisplay()
	end

	ui.updateData = function(data)
		ui.param_data = data
		assert(data.Type == 'ms')
		ui.number = data.Value

		updateDisplay()
	end

	ui.n_display.text = ''
end

blockchip.initParamDetail_Time = function(self)
	local ui = self.ui.chip_params.detail.time

	local function init_nodes(u, begin_n, end_n)
		u.onRenderItem = function(index, item)
			local number = index - 1 + begin_n
			item.num.text = number < 10 and '0' or ''
			item.num.text = item.num.text .. number
		end
		u.itemNum = end_n - begin_n + 1
	end

	init_nodes(ui.h, 0, 23)
	init_nodes(ui.m, 0, 59)
	init_nodes(ui.s, 0, 59)

	local function select_time(h,m,s)

	end

	ui.updateData = function(data)
		ui.param_data = data
		assert(data.Type == 'time')
		self:updateParamNode()
	end
end

blockchip.initParamDetail_Func = function(self)
	local ui = self.ui.chip_params.detail.func

	local function select_func()
		for i, u in ipairs(ui.funcs_uiitems) do
			select_btn(u, ui.param_data.Value == u.desc.text)
		end

		self:updateParamNode()
	end
	
	local function update_funcs(fs)
		ui.funcs_uiitems = {}
		ui.list.onRenderItem = function(index, item)
			local f = fs[index].name

			item.desc.text = f

			item.click = function()
				if ui.param_data.Value == f then return end
				ui.param_data.Value = f
				select_func(f)
				_G.CHIP_PARAM_RULES.apply_funcs(ui.param_data)
				ui.param_data.expand = true
				self:refreshParamList()
			end

			table.insert(ui.funcs_uiitems, item)
		end

		ui.list.itemNum = #fs
	end

	update_funcs(_G.CHIP_PARAM_CONFIG.func)

	ui.updateData = function(data)
		ui.param_data = data
		assert(data.Type == 'func')
		select_func()
	end
end

blockchip.initParamDetail_Condition = function(self)
	local ui = self.ui.chip_params.detail.condition

	local uis = {}

	local function select_op()
		for i, u in ipairs(uis) do
			select_btn(u, ui.param_data.Op == u.title.text)
			u.icon._icon = ui.param_data.Op == u.title.text and 'img://chip_sbtn_sel.png' or 'img://chip_sbtn.png'
		end

		self:updateParamNode()
	end

	for i, cfg in ipairs(_G.CHIP_PARAM_CONFIG.condition) do
		local op = cfg.name
		uis[i] = ui['n_'..op]
		uis[i].title.text = op
		uis[i].click = function()
			ui.param_data.Op = op
			select_op()
		end
	end

	ui.updateData = function(data)
		ui.param_data = data
		assert(data.Type == 'condition')
		select_op()
	end
end

-- 'number', 'direction', 'enum', 'formula',
-- 'ms', 'time', 'func', 'condition', 'setget', 'nodes',

blockchip.refreshParamDetail = function(self)
	local data = self.rtdata.cur_chip_param_data
	local ui = self.ui.chip_params.detail
	for i, k in next, param_uis do if ui[k] then
		ui[k].visible = false
	end end
	if data and data.Type then
		ui[data.Type].visible = true
		ui[data.Type].updateData(data)
	elseif data ~= 'Add' then
		ui.nodes.visible = true
		self:refreshParamDetail_Nodes(data.options)
	else
		return
	end
end

blockchip.setLogicNames = function(self, names)
	self.cur_logic_names = names
end

Global.BlockChipUI = blockchip