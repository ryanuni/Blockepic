local Container = _require('Container')
local command = _require('Pattern.Command')

local BuildHouse = Global.BuildHouse

BuildHouse.getModule = function(self, subid)
	if subid == 0 then
		return self.modules
	else
		return self.modules.subs[subid]
	end
end

BuildHouse.loadModulesFromData = function(self, data)
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

	-- if not self.modules.subs then
	-- 	self.modules.subs = {}
	-- end

	self.modules.subs = {}
	self.modules.groups = {}

	self.materials = data.materials or {{material = 1, color = 0xfffff1f1, roughness = 1, mtlmode = Global.MTLMODE.PAINT}}

	for subid, v in pairs(self.modules.subs) do
		v.sindex = subid
		v.command = command.new()
	end
end

BuildHouse.createModule = function(self)
	-- 分配标志符
	self.sindex = self.sindex + 1
	local module = {}
	module.command = command.new()
	module.sindex = self.sindex
	module.blocks = {}

	self.modules.subs[module.sindex] = module
	return module
end

BuildHouse.saveSceneToModule = function(self, module, nbs)
	if not nbs then
		nbs = {}
		self:getBlocks(nbs)
	end

	table.clear(module.blocks)
	local aabb = Container:get(_AxisAlignedBox)
	Block.getAABBs(nbs, aabb)

	if not module.center then
		module.center = _Vector3.new()
	end
	aabb:getCenter(module.center)

	if not module.size then
		module.size = _Vector3.new()
	end
	aabb:getSize(module.size)

	-- 添加block信息
	for i, b in ipairs(nbs) do if not b:isDummy() then
		local add = not b.isblocking2
		if Global.Achievement:check('goouthouse') == false and b.data.shape == 'work' and add == false then
			b.data.space = {
				scale = _Vector3.new(1.000000,1.000000,1.000000),
				rotation = _Vector4.new(0.000000,0.000000,1.000000,0.000000),
				translation = _Vector3.new(1.680001,0.300000,1.120000),
			}
			b:resetSpace()
			add = true
		end
		if add then
			b.index = i

			local data = Global.saveBlockData(b, module.center)
			table.insert(module.blocks, data)
		end
	end end

	Container:returnBack(aabb)

	-- 清除模型缓存
	Block.clearCaches(self.shapeid)
	print('Block.clearCaches: ', self.shapeid)
end

-- 把模块的每一个单元加入场景
Global.loadBlocksFromHouse = function(module, sen)
	sen = sen or Global.sen
	--加载block信息
	local bs = {}
	for i, v in ipairs(module.blocks) do
		local b = sen:createBlock(v)

		-- 房子的墙设置特殊的pickflag
		if Global.HouseBases[v.shape] or Global.HouseWalls[v.shape] or Global.HouseFloors[v.shape] then
			b:setPickFlag(Global.CONSTPICKFLAG.TERRAIN)
		end

		if module.center then
			b.node.transform:mulTranslationRight(module.center.x, module.center.y, module.center.z)
			-- 处理房间位置错位问题
			-- if Global.HouseBases[v.shape] then
			-- 	b.node.transform:setTranslation(0, -3.8, 0)
			-- end
			b:updateSpace()
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

	return bs
end

BuildHouse.loadSceneFromModule = function(self, module)
	local bs = Global.loadBlocksFromHouse(module)
	for i, b in ipairs(bs) do
		local shape = b:getShape()
		if Global.HouseBases[shape] then
			b:getShapeAABB(self.wallab)

			-- 设置内墙的的包围盒
			self.innerWallab:set(self.wallab)
			local min, max = self.innerWallab.min, self.innerWallab.max
			local thick = Global.WallThickness[shape]
			max.x = max.x - thick[1]
			max.y = max.y - thick[2]
			max.z = max.z - thick[3]
			min.x = min.x + thick[4]
			min.y = min.y + thick[5]
			min.z = min.z + thick[6]

			-- 稍微缩小一些
			local s = 0.1
			self.wallab.min.x = self.wallab.min.x + s
			self.wallab.min.y = self.wallab.min.y + s
			self.wallab.min.z = self.wallab.min.z + s
			self.wallab.max.x = self.wallab.max.x - s
			self.wallab.max.y = self.wallab.max.y - s
			self.wallab.max.z = self.wallab.max.z - s
			break
		end
	end

	self:checkBlocking()
end

BuildHouse.setModule = function(self, module)
	--保存之前的brick
	if self.curmodule then
		self:saveSceneToModule(self.curmodule)
		-- TODO[module undo]不用清
		self:clearCommand()
		self:clearSceneBlock(true)
	end

	self:loadSceneFromModule(module)
	self.curmodule = module
	-- TODO[module undo],切换rtdata
	self:atom_init_rt()
	self:ui_flush_undo()
end