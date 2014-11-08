-- fracture 0.2.1 by paramat
-- For latest stable Minetest and back to 0.4.8
-- Depends default
-- License: code WTFPL

-- update spawnplayer function
-- tunnels replace fissures
-- remove soil depth table, pines
-- thicker dirt/sand
-- new edge erosion stability system, calculation only to 15 nodes below
-- TODO
-- integrate water pools. Clouds, humidity linked to distribution

-- Parameters

local YMIN = -32
local YMAX = 33000
local TSTONE = 0.03 -- Stone density threshold, controls average depth of dirt/sand
local STABLE = 3 -- Minimum depth of stone for stable support of dirt/sand
local TTUN = 0.02 -- Tunnel width
local ORECHA = 1 / 5 ^ 3 -- Ore chance per stone node

local BLEND = 0.02 -- Controls biome blend distance
local APPCHA = 1 / 59 ^ 2 -- Appletree
local CACCHA = 1 / 61 ^ 2 -- Cactus
local FLOCHA = 1 / 47 ^ 2 -- Random flower
local GRACHA = 1 / 7 ^ 2 -- Grass_5
local DRYCHA = 1 / 47 ^ 2 -- Dry shrub

-- 3D noise for realm

local np_realm = {
	offset = 0,
	scale = 1,
	spread = {x=1192, y=1192, z=1192},
	seed = 98320,
	octaves = 3,
	persist = 0.4
}

-- 3D noise for terrain

local np_terrain = {
	offset = 0,
	scale = 1,
	spread = {x=384, y=128, z=384},
	seed = 593,
	octaves = 5,
	persist = 0.67
}

-- 3D noise for alt terrain in golden ratio

local np_terralt = {
	offset = 0,
	scale = 1,
	spread = {x=311, y=104, z=311},
	seed = 593,
	octaves = 5,
	persist = 0.67
}

-- 3D noises for tunnels

local np_weba = {
	offset = 0,
	scale = 1,
	spread = {x=192, y=192, z=192},
	seed = 5900033,
	octaves = 3,
	persist = 0.4
}

local np_webb = {
	offset = 0,
	scale = 1,
	spread = {x=191, y=191, z=191},
	seed = 33,
	octaves = 3,
	persist = 0.4
}

-- 3D noise for temperature

local np_biome = {
	offset = 0,
	scale = 1,
	spread = {x=512, y=512, z=512},
	seed = -188900,
	octaves = 3,
	persist = 0.4
}

-- 3D noise for clouds

local np_cloud = {
	offset = 0,
	scale = 1,
	spread = {x=414, y=414, z=414},
	seed = 1313131313,
	octaves = 4,
	persist = 0.8
}

-- Stuff

dofile(minetest.get_modpath("fracture").."/functions.lua")
dofile(minetest.get_modpath("fracture").."/nodes.lua")

-- On generated function

