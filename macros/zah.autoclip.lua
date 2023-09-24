script_name = "AutoClip"
script_description = "Add clips to subtitles 𝓪𝓾𝓽𝓸𝓶𝓪𝓰𝓲𝓬𝓪𝓵𝓵𝔂"
script_version = "2.0.5"
script_author = "Zahuczky, Akatsumekusa"
script_namespace = "zah.autoclip"
-- Even when this file doesn't change, version numbering is kept consistent with the python script.

local last_supported_script_version = "2.0.3"


local DepCtrl = require("l0.DependencyControl")({
    name = script_name,
    description = script_description,
    version = script_version,
    author = script_author,
    moduleName = script_namespace,
    url = "https://github.com/Zahuczky/Zahuczkys-Aegisub-Scripts",
    feed = "https://raw.githubusercontent.com/Zahuczky/Zahuczkys-Aegisub-Scripts/main/DependencyControl.json",
    {
        {
            "ILL.ILL",
            version = "1.1.0",
            url = "https://github.com/TypesettingTools/ILL-Aegisub-Scripts",
            feed = "https://raw.githubusercontent.com/TypesettingTools/ILL-Aegisub-Scripts/main/DependencyControl.json"
        },
        {
            "aka.config",
            version = "1.0.0",
            url = "https://github.com/Akatmks/Akatsumekusa-Aegisub-Scripts",
            feed = "https://raw.githubusercontent.com/Akatmks/Akatsumekusa-Aegisub-Scripts/master/DependencyControl.json"
        },
        {
            "aka.outcome",
            version = "1.0.0",
            url = "https://github.com/Akatmks/Akatsumekusa-Aegisub-Scripts",
            feed = "https://raw.githubusercontent.com/Akatmks/Akatsumekusa-Aegisub-Scripts/master/DependencyControl.json"
        },
        {
            "petzku.util",
            version = "0.4.0",
            url = "https://github.com/petzku/Aegisub-Scripts",
            feed = "https://raw.githubusercontent.com/petzku/Aegisub-Scripts/master/DependencyControl.json"
        },
        {
            "aka.unsemantic",
            version = "1.0.0",
            url = "https://github.com/Akatmks/Akatsumekusa-Aegisub-Scripts",
            feed = "https://raw.githubusercontent.com/Akatmks/Akatsumekusa-Aegisub-Scripts/master/DependencyControl.json"
        },
        {
            "aegisub.re"
        }
    }
})
DepCtrl:requireModules()

local ILL = require("ILL.ILL")
local Aegi, Ass, Line = ILL.Aegi, ILL.Ass, ILL.Line

local outcome = require("aka.outcome")
local ok, err = outcome.ok, outcome.err

local default_config = {
    ["python"] = "python3",
    ["vsrepo_mode"] = "vsrepo in PATH (`$ vsrepo --help`)",
    ["vsrepo"] = "vsrepo",
    ["disable_layer_mismatch"] = false,
    ["disable_version_notify"] = false
}

local aconfig = require("aka.config").make_editor({
    display_name = "AutoClip",
    presets = {
        ["default"] = default_config
    },
    default = "default"
})
local json = aconfig.json

local validation_func = function(config)
    if type(config) ~= "table" then
        return err("Missing root table.")
    end
    if config["python"] == nil then
        config["python"] = default_config["python"]
    elseif type(config["python"]) ~= "string" then
        return err("Invalid key \"python\".")
    end
    if config["vsrepo_mode"] == nil then
        config["vsrepo_mode"] = default_config["vsrepo_mode"]
    elseif config["vsrepo_mode"] ~= "vsrepo in PATH (`$ vsrepo --help`)" and config["vsrepo_mode"] ~= "Path to vsrepo.py (`$ python vsrepo.py --help`)" then
        return err("Invalid key \"vsrepo_mode\".")
    end
    if config["vsrepo"] == nil then
        config["vsrepo"] = default_config["vsrepo"]
    elseif type(config["vsrepo"]) ~= "string" then
        return err("Invalid key \"vsrepo\".")
    end
    if config["disable_layer_mismatch"] == nil then
        config["disable_layer_mismatch"] = default_config["disable_layer_mismatch"]
    elseif type(config["disable_layer_mismatch"]) ~= "boolean" then
        return err("Invalid key \"disable_layer_mismatch\".")
    end
    if config["disable_version_notify"] == nil then
        config["disable_version_notify"] = default_config["disable_version_notify"]
    elseif type(config["disable_version_notify"]) ~= "boolean" then
        return err("Invalid key \"disable_version_notify\".")
    end
    return ok(config)
end
local config

local V = require("aka.unsemantic").V
local disable_version_notify_until_next_time = false

local re = require("aegisub.re")
local re_newline = re.compile([[\s*(?:\n\s*)+]])

local run_cmd = require("petzku.util").io.run_cmd

local c = function(command)
    if jit.os == "Windows" then
        local i = 1
        for chunks in re_newline:gsplit(command, true) do
            if i == 1 then
                command = "& " .. chunks
            else
                command = command .. " ; if ($LASTEXITCODE -eq 0) {& " .. chunks .. "}"
            end
            i = i + 1
        end
        command = command .. " ; exit $LASTEXITCODE"
        return "powershell -Command \"" .. command .. "\""
    else
        local i = 1
        for chunks in re_newline:gsplit(command, true) do
            if i == 1 then
                command = chunks
            else
                command = command .. " && " .. chunks
            end
            i = i + 1
        end
        return command
end end

local first_time_python_vsrepo
local first_time_python_unix
local first_time_python
local first_time_python_vs_unix
local first_time_vsrepo
local edit_config
local edit_config_unix

local run_command_until

local fisrt_time_dependencies
local first_time_python_dependencies_unix
local first_time_vs_dependencies_unix
local update_vs_dependencies_unix
local no_dependencies
local no_python_dependencies_unix
local no_vs_dependencies_unix
local out_of_date_dependencies
local out_of_date_dependencies_unix
local update_dependencies
local update_dependencies_unix
local unsupported_dependencies
local unsupported_dependencies_unix

