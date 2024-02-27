
local ui = Global.UI
local mcs = {}
local rtdata = {l_w = 10, r_w = 10, up = 0}
local debugflag = 0
ui.safeArea_flushOne = function(self, l, r)
	if l then
		l._width = rtdata.l_w
	end
	if r then
		r._width = rtdata.r_w
	end
end
ui.safeArea_flush = function(self)
	for _, t in next, mcs do
		self:safeArea_flushOne(t.left, t.right)
	end
end
ui.safeArea_update = function(self)
	local r = _sys.safeArea
	local l_w = 10
	local r_w = 10
	if _app:isScreenH() then
		l_w = math.max(l_w, r.x1)
		r_w = math.max(r_w, (_rd.w - r.x2) / (_Fairy.root._xscale / 100))

		-- fixed
		l_w = 135
		r_w = 135
	end

	rtdata.l_w = l_w
	rtdata.r_w = r_w
	rtdata.up = r.y1
	if _sys:getGlobal('AUTOTEST') then
		rtdata.l_w = 0
	end

	if debugflag > 0 then
		rtdata.l_w = debugflag * 20
		rtdata.r_w = debugflag * 20
		rtdata.up = debugflag * 20
	end

	self:safeArea_flush()
end
ui.safeArea_getLW = function(self)
	return rtdata.l_w
end
ui.safeArea_getRW = function(self)
	return rtdata.r_w
end
ui.safeArea_getUP = function(self)
	return rtdata.up
end
ui.safeArea_add = function(self, u)
	if u.safearea_right or u.safearea_left then
		mcs[u] = {left = u.safearea_left, right = u.safearea_right}
	end
end
ui.safeArea_del = function(self, u)
	mcs[u] = nil
end

ui.safeArea_debug = function(self)
	debugflag = debugflag + 1
	if debugflag > 3 then
		debugflag = 0
	end
end