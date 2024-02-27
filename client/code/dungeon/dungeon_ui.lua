---@diagnostic disable: undefined-field, inject-field

local d = Global.Dungeon_TEMP
d.ui_show = function(self, istest)
	if self.ui then
		self:ui_init_life()
		self.ui.result.visible = false
		return
	end

	self.ui = Global.UI:new('NeverUp.bytes')

	-- game
	local mc_game = self.ui.game
	local allinfo = mc_game.allinfo
	allinfo.visible = false
	self:ui_init_life()

	mc_game.timer.visible = false

	local floors_ui = mc_game.floors
	floors_ui.n0.visible = false
	floors_ui.target.edgePower = 20
	floors_ui.target.text = 0
	floors_ui.visible = false

	mc_game.reset.visible = istest
	mc_game.reset.click = function()
		Global.role:Respawn()
	end

	mc_game.back.click = function()
		self:show_pause_menu()
	end

	local menu = self.ui.menu
	menu.title.target.text = self.mode.obj.title

	-- pause
	local mc_pause = menu.pause
	mc_pause.visible = false
	mc_pause.mc_pause.visible = not self.mode.online
	mc_pause.continue.title.text = 'Continue'
	mc_pause.continue.click = function()
		self:resume()
	end

	-- if self.mode.restart_func then
	-- 	mc_pause.restart.visible = true
	-- else
	-- 	mc_pause.restart.visible = false
	-- end
	mc_pause.restart.click = function()
		-- confirm
		Confirm('Confirm to restart?',
		function()
			self:restart()
		end)
	end

	mc_pause.quit.click = function()
		Confirm('Confirm to exit?',
		function()
			if self.mode.online then
				Global.Room_New:DoOp({act = 'finish'})
			end

			self:over()
			Global.entry:back(function()
				if Global.GameState:isState('BUILDBRICK') then
					Global.BuildBrick:reuseCamera()
				end
			end)
		end)
	end

	-- result
	local mc_result = self.ui.menu.result
	mc_result.visible = false
	mc_result.quit.click = function()
		if self.mode.online then
			self.timer:start('showFinish', 300, function()
				self:goBackShowRank(self.rank)
				self.timer:stop('showFinish')
			end)
		end

		self:over()
		Global.entry:back(function()
			if Global.GameState:isState('BUILDBRICK') then
				Global.BuildBrick:reuseCamera()
			end
		end)
	end

	mc_result.restart.click = function()
		self:restart()
	end

	self:ui_show_game()
end
d.ui_hide = function(self)
	if self.ui then
		self.ui:removeMovieClip()
		self.ui = nil
	end
end
-----------------------------------------
d.set_ui = function(self, k, s)
	local mc_game = self.ui.game
	local mc
	if k == 'Life' then
		mc = mc_game.allinfo
	elseif k == 'Score' then
		mc = mc_game.floors
	elseif k == 'Timer' then
		mc = mc_game.timer
	else
		print('[NYI]unknown ui key: ' .. k)
	end

	mc.visible = s
end
-----------------------------------------
d.ui_init_life = function(self)
	local ps = Global.dungeon:get_players()
	local mc = self.ui.game.allinfo

	self.ui.life_data = {}

	mc.onRenderItem = function(index, item)
		local p = ps[index]
		self.ui.life_data[p] = {mc = item, life_mc = {}, life = 0, maxlife = 0}
		self:ui_update_life(p)
		item.name.text = p.name
	end
	mc.itemNum = #ps
end
d.ui_update_life = function(self, p)
	local data = self.ui.life_data[p]
	local item = data.mc
	local maxlife = p:attr_get('MaxLife')

	if data.maxlife ~= maxlife then
		if maxlife == 1 then
			item.lifes.itemNum = 0
		else
			data.life_mc = {}
			item.lifes.onRenderItem = function(i, it)
				-- if 
				data.life_mc[i] = it
			end
			item.lifes.itemNum = maxlife
		end

		if data.maxlife < maxlife then
            if data.maxlife > 0 then
                for i = data.maxlife + 1, maxlife do
                    data.life_mc[i]:gotoAndPlay('del')
                end
            end
		end

		data.maxlife = maxlife
		data.life = math.min(data.life, maxlife)

        for i = 1, data.life do
            data.life_mc[i]:gotoAndPlay('add')
        end
	end

	local life = p:attr_get('Life')
	if life > data.life then
		for i = data.life + 1, life do
			data.life_mc[i]:gotoAndPlay('add')
		end
	else
		for i = life + 1, data.life do
			data.life_mc[i]:gotoAndPlay('del')
		end
	end
	data.life = life
end
-----------------------------------------
d.ui_update_score = function(self, p)
	local s = p:attr_get('Score')
	local floors_ui = self.ui.game.floors
	if s < 0 then
		-- self.ui.floors.visible = false
	else
		-- self.ui.floors.visible = true
		floors_ui.target.text = s
	end
end
-----------------------------------------
d.ui_show_game = function(self)
	self.ui.game.visible = true
	self.ui.menu.visible = false

	Global.AddHotKeyFunc(_System.KeyESC, function()
		return self.ui and self.ui.visible
	end, function()
		self:show_pause_menu()
	end)
end
-----------------------------------------
d.ui_show_result = function(self, result)
	local mc_game = self.ui.game
	mc_game.visible = false
	self.ui.menu.visible = true

	self.ui.menu.pause.visible = false

	local mc = self.ui.menu.result
	mc.visible = true

	if result == 'Win' then
		mc.mc_win.visible = true
		mc.mc_lose.visible = false
	elseif result == 'Lose' then
		mc.mc_win.visible = false
		mc.mc_lose.visible = true
	else
		mc.mc_win.visible = false
		mc.mc_lose.visible = false
	end

	if self.mode.online then
		local rank = Global.role:attr_get('Rank')
		mc.rank.rank.text = 'Rank'
		mc.rank.target.text = '#' .. rank
	else
		mc.rank.visible = false
	end

	if mc_game.timer.visible then
		mc.timer.visible = true
		mc.timer.rank.text = 'Time'
		mc.timer.target.text = mc_game.timer.target.text
	else
		mc.timer.visible = false
	end
	if mc_game.floors.visible then
		mc.score.visible = true
		mc.score.rank.text = 'Score'
		mc.score.target.text = mc_game.floors.target.text
	else
		mc.score.visible = false
	end
end
-----------------------------------------
d.ui_show_pause = function(self)
	local mc_game = self.ui.game
	mc_game.visible = false
	self.ui.menu.visible = true

	self.ui.menu.result.visible = false

	local mc = self.ui.menu.pause
	mc.visible = true

	if mc_game.timer.visible then
		mc.timer.visible = true
		mc.timer.rank.text = 'Time'
		mc.timer.target.text = mc_game.timer.target.text
	else
		mc.timer.visible = false
	end
	if mc_game.floors.visible then
		mc.score.visible = true
		mc.score.rank.text = 'Score'
		mc.score.target.text = mc_game.floors.target.text
	else
		mc.score.visible = false
	end
end
-----------------------------------------
d.ui_update_timer = function(self)
	local fid = Global.FrameSystem:GetFid()
	local t = fid * 20
	-- hour min sec
	local h = math.floor(t / 3600000)
	local m = math.floor((t - h * 3600000) / 60000)
	local s = math.floor((t - h * 3600000 - m * 60000) / 1000)

	self.ui.game.timer.target.text = string.format('%02d:%02d:%02d', h, m, s)
end