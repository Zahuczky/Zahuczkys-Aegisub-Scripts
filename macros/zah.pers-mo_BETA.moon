export script_name="Aegisub-Perspective-Motion BETA"
export script_description="Applying perspective tracking"
export script_author="Zahuczky"
export script_version = "0.2.7"
export script_namespace="zah.pers-mo_BETA"
github_repo="https://github.com/Zahuczky/Zahuczkys-Aegisub-Scripts"
tutorial_docs="https://zahuczky.com/aegisub-perspective-motion/"

export helptext = "Thank you for using my script!\n\nKeep in mind, that it's still in beta, so it might not perform as expected in every situation.\n\nYou can find instructions and a tutorial at\n\t"..tutorial_docs.."\n\nOr you can contribute to the project at my GitHub page\n\t"..github_repo.."\n\nPull requests, issues and feature requests are very welcome! "

tr = aegisub.gettext

dlgg = require'zah.ZF.ass.dialog'
linee = require'zah.ZF.ass.line'
fbff = require'zah.ZF.ass.fbf'

--DependencyControl = require "l0.DependencyControl"
--depctrl = DependencyControl{
--    feed: "https://github.com/Zahuczky/Zahuczkys-Aegisub-Scripts/DependencyControl.json",
--        }

-- DependencyControl stuff for version management
haveDepCtrl, DependencyControl, depctrl = pcall(require, "l0.DependencyControl")
if haveDepCtrl
    depctrl = DependencyControl {
        feed: "https://github.com/Zahuczky/Zahuczkys-Aegisub-Scripts/DependencyControl.json",
        {
            "karaskel"
        }
    }

    depctrl\requireModules!
else
    require'karaskel'


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

-- END OF PERSPECTIVE.MOON CODE


-- XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX


get_line_group = (line, actorgroups) ->
    return "" if not actorgroups
    return line.actor\match("^([^ ]+)")


relativeStuff = (sub, sel, group) ->
    aegisub.progress.task(string.format("Theory of relativity"))
    videoPos = aegisub.project_properties!.video_position

    sel_lines = [sub[si] for si in *sel when group == nil or group == "" or get_line_group(sub[si], true) == group]

    if videoPos == nil
        -- not sure what you're doing without a video loaded, but sure
        return sel_lines[1], 1

    vis_lines = [s for s in *sel_lines when aegisub.frame_from_ms(s.start_time) <= videoPos and aegisub.frame_from_ms(s.end_time) >= videoPos]
    return sel_lines[1], 1 if #vis_lines == 0

    -- TODO be smarter about this?
    return vis_lines[1], videoPos - aegisub.frame_from_ms(sel_lines[1].start_time) + 1


parsePin = (dataArray, n) ->
    local posPin
    for k=1,#dataArray
        if dataArray[k]\match("^Effects[\t ]CC Power Pin #1[\t ]CC Power Pin%-#{n}$")
            posPin = k
            break

    if posPin == nil
        aegisub.log("Invalid tracking data!\n")
        aegisub.cancel()

    i = posPin + 2

    x = {}
    y = {}
    while dataArray[i]\match("^[\t ]+[0-9]")
        values = [t for t in string.gmatch(dataArray[i], "%S+")]
        table.insert(x, values[2])
        table.insert(y, values[3])
        i += 1

    return x, y

