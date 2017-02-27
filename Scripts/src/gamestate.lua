local gs_t = {}
local gs_mt = {
	__index = gs_t
}

local coins = require "src.coin-counter"

local function new()
	local t = {
		_bookkeeper = coins.new {
			max_credits     = 20,
			cost_per_credit = 4,
			joint_premium   = true
		},
		_stages = {},
		_players = {},
		_master = false
	}
	setmetatable(t, gs_mt)
	t:reset()

	return t
end

function gs_t:reset()
	for pn, _ in pairs(self._players) do
		self:unjoin(pn)
	end
	self._stages = {}
	self:nextStage()
end

function gs_t:nextStage()
	local t = {
		song    = false,
		players = {}
	}
	if #self._stages > 0 then
		local stage = self:getCurrentStage()
		for k, v in ipairs(stage.players) do
			t.players[k] = v
		end
	end
	table.insert(self._stages, t)
end

function gs_t:getCurrentStage()
	assert(#self._stages > 0, "Invalid gamestate: no stages")
	return self._stages[#self._stages]
end

function gs_t:join(pn)
	assert(type(pn) == "number", "`pn` must be a number.")
	if self._players[pn] then
		return
	end
	local players = self:getCurrentStage().players
	table.insert(players, {
		index = pn
	})
	if #players == 1 then
		self._master = pn
	end
	self._players[pn] = #players
end

function gs_t:unjoin(pn)
	assert(type(pn) == "number", "`pn` must be a number.")
	if not self._players[pn] then
		return
	end
	local players = self:getCurrentStage().players
	table.remove(players, self._players[pn])
	self._players[pn] = nil

	if self._master == pn then
		-- player list is in join order, so when master leaves we can use next.
		if #players > 0 then
			self._master = self._players[1]
		end
	end
end

function gs_t.test()
	local gs = new()
	gs:join(1)
	gs:join(3)
	gs:unjoin(1)
	gs:unjoin(3)
	gs:nextStage()
	gs:reset()
end

return setmetatable({ new = new }, gs_mt)
