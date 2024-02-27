local NeverUpEntry = {timer = _Timer.new()}
Global.NeverUpEntry = NeverUpEntry
local Function = _require('Function')
local Container = _require('Container')

local loadBlockFunction = function(b, funcname)
	-- print('loadBlockFunction:', funcname)
	local data = _dofile(funcname)
	for i, v in ipairs(data or {}) do
		b:addFunction(Function.new(v))
	end
	b:loadActionFunctions(Global.sen)
	b:registerEvents()
	b:initEvents()
end

NeverUpEntry.initBlock = function(self)
	local block = Global.sen:getBlockByShape('NeverupDoor')
	if not block then return end
	local mesh = _G.Block.getPaintMeshs(block.node.mesh)[1]
	if not mesh then return end
	local pmesh = _G.Block.getParentMesh(block.node.mesh, mesh)

	if self.block == block then
		return true
	end
	block:setName('neverup')

	loadBlockFunction(block, 'neverup.func')

	self.block = block
	self.mesh = mesh
	self.mesh.isInvisible = true

	local s = 6 / 5
	self.mesh.transform:mulScalingLeft(s, s, 1)

	local material = self.mesh.material
	material.isAlpha = true
	material.isDecal = true
	material.isNoLight = true
	material.isNoFog = true
	material.isUseEnvironmentMap = false
	material.emissive = 0xff0f0f1f
	material.emissivePower = 20.0
	material.power = 1.0

	pmesh.material.emissive = 0xff0f0f1f
	pmesh.material.emissivePower = 1.0
	pmesh.material.power = 1.0
	
	local cam = _Camera.new()
	cam.eye:set(Global.GameRankCameras.Npc.eye)
	cam.look:set(Global.GameRankCameras.Npc.look)

	local mat = block.node.transform
	mat:apply(cam.eye, cam.eye)
	mat:apply(cam.look, cam.look)

	self.camera = cam
	self.pfx1 = _Particle.new('wq_rongjie_xs.pfx')
	self.pfx2 = _Particle.new('wq_rongjie_cx.pfx')

	return true
end

NeverUpEntry.init = Global.BlockBrawlEntry.init
NeverUpEntry.drawnode = Global.BlockBrawlEntry.drawnode
NeverUpEntry.updateMatchTick = Global.BlockBrawlEntry.updateMatchTick
NeverUpEntry.updateMatchUI = Global.BlockBrawlEntry.updateMatchUI
NeverUpEntry.showPrepareUI = Global.BlockBrawlEntry.showPrepareUI
NeverUpEntry.updateScoreUI = Global.BlockBrawlEntry.updateScoreUI
NeverUpEntry.camera_focus = Global.BlockBrawlEntry.camera_focus