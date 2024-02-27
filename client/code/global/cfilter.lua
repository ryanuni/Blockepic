local filter = {}
Global.cFilter = filter

filter.init = function(self)
	if self.filter then
		return
	end

	self.filter = _Filter.new()
	self.filter.replacer = '*'
	self.filter:addFile('cfg_no_word.flt', 7000)
end

filter.replace = function(self, str)
	if not self.filter then
		return
	end

	local res = self.filter:filter(str)

	return res
end

filter.check = function(self, str)
	if not self.filter then
		return
	end

	local res = self.filter:filter(str)

	return res == str
end

filter.checkName = function(self, str)
	if not self.filter then
		return
	end

	local res = self.filter:filter(str)

	res = string.gsub(res, " ", "")
	res = string.gsub(res, "/", "")
	res = string.gsub(res, "\\", "")

	return res == str
end

filter.checkIslandName = function(self, str)
	if not self.filter then
		return
	end

	local res = self.filter:filter(str)

	res = string.gsub(res, "/", "")
	res = string.gsub(res, "\\", "")

	return res == str
end

filter:init()