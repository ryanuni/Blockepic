------------------ PivotMat -------------------------
local PivotMat = {}
_G.PivotMat = PivotMat
PivotMat.typestr = 'PivotMat'

PivotMat.new = function(mat, pivot)
	local k = {}
	setmetatable(k, {__index = PivotMat})
	k.mat = _Matrix3D.new()
	if mat then
		k.mat:set(mat)
	end
	-- if mat then
	-- 	k.mat = mat
	-- else
	-- 	k.mat = _Matrix3D.new()
	-- end

	if pivot then
		k.pivot = _Vector3.new(pivot)
	end

	return k
end

-- PivotMat.lerp = function(m1, m2, factor, m0)

-- end
-- TODO:
PivotMat.diffFromTo = function(m1, m2, m0)
	if not m0 then m0 = PivotMat.new() end

	m0.mat:transformFromTo(m1.mat, m2.mat)
	if m2.pivot then
		m0.pivot = _Vector3.new()
		m2.mat:apply(m2.pivot, m0.pivot)
	end

	return m0
end

PivotMat.getMatrix = function(self)
	return self.mat
end

PivotMat.getPivot = function(self)
	return self.pivot
end

PivotMat.setPivot = function(self, pivot)
	if not pivot then self.pivot = nil end

	if not self.pivot then self.pivot = _Vector3.new() end
	self.pivot:set(pivot)
end

PivotMat.load = function(self, mat, pivot)
	self.mat = mat
	self.pivot = pivot
end

PivotMat.set = function(self, p)
	if p.typestr == '_Matrix3D' then
		self.mat:set(p)
		self.pivot = nil
	else
		self.mat:set(p.mat)
		if p.pivot then
			if not self.pivot then
				self.pivot = _Vector3.new()
			end
			self.pivot:set(p.pivot)
		else
			self.pivot = nil
		end
	end
end

PivotMat.move = function(self, x, y, z)
	self.mat:mulTranslationRight(x, y, z)
	if self.pivot then
		self.pivot.x = self.pivot.x + x
		self.pivot.y = self.pivot.y + y
		self.pivot.z = self.pivot.z + z
	end
end

PivotMat.formatMatrix = function(self)
	self.mat:formatMatrix()
end

PivotMat.tostring = function(self)
	local matstr = value2string(self.mat)
	if not self.pivot then
		local str = 'PivotMat.new(%s)'
		return string.format(str, matstr)
	end

	local pivotstr = value2string(self.pivot)
	local str = 'PivotMat.new(%s, %s)'
	return string.format(str, matstr, pivotstr)
end

PivotMat.md5 = function(self)
	local str = self:tostring()
	return _sys:md5(str)
end

------------------ LerpMaterail -------------------------
local LerpMaterial = {}
_G.LerpMaterial = LerpMaterial
LerpMaterial.typestr = 'LerpMaterial'

LerpMaterial.new = function(data)
	local k = {}
	setmetatable(k, {__index = LerpMaterial})
	k:set(data)

	return k
end

LerpMaterial.lerp = function(m1, m2, factor, m0)
	m0.roughness = m2.roughness
	m0.mtlmode = m2.mtlmode
	m0.material = m2.material
	m0.color = _Color.lerp(m1.color, m2.color, factor)
end

LerpMaterial.diffFromTo = function(m1, m2, m0)
	if not m0 then m0 = LerpMaterial.new() end

	m0.roughness = m2.roughness
	m0.mtlmode = m2.mtlmode
	m0.material = m2.material
	--m0.color = _Color.lerp(m1.color, m2.color, factor)
end

LerpMaterial.set = function(self, data)
	self.color = data and data.color and (type(data.color) == 'number' and data.color or data.color:toInt()) or _Color.White
	self.roughness = data and data.roughness or 1
	self.mtlmode = data and data.mtlmode or 1
	self.material = data and data.material or 1
end

LerpMaterial.saveToData = function(self, data)
	if not data then data = {} end
	data.color = self.color
	data.roughness = self.roughness
	data.mtlmode = self.mtlmode
	data.material = self.material

	return data
end

LerpMaterial.tostring = function(self)
	local str = 'LerpMaterial.new(%s)'
	local data = self:saveToData()
	return string.format(str, value2string(data))
end