first_time_python_vsrepo = function()
    local dialog = {
        { class = "label",                          x = 0, y = 0, width = 25,
                                                    label = "Welcome to AutoClip!" },
        { class = "label",                          x = 0, y = 1, width = 25,
                                                    label = "Enter name to Python if it is in PATH or path to Python executable:" },
        { class = "edit", name = "python",          x = 0, y = 2, width = 25,
                                                    text = config["python"] },
        { class = "label",                          x = 0, y = 3, width = 25,
                                                    label = "Select whether vsrepo is in PATH and enter either the name to vsrepo or path to vsrepo.py:" },
        { class = "dropdown", name = "vsrepo_mode", x = 0, y = 4, width = 25,
                                                    items = { "vsrepo in PATH (`$ vsrepo --help`)", "Path to vsrepo.py (`$ python vsrepo.py --help`)" }, value = config["vsrepo_mode"] },
        { class = "edit", name = "vsrepo",          x = 0, y = 5, width = 25,
                                                    text = config["vsrepo"] }
    }
    local buttons = { "&Set", "Cancel" }
    local button_ids = { ok = "&Set", yes = "&Set", save = "&Set", apply = "&Set", close = "Cancel", no = "Cancel", cancel = "Cancel" }

    local button, result_table = aegisub.dialog.display(dialog, buttons, button_ids)

    if button == false or button == "Cancel" then
        return err("[zah.autoclip] Operation cancelled by user")
    elseif button == "&Set" then
        for k, v in pairs(result_table) do
            config[k] = v
        end
        aconfig.write_config("zah.autoclip", config)
            :ifErr(function()
                aegisub.debug.out("[aka.config] Failed to write config to file.\n")
                aegisub.debug.out("[aka.config] " .. error .. "\n") end)

        return ok()
end end

first_time_python_unix = function()
    local dialog = {
        { class = "label",                          x = 0, y = 0, width = 25,
                                                    label = "Welcome to AutoClip!" },
        { class = "label",                          x = 0, y = 1, width = 25,
                                                    label = "Enter name to Python if it is in PATH or path to Python executable:" },
        { class = "edit", name = "python",          x = 0, y = 2, width = 25,
                                                    text = config["python"] }
    }
    local buttons = { "&Set", "Cancel" }
    local button_ids = { ok = "&Set", yes = "&Set", save = "&Set", apply = "&Set", close = "Cancel", no = "Cancel", cancel = "Cancel" }

    local button, result_table = aegisub.dialog.display(dialog, buttons, button_ids)

    if button == false or button == "Cancel" then
        return err("[zah.autoclip] Operation cancelled by user")
    elseif button == "&Set" then
        for k, v in pairs(result_table) do
            config[k] = v
        end
        aconfig.write_config("zah.autoclip", config)
            :ifErr(function()
                aegisub.debug.out("[aka.config] Failed to write config to file.\n")
                aegisub.debug.out("[aka.config] " .. error .. "\n") end)

        return ok()
end end

first_time_python = function()
    local dialog
    local buttons
    local button_ids
    local button
    local result_table
    if os.execute(c("'" .. config["python"] .. "' --version")) then
        return ok("Already satisfied")
    else
        repeat
            dialog = {
                { class = "label",                          x = 0, y = 0, width = 25,
                                                            label = "Unable to find Python with given name or path." },
                { class = "label",                          x = 0, y = 1, width = 25,
                                                            label = "Enter name to Python if it is in PATH or path to Python executable:" },
                { class = "edit", name = "python",          x = 0, y = 2, width = 25,
                                                            text = config["python"] }
            }
            buttons = { "&Continue", "Cancel" }
            button_ids = { ok = "&Continue", yes = "&Continue", save = "&Continue", apply = "&Continue", close = "Cancel", no = "Cancel", cancel = "Cancel" }

            button, result_table = aegisub.dialog.display(dialog, buttons, button_ids)

            if button == false or button == "Cancel" then
                return err("[zah.autoclip] Operation cancelled by user")
            elseif button == "&Continue" then
                config["python"] = result_table["python"]
            end
        until os.execute(c("'" .. config["python"] .. "' --version"))

        aconfig.write_config("zah.autoclip", config)
            :ifErr(function()
                aegisub.debug.out("[aka.config] Failed to write config to file.\n")
                aegisub.debug.out("[aka.config] " .. error .. "\n") end)

        return ok()
end end

first_time_python_vs_unix = function()
    local dialog
    local buttons
    local button_ids
    local button
    local result_table
    if os.execute(c("'" .. config["python"] .. "' -c 'import vapoursynth'")) then
        return ok("Already satisfied")
    else
        repeat
            dialog = {
                { class = "label",                          x = 0, y = 0, width = 25,
                                                            label = "Unable to find Python with VapourSynth at given name or path." },
                { class = "label",                          x = 0, y = 1, width = 25,
                                                            label = "Enter name to Python if it is in PATH or path to Python executable:" },
                { class = "edit", name = "python",          x = 0, y = 2, width = 25,
                                                            text = config["python"] }
            }
            buttons = { "&Continue", "Cancel" }
            button_ids = { ok = "&Continue", yes = "&Continue", save = "&Continue", apply = "&Continue", close = "Cancel", no = "Cancel", cancel = "Cancel" }

            button, result_table = aegisub.dialog.display(dialog, buttons, button_ids)

            if button == false or button == "Cancel" then
                return err("[zah.autoclip] Operation cancelled by user")
            elseif button == "&Continue" then
                config["python"] = result_table["python"]
            end
        until os.execute(c("'" .. config["python"] .. "' -c 'import vapoursynth'"))

        aconfig.write_config("zah.autoclip", config)
            :ifErr(function()
                aegisub.debug.out("[aka.config] Failed to write config to file.\n")
                aegisub.debug.out("[aka.config] " .. error .. "\n") end)

        return ok()
end end

first_time_vsrepo = function()
    local dialog
    local buttons
    local button_ids
    local button
    local result_table
    if os.execute(c(config["vsrepo_mode"] == "vsrepo in PATH (`$ vsrepo --help`)"
                and "'" .. config["vsrepo"] .. "' --help"
                 or "'" .. config["python"] .. "' '" .. config["vsrepo"] .. "' --help")) then
        return ok("Already satisfied")
    else
        repeat
            dialog = {
                { class = "label",                          x = 0, y = 0, width = 25,
                                                            label = "Unable to find vsrepo with given " .. (config["vsrepo_mode"] == "vsrepo in PATH (`$ vsrepo --help`)"
                                                                                                        and "name" or "path") .. "." },
                { class = "label",                          x = 0, y = 1, width = 25,
                                                            label = "Select whether vsrepo is in PATH and enter either the name to vsrepo or path to vsrepo.py:" },
                { class = "dropdown", name = "vsrepo_mode", x = 0, y = 2, width = 25,
                                                            items = { "vsrepo in PATH (`$ vsrepo --help`)", "Path to vsrepo.py (`$ python vsrepo.py --help`)" }, value = config["vsrepo_mode"] },
                { class = "edit", name = "vsrepo",          x = 0, y = 3, width = 25,
                                                            text = config["vsrepo"] }
            }
            buttons = { "&Continue", "Cancel" }
            button_ids = { ok = "&Continue", yes = "&Continue", save = "&Continue", apply = "&Continue", close = "Cancel", no = "Cancel", cancel = "Cancel" }

            button, result_table = aegisub.dialog.display(dialog, buttons, button_ids)

            if button == false or button == "Cancel" then
                return err("[zah.autoclip] Operation cancelled by user")
            elseif button == "&Continue" then
                config["vsrepo_mode"] = result_table["vsrepo_mode"]
                config["vsrepo"] = result_table["vsrepo"]
            end
        until os.execute(c(config["vsrepo_mode"] == "vsrepo in PATH (`$ vsrepo --help`)"
                       and "'" .. config["vsrepo"] .. "' --help"
                        or "'" .. config["python"] .. "' '" .. config["vsrepo"] .. "' --help"))

        aconfig.write_config("zah.autoclip", config)
            :ifErr(function()
                aegisub.debug.out("[aka.config] Failed to write config to file.\n")
                aegisub.debug.out("[aka.config] " .. error .. "\n") end)

        return ok()
