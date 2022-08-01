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
do
  local _with_0 = math
  pi, log, sin, cos, tan, max, min = _with_0.pi, _with_0.log, _with_0.sin, _with_0.cos, _with_0.tan, _with_0.max, _with_0.min
  abs, deg, rad, log10, asin, sqrt = _with_0.abs, _with_0.deg, _with_0.rad, _with_0.log10, _with_0.asin, _with_0.sqrt
  acos, atan, sinh, cosh, tanh, random = _with_0.acos, _with_0.atan, _with_0.asin, _with_0.cosh, _with_0.tanh, _with_0.random
  ceil, floor, atan2, format, unpack = _with_0.ceil, _with_0.floor, _with_0.atan2, string.format, table.unpack or unpack
end
local MATH
do
  local _class_0
  local _base_0 = {
    version = "1.1.1",
    round = function(self, a, dec, snot)
      if dec == nil then
        dec = 3
      end
      if snot == nil then
        snot = 10 ^ floor(dec)
      end
      return dec >= 1 and floor(a * snot + 0.5) / snot or floor(a + 0.5)
    end,
    clamp = function(self, a, b, c)
      return min(max(a, b), c)
    end,
    random = function(self, a, b)
      return random() * (b - a) + a
    end,
    lerp = function(self, t, a, b, u)
      if u == nil then
        u = self:clamp(t, 0, 1)
      end
      return self:round((1 - u) * a + u * b)
    end,
    cubicRoots = function(self, a, b, c, d, ep)
      if ep == nil then
        ep = 1e-8
      end
      local cubeRoot
      cubeRoot = function(x)
        local y = abs(x) ^ (1 / 3)
        return x < 0 and -y or y
      end
      local p = (3 * a * c - b * b) / (3 * a * a)
      local q = (2 * b * b * b - 9 * a * b * c + 27 * a * a * d) / (27 * a * a * a)
      local roots = { }
      if abs(p) < ep then
        roots[1] = cubeRoot(-q)
      elseif abs(q) < ep then
        roots[1] = 0
        roots[2] = p < 0 and sqrt(-p) or nil
        roots[3] = p < 0 and -sqrt(-p) or nil
      else
        local D = q * q / 4 + p * p * p / 27
        if abs(D) < ep then
          roots[1] = -1.5 * q / p
          roots[2] = 3 * q / p
        elseif D > 0 then
          local u = cubeRoot(-q / 2 - sqrt(D))
          roots[1] = u - p / (3 * u)
        else
          local u = 2 * sqrt(-p / 3)
          local t = acos(3 * q / p / u) / 3
          local k = 2 * pi / 3
          roots[1] = u * cos(t)
          roots[2] = u * cos(t - k)
          roots[3] = u * cos(t - 2 * k)
        end
      end
      for i = 1, #roots do
        roots[i] = roots[i] - (b / (3 * a))
      end
      return roots
    end
  }
  _base_0.__index = _base_0
  _class_0 = setmetatable({
    __init = function() end,
    __base = _base_0,
    __name = "MATH"
  }, {
    __index = _base_0,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  MATH = _class_0
end
return {
  MATH = MATH
}
