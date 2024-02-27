
local MainBody = {}
Global.MainBody = MainBody

MainBody.new = function(host, isrole)
	local b = {}
	b.host = host
	b.node = host.node

	b.isRole = isrole

	setmetatable(b, {__index = MainBody})

	b.dir = _Vector3.new(0, -1, 0)

	if Version:isAlpha1() then
		b:xl_setAvatar()
	else
		b:xl_createMesh()
	end

	b.host.eyeHeight = 0.96

	return b
end
MainBody.xl_remove = function(self)
	if self.block then self.block:stopAnim() end
	self.block = nil
end
MainBody.xl_refresh = function(self)
	self.node.mesh = self.mesh
	self.host.mesh = self.mesh
end
MainBody.xl_createMesh = function(self)
	self:xl_remove()

	local m = _Mesh.new()
	self.mesh = m
	m.dir = _Vector3.new(0, -1, 0)

	if Version:isAlpha1() then
		m:addSubMesh('cha_gangtiexia_01.skn')
	else
		m:addSubMesh('cha_xiaohaizi.skn').name = 'body'

		m:enumMesh('', true, function(m1, n)
			if n == 'decal ' then
				self.facemesh = m1
			end
		end)
	end

	local skl = m:attachSkeleton('cha_xiaohaizi.skl')

	local scale = 12 / 20
	m.transform:setScaling(scale, scale, scale)

	m.enableInstanceCombine = false

	self:xl_setupAnima()

	self:xl_refresh()
end

MainBody.getDefaultAABBScale = function(self, block)
	if not block or not block.mesh then return 1.0 end
	local ab1 = block.mesh:getBoundBox()
	local defaultsize = {x = 0.71612399816513062, y = 0.57403194904327393, z = 1.2045744361821562}

	local getDefaultScale = function(h, defaulth)
		local maxzper = 1.2 * defaulth
		local minzper = 0.8 * defaulth
		local scale = (h - maxzper) * (h - minzper) + 1
		if h < defaulth then
			scale = math.sqrt(scale)
		elseif h > defaulth then
			scale = math.sqrt(1 / scale)
		end

		return scale
	end

	local scalez = getDefaultScale(ab1.z2 - ab1.z1, defaultsize.z)
	local scaley = getDefaultScale(ab1.y2 - ab1.y1, defaultsize.y)
	local scalex = getDefaultScale(ab1.x2 - ab1.x1, defaultsize.x)

	return math.min(scalex, math.min(scaley, scalez))
end
-------------------------------------------------------

MainBody.getPartAABB = function(self, pname)
	local object = self.block
	local subs = Block.getHelperData(object.data.shape, object.data.subshape).subs

	local aabb = _AxisAlignedBox.new()
	aabb:initBox()
	local p = subs.parts.data and subs.parts.data[pname]
	if p and p.logicGroup then

		local g = p.logicGroup
		for _, bi in ipairs(g.blocks) do
			local sub = object:getSubMesh(bi)
			local ab = _AxisAlignedBox.new()
			ab:set(sub:getBoundBox())
			_AxisAlignedBox.union(ab, aabb, aabb)
		end
	end
	return aabb
end

local b1 = _Vector3.new()
local b2 = _Vector3.new()
MainBody.getFootDiff = function(self)
	local ab1 = self:getPartAABB('l_foot')
	local ab2 = self:getPartAABB('r_foot')

	if not ab1:isValid() and not ab2:isValid() then
		ab1 = self:getPartAABB('l_calf')
		ab2 = self:getPartAABB('r_calf')

		if not ab1:isValid() and not ab2:isValid() then
			ab1 = self:getPartAABB('l_thing')
			ab2 = self:getPartAABB('r_thing')
		end
	end

	if ab1:isValid() and ab2:isValid() then
		ab1:getBottom(b1)
		ab2:getBottom(b2)

		_Vector3.add(b1, b2, b1)
		_Vector3.mul(b1, -0.5, b1)
		return b1
	elseif ab1:isValid() then
		local b1 = _Vector3.new()
		ab1:getBottom(b1)
		_Vector3.mul(b1, -1, b1)
		return b1
	elseif ab2:isValid() then
		local b1 = _Vector3.new()
		ab2:getBottom(b1)
		_Vector3.mul(b1, -1, b1)
		return b1
	else
		local m = self.block.mesh
		local newab = m:getBoundBox()
		return _Vector3.new(0, 0, -newab.z1)
	end
end

