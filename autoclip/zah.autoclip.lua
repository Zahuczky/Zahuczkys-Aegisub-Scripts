script_name = "AutoClip"
script_description = "Add clips to subtitles 𝓪𝓾𝓽𝓸𝓶𝓪𝓰𝓲𝓬𝓪𝓵𝓵𝔂"
script_version = "1.0.7"
script_author = "Zahuczky"
script_namespace = "zah.autoclip"
-- Even when this file doesn't change, version numbering is kept consistent with the python script.

local hasDepCtrl, DepCtrl = pcall(require, "l0.DependencyControl")
local ILL
local lfs
local Aegi
local Ass
local Line
if hasDepCtrl then
    DepCtrl = DepCtrl({
        name = script_name,
        description = script_description,
        version = script_version,
        author = script_author,
        moduleName = script_namespace,
        url = "https://github.com/Zahuczky/Zahuczkys-Aegisub-Scripts",
        feed = "https://raw.githubusercontent.com/Zahuczky/Zahuczkys-Aegisub-Scripts/main/DependencyControl.json",
        {
            { "ILL.ILL" }
        }
    })
    ILL = DepCtrl:requireModules()
    Aegi = ILL.Aegi
    Ass = ILL.Ass
    Line = ILL.Line
else
    ILL = require("ILL.ILL")
    Aegi = ILL.Aegi
    Ass = ILL.Ass
    Line = ILL.Line
end

local function autoclip(sub, sel, act)
    local ass = Ass(sub, sel, act)

    local project_props = aegisub.project_properties()
    local video_file = project_props.video_file
    local output_file = aegisub.decode_path("?temp/zah.autoclip" .. string.sub(tostring(math.random()), 2))

    -- Grab frame and clip information and check frame continuity across subtitle lines
    Aegi.progressTitle("Gathering frame information")
    local active = project_props.video_position
    local first
    local last
    local active_clip
    local clip
    for line, s, i, n in ass:iterSel(false) do
        ass:progressLine(s, i, n)

        if not first then
            first = aegisub.frame_from_ms(line.start_time)
            last = aegisub.frame_from_ms(line.end_time)
        else
            if aegisub.frame_from_ms(line.start_time) ~= last then
                aegisub.debug.out("[zah.autoclip] Selected lines must be time continuous.\n")
                aegisub.debug.out("[zah.autoclip] The starting time of line " .. tostring(s) .. " does not match the ending time of previous line.\n")
                aegisub.cancel()
            end
            last = aegisub.frame_from_ms(line.end_time)
        end

        -- Get active_clip if the line is act
        if ass:lineNumber(s) == act then
            Line.process(ass, line)
            if type(line.data["clip"]) == "table" then
                active_clip = line.data["clip"]
        end end

        -- Get clip from line if active_clip is not set
        if clip == nil then
            if active_clip == nil then
                Line.process(ass, line)
                if type(line.data["clip"]) == "table" then
                    clip = line.data["clip"]
            end end
        else
            Line.process(ass, line)
            if type(line.data["clip"]) == "table" then
                -- There must be exactly one unique clip in the selected lines
                if not (line.data["clip"][1] == clip[1] and
                        line.data["clip"][2] == clip[2] and
                        line.data["clip"][3] == clip[3] and
                        line.data["clip"][4] == clip[4]) then
                    clip = false
    end end end end

    -- Check active_clip and set to clip
    if active_clip then
        clip = active_clip
    else
        if clip == nil then
            aegisub.debug.out("[zah.autoclip] No rect clips found in selected lines.\n")
            aegisub.debug.out("[zah.autoclip] AutoClip requires a rect clip to be set for the area it is active. This could be in active line or any selected lines.\n")
            aegisub.cancel()
        elseif clip == false then
            aegisub.debug.out("[zah.autoclip] No rect clip found in active line, and there are multiple different rect clips found on selected line.\n")
            aegisub.debug.out("[zah.autoclip] AutoClip requires a rect clip to be set for the area it is active.\n")
            aegisub.cancel()
        end
    end

    -- Run commands
    Aegi.progressTitle("Waiting for Python to complete")
    local command = "python3 -m ass_autoclip --input \"" .. video_file .. "\"" ..
                                           " --output \"" .. output_file .. "\"" ..
                             string.format(" --clip \"%f %f %f %f\"", clip[1], clip[2], clip[3], clip[4]) ..
                                           " --first " .. first ..
                                           " --last " .. last ..
                                           " --active " .. active
    local code = os.execute(command)
    if not (code == 0 or code == true) then
        if code then
            aegisub.debug.out("[zah.autoclip] Python returns with code " .. tostring(code) .. ".\n")
        else
            aegisub.debug.out("[zah.autoclip] Error occurs when executing command:\n")
        end
        aegisub.debug.out("[zah.autoclip] " .. command .. "\n")
        aegisub.debug.out("[zah.autoclip] Attempting to continue.\n")
    end

    Aegi.progressTitle("Applying clips")
    -- Open output file
    local f, error = io.open(output_file, "r")
    if not f then
        aegisub.debug.out("[zah.autoclip] Failed to open output file:\n")
        aegisub.debug.out("[zah.autoclip] " .. error .. "\n")
        aegisub.cancel()
    end

    for line, s, i, n in ass:iterSel(false) do
        ass:progressLine(s, i, n)

        ass:removeLine(line, s)
        Line.process(ass, line)
        line.text.tagsBlocks[1]:remove("clip")

        Line.callBackFBF(ass, line, function(line_, i_, end_frame)
            line_.text.tagsBlocks[1]:insert(f:read("*l"))
            ass:insertLine(line_, s) end)
    end

    return ass:getNewSelection()
end

if hasDepCtrl then
    DepCtrl:registerMacro(autoclip)
else
    aegisub.register_macro("AutoClip", script_description, autoclip)
end
