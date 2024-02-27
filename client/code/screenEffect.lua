local ScreenEffect = {timer = _Timer.new()}

local ui = Global.UI:new('MovieCurtain.bytes', 'screen')
ui._visible = false

Global.ScreenEffect = ScreenEffect

ScreenEffect.fadeOut = function(self, time, showUI)
	-- 正在进行fade操作
	if self.isFading then
		return
	end

	time = time or 1

	_rd.screenBlender = _rd.screenBlender or _Blender.new()
	_rd.screenBlender:blend(0xffffffff, 0xff000000, time)

	if not showUI then
		self.isFading = true
		self.curAlpha = _Fairy.root._alpha
		self.unitFade = -_Fairy.root._alpha / time
	end
end
ScreenEffect.fadeIn = function(self, time)
	-- 正在进行fade操作
	if self.isFading then
		return
	end

	time = time or 1

	_rd.screenBlender = _rd.screenBlender or _Blender.new()
	_rd.screenBlender:blend(0xff000000, 0xffffffff, time)

	self.isFading = true
	self.curAlpha = _Fairy.root._alpha
	self.unitFade = (100 - _Fairy.root._alpha) / time
end
ScreenEffect.update = function(self, e)
	if not self.isFading then
		return
	end

	self.curAlpha = self.curAlpha + self.unitFade * e
	if self.curAlpha < 0 then
		self.curAlpha = 0
	end

	if self.curAlpha > 100 then
		self.curAlpha = 100
	end

	_Fairy.root._alpha = self.curAlpha

	if self.isFading and (self.curAlpha == 100 or self.curAlpha == 0) then
		self.isFading = false
		self.curAlpha = nil
		self.unitFade = nil
	end
end
ScreenEffect.setDisabled = function(self, disabled)
	self.disabled = disabled
	ui.next.visible = disabled == false
end

ScreenEffect.movieCurtainIn = function(self)
	-- print('[ScreenEffect.movieCurtainIn]', self.visible)
	if self.visible then return end

	self.visible = true
	ui:gotoAndPlay('start')
end
ScreenEffect.movieCurtainOut = function(self)
	-- print('[ScreenEffect.movieCurtainOut]', self.visible)
	if not self.visible then return end

	self.visible = false
	ui:gotoAndPlay('end')
end
ScreenEffect.movieCurtainStay = function(self)
	-- print('[ScreenEffect.movieCurtainIn]', self.visible)
	if self.visible then return end

	self.visible = true
	ui:gotoAndPlay('stay')
end
ScreenEffect.movieCurtainStayEnd = function(self)
	-- print('[ScreenEffect.movieCurtainOut]', self.visible)
	if self.visible then return end

	self.visible = true
	ui:gotoAndPlay('stayend')
end

ScreenEffect.blur = function(self, on)
	_rd.screenBlender = _rd.screenBlender or _Blender.new()
	if on then
		_rd.screenBlender:blur(0.2)
		if _rd.postProcess then
		end
	else
		_rd.screenBlender = nil
		if _rd.postProcess then
			-- if _sys.os == 'win32' then
			-- 	_rd.postProcess.ssao = true
			-- else
			-- 	_rd.postProcess.ssao = false
			-- end
		end
	end
end
ScreenEffect.dof = function(self, on, r)
	local pp = _rd.postProcess
	pp.dof = on
	if on then
		r = r or _rd.camera.radius
		pp.dofFocalDistance = r
		if r < 2.5 then --微距镜头
			pp.dofFocalRegion = 0.5
			pp.dofNearTransitionRegion = 0
			pp.dofNearBlurSize = 0
			pp.dofFarTransitionRegion = 1
			pp.dofFarBlurSize = 2
		else
			pp.dofFocalRegion = 1
			pp.dofNearTransitionRegion = 1
			pp.dofNearBlurSize = 2
			pp.dofFarTransitionRegion = 1
			pp.dofFarBlurSize = 2
		end
	end
end

ScreenEffect.onNext = function() end

ui.bg.click = function()
	if Global.ScreenEffect.disabled then return end

	Global.ScreenEffect.onNext()
end

local pfxes = {
	countdown	= { res = '3210.pfx', scale = 2 },
	warning		= { res = 'warning.pfx', scale = 0.9 },
	youwin		= { res = 'youwin.pfx', scale = 0.9, pause_time = 2000 },
	youlose		= { res = 'youlose.pfx', scale = 0.9, pause_time = 2000 },
	top1		= { res = 'top1.pfx', scale = 0.9, pause_time = 2000 },
}

ScreenEffect.showPfx = function(self, pfx, callback, x, y, scale)
	self.timer:stop()

	local u = Global.ui.fullscreenpfx
	local p = pfxes[pfx]
	if p then
		u.visible = true
		u.pfxPlayer:stopAll(true)
		local particle = u:playPfx(p.res, x or 0, y or 0, scale or p.scale, scale or p.scale)

		if p.pause_time then
			self.timer:start('ScreenEffect.pfx_pause', p.pause_time, function()
				self.timer:stop()
				particle.pause = true
			end)
		end
	else
		u.visible = false
	end

	Global.ui.fullscreenpfx.click = function()
		if callback then callback() end
	end

end

_app:registerUpdate(ScreenEffect)
