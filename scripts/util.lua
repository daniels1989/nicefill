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

---@param table table
---@return boolean
function table_contains(table, needle)
	for _, value in pairs(table) do
        if value == needle then
            return true
        end
    end

    return false
end

---@param table table
---@return boolean
function table_key_exists(table, needle)
	for key, _ in pairs(table) do
        if key == needle then
            return true
        end
    end

    return false
end

---@param table1 table
---@param table2 table
function table_merge(table1, table2)
	for _, value in pairs(table2) do
		table.insert(table1, value)
	end
end

---@param table1 table
---@param table2 table
function table_merge_keys(table1, table2)
	for key, value in pairs(table2) do
		table1[key] = value
	end
	return table1
end

---@param tile LuaTilePrototype
---@param old_tiles OldTileAndPosition[]
---@return Tile[]
function convert_old_tile_and_position(tile, old_tiles)
	---@type Tile[]
	local tiles = {}

	for _, old_tile in pairs(old_tiles) do
		table.insert(tiles, {name = tile.name, position = old_tile.position})
	end

	return tiles
end