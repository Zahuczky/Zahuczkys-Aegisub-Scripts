--[[The MIT License (MIT)

Copyright (c) 2022 Ruan Dias

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE]]--
local MATH
MATH = require("ZF.util.math").MATH
local POINT
do
  local _class_0
  local _base_0 = {
    version = "1.0.0",
    __add = function(self, p)
      if p == nil then
        p = 0
      end
      return type(p) == "number" and POINT(self.x + p, self.y + p) or POINT(self.x + p.x, self.y + p.y)
    end,
    __sub = function(self, p)
      if p == nil then
        p = 0
      end
      return type(p) == "number" and POINT(self.x - p, self.y - p) or POINT(self.x - p.x, self.y - p.y)
    end,
    __mul = function(self, p)
      if p == nil then
        p = 1
      end
      return type(p) == "number" and POINT(self.x * p, self.y * p) or POINT(self.x * p.x, self.y * p.y)
    end,
    __div = function(self, p)
      if p == nil then
        p = 1
      end
      return type(p) == "number" and POINT(self.x / p, self.y / p) or POINT(self.x / p.x, self.y / p.y)
    end,
    __mod = function(self, p)
      if p == nil then
        p = 1
      end
      return type(p) == "number" and POINT(self.x % p, self.y % p) or POINT(self.x % p.x, self.y % p.y)
    end,
    __pow = function(self, p)
      if p == nil then
        p = 1
      end
      return type(p) == "number" and POINT(self.x ^ p, self.y ^ p) or POINT(self.x ^ p.x, self.y ^ p.y)
    end,
    __eq = function(self, p)
      return self.x == p.x and self.y == p.y
    end,
    __df = function(self, p)
      return self.x ~= p.x and self.y ~= p.y
    end,
    __lt = function(self, p)
      return self.x < p.x and self.y < p.y
    end,
    __le = function(self, p)
      return self.x <= p.x and self.y <= p.y
    end,
    __gt = function(self, p)
      return self.x > p.x and self.y > p.y
    end,
    __ge = function(self, p)
      return self.x >= p.x and self.y >= p.y
    end,
    __tostring = function(self)
      return tostring(self.x) .. " " .. tostring(self.y) .. " "
    end,
    get = function(self)
      return self
    end,
    set = function(self, p)
      self.x, self.y = p.x, p.y
    end,
    dot = function(self, p)
      return self.x * p.x + self.y * p.y
    end,
    min = function(self, p)
      return POINT(min(self.x, p.x), min(self.y, p.y))
    end,
    max = function(self, p)
      return POINT(max(self.x, p.x), max(self.y, p.y))
    end,
    minx = function(self, p)
      return POINT(min(self.x, p.x), self.y)
    end,
    miny = function(self, p)
      return POINT(self.x, min(self.y, p.y))
    end,
    maxx = function(self, p)
      return POINT(max(self.x, p.x), self.y)
    end,
    maxy = function(self, p)
      return POINT(self.x, max(self.y, p.y))
    end,
    copy = function(self)
      return POINT(self.x, self.y)
    end,
    angle = function(self, p)
      return deg(atan2(p.y - self.y, p.x - self.x))
    end,
    cross = function(self, p, o)
      return (self.x - o.x) * (p.y - o.y) - (self.y - o.y) * (p.x - o.x)
    end,
    distance = function(self, p)
      return sqrt((p.x - self.x) ^ 2 + (p.y - self.y) ^ 2)
    end,
    inside = function(self, p1, p2)
      return (p2.x - p1.x) * (self.y - p1.y) > (p2.y - p1.y) * (self.x - p1.x)
    end,
    lerp = function(self, p, t)
      if t == nil then
        t = 0.5
      end
      return POINT((1 - t) * self.x + t * p.x, (1 - t) * self.y + t * p.y)
    end,
    abs = function(self)
      self.x, self.y = abs(self.x), abs(self.y)
    end,
    round = function(self, dec)
      if dec == nil then
        dec = 3
      end
      self.x = MATH:round(self.x, dec)
      self.y = MATH:round(self.y, dec)
      return self
    end,
    rotate = function(self, c, angle)
      if c == nil then
        c = POINT()
      end
      self.x = cos(angle) * (self.x - c.x) - sin(angle) * (self.y - c.y) + c.x
      self.y = sin(angle) * (self.x - c.x) + cos(angle) * (self.y - c.y) + c.y
      return self
    end,
    hypot = function(self)
      if self.x == 0 and self.y == 0 then
        return 0
      end
      self:abs()
      local x, y = max(self.x, self.y), min(self.x, self.y)
      return x * sqrt(1 + (y / x) ^ 2)
    end,
    vecDistance = function(self)
      return self.x ^ 2 + self.y ^ 2
    end,
    vecDistanceSqrt = function(self)
      return sqrt(self:vecDistance())
    end,
    vecNegative = function(self)
      return POINT(-self.x, -self.y)
    end,
    vecNormalize = function(self)
      local result = POINT()
      local length = self:vecDistanceSqrt()
      if length ~= 0 then
        result.x = self.x / length
        result.y = self.y / length
      end
      return result
    end,
    vecScale = function(self, len)
      local result = POINT()
      local length = self:vecDistanceSqrt()
      if length ~= 0 then
        result.x = self.x * len / length
        result.y = self.y * len / length
      end
      return result
    end,
    sqDistance = function(self, p)
      return self:distance(p) ^ 2
    end,
    sqSegDistance = function(self, p1, p2)
      local p = POINT(p1)
      local d = p2 - p
      if d.x ~= 0 or d.y ~= 0 then
        local t = ((self.x - p.x) * d.x + (self.y - p.y) * d.y) / d:vecDistance()
        if t > 1 then
          p = POINT(p2)
        elseif t > 0 then
          p = p + (d * t)
        end
      end
      return self:sqDistance(p)
    end
  }
  _base_0.__index = _base_0
  _class_0 = setmetatable({
    __init = function(self, x, y)
      if x == nil then
        x = 0
      end
      if y == nil then
        y = 0
      end
      self.x = type(x) == "table" and (rawget(x, "x") and x.x or x[1]) or x
      self.y = type(x) == "table" and (rawget(x, "y") and x.y or x[2]) or y
    end,
    __base = _base_0,
    __name = "POINT"
  }, {
    __index = _base_0,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  POINT = _class_0
end
return {
  POINT = POINT
}
