export script_name="Aegisub-Perspective-Motion BETA"
export script_description="Applying perspective tracking"
export script_author="Zahuczky"
export script_version = "0.2.9"
export script_namespace="zah.pers-mo_BETA"
github_repo="https://github.com/Zahuczky/Zahuczkys-Aegisub-Scripts"
tutorial_docs="https://zahuczky.com/aegisub-perspective-motion/"

export helptext = "Thank you for using my script!\n\nKeep in mind, that it's still in beta, so it might not perform as expected in every situation.\n\nYou can find instructions and a tutorial at\n\t"..tutorial_docs.."\n\nOr you can contribute to the project at my GitHub page\n\t"..github_repo.."\n\nPull requests, issues and feature requests are very welcome! "

tr = aegisub.gettext

--DependencyControl = require "l0.DependencyControl"
--depctrl = DependencyControl{
--    feed: "https://github.com/Zahuczky/Zahuczkys-Aegisub-Scripts/DependencyControl.json",
--        }

-- DependencyControl stuff for version management
haveDepCtrl, DependencyControl, depctrl = pcall(require, "l0.DependencyControl")
if haveDepCtrl
    depctrl = DependencyControl {
        feed: "https://github.com/Zahuczky/Zahuczkys-Aegisub-Scripts/DependencyControl.json",
    }

-- Relative stuff

-- CODE OF ORIGINAL PERSPECTIVE.MOON STARTS HERE

round = (val, n) ->
        if n
            return math.floor((val * 10^n) + 0.5) / (10^n)
        else
            return math.floor(val+0.5)

class Point
    new: (@x, @y, @z) =>
        if @z == nil
            @z = 0

    repr: () =>
        if math.abs(@z) > 1e5
            @x, @y, @z
        else
            @x, @y

    add: (p) =>
        return Point @x + p.x, @y + p.y, @z + p.z

    sub: (p) =>
        return Point @x - p.x, @y - p.y, @z - p.z

    length: =>
        return math.sqrt @x^2 + @y^2 + @z^2

    rot_y: (a) =>
        rot_v = Point @x * math.cos(a) - @z * math.sin(a), @y, @x * math.sin(a) + @z * math.cos(a)
        return rot_v

    rot_x: (a) =>
        rot_v = Point @x, @y * math.cos(a) + @z * math.sin(a), -@y * math.sin(a) + @z * math.cos(a)
        return rot_v

    rot_z: (a) =>
        rot_v = Point @x * math.cos(a) + @y * math.sin(a), -@x * math.sin(a) + @y * math.cos(a), @z
        return rot_v

    mul: (m) =>
        return Point @x * m, @y * m, @z * m

vector = (a, b) ->
    return Point b.x - a.x, b.y - a.y, b.z - a.z

vec_pr = (a, b) ->
    return Point a.y * b.z - a.z * b.y, -a.x * b.z + a.z * b.x, a.x * b.y - a.y * b.x

sc_pr = (a, b) ->
    return a.x*b.x + a.y*b.y + a.z*b.z

dist = (a, b) ->
    return a\sub(b)\length!



intersect = (l1, l2) ->
    if vec_pr(vector(l1[1], l1[2]), vector(l2[1], l2[2]))\length! == 0
        return l1[1]\add(vector(l1[1], l1[2])\mul(1e30))
    else
        d = ((l1[1].x - l1[2].x)*(l2[1].y - l2[2].y) - (l1[1].y - l1[2].y)*(l2[1].x-l2[2].x))
        x = (vec_pr(l1[1], l1[2]).z*(l2[1].x-l2[2].x) - vec_pr(l2[1], l2[2]).z*(l1[1].x-l1[2].x))
        y = (vec_pr(l1[1], l1[2]).z*(l2[1].y-l2[2].y) - vec_pr(l2[1], l2[2]).z*(l1[1].y-l1[2].y))
        x /= d
        y /= d
        return Point x, y

