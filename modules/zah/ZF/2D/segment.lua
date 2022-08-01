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
local bor
bor = require("bit").bor
local MATH
MATH = require("ZF.util.math").MATH
local TABLE
TABLE = require("ZF.util.table").TABLE
local POINT
POINT = require("ZF.2D.point").POINT
local argsArePoints
argsArePoints = function(args)
  for _index_0 = 1, #args do
    local point = args[_index_0]
    if not (rawget(point, "x") and rawget(point, "y")) then
      return false
    end
  end
  return true
end
local SEGMENT
do
  local _class_0
  local _base_0 = {
    version = "1.0.1",
    push = function(self, ...)
      local args = {
        ...
      }
      if #args == 1 and rawget(args[1], "segment") then
        local _list_0 = args[1].segment
        for _index_0 = 1, #_list_0 do
          local point = _list_0[_index_0]
          TABLE(self.segment):push(point:copy())
        end
      elseif #args <= 4 and argsArePoints(args) then
        for _index_0 = 1, #args do
          local point = args[_index_0]
          TABLE(self.segment):push(point:copy())
        end
      end
      self.segment.t = #self.segment == 2 and "l" or "b"
      return self
    end,
    unpack = function(self)
      return self.segment[1], self.segment[2], self.segment[3], self.segment[4]
    end,
    assert = function(self, t)
      local len, msg = #self.segment, "The paths do not correspond with a"
      if t == "linear" then
        assert(len == 2, tostring(msg) .. " Linear Bezier")
      elseif t == "cubic" then
        assert(len == 4, tostring(msg) .. " Cubic Bezier")
      end
      return self
    end,
    __add = function(self, p)
      if p == nil then
        p = 0
      end
      local a, b, c, d = self:unpack()
      return SEGMENT(a + p, b + p, c and c + p or nil, d and d + p or nil)
    end,
    __sub = function(self, p)
      if p == nil then
        p = 0
      end
      local a, b, c, d = self:unpack()
      return SEGMENT(a - p, b - p, c and c - p or nil, d and d - p or nil)
    end,
    __mul = function(self, p)
      if p == nil then
        p = 1
      end
      local a, b, c, d = self:unpack()
      return SEGMENT(a * p, b * p, c and c * p or nil, d and d * p or nil)
    end,
    __div = function(self, p)
      if p == nil then
        p = 1
      end
      local a, b, c, d = self:unpack()
      return SEGMENT(a / p, b / p, c and c / p or nil, d and d / p or nil)
    end,
    __mod = function(self, p)
      if p == nil then
        p = 1
      end
      local a, b, c, d = self:unpack()
      return SEGMENT(a % p, b % p, c and c % p or nil, d and d % p or nil)
    end,
    __pow = function(self, p)
      if p == nil then
        p = 1
      end
      local a, b, c, d = self:unpack()
      return SEGMENT(a ^ p, b ^ p, c and c ^ p or nil, d and d ^ p or nil)
    end,
    __tostring = function(self, len)
      if len == nil then
        len = #self.segment
      end
      local a, b, c, d = self:unpack()
      local _exp_0 = len
      if 1 == _exp_0 then
        return tostring(a.x) .. " " .. tostring(a.y) .. " "
      elseif 2 == _exp_0 then
        return tostring(b.x) .. " " .. tostring(b.y) .. " "
      elseif 4 == _exp_0 then
        return tostring(b.x) .. " " .. tostring(b.y) .. " " .. tostring(c.x) .. " " .. tostring(c.y) .. " " .. tostring(d.x) .. " " .. tostring(d.y) .. " "
      end
    end,
    round = function(self, dec)
      if dec == nil then
        dec = 0
      end
      for p, path in ipairs(self.segment) do
        path:round(dec)
      end
      return self
    end,
    inverse = function(self)
      local p = {
        self:unpack()
      }
      for i = 1, #p do
        self.segment[i] = p[#p + 1 - i]
      end
      return self
    end,
    linear = function(self, t)
      self:assert("linear")
      local a, b = self:unpack()
      local x = (1 - t) * a.x + t * b.x
      local y = (1 - t) * a.y + t * b.y
      return POINT(x, y)
    end,
    cubic = function(self, t)
      self:assert("cubic")
      local a, b, c, d = self:unpack()
      local x = (1 - t) ^ 3 * a.x + 3 * t * (1 - t) ^ 2 * b.x + 3 * t ^ 2 * (1 - t) * c.x + t ^ 3 * d.x
      local y = (1 - t) ^ 3 * a.y + 3 * t * (1 - t) ^ 2 * b.y + 3 * t ^ 2 * (1 - t) * c.y + t ^ 3 * d.y
      return POINT(x, y)
    end,
    rotate = function(self, c, angle)
      if not (c) then
        local l, t, r, b = self:boudingBox()
        c = POINT(l + (r - l) / 2, t + (b - t) / 2)
      end
      for i = 1, #self.segment do
        self.segment[i]:rotate(c, angle)
      end
      return self
    end,
    getPoint = function(self, t, fix)
      local _exp_0 = #self.segment
      if 2 == _exp_0 then
        return self:linear(t)
      elseif 4 == _exp_0 then
        return fix and self:fixCasteljauPoint(t) or self:cubic(t)
      else
        return error("expected a linear bezier or a cubic bezier")
      end
    end,
    getMidPoint = function(self)
      return self:getPoint(0.5, true)
    end,
    getNormal = function(self, t, inverse)
      self = self:allCubic()
      t = self:fixCasteljauMap(t)
      local pnt = self:getPoint(t)
      local tan = self:cubicDerivative(t)
      do
        if inverse then
          tan.x, tan.y = -tan.y, tan.x
        else
          tan.x, tan.y = tan.y, -tan.x
        end
        tan = tan / tan:vecDistanceSqrt()
      end
      return tan, pnt, t
    end,
    linearAngle = function(self)
      self:assert("linear")
      local a, b = self:unpack()
      local p = b - a
      return atan2(p.y, p.x)
    end,
    fixCasteljau = function(self, len)
      if len == nil then
        len = 100
      end
      local arcLens, o, sum = {
        0
      }, self:getPoint(0), 0
      for i = 1, len do
        local p = self:getPoint(i * (1 / len))
        local d = o - p
        sum = sum + d:vecDistanceSqrt()
        arcLens[i + 1] = sum
        o = p
      end
      return arcLens, len
    end,
    fixCasteljauMap = function(self, u, len)
      local arcLens
      arcLens, len = self:fixCasteljau(len)
      local tLen = u * arcLens[len]
      local low, i, high = 0, 0, len
      while low < high do
        i = low + bor((high - low) / 2, 0)
        if arcLens[i + 1] < tLen then
          low = i + 1
        else
          high = i
        end
      end
      if arcLens[i + 1] > tLen then
        i = i - 1
      end
      local lenB, last = arcLens[i + 1], len - 1
      return lenB == tLen and i / last or (i + (tLen - lenB) / (arcLens[i + 2] - lenB)) / last
    end,
    fixCasteljauPoint = function(self, u)
      return self:getPoint(self:fixCasteljauMap(u))
    end,
    casteljau = function(self, srt, len, red, fix)
      if srt == nil then
        srt = 0
      end
      if len == nil then
        len = self:length()
      end
      if red == nil then
        red = 1
      end
      if fix == nil then
        fix = true
      end
      local points
      points, len = { }, MATH:round(len / red, 0)
      for i = srt, len do
        TABLE(points):push(self:getPoint(i / len, fix))
      end
      return points
    end,
    linear2cubic = function(self)
      self:assert("linear")
      local a, d = self:unpack()
      local b = POINT((2 * a.x + d.x) / 3, (2 * a.y + d.y) / 3)
      local c = POINT((a.x + 2 * d.x) / 3, (a.y + 2 * d.y) / 3)
      return SEGMENT(a, b, c, d)
    end,
    allCubic = function(self)
      return #self.segment == 2 and self:linear2cubic() or self
    end,
    split = function(self, t)
      if t == nil then
        t = 0.5
      end
      t = MATH:clamp(t, 0, 1)
      local a, b, c, d = self:unpack()
      local _exp_0 = #self.segment
      if 2 == _exp_0 then
        local v1 = a:lerp(b, t)
        return {
          SEGMENT(a, v1),
          SEGMENT(v1, b)
        }
      elseif 4 == _exp_0 then
        local v1 = a:lerp(b, t)
        local v2 = b:lerp(c, t)
        local v3 = c:lerp(d, t)
        local v4 = v1:lerp(v2, t)
        local v5 = v2:lerp(v3, t)
        local v6 = v4:lerp(v5, t)
        return {
          SEGMENT(a, v1, v4, v6),
          SEGMENT(v6, v5, v3, d)
        }
      end
    end,
    splitInInterval = function(self, s, e)
      if s == nil then
        s = 0
      end
      if e == nil then
        e = 1
      end
      s = MATH:clamp(s, 0, 1)
      e = MATH:clamp(e, 0, 1)
      if s > e then
        s, e = e, s
      end
      local u = (e - s) / (1 - s)
      u = u ~= u and e or u
      local a = self:split(s)
      local b = a[2]:split(u)
      return b[1]
    end,
    spline = function(self, points, tension)
      if tension == nil then
        tension = 1
      end
      local splines = { }
      for i = 1, #points - 1 do
        local p1 = i > 1 and points[i - 1] or points[1]
        local p2 = points[i]
        local p3 = points[i + 1]
        local p4 = (i ~= #points - 1) and points[i + 2] or p2
        local cp1x = p2.x + (p3.x - p1.x) / 6 * tension
        local cp1y = p2.y + (p3.y - p1.y) / 6 * tension
        local cp1 = POINT(cp1x, cp1y)
        local cp2x = p3.x - (p4.x - p2.x) / 6 * tension
        local cp2y = p3.y - (p4.y - p2.y) / 6 * tension
        local cp2 = POINT(cp2x, cp2y)
        TABLE(splines):push(SEGMENT(i > 1 and splines[i - 1].segment[4] or points[1], cp1, cp2, p2))
      end
      return splines
    end,
    cubicCoefficient = function(self)
      self:assert("cubic")
      local a, b, c, d = self:unpack()
      return {
        POINT(d.x - a.x + 3 * (b.x - c.x), d.y - a.y + 3 * (b.y - c.y)),
        POINT(3 * a.x - 6 * b.x + 3 * c.x, 3 * a.y - 6 * b.y + 3 * c.y),
        POINT(3 * (b.x - a.x), 3 * (b.y - a.y)),
        POINT(a.x, a.y)
      }
    end,
    cubicDerivative = function(self, t, coef)
      if coef == nil then
        coef = self:cubicCoefficient()
      end
      self:assert("cubic")
      local a, b, c = unpack(coef)
      local x = c.x + t * (2 * b.x + 3 * a.x * t)
      local y = c.y + t * (2 * b.y + 3 * a.y * t)
      return POINT(x, y)
    end,
    length = function(self, t)
      if t == nil then
        t = 1
      end
      local abscissas = {
        -0.0640568928626056299791002857091370970011,
        0.0640568928626056299791002857091370970011,
        -0.1911188674736163106704367464772076345980,
        0.1911188674736163106704367464772076345980,
        -0.3150426796961633968408023065421730279922,
        0.3150426796961633968408023065421730279922,
        -0.4337935076260451272567308933503227308393,
        0.4337935076260451272567308933503227308393,
        -0.5454214713888395626995020393223967403173,
        0.5454214713888395626995020393223967403173,
        -0.6480936519369755455244330732966773211956,
        0.6480936519369755455244330732966773211956,
        -0.7401241915785543579175964623573236167431,
        0.7401241915785543579175964623573236167431,
        -0.8200019859739029470802051946520805358887,
        0.8200019859739029470802051946520805358887,
        -0.8864155270044010714869386902137193828821,
        0.8864155270044010714869386902137193828821,
        -0.9382745520027327978951348086411599069834,
        0.9382745520027327978951348086411599069834,
        -0.9747285559713094738043537290650419890881,
        0.9747285559713094738043537290650419890881,
        -0.9951872199970213106468008845695294439793,
        0.9951872199970213106468008845695294439793
      }
      local weights = {
        0.1279381953467521593204025975865079089999,
        0.1279381953467521593204025975865079089999,
        0.1258374563468283025002847352880053222179,
        0.1258374563468283025002847352880053222179,
        0.1216704729278033914052770114722079597414,
        0.1216704729278033914052770114722079597414,
        0.1155056680537255991980671865348995197564,
        0.1155056680537255991980671865348995197564,
        0.1074442701159656343712356374453520402312,
        0.1074442701159656343712356374453520402312,
        0.0976186521041138843823858906034729443491,
        0.0976186521041138843823858906034729443491,
        0.0861901615319532743431096832864568568766,
        0.0861901615319532743431096832864568568766,
        0.0733464814110802998392557583429152145982,
        0.0733464814110802998392557583429152145982,
        0.0592985849154367833380163688161701429635,
        0.0592985849154367833380163688161701429635,
        0.0442774388174198077483545432642131345347,
        0.0442774388174198077483545432642131345347,
        0.0285313886289336633705904233693217975087,
        0.0285313886289336633705904233693217975087,
        0.0123412297999872001830201639904771582223,
        0.0123412297999872001830201639904771582223
      }
      local len = 0
      local _exp_0 = #self.segment
      if 2 == _exp_0 then
        len = len + self.segment[1]:distance(self.segment[2])
      elseif 4 == _exp_0 then
        local coef, Z = self:cubicCoefficient(), t / 2
        for i = 1, #abscissas do
          local fixT = Z * abscissas[i] + Z
          local derv = self:cubicDerivative(fixT, coef)
          len = len + (weights[i] * derv:hypot())
        end
        len = len * Z
      end
      return len
    end,
    pointIsOnLine = function(self, c, ep)
      if ep == nil then
        ep = 1e-6
      end
      self:assert("linear")
      local a, b = self:unpack()
      local dab = a:distance(b)
      local dac = a:distance(c)
      local dbc = b:distance(c)
      local dff = dab - dac + dbc
      return -ep < dff and dff < ep
    end,
    linearOffset = function(self, size)
      if size == nil then
        size = 0
      end
      self:assert("linear")
      local a, b = self:unpack()
      local d = POINT(-(b.y - a.y), b.x - a.x)
      local k = size / self:length()
      a = a - (d * k)
      b = b - (d * k)
      return SEGMENT(a, b)
    end,
    linearBoudingBox = function(self)
      self:assert("linear")
      local p1, p2 = self:unpack()
      local x1, y1
      x1, y1 = p1.x, p1.y
      local x2, y2
      x2, y2 = p2.x, p2.y
      local l = x2 < x1 and x2 or x1
      local t = y2 < y1 and y2 or y1
      local r = x2 > x1 and x2 or x1
      local b = y2 > y1 and y2 or y1
      return l, t, r, b
    end,
    cubicBoudingBox = function(self, ep)
      if ep == nil then
        ep = 1e-12
      end
      self:assert("cubic")
      local p1, p2, p3, p4 = self:unpack()
      local vt = { }
      local _list_0 = {
        "x",
        "y"
      }
      for _index_0 = 1, #_list_0 do
        local _continue_0 = false
        repeat
          local axi = _list_0[_index_0]
          local a = -3 * p1[axi] + 9 * p2[axi] - 9 * p3[axi] + 3 * p4[axi]
          local b = 6 * p1[axi] - 12 * p2[axi] + 6 * p3[axi]
          local c = 3 * p2[axi] - 3 * p1[axi]
          if abs(a) < ep then
            if abs(b) < ep then
              _continue_0 = true
              break
            end
            local t = -c / b
            if 0 < t and t < 1 then
              TABLE(vt):push(t)
            end
            _continue_0 = true
            break
          end
          local delta = b ^ 2 - 4 * c * a
          if delta < 0 then
            if abs(delta) < ep then
              local t = -b / (2 * a)
              if 0 < t and t < 1 then
                TABLE(vt):push(t)
              end
            end
            _continue_0 = true
            break
          end
          local bhaskara = {
            (-b + sqrt(delta)) / (2 * a),
            (-b - sqrt(delta)) / (2 * a)
          }
          for _, t in ipairs(bhaskara) do
            if 0 < t and t < 1 then
              TABLE(vt):push(t)
            end
          end
          _continue_0 = true
        until true
        if not _continue_0 then
          break
        end
      end
      local l, t, r, b = SEGMENT(p1, p4):linearBoudingBox()
      for _index_0 = 1, #vt do
        local v = vt[_index_0]
        do
          local _with_0 = self:cubic(v)
          l = min(l, _with_0.x)
          t = min(t, _with_0.y)
          r = max(r, _with_0.x)
          b = max(b, _with_0.y)
        end
      end
      return l, t, r, b
    end,
    boudingBox = function(self, typer)
      if typer == "real" then
        local _exp_0 = #self.segment
        if 2 == _exp_0 then
          return self:linearBoudingBox()
        elseif 4 == _exp_0 then
          return self:cubicBoudingBox()
        end
      else
        local l, t, r, b = math.huge, math.huge, -math.huge, -math.huge
        local _list_0 = self.segment
        for _index_0 = 1, #_list_0 do
          local _des_0 = _list_0[_index_0]
          local x, y
          x, y = _des_0.x, _des_0.y
          l, t = min(l, x), min(t, y)
          r, b = max(r, x), max(b, y)
        end
        return l, t, r, b
      end
    end,
    l2lIntersection = function(self, linear)
      self:assert("linear")
      local x1, y1
      do
        local _obj_0 = self.segment[1]
        x1, y1 = _obj_0.x, _obj_0.y
      end
      local x2, y2
      do
        local _obj_0 = self.segment[2]
        x2, y2 = _obj_0.x, _obj_0.y
      end
      local x3, y3
      do
        local _obj_0 = linear.segment[1]
        x3, y3 = _obj_0.x, _obj_0.y
      end
      local x4, y4
      do
        local _obj_0 = linear.segment[2]
        x4, y4 = _obj_0.x, _obj_0.y
      end
      local d = (x1 - x2) * (y3 - y4) - (y1 - y2) * (x3 - x4)
      local t = (x1 - x3) * (y3 - y4) - (y1 - y3) * (x3 - x4)
      local u = (x2 - x1) * (y1 - y3) - (y2 - y1) * (x1 - x3)
      local status = "parallel"
      if d ~= 0 then
        t = t / d
        u = u / d
        if 0 <= t and t <= 1 and 0 <= u and u <= 1 then
          status = "intersected"
          return status, self.segment[1]:lerp(self.segment[2], t)
        else
          status = "not intersected"
        end
      elseif t == 0 or u == 0 then
        status = "coincide"
      end
      return status
    end,
    c2lIntersection = function(self, linear, ep)
      if ep == nil then
        ep = 1e-8
      end
      self:assert("cubic")
      local p1, p2, p3, p4 = self:unpack()
      local result, status = { }, "not intersected"
      local a1, a2
      do
        local _obj_0 = linear.segment
        a1, a2 = _obj_0[1], _obj_0[2]
      end
      local pmin = a1:min(a2)
      local pmax = a1:max(a2)
      local coef = self:cubicCoefficient()
      local N = POINT(a1.y - a2.y, a2.x - a1.x)
      local C = a1.x * a2.y - a2.x * a1.y
      local P = {
        N:dot(coef[1]),
        N:dot(coef[2]),
        N:dot(coef[3]),
        N:dot(coef[4]) + C
      }
      local roots = MATH:cubicRoots(unpack(P))
      for _index_0 = 1, #roots do
        local t = roots[_index_0]
        if ep <= t and t <= 1 then
          local p5 = p1:lerp(p2, t)
          local p6 = p2:lerp(p3, t)
          local p7 = p3:lerp(p4, t)
          local p8 = p5:lerp(p6, t)
          local p9 = p6:lerp(p7, t)
          local p10 = p8:lerp(p9, t)
          if a1.x == a2.x then
            if pmin.y <= p10.y and p10.y <= pmax.y then
              status = "intersected"
              TABLE(result):push(p10)
            end
          elseif a1.y == a2.y then
            if pmin.x <= p10.x and p10.x <= pmax.x then
              status = "intersected"
              TABLE(result):push(p10)
            end
          elseif pmin.x <= p10.x and p10.x <= pmax.x and pmin.y <= p10.y and p10.y <= pmax.y then
            status = "intersected"
            TABLE(result):push(p10)
          end
        end
      end
      return status, result
    end
  }
  _base_0.__index = _base_0
  _class_0 = setmetatable({
    __init = function(self, ...)
      self.segment = { }
      return self:push(...)
    end,
    __base = _base_0,
    __name = "SEGMENT"
  }, {
    __index = _base_0,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  SEGMENT = _class_0
end
return {
  SEGMENT = SEGMENT
}
