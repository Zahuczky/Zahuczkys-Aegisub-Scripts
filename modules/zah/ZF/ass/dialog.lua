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
local TABLE
TABLE = require("ZF.util.table").TABLE
local LAYER
LAYER = require("ZF.ass.tags.layer").LAYER
local DIALOG
do
  local _class_0
  local _base_0 = {
    version = "1.0.0",
    iterSelected = function(self, copy, i)
      if copy == nil then
        copy = true
      end
      if i == nil then
        i = 0
      end
      local n = #self.selected
      return function()
        i = i + 1
        if i <= n then
          local s = self.selected[i]
          local l = self.subs[s + self.i[1]]
          if copy then
            local line = TABLE(l):copy()
            return l, line, s, i, n
          end
          return l, s, i, n
        end
      end
    end,
    iterSubtitle = function(self, copy, i)
      if copy == nil then
        copy = true
      end
      if i == nil then
        i = 0
      end
      local n = #self.subs
      return function()
        i = i + 1
        if i <= n then
          local l = self.subs[i + self.i[1]]
          if copy then
            local line = TABLE(l):copy()
            return l, line, i, n
          end
          return l, i, n
        end
      end
    end,
    getSelection = function(self)
      aegisub.set_undo_point(script_name)
      if #self.new_selection > 0 then
        return self.new_selection, self.new_selection[1]
      end
    end,
    insertLine = function(self, line, s, j)
      if j == nil then
        j = s + self.i[1] + 1
      end
      self.i[1] = self.i[1] + 1
      self.i[2] = self.i[2] + 1
      self.subs.insert(j, line)
      return TABLE(self.new_selection):push(j)
    end,
    removeLine = function(self, line, s, j)
      if j == nil then
        j = s + self.i[1]
      end
      line.comment = true
      self.subs[j] = line
      line.comment = false
      if self.rem then
        self.i[1] = self.i[1] - 1
        self.i[2] = self.i[2] - 1
        return self.subs.delete(j)
      end
    end,
    colletHead = function(self)
      self.meta, self.style = karaskel.collect_head(self.subs)
      for i = 1, self.style.n do
        do
          local _with_0 = self.style[i]
          _with_0.alpha = "&H00&"
          _with_0.alpha1 = alpha_from_style(_with_0.color1)
          _with_0.alpha2 = alpha_from_style(_with_0.color2)
          _with_0.alpha3 = alpha_from_style(_with_0.color3)
          _with_0.alpha4 = alpha_from_style(_with_0.color4)
          _with_0.color1 = color_from_style(_with_0.color1)
          _with_0.color2 = color_from_style(_with_0.color2)
          _with_0.color3 = color_from_style(_with_0.color3)
          _with_0.color4 = color_from_style(_with_0.color4)
        end
      end
    end,
    reStyle = function(self, line, layer)
      local flayer = LAYER(layer or line.text, false):animated("hide")
      local copyStyle = TABLE(self.style):copy()
      local newValues = {
        align = flayer:getTagValue("an"),
        fontname = flayer:getTagValue("fn"),
        fontsize = flayer:getTagValue("fs"),
        scale_x = flayer:getTagValue("fscx"),
        scale_y = flayer:getTagValue("fscy"),
        spacing = flayer:getTagValue("fsp"),
        outline = flayer:getTagValue("bord"),
        shadow = flayer:getTagValue("shad"),
        angle = flayer:getTagValue("frz"),
        alpha = flayer:getTagValue("alpha"),
        alpha1 = flayer:getTagValue("1a"),
        alpha2 = flayer:getTagValue("2a"),
        alpha3 = flayer:getTagValue("3a"),
        alpha4 = flayer:getTagValue("4a"),
        color1 = flayer:getTagValue("1c"),
        color2 = flayer:getTagValue("2c"),
        color3 = flayer:getTagValue("3c"),
        color4 = flayer:getTagValue("4c"),
        bold = flayer:getTagValue("b"),
        italic = flayer:getTagValue("i"),
        underline = flayer:getTagValue("u"),
        strikeout = flayer:getTagValue("s")
      }
      do
        local fs = newValues["fontsize"]
        if fs then
          newValues["fontsize"] = fs <= 0 and nil or fs
        end
      end
      local margin_l, margin_r, margin_t, margin_b, text
      margin_l, margin_r, margin_t, margin_b, text = line.margin_l, line.margin_r, line.margin_t, line.margin_b, line.text
      for s, value in ipairs(copyStyle) do
        for k, v in pairs(newValues) do
          value[k] = v or value[k]
        end
        if margin_l > 0 then
          value.margin_l = margin_l
        end
        if margin_r > 0 then
          value.margin_r = margin_r
        end
        if margin_t > 0 then
          value.margin_v = margin_t
        end
        if margin_b > 0 then
          value.margin_v = margin_b
        end
      end
      flayer:animated("unhide")
      return copyStyle
    end,
    getPerspectiveTags = function(self, line, layer, values)
      if values == nil then
        values = { }
      end
      local flayer = LAYER(layer or line.text, false):animated("hide")
      do
        local ref = line.styleref
        if ref then
          local res_x, res_y
          do
            local _obj_0 = self.meta
            res_x, res_y = _obj_0.res_x, _obj_0.res_y
          end
          local align, margin_l, margin_r, margin_v
          align, margin_l, margin_r, margin_v = ref.align, ref.margin_l, ref.margin_r, ref.margin_v
          local x
          local _exp_0 = align
          if 1 == _exp_0 or 4 == _exp_0 or 7 == _exp_0 then
            x = margin_l
          elseif 2 == _exp_0 or 5 == _exp_0 or 8 == _exp_0 then
            x = (res_x - margin_r + margin_l) / 2
          elseif 3 == _exp_0 or 6 == _exp_0 or 9 == _exp_0 then
            x = res_x - margin_r
          end
          local y
          local _exp_1 = align
          if 1 == _exp_1 or 2 == _exp_1 or 3 == _exp_1 then
            y = res_y - margin_v
          elseif 4 == _exp_1 or 5 == _exp_1 or 6 == _exp_1 then
            y = res_y / 2
          elseif 7 == _exp_1 or 8 == _exp_1 or 9 == _exp_1 then
            y = margin_v
          end
          values["pos"] = {
            x,
            y
          }
        end
      end
      do
        values.p = flayer:getTagValue("p") or "text"
        values.frx = flayer:getTagValue("frx") or 0
        values.fry = flayer:getTagValue("fry") or 0
        values.fax = flayer:getTagValue("fax") or 0
        values.fay = flayer:getTagValue("fay") or 0
        values.xshad = flayer:getTagValue("xshad") or 0
        values.yshad = flayer:getTagValue("yshad") or 0
        values.pos = flayer:getTagValue("pos") or (values.pos or {
          0,
          0
        })
        do
          local move = flayer:getTagValue("move")
          if move then
            values.pos = {
              move[1],
              move[2]
            }
            values.move = move
          end
        end
        values.org = flayer:getTagValue("org") or {
          values.pos[1],
          values.pos[2]
        }
      end
      flayer:animated("unhide")
      return values
    end,
    currentIndex = function(self, s)
      return s + self.i[1] - self.i[2] - self.i[4] + 1
    end,
    progressLine = function(self, s)
      if s == "reset" then
        aegisub.progress.set(0)
        return aegisub.progress.task("")
      else
        aegisub.progress.set(100 * s / self.i[3])
        return aegisub.progress.task("Processing Line: [ " .. tostring(self:currentIndex(s)) .. " ]")
      end
    end,
    warning = function(self, s, msg)
      if msg == nil then
        msg = ""
      end
      aegisub.debug.out(2, "———— [Warning] ➔ Line \"[ " .. tostring(self:currentIndex(s)) .. " ]\" skipped\n")
      return aegisub.debug.out(2, "—— [Cause] ➔ " .. msg .. "\n\n")
    end
  }
  _base_0.__index = _base_0
  _class_0 = setmetatable({
    __init = function(self, subs, selected, active, rem)
      if rem == nil then
        rem = false
      end
      self.subs, self.selected, self.active, self.rem = subs, selected, active, rem
      self.i = {
        0,
        0,
        self.selected[#self.selected],
        0
      }
      self.new_selection = { }
      for l, i in self:iterSubtitle(false) do
        if l["class"] == "dialogue" then
          self.i[4] = i
          break
        end
      end
      return self:colletHead()
    end,
    __base = _base_0,
    __name = "DIALOG"
  }, {
    __index = _base_0,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  DIALOG = _class_0
end
return {
  DIALOG = DIALOG
}