end end

edit_config = function()
    local dialog = {
        { class = "label",                          x = 0, y = 0, width = 25,
                                                    label = "Enter name to Python if it is in PATH or path to Python executable:" },
        { class = "edit", name = "python",          x = 0, y = 1, width = 25,
                                                    text = config["python"] },
        { class = "label",                          x = 0, y = 2, width = 25,
                                                    label = "Select whether vsrepo is in PATH and enter either the name to vsrepo or path to vsrepo.py:" },
        { class = "dropdown", name = "vsrepo_mode", x = 0, y = 3, width = 25,
                                                    items = { "vsrepo in PATH (`$ vsrepo --help`)", "Path to vsrepo.py (`$ python vsrepo.py --help`)" }, value = config["vsrepo_mode"] },
        { class = "edit", name = "vsrepo",          x = 0, y = 4, width = 25,
                                                    text = config["vsrepo"] },
        { class = "label",                          x = 0, y = 5, width = 25,
                                                    label = "Do you want to disable warning when the number of layers mismatches?" },
        { class = "checkbox", name = "disable_layer_mismatch", x = 0, y = 6, width = 25,
                                                    label = "Disable", value = config["disable_layer_mismatch"] },
        { class = "label",                          x = 0, y = 7, width = 25,
                                                    label = "Do you want to disable warning when Python script is outdated?" },
        { class = "checkbox", name = "disable_version_notify", x = 0, y = 8, width = 25,
                                                    label = "Disable", value = config["disable_version_notify"] }
    }
    local buttons = { "&Apply", "Close" }
    local button_ids = { ok = "&Apply", yes = "&Apply", save = "&Apply", apply = "&Apply", close = "Close", no = "Close", cancel = "Close" }

    local button, result_table = aegisub.dialog.display(dialog, buttons, button_ids)

    if button == false or button == "Close" then
        return err("[zah.autoclip] Operation cancelled by user")
    elseif button == "&Apply" then
        if config["disable_version_notify"] ~= result_table["disable_version_notify"] then
            disable_version_notify_until_next_time = false
        end

        for k, v in pairs(result_table) do
            config[k] = v
        end
        aconfig.write_config("zah.autoclip", config)
            :ifErr(function()
                aegisub.debug.out("[aka.config] Failed to write config to file.\n")
                aegisub.debug.out("[aka.config] " .. error .. "\n")
                aegisub.cancel() end)

        return ok()
end end

edit_config_unix = function()
    local dialog = {
        { class = "label",                          x = 0, y = 0, width = 25,
                                                    label = "Enter name to Python if it is in PATH or path to Python executable:" },
        { class = "edit", name = "python",          x = 0, y = 1, width = 25,
                                                    text = config["python"] },
        { class = "label",                          x = 0, y = 2, width = 25,
                                                    label = "Do you want to disable warning when the number of layers mismatches?" },
        { class = "checkbox", name = "disable_layer_mismatch", x = 0, y = 3, width = 25,
                                                    label = "Disable", value = config["disable_layer_mismatch"] },
        { class = "label",                          x = 0, y = 4, width = 25,
                                                    label = "Do you want to disable warning when Python script is outdated?" },
        { class = "checkbox", name = "disable_version_notify", x = 0, y = 5, width = 25,
                                                    label = "Disable", value = config["disable_version_notify"] }
    }
    local buttons = { "&Apply", "Close" }
    local button_ids = { ok = "&Apply", yes = "&Apply", save = "&Apply", apply = "&Apply", close = "Close", no = "Close", cancel = "Close" }

    local button, result_table = aegisub.dialog.display(dialog, buttons, button_ids)

    if button == false or button == "Close" then
        return err("[zah.autoclip] Operation cancelled by user")
    elseif button == "&Apply" then
        if config["disable_version_notify"] ~= result_table["disable_version_notify"] then
            disable_version_notify_until_next_time = false
        end

        for k, v in pairs(result_table) do
            config[k] = v
        end
        aconfig.write_config("zah.autoclip", config)
            :ifErr(function()
                aegisub.debug.out("[aka.config] Failed to write config to file.\n")
                aegisub.debug.out("[aka.config] " .. error .. "\n")
                aegisub.cancel() end)

        return ok()
end end

run_command_until = function(command)
    local run
    local status
    local terminate
    local code
    local log
    local dialog
    local buttons
    local button_ids
    local button
    local result_table

    while true do
        run = command .. "\n'" .. config["python"] .. "' -m ass_autoclip --check-dependencies"
        log, status, terminate, code = run_cmd(c(run), true)
        if status then
            return ok()
        end

        dialog = {
            { class = "label",                          x = 0, y = 0, width = 40,
                                                        label = terminate == "exit"
                                                            and "Command execution exits with code " .. tostring(code) .. ":"
                                                             or "Command execution terminated with signal " .. tostring(code) .. ":" },
            { class = "textbox", name = "log",          x = 0, y = 1, width = 40, height = 12,
                                                        text = log },
            { class = "label",                          x = 0, y = 13, width = 40,
                                                        label = "You may edit the command below to fix the problem and click „Run Again“ to retry." },
            { class = "textbox", name = "command",      x = 0, y = 14, width = 40, height = 12,
                                                        text = command }
        }
        buttons = { "&Run Again", "Cancel" }
        button_ids = { ok = "&Run Again", yes = "&Run Again", save = "&Run Again", apply = "&Run Again", close = "Cancel", no = "Cancel", cancel = "Cancel" }

        button, result_table = aegisub.dialog.display(dialog, buttons, button_ids)
        if button == false or button == "Cancel" then
            return err("[zah.autoclip] Operation cancelled by user")
        elseif button == "&Run Again" then
            command = result_table["command"]
