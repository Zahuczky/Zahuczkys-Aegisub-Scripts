-- Adds or subtracts 0.1 from the blur value of the selected line
-- Intended use is with a keyboard dial that you set to execute this script in aegisub. 

script_name="DialBlur"
script_description="Set blur with keyboard Dial"
script_author="Zahuczky"
script_version="1.0"


function dialblurplus(sub, sel)
    line = sub[sel[1]]
    bluramount = string.match(line.raw, "blur+(-?[0-9.]+)")
    bluramount = bluramount + 0.1
    line.text = string.gsub(line.text, "blur+(-?[0-9.]+)", "blur"..bluramount)
    sub[sel[1]] = line

end

function dialblurminus(sub, sel)
    line = sub[sel[1]]
    bluramount = string.match(line.raw, "blur+(-?[0-9.]+)")
    bluramount = bluramount - 0.1
    line.text = string.gsub(line.text, "blur+(-?[0-9.]+)", "blur"..bluramount)
    sub[sel[1]] = line

end

aegisub.register_macro("DialBlur/Plus",script_description,dialblurplus)
aegisub.register_macro("DialBlur/Minus",script_description,dialblurminus)