local coin_t = {}
local coin_mt = {
	__index = coin_t
}

--[[
	local counter = coins.new {
		max_credits     = 20,
		cost_per_credit = 4,
		joint_premium   = true
	}
	local need = counter:getCreditsRequired {
		players = 1,
		double  = true
	}
	print(string.format(
		"doubles costs %d credits (%d coins)",
		need,
		counter.cost_per_credit
	))
--]]
local default_settings = {
	max_credits     = 20,
	cost_per_credit = 1,
	joint_premium   = true
}

local function new(settings)
	settings = settings or default_settings
	assert(type(settings.max_credits     == "number"))
	assert(type(settings.cost_per_credit == "number"))
	assert(type(settings.joint_premium   == "boolean"))

	local t = {
		max_credits     = settings.max_credits,
		cost_per_credit = settings.cost_per_credit,
		joint_premium   = settings.joint_premium,
		credits         = 0,
		coins           = 0
	}
	return setmetatable(t, coin_mt)
end

function coin_t:insertCoin(n)
	n = n or 1
	assert(n > 0)
	self.coins   = self.coins + n
	self.credits = math.floor(self.coins / self.cost_per_credit)
end

function coin_t:useCredit(params)
	local needed = self:getCreditsRequired(params)
	if self.credits >= needed then
		self.credits = self.credits - needed
		return true
	end
	return false
end

function coin_t:getCreditsRequired(params)
	local cost = 1
	if params.double and not self.joint_premium then
		cost = cost * 2
	end
	if params.players then
		assert(type(params.players) == "number")
		cost = cost * params.players
	end
	return cost
end

return setmetatable({ new = new }, coin_mt)
