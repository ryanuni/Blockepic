local BuildBrick = _G.BuildBrick
BuildBrick.debug_group = function(self)
	print('======== debug_group ========')
	local i = 0
	for _, g in pairs(self.BlockGroups) do
		i = i + 1
		print(i, g, 'isparent:' .. tostring(g.parent))
		for ii, b in ipairs(g) do
			print(b)
		end
	end
end
BuildBrick.debug_rt = function(self)
	print('======== debug_rt ========')
	print('rt_group', self.rt_selectedGroups[1])
	for i, b in ipairs(self.rt_selectedBlocks) do
		print(b, b.rtdata.state)
	end
	print('======== debug_rt end ========')
end