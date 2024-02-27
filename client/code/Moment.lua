local Container = _require('Container')
local Moment = {}

local function fillData(m, ndata, nfunc, name, nattr, attrdata, t)
	if not m then return end
	local str = string.format('%s.%s.%s.%s', ndata, nfunc, name, nattr)
	local array = string.fsplit(ndata, '%.')
	m[str] = {
		data = attrdata,
		type = t,
		splits = {
			name = ndata,
			data = array,
			func = nfunc,
			dstname = name,
			attr = nattr,
		},
	}
end

Moment.new = function(sen, moment)
	local m = {}
	setmetatable(m, {__index = Moment})

	m.moment = 0
	m.data = {}

	if not sen then return m end

	m.moment = moment

	local lights = {}
	local fogs = {}
	local grasses = {}
	local plants = {}
	local waters = {}

	sen.graData:getLights(lights)
	sen.graData:getFogs(fogs)
	sen.graData:getGrasses(grasses)
	sen.graData:getPlants(plants)
	sen.graData:getWaters(waters)

	for k, v in pairs(lights) do
		fillData(m.data, 'graData', 'getLight', v.name, 'color', v.color, 'color')
		fillData(m.data, 'graData', 'getLight', v.name, 'direction', v.direction, 'vec3')
		fillData(m.data, 'graData', 'getLight', v.name, 'factor', v.factor, 'float')
		fillData(m.data, 'graData', 'getLight', v.name, 'fogFactor', v.fogFactor, 'float')
		fillData(m.data, 'graData', 'getLight', v.name, 'gradualFactor', v.gradualFactor, 'float')
		fillData(m.data, 'graData', 'getLight', v.name, 'power', v.power, 'float')
		fillData(m.data, 'graData', 'getLight', v.name, 'specularFactor', v.specularFactor, 'float')
	end

	for k, v in pairs(fogs) do
		fillData(m.data, 'graData', 'getFog', v.name, 'color', v.color, 'color')
		fillData(m.data, 'graData', 'getFog', v.name, 'density', v.density, 'float')
		fillData(m.data, 'graData', 'getFog', v.name, 'down', v.down, 'float')
		fillData(m.data, 'graData', 'getFog', v.name, 'far', v.far, 'float')
		fillData(m.data, 'graData', 'getFog', v.name, 'height', v.height, 'float')
		fillData(m.data, 'graData', 'getFog', v.name, 'heightColor', v.heightColor, 'color')
		fillData(m.data, 'graData', 'getFog', v.name, 'heightFalloff', v.heightFalloff, 'float')
		fillData(m.data, 'graData', 'getFog', v.name, 'inscatteringColor', v.inscatteringColor, 'color')
		fillData(m.data, 'graData', 'getFog', v.name, 'maxOpacity', v.maxOpacity, 'float')
		fillData(m.data, 'graData', 'getFog', v.name, 'near', v.near, 'float')
		fillData(m.data, 'graData', 'getFog', v.name, 'up', v.up, 'float')
	end

	for k, v in pairs(waters) do
		fillData(m.data, 'graData', 'getWater', v.name, 'alpha', v.alpha, 'float')
		fillData(m.data, 'graData', 'getWater', v.name, 'color', v.color, 'color')
		fillData(m.data, 'graData', 'getWater', v.name, 'depth', v.depth, 'float')
		fillData(m.data, 'graData', 'getWater', v.name, 'direction1', v.direction1, 'vec2')
		fillData(m.data, 'graData', 'getWater', v.name, 'direction2', v.direction2, 'vec2')
		fillData(m.data, 'graData', 'getWater', v.name, 'distort', v.distort, 'float')
		fillData(m.data, 'graData', 'getWater', v.name, 'height', v.height, 'float')
		fillData(m.data, 'graData', 'getWater', v.name, 'lightColor', v.lightColor, 'color')
		fillData(m.data, 'graData', 'getWater', v.name, 'lightDir', v.lightDir, 'vec3')
		fillData(m.data, 'graData', 'getWater', v.name, 'lightPower', v.lightPower, 'float')
		fillData(m.data, 'graData', 'getWater', v.name, 'lightShine', v.lightShine, 'float')
		fillData(m.data, 'graData', 'getWater', v.name, 'reflectColor', v.reflectColor, 'color')
		fillData(m.data, 'graData', 'getWater', v.name, 'reflectionDistort', v.reflectionDistort, 'float')
		fillData(m.data, 'graData', 'getWater', v.name, 'reflectionPower', v.reflectionPower, 'float')
		fillData(m.data, 'graData', 'getWater', v.name, 'speed1', v.speed1, 'float')
		fillData(m.data, 'graData', 'getWater', v.name, 'speed2', v.speed2, 'float')
		fillData(m.data, 'graData', 'getWater', v.name, 'transparency', v.transparency, 'float')
		fillData(m.data, 'graData', 'getWater', v.name, 'waves', v.waves, 'float')
	end

	return m
end

Moment.lerp = function(m1, m2, factor)
	assert(m1 and m2 and factor)
	local m = Moment.new()
	for k, v in pairs(m1.data) do
		if m2.data[k] then
			if v.data and m2.data[k].data then
				fillData(m.data, v.splits.name, v.splits.func, v.splits.dstname, v.splits.attr,
				math.lerp(v.data, m2.data[k].data, factor, v.type), v.type)
			end
		end
	end

	for k, v in pairs(m2.data) do
		if not m1.data[k] then m.data[k] = v end
	end

	return m
end

Moment.apply = function(self, sen, onlyColor)
	-- v.name to sen attributes
	local skylight = {}
	local ambient = {}

	for k, v in pairs(self.data) do
		local data = v.splits.data
		local source = sen
		for k, v in pairs(data) do
			source = source[v]
		end

		local func = v.splits.func
		local dstname = v.splits.dstname
		local attr = v.splits.attr
		local iscolor = string.find(attr, 'color') or string.find(attr, 'Color')
		if onlyColor ~= true or iscolor then
			if func == 'getLight' then
				if dstname == 'skylight' then skylight[attr] = v.data end
				if dstname == 'ambient' then ambient[attr] = v.data end

				if source:getLight(dstname) then
					source:getLight(dstname)[attr] = v.data
				end
			elseif func == 'getFog' and Global.TimeOfDayManager.enableFog then
				if source:getFog(dstname) then
					source:getFog(dstname)[attr] = v.data
				end
			elseif func == 'getWater' then
				if source:getWater(dstname) then
					source:getWater(dstname)[attr] = v.data
				end
			elseif func == '' and dstname == '' then
				source[attr] = v.data
			end
		end
	end

	-- sync Shadow Water Lighting
	sen:useSkylightDirection()
end

return Moment