LerpMaterial.md5 = function(self)
	local str = self:tostring()
	return _sys:md5(str)
end

------------------ PaintInfo -------------------------
local PaintInfo = {}
PaintInfo.typestr = 'PaintInfo'
_G.PaintInfo = PaintInfo

PaintInfo.new = function(data)
	local k = {}
	setmetatable(k, {__index = PaintInfo})

	k.resname = ''
	k.face = 1
	k.translation = _Vector3.new(0, 0, 0)
	k.scale = _Vector3.new(1, 1, 1)
	k.rotate = _Vector4.new(0, 0, 1, 0)

	k:set(data)

	return k
end

PaintInfo.lerp = function(m1, m2, factor, m0)
	m0:set(m2)

	-- if m2.resname ~= m1.resname or m2.face ~= m1.face then
	-- 	m0:set(m2)
	-- 	return
	-- end

	-- m0.resname = m2.resname
	-- m0.face = m2.face
	-- _Vector3.lerp(m1.translation, m2.translation, factor, m0.translation)
	-- _Vector3.lerp(m1.scale, m2.scale, factor, m0.scale)
	-- _Vector3.lerp(m1.rotate, m2.rotate, factor, m0.rotate)
end

PaintInfo.set = function(self, data)
	self.resname = data and data.resname or ''
	self.face = data and data.face or 1
	if data and data.translation then
		self.translation:set(data.translation)
	else
		self.translation:set(0, 0, 0)
	end

	if data and data.scale then
		self.scale:set(data.scale)
	else
		self.scale:set(1, 1, 1)
	end

	if data and data.rotate then
		self.rotate:set(data.rotate)
	else
		self.rotate:set(0, 0, 1, 0)
	end
end

PaintInfo.setPaintRes = function(self, res, face, bindmat)
	self.resname = res

	if face then
		self.face = face
	elseif bindmat then
		self.face = Global.getRotaionAxisType(Global.AXISTYPE.Z, bindmat)
	end
end

PaintInfo.movePaint = function(self, dir, step, bindmat)
	local axis = Global.typeToAxis(Global.dir2AxisType(dir, Global.AXISTYPE.Z))
	local stepvec = axis:mul(step)

	if bindmat then
		Global.getRotaionAxisInverse(stepvec, bindmat, stepvec)
	end

	_Vector3.add(self.translation, stepvec, self.translation)
end

PaintInfo.rotatePaint = function(self, r, bindmat)
	local face = self.face
	local axis = Global.typeToAxis(Global.AXISTYPE.Z)
	if bindmat then
		Global.getRotaionAxisInverse(axis, bindmat, axis)
	end

	local m = axis.x + axis.y + axis.z
	if face == Global.AXISTYPE.Y or face == Global.AXISTYPE.NY then m = -m end
	if m < 0 then r = -r end
	local curr = self.rotate.w - r
	self.rotate:set(axis, curr)
end

PaintInfo.scalePaint = function(self, scale)
	local face = self.face
	if face == Global.AXISTYPE.X or face == Global.AXISTYPE.NX then
		self.scale:set(1, scale, scale)
	elseif face == Global.AXISTYPE.Y or face == Global.AXISTYPE.NY then
		self.scale:set(scale, 1, scale)
	elseif face == Global.AXISTYPE.Z or face == Global.AXISTYPE.NZ then
		self.scale:set(scale, scale, 1)
	end
end

PaintInfo.saveToData = function(self, data)
	if not data then data = {} end
	data.resname = self.resname
	data.face = self.face

	data.translation = _Vector3.new(0, 0, 0)
	data.scale = _Vector3.new(1, 1, 1)
	data.rotate = _Vector4.new(0, 0, 1, 0)
	data.translation:set(self.translation)
	data.scale:set(self.scale)
	data.rotate:set(self.rotate)

	return data
end

PaintInfo.tostring = function(self)
	local str = 'PaintInfo.new(%s)'
	local data = self:saveToData()
	return string.format(str, value2string(data))
end

PaintInfo.md5 = function(self)
	if self.resname == '' then return 0 end

	local str = self:tostring()
	return _sys:md5(str)
end

-----------------------------------------------
local DiffValue = {}
DiffValue.typestr = 'DiffValue'
_G.DiffValue = DiffValue

