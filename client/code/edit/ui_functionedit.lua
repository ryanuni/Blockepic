local ui = Global.ui
local propertyUI = Global.UI:new('Property.bytes')
local propertyEditor = propertyUI.functionui
ui.propertyUI = propertyUI
ui.propertyEditor = propertyEditor

local Function = _require('Function')
local Action = _require('Action')
local BombAction = _require('Action.BombAction')
local Container = _require('Container')

local DetailEditor = _require('DetailEditor')
local detailEditor = DetailEditor.new()
local detailEditorWidget = detailEditor:getWidget()

propertyEditor.visible = false
propertyEditor.currentObject = nil
propertyEditor.currentFunction = nil
propertyEditor.currentAction = nil
propertyEditor.currentEvent = nil

propertyEditor.isLinking = false
propertyEditor.sourceaction = nil
propertyEditor.sourceobject = nil
propertyEditor.checkobject = nil
propertyEditor.targetobject = nil
propertyEditor.checkfunction = nil

propertyEditor.isSelectingObject = false
propertyEditor.selectcheckobject = nil
propertyEditor.selectobjectview = nil
propertyEditor.selectlineview = nil
propertyEditor.selectlineobject = nil

local function isInGuide()
	return Global.Guide.progress == 5
end

ui.get2DPosition = function(self, xx)
	local x1, y1 = 0, 0
	local node = xx.node and xx.node or (xx.selectedEffect and xx.selectedEffect.node or nil)

	if node then
		local vec3 = Container:get(_Vector3)
		local vec2 = Container:get(_Vector2)
		node.transform:getTranslation(vec3)
		_rd:projectPoint(vec3.x, vec3.y, vec3.z, vec2)
		x1, y1 = vec2.x, vec2.y
		Container:returnBack(vec3, vec2)
	elseif xx.widget then
		local p = xx.widget:getMCRect()
		x1, y1 = p.p2.x, p.p1.y
	else
		local p = xx:getMCRect()
		x1, y1 = p.p2.x, p.p1.y
	end

	return x1, y1
end

