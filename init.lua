-- fracture 0.1.0 by paramat
-- For latest stable Minetest and back to 0.4.8
-- Depends default
-- License: code WTFPL

-- Parameters

local YMIN = -33000
local YMAX = 33000
local DENOFF = -0.4 -- Density offset, 0 = equal volumes of air and floatland
local TSTONE = 0.08 -- Stone density threshold, controls average depth of stone below surface
local STABLE = 2 -- Minimum number of stacked stone nodes in column required to support dirt/sand

local BLEND = 0.04 -- Controls biome blend distance
local PINCHA = 36 -- Pine chance 1/x chance
local APPCHA = 36 -- Appletree 1/x chance
local CACCHA = 841 -- Cactus 1/x chance
local TCAC = 0.2 -- Cactus threshold, width of cactus areas
local TFOR = 0.2 -- Forest threshold, width of forest clearings

-- 3D noise for terrain

local np_terrain = {
	offset = 0,
	scale = 1,
	spread = {x=512, y=171, z=512},
	seed = 5900033,
	octaves = 6,
	persist = 0.67
}

-- 3D noise for biomes

local np_biome = {
	offset = 0,
	scale = 1,
	spread = {x=512, y=512, z=512},
	seed = -188900,
	octaves = 3,
	persist = 0.5
}

-- 3D noise for flora

local np_flora = {
	offset = 0,
	scale = 1,
	spread = {x=256, y=256, z=256},
	seed = 188,
	octaves = 4,
	persist = 0.67
}

-- Stuff

fracture = {}

dofile(minetest.get_modpath("fracture").."/functions.lua")

-- Nodes

minetest.register_node("fracture:stone", {
	description = "FR Stone",
	tiles = {"default_stone.png"},
	groups = {cracky=3},
	drop = "default:stone",
	sounds = default.node_sound_stone_defaults(),
})

minetest.register_node("fracture:desertstone", {
	description = "FR Desert Stone",
	tiles = {"default_desert_stone.png"},
	groups = {cracky=3},
	drop = "default:desert_stone",
	sounds = default.node_sound_stone_defaults(),
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

-- Set mapgen parameters

minetest.register_on_mapgen_init(function(mgparams)
	minetest.set_mapgen_params({mgname="singlenode", water_level=-32000})
end)

-- On generated function

minetest.register_on_generated(function(minp, maxp, seed)
	if minp.y < YMIN or maxp.y > YMAX then
		return
	end

	local t1 = os.clock()
	local x1 = maxp.x
	local y1 = maxp.y
	local z1 = maxp.z
	local x0 = minp.x
	local y0 = minp.y
	local z0 = minp.z
	
	print ("[fracture] chunk minp ("..x0.." "..y0.." "..z0..")")
	
	local vm, emin, emax = minetest.get_mapgen_object("voxelmanip")
	local area = VoxelArea:new{MinEdge=emin, MaxEdge=emax}
	local data = vm:get_data()
	
	local c_air = minetest.get_content_id("air")
	local c_frstone = minetest.get_content_id("fracture:stone")
	local c_frdestone = minetest.get_content_id("fracture:desertstone")
	local c_sand = minetest.get_content_id("default:sand")
	local c_desand = minetest.get_content_id("default:desert_sand")
	local c_dirt = minetest.get_content_id("default:dirt")
	local c_grass = minetest.get_content_id("default:dirt_with_grass")
	local c_dirtsnow = minetest.get_content_id("default:dirt_with_snow")
	local c_snowblock = minetest.get_content_id("default:snowblock")
	
	local sidelen = x1 - x0 + 1
	local chulens = {x=sidelen, y=sidelen, z=sidelen}
	local minposxyz = {x=x0, y=y0, z=z0}
	
	local nvals_terrain = minetest.get_perlin_map(np_terrain, chulens):get3dMap_flat(minposxyz)
	local nvals_biome = minetest.get_perlin_map(np_biome, chulens):get3dMap_flat(minposxyz)
	local nvals_flora = minetest.get_perlin_map(np_flora, chulens):get3dMap_flat(minposxyz)
	
	local nixyz = 1
	local stable = {}
	local under = {}
	for z = z0, z1 do
		for x = x0, x1 do
			local si = x - x0 + 1
			under[si] = 0
			local nodename = minetest.get_node({x=x,y=y0-1,z=z}).name
			if nodename == "air" then
				stable[si] = 0
			else
				stable[si] = STABLE
			end
		end
		for y = y0, y1 do
			local vi = area:index(x0, y, z)
			local viu = area:index(x0, y-1, z)
			for x = x0, x1 do
				local si = x - x0 + 1
				local density = nvals_terrain[nixyz] + DENOFF
				local n_biome = nvals_biome[nixyz]
				local n_flora = math.abs(nvals_flora[nixyz])
				
				local biome = false
				if n_biome > 0.4 + (math.random() - 0.5) * BLEND then
					biome = 3
				elseif n_biome < -0.4 + (math.random() - 0.5) * BLEND then
					biome = 1
				else
					biome = 2
				end
				
				if density >= TSTONE then
					if biome == 3 then
						data[vi] = c_frdestone
					else
						data[vi] = c_frstone
					end
					stable[si] = stable[si] + 1
					under[si] = 0
				elseif density >= 0 and density < TSTONE and stable[si] >= 2 then
					if biome == 3 then
						data[vi] = c_desand
						under[si] = 3
					elseif biome == 1 then
						data[vi] = c_dirt
						under[si] = 1
					else
						data[vi] = c_dirt
						under[si] = 2
					end
				elseif density < 0 and under[si] ~= 0 then
					if under[si] == 1 then
						if math.random(PINCHA) == 2 and n_flora > TFOR then
							fracture_snowypine(x, y, z, area, data)
						else
							data[viu] = c_dirtsnow
							data[vi] = c_snowblock
						end
					elseif under[si] == 2 then
						if math.random(APPCHA) == 2 and n_flora > TFOR then
							fracture_appletree(x, y, z, area, data)
						else
							data[viu] = c_grass
						end
					elseif under[si] == 3 then
						if math.random(CACCHA) == 2 and n_flora < TCAC then
							fracture_cactus(x, y, z, area, data)
						end
					end
					under[si] = 0
				else -- air
					stable[si] = 0
					under[si] = 0 
				end
				nixyz = nixyz + 1
				vi = vi + 1
				viu = viu + 1
			end
		end
	end
	
	vm:set_data(data)
	vm:set_lighting({day=0, night=0})
	vm:calc_lighting()
	vm:write_to_map(data)
	local chugent = math.ceil((os.clock() - t1) * 1000)
	print ("[fracture] "..chugent.." ms")
end)