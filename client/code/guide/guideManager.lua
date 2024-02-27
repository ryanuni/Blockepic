local Guide = {}
Global.Guide = Guide

-- 0.未开始
-- 1.移动引导
-- 2.跳跃引导
-- 3.建造引导
-- 4.触发引导
-- 5.逻辑块引导
-- 6.传送门引导

Guide.finish = function(self)
	TEMP_SETUP_CAMERA()
	Global.ScreenEffect:movieCurtainOut()
end
Guide.init = function(self)
	self.timer = _Timer.new()
	self.progress = 0

	Global.sen.onWin = function()
		Global.Guide:enterTunnel()
	end

	Guide.introducercontent = {
		'Drag <span style="color: rgb(150, 50, 50);">Move Stick</span>, move to the specified location.',
		'Touch <span style="color: rgb(150, 50, 50);">Jump Button</span>, jump onto the platform.',
		'Touch <span style="color: rgb(150, 50, 50);">Build Button</span>, enter build mode.',
		'Jump onto <span style="color: rgb(150, 50, 50);">Red Button</span>, detonate the wall.',
		'Link <span style="color: rgb(150, 50, 50);">Button Trigger</span> to the wall.',
	}

	-- ui
	self.ui = Global.UI:new('Guide.bytes')
	self:show(false)

	-- 右下角键、edit锁住
	Global.UIParkour:show(false)

	-- mark点
	local transform1 = _Matrix3D.new()
	transform1:setScaling(0.1, 0.1, 0.1)
	transform1:mulTranslationRight(-59.5, 0.59, 11.84)

	local transform2 = _Matrix3D.new()
	transform2:setScaling(0.1, 0.1, 0.1)
	transform2:mulTranslationRight(-10, 0.59, 17.84)

	local transform3 = _Matrix3D.new()
	transform3:setScaling(0.1, 0.1, 0.1)
	transform3:mulTranslationRight(13.8, 0.10, 17.9)

	local transform4 = _Matrix3D.new()
	transform4:setScaling(0.1, 0.1, 0.1)
	transform4:mulTranslationRight(66.31, 0.49, 26.39)

	self.markpoints = {transform1, transform2, transform3, transform4}

	self.markpfx = Global.sen.pfxPlayer:play('cj_zhiyin_zs.pfx')
	self.markpfx.transform = self.markpoints[1]
end
Guide.show = function(self, s)
	if self.ui then
		self.ui.visible = s
	end
end
Guide.hide = function(self)
	Global.GameState:changeState('GAME')
end
Guide.appear = function(self)
	Global.GameState:changeState('GUIDE')
end
-- 角色移动
Guide.moveGuide = function(self)
	if self.progress < 1 then
		self.progress = 1
	else
		return
	end

	self:appear()

	-- 提示语
	self.ui.introducer.title.text = Guide.introducercontent[1]
	self.ui.introducer.visible = true
	self.ui.mask.visible = false

	Global.UIParkour:moveGuide()
end
-- 角色跳跃
Guide.jumpGuide = function(self)
	if self.progress < 2 then
		self.progress = 2
	else
		return
	end

	-- 等待平台升起2s
	self:appear()

	-- 提示语
	self.ui.introducer.title.text = Guide.introducercontent[2]
	self.ui.introducer.visible = true
	self.ui.mask.visible = false

	-- 跳跃按钮出现
	Global.UIParkour:jumpGuide()
end
-- 建造
Guide.buildGuide = function(self)
	if self.progress < 3 then
		self.progress = 3
	else
		return
	end

	self:appear()

	-- 提示语
	self.ui.introducer.title.text = Guide.introducercontent[3]
	self.ui.introducer.visible = true
	self.ui.mask.visible = false

	-- 建造按钮出现 TODO.引导长按主角
	-- Global.ui:gotoAndPlay('buildguide')
	Global.ui:showEdit(true, false)
end
-- 触发逻辑块
Guide.triggerGuide = function(self)
	if self.progress < 4 then
		self.progress = 4
	else
		return
	end

	self:appear()

	-- 提示语
	self.ui.introducer.title.text = self.introducercontent[4]
	self.ui.introducer.visible = true
end
-- 创造逻辑块
Guide.eventBlockGuide = function(self)
	if self.progress < 5 then
		self.progress = 5
	else
		return
	end

	self:appear()

	-- 提示语
	self.ui.introducer.title.text = self.introducercontent[5]
	self.ui.introducer.visible = true