end end end

fisrt_time_dependencies = function()
    if not os.execute(c("'" .. config["python"] .. "' -m ass_autoclip --check-dependencies")) then
        local dialog = {
            { class = "label",                          x = 0, y = 0, width = 40,
                                                        label = "AutoClip requires additional dependencies to be installed." },
            { class = "label",                          x = 0, y = 1, width = 40,
                                                        label = "Click „Run“ to execute the following commands. You may edit the command before running, or copy the command and execute it elsewhere." },
            { class = "textbox", name = "command",      x = 0, y = 2, width = 40, height = 12,
                                                        text = "'" .. config["python"] .. "' -m ensurepip\n" .. 
                                                               "'" .. config["python"] .. "' -m pip install numpy PySide6 scikit-image --upgrade --upgrade-strategy eager\n" .. 
                                                               "'" .. config["python"] .. "' -m pip install ass-autoclip --upgrade\n" ..
                                                              (config["vsrepo_mode"] == "vsrepo in PATH (`$ vsrepo --help`)"
                                                           and "'" .. config["vsrepo"] .. "' update\n" ..
                                                               "'" .. config["vsrepo"] .. "' install lsmas dfttest\n"
                                                            or "'" .. config["python"] .. "' '" .. config["vsrepo"] .. "' update\n" ..
                                                               "'" .. config["python"] .. "' '" .. config["vsrepo"] .. "' install lsmas dfttest\n") }
        }
        local buttons = { "&Run", "Cancel" }
        local button_ids = { ok = "&Run", yes = "&Run", save = "&Run", apply = "&Run", close = "Cancel", no = "Cancel", cancel = "Cancel" }
    
        local button, result_table = aegisub.dialog.display(dialog, buttons, button_ids)
    
        if button == false or button == "Cancel" then
            return err("[zah.autoclip] Operation cancelled by user")
        elseif button == "&Run" then
            return run_command_until(result_table["command"])
        end
    else
        return ok()
end end

first_time_python_dependencies_unix = function()
    if not os.execute(c("'" .. config["python"] .. "' -m ass_autoclip --check-python-dependencies")) then
        local dialog = {
            { class = "label",                          x = 0, y = 0, width = 40,
                                                        label = "AutoClip requires additional dependencies to be installed." },
            { class = "label",                          x = 0, y = 1, width = 40,
                                                        label = "Click „Run“ to execute the following commands. You may edit the command before running, or copy the command and execute it elsewhere." },
            { class = "textbox", name = "command",      x = 0, y = 2, width = 40, height = 12,
                                                        text = "'" .. config["python"] .. "' -m ensurepip\n" .. 
                                                               "'" .. config["python"] .. "' -m pip install numpy PySide6 scikit-image --upgrade --upgrade-strategy eager\n" .. 
                                                               "'" .. config["python"] .. "' -m pip install ass-autoclip --upgrade\n" }
        }
        local buttons = { "&Run", "Cancel" }
        local button_ids = { ok = "&Run", yes = "&Run", save = "&Run", apply = "&Run", close = "Cancel", no = "Cancel", cancel = "Cancel" }
    
        local button, result_table = aegisub.dialog.display(dialog, buttons, button_ids)
    
        if button == false or button == "Cancel" then
            return err("[zah.autoclip] Operation cancelled by user")
        elseif button == "&Run" then
            return run_command_until(result_table["command"])
        end
    else
        return ok()
end end

first_time_vs_dependencies_unix = function()
    if not os.execute(c("'" .. config["python"] .. "' -m ass_autoclip --check-vs-dependencies")) then
        local dialog = {
            { class = "label",                          x = 0, y = 0, width = 30,
                                                        label = "AutoClip requires additional VapourSynth plugins to be installed:" },
            { class = "label",                          x = 0, y = 1, width = 30,
                                                        label = "Please follow the links below and install the required plugins." },
            { class = "textbox", name = "command",      x = 0, y = 2, width = 30, height = 7,
                                                        text = "lsmas (https://github.com/AkarinVS/L-SMASH-Works)\n" .. 
                                                               "dfttest (https://github.com/HomeOfVapourSynthEvolution/VapourSynth-DFTTest)\n" }
        }
        local buttons = { "Cancel" }
        local button_ids = { close = "Cancel", no = "Cancel", cancel = "Cancel" }
    
        local button, result_table = aegisub.dialog.display(dialog, buttons, button_ids)
    
        if button == false or button == "Cancel" then
            return err("[zah.autoclip] Operation cancelled by user")
        end
    else
        return ok()
end end

update_vs_dependencies_unix = function()
    if not os.execute(c("'" .. config["python"] .. "' -m ass_autoclip --check-vs-dependencies")) then
        local dialog = {
            { class = "label",                          x = 0, y = 0, width = 30,
                                                        label = "The newly installed version of AutoClip requires VapourSynth plugins to be installed:" },
            { class = "label",                          x = 0, y = 1, width = 30,
                                                        label = "Please follow the links below and install or update the required plugins." },
            { class = "textbox", name = "command",      x = 0, y = 2, width = 30, height = 7,
                                                        text = "lsmas (https://github.com/AkarinVS/L-SMASH-Works)\n" .. 
                                                               "dfttest (https://github.com/HomeOfVapourSynthEvolution/VapourSynth-DFTTest)\n" }
        }
        local buttons = { "Cancel" }
        local button_ids = { close = "Cancel", no = "Cancel", cancel = "Cancel" }
    
        local button, result_table = aegisub.dialog.display(dialog, buttons, button_ids)
    
        if button == false or button == "Cancel" then
            return err("[zah.autoclip] Operation cancelled by user")
        end
    else
        return ok()
end end

