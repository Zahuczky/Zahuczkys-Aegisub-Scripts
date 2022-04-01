export script_name="Aegisub-Perspective-Motion BETA"
export script_description="Applying perspective tracking"
export script_author="Zahuczky"
export script_version="0.2.6"
export script_namespace="zah.pers-mo_BETA"
github_repo="https://github.com/Zahuczky/Zahuczkys-Aegisub-Scripts"
tutorial_docs="https://zahuczky.com/aegisub-perspective-motion/"

export helptext = "Thank you for using my script!\n\nKeep in mind, that it's still in beta, so it might not perform as expected in every situation.\n\nYou can find instructions and a tutorial at\n\t"..tutorial_docs.."\n\nOr you can contribute to the project at my GitHub page\n\t"..github_repo.."\n\nPull requests, issues and feature requests are very welcome!"

tr = aegisub.gettext

--DependencyControl = require "l0.DependencyControl"
--depctrl = DependencyControl{
--    feed: "https://github.com/Zahuczky/Zahuczkys-Aegisub-Scripts/DependencyControl.json",
--		}

-- DependencyControl stuff for version management
haveDepCtrl, DependencyControl, depctrl = pcall(require, "l0.DependencyControl")
if haveDepCtrl
    depctrl = DependencyControl {
        feed: "https://github.com/Zahuczky/Zahuczkys-Aegisub-Scripts/DependencyControl.json",
    }

-- Relative stuff

-- solves a system of linear equation using LU decomposition with partial pivoting.
-- mat: nxn table of row vectors
-- b: rhs vector
solveLU = (mat, b) ->
	n = #mat

	-- deep copy mat
	m = {k, {kk, vv for kk, vv in pairs v} for k, v in pairs mat}

	-- LU
	for i=1,n
		-- pivoting
		maxv = -1
		p = -1
		for j=i,n
			if math.abs(m[j][i]) > maxv
				p = i
				maxv = math.abs(m[j][i])

		mi = m[i]
		mp = m[p]
		bi = b[i]
		bp = b[p]
		m[i] = mp
		m[p] = mi
		b[i] = bp
		b[p] = bi

		-- LU step
		for j=i,n 		-- R
			for k=1,(i-1)
				m[i][j] -= m[i][k] * m[k][j]
		for j=(i+1),n 	-- L
			for k=1,(i-1)
				m[j][i] -= m[j][k] * m[k][i]
			m[j][i] /= m[i][i]

	-- forward substitution
	z = {}
	for i=1,n
		z[i] = b[i]
		for j=1,(i-1)
			z[i] -= m[i][j] * z[j]

	-- backward substitution
	x = {}
	for ii=1,n
		i = n + 1 - ii
		x[i] = z[i]
		for j=(i+1),n
			x[i] -= m[i][j] * x[j]
		x[i] /= m[i][i]

	return x


-- 2x2 wrapper for solveLU
solve2x2 = (a11, a12, a21, a22, b1, b2) ->
	b = solveLU({{a11, a12}, {a21, a22}}, {b1, b2})
	return b[1], b[2]


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

unrot = (coord_in, org, diag, get_rot) -> --diag=true, get_rot=false
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

	if not get_rot
		if diag return diag_diff else return ratio
	if flip < 0
		return nil

	fry = math.atan(n.x/n.z)
	s = ""
	s = s.."\\fry"..round((-fry / math.pi * 180), 2)
	export debfry = round((-fry / math.pi * 180), 2)
	rot_n = n\rot_y(fry)
	frx = -math.atan(rot_n.y/rot_n.z)
	if n0.z < 0
		frx += math.pi
	s = s.."\\frx"..round((-frx / math.pi * 180), 2)
	export debfrx = round((-frx / math.pi * 180), 2)
	n = vector(a, b)
	ab_unrot = vector(a, b)\rot_y(fry)\rot_x(frx)
	ac_unrot = vector(a, c)\rot_y(fry)\rot_x(frx)
	ad_unrot = vector(a, d)\rot_y(fry)\rot_x(frx)
	frz = math.atan2(ab_unrot.y, ab_unrot.x)
	s = s.."\\frz"..round((-frz / math.pi * 180), 2)
	export debfrz = round((-frz / math.pi * 180), 2)
	ad_unrot = ad_unrot\rot_z(frz)
	fax = ad_unrot.x/ad_unrot.y
	if math.abs(fax) > 0.01
		s = s.."\\fax"..round(fax, 2)
		export debfax = round(fax, 2)
	return s

