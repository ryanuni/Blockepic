local Container = _require('Container')

local BlockBrawlRole = {}
_G.BlockBrawlRole = BlockBrawlRole

BlockBrawlRole.new = function(role)
	local bbrole = {}
	setmetatable(bbrole, {__index = BlockBrawlRole})

	bbrole.role = role
	-- bbrole.tempcamera = _Camera.new()
	bbrole.defaultcamera = _Camera.new()
	bbrole.defaultcamera.look:set(0, 0, 1.1)
	bbrole.defaultcamera.eye:set(0, -3.2, 1.1)

	return bbrole
end

BlockBrawlRole.loadUI = function(self, ui)
	if not ui then return end

	local rui = ui.picload
	if not self.db then
		self.db = _DrawBoard.new(rui._width, rui._height)
	else
		self.db.w = rui._width
		self.db.h = rui._height
	end

	rui:loadMovie(self.db)
end

BlockBrawlRole.render = function(self, e)
	if not self.db then return end
	-- self.tempcamera:set(_rd.camera)
	local current = _rd.camera
	_rd.camera = self.defaultcamera
	_rd:useDrawBoard(self.db, _Color.Null)

	if self.role then
		-- local tempmat = Container:get(_Matrix3D)
		-- local mat = Container:get(_Matrix3D)
		-- mat:identity()
		local node = self.role.mb.node
		self.db.postProcess = _rd.postProcess
		local tempshadowcaster = node.isShadowCaster
		node.isShadowCaster = false
		-- self.tempcamera:set(_rd.camera)

		-- _rd.camera:set(self.defaultcamera)
		local ambient = Global.sen.graData:getLight('ambient')
		local skylight = Global.sen.graData:getLight('skylight')
		if ambient then
			_rd:useLight(ambient)
		end
		if skylight then
			_rd:useLight(skylight)
		end

		-- copyMat(tempmat, node.mesh.transform)
		-- node.mesh.transform:set(mat)
		node.mesh:drawMesh()
		-- copyMat(node.mesh.transform, tempmat)
		if ambient then
			_rd:popLight()
		end
		if skylight then
			_rd:popLight()
		end

		self.db.postProcess = nil
		node.isShadowCaster = tempshadowcaster
		-- Container:returnBack(tempmat, mat)
	end

	_rd:resetDrawBoard()
	_rd.camera = current
	--_rd.camera:set(self.tempcamera)
end