no_dependencies = function()
    local dialog
    local buttons
    local button_ids
    local button
    local result_table
    while not os.execute(c("'" .. config["python"] .. "' -m ass_autoclip --check-dependencies")) do
        dialog = {
            { class = "label",                          x = 0, y = 0, width = 40,
                                                        label = "Failed to execute AutoClip." },
            { class = "label",                          x = 0, y = 1, width = 40,
                                                        label = "Click „Run Command“ to execute the following commands and reinstall AutoClip. You may edit the command before running, or copy the command and execute it elsewhere." },
            { class = "textbox", name = "command",      x = 0, y = 2, width = 40, height = 12,
                                                        text = "'" .. config["python"] .. "' -m ensurepip\n" .. 
                                                               "'" .. config["python"] .. "' -m pip install numpy PySide6 scikit-image --upgrade --upgrade-strategy eager\n" .. 
                                                               "'" .. config["python"] .. "' -m pip install ass-autoclip --force-reinstall\n" ..
                                                              (config["vsrepo_mode"] == "vsrepo in PATH (`$ vsrepo --help`)"
                                                           and "'" .. config["vsrepo"] .. "' update\n" ..
                                                               "'" .. config["vsrepo"] .. "' install lsmas dfttest\n" ..
                                                               "'" .. config["vsrepo"] .. "' upgrade lsmas dfttest\n"
                                                            or "'" .. config["python"] .. "' '" .. config["vsrepo"] .. "' update\n" ..
                                                               "'" .. config["python"] .. "' '" .. config["vsrepo"] .. "' install lsmas dfttest\n" ..
                                                               "'" .. config["python"] .. "' '" .. config["vsrepo"] .. "' upgrade lsmas dfttest\n") }
        }
        buttons = { "&Run Command", "Cancel" }
        button_ids = { ok = "&Run Command", yes = "&Run Command", save = "&Run Command", apply = "&Run Command", close = "Cancel", no = "Cancel", cancel = "Cancel" }
        
        button, result_table = aegisub.dialog.display(dialog, buttons, button_ids)
        
        if button == false or button == "Cancel" then
            return err("[zah.autoclip] Operation cancelled by user")
        elseif button == "&Run Command" then
            return run_command_until(result_table["command"])
    end end
    return ok("Already satisfied")
end

no_python_dependencies_unix = function()
    if not os.execute(c("'" .. config["python"] .. "' -m ass_autoclip --check-python-dependencies")) then
        local dialog = {
            { class = "label",                          x = 0, y = 0, width = 40,
                                                        label = "Failed to execute AutoClip." },
            { class = "label",                          x = 0, y = 1, width = 40,
                                                        label = "Click „Run Command“ to execute the following commands and reinstall AutoClip. You may edit the command before running, or copy the command and execute it elsewhere." },
            { class = "textbox", name = "command",      x = 0, y = 2, width = 40, height = 12,
                                                        text = "'" .. config["python"] .. "' -m ensurepip\n" .. 
                                                               "'" .. config["python"] .. "' -m pip install numpy PySide6 scikit-image --upgrade --upgrade-strategy eager\n" .. 
                                                               "'" .. config["python"] .. "' -m pip install ass-autoclip --force-reinstall\n" }
        }
        local buttons = { "&Run Command", "Cancel" }
        local button_ids = { ok = "&Run Command", yes = "&Run Command", save = "&Run Command", apply = "&Run Command", close = "Cancel", no = "Cancel", cancel = "Cancel" }
    
        local button, result_table = aegisub.dialog.display(dialog, buttons, button_ids)
    
        if button == false or button == "Cancel" then
            return err("[zah.autoclip] Operation cancelled by user")
        elseif button == "&Run Command" then
            return run_command_until(result_table["command"])
        end
    else
        return ok()
end end

no_vs_dependencies_unix = function()
    if not os.execute(c("'" .. config["python"] .. "' -m ass_autoclip --check-vs-dependencies")) then
        local dialog = {
            { class = "label",                          x = 0, y = 0, width = 30,
                                                        label = "Failed to execute AutoClip:" },
            { class = "label",                          x = 0, y = 1, width = 30,
                                                        label = "Please follow the links below and install the required VapourSynth plugins." },
            { class = "textbox", name = "command",      x = 0, y = 2, width = 30, height = 7,
                                                        text = "lsmas (https://github.com/AkarinVS/L-SMASH-Works)\n" .. 
                                                               "dfttest (https://github.com/HomeOfVapourSynthEvolution/VapourSynth-DFTTest)\n" }
        }
        local buttons = { "Cancel" }
        local button_ids = { close = "Cancel", no = "Cancel", cancel = "Cancel" }
    
        local button, result_table = aegisub.dialog.display(dialog, buttons, button_ids)
    
        if button == false or button == "Cancel" then
            return err("[zah.autoclip] Operation cancelled by user")
        end
    else
        return ok()
end end

out_of_date_dependencies = function()
    local dialog = {
        { class = "label",                          x = 0, y = 0, width = 40,
                                                    label = "AutoClip dependencies are out of date." },
        { class = "label",                          x = 0, y = 1, width = 40,
                                                    label = "Click „Run Command“ to execute the following commands and update AutoClip. You may edit the command before running, or copy the command and execute it elsewhere." },
        { class = "textbox", name = "command",      x = 0, y = 2, width = 40, height = 12,
                                                    text = "'" .. config["python"] .. "' -m pip install ass-autoclip --upgrade --upgrade-strategy eager\n" ..
                                                          (config["vsrepo_mode"] == "vsrepo in PATH (`$ vsrepo --help`)"
                                                       and "'" .. config["vsrepo"] .. "' update\n" ..
                                                           "'" .. config["vsrepo"] .. "' upgrade lsmas dfttest\n"
                                                        or "'" .. config["python"] .. "' '" .. config["vsrepo"] .. "' update\n" ..
                                                           "'" .. config["python"] .. "' '" .. config["vsrepo"] .. "' upgrade lsmas dfttest\n") }
    }
    local buttons = { "&Run Command", "Remind Me Next Time", "Do Not Show Again", "Cancel" }
    local button_ids = { ok = "&Run Command", yes = "&Run Command", save = "&Run Command", apply = "&Run Command", close = "Cancel", no = "Cancel", cancel = "Cancel" }

    local button, result_table = aegisub.dialog.display(dialog, buttons, button_ids)

    if button == false or button == "Cancel" then
        return err("[zah.autoclip] Operation cancelled by user")
    elseif button == "&Run Command" then
        return run_command_until(result_table["command"])
    elseif button == "Remind Me Next Time" then
        disable_version_notify_until_next_time = true
        return ok()
    elseif button == "Do Not Show Again" then
        config["disable_version_notify"] = true
        aconfig.write_config("zah.autoclip", config)
            :ifErr(function()
                aegisub.debug.out("[aka.config] Failed to write config to file.\n")
                aegisub.debug.out("[aka.config] " .. error .. "\n")
                aegisub.cancel() end)
        return ok()
end end

