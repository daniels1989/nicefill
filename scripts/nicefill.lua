local NiceFill = {}

NiceFill.surface_prefix = "NiceFill_"
NiceFill.tile_conditions = {
	["landfill"] = {
		"water", "deepwater", "water-green", "deepwater-green", --nauvis
	}
}
NiceFill.water_blending_mapping = {
	["deepwater"] = "water",
	["deepwater-green"] = "water-green",
}

if script.active_mods['space-age'] then
	table_merge(NiceFill.tile_conditions["landfill"], {
		--nauvis, added in base but can't be landfilled without Space Age?
		"water-mud",
		"water-shallow",

		-- gleba
		"wetland-light-green-slime",
		"wetland-green-slime",
		"wetland-light-dead-skin",
		"wetland-dead-skin",
		"wetland-pink-tentacle",
		"wetland-red-tentacle",
		"wetland-yumako",
		"wetland-jellynut",
		"wetland-blue-slime",
		"gleba-deep-lake",

		--aquilo, fulgora and vulcanus cannot be landfilled
		--aquilo uses ice-platform
		--fulgora and vulcanus use foundation
	})

	table_merge_keys(NiceFill.tile_conditions, {
		["ice-platform"] = {
			--aquilo
			"ammoniacal-ocean",
			"ammoniacal-ocean-2",
			"brash-ice",
		}
	})

	table_merge_keys(NiceFill.water_blending_mapping, {
		["gleba-deep-lake"] = "wetland-blue-slime",
		["ammoniacal-ocean"] = "brash-ice",
		["ammoniacal-ocean-2"] = "brash-ice",
	})
end

---@return string[]
function NiceFill.get_supported_tiles()
	local tiles = {}

	for name, _ in pairs(NiceFill.tile_conditions) do
		table.insert(tiles, name)
	end

	return tiles
end

---@return string[]
function NiceFill.get_replaceable_tiles()
	local tiles = {}

	for _, conditions in pairs(NiceFill.tile_conditions) do
		table_merge(tiles, conditions)
	end

	return tiles
end

---
---@param tile string Tile that NiceFill should support when it's being placed
---@param tiles string[] The tiles that `tile` can replace, these won't be generated when generating a NiceFill surface
function NiceFill.register_tile_conditions(tile, tiles)
	if NiceFill.tile_conditions[tile] == nil then
		NiceFill.tile_conditions[tile] = {}
	end

	table_merge(NiceFill.tile_conditions[tile], tiles)
end

---@param surface LuaSurface
function NiceFill.create_surface_from(surface)
	debug.print( "Creating Nicefill surface" )
	if DEBUG then log( "Creating Nicefill surface" ) end

	local map_gen_settings = surface.map_gen_settings
	if DEBUG then log( serpent.block( map_gen_settings ) ) end

	local replaceable_tiles = NiceFill.get_replaceable_tiles()

	local autoplace_controls = {
		"enemy-base", "trees", --nauvis
		"gleba_enemy_base", "gleba_plants", -- gleba
	}

	-- Disable autoplace controls
	for name, _ in pairs(map_gen_settings.autoplace_controls) do
		if table_contains(autoplace_controls, name) then
			map_gen_settings.autoplace_controls[name] = { frequency = 0, size = 0, richness = 0 }
		end
	end

	-- Disable placement of entities
	for name, _ in pairs(map_gen_settings.autoplace_settings.entity.settings) do
		map_gen_settings.autoplace_settings.entity.settings[name] = { frequency = 0, size = 0, richness = 0 }
	end

	-- Disable placement of decoratives
	for name, _ in pairs(map_gen_settings.autoplace_settings.decorative.settings) do
		map_gen_settings.autoplace_settings.decorative.settings[name] = { frequency = 0, size = 0, richness = 0 }
	end

	-- Disable placement of replaceable tiles
	for name, _ in pairs(map_gen_settings.autoplace_settings.tile.settings) do
		if table_contains(replaceable_tiles, name) then
			map_gen_settings.autoplace_settings.tile.settings[name] = { frequency = 0, size = 0, richness = 0 }
		end
	end

	-- Disable placement of replaceable tiles by reducing their probability
	-- Originally added by slippycheeze
	for _, name in pairs(replaceable_tiles) do
		map_gen_settings.property_expression_names["tile:"..name..":probability"] = "-1000"
	end

	-- Disable enemies
	map_gen_settings.peaceful_mode = true

	-- Disable cliffs
	map_gen_settings.cliff_settings.cliff_elevation_0 = 0
	map_gen_settings.cliff_settings.cliff_elevation_interval = 0

	if DEBUG then log( serpent.block( map_gen_settings ) ) end

	local nicefill_surface_name = NiceFill.get_surface_name_from(surface)

	-- Try create surface with new map gen settings
	if not pcall( game.create_surface, nicefill_surface_name, map_gen_settings ) then
		log( "NiceFill failed to create surface." )
		debug.print( "NiceFill failed to create surface. Did you disable or enable any mods mid-game ?" )
		return
	end

	if DEBUG then log( "NiceFill surface success." ) end
