
local scene = Global.Scene
local nodes = {}
scene.calc_range = function(self)
	local aabb = _AxisAlignedBox.new()
    self:getNodes(nodes)
	for i, v in next, nodes do
		if v.mesh then
			local data = v.mesh:getBoundBox(v.transform)
			local aabb2 = _AxisAlignedBox.new(_Vector3.new(data.x1, data.y1, data.z1), _Vector3.new(data.x2, data.y2, data.z2))
			-- print(v.mesh:getBoundBox(v.transform))
			_AxisAlignedBox.union(aabb, aabb2, aabb)
		end
	end

	print(aabb, aabb.min.x, aabb.min.y, aabb.min.z, aabb.max.x, aabb.max.y, aabb.max.z)
end

-- 挨个显隐节点
scene.check_node = function(self)
	self._check_data = self._check_data or {last_index = 0}
	self:getNodes(nodes)

	local last_node = nodes[self._check_data.last_index]
	if last_node then
		last_node.visible = true
	end

	local found = false
	for i = self._check_data.last_index + 1, #nodes do
		if nodes[i].mesh then
			nodes[i].visible = false
			self._check_data.last_index = i
			found = true
			break
		end
	end

	if found then
	else
		self._check_data.last_index = 1
	end

	print('check_node', self._check_data.last_index, #nodes)
end
-- 精准显隐
scene.check_node_one = function(self, index)
	self:getNodes(nodes)
	nodes[index].visible = not nodes[index].visible
end
-- 整体情况
scene.check_scene_stat = function(self)
	print('========== single node =============')
	self:getNodes(nodes)
	local tb = {}
	for i, v in ipairs(nodes) do
		if v.mesh then
			local c = v.mesh:getSubMeshCount()
			print(i, c)
			tb[c] = (tb[c] or 0) + 1
		end
	end
	print('=========== all node =======================')
	-- tb按值排序
	local tb2 = {}
	for k, v in pairs(tb) do
		table.insert(tb2, {k, v})
	end
	table.sort(tb2, function(a, b)
		return a[2] > b[2]
	end)
	-- 输出
	for i, v in ipairs(tb2) do
		print(v[1], v[2])
	end
end
-- 按submesh数量显隐
scene.check_node_by_submesh = function(self, count)
	self:getNodes(nodes)
	for i, v in ipairs(nodes) do
		if v.mesh and v.mesh:getSubMeshCount() == count then
			v.visible = not v.visible
		end
	end
end
-- pick
scene.check_pick_node = function(self)
	local pos = _sys:getMousePos()
	local result = {}
	self:pick(_rd:buildRay(pos.x, pos.y), 0xffffff, false, result)
	if result.node then
		self:getNodes(nodes)
		for i, v in ipairs(nodes) do
			if v == result.node then
				print('pick node', i)
				return i
			end
		end
	end
end