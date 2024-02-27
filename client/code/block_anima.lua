local Container = _require('Container')

--local skls = _dofile'cfg_skl.lua'
local skls = {
	dragon = {skl = 'Y_long.skl', anims = {idle = 'Y_long_idle.san', run = 'Y_long_run.san'}},
	--human = {skl = 'y_tosp_guge02.skl', anims = {idle = 'y_tosp_guge02_ceshi.san'}},
	-- human = {skl = 'y_cha_kong.skl', anims = {idle = 'y_cha_kong_idle.san', run = 'y_cha_kong_run.san', attack = 'y_cha_kong_atc01.san', dance = 'y_cha_kong_dance.san'}},
	human = {
		skl = 'cha_gangtiexia_02.skl',
		anims = {-- 与AnimationCfg对应，可以自定义
			-- idle = 'cha_gangtiexia_01_idle.san',
			-- idle = false,
		},
	},

	box = {
		skl = 'box_open.skl',
		anims = {
			idle1 = 'box_open_idle01.san',
			idle2 = 'box_open_idle02.san',
			emo = 'box_open_emo.san',
		},
	},
}

for name, v in pairs(skls) do
	local skl = _Skeleton.new(v.skl)
	v.bonenames = skl:getBones()
end

for k, v in next, Global.AnimationCfg do
	if skls.human.anims[k] == nil then
		skls.human.anims[k] = v.res
	end
end

_G.cfg_skls = skls

Global.AnimIdle = 'idle'

-- 0xff00f1ff
-- 0xff004bed
-- 0xff5e00fc

-- 0xff60f014
-- 0xffb40101

-- 0xff05622a
-- 0xff089d26
-- 0xff423813

-- 0xff9c6421
local partData = {
	human = {
		parts = {
			-- palign 当前部位的连接点相对父的位置, jointalign 当前部位相对与连接点的位置
			head = {bones = {'bip001 head', 'bip001 neck'}, jointalign = 'cb', parents = {'chest', 'waist'}, parent = 'chest', palign = 'ct', color = '0xffb40101', itemid = 'body_head'},
			chest = {bones = {'bip001 spine', 'bip001 l clavicle', 'bip001 r clavicle'}, jointalign = 'cb', parents = {'waist'}, parent = 'waist', palign = 'ct', color = '0xff423813', itemid = 'body_chest'},
			waist = {bones = {'bip001 pelvis'}, jointalign = 'cm', parents = {}, parent = nil, color = '0xff9c6421', itemid = 'body_waist'},

			l_upperarm = {bones = {'bip001 l upperarm'}, jointalign = 'rt', parents = {'chest', 'waist'}, parent = 'chest', palign = 'lt', color = '0xff05622a', itemid = 'body_upperarm'},
			l_forearm = {bones = {'bip001 l forearm'}, jointalign = 'ct', parents = {'l_upperarm'}, parent = 'l_upperarm', palign = 'cb', color = '0xff089d26', itemid = 'body_forearm'},
			l_hand = {bones = {'bip001 l hand'}, jointalign = 'ct', parents = {'l_forearm'}, parent = 'l_forearm', palign = 'cb', color = '0xff60f014', itemid = 'body_hand'},

			r_upperarm = {bones = {'bip001 r upperarm'}, jointalign = 'lt', parents = {'chest', 'waist'}, parent = 'chest', palign = 'rt', color = '0xff05622a', itemid = 'body_upperarm'},
			r_forearm = {bones = {'bip001 r forearm'}, jointalign = 'ct', parents = {'r_upperarm'}, parent = 'r_upperarm', palign = 'cb', color = '0xff089d26', itemid = 'body_forearm'},
			r_hand = {bones = {'bip001 r hand'}, jointalign = 'ct', parents = {'r_forearm'}, parent = 'r_forearm', palign = 'cb', color = '0xff60f014', itemid = 'body_hand'},

			l_thing = {bones = {'bip001 l thigh'}, jointalign = 'ct', parents = {'waist', 'chest'}, parent = 'waist', palign = 'lb', color = '0xff00f1ff', itemid = 'body_thigh'},
			l_calf = {bones = {'bip001 l calf'}, jointalign = 'ct', parents = {'l_thing'}, parent = 'l_thing', palign = 'cb', color = '0xff004bed', itemid = 'body_calf'},
			l_foot = {bones = {'bip001 l foot'}, jointalign = 'ct', parents = {'l_calf'}, parent = 'l_calf', palign = 'cb', color = '0xff5e00fc', itemid = 'body_foot'},

			r_thing = {bones = {'bip001 r thigh'}, jointalign = 'ct', parents = {'waist', 'chest'}, parent = 'waist', palign = 'rb', color = '0xff00f1ff', itemid = 'body_thigh'},
			r_calf = {bones = {'bip001 r calf'}, jointalign = 'ct', parents = {'r_thing'}, parent = 'r_thing', palign = 'cb', color = '0xff004bed', itemid = 'body_calf'},
			r_foot = {bones = {'bip001 r foot'}, jointalign = 'ct', parents = {'r_calf'}, parent = 'r_calf', palign = 'cb', color = '0xff5e00fc', itemid = 'body_foot'},
		},
		orders = {'waist', 'chest', 'head', 'l_upperarm', 'l_forearm', 'l_hand', 'r_upperarm', 'r_forearm', 'r_hand',
			'l_thing', 'l_calf', 'l_foot', 'r_thing', 'r_calf', 'r_foot'}
	},
	box = {
		parts = {
			-- palign 当前部位的连接点相对父的位置, jointalign 当前部位相对与连接点的位置
			l_hand = {bones = {'l'}, jointalign = 'lb', parents = {}, parent = nil, palign = 'cb', color = '0xffffffff', itemid = 'body_hand'},
			r_hand = {bones = {'r'}, jointalign = 'rb', parents = {}, parent = nil, palign = 'cb', color = '0xff60f014', itemid = 'body_hand'},
		},
		orders = {'l_hand', 'r_hand'}
	}
}
--_G.cfg_part = parts

