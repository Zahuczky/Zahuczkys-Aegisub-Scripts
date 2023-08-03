script_name="AutoClip"
script_description="Add clips automagically"
script_author="Zahuczky"
script_version="1.0.0"

petzku = require 'petzku.util'
ILL = require("ILL.ILL")
Ass = ILL.Ass
Line = ILL.Line

function file_exists(name)
    local f=io.open(name,"r")
    if f~=nil then io.close(f) return true else return false end
 end

function autoclip(sub, sel, act)
    ps = petzku.io.pathsep

    videoPos = aegisub.project_properties().video_position

    initline = sub[sel[1]]

    start_time = initline.start_time
    start_frame = tostring(aegisub.frame_from_ms(start_time))
    end_time = initline.end_time
    end_frame = tostring(aegisub.frame_from_ms(end_time))

    active_frame = videoPos - start_frame


    clipmatch = "\\clip%(([%d.]+)%s*,%s*([%d.]+)%s*,%s*([%d.]+)%s*,%s*([%d.]+)%)"

    if initline.text:match(clipmatch) ~= nil then
        x1, y1, x2, y2 = initline.text:match(clipmatch)
    else
        aegisub.debug.out("No rectangular clip was found in your line!")
        aegisub.cancel()
    end

    initline.text = initline.text:gsub(clipmatch, "")
    sub[sel[1]] = initline

    clipstr = tostring(x1.." "..y1.." "..x2.." "..y2)

    video_path = aegisub.project_properties().video_file

    args = string.format("-i \"%s\" -f \"%s\" -l \"%s\" -c \"%s\" -a \"%s\"", video_path, start_frame, end_frame, clipstr, active_frame)


    pyscript = aegisub.decode_path("?user")..ps.."automation"..ps.."include"..ps.."zah"..ps.."autoclip"..ps.."autoclip.vpy "..args

    petzku.io.run_cmd("python "..pyscript, true)

    clipfile = aegisub.decode_path("?temp")..ps.."zahuczky"..ps.."autoclip.txt"

    if file_exists(clipfile) == false then
        aegisub.debug.out("Something wen horribly wrong, and I have no idea exactly where.")
        aegisub.cancel()
    end

    -- open a file for reading
    file = io.open(clipfile, "r")
    -- put every line from the text file into a table
    filelines = {}
    for line in file:lines() do 
        table.insert(filelines, line)
    end
    -- close the file
    file:close()

    ass = Ass(sub, sel, act)
    for line, s, i, n in ass:iterSel(false) do
        ass:removeLine(line, s)

        Line.process(ass, line)
        Line.callBackFBF(ass, line, function(line, i, end_frame)
            ass:insertLine(line, s) end)
        end
    sel = ass:getNewSelection()


    -- loop all the lines in the subtitle file and put the element from the filelines table into the line.
    for i = 1, #filelines do
        if filelines[i] ~= "empty" then
            fline = sub[sel[i]]
            -- replace the first { character with the filelines[i]
            fline.text = fline.text:gsub("{", "{"..filelines[i], 1)
            sub[sel[i]] = fline
        end
    end

    return ass:getNewSelection()
end

aegisub.register_macro("AutoClip",script_description,autoclip)