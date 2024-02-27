local switcher = {}

Global.Switcher = switcher

switcher.meshes = {
	_Mesh.new('cut_to.skn'),
	_Mesh.new('cut_to_b.skn'),
	_Mesh.new('cut_to_c.skn'),
	_Mesh.new('cut_to_d.skn'),
	_Mesh.new('cut_to_e.skn'),
}

switcher.init = function(self)
	if self.ui then return end
	self.ui = Global.UI:new('SwitchScene.bytes', 'screen')
	self.db = _DrawBoard.new(math.max(self.ui._width, 1), math.max(self.ui._height, 1))
	self.scene = _Scene.new('cut_to.sen')
	self.db:usePostSetting(self.scene.postSetting)
	self.ui.onSizeChange = function()
		-- self.db.w = math.max(self.ui._width, 1)
		-- self.db.h = math.max(self.ui._height, 1)
		self.db:resize(math.max(self.ui._width, 1), math.max(self.ui._height, 1))
		self.ui.rt:loadMovie(self.db)
	end
	self.ui.rt:loadMovie(self.db)
	_rd:useDrawBoard(self.db, _Color.Null)
	_rd:resetDrawBoard()
	self.camera = _Camera.new()
	self.waitfinish = false
end
switcher.enable = function(self, e)
	if _sys:getGlobal('AUTOTEST') then
		self.disable = true
	end
	self.disable = not e
end
switcher.show = function(self, show, type, subtype)
	self:init()
	self.ui.visible = show
	self.type = type
	if show then
		local node1 = self.scene:getNode('cut_to')
		local node2 = self.scene:getNode('cut_to_01')
		node1.visible = false
		node2.visible = false
		local node, sklname, esanname, osanname
		if type == 1 then
			node = node1
			self.subtype = subtype or math.random(#switcher.meshes)
			node.mesh = switcher.meshes[self.subtype]
			sklname = 'cut_to.skl'
			esanname = 'cut_to_skin01_enter02.san'
			osanname = 'cut_to_skin01_out02.san|cut_to_skin01_out.tag'
		elseif type == 2 then
			node = node2
			sklname = 'cut_to_01.skl'
			esanname = 'cut_to_01_enter.san'
			osanname = 'cut_to_01_out.san|cut_to_01_out.tag'
		end
		self.viewcamera = self.scene.graData:getCamera(type)
		if node.mesh.skeleton == nil then
			if node.meshskeleton then
				node.mesh.skeleton = node.meshskeleton
			else
				node.meshskeleton = node.mesh:attachSkeleton(sklname)

				local eani = node.mesh.skeleton:addAnima(esanname)
				eani.loop = false

				local oani = node.mesh.skeleton:addAnima(osanname)
				oani.loop = false

				eani:onStop(function()
					if self.onSwitch then
						self.onSwitch()
						self.onSwitch = nil
					end
					if self.waitfinish == false and oani.isPlaying == false then
						self:playEndAnima()
					end
				end)

				oani:onEvent(function(name)
					if name == 'over' then
						if self.onOver then
							self.onOver()
							self.onOver = nil
						end
						Global.Switcher:show(false)
					end
				end)

				node.eani = eani
				node.oani = oani
			end
		end

		node.visible = true
		node.eani:play()
	end
end

switcher.playEndAnima = function(self)
	self.playEndAnimaFlag = true
end

switcher.onPlayEndAnima = function(self)
	if self.scene == nil then return end
	if self.type == 1 then
		local node1 = self.scene:getNode('cut_to')
		if node1.oani and node1.oani.isPlaying == false then
			node1.oani:play()
		end
	elseif self.type == 2 then
		local node2 = self.scene:getNode('cut_to_01')
		if node2.oani and node2.oani.isPlaying == false then
			node2.oani:play()
		end
	end
	self.waitfinish = false
end

switcher.specialupdate = function(self, e)
	-- 为了动画播放完整需要间隔两帧之后开始播放
	if self.playEndAnimaFlag1 then
		self:onPlayEndAnima()
		self.playEndAnimaFlag1 = nil
	end
	if self.playEndAnimaFlag then
		self.playEndAnimaFlag1 = true
		self.playEndAnimaFlag = nil
	end
end

switcher.render = function(self)
	if self.ui == nil or self.ui.visible == false then return end
	self.camera:set(_rd.camera)
	_rd.camera:set(self.viewcamera)
	_rd:useDrawBoard(self.db, _Color.Null)
	self.scene:render()
	_rd:resetDrawBoard()
	_rd.camera:set(self.camera)
end

switcher.getTypeAndSubType = function(self, state, mode)
	if state == 'BROWSER' then
		if mode == 'house' then
			return 2
		else
			return 1, 2
		end
	elseif state == 'GAME' or state == 'DRESSUP' then
		return 1, 1
	elseif state == 'BUILDBRICK' then
		return 1, 3
	elseif state == 'NEVERUP' or state == 'MARIO' then
		return 1, 4
	elseif state == 'BLOCKBRAWL' then
		return 1, 5
	else
		return 1
	end
end

switcher.doSwitch = function(self, level, type, subtype, func)
	if self:needSwitch(level) then
		self.onSwitch = function()
			func(true)
		end
		self:show(true, type, subtype)
	else
		func(false)
	end
end

local noswitch = {
	room_1 = {house1 = true},
	house1 = {room_1 = true},
	home = {tunnel = true},
}

switcher.needSwitch = function(self, scenename)
	if self.disable then return false end
	if Global.sen == nil then return false end
	if _sys:getFileName(Global.sen.resname, false, false) == _sys:getFileName(scenename, false, false) then return false end

	local s1 = _sys:getFileName(scenename, false, false)
	local s2 = _sys:getFileName(Global.sen.resname, false, false)
	if noswitch[s1] and noswitch[s1][s2] then
		return false
	end
	return true
end

_app:registerUpdate(switcher, 1)

if _sys:getGlobal('AUTOTEST') then
	switcher:enable()
end