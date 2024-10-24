DEBUG = false

require('scripts.util')
debug = require('scripts.debug')

NiceFill = require('scripts.nicefill')

-- For testing
-- Unlock planets with /cheat planetname, e.g. /cheat gleba
-- To hop between unlocked planets use /c game.player.teleport(game.player.position, "planetname")
-- e.g. /c game.player.teleport(game.player.position, "gleba")

---@param surface_index integer
---@param tiles Tile[]
function do_nicefill( surface_index, tiles )
	local surface = game.get_surface(surface_index);

	if surface == nil then
		log(string.format('Unable to get a surface with index %d', surface_index))
		return
	end

	-- Todo support other tiles that only need waterblending e.g. aquilo/ice platforms
	tiles = NiceFill.filter_tiles(tiles, 'landfill')
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

	if settings.global["nicefill-dowaterblending"].value == true then
		-- Get water blending tiles and set them first
		local water_blending_tiles = NiceFill.get_water_blending_tiles(surface, tiles)
		surface.set_tiles( water_blending_tiles )
	end

	surface.set_tiles( nice_tiles )
end

script.on_event(defines.events.on_robot_built_tile,
	function(event)
		if DEBUG then
			log( "NiceFill on_robot_built_tile" )
			log( serpent.block( event ) )
		end

		local tiles = convert_old_tile_and_position(event.tile, event.tiles)

		if not pcall(do_nicefill, event.surface_index, tiles ) then
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

		if not pcall(do_nicefill, event.surface_index, tiles ) then
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

		if not pcall(do_nicefill, event.surface_index, event.tiles ) then
			log( "NiceFill failed." )
		end
	end
)

script.on_event(defines.events.on_chunk_generated,
	function(event)
		if NiceFill.is_nicefill_surface(event.surface) then
			debug.print(serpent.block( event.area ) )
		end
	end
)

script.on_event(defines.events.on_surface_created,
	function(event)
		local surface = game.get_surface(event.surface_index)

		if surface == nil then
			log( "NiceFill on_surface_created found no surface." )
			return
		end

		if not NiceFill.is_nicefill_surface(surface) then return end

		debug.print('NiceFill created surface ' .. surface.name)

		if remote.interfaces["RSO"] then -- RSO compatibility
			if pcall(remote.call, "RSO", "ignoreSurface", surface) then
				if DEBUG then log( "NiceFill surface registered with RSO." ) end
			else
				log( "NiceFill surface failed to register with RSO" )
				debug.print( "NiceFill failed to register surface with RSO" )
			end
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