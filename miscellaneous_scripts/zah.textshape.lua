-- Quickly turn a text into a shape
-- Bunch of hardcoded stuff, sharing for the lulz

script_name = "!Zahuczky's t2s"
script_description = "t2s"
script_author = "Zahuczky"
script_version = "1.0.0"

require "Yutils"
require "karaskel"

function texttoshapee(sub, sel, act)
    for i=1, #sel do
        line=sub[sel[i]]
        FONT_HANDLE = Yutils.decode.create_font("FOT-NewRodin Pro UB", false, false, false, false, 100)
        meta, styles = karaskel.collect_head(sub, false)
	 	karaskel.preproc_line(sub, meta, styles, line)
        shape = FONT_HANDLE.text_to_shape(line.text_stripped)
        line.text=line.text..shape
        sub[sel[i]] = line
    end
end

aegisub.register_macro(script_name, script_description, texttoshapee)