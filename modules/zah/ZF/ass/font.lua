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
local FONT
do
  local _class_0
  local _base_0 = {
    version = "1.0.0",
    metrics = function(self)
      return self.f.metrics()
    end,
    extents = function(self, text)
      return self.f.text_extents(text)
    end,
    shape = function(self, text)
      return self.f.text_to_shape(text):gsub(" c", "")
    end,
    get = function(self, text)
      local metrics = self:metrics(text)
      local extents = self:extents(text)
      local shape = self:shape(text)
      return {
        shape = shape,
        width = tonumber(extents.width),
        height = tonumber(extents.height),
        ascent = tonumber(metrics.ascent),
        descent = tonumber(metrics.descent),
        internal_leading = tonumber(metrics.internal_leading),
        external_leading = tonumber(metrics.external_leading)
      }
    end
  }
  _base_0.__index = _base_0
  _class_0 = setmetatable({
    __init = function(self, styleref)
      if styleref then
        do
          local _with_0 = styleref
          self.f = Yutils.decode.create_font(_with_0.fontname, _with_0.bold, _with_0.italic, _with_0.underline, _with_0.strikeout, _with_0.fontsize, _with_0.scale_x / 100, _with_0.scale_y / 100, _with_0.spacing)
          return _with_0
        end
      else
        return error("missing style values")
      end
    end,
    __base = _base_0,
    __name = "FONT"
  }, {
    __index = _base_0,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  FONT = _class_0
end
return {
  FONT = FONT
}
