minetest.register_node("fracture:stone", {
	description = "FR Stone",
	tiles = {"default_stone.png"},
	groups = {cracky=3},
	drop = "default:cobble",
	sounds = default.node_sound_stone_defaults(),
})

minetest.register_node("fracture:desertstone", {
	description = "FR Desert Stone",
	tiles = {"default_desert_stone.png"},
	groups = {cracky=3},
	drop = "default:desert_stone",
	sounds = default.node_sound_stone_defaults(),
})

minetest.register_node("fracture:dirt", {
	description = "Dirt",
	tiles = {"default_dirt.png"},
	is_ground_content = false,
	groups = {crumbly=3,soil=1},
	drop = "default:dirt",
	sounds = default.node_sound_dirt_defaults(),
})

minetest.register_node("fracture:dirtsnow", {
	description = "Dirt with Snow",
	tiles = {"default_snow.png", "default_dirt.png", "default_snow.png"},
	is_ground_content = true,
	groups = {crumbly=3},
	drop = "default:dirt",
	sounds = default.node_sound_dirt_defaults({
		footstep = {name="default_snow_footstep", gain=0.25},
	}),
})

minetest.register_node("fracture:grass", {
	description = "Grass",
	tiles = {"default_grass.png", "default_dirt.png", "default_grass.png"},
	is_ground_content = false,
	groups = {crumbly=3,soil=1},
	drop = "default:dirt",
	sounds = default.node_sound_dirt_defaults({
		footstep = {name="default_grass_footstep", gain=0.25},
	}),
})

minetest.register_node("fracture:appleleaf", {
	description = "Appletree Leaves",
	drawtype = "allfaces_optional",
	visual_scale = 1.3,
	tiles = {"default_leaves.png"},
	paramtype = "light",
	is_ground_content = false,
	groups = {snappy=3, flammable=2},
	sounds = default.node_sound_leaves_defaults(),
})

minetest.register_node("fracture:pinetree", {
	description = "Pine Tree",
	tiles = {"fracture_pinetreetop.png", "fracture_pinetreetop.png", "fracture_pinetree.png"},
	paramtype2 = "facedir",
	is_ground_content = false,
	groups = {tree=1,choppy=2,oddly_breakable_by_hand=1,flammable=2},
	sounds = default.node_sound_wood_defaults(),
	on_place = minetest.rotate_node
})

minetest.register_node("fracture:pinewood", {
	description = "Pine Wood Planks",
	tiles = {"fracture_pinewood.png"},
	groups = {choppy=2,oddly_breakable_by_hand=2,flammable=3,wood=1},
	sounds = default.node_sound_wood_defaults(),
})

minetest.register_node("fracture:needles", {
	description = "Pine Needles",
	drawtype = "allfaces_optional",
	visual_scale = 1.3,
	tiles = {"fracture_needles.png"},
	paramtype = "light",
	is_ground_content = false,
	groups = {snappy=3},
	sounds = default.node_sound_leaves_defaults(),
})

minetest.register_node("fracture:cactus", {
	description = "Cactus",
	tiles = {"default_cactus_top.png", "default_cactus_top.png", "default_cactus_side.png"},
	paramtype2 = "facedir",
	is_ground_content = false,
	groups = {snappy=1, choppy=3, flammable=2},
	drop = "default:cactus",
	sounds = default.node_sound_wood_defaults(),
	on_place = minetest.rotate_node
})

minetest.register_node("fracture:cloud", {
	description = "Cloud",
	drawtype = "glasslike",
	tiles = {"fracture_cloud.png"},
	paramtype = "light",
	is_ground_content = false,
	sunlight_propagates = true,
	walkable = false,
	pointable = false,
	diggable = false,
	buildable_to = true,
	post_effect_color = {a=63, r=241, g=248, b=255},
})

-- Crafting

minetest.register_craft({
	output = "fracture:pinewood 4",
	recipe = {
		{"fracture:pinetree"},
	}
})