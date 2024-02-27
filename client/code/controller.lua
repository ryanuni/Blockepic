local Container = _require('Container')

local new_cct = function(sen)
	local cct = sen:addController(_PhysicsController.Box)
	cct.position_last = _Vector3.new()

	return cct
end

function _G.CreateCCT(sen, node)
	local cct = new_cct(sen)

	cct.stepOffset = 0.11
	cct.halfHeight = 0.5
	cct.halfSide = 0.3
	cct.halfForward = 0.3
	cct.contactOffset = 0.02
	-- cct.height = 0.5
	-- cct.radius = 0.25

	cct.input = function(self, dir)
		self.displacement.x = dir.x
		self.displacement.y = dir.y
		self.displacement.z = dir.z
	end

	return cct
end

function _G.CreateCCTByShape(sen, node)
	local cct = new_cct(sen)

	UpdateCCT(cct, node)

	cct.input = function(self, dir)
		self.displacement.x = dir.x
		self.displacement.y = dir.y
		self.displacement.z = dir.z
	end

	return cct
end

function _G.UpdateCCT(cct, node)
	local size = Container:get(_Vector3)
	local ab = Container:get(_AxisAlignedBox)
	node:getAABB(ab)
	ab:getSize(size)

	cct.stepOffset = 0.11
	cct.halfHeight = size.z / 2 - cct.contactOffset
	cct.halfSide = 0.3
	cct.halfForward = 0.3
	Container:returnBack(size, ab)
end
