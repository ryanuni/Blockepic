local Container = _require('Container')
_require('ExtendFile')
_require('ExtendTable')
_require('SceneRDSetting')
_sys.enableOldShadow = true
_rd.enableShadowProjection = false
_rd.shadowNormalBias = 0.005
-- 正面生成shadowmap
_rd.oldShadowBackFace = true

-- 开启近平面视锥裁剪生成shadowmap，默认近平面depth = 0
_rd.shadowMapFrustumClip = false
_rd.shadowMapClipZ = -1.0

_rd.oldShadowLength = 200
_rd.oldShadowBias = 0.0001

if _sys.os == 'win32' or _sys.os == 'mac' then
	_rd.shadowMapSize = 4096
else
	_rd.shadowMapSize = 2048
end

_rd.lodDistance = 10
_rd.edgeBias = 0.0
_rd.usePostEdge = true

-- _rd.shadowCaster = true
-- _rd.shadowReceiver = true
local block = _dofile('block.lua')
local group = _dofile('group.lua')
local blockui = _dofile('blockui.lua')

Global.HomeTmpCache = nil
Global.LobbyTmpCache = nil
Global.lobbyExitPos = _Vector3.new(3.06, -22.32, 2.86)

local Scene = {}

Global.Scene = Scene
_dofile('scene_utils.lua')
-- 基础操作 --------------------------------
Scene.createBlockByCell = function(self, data)
	local blocks = {}
	if type(data.shape) == 'number' then
		local b = self:createBlock(data)
		table.insert(blocks, b)
	else
		local mat = Container:get(_Matrix3D)
		if data.space then
			mat:loadFromSpace(data.space)
		end

		local bdata = Block.loadItemData(data.shape)
		for i, v in ipairs(bdata.blocks or {}) do
			local bs = self:createBlockByCell(v)
			for p, q in ipairs(bs) do
				if data.space then
					q.node.transform:mulRight(mat)
				end
				table.insert(blocks, q)
			end
		end
		Container:returnBack(mat)
	end
	return blocks
end

