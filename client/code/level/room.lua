
local room = {funcs = {}}
Global.Room_New = room
-- client call
-- room:Join({count = 4, game = 'puzzle_brawl'})
local funcs_check = {
	'waiting_update',
	'waiting_leave',
	'prepare',
	'start',
	'do_op',
	'finish',
}

room.Join = function(self, cfg, funcs)
	-- print('room:Join')
	RPC('Room_Action', {Action = 'join', Data = {cfg = cfg}})

	for _, k in pairs(funcs_check) do
		if not funcs[k] then
			dump(cfg)
			assert(false, 'room:Join funcs error')
		end
	end
	self.funcs = funcs
end
room.Leave = function(self)
	-- print('room:Leave')
	RPC('Room_Action', {Action = 'leave'})
end
room.Ready = function(self)
	RPC('Room_Action', {Action = 'ready'})
end
room.DoOp = function(self, op, aid)
	-- print('room:DoOp')
	RPC('Room_Action', {Action = 'op', Data = op, Aid = aid})
end
room.Single_Record = function(self, g, s, eid)
	RPC('Room_Action', {Action = 'single_record', Data = {game = g, score = s, eventid = eid}})
end
-- receive from server
room.clean = function(self)
	self.cfg = nil
	self.rtdata = nil
end
room.waiting_update = function(self)
	self.funcs.waiting_update(self.count, self.cfg.count)
end
room.join = function(self)
	-- print('room:join')

	self.count = self.count + 1
	self:waiting_update()
end
room.new = function(self, cfg, count)
	print('room:new')
	self:clean()

	self.cfg = cfg

	self.count = count

	self:waiting_update()
end
room.leave = function(self, pid)
	print('room:leave', pid)
	if pid == Global.Login:getAid() then
		-- leave waiting
		self.funcs.waiting_leave()
	else
		self.count = self.count - 1
		self:waiting_update()
	end
end
room.prepare = function(self, ...)
	print('room:prepare')
	self.funcs.prepare(...)
end
room.start = function(self)
	self.funcs.start()
end
room.op = function(self, data)
	-- print('room:op', dump(data))
	self.funcs.do_op(data)
end
room.finish = function(self, rank)
	self.funcs.finish(rank)
end

-- delay display ----------------------------------------------------
_dofile('delay_display.lua')
------------------------------------------------------
define.Room_Action{Action = '', Data = {}}
when{}
function Room_Action(Action, Data)
	if Action == 'new' then
		room:new(Data.cfg, Data.count)
	elseif Action == 'join' then
		room:join()
	elseif Action == 'leave' then
		room:leave(Data.Pid)
	elseif Action == 'prepare' then
		room:prepare(Data.obj, Data.players, Data.randomseed, Data.data)
	elseif Action == 'start' then
		room:start()
	elseif Action == 'finish' then
		room:finish(Data)
	elseif Action == 'op' then
		room:op(Data)
	elseif Action == 'delay' then
		Global.Delay_Display:update_data(Data)
	else
		print('Room_Action [NYI]', Action, dump(Data))
	end
end

------------------------------------------------------
room.Single_Game = function(self, obj)
	Global.downloadWhole(obj, function()
		local func
		func = function()
			Global.entry:goDungeon(obj, nil, {restart_func = func, eid = nil})
		end
		func()
	end)
end
room.Join_Game = function(self, obj, count, game)
	self:Join({count = count, game = game, gid = obj.id}, {
		waiting_update = function(current, total)
			-- print('waiting_update', current, total, debug.traceback())
			Global.Browser:show_waiting(true, current, total)
		end,
		waiting_leave = function()
			-- print('waiting_leave', debug.traceback())
			Global.Browser:dec_waiting()
		end,
		prepare = function(o, players, randomseed, data)
			-- print('prepare')
			local ready = 2
			local go_func = function()
				ready = ready - 1
				if ready == 0 then
					Global.entry:goDungeon(o, players, {online = true}, randomseed, data)
				end
			end
			Global.downloadWhole(o, function()
				go_func()
			end, function(p)
				-- print('preoooo', p)
			end)
			Global.Timer:add('gomultigame', 3000, function()
				print('=gogogogogogo')
				-- Global.NeverUpEntry:updateMatchUI()
				go_func()
			end)
		end,
		start = function()
			-- print('start', debug.traceback())
			Global.dungeon:prepare_to_start()
		end,
		do_op = function(data)
			-- print('do_op', data, debug.traceback())
			Global.dungeon:doOperation(data)
		end,
		finish = function(rank)
			print('finish', dump(rank), debug.traceback())
		end
	})
end