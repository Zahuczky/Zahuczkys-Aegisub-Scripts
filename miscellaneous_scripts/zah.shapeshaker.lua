-- Randomizes points of a shape
-- Buncha hardcoded stuff, sharing for the lulz  <-this line was suggested by github copilot, therefore it stays

script_name = "!Zahuczky's ShapeShaker"
script_description = "shakethat"
script_author = "Zahuczky"
script_version = "1.0.0"

require "Yutils"
require "karaskel"

function shakey(sub, sel, act)

    for i=1, #sel do
        line = sub[sel[i]]
        meta, styles = karaskel.collect_head(sub, false)
	 	karaskel.preproc_line(sub, meta, styles, line)
        shape = line.text
        new_shape = Yutils.shape.filter(shape, function(x,y) x=x+math.random(-2,2) y=y+math.random(-2,2) return x,y end)
        aegisub.progress.set((i/#sel)*100)
        aegisub.progress.task(string.format("Fucking with line %d/%d", i, #sel))
        line.text = "{\\an7\\pos(960,1030)\\3c&H000096&\\bord0\\p1\\c&H000096&\\shad0}"..new_shape
        sub[sel[i]] = line
    end

end

aegisub.register_macro(script_name, script_description, shakey)