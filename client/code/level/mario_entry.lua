local MarioEntry = {timer = _Timer.new()}
Global.MarioEntry = MarioEntry
local Function = _require('Function')
local Container = _require('Container')

local loadBlockFunction = function(b, funcname)
	-- print('loadBlockFunction:', funcname)
	local data = _dofile(funcname)
	for i, v in ipairs(data or {}) do
		print(i, v)
		b:addFunction(Function.new(v))
	end
	b:loadActionFunctions(Global.sen)
	b:registerEvents()
	b:initEvents()
end

MarioEntry.initBlock = function(self)
	local block = Global.sen:getBlockByShape('MarioDoor')
	if not block then return end
	local mesh = _G.Block.getPaintMeshs(block.node.mesh)[1]
	if not mesh then return end
	local pmesh = _G.Block.getParentMesh(block.node.mesh, mesh)

	if self.block == block then
		return true
	end
	block:setName('mario')
	block:setVisible(false)
	if not _sys:getGlobal('PCRelease') then
		loadBlockFunction(block, 'mario.func')
		block:setVisible(true)
	end

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

	local cam
	if not cam then
		cam = _Camera.new()
		cam.eye = _Vector3.new(18.28, -7.24, 26.3)
		cam.look = _Vector3.new(22.99, -7.27, 24.78)

		local dir = Container:get(_Vector3)
		_Vector3.sub(cam.look, cam.eye, dir)
		dir:normalize()
		dir:scale(2)
		_Vector3.add(cam.eye, dir, cam.look)
		Container:returnBack(dir)
	end

	self.camera = cam
	self.pfx1 = _Particle.new('wq_rongjie_xs.pfx')
	self.pfx2 = _Particle.new('wq_rongjie_cx.pfx')

	return true
end

MarioEntry.init = Global.BlockBrawlEntry.init
MarioEntry.drawnode = Global.BlockBrawlEntry.drawnode
MarioEntry.updateMatchTick = Global.BlockBrawlEntry.updateMatchTick
MarioEntry.updateMatchUI = Global.BlockBrawlEntry.updateMatchUI
MarioEntry.showPrepareUI = Global.BlockBrawlEntry.showPrepareUI
MarioEntry.updateScoreUI = Global.BlockBrawlEntry.updateScoreUI
MarioEntry.camera_focus = Global.BlockBrawlEntry.camera_focus