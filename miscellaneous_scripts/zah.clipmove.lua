--If you have a \move tag and rectangular \clip tag in the same line, running this will make the same movement on the clip.

script_name = "Transform clip from move"
script_description = "Use move tag in the line to transform rect clip"
script_author = "Zahuczky"
script_version = "1.0.0"

function ugoke(sub, sel, act)

    for si,li in ipairs(sel) do
        line = sub[li]

        --parse move from line
        local move = line.text:match("\\move%(([^%)]+)%)")
        if move then
            x1, y1, x2, y2, t1, t2 = move:match("(-?[0-9.]+),+(-?[0-9.]+),+(-?[0-9.]+),+(-?[0-9.]+),+(-?[0-9.]+),+(-?[0-9.]+)")
            x1 = tonumber(x1)
            y1 = tonumber(y1)
            x2 = tonumber(x2)
            y2 = tonumber(y2)
            t1 = tonumber(t1)
            t2 = tonumber(t2)
        else
            aegisub.log("No move tag found in line.")
            aegisub.cancel()
        end
            

        --parse rectangular clip from line
        local clip = line.text:match("\\clip%(([^%)]+)%)")
        if clip then
            x1c, y1c, x2c, y2c = clip:match("(-?[0-9.]+),+(-?[0-9.]+),+(-?[0-9.]+),+(-?[0-9.]+)")
            x1c = tonumber(x1c)
            y1c = tonumber(y1c)
            x2c = tonumber(x2c)
            y2c = tonumber(y2c)
        else
            aegisub.log("No rectangular clip found in line.")
            aegisub.cancel()
        end
        
        local xmove = x2 - x1
        local ymove = y2 - y1

        local transform = "\\t(" .. t1 .. "," .. t2 .. ",\\clip(" .. x1c + xmove .. "," .. y1c + ymove .. "," .. x2c + xmove .. "," .. y2c + ymove .. "))"
        line.text = line.text:gsub("(\\clip%(([^%)]+)%))", "%1"..transform) 

        sub[li] = line
    end

end

aegisub.register_macro(script_name, script_description, ugoke)