-----------------------------------------------
Global.fvalueType = function(value)
	local isobject = type(value) == 'table' or type(value) == 'userdata'
	if isobject then
		return value.typestr, true
	else
		return type(value), false
	end
end
------------------ Translation -------------------------
local DfFrame = {}
_G.DfFrame = DfFrame

DfFrame.new = function(data)
	local f = {}
	setmetatable(f, {__index = DfFrame})

	f.time = data.time
	f.istween = data.istween

	local ftype = Global.fvalueType(data.value)
	if ftype == '_Matrix3D' then
		data.value:updateTransformValue()
		f.value = PivotMat.new(data.value)
	else
		f.value = data.value
		if ftype == 'PivotMat' then
			local mat = f.value:getMatrix()
			mat:updateTransformValue()
		end
	end

	return f
end

DfFrame.saveToData = function(self, data, center)
	if not data then data = {} end
	data.time = self.time
	data.istween = self.istween

	local ftype = Global.fvalueType(data.value)
	if (ftype == '_Matrix3D' or ftype == 'PivotMat') and center then
		local m = PivotMat.new()
		m:set(self.value)
		m:move(-center.x, -center.y, -center.z)
		m:formatMatrix()
		data.value = m
	else
		data.value = self.value
	end

	return data
end

DfFrame.tostring = function(self)
	-- local str = 'DfFrame.new(%s)'
	local str = '%s'
	local data = self:saveToData()
	return string.format(str, value2string(data))
end

------------------ Translation -------------------------
local DfTransition = {}
_G.DfTransition = DfTransition

