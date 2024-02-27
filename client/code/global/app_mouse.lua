---@diagnostic disable: redundant-parameter

local cc = Global.CameraControl
local funcs = {}

local predown = function()
	if funcs.predown then
		funcs.predown()
	end
end

local premove = function(x, y, fid, count)
	if funcs.premove then
		funcs.premove(x, y, fid, count)
	end
end

local postmove = function(x, y, fid, count)
	if funcs.postmove then
		funcs.postmove(x, y, fid, count)
	end
end

local tick = 0
local currentFid = -1
local touchData = {}
_app:onMouseDown(function(b, x, y)
	touchData[b] = {x = x, y = y}
	if b == 0 then
		tick = _now(0)
	end

	cc:onStart(x, y, 1, 1)
	if funcs.onDown then
		if funcs.onDown(b, x, y) then
			return
		end
	end
end, predown)
_app:onTouchBegin(function(x, y, count, id)
	touchData[id] = {x = x, y = y}
	cc:onStart(x, y, id, count)
	if count == 1 then
		-- 对于down、move、up事件，只允许一个手指
		currentFid = id
		if funcs.onDown then
			if funcs.onDown(0, x, y) then
				return
			end
		end
	else
		if currentFid ~= -1 then
			if funcs.onUp then
				local d = touchData[currentFid]
				funcs.onUp(0, d.x, d.y, count, id)
			end

			if funcs.onMultiDown then
				funcs.onMultiDown(x, y, id, count)
			end
		end
		currentFid = -1
	end
end, predown)
_app:onTouchClick(function(x, y)
	if funcs.click then
		funcs.click(x, y)
	end
end)
----------------------------------------------
_app:onMouseUp(function(b, x, y)
	if not touchData[b] then return end
	-- print('onMouseUp', b, x, y, CurrentFrame())
	local x0, y0 = touchData[b].x, touchData[b].y
	touchData[b] = nil
	cc:onStop(x, y, 1, 1)
--	print('_now(0) - tick', _now(0) - tick)
	if b == 0 then
		if _now(0) - tick <= 500 * 1000 then
			if x0 == x and y0 == y then
--				print('click')
				if funcs.click then
					funcs.click(x, y)
				end
				return
			end
		end
	end

--	print('up')
	if funcs.onUp then
		funcs.onUp(b, x, y)
	end
end)
_app:onTouchEnd(function(x, y, count, id)
	cc:onStop(x, y, id, count)
	if count == 1 and currentFid == id then
		if funcs.onUp then
			funcs.onUp(0, x, y)
		end
	else
		if funcs.onMultiUp then
			funcs.onMultiUp(x, y, id, count)
		end
	end
end)
-----------------------------------------------
_app:onMouseMove(function(x, y)
	if next(touchData) then
		cc:onMove(x, y, 1, 1)
		if funcs.onMove then
			if funcs.onMove(x, y, 1) then
				return
			end
		end
	end
end, premove, postmove)

_app:onTouchMove(function(x, y, count, id)
	if count == 1 and currentFid == id then
		if funcs.onMove then
			if funcs.onMove(x, y, id) then
				return
			end
		end
	else
		if funcs.onMultiMove then
			funcs.onMultiMove(x, y, id, count)
		end
	end

	cc:onMove(x, y, id, count)
end, premove, postmove)
-----------------------------------------------
-- TODO.
_app:onTouchZoom(function(d, count)
	if funcs.onZoom then
		funcs.onZoom(d)
	end
end)
-----------------------------------------------
-- TODO.
local defaultmousewheel = function(d)
	if not TEMP_WHEEL_ENABLED() then return end
	local dis = math.max(cc:get():getScale(), 5) * 0.2
	cc:zoomAtom(d * 0.5 * dis)
end

funcs.mouseWheel = defaultmousewheel
funcs.magnify = defaultmousewheel

_app:onMouseWheel(function(d)
	if funcs.mouseWheel then
		funcs.mouseWheel(d)
	end
end)
_app:onMagnify(function(d)
	if funcs.magnify then
		funcs.magnify(d)
	end
end)
-----------------------------------------------
_app.onMouseDown = function()
	assert(nil, 'onMouseDown不要重写')
end
_app.onMouseUp = function()
	assert(nil, 'onMouseUp不要重写')
end
_app.onMouseMove = function()
	assert(nil, 'onMouseMove不要重写')
end
_app.onTouchBegin = function()
	assert(nil, 'onTouchBegin不要重写')
end
_app.onTouchEnd = function()
	assert(nil, 'onTouchEnd不要重写')
end
_app.onTouchMove = function()
	assert(nil, 'onTouchMove不要重写')
end
_app.onTouchClick = function()
	assert(nil, 'onTouchClick不要重写')
end
_app.onTouchZoom = function()
	assert(nil, 'onTouchZoom不要重写')
end
_app.onMouseWheel = function()
	assert(nil, 'onMouseWheel不要重写')
end
_app.onMagnify = function()
	assert(nil, 'onMagnify不要重写')
end
-----------------------------------------------
-- 对外
_app.onClick = function(self, func)
	-- x, y
	funcs.click = func
end
_app.onMove = function(self, func)
	-- x, y, fid, count
	funcs.onMove = func
end
_app.onDown = function(self, func)
	-- b, x, y
	funcs.onDown = func
end
_app.onUp = function(self, func)
	-- b, x, y, fid, count
	funcs.onUp = func
end
-- 1指触摸->多指时
_app.onTouchMultiDown = function(self, func)
	funcs.onMultiDown = func
end
_app.onTouchMultiMove = function(self, func)
	funcs.onMultiMove = func
end
_app.onTouchMultiUp = function(self, func)
	funcs.onMultiUp = func
end
_app.onPredown = function(self, func)
	funcs.predown = func
end
_app.onPremove = function(self, func)
	funcs.premove = func
end
_app.onPostmove = function(self, func)
	funcs.postmove = func
end
_app.onZoom = function(self, func)
	funcs.onZoom = func
end
_app.clearMouse = function(self)
	funcs = {}
	funcs.mouseWheel = defaultmousewheel
	funcs.magnify = defaultmousewheel
end
_app.onWheel = function(self, func)
	funcs.mouseWheel = func or defaultmousewheel
end