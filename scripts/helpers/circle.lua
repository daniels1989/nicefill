local Circle = { calculated = {} }

---@param radius integer
---@return MapPosition[]
function Circle.calculate(radius)
	if radius == 0 then
		return {}
	end

	if SharedUtils.table.key_exists(Circle.calculated, radius) then
		return Circle.calculated[radius]
	end

	---@type MapPosition[]
	local _positions = Circle.quadrant(radius)
	---@type MapPosition[]
	local positions = {}

	for _, position in pairs(_positions) do
		table.insert(positions, position)
		if position.x ~= 0 then table.insert(positions, {x = position.x * -1, y = position.y}) end
		if position.y ~= 0 then table.insert(positions, {x = position.x, y = position.y * -1}) end

		if position.x ~= 0 and position.y ~= 0 then
			table.insert(positions, {x = position.x * -1, y = position.y * -1})
		end
	end

	Circle.calculated[radius] = positions

	return positions
end

---@param radius integer
---@return MapPosition[]
function Circle.quadrant(radius)
	---@type MapPosition[]
	local positions = {}
	for y = 0,radius do
		for x = 0,radius do
			local in_circle = radius == 1 or ((x * x) + (y * y) - (radius * radius)) <= 0
			if in_circle and not( x == 0 and y == 0) then
				table.insert(positions, {x = x, y = y})
			end
		end
	end

	return positions
end

return Circle