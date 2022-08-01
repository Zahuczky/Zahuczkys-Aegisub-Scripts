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
local UTIL
do
  local _class_0
  local _base_0 = {
    version = "1.3.0",
    interpolation = function(self, t, interpolationType, ...)
      if t == nil then
        t = 0.5
      end
      if interpolationType == nil then
        interpolationType = "auto"
      end
      local values = type(...) == "table" and ... or {
        ...
      }
      local interpolate
      interpolate = function(u, f, l)
        u = MATH:clamp(u, 0, 1)
        return MATH:round((1 - u) * f + u * l)
      end
      local interpolate_alpha
      interpolate_alpha = function(u, f, l)
        local a = f:match("&?[hH](%x%x)&?")
        local b = l:match("&?[hH](%x%x)&?")
        local c = interpolate(u, tonumber(a, 16), tonumber(b, 16))
        return ("&H%02X&"):format(c)
      end
      local interpolate_color
      interpolate_color = function(u, f, l)
        local a = {
          f:match("&?[hH](%x%x)(%x%x)(%x%x)&?")
        }
        local b = {
          l:match("&?[hH](%x%x)(%x%x)(%x%x)&?")
        }
        local c
        do
          local _accum_0 = { }
          local _len_0 = 1
          for i = 1, 3 do
            _accum_0[_len_0] = interpolate(u, tonumber(a[i], 16), tonumber(b[i], 16))
            _len_0 = _len_0 + 1
          end
          c = _accum_0
        end
        return ("&H%02X%02X%02X&"):format(unpack(c))
      end
      local interpolate_shape
      interpolate_shape = function(u, f, l, j)
        if j == nil then
          j = 0
        end
        local a
        do
          local _accum_0 = { }
          local _len_0 = 1
          for s in f:gmatch("%-?%d[%.%d]*") do
            _accum_0[_len_0] = tonumber(s)
            _len_0 = _len_0 + 1
          end
          a = _accum_0
        end
        local b
        do
          local _accum_0 = { }
          local _len_0 = 1
          for s in l:gmatch("%-?%d[%.%d]*") do
            _accum_0[_len_0] = tonumber(s)
            _len_0 = _len_0 + 1
          end
          b = _accum_0
        end
        assert(#a == #b, "The shapes must have the same stitch length")
        f = f:gsub("%-?%d[%.%d]*", function(s)
          j = j + 1
          return MATH:round(interpolate(u, a[j], b[j]))
        end)
        return f
      end
      local _ = {
        interpolate_table = function(u, f, l, new)
          if new == nil then
            new = { }
          end
          assert(#f == #l, "The interpolation depends on tables with the same number of elements")
          for i = 1, #f do
            new[i] = UTIL:interpolation(u, nil, f[j], l[j])
          end
          return new
        end
      }
      local fn
      local _exp_0 = interpolationType
      if "number" == _exp_0 then
        fn = interpolate
      elseif "alpha" == _exp_0 then
        fn = interpolate_alpha
      elseif "color" == _exp_0 then
        fn = interpolate_color
      elseif "shape" == _exp_0 then
        fn = interpolate_shape
      elseif "table" == _exp_0 then
        fn = interpolate_table
      elseif "auto" == _exp_0 then
        local types = { }
        for k, v in ipairs(values) do
          if type(v) == "number" then
            types[k] = "number"
          elseif type(v) == "table" then
            types[k] = "table"
          elseif type(v) == "string" then
            if v:match("&?[hH]%x%x%x%x%x%x&?") then
              types[k] = "color"
            elseif v:match("&?[hH]%x%x&?") then
              types[k] = "alpha"
            elseif v:match("m%s+%-?%d[%.%-%d mlb]*") then
              types[k] = "shape"
            end
          end
          assert(types[k] == types[1], "The interpolation must be done on values of the same type")
        end
        return UTIL:interpolation(t, types[1], ...)
      end
      t = clamp(t, 0, 1) * (#values - 1)
      local u = floor(t)
      return fn(t - u, values[u + 1], values[u + 2] or values[u + 1])
    end,
    convertColor = function(self, color, mode)
      if mode == nil then
        mode = "html2ass"
      end
      local values = { }
      local _exp_0 = mode
      if "html2ass" == _exp_0 then
        color:gsub("#%s*(%x%x)(%x%x)(%x%x)", function(b, g, r)
          values[1] = "&H" .. tostring(r) .. tostring(g) .. tostring(b) .. "&"
        end)
      elseif "html2number" == _exp_0 then
        color:gsub("#%s*(%x%x)(%x%x)(%x%x)", function(b, g, r)
          values[1] = tonumber(b, 16)
          values[2] = tonumber(g, 16)
          values[3] = tonumber(r, 16)
        end)
      elseif "ass2html" == _exp_0 then
        color:gsub("&?[hH](%x%x)(%x%x)(%x%x)&?", function(r, g, b)
          values[1] = "#" .. tostring(b) .. tostring(g) .. tostring(r)
        end)
      elseif "ass2number" == _exp_0 then
        color:gsub("&?[hH](%x%x)(%x%x)(%x%x)&?", function(r, g, b)
          values[1] = tonumber(r, 16)
          values[2] = tonumber(g, 16)
          values[3] = tonumber(b, 16)
        end)
      end
      return unpack(values)
    end,
    clip2Draw = function(self, clip)
      local caps, shape = {
        v = "\\i?clip%((m%s+%-?%d[%.%-%d mlb]*)%)",
        r = "\\i?clip%(%s*(%-?%d[%.%d]*)%s*,%s*(%-?%d[%.%d]*)%s*,%s*(%-?%d[%.%d]*)%s*,%s*(%-?%d[%.%d]*)%s*%)"
      }, clip
      if clip:match("\\i?clip%b()") then
        do
          if not (clip:match(caps.v)) then
            local l, t, r, b = clip:match(caps.r)
            shape = "m " .. tostring(l) .. " " .. tostring(t) .. " l " .. tostring(r) .. " " .. tostring(t) .. " " .. tostring(r) .. " " .. tostring(b) .. " " .. tostring(l) .. " " .. tostring(b)
          else
            shape = clip:match(caps.v)
          end
        end
        return shape
      end
    end,
    getClassName = function(self, cls)
      do
        cls = getmetatable(cls)
        if cls then
          return cls.__class.__name
        end
      end
    end,
    headTail = function(self, s, div)
      local a, b, head, tail = s:find("(.-)" .. tostring(div) .. "(.*)")
      if a then
        return head, tail
      else
        return s, ""
      end
    end,
    headsTails = function(self, s, div)
      local add = { }
      while s ~= "" do
        local head, tail = UTIL:headTail(s, div)
        TABLE(add):push(head)
        s = tail
      end
      return add
    end,
    isBlank = function(self, t)
      if type(t) == "table" then
        if t.duration and t.text_stripped then
          if t.duration <= 0 or t.text_stripped:len() <= 0 then
            return true
          end
          t = t.text_stripped
        else
          t = t.text:gsub("%b{}", "")
        end
      else
        t = t:gsub("[ \t\n\r]", "")
        t = t:gsub("　", "")
      end
      return t:len() <= 0
    end,
    isShape = function(self, text, isShape, shape)
      if type(text) == "string" then
        do
          shape = text:gsub("%b{}", ""):match("m%s+%-?%d[%.%-%d mlb]*")
          if shape then
            return shape
          end
        end
      end
    end
  }
  _base_0.__index = _base_0
  _class_0 = setmetatable({
    __init = function() end,
    __base = _base_0,
    __name = "UTIL"
  }, {
    __index = _base_0,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  UTIL = _class_0
end
return {
  UTIL = UTIL
}
