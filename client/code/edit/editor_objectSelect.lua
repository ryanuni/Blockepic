local objectSelect = {
	editMenuBlockIndex = 1,
	editMenuObjectIndex = 1,
	editMenuFObjectIndex = 1,
	currentChooseMesh = nil,
	currentChooseMeshTrans = _Matrix3D.new(),
}

--编辑面板
objectSelect.setEditMenuBlockIndex = function(self, index)
	self.editMenuBlockIndex = index
end

objectSelect.getEditMenuBlockIndex = function(self)
	return self.editMenuBlockIndex
end

objectSelect.setEditMenuObjectIndex = function(self, index)
	self.editMenuObjectIndex = index
end

objectSelect.getEditMenuObjectIndex = function(self)
	return self.editMenuObjectIndex
end

objectSelect.setEditMenuFObjectIndex = function(self, index)
	self.editMenuFObjectIndex = index
end

objectSelect.getEditMenuFObjectIndex = function(self)
	return self.editMenuFObjectIndex
end

objectSelect.setCurrentChooseMesh = function(self, mesh)
	-- 只要有选择则为托举
	if Global.role then
		Global.role.animaState:changeAnima('float2')
		self.currentChooseMesh = mesh
		self.currentChooseMeshTrans:set(mesh.transform)
		local bb = mesh:getBoundBox()
		self.currentChooseMeshTrans:mulTranslationRight(bb.x1, 0, 0)
	end
end

objectSelect.setCurrentChooseBlock = function(self, shapeid, transform, colorid, roughness, materialid)
	local data = {
		shape = shapeid,
		color = colorid or 1,
		roughness = roughness or 1,
		material = materialid or 1,
	}

	local block = Global.sen:createBlock(data)

	if transform then
		block.node.transform:set(transform)
		block:updateSpace()
	end

	Global.editor.objectSelect:setCurrentChooseMesh(block.node.mesh)

	Global.editor:cmd_clickSelect(block)
	return block
end

objectSelect.setCurrentChooseBlockUI = function(self, shapeid, colorid, roughness, materialid)
	local data = {
		shape = shapeid,
		color = colorid or 1,
		roughness = roughness or 1,
		material = materialid or 1,
	}

	local blockui = Global.sen:createBlockUI(data)
	blockui:setMode('Edit')

	Global.editor.objectSelect:setCurrentChooseMesh(blockui.meshes[1])

	Global.editor:cmd_clickSelectUI(blockui)
	return blockui
end

objectSelect.getCurrentChoose = function(self)
	return self.currentChoose
end

return objectSelect