-- function that contains everything that happens before the transforms
datahandling = (sub, sel, results) ->
    aegisub.progress.task(string.format("Crunching data..."))
    -- Putting the user input into a table
    dataArray = { }
    j=1
    for i in string.gmatch(results.data, "([^\n]*)\n?")
        dataArray[j] = i
        j=j+1

    if results.data == ""
        aegisub.debug.out("You forgot to give me any data, so I quit.\n\n")
        aegisub.cancel()

    elseif #([i for i, l in ipairs(dataArray) when l\match"Effects[\t ]CC Power Pin #1[\t ]CC Power Pin%-0002"]) == 0
        aegisub.debug.out("I have no idea what kind of data you pasted in, but I'm sure it's not what I wanted.\n\nI need After Effects CC Power Pin data.\n\nPress the HELP button in the script if you don't know what you're doing.\n\n")
        aegisub.cancel()

    -- Filtering out everything other than the data, and putting them into their own tables.
    -- Power Pin data goes like this: TopLeft=0002, TopRight=0003, BottomRight=0005,  BottomLeft=0004
    x1, y1 = parsePin(dataArray, "0002")
    x2, y2 = parsePin(dataArray, "0003")
    x3, y3 = parsePin(dataArray, "0005")
    x4, y4 = parsePin(dataArray, "0004")

    return [{Point(x1[i], y1[i]), Point(x2[i], y2[i]), Point(x3[i], y3[i]), Point(x4[i], y4[i])} for i=1,#x1]


-- helper function so I can more or less paste Mathematica output directly into the code
unwrapQuadVals = (quad) ->
    x1 = quad[1].x
    x2 = quad[2].x - x1
    x3 = quad[3].x - x1
    x4 = quad[4].x - x1
    y1 = quad[1].y
    y2 = quad[2].y - y1
    y3 = quad[3].y - y1
    y4 = quad[4].y - y1

    return x1, x2, x3, x4, y1, y2, y3, y4


quadToUnitSquare = (quad, pos) ->
    x1, x2, x3, x4, y1, y2, y3, y4 = unwrapQuadVals(quad)
    xp = pos.x - x1
    yp = pos.y - y1

    -- Invoke black math magic. Do not attempt to read it, for it will destroy your sanity.
    cx = -(((x3*y2 - x2*y3)*(x4*(-y2 + y3) + x3*(y2 - y4) + x2*(-y3 + y4))*(-(xp*y4) + x4*yp))/ (x3*(x2*y4*(2*xp*y2*(-y3 + y4) + x2*y4*(y3 - yp)) + x4^2*y2^2*(-y3 + yp) - 2*x4*(xp*y2*(y2 - y3)*y4 + x2*y3*(-y2 + y4)*yp)) + x3^2*(x4*y2^2*(y4 - yp) + y4*(xp*y2*(y2 - y4) + x2*y4*(-y2 + yp))) + y3*(x2^2*xp*(y3 - y4)*y4 + x4^2*(xp*y2*(y2 - y3) + x2*y2*(y3 - 2*yp) + x2*y3*yp) - x2^2*x4*(-2*y4*yp + y3*(y4 + yp)))))
    cy = ((-(x4*y3) + x3*y4)*(x4*(-y2 + y3) + x3*(y2 - y4) + x2*(-y3 + y4))*(xp*y2 - x2*yp))/ (x3*(x2*y4*(2*xp*y2*(-y3 + y4) + x2*y4*(y3 - yp)) + x4^2*y2^2*(-y3 + yp) - 2*x4*(xp*y2*(y2 - y3)*y4 + x2*y3*(-y2 + y4)*yp)) + x3^2*(x4*y2^2*(y4 - yp) + y4*(xp*y2*(y2 - y4) + x2*y4*(-y2 + yp))) + y3*(x2^2*xp*(y3 - y4)*y4 + x4^2*(xp*y2*(y2 - y3) + x2*y2*(y3 - 2*yp) + x2*y3*yp) - x2^2*x4*(-2*y4*yp + y3*(y4 + yp))))

    return cx, cy


unitSquareToQuad = (quad, cx, cy) ->
    x1 = quad[1].x
    x2 = quad[2].x
    x3 = quad[3].x
    x4 = quad[4].x
    y1 = quad[1].y
    y2 = quad[2].y
    y3 = quad[3].y
    y4 = quad[4].y

    -- More black magic
    px = (cx*(x2*x4*(y1 - y3) + x1*x4*(-y2 + y3) + x1*x3*(y2 - y4) + x2*x3*(-y1 + y4)) + x1*(x4*(y2 - y3) + x2*(y3 - y4) + x3*(-y2 + y4)) + cy*(x3*x4*(y1 - y2) + x2*x4*(-y1 + y3) + x1*x3*(y2 - y4) + x1*x2*(-y3 + y4)))/(-(x3*y2) + x4*y2 + x2*y3 - x4*y3 + cx*(x4*(y1 - y2) + x3*(-y1 + y2) + (x1 - x2)*(y3 - y4)) - x2*y4 + x3*y4 + cy*((x1 - x4)*(y2 - y3) + x3*(y1 - y4) + x2*(-y1 + y4)))
    py = (x2*y1*y3 - cx*x2*y1*y3 - cy*x2*y1*y3 + cx*x1*y2*y3 - cx*x4*y2*y3 + x4*y1*(y2 - cy*y2 + (-1 + cx + cy)*y3) - x2*y1*y4 + cx*x2*y1*y4 - cx*x1*y2*y4 + cy*x1*y2*y4 - cy*x1*y3*y4 + cy*x2*y3*y4 + x3*((cx - cy)*y2*y4 + y1*((-1 + cy)*y2 + y4 - cx*y4)))/(-(x3*y2) + x4*y2 + x2*y3 - x4*y3 + cx*(x4*(y1 - y2) + x3*(-y1 + y2) + (x1 - x2)*(y3 - y4)) - x2*y4 + x3*y4 + cy*((x1 - x4)*(y2 - y3) + x3*(y1 - y4) + x2*(-y1 + y4)))

    return Point(px, py)


getScale = (quad, pos, perspInfo, relScale=Point(1, 1)) ->
    x1, x2, x3, x4, y1, y2, y3, y4 = unwrapQuadVals(quad)
    xp = pos.x - x1
    yp = pos.y - y1

    rx = -perspInfo["debfrx"] * math.pi / 180
    ry = perspInfo["debfry"] * math.pi / 180
    rz = -perspInfo["debfrz"] * math.pi / 180
    fax = perspInfo["debfax"]

    cx, cy = quadToUnitSquare(quad, pos)
    -- And now the real black magic
    dsx2 = (((-1 + cy)*x3^2*y2*(y2 - y4)*y4 + y3*((-1 + cy)*x4^2*y2*(y2 - y3) + cy*x2^2*(y3 - y4)*y4 + x2*x4*y2*(-y3 + y4)) + x3*y2*(2*(-1 + cy)*x4*y3*y4 - (-1 + 2*cy)*x2*(y3 - y4)*y4 + x4*y2*(y3 + y4 - 2*cy*y4)))^2 + (x2*(x4*y3 - x3*y4)*(x4*((-1 + cx + cy)*y2 + y3 - cy*y3) + x3*(y2 - cx*y2 + (-1 + cy)*y4) + x2*((-1 + cx)*y3 - (-1 + cx + cy)*y4)) + (x3*y2 - x4*y2 + x2*(-y3 + y4))*(cy*x4*(x3*y2 - x2*y3) + cx*x2*(x4*y3 - x3*y4)))^2)/ (x4*((-1 + cx + cy)*y2 + y3 - cy*y3) + x3*(y2 - cx*y2 + (-1 + cy)*y4) + x2*((-1 + cx)*y3 - (-1 + cx + cy)*y4))^4
    dsy2 = ((x4*(x3*y2 - x2*y3)*(x4*((-1 + cx + cy)*y2 + y3 - cy*y3) + x3*(y2 - cx*y2 + (-1 + cy)*y4) + x2*((-1 + cx)*y3 - (-1 + cx + cy)*y4)) - (x4*(y2 - y3) + (-x2 + x3)*y4)*(cy*x4*(x3*y2 - x2*y3) + cx*x2*(x4*y3 - x3*y4)))^2 + ((x3*y2 - x2*y3)*y4*(-(x4*y2) - x2*y3 + x4*y3 + x3*(y2 - y4) + x2*y4) + cx*(x4^2*y2*y3*(-y2 + y3) + 2*x3*x4*y2*(y2 - y3)*y4 + y4*(2*x2*x3*y2*(y3 - y4) + x3^2*y2*(-y2 + y4) + x2^2*y3*(-y3 + y4))))^2)/ (x4*((-1 + cx + cy)*y2 + y3 - cy*y3) + x3*(y2 - cx*y2 + (-1 + cy)*y4) + x2*((-1 + cx)*y3 - (-1 + cx + cy)*y4))^4

    drx2 = math.cos(rx)^2 * math.sin(rz)^2 + (math.cos(ry) * math.cos(rz) - math.sin(rx) * math.sin(ry) * math.sin(rz))^2
    dry2 = math.cos(rx)^2 * (math.cos(rz) + fax * math.sin(rz))^2 + (math.cos(ry) * (math.sin(rz) - fax * math.cos(rz)) + math.sin(rx) * math.sin(ry) * (math.cos(rz) + fax * math.sin(rz)))^2

    scaleX = math.sqrt(dsx2 / drx2)
    scaleY = math.sqrt(dsy2 / dry2)

    return Point(scaleX * relScale.x, scaleY * relScale.y)


getLinePos = (line) ->
    position = line.text\match("pos%b()")
    posX, posY = position\match("([-%d.]+).([-%d.]+)")
    return Point(posX, posY)

-- Given a line, returns the y coordinate of the alignment point relative to the \an7 point
-- i.e. 0 for \an7-9, half the height for \an4-6, and the full height for \an1-3.
getFaxCompFactor = (styles, line) ->
    style = styles[line.style]

    an = tonumber(line.text\match("\\an(%d)")) or style.align
    if an >= 7 and an <= 9
        return 0

    fs = tonumber(line.text\match("\\fs(%d+)"))
    style.fontsize = fs if fs != nil

    width, height, descent, ext_lead = aegisub.text_extents(style, line.text\gsub("{[^}]+}", ""))
    height = height * 100 / style.scale_y

    if an >= 4 and an <= 6
        return height / 2

    if an >= 1 and an <= 3
        return height


delete_old_tags = (text) ->
    return text\gsub("\\frx([-%d.]+)", "")\gsub("\\fry([-%d.]+)", "")\gsub("\\frz([-%d.]+)", "")\gsub("\\org%b()", "")\gsub("\\fax([-%d.]+)", "")\gsub("\\fay([-%d.]+)", "")\gsub("\\fscx([-%d.]+)", "")\gsub("\\fscy([-%d.]+)", "")\gsub("\\bord([-%d.]+)", "")


line2fbf = (sub, sel, act) ->
    -- Me monkey, me patch!
    oldundo = aegisub.set_undo_point
    aegisub.set_undo_point = (x) -> return

    dlg = dlgg.DIALOG(sub, sel, act, true)
    for l, line, sel, i, n in dlg\iterSelected() 
        fbf = fbff.FBF(l)
        linee.LINE(line)\prepoc(dlg)
        tags, move, fade = fbf\setup(line)
        dlg\removeLine(l, sel)
        for s, e in fbf\iter(1) 
            line.start_time = s
            line.end_time = e
            line.text = fbf\perform(line, tags, move, fade)
            dlg\insertLine(line, sel)
    result = dlg\getSelection()

    aegisub.set_undo_point = oldundo
    return result


-- Given the tags from perspinfo and the scaling, transform a point
ass_transform = (perspinfo, scale, pt) ->
    pt = Point(pt.x + perspinfo["debfax"] * pt.y, pt.y)
    pt = Point(pt.x * scale.x, pt.y * scale.y)
    pt = pt\rot_z(math.rad(perspinfo["debfrz"]))    -- the Point class handles the signs for x and z
    pt = pt\rot_x(math.rad(perspinfo["debfrx"]))    -- ... which is very stupid, but I guess it's better not to touch it
    pt = pt\rot_y(math.rad(perspinfo["debfry"]))
    pt = pt\mul(312.5 / (pt.z + 312.5))
    return pt


-- main function, this get's run as 'apply' is clicked
perspmotion = (sub, sel, act) ->
    sel = line2fbf(sub, sel, act)
    meta, styles = karaskel.collect_head(sub, false)

    mainRelLine, relFrame = relativeStuff(sub,sel)
    xScaleRel = mainRelLine.text\match("\\fscx([-%d.]+)") or 100
    yScaleRel = mainRelLine.text\match("\\fscy([-%d.]+)") or 100

    aegisub.debug.out(4, "Relative Frame: #{relFrame}\n")

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
          {class: "checkbox", name: "followpos",  x: 4, y: 9, width: 2, height: 1, label: "Also track position", value: false, hint: "Update the positions to keep the text's relative position in the quad constant. The reference point is the current frame. Still needs the line to be fbf'ed."}
          {class: "checkbox", name: "actorgroups",  x: 4, y: 10, width: 2, height: 1, label: "Multiple grouped tracks", value: false, hint: "Tracking multiple signs in a single run. For this, mark every sign's group of lines with a different actor (only the first word matters). For each actor group, the line at the current frame will be taken as the reference line for scaling and positioning (wherever applicable). The x and y scaling values in the dialog will be discarded."}
          {class: "checkbox", name: "unprojshapes", x: 4, y: 11, width: 2, height: 1, label: "Deproject shapes first", value: true, hint: "If not set, this will treat a shape like an ordinary dialogue line. If set, it will assume that shapes are drawn in the perspective of the reference frame, and transform them to screen coordinates first."}
          },

        help: {
            {class: "textbox", x: 0, y: 0, width: 45, height: 15, value: helptext}
        }
    }

    buttons = {"Apply","Rescale","Cancel","HELP"}

    pressed, results = aegisub.dialog.display(GUI.main, {"Apply","Rescale","Cancel","HELP"})
    aegisub.cancel() if pressed == "Cancel" or pressed == false
    if pressed=="HELP" pressed, results = aegisub.dialog.display(GUI.help, {"Close"})

    aegisub.progress.task(string.format("Faxing...(ur mom)"))

    lines = [sub[li] for li in *sel]
    linePos = [getLinePos(line) for line in *lines]

    quads = datahandling(sub, sel, results)

    allgroups = {}
    for i, line in ipairs(lines)
        allgroups[get_line_group(line, results.actorgroups)] = true

    -- first, do the rel lines to get their scales
    relLines = {}
    for group, v in pairs(allgroups)
        aegisub.log(5, "Group: #{group}\n")
        relLine = relativeStuff(sub, sel, group)
        rpos = getLinePos(relLine)
        rquad = quads[relFrame]
        rcx, rcy = quadToUnitSquare(rquad, rpos)
        aegisub.debug.out(4, "Internal coordinates of relative #{group} line: #{rcx}, #{rcy}\n")
        perspRes, info = unrot(rquad, rpos)
        rscale = getScale(rquad, rpos, info)
        rclip = relLine.text\match("\\i?clip%([^%)]-%)")
        -- FIXME: Handle two clips per line properly
        if rclip
            rclip = rclip\gsub("%(([-%d. ]+),([-%d. ]+),([-%d. ]+),([-%d. ]+)%)", (a, b, c, d) -> "m #{a} #{b} l #{c} #{b} #{c} #{d} #{a} #{d}")

        orgrxscale = relLine.text\match("\\fscx([-%d.]+)") or 100
        orgryscale = relLine.text\match("\\fscy([-%d.]+)") or 100

        aegisub.debug.out(4, "Original scale of relative #{group} line: #{orgrxscale}, #{orgryscale}\n")
        aegisub.debug.out(4, "Relative #{group} line's scale: #{rscale.x}, #{rscale.y}\n")

        relLines[group] = {
            cx: rcx,
            cy: rcy,
            scale: rscale,
            orgscale: Point(orgrxscale, orgryscale),
            quad: rquad,
            clip: rclip,
            transform: (pt) -> ass_transform(info, Point(1, 1), pt)
        }

    -- now loop over all lines
    for i, line in ipairs(lines)
        style = styles[line.style]
        abs_frame = aegisub.frame_from_ms(line.start_time)
        frame = if abs_frame != nil then abs_frame - aegisub.frame_from_ms(sub[sel[1]].start_time) + 1 else i
        quad = quads[frame]
        pos = linePos[i]
        group = get_line_group(line, results.actorgroups)
        relLine = relLines[group]

        aegisub.debug.out(5, "Line #{i}: Relative frame #{frame}, in group #{group}, at position #{pos.x}, #{pos.y}\n")

        if quad == nil
            aegisub.debug.out("Tracking data is too short!\nTracking Data: #{#quads} frames.\nCurrent subtitle line: at frame #{frame}.\n")
            aegisub.cancel()

        if results.followpos
            pos = unitSquareToQuad(quad, relLine.cx, relLine.cy)
            aegisub.debug.out(5, "New coordinates: #{pos.x}, #{pos.y}\n")

        perspRes, perspInfo = unrot(quad, pos)
        relscale = if results.actorgroups then relLine.orgscale else Point(results.xSca, results.ySca)
        scale = getScale(quad, pos, perspInfo, Point(relscale.x / relLine.scale.x, relscale.y / relLine.scale.y))

        scaleCmds = "\\fscx#{round(scale.x,2)}\\fscy#{round(scale.y,2)}"

        -- TODO read from relFrame again? This would be inconsistent with other values though
        -- baseBord = tonumber(orgBordArray[relFrame])
        baseBord = tonumber(line.text\match("\\bord([-%d.]+)") or style.outline)
        aegisub.debug.out(5, "Bord in style is: #{baseBord}\n")
        xBord = baseBord*(scale.x/100)
        yBord = baseBord*(scale.y/100)

        bordCmds = "\\xbord#{round(xBord,2)}\\ybord#{round(yBord,2)}"

        line.text = delete_old_tags(line.text)
        if results.includeclip
            line.text = line.text\gsub("\\pos", "\\clip(m #{quad[1].x} #{quad[1].y} l #{quad[2].x} #{quad[2].y} l #{quad[3].x} #{quad[3].y} l #{quad[4].x} #{quad[4].y})\\pos")

        -- assume that every line is either a shape or not...
        drawingmatch = line.text\match("\\p(%d+)")
        if drawingmatch and tonumber(drawingmatch) != 0 and results.unprojshapes
            -- We want to take the transformation tags on the relative line, and undo them for the shape coordinates, so
            -- that when transforming the resulting shape with these quads, we get the original shape.
            -- So take a 1x1 square and apply the transform, and then transform the shape coordinates from the resulting quad back to the 1x1 square
            squarequad = {Point(0, 0), Point(1, 0), Point(1, 1), Point(0, 1)}
            orgtransfquad = [ relLine.transform(pt) for pt in *squarequad ]

            transf = (x, y) ->
                cx, cy = quadToUnitSquare(orgtransfquad, Point(x, y))
                t = unitSquareToQuad(squarequad, cx, cy)    -- this should be a no-op but let's keep it for robustness
                return "#{round(t.x, 3)} #{round(t.y, 3)}"

            transfs = (shape) -> shape\gsub("([-%d.]+) +([-%d.]+)", transf)

            -- assume that the whole line is a shape, but that there could be multiple formatting blocks
            line.text = line.text\gsub("}[^{]+", transfs)
        
        if relLine.clip
            transf = (x, y) ->
                cx, cy = quadToUnitSquare(relLine.quad, Point(x, y))
                t = unitSquareToQuad(quad, cx, cy)
                return "#{round(t.x, 2)} #{round(t.y, 2)}"

            clip = relLine.clip\gsub("([-%d.]+) +([-%d.]+)", transf)

            -- FIXME: Handle two clips per line properly
            line.text = line.text\gsub("\\i?clip%([^%)]-%)", clip)
            if not line.text\gmatch("\\i?clip")
                line.text = line.text\gsub("\\pos", clip .. "\\pos")

        if results.followpos
            line.text = line.text\gsub("\\pos%([-%d.]+.[-%d.]+%)", "\\pos(#{round(pos.x, 2)},#{round(pos.y,2)})")

        line.text = line.text\gsub("\\pos", perspRes..scaleCmds..bordCmds.."\\pos")

        if perspInfo["debfax"] != 0
            realfax = (perspInfo["debfax"]*(scale.y/100))/(scale.x/100)
            line.text = line.text\gsub("\\fax([-%d.]+)", "\\fax"..realfax)

            factor = getFaxCompFactor(styles, line)
            newPosX = round(pos.x - realfax * factor * scale.x / 100, 3)
            line.text = line.text\gsub("\\pos", "\\pos(#{newPosX},#{round(pos.y, 3)})\\org")

    -- finally, set the lines
    for si, li in ipairs(sel)
        sub[li] = lines[si]

    aegisub.progress.task(string.format("Magiccing it together"))
    aegisub.set_undo_point(script_name)
    return sel

--Register macro (no validation function required)

if haveDepCtrl
    depctrl\registerMacro perspmotion
else
    aegisub.register_macro(script_name, script_description, perspmotion)
