local Container = _require('Container')

-- 离线处理图片
local Capture = {}
Global.Capture = Capture

-- 设置截图后处理参数
local pp = _PostProcess.new()
pp.fxaa = false
pp.enableSSAOOcclusion = false
pp.ssaoOcclusionImage = _Image.new()
pp.toneMapKeepAlpha = true

-- 边缘描边配置参数
pp.normalOutlineRadius = 0.99
pp.depthOutlineBias = 0.1
pp.depthOutlinePower = 1000.0
pp.outlineColor = _Color.Black
if _sys.os == 'win32' then
	pp.depthOutline = true
end
Capture.postProcess = pp

Capture.init = function(self)
	if self.sen then return end

	self.sen = _Scene.new('capture.sen')
	self.sen.groups = {}
	self.sen.blocks = {}
	self.sen.blockuis = {}
	for k, v in next, Global.Scene do
		self.sen[k] = v
	end

	local plane = _mf:createPlane()
	plane.material = _Material.new()
	plane.material.ambient = _Color.lerp(_Color.Black, _Color.White, 0.05)
	plane.material.isMaterial = true
	plane.transform:setScaling(100, 100, 1)
	self.plane = plane
	self.sen:onRender(function(n, e)
		if _sys.enableOldShadow then
			_rd.shadowCaster = n.isShadowCaster
			_rd.shadowReceiver = n.isShadowReceiver
		end

		if n.terrain then
			n.terrain:draw()
		else
			if n.instanceMesh then
				n.instanceMesh:drawInstanceMesh()
			else
				n.mesh:drawMesh()
			end
		end

		if _sys.enableOldShadow then
			_rd.shadowCaster = false
			_rd.shadowReceiver = false
		end
	end)

	self.sen:onRenderCaster(function(n)
		if n.isShadowCaster then _rd.shadowCaster = true end
		if n.terrain then
			n.terrain:draw()
		else
			if n.instanceMesh then
				n.instanceMesh:drawInstanceMesh()
			else
				n.mesh:drawMesh()
			end
		end

		_rd.shadowCaster = false
	end)

	if not self.dbw then self.dbw = 1024 end
	if not self.dbh then self.dbh = 1024 end
	self.onlyZdb = _DrawBoard.new(self.dbw, self.dbh)
	self.drawboard = _DrawBoard.new(self.dbw, self.dbh)
	self.camera = self.sen.graData:getCamera('camera1')

	self.camera1 = _Camera.new()
	self.camera1.viewNear = 0.15
	self.camera1.viewFar = 500
	self.camera1.look:set(_Vector3.new(0, 0, 0))
	self.camera1.eye:set(_Vector3.new(0, -4, 2.8))

	self.camera2 = _Camera.new()
	self.camera2.viewNear = 0.15
	self.camera2.viewFar = 500
	self.camera2.look:set(_Vector3.new(0, 0, 0))
	self.camera2.eye:set(_Vector3.new(0, 0.3, 0))

	self.tempcamera = _Camera.new()
	self.aabb = _AxisAlignedBox.new()
	local sky = self.sen.graData:getLight('skylight')
	self.dir = sky.direction
	if self.useglobalcamera == nil then self.useglobalcamera = false end
	if self.turnToward == nil then self.turnToward = false end

	self.zaxis = _Vector3.new()
	_Vector3.sub(self.camera.look, self.camera.eye, self.zaxis)
	self.zaxis:normalize()

	--self.sen:useRDSetting(self.drawboard)
	--self.sen:useRDSetting()
end

Capture.config = function(self, camera, w, h, t)
	if not self.sen then self:init() end

	self.useglobalcamera = camera
	self.turnToward = t == nil and false or t
	if w ~= self.dbw or h ~= self.dbh then
		self.dbw = w
		self.dbh = h
		if self.sen then
			-- self.onlyZdb.w = w
			-- self.onlyZdb.h = h
			self.onlyZdb:resize(w, h)
			-- self.drawboard.w = w
			-- self.drawboard.h = h
			self.drawboard:resize(w, h)
		end
	end
