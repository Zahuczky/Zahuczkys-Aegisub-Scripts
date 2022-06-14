local tr = aegisub.gettext

script_name = tr"Aegisub-Color-Tracking"
script_description = tr"Tracking the color from a given pixel or tracking data"
script_author = "Zahuczky"
script_version = "1.0.1"
script_namespace = "zah.aegi-color-track"

-- Conditional depctrl support. Will work without depctrl.
local haveDepCtrl, DependencyControl, depCtrl = pcall(require, "l0.DependencyControl")
local ConfigHandler, config, petzku, pngModule, deflatelua
if haveDepCtrl then
    depCtrl = DependencyControl {
        feed="https://raw.githubusercontent.com/Zahuczky/Zahuczkys-Aegisub-Scripts/main/DependencyControl.json",
        {
            {"petzku.util", version="0.3.0", url="https://github.com/petzku/Aegisub-Scripts",
             feed="https://raw.githubusercontent.com/petzku/Aegisub-Scripts/stable/DependencyControl.json"},
            {"a-mo.ConfigHandler", version= "1.1.4", url= "https://github.com/TypesettingTools/Aegisub-Motion",
             feed= "https://raw.githubusercontent.com/TypesettingTools/Aegisub-Motion/DepCtrl/DependencyControl.json"},
            {"zah.png", version="1.0.1", url="https://github.com/Zahuczky/Zahuczkys-Aegisub-Scripts",
             feed="https://raw.githubusercontent.com/Zahuczky/Zahuczkys-Aegisub-Scripts/main/DependencyControl.json"},
            {"zah.deflatelua", version="1.0.1", url="https://github.com/Zahuczky/Zahuczkys-Aegisub-Scripts",
             feed="https://raw.githubusercontent.com/Zahuczky/Zahuczkys-Aegisub-Scripts/main/DependencyControl.json"}
        }
    }
    petzku, ConfigHandler, pngModule, deflatelua = depCtrl:requireModules()
else
    petzku = require 'petzku.util'
    ConfigHandler = require 'a-mo.ConfigHandler'
    pngModule = require 'zah.png'
    deflatelua = require 'zah.deflatelua'
end

local pngImage = pngModule.pngImage

local pathsep = package.config:sub(1, 1)
local tmp = aegisub.decode_path("?temp")..pathsep.."aegisub-color-tracking"

local GUI = {
    main= {
      data_label = {class= "label",  x= 0, y= 0, width= 1, height= 1, label= "Tracking data"},
      data = {class= "textbox", name="data",  x= 0, y= 1, width= 2, height= 3},
      pixel_label = {class= "label",  x= 0, y= 4, width= 1, height= 1, label= "Defined pixel to track:"},
      pixX = {class= "intedit", config=true,  x= 0, y= 5, width= 1, height= 1, value= 0},
      pixY = {class= "intedit", config=true,  x= 0, y= 6, width= 1, height= 1, value= 0},
      posx_label = {class= "label",  x= 1, y= 5, width= 1, height= 1, label= "Position X"},
      posy_label = {class= "label",  x= 1, y= 6, width= 1, height= 1, label= "Position Y"},
      c = {class= "checkbox", x= 0, y= 7, width= 1, config=true, height= 1, label= "\\c (fill)", value= true},
      c2 = {class= "checkbox", x= 1, y= 7, width= 1, config=true, height= 1, label= "\\2c (secondary)", value= false},
      c3 = {class= "checkbox", x= 0, y= 8, width= 1, config=true, height= 1, label= "\\3c (border)", value= false},
      c4 = {class= "checkbox", x= 1, y= 8, width= 1, config=true, height= 1, label= "\\4c (shadow)", value= false},
      setting = {class= "dropdown",  x= 0, y= 9, width= 2, height= 1, config=true, items= {"Defined pixels","Tracking Data"}, value= "Defined pixels"}
      }

}

-- GUI inicialization with config
local function showDialog(macro)
  local options = ConfigHandler(GUI, depCtrl.configFile, false, script_version, depCtrl.configDir)
  options:read()
  options:updateInterface(macro)
  local btn, res = aegisub.dialog.display(GUI[macro])
  if btn then
    options:updateConfiguration(res, macro)
    options:write()
    return res
  end
end