MainBody.xl_setAvatar = function(self, shapeid)
	self:xl_remove()

	shapeid = shapeid or 'defaultavatar'
	-- print('xl_setAvatar', shapeid, debug.traceback()) -- TODOGG
	local curnode = self.node

	-- ???
	local curactor = self.node.actor
	if not curactor then curactor = Global.sen:addActor() end

	local tmpmat = curnode.transform
	curnode.transform = _Matrix3D.new()
	local b = Global.Block.new(curnode, curactor, shapeid)
	curnode.transform = tmpmat

	b:setDynamic(true)
	b:addPickFlag(Global.CONSTPICKFLAG.ROLE)
	b:delPickFlag(Global.CONSTPICKFLAG.NORMALBLOCK)
	b.isAstronautNFT = not not shapeid:find'ipfs' -- TODO. Astronaut NFT --'astronaut'
	self.block = b

	Global.sen:delActor(b.actor)

	local m = b.mesh
	self.node.mesh = m
	self.mesh = m
	m.dir = _Vector3.new(0, -1, 0)

	local scale = self:getDefaultAABBScale(b)
	if shapeid == 'defaultavatar' then
		scale = scale * 0.8
	elseif b.isAstronautNFT then -- TODO. Astronaut NFT --'astronaut'
		scale = scale * 1.4
	end
	local footdiff = self:getFootDiff()

	m.transform:mulTranslationRight(footdiff)
	m.transform:mulScalingRight(scale, scale, scale)

	m.enableInstanceCombine = false			-- not b:hasBindPfx()
	self.node.instanceGroup = 'avatarRole'
	self.node.isSkeletal = false

	if b.isAstronautNFT then -- TODO. Astronaut NFT --'astronaut'
		local mat = _Matrix3D.new()

		mat:setScaling(0.2, 0.2, 1):mulTranslationRight(-footdiff.x, -footdiff.y, -footdiff.z)
		self.host.ringpfx = m.pfxPlayer:play('astronaut_aperture_01.pfx', mat) -- TODO. Add an invisible submesh to play pfx
		self.host.ringpfx.clipMode = _Particle.ClipNone
		m.enableInstanceCombine = false
	end

	self:xl_setupAnima()

	self:xl_refresh()
end
MainBody.bindAnimaEvents = function(self)
	local min, max = 3, 6
	if self.isRole then
		min, max = 5, 20
	end
	local r = self.host
	local m = self.node.mesh
	if not self.pfxs then self.pfxs = {} end
	if r.animas.run then
		r.animas.run:onStop(function()
			if not self.pfxs then return end
			local pfx = self.pfxs['run_smoke_01.pfx']
			if pfx then
				pfx:stop()
				self.pfxs['run_smoke_01.pfx'] = nil
			end
		end)
	end

	for k, a in next, r.animas do
		a:onEvent(function(name)
			if name == 'jump' then
				local pos = r:getPosition_const()
				Global.Sound:play3D('jump', pos, min, max)
			elseif name == 'jump2' then
				if self.block.isAstronautNFT then
					self.block:refreshPfx(true, 'rocket_jump.pfx')
				end
			elseif name == 'run1' or name == 'run2' then
				if m and not self.pfxs['run_smoke_01.pfx'] then
					local mat = _Matrix3D.new()
					local footdiff = self:getFootDiff()
					mat:setScaling(0.2, 0.2, 0.2):mulTranslationRight(-footdiff.x, -footdiff.y, -footdiff.z)
					self.pfxs['run_smoke_01.pfx'] = m.pfxPlayer:play('run_smoke_01.pfx', mat) -- TODO. Add an invisible submesh to play pfx
				end

				Global.Sound:play3D('run_smoke', r:getPosition_const(), min, max)
				if name == 'run1' then
					Global.Sound:play3D('anima_step01', r:getPosition_const(), min, max)
				elseif name == 'run2' then
					Global.Sound:play3D('anima_step01', r:getPosition_const(), min, max)
				end
			end
		end, false)
	end

	for k, a in next, r.animas do
		local e = Global.AnimationCfg[k].emoji
		if e and not a.emoji_setted then
			a.graEvent:addTag(e.name, e.tick / a.duration)
			a:onEvent(function(name)
				if name == e.name then
					-- print(name)
					r:applyFacialExpression(name)
				end
			end, false)
			a.emoji_setted = true
		end
	end
end
MainBody.xl_setupAnima = function(self)
	local animation_cfg = Global.AnimationCfg
	self.host.animas = {}
	local as = self.host.animas
	for k, v in next, animation_cfg do
		local a
		if self.block then
			a = self.block:applyAnim(k, v.loop, nil, v.rootz)
		else
			a = self.mesh.skeleton:addAnima(v.res)
		end

		a.speed = v.speed or 1
		a.loop = v.loop
		if v.nextanima then
			a:onStop(function()
				self.host:playAnima(v.nextanima)
				if a.onend then
					a.onend()
				end
			end)
		end
		as[k] = a
	end

	self:bindAnimaEvents()
end

return MainBody