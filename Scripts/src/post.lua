local tested = 0
local passed = 0
local failed = 0
local missing = 0

local status = love.thread.getChannel("test-status")

local function test(name)
	local module = require(name)

	if not module.test then
		print(string.format("module %s has no tests.", name))
		missing = missing + 1
		status:supply { name, "missing" }
		return
	end

	tested = tested + 1
	if module.test and pcall(module.test) then
		passed = passed + 1
		status:supply { name, "passed" }
	else
		failed = failed + 1
		status:supply { name, "failed" }
	end
end

return function()
	tested  = 0
	passed  = 0
	failed  = 0
	missing = 0

	test("src.coin-counter")
	test("src.score")
	test("src.grade")
	test("src.gamestate")

	print(string.format(
		"%d tests completed (passed: %d, failed: %d, missing: %d)",
		tested, passed, failed, missing
	))

	status:supply(false)
end
