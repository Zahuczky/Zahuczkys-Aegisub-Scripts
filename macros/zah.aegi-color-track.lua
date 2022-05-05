local tr = aegisub.gettext

script_name = tr"Aegisub-Color-Tracking"
script_description = tr"Tracking the color from a given pixel or tracking data"
script_author = "Zahuczky"
script_version = "1.0.0"
script_namespace = "zah.aegi-color-track"

-- Conditional depctrl support. Will work without depctrl.
local haveDepCtrl, DependencyControl, depCtrl = pcall(require, "l0.DependencyControl")
local ConfigHandler, config, petzku
if haveDepCtrl then
    depCtrl = DependencyControl {
        feed="https://github.com/Zahuczky/Zahuczkys-Aegisub-Scripts/blob/main/DependencyControl.json",
        {
            {"petzku.util", version="0.3.0", url="https://github.com/petzku/Aegisub-Scripts",
             feed="https://raw.githubusercontent.com/petzku/Aegisub-Scripts/stable/DependencyControl.json"},
            {"a-mo.ConfigHandler", version= "1.1.4", url= "https://github.com/TypesettingTools/Aegisub-Motion",
             feed= "https://raw.githubusercontent.com/TypesettingTools/Aegisub-Motion/DepCtrl/DependencyControl.json"},
            {"zah.png", version="1.0.0", url="https://github.com/Zahuczky/Zahuczkys-Aegisub-Scripts",
             feed="https://raw.githubusercontent.com/Zahuczky/Zahuczkys-Aegisub-Scripts/main/DependencyControl.json"},
            {"zah.deflatelua", version="1.0.0", url="https://github.com/Zahuczky/Zahuczkys-Aegisub-Scripts",
             feed="https://raw.githubusercontent.com/Zahuczky/Zahuczkys-Aegisub-Scripts/main/DependencyControl.json"}
        }
    }
    petzku, ConfigHandler = depCtrl:requireModules()
else
    petzku = require 'petzku.util'
    ConfigHandler = require 'a-mo.ConfigHandler'
    pngImage = require 'zah.png'
    pngdeflatelua = 'zah.deflatelua'
end


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
local showDialog
showDialog = function(macro)
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

-- Main function
function colortrack(subtitles, selected_lines, active_line)
  line = subtitles[selected_lines[1]]
  -- Start gui
  local res = showDialog("main")
  if not (res) then
    return aegisub.cancel()
  end

  tmp = aegisub.decode_path("?temp").."\\aegisub-color-tracking"

-- Delete old temp files
-- While the script is still running the pixel.png's can't be deleted, because they're considered open.
  j = 1
  while (os.remove(tmp.."\\pixel"..j..".png")) ~= nil do
    os.remove(tmp.."\\frame"..j..".png")
    os.remove(tmp.."\\pixel"..j..".png")
    j=j+1
  end

-- Calculate frame perfect times for trimming
  local starterMS = subtitles[selected_lines[1]].start_time
  local enderMS = subtitles[selected_lines[1]].end_time
  local startframe = aegisub.frame_from_ms(starterMS)
  local endframe = aegisub.frame_from_ms(enderMS)
  local startMS = aegisub.ms_from_frame(startframe)
  local endMS = aegisub.ms_from_frame(endframe)

  local startS = math.floor(startMS / 1000)
  local startM = math.floor(startS / 60)
  local startH = math.floor(startM / 60)

  startS = startS % 60
  startM = startM % 60

  local startRem = startMS - (startS*1000) - (startM*60) - (startH*60)

  local starttime = startH..":"..startM..":"..startS.."."..startRem
  if starterMS == 0 then starttime = "0:00:00" end

  local endS = math.floor(endMS / 1000)
  local endM = math.floor(endS / 60)
  local endH = math.floor(endM / 60)

  endS = endS % 60
  endM = endM % 60

  local endRem = endMS - (endS*1000) - (endM*60) - (endH*60)

  local endtime = endH..":"..endM..":"..endS.."."..endRem

  numOfFrames = endframe-startframe


-- Settings
  XPixArray = { }
  YPixArray = { }
  if res.setting == "Tracking Data" then
    dataArray = { }
    local j = 1
    for i in string.gmatch(res.data, "([^\n]*)\n?") do
      dataArray[j] = i
      j = j + 1
    end
    if res.setting == "Tracking Data" and res.data == "" then
      aegisub.debug.out("You forgot to give me any data, so I quit.\n\n")
      return aegisub.cancel()
    elseif res.setting == "Tracking Data" and dataArray[9] ~= "Position" then
      aegisub.debug.out("I have no idea what kind of data you pasted in, but I'm sure it's not what I wanted.\n\nI need After Effects Transform data.\n\nThe same thing you use for Aegisub-Motion.\n\n")
      return aegisub.cancel()
    end

-- Parsing tracking data
    posPin = 11
    dataLength = numOfFrames + 11
    p = 1
    helpArray = { }
    for l = posPin, dataLength do
      o = 1
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

    else
      aegisub.debug.out("You don't have a rectangular clip in your line, so I quit.")
      aegisub.cancel()
    end
  end



  --aegisub.debug.out("\n\n\n\nvideo path: "..aegisub.decode_path("?video").."\n\n\n\n"..aegisub.project_properties().video_file.."\n\n\n"..aegisub.decode_path("?temp").."\n\n\n")

  tmp = aegisub.decode_path("?temp").."\\aegisub-color-tracking"

  petzku.io.run_cmd("mkdir "..tmp, true)

-- Trim selected line out, to full frame PNGs
  petzku.io.run_cmd("ffmpeg -i "..aegisub.project_properties().video_file.." -ss "..starttime.." -to "..endtime.." "..tmp.."\\frame%%d.png", true)

