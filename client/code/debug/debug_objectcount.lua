
local objectmonitor = {
	font1 = _Font.new('simhei', 18),
	font2 = _Font.new('simhei', 18),
	data = {},
	enabled = false,
	tracing = false,
}

objectmonitor.addOne = function(self, o)
	local d = {}
	d.object = o
	d.name = o.typestr
	d.id = o.typeid
	d.old = 0
	d.new = 0
	d.oldNew = o.new
	d.traceNew = function(...)
		print(d.name, debug.traceback())
		return d.oldNew(...)
	end

	table.insert(self.data, d)
end
objectmonitor.update = function(self)
	local font
	local y = 0
	local h = 20
	_rd:fillRect(0,0,200, 20 * #self.data, 0x88222222)

	for i, d in ipairs(self.data) do
		d.new = _debug:objectCount(d.id, 50)
		if d.new == d.old then
			font = self.font1
		else
			font = self.font2
			d.old = d.new
		end

		font:drawText(0, h * (i - 1), string.format('%s : %d', d.name, d.new))
	end
end
objectmonitor.init = function(self)
	self.font1.textColor = _Color.Green
	self.font2.textColor = _Color.Red

	local objecttable = {
		_DrawBoard, _Image,
		_Vector3, _Vector2, _Matrix3D, _AxisAlignedBox,
		_Scene, _Mesh, _SceneNode,
		_Particle, _ParticlePlayer,
		_PhysicsActor, _PhysicsShape,
		_FairyManager, _FairyComponent,
	}

	for i, o in ipairs(objecttable) do
		self:addOne(o)
	end
end
objectmonitor.show = function(self, s)
	self.enabled = s
	_debug.enable = s

	if s then
		_debug:registerRender(self, self.update)
	else
		_debug:registerRender(self)
	end
end
objectmonitor.traceback = function(self, t)
	self.tracing = t
	if t then
		for i, d in ipairs(self.data) do
			local obj = d.object
			obj.new = d.traceNew
		end
	else
		for i, d in ipairs(self.data) do
			local obj = d.object
			obj.new = d.oldNew
		end
	end
end
objectmonitor:init()
Global.Debug.switchObjectCount = function(self)
	objectmonitor:show(not objectmonitor.enabled)
end
Global.Debug.switchObjectTrace = function(self)
	objectmonitor:traceback(not objectmonitor.tracing)
end

Global.Debug.switchMode = function(self)
	self.mode = (self.mode or 0) % 4 + 1

	if self.mode == 1 then
		objectmonitor:show(true)
	elseif self.mode == 2 then
		objectmonitor:show(false)
		_debug.enable = true
		_debug.monitor = true
		_debug.enableProfiler = true
		_debug:frameMonitor(true)
	elseif self.mode == 3 then
		_debug:frameMonitor(false)
	elseif self.mode == 4 then
		_debug.enable = false
		_debug.monitor = false
		_debug.enableProfiler = false
	end
end