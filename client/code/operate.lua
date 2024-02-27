local Operate = {
	disableUi = false,
	disableRole = false,
}

Global.Operate = Operate

Operate.disabled = function(self, d)
--	print('[Operate.disabled]', debug.traceback())
	self.disableUi = d
end
Operate.disable_role = function(self, d)
--	print(d, debug.traceback())
	self.disableRole = d
end

local sc = {
	data = {
		input = true,
		cameracontrol = true,
		render = true,
	}
}

Global.SwitchControl = sc
sc.set = function(self, name, v)
	self.data[name] = v
end
sc.get = function(self, name)
	return self.data[name]
end
------------------------------
sc.set_input_on = function(self)
	self.data.input = true
end
sc.set_input_off = function(self)
	self.data.input = false
end
sc.is_input_on = function(self)
	return self.data.input
end
sc.is_input_off = function(self)
	return not self.data.input
end
------------------------------
sc.set_cameracontrol_on = function(self)
	self.data.cameracontrol = true
end
sc.set_cameracontrol_off = function(self)
	self.data.cameracontrol = false
end
sc.is_cameracontrol_on = function(self)
	return self.data.cameracontrol
end
sc.is_cameracontrol_off = function(self)
	return not self.data.cameracontrol
end
------------------------------
sc.set_render_on = function(self)
	self.data.render = true
end
sc.set_render_off = function(self)
	self.data.render = false
end
sc.is_render_on = function(self)
	return self.data.render
end
sc.is_render_off = function(self)
	return not self.data.render
end
------------------------------
-- no input, no cameracontrol
sc.set_freeze_on = function(self)
	self:set_input_off()
	self:set_cameracontrol_off()
end
sc.set_freeze_off = function(self)
	self:set_input_on()
	self:set_cameracontrol_on()
end