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
local CONFIG
do
  local _class_0
  local _base_0 = {
    version = "1.0.2",
    fileExist = function(self, dir, isDir)
      local a = dir:sub(1, 1)
      local b = dir:sub(-1, -1)
      local c = "\""
      if a == c and b == c then
        dir = dir:sub(2, -2)
      end
      if isDir then
        dir = dir .. "/"
      end
      local ok, err, code = os.rename(dir, dir)
      if not (ok) then
        if code == 13 then
          return true
        end
      end
      return ok, err
    end,
    mkdir = function(self, dir)
      assert(dir, "expected dir")
      if not (self:fileExist(dir, true)) then
        return os.execute("mkdir " .. tostring(dir))
      end
    end,
    rmdir = function(self, dir)
      assert(dir, "expected dir")
      if self:fileExist(dir, true) then
        return os.execute("rd /s /q " .. tostring(dir))
      end
    end,
    aegiPath = function(self, code)
      if code == nil then
        code = "?user"
      end
      self.path = aegisub.decode_path(code)
    end,
    writeGui = function(self, dir, gui)
      local write
      write = function(content)
        local written = ""
        for name, value in pairs(content) do
          written = written .. tostring(name) .. ":" .. tostring(value) .. "|"
        end
        written = written:sub(1, -2)
        return written
      end
      local written = type(gui) ~= "table" and "" or write(gui)
      local file = io.open(dir, "w")
      file:write(written)
      file:close()
      return written
    end,
    readGui = function(self, dir)
      local split
      split = function(content)
        local result, values = { }, UTIL:headsTails(content, "|")
        for _, value in ipairs(values) do
          local set = UTIL:headsTails(value, ":")
          local conc = table.concat(set, "", 2)
          conc = conc == "true" and true or (tonumber(conc) and tonumber(conc) or conc)
          result[set[1]] = conc
        end
        return result
      end
      do
        local arq = io.open(dir, "r")
        if arq then
          local read = arq:read("*a")
          arq:close()
          return split(read)
        end
      end
    end,
    loadGui = function(self, gui, macro_name)
      self:aegiPath()
      macro_name = macro_name:lower()
      local dir, new, read = tostring(self.path) .. "\\zeref-cfg\\" .. tostring(macro_name:gsub("%s", "_")) .. ".config", TABLE(gui):copy()
      do
        read = self:readGui(dir)
        if read then
          for k, v in ipairs(new) do
            if v.name then
              v.value = read[v.name]
            end
          end
        end
      end
      return new, read
    end,
    saveGui = function(self, gui, macro_name)
      self:aegiPath()
      local dir = tostring(self.path) .. "\\zeref-cfg"
      self:mkdir("\"" .. tostring(dir) .. "\"")
      return self:writeGui(tostring(dir) .. "\\" .. tostring(macro_name:lower():gsub("%s", "_")) .. ".config", gui)
    end
  }
  _base_0.__index = _base_0
  _class_0 = setmetatable({
    __init = function() end,
    __base = _base_0,
    __name = "CONFIG"
  }, {
    __index = _base_0,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  CONFIG = _class_0
end
return {
  CONFIG = CONFIG
}
