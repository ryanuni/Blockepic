local Container = _require('Container')

local cameracontrol = {}
if _sys.os == 'win32' then
	cameracontrol.rotate = _System.MouseRight
	cameracontrol.move = _System.MouseMiddle
else
	cameracontrol.zoomAndRotate = 2
	cameracontrol.move = 1
end
Global.GameState:setupCallback({
	onClick = function(x, y)
		Global.editor:onMouseUp_PropertyEdit(x, y)
	end,
	cameraControl = cameracontrol
},
'PROPERTYEDIT')
Global.GameState:onEnter(function()
	Global.ui:showEdit(false, false)
	Global.ui.propertyEditor.visible = true
	Global.ui.propertyUI.visible = true
	Global.ui.propertyUI.back.visible = true
	Global.Operate:disable_role(true)
	local object = Global.ui.propertyEditor.currentObject
	if object then
		if object.typestr ~= 'blockui' then
			local translation = Container:get(_Vector3)
			Global.editor.selection.transform:getTranslation(translation)
			Global.CameraControl:get():setOrtho(false)
			Global.CameraControl:get():moveLook(translation, 0, 'editFocus')
			Container:returnBack(translation)
		end
	end
end, 'PROPERTYEDIT')

Global.GameState:onLeave(function()
	Global.ui:showEdit(true, true, false)
	Global.ui.propertyEditor.visible = false
	Global.ui.propertyUI.back.visible = false
	Global.Operate:disable_role(true)
	Global.ui.propertyEditor:setCurrentObject()
end, 'PROPERTYEDIT')