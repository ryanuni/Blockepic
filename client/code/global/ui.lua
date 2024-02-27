local UIMovementManager = _require('UIMovementManager')
local UIAlphaManager = _require('UIAlphaManager')
local UIVisibleManager = _require('UIVisibleManager')

local ui = {
	list = {
		global = {},
		normal = {},
		screen = {},
	},
	isHiding = false,
	stack = {},
	depth = {
		['Debugger.bytes'] = 10000,
		['SwitchScene.bytes'] = 9999,
		['FullScreenNotice.bytes'] = 9998,
		['MovieCurtain.bytes'] = 9998,
		['Confirm.bytes'] = 9997,
		['Notice.bytes'] = 9996,
		['Island.bytes'] = 9996,
		['Introduce.bytes'] = 9995,
		['DressAvatarShot.bytes'] = 9995,
		['HotKey.bytes'] = 9994,

		['View1.bytes'] = 13,
		['Barrage.bytes'] = 12,
		['BarrageEdit.bytes'] = 12,
		['Guide.bytes'] = 11,
		['Win.bytes'] = 11,
		['Coin.bytes'] = 9,
		['Parkour.bytes'] = 1,
	},
	mmanager = UIMovementManager.new(),
	amanager = UIAlphaManager.new(),
	vmanager = UIVisibleManager.new(),
}
Global.UI = ui
_dofile('ui_safearea.lua')

local ui_adapter = _require('UIFairyAdapt')
Global.DesignW = 1920
Global.DesignH = 1080
ui_adapter:initialize(Global.DesignW, Global.DesignH)

ui.new = function(self, name, group)
	group = group or 'normal'

	local u = _FairyManager.new(name)
	-- print('[UI:new]', name, group, u.sortingOrder)
	if self.depth[name] then
		u.sortingOrder = self.depth[name]
	end
	local g = self.list[group]
	local m = u.main
	-- if _sys.isRetinaScreen == false then
		-- temporary keep scale(login keep using scaling)
	if name == 'Login.bytes' or name == 'BlockBrawl.bytes' then
		m.keepScale = true
	end
	-- end
	g[name] = m
	self:safeArea_add(m)

	self:resizeOne(m)

	return m
end
ui.resizeOne = function(self, m)
	if m.keepScale then
		local s = ui_adapter:getRootScale()
		m._xscale = 1 / s * _rd.w / ui_adapter.designW * 100
		m._yscale = 1 / s * _rd.h / ui_adapter.designH * 100

		m._width, m._height = ui_adapter.designW, ui_adapter.designH
	else
		m._width, m._height = ui_adapter:getSize()
	end
end
ui.del = function(self, mc)
	for gn, g in next, self.list do
		for n, m in next, g do
			if m == mc then
				g[n] = nil
				m.parent.visible = false
				self:safeArea_del(m)
				return
			end
		end
	end
end
ui.changeDesignWH = function(self, w, h)
	if Global.DesignW ~= w or Global.DesignH ~= h then
		Global.DesignW = w
		Global.DesignH = h
		ui:onResize(_rd.w, _rd.h)
	end
end
ui.getScale = function(self)
	return ui_adapter:getRootScale()
end
ui.getDesignSize = function(self)
	if _app:isScreenH() then
		return ui_adapter.designW, ui_adapter.designH
	else
		return ui_adapter.designH, ui_adapter.designW
	end
end
ui.getSize = function(self)
	return ui_adapter:getSize()
end
ui.UI2ScreenPos = function(self, x, y)
	return x / (_Fairy.root._xscale / 100), y / (_Fairy.root._yscale / 100)
end
local v2 = _Vector2.new()
ui.Vector3ToPos = function(self, v)
	_rd:projectPoint(v.x, v.y, v.z, v2)
	return self:UI2ScreenPos(v2.x, v2.y)
