---@param haystack string
---@param needle string
---@return boolean
function string.starts(haystack, needle)
	return string.sub(haystack, 1, string.len(needle)) == needle
end

---@param haystack string
---@param needle string
---@return boolean
function string.ends(haystack, needle)
	return string.sub(haystack, string.len(needle) * -1) == needle
end

---@param x number
---@return number
function math.absfloor(x)
	if x > 0 then
		return math.floor(x)
	end

	return math.ceil(x)
end

---@param x number
---@return number
function math.round(x)
	return math.floor(x + 0.5)
end

---@param table table
---@return boolean
function has_value(table, needle)
	for _, value in ipairs(table) do
        if value == needle then
            return true
        end
    end

    return false
end

---@param table1 table
---@param table2 table
function merge(table1, table2)
	for _, value in pairs(table2) do
		table.insert(table1, value)
	end
end