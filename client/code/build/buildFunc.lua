local Container = _require('Container')
local command = _require('Pattern.Command')

local BuildFunc = {}
Global.BuildFunc = BuildFunc

Global.BlockFuncFlagIcon = {
	{name = 'blast', icon = 'star.png'},
	{name = 'movepfx', icon = 'star.png'},
}

BuildFunc.init = function(self, sen, shapeid)
	self.sen = sen
	self:clearSceneBlock()

	self.ui = Global.UI:new('BuildFunc.bytes')
	self.globalfuncflags = {}
	self.curmodule = nil

	self:initUI()
	self.downX, self.downY = 0, 0
	self:load(shapeid)

end

BuildFunc.load = function(self, id)
	if not id then return end
	self.globalfuncflags = {}
	self:clearSceneBlock()
	local data = Block.loadItemData(id)
	self:loadModulesFromData(data)

	-- 把shapeid和self.modules绑定起来
	self.shapeid = id
	Block.addDataCache(self.shapeid, self:getModule())
	self:loadSceneFromModule(self:getModule())

	if data and data.funcflags ~= nil then
		self.globalfuncflags = data.funcflags
	end

	self:updateGlobalFuncList()
end

BuildFunc.loadModulesFromData = function(self, data)
	if not data then
		data = {
			version = 1,
			scale = 1,
			blocks = {},
		}
	end

	self.modules = data
	self.modules.command = command.new()
	self.modules.sindex = 0
	if #self.modules.blocks == 0 then
		for i, v in ipairs(self.modules) do
			self.modules.blocks[i] = v
		end
	end

	-- for i = #self.modules.blocks, 1, -1 do
	-- 	if self.modules.blocks[i].need == false then
	-- 		table.remove(self.modules.blocks, i)
	-- 	end
	-- end

	if not self.modules.groups then
		self.modules.groups = {}
	end
	if not self.modules.parts then
		self.modules.parts = {}
	end
	if not self.modules.subs then
		self.modules.subs = {}
	end

	self.materials = data.materials or {{material = 1, color = 0xfffff1f1, roughness = 1, mtlmode = Global.MTLMODE.PAINT}}

	for subid, v in pairs(self.modules.subs) do
		v.sindex = subid
		if not v.groups then v.groups = {} end
		if not v.parts then v.parts = {} end
		v.command = command.new()
	end
end

