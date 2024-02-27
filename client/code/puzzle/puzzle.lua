_require('Base_Class')
_require('ExtendFile')

local PuzzleItem = Class('PuzzleItem')

PuzzleItem.outtersize = 50
PuzzleItem.innersize = 45

PuzzleItem.constructor = function(self, data)
	self.posx = 0
	self.posy = 0
end

PuzzleItem.setPos = function(self, x, y)
	self.posx = x
	self.posy = y
end

PuzzleItem.isEmpty = function(self)
	return false
end

PuzzleItem.canMove = function(self)
	assert(false, 'need to override')
end

PuzzleItem.canFall = function(self)
	assert(false, 'need to override')
end

PuzzleItem.canClear = function(self)
	assert(false, 'need to override')
end

PuzzleItem.canSelect = function(self)
	assert(false, 'need to override')
end

PuzzleItem.canColor = function(self)
	assert(false, 'need to override')
end

PuzzleItem.draw = function(self)
	assert(false, 'need to override')
end

PuzzleItem.isin = function(self, x, y)
	local itemx = (self.posx - 1) * PuzzleItem.outtersize + (PuzzleItem.outtersize - PuzzleItem.innersize) / 2
	local itemy = (self.posy - 1) * PuzzleItem.outtersize + (PuzzleItem.outtersize - PuzzleItem.innersize) / 2
	return x >= itemx and x <= itemx + PuzzleItem.innersize and y >= itemy and y <= itemy + PuzzleItem.innersize
end

PuzzleItem.tostring = function(self, head)
	assert(false, 'need to override')
end

PuzzleItem.todata = function(self)
	assert(false, 'need to override')
end

local PuzzleEmptyItem = Class('PuzzleEmptyItem', PuzzleItem)

PuzzleEmptyItem.constructor = function(self, data)
end

PuzzleEmptyItem.isEmpty = function(self)
	return true
end

PuzzleEmptyItem.canMove = function(self)
	return true
end

PuzzleEmptyItem.canFall = function(self)
	return true
end

PuzzleEmptyItem.canClear = function(self)
	return false
end

PuzzleEmptyItem.canSelect = function(self)
	return false
end

PuzzleEmptyItem.canColor = function(self)
	return false
end

PuzzleEmptyItem.draw = function(self)
end

PuzzleEmptyItem.tostring = function(self, head)
	head = head or ''
	local str = head .. '{\n'
	str = str .. head .. '\ttype = \'empty\',\n'
	str = str .. head .. '}'
	return str
end

PuzzleEmptyItem.todata = function(self)
	local data = {}
	data.type = 'empty'
	return data
end

local PuzzleBarrierItem = Class('PuzzleBarrierItem', PuzzleItem)

PuzzleBarrierItem.constructor = function(self, data)
end

PuzzleBarrierItem.canMove = function(self)
	return false
end

PuzzleBarrierItem.canFall = function(self)
	return false
end

PuzzleBarrierItem.canClear = function(self)
	return false
end

PuzzleBarrierItem.canSelect = function(self)
	return false
end

PuzzleBarrierItem.canColor = function(self)
	return false
end

PuzzleBarrierItem.draw = function(self)
	local x = (self.posx - 1) * PuzzleItem.outtersize + (PuzzleItem.outtersize - PuzzleItem.innersize) / 2
	local y = (self.posy - 1) * PuzzleItem.outtersize + (PuzzleItem.outtersize - PuzzleItem.innersize) / 2
	_rd:fillRect(x, y, x + PuzzleItem.innersize, y + PuzzleItem.innersize, 0xff000000)
end

PuzzleBarrierItem.tostring = function(self, head)
	head = head or ''
	local str = head .. '{\n'
	str = str .. head .. '\ttype = \'barrier\',\n'
	str = str .. head .. '}'
	return str
end

PuzzleBarrierItem.todata = function(self)
	local data = {}
	data.type = 'barrier'
	return data
end

