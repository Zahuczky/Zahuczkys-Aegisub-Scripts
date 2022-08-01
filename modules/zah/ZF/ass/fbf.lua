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
local UTIL
UTIL = require("ZF.util.util").UTIL
local MATH
MATH = require("ZF.util.math").MATH
local TABLE
TABLE = require("ZF.util.table").TABLE
local LAYER
LAYER = require("ZF.ass.tags.layer").LAYER
local TAGS
TAGS = require("ZF.ass.tags.tags").TAGS
local ffm = aegisub.frame_from_ms
local mff = aegisub.ms_from_frame
local FBF
do
  local _class_0
  local _base_0 = {
    version = "1.1.4",
    frameDur = function(self, dec)
      if dec == nil then
        dec = 0
      end
      local msa, msb = mff(1), mff(101)
      return MATH:round(msb and (msb - msa) / 100 or 41.708, dec)
    end,
    insertMove = function(self, layer, move)
      if move then
        local x, y = self.util.move(unpack(move["value"]))
        return layer:remove({
          "move",
          "\\pos(" .. tostring(x) .. "," .. tostring(y) .. ")"
        })
      end
    end,
    insertFade = function(self, layer, fade)
      if fade then
        local value = layer:getTagValue("alpha") or "&H00&"
        value = value:match("%x%x")
        value = tonumber(value, 16)
        value = self.util.fade(value, unpack(fade["value"]))
        return layer:remove({
          "fade",
          "\\alpha" .. tostring(value)
        })
      end
    end,
    insertTransform = function(self, layer, concat)
      if concat == nil then
        concat = ""
      end
      while layer:contain("t") do
        local s, e, a, transform
        do
          local _obj_0 = layer:getTagValue("t")
          s, e, a, transform = _obj_0.s, _obj_0.e, _obj_0.a, _obj_0.transform
        end
        layer:animated("hide")
        local _list_0 = LAYER(transform):split()
        for _index_0 = 1, #_list_0 do
          local v = _list_0[_index_0]
          local name, value, info
          name, value, info = v.name, v.value, v.info
          local morph, id, p = {
            nil,
            value
          }, info["id"], nil
          if layer:contain(name) then
            morph[1] = layer:getTagValue(name)
          else
            morph[1] = AssTagsPatterns[name]["value"]
          end
          local u = self.util.transform(s, e, a)
          if not (name == "clip" or name == "iclip") then
            p = UTIL:interpolation(u, "auto", morph)
            if type(p) == "number" then
              MATH:round(p)
            end
          else
            assert(morph[1], "Can't transform a \\clip into a \\iclip or vice versa")
            if type(morph[1]) == "table" and type(morph[2]) == "table" then
              local l1, t1, r1, b1
              do
                local _obj_0 = morph[1]
                l1, t1, r1, b1 = _obj_0[1], _obj_0[2], _obj_0[3], _obj_0[4]
              end
              local l2, t2, r2, b2
              do
                local _obj_0 = morph[2]
                l2, t2, r2, b2 = _obj_0[1], _obj_0[2], _obj_0[3], _obj_0[4]
              end
              local l = MATH:round(UTIL:interpolation(u, "number", l1, l2))
              local t = MATH:round(UTIL:interpolation(u, "number", t1, t2))
              local r = MATH:round(UTIL:interpolation(u, "number", r1, r2))
              local b = MATH:round(UTIL:interpolation(u, "number", b1, b2))
              p = "(" .. tostring(l) .. "," .. tostring(t) .. "," .. tostring(r) .. "," .. tostring(b) .. ")"
            else
              p = "(" .. tostring(UTIL:interpolation(u, "shape", morph)) .. ")"
            end
          end
          concat = concat .. (id .. p)
        end
        layer:animated("unhide")
        layer:remove({
          "t",
          concat,
          1
        })
      end
    end,
    setup = function(self, line)
      for name, info in pairs(AssTagsPatterns) do
        do
          local style_name = info["style_name"]
          if style_name then
            AssTagsPatterns[name]["value"] = line.styleref_old[style_name]
          else
            AssTagsPatterns[name]["value"] = AssTagsPatterns[name]["default_value"]
          end
        end
      end
      local tags = TAGS(line.text)
      tags:firstCategory()
      tags:insertPending(false, false, true)
      local flyr = tags["layers_data"][1]
      local move = flyr.getTagValue("move")
      local fade = flyr.getTagValue("fade")
      return tags, move, fade
    end,
    perform = function(self, line, tags, move, fade)
      local __tags = TAGS(tags)
      local layers = __tags["layers"]
      self:insertMove(layers[1], move)
      for li, layer in ipairs(layers) do
        if li > 1 then
          layer:insertPending(layers[li - 1])
        end
        self:insertTransform(layer)
        self:insertFade(layer, fade)
        layer:clear(li > 1 and line.styleref or line.styleref_old)
        if li > 1 then
          layer:removeEquals(layers[li - 1])
        end
      end
      local result = __tags:__tostring()
      return result:gsub("{%s*}", "")
    end,
    iter = function(self, step)
      if step == nil then
        step = 1
      end
      local sframe, eframe, dframe
      sframe, eframe, dframe = self.sframe, self.eframe, self.dframe
      local d = sframe - 1
      local i = d
      return function()
        i = i + step
        if i < eframe then
          self.s = mff(i - step == d and sframe or i)
          self.e = mff(min(i + step, eframe))
          self.d = self.e - self.s
          return self.s, self.e, self.d, i - d, dframe
        end
      end
    end
  }
  _base_0.__index = _base_0
  _class_0 = setmetatable({
    __init = function(self, l, start_time, end_time)
      if start_time == nil then
        start_time = l.start_time
      end
      if end_time == nil then
        end_time = l.end_time
      end
      assert(mff(0), "video not loaded")
      self.line = TABLE(l):copy()
      self.lstart = start_time
      self.lend = end_time
      self.ldur = end_time - start_time
      self.sframe = ffm(start_time)
      self.eframe = ffm(end_time)
      local soffset = mff(self.sframe)
      local eoffset = mff(self.sframe + 1)
      self.offset = math.floor((eoffset - soffset) / 2)
      self.dframe = self.eframe - self.sframe
      self.s, self.e, self.d = 0, end_time, end_time - start_time
      local getTimeInInterval
      getTimeInInterval = function(t1, t2, accel, t)
        if accel == nil then
          accel = 1
        end
        local u = self.s + self.offset - self.lstart
        if u < t1 then
          t = 0
        elseif u >= t2 then
          t = 1
        else
          t = (u - t1) ^ accel / (t2 - t1) ^ accel
        end
        return t
      end
      self.util = {
        transform = function(...)
          local args, t1, t2, accel = {
            ...
          }, 0, self.ldur, 1
          if #args == 3 then
            t1, t2, accel = args[1], args[2], args[3]
          elseif #args == 2 then
            t1, t2 = args[1], args[2]
          elseif #args == 1 then
            accel = args[1]
          end
          return getTimeInInterval(t1, t2, accel)
        end,
        move = function(x1, y1, x2, y2, t1, t2)
          if t1 and t2 then
            if t1 > t2 then
              t1, t2 = t2, t1
            end
          else
            t1, t2 = 0, 0
          end
          if t1 <= 0 and t2 <= 0 then
            t1, t2 = 0, self.ldur
          end
          local t = getTimeInInterval(t1, t2)
          local x = MATH:round((1 - t) * x1 + t * x2, 3)
          local y = MATH:round((1 - t) * y1 + t * y2, 3)
          return x, y
        end,
        fade = function(dec, ...)
          local interpolate_alpha
          interpolate_alpha = function(now, t1, t2, t3, t4, a1, a2, a3, a)
            if a == nil then
              a = a3
            end
            if now < t1 then
              a = a1
            elseif now < t2 then
              local cf = (now - t1) / (t2 - t1)
              a = a1 * (1 - cf) + a2 * cf
            elseif now < t3 then
              a = a2
            elseif now < t4 then
              local cf = (now - t3) / (t4 - t3)
              a = a2 * (1 - cf) + a3 * cf
            end
            return a
          end
          local args, a1, a2, a3, t1, t2, t3, t4 = {
            ...
          }
          if #args == 2 then
            a1 = 255
            a2 = 0
            a3 = 255
            t1 = 0
            t2, t3 = args[1], args[2]
            t4 = self.ldur
            t3 = t4 - t3
          elseif #args == 7 then
            a1, a2, a3, t1, t2, t3, t4 = args[1], args[2], args[3], args[4], args[5], args[6], args[7]
          else
            return ""
          end
          return ass_alpha(interpolate_alpha(self.s + self.offset - self.lstart, t1, t2, t3, t4, a1, dec or a2, a3))
        end
      }
    end,
    __base = _base_0,
    __name = "FBF"
  }, {
    __index = _base_0,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  FBF = _class_0
end
return {
  FBF = FBF
}
