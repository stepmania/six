local actor = require "actor"
local anchor = require "anchor"
local cpml = require "cpml"
local inifile = require "inifile"
local memoize = require "memoize"

anchor:set_overscan(0.1)
anchor:update()

local theme = {}
local theme_mt = {
	__index = theme
}

function theme:get_path(filename)
	return string.format("%s/%s", self.base_dir, filename)
end

function theme:get_metric(section, key)
	if not self.metrics[section] then
		return nil
	end
	local chunk = assert(loadstring("return (" .. self.metrics[section][key] .. ")"))
	setfenv(chunk, self.env)
	return assert(chunk())
end

function theme:run_file(filename)
	local ok, screen = pcall(love.filesystem.load, filename)
	if not ok then
		error(screen)
	end

	setfenv(screen, self.env)

	local ok, data = pcall(screen)
	if not ok then
		error(data)
	end

	return data
end

function theme:get_screen_files(screen)
	local files = {}
	local search = {
		"%s.lua",
		"%s/default.lua"
	}
	for _, pattern in ipairs(search) do
		local filename = self:get_path(string.format(pattern, screen))
		if love.filesystem.isFile(filename) then
			-- print(filename)
			table.insert(files, filename)
		end
	end
	return files
end

local function load_theme(params)
	local t = setmetatable({
		base_dir = assert(params.path),
		metrics  = inifile.parse(params.metrics)
	}, theme_mt)

	local actor_frame = setmetatable({}, {
		__call = function(_, ...)
			return actor(...)
		end
	})

	local load_texture = memoize(function(filename)
		return love.graphics.newImage(t:get_path(filename))
	end)

	local sprite = setmetatable({}, {
		__call = function(_, ...)
			local ret = actor(...)
			if ret.Texture then
				ret._texture = load_texture(ret.Texture)
				local top = ret:_get_top()
				top.size.x = ret._texture:getWidth()
				top.size.y = ret._texture:getHeight()
			end
			return ret
		end
	})

	local env = {
		-- basic lua stuff
		print = print,
		string = string,

		-- actors
		Def = {
			ActorFrame = actor_frame,
			Actor = actor,
			Sprite = sprite
		},

		-- useful vars
		SCREEN_TOP      = anchor:top(),
		SCREEN_BOTTOM   = anchor:bottom(),
		SCREEN_LEFT     = anchor:left(),
		SCREEN_RIGHT    = anchor:right(),
		SCREEN_CENTER_X = anchor:center_x(),
		SCREEN_CENTER_Y = anchor:center_y(),
		SCREEN_WIDTH    = anchor:width(),
		SCREEN_HEIGHT   = anchor:height(),
		SCREEN_WIDTH_FULL  = love.graphics.getWidth(),
		SCREEN_HEIGHT_FULL = love.graphics.getHeight()
	}

	t.env = env

	local initial_screen = assert(t:get_metric("Common", "InitialScreen"))
	local files = t:get_screen_files(initial_screen)

	t.root = actor_frame {}
	for _, file in ipairs(files) do
		table.insert(t.root.children, t:run_file(file))
	end

	return t
end

local function get_themes()
	local base = "Themes"
	local themes = love.filesystem.getDirectoryItems(base)
	local theme_list = {}
	for _, v in ipairs(themes) do
		local theme_dir = string.format("%s/%s", base, v)
		local metrics = string.format("%s/metrics.ini", theme_dir, v)
		if love.filesystem.isFile(metrics) then
			table.insert(theme_list, {
				name = v,
				path = theme_dir,
				metrics = metrics
			})
			theme_list[v] = theme_list[#theme_list]
		end
	end
	return theme_list
end

local theme_list = get_themes()
local theme = load_theme(theme_list.default)

local function event(root, message, params)
	local msg = message .. "Command"
	actor.walk(root, function(self)
		if self.commands[msg] then
			self.commands[msg](self, params)
		end
	end)
end

function love.keypressed(k)
	if love.keyboard.isDown("lshift") or love.keyboard.isDown("rshift") then
		if k == "escape" then
			love.event.quit()
		end
	end
end

local function smupdate(self, parent, dt)
	local cmds = self.commands
	if self._first_update then
		if cmds.InitCommand then
			cmds.InitCommand(self)
		end
		self._first_update = false
	end

	actor.update_internal(self, dt)

	local bounds = {
		min = cpml.vec3(self._vertices[1][1], self._vertices[1][2], 0),
		max = cpml.vec3(self._vertices[1][1], self._vertices[1][2], 0)
	}

	for _, vertex in ipairs(self._vertices) do
		bounds.min.x = math.min(vertex[1], bounds.min.x)
		bounds.min.y = math.min(vertex[2], bounds.min.y)

		bounds.max.x = math.max(vertex[1], bounds.max.x)
		bounds.max.y = math.max(vertex[2], bounds.max.y)
	end

	self._bounds = bounds

	local mx, my = love.mouse.getPosition()
	local mouse = cpml.vec3(mx, my, 0)
	if cpml.intersect.point_aabb(mouse, bounds) then
		if not self._hover then
			event(self, "MouseEnter")
		end
		self._hover = true
	else
		if self._hover then
			event(self, "MouseLeave")
		end
		self._hover = false
	end
end

function love.mousepressed(x, y, button)
	local mouse = cpml.vec3(x, y, 0)
	actor.walk(theme.root, function(self)
		if not self._bounds then
			return
		end

		if cpml.intersect.point_aabb(mouse, self._bounds) then
			event(self, "MousePressed", { button = button })
		end
	end)
end

function love.mousereleased(x, y, button)
	local mouse = cpml.vec3(x, y, 0)
	actor.walk(theme.root, function(self)
		if not self._bounds then
			return
		end

		if cpml.intersect.point_aabb(mouse, self._bounds) then
			event(self, "MouseReleased", { button = button })
		end
	end)
end

function love.update(dt)
	anchor:update()
	actor.walk(theme.root, smupdate, dt)
end

local quad = love.graphics.newMesh(4, "fan", "stream")

local function draw(self, parent)
	quad:setTexture(self._texture or nil)
	quad:setVertices(self._vertices)
	love.graphics.draw(quad)
	love.graphics.setColor(200, 200, 0)

	local pos = cpml.vec3(math.floor(self._bounds.min.x), math.floor(self._bounds.min.y), 0)
	-- don't display the name of the root object, it's internal.
	love.graphics.print(parent and (self.Name and self.Name or "<unnamed>") or "", pos.x + 15, pos.y + 10)
	love.graphics.setColor(0, 140, 110)

	love.graphics.setLineWidth(1)
	love.graphics.setLineStyle("rough")
	love.graphics.rectangle("line",
		self._bounds.min.x,
		self._bounds.min.y,
		self._bounds.max.x - self._bounds.min.x,
		self._bounds.max.y - self._bounds.min.y
	)

	love.graphics.setColor(255, 255, 255)
end

function love.draw()
	actor.walk(theme.root, draw, 0)
end
