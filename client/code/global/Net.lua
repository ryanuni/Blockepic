--[[
	Net
]]

local host

_net_async_threshhold(0, 1024, 600, 100 * 1024 * 1024)

local Net = {NETS = {}, timer = _Timer.new(), NETS_DATA = {}, Delay_Time = 99999}
Global.Net = Net

local HeartBeatStr = 'HeartBeat'
local HeartBeatTime = 3 -- 3s
local ReconnectTime = 5
local TIME_DISCONNECT = 60

_G.SocketMaxLength = 16384

-- recieve (data format: len \0\0\0\0 data)
Net.onHead = function(net, data)
	local len = string.to32b(data, 1, true) - 8
	if len < 0 or len > 16384 then
		-- net:close()
		print('[Net.onHead] warning net data length: ' .. len)
	end

	-- 无长度 heartbeat
	if len == 0 then
		net:receive(9, Net.onHeartBeat, 5)
	else
		--- 更换方案，分段收取
		if len > SocketMaxLength then
			Net.NETS_DATA[net] = {len = len, last = len - SocketMaxLength}
			print("net 拼接方案", net, len)
			net:receive(SocketMaxLength, Net.onSplitBody, 5)
			return
		end
		net:receive(len, Net.onBody, 5)
	end
end
Net.onBody = function(net, data)
	net:receive(8, Net.onHead, 600)
	_callin(net, data)
end

Net.onSplitBody = function(net, data)
	local net_data = Net.NETS_DATA[net]
	if not net_data then
		net:receive(8, Net.onHead, 600)
		return
	end

	-- local len = net_data.len
	local last = net_data.last
	local str = data:tostr()
	Net.NETS_DATA[net].data = Net.NETS_DATA[net].data and Net.NETS_DATA[net].data .. str or str
	-- print("net 拼接", Net.NETS_DATA[net].data)

	if last <= 0 then
		local orgdata = Net.NETS_DATA[net].data
		net:receive(8, Net.onHead, 600)
		local name, args = _decode(orgdata)
		-- print("net 使用", name, args)
		_enqueue(_now(0, nil), net, name, args)
		Net.NETS_DATA[net] = nil
	elseif last < SocketMaxLength then
		Net.NETS_DATA[net].last = 0
		net:receive(last, Net.onSplitBody, 5)
	else
		Net.NETS_DATA[net].last = last - SocketMaxLength
		net:receive(SocketMaxLength, Net.onSplitBody, 5)
	end
end

Net.onHeartBeat = function(net, data)
	net:receive(8, Net.onHead, 600)
	local str = data:tostr()
	if str ~= HeartBeatStr then
		net:close()
		error('Heart Beat Err ' .. str)
	end

	local now = _now(0.001, nil)
	if Net.HeartBeat_Send_Time then
		Net.Delay_Time = now - Net.HeartBeat_Send_Time
	end
	Net.HeartBeat_Send_Time = nil

	Net.timer:stop('connect-timeout')
	ShowConnecting(false)
	Net.timer:start('connect-timeout', TIME_DISCONNECT * 1000, function()
		ShowConnecting(true)
	end)
end

