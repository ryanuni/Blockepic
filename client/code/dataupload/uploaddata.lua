-- login
-- login_relogin
-- logout
local du = {}

-- du.tasks = Global.SaveManager:Register('datatask'
du.tasks = {}

du.init = function(self)
	self.system = _sys.os
	self.device = _sys.machine
	self.uuid = _sys.uuid
--	self.uuid = '156156'

	self.uploadUrl = _sys:getGlobal('reportserver') or '127.0.0.1:4445'
	self.uploadUrl = self.uploadUrl .. '/data_upload'
end
du.uploadData = function(self)
	local function Upload(id, task)
--		print('UPLOAD', self.uploadUrl, task)
		_sys:httpPost(self.uploadUrl, task, function(result)
			local tb = _jsondecode(result)
			local res = tb and tb.res
			if res == 'success' then
				self.tasks[id] = nil
				-- Global.SaveManager:Save()
			end
		end)
	end

	for id, task in pairs(self.tasks) do
		Upload(id, task)
	end
end
du.new = function(self, action, p1, p2, p3)
	local aid = Global.Login:getAid()
	local time = Global.Login:getServerTime()

	local body = string.format([[aid=%d&device=%s&system=%s&uuid=%s&action=%s]],
	aid, self.device, self.system, self.uuid, action)
	if p1 then
		body = body .. '&param1=' .. p1
	end
	if p2 then
		body = body .. '&param2=' .. p2
	end
	if p3 then
		body = body .. '&param3=' .. p3
	end

	-- local taskid = aid .. '_' .. time .. '_' .. action
	-- self.tasks[taskid] = body
	self.tasks[1] = body
	-- Global.SaveManager:Save()

	self:uploadData()
end

du:init()

_G.UPLOAD_DATA = function(a, p1, p2, p3)
	du:new(a, p1, p2, p3)
end