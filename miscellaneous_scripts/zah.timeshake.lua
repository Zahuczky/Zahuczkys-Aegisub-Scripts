-- Adds some randomness to the start time of the line
-- Bunch of hardcoded stuff, sharing for the lulz

script_name = "!Zahuczky's Timeshake"
script_description = "timeshake"
script_author = "Zahuczky"
script_version = "1.0.0"

require "Yutils"
require "karaskel"

function shook(sub, sel, act)
    for i=1, #sel do
        line = sub[sel[i]]
        st = line.start_time
        line.start_time = st + math.random(0, 1700)
        sub[sel[i]] = line
    end
end

aegisub.register_macro(script_name, script_description, shook)