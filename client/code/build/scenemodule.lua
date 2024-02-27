---------------------------- module
local command = _require('Pattern.Command')
local SceneModule = {}
SceneModule.typestr = 'SceneModule'
Global.SceneModule = SceneModule

SceneModule.new = function(data)
	local m = {}
	m.version = data and data.version or 1
	m.scale = data and data.scale or 1

	m.blocks = {}
	m.groups = {}
	m.parts = {}
	m.subs = {}
	m.materials = {{material = 1, color = 0xfffff1f1, roughness = 1, mtlmode = Global.MTLMODE.PAINT}}

	if data then
		if not data.blocks and #data > 0 then -- 处理老资源
			for i, v in ipairs(data) do
				m.blocks[i] = v
			end
		else
			for k, v in pairs(data) do
				if k ~= 'subs' then
					m[k] = v
				end
			end

			-- if data.subs and next(data.subs) then
			-- 	for sid, v in ipairs(data.subs) do
			-- 		m.subs[sid] = Module.new(v)
			-- 	end
			-- end
		end
	end

	m.command = command.new()
	setmetatable(m, {__index = SceneModule})

	return m
end

SceneModule.getBlocksCount = function(self)
	return #self.blocks
end

SceneModule.isBlank = function(self)
	return self:getBlocksCount() == 0 and not next(self.subs)
end

SceneModule.getInitAABB = function(self)
	return self.funcflags and self.funcflags.userAABB
end

SceneModule.setAABB = function(self, ab)
	self.aabb = ab
end
SceneModule.getAABB = function(self)
	return self.aabb
end

SceneModule.tostring = function(self, data)
	return '{' .. Global.writeModuleString(self) .. '}'
end

SceneModule.clone = function(self)
	local str = Global.writeModuleString(self)
	local data = _dostring('return {' .. str .. '}')
	local m = SceneModule.new(data)

	-- print('SceneModule.clone0', self:tostring())
	-- print('SceneModule.clone', m:tostring())
	return m
end
-- TODO: add load and save to module