local Util = {}

---@param tile LuaTilePrototype
---@param old_tiles OldTileAndPosition[]
---@return Tile[]
function Util.convert_old_tile_and_position(tile, old_tiles)
	---@type Tile[]
	local tiles = {}

	for _, old_tile in pairs(old_tiles) do
		table.insert(tiles, {name = tile.name, position = old_tile.position})
	end

	return tiles
end

return Util