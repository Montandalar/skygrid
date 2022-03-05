local skygrid = {}

local gridlen = tonumber(minetest.settings:get("skygrid.grid_length"))
if gridlen == nil or gridlen == 0 then
	gridlen = 4
end

-- A few important cids for special rules like plants, chests and spawners
local CONTENT_DIRT = minetest.get_content_id("mcl_core:dirt")
local CONTENT_STONE = minetest.get_content_id("mcl_core:stone")
local CONTENT_SAND = minetest.get_content_id("mcl_core:sand")
local CONTENT_WATER_SOURCE = minetest.get_content_id("mcl_core:water_source")
local CONTENT_VINE = minetest.get_content_id("mcl_core:vine")
local CONTENT_CACTUS = minetest.get_content_id("mcl_core:cactus")
local CONTENT_NETHER_WART = minetest.get_content_id("mcl_nether:nether_wart_0")
local CONTENT_NETHER_BRICK = minetest.get_content_id("mcl_nether:nether_brick")
local CONTENT_CHEST = minetest.get_content_id("mcl_chests:chest")
local CONTENT_SPAWNER = minetest.get_content_id("mcl_mobspawners:spawner")

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

local plants = {}
local function indexplants()
	local cid = nil
	for idx, plant in ipairs({
		"mcl_core:sapling",
		"mcl_flowers:tallgrass",
		"mcl_core:deadbush",
		"mcl_flowers:dandelion",
		"mcl_flowers:poppy",
		"mcl_mushrooms:mushroom_brown",
		"mcl_mushrooms:mushroom_red",
		"mcl_core:reeds",
	}) do
		cid = minetest.get_content_id(plant)
		plants[cid] = 1
	end
end
skygrid.plants = plants
indexplants()

