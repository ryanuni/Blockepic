local KnotGroupManager = {}
_G.KnotGroupManager = KnotGroupManager

KnotGroupManager.new = function(self)
	self.groups = {}
end

KnotGroupManager.add = function(self, kg)
	table.insert(self.groups, kg)
end

KnotGroupManager.del = function(self, kg)
	for i, v in ipairs(self.groups) do
		if v == kg then
			table.remove(self.groups, kg)
			return
		end
	end
end

KnotGroupManager.getRootByBlocks = function(self, blocks)
	local kg_hash = {}
	for i, b in ipairs(blocks) do
		local g = b:getKnotGroup()
		local root = g:getRoot()
		kg_hash[root] = true
	end

	local kgs = {}
	for g in pairs(kg_hash) do
		table.insert(kgs, g)
	end

	return kgs, kg_hash
end

KnotGroupManager.decomposeRootByBlocks = function(self, blocks)

end

KnotGroupManager.mergeRootByBlocks = function(self, blocks)

end