Scene.createSubBlocks = function(self, data)
	print('createSubBlocks', data.shape)
	local blocks = {}
	if type(data.shape) == 'number' then
		local b = self:createBlock(data)
		table.insert(blocks, b)
	else
		local mat = Container:get(_Matrix3D)
		if data.space then
			mat:loadFromSpace(data.space)
		end

		local bdata = Block.loadItemData(data.shape)
		print('bdata.blocks', #bdata.blocks)
		for i, v in ipairs(bdata.blocks or {}) do
			print('v.shape', v.shape)
			local b = self:createBlock(v)
			if data.space then
				b.node.transform:mulRight(mat)
			end
			table.insert(blocks, b)
			-- for p, q in ipairs(bs) do
			-- 	if data.space then
			-- 		q.node.transform:mulRight(mat)
			-- 	end
			-- 	table.insert(blocks, q)
			-- end
		end
		Container:returnBack(mat)
	end
	return blocks
end

Scene.createBlock = function(self, data)
	local node = self:add()
	-- node.isShadowReceiver = true
	local actor = self:addActor()
	local b = block.new(node, actor, data and data.shape or 1, data, self.enableDelayLoad)
	self:addBlock(b)

	return b
end
Scene.addBlock = function(self, b)
	if self:indexBlock(b) == -1 then
		table.insert(self.blocks, b)
	end
end
Scene.addBlockUndo = function(self, b)
	local node = self:add()
	local actor = self:addActor()
	b:initNodeActor(node, actor)
	self:addBlock(b)
end
Scene.delBlock = function(self, b)
	b:stopBindPfx()
	b:stopAnim()
	b:clearOverlaps()
	b:clearNeighbors()
	b:clearConnects()
	b:resetKnots()
	b:setMovement()

	self:delActor(b.actor)
	self:del(b.node)

	self:removeFromGroup(b)
	table.remove(self.blocks, self:indexBlock(b))
end
Scene.indexBlock = function(self, b)
	for i, v in ipairs(self.blocks) do
		if v == b then
			return i
		end
	end
	return -1
end
Scene.getBlockByName = function(self, name)
	for i, v in ipairs(self.blocks) do
		if v.name == name then
			return v
		end
	end
end
Scene.getBlockByShape = function(self, shape)
	for i, v in ipairs(self.blocks) do
		if v.data.shape == shape then
			return v
		end
	end
end

Scene.getBlocksByFilter = function(self, nbs, f)
	for i, b in ipairs(self.blocks) do
		if not f or f(b) then
			table.insert(nbs, b)
		end
	end
end

--结果依赖与最近pick的结果
Scene.getPickedBlocks = function(self, nbs, f)
	local nodes = {}
	Global.sen:getPickedNodes(nodes)
	for i, v in ipairs(nodes) do
		if v.block then
			if not f or f(v.block) then
				table.insert(nbs, v.block)
			end
		end
	end
end

Scene.cloneBlock = function(self, b)
	self:syncIndex()
	local nb = self:createBlock(_dostring('return ' .. b:tostring()))
	nb:loadActionFunctions(self)
	return nb
end

Scene.cloneBlock2 = function(self, b)
	self:syncIndex()
	local nb = self:createBlock(_dostring('return ' .. Global.writeBlockString(b, Global.AXIS.ZERO, true)))
	nb:loadActionFunctions(self)
	return nb
end
Scene.removeFromGroup = function(self, b)
	for i, v in pairs(self.groups) do
		v:delBlock(b, true)
	end
end
Scene.syncIndex = function(self)
	for i, v in ipairs(self.blocks) do
		if not v:isDummy() then
			v.index = i
			for p, q in ipairs(v.functions) do
				q.index = p
			end
		end
	end
	for i, v in ipairs(self.groups) do
		v.index = i
		for p, q in ipairs(v.functions) do
			q.index = p
		end
	end
	for i, v in ipairs(self.blockuis) do
		v.index = i
		for p, q in ipairs(v.functions) do
			q.index = p
		end
	end
end
Scene.saveLevelToObject = function(self, n)
	self:syncIndex()
	n = n or self.name .. 'itemlv'
	local data = 'return {\n'
	data = data .. '\tversion = 1,\n'
	data = data .. '\tscale = 1,\n'
	data = data .. '\tcenter = _Vector3.new(0, 0, 0),\n'
	data = data .. '\tmaterials = {},\n'

	data = data .. '\tblocks = {\n'
	for i, v in ipairs(self.blocks) do if not v:isDummy() then
		data = data .. v:tostringForObject('\t\t') .. ',\n'
	end end
	data = data .. '\t},\n'
	data = data .. '\tgroups = {},\n'
	data = data .. '}'

	_File.writeString(n, data, 'utf-8')
end

Scene.saveLevel2String = function(self)
	self:syncIndex()
	local data = 'return {\n'
	data = data .. '\tblocks = {\n'
	for i, v in ipairs(self.blocks) do if not v:isDummy() then
		v:updateSpace()
		data = data .. v:tostring('\t\t') .. ',\n'
	end end
	data = data .. '\t},\n'
	data = data .. '\tgroups = {\n'
	for i, v in pairs(self.groups) do
		data = data .. v:tostring('\t\t') .. ',\n'
	end
	data = data .. '\t},\n'
	data = data .. '\tblockuis = {\n'
	for i, v in pairs(self.blockuis) do
		data = data .. v:tostring('\t\t') .. ',\n'
	end
	data = data .. '\t},\n'
	data = data .. '\tsetting = {\n'
	data = data .. '\t\tneedrole = ' .. tostring(self.setting.needrole) .. ',\n'
	data = data .. '\t\tneedrolecct = ' .. tostring(self.setting.needrolecct) .. ',\n'
	data = data .. '\t\tspecialtype = \'' .. self.setting.specialtype .. '\',\n'
	data = data .. '\t\tcamfollowrole = ' .. tostring(self.setting.camfollowrole) .. ',\n'
	data = data .. '\t\tscreenmode = ' .. self.setting.screenmode .. ',\n'
	data = data .. '\t\tneedrefresh = ' .. tostring(self.setting.needrefresh) .. ',\n'
	data = data .. '\t},\n'
	data = data .. '}'

	return data
end

Scene.saveLevel = function(self, n)
	local data = self:saveLevel2String()
	n = n or self.name .. 'lv'
	_File.writeString(n, data, 'utf-8')
end

Scene.getLevelData = function(self, n)
	n = n or self.name .. 'lv'

	local data
	if n == 'lv' then
		data = {}
	else
		n = _sys:getFileName(n, true, false)
		if _sys.os == 'win32' or _sys.os == 'mac' then
			if _sys:fileExist(n) then
				data = _dofile(n)
			else
				data = {}
			end
		else
			data = _dofile(n) or {}
		end
	end
	return data
end

Scene.loadLevelData = function(self, data)
	local loadingblocks = {}
	for i, v in ipairs(data.blocks or {}) do
		local b = self:createBlock(v)
		if b.needLoad then
			table.insert(loadingblocks, b)
		end
	end
	self.loadingblocks = loadingblocks

	for i, v in ipairs(data.groups or {}) do
		self:createGroup(v)
	end
	for i, v in ipairs(data.blockuis or {}) do
		self:createBlockUI(v)
	end

	local default = {needrole = true, needrolecct = true, specialtype = 'parkour', camfollowrole = true, screenmode = 2, needrefresh = true}
	self.setting = data.setting or {}
	for i, v in pairs(default) do
		if self.setting[i] == nil then
			self.setting[i] = v
		end
	end
end

Scene.loadBlockslData = function(self, shape)
	self:createBlockByCell({shape = shape}) -- object.name
	-- local hdata = Block.getHelperData(id)
	-- if not hdata then
	-- 	hdata = Block.loadHelperData(id, nil, data)
	-- end
end

Scene.refreshLevel = function(self)
	for i = #self.blocks, 1, -1 do
		self.blocks[i]:refresh()
	end
	for i = #self.groups, 1, -1 do
		self.groups[i]:refresh()
	end
end
local result = {}
Scene.pickBlock = function(self, x, y)
	self:pick(_rd:buildRay(x, y), Global.CONSTPICKFLAG.NORMALBLOCK + Global.CONSTPICKFLAG.SELECTBLOCK, result)
	local b = result.node and result.node.block

	return b
end
Scene.pickNode = function(self, x, y, flag)
	self:pick(_rd:buildRay(x, y), flag, result)

	return result.node
end
Scene.getBlock = function(self, id)
	return self.blocks[id]
end
Scene.getAllBlocks = function(self)
	return self.blocks
end
Scene.getBlockCount = function(self)
	return #self:getAllBlocks()
end
Scene.delAllBlocks = function(self)
	local bs = self:getAllBlocks()
	for i = #bs, 1, -1 do
		self:delBlock(bs[i])
	end
end
Scene.getRenderingBlocks = function(self)
	return self.renderingBlocks
end
Scene.getRenderingBlocksHash = function(self)
	return self.renderingBlocksHash
end
Scene.addRenderingBlock = function(self, b)
	table.insert(self.renderingBlocks, b)
	self.renderingBlocksHash[b] = true
end
Scene.clearRenderingBlocks = function(self)
	self.renderingBlocks = {}
	self.renderingBlocksHash = {}
end
Scene.createGroup = function(self, data)
	local g = group.new(self, data)
	self:addGroup(g)
	return g
end
Scene.addGroup = function(self, g)
	if self:indexGroup(g) == -1 then
		g:setNeedUpdateBoundBox()
		table.insert(self.groups, g)
	end
end
Scene.delGroup = function(self, g)
	if not g then return end

	g:clearSelectedEffect()
	g:setNeedUpdateBoundBox()
	table.remove(self.groups, self:indexGroup(g))
end
Scene.indexGroup = function(self, g)
	for i, v in pairs(self.groups) do
		if v == g then
			return i
		end
	end
	return -1
end
Scene.getGroupByName = function(self, name)
	for i, v in pairs(self.groups) do
		if v.blocks[1].name == name then
			return v
		end
	end
end
Scene.getGroup = function(self, id)
	return self.groups[id]
end

Scene.getGroups = function(self)
	return self.groups
end

Scene.getObjectByIndexInfo = function(self, info)
	if info == nil then return end

	if info.groupid and info.groupid ~= -1 then
		return self:getGroup(info.groupid)
	elseif info.blockid and info.blockid ~= -1 then
		return self:getBlock(info.blockid)
	elseif info.blockuiid and info.blockuiid ~= -1 then
		return self:getBlockUI(info.blockuiid)
	end
end

local comparegroupfunc = function(a, b)
	return a < b
end

-- To be optimized.
Scene.searchGroupByBlocks = function(self, bs)
	if #bs == 0 then return nil end

	for i, b in ipairs(bs) do
		b.tempselected = true
	end

	local result = nil

	for i, v in pairs(self.groups) do
		if #v.blocks == #bs then
			local issame = true
			result = v
			for p, q in ipairs(v.blocks) do
				if q.tempselected ~= true then
					issame = false
					result = nil
					break
				end
			end
			if result then
				break
			end
		end
	end

	for i, b in ipairs(bs) do
		b.tempselected = false
	end

	return result
end

-- To be optimized.
Scene.searchGroupsByBlocks = function(self, bs)
	for _, b in next, bs do
		b.tempselected = true
	end
	local groups = {}
	for i, v in pairs(self.groups) do
		local isin = #v.blocks > 0 and true or false
		for p, q in ipairs(v.blocks) do
			if q.tempselected ~= true then
				isin = false
				break
			end
		end
		if isin then
			table.insert(groups, v)
		end
	end
	for _, b in next, bs do
		b.tempselected = nil
	end
	return groups
end
---------------------------------------------

Scene.createBlockUI = function(self, data)
	local u = blockui.new(data)
	self:addBlockUI(u)
	return u
end

Scene.addBlockUI = function(self, u)
	if self:indexBlockUI(u) == -1 then
		if u.widget == nil then
			u:createWidget()
		end
		table.insert(self.blockuis, u)
	end
end
Scene.delBlockUI = function(self, u)
	table.remove(self.blockuis, self:indexBlockUI(u))
	u:removeWidget()
end
Scene.indexBlockUI = function(self, u)
	for i, v in ipairs(self.blockuis) do
		if v == u then
			return i
		end
	end
	return -1
end
Scene.getBlockUIByName = function(self, name)
	for i, v in ipairs(self.blockuis) do
		if v.name == name then
			return v
		end
	end
end
Scene.cloneBlockUI = function(self, u)
	self:syncIndex()
	local nu = self:createBlockUI(_dostring('return ' .. u:tostring()))
	nu:loadActionFunctions(self)
	return nu
end

Scene.getBlockUI = function(self, id)
	return self.blockuis[id]
end
Scene.getAllBlockUIs = function(self)
	return self.blockuis
end
Scene.delAllBlockUIs = function(self)
	for i = #self.blockuis, 1, -1 do
		self:delBlockUI(self.blockuis[i])
	end
end

Scene.updateBlockUIs = function(self, e)
	for i, v in ipairs(self.blockuis) do
		v:update(e)
	end
end

Scene.setUIMode = function(self, mode)
	for i, v in ipairs(self.blockuis) do
		v:setMode(mode)
	end
end

---------------------------------------------
-- TODO:
Scene.getSubGroup = function(self, index)
	if not self.subgroup then self.subgroup = {} end
	if not self.subgroup[index] then
		self.subgroup[index] = group.new(self, {blocks = {index}})
	end

	return self.subgroup[index]
end

Scene.createDynamicEffects = function(self, df)
	if not df then return end
	self.playingDf = DynamicEffect.new(df, self)
	self.playingDf:setSpeed(self.dynamicEffectSpeed or 1)
end

Scene.setDynamicEffectSpeed = function(self, speed)
	self.dynamicEffectSpeed = speed or 1
	if self.playingDf then
		self.playingDf:setSpeed(self.dynamicEffectSpeed or 1)
	end
end

Scene.playDynamicEffect = function(self)
	if self.playingDf then
		self.playingDf:play()
		self.playingDf:setSpeed(self.dynamicEffectSpeed or 1)
	end
end

Scene.stopDynamicEffect = function(self, stopuntilend)
	if not self.playingDf then return end

	self.playingDf:stop(stopuntilend)
end

---------------------------------------------
Scene.createWall = function(self)
	if _G.load_dungeon then return end

	if self.wallActors then
		for _, a in next, self.wallActors do
			self:delActor(a)
		end
	end

	self.wallActors = {}

	-- self.walls = {}
	local x = self.terrain.tileX * self.terrain.tileSize * 0.5
	local y = self.terrain.tileY * self.terrain.tileSize * 0.5
	local s = 0.5
	local z = 500

	-- floor
	local a = self:addActor()
	a.transform:setTranslation(0, 0, -s)
	local shape = a:addShape(_PhysicsShape.Cube)
	shape.size = _Vector3.new(x, y, s)

	shape.queryFlag = Global.CONSTPICKFLAG.TERRAIN
	table.insert(self.wallActors, a)

	-- wall
	local a = self:addActor()
	a.transform:setTranslation(-x, 0, z)
	local shape = a:addShape(_PhysicsShape.Cube)
	shape.size = _Vector3.new(s, y, z)
	shape.queryFlag = Global.CONSTPICKFLAG.WALL
	table.insert(self.wallActors, a)

	local a = self:addActor()
	a.transform:setTranslation(x, 0, z)
	local shape = a:addShape(_PhysicsShape.Cube)
	shape.size = _Vector3.new(s, y, z)
	shape.queryFlag = Global.CONSTPICKFLAG.WALL
	table.insert(self.wallActors, a)

	local a = self:addActor()
	a.transform:setTranslation(0, -y, z)
	local shape = a:addShape(_PhysicsShape.Cube)
	shape.size = _Vector3.new(x, s, z)
	shape.queryFlag = Global.CONSTPICKFLAG.WALL
	table.insert(self.wallActors, a)

	local a = self:addActor()
	a.transform:setTranslation(0, y, z)
	local shape = a:addShape(_PhysicsShape.Cube)
	shape.size = _Vector3.new(x, s, z)
	shape.queryFlag = Global.CONSTPICKFLAG.WALL
	table.insert(self.wallActors, a)
end

Scene.renderSkybox = function(self)
	for i, v in ipairs(self.waters) do
		if v:reflectionBegin() then
			self.skyBox.mesh:drawMesh()
			v:reflectionEnd()
		end
	end
end

Scene.isDungeon = function(self)
	local sen = Global.findSenName(self.resname)
	return not (sen == 'home' or sen == 'lobby' or sen == 'guide')
end

Scene.isGuide = function(self)
	return Global.findSenName(self.resname) == 'guide'
end

Scene.isHome = function(self)
	return Global.findSenName(self.resname) == 'home'
end

Scene.isHouse = function(self)
	return Global.findSenName(self.resname) == 'house1'
end

Scene.isLobby = function(self)
	return Global.findSenName(self.resname) == 'lobby'
end

local clipper = _Clipper.new()

_G.resetSceneConfig = function(sen)
	if not sen then return end
	sen:useRDSetting()
	sen.gravity = _Vector3.new(0.0, 0.0, -9.8)
	-- _rd.shadowLight = _Vector3.new(0.001, 0.001, -1.0)

	_rd.postProcess.lightShaft = true
	if _sys.os == 'win32' or _sys.os == 'mac' then
		_rd.postProcess.ssao = true
		_rd.postProcess.fxaa = true
	else
		if Version:isAlpha1() then
			_rd.postProcess.ssao = false
			_rd.postProcess.fxaa = false
		end
	end
end

_G.CreateSceneWithBlocks = function(n)
	local sen = _Scene.new(n)
	sen.backupGraData = sen.graData:clone()
	sen.dimianpfx = sen.pfxPlayer:play('dimianwangge', 'dimianwangge.pfx')
	sen.dimianpfx.transform:mulTranslationRight(0, 0, -0.6)
	sen.dimianpfx.visible = false

	if sen.terrain == nil then
		sen.terrain = _Terrain.new(10, 10, 10, 200, 32)
		local x = -((sen.terrain.tileX - 1) * sen.terrain.tileSize) / 2
		local y = ((sen.terrain.tileY - 1) * sen.terrain.tileSize) / 2
		local edgeX = sen.terrain.tileX * sen.terrain.tileSize / 2
		local edgeY = -sen.terrain.tileY * sen.terrain.tileSize / 2
		while x < edgeX do
			y = ((sen.terrain.tileY - 1) * sen.terrain.tileSize) / 2
			while y > edgeY do
				sen.terrain:showTile(x, y, false)
				y = y - sen.terrain.tileSize
			end
			x = x + sen.terrain.tileSize
		end

		-- local ambientLight = _AmbientLight.new()
		-- ambientLight.name = 'ambient'
		-- sen.graData:addLight(ambientLight)

		-- local skyLight = _SkyLight.new()
		-- skyLight.name = 'skylight'
		-- skyLight.direction = _Vector3.new(40, -5, -30) --TODO.
		-- sen.graData:addLight(skyLight)

		-- local fog = _Fog.new()
		-- fog.name = 'fog'
		-- sen.graData:addFog(fog)
	end

	resetSceneConfig(sen)

	if sen.blocks then
		for i = #sen.blocks, 1, -1 do
			sen:delBlock(sen.blocks[i])
		end
	end
	sen.groups = {}
	sen.blocks = {}
	sen.blockuis = {}
	sen.renderingBlocks = {}

	sen.respawnlist = {}

	for k, v in next, Scene do
		sen[k] = v
	end

	sen:clearActors()
	sen:onUpdate(function(n, e)
		if n.block then
			n.block:update(e)
		end
	end)

	sen.reflects = {}
	sen.refracts = {}
	sen.waters = {}
	sen.graData:getWaters(sen.waters)
	for i, v in ipairs(sen.waters) do
		if _and(v.mode, _Water.Reflect) > 0 then
			table.insert(sen.reflects, v)
		end
		if _and(v.mode, _Water.Refract) > 0 then
			table.insert(sen.refracts, v)
		end
		-- v.isRefColor = true
		-- v.isHighQuality = true
	end

	if sen.terrainNode then sen.terrainNode.pickFlag = Global.CONSTPICKFLAG.TERRAIN end

	sen:onRender(function(n, e)
		-- 临时代码，隐藏动画辅助模型
		if _G.useOldShadow and _sys.enableOldShadow then
			_rd.shadowCaster = n.isShadowCaster
			_rd.shadowReceiver = n.isShadowReceiver
		end

		if n.block then
			--table.insert(sen.renderingBlocks, n.block)
			n.block:onRender(n.instanceMesh)
		elseif n.mesh then
			if not n.tooNearByCam then
				if n and n.blender then
					_rd:useBlender(n.blender)
				end
				
				if n.mesh.isAlphaFilter then 
					_rd.isAlphaFilter = true 
				end

				if n.instanceMesh then
					n.instanceMesh:drawInstanceMesh()
				else
					n.mesh:drawMesh()
				end

				if n.mesh.isAlphaFilter then
					_rd.isAlphaFilter = false
				end

				n:drawEmoji()

				if n and n.blender then
					_rd:popBlender()
				end
			end
		elseif n.terrain then
			n.terrain:draw()
		end

		if _G.useOldShadow and _sys.enableOldShadow then
			_rd.shadowCaster = false
			_rd.shadowReceiver = false
		end
	end)

	if _G.useOldShadow and _sys.enableOldShadow then
		sen:onRenderCaster(function(n)
			if n.isShadowCaster then _rd.shadowCaster = true end

			if n.block then
				n.block:onRender(n.instanceMesh)
			elseif n.mesh then
				if n.instanceMesh then n.instanceMesh:drawInstanceMesh() else n.mesh:drawMesh() end
			elseif n.terrain then
				n.terrain:draw()
			end

			_rd.shadowCaster = false
		end)
	end

	return sen
end

function _G.CreateSceneInstance(n)
	local sen = CreateSceneWithBlocks(n)

	sen.events = {}
	sen.GameData = {
		Trophies = {},
		setTrophy = function(self, block, enabled)
			if self.Trophies[block] then
				self.Trophies[self.Trophies[block]].enabled = enabled
			else
				table.insert(self.Trophies, {block = block, enabled = enabled})
				self.Trophies[block] = #self.Trophies
			end
		end,
		Score = nil,
	}

	--- 给项目中的可破坏砖块增加破坏记录
	sen.DestoryBlock = {}

	sen.name = sen.resname ~= '' and sen.resname:sub(1, -4) or n:sub(1, -4)

	sen:createWall()

	sen:loadLevelData(sen:getLevelData())

	sen:refreshLevel()
	sen:logoutEvents()
	sen:loadActionFunctions()
	sen:registerEvents()
	sen:initEvents()
	sen:useRDSetting()

	_gc()

	return sen
end

function _G.CreateScene(n, auto_air_wall)
	if Global.sen then
		-- 停止录制shader
		if _G.RECORDSHADER then
			_sys:endRecordShader()
			_sys:saveRecordShader("./shaderRecord/" .. Global.sen.shaderKey, true)
			_sys:clearRecordShader()
		end

		Global.sen:logoutEvents()
		Global.sen:delAllBlockUIs()

		-- mesh存放于全局表中，需要将mesh与场景解耦，否则释放不掉场景.
		if Global.sen ~= Global.HomeTmpCache and Global.sen ~= Global.LobbyTmpCache then
			Global.sen:clear()
		end
	end

	Global.ClearHotKeyFunc()

	if n and n:find('home') and Global.HomeTmpCache then
		Global.sen = Global.HomeTmpCache

		Global.sen:refreshLevel()
		Global.sen:logoutEvents()
		Global.sen:loadActionFunctions()
		Global.sen:registerEvents()
		Global.sen:initEvents()
		Global.sen:useRDSetting()
		_gc()

		return
	elseif Global.findSenName(n) == 'lobby' and Global.LobbyTmpCache then
		Global.sen = Global.LobbyTmpCache
		Global.sen:refreshLevel()
		Global.sen:logoutEvents()
		Global.sen:loadActionFunctions()
		Global.sen:registerEvents()
		Global.sen:initEvents()
		Global.sen:useRDSetting()
		_gc()

		return
	end

	local sen = CreateSceneWithBlocks(n)

	local respawninfo = Global.initrespawnpos[1]
	sen.respawnpos = _Vector3.new(respawninfo.pos.x, respawninfo.pos.y, respawninfo.pos.z)
	sen.respawndir = _Vector3.new(respawninfo.dir.x, respawninfo.dir.y, respawninfo.dir.z)

	sen.events = {}
	sen.GameData = {
		Trophies = {},
		setTrophy = function(self, block, enabled)
			if self.Trophies[block] then
				self.Trophies[self.Trophies[block]].enabled = enabled
			else
				table.insert(self.Trophies, {block = block, enabled = enabled})
				self.Trophies[block] = #self.Trophies
			end
		end,
		Score = nil,
	}
	sen.update_block_list = {}

	--- 给项目中的可破坏砖块增加破坏记录
	sen.DestoryBlock = {}

	sen.name = sen.resname ~= '' and sen.resname:sub(1, -4) or n and n:sub(1, -4) or ''
	local sname = _sys:getFileName(n, false, false)
	Global.sen = sen
	-- 录制shader
	Global.sen.shaderKey = string.format("%s_%s.sr", sname, _sys.os)
	if _G.useRecordShader then
		if _sys:fileExist(Global.sen.shaderKey) then
			_sys:loadRecordShader(Global.sen.shaderKey)
		end
	end
	if _G.RECORDSHADER then
		_sys:beginRecordShader()
	end

	if sname == 'build' then
		_rd.asyncShader = false
	else
		_rd.asyncShader = _G.useAsyncShader
	end

	if _sys:getFileName(sen.resname) == 'house3.sen' then
		sen.enableDelayLoad = true
	end

	-- if auto_air_wall then
	-- 	sen:createWall()
	-- end

	sen:loadLevelData(sen:getLevelData())
	for i, b in ipairs(sen.blocks) do
		b:enableAutoAnima(true, true, true)
	-- 	b:playDynamicEffect('df1')
	end

	Global.sen:refreshLevel()
	Global.sen:logoutEvents()
	Global.sen:loadActionFunctions()
	Global.sen:registerEvents()
	Global.sen:initEvents()

	local function buildMirror(sen)
		-- Add mirror.
		local block = sen:getBlockByShape('mirror')
		if not block then return end

		sen.isMirrorSen = true

		local trans = _Vector3.new()
		block.node.transform:getTranslation(trans)

		local plane = _mf:createPlane()
		-- plane.transform = _Matrix3D.new():setScaling(0.08, 0.50, 0.72)
		plane.transform = _Matrix3D.new():setScaling(0.6, 5, 1.2):mulRotationXLeft(math.pi / 2):mulTranslationRight(0, -0.05, -0.05)

		local db = _DrawBoard.new(_rd.w, _rd.h)
		db.postProcess = _PostProcess.new()
		db.postProcess.bloom = false
		plane.material.diffuseMap = db
		plane.material.isNoLight = true

		local node = sen:add(plane, block.node.transform)
		node.isMirrorNode = true

		node.mesh.enableInstanceCombine = false
	end

	if sen.name:find('home') then
		Global.HomeTmpCache = sen

		buildMirror(sen)
	elseif Global.findSenName(sen.name) == 'lobby' then
		local resname = _sys:getFileName(sen.resname)
		if resname == 'Garden.sen' then
			sen.skyRange = 18
		end
		Global.LobbyTmpCache = sen
	elseif _sys:getFileName(sen.resname) == 'house3.sen' then
		sen.skyRange = 42
	end

	if sen.name:find('studio') then
		buildMirror(sen)
	end

	if sen.resname:find('guide') or sen.resname:find('tunnel') or sen.resname:find('room_animal') then
		-- print(sen.name)
	elseif _sys:getGlobal('AUTOTEST') then
		Global.TimeOfDayManager:setCurrentTime()
	else
		local curtime = _sys.currentTime
		local time = curtime.hour + curtime.minute / 60
		Global.TimeOfDayManager.curTime = time
	end

	_gc()

	return sen
end

Scene.useSkylightDirection = function(self)
	local skylight = self.graData:getLight('skylight')
	if skylight and skylight.direction then
		local waters = {}
		self.graData:getWaters(waters)
		_rd.shadowLight = skylight.direction
		for i, w in next, waters do
			w.lightDir = skylight.direction
			-- w.lightColor = skylight.color
			-- w.lightPower = skylight.power
			-- w.reflectColor = ambient.color
			-- w.color = ambient.color
		end
	end
end

Scene.useBackupGraData = function(self)
	self.backupGraData = self.backupGraData:clone()
	self.graData = self.backupGraData
	self:useSkylightDirection()
end

Scene.showTile = function(self, show)
	self.dimianpfx.visible = show
	self.drawTile = show
end

Scene.renderHint = function(self)
	for i, v in ipairs(self.blocks) do
		v:renderHint()
	end
end

-- 执行一个动作
Scene.doAction = function(self, a, object)
	if a.type == 'guide' then
		local step = a.data[1]
		if step == 'move' then
			Global.Guide:moveGuide()
		elseif step == 'jump' then
			Global.Guide:jumpGuide()
		elseif step == 'build' then
			Global.Guide:buildGuide()
		elseif step == 'trigger' then
			Global.Guide:triggerGuide()
		elseif step == 'eventblock' then
			Global.Guide:eventBlockGuide()
		elseif step == 'passgate' then
			Global.Guide:enterGate()
		elseif step == 'markchange' then
			Global.Guide:updateMarkPoint(a.data[2])
		elseif step == 'stoppfx' then
			Global.Guide:stopMarkPoint()
		end
	elseif a.type == 'losecontroll' then
		local time = a.data[1]
		Global.SwitchControl:set_freeze_on()
		Global.clock1 = _Timer.new()
		Global.clock1:start("clock1", time,
			function()
				Global.clock1:stop("clock1")
				Global.SwitchControl:set_freeze_off()
			end
		)
	elseif a.type == 'modeui' then
		Global.ui.interact:attach(object, a)
	elseif a.type == 'closeup' then
		local camera = a.data[1]
		local time = a.data[2]

		self:setCloseupCamera(camera, time)
		if self.onCloseupCamera then
			self:onCloseupCamera(camera, time)
		end
	end
end
Scene.logoutEvents = function(self)
	for i, v in ipairs(self.blocks) do
		v:logoutEvents()
	end
	for i, v in pairs(self.groups) do
		v:logoutEvents()
	end
	for i, v in pairs(self.blockuis) do
		v:logoutEvents()
	end
end
Scene.loadActionFunctions = function(self)
	for i, v in ipairs(self.blocks) do
		v:loadActionFunctions(self)
	end
	for i, v in pairs(self.groups) do
		v:loadActionFunctions(self)
	end
	for i, v in pairs(self.blockuis) do
		v:loadActionFunctions(self)
	end
end
Scene.registerEvents = function(self)
	for i, v in ipairs(self.blocks) do
		v:registerEvents()
	end
	for i, v in pairs(self.groups) do
		v:registerEvents()
	end
	for i, v in pairs(self.blockuis) do
		v:registerEvents()
	end
end
Scene.initEvents = function(self)
	for i, v in ipairs(self.blocks) do
		v:initEvents()
	end
	for i, v in pairs(self.groups) do
		v:initEvents()
	end
	for i, v in pairs(self.blockuis) do
		v:initEvents()
	end
end

Scene.setCloseupCamera = function(self, camera, time)
	local oldcamera = _rd.camera:clone()
	_rd.camera:set(camera)

	local function closeup()
		_rd.camera:set(oldcamera)
		self.rtdata.closeuptimer:stop('closeup')
	end

	if not self.rtdata.closeuptimer then
		self.rtdata.closeuptimer = _Timer.new()
	end

	self.rtdata.closeuptimer:start('closeup', time, closeup)
end
Scene.setRespawn = function(self, object, dir)
	local bs = object:getBlocks()
	-- 同名重生块只取最后一个
	local block = bs[#bs]
	local aabb = _AxisAlignedBox.new()
	block:getAABB(aabb)

	local pos = _Vector3.new()
	pos.x = (aabb.max.x + aabb.min.x) / 2
	pos.y = (aabb.max.y + aabb.min.y) / 2
	-- 紧贴地表会被物理影响可能导致滑动位置
	pos.z = aabb.max.z + 0.5

	self:setRespawnPosDir(pos, dir)
end
Scene.setRespawnPosDir = function(self, pos, dir, i)
	i = i or 1
	self.respawnlist[i] = {pos = pos:clone(), dir = dir:clone()}
end
local default_respawn = {pos = _Vector3.new(0, 0, 0), dir = _Vector3.new(0, -1, 0)}
Scene.getRespawnData = function(self, i)
	i = i or 1
	if i > #self.respawnlist then
		i = i % #self.respawnlist + 1
	end

	if self.respawnlist[i] then
		return self.respawnlist[i]
	else
		return default_respawn
	end
end
-- 回调
Scene.onWin = function(self, bs)
	-- print('win')
	-- for i, got in ipairs(self.GameData.Trophies) do
	-- 	print(got.block, got.enabled)
	-- end
	if #Global.sen.GameData.Trophies > 0 then
		Global.GameState:changeState('WINTROPHY')
	else
		Global.GameState:changeState('WINSCORE')
	end
end

Scene.onCloseupCamera = function(self, camera, time)
end

Scene.inEdit = function(self)
	if self.setting.needrefresh == false then return end

	self:refreshLevel()
	self:logoutEvents()
	self:loadActionFunctions()
	self:setUIMode('Edit')
end
Scene.inGame = function(self)
	if self.setting.needrefresh == false then return end

	self:setUIMode('Game')
	self:registerEvents()
	self:initEvents()
end
Scene.getDummyActor = function(self)
	if not self.dummyActor then
		self.dummyActor = Global.sen:addActor()
	end

	return self.dummyActor
end

Scene.bindDummyData = function(self, data)
	local actor = self:getDummyActor()
	actor:clearShapes()

	local vec = Container:get(_Vector3)
	local transform = Container:get(_Matrix3D)
	for i, v in ipairs(data) do
		local shape = actor:addShape(_PhysicsShape.Cube)
		v.box:getSize(vec)
		local sx, sy, sz = vec.x * 0.5, vec.y * 0.5, vec.z * 0.5
		shape.size = _Vector3.new(sx, sy, sz)
		shape.queryFlag = Global.CONSTPICKFLAG.DUMMY

		v.box:getCenter(vec)
		transform:setTranslation(vec)
		if v.rot then
			transform:mulRotationLeft(v.rot.x, v.rot.y, v.rot.z, v.rot.w)
		end

		shape.transform:set(transform)
	end

	Container:returnBack(vec, transform)
end

Scene.sweepBox = function(self, ab, ori, dir, len, flag)
	local box = Container:get(_AxisAlignedBox)
	box:set(ab)
	box:alignCenter(Global.AXIS.ZERO)
	local data = {}
	table.insert(data, {box = box})
	self:bindDummyData(data)

	local actor = self:getDummyActor()
	actor.transform:setTranslation(ori)

	local sweeps = {}
	local r = Global.sen:physicsSweep(actor, dir, len, flag, sweeps)
	local pos = Container:get(_Vector3)
	_Vector3.mul(dir, r and sweeps.distance or len, pos)
	_Vector3.add(pos, ori, pos)
	ab:alignCenter(pos)

	Container:returnBack(box, pos)
	--print('sweepBox', r, len, sweeps.distance, pos, ori, dir, flag)
	return r
end

Scene.updateBgPfx = function(self)
	if self.bgpfx == nil or self.bgpfx.visible == false then return end
	local dir = Container:get(_Vector3)
	local camera = Global.CameraControl:get()
	camera:update()
	_Vector3.sub(camera.camera.look, camera.camera.eye, dir)
	dir:normalize()
	_Vector3.mul(dir, 400, dir)
	_Vector3.add(dir, camera.camera.eye, dir)
	self.bgpfx.transform:setTranslation(dir)
	Container:returnBack(dir)
end

Scene.updateLoadingBlocks = function(self)
	if self.loadingblocks and #self.loadingblocks > 0 then
		--local cc = Global.CameraControl:get()
		--local look = cc.camera.look
		--local t = self.data.space.translation
		local t0 = _tick()
		for i = #self.loadingblocks, 1, -1 do
			local b = self.loadingblocks[i]
			b:loadMeshData()
			table.remove(self.loadingblocks)
			local t1 = _tick()
			if t1 - t0 > 30 then
				return
			end
		end
	end
end
Scene.add_update_block = function(self, b)
	if not self.update_block_list then return end
	table.insert(self.update_block_list, b)
end
Scene.update_blocks = function(self, e)
	if not self.update_block_list then return end
	for i, b in ipairs(self.update_block_list) do
		b:update2(e)
	end
	table.clear(self.update_block_list)
end