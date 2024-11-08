-- Set to true to enable full logging.
DEBUG = true

-- Require runtime helpers
Circle = require('scripts/helpers/circle')
debug = require('scripts/helpers/debug')
SurfaceHelper = require('scripts/helpers/surface')
require('scripts/helpers/util')

-- require general utils
require('utils/string')
require('utils/table')

-- require the thing that does all the things
NiceFill = require('scripts/nicefill')

-- For testing
-- Unlock planets with /cheat planetname, e.g. /cheat gleba
-- To hop between unlocked planets use /c game.player.teleport(game.player.position, "planetname")
-- e.g. /c game.player.teleport(game.player.position, "gleba")

script.on_event(defines.events.on_player_built_tile, function(event)
	if DEBUG then
		log( "NiceFill on_player_built_tile" )
		log( serpent.block( event ) )
	end

	local tiles = convert_old_tile_and_position(event.tile, event.tiles)

	if not pcall( NiceFill.run, event.surface_index, tiles ) then
		log( "NiceFill failed." )
		debug.print( "NiceFill failed." );
	end
end)

script.on_event(defines.events.on_robot_built_tile, function(event)
	if DEBUG then
		log( "NiceFill on_robot_built_tile" )
		log( serpent.block( event ) )
	end

	local tiles = convert_old_tile_and_position(event.tile, event.tiles)

	if not pcall( NiceFill.run, event.surface_index, tiles ) then
		log( "NiceFill failed." )
		debug.print( "NiceFill failed." );
	end
end)

script.on_event(defines.events.script_raised_set_tiles, function(event)
	if DEBUG then
		log( "NiceFill script_raised_set_tiles" )
		log( serpent.block( event ) )
	end

	if not event.tiles or not event.tiles[1] then return end

	if not pcall( NiceFill.run, event.surface_index, event.tiles ) then
		log( "NiceFill failed." )
	end
end)

script.on_event(defines.events.on_force_created, function(event)
	debug.print(string.format(
		"NiceFill detected force '%s' creation",
		event.force.name
	))

	NiceFill.hide_surfaces_from_force(event.force)
end)

script.on_event(defines.events.on_surface_created, function(event)
	local surface = game.get_surface(event.surface_index)

	if surface == nil then
		log( "NiceFill on_surface_created found no surface." )
		return
	end

	if not NiceFill.is_nicefill_surface(surface) then return end

	debug.print('NiceFill created surface ' .. surface.name)

	NiceFill.hide_surface(surface)

	if remote.interfaces["RSO"] then -- RSO compatibility
		if pcall(remote.call, "RSO", "ignoreSurface", surface) then
			if DEBUG then log( "NiceFill surface registered with RSO." ) end
		else
			log( "NiceFill surface failed to register with RSO" )
			debug.print( "NiceFill failed to register surface with RSO" )
		end
	end
end)

-- /c remote.call("NiceFill", "spawn_tiles")
-- remote.add_interface("NiceFill", {
-- })

if DEBUG then
	-- /nf_spawn_tiles landfill
	commands.add_command('nf_spawn_tiles', nil, function (command)
		local player = game.get_player(command.player_index)
		if player == nil then return end

		local tile = command.parameter
		if tile == nil then tile = 'landfill' end

		debug.spawn_tiles(player, tile)
	end)

	commands.add_command('nf_create_surface', nil, function (command)
		local player = game.get_player(command.player_index)
		if player == nil then return end

		pcall( game.delete_surface, NiceFill.get_surface_name_from(player.surface) )
		NiceFill.create_surface_from(player.surface)
	end)

	commands.add_command('nf_sample_tiles', nil, function (command)
		local player = game.get_player(command.player_index)
		if player == nil then return end

		local tiles = player.surface.find_tiles_filtered{ position = player.position, radius = 2}
		for _, tile in pairs(tiles) do debug.print(tile.name) end
	end)

	script.on_event(defines.events.on_chunk_generated, function(event)
		if NiceFill.is_nicefill_surface(event.surface) then
			debug.print(serpent.block( event.area ) )
		end
	end)
end