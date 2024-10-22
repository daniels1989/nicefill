DEBUG = true

require('scripts.util')
debug = require('scripts.debug')

NiceFill = require('scripts.nicefill')

---@param surface_index integer
---@param item_name string
---@param tiles Tile[]
function do_nicefill( surface_index, item_name, tiles )
	local surface = game.get_surface(surface_index);

	if(surface == nil) then
		log(string.format('Unable to get a surface with index %d', surface_index))
		return
	end

	-- delete legacy surfaces, we are no longer using them
	NiceFill.delete_legacy_surfaces()

	-- if DEBUG then log( "NiceFill on landfill" ) end
	-- debug.print("Nicefill item : " .. serpent.block( item_name ) )

	-- if item_name ~= 'landfill' then return end


	-- Try to get the NiceFill surface for this surface
	local NiceFillSurface = NiceFill.get_surface_from(surface)

	-- Validate the NiceFill surface
	if(NiceFillSurface ~= nil and not NiceFill.validate_surface(NiceFillSurface, tiles)) then
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

	local nice_tiles = NiceFill.get_tiles(NiceFillSurface, tiles)

	if settings.global["nicefill-dowaterblending"].value == true then
		local waterblend_tilelist = {}

		--local tileghosts = {}

		for _, tile in pairs(tiles) do

			--log( serpent.block ( evtsurface.get_tile({x=tile.position.x-1, y=tile.position.y}).name ) )
			if DEBUG then log( "---WB BEGIN" ) end

			for i = -2,2 do
				for j = -2,2 do
					local temp_position = { x=(tile.position.x + j), y=(tile.position.y + i) }

					if surface.get_tile(temp_position.x, temp_position.y).name == "deepwater" then
						local temp_tile = surface.get_tile(temp_position.x, temp_position.y)
						if DEBUG then log( serpent.block( temp_tile ) ) end

						--log( serpent.block( evtsurface.find_entities_filtered{position = temp_position, radius = 1} ) )

						local temp_tile_ghosts = surface.find_entities_filtered{position = temp_position, radius = 1, type="tile-ghost"}

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

		surface.set_tiles( waterblend_tilelist )

		--for _, tile_ghost in pairs(tileghosts) do
		--	evtsurface.create_entity( { name = "entity-ghost", inner_name = "landfill", position = tile_ghost } )
		--end

	end

	surface.set_tiles( nice_tiles );
end

script.on_init(
	function()
		debug.print("Nicefill INIT.")
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

		local tiles = convert_old_tile_and_position(event.tile, event.tiles)

		if not pcall(do_nicefill, event.surface_index, event.item.name, tiles ) then
			log( "NiceFill failed." )
			debug.print( "NiceFill failed." );
		end
	end
)

script.on_event(defines.events.on_player_built_tile,
	function(event)
		if DEBUG then
			log( "NiceFill on_player_built_tile" )
			log( serpent.block( event ) )
		end

		local tiles = convert_old_tile_and_position(event.tile, event.tiles)

		if not pcall(do_nicefill, event.surface_index, event.item.name, tiles ) then
			log( "NiceFill failed." )
			debug.print( "NiceFill failed." );
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

		log(serpent.block(event));
		if true then return end

		if not pcall(do_nicefill, event.surface_index, event.tiles[1].name, event.tiles ) then
			log( "NiceFill failed." )
		end
	end
)

script.on_event(defines.events.on_chunk_generated,
	function(event)
		if string.starts(event.surface.name, "NiceFill") then
			debug.print(serpent.block( event.area ) )
		end
	end
)

if DEBUG then
	-- /c remote.call("NiceFill", "spawn_tiles")
	remote.add_interface("NiceFill", {
		spawn_tiles = function()
			debug.spawn_tiles()
		end
	})
end