out_of_date_dependencies_unix = function()
    local dialog = {
        { class = "label",                          x = 0, y = 0, width = 40,
                                                    label = "AutoClip dependencies are out of date." },
        { class = "label",                          x = 0, y = 1, width = 40,
                                                    label = "Click „Run Command“ to execute the following commands and update AutoClip. You may edit the command before running, or copy the command and execute it elsewhere." },
        { class = "textbox", name = "command",      x = 0, y = 2, width = 40, height = 12,
                                                    text = "'" .. config["python"] .. "' -m pip install ass-autoclip --upgrade --upgrade-strategy eager\n" }
    }
    local buttons = { "&Run Command", "Remind Me Next Time", "Do Not Show Again", "Cancel" }
    local button_ids = { ok = "&Run Command", yes = "&Run Command", save = "&Run Command", apply = "&Run Command", close = "Cancel", no = "Cancel", cancel = "Cancel" }

    local button, result_table = aegisub.dialog.display(dialog, buttons, button_ids)

    if button == false or button == "Cancel" then
        return err("[zah.autoclip] Operation cancelled by user")
    elseif button == "&Run Command" then
        return run_command_until(result_table["command"])
            :andThen(update_vs_dependencies_unix)
    elseif button == "Remind Me Next Time" then
        disable_version_notify_until_next_time = true
        return ok()
    elseif button == "Do Not Show Again" then
        config["disable_version_notify"] = true
        aconfig.write_config("zah.autoclip", config)
            :ifErr(function()
                aegisub.debug.out("[aka.config] Failed to write config to file.\n")
                aegisub.debug.out("[aka.config] " .. error .. "\n")
                aegisub.cancel() end)
        return ok()
end end

update_dependencies = function()
    local dialog = {
        { class = "label",                          x = 0, y = 0, width = 40,
                                                    label = "Update dependencies." },
        { class = "label",                          x = 0, y = 1, width = 40,
                                                    label = "Click „Run“ to execute the following commands. You may edit the command before running, or copy the command and execute it elsewhere." },
        { class = "textbox", name = "command",      x = 0, y = 2, width = 40, height = 12,
                                                    text = "'" .. config["python"] .. "' -m pip install ass-autoclip --upgrade --upgrade-strategy eager\n" ..
                                                          (config["vsrepo_mode"] == "vsrepo in PATH (`$ vsrepo --help`)"
                                                       and "'" .. config["vsrepo"] .. "' update\n" ..
                                                           "'" .. config["vsrepo"] .. "' upgrade lsmas dfttest\n"
                                                        or "'" .. config["python"] .. "' '" .. config["vsrepo"] .. "' update\n" ..
                                                           "'" .. config["python"] .. "' '" .. config["vsrepo"] .. "' upgrade lsmas dfttest\n") }
    }
    local buttons = { "&Run", "Close" }
    local button_ids = { ok = "&Run", yes = "&Run", save = "&Run", apply = "&Run", close = "Close", no = "Close", cancel = "Close" }

    local button, result_table = aegisub.dialog.display(dialog, buttons, button_ids)

    if button == false or button == "Close" then
        return err("[zah.autoclip] Operation cancelled by user")
    elseif button == "&Run" then
        return run_command_until(result_table["command"])
end end

update_dependencies_unix = function()
    local dialog = {
        { class = "label",                          x = 0, y = 0, width = 40,
                                                    label = "Update dependencies." },
        { class = "label",                          x = 0, y = 1, width = 40,
                                                    label = "Click „Run“ to execute the following commands. You may edit the command before running, or copy the command and execute it elsewhere." },
        { class = "textbox", name = "command",      x = 0, y = 2, width = 40, height = 12,
                                                    text = "'" .. config["python"] .. "' -m pip install ass-autoclip --upgrade --upgrade-strategy eager\n" }
    }
    local buttons = { "&Run", "Close" }
    local button_ids = { ok = "&Run", yes = "&Run", save = "&Run", apply = "&Run", close = "Close", no = "Close", cancel = "Close" }

    local button, result_table = aegisub.dialog.display(dialog, buttons, button_ids)

    if button == false or button == "Close" then
        return err("[zah.autoclip] Operation cancelled by user")
    elseif button == "&Run" then
        return run_command_until(result_table["command"])
            :andThen(update_vs_dependencies_unix)
end end

unsupported_dependencies = function()
    local dialog = {
        { class = "label",                          x = 0, y = 0, width = 40,
                                                    label = "AutoClip dependencies are out of date and no longer supported." },
        { class = "label",                          x = 0, y = 1, width = 40,
                                                    label = "Click „Run Command“ to execute the following commands and update AutoClip. You may edit the command before running, or copy the command and execute it elsewhere." },
        { class = "textbox", name = "command",      x = 0, y = 2, width = 40, height = 12,
                                                    text = "'" .. config["python"] .. "' -m pip install ass-autoclip --upgrade --upgrade-strategy eager\n" ..
                                                          (config["vsrepo_mode"] == "vsrepo in PATH (`$ vsrepo --help`)"
                                                       and "'" .. config["vsrepo"] .. "' update\n" ..
                                                           "'" .. config["vsrepo"] .. "' upgrade lsmas dfttest\n"
                                                        or "'" .. config["python"] .. "' '" .. config["vsrepo"] .. "' update\n" ..
                                                           "'" .. config["python"] .. "' '" .. config["vsrepo"] .. "' upgrade lsmas dfttest\n") }
    }
    local buttons = { "&Run Command", "Cancel" }
    local button_ids = { ok = "&Run Command", yes = "&Run Command", save = "&Run Command", apply = "&Run Command", close = "Cancel", no = "Cancel", cancel = "Cancel" }

    local button, result_table = aegisub.dialog.display(dialog, buttons, button_ids)

    if button == false or button == "Cancel" then
        return err("[zah.autoclip] Operation cancelled by user")
    elseif button == "&Run Command" then
        return run_command_until(result_table["command"])
end end

out_of_date_dependencies_unix = function()
    local dialog = {
        { class = "label",                          x = 0, y = 0, width = 40,
                                                    label = "AutoClip dependencies are out of date and no longer supported." },
        { class = "label",                          x = 0, y = 1, width = 40,
                                                    label = "Click „Run Command“ to execute the following commands and update AutoClip. You may edit the command before running, or copy the command and execute it elsewhere." },
        { class = "textbox", name = "command",      x = 0, y = 2, width = 40, height = 12,
                                                    text = "'" .. config["python"] .. "' -m pip install ass-autoclip --upgrade --upgrade-strategy eager\n" }
    }
    local buttons = { "&Run Command", "Cancel" }
    local button_ids = { ok = "&Run Command", yes = "&Run Command", save = "&Run Command", apply = "&Run Command", close = "Cancel", no = "Cancel", cancel = "Cancel" }

    local button, result_table = aegisub.dialog.display(dialog, buttons, button_ids)

    if button == false or button == "Cancel" then
        return err("[zah.autoclip] Operation cancelled by user")
    elseif button == "&Run Command" then
        return run_command_until(result_table["command"])
            :andThen(update_vs_dependencies_unix)
