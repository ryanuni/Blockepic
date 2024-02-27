local iosSocial = {}
Global.iOSSocial = iosSocial

-- 系统分享方案，第三方自己注册
iosSocial.requireShare = function(self, image, content)
	if _sys.os ~= 'ios' then
		print('非iOS平台')
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

iosSocial.shareResult = function(self, res)
	if res == 'success' then
		print('[iOS Social] share success')
	else
		print('[iOS Social] share error', res)
	end
end

iosSocial.extendResult = function(self, result)
	local res = string.fsplit(result, ':')

	local type, done = res[1], res[2]

	if type == 'share' then
		self:shareResult(done)
	end
end