local cur, cur1, cur2 = 0, 0, 0
local period, period1, period2 = 10, 10, 10
propertyEditor.update = function(self, e)
	if self.currentObject then
		local x, y = ui:get2DPosition(self.currentObject)
		propertyUI.back._x, propertyUI.back._y = Global.UI:UI2ScreenPos(x, y + 30)
		propertyUI.back._x = propertyUI.back._x - propertyUI.back._width / 2
	end
	if self.isLinking then
		-- 画linkingaction到checkobject或者checkfunction的线
		if propertyUI.linkingaction.visible then
			cur2 = cur2 + e / 1000
			cur2 = cur2 > period2 and 0 or cur2
			if self.checkfunction then
				local x1, y1 = ui:get2DPosition(propertyUI.linkingaction.point1)
				local x2, y2 = ui:get2DPosition(propertyUI.linkingaction.point2)
				local x3, y3 = ui:get2DPosition(self.checkfunction.item.point2)
				local x4, y4 = ui:get2DPosition(self.checkfunction.item.point1)
				_rd:drawBezierTransportCurve(x1, y1, x2, y2, x3, y3, x4, y4, cur2 / period2, 2, 0xff00ff00)
			elseif self.checkobject then
				local x1, y1 = ui:get2DPosition(propertyUI.linkingaction.point1)
				local x2, y2 = ui:get2DPosition(self.checkobject)
				_rd:drawBezierTransportCurve(x1, y1, x1 + 20, y1 + 20, x2 + 20, y2 + 20, x2, y2, cur2 / period2, 2, 0xff00ff00)
			else
				local x1, y1 = ui:get2DPosition(propertyUI.linkingaction.point1)
				local x2, y2 = ui:get2DPosition(propertyUI.linkingaction.point2)
				_rd:drawBezierTransportCurve(x1, y1, x1, y1, x2, y2, x2, y2, cur2 / period2, 2, 0xff00ff00)
			end
		end

		-- checkfunction的选择按钮位置
		local x, y = 0, 0
		if self.checkfunction then
			x, y = ui:get2DPosition(self.checkfunction.item.point4)
			x, y = x - 20, y + 20
		-- checkobject的选择按钮位置
		elseif self.checkobject then
			x, y = ui:get2DPosition(self.checkobject)
			x, y = x - propertyUI.ok._width / 2, y + 20
		end
		propertyUI.ok._x, propertyUI.ok._y = Global.UI:UI2ScreenPos(x, y)
		propertyUI.ok._y = propertyUI.ok._y - propertyUI.ok._width / 2
		propertyUI.ok._y = propertyUI.ok._y - 50
	elseif self.isSelectingObject then
		local x, y = 0, 0
		if self.selectcheckobject then
			x, y = ui:get2DPosition(self.selectcheckobject)
			x, y = x - 20, y + 20
		end
		propertyUI.ok._x, propertyUI.ok._y = Global.UI:UI2ScreenPos(x, y)
		propertyUI.ok._y = propertyUI.ok._y - propertyUI.ok._width / 2
		propertyUI.ok._y = propertyUI.ok._y - 50
	else
		-- 选中Event和对应object的连线
		if self._visible and self.currentEvent then
			cur1 = cur1 + e / 1000
			cur1 = cur1 > period1 and 0 or cur1
			local x1, y1 = ui:get2DPosition(self.currentEvent.item.point1)
			local x2, y2 = ui:get2DPosition(self.currentEvent.item.point2)
			local x3, y3 = ui:get2DPosition(self.currentEvent.owner)
			_rd:drawBezierTransportCurve(x1, y1, x2, y2, x3 + 20, y3 + 20, x3, y3, cur1 / period1, 2, 0xff00ff00)
		end
	end
	if self.visible and self.selectlineview and self.selectlineobject then
		cur2 = cur2 + e / 1000
		cur2 = cur2 > period2 and 0 or cur2
		local x1, y1 = ui:get2DPosition(self.selectlineview.widget.right.event)
		local x2, y2 = ui:get2DPosition(self.selectlineobject)
		_rd:drawBezierTransportCurve(x1, y1, x1 + 20, y1 + 20, x2 + 20, y2 + 20, x2, y2, cur2 / period2, 2, 0xff00ff00)
	end
	if self.visible and self.currentFunction and #self.currentFunction.sourceactions > 0 then
		cur = cur + e / 1000
		cur = cur > period and 0 or cur

		for i, v in ipairs(self.currentFunction.sourceactions) do
			local object = v.owner.owner
			local x1, y1 = ui:get2DPosition(object)
			local x2, y2 = ui:get2DPosition(self.currentFunction.item.point2)
			local x3, y3 = ui:get2DPosition(self.currentFunction.item.point1)
			_rd:drawBezierTransportCurve(x1, y1, x1 + 20, y1 + 20, x2, y2, x3, y3, cur / period, 2, 0xff00ff00)
		end
	end
	detailEditorWidget._visible = false
	if propertyUI._visible and propertyEditor._visible then
		local property = detailEditorWidget.parentproperty
		if property and property._visible and property.parent and property.parent._visible then
			detailEditorWidget._visible = true
			local p = property:getMCRect()
			detailEditorWidget._x, detailEditorWidget._y = Global.UI:UI2ScreenPos(p.p1.x, p.p1.y)
		end
	end
end

propertyUI.linkingaction.del.click = function()
	propertyEditor:setCurrentObject(propertyEditor.sourceobject)
	propertyEditor:setCurrentFunction(propertyEditor.sourceaction.owner)
	propertyEditor:setCurrentAction(propertyEditor.sourceaction)
	propertyEditor.isLinking = false
	rawset(propertyEditor, 'sourceaction', nil)
	rawset(propertyEditor, 'sourceobject', nil)
	propertyEditor:setCheckObject(nil)
	rawset(propertyEditor, 'targetobject', nil)
	propertyEditor:setCheckFunction(nil)
	propertyUI.linkingaction._visible = false
	propertyUI.ok._visible = false
	propertyEditor._visible = true
end

