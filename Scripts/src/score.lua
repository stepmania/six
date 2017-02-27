local score_t = {}
local score_mt = {
	__index = score_t
}

local default_weights = {
	W1 = 9,
	W2 = 6,
	W3 = 3,
	W4 = 2,
	W5 = 1,
	Miss = 0,
	OK = 9,
	NG = 0,
	Mine_OK = 9,
	Mine_NG = 0
}

local score_limit = 100000000

local levels = {
	"W1", "W2", "W3", "W4", "W5", "Miss",
	"OK", "NG",
	"Mine_OK", "Mine_NG"
}

--[[
	info expects a table such as: {
		notes = total tap count,
		holds = total hold count,
		mines = total mine count
	}.

	for an example of weights, look at the default_weights table.
]]
local function new(info, weights)
	weights = weights or default_weights
	local t = {
		_weights = {},
		_values  = {},
		_max_dp  = 0,
		dp       = 0,
		score    = 0,
		percent  = 0
	}
	for _, k in ipairs(levels) do
		t._weights[k] = weights[k]
		t._values[k] = 0
	end

	local dp = 0
	dp = dp + info.notes * weights.W1
	dp = dp + info.holds * weights.OK
	dp = dp + info.mines * weights.Mine_OK
	t._max_dp = dp

	return setmetatable(t, score_mt)
end

local function update_score(self)
	assert(self._max_dp > 0)

	local dp = 0
	for _, k in ipairs(levels) do
		dp = dp + self._values[k] * self._weights[k]
	end

	self.dp = dp
	self.percent = dp / self._max_dp
	self.score = math.floor(self.percent * score_limit)
end

function score_t:hit(level)
	assert(self._weights[level] ~= nil, string.format("Invalid judgment type %s", level))
	self._values[level] = self._values[level] + 1

	update_score(self)
	assert(self.dp <= self._max_dp, string.format("Scoring bug: dp > max_dp (%d %d)", self.dp, self._max_dp))
end

function score_t.test()
	local function log(fmt, ...)
		if select("#", ...) > 0 then
			print(string.format(fmt, ...))
		else
			print(fmt)
		end
	end

	local info = {
		notes = 573,
		holds = 50,
		mines = 10
	}

	local migs = {
		W1 = 3,
		W2 = 2,
		W3 = 1,
		W4 = 0,
		W5 = -4,
		Miss = -8,
		OK = 6,
		NG = 0,
		Mine_OK = 0,
		Mine_NG = -8
	}

	local sm6_score = new(info)
	local migs_score = new(info, migs)

	for _=1,373 do
		sm6_score:hit("W1")
		migs_score:hit("W1")
	end

	for _=1,50 do
		sm6_score:hit("OK")
		migs_score:hit("OK")
	end

	for _=1,10 do
		sm6_score:hit("Mine_OK")
		migs_score:hit("Mine_OK")
	end

	local function commify(num)
		return ("%s")
			:format(tostring(num):reverse():gsub("(%d%d%d)", "%1,"))
			:reverse()
			:gsub(",%.", ".")
			:gsub("^,", "")
			:gsub("%.(.*)", function(s)
				return "."..s:gsub(",", "")
			end)
	end

	local fmt = "%s:\t%s\t(%0.2f%%, %s DP)"
	log(fmt, "SM6 ", commify(sm6_score.score), sm6_score.percent * 100, commify(sm6_score.dp))
	log(fmt, "MIGS", commify(migs_score.score), migs_score.percent * 100, commify(migs_score.dp))

	for _=1,200 do
		sm6_score:hit("W1")
		migs_score:hit("W1")
	end

	log(fmt, "SM6 ", commify(sm6_score.score), sm6_score.percent * 100, commify(sm6_score.dp))
	log(fmt, "MIGS", commify(migs_score.score), migs_score.percent * 100, commify(migs_score.dp))
end

return setmetatable({ new = new }, score_mt)
