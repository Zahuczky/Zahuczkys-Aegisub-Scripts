-- Adds a shaking motion to xshad and yshad tags

script_name = "!Zahuczky's ShadShake"
script_description = "shake shad"
script_author = "Zahuczky"
script_version = "1.0.0"

function shaker(sub, sel, act)

    line = sub[sel[1]]
    linelength = line.end_time - line.start_time

    GUI = {    
        {class= "label",  x= 0, y= 0, width= 1, height= 1, label= "Min. Shake"},
        {class= "intedit", name= "minshake",  x= 1, y= 0, width= 1, height= 1, value= -1},
        {class= "label",  x= 0, y= 1, width= 1, height= 1, label= "Max. Shake"},
        {class= "intedit", name= "maxshake",  x= 1, y= 1, width= 1, height= 1, value= 1},
        {class= "label",  x= 0, y= 2, width= 1, height= 1, label= "Time"},
        {class= "intedit", name= "shaketime",  x= 1, y= 2, width= 1, height= 1, value= linelength},
        {class= "label",  x= 0, y= 3, width= 1, height= 1, label= "Shake interval"},
        {class= "intedit", name= "interv",  x= 1, y= 3, width= 1, height= 1, value= 42}
  }

  buttons = {"Go","Cancel"}

  pressed, results = aegisub.dialog.display(GUI, buttons)
  if pressed == "Cancel" then aegisub.cancel() end

  loopnum = math.floor(results["shaketime"] / results["interv"])+1

    function dashake()
        tstring = "\\xshad"..math.random(results["minshake"],results["maxshake"]).."\\yshad"..math.random(results["minshake"],results["maxshake"])
        for i=1, loopnum do
        rando = math.random(results["minshake"],results["maxshake"])
        rando2 = math.random(results["minshake"],results["maxshake"])
        if rando == 0 or rando2 == 0 then rando = 1 end
        tstring = tstring.."\\t("..(i-1)*(results["interv"])..","..i*(results["interv"])..",\\xshad"..rando.."\\yshad"..rando2..")"
        end
        return tstring
    end

    for i=1, #sel do
        line = sub[sel[i]]
        line.text = line.text:gsub("}", dashake().."}")
        sub[sel[i]] = line
    end




end
aegisub.register_macro(script_name, script_description, shaker)