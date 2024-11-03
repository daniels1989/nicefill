local SurfaceHelper = {}

--- Change visibility of all surfaces for all forces
---@param hidden boolean
function SurfaceHelper.change_surfaces_visibility(hidden)
	for _, surface in pairs(game.surfaces) do
		if NiceFill.is_nicefill_surface(surface) then
			SurfaceHelper.change_surface_visibility_for_forces(surface, hidden)
		end
	end
end


--- Change visibility of a surface for all forces
---@param surface LuaSurface
---@param hidden boolean
function SurfaceHelper.change_surface_visibility_for_forces(surface, hidden)
	for _, force in pairs(game.forces) do
		SurfaceHelper.change_surface_visibility_for_force(surface, force, hidden)
	end
end

--- Change visibility of all surfaces for a force
---@param force LuaForce
---@param hidden boolean
function SurfaceHelper.change_surfaces_visibility_for_force(force, hidden)
	for _, surface in pairs(game.surfaces) do
		if NiceFill.is_nicefill_surface(surface) then
			SurfaceHelper.change_surface_visibility_for_force(surface, force, hidden)
		end
	end
end

--- Change visibility of a surface for a force
---@param surface LuaSurface
---@param force LuaForce
---@param hidden boolean
function SurfaceHelper.change_surface_visibility_for_force(surface, force, hidden)
	if force.get_surface_hidden(surface) ~= hidden
	then
		force.set_surface_hidden(surface, hidden)

		if DEBUG
		then
			local visibility

			if not hidden
			then
				visibility = "visible"
			else
				visibility = "hidden"
			end

			log(string.format(
				'Change visibility of surface %s for force %s to %s',
				surface.name,
				force.name,
				visibility
			))
		end
	end
end

return SurfaceHelper