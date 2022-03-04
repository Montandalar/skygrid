local skygrid = {}

local gridlen = tonumber(minetest.settings:get("skygrid.grid_length"))
if gridlen == nil or gridlen == 0 then
	gridlen = 4
end

local cid_dirt = minetest.get_content_id("mcl_core:dirt")
local cid_stone = minetest.get_content_id("mcl_core:stone")

local vm_data = {}

-- 0.5, 0,5: 0 <= x <= 1
-- 1, 1: 0 <= x <= 2
-- 2, 2: 0 <= x <= 4
-- 3, 3: 0 <= x <= 6
-- 3.5, 3.5: 0 <= x <= 7 ?
local np_grid = {
	offset = nil,
	scale = nil,
	spread = vector.new(1,1,1),
	seed = 0,
	octaves = 1,
	persist = 1,
}

local overworld_p = {
	[minetest.get_content_id("mcl_core:stone")] = 120,
	[minetest.get_content_id("mcl_core:dirt_with_grass")] = 80,
	[minetest.get_content_id("mcl_core:dirt")] = 20,
	-- Disabled for now - liquids can't avoid block updates under MCL2
	--[minetest.get_content_id("mcl_core:water_source")] = 10,
	--[minetest.get_content_id("mcl_core:lava_source")] = 5,
	[minetest.get_content_id("mcl_core:sand")] = 20,
	[minetest.get_content_id("mcl_core:gravel")] = 10,
	[minetest.get_content_id("mcl_core:stone_with_gold")] = 10,
	[minetest.get_content_id("mcl_core:stone_with_iron")] = 20,
	[minetest.get_content_id("mcl_core:stone_with_coal")] = 40,
	[minetest.get_content_id("mcl_core:tree")] = 100,
	[minetest.get_content_id("mcl_core:leaves")] = 40,
	[minetest.get_content_id("mcl_core:glass")] = 1,
	[minetest.get_content_id("mcl_core:stone_with_lapis")] = 5,
	[minetest.get_content_id("mcl_core:sandstone")] = 10,
	[minetest.get_content_id("mesecons_pistons:piston_sticky_off")] = 1,
	[minetest.get_content_id("mcl_flowers:tallgrass")] = 3,
	[minetest.get_content_id("mcl_core:deadbush")] = 3,
	[minetest.get_content_id("mesecons_pistons:piston_normal_off")] = 1,
	[minetest.get_content_id("mcl_wool:white")] = 25,
	[minetest.get_content_id("mcl_flowers:dandelion")] = 2,
	[minetest.get_content_id("mcl_flowers:poppy")] = 2,
	[minetest.get_content_id("mcl_mushrooms:mushroom_brown")] = 2,
	[minetest.get_content_id("mcl_mushrooms:mushroom_red")] = 2,
	[minetest.get_content_id("mcl_tnt:tnt")] = 2,
	[minetest.get_content_id("mcl_books:bookshelf")] = 3,
	[minetest.get_content_id("mcl_core:mossycobble")] = 5,
	[minetest.get_content_id("mcl_core:obsidian")] = 5,
	[minetest.get_content_id("mcl_mobspawners:spawner")] = 1,
	[minetest.get_content_id("mcl_chests:chest")] = 1,
	[minetest.get_content_id("mcl_core:stone_with_diamond")] = 1,
	[minetest.get_content_id("mcl_core:stone_with_redstone")] = 12,
	[minetest.get_content_id("mcl_core:ice")] = 4,
	[minetest.get_content_id("mcl_core:snowblock")] = 8,
	[minetest.get_content_id("mcl_core:cactus")] = 1,
	[minetest.get_content_id("mcl_core:clay")] = 20,
	[minetest.get_content_id("mcl_core:reeds")] = 15,
	[minetest.get_content_id("mcl_farming:pumpkin_face")] = 5,
	[minetest.get_content_id("mcl_farming:melon")] = 5,
	[minetest.get_content_id("mcl_core:mycelium")] = 15,
}
skygrid.overworld_p = overworld_p