end end


local first_time_python_vsrepo_main
local no_dependencies_main
local autoclip_main
local edit_config_main
local update_dependencies_main

first_time_python_vsrepo_main = function()
    if not config then
        aconfig.read_config_string("zah.autoclip")
            :ifOk(function()
                config = aconfig:read_and_validate_config_if_empty_then_default_or_else_edit_and_save("zah.autoclip", validation_func)
                    :ifErr(aegisub.cancel)
                    :unwrap() end)
            :ifErr(function()
                config = aconfig:read_and_validate_config_if_empty_then_default_or_else_edit_and_save("zah.autoclip", validation_func)
                    :ifErr(aegisub.cancel)
                    :unwrap()
                if jit.os == "Windows" then
                    first_time_python_vsrepo()
                        :ifErr(aegisub.cancel)
                    first_time_python()
                        :ifErr(aegisub.cancel)
                    first_time_vsrepo()
                        :ifErr(aegisub.cancel)
                    fisrt_time_dependencies()
                        :ifErr(aegisub.cancel)
                else
                    first_time_python_unix()
                        :ifErr(aegisub.cancel)
                    first_time_python_vs_unix()
                        :ifErr(aegisub.cancel)
                    first_time_python_dependencies_unix()
                        :ifErr(aegisub.cancel)
                    first_time_vs_dependencies_unix()
                        :ifErr(aegisub.cancel)
                end end)
end end

no_dependencies_main = function()
    if os.execute(c("'" .. config["python"] .. "' -m ass_autoclip --check-dependencies")) then
        return ok("Already satisfied")
    else
        if jit.os == "Windows" then
            first_time_python()
                :ifErr(aegisub.cancel)
            first_time_vsrepo()
                :ifErr(aegisub.cancel)
            no_dependencies()
                :ifErr(aegisub.cancel)
        else
            first_time_python_vs_unix()
                :ifErr(aegisub.cancel)
            no_python_dependencies_unix()
                :ifErr(aegisub.cancel)
            no_vs_dependencies_unix()
                :ifErr(aegisub.cancel)
        end
        return ok()
end end

