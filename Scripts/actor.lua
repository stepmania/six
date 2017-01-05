local cpml = require "cpml"
local vec3 = cpml.vec3

local function nyi()
	error "function not yet implemented."
end

local actor = {}

local interp = {
	out = function(f)
		return function(s, ...) return 1 - f(1-s, ...) end
	end,
	chain = function(f1, f2)
		return function(s, ...) return (s < .5 and f1(2*s, ...) or 1 + f2(2*s-1, ...)) * .5 end
	end,
	linear = function(s) return s end,
	quad   = function(s) return s*s end,
	cubic  = function(s) return s*s*s end,
}

local tween_types = {
	linear     = interp.linear,
	decelerate = interp.out(interp.quad),
	accelerate = interp.quad,
	smooth     = interp.chain(interp.quad, interp.out(interp.quad)),
	sleep      = function() return 0 end
}

-- These are all the same, might as well just loop...
for tween, v in pairs(tween_types) do
	actor[tween] = function(self, duration)
		assert(type(duration) == "number")
		local top = self:_get_top()
		top.tween_type = v
		top.tween_duration = duration
		self:_push_state()
		return self
	end
end

function actor:hurrytweening(rate)
	self._current_state.rate = rate
	return self
end

function actor:finishtweening()
	self._tween_stack[1] = self:_get_top()

	while #self._tween_stack > 1 do
		table.remove(self._tween_stack)
	end

	return self
end

function actor:stoptweening()
	while #self._tween_stack > 1 do
		table.remove(self._tween_stack)
	end

	local top = self:_get_top()

	for _, k in ipairs(self._keys) do
		top[k] = self._current_state[k]
	end

	return self
end

function actor:diffusetopedge(color)
	local top = self:_get_top()
	for i=1, 4 do
		top.color1[i] = color[i] or 1
		top.color2[i] = color[i] or 1
	end
end

function actor:diffusebottomedge(color)
	local top = self:_get_top()
	for i=1, 4 do
		top.color3[i] = color[i] or 1
		top.color4[i] = color[i] or 1
	end
end

function actor:x(x)
	assert(x)
	self:_get_top().position.x = x
	return self
end

function actor:y(y)
	assert(y)
	self:_get_top().position.y = y
	return self
end

function actor:z(z)
	assert(z)
	self:_get_top().position.z = z
	return self
end

function actor:xy(x, y)
	self:x(x)
	self:y(y)
	return self
end

function actor:addx(x)
	assert(y)
	local top = self:_get_top().position
	top.x = top.x + x
	return self
end

function actor:addy(y)
	assert(y)
	local top = self:_get_top().position
	top.y = top.y + y
	return self
end

function actor:addxy(x, y)
	self:x(x)
	self:y(y)
	return self
end

function actor:setsize(x, y)
	local size = self:_get_top().size
	size.x = x
	size.y = y
end

-- TODO: rotate quaternions instead?
function actor:rotationx(rx)
	assert(rx)
	self:_get_top().rotation.x = math.rad(rx)
	return self
end

function actor:rotationy(ry)
	assert(ry)
	self:_get_top().rotation.y = math.rad(ry)
	return self
end

function actor:rotationz(rz)
	assert(rz)
	self:_get_top().rotation.z = math.rad(rz)
	return self
end

function actor:zoom(zoom)
	assert(zoom)
	local top = self:_get_top()
	top.scale.x = zoom
	top.scale.y = zoom
	top.scale.z = zoom
	return self
end

function actor:zoomx(zoomx)
	assert(zoomx)
	self:_get_top().scale.x = zoomx
	return self
end

function actor:zoomy(zoomy)
	assert(zoomy)
	self:_get_top().scale.z = zoomy
	return self
end

function actor:zoomz(zoomz)
	assert(zoomz)
	self:_get_top().scale.z = zoomz
	return self
end

