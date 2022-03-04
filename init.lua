local gridlen = tonumber(minetest.settings:get("skygrid.grid_length"))
if gridlen == nil or gridlen == 0 then
	gridlen = 4
end

local cid_dirt = minetest.get_content_id("mcl_core:dirt")
local cid_stone = minetest.get_content_id("mcl_core:stone")

local vm_data = {}

local np_grid = {
	offset = 1.0,
	scale = 1,
	spread = vector.new(4,4,4),
	seed = 0,
	octaves = 1,
	persist = 1,
}

local function decide_cid(pos, perlin)
	local noise = perlin:get_3d(pos)
	--minetest.chat_send_all(string.format("%d, %d, %d: %s", pos.x, pos.y, pos.z, noise))
	if noise > 0.5 then
		return cid_dirt
	else
		return cid_stone
	end
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

	local np = {
		offset = np_grid.offset,
		scale = np_grid.scale,
		spread = np_grid.spread,
		seed = blockseed,
		octaves = np_grid.octaves,
		persist = np_grid.persist,
	}

	--[[local pmapsize = vector.new(
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
				local cid = decide_cid(pos, perlin)
				vm_data[voxindex] = cid
			end
		end
	end

	voxmanip:set_data(vm_data)
	voxmanip:set_lighting({day = 0, night = 0})
	voxmanip:calc_lighting()
	voxmanip:write_to_map(data)

end

minetest.register_on_generated(ongen)