binary_search = (f, l, r, eps) ->
	fl = f(l)
	fr = f(r)
	if fl <= 0 and fr >= 0
		export op = (a, b) ->
			if a > b
				return true
			else
				return false
	elseif fl >= 0 and fr <= 0
		export op = (a, b) ->
			if a < b
				return true
			else
				return false
	else
		return nil

	while (r - l > eps)
		c = (l + r) / 2
		if op(f(c), 0)
			r = c
		else
			l = c

	return (l + r) / 2

find_ex = (f, coord) ->
	w_center = {0, 0}
	w_size = 100000.0
	iterations = math.floor(math.log(w_size * 100) / math.log(4))
	s = 4
	for k = 0, iterations-1
		res = {}
		for i = -s, s-1
			x = w_center[1] + w_size*i/10
			for j = -s, s-1
				y = w_center[2] + w_size*j/10
				table.insert(res, {unrot(coord, Point(x, y), true, false), x, y})

		export ex = f(res)
		w_center = {ex[2], ex[3]}
		w_size = w_size / 3
	return Point(ex[2], ex[3])

zero_on_ray = (coord, center, v, a, eps) ->
	vrot = v\rot_z(a)
	f = (x) ->
		p = vrot\mul(x)\add(center)
		return unrot(coord, p, true, false)
	l = binary_search(f, 0, (center\length! + 1000000) / v\length!, eps)
	if l == nil
		return nil
	p = vrot\mul(l)\add(center)
	ratio = unrot(coord, p, false, false)
	r = unrot(coord, p, true, false)
	if r == nil
		return nil
	else
		return p, ratio

find_rot = (t, n, t_center) ->
	for i = 1, n
		table.insert(t[i], dist(t_center, t[i][2]))

	m = t[1][4]
	r = t[1]
	for i = 1, n
		if m > t[i][4]
			m = t[i][4]
			r = t[i]
	return r[1], r[2], r[3]

find_mn_point = (t) ->
	j = 1
	for k, v in pairs(t)
		if t[j] != nil
			j += 1
		else break

	rs = t[1][1]
	rl = t[1]
	for i = 1, j-1
		if rs > t[i][1]
			rs = t[i][1]
			rl = t[i]

	return rl

find_mx_point = (t) ->
	j = 1
	for k, v in pairs(t)
		if t[j] != nil
			j += 1
		else break

	rs = t[1][1]
	rl = t[1]
	for i = 1, j-1
		if rs < t[i][1]
			rs = t[i][1]
			rl = t[i]

	return rl

count_e = (t) ->
	e = 0
	for i = 1, 100
		if t[i] != nil
			e += 1
		else break
	return e

-- Getting clip() from clipArray, instead of matching from line
perspective = (clip, midPointOrg, line, tr_org, tr_centorg, tr_center, tr_ratio) ->
	if clip == nil
		aegisub.log("\\clip missing")

	coord = {}
	for cx, cy in clip\gmatch("([-%d.]+).([-%d.]+)")
		table.insert(coord, Point(cx, cy))

	mn_point = find_ex(find_mn_point, coord)
	mx_point = find_ex(find_mx_point, coord)

	target_ratio = dist(coord[1], coord[2])/dist(coord[1], coord[4])

	c = mn_point\add(mx_point)\mul(0.5)
	v = mn_point\sub(mx_point)\rot_z(math.pi / 2)\mul(100000)

	inf_p = c\add(v)
	if unrot(coord, inf_p, true, false) > 0
		mn_center = true
		export center = mn_point
		export other = mx_point
	else
		mn_center = false
		export center = mx_point
		export other = mn_point

	v = other\sub(center)

	rots = {}
	steps = 100
	for i = 0, steps-1
		a = 2 * math.pi * i / steps

		zero = {}
		zero[1], zero[2] = zero_on_ray(coord, center, v, a, 1e-02)

		if zero[1] != nil
			p, ratio = zero[1], zero[2]
			table.insert(rots, {ratio, p, a})

	if tr_org
		if line.text\match("org%b()")
			export pos_org = line.text\match("org%b()")
		elseif line.text\match("pos%b()")
			export pos_org = line.text\match("pos%b()")
		else
			aegisub.log("\\org or \\pos missing")
			aegisub.cancel!

		px, py = pos_org\match("([-%d.]+).([-%d.]+)")
		target_org = Point(px, py)

		tf_tags = unrot(coord, target_org, true, true)

		if tf_tags == nil
			aegisub.log(tf_tags)
		else
			return ""..tf_tags


	if tr_centorg
		if line.text\match("org%b()")
			export pos_org = line.text\match("org%b()")
		elseif line.text\match("pos%b()")
			export pos_org = line.text\match("pos%b()")
		else
			aegisub.log("\\org or \\pos missing")
			aegisub.cancel!

		px, py = midPointOrg[si]\match("([-%d.]+).([-%d.]+)")
		target_org = Point(px, py)

		tf_tags = unrot(coord, target_org, true, true)

		if tf_tags == nil
			aegisub.log(tf_tags)
		else
			return "\\org("..target_org.x..","..target_org.y..")"..tf_tags

