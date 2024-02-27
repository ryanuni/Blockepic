local Function = _require('Function')

local of = {}
Global.ObtainFame = of

local pft = {}
Global.PortalFixTask = pft
local portallvs = {
	'portal0',
	'portal1',
	'portal2',
	'portal3',
	'portal4',
	'portal5',
	'portal6',
	'portal7',
	'portal8',
	'portal9',
	'portal',
}

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

local function drawNumberImgs(number, offsetx, scale, x, y, w, h)
	local fontstr = 'number_white'
	local l = _String.len(tostring(number))
	-- local offsetx = -2
	local fontw, fonth = 0, 0
	local images = {}
	for i = 1, l do
		local c = _String.sub(number, i, i)
		local img = _Image.new(fontstr .. '_' .. c .. '.png')
		table.insert(images, img)

		if i == 1 then
			fontw = fontw + img.w
			fonth = img.h
		else
			fontw = fontw + img.w + offsetx
		end
	end

	local diffx = (w - fontw * scale) / 2 + x - 4 * scale
	local diffy = (h - fonth * scale) / 2 + y
	for i, img in ipairs(images) do
		img:drawImage(diffx, diffy, diffx + img.w * scale, diffy + img.h * scale)
		diffx = diffx + (img.w + offsetx) * scale
	end
end

pft.initScene = function(self)
	self.level = 0
	self.progress = self.progress and math.min(self.progress, 100) or 0
	self.subprogress = self.subprogress and math.min(self.subprogress, 100) or 0

	local portal = Global.sen:getBlockByShape('portal')
	if not portal then return end
	portal:setName('portal')
	loadBlockFunction(portal, 'portal.func')
	self.portalBlock = portal

	local stonetablet = Global.sen:getBlockByShape('Stonetablet')
	stonetablet:setName('stonetablet')
	of.stonetabletBlock = stonetablet
	loadBlockFunction(stonetablet, 'stonetablet.func')

	self:updateTotalProgress()
end

pft.updateTotalProgress = function(self, add1, add2)
	if _sys:getFileName(Global.sen.name, false, false) ~= 'house2' then return end

	local progress = self.progress or 0
	local lv = toint(progress / 10) + 1
	if self.level ~= lv then
		self.level = lv
		self:updateRepairNPC(self.level, add1)
	end

	if add1 then
		local b = self.portalBlock
		local mesh = b.node.mesh
		mesh.enableInstanceCombine = false
		local mat = _Matrix3D.new():setScaling(0.1, 0.1, 0.1)
			:mulRotationZRight(math.pi / 2):mulTranslationRight(-1.2, 0, 1.6)
		mesh.pfxPlayer:play('portal_activation_01.pfx', mat)
	end

	self:updateSubProgress(add2)
end

pft.updateSubProgress = function(self, add2)
	if _sys:getFileName(Global.sen.name, false, false) ~= 'house2' then return end

	-- self.subprogress = math.max(progress, 100)
	if add2 then
		Global.Sound:play('showfame')
	end
	self:updateBoardData()
end

pft.genBoardImage2 = function(self, prog1)
	self.boarddb2 = self.boarddb2 or _DrawBoard.new(200, 200)
	-- self.defaultstar = self.defaultstar or _Image.new('func_bg.png')
	-- self.imgbg1 = self.bgimg1 or _Image.new('portal_prog1_bg.png')
	self.imgbg1 = self.imgbg1 or _Image.new('circlebg.png')
	_rd:useDrawBoard(self.boarddb2, _Color.Null)
	local x, y, w, h = 10, 10, 180, 180

	local shapes = {}
	DrawHelper.FillRadial360(1, prog1 / 100, true, _Vector2.new(x, y), _Vector2.new(x + w, y + h), shapes)

	_rd:useMask(function()
		DrawHelper.drawFillRadialShapes(shapes, _Color.Red)
	end)
	self.imgbg1:drawImage(x, y, x + w, y + h)

	_rd:popMask()

	self.boardfont2 = self.boardfont2 or _Font.new('Supersonic Rocketship', 60, 0, 0, 3, 600)
	-- self.boardfont = self.boardfont or _Font.new('Comic Sans MS', 30, 0, 0, 2, 400)
	self.boardfont2.textColor = _Color.White
	self.boardfont2.edgeColor = _Color.Black
	self.boardfont2.glowColor = _Color.Black

	self.boardfont3 = self.boardfont3 or _Font.new('Supersonic Rocketship', 30, 0, 0, 3, 400)
	self.boardfont3.textColor = _Color.White
	self.boardfont3.edgeColor = _Color.Black
	self.boardfont3.glowColor = _Color.Black

	self.boardfont3:drawText(x, y + 50, x + w, y + h, 'Total', _Font.hCenter)
	self.boardfont2:drawText(x, y + 95, x + w, y + h, prog1 .. '%', _Font.hCenter)

	_rd:resetDrawBoard()
	return _Image.new(self.boarddb2)
