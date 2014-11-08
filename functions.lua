function fracture_appletree(x, y, z, area, data)
	local c_tree = minetest.get_content_id("default:tree")
	local c_apple = minetest.get_content_id("default:apple")
	local c_appleaf = minetest.get_content_id("fracture:appleleaf")
	for j = -2, 4 do
		if j == 3 or j == 4 then
			for i = -2, 2 do
			for k = -2, 2 do
				local vi = area:index(x + i, y + j, z + k)
				if math.random(64) == 2 then
					data[vi] = c_apple
				elseif math.random(5) ~= 2 then
					data[vi] = c_appleaf
				end
			end
			end
		elseif j == 2 then
			for i = -1, 1 do
			for k = -1, 1 do
				if math.abs(i) + math.abs(k) == 2 then
					local vi = area:index(x + i, y + j, z + k)
					data[vi] = c_tree
				end
			end
			end
		else
			local vi = area:index(x, y + j, z)
			data[vi] = c_tree
		end
	end
end

function fracture_cactus(x, y, z, area, data)
	local c_cactus = minetest.get_content_id("fracture:cactus")
	for j = -2, 4 do
	for i = -2, 2 do
		if i == 0 or j == 2 or (j == 3 and math.abs(i) == 2) then
			local vi = area:index(x + i, y + j, z)
			data[vi] = c_cactus
		end
	end
	end
end

function fracture_flower(data, vi)
	local c_danwhi = minetest.get_content_id("flowers:dandelion_white")
	local c_danyel = minetest.get_content_id("flowers:dandelion_yellow")
	local c_rose = minetest.get_content_id("flowers:rose")
	local c_tulip = minetest.get_content_id("flowers:tulip")
	local c_geranium = minetest.get_content_id("flowers:geranium")
	local c_viola = minetest.get_content_id("flowers:viola")
	local rand = math.random(6)
	if rand == 1 then
		data[vi] = c_danwhi
	elseif rand == 2 then
		data[vi] = c_rose
	elseif rand == 3 then
		data[vi] = c_tulip
	elseif rand == 4 then
		data[vi] = c_danyel
	elseif rand == 5 then
		data[vi] = c_geranium
	else
		data[vi] = c_viola
	end
end

-- Singlenode option

local SINGLENODE = false

if SINGLENODE then
	minetest.register_on_mapgen_init(function(mgparams)
		minetest.set_mapgen_params({mgname="singlenode", water_level=-32000})
	end)

	-- Spawn player. Dependant on chunk size = 5 mapblocks

	function spawnplayer(player)
		local TSTONE = 0.02
		local PSCA = 26 -- Player scatter from world centre in chunks (80 nodes).
		local xsp
		local ysp
		local zsp
		local np_realm = {
			offset = 0,
			scale = 1,
			spread = {x=8192, y=8192, z=8192},
			seed = 98320,
			octaves = 3,
			persist = 0.4
		}
		local np_terrain = {
			offset = 0,
			scale = 1,
			spread = {x=384, y=128, z=384},
			seed = 593,
			octaves = 5,
			persist = 0.67
		}
		local np_terralt = {
			offset = 0,
			scale = 1,
			spread = {x=621, y=207, z=621},
			seed = 593,
			octaves = 5,
			persist = 0.67
		}
		for chunk = 1, 128 do
			print ("[fracture] searching for spawn "..chunk)
			local x0 = 80 * math.random(-PSCA, PSCA) - 32
			local z0 = 80 * math.random(-PSCA, PSCA) - 32
			local y0 = 80 * math.random(-PSCA, PSCA) - 32
			local x1 = x0 + 79
			local z1 = z0 + 79
			local y1 = y0 + 79
	
			local sidelen = 80
			local chulens = {x=sidelen, y=sidelen, z=sidelen}
			local minposxyz = {x=x0, y=y0, z=z0}

			local nvals_realm = minetest.get_perlin_map(np_realm, chulens):get3dMap_flat(minposxyz)
			local nvals_terrain = minetest.get_perlin_map(np_terrain, chulens):get3dMap_flat(minposxyz)
			local nvals_terralt = minetest.get_perlin_map(np_terralt, chulens):get3dMap_flat(minposxyz)
	
			local nixyz = 1
			local stable = {}
			for z = z0, z1 do
				for y = y0, y1 do
					for x = x0, x1 do
						local si = x - x0 + 1
						local n_realm = nvals_realm[nixyz]
						local n_terrain = nvals_terrain[nixyz]
						local n_terralt = nvals_terralt[nixyz]
						local density = (n_terrain + n_terralt) * 0.5 - math.abs(n_realm) ^ 1.5 * 64

						if density >= TSTONE then
							stable[si] = true
						elseif stable[si] and density < 0 then
							ysp = y + 1
							xsp = x
							zsp = z
							break
						end
						nixyz = nixyz + 1
					end
					if ysp then
						break
					end
				end
				if ysp then
					break
				end
			end
			if ysp then
				break
			end
		end
		print ("[fracture] spawn player ("..xsp.." "..ysp.." "..zsp..")")
		player:setpos({x=xsp, y=ysp, z=zsp})
	end

	minetest.register_on_newplayer(function(player)
		spawnplayer(player)
	end)

	minetest.register_on_respawnplayer(function(player)
		spawnplayer(player)
		return true
	end)
end

-- ABM

-- Appletree sapling

minetest.register_abm({
	nodenames = {"fracture:appling"},
	interval = 31,
	chance = 5,
	action = function(pos, node)
		local x = pos.x
		local y = pos.y
		local z = pos.z
		local vm = minetest.get_voxel_manip()
		local pos1 = {x=x-2, y=y-2, z=z-2}
		local pos2 = {x=x+2, y=y+4, z=z+2}
		local emin, emax = vm:read_from_map(pos1, pos2)
		local area = VoxelArea:new({MinEdge=emin, MaxEdge=emax})
		local data = vm:get_data()
		fracture_appletree(x, y, z, area, data)
		vm:set_data(data)
		vm:write_to_map()
		vm:update_map()
	end,
})

