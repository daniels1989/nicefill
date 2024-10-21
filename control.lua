DEBUG = false

function print_force(message, ...)
    if not DEBUG then
        return
    end

    local args = table.pack(...)
    for i = 1, args.n do
        if type(args[i]) == 'table' then
            args[i] = serpent.dump(args[i])
        end
    end

	game.player.force.print(string.format(message, table.unpack(args, 1, args.n)))
end

function debug_log(message)
	if not DEBUG then
        return
    end

	log(message)
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

function do_nicefill( game, surface_index, item_name, tiles )
	evtsurface = game.surfaces[surface_index];
	evtsurfacename = evtsurface.name;
	nicename = "NiceFill_" .. evtsurfacename;

	debug_log( "NiceFill on landfill" )
	print_force("Nicefill item : " .. serpent.dump( item_name ) )

	if item_name ~= 'landfill' then
		return
	end

	if item_name == 'landfill' then

		--delete NiceFill surface, we are no longer using it
		if game.surfaces["NiceFill"] ~= nil then
			game.delete_surface("NiceFill")
		end

		if game.surfaces[nicename] ~= nil and tiles ~= nil and tiles[1] ~= nil then

			if not game.surfaces[nicename].is_chunk_generated( { x=(tiles[1].position.x/32), y=(tiles[1].position.y/32) } ) then
				game.surfaces[nicename].request_to_generate_chunks( { x=tiles[1].position.x, y=tiles[1].position.y }, 0 )
			end

			game.surfaces[nicename].force_generate_chunk_requests()

			debug_log(serpent.block( game.surfaces[nicename].get_tile( tiles[1].position ).name ))

			if string.match(game.surfaces[nicename].get_tile( tiles[1].position ).name, "water") ~= nil then
				-- fix incorrect surface
				log( "NiceFill surface regenerate" )
				game.delete_surface( nicename )
			end
		end

		if game.surfaces[nicename] == nil then
			print_force( serpent.dump( game.surfaces ) )
			debug_log( serpent.dump( game.surfaces ) )

			-- make a copy of the world, without water.

			local map_gen_settings = evtsurface.map_gen_settings

			--map_gen_settings.autoplace_controls = nil
			--map_gen_settings.autoplace_controls = {}

			for k,v in pairs(map_gen_settings.autoplace_controls) do
				debug_log( serpent.block( k ) )
				debug_log( serpent.block( v ) )
			end

			map_gen_settings.autoplace_controls["enemy-base"] = { frequency="none", size="none", richness="none" }
			map_gen_settings.autoplace_controls["trees"] = { frequency="none", size="none", richness="none" }
			-- map_gen_settings.default_enable_all_autoplace_controls = false
			map_gen_settings.autoplace_settings =
			{
				entity =
				{
					treat_missing_as_default = false,
					settings =
					{
						frequency = "none",
						size = "none",
						richness = "none"
					}
				},
				decorative =
				{
					treat_missing_as_default = false,
					settings =
					{
						frequency = "none",
						size = "none",
						richness="none"
					}
				}
			}

			debug_log( serpent.block( map_gen_settings.cliff_settings ) )
			debug_log( serpent.block( map_gen_settings.autoplace_settings ) )

			map_gen_settings.water = "none"
			map_gen_settings.starting_area = "none"
			map_gen_settings.starting_points = {}
			map_gen_settings.peaceful_mode = true

			map_gen_settings.cliff_settings = {
				cliff_elevation_0 = 0,
				cliff_elevation_interval = 0,
				name = "cliff"
			}

			-- THANKS slippycheeze :)
			-- (I think this can be generated when control.lua is loaded safely, but i did it in the nicefill function)
            for name, _ in pairs(game.tile_prototypes) do
                if name:find("water") then
                    map_gen_settings.property_expression_names["tile:"..name..":probability"] = -1000
                end
            end

			-- if not pcall(game.create_surface( "NiceFill", map_gen_settings )) then
				-- log( "Failed to create surface " .. serpent.block( map_gen_settings ) )
			-- end

			--log( serpent.block( map_gen_settings ) )

			if pcall( game.create_surface,nicename, map_gen_settings ) then
				if remote.interfaces["RSO"] then -- RSO compatibility
					if pcall(remote.call, "RSO", "ignoreSurface", nicename) then
						debug_log( "NiceFill surface registered with RSO." )
					else
						log( "NiceFill surface failed to register with RSO" )
						print_force( "NiceFill failed to register surface with RSO" )
					end
				end
				debug_log( "NiceFill surface success." )
			else
				log( "NiceFill surface fail." )
				print_force( "NiceFill failed create surface. Did you disable or enable any mods mid-game ?" );
			end

			NiceFillSurface = game.surfaces[nicename]

			debug_log( serpent.block( evtsurface.map_gen_settings ) )
			debug_log( serpent.block( game.surfaces[nicename].map_gen_settings ) )
		else
			NiceFillSurface = game.surfaces[nicename]
		end

		local tilelist = {}	--this list is temporary, it contains tiles that has been landfilled, and we remove ready tiles from it each round.

		--build teporary list of landfilled tiles
		for k,vv in pairs(tiles) do
			local v = vv.position -- quick fix for 0.16.17

			if not NiceFillSurface.is_chunk_generated( { x=(v.x / 32), y=(v.y / 32) } ) then
				NiceFillSurface.request_to_generate_chunks( { x=v.x, y=v.y }, 0 )
			end

			NiceFillSurface.force_generate_chunk_requests()

			local NFSTile = NiceFillSurface.get_tile( { x=v.x, y=v.y } )

			if string.match(NFSTile.name, "water") ~= nil then
				log( "NiceFill failed to get correct texture. Default will be used at x:" .. v.x .. " y:" .. v.y .. " failing source texture is: " .. NFSTile.name )
			else
				table.insert( tilelist, {name=NFSTile.name, position = NFSTile.position } )
			end

		end
		--and update the game map. There is probably a way to cache this too, TODO?

		if settings.global["nicefill-dowaterblending"].value == true then
			local waterblend_tilelist = {}

			--local tileghosts = {}

			for k,vv in pairs(tiles) do
				local v = vv.position

				--log( serpent.block ( evtsurface.get_tile({x=v.x-1,y=v.y}).name ) )
				debug_log( "---WB BEGIN" )

				for i = -2,2 do
					for j = -2,2 do
						temp_position = { x=(v.x + j), y=(v.y + i) }

						if evtsurface.get_tile(temp_position).name == "deepwater" then
							local temp_tile = evtsurface.get_tile(temp_position)
							debug_log( serpent.block( temp_tile ) )

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
				debug_log( "---WB END" )
			end

			evtsurface.set_tiles( waterblend_tilelist )

			--for _, tile_ghost in pairs(tileghosts) do
			--	evtsurface.create_entity( { name = "entity-ghost", inner_name = "landfill", position = tile_ghost } )
			--end

		end

		evtsurface.set_tiles( tilelist );

	end
