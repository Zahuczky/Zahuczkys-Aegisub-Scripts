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
local CPP, has_loaded, version
do
  local _obj_0 = require("ZPCP.polyclipping")
  CPP, has_loaded, version = _obj_0.CPP, _obj_0.has_loaded, _obj_0.version
end
local POINT
POINT = require("ZF.2D.point").POINT
local SEGMENT
SEGMENT = require("ZF.2D.segment").SEGMENT
local PATH
PATH = require("ZF.2D.path").PATH
local SHAPE
SHAPE = require("ZF.2D.shape").SHAPE
local CLIPPER
do
  local _class_0
  local _base_0 = {
    version = "1.0.3",
    simplify = function(self, ft)
      self.sbj = self.sbj:simplify(ft)
      return self
    end,
    clipper = function(self, ct, ft)
      if ct == nil then
        ct = "intersection"
      end
      if ft == nil then
        ft = "even_odd"
      end
      assert(self.clp, "expected clip")
      local c = CPP.clipper.new()
      c:add_paths(self.sbj, "subject")
      c:add_paths(self.clp, "clip")
      self.sbj = c:execute(ct, ft)
      return self
    end,
    offset = function(self, size, jt, et, mtl, act)
      if jt == nil then
        jt = "round"
      end
      if et == nil then
        et = "closed_polygon"
      end
      if mtl == nil then
        mtl = 2
      end
      if act == nil then
        act = 0.25
      end
      jt = jt:lower()
      local o = CPP.offset.new(mtl, act)
      self.sbj = o:paths(self.sbj, size, jt, et)
      return self
    end,
    toStroke = function(self, size, jt, mode, mtl, act)
      if jt == nil then
        jt = "round"
      end
      if mode == nil then
        mode = "center"
      end
      assert(size >= 0, "The size must be positive")
      mode = mode:lower()
      size = mode == "inside" and -size or size
      local fill = CLIPPER((mode ~= "center" and self:simplify() or self):build())
      local offs = CLIPPER(self:offset(size, jt, mode == "center" and "closed_line" or nil, mtl, act):build())
      local _exp_0 = mode
      if "outside" == _exp_0 then
        self.sbj = offs.sbj
        self.clp = fill.sbj
        return self:clip(true), fill
      elseif "inside" == _exp_0 then
        self.sbj = fill.sbj
        self.clp = offs.sbj
        return self:clip(true), offs
      elseif "center" == _exp_0 then
        self.sbj = fill.sbj
        self.clp = offs.sbj
        return offs, self:clip(true)
      end
    end,
    clip = function(self, iclip)
      return iclip and self:clipper("difference") or self:clipper("intersection")
    end,
    build = function(self, simplifyType, precision, decs)
      if precision == nil then
        precision = 1
      end
      if decs == nil then
        decs = 3
      end
      local new, rsc = SHAPE(), CPP.RESCALE_POINT_SIZE
      for i = 1, self.sbj:len() do
        local path = self.sbj:get(i)
        new.paths[i] = PATH()
        for j = 2, path:len() do
          local prevPoint = path:get(j - 1)
          local currPoint = path:get(j - 0)
          local p, c = POINT(), POINT()
          p.x = tonumber(prevPoint.X) * rsc
          p.y = tonumber(prevPoint.Y) * rsc
          c.x = tonumber(currPoint.X) * rsc
          c.y = tonumber(currPoint.Y) * rsc
          new.paths[i]:push(SEGMENT(p, c))
        end
        if simplifyType then
          new.paths[i] = new.paths[i]:simplify(simplifyType, precision, precision * 3)
        end
      end
      return new:build(decs)
    end
  }
  _base_0.__index = _base_0
  _class_0 = setmetatable({
    __init = function(self, subj, clip, close)
      if close == nil then
        close = false
      end
      if not (has_loaded) then
        libError("libpolyclipping")
      end
      assert(subj, "subject expected")
      subj = SHAPE(subj, close):flatten(nil, nil, 1, "b")
      clip = clip and SHAPE(clip, close):flatten(nil, nil, 1, "b") or nil
      local scale = CPP.SCALE_POINT_SIZE
      local createPaths
      createPaths = function(paths)
        local createPath
        createPath = function(path)
          local newPath = CPP.path.new()
          if path[1] then
            local a, b
            do
              local _obj_0 = path[1]["segment"]
              a, b = _obj_0[1], _obj_0[2]
            end
            newPath:add(a.x * scale, a.y * scale)
            newPath:add(b.x * scale, b.y * scale)
          end
          for i = 2, #path do
            local c = path[i]["segment"][2]
            newPath:add(c.x * scale, c.y * scale)
          end
          return newPath
        end
        local newPaths = CPP.paths.new()
        for _index_0 = 1, #paths do
          local p = paths[_index_0]
          newPaths:add(createPath(p.path))
        end
        return newPaths
      end
      self.cls = close
      self.sbj = createPaths(subj.paths)
      self.clp = clip and createPaths(clip.paths) or nil
    end,
    __base = _base_0,
    __name = "CLIPPER"
  }, {
    __index = _base_0,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  CLIPPER = _class_0
end
return {
  CLIPPER = CLIPPER
}
