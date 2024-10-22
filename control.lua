DEBUG = false

function debug_print(message, ...)
    if not DEBUG then
        return
    end

    local args = table.pack(...)
    for i = 1, args.n do
        if type(args[i]) == 'table' then
            args[i] = serpent.block(args[i])
        end
    end

	game.print(string.format(message, table.unpack(args, 1, args.n)))
end

function string.starts(String,Start)
   return string.sub(String,1,string.len(Start))==Start
end

function absfloor( x )
	if x > 0 then
		return math.floor(x)
	end

	return math.ceil(x)
end

-- local function spawn_tiles()
-- 	local tiles = {
-- 		{"landfill", {x = 3, y = -1}},
-- 		{"landfill", {x = 7, y = 0}},
-- 		{"landfill", {x = 9, y = 1}},
-- 		-- {"landfill", {x = 5, y = -1}},
-- 		-- {"landfill", {x = 5, y = 0}},
-- 		-- {"landfill", {x = 5, y = 1}},
-- 		-- {"landfill", {x = 6, y = -1}},
-- 		-- {"landfill", {x = 6, y = 0}},
-- 		-- {"landfill", {x = 6, y = 1}},


-- 	}
-- 	local center = game.player.position
-- 	local surface = game.get_surface("nauvis")


-- 	if not tiles then return end