-- Crop full frames into the pixel we actually want
  ffbatchstring = ""
  for i=1,numOfFrames do
    ffbatchstring = ffbatchstring.."ffmpeg -loglevel warning -i "..tmp.."\\frame"..i..".png -filter:v \"crop=2:2:"..XPixArray[i]..":"..YPixArray[i].."\"".." "..tmp.."\\pixel"..i..".png\n"
  end
  petzku.io.run_cmd(ffbatchstring, true)

  fileNames = {}

  for i=1, numOfFrames do
    fileNames[i] = "pixel"..i..".png"
  end

	local pngImage = require 'zah.png'

  trackedImg = {}

	for i=1, numOfFrames do trackedImg[i] = tmp.."\\"..fileNames[i] end

-- I have no idea what this is but it doesn't work without it
	function printProg(line, totalLine)
		-- aegisub.debug.out(line .. " of " .. totalLine)
	end
-- use png-lua to decode the images
	local function getPixelStr(pixel)
		return string.format("R: %d, G: %d, B: %d, A: %d", pixel.R, pixel.G, pixel.B, pixel.A)
	end

  reds = {}
  greens = {}
  blues = {}


  for i=1, numOfFrames do
  	img = pngImage(trackedImg[i], printProg, true)
  	pixel = img.pixels[1][1]
    redpix = tostring(pixel.R)
    greenpix = tostring(pixel.G)
    bluepix = tostring(pixel.B)
    reds[i] = tonumber(redpix)
    greens[i] = tonumber(greenpix)
    blues[i] = tonumber(bluepix)
  end

-- Turn the decimal color values into HEX numbers.
  function DEC_HEX(IN)
    local B,K,OUT,I,D=16,"0123456789ABCDEF","",0
    while IN>0 do
        I=I+1
        IN,D=math.floor(IN/B),math.fmod(IN,B)+1
        OUT=string.sub(K,D,D)..OUT
    end
    return OUT
  end

  redHEX = {}
  greenHEX = {}
  blueHEX = {}

-- Format the numbers to the aegisub color format which is HEX \\c&HBBGGRR&
  for i=1, numOfFrames do
    redHEX[i] = tostring(DEC_HEX(reds[i]))
    greenHEX[i] = tostring(DEC_HEX(greens[i]))
    blueHEX[i] = tostring(DEC_HEX(blues[i]))
    if #redHEX[i] == 1 then redHEX[i] = "0"..redHEX[i] end
    if #greenHEX[i] == 1 then greenHEX[i] = "0"..greenHEX[i] end
    if #blueHEX[i] == 1 then blueHEX[i] = "0"..blueHEX[i] end
    if redHEX[i] == 0 or redHEX[i] == nil or redHEX[i] == "" then redHEX[i] = "00" end
    if greenHEX[i] == 0 or greenHEX[i] == nil or greenHEX[i] == "" then greenHEX[i] = "00" end
    if blueHEX[i] == 0 or blueHEX[i] == nil or blueHEX[i] == "" then blueHEX[i] = "00" end
  end


--Put the colors into every table. This is suboptimal but I'm lazy to change it and it's not like it does any harm.
  fillHexTable = {}
  secoHexTable = {}
  bordHexTable = {}
  shadHexTable = {}
  for i=1,numOfFrames do
    fillHexTable[i] = "\\c&H"..blueHEX[i]..greenHEX[i]..redHEX[i].."&"
    secoHexTable[i] = "\\2c&H"..blueHEX[i]..greenHEX[i]..redHEX[i].."&"
    bordHexTable[i] = "\\3c&H"..blueHEX[i]..greenHEX[i]..redHEX[i].."&"
    shadHexTable[i] = "\\4c&H"..blueHEX[i]..greenHEX[i]..redHEX[i].."&"
  end

-- Delete the colors from the tables if they're not needed. I told yo this is stupid.
  for i=1,numOfFrames do
    if res.c == false then fillHexTable[i] = "" end
    if res.c2 == false then secoHexTable[i] = "" end
    if res.c3 == false then bordHexTable[i] = "" end
    if res.c4 == false then shadHexTable[i] = "" end
  end

-- Getting accurate times for the \t transform. Thx petzku. :*
  transformtimes = {}
  local t_start_frame = aegisub.frame_from_ms(subtitles[selected_lines[1]].start_time)
  local t_start_time = aegisub.ms_from_frame(start_frame)
  for i=1, numOfFrames do
    local ft = aegisub.ms_from_frame(t_start_frame + i) - t_start_time --frame time
    transformtimes[i] = ft..","..ft..","
  end
  -- for i=1,numOfFrames do
  --   transformtimes[i] = oneframe*i..","..oneframe*i..","
  -- end

-- Creating a single string from the color tables
  transform = fillHexTable[1]..secoHexTable[1]..bordHexTable[1]..shadHexTable[1]
  for i=2, numOfFrames do
    transform = transform.."\\t("..transformtimes[i-1]..fillHexTable[i]..secoHexTable[i]..bordHexTable[i]..shadHexTable[i]..")"
  end

-- Put the string in the line
  line.text = line.text:gsub("\\pos", transform.."\\pos")
  subtitles[selected_lines[1]] = line

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
--  aegisub.debug.out("works: \n"..transform)

-- I don't remember what it does and might not even be needed anymore but whatever I'm lazy to test it.
	aegisub.set_undo_point(script_name)
end



-- Register the macro, with depctrl if you have, regularly if you don't.
if haveDepCtrl then
  return depCtrl:registerMacro(colortrack)
else
  return aegisub.register_macro(script_name, script_description, colortrack)
end
