remote.add_interface("NiceFill", {
	--- Register additional tiles to be excluded when NiceFill generates a surface
	--- /c remote.call("NiceFill", "register_tile_conditions", "landfill", {"water", "deepwater"})
	---@param tile string Name of a tile that NiceFill should support when it's being placed
	---@param tiles string[] Names of the tiles that `tile` can replace, these will be excluded when NiceFill generates a surface
	register_tile_conditions = function(tile, tiles)
		NiceFill.register_tile_conditions(tile, tiles)
	end,

	--- Register smooth transition tile mapping. If `from_tile` is found in a certain radius around the landfilled tile, it will be replaced with `to_tile`
	--- /c remote.call("NiceFill", "register_smooth_transition_mapping", "deepwater", "water")
	---@param from_tile string Name of the tile that should be replaced
	---@param to_tile string Name of the tile it will be replaced with
	register_smooth_transition_mapping = function(from_tile, to_tile)
		NiceFill.register_smooth_transition_mapping(from_tile, to_tile)
	end,

	--- Register smooth transition radius.
	--- A float between 0 and 1 will be generated when placing a supported tile, which will be matched against `radius_probabilities` to determine the radius of tiles that will be changes based on the smooth transition mapping.
	--- Ex. probabilities are {0.3, 0.8}, meaning a 30% chance of radius 0, 50% chance of radius 1, and 20% chance of radius 2.
	--- This reads as: 0 to 0.3 is a radius of 0, 0.3 to 0.8 is a radius of 1, and 0.8 to 1 is a radius of 2.
	--- Ex. probabilities are {0, 0.25, 0.7}, meaning a 0% chance of radius 0, 25% chance of radius 1, 45% chance of radius 2, and 30% chance of radius 3.
	--- This reads as: 0 to 0.25 is a radius of 1, 0.25 to 0.7 is a radius of 2, and 0.7 to 1 is a radius of 3.
	--- /c remote.call("NiceFill", "register_smooth_transition_radius", "landfill", {0, 0.3, 0.8})
	---@param tile string Name of the tile
	---@param radius_probabilities float[] Array of floats indicating how big the smooth transition radius is going to be. Radius will be the index of the highest matching probability.
	register_smooth_transition_radius = function(tile, radius_probabilities)
		NiceFill.register_smooth_transition_radius(tile, radius_probabilities)
	end,
})