autoclip_main = function(sub, sel, act)
    first_time_python_vsrepo_main()

    local ass = Ass(sub, sel, act)

    local project_props = aegisub.project_properties()
    if not project_props.video_file or project_props.video_file == "" then
        aegisub.debug.out("[zah.autoclip] AutoClip requires a video to be loaded for clipping.\n")
        aegisub.cancel()
    end
    local video_file = project_props.video_file

    -- Grab frame and clip information and check frame continuity across subtitle lines
    Aegi.progressTitle("Gathering frame information")
    local active = project_props.video_position
    local frames = {}
    local first
    local last
    local active_clip
    local clip
    for line, s, i, n in ass:iterSel() do
        ass:progressLine(s, i, n)

        line.start_frame = aegisub.frame_from_ms(line.start_time)
        line.end_frame = aegisub.frame_from_ms(line.end_time)

        if not first then
            first = line.start_frame
            last = line.end_frame
        else
            first = first <= line.start_frame and first or line.start_frame
            last = last >= line.end_frame and last or line.end_frame
        end

        for j = line.start_frame, line.end_frame - 1 do
            if not frames[j] then
                frames[j] = 1
            else
                frames[j] = frames[j] + 1
        end end

        Line.process(ass, line)
        if type(line.data["clip"]) == "table" then
            if line.start_frame <= active and active < line.end_frame then
                if active_clip == nil then
                    active_clip = line.data["clip"]
                elseif type(active_clip) == "table" then
                    if not (line.data["clip"][1] == active_clip[1] and
                            line.data["clip"][2] == active_clip[2] and
                            line.data["clip"][3] == active_clip[3] and
                            line.data["clip"][4] == active_clip[4]) then
                        active_clip = false
            end end end
                
            if clip == nil then
                clip = line.data["clip"]
            elseif type(clip) == "table" then
                if not (line.data["clip"][1] == clip[1] and
                        line.data["clip"][2] == clip[2] and
                        line.data["clip"][3] == clip[3] and
                        line.data["clip"][4] == clip[4]) then
                    clip = false
    end end end end

    -- Check frame continuity
    local head
    for i = first, last - 1 do
        if not frames[i] then
            for j = i, last - 1 do
                if frames[j] then
                    aegisub.debug.out("[zah.autoclip] Selected lines must be time continuous.\n")
                    aegisub.debug.out("[zah.autoclip] The earliest frame in the selected line is frame " .. tostring(first) .. ", and the latest frame is frame " .. tostring(last - 1) .. ".\n")
                    if i ~= j - 1 then
                        aegisub.debug.out("[zah.autoclip] There is at least one gap from frame " .. tostring(i) .. " to frame " .. tostring(j - 1) .. " that no lines in the selection covers.\n")
                    else
                        aegisub.debug.out("[zah.autoclip] There is at least one gap at frame " .. tostring(i) .. " that no lines in the selection covers.\n")
                    end
                    aegisub.cancel()
            end end
        elseif not config["disable_layer_mismatch"] then
            if head == nil then
                head = frames[i]
            elseif head ~= false and head ~= frames[i] then
                aegisub.debug.out("[zah.autoclip] Number of layers mismatches.\n")
                aegisub.debug.out("[zah.autoclip] There are " .. tostring(head) .. " layers on frame " .. tostring(i - 1) .. ", but there are " .. tostring(frames[i]) .. " layers on frame " .. tostring(i) .. ".\n")
                aegisub.debug.out("[zah.autoclip] If this is intentional and you want to silence this warning, you can disable it in „AutoClip > Configure AutoClip“.\n")
                aegisub.debug.out("[zah.autoclip] Continuing.\n")
                head = false
    end end end

    -- Make sure active is inside [first:last]
    if not (first <= active and active < last) then
        aegisub.debug.out("[zah.autoclip] Video seek head outside the range of selected lines.\n")
        aegisub.debug.out("[zah.autoclip] The selected lines start at frame " .. tostring(first) .. " and end at frame " .. tostring(last - 1) .. " but video seek head is at frame " .. tostring(active) .. ".\n")
        aegisub.debug.out("[zah.autoclip] AutoClip uses video seek head as the reference frame and also by default takes the clipping area from lines containing video seek head.\n")
        aegisub.cancel()
    end

    if active_clip == false then
        aegisub.debug.out("[zah.autoclip] Multiple different rect clips found on lines containing the frame at video seek head.\n")
        aegisub.debug.out("[zah.autoclip] AutoClip requires a rect clip to be set for the area it will be active.\n")
        aegisub.debug.out("[zah.autoclip] AutoClip by default takes this clip from lines containing the frame at video seek head. AutoClip expects one unique rect clip on the lines.\n")
        aegisub.cancel()
    end
    -- Check active_clip and set to clip
    if active_clip then
        clip = active_clip
    else
        if clip == nil then
            aegisub.debug.out("[zah.autoclip] No rect clips found in selected lines.\n")
            aegisub.debug.out("[zah.autoclip] AutoClip requires a rect clip to be set for the area it will be active.\n")
            aegisub.debug.out("[zah.autoclip] AutoClip first checks if such clip exists on lines containing the frame at video seek head, otherwise it fallbacks and checks for clips in every lines in the selection.\n")
            aegisub.cancel()
        elseif clip == false then
            aegisub.debug.out("[zah.autoclip] No rect clip found in lines containing the frame at video seek head, and there are multiple different rect clips found on other selected line.\n")
            aegisub.debug.out("[zah.autoclip] AutoClip requires a rect clip to be set for the area it will be active.\n")
            aegisub.debug.out("[zah.autoclip] AutoClip first checks if such clip exists on lines containing the frame at video seek head, otherwise it fallbacks and checks for clips in every lines in the selection.\n")
            aegisub.cancel()
        end
    end

    -- Run commands
    Aegi.progressTitle("Waiting for Python to complete")
    local output_file
    local command
    local log
    local status
    local terminate
    local code
    local f
    local msg
    local output

    ::run_again::
    
    output_file = aegisub.decode_path("?temp/zah.autoclip." .. string.sub(tostring(math.random(10000000, 99999999)), 2) .. ".json")
    command = "'" .. config["python"] .. "'" ..
                      " -m ass_autoclip --input '" .. video_file .. "'" ..
                                      " --output '" .. output_file .. "'" ..
                        string.format(" --clip '%f %f %f %f'", clip[1], clip[2], clip[3], clip[4]) ..
                                      " --first " .. first ..
                                      " --last " .. last ..
                                      " --active " .. active ..
                                      " --supported-version " .. ((not disable_version_notify_until_next_time and not config["disable_version_notify"])
                                                              and script_version
                                                               or last_supported_script_version)
    log, status, terminate, code = run_cmd(c(command), true)
    Aegi.progressCancelled()

    Aegi.progressTitle("Parsing output from Python")
    if not status then
        if no_dependencies_main()
            :ifErr(aegisub.cancel)
            :unwrap() ~= "Already satisfied" then
            goto run_again
        end

        if terminate == "exit" then
            aegisub.debug.out("[zah.autoclip] Python exits with code " .. tostring(code) .. ":\n")
        else
            aegisub.debug.out("[zah.autoclip] Python terminated with signal " .. tostring(code) .. ":\n")
        end
        aegisub.debug.out("[zah.autoclip] " .. c(command) .. "\n")
        aegisub.debug.out(log)
        aegisub.debug.out("[zah.autoclip] Attempting to continue.\n")
    end

    -- Open output file
    f, msg = io.open(output_file, "r")
    if not f then
        aegisub.debug.out("[zah.autoclip] Failed to open output file:\n")
        aegisub.debug.out("[zah.autoclip] " .. msg .. "\n")
        aegisub.cancel()
    end

    output = json:decode3(f:read("*a"))
        :ifErr(function(error)
            aegisub.debug.out("[zah.autoclip] Failed to parse output file:\n")
            aegisub.debug.out("[zah.autoclip] " .. error .. "\n")
            aegisub.cancel() end)
        :unwrap()
    f:close()

    if type(output["clip"]) ~= "table" then
        if output["current_version"] then
            if V(output["current_version"]) < V(last_supported_script_version) then
                if jit.os == "Windows" then
                    unsupported_dependencies()
                        :ifErr(aegisub.cancel)
                else
                    unsupported_dependencies_unix()
                        :ifErr(aegisub.cancel)
                end
            elseif V(output["current_version"]) < V(script_version) then
                if jit.os == "Windows" then
                    out_of_date_dependencies()
                        :ifErr(aegisub.cancel)
                else
                    out_of_date_dependencies_unix()
                        :ifErr(aegisub.cancel)
                end
            else
                error("Unexpected error")
            end
            goto run_again
        else
            aegisub.debug.out("[zah.autoclip] Failed to parse output file:\n")
            aegisub.debug.out("[zah.autoclip] Malformatted or missing key \"clip\".\n")
            aegisub.cancel()
    end end

    frames = output["clip"]
    if frames[last - first] == nil then
        aegisub.debug.out("[zah.autoclip] Output file contains less frames than expected.\n")
        aegisub.debug.out("[zah.autoclip] AutoClip will continue but please manually confirm the result after run.\n")
    elseif frames[last - first + 1] ~= nil then
        aegisub.debug.out("[zah.autoclip] Output file contains more frames than expected.\n")
        aegisub.debug.out("[zah.autoclip] AutoClip will continue but please manually confirm the result after run.\n")
    end

    -- Apply the frames table to subtitle
    Aegi.progressTitle("Writing clips to lines")
    for line, s, i, n in ass:iterSel() do
        ass:progressLine(s, i, n)

        ass:removeLine(line, s)
        -- Internal ILL value, may break
        line.isShape = false
        Line.process(ass, line)
        line.text.tagsBlocks[1]:remove("clip")

        Line.callBackFBF(ass, line, function(line_, i_, end_frame)
            if frames[aegisub.frame_from_ms(line_.start_time) - first + 1] then
                line_.text.tagsBlocks[1]:insert("\\iclip(" .. frames[aegisub.frame_from_ms(line_.start_time) - first + 1] .. ")")
            end
            ass:insertLine(line_, s) end)
    end

    return ass:getNewSelection()
end

update_dependencies_main = function()
    first_time_python_vsrepo_main()

    if jit.os == "Windows" then
        update_dependencies()
            :ifErr(aegisub.cancel)
    else
        update_dependencies_unix()
            :ifErr(aegisub.cancel)
end end

edit_config_main = function()
    if not config then
        config = aconfig:read_and_validate_config_if_empty_then_default_or_else_edit_and_save("zah.autoclip", validation_func)
            :ifErr(aegisub.cancel)
            :unwrap()
    end

    if jit.os == "Windows" then
        edit_config()
            :ifErr(aegisub.cancel)
    else
        edit_config_unix()
            :ifErr(aegisub.cancel)
end end


DepCtrl:registerMacros({
    { "AutoClip", script_description, autoclip_main },
    { "Update Dependencies", "Update AutoClip dependencies", update_dependencies_main },
    { "Configure AutoClip", "Configure AutoClip", edit_config_main }
})