local PuzzleNormalItem = Class('PuzzleNormalItem', PuzzleItem)
PuzzleNormalItem.COLORTYPE = {
	0xffff0000,
	0xff00ff00,
	0xff0000ff,
	0xff00ffff,
	0xffff00ff,
	0xffffff00,
}

PuzzleNormalItem.constructor = function(self, data)
	self.color = data.color
end

PuzzleNormalItem.canMove = function(self)
	return true
end

PuzzleNormalItem.canFall = function(self)
	return true
end

PuzzleNormalItem.canClear = function(self)
	return true
end

PuzzleNormalItem.canSelect = function(self)
	return true
end

PuzzleNormalItem.canColor = function(self)
	return true
end

PuzzleNormalItem.draw = function(self)
	local x = (self.posx - 1) * PuzzleItem.outtersize + (PuzzleItem.outtersize - PuzzleItem.innersize) / 2
	local y = (self.posy - 1) * PuzzleItem.outtersize + (PuzzleItem.outtersize - PuzzleItem.innersize) / 2
	_rd:fillRect(x, y, x + PuzzleItem.innersize, y + PuzzleItem.innersize, PuzzleNormalItem.COLORTYPE[self.color])
end

PuzzleNormalItem.tostring = function(self, head)
	head = head or ''
	local str = head .. '{\n'
	str = str .. head .. '\ttype = \'normal\',\n'
	str = str .. head .. '\tcolor = ' .. self.color .. ',\n'
	str = str .. head .. '}'
	return str
end

PuzzleNormalItem.todata = function(self)
	local data = {}
	data.type = 'normal'
	data.color = self.color
	return data
end

PuzzleItem.PuzzleItemClass = {
	empty = PuzzleEmptyItem,
	barrier = PuzzleBarrierItem,
	normal = PuzzleNormalItem,
}

local PuzzleRenderSystem = Class('PuzzleRenderSystem')
PuzzleRenderSystem.constructor = function(self)
	self.items = {}
	self.column = 0
	self.row = 0

	self.steps = {}
	self.current = 0
	self.currentGroup = 1
	self.offset = _Matrix2D.new()
	self:updateOffset()
end

PuzzleRenderSystem.init = function(self, data)
	self.column = data.column
	self.row = data.row
	for x = 1, data.column do
		self.items[x] = {}
	end
end

PuzzleRenderSystem.updateOffset = function(self)
	self.offset:setTranslation(_rd.w / 2 - PuzzleItem.outtersize * self.column / 2, _rd.h / 2 - PuzzleItem.outtersize * self.row / 2)
end

PuzzleRenderSystem.getItem = function(self, x, y)
	if x > self.column or x < 1 or y > self.row or y < 1 then return end
	return self.items[x][y]
end

PuzzleRenderSystem.switchStepGroup = function(self)
	self.currentGroup = 1 - self.currentGroup
end

PuzzleRenderSystem.pushStep = function(self, type, ...)
	local param = {...}
	if type == 'destoryItem' then
		local item = param[1]
		assert(item, 'no item')
		table.insert(self.steps, 1, {type = type, x = item.posx, y = item.posy, group = self.currentGroup})
	elseif type == 'createItem' then
		local item = param[1]
		assert(item, 'no item')
		table.insert(self.steps, 1, {type = type, x = item.posx, y = item.posy, data = item:todata(), group = self.currentGroup})
	elseif type == 'changePos' then
		local item1 = param[1]
		local item2 = param[2]
		assert(item1 and item2, 'no items')
		table.insert(self.steps, 1, {type = type, x1 = item1.posx, y1 = item1.posy, x2 = item2.posx, y2 = item2.posy, group = self.currentGroup})
	end
end

