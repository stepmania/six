local grade_t = {}
local grade_mt = {
	__index = grade_t
}

local default_tiers = {
	{ full_combo = "W1",  requirement = 0.0, life = 1.0 },   -- AAAA, FFC
	{ full_combo = "W2",  requirement = 0.0, life = 1.0 },   -- AAA, FPC
	{ full_combo = "W3",  requirement = 0.0, life = 1.0 },   -- AA, FGC
	{ full_combo = false, requirement = 3/4, life = 0.8 },   -- A, 75% DP, 80% health
	{ full_combo = false, requirement = 2/3, life = 0.0 },   -- B, 66% DP, survived
	{ full_combo = false, requirement = 1/2, life = 0.0 },   -- C, 50% DP, survived
	{ full_combo = false, requirement = 0.0, life = 0.0 },   -- D, survived
	{ full_combo = false, requirement = 0.0, life = false }  -- F, died
}

function grade_t.calc_grade(stats, tiers)
	tiers = tiers or default_tiers

	local grade = 0
	for k, tier in ipairs(tiers) do
		if false
			-- lifebar fail
			or (tier.life and stats.life < tier.life)
			-- didn't meet combo requirement
			or (tier.full_combo and tier.full_combo ~= stats.full_combo)
			-- didn't meet required %
			or (tier.requirement and stats.percent < tier.requirement)
		then
			goto continue
		else
			grade = k
			break
		end
		::continue::
	end

	return grade
end

return setmetatable({}, grade_mt)
