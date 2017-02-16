local function log(fmt, ...)
	if select("#", ...) > 0 then
		print(string.format(fmt, ...))
	else
		print(fmt)
	end
end

local c = require "coin-counter"
local counter = c.new {
	max_credits = 20,
	cost_per_credit = 4,
	joint_premium = false
}

counter:insertCoin(6)
log("credits available: %s", counter.credits)

local params = {
	players = 1,
	double  = true
}
log(
	"doubles costs %d credits (%d coins)",
	counter:getCreditsRequired(params),
	counter.cost_per_credit
)

local ok = counter:useCredit(params)
log("can we use it? %s", tostring(ok))
assert(not ok)

counter:insertCoin(2)
ok = counter:useCredit(params)
log("can we use it now? %s", tostring(ok))
assert(ok)