--	if results.option = "Transform for target org"
--		if tr_org
--			if line.text\match("org%b()")
--				export pos_org = line.text\match("org%b()")
--			elseif line.text\match("pos%b()")
--				export pos_org = line.text\match("pos%b()")
--			else
--				aegisub.log("\\org or \\pos missing")
--				aegisub.cancel!

--			px, py = pos_org\match("([-%d.]+).([-%d.]+)")
--			target_org = Point(px, py)
--
--			tf_tags = unrot(coord, target_org, true, true)

--			if tf_tags == nil
--				aegisub.log(tf_tags)
--			else
--				return ""..tf_tags

	if count_e(rots) == 0
		aegisub.log("No proper perspective found.")
		aegisub.cancel!

	if tr_center
		t_center = coord[1]\add(coord[2])\add(coord[3])\add(coord[4])\mul(0.25)
		ratio, p, a = find_rot(rots, count_e(rots), t_center)
		tf_tags = unrot(coord, p, true, true)
		if tf_tags == nil
			aegisub.log(tf_tags)
		else
			return "\\org("..round(p.x, 1)..","..round(p.y, 1)..")"..tf_tags

	if tr_ratio
		segs = {}
		for i = 0, count_e(rots)-1
			if i == 0
				i2 = count_e(rots)
				if (rots[i2-1][1] - target_ratio) * (rots[i+1][1] - target_ratio) <= 0
					table.insert(segs, {rots[i2-1][3], rots[i+1][3]})
			elseif i == 1
				i2 = 2
				if (rots[i2-1][1] - target_ratio) * (rots[i+1][1] - target_ratio) <= 0
					table.insert(segs, {rots[i2-1][3], rots[i+1][3]})
			else
				if (rots[i][1] - target_ratio) * (rots[i+1][1] - target_ratio) <= 0
					table.insert(segs, {rots[i][3], rots[i+1][3]})

		for i = 1, count_e(segs)
			seg = {}
			seg = {segs[i][1], segs[i][2]}

			f = (x) ->
				t_res = {}
				t_res[1], t_res[2] = zero_on_ray(coord, center, v, x, 1e-05)

				if t_res[1] != nil
					p, ratio = t_res[1], t_res[2]
					return (ratio - target_ratio)
				else
					return 1e7

			a = binary_search(f, seg[1], seg[2], 1e-04)

			if a == nil then
				a = seg[1]

			p, ratio = zero_on_ray(coord, center, v, a, 1e-05)
			tf_tags = unrot(coord, p, true, true)

			if tf_tags != nil
				return "\\org("..round(p.x, 1)..","..round(p.y, 1)..")"..tf_tags


-- XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX

-- function that contains everything that happens before the transforms
datahandling = (sub, sel, results, pressed) ->

