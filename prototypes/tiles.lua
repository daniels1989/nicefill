data:extend(
{
  {
    type = "tile",
    name = "tdebug",
    collision_mask = {"ground-tile"},
    --autoplace = autoplace_settings("tdebug", {{{35, 0.35}, {lavatemp+2, 0}, (default_influence or 1)*1.05}}),--
	  --autoplace = water_autoplace_settings2((-1*stoneamount), {{{35, lavawater}, {lavatemp, lavadry}}}),
    layer = 34,------WHAT DO
    variants =
    {
      main =
      {
        {
          picture = "__nicefill-scriptfix__/graphics/terrain/tdebug/stone-path-1.png",
          count = 16,
          size = 1
        },
        {
          picture = "__nicefill-scriptfix__/graphics/terrain/tdebug/stone-path-2.png",
          count = 4,
          size = 2,
          probability = 0.39,
        },
        {
          picture = "__nicefill-scriptfix__/graphics/terrain/tdebug/stone-path-4.png",
          count = 4,
          size = 4,
          probability = 1,
        },
      },
      inner_corner =
      {
        picture = "__nicefill-scriptfix__/graphics/terrain/tdebug/stone-path-inner-corner.png",
        count = 8
      },
      outer_corner =
      {
        picture = "__nicefill-scriptfix__/graphics/terrain/tdebug/stone-path-outer-corner.png",
        count = 1
      },
      side =
      {
        picture = "__nicefill-scriptfix__/graphics/terrain/tdebug/stone-path-side.png",
        count = 10
      },
      u_transition =
      {
        picture = "__nicefill-scriptfix__/graphics/terrain/tdebug/stone-path-u.png",
        count = 10
      },
      o_transition =
      {
        picture = "__nicefill-scriptfix__/graphics/terrain/tdebug/stone-path-o.png",
        count = 10
      }
    },
	  --allowed_neighbors = {"sand", "dark-sand"},
    map_color={r=160, g=160, b=160},
    --ageing=0.00025,---------WHAT DO
	  ageing=0,
	  decorative_removal_probability = 0.0,
    --vehicle_friction_modifier = sand_vehicle_speed_modifier
	  pollution_absorption_per_second = 0.0
  }
})