end

Capture.reset = function(self)
	self.useglobalcamera = false
	self.turnToward = false
	if self.dbw == 1024 and self.dbh == 1024 then return end
	self.dbw = 1024
	self.dbh = 1024
	if self.sen then
		self.onlyZdb.w = 1024
		self.onlyZdb.h = 1024
		self.drawboard.w = 1024
		self.drawboard.h = 1024
	end
end

Capture.registerFinish = function(self, func)
	self.onFinish = func
end

Capture.registerUpload = function(self, func)
	self.onUpload = func
end

Capture.uploadCapture = function(self, filename)
	local picname, picmd5
	if self.onFinish then self.onFinish(picname, picmd5) end

	if filename ~= nil then
		picname, picmd5 = Global.FileSystem:atom_newFile(filename)
		if self.onUpload then self.onUpload(picname, picmd5) end
	end
end

Capture.addNode = function(self, itemid, subid, mtlid, colorid, roughness, mtlmode, paintinfo, filename, turnToward, usejpg, cammode)
	if not self.sen then self:init() end

	self.localcam = (cammode == 1 and self.camera1) or (cammode == 2 and self.camera2) or self.camera
	-- print('Capture.config', cammode, self.camera1, self.camera, self.localcam)

	if self.block then
		self.sen:delBlock(self.block)
		self.block = nil
	end

	local data = {
		shape = itemid,
		subshape = subid,
		material = mtlid or 1,
		color = colorid or 1,
		roughness = roughness or 1,
		mtlmode = mtlmode or 1,
		paintinfo = paintinfo,
	}

	self.block = self.sen:createBlock(data)
	self.block:invokeMarker()
	self.block.node.isShadowCaster = true
	self.block.node.isShadowReceiver = true

	local paintmeshs = self.block:getPaintMeshs()
	if paintmeshs and #paintmeshs > 0 then
		local turnmat = Container:get(_Matrix3D)
		turnmat:identity()
		turnmat:mulRotationYRight(math.pi * 0.0001)
		self.block.node.mesh.transform:mulRight(turnmat)
		Container:returnBack(turnmat)
	end

	if turnToward then
		local turnmat = Container:get(_Matrix3D)
		turnmat:identity()
		turnmat:mulRotationZRight(math.pi)
		self.block.node.mesh.transform:mulRight(turnmat)
		Container:returnBack(turnmat)
	end

	self.block:getAABB(self.aabb)
	local h = -self.aabb.min.z
	local offset = _Vector3.new(0, 0, h + 0.01)
	_AxisAlignedBox.offset(self.aabb, offset, self.aabb)
	self.block.node.transform:setTranslation(offset)
	self.block:updateSpace()

	local cam = self.localcam or self.camera
	self.aabb:getCenter(offset)
	cam:focus(offset)
	--self.aabb:getCenter(cam.look)
	return self:capturescreen(filename, usejpg)
end
Capture.addNode_new = function(self, id, filename, usejpg, cammode)
	self:addNode(id, nil, nil, nil, nil, nil, nil, filename, nil, usejpg, cammode)
end

