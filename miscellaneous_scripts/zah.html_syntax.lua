-- Prints syntax highlighted HTML code to the debug console
-- Intended to be used with the KFX template line, but works with any line

script_name="!HTML syntax KFX"
script_description="Exporting a KFX template line with HTML syntax highlight"
script_author="Zahuczky"
script_version="1.0"

require "re"
clipboard = require "aegisub.clipboard"

function italicize(sub, sel)
    line=sub[sel[1]]
	
    input = line.text
    output = [[<FONT COLOR="#285A28">]]..input
    brackets = {"{","}"}
    tags = {"\\1a","\\1c","\\2a","\\2c","\\3a","\\3c","\\4a","\\4c","\\an","\\be","\\fe","\\fn","\\fr","\\fs","\\kf","\\ko","\\fax","\\fay","\\frx","\\fry","\\frz","\\fsp","\\org","\\pbo","\\pos","\\blur","\\blur","\\clip","\\fad","\\fade","\\fscx","\\fscy","\\move","\\shad","\\alpha","\\iclip","\\iclip","\\iclip","\\xbord","\\xshad","\\ybord","\\yshad","\\K","\\a","\\b","\\c","\\i","\\k","\\p","\\q","\\r","\\s","\\t","\\t","\\t","\\u"}
    slashAndPar = {"\\","(",")"}
    tags2 = {"\\K","\\a","\\b","\\c","\\i","\\k","\\p","\\q","\\r","\\s","\\t","\\t","\\t","\\u","\\1a","\\1c","\\2a","\\2c","\\3a","\\3c","\\4a","\\4c","\\an","\\be","\\fe","\\fn","\\fr","\\kf","\\ko","\\fax","\\fay","\\frx","\\fry","\\frz","\\fsp","\\org","\\pbo","\\pos","\\blur","\\blur","\\clip","\\fad","\\fade","\\fscx","\\fscy","\\move","\\shad","\\alpha","\\iclip","\\iclip","\\iclip","\\xbord","\\xshad","\\ybord","\\yshad","\\fs"}
    inlinevars = {"$layer","$lstart","$lend","$ldur","$lmid","$style","$actor","$margin_l","$margin_r","$margin_v","$margin_t","$margin_b","$syln","$li","$lleft","$lcenter","$lright","$ltop","$lmiddle","$lbottom","$ltop","$lmiddle","$lbottom","$lwidth","$lheight","$sstart","$send","$smid","$sdur","$skdur","$si","$sleft","$scenter","$sright","$sbottom","$smiddle","$stop","$sx","$sy","$swidth","$sheight","$start","$end","$mid","$dur","$kdur","$i","$left","$center","$right","$top","$middle","$bottom","$x","$y","$width","$height"}

    for i=1,#brackets do
        output = string.gsub(output, brackets[i], "<FONT COLOR=\"#1432FF\">"..brackets[i].."</FONT>" )
    end

    for i=1,#inlinevars do
        output = string.gsub(output, inlinevars[i], "<FONT COLOR=\"#8000C0\"><b>"..inlinevars[i].."</b></FONT>" )
    end

    for i=1,#tags do
        output = string.gsub(output, tags[i], "<FONT COLOR=\"#5A5A5A\"><b>"..tags[i].."</b></FONT>" )
    end


    output = string.gsub(output, "\\", "<FONT COLOR=\"#FF00C8\">\\</FONT>" )
    output = string.gsub(output, "%(", "<FONT COLOR=\"#FF00C8\">(</FONT>" )
    output = string.gsub(output, "%)", "<FONT COLOR=\"#FF00C8\">)</FONT>" )
    output = string.gsub(output, "%,", "<FONT COLOR=\"#FF00C8\">,</FONT>" )
    

    function stripHTML(stripped)
        outputt = re.sub(stripped, "<[^>]*>", "")
        return outputt
    end

    output = re.sub(output, "\\![^!]*\\!", "<FONT COLOR=\"#8000C0\"><b>$&</b></FONT>")
    output = re.sub(output, "\\![^!]*\\!", stripHTML)

    output = string.gsub(output, "fs</b></FONT>cy", "fscy</b></FONT>")
    output = string.gsub(output, "fs</b></FONT>cx", "fscx</b></FONT>")
    output = string.gsub(output, "$mid</b></FONT>dle", "$middle</b></FONT>")
    output = string.gsub(output, "$lmid</b></FONT>dle", "$lmiddle</b></FONT>")
    output = string.gsub(output, "$smid</b></FONT>dle", "$smiddle</b></FONT>")

    aegisub.debug.out("<pre>\n")
    aegisub.debug.out(output)
    aegisub.debug.out("</pre>")
end

aegisub.register_macro(script_name,script_description,italicize)