end

---@param surface LuaSurface
---@return LuaSurface?
function NiceFill.get_surface_from(surface)
	local nicefill_name = NiceFill.get_surface_name_from(surface)
	return game.get_surface(nicefill_name)
end

---@param surface LuaSurface
function NiceFill.get_surface_name_from(surface)
	if string.starts(surface.name, NiceFill.surface_prefix) then
		return surface.name
	end

	return NiceFill.surface_prefix .. surface.name
end

---@param surface LuaSurface?
---@return boolean
function NiceFill.is_nicefill_surface(surface)
	if surface == nil then return false end
	return string.starts(surface.name, NiceFill.surface_prefix)
end

---@param surface LuaSurface
---@param tiles Tile[]
function NiceFill.generate_chunks(surface, tiles)
	for _, tile in pairs(tiles) do
		if not surface.is_chunk_generated( { x = (tile.position.x / 32), y = (tile.position.y / 32) } ) then
			surface.request_to_generate_chunks( tile.position, 0 )
		end
	end

	surface.force_generate_chunk_requests()
end

---@param surface LuaSurface
---@param tile Tile
---@return Tile?
function NiceFill.get_nice_tile(surface, tile)
	local nice_tile = surface.get_tile( tile.position.x, tile.position.y )
	local replaceable_tiles = NiceFill.get_replaceable_tiles()

	if DEBUG then log( "NiceFill nice tile: " .. nice_tile.name ) end

	if not table_contains(replaceable_tiles, nice_tile.name) then
		return { name = nice_tile.name, position = nice_tile.position }
	end

	log(string.format(
		'NiceFill surface "%s" contains an invalid tile "%s" at position {%f, %f}',
		surface.name,
		nice_tile.name,
		math.floor(tile.position.x),
		math.floor(tile.position.y)
	))
end

---@param surface LuaSurface
---@param tiles Tile[]
---@return Tile[]
function NiceFill.get_nice_tiles(surface, tiles)
	NiceFill.generate_chunks(surface, tiles)

	---@type Tile[]
	local nice_tiles = {}

	for _, tile in pairs(tiles) do
		local nice_tile = NiceFill.get_nice_tile(surface, tile)

		if(nice_tile ~= nil) then
			table.insert( nice_tiles, nice_tile )
		end
	end

	return nice_tiles
end

---@param surface LuaSurface
---@param tiles Tile[]
---@return Tile[]
function NiceFill.get_water_blending_tiles(surface, tiles)
	---@type Tile[]
	local water_blending_tiles = {}

	if DEBUG then log(NiceFill.water_blending_mapping) end

	for _, tile in pairs(tiles) do
		if DEBUG then log(string.format('---Water blending start %d, %d', tile.position.x, tile.position.y)) end

		for y = -2,2 do
			for x = -2,2 do
				---@type MapPosition
				local temp_position = { x = (tile.position.x + x), y = (tile.position.y + y) }

				---@type LuaTile
				local temp_tile = surface.get_tile(temp_position.x, temp_position.y)

				if DEBUG then log(string.format('%s at %d, %d', temp_tile.name, x, y)) end

				if table_key_exists(NiceFill.water_blending_mapping, temp_tile.name) then
					---@type LuaEntity[]
					local temp_tile_ghosts = surface.find_entities_filtered{ position = temp_position, radius = 1, type="tile-ghost" }

					if DEBUG then
						log(string.format(
							'Replacing %s with %s at %d, $d',
							temp_tile.name,
							NiceFill.water_blending_mapping[temp_tile.name],
							temp_position.x,
							temp_position.y
						))
					end

					if #temp_tile_ghosts == 0 then
						table.insert( water_blending_tiles, {
							name = NiceFill.water_blending_mapping[temp_tile.name],
							position = temp_position
						} )
					end
				end
			end
		end

		if DEBUG then log('---Water blending end') end
	end

	return water_blending_tiles
end

---@param surface LuaSurface?
---@param tiles Tile[]
---@return boolean
function NiceFill.validate_surface(surface, tiles)
	if surface == nil then return false end

	-- Check if we're validating a NiceFill surface and return false if not
	if not NiceFill.is_nicefill_surface(surface) then return false end

	-- At this point we're validating a surface generated by NiceFill

	NiceFill.generate_chunks(surface, tiles)

	for _, tile in pairs(tiles) do
		local nice_tile = NiceFill.get_nice_tile(surface, tile)

		if(nice_tile == nil) then
			return false
		end
	end

	return true
end

---@param tiles Tile[]
---@return Tile[]
function NiceFill.filter_supported_tiles(tiles)
	---@type Tile[]
	local filtered = {}
	local supported = NiceFill.get_supported_tiles()

	for _, tile in pairs(tiles) do
		if table_contains(supported, tile.name) then
			table.insert( filtered, tile )
		end
	end

	return filtered
end

function NiceFill.delete_legacy_surfaces()
	local names = {"NiceFill"}

	for _, name in pairs(names) do
		if game.get_surface(name) ~= nil then
			game.delete_surface(name)
		end
	end
end


return NiceFill