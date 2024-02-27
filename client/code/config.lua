if _sys:getGlobal('version') == nil then
	_sys:setGlobal('version', 'alpha1')
end

if _sys:getGlobal('hostserver') == "www.blockepic.com:7001" then
	_sys:setGlobal('hostserver', 'game.blockepic.com:7001')
end

if _sys:getGlobal('reportserver') == "www.blockepic.com:4445" then
	_sys:setGlobal('reportserver', 'game.blockepic.com:4445')
end

local os = _sys.os
function _System.isMobile(self)
	return os == 'android' or os == 'ios'
end

if _sys:getGlobal('PCPackage') or _sys:getGlobal('datapath') then
	_sys.currentFolder = _sys.userLocalAppDataPath .. '\\' .. _sys:getGlobal('datapath')
	_debug.isPopupException = false
	_G.CHECK_VERSION = true
end

_G.ENABLE_KEY = true
if _sys:getGlobal('PCRelease') then
	_G.ENABLE_KEY = false
end

_debug.reportError = true
if _sys:getGlobal("AUTOTEST") or _sys:getGlobal("xl") then
	_debug.reportError = false
end

if _sys:isMobile() then
	_sys.fpsLimit = 30
else
	_sys.fpsLimit = 60
end

_sys.showStat = false
_sys.showVersion = false
_sys.gpuSkinning = false
_sys.instanceNodesRender = true
_G.PickChangeShape = false

if _sys.os ~= 'win32' then
	_sys.fileExist = _sys.fileExist2
end

_G.useOldShadow = true
_G.useRecordShader = true
_G.RECORDSHADER = false
_G.useAsyncShader = true
if _sys:getGlobal('AUTOTEST') then
	_G.useAsyncShader = false
end

_G.enableInsMaterial = true
_G.RECORDMATERIAL = false

if _sys:getGlobal('OnlyWallet') == "true" then
	_G.OnlyWalletConnect = true
else
	_G.OnlyWalletConnect = false
end

_G.GenMirrorMesh = false
_G.showDBGraffiti = false

_G.enableActorFile = false

_sys:addPath('res')
if _sys.os ~= 'win32' then
	_sys:mapFont('Supersonic Rocketship', 'SupersonicRocketship')
	_sys:mapFont('Berlin Sans FB Demi', 'BRLNSDB')
	_sys:mapFont('Berlin Sans FB', 'BRLNSR')
	_sys:mapFont('Comic Sans MS', 'Comic Sans MS')
	_sys:mapFont('CORBELB', 'CORBEL')
	_sys:mapFont('Half Bold Pixel-7', 'Half Bold Pixel-7')
	if _sys.os == 'mac' then
		_sys:mapFont('SimHei', 'Menlo')
	else
		_sys:mapFont('SimHei', 'SIMHEI')
	end
else
	_sys:installFont('Comic Sans MS.ttf', 'Comic Sans MS')
	_sys:installFont('SupersonicRocketship.ttf', 'Supersonic Rocketship')
	_sys:installFont('BRLNSDB.ttf', 'Berlin Sans FB Demi')
	_sys:installFont('BRLNSR.ttf', 'Berlin Sans FB')
	_sys:installFont('CORBELB.ttf', 'CORBEL')
	_sys:installFont('Half Bold Pixel-7.ttf', 'Half Bold Pixel-7')
end