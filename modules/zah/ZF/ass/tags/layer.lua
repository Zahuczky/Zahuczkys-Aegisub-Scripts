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
local getPatterns
getPatterns = function(get_value)
  local patterns = { }
  for name, pattern in pairs({
    font = "[^\\}]*",
    unsigned_int = "%d+",
    unsigned_float = "%d[%.%d]*",
    float = "%-?%d[%.%d]*",
    hex = "&?[Hh]%x+&?",
    bool = "[0-1]",
    zut = "[0-3]",
    oun = "[1-9]",
    braces = "%b{}",
    bracket = "%b()",
    shape = "m%s+%-?%d[ %-%d%.mlb]"
  }) do
    if name == "braces" then
      patterns[name] = get_value and "%{(.-)%}" or pattern
    elseif name == "bracket" then
      patterns[name] = get_value and "%((.+)%)" or pattern
    else
      patterns[name] = "%s*" .. (get_value and "(" .. pattern .. ")" or pattern)
    end
  end
  return patterns
end
local getTagsPatterns
getTagsPatterns = function()
  local tagsPatterns = {
    an = {
      id = "\\an",
      type = "oun",
      style_name = "align",
      default_value = 7
    },
    fn = {
      id = "\\fn",
      type = "font",
      style_name = "fontname",
      default_value = "Arial"
    },
    fs = {
      id = "\\fs",
      type = "unsigned_float",
      style_name = "fontsize",
      default_value = 20,
      transformable = true
    },
    fsp = {
      id = "\\fsp",
      type = "float",
      style_name = "spacing",
      default_value = 0,
      transformable = true
    },
    fscx = {
      id = "\\fscx",
      type = "unsigned_float",
      style_name = "scale_x",
      default_value = 100,
      transformable = true
    },
    fscy = {
      id = "\\fscy",
      type = "unsigned_float",
      style_name = "scale_y",
      default_value = 100,
      transformable = true
    },
    frz = {
      id = "\\frz",
      type = "float",
      style_name = "angle",
      default_value = 0,
      transformable = true
    },
    bord = {
      id = "\\bord",
      type = "unsigned_float",
      style_name = "outline",
      default_value = 2,
      transformable = true
    },
    shad = {
      id = "\\shad",
      type = "unsigned_float",
      style_name = "shadow",
      default_value = 2,
      transformable = true
    },
    alpha = {
      id = "\\alpha",
      type = "hex",
      style_name = "alpha",
      default_value = "&H00&",
      transformable = true
    },
    ["1c"] = {
      id = "\\1c",
      type = "hex",
      style_name = "color1",
      default_value = "&HFFFFFF&",
      transformable = true
    },
    ["2c"] = {
      id = "\\2c",
      type = "hex",
      style_name = "color2",
      default_value = "&HFFFFFF&",
      transformable = true
    },
    ["3c"] = {
      id = "\\3c",
      type = "hex",
      style_name = "color3",
      default_value = "&HFFFFFF&",
      transformable = true
    },
    ["4c"] = {
      id = "\\4c",
      type = "hex",
      style_name = "color4",
      default_value = "&HFFFFFF&",
      transformable = true
    },
    ["1a"] = {
      id = "\\1a",
      type = "hex",
      style_name = "alpha1",
      default_value = "&HFFFFFF&",
      transformable = true
    },
    ["2a"] = {
      id = "\\2a",
      type = "hex",
      style_name = "alpha2",
      default_value = "&HFFFFFF&",
      transformable = true
    },
    ["3a"] = {
      id = "\\3a",
      type = "hex",
      style_name = "alpha3",
      default_value = "&HFFFFFF&",
      transformable = true
    },
    ["4a"] = {
      id = "\\4a",
      type = "hex",
      style_name = "alpha4",
      default_value = "&HFFFFFF&",
      transformable = true
    },
    b = {
      id = "\\b",
      type = "bool",
      style_name = "bold",
      default_value = false
    },
    i = {
      id = "\\i",
      type = "bool",
      style_name = "italic",
      default_value = false
    },
    s = {
      id = "\\s",
      type = "bool",
      style_name = "strikeout",
      default_value = false
    },
    u = {
      id = "\\u",
      type = "bool",
      style_name = "underline",
      default_value = false
    },
    k = {
      id = "\\[kK]^*[fo ]*",
      type = "unsigned_int",
      default_value = 0
    },
    p = {
      id = "\\p",
      type = "oun",
      default_value = 1
    },
    q = {
      id = "\\q",
      type = "zut",
      default_value = 0
    },
    t = {
      id = "\\t",
      type = "bracket"
    },
    pos = {
      id = "\\pos",
      type = "bracket"
    },
    org = {
      id = "\\org",
      type = "bracket"
    },
    move = {
      id = "\\move",
      type = "bracket"
    },
    fad = {
      id = "\\fad",
      type = "bracket"
    },
    fade = {
      id = "\\fade",
      type = "bracket"
    },
    clip = {
      id = "\\clip",
      type = "bracket"
    },
    iclip = {
      id = "\\iclip",
      type = "bracket"
    },
    frx = {
      id = "\\frx",
      type = "float",
      default_value = 0,
      transformable = true
    },
    fry = {
      id = "\\fry",
      type = "float",
      default_value = 0,
      transformable = true
    },
    fax = {
      id = "\\fax",
      type = "float",
      default_value = 0,
      transformable = true
    },
    fay = {
      id = "\\fay",
      type = "float",
      default_value = 0,
      transformable = true
    },
    be = {
      id = "\\be",
      type = "unsigned_float",
      default_value = 0,
      transformable = true
    },
    blur = {
      id = "\\blur",
      type = "unsigned_float",
      default_value = 0,
      transformable = true
    },
    xbord = {
      id = "\\xbord",
      type = "float",
      default_value = 0,
      transformable = true
    },
    ybord = {
      id = "\\ybord",
      type = "float",
      default_value = 0,
      transformable = true
    },
    xshad = {
      id = "\\xshad",
      type = "float",
      default_value = 0,
      transformable = true
    },
    yshad = {
      id = "\\yshad",
      type = "float",
      default_value = 0,
      transformable = true
    }
  }
  for name, info in pairs(tagsPatterns) do
    local id, type
    id, type = info.id, info.type
    info["patterns_none_value"] = id .. AssPatternsNoneValues[type]
    info["patterns_with_value"] = id .. AssPatternsWithValues[type]
  end
  return tagsPatterns
