local GOS1Entry = {timer = _Timer.new()}
Global.GOS1Entry = GOS1Entry
_dofile('cfg_gos1.lua')
for i = 1, 100 do
	local v = _G.cfg_gos1[i]
	if v then
		_G.cfg_gos1[v.filename] = v
	end
end

local Function = _require('Function')
local Container = _require('Container')

local function checkGOS1(name)
	return _G.cfg_gos1[name] ~= nil
end

local function getGOS1(name)
	return _G.cfg_gos1[name]
end

local xaxis2 = _Vector2.new(0, -1)
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

local loadFBlockFunction = function(b, funcdata)
	for i, v in ipairs(funcdata or {}) do
		b:addFunction(Function.new(v))
	end

	b:loadActionFunctions(Global.sen)
	local actions = b:getActions()
	actions[3]:registerDefineFunc(function()
		GOS1Entry:show_board(b)
	end)
	actions[4]:registerDefineFunc(function()
		GOS1Entry:hide_board(b)
	end)
	b:registerEvents()
	b:initEvents()
end
GOS1Entry.show_board = function(self, b)
	--print('show_board', b.data.shape)
	Global.sen.browsering_block = b

	local data = getGOS1(b.data.shape)
	GOS1Entry:updateBBUI(data)
	Global.sen.browserblock:setVisible(true, false)
	Global.sen.browserblock:setPickFlag(Global.CONSTPICKFLAG.SELECTBLOCK)

	local ab = Container:get(_AxisAlignedBox)
	local vec3 = Container:get(_Vector3)
	local size = Container:get(_Vector3)
	b:getAABB(ab)
	ab:getSize(size)
	b.node.transform:getTranslation(vec3)
	local rolepos = Container:get(_Vector3)
	Global.role:getPosition(rolepos)
	local vec2 = Container:get(_Vector2)
	vec2.x = rolepos.x - vec3.x
	vec2.y = rolepos.y - vec3.y
	vec2:normalize()
	local centerx = size.x / 2
	local centery = size.y / 2
	local msy = centery / math.abs(vec2.y)
	local msx = centerx / math.abs(vec2.x)
	local mlen = math.min(msy, msx)

	vec3.x = vec3.x + vec2.x * mlen
	vec3.y = vec3.y + vec2.y * mlen
	vec3.z = rolepos.z + Global.role:getEyeHeight() * 1.6
	local function calcrot(v)
		local r = _Vector2.dot(v, xaxis2)
		return v.x > 0 and math.acos(r) or -math.acos(r)
	end

	local pi2 = math.pi / 2
	local rot = calcrot(vec2)
	local rot0 = math.modf(rot / pi2)
	local mod = math.fmod(rot, pi2)
	if mod > 0 then
		if mod > math.pi / 6 then rot0 = rot0 + 1 end
	else
		if mod < -math.pi / 6 then rot0 = rot0 - 1 end
	end

	GOS1Entry:resetBBlock(vec3, rot0 * pi2)
	Container:returnBack(ab, vec3, size, rolepos, vec2)
end
GOS1Entry.hide_board = function(self, b)
	if Global.sen.browsering_block == b then
		Global.sen.browserblock:setVisible(false)
	end
end
GOS1Entry.init = function(self, sen)
	if not sen then return end
	self.sen = sen

	local funcdata = _dofile('browser.func')
	for i, v in ipairs(sen:getAllBlocks()) do
		local isgos1 = checkGOS1(v.data.shape)
		--print('GOS1Entry.init', v.data.shape, isgos1)
		if isgos1 then
			loadFBlockFunction(v, funcdata)
		end
	end

	local data = {shape = 'browserbg'}
	local block = self.sen:createBlock(data)
	block:setVisible(false)
	block:setPickFlag(Global.CONSTPICKFLAG.SELECTBLOCK)
	sen.browserblock = block

	local meshs = _G.Block.getPaintMeshs(block.node.mesh)
	if not meshs or #meshs == 0 then return end
	self.db = _DrawBoard.new(700, 700)
	for _, m in pairs(meshs) do
		local pmesh = _G.Block.getParentMesh(block.node.mesh, m)
		local material = m.material
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
		m.material.diffuseMap = self.db
	end

	self.font1 = _Font.new('Supersonic Rocketship', 40, 0, 0, 0, 0, true)
	self.font1.textColor = _Color.White
	self.font2 = _Font.new('Supersonic Rocketship', 40, 0, 0, 0, 0, true)
	self.font2.textColor = _Color.Gray
end

local bimg = _Image.new('icon_shape_brick.png')
local function GetNumDigit(num)
	local result = num
	local digit = 0
	while(result > 0) do
		result = math.modf(result / 10)
		digit = digit + 1
	end
	return digit
end

GOS1Entry.updateBBUI = function(self, data)
	if not data then return end
	-- print('updateBBUI', data.filename, data.creator, data.bcount, data.title, data.buyurl)
	_rd:useDrawBoard(self.db, _Color.Null)
	local l = 100
	local t = 200
	local r = 600
	local b = 280
	local lstep = 60
	local bstep = 200
	if data.title then
		self.font1:drawText(l, t, r, b, data.title)
		t = t + lstep
		b = b + bstep
	end

	self.font1:drawText(l, t, r, b, 'Created by ' .. data.creator)
	t = t + lstep
	b = b + bstep

	local digit = GetNumDigit(tonumber(data.bcount))
	self.font1:drawText(l, t, r, b, data.bcount)
	local cl = l + digit * 20
	bimg:drawImage(cl, t - 30, cl + 100, t + 70)
	self.font1:drawText(cl + 120, t, r + 100, b, data.ltime)
	t = t + lstep
	b = b + bstep

	self.font2:drawText(l, t, r, b, 'GO TO MARKET')
	_rd:resetDrawBoard()
end
GOS1Entry.resetBBlock = function(self, vec3, r)
	local block = Global.sen.browserblock
	block.node.transform:setTranslation(vec3)
	block.node.transform:mulScalingLeft(1.5, 1.5, 1.5)
	if r then
		block.node.transform:mulRotationZLeft(r)
	end

	block:updateSpace()
end

GOS1Entry.initBlock = function(self)
	local block = Global.sen:getBlockByShape('GOS')
	if not block then return end
	loadBlockFunction(block, 'gos.func')
end