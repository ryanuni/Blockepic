local social = {}
Global.Social = social

if _sys.os == 'android' then
	_dofile('and_social.lua')
elseif _sys.os == 'ios' then
	_dofile('ios_social.lua')
end

social.share = function(self, image, content)
	if _sys.os == 'win32' or _sys.os == 'mac' then
		print('PC 无分享')
		return
	end

	-- ios 分享使用系统分享接口，Android 自己接平台sdk
	if _sys.os == 'ios' then
		Global.iOSSocial:requireShare(image, content)
	elseif _sys.os == 'android' then
		Global.AndSocial:requireShare(image, content)
	end
end

social.extendResult = function(self, result)
	local res = string.fsplit(result, '|')
	if res[1] ~= 'social' then
		return
	end

	local channel, done = res[2], res[3]

	if _sys.os == 'ios' then
		if channel == 'native' then
			Global.iOSSocial:extendResult(done)
		end
	elseif _sys.os == 'android' then
		if channel == 'native' then
			Global.AndSocial:extendResult(done)
		end
	end
end