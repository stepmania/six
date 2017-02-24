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
		_total   = 0,
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
	self._total = self._total + 1

	update_score(self)
	assert(self.dp <= self._max_dp, string.format("Scoring bug: dp > max_dp (%d %d)", self.dp, self._max_dp))
end

return setmetatable({ new = new }, score_mt)
