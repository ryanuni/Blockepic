

-- 根据输入做出改变的role
local role = {}
local gr = Global.Role
role.new = function(data)
	local r = Global.Role.new_xl(data)

	setmetatable(r, {__index = role})

	if data.avatarid then
		r:setAvatarid(data.avatarid)
	end

	r.createCCT = gr.createCCT
	r:createCCT(r.node)

	return r
end
role.onChangeState = gr.onChangeState
role.updateFootPfx = gr.updateFootPfx
role.getPosition_const = gr.getPosition_const
role.setAvatarid = gr.setAvatarid
role.updateFace = gr.updateFace
role.setScale = gr.setScale
role.getAABB = gr.getAABB
role.getPosition = gr.getPosition
role.setPosition = gr.setPosition
role.gethit = gr.gethit
role.Respawn = gr.Respawn
role.fix_position = gr.fix_position
role.check_dir_before_physics = gr.check_dir_before_physics
role.setJumpLimit = gr.setJumpLimit
role.jump = gr.jump
role.isInAir = gr.isInAir
role.ChangeAvatar = Global.Character.ChangeAvatar
role.do_collide = gr.do_collide

role.pause = gr.pause

----- logic
role.getTotalLifes = gr.getTotalLifes
role.getCurLifes = gr.getCurLifes
role.updateCurFloor = gr.updateCurFloor
role.getCurFloor = gr.getCurFloor
role.destory = gr.destory
role.getRole = gr.getRole
role.die = gr.die
---------------------------------------
role.ai_prepare = gr.ai_prepare
role.ai_start = gr.ai_start
role.ai_update = gr.ai_update
role.ai_idle = gr.ai_idle
role.ai_do_input = gr.ai_do_input
role.ai_stop = gr.ai_stop
role.ai_move = gr.ai_move
role.ai_go_left = gr.ai_go_left
role.ai_go_right = gr.ai_go_right
role.ai_calc_dis = gr.ai_calc_dis
role.ai_wait = gr.ai_wait
role.ai_wander = gr.ai_wander
role.ai_wander_2 = gr.ai_wander_2
role.ai_go_down = gr.ai_go_down
role.ai_land = gr.ai_land
role.ai_pick_ray = gr.ai_pick_ray

-----------

role.playAnima = function(self, a, onend)
	if self.currentAnimaName == a then return end
	
	if self.currentAnima then
		self.currentAnima:stop()
	end

	if not self.mb.block then
		self.animas[a]:play()
	else
		self.mb.block:playAnim(a)
	end

	self.currentAnima = self.animas[a]
	self.currentAnimaName = a
	self.currentAnima.onend = onend
end
--[[
	操作输入缓冲

	index
		操作序列
	frame_index
	elapse
	keys
		输入
	pos
		校正
]]
role.set_input = gr.set_input
role.input_update_sub = gr.input_update_sub
role.input_update = gr.input_update
role.set_outer_input = gr.set_outer_input

role.get_position_render = gr.get_position_render
role.set_position_render = gr.set_position_render
role.update_render = gr.update_render

role.update = function(self, e)
	if self.cct == nil then return end

	self:fix_position()

	Global.Role_Base_xl.calc_anima_state(self, e)
end
role.releaseCCT = function(self)
	self.node.scene:delController(self.cct)
	self.cct = nil
end

role.release = function(self)
	self:releaseCCT()
	Global.EntityManager:del_role(self)
end

role.chip_register_event = gr.chip_register_event
role.chip_call_event = gr.chip_call_event
role.registerGameBegin = gr.registerGameBegin
role.attr_add_life = gr.attr_add_life
role.attr_set_life = gr.attr_set_life
role.attr_set_maxlife = gr.attr_set_maxlife
role.attr_set_score = gr.attr_set_score
role.attr_get = gr.attr_get
role.attr_set = gr.attr_set
role.Speed_get = gr.Speed_get
role.Speed_set = gr.Speed_set

Global.TEMP_ROLE_NEW = role

return role
