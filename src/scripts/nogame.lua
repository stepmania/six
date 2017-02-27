local love = require("love")

function love.keypressed(key)
	if key == "escape" then
		love.event.quit()
	end
end

function love.mousepressed(x, y, b, istouch, clicks)
	-- Double-tap the screen (when using a touch screen) to exit.
	if istouch and clicks == 2 then
		if love.window.showMessageBox("Exit No-Game Screen", "", {"OK", "Cancel"}) == 1 then
			love.event.quit()
		end
	end
end

function love.conf(t)
	t.title = "StepMania"
	t.gammacorrect = true
	t.modules.audio = false
	t.modules.sound = false
	t.modules.joystick = false
	t.window.resizable = true
	t.window.highdpi = true

	t.window.width  = 960
	t.window.height = 540

	io.stdout:setvbuf("no")
end

function love.load()
	local filename = "Scripts/src/stepmania.lua"
	assert(love.filesystem.isFile(filename), "boot script not found")

	local game = love.filesystem.load(filename)
	game()
end