Capture.capturescreen = function(self, filename, usejpg)
	if not self.block then return end

	local lastAsyncShader = _sys.asyncShader
	_sys.asyncShader = false

	local enableOldShadow = _sys.enableOldShadow
	local shadowColor = _rd.shadowColor
	local oldShadowBackFace = _rd.oldShadowBackFace
	local oldShadowBias = _rd.oldShadowBias
	local oldShadowLightWidth = _rd.oldShadowLightWidth
	local oldShadowColor = _rd.oldShadowColor
	local dir = _rd.shadowLight
	_rd.shadowLight = self.dir
	_rd.shadowColor = 0xFF606060

	local paintmeshs = self.block:getPaintMeshs()
	for i, m in pairs(paintmeshs) do
		m.material.isNoLight = true
	end

	if self.useglobalcamera == false then
		self.tempcamera:set(_rd.camera)
		_rd.camera:set(self.localcam or self.camera)
		local scalemat = _Matrix3D.new()
		scalemat:setScaling(1.1, 1.1, 1.1)
		calcCameraRadius(_rd.camera, self.aabb, self.drawboard, scalemat)
	end

	if self.turnToward then
		local dir = _rd.camera.eye
		_rd.camera.eye:set(dir.x * -1, dir.y * -1, dir.z)
	end

	self.sen:useRDSetting()
	self.onlyZdb.postProcess = self.postProcess
	_rd:useDrawBoard(self.onlyZdb, _Color.Null)
	self.sen:render()
	_rd:resetDrawBoard()

	_sys.enableOldShadow = true
	_rd.oldShadowBackFace = true
	_rd.oldShadowBias = 0
	_rd.oldShadowColor = 1.0
	self.drawboard.postProcess = self.postProcess
	self.drawboard.postProcess.normalOutline = true

	local pnode = self.sen:add(self.plane)
	pnode.isShadowReceiver = true
	_rd:useDrawBoard(self.drawboard, _Color.White)
	self.sen:render()
	_rd:resetDrawBoard()

	if self.useglobalcamera == false then _rd.camera:set(self.tempcamera) end
	_rd.shadowLight = dir
	_sys.enableOldShadow = enableOldShadow
	_rd.shadowColor = shadowColor
	_rd.oldShadowBackFace = oldShadowBackFace
	_rd.oldShadowBias = oldShadowBias
	_rd.oldShadowLightWidth = oldShadowLightWidth
	_rd.oldShadowColor = oldShadowColor

	Global.sen:useRDSetting()
	self.sen:del(pnode)

	self.drawboard.postProcess.normalOutline = false
	self.drawboard.postProcess = nil
	local outimg = _mf:occlusionAlphaTexture(self.drawboard, nil, nil, self.onlyZdb, nil, true)
	_sys.asyncShader = lastAsyncShader

	for i, m in pairs(paintmeshs) do
		m.material.isNoLight = false
	end
	local mesh = self.block.node.mesh
	local displaypicture = _sys:getSaveFileName(filename or _sys:getFileName(mesh.name, false) .. '-display.bmp')
	if self.dbw == self.dbh and self.dbw == 1024 then
		local ratio = Global.BuildBrick.defaultImageSize / self.dbw
		_mf:resizeFImage(outimg, ratio, ratio, function(img)
			if usejpg then
				img:saveToFile(displaypicture, _ModelFactory.ImageJpg)
			else
				img:saveToFile(displaypicture, _ModelFactory.ImagePng)
			end
			Global.Capture:uploadCapture(filename)
		end)
	else
		if usejpg then
			outimg:saveToFile(displaypicture, _ModelFactory.ImageJpg)
		else
			outimg:saveToFile(displaypicture, _ModelFactory.ImagePng)
		end
		Global.Capture:uploadCapture(filename)
	end

	return displaypicture
end

local kevents = {
	{
		k = _System.KeyA,
		func = function()
			Global.Capture:addNode('road')
		end
	},
}

local cameracontrol = {}
if _sys.os == 'win32' then
	cameracontrol.rotate = _System.MouseRight
	cameracontrol.move = _System.MouseMiddle
else
	cameracontrol.rotate = 2
	cameracontrol.move = 1
end

Global.GameState:setupCallback({
	addKeyDownEvents = kevents,
	onClick = function(x, y)
		Global.editor:onMouseUp(0, x, y)
	end,
	onDown = function(b, x, y)
		return Global.editor.dragSelect:onMouseDown(b, x, y)
	end,
	onMove = function(x, y)
		return Global.editor.dragSelect:onMouseMove(x, y)
	end,
	onUp = function(b, x, y)
		return Global.editor.dragSelect:onMouseUp(b, x, y)
	end,
	cameraControl = cameracontrol
}, 'CAPTURE')