-- send (data format: len \0\0\0\0 data)
Net.netSend = function(net, name, args, data)
	local len = #data
	if len + 8 > 1024 * 512 then
		print('[Net] WARN: ', name, 'data len', #data)
	end
	net:send(string.from32b(len + 8, true))
	net:send('\0\0\0\0')
	net:send(data)
end

Net.setOnconnectCallback = function(self, onconnect)
	self.onConnectCallback = onconnect
end
Net.sendHeartBeat = function(self, net)
	net:send(string.from32b(8, true))
	net:send('\0\0\0\0')
	net:send(HeartBeatStr)

	self.HeartBeat_Send_Time = _now(0.001, nil)
end
Net.onConnect = function(net, ip, port, myip, myport)
	print('[Net] onConnect ', net, ip, port, myip, myport)
	host = ip

	net:nagle(false)
	net:receive(8, Net.onHead, 600)
	_callout(net, Net.netSend)
	Net.Server = net
	-- heart beat
	Net.timer:start('heartbeat', HeartBeatTime * 1000, function()
		Net:sendHeartBeat(net)
	end)

	ShowConnecting(false)
	if Global.LoginUI then
		Global.LoginUI:unconnectState(false)
	end
	if Net.onConnectCallback then
		Net.onConnectCallback()
	end
end
Net.onClose = function(net, timeout, notconn, err)
	print('onClose', net, timeout, notconn, err)
	if Net.Server then
		-- Notice(Global.TEXT.CONNECT_LOST)
		ShowConnecting(true)
	end

	if Global.LoginUI then
		Global.LoginUI:unconnectState(true)
	end
	Net.timer:stop('heartbeat')
	Net.Server = nil
	Net.NETS_DATA[net] = nil
end

Net.connect = function(self)
	local addr = _sys:getGlobal('hostserver') or '0.0.0.0:4444'

	print('[Net.connect] ing', addr)
	if self.Server then
	else
		_enqueue(_now(0, nil) + ReconnectTime * 1000 * 1000, nil, 'reconnect')
		_connect(addr, self.onConnect, self.onClose, 10)
	end
end
local emptytb = {}
_G.RPC = function(func, data)
	data = data or emptytb
	if Net.Server then
		Net.Server[func](data)
	else
		-- Notice(Global.TEXT.CONNECT_OFFLINE)
		if not _sys:getGlobal("AUTOTEST") then
			print('[RPC]', func)
		end
	end
end

_G.reconnect = function()
	if Net.Server then
		_enqueue(_now(0, nil) + ReconnectTime * 1000 * 1000, nil, 'reconnect')
		return
	end

	Global.Net:connect()
end

_G.isConnected = function()
	return Net.Server ~= nil
end

-------------------------------------------------------------------------------
local ntoip = function(host)
	local a = _rshift(_and(host, 0xff000000), 24)
	local b = _rshift(_and(host, 0x00ff0000), 16)
	local c = _rshift(_and(host, 0x0000ff00), 8)
	local d = _and(host, 0x000000ff)

	return a .. '.' .. b .. '.' .. c .. '.' .. d
end

local K_Net = {}
Global.KCP_Net = K_Net
local DELAY_COUNT = 5
local calc_delay = function(n, delay)
	table.insert(n.delay_data, delay)
	if #n.delay_data > DELAY_COUNT then
		table.remove(n.delay_data, 1)
	end
	local sum = 0
	for i = 1, #n.delay_data do
		sum = sum + n.delay_data[i]
	end

	n.delay_avg = math.floor(sum / #n.delay_data)
end
K_Net.connect = function(self, onconnect, onrecv, onclose)
	local ip = ntoip(host)
	print('KCP connect', ip)
	local port = 7124
	local id = 0x11223344
	self.net = _KCP.connect(ip, port, id, function(n)
		print('======== on connect kcp', tostring(Global.Login:getAid()))
		n:send(tostring(Global.Login:getAid()))
	end, function(n, s)
		-- print('========= on recv', s)
		if s == 'ready' then
			onconnect(n)
			n.timer = _Timer.new()
			n.timer:start('', 1000, function()
				n:send(_jsonencode({timestamp = _now(0), delay = self:get_delay()}))
			end)

			Global.Delay_Display:show(true)
		else
			local data = _jsondecode(s)
			if data.timestamp then
				calc_delay(n, (_now(0) - data.timestamp) / 1000 / 2)
			else
				onrecv(n, data)
			end
		end
	end, onclose)
	self.net.delay_data = {}
	self.net.delay_avg = 999
end
-- K_Net.send = function(data)
-- 	K_Net.net:send(data)
-- end
K_Net.update = function(self)
	if self.net then
		self.net:update()
	end
end
K_Net.get_delay = function(self)
	if self.net then
		return self.net.delay_avg or 999
	else
		return 0
	end
end
K_Net.close = function(self)
	if self.net then
		self.net.timer:stop()
		self.net = nil
	end
end
_app:registerUpdate(K_Net, 1)