local function getTimes(line)
  local starterMS = line.start_time
  local enderMS = line.end_time
  local startframe = aegisub.frame_from_ms(starterMS)
  local endframe = aegisub.frame_from_ms(enderMS)
  local startMS = aegisub.ms_from_frame(startframe)
  local endMS = aegisub.ms_from_frame(endframe)

  local startS = math.floor(startMS / 1000)
  local startM = math.floor(startS / 60)
  local startH = math.floor(startM / 60)

  startS = startS % 60
  startM = startM % 60

  local startRem = startMS - (1000 * (startS + 60 * (startM + 60 * startH)))

  local starttime = string.format("%d:%02d:%02d.%03d", startH, startM, startS, startRem)
  if starterMS == 0 then starttime = "0:00:00" end

  local endS = math.floor(endMS / 1000)
  local endM = math.floor(endS / 60)
  local endH = math.floor(endM / 60)

  endS = endS % 60
  endM = endM % 60

  local endRem = endMS - (1000 * (endS + 60 * (endM + 60 * endH)))

  local endtime = string.format("%d:%02d:%02d.%03d", endH, endM, endS, endRem)

  local numOfFrames = endframe-startframe

  return starttime, endtime, numOfFrames
end

local function trimFrames(starttime, endtime)
  petzku.io.run_cmd("mkdir "..tmp, true)

  -- Trim selected line out, to full frame PNGs
  petzku.io.run_cmd(
    string.format(
      "ffmpeg -ss %s -to %s -i \"%s\" -pix_fmt rgb24 \"%s\"",
      starttime, endtime,
      aegisub.project_properties().video_file,
      tmp .. pathsep .. "frame%%d.png"
    ),
    true
  )
end

local function cropPixels(numOfFrames, XPixArray, YPixArray)
  -- Crop full frames into the pixel we actually want
  local ffbatchstring = ""
  for i=1,numOfFrames do
    local infile = tmp..pathsep.."frame"..i..".png"
    local outfile = tmp..pathsep.."pixel"..i..".png"
    local crop = "crop=2:2:"..XPixArray[i]..":"..YPixArray[i]

    ffbatchstring = ffbatchstring.."ffmpeg -loglevel warning -i \""..infile.."\" -filter:v \""..crop.."\"".." \""..outfile.."\"\n"
  end
  petzku.io.run_cmd(ffbatchstring, true)

  local fileNames = {}

  for i=1, numOfFrames do
    fileNames[i] = "pixel"..i..".png"
  end

  local trackedImg = {}

  for i=1, numOfFrames do trackedImg[i] = tmp..pathsep..fileNames[i] end
  return trackedImg
end


