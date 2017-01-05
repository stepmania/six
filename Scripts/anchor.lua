-- Helper utilities for positioning things relative to screen anchor points and
-- dealing with overscan.
--
-- Use the default instance or make a new one with anchor.new(params) or using
-- anchor(params). You can control X and Y offset and padding for all 4 edges.
--
-- This library does not retain state for screen dimensions, so resizing should
-- be perfectly fine.

local anchor = {}

local function new(params)
	params = params or {}
	return setmetatable({
		x_offset       = params.x_offset or 0,
		y_offset       = params.x_offset or 0,
		padding_left   = params.padding_left or 0,
		padding_right  = params.padding_right or 0,
		padding_top    = params.padding_top or 0,
		padding_bottom = params.padding_bottom or 0,
		overscan       = params.overscan or 0,
		new            = new
	}, {
		__index = anchor,
		__call  = function(_, ...)
			return new(...)
		end
	})
end

function anchor:update()
	self._width  = w or love.graphics.getWidth()
	self._height = h or love.graphics.getHeight()

	self.padding_left   = math.floor(self._width * (self.overscan / 2))
	self.padding_right  = self.padding_left

	self.padding_top    = math.floor(self._height * (self.overscan / 2))
	self.padding_bottom = self.padding_top
end

function anchor:set_overscan(amount)
	self.overscan = amount
end

function anchor:top()
	return self.y_offset + self.padding_top
end

function anchor:bottom()
	return self._height + self.y_offset - self.padding_bottom
end

function anchor:left()
	return self.x_offset + self.padding_left
end

function anchor:right()
	return self._width + self.x_offset - self.padding_right
end

function anchor:width()
	return self:right() - self:left()
end

function anchor:height()
	return self:bottom() - self:top()
end

function anchor:bounds()
	local x, y = self:left(), self:top()
	return x, y, self:right() - self:left(), self:bottom() - self:top()
end

function anchor:center_x()
	return (self:left() + self:right()) / 2
end

function anchor:center_y()
	return (self:top() + self:bottom()) / 2
end

function anchor:center()
	return self:center_x(), self:center_y()
end

return new()