minetest.register_on_generated(function(minp, maxp, seed)
	if minp.y < YMIN or maxp.y > YMAX then
		return
	end

	local t0 = os.clock()
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
	
	local c_stone = minetest.get_content_id("fracture:stone")
	local c_destone = minetest.get_content_id("fracture:desertstone")
	local c_cloud = minetest.get_content_id("fracture:cloud")
	local c_dirt = minetest.get_content_id("fracture:dirt")
	local c_grass = minetest.get_content_id("fracture:grass")
	
	local c_desand = minetest.get_content_id("default:desert_sand")
	local c_snowblock = minetest.get_content_id("default:snowblock")
	local c_stodiam = minetest.get_content_id("default:stone_with_diamond")
	local c_stomese = minetest.get_content_id("default:stone_with_mese")
	local c_stogold = minetest.get_content_id("default:stone_with_gold")
	local c_stocopp = minetest.get_content_id("default:stone_with_copper")
	local c_stoiron = minetest.get_content_id("default:stone_with_iron")
	local c_stocoal = minetest.get_content_id("default:stone_with_coal")
	local c_grass5 = minetest.get_content_id("default:grass_5")
	local c_dryshrub = minetest.get_content_id("default:dry_shrub")
	
	local sidelen = x1 - x0 + 1 -- mapchunk side length
	local facearea = sidelen ^ 2 -- mapchunk face area
	local chulens = {x=sidelen, y=sidelen+16, z=sidelen}
	local minposxyz = {x=x0, y=y0-15, z=z0}
	
	local nvals_realm = minetest.get_perlin_map(np_realm, chulens):get3dMap_flat(minposxyz)
	local nvals_terrain = minetest.get_perlin_map(np_terrain, chulens):get3dMap_flat(minposxyz)
	local nvals_terralt = minetest.get_perlin_map(np_terralt, chulens):get3dMap_flat(minposxyz)
	local nvals_weba = minetest.get_perlin_map(np_weba, chulens):get3dMap_flat(minposxyz)
	local nvals_webb = minetest.get_perlin_map(np_webb, chulens):get3dMap_flat(minposxyz)
	local nvals_biome = minetest.get_perlin_map(np_biome, chulens):get3dMap_flat(minposxyz)
	local nvals_cloud = minetest.get_perlin_map(np_cloud, chulens):get3dMap_flat(minposxyz)
	
	local nixyz = 1
	local stable = {}
	local under = {}
	for z = z0, z1 do

	for x = x0, x1 do -- set initial values of tables to zero
		local si = x - x0 + 1
		stable[si] = 0
		under[si] = 0
	end

	for y = y0 - 15, y1 + 1 do
		local vi = area:index(x0, y, z)
		local viu = area:index(x0, y-1, z)
		for x = x0, x1 do
			local si = x - x0 + 1
			
			local n_realm = nvals_realm[nixyz]
			local n_terrain = nvals_terrain[nixyz]
			local n_terralt = nvals_terralt[nixyz]
			local density = (n_terrain + n_terralt) * 0.5 -- - math.abs(n_realm) ^ 1.5 * 64
			
			local n_biome = nvals_biome[nixyz]
			local biome = false
			if n_biome > 0.4 + (math.random() - 0.5) * BLEND then
				biome = 3 -- desert
			elseif n_biome < -0.4 + (math.random() - 0.5) * BLEND then
				biome = 1 -- tundra
			else
				biome = 2 -- forest / grassland
			end
			
			local weba = math.abs(nvals_weba[nixyz]) < TTUN
			local webb = math.abs(nvals_webb[nixyz]) < TTUN
			local novoid = not (weba and webb)
			
			if y < y0 then -- overgeneration, initialise tables
				if density >= TSTONE then
					stable[si] = stable[si] + 1
				elseif density >= 0 and density < TSTONE then
					stable[si] = stable[si] - 1
				else
					stable[si] = 0
				end
			elseif y >= y0 and y <= y1 then
				if novoid and density >= TSTONE then -- stone, ores
					if biome == 3 then
						data[vi] = c_destone
					elseif math.random() < ORECHA then
						local osel = math.random(24)
						if osel == 24 then
							data[vi] = c_stodiam
						elseif osel == 23 then
							data[vi] = c_stomese
						elseif osel == 22 then
							data[vi] = c_stogold
						elseif osel >= 19 then
							data[vi] = c_stocopp
						elseif osel >= 10 then
							data[vi] = c_stoiron
						else
							data[vi] = c_stocoal
						end
					else
						data[vi] = c_stone
					end
					stable[si] = stable[si] + 1
					under[si] = 0
				elseif density >= 0 and density < TSTONE
				and stable[si] >= STABLE then -- fine materials
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
					local oldstable = stable[si]
					stable[si] = stable[si] - 1
				elseif density < 0 and under[si] ~= 0 then -- air above surface node
					if under[si] == 1 then
						data[viu] = c_dirt
						data[vi] = c_snowblock
					elseif under[si] == 2 then
						if math.random() < APPCHA then
							fracture_appletree(x, y, z, area, data)
						else
							data[viu] = c_grass
							if math.random() < FLOCHA then
								fracture_flower(data, vi)
							elseif math.random() < GRACHA then
								data[vi] = c_grass5
							end
						end
					elseif under[si] == 3 then
						if math.random() < CACCHA then
							fracture_cactus(x, y, z, area, data)
						elseif math.random() < DRYCHA then
								data[vi] = c_dryshrub
						end
					end
					stable[si] = 0
					under[si] = 0
				elseif density < TSTONE and y - y0 == 16
				and biome ~= 3 and math.abs(y) > 1024 then -- clouds
					local xrq = 16 * math.floor((x - x0) / 16)
					local zrq = 16 * math.floor((z - z0) / 16)
					local yrq = 16
					local qixyz = zrq * facearea + yrq * sidelen + xrq + 1
					if math.abs(nvals_cloud[qixyz]) < 0.05 then
						data[vi] = c_cloud
					end
					stable[si] = 0
					under[si] = 0
				else -- air
					stable[si] = 0
					under[si] = 0
				end
			elseif y == y1 + 1 then -- overgeneration, detect surface, add surface nodes
				if density < 0 and under[si] ~= 0 then
					if under[si] == 1 then
						data[viu] = c_dirt
						data[vi] = c_snowblock -- added in chunk above
					elseif under[si] == 2 then
						data[viu] = c_grass
					end
				end
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

	local chugent = math.ceil((os.clock() - t0) * 1000)
	print ("[fracture] "..chugent.." ms")
end)
