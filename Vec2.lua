Vec2 = {}
Vec2.__index = Vec2
Vec2.__tostring = function(v)
	return "("..v.x..","..v.y..")"
end

Vec2.new = function(x,y)
	local self = {}
	if (x==nil) and (y==nil) then
		self.x = 0
		self.y = 0
	else
		self.x = x
		self.y = y
	end
	setmetatable(self, Vec2)
	return self
end

Vec2.angle = function(self)
	return math.atan2(self.y, self.x)
end

Vec2.mag = function(self)
	return math.sqrt(self.x*self.x, self.y*self.y)
end

Vec2.rotate = function(self, angle)
	local mag = self:mag()
	local oldangle = self:angle()
	return Vec2.new(mag*math.cos(angle+oldangle), mag*math.sin(angle+oldangle))
end

Vec2.__add = function(a, b)
	return Vec2.new(a.x+b.x, a.y+b.y)
end

Vec2.__sub = function(a, b)
	b = -b
	return Vec2.new(a.x+b.x, a.y+b.y)
end

Vec2.__unm = function(a)
	return a*-1
end

Vec2.__mul = function(a, b)
	if (type(a) == "number") then
		return Vec2.new(a*b.x, a*b.y)
	elseif (type(b) == "number") then
		return Vec2.new(b*a.x, b*a.y)
	else
		return a.x*b.x + a.y*b.y
	end
end

Vec2.__div = function(a, b)
	return Vec2.new(a.x/b, a.y/b)
end

Vec2.__eq = function(a, b)
	return (a.x==b.x) and (a.y==b.y)
end

Vec2.__lt = function(a, b)
	if (type(a)~="number") then
		a = a:mag()
	end
	if (type(b)~="number") then
		b = b:mag()
	end
	return a<b
end