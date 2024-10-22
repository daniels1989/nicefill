local NiceFill = {}

NiceFill.surface_prefix = "NiceFill_"
NiceFill.replaceable_tiles = {
	"water", "deepwater", "water-green", "deepwater-green", --nauvis
}

if(script.active_mods['space-age']) then
	table_merge(NiceFill.replaceable_tiles, {
		"water-mud", "water-shallow", --nauvis, added in base but can't be landfilled without Space Age?

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
	})
end

---@param surface LuaSurface
function NiceFill.create_surface_from(surface)
	debug.print( "Creating Nicefill surface" )
	if DEBUG then log( "Creating Nicefill surface" ) end

	local map_gen_settings = surface.map_gen_settings
	if DEBUG then log( serpent.block( map_gen_settings ) ) end

	---@type AutoplaceControl
	local autoplace_none = { frequency = 0, size = 0, richness = 0 }

	local autoplace_controls = {
		"enemy-base", "trees", --nauvis
		"gleba_enemy_base", "gleba_plants", -- gleba
	}

	-- Disable autoplace controls
	for name, _ in pairs(map_gen_settings.autoplace_controls) do
		if table_contains(autoplace_controls, name) then
			map_gen_settings.autoplace_controls[name] = autoplace_none
		end
	end

	-- Disable placement of entities
	for name, _ in pairs(map_gen_settings.autoplace_settings.entity.settings) do
		map_gen_settings.autoplace_settings.entity.settings[name] = autoplace_none
	end

	-- Disable placement of decoratives
	for name, _ in pairs(map_gen_settings.autoplace_settings.decorative.settings) do
		map_gen_settings.autoplace_settings.decorative.settings[name] = autoplace_none
	end

	-- Disable placement of replaceable tiles
	for name, _ in pairs(map_gen_settings.autoplace_settings.tile.settings) do
		if table_contains(NiceFill.replaceable_tiles, name) then
			map_gen_settings.autoplace_settings.tile.settings[name] = autoplace_none
		end
	end

	-- Disable placement of replaceable tiles by reducing their probability
	-- Originally added by slippycheeze
	for _, name in pairs(NiceFill.replaceable_tiles) do
		map_gen_settings.property_expression_names["tile:"..name..":probability"] = "-1000"
	end

	-- Disable starting area and enemies
	map_gen_settings.starting_area = 0
	map_gen_settings.starting_points = {}
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

	-- TODO move to create surface event
	if remote.interfaces["RSO"] then -- RSO compatibility
		if pcall(remote.call, "RSO", "ignoreSurface", nicefill_surface_name) then
			if DEBUG then log( "NiceFill surface registered with RSO." ) end
		else
			log( "NiceFill surface failed to register with RSO" )
			debug.print( "NiceFill failed to register surface with RSO" )
		end
	end
end

---@param surface LuaSurface
---@return LuaSurface?
function NiceFill.get_surface_from(surface)
	local nicefill_name = NiceFill.get_surface_name_from(surface)
	return game.get_surface(nicefill_name)
end

---@param surface LuaSurface
function NiceFill.get_surface_name_from(surface)
	if(string.starts(surface.name, NiceFill.surface_prefix)) then
		return surface.name
	end

	return NiceFill.surface_prefix .. surface.name
end

---@param surface LuaSurface?
---@return boolean
function NiceFill.is_nicefill_surface(surface)
	if(surface == nil) then return false end
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

	if DEBUG then log(serpent.block( nice_tile )) end

	if(not table_contains(NiceFill.replaceable_tiles, nice_tile.name)) then
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
---@return Tile[]
function NiceFill.get_tiles(surface, tiles)
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

---@param surface LuaSurface?
---@param tiles Tile[]
---@return boolean
function NiceFill.validate_surface(surface, tiles)
	if(surface == nil) then return false end

	-- Check if we're validating a NiceFill surface and return false if not
	if( not NiceFill.is_nicefill_surface(surface)) then return false end

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

function NiceFill.delete_legacy_surfaces()
	local names = {"NiceFill"}

	for _, name in pairs(names) do
		if game.get_surface(name) ~= nil then
			game.delete_surface(name)
		end
	end
end


return NiceFill