BuildFunc.loadSceneFromModule = function(self, module)
	--加载block信息
	local bs = {}
	for i, v in ipairs(module.blocks) do
		local b = self.sen:createBlock(v)
		b.index = i
		if module.center then
			b.node.transform:mulTranslationRight(module.center.x, module.center.y, module.center.z)
			b:updateSpace()
		end

		if v.disablephyx then
			b:setPhyxCulliing(true)
		end

		-- 加载特效
		if v.pfxs then
			for _, vv in ipairs(v.pfxs) do
				local mat = _Matrix3D.new()
				mat:setScaling(vv.scale)
				mat:mulRotationRight(vv.rotation.x, vv.rotation.y, vv.rotation.z, vv.rotation.w)
				mat:mulTranslationRight(vv.translation)
				self:createPfxDummy(vv.pfxname, b, mat)
			end
		end

		table.insert(bs, b)
	end

	-- 第一次加载场景时模型放置在地面上
	if not module.center then
		local aabb = Container:get(_AxisAlignedBox)
		Block.getAABBs(bs, aabb)
		for i, b in ipairs(bs) do
			b.node.transform:mulTranslationRight(0, 0, -aabb.min.z)
			b:updateSpace()
		end
		Container:returnBack(aabb)
	end

	local gs = {}
	if self.enableGroup then
		gs = self:loadGroupInfos(module.groups, bs)
		if not self.enablePart then
			for i, g in ipairs(gs) do
				g.switchPart = nil
				g.switchName = nil
			end
		end
		self:loadOverlapInfo(bs, module.connects, module.overlaps, module.neighbors)
	end

	-- 初始化knotgroup
	for i, g in ipairs(gs) do
		g:getKnotGroup()
	end

	-- load part
	if self.enablePart and module.parts and next(module.parts) then
		self.parttype = module.parts.bindbone or 'human'
		self.disableBindPart = module.parts.disableBind

		if not next(self.parts) then self:initParts() end

		local data = Part.getPartData(self.parttype)

		local type1 = Global.dir2AxisType(Global.DIRECTION.LEFT, Global.AXISTYPE.Z)
		local type2 = Global.dir2AxisType(Global.DIRECTION.DOWN, Global.AXISTYPE.Z)
		local type3 = Global.dir2AxisType(Global.DIRECTION.RIGHT, Global.AXISTYPE.Z)
		local ns = {type1, type2, type3}

		local lookcenter = _Vector3.new(0, -3, 0)
		for i, pname in ipairs(data.orders) do
			local part = self.parts[pname]
			local p = module.parts[pname]
			if p then
				local group = gs[p.group]
				-- 增加绑定积木的初始位置，用于解绑时放置
				local nbs = {}
				group:getBlocks(nbs)
				self:findUncollidedPlace(nbs, ns, lookcenter)
			end
		end

		local v1 = Container:get(_Vector3)
		local v2 = Container:get(_Vector3)
		for i, pname in ipairs(data.orders) do
			local part = self.parts[pname]
			local p = module.parts[pname]
			if p then
				local group = gs[p.group]

				self:atom_part_bind(group, part)

				--移动transform
				_Vector3.add(p.partpos, module.center, v1)
				part.roottransform.ignoreParent = true
				part.roottransform:setTranslation(v1)
				part.roottransform.ignoreParent = false

				-- 移动jointnode.transform
				local gmat = part.jointnode.transform
				_Vector3.add(p.jointpos, module.center, v1)
				part.roottransform:getTranslation(v2)
				_Vector3.sub(v1, v2, v1)
				gmat.ignoreParent = true
				gmat:setTranslation(v1)
				gmat.ignoreParent = false

				if p.attachs then
					for i, gi in ipairs(p.attachs) do
						local g = gs[gi]
						self:attachPartGroup(part, g)
					end
				end
			end
		end

		Container:returnBack(v1, v2)

		--父矩阵更新时物理没有及时更新，这里重新更新一次
		for name, part in pairs(self.parts) do if part.group then
			local bs = {}
			part.group:getBlocks(bs, 'connect')
			for i, g in ipairs(part.attachs) do
				g:getBlocks(bs)
			end

			for i, b in ipairs(bs) do
				b.node.transform:mulTranslationRight(0, 0, 0)
			end
			part.jointnode.transform:mulTranslationRight(0, 0, 0)
			part.bonenode.transform:mulTranslationRight(0, 0, 0)
		end end

		self:editPart('exit')
	end

	-- 加载修复信息
	if self.enableRepair then
		self:initRepairData()

		if module.repair_version and module.repair_version > 0 then
			for i, v in ipairs(module.repair_adds or {}) do
				local g = gs[v.bindGroup]

				local addg = self:createAddRepair(g, v.trans)
				addg:setDirty()

				self:checkRepaired(addg, true)
			end

			self:markSameDelRepair(gs)
			for i, v in ipairs(module.repair_dels or {}) do
				local g = gs[v.index]
				self:setDelRepair(g, i)
			end
		else
			for i, v in ipairs(module.repair_adds or {}) do
				local b = self.sen:createBlock({shape = v.shape})
				b.node.transform:setRotation(v.rot)
				b.node.transform:mulTranslationRight(v.trans)
				b:updateSpace()
				local g = b:getBlockGroup()
				g:setDirty()
				self:setAddRepair(g)

				self:checkRepaired(g, true)
			end

			for i, v in ipairs(module.repair_dels or {}) do
				local b = bs[v.index]
				local g = b:getBlockGroup()
				self:setDelRepair(g, i)
			end
		end

		if self.mode == 'repair' and not next(self:getRepairShapeFilter()) then
			self.enableOpenLib = false
			--Tip(Global.TEXT.TIP_BUILDBRICK_FORBIDDENLIB)
			Tip()
		else
			self.enableOpenLib = true
			Tip(Global.TEXT.TIP_BUILDBRICK)
		end
	end

	-- self:showTopButtons()

	return bs, gs
end

BuildFunc.getBlocks = _G.BuildBrick.getBlocks
BuildFunc.atom_block_del_s = _G.BuildBrick.atom_block_del_s
BuildFunc.clearSceneBlock = function(self, keepicon)
	local nbs = {}
	self:getBlocks(nbs)
	self:atom_block_del_s(nbs)
end