-- Main function
function colortrack(subtitles, selected_lines, active_line)
  -- Assume the whole selection is the same length
  local line = subtitles[selected_lines[1]]
  -- Start gui
  local res = showDialog("main")
  if not (res) then
    return aegisub.cancel()
  end

  -- Delete old temp files
  -- While the script is still running the pixel.png's can't be deleted, because they're considered open.
  local j = 1
  while (os.remove(tmp..pathsep.."pixel"..j..".png")) ~= nil do
    os.remove(tmp..pathsep.."frame"..j..".png")
    os.remove(tmp..pathsep.."pixel"..j..".png")
    j=j+1
  end

  -- Calculate frame perfect times for trimming
  local starttime, endtime, numOfFrames = getTimes(line)

  -- Settings
  local XPixArray = { }
  local YPixArray = { }
  if res.setting == "Tracking Data" then
    local dataArray = { }
    local j = 1
    for i in string.gmatch(res.data, "([^\n]*)\n?") do
      dataArray[j] = i
      j = j + 1
    end
    if res.data == "" then
      aegisub.debug.out("You forgot to give me any data, so I quit.\n\n")
      return aegisub.cancel()
    elseif dataArray[9] ~= "Position" then
      aegisub.debug.out("I have no idea what kind of data you pasted in, but I'm sure it's not what I wanted.\n\nI need After Effects Transform data.\n\nThe same thing you use for Aegisub-Motion.\n\n")
      return aegisub.cancel()
    end

    -- Parsing tracking data
    local posPin = 11
    local dataLength = numOfFrames + 11
    local p = 1
    local helpArray = { }
    for l = posPin, dataLength do
      local o = 1
      for token in string.gmatch(dataArray[l], "%S+") do
        helpArray[o] = token
        o = o + 1
      end
      XPixArray[p] = math.floor(helpArray[2])
      YPixArray[p] = math.floor(helpArray[3])
      p = p + 1
    end
  end

  for i=1, numOfFrames do
    if res.setting == "Defined pixels" then XPixArray[i] = res.pixX end
    if res.setting == "Defined pixels" then YPixArray[i] = res.pixY end
  end

  -- if res.setting == "Middle of Rect. Clip" then
  --   if line.text:match("clip") and not line.text:match("clip(m") then
  --     for topX, topY, botX, botY in line.text:gmatch("([-%d.]+).([-%d.]+)") end
  --     for i=1, numOfFrames do
  --       XPixArray[i] = (botX-topX)/2
  --       XPixArray[i] = (botY-topY)/2
  --     end

  --   else
  --     aegisub.debug.out("You don't have a rectangular clip in your line, so I quit.")
  --     aegisub.cancel()
  --   end
  -- end



  --aegisub.debug.out("\n\n\n\nvideo path: "..aegisub.decode_path("?video").."\n\n\n\n"..aegisub.project_properties().video_file.."\n\n\n"..aegisub.decode_path("?temp").."\n\n\n")

  trimFrames(starttime, endtime)
  local trackedImg = cropPixels(numOfFrames, XPixArray, YPixArray)

  -- use png-lua to decode the images
  local reds = {}
  local greens = {}
  local blues = {}


  for i=1, numOfFrames do
    local img = pngImage(trackedImg[i], nil, true)
    local pixel = img.pixels[1][1]
    reds[i] = pixel.R
    greens[i] = pixel.G
    blues[i] = pixel.B
  end

  local function calcTransformTime(i)
    -- Getting accurate times for the \t transform. Thx petzku. :*
    local t_start_frame = aegisub.frame_from_ms(line.start_time)
    local t_start_time = aegisub.ms_from_frame(t_start_frame)
    local ft = aegisub.ms_from_frame(t_start_frame + i) - t_start_time --frame time
    return ft
  end

  local function makeTransformTimes(i)
    local t = calcTransformTime(i)
    return t..","..t..","
  end

  local function makeColorTags(i)
    local c = string.format("&H%02X%02X%02X&", blues[i], greens[i], reds[i])
    local ret = ""
    if res.c then
      ret = ret .. "\\c" .. c
    end
    if res.c2 then
      ret = ret .. "\\2c" .. c
    end
    if res.c3 then
      ret = ret .. "\\3c" .. c
    end
    if res.c4 then
      ret = ret .. "\\4c" .. c
    end
    return ret
  end

  -- Creating a single string from the colors
  local transform = makeColorTags(1)
  for i=2, numOfFrames do
    transform = transform.."\\t("..makeTransformTimes(i-1)..makeColorTags(i)..")"
  end

  -- Put the string in the lines
  for _, si in ipairs(selected_lines) do
    local l = subtitles[si]
    if l.text:match("\\pos") then
      l.text = l.text:gsub("\\pos", transform.."\\pos")
    elseif l.text:match("\\move") then
      l.text = l.text:gsub("\\move", transform.."\\move")
    else
      l.text = l.text:gsub("}", transform.."}", 1)
    end
    subtitles[si] = l
  end

  -- aegisub.debug.out("-----Test-----")
  -- if (testVal.width ~= img.width) then
    -- error("Test failed: width")
  -- elseif (testVal.height ~= img.height) then
    -- error("Test failed: height")
  -- elseif (testVal.depth ~= img.depth) then
    -- error("Test failed: depth")
  -- elseif (testVal.pixelColor ~= getPixelStr(pixel)) then
    -- error("Test failed: color")
  -- else
    -- aegisub.debug.out("Tests passed!")
  -- end



  -- aegisub.debug.out("it works!  R:"..mypixel1.."\n G:"..mypixel2.."\n B:"..mypixel3)
  -- aegisub.debug.out("\n\nstart time: "..starttime.."\n end time: "..endtime)
  -- aegisub.debug.out("\n\nstart frame: "..startframe.."\n end frame: "..endframe)
  -- aegisub.debug.out("\n\nlengthframe: "..endframe-startframe)

  -- os.remove("C:\\Users\\zozic\\AppData\\Roaming\\Aegisub\\log\\frame0001.png")


  -- for i=1, numOfFrames do
  --   runTests(trackedImg, i)
  -- end

  -- aegisub.debug.out("first: "..reds[1].." - "..greens[1].." - "..blues[1])
  -- aegisub.debug.out("\n\nsecond: "..reds[2].." - "..greens[2].." - "..blues[2])
  -- aegisub.debug.out("first: "..fillHexTable[1])
  -- aegisub.debug.out("\nsecond: "..fillHexTable[2])
  -- aegisub.debug.out("works: \n"..transform)

  -- I don't remember what it does and might not even be needed anymore but whatever I'm lazy to test it.
  aegisub.set_undo_point(script_name)
end



-- Register the macro, with depctrl if you have, regularly if you don't.
if haveDepCtrl then
  return depCtrl:registerMacro(colortrack)
else
  return aegisub.register_macro(script_name, script_description, colortrack)
end