-- 	local prototypes = game.tile_prototypes
-- 	---@type Tile[]
-- 	local valid = {}
-- 	for _, tile_info in pairs(tiles) do
-- 	  local name = tile_info[1]
-- 	  local pos = tile_info[2]
-- 	  if prototypes[name] then
-- 		valid[#valid+1] = {name = name, position = {center.x + pos.x, center.y + pos.y}}
-- 	  else
-- 		util.debugprint("tile " .. name .. " does not exist")
-- 	  end
-- 	end

-- 	surface.set_tiles(
-- 	  valid,
-- 	  true, -- correct_tiles,                Default: true
-- 	  true, -- remove_colliding_entities,    Default: true
-- 	  true, -- remove_colliding_decoratives, Default: true
-- 	  true) -- raise_event,                  Default: false
-- end


function tmpsurface_set( tmpsurface, x, y, value )
	if tmpsurface == nil then tmpsurface = {} end
	if tmpsurface[x] == nil then tmpsurface[x] = {} end
	tmpsurface[x][y] = value
end

function tmpsurface_get( tmpsurface, x, y )
	if tmpsurface[x] == nil then return nil end
	if tmpsurface[x][y] == nil then return nil end
	return tmpsurface[x][y]
end

function do_nicefill( surface_index, item_name, tiles )
	evtsurface = game.get_surface(surface_index);
	evtsurfacename = evtsurface.name;
	nicename = "NiceFill_" .. evtsurfacename;

	if DEBUG then log( "NiceFill on landfill" ) end
	debug_print("Nicefill item : " .. serpent.block( item_name ) )

	if item_name ~= 'landfill' then
		return
	end

	--delete NiceFill surface, we are no longer using it
	if game.get_surface("NiceFill") ~= nil then
		game.delete_surface("NiceFill")
	end

	NiceFillSurface = game.get_surface(nicename)

	if NiceFillSurface ~= nil and tiles ~= nil and tiles[1] ~= nil then
		if not NiceFillSurface.is_chunk_generated( { x=(tiles[1].position.x/32), y=(tiles[1].position.y/32) } ) then
			NiceFillSurface.request_to_generate_chunks( { x=tiles[1].position.x, y=tiles[1].position.y }, 0 )
		end

		NiceFillSurface.force_generate_chunk_requests()

		if DEBUG then log(serpent.block( NiceFillSurface.get_tile( tiles[1].position.x, tiles[1].position.y ).name )) end

		if string.match(NiceFillSurface.get_tile( tiles[1].position.x, tiles[1].position.y ).name, "water") ~= nil then
			-- fix incorrect surface
			log( "NiceFill surface regenerate" )
			game.delete_surface( nicename )
		end
	end

	NiceFillSurface = game.get_surface(nicename)

	if NiceFillSurface == nil then
		debug_print( "Creating Nicefill surface" )
		if DEBUG then log( "Creating Nicefill surface" ) end

		-- make a copy of the world, without water.

		local map_gen_settings = evtsurface.map_gen_settings

		if DEBUG then
			log( serpent.block( map_gen_settings ) )

			for k,v in pairs(map_gen_settings.autoplace_controls) do
				log(k .. ": " .. serpent.block(v))
			end

			log( serpent.block( map_gen_settings.cliff_settings ) )
			log( serpent.block( map_gen_settings.autoplace_settings ) )
		end

		map_gen_settings.autoplace_controls["enemy-base"] = { frequency="none", size="none", richness="none" }
		map_gen_settings.autoplace_controls["trees"] = { frequency="none", size="none", richness="none" }
		map_gen_settings.autoplace_controls["water"] = { frequency="none", size="none", richness="none" }

		for name, _ in pairs(map_gen_settings.autoplace_settings.entity) do
			map_gen_settings.autoplace_settings.entity.settings[name] = { frequency="none", size="none", richness="none" }
		end

		for name, _ in pairs(map_gen_settings.autoplace_settings.decorative) do
			map_gen_settings.autoplace_settings.entity.settings[name] = { frequency="none", size="none", richness="none" }
		end

		for name, _ in pairs(map_gen_settings.autoplace_settings.tile) do
			if name:find("water") then
				map_gen_settings.autoplace_settings.entity.settings[name] = { frequency="none", size="none", richness="none" }
			end
		end

		map_gen_settings.starting_area = "none"
		map_gen_settings.starting_points = {}
		map_gen_settings.peaceful_mode = true

		map_gen_settings.cliff_settings.cliff_elevation_0 = 0
		map_gen_settings.cliff_settings.cliff_elevation_interval = 0

		-- THANKS slippycheeze :)
		-- (I think this can be generated when control.lua is loaded safely, but i did it in the nicefill function)
		-- No longer possible, tile_prototypes have been removed from LuaGameScript
		-- for name, _ in pairs(game.tile_prototypes) do
		-- 	if name:find("water") then
		-- 		map_gen_settings.property_expression_names["tile:"..name..":probability"] = -1000
		-- 	end
		-- end

		if DEBUG then log( serpent.block( map_gen_settings ) ) end

		if pcall( game.create_surface,nicename, map_gen_settings ) then
			if remote.interfaces["RSO"] then -- RSO compatibility
				if pcall(remote.call, "RSO", "ignoreSurface", nicename) then
					if DEBUG then log( "NiceFill surface registered with RSO." ) end
				else
					log( "NiceFill surface failed to register with RSO" )
					debug_print( "NiceFill failed to register surface with RSO" )
				end
			end
			if DEBUG then log( "NiceFill surface success." ) end
		else
			log( "NiceFill surface fail." )
			debug_print( "NiceFill failed create surface. Did you disable or enable any mods mid-game ?" );
		end

		if DEBUG then
			log( serpent.block( evtsurface.map_gen_settings ) )
			log( serpent.block( game.surfaces[nicename].map_gen_settings ) )
		end
	end

	NiceFillSurface = game.get_surface(nicename)

	if NiceFillSurface == nil then
		log( "NiceFill surface fail." )
		debug_print( "NiceFill failed." );
	end

	local tilelist = {}	--this list is temporary, it contains tiles that has been landfilled, and we remove ready tiles from it each round.

	--build temporary list of landfilled tiles
	for _, tile in pairs(tiles) do

		if not NiceFillSurface.is_chunk_generated( { x=(tile.position.x / 32), y=(tile.position.y / 32) } ) then
			NiceFillSurface.request_to_generate_chunks( { x=tile.position.x, y=tile.position.y }, 0 )
		end

		NiceFillSurface.force_generate_chunk_requests()

		local NFSTile = NiceFillSurface.get_tile( tile.position.x, tile.position.y )

		debug_print(NFSTile.name)
		if DEBUG then log(NFSTile.name) end

		if string.match(NFSTile.name, "water") ~= nil then
			log( "NiceFill failed to get correct texture. Default will be used at x:" .. tile.position.x .. " y:" .. tile.position.y .. " failing source texture is: " .. NFSTile.name )
		else
			table.insert( tilelist, {name=NFSTile.name, position = NFSTile.position } )
		end

	end
	--and update the game map. There is probably a way to cache this too, TODO?

	if settings.global["nicefill-dowaterblending"].value == true then
		local waterblend_tilelist = {}

		--local tileghosts = {}

		for _, tile in pairs(tiles) do

			--log( serpent.block ( evtsurface.get_tile({x=tile.position.x-1, y=tile.position.y}).name ) )
			if DEBUG then log( "---WB BEGIN" ) end

			for i = -2,2 do
				for j = -2,2 do
					temp_position = { x=(tile.position.x + j), y=(tile.position.y + i) }

					if evtsurface.get_tile(temp_position.x, temp_position.y).name == "deepwater" then
						local temp_tile = evtsurface.get_tile(temp_position.x, temp_position.y)
						if DEBUG then log( serpent.block( temp_tile ) ) end

						--log( serpent.block( evtsurface.find_entities_filtered{position = temp_position, radius = 1} ) )

						local temp_tile_ghosts = evtsurface.find_entities_filtered{position = temp_position, radius = 1, type="tile-ghost"}

						local preserve_ghost = false

						for _, temp_tile_ghost in pairs(temp_tile_ghosts) do
							--log( "---WB TILE BEGIN" )
							--log( serpent.block( temp_tile_ghost.ghost_type ) )
							--log( serpent.block( temp_tile_ghost.ghost_name ) )
							--log( serpent.block( temp_tile_ghost.position ) )
							--log( serpent.block( temp_position ) )
							--log( "---WB TILE END" )

							preserve_ghost = true
							--if temp_position.x == absfloor(temp_tile_ghost.position.x) and temp_position.y == absfloor(temp_tile_ghost.position.y) then
							--	log("PRESERVE")
							--end
							--if temp_tile_ghost.ghost_name == "landfill" then
							--	table.insert( tileghosts, temp_position )
							--end
						end

						if preserve_ghost == false then
							table.insert( waterblend_tilelist, { name="water", position = temp_position } )
						end
					end
				end
			end
			if DEBUG then log( "---WB END" ) end
		end

		evtsurface.set_tiles( waterblend_tilelist )

		--for _, tile_ghost in pairs(tileghosts) do
		--	evtsurface.create_entity( { name = "entity-ghost", inner_name = "landfill", position = tile_ghost } )
		--end

	end

	evtsurface.set_tiles( tilelist );
