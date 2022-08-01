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
local POINT, SEGMENT, MATH, TABLE, UTIL, PATH, SIMPLIFY
POINT = require("ZF.2D.point").POINT
SEGMENT = require("ZF.2D.segment").SEGMENT
MATH = require("ZF.util.math").MATH
TABLE = require("ZF.util.table").TABLE
UTIL = require("ZF.util.util").UTIL
do
  local _class_0
  local _base_0 = {
    version = "1.1.0",
    toPoints = function(self, points)
      if points == nil then
        points = { }
      end
      local path
      path = self.path
      points = {
        path[1]:unpack()
      }
      for j = 2, #path - 1 do
        TABLE(points):push(path[j]["segment"][2])
      end
      return points
    end,
    push = function(self, ...)
      local args = {
        ...
      }
      if #args == 1 and rawget(args[1], "path") then
        for segment in args[i].path do
          TABLE(self.path):push(SEGMENT())
          for _index_0 = 1, #segment do
            local point = segment[_index_0]
            self.path[#self.path]:push(point)
          end
        end
      elseif #args == 1 and rawget(args[1], "segment") then
        TABLE(self.path):push(SEGMENT())
        local _list_0 = args[1].segment
        for _index_0 = 1, #_list_0 do
          local point = _list_0[_index_0]
          self.path[#self.path]:push(point)
        end
      end
      return self
    end,
    isClosed = function(self)
      return self.path[1]["segment"][1] == self.path[#self.path]["segment"][#self.path[#self.path]["segment"]]
    end,
    isOpen = function(self)
      return not self:isClosed()
    end,
    close = function(self)
      local fx, fy
      do
        local _obj_0 = self.path[1]["segment"][1]
        fx, fy = _obj_0.x, _obj_0.y
      end
      local lx, ly
      do
        local _obj_0 = self.path[#self.path]["segment"][#self.path[#self.path]["segment"]]
        lx, ly = _obj_0.x, _obj_0.y
      end
      if not (self:isClosed()) then
        TABLE(self.path):push(SEGMENT(POINT(lx, ly), POINT(fx, fy)))
      end
      return self
    end,
    open = function(self)
      if not (self:isOpen()) then
        TABLE(self.path):pop()
      end
      return self
    end,
    boudingBox = function(self, typer)
      local l, t, r, b = math.huge, math.huge, -math.huge, -math.huge
      local _list_0 = self.path
      for _index_0 = 1, #_list_0 do
        local segment = _list_0[_index_0]
        local minx, miny, maxx, maxy = segment:boudingBox(typer)
        l, t = min(l, minx), min(t, miny)
        r, b = max(r, maxx), max(b, maxy)
      end
      return l, t, r, b
    end,
    allCubic = function(self)
      for i = 1, #self.path do
        self.path[i] = self.path[i]:allCubic()
      end
      return self
    end,
    getLength = function(self)
      local length = {
        sum = { },
        max = 0
      }
      for b, bezier in ipairs(self.path) do
        length[b] = bezier:length()
        length.max = length.max + length[b]
        length.sum[b] = length.max
      end
      return length
    end,
    length = function(self)
      return self:getLength()["max"]
    end,
    filter = function(self, fn)
      if fn == nil then
        fn = function(x, y, p)
          return x, y
        end
      end
      for p, path in ipairs(self.path) do
        for b, pt in ipairs(path.segment) do
          do
            local x, y
            x, y = pt.x, pt.y
            local px, py = fn(x, y, pt)
            if type(px) == "table" and UTIL:getClassName(px) == "POINT" then
              pt.x, pt.y = px.x, px.y
            else
              pt.x, pt.y = px or x, py or y
            end
          end
        end
      end
      return self
    end,
    flatten = function(self, srt, len, red, seg, fix)
      if seg == nil then
        seg = "m"
      end
      local new = PATH()
      local _list_0 = self.path
      for _index_0 = 1, #_list_0 do
        local segment = _list_0[_index_0]
        local tp = segment.segment.t
        if tp == (seg == "m" and tp or seg) then
          local flatten = segment:casteljau(srt, len, red, fix)
          for i = 2, #flatten do
            local prev = flatten[i - 1]
            local curr = flatten[i - 0]
            new:push(SEGMENT(prev, curr))
          end
        else
          new:push(SEGMENT(segment:unpack()))
        end
      end
      return new
    end,
    roundCorners = function(self, radius, limit)
      local isCorner
      isCorner = function(ct, nt, lt)
        if ct == "b" then
          return false
        elseif ct == "l" and nt == "b" then
          return false
        elseif lt == "b" then
          return false
        end
        return true
      end
      local new, r = PATH(), limit < radius and limit or radius
      for i = 1, #self.path do
        local currPath = self.path[i]
        local nextPath = self.path[i == #self.path and 1 or i + 1]
        if isCorner(currPath.segment.t, nextPath.segment.t, self.path[#self.path].segment.t) then
          local prevPoint = currPath.segment[1]
          local currPoint = currPath.segment[2]
          local nextPoint = nextPath.segment[2]
          local F = SEGMENT(currPoint, prevPoint)
          local L = SEGMENT(currPoint, nextPoint)
          local angleF = F:linearAngle()
          local angleL = L:linearAngle()
          local px, py
          px, py = currPoint.x, currPoint.y
          local p1 = POINT(px + r * cos(angleF), py + r * sin(angleF))
          local p4 = POINT(px + r * cos(angleL), py + r * sin(angleL))
          local c1 = POINT((p1.x + 2 * px) / 3, (p1.y + 2 * py) / 3)
          local c2 = POINT((p4.x + 2 * px) / 3, (p4.y + 2 * py) / 3)
          if i > 1 then
            new:push(SEGMENT(currPoint, p1))
          end
          new:push(SEGMENT(p1, c1, c2, p4))
        else
          new:push(currPath)
        end
      end
      return new
    end,
    split = function(self, t)
      if t == nil then
        t = 0.5
      end
      local a = self:splitInInterval(0, t)
      local b = self:splitInInterval(t, 1)
      return {
        a,
        b
      }
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
      local lens = self:getLength()
      local slen = s * lens.max
      local elen = e * lens.max
      local new, inf, sum = PATH(), { }, 0
      for i = 1, #lens.sum do
        if lens.sum[i] >= elen then
          local k = 1
          for i = 1, #lens do
            if lens.sum[i] >= slen then
              k = i
              break
            end
          end
          local val = self.path[k]
          local u = (lens.sum[k] - slen) / val:length()
          u = 1 - u
          if i ~= k then
            new:push(val:split(u)[2])
          end
          if i > 1 then
            for j = k + 1, i - 1 do
              new:push(self.path[j])
            end
          end
          val = self.path[i]
          local t = (lens.sum[i] - elen) / val:length()
          t = 1 - t
          if i ~= k then
            new:push(val:split(t)[1])
          else
            new:push(val:splitInInterval(u, t))
          end
          inf = {
            i = i,
            k = k,
            u = u,
            t = t
          }
          break
        end
      end
      return new, inf
    end,
    getNormal = function(self, t, inverse)
      local new, inf = self:splitInInterval(0, t)
      return self.path[inf.i]:getNormal(inf.t, inverse)
    end,
    simplify = function(self, simplifyType, precision, limit)
      if simplifyType == nil then
        simplifyType = "linear"
      end
      if limit == nil then
        limit = 3
      end
      local newPath = PATH()
      if simplifyType == "line" or simplifyType == "linear" then
        local points = { }
        local a, b
        do
          local _obj_0 = self.path[1].segment
          a, b = _obj_0[1], _obj_0[2]
        end
        TABLE(points):push(a, b)
        for i = 2, #self.path do
          TABLE(points):push(self.path[i].segment[2])
        end
        points = SIMPLIFY(points, precision):spLines()
        for i = 2, #points do
          local pointPrev = points[i - 1]
          local pointCurr = points[i - 0]
          newPath:push(SEGMENT(pointPrev, pointCurr))
        end
      else
        local i, lens, groups = 1, self:getLength(), { }
        while i <= #lens do
          if lens[i] <= limit then
            local temp = { }
            TABLE(groups):push({
              simplify = true
            })
            while true do
              TABLE(temp):push(self.path[i])
              i = i + 1
              if not lens[i] or lens[i] > limit then
                break
              end
            end
            local a, b
            do
              local _obj_0 = temp[1].segment
              a, b = _obj_0[1], _obj_0[2]
            end
            TABLE(groups[#groups]):push(a, b)
            for j = 2, #temp do
              TABLE(groups[#groups]):push(temp[j].segment[2])
            end
            if self.path[i] then
              TABLE(groups):push({
                self.path[i]
              })
            end
          else
            if #groups == 0 then
              TABLE(groups):push({ })
            end
            if self.path[i] then
              TABLE(groups[#groups]):push(self.path[i])
            end
          end
          i = i + 1
        end
        for _index_0 = 1, #groups do
          local spt = groups[_index_0]
          spt = spt.simplify and SIMPLIFY(spt, precision):spLines2Bezier() or spt
          for _index_1 = 1, #spt do
            local smp = spt[_index_1]
            newPath:push(smp)
          end
        end
      end
      return newPath
    end,
    __tostring = function(self, dec)
      if dec == nil then
        dec = 3
      end
      local conc, last = "", ""
      for p, path in ipairs(self.path) do
        local tp = path.segment.t
        path:round(dec)
        if p == 1 then
          conc = conc .. ("m " .. path:__tostring(1))
        end
        conc = conc .. ((tp == last and "" or tp .. " ") .. path:__tostring())
        last = tp
      end
      return conc
    end
  }
  _base_0.__index = _base_0
  _class_0 = setmetatable({
    __init = function(self, ...)
      self.path = { }
      return self:push(...)
    end,
    __base = _base_0,
    __name = "PATH"
  }, {
    __index = _base_0,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  PATH = _class_0
end
do
  local _class_0
  local _base_0 = {
    push = function(self, curve)
      return TABLE(self.bld):push(SEGMENT(curve[1], curve[2], curve[3], curve[4]))
    end,
    computeLeftTangent = function(self, d, _end)
      local tHat1 = d[_end + 1] - d[_end]
      return tHat1:vecNormalize()
    end,
    computeRightTangent = function(self, d, _end)
      local tHat2 = d[_end - 1] - d[_end]
      return tHat2:vecNormalize()
    end,
    computeCenterTangent = function(self, d, center)
      local V1 = d[center - 1] - d[center]
      local V2 = d[center] - d[center + 1]
      local tHatCenter = POINT()
      tHatCenter.x = (V1.x + V2.x) / 2
      tHatCenter.y = (V1.y + V2.y) / 2
      return tHatCenter:vecNormalize()
    end,
    chordLengthParameterize = function(self, d, first, last)
      local u = {
        0
      }
      for i = first + 1, last do
        u[i - first + 1] = u[i - first] + d[i]:distance(d[i - 1])
      end
      for i = first + 1, last do
        u[i - first + 1] = u[i - first + 1] / u[last - first + 1]
      end
      return u
    end,
    bezierII = function(self, degree, V, t)
      local Vtemp = { }
      for i = 0, degree do
        Vtemp[i] = POINT(V[i + 1].x, V[i + 1].y)
      end
      for i = 1, degree do
        for j = 0, degree - i do
          Vtemp[j].x = (1 - t) * Vtemp[j].x + t * Vtemp[j + 1].x
          Vtemp[j].y = (1 - t) * Vtemp[j].y + t * Vtemp[j + 1].y
        end
      end
      return POINT(Vtemp[0].x, Vtemp[0].y)
    end,
    computeMaxError = function(self, d, first, last, bezCurve, u, splitPoint)
      splitPoint = (last - first + 1) / 2
      local maxError = 0
      for i = first + 1, last - 1 do
        local P = self:bezierII(3, bezCurve, u[i - first + 1])
        local v = P - d[i]
        local dist = v:vecDistance()
        if dist >= maxError then
          maxError = dist
          splitPoint = i
        end
      end
      return {
        maxError = maxError,
        splitPoint = splitPoint
      }
    end,
    newtonRaphsonRootFind = function(self, _Q, _P, u)
      local Q1, Q2 = { }, { }
      local Q = {
        POINT(_Q[1].x, _Q[1].y),
        POINT(_Q[2].x, _Q[2].y),
        POINT(_Q[3].x, _Q[3].y),
        POINT(_Q[4].x, _Q[4].y)
      }
      local P = POINT(_P.x, _P.y)
      local Q_u = self:bezierII(3, Q, u)
      for i = 1, 3 do
        Q1[i] = POINT()
        Q1[i].x = (Q[i + 1].x - Q[i].x) * 3
        Q1[i].y = (Q[i + 1].y - Q[i].y) * 3
      end
      for i = 1, 2 do
        Q2[i] = POINT()
        Q2[i].x = (Q1[i + 1].x - Q1[i].x) * 2
        Q2[i].y = (Q1[i + 1].y - Q1[i].y) * 2
      end
      local Q1_u = self:bezierII(2, Q1, u)
      local Q2_u = self:bezierII(1, Q2, u)
      local numerator = (Q_u.x - P.x) * (Q1_u.x) + (Q_u.y - P.y) * (Q1_u.y)
      local denominator = (Q1_u.x) * (Q1_u.x) + (Q1_u.y) * (Q1_u.y) + (Q_u.x - P.x) * (Q2_u.x) + (Q_u.y - P.y) * (Q2_u.y)
      if denominator == 0 then
        return u
      end
      return u - (numerator / denominator)
    end,
    reparameterize = function(self, d, first, last, u, bezCurve)
      local _bezCurve = {
        POINT(bezCurve[1].x, bezCurve[1].y),
        POINT(bezCurve[2].x, bezCurve[2].y),
        POINT(bezCurve[3].x, bezCurve[3].y),
        POINT(bezCurve[4].x, bezCurve[4].y)
      }
      local uPrime = { }
      for i = first, last do
        uPrime[i - first + 1] = self:newtonRaphsonRootFind(_bezCurve, d[i], u[i - first + 1])
      end
      return uPrime
    end,
    BM = function(self, u, tp)
      local _exp_0 = tp
      if 1 == _exp_0 then
        return 3 * u * ((1 - u) ^ 2)
      elseif 2 == _exp_0 then
        return 3 * (u ^ 2) * (1 - u)
      elseif 3 == _exp_0 then
        return u ^ 3
      else
        return (1 - u) ^ 3
      end
    end,
    generateBezier = function(self, d, first, last, uPrime, tHat1, tHat2)
      local C, A, bezCurve = {
        {
          0,
          0
        },
        {
          0,
          0
        },
        {
          0,
          0
        }
      }, { }, { }
      local nPts = last - first + 1
      for i = 1, nPts do
        local v1 = POINT(tHat1.x, tHat1.y)
        local v2 = POINT(tHat2.x, tHat2.y)
        v1 = v1:vecScale(self:BM(uPrime[i], 1))
        v2 = v2:vecScale(self:BM(uPrime[i], 2))
        A[i] = {
          v1,
          v2
        }
      end
      for i = 1, nPts do
        C[1][1] = C[1][1] + A[i][1]:dot(A[i][1])
        C[1][2] = C[1][2] + A[i][1]:dot(A[i][2])
        C[2][1] = C[1][2]
        C[2][2] = C[2][2] + A[i][2]:dot(A[i][2])
        local b0 = d[first] * self:BM(uPrime[i])
        local b1 = d[first] * self:BM(uPrime[i], 1)
        local b2 = d[last] * self:BM(uPrime[i], 2)
        local b3 = d[last] * self:BM(uPrime[i], 3)
        local tm0 = b2 + b3
        local tm1 = b1 + tm0
        local tm2 = b0 + tm1
        local tmp = d[first + i - 1] - tm2
        C[3][1] = C[3][1] + A[i][1]:dot(tmp)
        C[3][2] = C[3][2] + A[i][2]:dot(tmp)
      end
      local det_C0_C1 = C[1][1] * C[2][2] - C[2][1] * C[1][2]
      local det_C0_X = C[1][1] * C[3][2] - C[2][1] * C[3][1]
      local det_X_C1 = C[3][1] * C[2][2] - C[3][2] * C[1][2]
      local alpha_l = det_C0_C1 == 0 and 0 or det_X_C1 / det_C0_C1
      local alpha_r = det_C0_C1 == 0 and 0 or det_C0_X / det_C0_C1
      local segLength = d[last]:distance(d[first])
      local epsilon = 1e-6 * segLength
      if alpha_l < epsilon or alpha_r < epsilon then
        local dist = segLength / 3
        bezCurve[1] = d[first]
        bezCurve[4] = d[last]
        bezCurve[2] = bezCurve[1] + tHat1:vecScale(dist)
        bezCurve[3] = bezCurve[4] + tHat2:vecScale(dist)
        return bezCurve
      end
      bezCurve[1] = d[first]
      bezCurve[4] = d[last]
      bezCurve[2] = bezCurve[1] + tHat1:vecScale(alpha_l)
      bezCurve[3] = bezCurve[4] + tHat2:vecScale(alpha_r)
      return bezCurve
    end,
    fitCubic = function(self, d, first, last, tHat1, tHat2, _error)
      local u, uPrime, maxIterations, tHatCenter = { }, { }, 4, POINT()
      local iterationError = _error ^ 2
      local nPts = last - first + 1
      if nPts == 2 then
        local dist = d[last]:distance(d[first]) / 3
        local bezCurve = { }
        bezCurve[1] = d[first]
        bezCurve[4] = d[last]
        tHat1 = tHat1:vecScale(dist)
        tHat2 = tHat2:vecScale(dist)
        bezCurve[2] = bezCurve[1] + tHat1
        bezCurve[3] = bezCurve[4] + tHat2
        self:push(bezCurve)
        return 
      end
      u = self:chordLengthParameterize(d, first, last)
      local bezCurve = self:generateBezier(d, first, last, u, tHat1, tHat2)
      local resultMaxError = self:computeMaxError(d, first, last, bezCurve, u, nil)
      local maxError = resultMaxError.maxError
      local splitPoint = resultMaxError.splitPoint
      if maxError < _error then
        self:push(bezCurve)
        return 
      end
      if maxError < iterationError then
        for i = 1, maxIterations do
          uPrime = self:reparameterize(d, first, last, u, bezCurve)
          bezCurve = self:generateBezier(d, first, last, uPrime, tHat1, tHat2)
          resultMaxError = self:computeMaxError(d, first, last, bezCurve, uPrime, splitPoint)
          maxError = resultMaxError.maxError
          splitPoint = resultMaxError.splitPoint
          if maxError < _error then
            self:push(bezCurve)
            return 
          end
          u = uPrime
        end
      end
      tHatCenter = self:computeCenterTangent(d, splitPoint)
      self:fitCubic(d, first, splitPoint, tHat1, tHatCenter, _error)
      tHatCenter = tHatCenter:vecNegative()
      self:fitCubic(d, splitPoint, last, tHatCenter, tHat2, _error)
    end,
    fitCurve = function(self, d, nPts, _error)
      if _error == nil then
        _error = 1
      end
      local tHat1 = self:computeLeftTangent(d, 1)
      local tHat2 = self:computeRightTangent(d, nPts)
      self:fitCubic(d, 1, nPts, tHat1, tHat2, _error)
    end,
    simplifyRadialDist = function(self)
      local prevPoint = self.pts[1]
      local newPoints, point = {
        prevPoint
      }, nil
      for i = 2, #self.pts do
        point = self.pts[i]
        if point:sqDistance(prevPoint) > self.tol then
          TABLE(newPoints):push(point)
          prevPoint = point
        end
      end
      if prevPoint ~= point then
        TABLE(newPoints):push(point)
      end
      return newPoints
    end,
    simplifyDPStep = function(self, first, last, simplified)
      local maxSqDist, index = self.tol, nil
      for i = first + 1, last do
        local sqDist = self.pts[i]:sqSegDistance(self.pts[first], self.pts[last])
        if sqDist > maxSqDist then
          index = i
          maxSqDist = sqDist
        end
      end
      if maxSqDist > self.tol then
        if index - first > 1 then
          self:simplifyDPStep(first, index, simplified)
        end
        TABLE(simplified):push(self.pts[index])
        if last - index > 1 then
          return self:simplifyDPStep(index, last, simplified)
        end
      end
    end,
    simplifyDouglasPeucker = function(self)
      local simplified = {
        self.pts[1]
      }
      self:simplifyDPStep(1, #self.pts, simplified)
      TABLE(simplified):push(self.pts[#self.pts])
      return simplified
    end,
    spLines = function(self)
      if #self.pts <= 2 then
        return self.pts
      end
      self.tol = self.tol ^ 2
      self.pts = self.hqy and self.pts or self:simplifyRadialDist()
      self.bld = self:simplifyDouglasPeucker()
      return self.bld
    end,
    spLines2Bezier = function(self)
      self:fitCurve(self.pts, #self.pts, self.tol)
      return self.bld
    end
  }
  _base_0.__index = _base_0
  _class_0 = setmetatable({
    __init = function(self, points, tolerance, highestQuality)
      if tolerance == nil then
        tolerance = 1
      end
      if highestQuality == nil then
        highestQuality = true
      end
      self.pts = points
      self.tol = tolerance / 10
      self.hqy = highestQuality
      self.bld = { }
    end,
    __base = _base_0,
    __name = "SIMPLIFY"
  }, {
    __index = _base_0,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  SIMPLIFY = _class_0
end
return {
  PATH = PATH,
  SIMPLIFY = SIMPLIFY
}