propertyUI.ok.click = function()
	if propertyEditor.checkfunction then
		propertyEditor.isLinking = false
		propertyUI.ok._visible = false
		propertyUI.linkingaction._visible = false
		propertyEditor.sourceaction:addFunction(propertyEditor.checkfunction)
		-- 有直接退出了就不需要返回到源物件的事件编辑面板了
		-- propertyEditor:setCurrentObject(propertyEditor.sourceobject)
		-- propertyEditor:setCurrentFunction(propertyEditor.sourceaction.owner)
		-- propertyEditor:setCurrentAction(propertyEditor.sourceaction)
		-- propertyEditor:setCurrentEvent(propertyEditor.checkfunction)
		propertyEditor.checkfunction = nil
		propertyEditor.checkobject = nil
		propertyEditor.targetobject = nil
		propertyUI.back.click()
		Global.editor:updateRelations()
	elseif propertyEditor.checkobject then
		rawset(propertyEditor, 'targetobject', propertyEditor.checkobject)
		if #propertyEditor.targetobject.functions == 0 then
			local naction = Action.new()
			naction.open = true
			local nfunc = Function.new()
			nfunc:addAction(naction)
			propertyEditor.targetobject:addFunction(nfunc)
		end
		local fristf = propertyEditor.targetobject.functions[1]
		propertyEditor:setCheckFunction(fristf)
		propertyEditor:setCurrentObject(propertyEditor.targetobject)
		propertyEditor:setCurrentFunction(fristf)
		local frista = fristf.actions[1]
		if frista then
			frista.open = true
			propertyEditor:setCurrentAction(fristf.actions[1])
		end

		local translation = Container:get(_Vector3)
		propertyEditor.targetobject:getTransform():getTranslation(translation)
		Global.CameraControl:get():moveLook(translation, 300, 'editFocus')
		Container:returnBack(translation)

		propertyEditor._visible = true
	elseif propertyEditor.selectcheckobject then
		confirmSelectObject(propertyEditor.selectcheckobject)
		finishSelectObject()
	end
end

propertyEditor.setCheckObject = function(self, object)
	for _, b in pairs(self.checkobject and self.checkobject:getBlocks() or {}) do
		b:setEditState()
	end
	for _, b in pairs(object and object:getBlocks() or {}) do
		b:setEditState('selected')
	end
	rawset(propertyEditor, 'checkobject', object)
	propertyUI.ok._visible = object ~= nil

	if isInGuide() and Global.sen:indexGroup(object) == 6 then
		propertyUI.ok.click()
	end
end

propertyEditor.setSelectObject = function(self, object)
	for _, b in pairs(self.selectcheckobject and self.selectcheckobject:getBlocks() or {}) do
		b:setEditState()
	end
	for _, b in pairs(object and object:getBlocks() or {}) do
		b:setEditState('selected')
	end
	rawset(propertyEditor, 'selectcheckobject', object)
	propertyUI.ok._visible = object ~= nil
end

propertyEditor.setCheckFunction = function(self, func)
	rawset(self, 'checkfunction', func)
	propertyUI.ok._visible = true
end

propertyEditor.syncEventUI = function(self)
	local action = self.currentAction
	if action == nil or action.vitem == nil then return end

	local eventui = action.vitem.item.propertytab.eventui
	eventui.list.onRenderItem = function(index, item)
		local event = action.functions[index]
		event.item = item
		item.event.selected = event == self.currentEvent

		item.event.click = function()
			self:setCurrentEvent(event)
		end
	end

	eventui.list.itemNum = #action.functions
	eventui.list._width = #action.functions * 55 - 5

	eventui.add.click = function()
		self:setCurrentEvent(nil)
		self.isLinking = true
		rawset(self, 'sourceaction', action)
		rawset(self, 'sourceobject', action.owner.owner)
		propertyUI.linkingaction._visible = true
		propertyUI.linkingaction.image._icon = action.url
		propertyUI.linkingaction.text.text = action.name
		propertyEditor._visible = false
	end

	eventui.del.click = function()
		if self.currentEvent then
			self.currentAction:delFunction(self.currentEvent)
			self:setCurrentEvent(nil)
			Global.editor:updateRelations()
		end
	end
end

