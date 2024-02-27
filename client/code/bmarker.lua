local SoundGroup = _require('SoundGroup')
local BMarkers = {}
Global.BMarkers = BMarkers

BMarkers.type2shape = {
	rot_circle = 'rotdummy_797',
	rot_bar = 'rotdummy_389',
	camera = 'newcamera',
	copybox = 'copybox',
	marker_start = 'location_enter',
	marker_exit = 'location_exit',
	-- marker_obj = 'location_obj',
	marker_blocks = 'locationnew',
	xfxs = 'xfx_obj',
	marker_train = 'marker_train',
	marker_shapeProbe = 'marker_shapeProbe',
}

BMarkers.shape2type = {}
for k, v in pairs(BMarkers.type2shape) do
	BMarkers.shape2type[v] = k
end

-------------- BMarker
local BMarker = {}
BMarker.typestr = 'BMarker'
_G.BMarker = BMarker

-- type: rot_circle, rot_bar, copybox, camera, marker_enter, marker_exit, marker_start, marker_obj
BMarker.new = function(data, bs)
	local m = {}
	m.enable = false
	setmetatable(m, {__index = BMarker})
	m:loadFromData(data, bs)
	return m
end

BMarker.shape2type = function(shape)
	return BMarkers.shape2type[shape]
end

BMarker.type2shape = function(type)
	return BMarkers.type2shape[type]
end

BMarker.getName = function(self)
	return self.name
end

BMarker.getType = function(self)
	return self.type
end

BMarker.setName = function(self, name)
	self.name = name
end

BMarker.setBlock = function(self, block, index)
	self.block = block
	self.block_subindex = index
end

BMarker.bindBlock = function(self, block)
	self.bindblock = block
end

BMarker.loadFromData = function(self, data, bs)
	self.name = data.name
	self.type = data.type

	if data.bindblock then
		if type(data.bindblock) == 'table' and data.bindblock.typestr == 'block' then
			self.bindblock = data.bindblock
		elseif type(data.bindblock) == 'number' and bs then
			self.bindblock = bs[data.bindblock]
		end
	end

	if data.trains then
		self.trains = {}
		table.deep_clone(self.trains, data.trains)
	end
	if data.bindshape then
		self.bindshape = data.bindshape
	end

	if self.type == 'xfxs' then
		self.ress = {}
		if data.ress then
			table.deep_clone(self.ress, data.ress)
		end
	end
end

BMarker.saveToData = function(self, mdata)
	mdata.type = self.type
	mdata.name = self.name
	local bindblock = self.bindblock
	if bindblock and bindblock:isNodeValid() then
		mdata.bindblock = bindblock.index
	end

	if self.trains then
		mdata.trains = {}
		table.deep_clone(mdata.trains, self.trains, function(k, v)
			return k ~= 'module'
		end)
	end

	if self.bindshape then
		mdata.bindshape = self.bindshape
	end

	if self.type == 'xfxs' then
		mdata.ress = {}
		table.deep_clone(mdata.ress, self.ress)
	end

	return mdata
end
BMarker.isMarkerEnabled = function(self, enable)
	return self.enable
end

BMarker.enableMarker = function(self, enable)
	self.enable = enable
	if enable then
		if self.type == 'xfxs' then
			self:resetXfx()
		elseif self.type == 'marker_shapeProbe' then
			self:enableShapeProbe(true)
		end
	else
		if self.type == 'xfxs' then
			self:stopXfxs()
		elseif self.type == 'marker_shapeProbe' then
			self:enableShapeProbe(false)
		end
	end
end

local soundpos = _Vector3.new()
BMarker.playXfxs = function(self)
	if self.type == 'xfxs' then
		for i, v in ipairs(self.ress) do
			if v.xfxtype == 'pfx' and self.block then
				local pfxdata = Global.Marker_PfxRess[v.type]
				local mat
				local scale = (pfxdata.scale or 1) * v.scale
				if scale ~= 1 then
					mat = _Matrix3D.new()
					mat:setScaling(scale, scale, scale)
				end
				local sub
				if self.block_subindex then
					sub = self.block:getSubMesh(self.block_subindex)
				end
				local pfx = self.block:playBindPfx(pfxdata.res, sub, mat)
				if v.loop then
					local emitters = {}
					pfx:getEmitters(emitters)
					for _, e in ipairs(emitters) do
						-- print('duration', e.duration, e.interval, e.lifeMin, e.lifeMax, e.delay)
						e.duration = -1
						if e.interval == 0 or e.interval == 0xffffffff then
							e.interval = (e.lifeMax == 0 or e.lifeMax == 0xffffffff) and 100 or (e.lifeMax + 100)
						end
					end
				end
			elseif v.xfxtype == 'sfx' and self.block then
				local sounddata = Global.Marker_SoundRess[v.type]

				local sg = SoundGroup.new()
				sg.type = v.loop and _SoundDevice.Loop or 0
				sg.volume = v.volume
				sg.soundName = sounddata.res

				local sub
				if self.block_subindex then
					sub = self.block:getSubMesh(self.block_subindex)
					sub.transform:getTranslation(soundpos)
					self.block.node.transform:apply(soundpos, soundpos)
				else
					self.block.node.transform:getTranslation(soundpos)
				end

				sg:play(soundpos)

				if not self.soundGroups then self.soundGroups = {} end
				table.insert(self.soundGroups, sg)
			end
		end
	end

	self.playingXfx = true
end

BMarker.stopXfxs = function(self)
	if self.type == 'xfxs' then
		-- print('stopXfxs', self.soundGroups and #self.soundGroups, debug.traceback())
		-- if self.block then
		-- 	self.block:stopBindPfx()
		-- end

		if self.soundGroups then
			-- for i, sg in ipairs(self.soundGroups) do
			-- 	sg:stop(true)
			-- end
			table.clear(self.soundGroups)
		end
	end

	self.playingXfx = false
end

BMarker.refreshXfx = function(self, show)
	local playing = self.playingXfx
	self:stopXfxs()
	if playing then
		self:playXfxs()
	end
end

BMarker.resetXfx = function(self, show)
	self:stopXfxs()
	self:playXfxs()
end

BMarker.getBindMatrix = function(self)
	if self.block and self.block_subindex then
		local sub = self.block:getSubMesh(self.block_subindex)
		return sub.transform
	elseif self.block then
		return self.block.node.transform
	end
end

BMarker.enableShapeProbe = function(self, enable)
	if self.type ~= 'marker_shapeProbe' then return end
	if not self.bindshape then return end

	if enable then
		if not self.bindshapeBlock then
			local b = Global.sen:createBlock({shape = self.bindshape})
			if self.block_subindex then
				local sub = self.block:getSubMesh(self.block_subindex)
				b.node.transform:mulRight(sub.transform)
			end
			b.node.transform.parent = self.block.node.transform
			b:enable_node_update(true)
			b.isdummyblock = true
			self.bindshapeBlock = b
		end
		self.bindshapeBlock:setVisible(true)
		self.bindshapeBlock:enableQuery(true)
		if Global.dungeon then
			self.bindshapeBlock:check_collision_overlap()
		end
	else
		if self.bindshapeBlock then
			self.bindshapeBlock:setVisible(false)
			self.bindshapeBlock:enableQuery(false)
		end
	end
end