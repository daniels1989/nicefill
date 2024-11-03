if not table.contains then
	---@param table table
	---@return boolean
	function table.contains(table, needle)
		for _, value in pairs(table) do
			if value == needle then
				return true
			end
		end

		return false
	end
end

if not table.key_exists then
	---@param table table
	---@return boolean
	function table.key_exists(table, needle)
		for key, _ in pairs(table) do
			if key == needle then
				return true
			end
		end

		return false
	end
end

if not table.merge then
	---@param table1 table
	---@param table2 table
	function table.merge(table1, table2)
		for _, value in pairs(table2) do
			table.insert(table1, value)
		end
	end
end

if not table.merge_keys then
	---@param table1 table
	---@param table2 table
	function table.merge_keys(table1, table2)
		for key, value in pairs(table2) do
			table1[key] = value
		end
		return table1
	end
end
