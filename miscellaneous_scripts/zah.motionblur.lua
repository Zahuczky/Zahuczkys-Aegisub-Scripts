-- Calculates motion blur for tracked lines.
-- It expects a base amount of blur to be already set in all lines.
-- Intensity is used for the amount of blur ADDED to what's already in the line.
-- Blur will equal the base amount plus the distance traveled by the line from the previous frame divided by 100, times the intensity. 
-- (generally try something in the 5-10 range)

script_name="Motion blur"
script_description="Add motion blur to tracked lines"
script_author="Zahuczky"
script_version="1.0"

function motionblur(sub, sel)

    GUI = {
        {class= "label",  x= 0, y= 0, width= 1, height= 1, label= "Intensity:"},
        {class= "intedit", name="intensity",  x= 0, y= 1, width= 2, height= 1, value=1}
    }

    buttons = {"Go","Cancel"}

    btn, res = aegisub.dialog.display(GUI, buttons)
    if btn == "Cancel" then aegisub.cancel() end

    lines = {}
    blur = {}
    move = {}
    for i=1, #sel do
        lines[i] = sub[sel[i]]
        local line = lines[i]
        local text = line.text
        blur[i] = text:match("\\blur(%d+%.?%d*)")
        if i == 1 then
            move[i] = 0
        else
            local x1 = tonumber(text:match("\\pos%((%d+%.?%d*),"))
            local y1 = tonumber(text:match("\\pos%(%d+%.?%d*,(%d+%.?%d*)%)"))
            local x2 = tonumber(lines[i-1].text:match("\\pos%((%d+%.?%d*),"))
            local y2 = tonumber(lines[i-1].text:match("\\pos%(%d+%.?%d*,(%d+%.?%d*)%)"))
            move[i] = math.sqrt((x1-x2)^2+(y1-y2)^2)
        end
    end

    intens = tonumber(res["intensity"])
    for i=1, #lines do
        local line = lines[i]
        local text = line.text
        if i == 1 then
            blur[i] = blur[i]
        else
            blur[i] = tonumber(blur[i]) + ((tonumber(move[i]/100))*intens)
        end
        text = text:gsub("\\blur(%d+%.?%d*)", "\\blur"..blur[i])
        line.text = text
        sub[sel[i]] = line
    end

end


aegisub.register_macro("Motion blur",script_description,motionblur)