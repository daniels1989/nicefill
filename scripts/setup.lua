local prefix = "nicefill-tile-conditions-"

for _, item_prototype in pairs(prototypes.item) do
	if SharedUtils.string.starts_with(item_prototype.name, prefix) then
		local tile_conditions = item_prototype.get_tile_filters(defines.selection_mode.reverse_select)
		local tile_name = string.sub(item_prototype.name, #prefix + 1)

		if tile_conditions ~= nil then
			local tiles = {}
			for _, tile in pairs(tile_conditions) do
				table.insert(tiles, tile.name)
			end

			NiceFill.register_tile_conditions(tile_name, tiles)
		end
	end
end