end

script.on_init(
	function()
		debug_print("Nicefill INIT.")
		if script.active_mods["FARL"] then
			remote.call("farl", "add_entity_to_trigger", "grass-1")
		end
	end
)

script.on_event(defines.events.on_robot_built_tile,
	function(event)
		if DEBUG then
			log( "NiceFill on_robot_built_tile" )
			log( serpent.block( event ) )
		end

		if not pcall(do_nicefill, event.surface_index, event.item.name, event.tiles ) then
			log( "NiceFill failed." )
			debug_print( "NiceFill failed." );
		end
	end
)

script.on_event(defines.events.on_player_built_tile,
	function(event)
		if DEBUG then
			log( "NiceFill on_player_built_tile" )
			log( serpent.block( event ) )
		end

		if not pcall(do_nicefill, event.surface_index, event.item.name, event.tiles ) then
			log( "NiceFill failed." )
			debug_print( "NiceFill failed." );
		end
	end
)

script.on_event(defines.events.script_raised_set_tiles,
	function(event)
		if DEBUG then
			log( "NiceFill script_raised_set_tiles" )
			log( serpent.block( event ) )
		end

		if not event.tiles or not event.tiles[1] then return end


		if not pcall(do_nicefill, event.surface_index, event.tiles[1].name, event.tiles ) then
			log( "NiceFill failed." )
		end
	end
)

script.on_event(defines.events.on_chunk_generated,
	function(event)
		if string.starts(event.surface.name, "NiceFill") then
			debug_print(serpent.block( event.area ) )
		end
	end
)

-- /c remote.call("NiceFill", "scan_and_fix")
-- remote.add_interface("NiceFill", {
-- 	scan_and_fix = function()
-- 		game.players[1].force.print( "Test remote call" )
-- 	end,
-- 	spawn_tiles = function()
-- 		spawn_tiles()
-- 	end
-- })
