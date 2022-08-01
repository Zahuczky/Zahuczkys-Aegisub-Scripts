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
local SHAPE
SHAPE = require("ZF.2D.shape").SHAPE
local MATH
MATH = require("ZF.util.math").MATH
local TABLE
TABLE = require("ZF.util.table").TABLE
local UTIL
UTIL = require("ZF.util.util").UTIL
local TAGS
TAGS = require("ZF.ass.tags.tags").TAGS
local FONT
FONT = require("ZF.ass.font").FONT
local LINE
do
  local _class_0
  local _base_0 = {
    version = "1.4.0",
    prepoc = function(self, dialog)
      local line, tags, text
      line, tags, text = self.line, self.tags, self.text
      local res_x, res_y, video_x_correct_factor
      do
        local _obj_0 = dialog["meta"]
        res_x, res_y, video_x_correct_factor = _obj_0.res_x, _obj_0.res_y, _obj_0.video_x_correct_factor
      end
      line.tags = line.tags and line.tags or tags.layers[1]["layer"]
      line.text_stripped = text:gsub("%b{}", ""):gsub("\\h", " ")
      line.duration = line.end_time - line.start_time
      local new_style = dialog:reStyle(line)
      do
        local style = new_style[line.style]
        if style then
          line.styleref = style
        else
          aegisub.debug.out(2, "WARNING: Style not found: " .. tostring(line.style) .. "\n")
          line.styleref = new_style[1]
        end
      end
      do
        local style = dialog.style[line.style]
        if style then
          line.styleref_old = style
        else
          aegisub.debug.out(2, "WARNING: Style not found: " .. tostring(line.style) .. "\n")
          line.styleref_old = new_style[1]
        end
      end
      local align = line.styleref.align
      line.width, line.height, line.descent, line.extlead = aegisub.text_extents(line.styleref, line.text_stripped)
      line.space_width = aegisub.text_extents(line.styleref, " ")
      line.width = line.width * video_x_correct_factor
      line.space_width = line.space_width * video_x_correct_factor
      line.margin_v = line.margin_t
      line.eff_margin_l = line.margin_l > 0 and line.margin_l or line.styleref.margin_l
      line.eff_margin_r = line.margin_r > 0 and line.margin_r or line.styleref.margin_r
      line.eff_margin_t = line.margin_t > 0 and line.margin_t or line.styleref.margin_t
      line.eff_margin_b = line.margin_b > 0 and line.margin_b or line.styleref.margin_b
      line.eff_margin_v = line.margin_v > 0 and line.margin_v or line.styleref.margin_v
      local _exp_0 = align
      if 1 == _exp_0 or 4 == _exp_0 or 7 == _exp_0 then
        line.left = line.eff_margin_l
        line.center = line.left + line.width / 2
        line.right = line.left + line.width
        line.x = line.left
      elseif 2 == _exp_0 or 5 == _exp_0 or 8 == _exp_0 then
        line.left = (res_x - line.eff_margin_l - line.eff_margin_r - line.width) / 2 + line.eff_margin_l
        line.center = line.left + line.width / 2
        line.right = line.left + line.width
        line.x = line.center
      elseif 3 == _exp_0 or 6 == _exp_0 or 9 == _exp_0 then
        line.left = res_x - line.eff_margin_r - line.width
        line.center = line.left + line.width / 2
        line.right = line.left + line.width
        line.x = line.right
      end
      local _exp_1 = align
      if 7 == _exp_1 or 8 == _exp_1 or 9 == _exp_1 then
        line.top = line.eff_margin_t
        line.middle = line.top + line.height / 2
        line.bottom = line.top + line.height
        line.y = line.top
      elseif 4 == _exp_1 or 5 == _exp_1 or 6 == _exp_1 then
        line.top = (res_y - line.eff_margin_t - line.eff_margin_b - line.height) / 2 + line.eff_margin_t
        line.middle = line.top + line.height / 2
        line.bottom = line.top + line.height
        line.y = line.middle
      elseif 1 == _exp_1 or 2 == _exp_1 or 3 == _exp_1 then
        line.bottom = res_y - line.eff_margin_b
        line.middle = line.bottom - line.height / 2
        line.top = line.bottom - line.height
        line.y = line.bottom
      end
      return self
    end,
    tags2Lines = function(self, dialog, noblank)
      if noblank == nil then
        noblank = true
      end
      local line, tags
      line, tags = self.line, self.tags
      if not (line.styleref) then
        self:prepoc(dialog)
      end
      local res_x, res_y
      do
        local _obj_0 = dialog["meta"]
        res_x, res_y = _obj_0.res_x, _obj_0.res_y
      end
      local layers, between
      do
        local _obj_0 = self.tags
        layers, between = _obj_0.layers, _obj_0.between
      end
      local temp = {
        n = #layers,
        text = "",
        left = 0,
        width = 0,
        height = 0,
        offsety = 0,
        breaky = 0
      }
      for i = 1, temp.n do
        local tag_layer = layers[i]["layer"]
        local txt_layer = between[i]
        txt_layer = txt_layer:gsub("\\h", " ")
        local l = TABLE(line):copy()
        l.isTags = true
        l.prevspace = self.tags:blank(txt_layer, "spaceL"):len()
        l.postspace = self.tags:blank(txt_layer, "spaceR"):len()
        txt_layer = self.tags:blank(txt_layer)
        l.text = tag_layer .. txt_layer
        l.tags = tag_layer
        l.text_stripped = txt_layer
        LINE(l):prepoc(dialog)
        local align, offsety = l.styleref.align
        local prevspace = l.prevspace * l.space_width
        temp.left = temp.left + prevspace
        local _exp_0 = align
        if 1 == _exp_0 or 4 == _exp_0 or 7 == _exp_0 then
          l.offsetx = 0
          l.left = temp.left + l.eff_margin_l
          l.center = l.left + l.width / 2
          l.right = l.left + l.width
        elseif 2 == _exp_0 or 5 == _exp_0 or 8 == _exp_0 then
          l.offsetx = (res_x - l.eff_margin_l - l.eff_margin_r) / 2 + l.eff_margin_l
          l.left = temp.left
          l.center = l.left + l.width / 2
          l.right = l.left + l.width
        elseif 3 == _exp_0 or 6 == _exp_0 or 9 == _exp_0 then
          l.offsetx = res_x - l.eff_margin_r
          l.left = temp.left
          l.center = l.left + l.width / 2
          l.right = l.left + l.width
        end
        local _exp_1 = align
        if 7 == _exp_1 or 8 == _exp_1 or 9 == _exp_1 then
          l.offsety = 0.5 - l.descent + l.height
          l.top = l.eff_margin_t
          l.middle = l.top + l.height / 2
          l.bottom = l.top + l.height
        elseif 4 == _exp_1 or 5 == _exp_1 or 6 == _exp_1 then
          l.offsety = 0.5 - l.descent + l.height / 2
          l.top = (res_y - l.eff_margin_t - l.eff_margin_b - l.height) / 2 + l.eff_margin_t
          l.middle = l.top + l.height / 2
          l.bottom = l.top + l.height
        elseif 1 == _exp_1 or 2 == _exp_1 or 3 == _exp_1 then
          l.offsety = 0.5 - l.descent
          l.bottom = res_y - l.eff_margin_b
          l.middle = l.bottom - l.height / 2
          l.top = l.bottom - l.height
        end
        local postspace = l.postspace * l.space_width
        temp.left = temp.left + (l.width + postspace)
        temp.text = temp.text .. l.text_stripped
        temp.width = temp.width + (l.width + prevspace + postspace)
        temp.height = math.max(temp.height, l.height)
        temp.descent = not temp.descent and l.descent or math.max(temp.descent, l.descent)
        temp.extlead = not temp.extlead and l.extlead or math.max(temp.extlead, l.extlead)
        temp.breaky = math.max(temp.breaky, l.styleref.fontsize * l.styleref.scale_y / 100)
        temp.offsety = align > 3 and math.max(temp.offsety, l.offsety) or math.min(temp.offsety, l.offsety)
        temp[i] = l
      end
      local n, text, offsety, width, height, breaky
      n, text, offsety, width, height, offsety, breaky = temp.n, temp.text, temp.offsety, temp.width, temp.height, temp.offsety, temp.breaky
      local data = {
        n = 0,
        text = text,
        offsety = offsety,
        width = width,
        height = height,
        offsety = offsety,
        breaky = breaky
      }
      for i = 1, n do
        local l = temp[i]
        local _exp_0 = l.styleref.align
        if 1 == _exp_0 or 4 == _exp_0 or 7 == _exp_0 then
          l.x = l.left
        elseif 2 == _exp_0 or 5 == _exp_0 or 8 == _exp_0 then
          l.offsetx = l.offsetx - (width / 2)
          l.center = l.center + l.offsetx
          l.x = l.center
        elseif 3 == _exp_0 or 6 == _exp_0 or 9 == _exp_0 then
          l.offsetx = l.offsetx - width
          l.right = l.right + l.offsetx
          l.x = l.right
        end
        l.offsety = offsety - l.offsety
        local _exp_1 = l.styleref.align
        if 7 == _exp_1 or 8 == _exp_1 or 9 == _exp_1 then
          l.top = l.top + l.offsety
          l.y = l.top
        elseif 4 == _exp_1 or 5 == _exp_1 or 6 == _exp_1 then
          l.middle = l.middle + l.offsety
          l.y = l.middle
        elseif 1 == _exp_1 or 2 == _exp_1 or 3 == _exp_1 then
          l.bottom = l.bottom + l.offsety
          l.y = l.bottom
        end
        if noblank and l.text_stripped ~= "" then
          data.n = data.n + 1
          data[data.n] = l
        end
      end
      return data
    end,
    breaks2Lines = function(self, dialog, noblank)
      if noblank == nil then
        noblank = true
      end
      local line, tags
      line, tags = self.line, self.tags
      local split = tags:breaks()
      local slen, data, add = #split, {
        n = 0
      }, {
        n = {
          sum = 0
        },
        r = {
          sum = 0
        }
      }
      local temp
      do
        local _accum_0 = { }
        local _len_0 = 1
        for i = 1, slen do
          _accum_0[_len_0] = LINE(line, split[i]):tags2Lines(dialog, noblank)
          _len_0 = _len_0 + 1
        end
        temp = _accum_0
      end
      for i = 1, slen do
        local j = slen - i + 1
        local text, breaky
        do
          local _obj_0 = temp[i]
          text, breaky = _obj_0.text, _obj_0.breaky
        end
        add.n[i] = add.n.sum
        add.n.sum = add.n.sum + (text == "" and breaky / 2 or breaky)
        do
          local _obj_0 = temp[j]
          text, breaky = _obj_0.text, _obj_0.breaky
        end
        add.r[j] = add.r.sum
        add.r.sum = add.r.sum + (text == "" and breaky / 2 or breaky)
      end
      for i = 1, slen do
        local brk = temp[i]
        for j = 1, brk.n do
          local tag = brk[j]
          local _exp_0 = line.styleref.align
          if 7 == _exp_0 or 8 == _exp_0 or 9 == _exp_0 then
            tag.y = tag.y + add.n[i]
          elseif 4 == _exp_0 or 5 == _exp_0 or 6 == _exp_0 then
            tag.y = tag.y + (add.n[i] - add.r[i]) / 2
          elseif 1 == _exp_0 or 2 == _exp_0 or 3 == _exp_0 then
            tag.y = tag.y - add.r[i]
          end
        end
        if noblank and brk.text ~= "" then
          data.n = data.n + 1
          data[data.n] = brk
        end
      end
      return data
    end,
    chars = function(self, noblank)
      if noblank == nil then
        noblank = true
      end
      local line, text_stripped
      line, text_stripped = self.line, self.text_stripped
      local tags, styleref, start_time, end_time, duration, isTags
      tags, styleref, start_time, end_time, duration, isTags = line.tags, line.styleref, line.start_time, line.end_time, line.duration, line.isTags
      local chars, left, align = {
        n = 0
      }, line.left, styleref.align
      for c, char in Yutils.utf8.chars(text_stripped) do
        local text = char
        text_stripped = char
        local width, height, descent, extlead = aegisub.text_extents(styleref, text_stripped)
        local center = left + width / 2
        local right = left + width
        local top = line.top
        local middle = line.middle
        local bottom = line.bottom
        local addx = isTags and line.offsetx or 0
        local x
        local _exp_0 = align
        if 1 == _exp_0 or 4 == _exp_0 or 7 == _exp_0 then
          x = left
        elseif 2 == _exp_0 or 5 == _exp_0 or 8 == _exp_0 then
          x = center + addx
        elseif 3 == _exp_0 or 6 == _exp_0 or 9 == _exp_0 then
          x = right + addx
        end
        local addy = isTags and line.y or nil
        local y
        local _exp_1 = align
        if 7 == _exp_1 or 8 == _exp_1 or 9 == _exp_1 then
          y = addy or top
        elseif 4 == _exp_1 or 5 == _exp_1 or 6 == _exp_1 then
          y = addy or middle
        elseif 1 == _exp_1 or 2 == _exp_1 or 3 == _exp_1 then
          y = addy or bottom
        end
        if not (noblank and UTIL:isBlank(text_stripped)) then
          chars.n = chars.n + 1
          chars[chars.n] = {
            i = chars.n,
            text = text,
            tags = tags,
            text_stripped = text_stripped,
            width = width,
            height = height,
            descent = descent,
            extlead = extlead,
            center = center,
            left = left,
            right = right,
            top = top,
            middle = middle,
            bottom = bottom,
            x = x,
            y = y,
            start_time = start_time,
            end_time = end_time,
            duration = duration
          }
        end
        left = left + width
      end
      return chars
    end,
    words = function(self, noblank)
      if noblank == nil then
        noblank = true
      end
      local line, text_stripped
      line, text_stripped = self.line, self.text_stripped
      local tags, styleref, space_width, start_time, end_time, duration, isTags
      tags, styleref, space_width, start_time, end_time, duration, isTags = line.tags, line.styleref, line.space_width, line.start_time, line.end_time, line.duration, line.isTags
      local words, left, align = {
        n = 0
      }, line.left, styleref.align
      for prevspace, word, postspace in line.text_stripped:gmatch("(%s*)(%S+)(%s*)") do
        local text = word
        text_stripped = word
        prevspace = prevspace:len()
        postspace = postspace:len()
        local width, height, descent, extlead = aegisub.text_extents(styleref, text_stripped)
        left = left + (prevspace * space_width)
        local center = left + width / 2
        local right = left + width
        local top = line.top
        local middle = line.middle
        local bottom = line.bottom
        local addx = isTags and line.offsetx or 0
        local x
        local _exp_0 = align
        if 1 == _exp_0 or 4 == _exp_0 or 7 == _exp_0 then
          x = left
        elseif 2 == _exp_0 or 5 == _exp_0 or 8 == _exp_0 then
          x = center + addx
        elseif 3 == _exp_0 or 6 == _exp_0 or 9 == _exp_0 then
          x = right + addx
        end
        local addy = isTags and line.y or nil
        local y
        local _exp_1 = align
        if 7 == _exp_1 or 8 == _exp_1 or 9 == _exp_1 then
          y = addy or top
        elseif 4 == _exp_1 or 5 == _exp_1 or 6 == _exp_1 then
          y = addy or middle
        elseif 1 == _exp_1 or 2 == _exp_1 or 3 == _exp_1 then
          y = addy or bottom
        end
        if not (noblank and UTIL:isBlank(text_stripped)) then
          words.n = words.n + 1
          words[words.n] = {
            i = words.n,
            text = text,
            tags = tags,
            text_stripped = text_stripped,
            width = width,
            height = height,
            descent = descent,
            extlead = extlead,
            center = center,
            left = left,
            right = right,
            top = top,
            middle = middle,
            bottom = bottom,
            x = x,
            y = y,
            start_time = start_time,
            end_time = end_time,
            duration = duration
          }
        end
        left = left + (width + postspace * space_width)
      end
      return words
    end,
    reallocate = function(self, index, coords)
      local line
      line = self.line
      local vx, vy, x1, y1, x2, y2, isMove
      do
        if coords.move then
          vx, vy, isMove = coords.move[1], coords.move[2], true
        else
          vx, vy, isMove = coords.pos[1], coords.pos[2]
        end
      end
      x1 = MATH:round(index.x - line.x + vx)
      y1 = MATH:round(index.y - line.y + vy)
      local pos = {
        x1,
        y1
      }
      if isMove then
        x2 = MATH:round(index.x - line.x + coords.move[3])
        y2 = MATH:round(index.y - line.y + coords.move[4])
        pos = {
          x1,
          y1,
          x2,
          y2,
          coords.move[5],
          coords.move[6]
        }
      end
      return pos, (index.tags:match("\\fr[xyz]*[%-%.%d]*") or line.styleref.angle ~= 0) and coords.org or nil
    end,
    toShape = function(self, dialog, align, px, py)
      if align == nil then
        align = self.line.styleref.align
      end
      if px == nil then
        px = 0
      end
      if py == nil then
        py = 0
      end
      local left, center, right, top, middle, bottom
      do
        local _obj_0 = self.line
        left, center, right, top, middle, bottom = _obj_0.left, _obj_0.center, _obj_0.right, _obj_0.top, _obj_0.middle, _obj_0.bottom
      end
      local clip, breaks = "", self:breaks2Lines(dialog)
      for b, brk in ipairs(breaks) do
        for t, tag in ipairs(brk) do
          local font = FONT(tag.styleref)
          local shape, width, height
          do
            local _obj_0 = font:get(tag.text_stripped)
            shape, width, height = _obj_0.shape, _obj_0.width, _obj_0.height
          end
          shape = SHAPE(shape)
          local temp
          local _exp_0 = align
          if 1 == _exp_0 or 4 == _exp_0 or 7 == _exp_0 then
            temp = shape:move(px + tag.x - left)
          elseif 2 == _exp_0 or 5 == _exp_0 or 8 == _exp_0 then
            temp = shape:move(px + tag.x - center - width / 2)
          elseif 3 == _exp_0 or 6 == _exp_0 or 9 == _exp_0 then
            temp = shape:move(px + tag.x - right - width)
          end
          local _exp_1 = align
          if 7 == _exp_1 or 8 == _exp_1 or 9 == _exp_1 then
            temp = temp:move(0, py + tag.y - top)
          elseif 4 == _exp_1 or 5 == _exp_1 or 6 == _exp_1 then
            temp = temp:move(0, py + tag.y - middle - height / 2)
          elseif 1 == _exp_1 or 2 == _exp_1 or 3 == _exp_1 then
            temp = temp:move(0, py + tag.y - bottom - height)
          end
          clip = clip .. temp:build()
        end
      end
      local shape = SHAPE(clip):setPosition(align, "ucp", px, py):build()
      return shape, clip
    end
  }
  _base_0.__index = _base_0
  _class_0 = setmetatable({
    __init = function(self, line, text, text_stripped, tags)
      self.line, self.text, self.text_stripped, self.tags = line, text, text_stripped, tags
      self.text = self.text or self.line.text
      self.text_stripped = self.text_stripped or self.line.text_stripped
      self.tags = self.tags or TAGS(self.text)
    end,
    __base = _base_0,
    __name = "LINE"
  }, {
    __index = _base_0,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  LINE = _class_0
end
return {
  LINE = LINE
}