function actor:basezoom(zoom)
	assert(zoom)
	local top = self:_get_top()
	top.base_scale.x = zoom
	top.base_scale.y = zoom
	top.base_scale.z = zoom
	return self
end

function actor:basezoomx(zoomx)
	assert(zoomx)
	self:_get_top().base_scale.z = zoomx
	return self
end

function actor:basezoomy(zoomy)
	assert(zoomy)
	self:_get_top().base_scale.z = zoomy
	return self
end

function actor:basezoomz(zoomz)
	assert(zoomz)
	self:_get_top().base_scale.z = zoomz
	return self
end

function actor:queuecommand(name, params)
	local top = self:_get_top()
	if not top.command_queue then
		top.command_queue = {}
	end
	table.insert(top.command_queue, {
		name = name .. "Command",
		params = params
	})
	return self
end

function actor:align(x, y)
	local top = self:_get_top()
	top.align.x = cpml.utils.clamp(x or 0, 0, 1)
	top.align.y = cpml.utils.clamp(y or 0, 0, 1)
	return self
end

function actor:_get_top()
	return self._tween_stack[#self._tween_stack]
end

function actor:_get_bottom()
	return self._tween_stack[1]
end

function actor:_get_next()
	assert(#self._tween_stack >= 2, "Stack underflow")
	return self._tween_stack[2]
end

function actor:_push_state()
	assert(#self._tween_stack < 64, "Stack overflow")
	local top = self:_get_top()
	local clone = {}

	-- NOTE: this gets called a lot, so don't use pairs (dammit luajit)
	for _, k in ipairs(self._keys) do
		-- vector-esque types have :clone() methods.
		local v = top[k]
		if type(v) == "table" and v.clone or vec3.is_vec3(v) then
			clone[k] = v:clone()
		else
			clone[k] = v
		end
	end

	table.insert(self._tween_stack, clone)
end

function actor:_next_state()
	local anim = self._current_state
	local next_state = self:_get_next()
	for _, k in ipairs(self._keys) do
		local next_item = next_state[k]
		anim[k] = next_item
	end

	assert(#self._tween_stack >= 2, "Stack underflow")
	table.remove(self._tween_stack, 1)
end

local actor_mt = {
	__index = actor
}

local function mtx_srt(translate, rotate, scale)
	local _sx, _sy, _sz = scale:unpack()
	local _tx, _ty, _tz = translate:unpack()
	local _ax, _ay, _az = rotate:unpack()

	local sx, sy, sz = math.sin(_ax), math.sin(_ay), math.sin(_az)
	local cx, cy, cz = math.cos(_ax), math.cos(_ay), math.cos(_az)

	local sxsz = sx*sz
	local cycz = cy*cz

	return cpml.mat4 {
		_sx * (cycz - sxsz*sy), _sx * -cx*sz, _sx * (cz*sy + cy*sxsz), 0.0,
		_sy * (cz*sx*sy + cy*sz), _sy * cx*cz, _sy * (sy*sz -cycz*sx), 0.0,
		_sz * -cx*sy, _sz * sx, _sz * cx*cy, 0.0,
		_tx, _ty, _tz, 1.0
	}
end

local function update_internal(self, dt)
	local anim = self._current_state
	local state = self:_get_bottom()

	if state.command_queue then
		for _, event in ipairs(state.command_queue) do
			self.commands[event.name](self, event.params)
		end
		state.command_queue = false
	end

	if state.tween_duration then
		anim.time = anim.time + dt * anim.rate

		local next_state = self:_get_next()
		local fn = state.tween_type

		local position = fn(math.min(anim.time / state.tween_duration, 1))

		for _, k in ipairs(self._keys) do
			local item = state[k]
			local next_item = next_state[k]
			if cpml.vec3.is_vec3(item) then
				anim[k] = cpml.vec3.lerp(item, next_item, position)
			elseif cpml.color.is_color(item) then
				anim[k] = cpml.color.lerp(item, next_item, position)
			else
				anim[k] = cpml.utils.lerp(position, item, next_item)
			end
		end

		if anim.time >= state.tween_duration then
			anim.time = 0
			self:_next_state()
		end

		-- reset rate if we've exhausted the tween stack
		if not self:_get_bottom().tween_duration then
			anim.rate = 1
		end
	end

	self.matrix = mtx_srt(anim.position, anim.rotation, anim.base_scale * anim.scale)

	if self.parent then
		self.matrix = self.parent.matrix * self.matrix
	end

	local size  = anim.size
	local pos   = cpml.vec3(
		math.floor(0 - size.x * anim.align.x),
		math.floor(0 - size.y * anim.align.y),
		math.floor(0 - size.z * anim.align.z)
	)
	local color1 = { anim.color1:unpack(false) }
	local color2 = { anim.color2:unpack(false) }
	local color3 = { anim.color3:unpack(false) }
	local color4 = { anim.color4:unpack(false) }
	local vertices = {
		{ pos.x, pos.y, 0, 0, color1[1], color1[2], color1[3], color1[4] },
		{ pos.x + size.x, pos.y, 1, 0, color2[1], color2[2], color2[3], color2[4] },
		{ pos.x + size.x, pos.y + size.y, 1, 1, color3[1], color3[2], color3[3], color3[4] },
		{ pos.x, pos.y + size.y, 0, 1, color4[1], color4[2], color4[3], color4[4] },
	}
	for i=1,#vertices do
		local p = self.matrix * cpml.vec3(vertices[i][1], vertices[i][2], 0)
		vertices[i][1], vertices[i][2] = p.x, p.y
	end

	self._vertices = vertices
end

local function new(t)
	local data = {
		children = {},
		commands = {},
		matrix   = cpml.mat4(),
		parent   = false
	}

	for k, v in pairs(t) do
		if type(v) == "function" then
			data.commands[k] = v
		elseif type(v) == "table" and getmetatable(v) == actor_mt then
			v.parent = data
			table.insert(data.children, v)
		else
			data[k] = v
		end
	end

	data._first_update  = true
	data._current_state = {
		time = 0,
		rate = 1,
	}
	data._tween_stack   = {{
		command_queue = false,
		align      = vec3(0, 0, 0),
		position   = vec3(0, 0, 0),
		rotation   = vec3(0, 0, 0),
		scale      = vec3(1, 1, 1),
		base_scale = vec3(1, 1, 1),
		size       = vec3(0, 0, 0),
		color1     = cpml.color(1, 1, 1, 1),
		color2     = cpml.color(1, 1, 1, 1),
		color3     = cpml.color(1, 1, 1, 1),
		color4     = cpml.color(1, 1, 1, 1)
	}}
	data._keys = {
		"align",
		"position",
		"rotation",
		"scale", "base_scale",
		"size",
		"color1", "color2", "color3", "color4"
	}
	for _, v in ipairs(data._keys) do
		data._current_state[v] = data._tween_stack[1][v]
	end
	return setmetatable(data, actor_mt)
end

-- basic update, doesn't call any commands.
local function update(self, dt)
	actor.update_internal(self, dt)
end

-- Animation stack debug util
local function dump(self, level)
	local indent = string.rep(" ", level * 2)
	for i, state in ipairs(self._tween_stack) do
		print(string.format("%sstate: %d {", indent, i))
		local _indent = string.rep(" ", (level+1) * 2)
		for k, v in pairs(state) do
			print(_indent .. k, v)
		end
		print(indent .. "}")
	end
end

-- recursive walk through children, for whatever reason you may have.
local function walk(self, fn, ...)
	assert(fn)
	local function step(self, parent, level, ...)
		fn(self, parent, ...)
		for _, child in ipairs(self.children) do
			step(child, self, level + 1, ...)
		end
	end
	return step(self, false, 0, ...)
end

return setmetatable(
	{ new = new, update = update, dump = dump, walk = walk, update_internal = update_internal },
	{ __call = function(_, ...) return new(...) end }
)
