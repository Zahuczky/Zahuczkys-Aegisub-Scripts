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
local TABLE
TABLE = require("ZF.util.table").TABLE
local POINT
POINT = require("ZF.2D.point").POINT
local SEGMENT
SEGMENT = require("ZF.2D.segment").SEGMENT
local PATH
PATH = require("ZF.2D.path").PATH
local PATHS
do
  local _class_0
  local _base_0 = {
    version = "1.1.2",
    toPoints = function(self, points)
      if points == nil then
        points = { }
      end
      local _list_0 = self.paths
      for _index_0 = 1, #_list_0 do
        local path = _list_0[_index_0]
        TABLE(points):push(path:toPoints())
      end
      return points
    end,
    push = function(self, ...)
      local args = {
        ...
      }
      if #args == 1 and rawget(args[1], "paths") then
        local _list_0 = args[1].paths
        for _index_0 = 1, #_list_0 do
          local path = _list_0[_index_0]
          TABLE(self.paths):push(PATH())
          for _index_1 = 1, #path do
            local segment = path[_index_1]
            self.paths[#self.paths]:push(segment)
          end
        end
      elseif #args == 1 and rawget(args[1], "path") then
        TABLE(self.paths):push(PATH())
        local _list_0 = args[1].path
        for _index_0 = 1, #_list_0 do
          local segment = _list_0[_index_0]
          self.paths[#self.paths]:push(segment)
        end
      end
      return self
    end,
    copy = function(self, copyPaths)
      if copyPaths == nil then
        copyPaths = true
      end
      local new = PATHS()
      do
        new.l, new.t, new.r, new.b, new.w, new.h, new.c, new.m = self.l, self.t, self.r, self.b, self.w, self.h, self.c, self.m
        if copyPaths then
          local _list_0 = self.paths
          for _index_0 = 1, #_list_0 do
            local path = _list_0[_index_0]
            new:push(path)
          end
        end
      end
      return new
    end,
    open = function(self)
      local _list_0 = self.paths
      for _index_0 = 1, #_list_0 do
        local path = _list_0[_index_0]
        path:open()
      end
      return self
    end,
    close = function(self)
      local _list_0 = self.paths
      for _index_0 = 1, #_list_0 do
        local path = _list_0[_index_0]
        path:close()
      end
      return self
    end,
    setBoudingBox = function(self)
      local _list_0 = self.paths
      for _index_0 = 1, #_list_0 do
        local path = _list_0[_index_0]
        local l, t, r, b = path:boudingBox()
        self.l, self.t = min(self.l, l), min(self.t, t)
        self.r, self.b = max(self.r, r), max(self.b, b)
      end
      self.w = self.r - self.l
      self.h = self.b - self.t
      self.c = self.l + self.w / 2
      self.m = self.t + self.h / 2
      return self
    end,
    getBoudingBoxAssDraw = function(self)
      local l, t, r, b
      l, t, r, b = self.l, self.t, self.r, self.b
      return ("m %s %s l %s %s %s %s %s %s "):format(l, t, r, t, r, b, l, b)
    end,
    unpackBoudingBox = function(self)
      return self.l, self.t, self.r, self.b
    end,
    allCubic = function(self)
      local _list_0 = self.paths
      for _index_0 = 1, #_list_0 do
        local path = _list_0[_index_0]
        path:allCubic()
      end
      return self
    end,
    filter = function(self, fn)
      if fn == nil then
        fn = function(x, y, p)
          return x, y
        end
      end
      local _list_0 = self.paths
      for _index_0 = 1, #_list_0 do
        local path = _list_0[_index_0]
        path:filter(fn)
      end
      return self
    end,
    move = function(self, px, py)
      if px == nil then
        px = 0
      end
      if py == nil then
        py = 0
      end
      return self:filter(function(x, y)
        x = x + px
        y = y + py
        return x, y
      end)
    end,
    scale = function(self, sx, sy, inCenter)
      if sx == nil then
        sx = 100
      end
      if sy == nil then
        sy = 100
      end
      sx = sx / 100
      sy = sy / 100
      local cx, cy
      cx, cy = self.c, self.m
      return self:filter(function(x, y)
        if inCenter then
          x = sx * (x - cx) + cx
          y = sy * (y - cy) + cy
        else
          x = x * sx
          y = y * sy
        end
        return x, y
      end)
    end,
    rotate = function(self, angle, cx, cy)
      if cx == nil then
        cx = self.c
      end
      if cy == nil then
        cy = self.m
      end
      local theta = rad(angle)
      local cs = cos(theta)
      local sn = sin(theta)
      return self:filter(function(x, y)
        local dx = x - cx
        local dy = y - cy
        local rx = cs * dx - sn * dy + cx
        local ry = sn * dx + cs * dy + cy
        return rx, ry
      end)
    end,
    toOrigin = function(self)
      return self:move(-self.l, -self.t)
    end,
    toCenter = function(self)
      return self:move(-self.l - self.w / 2, -self.t - self.h / 2)
    end,
    perspective = function(self, mesh, real, ep)
      if ep == nil then
        ep = 1e-2
      end
      mesh = mesh or {
        POINT(self.l, self.t),
        POINT(self.r, self.t),
        POINT(self.r, self.b),
        POINT(self.l, self.b)
      }
      real = real or {
        POINT(self.l, self.t),
        POINT(self.r, self.t),
        POINT(self.r, self.b),
        POINT(self.l, self.b)
      }
      local rx1, ry1
      do
        local _obj_0 = real[1]
        rx1, ry1 = _obj_0.x, _obj_0.y
      end
      local rx3, ry3
      do
        local _obj_0 = real[3]
        rx3, ry3 = _obj_0.x, _obj_0.y
      end
      local mx1, my1
      do
        local _obj_0 = mesh[1]
        mx1, my1 = _obj_0.x, _obj_0.y
      end
      local mx2, my2
      do
        local _obj_0 = mesh[2]
        mx2, my2 = _obj_0.x, _obj_0.y
      end
      local mx3, my3
      do
        local _obj_0 = mesh[3]
        mx3, my3 = _obj_0.x, _obj_0.y
      end
      local mx4, my4
      do
        local _obj_0 = mesh[4]
        mx4, my4 = _obj_0.x, _obj_0.y
      end
      if mx2 == mx3 then
        mx3 = mx3 + ep
      end
      if mx1 == mx4 then
        mx4 = mx4 + ep
      end
      if mx1 == mx2 then
        mx2 = mx2 + ep
      end
      if mx4 == mx3 then
        mx3 = mx3 + ep
      end
      local a1 = (my2 - my3) / (mx2 - mx3)
      local a2 = (my1 - my4) / (mx1 - mx4)
      local a3 = (my1 - my2) / (mx1 - mx2)
      local a4 = (my4 - my3) / (mx4 - mx3)
      if a1 == a2 then
        a2 = a2 + ep
      end
      local b1 = (a1 * mx2 - a2 * mx1 + my1 - my2) / (a1 - a2)
      local b2 = a1 * (b1 - mx2) + my2
      if a3 == a4 then
        a4 = a4 + ep
      end
      local c1 = (a3 * mx2 - a4 * mx3 + my3 - my2) / (a3 - a4)
      local c2 = a3 * (c1 - mx2) + my2
      if b1 == c1 then
        c1 = c1 + ep
      end
      local c3 = (b2 - c2) / (b1 - c1)
      if c3 == a3 then
        a3 = a3 + ep
      end
      local d1 = (c3 * mx4 - a3 * mx1 + my1 - my4) / (c3 - a3)
      local d2 = c3 * (d1 - mx4) + my4
      if c3 == a1 then
        a1 = a1 + ep
      end
      local e1 = (c3 * mx4 - a1 * mx2 + my2 - my4) / (c3 - a1)
      local e2 = c3 * (e1 - mx4) + my4
      return self:filter(function(x, y)
        local f1 = (ry3 - y) / (ry3 - ry1)
        local f2 = (x - rx1) / (rx3 - rx1)
        local g1 = (d1 - mx4) * f1 + mx4
        local g2 = (d2 - my4) * f1 + my4
        local h1 = (e1 - mx4) * f2 + mx4
        local h2 = (e2 - my4) * f2 + my4
        if c1 == g1 then
          g1 = g1 + ep
        end
        if b1 == h1 then
          h1 = h1 + ep
        end
        local i1 = (c2 - g2) / (c1 - g1)
        local i2 = (b2 - h2) / (b1 - h1)
        if i1 == i2 then
          i2 = i2 + ep
        end
        local px = (i1 * c1 - i2 * b1 + b2 - c2) / (i1 - i2)
        local py = i1 * (px - g1) + g2
        return px, py
      end)
    end,
    envelopeDistort = function(self, mesh, real, ep)
      if ep == nil then
        ep = 1e-2
      end
      self:allCubic()
      mesh = mesh or {
        POINT(self.l, self.t),
        POINT(self.r, self.t),
        POINT(self.r, self.b),
        POINT(self.l, self.b)
      }
      real = real or {
        POINT(self.l, self.t),
        POINT(self.r, self.t),
        POINT(self.r, self.b),
        POINT(self.l, self.b)
      }
      assert(#real == #mesh, "The control points must have the same quantity!")
      for i = 1, #real do
        do
          local _with_0 = real[i]
          if _with_0.x == self.l then
            _with_0.x = _with_0.x - ep
          end
          if _with_0.y == self.t then
            _with_0.y = _with_0.y - ep
          end
          if _with_0.x == self.r then
            _with_0.x = _with_0.x + ep
          end
          if _with_0.y == self.b then
            _with_0.y = _with_0.y + ep
          end
        end
        do
          local _with_0 = mesh[i]
          if _with_0.x == self.l then
            _with_0.x = _with_0.x - ep
          end
          if _with_0.y == self.t then
            _with_0.y = _with_0.y - ep
          end
          if _with_0.x == self.r then
            _with_0.x = _with_0.x + ep
          end
          if _with_0.y == self.b then
            _with_0.y = _with_0.y + ep
          end
        end
      end
      local A, W = { }, { }
      return self:filter(function(x, y, pt)
        for i = 1, #real do
          local vi, vj = real[i], real[i % #real + 1]
          local r0i = pt:distance(vi)
          local r0j = pt:distance(vj)
          local rij = vi:distance(vj)
          local r = (r0i ^ 2 + r0j ^ 2 - rij ^ 2) / (2 * r0i * r0j)
          A[i] = r ~= r and 0 or acos(max(-1, min(r, 1)))
        end
        for i = 1, #real do
          local j = (i > 1 and i or #real + 1) - 1
          local r = real[i]:distance(pt)
          W[i] = (tan(A[j] / 2) + tan(A[i] / 2)) / r
        end
        local Ws = TABLE(W):reduce(function(a, b)
          return a + b
        end)
        local nx, ny = 0, 0
        for i = 1, #real do
          local L = W[i] / Ws
          do
            local _with_0 = mesh[i]
            nx = nx + (L * _with_0.x)
            ny = ny + (L * _with_0.y)
          end
        end
        return nx, ny
      end)
    end,
    flatten = function(self, srt, len, red, seg, fix)
      local new = self:copy()
      for i = 1, #self.paths do
        new.paths[i] = self.paths[i]:flatten(srt, len, red, seg, fix)
      end
      return new
    end,
    getLengths = function(self)
      local lengths = {
        sum = { },
        max = 0
      }
      for i = 1, #self.paths do
        lengths[i] = self.paths[i]:getLength()
        lengths.max = lengths.max + lengths[i].max
        lengths.sum[i] = lengths.max
      end
      return lengths
    end,
    length = function(self)
      return self:getLengths()["max"]
    end,
    splitPath = function(self, t)
      local a = self:splitPathInInterval(0, t)
      local b = self:splitPathInInterval(t, 1)
      return {
        a,
        b
      }
    end,
    splitPathInInterval = function(self, s, e)
      local new = self:copy(false)
      for i = 1, #self.paths do
        new.paths[i] = self.paths[i]:splitInInterval(s, e)
      end
      return new
    end,
    splitPaths = function(self, t)
      local a = self:splitPathsInInterval(0, t)
      local b = self:splitPathsInInterval(t, 1)
      return {
        a,
        b
      }
    end,
    splitPathsInInterval = function(self, s, e)
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
      local lens = self:getLengths()
      local slen = s * lens.max
      local elen = e * lens.max
      local spt, inf, new = nil, nil, self:copy(false)
      for i = 1, #lens.sum do
        if lens.sum[i] >= elen then
          local k = 1
          for i = 1, #lens.sum do
            if lens.sum[i] >= slen then
              k = i
              break
            end
          end
          local val = self.paths[k]
          local u = (lens.sum[k] - slen) / val:length()
          u = 1 - u
          if i ~= k then
            spt = val:splitInInterval(u, 1)
            new:push(spt)
          end
          if i > 1 then
            for j = k + 1, i - 1 do
              TABLE(new.paths):push(self.paths[j])
            end
          end
          val = self.paths[i]
          local t = (lens.sum[i] - elen) / val:length()
          t = 1 - t
          if i ~= k then
            spt = val:splitInInterval(0, t)
            new:push(spt)
          else
            spt = val:splitInInterval(u, t)
            new:push(spt)
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
      local new, inf = self:splitPathsInInterval(0, t)
      return self.paths[inf.i]:getNormal(inf.t, inverse)
    end,
    roundCorners = function(self, radius)
      local lengths = self:getLengths()
      for i = 1, #self.paths do
        table.sort(lengths[i], function(a, b)
          return a < b
        end)
        self.paths[i] = self.paths[i]:roundCorners(radius, lengths[i][1] / 2)
      end
      return self
    end,
    __tostring = function(self, dec)
      local concat = ""
      local _list_0 = self.paths
      for _index_0 = 1, #_list_0 do
        local path = _list_0[_index_0]
        concat = concat .. path:__tostring(dec)
      end
      return concat
    end,
    build = function(self, dec)
      return self:__tostring(dec)
    end
  }
  _base_0.__index = _base_0
  _class_0 = setmetatable({
    __init = function(self, ...)
      self.paths, self.l, self.t, self.r, self.b = { }, math.huge, math.huge, -math.huge, -math.huge
      self:push(...)
      return self:setBoudingBox()
    end,
    __base = _base_0,
    __name = "PATHS"
  }, {
    __index = _base_0,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  PATHS = _class_0
end
return {
  PATHS = PATHS
}
