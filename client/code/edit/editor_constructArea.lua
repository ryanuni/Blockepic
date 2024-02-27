local Container = _require('Container')

local constructArea = {}
local tempcamera = _Camera.new()
local constructcamera = _Camera.new()
constructcamera.look:set(-0.25058, -0.34015, 2.1982007)
constructcamera.eye:set(-1.23815, 3.126423, 2.910746)
local db = _DrawBoard.new(500, 500)

-- 选中物件的2d图相对人物手的位置
local ImagePos = {
	x1 = -100,
	y1 = -100,
	x2 = 30,
	y2 = 30
}

local mat = _Matrix3D.new()
local tempmat = _Matrix3D.new()
local vec = _Vector3.new()
local ret = _Vector2.new()

local bone = _Matrix3D.new()

constructArea.constructAreaRender = function(self, e)
	if Global.GameState:isState('EDIT') == false then return end

	local tempshadowcaster = Global.role.mb.node.isShadowCaster
	Global.role.mb.node.isShadowCaster = false
	tempcamera:set(_rd.camera)

	_rd:useDrawBoard(db, _Color.Null)
	_rd.camera:set(constructcamera)
	local ambient = Global.sen.graData:getLight('ambient')
	local skylight = Global.sen.graData:getLight('skylight')
	if ambient then
		_rd:useLight(ambient)
	end
	if skylight then
		_rd:useLight(skylight)
	end

	copyMat(tempmat, Global.role.mb.mesh.transform)
	Global.role.mb.mesh.transform:set(mat)
	Global.role.mb.mesh:drawMesh()
	copyMat(Global.role.mb.mesh.transform, tempmat)
	Global.role.mb.mesh.skeleton:getBone('bip001 l hand', bone)
	bone:getTranslation(vec)
	_rd:projectPoint(vec.x, vec.y, vec.z, ret)
	if ambient then
		_rd:popLight()
	end
	if skylight then
		_rd:popLight()
	end

	if Global.editor.objectSelect.currentChooseMesh then
		local pic = Global.editor.objectSelect.currentChooseMesh:getDisplayPicture()
		local image = _Image.new(pic)
		image:drawImage(ret.x + ImagePos.x1, ret.y + ImagePos.y1, ret.x + ImagePos.x2, ret.y + ImagePos.y2) -- TODO
	end
	_rd:resetDrawBoard()

	_rd.camera:set(tempcamera)
	Global.role.mb.node.isShadowCaster = tempshadowcaster
end

constructArea.loadRoleMovie = function(self)
	Global.ui.roledb:loadMovie(db)
end

return constructArea