end
-------------------------------------------------
ui.pushAndHide = function(self, group)
	local s = {}
	for name, u in next, self.list[group] do
		if u.visible then
			s[u] = true
			u.visible = false
		end
	end

	table.insert(self.stack, s)
end
ui.popAndShow = function(self)
	local s = table.remove(self.stack)
	if s then
		for u in next, s do
			u.visible = true
		end
	end
end
ui.switchUIVisible = function(self, visible)
	if visible then
		ui:popAndShow()
		ui:popAndShow()
	else
		ui:clearStack()
		ui:pushAndHide('global')
		ui:pushAndHide('normal')
	end
end
local isHiding = false
ui.switchGroup = function(self)
	if isHiding then
		self:popAndShow()
	else
		self:pushAndHide('normal')
	end

	isHiding = not isHiding
end
ui.clearStack = function(self)
	for i = #self.stack, 1, -1 do
		ui:popAndShow()
	end
end
-------------------------------------------------
ui.resize = function(self, w, h)
	for gn, g in next, self.list do
		for n, u in next, g do
			self:resizeOne(u)
		end
	end
	if Global.debugFuncUI then
		Global.debugFuncUI:resize()
	end
end
ui.onResize = function(self, w, h)
	local isH = w > h
	if isH then
		ui_adapter:initialize(Global.DesignW, Global.DesignH)
	else
		ui_adapter:initialize(Global.DesignH, Global.DesignW)
	end

	local w2, h2 = ui_adapter:getSize()
	ui:resize(w2, h2)
end
_app:onResize(function(w, h)
	if not Global.CodeDone then return end
	ui:onResize(w, h)
	ui:onDeviceOrientation()
	Global.CameraControl:onDeviceOrientation(_app:isScreenH())

	local r = 1080 / math.min(w, h)
	if r < 1 then
		_rd:setResolution3D(r, r)
	end
end)

ui.onDeviceOrientation = function(self, u, func)
	if u then
		if not self.orifuncs then self.orifuncs = {} end
		self.orifuncs[u] = func
	elseif self.orifuncs then
		for u, func in next, self.orifuncs do
			if u._visible then
				func(_app:isScreenH())
			end
		end
	end
end
ui.slidein = function(self, us, time, dir)
	dir = dir or 'x'
	time = time or 200
	local dx = dir == 'x' and 250 or 0
	local dy = dir == 'y' and 250 or 0
	for i, u in ipairs(us) do
		local oldx = u._x
		local oldy = u._y
		u._x = u._x + dx
		u._y = u._y + dy
		u._alpha = 10

		Global.UI.mmanager:addMovment(u, {x = oldx, y = oldy}, time)
		Global.UI.amanager:addAlpha(u, 100, time)
	end
	Global.Sound:play('slidein')
end
ui.slideout = function(self, us, time, dir)
	dir = dir or 'x'
	time = time or 200
	local dx = dir == 'x' and 250 or (dir == '-x' and -250) or 0
	local dy = dir == 'y' and 250 or (dir == '-y' and -250) or 0
	for i, u in ipairs(us) do
		Global.UI.mmanager:delMovment(u)

		local oldx = u._x
		local oldy = u._y
		Global.UI.amanager:addAlpha(u, 10, time)
		Global.UI.mmanager:addMovment(u, {x = u._x - dx, y = u._y - dy}, time, function()
			u._x = oldx
			u._y = oldy
		end)
		Global.Timer:add('slideout', time + 100, function()
			Global.UI.mmanager:delMovment(u)
		end)
	end
	Global.Sound:play('slideout')
end
-------------------------------------------------------
ui.specialupdate = function(self, e)
	self:safeArea_update()
	self.mmanager:update(e)
	self.amanager:update(e)
	self.vmanager:update(e)
end
_app:registerUpdate(ui, 1)
-------------------------------------------------------
-- 逻辑编辑功能ui引用的模块用到了resize，暂时不能assert
-- _app.onResize = function()
	-- assert(nil, '[_app.onResize]不要重写')
-- end