local overworld_p = {
	[minetest.get_content_id("mcl_core:stone")] = 120,
	[minetest.get_content_id("mcl_core:dirt_with_grass")] = 80,
	[minetest.get_content_id("mcl_core:dirt")] = 20,
	-- Disabled for now - liquids can't avoid block updates under MCL2
	-- [minetest.get_content_id("mcl_core:water_source")] = 10,
	-- [minetest.get_content_id("mcl_core:lava_source")] = 5,
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
	minetest.log("warning", string.format("Failed to pick a content ID at: %s",
		minetest.pos_to_string(pos)))
end

local function random_normalised(randy)
	return ((randy:next()/2147483647+1)/2)
end

local chest_items_1 = {}
local function gen_chest_items_1()
	local items = {
		"mcl_fire:flint_and_steel",
		"mcl_core:apple",
		"mcl_bows:bow",
		"mcl_bows:arrow",
		"mcl_core:coal_lump",
		"mcl_core:diamond",
		"mcl_core:iron_ingot",
		"mcl_core:gold_ingot",
		"mcl_core:stick",
		"mcl_core:bowl",
		"mcl_mushrooms:mushroom_stew",
		"mcl_mobitems:string",
		"mcl_mobitems:feather",
		"mcl_farming:hoe_diamond",
		"mcl_farming:hoe_gold",
		"mcl_farming:hoe_iron",
		"mcl_farming:hoe_stone",
		"mcl_farming:hoe_wood",
	}

	local itemstring
	for idx_typ, typ in pairs({"sword", "shovel", "pick", "axe",}) do
		for idx_mat, mat in pairs({"diamond", "gold", "iron", "stone", "wood"}) do
			itemstring = string.format("mcl_tools:%s_%s", typ, mat)
			table.insert(items, #items+1, itemstring)
		end
	end

	items.size = #items
	return items
end

chest_items_1 = gen_chest_items_1()

local chest_items_armours = {}
local function gen_chest_items_armours()
	local items = {}

	local itemstring
	for idx_typ, typ in pairs({"boots", "chestplate", "helmet", "leggings"}) do
		for idx_mat, mat in pairs({"chain", "diamond", "gold", "iron", "leather"}) do
			itemstring = string.format("mcl_armor:%s_%s", typ, mat)
			table.insert(items, #items+1, itemstring)
		end
	end

	items.size = #items
	return items
end

chest_items_armours = gen_chest_items_armours()

local chest_items_2 = {
	"mcl_core:flint",
	"mcl_mobitems:porkchop",
	"mcl_mobitems:cooked_porkchop",
	"mcl_paintings:painting",
	"mcl_core:apple_gold",
	"mcl_signs:wall_sign",
	"mcl_doors:wooden_door",
	"mcl_buckets:bucket_empty",
	"mcl_buckets:bucket_water",
	"mcl_buckets:bucket_lava",
	"mcl_minecarts:minecart",
	"mcl_mobitems:saddle",
	"mcl_doors:iron_door",
	"mesecons:wire_00000000_off",
	"mcl_throwing:snowball",
	"mcl_boats:boat",
	"mcl_mobitems:leather",
	"mcl_mobitems:milk_bucket",
	"mcl_core:brick",
	"mcl_core:clay_lump",
	"mcl_core:reeds",
	"mcl_core:paper",
	"mcl_books:book",
	"mcl_mobitems:slimeball",
	-- These should be the cart with chest and furnace but they aren't
	--present in Mineclone2 :(
	"mcl_minecarts:minecart",
	"mcl_minecarts:minecart",
	"mcl_throwing:egg",
	"mcl_compass:17",
	"mcl_fishing:fishing_rod",
	"mcl_clock:clock",
	"mcl_nether:glowstone_dust",
	"mcl_fishing:fish_raw",
	"mcl_fishing:fish_cooked",
}
chest_items_2.size = #chest_items_2

local mob_egg_loot_aggro = {
	"mobs_mc:creeper",
	"mobs_mc:skeleton",
	"mobs_mc:spider",
}
mob_egg_loot_aggro.size = #mob_egg_loot_aggro

local mob_egg_loot_nasty = {
	"mobs_mc:zombie",
	"mobs_mc:slime_big",
	"mobs_mc:ghast",
	"mobs_mc:pigman",
	"mobs_mc:enderman",
	"mobs_mc:cave_spider",
	"mobs_mc:silverfish",
	"mobs_mc:blaze",
	"mobs_mc:magma_cube_big",
}
mob_egg_loot_nasty.size = #mob_egg_loot_nasty

local mob_egg_loot_nice = {
	"mobs_mc:pig",
	"mobs_mc:sheep",
	"mobs_mc:cow",
	"mobs_mc:chicken",
	"mobs_mc:squid",
	"mobs_mc:wolf",
	"mobs_mc:mooshroom",
}
mob_egg_loot_nice.size = #mob_egg_loot_nice

local chest_nodes_loot = {
	"mcl_core:stone",
	"mcl_core:dirt_with_grass",
	"mcl_core:dirt",
	"mcl_core:cobble",
	"mcl_core:wood",
}
chest_nodes_loot.size = #chest_nodes_loot

local chest_saplings_loot = {
	"mcl_core:sapling",
	"mcl_core:sprucesapling",
	"mcl_core:birchsapling",
	"mcl_core:junglesapling",
}
chest_saplings_loot.size = #chest_saplings_loot

-- Analogous to createItemInRange from SethBling plugin
local function add_loot_to_chest(list, randy, inv, count)
	count = count or 1
	local listsize = list.size
	local loot_idx = randy:next(1,listsize)
	local itemstack_str = list[loot_idx] .. " " .. tostring(count)
	--minetest.log("warning", "itemstack_str = ".. itemstack_str)
	local itemstack = ItemStack(itemstack_str)
	--minetest.log("warning", "itemstack =".. dump(itemstack))
	-- Working as intended: SethBling's plugin could overwrite items from the
	--same slot just like this can.
	local chest_spot = randy:next(1,24)
	--minetest.log("warning", "chest_spot =".. dump(chest_spot))
	--minetest.log("warning", "result: " .. tostring(inv:set_stack("main", chest_spot, itemstack)))
	inv:set_stack("main", chest_spot, itemstack)
end

-- Analogous to fillChestAt in SethBling plugin
local function gen_chest_inv_at(pos, perlin)
	local noise = perlin:get_3d(pos)
	local randy = PcgRandom(noise, minetest.hash_node_position(pos))
	local meta = minetest.get_meta(pos)
	local inv = meta:get_inventory()
	local result = ""
	local stack

	--minetest.log("warning", string.format("pos = %s, chest random result = %f", minetest.pos_to_string(pos), result))
	if random_normalised(randy) < 0.7 then
		add_loot_to_chest(chest_items_1, randy, inv)
	end

	if random_normalised(randy) < 0.7 then
		add_loot_to_chest(chest_items_armours, randy, inv)
	end

	if random_normalised(randy) < 0.7 then
		add_loot_to_chest(chest_items_2, randy, inv)
	end

	if random_normalised(randy) < 0.3 then
		add_loot_to_chest(mob_egg_loot_aggro, randy, inv)
	end

	if random_normalised(randy) < 0.9 then
		add_loot_to_chest(mob_egg_loot_nasty, randy, inv)
	end

	if random_normalised(randy) < 0.4 then
		add_loot_to_chest(mob_egg_loot_nice, randy, inv)
	end

	if random_normalised(randy) < 0.1 then
		inv:set_stack("main", randy:next(1,24), ItemStack("mobs_mc:ocelot 1"))
	end

	if random_normalised(randy) < 0.1 then
		inv:set_stack("main", randy:next(1,24), ItemStack("mobs_mc:villager 1"))
	end

	if random_normalised(randy) < 0.7 then
		add_loot_to_chest(chest_nodes_loot, randy, inv, randy:next(10,64))
	end

	add_loot_to_chest(chest_saplings_loot, randy, inv)

	return inv
end

local function gen_spawner_at(dimension, pos)
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

	-- FIXME: non-uniform for size 11 and probably other numbers that aren't
	-- divisors of 16 (block size) or 48 (chunk size). Should work from a
	-- block-aligned basis instead of whatever x_min this callback gave us.
	for x = x_min, x_max, gridlen do
		for y = y_min, y_max, gridlen do
			for z = z_min, z_max, gridlen do
				local voxindex = area:index(x,y,z)
				local pos = vector.new(x,y,z)
				local cid = decide_cid(pos, perlin, dimension)

				-- Put plants above a dirt node
				if (plants[cid]) then
					vm_data[voxindex] = CONTENT_DIRT
					vm_data[area:index(x,y+1,z)] = cid
				elseif cid == CONTENT_CACTUS then
					vm_data[voxindex] = CONTENT_SAND
					if y < y_max then
						vm_data[area:index(x,y+1,z)] = cid
					else
						vm_data[area:index(x,y-1,z)] = CONTENT_VINE
					end
				elseif cid == CONTENT_NETHER_WART then
					-- Working as intended: Sethbling's original skygrid places
					-- nether warts on nether brick blocks instead of soul sand
					vm_data[voxindex] = CONTENT_NETHER_BRICK
					if y < y_max then
						vm_data[area:index(x,y+1,z)] = CONTENT_NETHER_WART
					end
				else
					vm_data[voxindex] = cid
				end

				if cid == CONTENT_CHEST then
					-- Need set_node to make chests work; voxmanip is too basic
					minetest.set_node(pos, {name="mcl_chests:chest", param2=0})
					gen_chest_inv_at(pos, perlin)
				end

				if cid == CONTENT_SPAWNER then
					gen_spawner_at(dimension, pos)
				end
			end
		end
	end

	-- TODO: end portal in overworld after range check including
	-- correct rotation

	voxmanip:set_data(vm_data)
	voxmanip:set_lighting({day = 0, night = 0})
	voxmanip:calc_lighting()
	voxmanip:write_to_map(vm_data)

end

minetest.register_on_generated(ongen)