-- Relative stuff
	startOneMS = sub[sel[1]].start_time
	firstFrame = aegisub.frame_from_ms(startOneMS)
	videoPos = aegisub.project_properties!.video_position
	relFrame = videoPos-firstFrame+1
	aegisub.debug.out("relative frame: "..relFrame)


	-- Putting the user input into a table
	export dataArray = { }
	j=1
	for i in string.gmatch(results.data, "([^\n]*)\n?")
		dataArray[j] = i
		j=j+1

	if results.data == ""
		aegisub.debug.out("You forgot to give me any data, so I quit.\n\n")
	elseif dataArray[9] != "Effects	CC Power Pin #1	CC Power Pin-0002"
		aegisub.debug.out("I have no idea what kind of data you pasted in, but I'm sure it's not what I wanted.\n\nI need After Effects CC Power Pin data.\n\nPress the HELP button in the script if you don't know what you're doing.\n\n")

	-- Filtering out everything other than the data, and putting them into their own tables.
	-- Power Pin data goes like this: TopLeft=0002, TopRight=0003, BottomRight=0005,  BottomLeft=0004
	export posPin1=0
	export posPin2=0
	export posPin3=0
	export posPin4=0
	for k=1,#dataArray
		if dataArray[k] == "Effects	CC Power Pin #1	CC Power Pin-0002"
			posPin1=k+2

	export dataLength = ((#dataArray-26)/4)+posPin1

	export p=1
	export helpArray = { }
	export x1 = { }
	export y1 = { }
	--	for l=posPin1,dataLength
	--		for m in string.gmatch(dataArray[l], "([^\t]*)\t?")
	--			helpArray[o] = m
	--			x1[o] = helpArray[2]
	--			o+1

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
		if dataArray[k] == "Effects	CC Power Pin #1	CC Power Pin-0003"
			posPin1=k+2

	export dataLength = ((#dataArray-26)/4)+posPin1

	export p=1
	export helpArray = { }
	export x2 = { }
	export y2 = { }
	--	for l=posPin1,dataLength
	--		for m in string.gmatch(dataArray[l], "([^\t]*)\t?")
	--			helpArray[o] = m
	--			x1[o] = helpArray[2]
	--			o+1

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
		if dataArray[k] == "Effects	CC Power Pin #1	CC Power Pin-0004"
			posPin1=k+2

	export dataLength = ((#dataArray-26)/4)+posPin1

	export p=1
	export helpArray = { }
	export x4 = { }
	export y4 = { }
	--	for l=posPin1,dataLength
	--		for m in string.gmatch(dataArray[l], "([^\t]*)\t?")
	--			helpArray[o] = m
	--			x1[o] = helpArray[2]
	--			o+1

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
		if dataArray[k] == "Effects	CC Power Pin #1	CC Power Pin-0005"
			posPin1=k+2

	export dataLength = ((#dataArray-26)/4)+posPin1

	export p=1
	export helpArray = { }
	export x3 = { }
	export y3 = { }
	--	for l=posPin1,dataLength
	--		for m in string.gmatch(dataArray[l], "([^\t]*)\t?")
	--			helpArray[o] = m
	--			x1[o] = helpArray[2]
	--			o+1

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
	-- XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX



	-- XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX

	--Calculate org from center of plane
	export intersectX = { }
	export intersectY = { }
	for i=1,#x1
		-- la = ((x4[i] - x1[i]) * (y4[i] - y2[i]) - (x4[i] - x2[i]) * (y4[i] - y1[i])) / ((x3[i] - x1[i]) * (y4[i] - y2[i]) - (x4[i] - x2[i]) * (y3[i] - y1[i]))
		la1, la2 = solve2x2(x3[i] - x1[i], x4[i] - x2[i], y3[i] - y1[i], y4[i] - y2[i], x4[i] - x1[i], y4[i] - y1[i])

		intersectX[i] = la1 * (x3[i] - x1[i]) + x1[i]
		intersectY[i] = la2 * (y3[i] - y1[i]) + y1[i]

	export midPointOrg = { }
	for i=1,#x1
		midPointOrg[i] = "\\org("..round(intersectX[i],2)..","..round(intersectY[i],2)..")"


-- END OF PERSPECTIVE.MOON CODE

-- takes corners of a quad in the usual ordering
-- returns {q1, q2, q3, q4}, where:
-- 	- {q1, q2, q3, q4} form a rectangle in 3d space
--  - after the camera projection, the qi map to some translation of the given quad
-- such that these vertices make a rectangle in 3d space
find3Drect = (coord) ->
	-- translate to origin
	v1 = vector(coord[1], coord[2])
	v2 = vector(coord[1], coord[4])
	v12 = vector(coord[1], coord[3])
	-- want translation vector t = (xt, yt) and z-coordinates z1, z2, z3
	-- such that qi := (vi + t, z) (for vi = v3) and q0 := (t, 1)
	-- form a rectangle. The following is what you get when you work out the equations for that.
	-- Equations for the zi are linear and independent of t:
	h1 = v12\sub(v1)
	h2 = v12\sub(v2)
	z1, z2 = solve2x2(h1.x, h2.x, h1.y, h2.y, v12.x, v12.y)
	-- Remaining equation is a conic in xt and yt of the form:
	--  a (xt^2 + yt^2) + b1 xt + b2 yt + c
	-- i.e. always a circle
	cona = (1 - z1) * (1 - z2)
	conbx = z1 * z2 * (v1.x + v2.x) - z1 * v1.x - z2 * v2.x
	conby = z1 * z2 * (v1.y + v2.y) - z1 * v1.y - z2 * v2.y
	conc = z1 * z2 * sc_pr(v1, v2) + cona
	t = nil
	if cona ~= 0 and math.max(math.abs(conc / cona), math.abs(conbx * conbx + conby * conby / cona)) <= 1000000000000 -- 10^12
		-- complete the square and find the parameters of the circle
		centerx = -conbx / (2 * cona)
		centery = -conby / (2 * cona)
		sqradius = (conbx * conbx + conby * conby) / (4 * cona * cona) - conc / cona
		-- I don't really know what's numerically best here... just pick the rightmost point for now.
		t = Point(centerx + math.sqrt(sqradius), centery)
	else
		-- The conic is very close to degenerate and we just assume it's a line.
		-- Here, just picking x or y intercepts is probably the easiest - it's just a constant factor off of equal x and y.
		if math.abs(conbx) > math.abs(conby)
			t = Point(-conc / conbx, 0)
		else
			t = Point(0, -conc / conby)

	z = {1, z1, z1 + z2 - 1, z2}

	coord3d = {}
	for i=1,4
		coord3d[i] = Point(coord[i].x - coord[1].x, coord[i].y - coord[1].y, 1)\add(t)\mul(z[i])

	-- some tests - can be disabled.
	qdiff = coord3d[1]\add(coord3d[3])\sub(coord3d[2])\sub(coord3d[4]) 	-- quad should be a parallelogram
	qdot = sc_pr(vector(coord3d[1], coord3d[2]), vector(coord3d[1], coord3d[4])) 		-- sides of quad should be perpendicular
	qerror = qdiff\length() + math.abs(qdot)
	-- if these values get too large (larger than 1), bug arch1t3cht until he fixes it.
--	aegisub.debug.out("Largest absolute error in finding projection: #{qerror}\n")

	return coord3d


-- New new scaling algorithm: Derived from explicit formulas
newNewScale = (lines, x1, x2, x3, x4, y1, y2, y3, y4) ->
	scales = { }
	for i=1,#lines
		position = lines[i].text\match("pos%b()")
		posX, posY = position\match("([-%d.]+).([-%d.]+)")

		-- find a rectangle projecting to (a translation of) the perspective quad
		coord = { Point(x1[i], y1[i]), Point(x2[i], y2[i]), Point(x3[i], y3[i]), Point(x4[i], y4[i]) }
		coord3d = find3Drect(coord)

		-- translate the subtitle line into the projected rectangle
		p1t = coord3d[1]\mul(1 / coord3d[1].z)
		p1t.z = 0
		posTransl = Point(posX, posY)\add(vector(coord[1], p1t))
		posTransl.z = 1

		-- find the point on the 3d rectangle projecting to the translated point
		-- i.e. intersect the ray through the point with the plane through the quad
		v1 = vector(coord3d[1], coord3d[2])
		v2 = vector(coord3d[1], coord3d[4])
		sol = solveLU({
			{posTransl.x, -v1.x, -v2.x},
			{posTransl.y, -v1.y, -v2.y},
			{posTransl.z, -v1.z, -v2.z},
			}, {coord3d[1].x, coord3d[1].y, coord3d[1].z})
		pos3d = posTransl\mul(sol[1])

		rectCenter = coord3d[1]\add(coord3d[3])\mul(0.5)
		quadArea = 0.5 * (vec_pr(vector(coord[1], coord[2]), vector(coord[1], coord[4]))\length() + vec_pr(vector(coord[3], coord[2]), vector(coord[3], coord[4]))\length())

		scales[i] = math.sqrt(quadArea) * rectCenter.z * rectCenter.z / (pos3d.z * pos3d.z)

	relScales = { }
	for i=1,#lines
		relScales[i] = 100 * scales[i] / scales[27]

	return relScales, relScales

-- New scaling algorithm
newScale = (lines, x1, x2, x3, x4, y1, y2, y3, y4) ->
	posX = { }
	posY = { }
	for i=1,#lines
		export position = lines[i].text\match("pos%b()")
		posX[i], posY[i] = position\match("([-%d.]+).([-%d.]+)")

	export dA = { }
	export dB = { }
	export dC = { }
	export dD = { }
	export A = { }
	export B = { }
	export C = { }
	for i=1,#lines
		B[i] = x2[i]-x1[i]
		A[i] = y1[i]-y2[i]
		C[i] = x1[i]*y2[i]-x2[i]*y1[i]
		dA[i] = (A[i]*posX[i]+B[i]*posY[i]+C[i])/(math.sqrt(A[i]*A[i]+B[i]*B[i]))

	for i=1,#lines
		B[i] = x3[i]-x2[i]
		A[i] = y2[i]-y3[i]
		C[i] = x2[i]*y3[i]-x3[i]*y2[i]
		dB[i] = (A[i]*posX[i]+B[i]*posY[i]+C[i])/(math.sqrt(A[i]*A[i]+B[i]*B[i]))

	for i=1,#lines
		B[i] = x4[i]-x3[i]
		A[i] = y3[i]-y4[i]
		C[i] = x3[i]*y4[i]-x4[i]*y3[i]
		dC[i] = (A[i]*posX[i]+B[i]*posY[i]+C[i])/(math.sqrt(A[i]*A[i]+B[i]*B[i]))

	for i=1,#lines
		B[i] = x1[i]-x4[i]
		A[i] = y4[i]-y1[i]
		C[i] = x4[i]*y1[i]-x1[i]*y4[i]
		dD[i] = (A[i]*posX[i]+B[i]*posY[i]+C[i])/(math.sqrt(A[i]*A[i]+B[i]*B[i]))

	export distanceY = { }
	for i=1,#lines
		distanceY[i] = dA[i]+dC[i]

	export distanceX = { }
	for i=1,#lines
		distanceX[i] = dB[i]+dD[i]

	export scaleY = { }
	export scaleX = { }
	for k=1,#lines
		scaleY[k] = (distanceY[k]/distanceY[27])*100
		scaleX[k] = (distanceX[k]/distanceX[27])*100

	aegisub.debug.out("newscale")

	return scaleX, scaleY

-- Old scaling algorithm, better if the pos of sign is in the exact middle of the perspective plane
oldScale = (lines, x1, x2, x3, x4, y1, y2, y3, y4) ->
	export LMidPointX = { }
	export LMidPointY = { }
	export RMidPointX = { }
	export RMidPointY = { }
	for i=1,#x1
		LMidPointX[i] = (x1[i]+x4[i])/2
		LMidPointY[i] = (y1[i]+y4[i])/2
		RMidPointX[i] = (x2[i]+x3[i])/2
		RMidPointY[i] = (y2[i]+y3[i])/2

	export distanceX = { }
	for j=1,#x1
		distanceX[j] = math.sqrt(((RMidPointX[j]-LMidPointX[j])*(RMidPointX[j]-LMidPointX[j]))+((RMidPointY[j]-LMidPointY[j])*(RMidPointY[j]-LMidPointY[j])))

	export scaleX = { }
	for k=1,#x1
		scaleX[k] = (distanceX[k]/distanceX[27])*100

--	 XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
	export TMidPointX = { }
	export TMidPointY = { }
	export BMidPointX = { }
	export BMidPointY = { }
	for i=1,#x1
		TMidPointX[i] = (x1[i]+x2[i])/2
		TMidPointY[i] = (y1[i]+y2[i])/2
		BMidPointX[i] = (x4[i]+x3[i])/2
		BMidPointY[i] = (y4[i]+y3[i])/2

	export distanceY = { }
	for j=1,#x1
		distanceY[j] = math.sqrt(((TMidPointX[j]-BMidPointX[j])*(TMidPointX[j]-BMidPointX[j]))+((TMidPointY[j]-BMidPointY[j])*(TMidPointY[j]-BMidPointY[j])))

	export scaleY = { }
	for k=1,#x1
		scaleY[k] = (distanceY[k]/distanceY[27])*100

	aegisub.debug.out("oldscale")

	return scaleX, scaleY

-- main function, this get's run as 'apply' is clicked
perspmotion = (sub, sel) ->

	GUI = {
		main: {
			{class: "label",  x: 0, y: 14, width: 1, height: 1,
				label: "v"..script_version},
			{class: "label",  x: 0, y: 0, width: 1, height: 1,
				label: "Only paste After Effects CC POWER PIN data"},
			{class: "label",  x: 0, y: 1, width: 1, height: 1,
				label: "here, not Transform or Corner Pin data!"},
			{class: "textbox", name: "data",  x: 0, y: 2, width: 1, height: 7, },
			{class: "checkbox", name: "includeclip",  x: 0, y: 9, width: 1, height: 1,
				label: "Include \\clip for debugging", value: true},
			{class: "checkbox", name: "absolute",  x: 0, y: 10, width: 1, height: 1,
				label: "Absolute", value: false,
					hint: "Only tick this if you've also ticked absolute in Aegisub-Motion!"},
			{class: "label",  x: 0, y: 12, width: 1, height: 1,
				label: "Choose an option for calculating perspective:"},
			{class: "dropdown", name: "option",  x: 0, y: 13, width: 1, height: 1,
				items: {"Transform for target org","Transform with center org","Transforms near center of tetragon","Transforms with target ratio"}, value: "Transform for target org"},
			},

		help: {
			{class: "textbox", x: 0, y: 0, width: 45, height: 15, value: helptext}
		}
	}

	buttons = {"Apply","Cancel","HELP"}

	pressed, results = aegisub.dialog.display(GUI.main, {"Apply","Cancel","HELP"})
	if pressed=="Cancel" aegisub.cancel()
	if pressed=="HELP" pressed, results = aegisub.dialog.display(GUI.help, {"Close"})
	if pressed=="Close" aegisub.cancel()

	datahandling(sub, sel, results, pressed)

	lines = {}
	for si, li in ipairs(sel)
		lines[si] = sub[li]

	-- if results.absolute
	-- 	scaleX, scaleY = oldScale(lines, x1, x2, x3, x4, y1, y2, y3, y4)
	-- else
	-- 	scaleX, scaleY = newScale(lines, x1, x2, x3, x4, y1, y2, y3, y4)

	scaleX, scaleY = newNewScale(lines, x1, x2, x3, x4, y1, y2, y3, y4)

	export scales = { }
	for i=1,#lines
		scales[i] = "\\fscx"..round(scaleX[i],2).."\\fscy"..round(scaleY[i],2)

-- Bord scaling
	orgBordArray = { }
	xBordArray = { }
	yBordArray = { }
	baseBord = 0
	for i=1,#lines
		if lines[i].text\match("\\bord([-%d.]+)")
			orgBordArray[i] = lines[i].text\match("\\bord([-%d.]+)")
		else
			orgBordArray[i] = "0"
			aegisub.debug.out("Put your \\bord value in your line, if it's only in your style, it's gonna get translated to 0. \n")

	baseBord = tonumber(orgBordArray[27])

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

--		if 	debfax != nil
--			fayFix = (debfax*(scaleY[si]/100))/(scaleX[si]/100)

		result = ""
		if results.option == "Transform for target org"
			result = perspective(clipArray[si], midPointOrg, line, true, false, false, false)
		if results.option == "Transform with center org"
			result = perspective(clipArray[si], midPointOrg, line, false, true, false, false)
		elseif results.option == "Transforms near center of tetragon"
			result = perspective(clipArray[si], midPointOrg, line, false, false, true, false)
		elseif results.option == "Transforms with target ratio"
			result = perspective(clipArray[si], midPointOrg, line, false, false, false, true)
		line.text = delete_old_tag(line)
		if results.includeclip
			line.text = line.text\gsub("\\pos", "\\"..clipArray[si]..result..scales[si]..bords[si].."\\pos")
		else
			line.text = line.text\gsub("\\pos", result..scales[si]..bords[si].."\\pos")
		if debfax != nil
			line.text = line.text\gsub("\\fax([-%d.]+)", "\\fax"..(debfax*(scaleY[si]/100))/(scaleX[si]/100))
		sub[li] = line






--		aegisub.debug.out(clipArray[si])
--		aegisub.debug.out("\n")
--		for i=1,#sel
--			aegisub.debug.out(clipArray[si])
--			aegisub.debug.out("\n")
--	aegisub.debug.out(results.option)
--	aegisub.debug.out("\n")
--	aegisub.debug.out(tostring(LMidPointY[1]))
--	aegisub.debug.out("\n")
--	aegisub.debug.out(tostring(RMidPointX[1]))
--	aegisub.debug.out("\n")
--	aegisub.debug.out(tostring(RMidPointY[1]))
--	aegisub.debug.out("\n")
--	aegisub.debug.out("Distance: "..tostring(distanceX[1]))
--	aegisub.debug.out("\n")
--	aegisub.debug.out("Scale[1]: "..tostring(scaleX[1]))
--	aegisub.debug.out("\n")
--	aegisub.debug.out("Scale[2]: "..tostring(scaleX[2]))
--	aegisub.debug.out("\n")
--	aegisub.debug.out("- Zahuczky")
--	aegisub.debug.out(midPointOrg[1])
	aegisub.set_undo_point(script_name)
	return sel
--		if debfry > 90 and debfry < 270 aegisub.debug.out("Uh-oh! Seems like your text was mirrored! Are you sure that's what you wanted? Here's a reminder: You need to draw your clip in a manner, where the first point of your clip is the upper left, then going clockwise from there.")
--		elseif debfry > -270 and debfry < -90 aegisub.debug.out("Uh-oh! Seems like your text was mirrored! Are you sure that's what you wanted? Here's a reminder: You need to draw your clip in a manner, where the first point of your clip is the upper left, then going clockwise from there.")
--		elseif debfrx > 90 and debfrx < 270 aegisub.debug.out("Uh-oh! Seems like your text was mirrored! Are you sure that's what you wanted? Here's a reminder: You need to draw your clip in a manner, where the first point of your clip is the upper left, then going clockwise from there.")
--		elseif debfrx > -270 and debfrx < -90 aegisub.debug.out("Uh-oh! Seems like your text was mirrored! Are you sure that's what you wanted? Here's a reminder: You need to draw your clip in a manner, where the first point of your clip is the upper left, then going clockwise from there.")
--		elseif debfrz > 90 or debfrz < -90 aegisub.debug.out("Uh-oh! Seems like your text was rotated a lot! Are you sure that's what you wanted? Here's a reminder: You need to draw your clip in a manner, where the first point of your clip is the upper left, then going clockwise from there.")


--		tagArray = { }
--		for i=1,#x1
--			tagArray[i] = "\\frz"..debfrz.."\\fry"..debfry.."\\frx"..debfrx..






--		for si,li in ipairs(sel)

			--Read in the line
--			line=sub[li]

			--Add the tags. Don't forget to escape the slash
--			line.text=tagArray[si]..line.text

			--Put the line back into the subtitles
--			sub[li]=line


--			aegisub.set_undo_point(script_name)
--			return sel

-- XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
--	fuckme = x1[10]

	--Go through all the lines in the selection
--	for si,li in ipairs(sel)

		--Read in the line
--		line=sub[li]

		--Add the italics. Don't forget to escape the slash
--		line.text="\\frz"..debfrz.."\\fry"..debfry.."\\frx"..debfrx.."\\fax"..debfax..line.text

		--Put the line back into the subtitles
--		sub[li]=line

--	aegisub.debug.out(tostring(fuckme))
--	aegisub.debug.out(midPointOrg[i])

--		aegisub.debug.out(clipArray[8])

	--Set undo point and maintain selection

--Register macro (no validation function required)

if haveDepCtrl
	depctrl\registerMacro perspmotion
else
	aegisub.register_macro(script_name, script_description, perspmotion)


--aegisub.register_macro(script_name,script_description,perspmotion)
