_G.Version = {}
Version.version = _sys:getGlobal('version')
Version.channel = _sys:getGlobal('channel') or ''
_G.Featurelist = {
	sharehome = 1,
	showitem = 1
}
Version.isDemo = function(self)
	return self.version == 'demo'
end
Version.isAlpha1 = function(self)
	return self.version == 'alpha1'
end
Version.getChannel = function(self)
	return self.channel
end