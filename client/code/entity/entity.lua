

_dofile('role_new_base.lua')
_dofile('role.lua')

_dofile('character.lua')

local role_new = _dofile('role_new.lua')

local em = {}
Global.EntityManager = em

em.entitys = {}
em.get_roles = function(self)
	return self.entitys
end
em.input_update = function(self, e)
	if Global.role then
		Global.role:input_update(e)
	end
	for aid, entity in pairs(self.entitys) do
		entity:input_update(e)
	end
end
em.update = function(self, e)
	if Global.role then
		Global.role:update(e)
	end
	for aid, entity in pairs(self.entitys) do
		entity:update(e)
	end
end
em.new_role = function(self, d)
	local r
	if d.aid == Global.Login:getAid() then
		r = Global.Role.new()
	else
		r = role_new.new(d)
		self.entitys[d.aid] = r
	end

	return r
end
em.get_role = function(self, aid)
	return self.entitys[aid]
end
em.del_role = function(self, r)
	self.entitys[r.aid] = nil
end
em.clear = function(self)
	for aid, entity in pairs(self.entitys) do
		entity:release()
	end
	self.entitys = {}
	if Global.role then
		Global.role:release()
	end
end
---------------------------------------------
em.update_render = function(self, e, lerp)
	for aid, entity in pairs(self.entitys) do
		entity:update_render(e, lerp)
	end
	if Global.role then
		Global.role:update_render(e, lerp)
	end
end
em.pause = function(self, p)
	for aid, entity in pairs(self.entitys) do
		entity:pause(p)
	end
	if Global.role then
		Global.role:pause(p)
	end
end