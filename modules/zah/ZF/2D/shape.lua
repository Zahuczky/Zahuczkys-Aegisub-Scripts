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
local PATHS
PATHS = require("ZF.2D.paths").PATHS
local PATH
PATH = require("ZF.2D.path").PATH
local SEGMENT
SEGMENT = require("ZF.2D.segment").SEGMENT
local POINT
POINT = require("ZF.2D.point").POINT
local SHAPE
do
  local _class_0
  local _parent_0 = PATHS
  local _base_0 = {
    version = "1.1.3",
    setPosition = function(self, an, mode, px, py)
      if an == nil then
        an = 7
      end
      if mode == nil then
        mode = "tcp"
      end
      if px == nil then
        px = 0
      end
      if py == nil then
        py = 0
      end
      local w, h
      w, h = self.w, self.h
      local _exp_0 = an
      if 1 == _exp_0 then
        local _exp_1 = mode
        if "tcp" == _exp_1 then
          self:move(px, py - h)
        elseif "ucp" == _exp_1 then
          self:move(-px, -py + h)
        end
      elseif 2 == _exp_0 then
        local _exp_1 = mode
        if "tcp" == _exp_1 then
          self:move(px - w / 2, py - h)
        elseif "ucp" == _exp_1 then
          self:move(-px + w / 2, -py + h)
        end
      elseif 3 == _exp_0 then
        local _exp_1 = mode
        if "tcp" == _exp_1 then
          self:move(px - w, py - h)
        elseif "ucp" == _exp_1 then
          self:move(-px + w, -py + h)
        end
      elseif 4 == _exp_0 then
        local _exp_1 = mode
        if "tcp" == _exp_1 then
          self:move(px, py - h / 2)
        elseif "ucp" == _exp_1 then
          self:move(-px, -py + h / 2)
        end
      elseif 5 == _exp_0 then
        local _exp_1 = mode
        if "tcp" == _exp_1 then
          self:move(px - w / 2, py - h / 2)
        elseif "ucp" == _exp_1 then
          self:move(-px + w / 2, -py + h / 2)
        end
      elseif 6 == _exp_0 then
        local _exp_1 = mode
        if "tcp" == _exp_1 then
          self:move(px - w, py - h / 2)
        elseif "ucp" == _exp_1 then
          self:move(-px + w, -py + h / 2)
        end
      elseif 7 == _exp_0 then
        local _exp_1 = mode
        if "tcp" == _exp_1 then
          self:move(px, py)
        elseif "ucp" == _exp_1 then
          self:move(-px, -py)
        end
      elseif 8 == _exp_0 then
        local _exp_1 = mode
        if "tcp" == _exp_1 then
          self:move(px - w / 2, py)
        elseif "ucp" == _exp_1 then
          self:move(-px + w / 2, -py)
        end
      elseif 9 == _exp_0 then
        local _exp_1 = mode
        if "tcp" == _exp_1 then
          self:move(px - w, py)
        elseif "ucp" == _exp_1 then
          self:move(-px + w, -py)
        end
      end
      return self
    end,
    expand = function(self, line, data)
      local pf
      pf = function(sx, sy, p)
        if sx == nil then
          sx = 100
        end
        if sy == nil then
          sy = 100
        end
        if p == nil then
          p = 1
        end
        assert(p > 0 and p == floor(p))
        if p == 1 then
          return sx / 100, sy / 100
        else
          p = p - 1
          sx = sx / 2
          sy = sy / 2
          return pf(sx, sy, p)
        end
      end
      do
        local p = data.p == "text" and 1 or data.p
        local frx = pi / 180 * data.frx
        local fry = pi / 180 * data.fry
        local frz = pi / 180 * line.styleref.angle
        local sx, cx = -sin(frx), cos(frx)
        local sy, cy = sin(fry), cos(fry)
        local sz, cz = -sin(frz), cos(frz)
        local xscale, yscale = pf(line.styleref.scale_x, line.styleref.scale_y, p)
        local fax = data.fax * xscale / yscale
        local fay = data.fay * yscale / xscale
        local wx = line.styleref.shadow
        local wy = line.styleref.shadow
        if data.xshad ~= 0 and data.yshad == 0 then
          wx = data.xshad
        elseif data.xshad == 0 and data.yshad ~= 0 then
          wy = data.yshad
        elseif data.xshad ~= 0 and data.yshad ~= 0 then
          wx = data.xshad
          wy = data.yshad
        end
        local ascent = 0
        local _exp_0 = line.styleref.align
        if 1 == _exp_0 or 2 == _exp_0 or 3 == _exp_0 then
          ascent = data.p == "text" and line.height or self.h
        elseif 4 == _exp_0 or 5 == _exp_0 or 6 == _exp_0 then
          ascent = (data.p == "text" and line.height or self.h) / 2
        end
        local x1 = {
          1,
          fax,
          data.pos[1] - data.org[1] + wx + fax * ascent
        }
        local y1 = {
          fay,
          1,
          data.pos[2] - data.org[2] + wy
        }
        local x2, y2 = { }, { }
        for i = 1, 3 do
          x2[i] = x1[i] * cz - y1[i] * sz
          y2[i] = x1[i] * sz + y1[i] * cz
        end
        local y3, z3 = { }, { }
        for i = 1, 3 do
          y3[i] = y2[i] * cx
          z3[i] = y2[i] * sx
        end
        local x4, z4 = { }, { }
        for i = 1, 3 do
          x4[i] = x2[i] * cy - z3[i] * sy
          z4[i] = x2[i] * sy + z3[i] * cy
        end
        local dist = 312.5
        z4[3] = z4[3] + dist
        local offs_x = data.org[1] - data.pos[1] - wx
        local offs_y = data.org[2] - data.pos[2] - wy
        local matrix
        do
          local _accum_0 = { }
          local _len_0 = 1
          for i = 1, 3 do
            _accum_0[_len_0] = { }
            _len_0 = _len_0 + 1
          end
          matrix = _accum_0
        end
        for i = 1, 3 do
          matrix[1][i] = z4[i] * offs_x + x4[i] * dist
          matrix[2][i] = z4[i] * offs_y + y3[i] * dist
          matrix[3][i] = z4[i]
        end
        self:filter(function(x, y)
          local v
          do
            local _accum_0 = { }
            local _len_0 = 1
            for m = 1, 3 do
              _accum_0[_len_0] = (matrix[m][1] * x * xscale) + (matrix[m][2] * y * yscale) + matrix[m][3]
              _len_0 = _len_0 + 1
            end
            v = _accum_0
          end
          local w = 1 / max(v[3], 0.1)
          return v[1] * w, v[2] * w
        end)
      end
      return self
    end,
    inClip = function(self, an, clip, mode, leng, offset)
      if an == nil then
        an = 7
      end
      if mode == nil then
        mode = "left"
      end
      if offset == nil then
        offset = 0
      end
      mode = mode:lower()
      self:toOrigin()
      if type(clip) ~= "table" then
        clip = SHAPE(clip, false)
      end
      leng = leng or clip:length()
      local size = leng - self.w
      self = self:flatten(nil, nil, 2)
      self:filter(function(x, y)
        local _exp_0 = an
        if 7 == _exp_0 or 8 == _exp_0 or 9 == _exp_0 then
          y = y - self.h
        elseif 4 == _exp_0 or 5 == _exp_0 or 6 == _exp_0 then
          y = y - self.h / 2
        end
        local _exp_1 = mode
        if 1 == _exp_1 or "left" == _exp_1 then
          x = x + offset
        elseif 2 == _exp_1 or "center" == _exp_1 then
          x = x + offset + size / 2
        elseif 3 == _exp_1 or "right" == _exp_1 then
          x = x - offset + size
        end
        local tan, pnt, t = clip:getNormal(x / leng, true)
        tan.x = pnt.x + y * tan.x
        tan.y = pnt.y + y * tan.y
        return tan
      end)
      return self
    end
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  _class_0 = setmetatable({
    __init = function(self, shape, close)
      if close == nil then
        close = true
      end
      local isNumber
      isNumber = function(v)
        do
          v = tonumber(v)
          if v then
            return v
          else
            return error("unknown shape")
          end
        end
      end
      self.paths, self.l, self.t, self.r, self.b = { }, math.huge, math.huge, -math.huge, -math.huge
      if type(shape) == "string" then
        local i, data = 1, (function()
          local _accum_0 = { }
          local _len_0 = 1
          for s in shape:gmatch("%S+") do
            _accum_0[_len_0] = s
            _len_0 = _len_0 + 1
          end
          return _accum_0
        end)()
        while i <= #data do
          local _exp_0 = data[i]
          if "m" == _exp_0 then
            self:push(PATH())
            i = i + 2
          elseif "l" == _exp_0 then
            local j = 1
            while tonumber(data[i + j]) ~= nil do
              local last = self.paths[#self.paths]
              local path, p0 = last.path, POINT()
              if #path == 0 and data[i - 3] == "m" then
                p0.x = isNumber(data[i - 2])
                p0.y = isNumber(data[i - 1])
              else
                local segment = path[#path].segment
                p0 = POINT(segment[#segment])
              end
              local p1 = POINT()
              p1.x = isNumber(data[i + j + 0])
              p1.y = isNumber(data[i + j + 1])
              last:push(SEGMENT(p0, p1))
              j = j + 2
            end
            i = i + (j - 1)
          elseif "b" == _exp_0 then
            local j = 1
            while tonumber(data[i + j]) ~= nil do
              local last = self.paths[#self.paths]
              local path, p0 = last.path, POINT()
              if #path == 0 and data[i - 3] == "m" then
                p0.x = isNumber(data[i - 2])
                p0.y = isNumber(data[i - 1])
              else
                local segment = path[#path].segment
                p0 = POINT(segment[#segment])
              end
              local p1, p2, p3 = POINT(), POINT(), POINT()
              p1.x = isNumber(data[i + j + 0])
              p1.y = isNumber(data[i + j + 1])
              p2.x = isNumber(data[i + j + 2])
              p2.y = isNumber(data[i + j + 3])
              p3.x = isNumber(data[i + j + 4])
              p3.y = isNumber(data[i + j + 5])
              last:push(SEGMENT(p0, p1, p2, p3))
              j = j + 6
            end
            i = i + (j - 1)
          else
            error("unknown shape")
          end
          i = i + 1
        end
      elseif type(shape) == "table" and rawget(shape, "paths") then
        for key, value in pairs(shape:copy()) do
          self[key] = value
        end
      end
      local i = 1
      while i <= #self.paths do
        local path = self.paths[i].path
        if #path == 0 then
          table.remove(self.paths, i)
          i = i - 1
        end
        i = i + 1
      end
      if close == true or close == "close" then
        self:close()
      elseif close == "open" then
        self:open()
      end
      return self:setBoudingBox()
    end,
    __base = _base_0,
    __name = "SHAPE",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil then
        local parent = rawget(cls, "__parent")
        if parent then
          return parent[name]
        end
      else
        return val
      end
    end,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  SHAPE = _class_0
end
return {
  SHAPE = SHAPE
}
