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

function fracture_snowypine(x, y, z, area, data)
	local c_tree = minetest.get_content_id("default:tree")
	local c_needles = minetest.get_content_id("fracture:needles")
	local c_snowblock = minetest.get_content_id("default:snowblock")
	for j = -4, 14 do
		if j == 3 or j == 6 or j == 9 or j == 12 then
			for i = -2, 2 do
			for k = -2, 2 do
				if math.abs(i) == 2 or math.abs(k) == 2 then
					if math.random(7) ~= 2 then
						local vi = area:index(x + i, y + j, z + k)
						data[vi] = c_needles
						local via = area:index(x + i, y + j + 1, z + k)
						data[via] = c_snowblock
					end
				end
			end
			end
		elseif j == 4 or j == 7 or j == 10 then
			for i = -1, 1 do
			for k = -1, 1 do
				if not (i == 0 and j == 0) then
					if math.random(11) ~= 2 then
						local vi = area:index(x + i, y + j, z + k)
						data[vi] = c_needles
						local via = area:index(x + i, y + j + 1, z + k)
						data[via] = c_snowblock
					end
				end
			end
			end
		elseif j == 13 then
			for i = -1, 1 do
			for k = -1, 1 do
				if not (i == 0 and j == 0) then
					local vi = area:index(x + i, y + j, z + k)
					data[vi] = c_needles
					local via = area:index(x + i, y + j + 1, z + k)
					data[via] = c_needles
					local viaa = area:index(x + i, y + j + 2, z + k)
					data[viaa] = c_snowblock
				end
			end
			end
		end
		local vi = area:index(x, y + j, z)
		data[vi] = c_tree
	end
	local vi = area:index(x, y + 15, z)
	local via = area:index(x, y + 16, z)
	local viaa = area:index(x, y + 17, z)
	data[vi] = c_needles
	data[via] = c_needles
	data[viaa] = c_snowblock
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