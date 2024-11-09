local NiceFill = {}

NiceFill.surface_prefix = "NiceFill_"
NiceFill.tile_conditions = {
	["landfill"] = {
		"water", "deepwater", "water-green", "deepwater-green", --nauvis
	}
}
NiceFill.smooth_transition_tile_mapping = {
	["deepwater"] = "water",
	["deepwater-green"] = "water-green",
}
NiceFill.smooth_transition_radius = {
	["landfill"] = {0, 0.6, 0.9}, -- 60% r1, 30% r2, 10% r3
}


if script.active_mods['space-age'] then
	NiceFillSharedUtils.table.merge(NiceFill.tile_conditions["landfill"], {
		--nauvis, added in base but can't be landfilled without Space Age?
		--Supposedly these were only used in tutorials in the base
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
		--foundation can be used most anywhere, except in oil-ocean of fulgora
	})

	NiceFillSharedUtils.table.merge_keys(NiceFill.smooth_transition_tile_mapping, {
		["gleba-deep-lake"] = "wetland-blue-slime",
	})

	if settings.global["nicefill--enable-ice-platform"].value == true then
		NiceFillSharedUtils.table.merge_keys(NiceFill.tile_conditions, {
			["ice-platform"] = {
				--aquilo
				"ammoniacal-ocean",
				"ammoniacal-ocean-2",
				"brash-ice",
			}
		})

		NiceFillSharedUtils.table.merge_keys(NiceFill.smooth_transition_tile_mapping, {
			["ammoniacal-ocean"] = "brash-ice",
			["ammoniacal-ocean-2"] = "brash-ice",
		})

		NiceFillSharedUtils.table.merge_keys(NiceFill.smooth_transition_radius, {
			["ice-platform"] = {0.8, 0.95}, -- 80% r0, 15% r1, 5% r2
		})
	end
end

---@param surface_index integer
---@param tiles Tile[]
function NiceFill.run(surface_index, tiles)
	local surface = game.get_surface(surface_index);

	if surface == nil then
		log(string.format('Unable to get a surface with index %d', surface_index))
		return
	end

	tiles = NiceFill.filter_supported_tiles(tiles)
	if #tiles == 0 then return end

	-- delete legacy surfaces, we are no longer using them
	NiceFill.delete_legacy_surfaces()

	-- Try to get the NiceFill surface for this surface
	local NiceFillSurface = NiceFill.get_surface_from(surface)

	-- Validate the NiceFill surface
	if NiceFillSurface ~= nil and not NiceFill.validate_surface(NiceFillSurface, tiles) then
		-- Delete the surface if it's invalid
		game.delete_surface(NiceFillSurface)
		NiceFillSurface = NiceFill.get_surface_from(surface) -- Should be the same as NiceFillSurface = nil
	end

	-- If there's no NiceFill surface at this point, try to create it
	if NiceFillSurface == nil then
		NiceFill.create_surface_from(surface)
		NiceFillSurface = NiceFill.get_surface_from(surface)
	end

	if NiceFillSurface == nil then
		local message = string.format('NiceFill failed to get or create a NiceFill surface for "%s".', surface.name)
		log( message )
		debug.print( message );
		return
	end

	-- Get nicer tiles
	local nice_tiles = NiceFill.get_nice_tiles(NiceFillSurface, tiles)

	if settings.global["nicefill--enable-smooth-transitions"].value == true then
		-- Get smooth transition tiles and merge with nice tiles
		local smooth_transition_tiles = NiceFill.get_smooth_transition_tiles(surface, tiles)
		NiceFillSharedUtils.table.merge(nice_tiles, smooth_transition_tiles)
	end

	nice_tiles = NiceFill.filter_unique_tile_positions(nice_tiles)

	surface.set_tiles( nice_tiles )
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
		NiceFillSharedUtils.table.merge(tiles, conditions)
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

	NiceFillSharedUtils.table.merge(NiceFill.tile_conditions[tile], tiles)
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
		if NiceFillSharedUtils.table.contains(autoplace_controls, name) then
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
		if NiceFillSharedUtils.table.contains(replaceable_tiles, name) then
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
	if NiceFill.is_nicefill_surface(surface) then
		return surface.name
	end

	return NiceFill.surface_prefix .. surface.name
end

---@param surface LuaSurface?
---@return boolean
function NiceFill.is_nicefill_surface(surface)
	if surface == nil then return false end
	return NiceFillSharedUtils.string.starts_with(surface.name, NiceFill.surface_prefix)
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

	if not NiceFillSharedUtils.table.contains(replaceable_tiles, nice_tile.name) then
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
function NiceFill.get_smooth_transition_tiles(surface, tiles)
	---@type Tile[]
	local smooth_tiles = {}

	if DEBUG then log(NiceFill.smooth_transition_tile_mapping) end

	for _, tile in pairs(tiles) do
		if DEBUG then log(string.format('---Smooth transition start %d, %d', tile.position.x, tile.position.y)) end

		local radius = 0
		local probability = math.random()
		for new_radius, probability_threshold in pairs(NiceFill.smooth_transition_radius[tile.name]) do
			if probability >= probability_threshold then
				radius = new_radius
			end
		end

		if DEBUG then log(string.format("Tile: %s, probability: %f, radius: %d", tile.name, probability, radius)) end

		for _, position in pairs(Circle.calculate(radius)) do
			---@type MapPosition
			local temp_position = { x = (tile.position.x + position.x), y = (tile.position.y + position.y) }
			if DEBUG then log(serpent.line(temp_position)) end

			---@type LuaTile
			local temp_tile = surface.get_tile(temp_position.x, temp_position.y)

			if DEBUG then log(string.format('%s at %d, %d', temp_tile.name, position.x, position.y)) end

			if NiceFillSharedUtils.table.key_exists(NiceFill.smooth_transition_tile_mapping, temp_tile.name) then
				---@type LuaEntity[]
				local temp_tile_ghosts = surface.find_entities_filtered{ position = temp_position, radius = 1, type="tile-ghost" }

				if DEBUG then
					log(string.format(
						'Replacing %s with %s at %d, %d',
						temp_tile.name,
						NiceFill.smooth_transition_tile_mapping[temp_tile.name],
						temp_position.x,
						temp_position.y
					))
				end

				if #temp_tile_ghosts == 0 then
					table.insert( smooth_tiles, {
						name = NiceFill.smooth_transition_tile_mapping[temp_tile.name],
						position = temp_position
					} )
				end
			end
		end

		if DEBUG then log('---Smooth transition end') end
	end

	return smooth_tiles
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
		if NiceFillSharedUtils.table.contains(supported, tile.name) then
			table.insert( filtered, tile )
		end
	end

	return filtered
end

---@param tiles Tile[]
function NiceFill.filter_unique_tile_positions(tiles)
	---@type Tile[]
	local filtered = {}

	---@type string[]
	local keys = {}

	for _, tile in pairs(tiles) do
		local key = string.format("%d,%d", tile.position.x, tile.position.y)
		if not NiceFillSharedUtils.table.contains(keys, key) then
			table.insert( filtered, tile )
			table.insert( keys, key )
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

---@param surface LuaSurface
function NiceFill.hide_surface(surface)
	SurfaceHelper.change_surface_visibility_for_forces(surface, true)
end

---@param force LuaForce
function NiceFill.hide_surfaces_from_force(force)
	SurfaceHelper.change_surfaces_visibility_for_force(force, true)
end

function NiceFill.hide_surfaces()
	SurfaceHelper.change_surfaces_visibility(true)
end


return NiceFill