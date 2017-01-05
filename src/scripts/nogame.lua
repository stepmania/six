local love = require("love")

local cpml = require "cpml"

function love.keypressed(key)
	if key == "escape" then
		love.event.quit()
	end
end

function love.keyreleased(key)
	if key == "f" then
		local is_fs = love.window.getFullscreen()
		love.window.setFullscreen(not is_fs)
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