end
AssPatternsNoneValues = getPatterns(false)
AssPatternsWithValues = getPatterns(true)
AssTagsPatterns = getTagsPatterns()
local LAYER
do
  local _class_0
  local _base_0 = {
    version = "1.0.0",
    __find = function(self, pattern, init, plain)
      return self.layer:find(pattern, init, plain)
    end,
    __match = function(self, pattern, init, plain)
      return self.layer:match(pattern, init, plain)
    end,
    __gsub = function(self, pattern, repl, n)
      return self.layer:gsub(pattern, repl, n)
    end,
    __gmatch = function(self, pattern)
      return self.layer:gmatch(pattern)
    end,
    __lmatch = function(self, pattern, value)
      if value == nil then
        do
          local _accum_0 = { }
          local _len_0 = 1
          for v in self:__gmatch(pattern) do
            _accum_0[_len_0] = v
            _len_0 = _len_0 + 1
          end
          value = _accum_0
        end
      end
      return value[#value]
    end,
    contain = function(self, name)
      if self:__match(AssTagsPatterns[name]["patterns_none_value"]) then
        return true
      end
    end,
    getTagValue = function(self, name, info)
      if info == nil then
        info = AssTagsPatterns[name]
      end
      local def_value
      def_value = function(val)
        if name ~= "t" then
          if info["type"] == "bool" then
            return val == "1"
          else
            do
              local n = tonumber(val)
              if n then
                return n
              elseif val:match(",") then
                local _accum_0 = { }
                local _len_0 = 1
                for v in val:gmatch("[^,]+") do
                  _accum_0[_len_0] = tonumber(v)
                  _len_0 = _len_0 + 1
                end
                return _accum_0
              end
            end
          end
          return val
        else
          local s, e, a, transform = val:match("([%.%d]*)%,?([%.%d]*)%,?([%.%d]*)%,?(.+)")
          s = tonumber(s)
          e = tonumber(e)
          a = tonumber(a)
          return {
            s = s,
            e = e,
            a = a,
            transform = transform
          }
        end
      end
      local patterns_none_value, patterns_with_value
      patterns_none_value, patterns_with_value = info.patterns_none_value, info.patterns_with_value
      do
        local tag = name ~= "t" and self:__lmatch(patterns_none_value) or self:__match(patterns_none_value)
        if tag then
          local value = def_value(tag:match(patterns_with_value))
          return value, name, info, tag, self:__find(tag, 1, true)
        end
      end
    end,
    braces = function(self, cmd)
      if cmd == nil then
        cmd = "add"
      end
      if cmd == "add" then
        if not (self:__match("%b{}")) then
          self.layer = "{" .. self.layer .. "}"
        end
      elseif cmd == "rem" then
        if self:__match("%b{}") then
          self.layer = self:__gsub("{(.-)}", "%1")
        end
      else
        error("incompatible command")
      end
      return self
    end,
    animated = function(self, cmd)
      if cmd == nil then
        cmd = "hide"
      end
      if cmd == "hide" then
        self.layer = self:__gsub("\\t%b()", function(t)
          return t:gsub("\\", "\\@")
        end)
      elseif cmd == "unhide" then
        self.layer = self:__gsub("\\@", "\\")
      elseif cmd == "relocate" then
        local move
        move = function(val, new)
          if new == nil then
            new = ""
          end
          val = val:match("%((.+)%)")
          while val do
            local tag = val:gsub("\\t%b()", "")
            val = val:match("\\t%((.+)%)")
            new = new .. "\\t(" .. tostring(tag) .. ")"
          end
          return new
        end
        self.layer = self:__gsub("\\t%b()", function(t)
          return move(t)
        end)
      else
        error("incompatible command")
      end
      return self
    end,
    remove = function(self, ...)
      local _list_0 = {
        ...
      }
      for _index_0 = 1, #_list_0 do
        local t = _list_0[_index_0]
        if type(t) == "table" then
          local a, b, c
          a, b, c = t[1], t[2], t[3]
          self.layer = self:__gsub(AssTagsPatterns[a]["patterns_none_value"], b or "", c)
        elseif type(t) == "string" then
          self.layer = self:__gsub(AssTagsPatterns[t]["patterns_none_value"], "")
        else
          error("incompatible value type")
        end
      end
      return self
    end,
    insert = function(self, ...)
      self:braces("rem")
      local _list_0 = {
        ...
      }
      for _index_0 = 1, #_list_0 do
        local t = _list_0[_index_0]
        if type(t) == "table" then
          local a, b
          a, b = t[1], t[2]
          if a then
            self.layer = b and a .. self.layer or self.layer .. a
          end
        elseif type(t) == "string" then
          self.layer = self.layer .. t
        else
          error("incompatible value type")
        end
      end
      self:braces("add")
      return self
    end,
    insertStyleRef = function(self, styleref, onlyAnimated)
      if onlyAnimated == nil then
        onlyAnimated = true
      end
      for name, info in pairs(AssTagsPatterns) do
        local _continue_0 = false
        repeat
          do
            local style_name = info["style_name"]
            if style_name then
              if not (self:contain(name)) then
                if onlyAnimated then
                  if not (info["transformable"]) then
                    _continue_0 = true
                    break
                  end
                end
                local value = styleref[style_name]
                if info["type"] == "bool" then
                  value = value and "1" or "0"
                end
                self:insert(info["id"] .. value)
              end
            end
          end
          _continue_0 = true
        until true
        if not _continue_0 then
          break
        end
      end
      return self
    end,
    removeStyleRef = function(self, styleref)
      for name, info in pairs(AssTagsPatterns) do
        do
          local style_name = info["style_name"]
          if style_name then
            do
              local value = self:getTagValue(name)
              if value then
                if styleref[style_name] == value then
                  self:remove(name)
                end
              end
            end
          elseif info["transformable"] then
            do
              local value = self:getTagValue(name)
              if value then
                if info["value"] == value or info["default_value"] == value then
                  self:remove(name)
                end
              end
            end
          end
        end
      end
      return self
    end,
    insertPending = function(self, prev, concat)
      if concat == nil then
        concat = { }
      end
      local _list_0 = LAYER(prev):split()
      for _index_0 = 1, #_list_0 do
        local val = _list_0[_index_0]
        local name, info, tag
        name, info, tag = val.name, val.info, val.tag
        if info["transformable"] then
          TABLE(concat):push(tag)
        end
      end
      self:insert({
        table.concat(concat),
        true
      })
      return self
    end,
    removeEquals = function(self, prev)
      local _list_0 = LAYER(prev):split()
      for _index_0 = 1, #_list_0 do
        local val = _list_0[_index_0]
        local name, prev_tag
        name, prev_tag = val.name, val.tag
        local infos = {
          self:getTagValue(name)
        }
        if infos[1] and prev_tag == infos[4] then
          self:remove(name)
        end
      end
      return self
    end,
    replaceCoords = function(self, posVals, orgVals)
      self:braces("rem")
      if self:__match("\\move%b()") then
        if #posVals >= 4 then
          local a, b, c, d, e, f
          a, b, c, d, e, f = posVals[1], posVals[2], posVals[3], posVals[4], posVals[5], posVals[6]
          e = e and "," .. tostring(e) or ""
          f = f and "," .. tostring(f) or ""
          local move = "\\move(" .. tostring(a) .. "," .. tostring(b) .. "," .. tostring(c) .. "," .. tostring(d .. e .. f) .. ")"
          self:remove({
            "move",
            move,
            1
          })
        end
      elseif #posVals == 2 then
        local a, b
        a, b = posVals[1], posVals[2]
        local pos = "\\pos(" .. tostring(a) .. "," .. tostring(b) .. ")"
        if self:__match("\\pos%b()") then
          self:remove({
            "pos",
            pos,
            1
          })
        else
          self:insert({
            pos,
            true
          })
        end
      end
      if orgVals and #orgVals == 2 then
        local a, b
        a, b = orgVals[1], orgVals[2]
        local org = "\\org(" .. tostring(a) .. "," .. tostring(b) .. ")"
        if self:__match("\\org%b()") then
          self:remove({
            "org",
            org,
            1
          })
        else
          self:insert({
            org,
            true
          })
        end
      end
      self:braces("add")
      return self
    end,
    split = function(self, split)
      if split == nil then
        split = { }
      end
      local copy = LAYER(self.layer)
      local push
      push = function(name)
        local value, info, tag, i
        value, name, info, tag, i = copy:getTagValue(name)
        if value then
          return TABLE(split):push({
            name = name,
            info = info,
            tag = tag,
            value = value,
            i = i
          })
        end
      end
      while copy:__match("\\t%b()") do
        push("t")
        copy.layer = copy:__gsub("\\t%b()", "", 1)
      end
      self:animated("hide")
      for name in pairs(AssTagsPatterns) do
        push(name)
      end
      self:animated("unhide")
      split.getTagValue = function(name)
        for _index_0 = 1, #split do
          local val = split[_index_0]
          if val["name"] == name then
            return val
          end
        end
      end
      split.__tostring = function(concat)
        if concat == nil then
          concat = ""
        end
        local _list_0 = self:split()
        for _index_0 = 1, #_list_0 do
          local val = _list_0[_index_0]
          concat = concat .. val["tag"]
        end
        return "{" .. concat .. "}"
      end
      table.sort(split, function(a, b)
        return a.i < b.i
      end)
      return split
    end,
    clear = function(self, styleref)
      self.layer = self:split()["__tostring"]()
      if styleref then
        self:removeStyleRef(styleref)
      end
      return self
    end,
    __tostring = function(self)
      return self.layer
    end
  }
  _base_0.__index = _base_0
  _class_0 = setmetatable({
    __init = function(self, layer, last)
      if layer == nil then
        layer = ""
      end
      if last == nil then
        last = true
      end
      self.layer = layer
      self.layer = type(self.layer) == "table" and self.layer["layer"] or self.layer
      do
        local l = last and self:__lmatch("%b{}") or self:__match("%b{}")
        if l then
          self.layer = l
        elseif self.layer == "" then
          self.layer = "{}"
        end
      end
      self.layer = self:__gsub("\\a(" .. tostring(AssPatternsNoneValues["oun"]) .. ")", "\\an%1")
      self.layer = self:__gsub("\\c(" .. tostring(AssPatternsNoneValues["hex"]) .. ")", "\\1c%1")
      self.layer = self:__gsub("\\fr(" .. tostring(AssPatternsNoneValues["float"]) .. ")", "\\frz%1")
      self.layer = self:__gsub("\\fad(" .. tostring(AssPatternsNoneValues["bracket"]) .. ")", "\\fade%1")
      self:animated("relocate")
      local _list_0 = {
        "t",
        "pos",
        "org",
        "move",
        "fad",
        "fade",
        "i?clip"
      }
      for _index_0 = 1, #_list_0 do
        local name = _list_0[_index_0]
        self.layer = self:__gsub("\\" .. tostring(name) .. "%(%s*%)", "")
      end
    end,
    __base = _base_0,
    __name = "LAYER"
  }, {
    __index = _base_0,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  LAYER = _class_0
end
return {
  LAYER = LAYER
}
