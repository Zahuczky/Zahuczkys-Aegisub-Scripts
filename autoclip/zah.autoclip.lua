script_name = "AutoClip"
script_description = "Add clips to subtitles 𝓪𝓾𝓽𝓸𝓶𝓪𝓰𝓲𝓬𝓪𝓵𝓵𝔂"
script_version = "1.0.7"
script_author = "Zahuczky"
script_namespace = "zah.autoclip"
-- Even when this file doesn't change, version numbering is kept consistent with the python script.

local hasDepCtrl, DepCtrl = pcall(require, "l0.DependencyControl")
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
            { "ILL.ILL" },
            { "aka.config" },
            { "aka.outcome" }
        }
    })
    DepCtrl:requireModules()
end
local ILL = require("ILL.ILL")
local Aegi, Ass, Line = ILL.Aegi, ILL.Ass, ILL.Line

local aconfig = require("aka.config").make_editor({
    display_name = "AutoClip",
    presets = {
        ["default"] = { ["python"] = "python3" }
    },
    default = "default"
})
local outcome = require("aka.outcome")
local ok, err = outcome.ok, outcome.err
local validation_func = function(config)
    if type(config) == "table" and type(config["python"]) == "string" then
        return ok(config)
    else
        return err("Key \"python\" is missing.")
end end

local config
local function autoclip(sub, sel, act)
    if not config then
        config = aconfig:read_and_validate_config_if_empty_then_default_or_else_edit_and_save("zah.autoclip", validation_func)
            :ifErr(aegisub.cancel)
            :unwrap()
    end

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
    local command = " -m ass_autoclip --input '" .. video_file .. "'" ..
                                    " --output '" .. output_file .. "'" ..
                      string.format(" --clip '%f %f %f %f'", clip[1], clip[2], clip[3], clip[4]) ..
                                    " --first " .. first ..
                                    " --last " .. last ..
                                    " --active " .. active
    if jit.os == "Windows" then
        command = "powershell -Command \"& '" .. config["python"] .. "'" .. command .. "\""
    else
        command = "'" .. config["python"] .. "'" .. command
    end
    local status, terminate, code = os.execute(command)
    if not status then
        if terminate == "exit" then
            aegisub.debug.out("[zah.autoclip] Python exists with code " .. tostring(code) .. ".\n")
        else
            aegisub.debug.out("[zah.autoclip] Python terminated with signal " .. tostring(code) .. ".\n")
        end
        aegisub.debug.out("[zah.autoclip] " .. command .. "\n")
        aegisub.debug.out("[zah.autoclip] Attempting to continue.\n")
    end

    Aegi.progressTitle("Seting clips")
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

local function edit_config()
    if not config then
        config = aconfig:read_and_validate_config_if_empty_then_default_or_else_edit_and_save("zah.autoclip", validation_func)
            :ifErr(aegisub.cancel)
            :unwrap()
    end

    local dialog = { { class = "label",                     x = 0, y = 0, width = 30,
                                                            label = "Enter path to your Python executable:" },
                     { class = "edit", name = "python",     x = 0, y = 1, width = 30,
                                                            text = config["python"] } }
    local buttons = { "&Set", "Close" }
    local button_ids = { ok = "&Set", yes = "&Set", save = "&Set", apply = "&Set", close = "Close", no = "Close", cancel = "Close" }

    local button, result_table = aegisub.dialog.display(dialog, buttons, button_ids)

    if button == false or button == "Close" then aegisub.cancel()
    elseif button == "&Set" then
        config = result_table
        aconfig.write_config("zah.autoclip", config)
            :ifErr(function()
                aegisub.debug.out("[aka.config] Failed to write config to file.\n")
                aegisub.debug.out("[aka.config] " .. error .. "\n")
                aegisub.cancel() end)
end end

if hasDepCtrl then
    DepCtrl:registerMacros({
        { "AutoClip", script_description, autoclip },
        { "Configure python path", "Configure python path", edit_config }
    })
else
    aegisub.register_macro("AutoClip/AutoClip", script_description, autoclip)
    aegisub.register_macro("AutoClip/Configure python path", "Configure python path", edit_config)
end