local CaptureManager = {}
Global.CaptureManager = CaptureManager

local CaptureState = {
	Waiting = 0,
	Doing = 1,
}

CaptureManager.init = function(self)
	self.tasks = {}
	self.autotasks = {}
	self.capture = Global.Capture
	self.state = CaptureState.Waiting

	local onFinish = function(picname, picmd5)
		print('Capture finish', picname, picmd5)
		if #self.tasks ~= 0 then
			table.remove(self.tasks, 1)
		else
			table.remove(self.autotasks, 1)
		end
		self.state = CaptureState.Waiting
	end

	self.camera = _Camera.new()
	-- self.camera:setEyeLook(_Vector3.new(0, -4, 2.8), _Vector3.new(0, 0, 0))
	-- local c = Global.CameraControl:new()
	-- c:setEyeLook(_Vector3.new(0, -4, 2.8), _Vector3.new(0, 0, 0))
	-- self.camera = c.camera
	self.capture:registerFinish(onFinish)
end

CaptureManager.useJPG = function(self, use)
	self.usejpg = use
end

CaptureManager.doTask = function(self, task)
	-- 切换状态
	self.state = CaptureState.Doing
	self.capture:registerUpload(task.func)
	if task.config then
		local usecamera = task.config.cam ~= nil
		self.capture:config(usecamera, task.config.w, task.config.h, task.config.turnToward)

		if usecamera then
			self.camera:set(_rd.camera)
			_rd.camera:set(task.config.cam)
		end
	end

	local ext = 'bmp'
	if self.usejpg then
		ext = 'jpg'
	end
	local filename = Global.FileSystem:atom_newName(ext)
	print('DoTask filename', filename)
	self.capture:addNode_new(task.shapeid, filename, self.usejpg, task.config.cameramode)

	if task.config then
		if task.config.cam ~= nil then
			_rd.camera:set(self.camera)
		end

		self.capture:reset()
	end
end

CaptureManager.addAutoTask = function(self, data, material, color, roughness, mtlmode, turnToward)
	if not self.autotasks then self:init() end
	local task = {data = data, material = material, color = color, roughness = roughness, mtlmode = mtlmode, turn = turnToward}
	table.insert(self.autotasks, task)
end

CaptureManager.doAutoTask = function(self, task)
	-- 切换状态
	self.state = CaptureState.Doing
	self.capture:addNode(task.data, nil, task.material, task.color, task.roughness, task.mtlmode, nil, nil, task.turn)
end

CaptureManager.addTask = function(self, tempid, cfg, callback)
	if not self.tasks then self:init() end
	local task = {shapeid = tempid, config = cfg, func = callback}
	table.insert(self.tasks, task)
end

CaptureManager.update = function(self)
	if not self.tasks then self:init() end
	for _, task in ipairs(self.tasks) do
		if self.state == CaptureState.Doing then
			break
		end

		self:doTask(task)
	end

	for _, task in ipairs(self.autotasks) do
		if self.state == CaptureState.Doing then
			break
		end

		self:doAutoTask(task)
	end
end

CaptureManager.AutoCaptures = function(self, exdata)
	self.data = exdata
	self.capture:reset()
	self.capture.turnToward = true
	if not self.data then
		self.data = {}

		-- 添加基础块
		for _, id in ipairs(Block.BrickIDs) do
			table.insert(self.data, id)
		end

		-- 添加地板
		for i, v in ipairs(Global.GetObjects('edit', 'floors')) do
			table.insert(self.data, v.name)
		end

		-- 添加物件
		for i, v in ipairs(Global.GetObjects('edit', 'object')) do
			table.insert(self.data, v.name)
		end
	end

	local quality = 1
	local m = Global.BrickQuality[quality].mtls[1]
	for index = 1, #self.data do
		self:addAutoTask(self.data[index], m.material, m.color, m.roughness, m.mtlmode, type(self.data[index]) == 'number')
	end
end

_app:registerUpdate(CaptureManager)