unrot = (coord_in, org) ->
    screen_z = 312.5
    shift = org\mul(-1)
    coord = [c\add(shift) for c in *coord_in]
    center = intersect({coord[1], coord[3]}, {coord[2], coord[4]})
    center = Point(center.x, center.y, screen_z)
    rays = [Point(c.x, c.y, screen_z) for c in *coord]
    f = {}
    for i = 0, 1
        vp1 = vec_pr(rays[1 + i], center)\length!
        vp2 = vec_pr(rays[3 + i], center)\length!
        a = rays[1 + i]
        c = rays[3 + i]\mul(vp1/vp2)
        m = a\add(c)\mul(0.5)
        r = center.z/m.z
        a = a\mul(r)
        c = c\mul(r)
        table.insert(f, a)
        table.insert(f, c)

    a, c, b, d = f[1], f[2], f[3], f[4]
    ratio = math.abs(dist(a, b) / dist(a, d))
    diag_diff = (dist(a, c) - dist(b, d)) / (dist(a, c) + dist(b, d))
    n = vec_pr(vector(a,b), vector(a,c))
    n0 = vec_pr(vector(rays[1], rays[2]), vector(rays[1], rays[3]))
    if sc_pr(n, n0) > 0 export flip = 1 else export flip = -1

    -- if flip < 0
    --     return nil

    info = {}
    fry = math.atan(n.x/n.z)
    s = ""
    s = s.."\\fry"..round((-fry / math.pi * 180), 2)
    info["debfry"] = round((-fry / math.pi * 180), 2)
    rot_n = n\rot_y(fry)
    frx = -math.atan(rot_n.y/rot_n.z)
    if n0.z < 0
        frx += math.pi
    s = s.."\\frx"..round((-frx / math.pi * 180), 2)
    info["debfrx"] = round((-frx / math.pi * 180), 2)
    n = vector(a, b)
    ab_unrot = vector(a, b)\rot_y(fry)\rot_x(frx)
    ac_unrot = vector(a, c)\rot_y(fry)\rot_x(frx)
    ad_unrot = vector(a, d)\rot_y(fry)\rot_x(frx)
    frz = math.atan2(ab_unrot.y, ab_unrot.x)
    s = s.."\\frz"..round((-frz / math.pi * 180), 2)
    info["debfrz"] = round((-frz / math.pi * 180), 2)
    ad_unrot = ad_unrot\rot_z(frz)
    fax = ad_unrot.x/ad_unrot.y

    s = s.."\\fax"..round(fax, 5)
    info["debfax"] = round(fax, 5)

    sizeX = dist(a, b)
    sizeY = dist(a, d)
    info["sizes"] = { sizeX, sizeY }
    return s, info

-- Getting clip() from clipArray, instead of matching from line
perspective = (clip, line) ->
    if clip == nil
        aegisub.log("Perspective missing. What the heck? How did you pull this off?")

    coord = {}
    for cx, cy in clip\gmatch("([-%d.]+).([-%d.]+)")
        table.insert(coord, Point(cx, cy))

    if line.text\match("org%b()")
        export pos_org = line.text\match("org%b()")
    elseif line.text\match("pos%b()")
        export pos_org = line.text\match("pos%b()")
    else
        aegisub.log("\\org or \\pos missing")
        aegisub.cancel!

    px, py = pos_org\match("([-%d.]+).([-%d.]+)")
    target_org = Point(px, py)

    tf_tags, info = unrot(coord, target_org, true, true)

    return tf_tags, info

-- END OF PERSPECTIVE.MOON CODE


-- XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX

relativeStuff = (sub, sel) ->
  aegisub.progress.task(string.format("Theory of relativity"))
  startOneMS = sub[sel[1]].start_time
  firstFrame = aegisub.frame_from_ms(startOneMS)
  videoPos = aegisub.project_properties!.video_position
  export relFrame = videoPos-firstFrame+1
--    aegisub.debug.out("relative frame: #{relFrame}\n")