local nether_p = {
	--[minetest.get_content_id("mcl_core:lava_source")] = 50,
	[minetest.get_content_id("mcl_core:gravel")] = 30,
	[minetest.get_content_id("mcl_mobspawners:spawner")] = 2,
	[minetest.get_content_id("mcl_chests:chest")] = 1,
	[minetest.get_content_id("mcl_nether:netherrack")] = 300,
	[minetest.get_content_id("mcl_nether:soul_sand")] = 100,
	[minetest.get_content_id("mcl_nether:glowstone")] = 50,
	[minetest.get_content_id("mcl_nether:nether_brick")] = 30,
	[minetest.get_content_id("mcl_fences:nether_brick_fence")] = 10,
	[minetest.get_content_id("mcl_stairs:stair_nether_brick")] = 15,
	[minetest.get_content_id("mcl_nether:nether_wart_0")] = 30,
}
skygrid.nether_p = nether_p

function accumulate_probabilities(p)
	local total = 0
	local cump = {}
	for contentid, probability in pairs(p) do
		cump[contentid] = {total, total + probability}
		total = total + probability
	end
	p.cump = cump
	p.total = total
end

accumulate_probabilities(overworld_p)
accumulate_probabilities(nether_p)

for orekey, oredef in pairs(minetest.registered_ores) do
	if oredef.ore == "mcl_end:end_stone" then
		minetest.log("warning", string.format("endstone = %d", orekey))
	end
end

local dimension_register = {}
for _, dimname in pairs({"overworld", "nether", "end"}) do
	local dimregistration = { 
		def = skygrid[dimname.."_p"],
		min = mcl_vars["mg_"..dimname.."_min"],
	}
	-- Limit generation to the generation limit not the build limit
	local max = mcl_vars["mg_"..dimname.."_max_official"] 
		or mcl_vars["mg_"..dimname.."_max"]
	dimregistration.max = max

	dimension_register[dimname] = dimregistration
end

local maxnoise = 0
local minnoise = 5000

local function decide_cid(pos, perlin, dimension)
	local noise = perlin:get_3d(pos)
	if noise > maxnoise then
		maxnoise = noise
	end if noise < minnoise then
		minnoise = noise
	end

	local low local high
	local cump = dimension.cump
	for cid, limits in pairs(cump) do
		low = limits[1]
		high = limits[2]
		if noise >= low and noise < high then
			return cid
		end
	end
	minetest.chat_send_all("fail.")
end

local function ongen(minp, maxp, blockseed)
	local x_min = minp.x
	local y_min = minp.y
	local z_min = minp.z
	local x_max = maxp.x
	local y_max = maxp.y
	local z_max = maxp.z

	local voxmanip, coord_min, coord_max = minetest.get_mapgen_object("voxelmanip")
	local area = VoxelArea:new{MinEdge = coord_min, MaxEdge = coord_max}
	voxmanip:get_data(vm_data)

	local dimension = nil
	for dimname, dimdef in pairs(dimension_register) do
		if y_max > dimdef.min and y_min < dimdef.max then
			dimension = dimdef.def
			break
		end
	end
	-- No applicable dimension
	if dimension == nil then
	return end

	local np = {
		offset = dimension.total/2,
		scale = dimension.total/2,
		spread = np_grid.spread,
		seed = blockseed,
		octaves = np_grid.octaves,
		persist = np_grid.persist,
	}

	--[[ -- Switch to this if bulk update/overwrite gets implemented
local pmapsize = vector.new(
		(x_max - x_min)+1,
		(y_max - y_min)+1,
		(z_max - z_min)+1
	)--]]
	local perlin = PerlinNoise(np) --..Map(np, pmapsize) 

	for x = x_min, x_max, gridlen do
		for y = y_min, y_max, gridlen do
			for z = z_min, z_max, gridlen do
				local voxindex = area:index(x,y,z)
				local pos = vector.new(x,y,z)
				local cid = decide_cid(pos, perlin, dimension)
				vm_data[voxindex] = cid
			end
		end
	end

	voxmanip:set_data(vm_data)
	voxmanip:set_lighting({day = 0, night = 0})
	voxmanip:calc_lighting()
	voxmanip:write_to_map(vm_data)

end

minetest.register_on_generated(ongen)