end
-- 吸入传送门
Guide.enterGate = function(self)
	if self.progress < 6 then
		self.progress = 6
	else
		return
	end

	Global.GameState:changeState('MOVIE')
	Global.ScreenEffect:movieCurtainIn()

	Global.CameraControl:get():followTarget('role')
	Global.role:releaseCCT()

	Global.role:playAnima('struggle')

	local cur = _Vector3.new()
	Global.role:getPosition(cur)
	local tar = _Vector3.new(68.5, 0.48, 28)

	-- 转人
	local faceto = _Vector3.new()
	_Vector3.sub(cur, tar, faceto)
	Global.role:updateFace(faceto, 0)
	Global.role:focusFace(0)

	-- 移动
	local time1 = 3000
	local trans = _Vector3.new()
	_Vector3.sub(tar, cur, trans)
	-- 太远的时候先瞬移过去（debug功能）
	if trans:magnitude() > 5 then
		faceto:normalize()
		faceto:scale(5)
		_Vector3.add(tar, faceto, cur)
		Global.role:setPosition(cur)
		_Vector3.sub(tar, cur, trans)

		local g = Global.sen:getGroup(23)
		g.functions[1]:trigger()
	end

	Global.role.translation:mulTranslationRight(trans, time1)
	Global.Sound:play('in1')
	self.timer:start("gateclock", 4000, function()
		self.timer:stop('gateclock')
		Global.Sound:stop()
		self:enterTunnel()
	end)
end
-- 下一个mark点
Guide.updateMarkPoint = function(self, idx)
	self.markpfx.transform = self.markpoints[idx]
end
-- 结束特效播放
Guide.stopMarkPoint = function(self)
	self.markpfx:stop()
end
Guide.enterTunnel = function(self)
	initLevel('tunnel.sen')
	Global.GameState:changeState('MOVIE')
	Global.CameraControl:get():followTarget()

	local v1 = _Vector3.new(-59.70, 0.03, 30.03)
	local v2 = _Vector3.new(-86.44, 0.56, 31.24)

	-- 穿时空隧道
	Global.Sound:play('in2')
	local faceto = _Vector3.new()
	_Vector3.sub(v2, v1, faceto)
	Global.role.translation:setTranslation(-85, 0.496, 31.1)
	Global.role:updateFace(faceto, 0)
	Global.role:playAnima('struggle')

	local from = _Vector3.new(-85, 0.496, 31.1)
	local tar = _Vector3.new(-81, 0.496, 31.0)
	local dis = _Vector3.new()
	_Vector3.sub(tar, from, dis)

	local time1 = 2000
	local time2 = 2000
	local time3 = 1800

	Global.role.translation:mulTranslationRight(dis, time1)

	self.timer:start('tunnel', time1, function()
		local tar2 = _Vector3.new(-40, 0.496, 30.8)
		_Vector3.sub(tar2, tar, dis)
		Global.role.translation:mulTranslationRight(dis, time2)
		self.timer:stop('tunnel')
	end)

	self.timer:start('tunnel2', time1 + time3, function()
		Global.ScreenEffect:fadeOut(100)
		self.timer:stop('tunnel2')
	end)

	self.timer:start('tunnel3', time1 + time2, function()
		self:goHome()
	end)
end
Guide.goHome = function(self)
	Global.entry:goHome()
	Global.GameState:changeState('MOVIE')

	-- 等会掉落
	Global.role:releaseCCT()
	Global.CameraControl:get():followTarget()
	Global.Sound:stop()
	Global.ScreenEffect:fadeIn(200)

	local g = Global.sen:getGroup(3)
	g.functions[1]:trigger()

	Global.role:movieStruggle()
	Global.Achievement:ask('done_guide')

	self.timer:stop('tunnel3')

	local time1 = 3000
	self.timer:start('tunnel4', time1, function()
		-- 因为cct延迟创建，没拿到位置信息，要respawn一次
		Global.role:createCCT()
		Global.role:Respawn()
		self.timer:stop('tunnel4')

		_app:onPredown(function()
			local role = Global.role
			if not role or not role.isliedown then
				return
			end

			role.isliedown = false
			role.animas.standup:onStop(function()
				role.animaState:changeAnima('idle')
				Global.SwitchControl:set_input_on()
			end)
			role.animaState:changeAnima('standup')
			Global.Guide:finish()
			Global.GameState:changeState('GAME')
		end)
	end)
end
Guide.onMouseDown = function(self)
	if self.ui and self.ui.visible then
		self:hide()
	end
end

Global.GameState:onEnter(function(c)
	Global.Guide:show(true)
	Global.Sound:play('ui_hint01')
	_app:onPredown(function()
		Global.Guide:onMouseDown()
	end)
end, 'GUIDE')

Global.GameState:onLeave(function()
	Global.Guide:show(false)
end, 'GUIDE')