end

pft.genBoardImage1 = function(self, prog1, prog2)
	self.boarddb = self.boarddb or _DrawBoard.new(624, 156)
	-- self.defaultstar = self.defaultstar or _Image.new('func_bg.png')
	-- self.imgbg1 = self.bgimg or _Image.new('portal_prog1_bg.png')
	self.imgprog = self.imgprog or _Image.new('portal_prog2.png')
	self.imgprogbg = self.imgprogbg or _Image.new('portal_prog2_bg.png')

	_rd:useDrawBoard(self.boarddb, _Color.Null)
	-- local x, y, w, h = 38, 24, 120, 120

	-- local shapes = {}
	-- DrawHelper.FillRadial360(1, prog1 / 100, true, _Vector2.new(x, y), _Vector2.new(x + w, y + h), shapes)

	-- _rd:useMask(function()
	-- 	DrawHelper.drawFillRadialShapes(shapes, _Color.Red)
	-- end)
	-- self.imgbg1:drawImage(x, y, x + w, y + h)

	-- _rd:popMask()

	self.boardfont = self.boardfont or _Font.new('Supersonic Rocketship', 30, 0, 0, 3, 400)
	self.boardfont.textColor = _Color.White
	self.boardfont.edgeColor = _Color.Black
	self.boardfont.glowColor = _Color.Black

	-- self.boardfont:drawText(x, y, x + w, y + h, 'Total\n' .. prog1 .. '%', _Font.hCenter + _Font.vCenter)

	local x, y, w, h = 42, 50, 540, 70
	self.imgprogbg:drawImage(x, y, x + w, y + h)

	w = toint(w * prog2 / 100, 1)
	self.imgprog:drawImage(x, y, x + w, y + h)

	w = 540
	self.boardfont:drawText(x, y, x + w - 10, y + h, 'Daily ' .. prog2 .. '%', _Font.hCenter + _Font.vCenter)

	_rd:resetDrawBoard()
	return _Image.new(self.boarddb)
end

pft.updateBoardData = function(self)
	local meshes = _G.Block.getPaintMeshs(self.portalBlock.node.mesh)

	local mesh1, mesh2 = meshes[1], meshes[2]
--	print('mesh1', mesh1, mesh2)
	if mesh1 then
		mesh1.material.diffuseMap = self:genBoardImage1(self.progress, self.subprogress)
		mesh1.material.isAlpha = true
		mesh1.material.isDecal = true
		-- mesh1.material.isNoLight = true
		-- mesh1.material.isNoFog = true
	end
	if mesh2 then
		mesh2.material.diffuseMap = self:genBoardImage2(self.progress)
		mesh2.material.isAlpha = true
		mesh2.material.isDecal = true
		-- mesh2.material.isNoLight = true
		-- mesh2.material.isNoFog = true
	end
	--self.portalBlock:changePaintImage(self:genBoardImage(self.progress, self.subprogress))
end

pft.updateRepairNPC = function(self, lv, add1)
	self.portalBlock:refreshShape(portallvs[lv])

	-- 未修复完时隐藏SSAO
	self.portalBlock.node.mesh.ssaoReceiver = lv == #portallvs
	self.portalBlock.node.isInsAlphaFilter = false
	-- if add1 then
		--Global.Sound:play('coin')
	-- end
end

-----------------------------------------------

local addedSubProgress = false
pft.addSubProgress = function(self)
	RPC("AddPortalSubprogress", {})
	addedSubProgress = true
end
pft.getProgress = function(self)
	RPC("GetPortalProgressInfo", {})
end

------------------------------------------

define.UpdatePortalTask{TaskInfo = {}}
when{}
function UpdatePortalTask(TaskInfo)
	-- print("UpdatePortalTask", table.ftoString(TaskInfo))
	local prog1 = math.min(TaskInfo.progress, 100)
	local prog2 = math.min(TaskInfo.subprogress, 100)
	local add1 = addedSubProgress and prog1 > (pft.progress or 0)
	local add2 = addedSubProgress and prog2 > (pft.subprogress or 0)
	pft.progress = prog1
	pft.subprogress = prog2

	pft:updateTotalProgress(add1, add2)
end

----------------------

of.drawFameObtain = function(self, number, x, y, w, h)
	self.imgframetaskbg = self.imgframetaskbg or _Image.new('fametask_bg2.png')
	self.imgframetaskbg:drawImage(x, y, x + w, y + h)
	drawNumberImgs(number, -1, 0.8, x - 10, y, w, h)