propertyEditor.syncResourceUI = function(self, action, item)
	local resourcetab = item.resourcetab
	if action.class ~= Action or self.currentAction ~= action or not action.open then
		resourcetab._visible = false
		return
	end

	resourcetab.syncActions = function(self, actiontypes)
		self.list.onRenderItem = function(index, ritem)
			local atype = actiontypes[index]
			ritem.pic._icon = atype.url
			ritem.click = function()
				action.currentActionType = atype
				item.image._icon = atype.url
				item.text.text = atype.name
				item.ok._visible = atype ~= Action
				if isInGuide() then
					item.ok.click()
				end
			end
		end
		self.list.itemNum = #actiontypes
		self.list._height = 95 * math.floor(#actiontypes / 4 + 0.5) - 5
		propertyEditor:updateActionList()
	end

	resourcetab.changeActionType = function(self, type)
		if action.actionType == type then return end

		action.actionType = type
		local actiontypes = Function:getActionTypes(type)
		if isInGuide() then
			action.actionType = 'Bomb'
			actiontypes = {BombAction}
		end
		self:syncActions(actiontypes)
		self.eventbutton.visible = true
		self.functionbutton.visible = true
		self.eventbutton.selected = type == 'event'
		self.functionbutton.selected = type == 'function'
		if isInGuide() then
			self.eventbutton.visible = false
			self.functionbutton.visible = false
		end

		propertyEditor:updateActionList(propertyEditor.currentFunction)
		propertyEditor:updateListHeight()
	end

	resourcetab.eventbutton.click = function()
		resourcetab:changeActionType('event')
	end

	resourcetab.functionbutton.click = function()
		resourcetab:changeActionType('function')
	end

	if action.class == Action then
		if isInGuide() == false and action.actionType == 'Bomb' then
			action.actionType = nil
		end
		resourcetab:changeActionType(action.actionType or 'event')
	end

	item.ok.click = function()
		local index = self.currentFunction:indexAction(action)
		self.currentFunction:delAction(action)
		local naction = action.currentActionType.new()
		naction.open = true
		self.currentFunction:addAction(naction, index)
		self:setCurrentAction(naction)
		item.ok._visible = false
	end

	resourcetab._visible = true
	item._height = item.image._height + resourcetab._height
end

propertyEditor.syncPropertyUI = function(self, action, item)
	local propertytab = item.propertytab
	if action.class == Action or self.currentAction ~= action or not action.open then
		propertytab._visible = false
		return
	end

	if self.currentAction and self.currentAction.metaData then
		detailEditorWidget.parentproperty = propertytab.property
		detailEditorWidget._width = propertytab.property._width
		detailEditor:setEditObject(action)
		propertytab.property._height = detailEditorWidget._height
		propertytab.property._visible = true
		item.line1._visible = true
		propertytab.line2._y = propertytab.property._y + propertytab.property._height + 15
	else
		detailEditorWidget.parentproperty = nil
		propertytab.property._visible = false
		item.line1._visible = false
		propertytab.line2._y = 0
	end

	if action.type == 'event' then
		propertytab.eventui._y = propertytab.line2._y + propertytab.line2._height + 15
		propertytab.eventui.visible = true
		propertytab.eventui._height = propertytab.eventui.list._height
		propertytab.line2._visible = true
		propertyEditor:syncEventUI(action)
	else
		propertytab.eventui._y = propertytab.line2._y - 15
		propertytab.eventui.visible = false
		propertytab.eventui._height = 0
		propertytab.line2._visible = false
	end
	propertytab._visible = true
	item._height = item.image._height + propertytab._height
end

propertyEditor.updateActionList = function(self, func)
	if func == nil then return end

	local hitem = func.item.hitem
	local vitem = func.item.vitem
	local actions = func.actions
	hitem.shenglue._visible = #actions > 4
	hitem.list.onRenderItem = function(index, item)
		local action = actions[index]
		action.hitem = item
		item.image._icon = action.url
		item.click = function()
			action.open = true
			self:setCurrentFunction(func)
			self:setCurrentAction(action)
		end
	end
	hitem.list._width = #actions * 95 - 5
	hitem.list.itemNum = #actions
	for i, v in ipairs(actions) do
		v.hitem.selected = self.currentAction == v
	end

	hitem.button.click = function()
		self:setCurrentFunction(func)
		vitem._visible = true
		hitem._visible = false
		func.item._height = vitem._height
		self:updateListHeight()
	end
	if self.currentFunction == nil then return end

	vitem.list.onRenderItem = function(index, item)
		local action = actions[index]
		action.vitem = item
		item.copy._visible = false
		item.del._visible = false
		item.reset._visible = false
		item.item.image._icon = action.currentActionType and action.currentActionType.url or action.url
		item.item.text.text = action.currentActionType and action.currentActionType.name or action.name
		item.item.resourcetab._visible = false
		item.item.propertytab._visible = false
		item.item._height = item.item.image._height
		item.item._width = item.bg._width
		if self.currentAction == action then
			self:syncResourceUI(action, item.item)
			self:syncPropertyUI(action, item.item)
			if action.enableop then
				item.copy._visible = true
				item.del._visible = true
				item.reset._visible = true
				item.item.resourcetab._visible = false
				item.item.propertytab._visible = false
				item.item._height = item.item.image._height
				item.item._width = item.item.image._width + 60
			end
		else
			action.enableop = false
		end
		item._height = item.item._height
		item.itembutton.click = function()
			action.enableop = not action.enableop
			action.open = false
			self:setCurrentAction(action)
			self:updateActionList()
			self:updateListHeight()
		end
		item.item.button.click = function()
			if self.currentAction == action then
				action.open = not action.open
				self:setCurrentFunction(func)
				self:setCurrentAction(action)
			else
				action.open = true
				self:setCurrentFunction(func)
				self:setCurrentAction(action)
			end
		end
		item.del.click = function()
			func.owner:logoutAction(action)
			func:delAction(action)
			self:setCurrentAction(nil)
			Global.editor:updateRelations()
		end
		item.reset.click = function()
			action:resetProperty()
		end
		item.copy.click = function()
			Global.sen:syncIndex()
			local naction = action:clone()
			func:addAction(naction, index + 1)
			func.owner:loadActionFunctions(Global.sen)
			self:setCurrentAction(naction)
		end
	end
	vitem.list.itemNum = #actions
	for i, v in ipairs(actions) do
		v.vitem.selected = self.currentAction == v
	end
	vitem.list._y = #actions > 0 and 15 or 0

	vitem.add.click = function()
		if propertyEditor.isLinking then return end

		local action = Action.new()
		action.open = true
		self.currentFunction:addAction(action)
		self:setCurrentAction(action)
	end
end

propertyEditor.updateListHeight = function(self)
	local height = 0
	for i, v in ipairs(self.list:getChildren()) do
		local vheight = 0
		for p, q in ipairs(v.vitem.list:getChildren()) do
			vheight = vheight + q._height + (p > 1 and 15 or 0)
		end
		v.vitem.list._height = vheight
		v._height = v.vitem._visible and v.vitem._height or v.hitem._height
		height = height + v._height + (i > 1 and 15 or 0)
	end
	self.list._height = height
end

propertyEditor.updateFunctionList = function(self)
	if self.currentObject == nil then return end

	self.list.onRenderItem = function(index, item)
		local func = self.currentObject:getFunction(index)
		func.item = item
		item.copy._visible = false
		item.del._visible = false
		item.reset._visible = false
		item._height = item.bg._height
		item.vitem._visible = false
		item.hitem._visible = true
		self:updateActionList(func)
		if self.currentFunction == func then
			if func.enableop then
				item.vitem._visible = false
				item.hitem._visible = false
				item.copy._visible = true
				item.del._visible = true
				item.reset._visible = true
			else
				if self.currentAction then
					item.vitem._visible = true
					item.hitem._visible = false
					item._height = item.vitem._height
				else
					item.vitem._visible = false
					item.hitem._visible = true
				end
			end
		else
			func.enableop = false
		end

		item.button.click = function()
			if self.currentFunction ~= func then
				self:setCurrentFunction(func)
			else
				self:setCurrentFunction(nil)
			end
		end
		item.itembutton.click = function()
			func.enableop = not func.enableop
			self:setCurrentFunction(func)
			self:updateFunctionList()
			self:updateListHeight()
		end
		item.del.click = function()
			if propertyEditor.isLinking then return end

			for i, v in ipairs(func.actions or {}) do
				func.owner:logoutAction(v)
			end
			self.currentObject:delFunction(func)
			self:setCurrentFunction(nil)
			Global.editor:updateRelations()
		end
		item.reset.click = function()
			for i, v in ipairs(func.actions or {}) do
				func.owner:logoutAction(v)
			end
			func:clearActions()
			self:setCurrentAction(nil)
		end
		item.copy.click = function()
			Global.sen:syncIndex()
			local nfunc = func:clone()
			func.owner:addFunction(nfunc, index + 1)
			func.owner:loadActionFunctions(Global.sen)
			self:setCurrentFunction(nfunc)
		end
	end
	self.list.itemNum = #self.currentObject.functions
	for i, v in ipairs(self.currentObject.functions) do
		v.item.selected = self.currentFunction == v
	end
end

propertyEditor.add.click = function()
	local action = Action.new()
	action.open = true
	local func = Function.new()
	func:addAction(action)
	propertyEditor.currentObject:addFunction(func)
	propertyEditor:setCurrentFunction(func)
	propertyEditor:setCurrentAction(action)
end

propertyUI.back.click = function()
	if propertyEditor.isLinking then
		propertyUI.linkingaction.del.click()
	end
	propertyEditor.isSelectingObject = false
	propertyEditor.selectcheckobject = nil
	propertyEditor.selectobjectview = nil
	propertyEditor.selectlineview = nil
	propertyEditor.selectlineobject = nil
	Global.GameState:changeState('EDIT')
end

propertyEditor.setCurrentObject = function(self, object)
	for _, b in pairs(self.currentObject and self.currentObject:getBlocks() or {}) do
		b:setEditState()
	end
	for _, b in pairs(object and object:getBlocks() or {}) do
		b:setEditState('selected')
	end

	local fristfunc = object and object.functions[1] or nil
	local fristaction = fristfunc and fristfunc.actions[1] or nil
	if fristaction then
		fristaction.open = true
	end

	rawset(self, 'currentObject', object)
	rawset(self, 'currentFunction', fristfunc)
	rawset(self, 'currentAction', fristaction)
	rawset(self, 'currentEvent', nil)
	self:updateFunctionList()
	self:updateListHeight()
end

propertyEditor.setCurrentFunction = function(self, func)
	if propertyEditor.isLinking and func then
		propertyEditor:setCheckFunction(func)
	end
	rawset(self, 'currentFunction', func)
	rawset(self, 'currentAction', nil)
	rawset(self, 'currentEvent', nil)
	self:updateFunctionList()
	self:updateListHeight()
end

propertyEditor.setCurrentAction = function(self, action)
	rawset(self, 'currentAction', action)
	rawset(self, 'currentEvent', nil)
	self:updateFunctionList()
	self:updateListHeight()
	finishSelectObject()
	showSelectLine()
end

propertyEditor.setCurrentEvent = function(self, event)
	rawset(self, 'currentEvent', event)
	self:syncEventUI()
end

propertyEditor.print = function(self)
	print('currentFunction', self.currentFunction and self.currentFunction.owner:indexFunction(self.currentFunction) or -1, self.currentFunction)
	print('currentAction', self.currentFunction and self.currentFunction:indexAction(self.currentAction) or -1, self.currentAction)

	for i, v in ipairs(self.list:getChildren()) do
		for p, q in ipairs(v.vitem.list:getChildren()) do
			print('vlistitem', i, p, q._height)
		end
		print('vlist', i, v.vitem.list._height)
		print('listitem', i, v._height)
	end
	print('list', self.list._height)
end

_G.showSelectLine = function(view, object)
	rawset(propertyEditor, 'selectlineview', view)
	rawset(propertyEditor, 'selectlineobject', object)
end

_G.beginSelectObject = function(view)
	propertyEditor.isSelectingObject = true
	rawset(propertyEditor, 'selectobjectview', view)
end

_G.confirmSelectObject = function(object)
	propertyEditor.selectobjectview:onValueChanged(object)
	showSelectLine(propertyEditor.selectobjectview, object)
end

_G.finishSelectObject = function()
	if propertyEditor.isSelectingObject then
		propertyEditor.isSelectingObject = false
		propertyEditor.selectobjectview = nil
		propertyEditor:setSelectObject()
		propertyUI.ok._visible = false
	end
end