local debug = {}

function debug.print(message, ...)
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

function debug.spawn_tiles()
	local center = game.player.position
	local surface = game.player.surface

	if not surface then return end

	---@type Tile[]
	local valid = {}
	for i = -1,1 do
		for j = -1,1 do
			valid[#valid+1] = {name = "landfill", position = {center.x + i, center.y + j}}
		end
	end

	surface.set_tiles(
		valid,
		true, -- correct_tiles,                Default: true
		true, -- remove_colliding_entities,    Default: true
		true, -- remove_colliding_decoratives, Default: true
		true  -- raise_event,                  Default: false
	)
end

return debug