-- function that contains everything that happens before the transforms
datahandling = (sub, sel, results, pressed) ->
    aegisub.progress.task(string.format("Crunching data..."))
    -- Putting the user input into a table
    export dataArray = { }
    j=1
    for i in string.gmatch(results.data, "([^\n]*)\n?")
        dataArray[j] = i
        j=j+1

    if results.data == ""
        aegisub.debug.out("You forgot to give me any data, so I quit.\n\n")
        aegisub.cancel()
    elseif dataArray[9] != "Effects\tCC Power Pin #1\tCC Power Pin-0002"
        aegisub.debug.out("I have no idea what kind of data you pasted in, but I'm sure it's not what I wanted.\n\nI need After Effects CC Power Pin data.\n\nPress the HELP button in the script if you don't know what you're doing.\n\n")
        aegisub.cancel()

    -- Filtering out everything other than the data, and putting them into their own tables.
    -- Power Pin data goes like this: TopLeft=0002, TopRight=0003, BottomRight=0005,  BottomLeft=0004
    export posPin1=0
    export posPin2=0
    export posPin3=0
    export posPin4=0
    for k=1,#dataArray
        if dataArray[k] == "Effects\tCC Power Pin #1\tCC Power Pin-0002"
            posPin1=k+2

    export dataLength = ((#dataArray-26)/4)+posPin1

    export p=1
    export helpArray = { }
    export x1 = { }
    export y1 = { }
    --    for l=posPin1,dataLength
    --        for m in string.gmatch(dataArray[l], "([^\t]*)\t?")
    --            helpArray[o] = m
    --            x1[o] = helpArray[2]
    --            o+1

    for l=posPin1,dataLength
        export o=1
        for token in string.gmatch(dataArray[l], "%S+")
            helpArray[o] = token
            o=o+1
        x1[p] = helpArray[2]
        y1[p] = helpArray[3]
        p=p+1
    -- XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
    for k=1,#dataArray
        if dataArray[k] == "Effects\tCC Power Pin #1\tCC Power Pin-0003"
            posPin1=k+2

    export dataLength = ((#dataArray-26)/4)+posPin1

    export p=1
    export helpArray = { }
    export x2 = { }
    export y2 = { }
    --    for l=posPin1,dataLength
    --        for m in string.gmatch(dataArray[l], "([^\t]*)\t?")
    --            helpArray[o] = m
    --            x1[o] = helpArray[2]
    --            o+1

    for l=posPin1,dataLength
        o=1
        for token in string.gmatch(dataArray[l], "%S+")
            helpArray[o] = token
            o=o+1
        x2[p] = helpArray[2]
        y2[p] = helpArray[3]
        p=p+1
    -- XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
    for k=1,#dataArray
        if dataArray[k] == "Effects\tCC Power Pin #1\tCC Power Pin-0004"
            posPin1=k+2

    export dataLength = ((#dataArray-26)/4)+posPin1

    export p=1
    export helpArray = { }
    export x4 = { }
    export y4 = { }
    --    for l=posPin1,dataLength
    --        for m in string.gmatch(dataArray[l], "([^\t]*)\t?")
    --            helpArray[o] = m
    --            x1[o] = helpArray[2]
    --            o+1

    for l=posPin1,dataLength
        export o=1
        for token in string.gmatch(dataArray[l], "%S+")
            helpArray[o] = token
            o=o+1
        x4[p] = helpArray[2]
        y4[p] = helpArray[3]
        p=p+1
    -- XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
    for k=1,#dataArray
        if dataArray[k] == "Effects\tCC Power Pin #1\tCC Power Pin-0005"
            posPin1=k+2

    export dataLength = ((#dataArray-26)/4)+posPin1

    export p=1
    export helpArray = { }
    export x3 = { }
    export y3 = { }
    --    for l=posPin1,dataLength
    --        for m in string.gmatch(dataArray[l], "([^\t]*)\t?")
    --            helpArray[o] = m
    --            x1[o] = helpArray[2]
    --            o+1

    for l=posPin1,dataLength
        export o=1
        for token in string.gmatch(dataArray[l], "%S+")
            helpArray[o] = token
            o=o+1
        x3[p] = helpArray[2]
        y3[p] = helpArray[3]
        p=p+1
    -- XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX

    -- Turning the coordinates into a clip() (for the sake of not having to modify too much in the original code of perspective.moon)
    export clipArray = { }
    for i=1,#x1
        clipArray[i] = "clip(m "..x1[i].." "..y1[i].." l "..x2[i].." "..y2[i].." "..x3[i].." "..y3[i].." "..x4[i].." "..y4[i]..")"

    -- TODO support multi-frame lines
    if #clipArray != #sel
        aegisub.debug.out("The number of selected lines does not match the tracking data! Aborting.")
        aegisub.cancel()

    -- XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX


scale = (lines, xx1, xx2, xx3, xx4, yy1, yy2, yy3, yy4, perspInfo) ->
    aegisub.progress.task(string.format("Some scaling..."))
    scalesX = { }
    scalesY = { }
    for i=1,#lines
        x1 = xx1[i]
        x2 = xx2[i] - x1
        x3 = xx3[i] - x1
        x4 = xx4[i] - x1
        y1 = yy1[i]
        y2 = yy2[i] - y1
        y3 = yy3[i] - y1
        y4 = yy4[i] - y1

        position = lines[i].text\match("pos%b()")
        posX, posY = position\match("([-%d.]+).([-%d.]+)")
        xp = posX - x1
        yp = posY - y1

        rx = -perspInfo[i]["debfrx"] * math.pi / 180
        ry = perspInfo[i]["debfry"] * math.pi / 180
        rz = -perspInfo[i]["debfrz"] * math.pi / 180
        fax = perspInfo[i]["debfax"]

        -- Invoke black math magic. Do not attempt to read it, for it will destroy your sanity.
        cx = -(((x3*y2 - x2*y3)*(x4*(-y2 + y3) + x3*(y2 - y4) + x2*(-y3 + y4))*(-(xp*y4) + x4*yp))/ (x3*(x2*y4*(2*xp*y2*(-y3 + y4) + x2*y4*(y3 - yp)) + x4^2*y2^2*(-y3 + yp) - 2*x4*(xp*y2*(y2 - y3)*y4 + x2*y3*(-y2 + y4)*yp)) + x3^2*(x4*y2^2*(y4 - yp) + y4*(xp*y2*(y2 - y4) + x2*y4*(-y2 + yp))) + y3*(x2^2*xp*(y3 - y4)*y4 + x4^2*(xp*y2*(y2 - y3) + x2*y2*(y3 - 2*yp) + x2*y3*yp) - x2^2*x4*(-2*y4*yp + y3*(y4 + yp)))))
        cy = ((-(x4*y3) + x3*y4)*(x4*(-y2 + y3) + x3*(y2 - y4) + x2*(-y3 + y4))*(xp*y2 - x2*yp))/ (x3*(x2*y4*(2*xp*y2*(-y3 + y4) + x2*y4*(y3 - yp)) + x4^2*y2^2*(-y3 + yp) - 2*x4*(xp*y2*(y2 - y3)*y4 + x2*y3*(-y2 + y4)*yp)) + x3^2*(x4*y2^2*(y4 - yp) + y4*(xp*y2*(y2 - y4) + x2*y4*(-y2 + yp))) + y3*(x2^2*xp*(y3 - y4)*y4 + x4^2*(xp*y2*(y2 - y3) + x2*y2*(y3 - 2*yp) + x2*y3*yp) - x2^2*x4*(-2*y4*yp + y3*(y4 + yp))))
        dsx2 = (((-1 + cy)*x3^2*y2*(y2 - y4)*y4 + y3*((-1 + cy)*x4^2*y2*(y2 - y3) + cy*x2^2*(y3 - y4)*y4 + x2*x4*y2*(-y3 + y4)) + x3*y2*(2*(-1 + cy)*x4*y3*y4 - (-1 + 2*cy)*x2*(y3 - y4)*y4 + x4*y2*(y3 + y4 - 2*cy*y4)))^2 + (x2*(x4*y3 - x3*y4)*(x4*((-1 + cx + cy)*y2 + y3 - cy*y3) + x3*(y2 - cx*y2 + (-1 + cy)*y4) + x2*((-1 + cx)*y3 - (-1 + cx + cy)*y4)) + (x3*y2 - x4*y2 + x2*(-y3 + y4))*(cy*x4*(x3*y2 - x2*y3) + cx*x2*(x4*y3 - x3*y4)))^2)/ (x4*((-1 + cx + cy)*y2 + y3 - cy*y3) + x3*(y2 - cx*y2 + (-1 + cy)*y4) + x2*((-1 + cx)*y3 - (-1 + cx + cy)*y4))^4
        dsy2 = ((x4*(x3*y2 - x2*y3)*(x4*((-1 + cx + cy)*y2 + y3 - cy*y3) + x3*(y2 - cx*y2 + (-1 + cy)*y4) + x2*((-1 + cx)*y3 - (-1 + cx + cy)*y4)) - (x4*(y2 - y3) + (-x2 + x3)*y4)*(cy*x4*(x3*y2 - x2*y3) + cx*x2*(x4*y3 - x3*y4)))^2 + ((x3*y2 - x2*y3)*y4*(-(x4*y2) - x2*y3 + x4*y3 + x3*(y2 - y4) + x2*y4) + cx*(x4^2*y2*y3*(-y2 + y3) + 2*x3*x4*y2*(y2 - y3)*y4 + y4*(2*x2*x3*y2*(y3 - y4) + x3^2*y2*(-y2 + y4) + x2^2*y3*(-y3 + y4))))^2)/ (x4*((-1 + cx + cy)*y2 + y3 - cy*y3) + x3*(y2 - cx*y2 + (-1 + cy)*y4) + x2*((-1 + cx)*y3 - (-1 + cx + cy)*y4))^4

        drx2 = math.cos(rx)^2 * math.sin(rz)^2 + (math.cos(ry) * math.cos(rz) - math.sin(rx) * math.sin(ry) * math.sin(rz))^2
        dry2 = math.cos(rx)^2 * (math.cos(rz) + fax * math.sin(rz))^2 + (math.cos(ry) * (math.sin(rz) - fax * math.cos(rz)) + math.sin(rx) * math.sin(ry) * (math.cos(rz) + fax * math.sin(rz)))^2

        scalesX[i] = math.sqrt(dsx2 / drx2)
        scalesY[i] = math.sqrt(dsy2 / dry2)

    relScalesX = { }
    relScalesY = { }
    for i=1,#lines
        relScalesX[i] = results.xSca * scalesX[i] / scalesX[relFrame]
        relScalesY[i] = results.ySca * scalesY[i] / scalesY[relFrame]

    return relScalesX, relScalesY


-- Given a line, returns the y coordinate of the alignment point relative to the \an7 point
-- i.e. 0 for \an7-9, half the height for \an4-6, and the full height for \an1-3.
getFaxCompFactor = (subs, line) ->
    stylename = line.style
    styles = [s for i, s in ipairs(subs) when s.class == "style" and s.name == stylename]
    style = styles[1]

    an = tonumber(line.text\match("\\an(%d)")) or style.align
    if an >= 7 and an <= 9
        return 0

    fs = tonumber(line.text\match("\\fs(%d+)"))
    if fs ~= nil
        style.fontsize = fs

    width, height, descent, ext_lead = aegisub.text_extents(style, line.text\gsub("{[^}]+}", ""))
    height = height * 100 / style.scale_y
    -- height = style.fontsize

    if an >= 4 and an <= 6
        return height / 2

    if an >= 1 and an <= 3
        return height


-- main function, this get's run as 'apply' is clicked
perspmotion = (sub, sel) ->
    relativeStuff(sub,sel)
    relsel = sel[relFrame]
    export xScaleRel = sub[relsel].text\match("\\fscx([-%d.]+)")
    export yScaleRel = sub[relsel].text\match("\\fscy([-%d.]+)")
    if xScaleRel == nil
        xScaleRel = 100
    if yScaleRel == nil
        yScaleRel = 100

    GUI = {
        main: {
          {class: "label",  x: 0, y: 0, width: 1, height: 1, label: "Only paste After Effects CC POWER PIN data"}
          {class: "label",  x: 0, y: 1, width: 1, height: 1, label: "here, not Transform or Corner Pin data!"}
          {class: "textbox", name: "data",  x: 0, y: 2, width: 3, height: 7, },
          {class: "checkbox", name: "includeclip",  x: 0, y: 9, width: 1, height: 1, label: "Include \\clip for debugging", value: false}
          {class: "dropdown", name: "setupoptions",  x: 0, y: 10, width: 3, height: 1, items: {"Perspective + Scaling","Only Perspective","Only Scaling"}, value: "Perspective + Scaling"}
          {class: "label",  x: 0, y: 11, width: 1, height: 1, label: "v"..script_version}
          {class: "intedit", name: "xSca",  x: 4, y: 2, width: 1, height: 1, value: xScaleRel}
          {class: "label",  x: 5, y: 2, width: 1, height: 1, label: "X Scaling"}
          {class: "intedit", name: "ySca",  x: 4, y: 3, width: 1, height: 1, value: yScaleRel}
          {class: "label",  x: 5, y: 3, width: 1, height: 1, label: "Y Scaling"}
          {class: "intedit", name: "xtraRot",  x: 4, y: 4, width: 1, height: 1, value: yScaleRel}
          {class: "label",  x: 5, y: 4, width: 1, height: 1, label: "Extra Rotation"}
          {class: "intedit", name: "xtrafax",  x: 4, y: 5, width: 1, height: 1, value: yScaleRel}
          {class: "label",  x: 5, y: 5, width: 1, height: 1, label: "Extra Fax"}
          {class: "intedit", name: "xtrafay",  x: 4, y: 6, width: 1, height: 1, value: yScaleRel}
          {class: "label",  x: 5, y: 6, width: 1, height: 1, label: "Extra Fay"}
          {class: "checkbox", name: "scalebord",  x: 4, y: 7, width: 1, height: 1, label: "Scale \\bord", value: true}
          {class: "checkbox", name: "scaleshad",  x: 4, y: 8, width: 1, height: 1, label: "Scale \\shad", value: false, hint: "Don't tick this if you're using the \"shad trick!\""}

          },

        help: {
            {class: "textbox", x: 0, y: 0, width: 45, height: 15, value: helptext}
        }
    }

    buttons = {"Apply","Rescale","Cancel","HELP"}

    export pressed, results = aegisub.dialog.display(GUI.main, {"Apply","Rescale","Cancel","HELP"})
    if pressed=="Cancel" aegisub.cancel()
    if pressed=="HELP" pressed, results = aegisub.dialog.display(GUI.help, {"Close"})
    if pressed=="Close" aegisub.cancel()

    datahandling(sub, sel, results, pressed)

    aegisub.progress.task(string.format("Faxing...(ur mom)"))
    lines = {}
    for si, li in ipairs(sel)
        lines[si] = sub[li]

    perspResults = {}
    perspInfo = {}
    for i=1,#lines
        result = ""
        info = {}
        result, info = perspective(clipArray[i], lines[i])
        perspResults[i] = result
        perspInfo[i] = info

    scaleX, scaleY = scale(lines, x1, x2, x3, x4, y1, y2, y3, y4, perspInfo)

    export scales = { }
    for i=1,#lines
        scales[i] = "\\fscx"..round(scaleX[i],2).."\\fscy"..round(scaleY[i],2)

    orgBordArray = { }
    xBordArray = { }
    yBordArray = { }
    baseBord = 0
    for i=1,#lines
        -- Bord scaling
        stylename = lines[i].style
        styles = [s for i, s in ipairs(sub) when s.class == "style" and s.name == stylename]
        style = styles[1]

        if lines[i].text\match("\\bord([-%d.]+)")
            orgBordArray[i] = lines[i].text\match("\\bord([-%d.]+)")
        else
            orgBordArray[i] = style.outline
            aegisub.debug.out("Bord in style is: "..orgBordArray[i])

    baseBord = tonumber(orgBordArray[relFrame])

    for i=1,#lines
        xBordArray[i] = baseBord*(scaleX[i]/100)
        yBordArray[i] = baseBord*(scaleY[i]/100)

    bords = { }
    for i=1,#lines
        bords[i] = "\\xbord"..round(xBordArray[i],2).."\\ybord"..round(yBordArray[i],2)


-- Main loop, this get's looped for every selected line.
    for si, li in ipairs(sel)
        line = sub[li]

-- Deleting old tags from the line, so nothing interferes with the new ones. TODO add clip.
        delete_old_tag = (line) ->
            line.text = line.text\gsub("\\frx([-%d.]+)", "")\gsub("\\fry([-%d.]+)", "")\gsub("\\frz([-%d.]+)", "")\gsub("\\org%b()", "")\gsub("\\fax([-%d.]+)", "")\gsub("\\fay([-%d.]+)", "")\gsub("\\fscx([-%d.]+)", "")\gsub("\\fscy([-%d.]+)", "")\gsub("\\bord([-%d.]+)", "")
            return line.text

        result = perspResults[si]

        line.text = delete_old_tag(line)
        if results.includeclip
            line.text = line.text\gsub("\\pos", "\\"..clipArray[si]..result..scales[si]..bords[si].."\\pos")
        else
            line.text = line.text\gsub("\\pos", result..scales[si]..bords[si].."\\pos")
        if perspInfo[si]["debfax"] != nil
            realfax = (perspInfo[si]["debfax"]*(scaleY[si]/100))/(scaleX[si]/100)
            line.text = line.text\gsub("\\fax([-%d.]+)", "\\fax"..realfax)

            posX, posY = line.text\match("\\pos%(([-%d.]+).([-%d.]+)%)")
            factor = getFaxCompFactor(sub, line)
            newPosX = round(posX - realfax * factor * scaleX[si] / 100, 3)
            line.text = line.text\gsub("\\pos", "\\pos(#{newPosX},#{posY})\\org")
        sub[li] = line

    aegisub.progress.task(string.format("Magiccing it together"))
    aegisub.set_undo_point(script_name)
    return sel

--Register macro (no validation function required)

if haveDepCtrl
    depctrl\registerMacro perspmotion
else
    aegisub.register_macro(script_name, script_description, perspmotion)
