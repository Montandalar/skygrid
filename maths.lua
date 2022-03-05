-- Lua, Python: mathematical modulus; Java: remainder
-- Return x such that i % m == 0 and x is the closest number to i with such
-- property. Requires m ~=0.
-- This might be simplifiable to remove branching with math.sign but as
-- that's not native *shrug*.
local function mod_align_nearest(i, m)
	if m == 0 then return i end

	local hm = m/2
	local r = i % m
	local round_down

	if i < 0 then
		round_down = (r > hm)
		if round_down then
			return i+(m-r)
		else
			return i-r
		end
	else
		-- not <= because lower side has remainder zero
		round_down = (r < hm)
		if round_down then
			return i-r
		else
			return i+(m-r)
		end
	end
end

local function mod_align_neginf(i, m)
	if (m == 0) then return i end
	return i - (i%m)
end

local function mod_align_posinf(i, m)
	if (m == 0) then return i end
	local r = i % m
	local cr = (m - r) % m
	return i + cr
end

return {
	mod_align_nearest = mod_align_nearest,
	mod_align_neginf = mod_align_neginf,
	mod_align_posinf = mod_align_posinf,
}
