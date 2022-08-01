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
local UTIL
UTIL = require("ZF.util.util").UTIL
local LAYER
LAYER = require("ZF.ass.tags.layer").LAYER
local TAGS
do
  local _class_0
  local _base_0 = {
    version = "1.0.0",
    split = function(self, txt, layers, layers_data)
      if txt == nil then
        txt = self.text
      end
      if layers == nil then
        layers = { }
      end
      if layers_data == nil then
        layers_data = { }
      end
      if not (self.isShape) then
        for l in txt:gmatch("%b{}") do
          l = LAYER(l)
          TABLE(layers):push(l)
          TABLE(layers_data):push(l:split())
        end
        local n = #self.between
        if (#layers - n) == 1 then
          self.between[n] = self:blank(self.between[n], "end")
          TABLE(self.between):push("")
        end
      else
        local layer = LAYER(self.text:match("%b{}"))
        TABLE(layers):push(layer)
        TABLE(layers_data):push(layer:split())
      end
      self.layers, self.layers_data = layers, layers_data
      return self
    end,
    blank = function(self, txt, where)
      if where == nil then
        where = "both"
      end
      local _exp_0 = where
      if "both" == _exp_0 then
        return txt:match("^%s*(.-)%s*$")
      elseif "start" == _exp_0 then
        return txt:match("^%s*(.-%s*)$")
      elseif "end" == _exp_0 then
        return txt:match("^(%s*.-)%s*$")
      elseif "spaceL" == _exp_0 then
        return txt:match("^(%s*).-%s*$")
      elseif "spaceR" == _exp_0 then
        return txt:match("^%s*.-(%s*)$")
      elseif "spaces" == _exp_0 then
        return txt:match("^(%s*).-(%s*)$")
      end
    end,
    firstCategory = function(self, values, once)
      if values == nil then
        values = { }
      end
      if once == nil then
        once = {
          "an",
          "b",
          "i",
          "s",
          "u",
          "org",
          "pos",
          "move",
          "fade",
          "fad"
        }
      end
      for _index_0 = 1, #once do
        local t = once[_index_0]
        values[t] = { }
      end
      for l, layer in ipairs(self.layers) do
        for _index_0 = 1, #once do
          local t = once[_index_0]
          if layer:contain(t) then
            TABLE(values[t]):push(layer:__match(AssTagsPatterns[t]["patterns_none_value"]))
            if l > 1 then
              layer:remove(t)
            end
          end
        end
      end
      for name, value in pairs(values) do
        local layer = self.layers[1]
        if layer:contain(name) then
          layer:remove({
            name,
            value[1]
          })
        else
          layer:insert(value[1])
        end
      end
      self:split(self:__tostring())
      return self
    end,
    insertPending = function(self, add_all, animation, fade)
      if add_all == nil then
        add_all = true
      end
      if animation == nil then
        animation = false
      end
      if fade == nil then
        fade = false
      end
      local layers, layers_data
      layers, layers_data = self.layers, self.layers_data
      for i = 2, #layers do
        local layer = layers[i]
        local lprev = TABLE(layers_data[i - 1]):copy()
        for j = #lprev, 1, -1 do
          local name, info, tag
          do
            local _obj_0 = lprev[j]
            name, info, tag = _obj_0.name, _obj_0.info, _obj_0.tag
          end
          if add_all then
            layer:insert({
              tag,
              not ((name == "fad" or name == "fade") and fade)
            })
          else
            if info["transformable"] then
              if not (layer:contain(name)) then
                layer:insert({
                  tag,
                  true
                })
              end
            else
              if name == "t" and animation then
                layer:insert({
                  tag,
                  true
                })
              elseif (name == "fad" or name == "fade") and fade then
                layer:insert(tag)
              end
            end
          end
        end
        layers_data[i] = layer:split()
      end
      self:split(self:__tostring())
      return self
    end,
    insert = function(self, ...)
      for l, layer in ipairs(self.layers) do
        layer:insert(...)
      end
      return self
    end,
    remove = function(self, ...)
      for l, layer in ipairs(self.layers) do
        layer:remove(...)
      end
      return self
    end,
    removeEquals = function(self)
      for i = 2, #self.layers do
        self.layers[i]:removeEquals(self.layers[i - 1])
      end
      return self
    end,
    insertStyleRef = function(self, line, onlyAnimated)
      for l, layer in ipairs(self.layers) do
        local style = l > 1 and line.styleref or line.styleref_old
        layer:insertStyleRef(style, onlyAnimated)
      end
      self:split(self:__tostring())
      return self
    end,
    removeStyleRef = function(self, line)
      for l, layer in ipairs(self.layers) do
        local style = l > 1 and line.styleref or line.styleref_old
        layer:removeStyleRef(style)
      end
      self:split(self:__tostring())
      return self
    end,
    clear = function(self, line)
      for l, layer in ipairs(self.layers) do
        layer:clear(line and (l > 1 and line.styleref or line.styleref_old) or nil)
      end
      self:split(self:__tostring())
      return self
    end,
    breaks = function(self)
      self:insertPending(true)
      local breaks = UTIL:headsTails(self:__tostring(), "\\N")
      breaks[1] = TAGS(breaks[1]):insertPending(false):__tostring()
      for i = 2, #breaks do
        local solver = (LAYER(breaks[i - 1])["layer"] .. breaks[i]):gsub("}%s*{", "")
        breaks[i] = TAGS(solver):insertPending(false):__tostring()
      end
      return breaks
    end,
    __tostring = function(self, concat)
      if concat == nil then
        concat = ""
      end
      local layers, between
      layers, between = self.layers, self.between
      for i = 1, #layers do
        concat = concat .. (layers[i]["layer"] .. between[i])
      end
      return concat
    end
  }
  _base_0.__index = _base_0
  _class_0 = setmetatable({
    __init = function(self, text)
      if text == nil then
        text = ""
      end
      self.text = text
      if type(self.text) ~= "table" then
        self.text = self:blank(text, "both")
        self.text = self.text:find("%b{}") ~= 1 and "{}" .. tostring(self.text) or self.text
        do
          local shape = UTIL:isShape(self.text:gsub("%b{}", ""))
          if shape then
            self.isShape = true
            self.between = {
              shape
            }
          else
            self.between = UTIL:headsTails(self.text, "%b{}")
            if #self.between > 1 and self.between[1] == "" then
              TABLE(self.between):shift()
            end
            local n = #self.between
            if n >= 1 then
              self.between[1] = self:blank(self.between[1], "start")
              if n > 1 then
                self.between[n] = self:blank(self.between[n], "end")
              end
            end
          end
        end
        return self:split()
      else
        self.layers = TABLE(self.text["layers"]):copy()
        self.layers_data = TABLE(self.text["layers_data"]):copy()
        self.between = TABLE(self.text["between"]):copy()
      end
    end,
    __base = _base_0,
    __name = "TAGS"
  }, {
    __index = _base_0,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  TAGS = _class_0
end
return {
  TAGS = TAGS
}