end

script.on_init(
	function()
		print_force("Nicefill INIT.")
		-- if game.active_mods["FARL"] then
		-- 	remote.call("farl", "add_entity_to_trigger", "grass-1")
		-- end
	end
)

script.on_event(defines.events.on_robot_built_tile,
	function(event)
		if DEBUG then log( serpent.block( event ) ) end
		if DEBUG then log( serpent.block( event.robot ) ) end

		--log("robot" .. serpent.block(event));
		--log( serpent.block( event.item.name ) )

		local sfcindex={}
		for k,v in pairs(game.surfaces) do
		   sfcindex[v.name]=k
		end

		--log( serpent.block(event) )

		if event.robot.name == "character" and event.robot.valid == false then
			--CM
			if event.player_index ~= nil then
				event.surface_index = sfcindex[game.players[event.player_index].surface.name]
				--log("CM")
				if event.item.name == "grass-1" then
					event.item = game.item_prototypes["landfill"]
				end
			else
				log("Unable to process the event" .. serpent.block(event))
				force_debug("Unable to process the event" .. serpent.block(event))
			end
		else
			event.surface_index = sfcindex[event.robot.surface.name]
		end

		if not pcall(do_nicefill, game, event ) then
			log( "NiceFill failed." )
			print_force( "NiceFill failed." );
		end

		--do_nicefill(game, event)

		--log( serpent.block( sfcindex[event.robot.surface.name] ) )
		--do_nicefill( game, event )

	end
)

script.on_event(defines.events.on_player_built_tile,
	function(event)
		if DEBUG then log( "NiceFill on_player_built_tile" ) end
		if DEBUG then log( serpent.block(event) ) end

		--force_debug("character");

		local sfcindex={}
		for k,v in pairs(game.surfaces) do
		   sfcindex[v.name]=k
		end

		event.surface_index = sfcindex[game.players[event.player_index].surface.name]

		if not pcall(do_nicefill, game, event ) then
			log( "NiceFill failed." )
			print_force( "NiceFill failed." );
		end

		--log( serpent.block( sfcindex[game.players[event.player_index].surface.name] ) )
		--do_nicefill( game, event )
	end
)

script.on_event(defines.events.script_raised_set_tiles,
	function(event)
		if not event.tiles or not event.tiles[1] then return end

		debug_log( "NiceFill script_raised_set_tiles" )
		debug_log( serpent.block(event) )

		event.item = game.item_prototypes[event.tiles[1].name]

		if not pcall(do_nicefill, game, event ) then
			log( "NiceFill failed." )
		end
	end
)

script.on_event(defines.events.on_chunk_generated,
	function(event)
		if string.starts(event.surface.name, "NiceFill") then
			print_force(serpent.block( event.area ) )
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
