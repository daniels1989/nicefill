SharedUtils = require 'shared/util'

function find_placed_by_item(tile)
	for _, item in pairs(data.raw['item']) do
		if item.place_as_tile ~= nil and item.place_as_tile.result == tile.name then
			return item
		end
	end
end

function create_decon_planner(tile, item)
	if item.place_as_tile == nil or item.place_as_tile.tile_condition == nil then
		return
	end

	local decon = table.deepcopy(data.raw['deconstruction-item']['deconstruction-planner'])
	decon.name = "nicefill-tile-conditions-" .. tile.name
	decon.hidden = true
	decon.hidden_in_factoriopedia = true

	decon.burnt_result = item.name
	decon.select.tile_filters = item.place_as_tile.tile_condition

	decon.alt_select.tile_filters = decon.select.tile_filters

	decon.reverse_select = decon.select
	decon.alt_reverse_select = decon.alt_select
	decon.super_forced_select = decon.select

	data:extend({
		decon
	})
end

local disallowed_tiles = {
	-- These are needed for agriculture on gleba
	"artificial-jellynut-soil",
	"artificial-yumako-soil",
	"overgrowth-jellynut-soil",
	"overgrowth-yumako-soil",

	-- foundation works just fine, but want to test more with it
	"foundation"
}

---@type data.TilePrototype[]
local foundation_tiles = {}

for _, tile in pairs(data.raw.tile) do
	if tile.is_foundation and not SharedUtils.table.contains(disallowed_tiles, tile.name) then
		table.insert(foundation_tiles, tile)
	end
end

for _, tile in pairs(foundation_tiles) do
	local item = find_placed_by_item(tile)
	if item ~= nil then
		create_decon_planner(tile, item)
	end
end
