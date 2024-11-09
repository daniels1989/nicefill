local Debug = {}

function Debug.print(message, ...)
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

---@param player LuaPlayer
---@param tile string
function Debug.spawn_tiles(player, tile)
	local center = player.position
	local surface = player.surface

	if prototypes.tile[tile] == nil then player.print('invalid tile') return end

	---@type Tile[]
	local valid = {}
	for i = -1,1 do
		for j = -1,1 do
			valid[#valid+1] = {name = tile, position = {center.x + i, center.y + j}}
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

return Debug