-- 骨骼的获取的mat与其他mat属性不一样
local bonemats = {}
local function getBoneMat()
	if #bonemats > 0 then
		local mat = bonemats[#bonemats]
		table.remove(bonemats, #bonemats)

		mat:inverse()
		return mat
	else
		return _Matrix3D.new()
	end
end
local function returnBoneMat(mat)
	table.insert(bonemats, mat)
end

local Part = {}
Part.addmeshes = {}
_G.Part = Part

Part.getJointPos = function(ab, align, ds)
	local center = Container:get(_Vector3)
	ab:getCenter(center)
	ds = ds or 0
	--ds = 0

	local x, y, z = 0, 0, 0
	if align == 'cb' then
		x, y, z = center.x, center.y, ab.min.z - ds
	elseif align == 'cm' then --cm
		x, y, z = center.x, center.y, center.z
	elseif align == 'ct' then
		x, y, z = center.x, center.y, ab.max.z + ds
	elseif align == 'rt' then
		x, y, z = ab.max.x + ds, center.y, ab.max.z + ds
	elseif align == 'lt' then
		x, y, z = ab.min.x - ds, center.y, ab.max.z + ds
	elseif align == 'rb' then
		x, y, z = ab.max.x + ds, center.y, ab.min.z - ds
	elseif align == 'lb' then
		x, y, z = ab.min.x - ds, center.y, ab.min.z - ds
	else
		assert(false)
	end

	Container:returnBack(center)

	return x, y, z
end

Part.getBoxCenterAlignJoint = function(ab, align, jpos)
	local size = Container:get(_Vector3)
	ab:getSize(size)
	_Vector3.mul(size, 0.5, size)

	local cx, cy, cz = 0, 0, 0
	if align == 'ct' then
		cx, cy, cz = jpos.x, jpos.y, jpos.z - size.z
	elseif align == 'cm' then
		cx, cy, cz = jpos.x, jpos.y, jpos.z
	elseif align == 'cb' then
		cx, cy, cz = jpos.x, jpos.y, jpos.z + size.z
	elseif align == 'lt' then
		cx, cy, cz = jpos.x + size.x, jpos.y, jpos.z - size.z
	elseif align == 'rt' then
		cx, cy, cz = jpos.x - size.x, jpos.y, jpos.z - size.z
	elseif align == 'lb' then
		cx, cy, cz = jpos.x + size.x, jpos.y, jpos.z + size.z
	elseif align == 'rb' then
		cx, cy, cz = jpos.x - size.x, jpos.y, jpos.z + size.z
	else
		assert(false, align)
	end

	Container:returnBack(size)
	return cx, cy, cz
end

Part.addMesh = function(type)
	if Part.addmeshes[type] then return end
	Part.addmeshes[type] = true

	local pd = partData[type]

	local ab = Container:get(_AxisAlignedBox)
	local vec = Container:get(_Vector3)

	local minz = nil
	for i, name in ipairs(pd.orders) do
		local part = pd.parts[name]

		local mesh = Block.getBlockMesh(part.itemid)
		part.dummymsh = mesh

		if part.parent then
			local ppart = pd.parts[part.parent]
			ab:set(ppart.dummymsh:getBoundBox())
			-- 获取当前part绑定到父的位置
			local jx, jy, jz = Part.getJointPos(ab, part.palign, 0.04)

			-- 获取part应该在的中心位置
			vec:set(jx, jy, jz)
			ab:set(mesh:getBoundBox())
			local cx, cy, cz = Part.getBoxCenterAlignJoint(ab, part.jointalign, vec)

			ab:getCenter(vec)
			mesh.transform:mulTranslationRight(cx - vec.x, cy - vec.y, cz - vec.z)

			local z = ab.min.z + cz - vec.z
			minz = minz and math.min(z, minz) or z
		end
	end

	if minz then
		for i, name in ipairs(pd.orders) do
			local part = pd.parts[name]
			part.dummymsh.transform:mulTranslationRight(0, 0, -minz)
		end
	end

	Container:returnBack(ab, vec)
end

Part.getSubMesh = function(type, pname)
	Part.addMesh(type)

	local pd = partData[type]
	return pd and pd.parts[pname] and pd.parts[pname].dummymsh
end

Part.getPartData = function(type, pname)
	return partData[type]
end

----------------- animrole
local animRole = {}
animRole.typestr = 'animRole'

animRole.new = function()
	local role = {}
	role.bindinfo = {}
	role.animas = {}
	role.enableRoot = false
	setmetatable(role, {__index = animRole})
	return role
end

animRole.getRootbi = function(self)
	for i, part in ipairs(self.parts or {}) do
		local bi = self:getInfo(part)
		if bi.isroot then
			return bi
		end
	end
end

animRole.setEnableRoot = function(self, enable)
	self.enableRoot = enable
end

animRole.addPart = function(self, part)
	if not part then return end
	if not self.bindinfo[part] then
		self.bindinfo[part] = {
			res = {},
			slots = {},
		}
	end
end

animRole.getInfo = function(self, part)
--	assert(self.bindinfo[part], 'assert no part:' .. tostring(part))
	return self.bindinfo[part]
end

animRole.addSlot = function(self, part, slotdata)
	local bi = self:getInfo(part)
	for i, v in ipairs(bi.slots) do if v == slotdata then
		return
	end end

	bi.slots[#bi.slots + 1] = slotdata
	slotdata.parentpart = part
end

animRole.clearSlot = function(self, part)
	local bi = self:getInfo(part)
	bi.slots = {}
end

animRole.useSKlBone = function(self, part, bonename, slotdata, isroot)
	local bi = self:getInfo(part)
	bi.bonename = bonename
	bi.slotdata = slotdata
	bi.isroot = isroot
end

animRole.getSlotData = function(self, part)
	local bi = self:getInfo(part)
	if bi then return bi.slotdata end
end

animRole.clear = function(self)
	self:unbind()
	-- 回收mat
	for part, bi in pairs(self.bindinfo) do
		if bi.slotdata then
			bi.slotdata.mat.parent = nil
			Container:returnBack(bi.slotdata.mat)
			returnBoneMat(bi.res.bone)
			returnBoneMat(bi.res.parentbone)
		end
	end
	self.bindinfo = {}
end

animRole.refresh = function(self)
	if not skls[self.skltype] then return end

	self.parts = {}
	local names = skls[self.skltype].bonenames
	for i, v in ipairs(names) do
		for p, bi in next, self.bindinfo do
			if bi.bonename == v then
				table.insert(self.parts, p)
			end
		end
	end

	for i, part in ipairs(self.parts) do
		self:refreshPart(part)
	end

	local v3_1 = Container:get(_Vector3)
	local v4_1 = Container:get(_Vector4)

	-- 校正骨骼方向
	for i, part in ipairs(self.parts) do
		local bi = self:getInfo(part)

		bi.res.bone:getRotation(v4_1)
		local slotmat = bi.slotdata.mat
		slotmat:getTranslation(v3_1)
		slotmat.parent = nil
		slotmat:setRotation(v4_1)
		slotmat:mulTranslationRight(v3_1)
	end
	Container:returnBack(v3_1, v4_1)

	-- 重新绑定用于动画更新的父子关系
	for i, part in ipairs(self.parts) do
		local bi = self:getInfo(part)
		local ppart = bi.slotdata and bi.slotdata.parentpart
		local slotmat = bi.slotdata.mat
		if slotmat then slotmat:unbindParent() end
		if ppart then
			local pbi = self:getInfo(ppart)
			if pbi and pbi.slotdata then
				slotmat:bindParent(pbi.slotdata.mat)
			end
		end

		part.transform:bindParent(slotmat)
	end
end

animRole.refreshPart = function(self, part)
	if not self.skl then return end

	local bi = self:getInfo(part)
	bi.res.bone = getBoneMat()
	self.skl:getBone(bi.bonename, bi.res.bone)

	local pbn = self.skl:getParentBone(bi.bonename)
	bi.res.parentbone = getBoneMat()
	self.skl:getBone(pbn, bi.res.parentbone)

	--bi.res.animas = {}

	part.oldtransform = part.transform
	part.transform = _Matrix3D.new()
	--part.transform:identity()

	-- 计算位移的比值
	if bi.isroot then
		self.rootVec = _Vector3.new()
		bi.res.bone:getTranslation(self.rootVec)

		self.rootOffset = _Vector3.new()
		bi.slotdata.mat:getTranslation(self.rootOffset)
	end
end

animRole.bindSkl = function(self, skltype)
	self.skltype = skltype
	local sklname = skls[self.skltype] and skls[self.skltype].skl
	if not sklname then
		self.skl = nil
		self.animas = {}
		return
	end

	self.skl = _Skeleton.new(sklname)
	self.animas = {}
end

animRole.setRootz = function(self, z)
	self.rootZ = z
end

animRole.useAnima = function(self, anima, loop, useroot)
	if not self.skl then return end

	if not self.animas[anima] then
		local animname = skls[self.skltype].anims[anima]
		self.animas[anima] = animname and self.skl:addAnima(animname)
	end

	local san = self.animas[anima]
	if san then
		san.enableRoot = useroot
		if loop == nil then 
			local cfg = Global.AnimationCfg[anima]
			loop = cfg and cfg.loop
		end
		san.loop = loop
	end

	return san
end

animRole.playAnim = function(self, anima, autoidle)
	if not self.skl then return end
	local san = self.animas[anima]

	if not san then return end
	for i, v in pairs(self.animas) do
		v:stop()
	end
	--print('playAnim', animRole, anima, san, san.loop, san.current, san.pause)

	-- 切换动画时初始化位移
	if self.rootOffset then
		local bi = self:getRootbi()
		local slotmat = bi.slotdata.mat
		local vec = Container:get(_Vector3)
		slotmat:getTranslation(vec)
		_Vector3.sub(self.rootOffset, vec, vec)
		slotmat:mulTranslationRight(vec)
		Container:returnBack(vec)
	end
	self:setEnableRoot(san.enableRoot)

	san:play()
	self.updating = true
	self.playSan = san

	self.autoidle = autoidle

	return san
end

animRole.stopAnim = function(self)
	if not self.skl then return end
	if not self.animas then return end
	for _, san in pairs(self.animas) do
		san:stop()
	end

	self:update()
	self.updating = false
	self.playSan = nil
end

animRole.pauseAnim = function(self)
	if not self.skl then return end
	if not self.playSan then return end

	self.playSan.pause = true
	self.updating = false
end

animRole.seek = function(self, anima, t, play)
	if not self.skl then return end
	local san = self.animas[anima]
	if not san then return end

	local san = self:playAnim(anima)
	san:seek(t)
	san:forceUpdate()
	self:update()

	san.pause = not play
	self.updating = play
end

animRole.unbind = function(self)
	self:stopAnim()
	for part, bi in pairs(self.bindinfo) do
		part.transform.parent = nil
		part.transform = part.oldtransform
		part.oldtransform = nil
	end
end

animRole.update = function(self, part)
	--if not self.bindsklname then return end
	if not part then
		for i, part in ipairs(self.parts or {}) do
			self:update(part)
		end
		return
	end

	local bi = self:getInfo(part)
	if not bi.res.bone then return end

	local slotmat = bi.slotdata.mat
	local ppart = bi.slotdata.parentpart

	local rot = Container:get(_Vector4)
	local vec = Container:get(_Vector3)

	local pslot = slotmat.parent
	slotmat:unbindParent()

	slotmat:getTranslation(vec)

	local vec2 = Container:get(_Vector3)
	_Vector3.mul(vec, -1, vec2)
	slotmat:mulTranslationRight(vec2)

	slotmat:getRotation(rot)
	slotmat:mulRotationRight(rot.x, rot.y, rot.z, -rot.w)

	bi.res.bone:getRotation(rot)
	slotmat:mulRotationRight(rot.x, rot.y, rot.z, rot.w)

	if bi.isroot and self.enableRoot then
		-- 带有位移时每帧重新计算位移并乘以缩放
		bi.res.bone:getTranslation(vec2)
		_Vector3.sub(vec2, self.rootVec, vec2)
		local rate = self.rootZ / self.rootVec.z
		_Vector3.mul(vec2, rate, vec2)
		_Vector3.add(vec2, self.rootOffset, vec2)
		slotmat:mulTranslationRight(vec2)
	else
		slotmat:mulTranslationRight(vec)
	end

	if pslot then slotmat:bindParent(pslot) end

	Container:returnBack(rot, vec, vec2)

	if self.playSan and not self.playSan.isPlaying then
		if self.autoidle then
			self:useAnima(Global.AnimIdle, true)
			self:playAnim(Global.AnimIdle)
		else
			self.updating = false
		end
	end
end

animRole.draw = function(self, part)
	if self.skl then
		self.skl:drawSkeleton(0.02)
	end
end

local AM = {
	bindroles = {},

	addRole = function(self, role)
		if not self.bindroles.role then
			self.bindroles[role] = animRole.new()
		end

		return self.bindroles[role]
	end,

	getRole = function(self, role)
		return self.bindroles[role]
	end,

	delRole = function(self, role)
		if self.bindroles[role] then
			self.bindroles[role]:clear()
		end
		self.bindroles[role] = nil
	end,

	update = function(self)
		for b, r in pairs(self.bindroles) do
			if r.updating then
				local n = b.node
				if n then
					-- 暂时取消mesh与node的关系，节省更新node的时间
					_rd.forceSkipRefreshSceneNode = true
				end
				r:update()
				if n then
					_rd.forceSkipRefreshSceneNode = false
					if n.mesh then
						n.mesh:refreshSceneNodeTransform()
					end
				end
			end
		end
	end,
}

Global.AnimationManager = AM