end

of.genFameObtainDB = function(self, data)
	self.fameObtaindb = self.fameObtaindb or _DrawBoard.new(300, 200)
	self.imgfamebig = self.imgfamebig or _Image.new('fame.png')
	_rd:useDrawBoard(self.fameObtaindb, _Color.Null)

	local x, y, w, h = 0, 25, 150, 150
	self.imgfamebig:drawImage(x, y, x + w, y + h)

	x, y, w, h = 150, 0, 120, 40
	y = y + (5 - #data) / 2 * h
	for i, v in ipairs(data) do
		self:drawFameObtain(v.earn, x, y, w, h)
		y = y + h
	end

	_rd:resetDrawBoard()
	return _Image.new(self.fameObtaindb)
end

of.doneFameTask = function(self, fames)
	local img = self:genFameObtainDB(fames)
	-- local img = _Image.new('fame_big.png')
	img.duration = 6000
	img.tick = os.now() + 6000
	img.delay = 0
	img.nobg = true
	img.isDB = true

	-- local stonetablet = Global.sen:getBlockByShape('Stonetablet')
	local node = self.stonetabletBlock.node
	node.expimg = img

	local aabb = node.mesh:getBoundBox()
	node.Height = -1

	--local aabb = Global.role.node.mesh:getBoundBox()
	--local height = aabb.z2 - aabb.z1 + 0.5
	-- local mat = _Matrix3D.new()
	-- mat:set(Global.role.node.transform)
	-- mat:mulTranslationRight(0, 0, height, 0)
	-- Global.sen.pfxPlayer:play('ui_mybz_shanyixia.pfx', 'ui_mybz_shanyixia.pfx', mat)
	Global.Sound:play('showfame')
	Global.gmm:startMovie('lookstonetablet')
	Global.Timer:add('gmm_doneFameTask', 6000, function()
		-- node.expimg = nil
		if _sys:getFileName(Global.sen.name, false, false) == 'house2' then
			Global.role.node.expimg = nil
			self:updateBoard()
			Global.Sound:play('coin')
		end
		-- Global.CoinUI:flush()
	end)
end

of.updateFame = function(self, fames, behavior)
	local oldn = self.fames and #self.fames or 0
	self.fames = fames

	if _sys:getFileName(Global.sen.name, false, false) == 'house2' then
	if behavior == 'Do_Fix_Portal' and #fames - oldn > 0 then
		-- local n = #fames - oldn
		local data = {}
		local maxi = math.min(#fames, oldn + 5)
		for i = oldn + 1, maxi do
			table.insert(data, fames[i])
		end
			self:doneFameTask(data)
		else
			self:updateBoard()
		end
	end
end

of.getFameCount = function(self)
	if not self.fames then return 0 end
	local total = 0
	for i, v in ipairs(self.fames) do
		total = total + v.earn
	end

	return total
end

of.genBoardImage = function(self)
	self.boarddb = self.boarddb or _DrawBoard.new(400, 100)
	self.imgbg = self.imgbg or _Image.new('fame.png')
	_rd:useDrawBoard(self.boarddb, _Color.Null)

	local x, y, w, h = 240, 5, 90, 90
	self.imgbg:drawImage(x, y, x + w, y + h)

	local famecount = self:getFameCount()

	x, y, w, h = 0, 5, 300, 100
	drawNumberImgs(famecount, 0, 1.5, x, y, w, h)

	-- self.boardfont = self.boardfont or _Font.new('Supersonic Rocketship', 46)
	-- self.boardfont.textColor = _Color.White
	-- self.boardfont:drawText(x, y, x + w, y + h, famecount, _Font.hCenter + _Font.vCenter)

	_rd:resetDrawBoard()
	return _Image.new(self.boarddb)
end

of.updateBoard = function(self)
	local stonetablet = self.stonetabletBlock

	local famecount = self:getFameCount()
	local newshape = famecount == 0 and 'Stonetablet' or 'Stonetablet1'
	if stonetablet:getShape() ~= newshape then
		stonetablet:refreshShape(newshape)
	end

	stonetablet:changePaintImage(self:genBoardImage())
	Global.ui.interact:refresh()

	--self.portalBlock:refreshShape(famecount > 0)
end

of.obtainFame = function(self)
	if _sys:getFileName(Global.sen.name, false, false) ~= 'house2' then return end
	RPC("ObtainFames", {})
end

-- of.getFameEarnInfo = function(self)
-- 	-- TODO:
-- 	RPC("GetFameEarnInfo", {})
-- end
