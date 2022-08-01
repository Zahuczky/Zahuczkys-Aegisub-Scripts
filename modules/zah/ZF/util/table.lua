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
do
  local _class_0
  local _base_0 = {
    version = "1.0.0",
    arithmeticOp = function(self, fn, operation)
      if fn == nil then
        fn = (function(v)
          return v
        end)
      end
      if operation == nil then
        operation = "+"
      end
      local result = 0
      for k, v in ipairs(self.t) do
        local _exp_0 = operation
        if "+" == _exp_0 or "sum" == _exp_0 then
          result = result + fn(v)
        elseif "-" == _exp_0 or "sub" == _exp_0 then
          result = result - fn(v)
        elseif "*" == _exp_0 or "mul" == _exp_0 then
          result = result * fn(v)
        elseif "/" == _exp_0 or "div" == _exp_0 then
          result = result / fn(v)
        elseif "%" == _exp_0 or "rem" == _exp_0 then
          result = result % fn(v)
        elseif "^" == _exp_0 or "exp" == _exp_0 then
          result = result ^ fn(v)
        end
      end
      return result
    end,
    clean = function(self)
      local f, n = { }, { }
      for k, v in pairs(self.t) do
        if type(v) == "table" then
          TABLE(n):push(TABLE(v):clean(v))
        else
          if not (f[v]) then
            TABLE(n):push(v)
            f[v] = 0
          end
        end
      end
      return n
    end,
    shallowcopy = function(self)
      local shallowcopy
      shallowcopy = function(t)
        local copy = { }
        if type(t) == "table" then
          for key, value in pairs(t) do
            copy[key] = value
          end
        else
          copy = t
        end
        return copy
      end
      return shallowcopy(self.t)
    end,
    deepcopy = function(self)
      local deepcopy
      deepcopy = function(t, copies)
        if copies == nil then
          copies = { }
        end
        local copy = { }
        if type(t) == "table" then
          if copies[t] then
            copy = copies[t]
          else
            copies[t] = copy
            for key, value in next,t,nil do
              copy[deepcopy(key, copies)] = deepcopy(value, copies)
            end
            setmetatable(copy, deepcopy(getmetatable(t), copies))
          end
        else
          copy = t
        end
        return copy
      end
      return deepcopy(self.t)
    end,
    copy = function(self, deepcopy)
      if deepcopy == nil then
        deepcopy = true
      end
      return deepcopy and self:deepcopy() or self:shallowcopy()
    end,
    concat = function(self, ...)
      local t = self:copy()
      local _list_0 = {
        ...
      }
      for _index_0 = 1, #_list_0 do
        local val = _list_0[_index_0]
        if type(val) == "table" then
          for k, v in pairs(val) do
            if type(k) == "number" then
              TABLE(t):push(v)
            end
          end
        else
          TABLE(t):push(val)
        end
      end
      return t
    end,
    map = function(self, fn)
      local _tbl_0 = { }
      for k, v in pairs(self.t) do
        _tbl_0[k] = fn(v, k, self.t)
      end
      return _tbl_0
    end,
    pop = function(self)
      return table.remove(self.t)
    end,
    push = function(self, ...)
      local arguments, insert = {
        ...
      }, table.insert
      for i = 1, #arguments do
        insert(self.t, arguments[i])
      end
      return #arguments
    end,
    reduce = function(self, fn, ...)
      local arguments, init, len, acc = {
        ...
      }, 1, #self.t, nil
      if #arguments ~= 0 then
        acc = arguments[1]
      elseif len > 0 then
        init, acc = 2, self.t[1]
      end
      for i = init, len do
        acc = fn(acc, self.t[i], i, self.t)
      end
      return acc
    end,
    reverse = function(self)
      local _accum_0 = { }
      local _len_0 = 1
      for i = 1, #self.t do
        _accum_0[_len_0] = self.t[#self.t + 1 - i]
        _len_0 = _len_0 + 1
      end
      return _accum_0
    end,
    slice = function(self, f, l, s)
      local _accum_0 = { }
      local _len_0 = 1
      for i = f or 1, l or #self.t, s or 1 do
        _accum_0[_len_0] = self.t[i]
        _len_0 = _len_0 + 1
      end
      return _accum_0
    end,
    splice = function(self, start, delete, ...)
      local arguments, removes, t_len = {
        ...
      }, { }, #self.t
      local n_args, i_args = #arguments, 1
      start = start < 1 and 1 or start
      delete = delete < 0 and 0 or delete
      if start > t_len then
        start = t_len + 1
        delete = 0
      end
      delete = start + delete - 1 > t_len and t_len - start + 1 or delete
      for pos = start, start + math.min(delete, n_args) - 1 do
        TABLE(removes):push(self.t[pos])
        self.t[pos] = arguments[i_args]
        i_args = i_args + 1
      end
      i_args = i_args - 1
      for i = 1, delete - n_args do
        TABLE(removes):push(table.remove(self.t, start + i_args))
      end
      for i = n_args - delete, 1, -1 do
        self:push(start + delete, arguments[i_args + i])
      end
      return removes
    end,
    shift = function(self)
      return table.remove(self.t, 1)
    end,
    unshift = function(self, ...)
      local arguments = {
        ...
      }
      for k = #arguments, 1, -1 do
        table.insert(self.t, 1, arguments[k])
      end
      return #self.t
    end,
    isEmpty = function(self)
      return next(self.t) == nil
    end,
    view = function(self, table_name, indent)
      if table_name == nil then
        table_name = "table_unnamed"
      end
      if indent == nil then
        indent = ""
      end
      local cart, autoref = "", ""
      local basicSerialize
      basicSerialize = function(o)
        local so = tostring(o)
        if type(o) == "function" then
          local info = debug.getinfo(o, "S")
          if info.what == "C" then
            return format("%q", so .. ", C function")
          end
          format("%q, defined in (lines: %s - %s), ubication %s", so, info.linedefined, info.lastlinedefined, info.source)
        elseif (type(o) == "number") or (type(o) == "boolean") then
          return so
        end
        return format("%q", so)
      end
      local addtocart
      addtocart = function(value, table_name, indent, saved, field)
        if saved == nil then
          saved = { }
        end
        if field == nil then
          field = table_name
        end
        cart = cart .. (indent .. field)
        if type(value) ~= "table" then
          cart = cart .. (" = " .. basicSerialize(value) .. ";\n")
        else
          if saved[value] then
            cart = cart .. " = {}; -- " .. tostring(saved[value]) .. "(self reference)\n"
            autoref = autoref .. tostring(table_name) .. " = " .. tostring(saved[value]) .. ";\n"
          else
            saved[value] = table_name
            if TABLE(value):isEmpty() then
              cart = cart .. " = {};\n"
            else
              cart = cart .. " = {\n"
              for k, v in pairs(value) do
                k = basicSerialize(k)
                local fname = tostring(table_name) .. "[ " .. tostring(k) .. " ]"
                field = "[ " .. tostring(k) .. " ]"
                addtocart(v, fname, indent .. "	", saved, field)
              end
              cart = tostring(cart) .. tostring(indent) .. "};\n"
            end
          end
        end
      end
      if type(self.t) ~= "table" then
        return tostring(table_name) .. " = " .. tostring(basicSerialize(self.t))
      end
      addtocart(self.t, table_name, indent)
      return cart .. autoref
    end
  }
  _base_0.__index = _base_0
  _class_0 = setmetatable({
    __init = function(self, t)
      if t == nil then
        t = t
      end
      self.t = t
    end,
    __base = _base_0,
    __name = "TABLE"
  }, {
    __index = _base_0,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  TABLE = _class_0
end
return {
  TABLE = TABLE
}
