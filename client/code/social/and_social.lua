local andSocial = {}
Global.AndSocial = andSocial

-- 系统分享方案
andSocial.requireShare = function(self, image, content)
	if _sys.os ~= 'android' then
		print('非android平台')
		return
	end
	local str = ''
	if image then
		str = str .. '|picture|' .. image
	end
	if content then
		str = str .. '|content|' .. content
	end

	_sdk:command('TestSdk::cmd|requireShare|type|social' .. str)
end

andSocial.shareResult = function(self, res)
	if res == 'success' then
		print('[Android Social] share success')
	else
		print('[Android Social] share error', res)
	end
end

andSocial.extendResult = function(self, result)
	local res = string.fsplit(result, ':')

	local type, done = res[1], res[2]

	if type == 'share' then
		self:shareResult(done)
	end
end