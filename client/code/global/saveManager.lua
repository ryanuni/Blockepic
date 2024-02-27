------------- Save & Load ------------
local SaveManager = {
	data = {},
	levelData = {},
	mappings = {},
	timer = _Timer.new(),
	need_save = false,
}

SaveManager.Reset = function(self)
	self.data = {}
	self:Save(true)
end
SaveManager.Set = function(self, k, v)
	self.data[k] = v
end
SaveManager.Get = function(self, k)
	return self.data[k]
end
SaveManager.Register = function(self, k)
	if self.data[k] then
	else
		self.data[k] = {}
	end

	return self.data[k]
end
SaveManager.Save = function(self, now)
	print('[SaveManager.Save]')
	self.need_save = true
	if now then
		self:save_write()
	else
		self.timer:stop()
		self.timer:start('', 1000 * 30, function()
			self:save_write()
		end)
	end
end
SaveManager.save_write = function(self)
	if self.need_save then
		_sys:writeConfig(_sys:getSaveFileName('data.save'), table.ftoString(self.data))
		self.need_save = false
		self.timer:stop()
	end
end
_app:onExit(function()
	SaveManager:save_write()
end)
SaveManager.Load = function(self)
	local str = _sys:readConfig(_sys:getSaveFileName('data.save')) or '{}'
	self.data = _dostring('return' .. str)
	if type(self.data) ~= 'table' then self.data = {} end -- 兼容老版本，下周删除
end
---------------------------------------------------------------------------
SaveManager.RegisterOnAid = function(self, k, f)
	self.mappings[k] = f
end
SaveManager.AidChange = function(self)
	local aid = Global.Login:getAid()
	if not self.data.aids then
		self.data.aids = {}
	end

	if not self.data.aids[aid] then
		self.data.aids[aid] = {}
	end

	local d = self.data.aids[aid]
	for k, f in next, self.mappings do
		d[k] = d[k] or {}

		f(d[k])
	end
end

if _sys:getGlobal('AUTOTEST') then
else
	SaveManager:Load()
end

---------------------------------------------------------------------------
SaveManager.LoadLevel = function(self, aid)
	self:SaveLevel()
	aid = aid or 0

	local str = _File.getString('level' .. aid .. '.save')
	if str then
		self.levelData = _dostring('return' .. str)
	end

	self.levelData = self.levelData or {}

	self.curAid = aid
end
SaveManager.SaveLevel = function(self)
	if not self.curAid then
		return
	end

	_File.writeString('level' .. self.curAid .. '.save', table.ftoString(self.levelData or {}))
end
SaveManager.RegisterLevel = function(self)
	if not self.curAid then
		self:LoadLevel()
	end

	return self.levelData
end

Global.SaveManager = SaveManager