BuildFunc.saveSceneToModule = function(self, module, nbs)
	if self.enablePart then
		-- 保存时退出动画编辑界面
		if self.showSkl then
			self:showPart(self.parttype, false)
		end

		self:playAnimIndex(nil, false)
		self:editPart('exit')
	end

	if not nbs then
		nbs = {}
		if not self.enableRepair then
			self:getBlocks(nbs)
		else
			self:getBlocks(nbs, function(b)
				return not self:isAddRepairBlock(b)
			end)
		end
	end

	--local sindex = module.sindex
	table.clear(module.blocks)
	table.clear(module.groups)
	table.clear(module.parts)
	--module.sindex = sindex

	local aabb = Container:get(_AxisAlignedBox)
	Block.getAABBs(nbs, aabb)

	if not module.center then
		module.center = _Vector3.new()
	end

	local bindpart = false
	if self.enablePart then
		for name, part in pairs(self.parts) do
			if part.group then
				bindpart = true
				break
			end
		end
	end

	if not self.hideTerrain then
		if bindpart then
			local vnbs = {}
			for i, b in ipairs(nbs) do
				if b.part or b.part2 then
					table.insert(vnbs, b)
				end
			end
			Block.getAABBs(vnbs, aabb)
		end

		aabb:getCenter(module.center)
		Global.normalizePos(module.center, Global.MOVESTEP.TILE)
		--保存物件贴地表
		--module.center.z = module.center.z + 0.2
	else
		module.center:set(0, 0, 0)
	end

	if not module.size then
		module.size = _Vector3.new()
	end
	aabb:getSize(module.size)

	-- 处理特效
	-- local pfxnbs = {}
	-- self:getBlocks(pfxnbs, function(b)
	-- 	return b.isdummyblock
	-- end)

	-- 添加block信息
	for i, b in ipairs(nbs) do if not b:isDummy() then
		b.index = i

		-- 保存block的原始颜色信息
		local needrepair = b.needrepair
		if self.enableRepair and needrepair then
			b:setNeedRepair(false)
		end

		--未绑定的积木加了need=false标记
		if bindpart then
			if not b.part and not b.part2 then
				b.node.need = false
			end
		end

		local data = Global.saveBlockData(b, module.center)
		table.insert(module.blocks, data)

		if bindpart then
			if not b.part and not b.part2 then
				b.node.need = nil
			end
		end

		if self.enableRepair and needrepair then
			b:setNeedRepair(true)
		end
	end end

	if self.enableGroup then
		local gs = {}
		self:getGroups(gs, nbs)
		self:saveGroupInfos(gs, module.groups)

		-- 保存overlaps信息
		module.connects = {}
		module.overlaps = {}
		module.neighbors = {}
		self:saveOverlapInfo(nbs, module.connects, module.overlaps, module.neighbors)
	end

	-- 保存flag信息
	module.funcflags = {}
	module.funcflags = self.globalfuncflags

	module.parts = {}
	if self.enablePart then
		-- Write parts
		local bindbone = false
		local rootz = 0

		for name, part in pairs(self.parts) do if part.group then
			if part.group.index then
				local ppart = part.ppart
				local pgroup = ppart and ppart.group

				local data = Part.getPartData(self.parttype)
				local cpart = data.parts[name]
				local isroot = cpart.parent == nil

				-- partpos记录part移动的差值, 
				local partpos = _Vector3.new()
				part.roottransform.ignoreParent = true
				part.roottransform:getTranslation(partpos)
				part.roottransform.ignoreParent = false
				_Vector3.sub(partpos, module.center, partpos)

				-- jointpos记录joint的最终值
				local jointpos = _Vector3.new()
				part.jointnode.transform:getTranslation(jointpos)
				-- 记录root点离地面的高度，用于处理跳跃等动画时的高度
				if isroot then rootz = math.max(jointpos.z - self:getRootZ_MinZ(), 0) end
				_Vector3.sub(jointpos, module.center, jointpos)

				local pdata = {group = part.group.index, pgroup = pgroup and pgroup.index, jointpos = jointpos, partpos = partpos, attachs = {}}
				for i, g in ipairs(part.attachs) do
					if g.index then
						table.insert(pdata.attachs, g.index)
					end
				end

				module.parts[name] = pdata

				bindbone = true
			else
				print('ERROR part has invalid group', name, part.group)
				assert(false)
			end
		end end
		if bindbone then
			module.parts.bindbone = self.parttype
			module.parts.rootz = rootz
			module.parts.disableBind = self.disableBindPart
		end
	end

	-- 保存修复信息
	module.repair_dels = {}
	module.repair_adds = {}
	Container:returnBack(aabb)

	-- 清除模型缓存
	Block.clearCaches(self.shapeid)
	print('Block.clearCaches: ', self.shapeid)
end

BuildFunc.onDestory = function(self)
end

BuildFunc.initUI = function(self)
	local list = self.ui.funclist

	self.funcitems = {}
	list.onRenderItem = function(index, item)
		local name = Global.BlockFuncFlagIcon[index].name
		item.pic._icon = 'img://' .. Global.BlockFuncFlagIcon[index].icon
		table.insert(self.funcitems, item)

		item.click = function()
			self.globalfuncflags[name] = item.selected
		end
	end

	list.itemNum = #Global.BlockFuncFlagIcon
