script_name = "AutoClip"
script_description = "Add clips to subtitles 𝓪𝓾𝓽𝓸𝓶𝓪𝓰𝓲𝓬𝓪𝓵𝓵𝔂"
script_version = "2.1.0"
script_author = "Zahuczky, Akatsumekusa"
script_namespace = "zah.autoclip"
-- Lua version number is always kept aligned with version number in python script.

local last_supported_script_version = "2.0.3"

-----------------------------------------------------------------------------------------------------
-- Organisation of this file:
-- display_configurator and display_configurator derived functions:
--     first_time_python_with_vsrepo_win, check_python_with_vs_win, edit_config_win, etc.
--     This is for the „configuration“ windows that let the user enter python or vsrepo path.
-- display_runner and display_runner derived functions:
--     first_time_dependencies_win, no_dependencies_win, etc.
--     This is for the „execution“ windows that executes commands to install or upgrade dependencies.
-- main functions:
--     first_time_python_vsrepo_main, autoclip_main, edit_config_main, etc.
--     The main logic of Lua side of AutoClip. Calls functions from previous two sections.
-----------------------------------------------------------------------------------------------------



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
            "aka.uikit",
            version = "1.0.0",
            url = "https://github.com/Akatmks/Akatsumekusa-Aegisub-Scripts",
            feed = "https://raw.githubusercontent.com/Akatmks/Akatsumekusa-Aegisub-Scripts/master/DependencyControl.json"
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
            "lfs",
        },
        {
            "petzku.util",
            version = "0.4.0",
            url = "https://github.com/petzku/Aegisub-Scripts",
            feed = "https://raw.githubusercontent.com/petzku/Aegisub-Scripts/master/DependencyControl.json"
        },
        {
            "aka.unsemantic",
            version = "1.1.0",
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
local Aegi, Ass, Line, Table = ILL.Aegi, ILL.Ass, ILL.Line, ILL.Table

local uikit = require("aka.uikit")
local adialog, abuttons, adisplay = uikit.dialog, uikit.buttons, uikit.display
adialog.join = adialog.join_dialog

local outcome = require("aka.outcome")
local ok, err = outcome.ok, outcome.err

local VSREPO_IN_PATH = "vsrepo in PATH (`$ vsrepo --help`)"
local PATH_TO_VSREPO = "Path to vsrepo.py (`$ python vsrepo.py --help`)"

local default_config = {
    ["venv_activate"] = "",
    ["python"] = "python3",
    ["vsrepo_mode"] = VSREPO_IN_PATH,
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
    if config["venv_activate"] == nil then
        config["venv_activate"] = default_config["venv_activate"]
    elseif type(config["venv_activate"]) ~= "string" then
        return err("Invalid key \"venv_activate\".")
    end
    if config["python"] == nil then
        config["python"] = default_config["python"]
    elseif type(config["python"]) ~= "string" then
        return err("Invalid key \"python\".")
    end
    if config["vsrepo_mode"] == nil then
        config["vsrepo_mode"] = default_config["vsrepo_mode"]
    elseif config["vsrepo_mode"] ~= VSREPO_IN_PATH and config["vsrepo_mode"] ~= PATH_TO_VSREPO then
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

local lfs = require("lfs")

local V = require("aka.unsemantic").V
local disable_version_notify_until_next_time = false

local re = require("aegisub.re")
local re_newline = re.compile([[\s*(?:\n\s*)+]])

local run_cmd = require("petzku.util").io.run_cmd

-- Search "local.*command" for all commands in AutoClip
local c = function(command)
    if jit.os == "Windows" then
        local i = 1
        for chunks in re_newline:gsplit(command, true) do
            if i == 1 then
                command = "try { & " .. chunks
            else
                command = command .. " ; if ($LASTEXITCODE -eq 0) {& " .. chunks .. "}"
            end
            i = i + 1
        end
        command = command .. " ; exit $LASTEXITCODE } catch { exit 1 }"
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
local p = function(path)
    if jit.os == "Windows" then
        path = string.gsub(path, "[", "`[")
        path = string.gsub(path, "]", "`]")
        path = string.gsub(path, "'", "''")
    else
        path = string.gsub(path, "'", "\\'")
    end
    return "'" .. path .. "'"
end



-- display_configurator and display_configurator derived functions
local dialog_welcome = adialog.new({ width = 30 })
                              :label({ label = "Welcome to AutoClip!" })
if jit.os == "Windows" then
    local dialog_python = adialog.new({ width = 30 })
                                 :label({ label = "Enter name to Python if it’s in PATH or under venv (`$ python3 --version`) or path to Python executable (`$ /path/to/python3.exe --version`):" })
                                 :edit({ name = "python" })
else
    local dialog_python = adialog.new({ width = 30 })
                                 :label({ label = "Enter name to Python if it’s in PATH or under venv (`$ python3 --version`) or path to Python executable (`$ /path/to/python3 --version`):" })
                                 :edit({ name = "python" })
end
if jit.os == "Windows" then
    local dialog_venv_activate = adialog.new({ width = 30 })
                                        :label({ label = "(Leave empty unless using Python with venv) Enter path to venv activate script (`$ /path/to/Activate.ps1`):" })
                                        :edit({ name = "venv_activate" })
else
    local dialog_venv_activate = adialog.new({ width = 30 })
                                        :label({ label = "(Leave empty unless using Python with venv) Enter path to venv activate script (`$ source /path/to/activate`):" })
                                        :edit({ name = "venv_activate" })
end
local dialog_vsrepo = adialog.new({ width = 30 })
                             :label({ label = "Select whether vsrepo is in PATH and enter either the name to vsrepo or path to vsrepo.py:" })
                             :dropdown({ name = "vsrepo_mode", items = { VSREPO_IN_PATH, PATH_TO_VSREPO } })
                             :edit({ name = "vsrepo" })
local dialog_no_python_with_vs do
    dialog_no_python_with_vs = adialog.new({ width = 30 })
    local subdialog = dialog_no_vsrepo:unlessable({ name = "venv_activate", value = "" })
    subdialog:label({ label = "Unable to activate venv or unable to import VapourSynth (`import vapoursynth`) in given environment." })
    local subdialog = dialog_no_vsrepo:ifable({ name = "venv_activate", value = "" })
    subdialog:label({ label = "Unable to find Python with VapourSynth (`import vapoursynth`) at given name or path." })
end
local dialog_no_vsrepo do
    dialog_no_vsrepo = adialog.new({ width = 30 })
    local subdialog = dialog_no_vsrepo:ifable({ name = "vsrepo_mode", value = VSREPO_IN_PATH })
    subdialog:label({ label = "Unable to find vsrepo with given name." })
    local subdialog = dialog_no_vsrepo:unlessable({ name = "vsrepo_mode", value = VSREPO_IN_PATH })
    subdialog:label({ label = "Unable to find vsrepo with given path." })
end
local dialog_two_warnings = adialog.new({ width = 30 })
                                   :label({ label = "Do you want to disable warning when the number of layers mismatches?" })
                                   :checkbox({ label = "Disable", name = "disable_layer_mismatch" })
                                   :label({ label = "Do you want to disable warning when Python script is outdated?" })
                                   :checkbox({ label = "Disable", name = "disable_version_notify" })

local buttons_set_cancel = abuttons.ok("&Set"):close("Cancel")
local buttons_continue_cancel = abuttons.ok("&Continue"):close("Cancel")
local buttons_apply_close = abuttons.ok("&Apply"):close("Close")

local display_configurator = function(dialog, buttons)
    local button, result = adisplay(dialog:load_data(config),
                                    buttons):resolve()
    if buttons:is_ok(button) then
        for k, v in pairs(result) do
            config[k] = v
        end
        aconfig.write_config("zah.autoclip", config)
            :ifErr(function()
                aegisub.debug.out("[aka.config] Failed to write config to file.\n")
                aegisub.debug.out("[aka.config] " .. error .. "\n") end)
        return ok()
    else
        return err("[zah.autoclip] Operation cancelled by user")
end end
local display_verified_configurator = function(dialog, buttons, command_f)
    if os.execute(c(command_f(config))) then
        return ok("Already satisfied")
    else
        return adisplay(dialog:load_data(config),
                        buttons)
            :repeatUntil(function(button, result)
                setmetatable(result, { __index = config })
                if os.execute(c(command_f(result))) then
                    return ok(result)
                else
                    return err(result)
                end end)
            :andThen(function(result)
                for k, v in pairs(result) do
                    config[k] = v
                end
                aconfig.write_config("zah.autoclip", config)
                    :ifErr(function()
                        aegisub.debug.out("[aka.config] Failed to write config to file.\n")
                        aegisub.debug.out("[aka.config] " .. error .. "\n") end)
                return ok() end)
end end

local command_f_check_python_with_vs_win = function(data) -- XXX CHECK THIS IS RUNNED THROUGH os.execute NOT THROUGH run_cmd
    return (data["venv_activate"] ~= "" and p(data["venv_activate"]) .. "\n" or "") ..
           p(data["python"]) .. " -m 'import vapoursynth'\n"
local command_f_check_python_with_vs_unix = function(data)
    return (data["venv_activate"] ~= "" and "source " .. p(data["venv_activate"]) .. "\n" or "") ..
           p(data["python"]) .. " -m 'import vapoursynth'\n"
local command_f_check_vsrepo_win = function(data)
    return (data["venv_activate"] ~= "" and p(data["venv_activate"]) .. "\n" or "") ..
           (data["vsrepo_mode"] == VSREPO_IN_PATH and
            p(data["vsrepo"]) .. " --help\n" or
            p(data["python"]) .. " " .. p(data["vsrepo"]) .. " --help\n")

local first_time_python_with_vsrepo_win = function()
    return display_configurator(dialog_welcome:copy():join(dialog_python):join(dialog_venv_activate):join(dialog_vsrepo),
                                buttons_set_cancel)
end
local first_time_python_unix = function()
    return display_configurator(dialog_welcome:copy():join(dialog_python):join(dialog_venv_activate),
                                buttons_set_cancel)
end
local check_python_with_vs_win = function()
    return display_verified_configurator(dialog_no_python_with_vs:copy():join(dialog_python):join(dialog_venv_activate),
                                         buttons_continue_cancel,
                                         command_f_check_python_with_vs_win)
end
local check_python_with_vs_unix = function()
    return display_verified_configurator(dialog_no_python_with_vs:copy():join(dialog_python):join(dialog_venv_activate),
                                         buttons_continue_cancel,
                                         command_f_check_python_with_vs_unix)
end
local check_vsrepo_win = function()
    return display_verified_configurator(dialog_no_vsrepo:copy():join(dialog_vsrepo),
                                         buttons_continue_cancel,
                                         command_f_check_vsrepo_win)
end
local edit_config_win = function()
    return display_configurator(dialog_python:copy():join(dialog_venv_activate):join(dialog_vsrepo):join(dialog_two_warnings),
                                buttons_apply_close)
end
local edit_config_unix = function()
    return display_configurator(dialog_python:copy():join(dialog_venv_activate):join(dialog_two_warnings),
                                buttons_apply_close)
end



-- display_runner and display_runner derived functions
local dialog_execution_error_label_resolver = {}
dialog_execution_error_label_resolver.resolve = function(item, dialog, x, y, width)
    item = Table.copy(item)
    item.class = "label"
    if dialog["data"]["terminate"] == "exit" then
        item.label = "Command execution exits with code " .. tostring(dialog["data"]["code"]) .. ":"
    else
        item.label = "Command execution terminated with signal " .. tostring(dialog["data"]["code"]) .. ":"
    end
    item.x = x
    item.y = y
    item.width = width
    table.insert(dialog, item)
    return item.y + 1
end
local dialog_click_run_again = adialog.new({ width = 40 })
                                      :label({ label = "You can edit the command below and click „Run Again“ to retry." })
local dialog_command = adialog.new({ width = 40 })
                              :textbox({ height = 12, name = "command" })

local buttons_run_again_cancel = abuttons.ok("&Run Again"):close("Cancel")

local display_runner_with_ignore = function(dialog, buttons)
    local button, result = adisplay(dialog:load_data(config),
                                    buttons):resolve()
    if buttons:is_ok(button) then
        local log, status, terminate, code = run_cmd(c(result["command"]), true)
        if status then
            return ok() -- XXX WRONG USE E() (I’ve no idea what this message meant when I left it.)
        else
            dialog = adialog.new({ width = 40 })
                            :load_data({ ["command"] = result["command"] })
                            :load_data({ ["log"] = log, ["status"] = status, ["terminate"] = terminate, ["code"] = code })
            table.insert(dialog, setmetatable({}, { __index = dialog_execution_error_label_resolver }))
            dialog:textbox({ height = 12, name = "log" })
                  :join(dialog_click_run_again)
                  :join(dialog_command)

            return adisplay(dialog, buttons_run_again_cancel)
                :repeatUntil(function(button, result)
                    local log, status, terminate, code = run_cmd(c(result["command"]), true)
                    if status then
                        return ok()
                    else
                        result["log"] = log result["status"] = status result["terminate"] = terminate result["code"] = code
                        return err(result)
                    end end)
        end
    elseif buttons:is_close(button) then
        return err("[zah.autoclip] Operation cancelled by user")
    elseif button == "Remind Me Next Time" then
        disable_version_notify_until_next_time = true
        return ok()
    elseif button == "Do Not Show Again" then
        config["disable_version_notify"] = true
        aconfig.write_config("zah.autoclip", config)
            :ifErr(function()
                aegisub.debug.out("[aka.config] Failed to write config to file.\n")
                aegisub.debug.out("[aka.config] " .. error .. "\n") end)
        return ok()
    else
        error("[zah.autoclip] Reach if else end")
end end
local display_runner = display_runner_with_ignore

local dialog_requires_install = adialog.new({ width = 40 })
                                       :label({ label = "AutoClip requires additional dependencies to be installed." })
local dialog_click_run = adialog.new({ width = 40 })
                                :label({ label = "Click „Run“ to execute the following commands. You may edit the command before running, or copy the command and execute it in terminal." })
local dialog_failed_to_execute = adialog.new({ width = 40 })
                                        :label({ label = "Failed to execute AutoClip." })
local dialog_click_run_and_reinstall = adialog.new({ width = 40 })
                                              :label({ label = "Click „Run“ to execute the following commands and reinstall AutoClip. You may edit the command before running, or copy the command and execute it in terminal." })
local dialog_out_of_date = adialog.new({ width = 40 })
                                  :label({ label = "AutoClip dependencies are out of date." })
local dialog_click_run_command_and_update = adialog.new({ width = 40 })
                                                   :label({ label = "Click „Run Command“ to execute the following commands and update AutoClip. You may edit the command before running, or copy the command and execute it in terminal." })
local dialog_unsupported = adialog.new({ width = 40 })
                                  :label({ label = "AutoClip dependencies are out of date and no longer supported." })

local dialog_requires_vs_dependencies = adialog.new({ width = 30 })
                                               :label({ label = "AutoClip requires additional VapourSynth plugins to be installed." })
local dialog_follow_install = adialog.new({ width = 30 })
                                               :label({ label = "Please follow the links below and install the required plugins." })
local dialog_update_requires_vs_dependencies = adialog.new({ width = 30 })
                                               :label({ label = "The newly installed version requires additional VapourSynth plugins to be installed." })

local buttons_run_cancel = abuttons.ok("&Run"):close("Cancel")
local buttons_cancel = abuttons.close("Cancel")
local buttons_run_command_ignore_cancel = abuttons.ok("&Run Command")("Remind Me Next Time")("Do Not Show Again"):close("Cancel")
local buttons_run_command_cancel = abuttons.ok("&Run Command"):close("Cancel")

local data_command_win = { ["command"] = function(_, data)
    return (data["venv_activate"] ~= "" and p(data["venv_activate"]) .. "\n" or "") ..
           p(data["python"]) .. " -m ensurepip\n" .. 
           p(data["python"]) .. " -m pip install numpy PySide6 scikit-image --upgrade --upgrade-strategy eager\n" .. 
           p(data["python"]) .. " -m pip install ass-autoclip --upgrade --force-reinstall\n" ..
           (data["vsrepo_mode"] == VSREPO_IN_PATH and
            p(data["vsrepo"]) .. " update\n" ..
            p(data["vsrepo"]) .. " install lsmas dfttest\n" ..
            p(data["vsrepo"]) .. " upgrade lsmas dfttest\n" or
            p(data["python"]) .. " " .. p(data["vsrepo"]) .. " update\n" ..
            p(data["python"]) .. " " .. p(data["vsrepo"]) .. " install lsmas dfttest\n" ..
            p(data["python"]) .. " " .. p(data["vsrepo"]) .. " upgrade lsmas dfttest\n") end }
local data_command_python_unix = { ["command"] = function(_, data)
            return (data["venv_activate"] ~= "" and "source " .. p(data["venv_activate"]) .. "\n" or "") ..
                   p(data["python"]) .. " -m ensurepip\n" .. 
                   p(data["python"]) .. " -m pip install numpy PySide6 scikit-image --upgrade --upgrade-strategy eager\n" .. 
                   p(data["python"]) .. " -m pip install ass-autoclip --upgrade --force-reinstall\n" end }
local data_command_vs_unix = { ["command"] = "lsmas (https://github.com/AkarinVS/L-SMASH-Works)\n" .. 
                                             "dfttest (https://github.com/HomeOfVapourSynthEvolution/VapourSynth-DFTTest)\n" }
local data_command_update_win = { ["command"] = function(_, data)
           return (data["venv_activate"] ~= "" and p(data["venv_activate"]) .. "\n" or "") ..
                  p(data["python"]) .. " -m pip install ass-autoclip --upgrade --upgrade-strategy eager\n" ..
                  (data["vsrepo_mode"] == VSREPO_IN_PATH and
                   p(data["vsrepo"]) .. " update\n" ..
                   p(data["vsrepo"]) .. " install lsmas dfttest\n" ..
                   p(data["vsrepo"]) .. " upgrade lsmas dfttest\n" or
                   p(data["python"]) .. " " .. p(data["vsrepo"]) .. " update\n" ..
                   p(data["python"]) .. " " .. p(data["vsrepo"]) .. " install lsmas dfttest\n" ..
                   p(data["python"]) .. " " .. p(data["vsrepo"]) .. " upgrade lsmas dfttest\n") end }
local data_command_python_update_unix = { ["command"] = function(_, data)
                   return (data["venv_activate"] ~= "" and "source " .. p(data["venv_activate"]) .. "\n" or "") ..
                          p(data["python"]) .. " -m pip install ass-autoclip --upgrade --upgrade-strategy eager\n" end }

local command_f_check_dependencies_win = function(data) -- XXX CHECK THIS IS RUNNED THROUGH os.execute NOT THROUGH run_cmd
    return (data["venv_activate"] ~= "" and p(data["venv_activate"]) .. "\n" or "") ..
           p(data["python"]) .. " -m ass_autoclip --check-dependencies\n"
local command_f_check_dependencies_unix = function(data)
    return (data["venv_activate"] ~= "" and "source " .. p(data["venv_activate"]) .. "\n" or "") ..
           p(data["python"]) .. " -m ass_autoclip --check-dependencies\n"
local command_f_check_python_dependencies_unix = function(data)
    return (data["venv_activate"] ~= "" and "source " .. p(data["venv_activate"]) .. "\n" or "") ..
           p(data["python"]) .. " -m ass_autoclip --check-python-dependencies\n"
local command_f_check_vs_dependencies_unix = function(data)
    return (data["venv_activate"] ~= "" and "source " .. p(data["venv_activate"]) .. "\n" or "") ..
           p(data["python"]) .. " -m ass_autoclip --check-vs-dependencies\n"

local first_time_dependencies_win = function()
    local dialog
    local result
    while not os.execute(c(command_f_check_dependencies_win(config))) do
        if not dialog then
            dialog = adialog.new({ width = 40 })
                            :join(dialog_requires_install)
                            :join(dialog_click_run)
                            :join(dialog_command)
                            :load_data(data_command_win)
        end
        result = display_runner(dialog, buttons_run_cancel)
        if result:isErr() then return result end
    end
    return result or ok("Already satisfied")
end

local first_time_python_dependencies_unix = function()
    local dialog
    local result
    while not os.execute(c(command_f_check_python_dependencies_unix(config))) do
        if not dialog then
            dialog = adialog.new({ width = 40 })
                            :join(dialog_requires_install)
                            :join(dialog_click_run)
                            :join(dialog_command)
                            :load_data(data_command_python_unix)
        end
        result = display_runner(dialog, buttons_run_cancel)
        if result:isErr() then return result end
    end
    return result or ok("Already satisfied")
end

local first_time_vs_dependencies_unix = function()
    if not os.execute(c(command_f_check_vs_dependencies_unix(config))) then
        adisplay(adialog.new({ width = 30 })
                         :join(dialog_requires_vs_dependencies)
                         :join(dialog_follow_install)
                         :join(dialog_command)
                         :load_data(data_command_vs_unix),
                 buttons_cancel):resolve()
        return err()
    end
    return ok("Already satisfied")
end

local no_dependencies_win = function()
    local dialog
    local result
    while not os.execute(c(command_f_check_dependencies_win(config))) do
        if not dialog then
            dialog = adialog.new({ width = 40 })
                            :join(dialog_failed_to_execute)
                            :join(dialog_click_run_and_reinstall)
                            :join(dialog_command)
                            :load_data(data_command_win)
        end
        result = display_runner(dialog, buttons_run_cancel)
        if result:isErr() then return result end
    end
    return result or ok("Already satisfied")
end

local no_python_dependencies_unix = function()
    local dialog
    local result
    while not os.execute(c(command_f_check_python_dependencies_unix(config))) do
        if not dialog then
            dialog = adialog.new({ width = 40 })
                            :join(dialog_failed_to_execute)
                            :join(dialog_click_run_and_reinstall)
                            :join(dialog_command)
                            :load_data(data_command_python_unix)
        end
        result = display_runner(dialog, buttons_run_cancel)
        if result:isErr() then return result end
    end
    return result or ok("Already satisfied")
end

local no_vs_dependencies_unix = function()
    if not os.execute(c(command_f_check_vs_dependencies_unix(config))) then
        adisplay(adialog.new({ width = 30 })
                        :join(dialog_failed_to_execute)
                        :join(dialog_follow_install)
                        :join(dialog_command)
                        :load_data(data_command_vs_unix),
                 buttons_cancel):resolve()
        return err()
    end
    return ok("Already satisfied")
end

local out_of_date_dependencies_win = function()
    local dialog = adialog.new({ width = 40 })
                          :join(dialog_out_of_date)
                          :join(dialog_click_run_command_and_update)
                          :join(dialog_command)
                          :load_data(data_command_update_win)
    return display_runner_with_ignore(dialog, buttons_run_command_ignore_cancel)
end

local out_of_date_python_dependencies_unix = function()
    local dialog = adialog.new({ width = 40 })
                          :join(dialog_out_of_date)
                          :join(dialog_click_run_command_and_update)
                          :join(dialog_command)
                          :load_data(data_command_python_update_unix)
    return display_runner_with_ignore(dialog, buttons_run_command_ignore_cancel)
end

local update_dependencies_win = function()
    local dialog = adialog.new({ width = 40 })
                          :join(dialog_click_run)
                          :join(dialog_command)
                          :load_data(data_command_update_win)
    return display_runner_with_ignore(dialog, buttons_run_cancel)
end

local update_python_dependencies_unix = function()
    local dialog = adialog.new({ width = 40 })
                          :join(dialog_click_run)
                          :join(dialog_command)
                          :load_data(data_command_python_update_unix)
    return display_runner_with_ignore(dialog, buttons_run_cancel)
end

local update_precheck_vs_dependencies_unix = function()
    return os.execute(c(command_f_check_vs_dependencies_unix(config)))
end

local update_vs_dependencies_unix = function()
    if not os.execute(c(command_f_check_vs_dependencies_unix(config))) then
        adisplay(adialog.new({ width = 30 })
                        :join(dialog_update_requires_vs_dependencies)
                        :join(dialog_follow_install)
                        :join(dialog_command)
                        :load_data(data_command_vs_unix),
                 buttons_cancel):resolve()
        return err()
    end
    return ok("Already satisfied")
end

local unsupported_dependencies_win = function()
    local dialog = adialog.new({ width = 40 })
                          :join(dialog_unsupported)
                          :join(dialog_click_run_command_and_update)
                          :join(dialog_command)
                          :load_data(data_command_update_win)
    return display_runner(dialog, buttons_run_command_cancel)
end

local unsupported_python_dependencies_unix = function()
    local dialog = adialog.new({ width = 40 })
                          :join(dialog_unsupported)
                          :join(dialog_click_run_command_and_update)
                          :join(dialog_command)
                          :load_data(data_command_python_update_unix)
    return display_runner(dialog, buttons_run_command_cancel)
end



-- main functions
local first_time_python_vsrepo_main = function()
    if not config then
        if lfs.attributes(aconfig.config_dir .. "/zah.autoclip.json", "mode") then
            config = aconfig:read_and_validate_config_if_empty_then_default_or_else_edit_and_save("zah.autoclip", validation_func)
                :ifErr(aegisub.cancel)
                :unwrap()
        else
            config = aconfig:read_and_validate_config_if_empty_then_default_or_else_edit_and_save("zah.autoclip", validation_func)
                :ifErr(aegisub.cancel)
                :unwrap()

            if jit.os == "Windows" then
                ok():andThen(first_time_python_with_vsrepo_win)
                    :andThen(check_python_with_vs_win)
                    :andThen(check_vsrepo_win)
                    :andThen(first_time_dependencies_win)
                    :ifErr(aegisub.cancel)
            else
                ok():andThen(first_time_python_unix)
                    :andThen(check_python_with_vs_unix)
                    :andThen(first_time_python_dependencies_unix)
                    :andThen(first_time_vs_dependencies_unix)
                    :ifErr(aegisub.cancel)
end end end end

local no_dependencies_main = function()
    if jit.os == "Windows" then
        if os.execute(c(command_f_check_dependencies_win(config))) then
            return "Already satisfied"
        else
            ok():andThen(check_python_with_vs_win)
                :andThen(check_vsrepo_win)
                :andThen(no_dependencies_win)
                :ifErr(aegisub.cancel)
        end
    else
        if os.execute(c(command_f_check_dependencies_unix(config))) then
            return "Already satisfied"
        else
            ok():andThen(check_python_with_vs_unix)
                :andThen(no_python_dependencies_unix)
                :andThen(no_vs_dependencies_unix)
                :ifErr(aegisub.cancel)
end end end

local out_of_date_dependencies_main = function()
    if jit.os == "Windows" then
        ok():andThen(out_of_date_dependencies_win)
            :ifErr(aegisub.cancel)
    else
        if update_precheck_vs_dependencies_unix() then
            ok():andThen(out_of_date_python_dependencies_unix)
                :andThen(update_vs_dependencies_unix)
                :ifErr(aegisub.cancel)
        else
            ok():andThen(out_of_date_python_dependencies_unix)
                :andThen(no_vs_dependencies_unix)
                :ifErr(aegisub.cancel)
end end end

local unsupported_dependencies_main = function()
    if jit.os == "Windows" then
        ok():andThen(unsupported_dependencies_win)
            :ifErr(aegisub.cancel)
    else
        if update_precheck_vs_dependencies_unix() then
            ok():andThen(unsupported_python_dependencies_unix)
                :andThen(update_vs_dependencies_unix)
                :ifErr(aegisub.cancel)
        else
            ok():andThen(unsupported_python_dependencies_unix)
                :andThen(no_vs_dependencies_unix)
                :ifErr(aegisub.cancel)
end end end

local autoclip_main = function(sub, sel, act)
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
        Aegi.progressCancelled()
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
    ::run_again::

    Aegi.progressCancelled()
    Aegi.progressTitle("Waiting for Python to complete")
    local output_file
    local command -- ↓
    local log
    local status
    local terminate
    local code
    local f
    local msg
    local output
    
    output_file = aegisub.decode_path("?temp/zah.autoclip." .. string.sub(tostring(math.random(10000000, 99999999)), 2) .. ".json")
    command = (data["venv_activate"] ~= "" and p(data["venv_activate"]) .. "\n" or "") ..
              p(data["python"]) .. " -m ass_autoclip --input " .. p(video_file) ..
                                   " --output " .. p(output_file) ..
                     string.format(" --clip '%f %f %f %f'", clip[1], clip[2], clip[3], clip[4]) ..
                                   " --first " .. first ..
                                   " --last " .. last ..
                                   " --active " .. active ..
                                   " --supported-version " .. ((not disable_version_notify_until_next_time and not config["disable_version_notify"]) and
                                                               script_version or
                                                               last_supported_script_version)
    log, status, terminate, code = run_cmd(c(command), true)

    Aegi.progressCancelled()
    Aegi.progressTitle("Parsing output from Python")
    if not status then
        if no_dependencies_main() ~= "Already satisfied" then
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
                unsupported_dependencies_main()
            elseif V(output["current_version"]) < V(script_version) then
                out_of_date_dependencies_main()
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
        Aegi.progressCancelled()
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

local update_dependencies_main = function()
    first_time_python_vsrepo_main()

    if jit.os == "Windows" then
        ok():andThen(update_dependencies_win)
            :ifErr(aegisub.cancel)
    else
        if update_precheck_vs_dependencies_unix() then
            ok():andThen(update_python_dependencies_unix)
                :andThen(update_vs_dependencies_unix)
                :ifErr(aegisub.cancel)
        else
            ok():andThen(update_python_dependencies_unix)
                :andThen(no_vs_dependencies_unix)
                :ifErr(aegisub.cancel)
end end end

local edit_config_main = function()
    first_time_python_vsrepo_main()

    if jit.os == "Windows" then
        ok():andThen(edit_config_win)
            :ifErr(aegisub.cancel)
    else
        ok():andThen(edit_config_unix)
            :ifErr(aegisub.cancel)
end end


DepCtrl:registerMacros({
    { "AutoClip", script_description, autoclip_main },
    { "Update Dependencies", "Update AutoClip dependencies", update_dependencies_main },
    { "Configure AutoClip", "Configure AutoClip", edit_config_main }
})