PuzzleRenderSystem.popStep = function(self)
	local steplen = #self.steps
	if steplen < 1 then return end

	local step = self.steps[steplen]
	if step.type == 'destoryItem' then
		-- TODO
	elseif step.type == 'createItem' then
		local data = step.data
		local x, y = step.x, step.y
		local itemclass = PuzzleItem.PuzzleItemClass[data.type]
		local item = itemclass.new(data)
		item:setPos(x, y)
		self.items[x][y] = item
	elseif step.type == 'changePos' then
		local x1, y1, x2, y2 = step.x1, step.y1, step.x2, step.y2
		local item1 = self.items[x1][y1]
		local item2 = self.items[x2][y2]
		self.items[x1][y1] = item2
		self.items[x2][y2] = item1
		item1:setPos(x2, y2)
		item2:setPos(x1, y1)
	end
	table.remove(self.steps, steplen)
end

PuzzleRenderSystem.popSameGroupSteps = function(self)
	local steplen = #self.steps
	if steplen < 1 then return end

	local step = self.steps[steplen]
	local group = step.group
	while (step and step.group == group) do
		self:popStep()
		step = self.steps[#self.steps]
	end
end

PuzzleRenderSystem.clearSteps = function(self)
	local steplen = #self.steps
	for i = 1, steplen do
		self:popStep()
	end
end

PuzzleRenderSystem.render = function(self)
	_rd:pushMatrix2D(self.offset)
	for x = 1, self.column do
		for y = 1, self.row do
			self:getItem(x, y):draw()
		end
	end
	_rd:popMatrix2D()
end

PuzzleRenderSystem.update = function(self, e)
	if self.current == 0 then
		local steplen = #self.steps
		if steplen > 0 then
			self:popSameGroupSteps()
			self.current = e
		end
	elseif self.current < 200 then
		self.current = self.current + e
	else
		self.current = 0
	end
end

local Puzzle = Class('Puzzle')

Puzzle.MODE = {
	INIT = 0,
	IDLE = 1,
	CHECK = 2,
	FILL = 3,
	EXCHANGE = 4,
	CHECKFINISH = 9,
	FINISH = 10,
}

Puzzle.constructor = function(self, filename)
	self.items = {}
	self.column = 0
	self.row = 0
	self.step = 0
	self.score = 0
	self.font = _Font.new('simhei', 20)
	self.mode = Puzzle.MODE.INIT
	self.filename = filename

	self.renderSystem = PuzzleRenderSystem.new()

	local data = _dofile(filename)
	assert(data, 'Puzzle load failed.')

	self:init(data)

	self.exchangeItems = {}
end

Puzzle.save = function(self, filename)
	if filename == nil then
		filename = self.filename
	end

	if filename == nil then return end

	local str = 'return {\n'
	str = str .. '\tcolumn = ' .. self.column .. ',\n'
	str = str .. '\trow = ' .. self.row .. ',\n'
	str = str .. '\titems = {\n'
	for i, v in ipairs(self.items) do
		str = str .. '\t\t{\n'
		for p, q in ipairs(v) do
			str = str .. q:tostring('\t\t\t') .. ',\n'
		end
		str = str .. '\t\t},\n'
	end
	str = str .. '\t},\n'
	str = str .. '}'

	_File.writeString(filename, str, 'utf-8')
end

-- 初始化
Puzzle.init = function(self, data)
	self.column = data.column
	self.row = data.row
	for x = 1, data.column do
		self.items[x] = {}
		for y = 1, data.row do
			self:createItem(x, y, data.items[x][y])
		end
	end

	assert(data.step, 'no step limit')
	self.step = data.step
	self.goal = data.goal

	self.renderSystem:init(data)
	self.renderSystem:clearSteps()

	self.mode = Puzzle.MODE.CHECK
end

Puzzle.addScore = function(self, score)
	self.score = self.score + score
end

Puzzle.finish = function(self)
	-- TODO. check goal.
	if self.goal and self.goal.score then
		print('gameover', self.score > self.goal.score)
	end
end

Puzzle.destoryItem = function(self, item)
	-- TODO.
	self.renderSystem:pushStep('destoryItem', item)
end

Puzzle.createItem = function(self, x, y, itemdata)
	if self.items[x][y] then
		self:destoryItem(self.items[x][y])
	end
	local itemclass = PuzzleItem.PuzzleItemClass[itemdata.type]
	local item = itemclass.new(itemdata)
	item:setPos(x, y)
	self.items[x][y] = item
	self.renderSystem:pushStep('createItem', item)
end

Puzzle.render = function(self, e)
	self.renderSystem:render(e)
	self.font:drawText(0, 50, _rd.w, 100, string.format('step : %d', self.step), _Font.hCenter + _Font.vCenter)
	if self.goal and self.goal.score then
		self.font:drawText(0, 100, _rd.w, 150, string.format('goal : %d', self.goal.score - self.score), _Font.hCenter + _Font.vCenter)
	end

	if self.mode == Puzzle.MODE.FINISH then
		if self.goal and self.goal.score and self.score > self.goal.score then
			self.font:drawText(0, 150, _rd.w, 200, 'success', _Font.hCenter + _Font.vCenter)
		elseif self.step <= 0 then
			self.font:drawText(0, 150, _rd.w, 200, 'failed', _Font.hCenter + _Font.vCenter)
		end
	end
end

Puzzle.update = function(self, e)
	self.renderSystem:update(e)
	if self.mode == Puzzle.MODE.IDLE then return end

	if self.mode == Puzzle.MODE.CHECKFINISH then
		print(self.step, self.score)
		if self.step <= 0 or (self.goal and self.goal.score and self.score > self.goal.score) then
			self:finish()
			self.mode = Puzzle.MODE.FINISH
		else
			self.mode = Puzzle.MODE.IDLE
		end
	end

	if self.mode == Puzzle.MODE.CHECK then
		if self:checkAndClear() then
			self.mode = Puzzle.MODE.FILL
		else
			self.mode = Puzzle.MODE.CHECKFINISH
		end
		return
	end

	if self.mode == Puzzle.MODE.EXCHANGE then
		if self:checkAndClear() then
			self.mode = Puzzle.MODE.FILL
		else
			self:reverseExchange()
			self.mode = Puzzle.MODE.IDLE
		end
		return
	end

	if self.mode == Puzzle.MODE.FILL then
		while (not self:fill()) do end
		while (not self:refresh()) do end
		self.mode = Puzzle.MODE.CHECK
	end
end

Puzzle.getItem = function(self, x, y)
	if x > self.column or x < 1 or y > self.row or y < 1 then return end
	return self.items[x][y]
end

-- 检测是否有可消除的item
Puzzle.check = function(self)
	for x = 1, self.column do
		for y = 1, self.row do
			local item = self:getItem(x, y)
			if item:canClear() then
				local upitem = self:getUpItem(item)
				local downitem = self:getDownItem(item)
				local leftitem = self:getLeftItem(item)
				local rightitem = self:getRightItem(item)
				local upitem1 = self:getUpItem(upitem)
				local downitem1 = self:getDownItem(downitem)
				local leftitem1 = self:getLeftItem(leftitem)
				local rightitem1 = self:getRightItem(rightitem)
				if self:isSameColor(item, upitem, downitem) or
					self:isSameColor(item, upitem, upitem1) or
					self:isSameColor(item, downitem, downitem1) or
					self:isSameColor(item, leftitem, rightitem) or
					self:isSameColor(item, leftitem, leftitem1) or
					self:isSameColor(item, rightitem, rightitem1) then
					return true
				end
			end
		end
	end
	return false
end

Puzzle.match = function(self, x, y)
	local item = self:getItem(x, y)
	if item:canColor() then
		local hitems = {}
		local vitems = {}
		local finalitems = {}

		-- 检查一行的同色物件
		table.insert(hitems, item)
		for t = 1, 2 do
			for i = 1, self.column do
				local xpos = t == 1 and (x - i) or (x + i)
				if xpos < 1 or xpos > self.column then
					break
				end
				local testitem = self:getItem(xpos, y)
				if testitem:canColor() and testitem.color == item.color then
					table.insert(hitems, testitem)
				else
					break
				end
			end
		end
		if #hitems >= 3 then
			for i, v in ipairs(hitems) do
				table.insert(finalitems, v)
			end
		end

		-- 检查行结果的列方向的同色物件
		if #hitems >= 3 then
			for _, v in ipairs(hitems) do
				for t = 1, 2 do
					for i = 1, self.row do
						local ypos = t == 1 and (y - i) or (y + i)
						if ypos < 1 or ypos > self.row then
							break
						end
						local testitem = self:getItem(v.posx, ypos)
						if testitem:canColor() and testitem.color == item.color then
							table.insert(vitems, testitem)
						else
							break
						end
					end
				end
				if #vitems < 2 then
					vitems = {}
				else
					for i, v in ipairs(vitems) do
						table.insert(finalitems, v)
					end
				end
			end
		end

		if #finalitems >= 3 then
			return finalitems
		end

		hitems = {}
		vitems = {}
		finalitems = {}

		-- 检查一列的同色物件
		table.insert(vitems, item)
		for t = 1, 2 do
			for i = 1, self.row do
				local ypos = t == 1 and (y - i) or (y + i)
				if ypos < 1 or ypos > self.row then
					break
				end
				local testitem = self:getItem(x, ypos)
				if testitem:canColor() and testitem.color == item.color then
					table.insert(vitems, testitem)
				else
					break
				end
			end
		end
		if #vitems >= 3 then
			for i, v in ipairs(vitems) do
				table.insert(finalitems, v)
			end
		end

		-- 检查列结果的行方向的同色物件
		if #vitems >= 3 then
			for _, v in ipairs(vitems) do
				for t = 1, 2 do
					for i = 1, self.column do
						local xpos = t == 1 and (x - i) or (x + i)
						if xpos < 1 or xpos > self.column then
							break
						end
						local testitem = self:getItem(xpos, v.posy)
						if testitem:canColor() and testitem.color == item.color then
							table.insert(hitems, testitem)
						else
							break
						end
					end
				end
				if #hitems < 2 then
					hitems = {}
				else
					for i, v in ipairs(hitems) do
						table.insert(finalitems, v)
					end
				end
			end
		end

		if #finalitems >= 3 then
			return finalitems
		end
	end
	return {}
end

-- 消除
Puzzle.checkAndClear = function(self)
	self.renderSystem:switchStepGroup()
	local cleared = false
	for x = 1, self.column do
		for y = 1, self.row do
			local matchlist = self:match(x, y)
			-- 可以在这里分析matchlist来生成特殊物件
			-- 消除也不一定是创建一个empty物件替换现有物件
			-- 有可能是冰块或者巧克力的附着被消除
			for i, v in ipairs(matchlist) do
				self:createItem(v.posx, v.posy, {type = 'empty'})
			end
			self:addScore(#matchlist)
			if #matchlist > 0 then
				cleared = true
			end
		end
	end
	return cleared
end

-- 填充
Puzzle.fill = function(self)
	self.renderSystem:switchStepGroup()
	local fillfinished = true
	for y = self.row, 1, -1 do
		for x = 1, self.column do
			local item = self:getItem(x, y)
			if item:canFall() then
				local downitem = self:getDownItem(item)
				if downitem then
					if downitem:isEmpty() then
						self:changePos(item, downitem)
						fillfinished = false
					else
						local temp = {}
						local ldownitem = self:getLeftItem(downitem)
						if ldownitem then
							table.insert(temp, ldownitem)
						end
						local rdownitem = self:getRightItem(downitem)
						if rdownitem then
							table.insert(temp, rdownitem)
						end
						for _, v in ipairs(temp) do
							if v:isEmpty() then
								local canfill = false
								local upitem = self:getUpItem(v)
								while upitem do
									if upitem:canFall() then
										canfill = true
										break
									end
									upitem = self:getUpItem(upitem)
								end
								if not canfill then
									self:changePos(item, v)
									fillfinished = false
									break
								end
							end
						end
					end
				end
			end
		end
	end

	for x = 1, self.column do
		local item = self:getItem(x, 1)
		if item:isEmpty() then
			self:createItem(x, 1, {type = 'normal', color = math.random(1, #PuzzleNormalItem.COLORTYPE)})
			fillfinished = false
		end
	end
	return fillfinished
end

-- 刷新 交换现有物件顺序
Puzzle.refresh = function(self)
	self.renderSystem:switchStepGroup()
	if self:check() == false and self:hasMoveStep() == false then
		for i = 1, 10 do
			local item1 = self.items[math.random(1, self.column)][math.random(1, self.row)]
			local item2 = self.items[math.random(1, self.column)][math.random(1, self.row)]
			if item1:canMove() and item2:canMove() then
				self:changePos(item1, item2)
			end
		end
		return false
	end
	return true
end

-- 判断是否有可移动操作
Puzzle.hasMoveStep = function(self)
	for x = 1, self.column do
		for y = 1, self.row do
			local item = self:getItem(x, y)
			if item:canMove() then
				local upitem = self:getUpItem(item)
				local downitem = self:getDownItem(item)
				local leftitem = self:getLeftItem(item)
				local rightitem = self:getRightItem(item)
				local temp = {}
				if self:canExchange(item, upitem) then
					table.insert(temp, {self:getUpItem(upitem), self:getUpItem(self:getUpItem(upitem))})
					table.insert(temp, {self:getRightItem(upitem), self:getRightItem(self:getRightItem(upitem))})
					table.insert(temp, {self:getLeftItem(upitem), self:getLeftItem(self:getLeftItem(upitem))})
					table.insert(temp, {self:getLeftItem(upitem), self:getRightItem(upitem)})
				end
				if self:canExchange(item, downitem) then
					table.insert(temp, {self:getDownItem(downitem), self:getDownItem(self:getDownItem(downitem))})
					table.insert(temp, {self:getRightItem(downitem), self:getRightItem(self:getRightItem(downitem))})
					table.insert(temp, {self:getLeftItem(downitem), self:getLeftItem(self:getLeftItem(downitem))})
					table.insert(temp, {self:getLeftItem(downitem), self:getRightItem(downitem)})
				end
				if self:canExchange(item, leftitem) then
					table.insert(temp, {self:getLeftItem(leftitem), self:getLeftItem(self:getLeftItem(leftitem))})
					table.insert(temp, {self:getUpItem(leftitem), self:getUpItem(self:getUpItem(leftitem))})
					table.insert(temp, {self:getDownItem(leftitem), self:getDownItem(self:getDownItem(leftitem))})
					table.insert(temp, {self:getUpItem(leftitem), self:getDownItem(leftitem)})
				end
				if self:canExchange(item, rightitem) then
					table.insert(temp, {self:getRightItem(rightitem), self:getRightItem(self:getRightItem(rightitem))})
					table.insert(temp, {self:getUpItem(rightitem), self:getUpItem(self:getUpItem(rightitem))})
					table.insert(temp, {self:getDownItem(rightitem), self:getDownItem(self:getDownItem(rightitem))})
					table.insert(temp, {self:getUpItem(rightitem), self:getDownItem(rightitem)})
				end
				for i, v in ipairs(temp) do
					if v[1] and v[2] and self:isSameColor(item, v[1], v[2]) then
						return true
					end
				end
			end
		end
	end
	return false
end

Puzzle.isSameColor = function(self, item1, item2, item3)
	if item1 == nil or item2 == nil or item3 == nil then return false end
	if item1:canColor() == false or item2:canColor() == false or item3:canColor() == false then return false end
	return item1.color == item2.color and item2.color == item3.color and item1.color ~= nil
end

Puzzle.getUpItem = function(self, item)
	if item == nil then return end
	return self:getItem(item.posx, item.posy - 1)
end

Puzzle.getDownItem = function(self, item)
	if item == nil then return end
	return self:getItem(item.posx, item.posy + 1)
end

Puzzle.getLeftItem = function(self, item)
	if item == nil then return end
	return self:getItem(item.posx - 1, item.posy)
end

Puzzle.getRightItem = function(self, item)
	if item == nil then return end
	return self:getItem(item.posx + 1, item.posy)
end

-- 局部最优的移动操作
Puzzle.bestMoveStep = function(self)

end

Puzzle.changePos = function(self, item1, item2)
	local x1, y1 = item1.posx, item1.posy
	local x2, y2 = item2.posx, item2.posy
	self.items[x1][y1] = item2
	self.items[x2][y2] = item1
	item1:setPos(x2, y2)
	item2:setPos(x1, y1)
	self.renderSystem:pushStep('changePos', item1, item2)
end

-- 交换两个物件
Puzzle.exchange = function(self, item1, item2)
	if self:canExchange(item1, item2) == false then return end

	self.exchangeItems = {item1, item2}
	self.renderSystem:switchStepGroup()
	self:changePos(item1, item2)
	self.step = self.step - 1
	self.mode = Puzzle.MODE.EXCHANGE
end

-- 撤销交换两个物件
Puzzle.reverseExchange = function(self)
	assert(#self.exchangeItems == 2, 'exchangeItems wrong number')
	self.renderSystem:switchStepGroup()
	self:changePos(self.exchangeItems[1], self.exchangeItems[2])
	self.step = self.step + 1
	self.exchangeItems = {}
end

Puzzle.canExchange = function(self, item1, item2)
	return item1 and item2 and item1:canMove() and item2:canMove() and self:isNeighbor(item1, item2)
end

-- 判断是否相邻
Puzzle.isNeighbor = function(self, item1, item2)
	return (math.abs(item1.posx - item2.posx) == 1 and item1.posy == item2.posy) or
		(math.abs(item1.posy - item2.posy) == 1 and item1.posx == item2.posx)
end

Puzzle.getItemByPos = function(self, x, y)
	local otrans = _Vector2.new()
	self.renderSystem.offset:getTranslation(otrans)
	x = x - otrans.x
	y = y - otrans.y
	for xi = 1, self.column do
		for yi = 1, self.row do
			local item = self.items[xi][yi]
			if item:isin(x, y) then
				return item
			end
		end
	end
	return nil
end

Puzzle.onDown = function(self, b, x, y)
	if self.mode ~= Puzzle.MODE.IDLE then return end

	local item = self:getItemByPos(x, y)
	if item then
		self.selectitem = item
	else
		self.selectitem = nil
	end
end

Puzzle.onUp = function(self, b, x, y)
	if self.mode ~= Puzzle.MODE.IDLE then return end
	if self.selectitem == nil then return end

	local item = self:getItemByPos(x, y)
	if item then
		self:exchange(item, self.selectitem)
	end
end

Global.GameState:setupCallback({
	onDown = function(b, x, y)
		if Global.Puzzle then
			Global.Puzzle:onDown(b, x, y)
		end
	end,
	onUp = function(b, x, y)
		if Global.Puzzle then
			Global.Puzzle:onUp(0, x, y)
		end
	end,
}, 'PUZZLE')

Global.GameState:onEnter(function(...)
	Global.UI:pushAndHide('normal')
	Global.Puzzle = Puzzle.new(...)
	Global.Puzzle.renderSystem:updateOffset()
	_app:registerUpdate(Global.Puzzle, 7)
end, 'PUZZLE')

Global.GameState:onLeave(function()
	Global.UI:popAndShow()
	_app:unregisterUpdate(Global.Puzzle)
end, 'PUZZLE')

_app:onResize(function(w, h)
	if Global.Puzzle then
		Global.Puzzle.renderSystem:updateOffset()
	end
end)