end

BuildFunc.updateGlobalFuncList = function(self)
	if not self.funcitems or #self.funcitems == 0 then return end
	for i, item in pairs(self.funcitems) do
		local name = Global.BlockFuncFlagIcon[i].name
		local enable = self.globalfuncflags[name]
		item.selected = enable or false
	end
end

BuildFunc.save = function(self, browsertype, nbs, isauto)
	print('BuildBrick.save', self.shapeid, self.istemplate, browsertype)
	-- 先保存当前场景 再判断
	self:saveSceneToModule(self.modules, nbs)

	local o = Global.getObjectByName(self.shapeid)
	local isnew = self.istemplate
	if o then
		isnew = true
	end

	-- 如果是空，做删除
	if #self.modules.blocks == 0 and next(self.modules.subs) == nil then
		if isnew then
		elseif o then
			Global.ObjectManager:DeleteObject(o)
		end
	else
		self:uploadObject(isnew, browsertype, isauto)
	end

	if browsertype == 'Dress' or browsertype == 'Back' or browsertype == 'Browser' then
		self:goBack(browsertype, Global.getObjectByName(self.shapeid))
	end
end

BuildFunc.saveToFile = function(self, filename)
	local str = Global.saveBlock2String(self.modules, self.materials)
	_File.writeString(filename, str, 'utf-8')
end

local font = _Font.new('黑体', 20)
BuildFunc.render = function(self)
	font:drawText(10, 0, '形状id:' .. (self.shapeid or 0))
end

local kevents = {
	{
		-- 打开物品，并拆分未积木块
		k = _System.KeyO,
		func = function()
			if _sys:isKeyDown(_System.KeyCtrl) then
				local filename = _sys:openFile('*.itemlv', '*.lv')
				local ext = _sys:getExtention(filename)
				if ext == 'itemlv' then
					local shapeid = _sys:getFileName(filename, false, false)
					BuildFunc:load(shapeid)
				end
			end
		end
	},
	{
		--保存
		k = _System.KeyS,
		func = function()
			if ENABLE_KEY and _sys:isKeyDown(_System.KeyCtrl) and not _sys:isKeyDown(_System.KeyShift) then
				local savename = _sys:saveFile('.itemlv')
				if _sys:getExtention(savename) ~= 'itemlv' then savename = savename .. '.itemlv' end
				local openfilename = _sys:getFileName(savename)
				if not openfilename or openfilename == '' then return end

				print('保存', table.ftoString(BuildFunc.globalfuncflags))
				-- 先保存当前场景
				BuildFunc:saveSceneToModule(BuildFunc.modules)
				BuildFunc:saveToFile(openfilename)
				local itemid = _sys:getFileName(openfilename, false, false)
				Global.Capture:addNode(itemid, nil, nil, nil, nil, nil, nil, nil, true)
			end
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

Global.GameState:setupCallback({
	addKeyDownEvents = kevents,
	onDown = function(b, x, y)
		-- BuildFunc:onDown(b, x, y)
	end,
	onMove = function(x, y, fid, count)
		-- BuildFunc:onMove(x, y)
	end,
	onUp = function(b, x, y)
		-- if _sys.os == 'win32' or _sys.os == 'mac' then
		-- 	BuildFunc:onUp(b, x, y)
		-- else
		-- 	if _tick() - clicktick < 200 then
		-- 		BuildFunc:onDClick(x, y)
		-- 	else
		-- 		BuildFunc:onClick(x, y)
		-- 	end
		-- 	clicktick = _tick()
		-- 	BuildFunc:onUp(0, x, y)
		-- end
	end,
	onClick = function(x, y)
		-- if _sys.os == 'win32' or _sys.os == 'mac' then
		-- 	if _tick() - clicktick < 200 then
		-- 		BuildFunc:onDClick(x, y)
		-- 	else
		-- 		BuildFunc:onClick(x, y)
		-- 	end
		-- 	clicktick = _tick()
		-- 	BuildFunc:onUp(0, x, y)
		-- end
	end,
	cameraControl = cameracontrol
}, 'BUILDFUNC')

Global.GameState:onEnter(function(...)
	_app:registerUpdate(Global.BuildFunc, 7)
	local c = Global.CameraControl:get()
	c:scale(4)
	c:moveDirV(0.5)
	c:use()
	Global.BuildFunc:init(Global.sen, ...)
end, 'BUILDFUNC')

Global.GameState:onLeave(function()
	BuildFunc:onDestory()
	_app:unregisterUpdate(Global.BuildFunc)
end, 'BUILDFUNC')