DfTransition.new = function(data, bind, gs)
	local t = {}
	setmetatable(t, {__index = DfTransition})

	t.groupindex = data.group

	t.bind = bind
	if bind then
		t.group = bind:getSubGroup(data.group)
	elseif gs then
		t.group = gs[data.group]
	else
		t.group = data.group
	end

	t.attr = data.attr
	-- t.pivot = data.pivot
	-- t.localcenter = data.localcenter
	-- t.duration = data.duration
	-- if t.localcenter then
	-- 	local pivot = _Vector3.new()
	-- 	t.group:getCenter(pivot)
	-- 	t.group:setPivot(pivot)
	-- end

	t.frames = {}

	if data.frames then
		for i, v in ipairs(data.frames) do
			local f = DfFrame.new(v)
			table.insert(t.frames, f)
		end
	end
	table.sort(t.frames, function(a, b)
		return a.time < b.time
	end)

	if #t.frames > 0 then
		t.mintime = t.frames[1].time
		t.maxtime = t.frames[#t.frames].time
	end

	-- 设置初始化矩阵
	if t.attr == 'transformDiff' then
		local mats = t.group:getInitTransforms()
		local ab = t.group:getAABB()
		local pivot = _Vector3.new()
		ab:getCenter(pivot)
		t:initGroupMatrix(mats, pivot)
		--t:initGroupMatrix(mats)
	end

	return t
end

DfTransition.initGroupMatrix = function(self, mats, pivot)
	self.mats = mats
	self.pivot = pivot
end

DfTransition.beginBind = function(self)
	if self.isbinding then return end

	-- TODO:
	if self.attr == 'transformDiff' then
		local g = self.group
		g:bindTransforms(self.mats, self.pivot)
	end

	self.isbinding = true
end

DfTransition.endBind = function(self)
	if not self.isbinding then return end
	self.isbinding = false

	if self.attr == 'transformDiff' then
		self.group:unbindTransforms()
	end
end

DfTransition.refreshGroup = function(self)
	if self.bind then
		self.group = self.bind:getSubGroup(self.groupindex)
		-- if self.localcenter then
		-- 	local pivot = _Vector3.new()
		-- 	self.group:getCenter(pivot)
		-- 	self.group:setPivot(pivot)
		-- end
	end
end

DfTransition.getDuration = function(self)
	if self.duration then return self.duration end

	local f = self.frames[#self.frames]
	return f and f.time or 0
end

DfTransition.getKeyFrame = function(self, tick)
	for _, f in ipairs(self.frames) do
		if f.time == tick then
			return f
		end
	end
end

DfTransition.getLerpKeyFrames = function(self, tick)
	for i, f in ipairs(self.frames) do
		local nf = self.frames[i + 1]
		if f.time <= tick and (not nf or nf.time > tick) then
			local lerp = nf and (tick - f.time) / (nf.time - f.time) or 0
			return f, nf, lerp
		end
	end
end

local helpvec = _Vector3.new()
local helpmat = _Matrix3D.new()
local helpmat2 = _Matrix3D.new()
local helpPMat = PivotMat.new()
local helpLMtl = LerpMaterial.new()

local helpscale = _Vector3.new()
local helprot = _Vector3.new()
local helptranslation = _Vector3.new()
DfTransition.getFrameValue = function(self, tick)
	local f = self:getKeyFrame(tick)
	if f then
		return f.value
	else
		local cf, nf, lerp = self:getLerpKeyFrames(tick)
		if not cf then
			assert(false)
		elseif cf then
			if not cf.istween or not nf then
				return cf.value
			else
				if type(cf.value) == 'number' then
					return math.lerp(cf.value, nf.value, lerp, 'float'), lerp, cf.value, nf.value
				elseif cf.value.typestr == '_Vector3' then
					_Vector3.lerp(cf.value, nf.value, lerp, helpvec)
					return helpvec, lerp, cf.value, nf.value
				elseif cf.value.typestr == '_Matrix3D' then
					_Matrix3D.lerp(cf.value, nf.value, lerp, helpmat)
					return helpmat
				elseif cf.value.typestr == 'LerpMaterial' then
					LerpMaterial.lerp(cf.value, nf.value, lerp, helpLMtl)
					return helpLMtl
				elseif cf.value.typestr == 'PaintInfo' then
					--PaintInfo.lerp(cf.value, nf.value, lerp, helpPaint)
					--return helpPaint
					return nf.value
				elseif cf.value.typestr == 'PivotMat' then
					local mat1 = cf.value:getMatrix()
					local mat2 = nf.value:getMatrix()
					local pivot = nf.value:getPivot()

					if self.attr == 'transformDiff' then
						-- if Global.UseCMatrixMath then
							_Matrix3D.lerp(mat1, mat2, lerp, helpmat)
						-- else
						-- 	local rx1, rx2 = mat1.rotationP, mat2.rotationP
						-- 	local ry1, ry2 = mat1.rotationH, mat2.rotationH
						-- 	local rz1, rz2 = mat1.rotationB, mat2.rotationB

						-- 	local tx = math.lerp(mat1.translationX, mat2.translationX, lerp, 'float')
						-- 	local ty = math.lerp(mat1.translationY, mat2.translationY, lerp, 'float')
						-- 	local tz = math.lerp(mat1.translationZ, mat2.translationZ, lerp, 'float')

						-- 	local sx = math.lerp(mat1.scaleX, mat2.scaleX, lerp, 'float')
						-- 	local sy = math.lerp(mat1.scaleY, mat2.scaleY, lerp, 'float')
						-- 	local sz = math.lerp(mat1.scaleZ, mat2.scaleZ, lerp, 'float')

						-- 	-- 需要对旋转插值
						-- 	if rx1 ~= rx2 or ry1 ~= ry2 or rz1 ~= rz2 then
						-- 		helpmat:setTransformData(0, 0, 0, rx1, ry1, rz1, 1, 1, 1)
						-- 		helpmat2:setTransformData(0, 0, 0, rx2, ry2, rz2, 1, 1, 1)
						-- 		_Matrix3D.lerp(helpmat, helpmat2, lerp, helpmat)
						-- 		helpmat:updateTransformValue()
						-- 		local rx, ry, rz = helpmat.rotationP, helpmat.rotationH, helpmat.rotationB

						-- 		helpmat:setTransformData(tx, ty, tz, rx, ry, rz, sx, sy, sz)
						-- 		--helpmat:setTransformData(tx, ty, tz, rx1, ry1, rz1, sx, sy, sz)
						-- 	else
						-- 		helpmat:setTransformData(tx, ty, tz, rx1, ry1, rz1, sx, sy, sz)
						-- 	end
						-- end

						-- print('pivot', pivot, nf.value:tostring())
						if pivot then
							helpPMat:load(helpmat, pivot)
							return helpPMat
						else
							return helpmat
						end
					else
						if not pivot and not mat1:hasMirror() then
							_Matrix3D.lerp(mat1, mat2, lerp, helpmat)
							return helpmat
						else
							helpmat:transformFromTo(mat1, mat2)
							helpmat:decomposeWithPivot(pivot, helpscale, helprot, helptranslation)

							helpmat:composeWithPivotLerp(lerp, pivot, helpscale, helprot, helptranslation)
							helpmat:mulLeft(mat1)
						end

						return helpmat
					end
				end
			end
		end
	end
end

DfTransition.setTick = function(self, tick, pause)
	if not self.mintime or not self.maxtime then return end
	if tick < self.mintime or tick > self.maxtime then return end

	self:beginBind()

	local value, lerp, cvalue, nvalue = self:getFrameValue(tick)
	local attr = self.attr
	--print('DfTransition.setTick', tick, value, attr)
	if attr == 'translation' then
		-- self.group:changeTranslation(value)
	elseif attr == 'scale' then
		-- self.group:changeScale(value)
	elseif attr == 'rotation' then
		-- self.group:changeRotation(value)
	elseif attr == 'invisible' then
		self.group:changeInvisible(value)
		self.group:setPhysicEnable(not value)
	elseif attr == 'alpha' then
		self.group:changeAlpha(value)
		if not lerp or lerp == 0 then
			self.group:setPhysicEnable(value ~= 0)
		elseif nvalue then
			self.group:setPhysicEnable(nvalue ~= 0)
		end
	elseif attr == 'transform' then
		self.group:changeTransform(value)
	elseif attr == 'transformDiff' then
		self.group:changeTransformDiff(value)
	elseif attr == 'material' then
		self.group:changeMaterial(value)
	elseif attr == 'paint' then
		self.group:changePaint(value)
	end

	if pause then self:endBind() end
end

DfTransition.reset = function(self)
	self:setTick(0, true)
end

DfTransition.saveToData = function(self, data, center)
	if not data then data = {} end
	data.group = self.group.index
	data.attr = self.attr
	-- data.duration = self.duration
	-- data.localcenter = self.localcenter
	data.frames = {}
	if self.pivot then
		data.pivot = _Vector3.new(self.pivot.x, self.pivot.y, self.pivot.z)
	end

	for _, f in ipairs(self.frames) do
		local fdata = {}
		f:saveToData(fdata, self.attr == 'transform' and center)
		table.insert(data.frames, fdata)
	end

	return data
end

DfTransition.tostring = function(self)
	-- local str = 'DfTransition.new(%s)'
	local data = self:saveToData()
	--return string.format(str, value2string(data))
	return value2string(data)
end

------------------ DynamicEffect ------------------------

Global.hasDynamicEffect = function(df)
	if df and df.transitions and #df.transitions > 0 then
		local t0 = df.transitions[1]
		if not t0 or not t0.frames then return false end
		return #t0.frames > 1
	end

	return false
end

Global.isDynamicEffectAuto = function(df)
	if not Global.hasDynamicEffect(df) then return false end
	return not df.actions or not next(df.actions)
end

local DynamicEffect = {}
_G.DynamicEffect = DynamicEffect

DynamicEffect.new = function(data, bind, gs)
	local df = {}
	setmetatable(df, {__index = DynamicEffect})

	df.name = data and data.name or ''
	df.transitions = {}

	-- 动画控制数据
	df.maxDuration = 0
	df.currentTick = 0
	df.speed = 1
	df.stopUntilEnd = false
	df.isplaying = false
	df.bind = bind

	if data and data.transitions then
		for i, v in ipairs(data.transitions) do
			if v.group then
				local t = DfTransition.new(v, bind, gs)
				table.insert(df.transitions, t)

				df.maxDuration = math.max(df.maxDuration, t:getDuration())
			end
		end
	end

	if data and data.actions then
		df:setActions(data.actions)
	end

	return df
end

DynamicEffect.getDuration = function(self)
	return self.maxDuration
end

DynamicEffect.setDuration = function(self, duration)
	self.maxDuration = duration
end

DynamicEffect.setTransitions = function(self, ts)
	self.transitions = {}
	for i, t in ipairs(ts) do
		table.insert(self.transitions, t)
		self.maxDuration = math.max(self.maxDuration, t:getDuration())
	end
end

DynamicEffect.getTransitions = function(self)
	return self.transitions
end

DynamicEffect.setActions = function(self, actions)
	self.actions = actions
end

DynamicEffect.refreshGroup = function(self)
	for i, t in ipairs(self.transitions) do
		t:refreshGroup(self.bind)
	end
end

DynamicEffect.getName = function(self)
	return self.name
end

DynamicEffect.setTick = function(self, tick, pause)

	local block = self.bind and self.bind.typestr == 'block' and self.bind
	if block then block:skipRefreshSceneNode(true) end

	for i, t in ipairs(self.transitions) do
		t:setTick(tick, pause)
	end

	if block then block:skipRefreshSceneNode(false) end

	self.currentTick = tick
end

DynamicEffect.setSpeed = function(self, speed)
	self.speed = speed
end

-- 播放/暂定
DynamicEffect.play = function(self, action, inverse, onstopcallback)
	self.isplaying = true

	self.timeStart, self.timeEnd = nil, nil
	self.isLoop = true
	self.inverse = inverse
	self.onstopcallback = onstopcallback

	--print('onstopcallback', onstopcallback)
	if action and self.actions and self.actions[action] then
		local a = self.actions[action]
		self.timeStart = a.timeStart
		self.timeEnd = a.timeEnd
		self.isLoop = a.isloop
		-- self.currentTick = a.timeStart
	end

	if inverse then
		self.currentTick = self.maxDuration
	end
end

DynamicEffect.isPlaying = function(self)
	return self.isplaying
end

DynamicEffect.pause = function(self)
	self.isplaying = false
end

DynamicEffect.stop = function(self, stopuntilend)
	if stopuntilend and self.isplaying then
		self.stopUntilEnd = true
		return
	end

	local block = self.bind and self.bind.typestr == 'block' and self.bind
	if block then block:skipRefreshSceneNode(true) end

	-- group 复位
	for i, t in ipairs(self.transitions) do
		t:reset()
	end

	if block then block:skipRefreshSceneNode(false) end

	self.stopUntilEnd = false
	self.isplaying = false
	self.currentTick = 0

	if self.onstopcallback then
		--print('DynamicEffect.stop', debug.traceback())
		self.onstopcallback()
		self.onstopcallback = nil
	end
end

DynamicEffect.update = function(self, e)
	if not self.isplaying or self.speed == 0 then return end
	local timestart, timeend = self.timeStart or 0, self.timeEnd or self.maxDuration
	local duration = self.maxDuration
	local loop = self.isLoop

	if duration == 0 then
		self:setTick(timestart, true)
		self:pause()
		return
	end

	if self.inverse then
		local ctick = self.currentTick - e * self.speed
		if self.stopUntilEnd or not loop then
			if ctick <= timestart then
				self:setTick(timestart, true)
				if self.stopUntilEnd then
					self:stop()
				else
					self:pause()
				end
				return
			end
		end

		if ctick > timeend then
			self:setTick(timeend)
			return
		end

		local t0 = (ctick - timestart) % duration
		if t0 < 0 then t0 = t0 + duration end
		self:setTick(t0 + timestart)
	else
		local ctick = self.currentTick + e * self.speed
		if self.stopUntilEnd or not loop then
			if ctick >= timeend then
				self:setTick(timeend, true)
				if self.stopUntilEnd then
					self:stop()
				else
					self:pause()
				end
				return
			end
		end

		if ctick < timestart then
			self:setTick(timestart)
			return
		end

		local t0 = (ctick - timestart) % duration
		self:setTick(t0 + timestart)
	end
end

DynamicEffect.saveToData = function(self, data, center)
	if not data then data = {} end
	data.name = self.name

	print('#saveToData', #self.transitions)
	data.transitions = {}
	for _, t in ipairs(self.transitions) do
		local tdata = {}
		t:saveToData(tdata, center)
		table.insert(data.transitions, tdata)
	end

	if self.actions and next(self.actions) then
		data.actions = self.actions
	else
		data.actions = nil
	end

	return data
end

DynamicEffect.tostring = function(self)
	-- local str = 'DynamicEffect.new(%s)'
	local data = self:saveToData()
	--return string.format(str, value2string(data))
	return value2string(data)
end
