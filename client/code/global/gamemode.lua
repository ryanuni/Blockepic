
--[[
	mode控制
	mode就是一个独特的游戏状态，包括独特的摄像机控制方式、按键响应、ui显示等等
	比如EDIT状态会显示编辑按钮，能够移动摄像机，转动摄像机；而MOVIE状态无法操作，没有其他UI显示
	每个mode【应该】有自己的onEnter和onLeave事件，自己保证离开时的清理工作
]]

local states = {
	INIT = {name = 'INIT', cstates = {}, leaveFunc = {}, enterFunc = {}},
	GAME = {name = 'GAME', cstates = {'CREATEROLE', 'GUIDE', 'MOVIE', 'WINTROPHY', 'WINSCORE', 'ITEM', 'NEVERUP', 'MARIO'}, leaveFunc = {}, enterFunc = {}},
		CREATEROLE = {name = 'CREATEROLE', pstate = 'GAME', cstates = {}, leaveFunc = {}, enterFunc = {}},
		GUIDE = {name = 'GUIDE', pstate = 'GAME', cstates = {}, leaveFunc = {}, enterFunc = {}},
		MOVIE = {name = 'MOVIE', pstate = 'GAME', cstates = {}, leaveFunc = {}, enterFunc = {}},
		WINTROPHY = {name = 'WINTROPHY', pstate = 'GAME', cstates = {}, leaveFunc = {}, enterFunc = {}},
		WINSCORE = {name = 'WINSCORE', pstate = 'GAME', cstates = {}, leaveFunc = {}, enterFunc = {}},
		ITEM = {name = 'ITEM', pstate = 'GAME', cstates = {}, leaveFunc = {}, enterFunc = {}},
		NEVERUP = {name = 'NEVERUP', pstate = 'GAME', cstates = {}, leaveFunc = {}, enterFunc = {}},
		MARIO = {name = 'MARIO', pstate = 'GAME', cstates = {}, leaveFunc = {}, enterFunc = {}},
	EDIT = {name = 'EDIT', cstates = {'PROPERTYEDIT'}, leaveFunc = {}, enterFunc = {}},
		PROPERTYEDIT = {name = 'PROPERTYEDIT', pstate = 'EDIT', cstates = {}, leaveFunc = {}, enterFunc = {}},
	BUILD = {name = 'BUILD', cstates = {}, leaveFunc = {}, enterFunc = {}},
	CAPTURE = {name = 'CAPTURE', cstates = {}, leaveFunc = {}, enterFunc = {}},
	TEXTUREEDIT = {name = 'TEXTUREEDIT', cstates = {}, leaveFunc = {}, enterFunc = {}},
	BUILDBRICK = {name = 'BUILDBRICK', cstates = {}, leaveFunc = {}, enterFunc = {}},
	BUILDHOUSE = {name = 'BUILDHOUSE', cstates = {}, leaveFunc = {}, enterFunc = {}},
	ROLEEDIT = {name = 'ROLEEDIT', cstates = {}, leaveFunc = {}, enterFunc = {}},
	BROWSER = {name = 'BROWSER', cstates = {}, leaveFunc = {}, enterFunc = {}},
	DRESSUP = {name = 'DRESSUP', cstates = {}, leaveFunc = {}, enterFunc = {}},
	BUILDSHAPE = {name = 'BUILDSHAPE', cstates = {}, leaveFunc = {}, enterFunc = {}},
	BUILDKNOT = {name = 'BUILDKNOT', cstates = {}, leaveFunc = {}, enterFunc = {}},
	PUZZLE = {name = 'PUZZLE', cstates = {}, leaveFunc = {}, enterFunc = {}},
	BLOCKBRAWL = {name = 'BLOCKBRAWL', cstates = {}, leaveFunc = {}, enterFunc = {}},
	BUILDFUNC = {name = 'BUILDFUNC', cstates = {}, leaveFunc = {}, enterFunc = {}},
}
for _, t in next, states do
	t.ui = {}
end

local gs = {
	state = states.INIT,
	stack_callback = {},
}

gs.isState = function(self, s)
	return s == self.state.name or s == self.state.pstate
end
gs.getChangedStates = function(self, s)
	local leavestates, enterstates = {}, {}
	local oname = self.state.name
	local nname = s
	while oname do
		table.insert(leavestates, oname)
		oname = states[oname].pstate
	end
	while nname do
		table.insert(enterstates, 1, nname)
		nname = states[nname].pstate
	end
	oname = leavestates[#leavestates]
	nname = enterstates[1]
	while oname == nname and #leavestates > 0 and #enterstates > 0 do
		table.remove(leavestates, #leavestates)
		table.remove(enterstates, 1)
		oname = leavestates[#leavestates]
		nname = enterstates[1]
	end
	return leavestates, enterstates
end

gs.changeState = function(self, s, ...)
	-- print(string.format('GameState changeState %s -> %s', self.state.name, s), debug.traceback())

	local leavestates, enterstates = self:getChangedStates(s)
	for i, v in ipairs(leavestates) do
--		print('leaveState', v)
		self:leaveState(states[v])
	end

	if self.oldStateName ~= self.state.name then
		self.oldStateName = self.state.name
	end

	_G.tempshowui = true
	Global.ui.interact:hide()
	Global.ui.rolecontroller:hide()
	Global.ObjectBag:show(false)
	Global.InputSender:init()
	Global.InputSender:start()
	Global.FrameSystem:init()
	self.state = states[s]
	for i, v in ipairs(enterstates) do
--		print('enter', v)
		self:enterState(states[v], ...)
	end
end

gs.popState = function(self)
	if self.oldStateName then
		self:changeState(self.oldStateName)
	end
end
-------------------------------------------
gs.clearCallback = function(self)
	self.stack_callback = {}
end
gs.setupCallback = function(self, cb, s)
--	print('[gs.setupCallback]', s)
	states[s].callback = cb
--	dump(cb, 1)
end
gs.useCallback = function(self, s)
	local cb = s.callback
	table.insert(self.stack_callback, cb or {})
--	print('[gs.useCallback]', cb, #self.stack_callback)
	_app:setupCallback(cb)
end
gs.popCallback = function(self)
	table.remove(self.stack_callback)
	local cb = self.stack_callback[#self.stack_callback]
--	print('[gs.popCallback]', cb, #self.stack_callback)
	_app:setupCallback(cb)
end
---------------------------------------------
gs.leaveState = function(self, state)
	self:popCallback()
	for _, f in ipairs(state.leaveFunc) do
		f()
	end
	for _, ui in ipairs(state.ui) do
		ui:onLeave()
	end
end
gs.enterState = function(self, state, ...)
	self:useCallback(state)
	for _, f in ipairs(state.enterFunc) do
		f(...)
	end
	for _, ui in ipairs(state.ui) do
		ui:onEnter()
	end
end
gs.registerUI = function(self, ui, s)
	assert(ui.onEnter)
	assert(ui.onLeave)
	table.insert(states[s].ui, ui)
end
gs.onLeave = function(self, func, s)
	table.insert(states[s].leaveFunc, func)
end
gs.onEnter = function(self, func, s)
	table.insert(states[s].enterFunc, func)
end

Global.GameState = gs

_sys:addPath('code/gamemode')
_dofile('gamemode_game.lua')
