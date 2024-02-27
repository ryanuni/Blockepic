
local editor = Global.editor
local kevents = {
	{
		k = _System.KeyC,
		func = function()
			if _sys:isKeyDown(_System.KeyCtrl) then
				Global.editor:cmd_copy()
			end
		end
	},
	{
		k = _System.KeyV,
		func = function()
			if _sys:isKeyDown(_System.KeyCtrl) then
				Global.editor:cmd_paste()
			end
		end
	},
	{
		k = _System.KeyZ,
		func = function()
			if _sys:isKeyDown(_System.KeyCtrl) then
				editor.command:undo()
			end
		end
	},
	{
		k = _System.KeyY,
		func = function()
			if _sys:isKeyDown(_System.KeyCtrl) then
				editor.command:redo()
			end
		end
	},
	{
		k = _System.KeyA,
		func = function()
			if _sys:isKeyDown(_System.KeyCtrl) then
				local b = Global.editor.selectedBlocks[1]
				if not b then return end

				local nodes = {}
				Global.sen:getNodes(nodes)

				local nbs = {}
				for i, node in ipairs(nodes) do if node.block then
					local block = node.block
					if block:getColor() == b:getColor() and block:getMtlMode() == b:getMtlMode()
						and block:getShape() == b:getShape() and block:getMaterial() == b:getMaterial() then
						table.insert(nbs, block)
					end
				end end

				Global.editor:cmd_dragSelect(nbs)
			end
		end
	},
	{
		k = _System.KeyDel,
		func = function()
			Global.editor:cmd_delBlocks()
		end
	},
	{
		k = _System.KeyS,
		func = function()
			if _sys:isKeyDown(_System.KeyCtrl) then
				Global.sen:saveLevel()
			end
		end
	},
}

local cameracontrol = {}
if _sys.os == 'win32' then
	cameracontrol.rotate = _System.MouseRight
	cameracontrol.move = _System.MouseMiddle
else
	cameracontrol.zoomAndRotate = 2
	cameracontrol.move = 1
end

Global.GameState:setupCallback({
	addKeyDownEvents = kevents,
	onClick = function(x, y)
		return Global.editor:onMouseUp(0, x, y)
	end,
	onDown = function(b, x, y)
		return Global.editor.dragSelect:onMouseDown(b, x, y)
	end,
	onMove = function(x, y)
		return Global.editor.dragSelect:onMouseMove(x, y)
	end,
	onUp = function(b, x, y)
		return Global.editor.dragSelect:onMouseUp(b, x, y)
	end,
	cameraControl = cameracontrol
}, 'EDIT')

Global.GameState:registerUI(Global.UIEdit, "EDIT")

local editCameraUp = _Vector3.new(0, 0, 1)
Global.GameState:onEnter(function()
	Global.UI:pushAndHide('normal')
	Global.SwitchControl:set_cameracontrol_on()
	Global.role:enterEdit()
	-- 进入编辑模式默认没有任何选中
	Global.editor.objectSelect.currentChooseMesh = nil

	Global.editor:OnEnterEditMode()

	Global.CameraControl:push()
	local current = Global.CameraControl:get()
	current:setOrtho(false)
	current:setViewScale(1.0, 1.0)
	current:setUp(editCameraUp)
	current:scaleD(-current.camera.radius, 200)
	current:followTarget()

	Global.RegisterValue:reset()
	Global.sen:inEdit()
	_rd.bgColor = 0xff404040
end, 'EDIT')

Global.GameState:onLeave(function()
	Global.UI:popAndShow()
	Global.role:leaveEdit()
	Global.CameraControl:pop()

	Global.editor:setSelectState(false)

	Global.editor:OnLeaveEditMode()
end, 'EDIT')