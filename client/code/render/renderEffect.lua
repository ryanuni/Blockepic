local RenderEffect = {}
Global.RenderEffect = RenderEffect
RenderEffect.timer = _Timer.new()

RenderEffect.glassImages = {
	[1] = {
		glass = _Image.new('T_Set2_Frame4.tga'),
		dirt = _Image.new('T_Dirt_2.tga'),
	}
}
RenderEffect.glassBroken = function(self, pp, delay, time)
	if not pp or not time then return end

	local type = math.random(#self.glassImages)
	pp.glassBroken = true
	pp.glassImage = self.glassImages[type].glass
	pp.glassUseGlassHoles = true
	pp.glassDistortionCoeffX = 0.1
	pp.glassDistortionCoeffY = 0.1
	pp.glassDistortionIntensity = 0.1
	pp.glassCrackFade = 1.0 -- 0.0 ~ 1.0
	pp.glassReflectFade = 1.0 -- 0.0 ~ 1.0
	pp.glassDirtFade = 0.0
	pp.glassCrackColor = _Color.new(_Color.White)
	pp.glassDirtImage = self.glassImages[type].dirt
	pp.glassDirtColor = _Color.new(1.0, 1.0, 1.0, 0.0)
	pp.glassUseLight = true
	pp.glassLightDirection = _Vector3.new(1.0, -1.0, -1.0)
	pp.glassLightFactorMin = 1.0 --0.0 ~ 1.0
	if not self.timer then self.timer = _Timer.new() end
	if not delay then delay = 0 end
	self.timer:start('glassBrokendelay', delay, function()
		self.timer:start('glassBroken', time, function()
			pp.glassBroken = false
			self.timer:stop('glassBroken')
		end)

		self.timer:stop('glassBrokendelay')
	end)
end
