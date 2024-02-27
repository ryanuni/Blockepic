
local rb = {}
Global.Role_Base_xl = rb

_G.setRoleMoveParam = function(jumpheight, jumptime, runmax, runmin, runacctime, runfadetime, runforcefadetime)
	jumpheight = jumpheight or 2.4
	jumptime = jumptime or 300
	runmax = runmax or 0.003
	runmin = runmin or 0.0006
	runacctime = runacctime or 1000
	runfadetime = runfadetime or 100
	runforcefadetime = runforcefadetime or 0.01

	-- 跳跃高度
	_G.JUMP_HEIGHT = jumpheight
	-- 跳跃时间（半程）
	_G.JUMP_TIME = jumptime
	-- 跑最大速度(ms)
	_G.RUN_MAX = runmax
	-- 起步速度(ms)
	_G.RUN_MIN = runmin
	-- 加速到最大需要的时间
	_G.RUN_ACC_TIME = runacctime
	-- 减速时间
	_G.RUN_FADE_TIME = runfadetime

	_G.G = 2 * jumpheight / jumptime / jumptime
	_G.VZ_INIT = G * jumptime
	_G.FALL_MAX = VZ_INIT * 2
	_G.RUN_A = runmax / runacctime
	_G.RUN_STOP_A = runmax / runfadetime
	_G.RUN_STOP_FORCE_A = runmax / runforcefadetime
end

setRoleMoveParam()

local function getAngle(v1, v2)
	return v1:dot(v2)
end
rb.calc_input = function(self, dir, e)
	self.mb.dir:set(dir)

	self.mb.dir.z = 0
	self.logic.dir.z = 0
	-- 水平速度
	if self.mb.dir.x ~= 0 or self.mb.dir.y ~= 0 then
		if self.logic.needAcc then
			if getAngle(self.mb.dir, self.logic.dir) < 0 then
				self.logic.vxy = math.max(self.logic.vxy - RUN_STOP_FORCE_A * e, 0)
			else
				if self.logic.vxy < RUN_MIN then
					self.logic.vxy = RUN_MIN
				end
				if self.logic.speedUp then
					self.logic.vxy = RUN_MAX * 1.5
				elseif self.logic.vxy >= RUN_MAX then
					self.logic.vxy = math.max(self.logic.vxy - RUN_A * e, RUN_MAX)
				else
					self.logic.vxy = math.min(self.logic.vxy + RUN_A * e, RUN_MAX)
				end
				self.logic.dir:set(self.mb.dir)
			end
		else
			self.logic.vxy = RUN_MAX
			self.logic.dir:set(self.mb.dir)
		end
	else
		self.logic.vxy = math.max(self.logic.vxy - RUN_STOP_A * e, 0)
	end
	self.logic.dir:normalize()
	self.logic.dir:scale(self.logic.vxy * e)

	-- zspeed
	local v0 = self.logic.vz
	local dis = v0 * e - 0.5 * G * e * e
	self.logic.vz = self.logic.vz - G * e
	if math.abs(self.logic.vz) > FALL_MAX then
		self.logic.vz = FALL_MAX * -1
	end
	self.logic.dir.z = dis
	self.logic.zdis = self.logic.zdis + dis

	if self.cct then
		self.cct:input(self.logic.dir)
	end
end
rb.calc_anima_state = function(self)
	local flag = self.cct.collisionFlag

	if self.logic.rebound then
		self.logic.rebound = false
	elseif _and(flag, 4) > 0 then
		-- 落地
		self.logic.jumpState = 0
		self.logic.vz = 0
		self.logic.zdis = 0
	else
		-- 空中
		if self.logic.jumpState == 0 then
			if self.logic.vz < 0 and self.logic.vz > -0.006 then

			else
				self.logic.jumpState = 1
			end
		end
	end
	-- 磕头
	if _and(flag, 2) > 0 then
		self.logic.vz = math.min(-0.0001, self.logic.vz)
	end

	-- TODO 上面的logic.vz换个地方设置
	if Global.dungeon then return end

	local runstate = 'idle'
	if self.logic.vxy > 0 then
		runstate = 'run'
	end
	self.animaState:update(self.logic.vz, self.logic.zdis, self.logic.jumpState, runstate)
end
rb.jump = function(self, light)
	if light then
		-- print('反弹', self.logic.jumpState)
		self.logic.rebound = true
		self.logic.vz = VZ_INIT * 0.5

		return
	end

	if self.logic.jumpState == 1 then
		if self.logic.vz > VZ_INIT * 0.2 then
			return
		end
	end

	if self.logic.jumpState < self.logic.jumpLimit then
		self.logic.vz = VZ_INIT
		if self.logic.vxy >= RUN_MAX * 0.95 then
			self.logic.vz = self.logic.vz * 1.1
			-- print('加速跳')
		end
		self.logic.jumpState = self.logic.jumpState + 1
	end
end