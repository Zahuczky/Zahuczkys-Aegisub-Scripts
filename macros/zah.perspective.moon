script_name="Perspective"
script_description="Zeght's perspective.py but in moonscript by Alendt, with a few tweaks from Zahuczky"
script_author=""
script_version="1.1"

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

round = (val, n) ->
	if n
		return math.floor((val * 10^n) + 0.5) / (10^n)
	else
		return math.floor(val+0.5)

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

perspective = (line, tr_org, tr_center, tr_ratio) ->
	clip = line.text\match("clip%b()")
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

delete_old_tag = (line) ->
	line.text = line.text\gsub("\\frx([-%d.]+)", "")\gsub("\\fry([-%d.]+)", "")\gsub("\\frz([-%d.]+)", "")\gsub("\\org%b()", "")\gsub("\\fax([-%d.]+)", "")\gsub("\\fay([-%d.]+)", "")
	return line.text

aegi1 = (sub, sel) ->
	for si, li in ipairs(sel)
		line = sub[li]
		result = perspective(line, true, false, false)
		line.text = delete_old_tag(line)
		line.text = line.text\gsub("\\clip", result.."\\clip")
		sub[li] = line
	if debfry > 90 and debfry < 270 aegisub.debug.out("Uh-oh! Seems like your text was mirrored! Are you sure that's what you wanted? Here's a reminder: You need to draw your clip in a manner, where the first point of your clip is the upper left, then going clockwise from there.")
	elseif debfry > -270 and debfry < -90 aegisub.debug.out("Uh-oh! Seems like your text was mirrored! Are you sure that's what you wanted? Here's a reminder: You need to draw your clip in a manner, where the first point of your clip is the upper left, then going clockwise from there.")
	elseif debfrx > 90 and debfrx < 270 aegisub.debug.out("Uh-oh! Seems like your text was mirrored! Are you sure that's what you wanted? Here's a reminder: You need to draw your clip in a manner, where the first point of your clip is the upper left, then going clockwise from there.")
	elseif debfrx > -270 and debfrx < -90 aegisub.debug.out("Uh-oh! Seems like your text was mirrored! Are you sure that's what you wanted? Here's a reminder: You need to draw your clip in a manner, where the first point of your clip is the upper left, then going clockwise from there.")
	elseif debfrz > 90 or debfrz < -90 aegisub.debug.out("Uh-oh! Seems like your text was rotated a lot! Are you sure that's what you wanted? Here's a reminder: You need to draw your clip in a manner, where the first point of your clip is the upper left, then going clockwise from there.")

aegi2 = (sub, sel) ->
	for si, li in ipairs(sel)
		line = sub[li]
		result = perspective(line, false, true, false)
		line.text = delete_old_tag(line)
		line.text = line.text\gsub("\\clip", result.."\\clip")
		sub[li] = line
	if debfry > 90 and debfry < 270 aegisub.debug.out("Uh-oh! Seems like your text was mirrored! Are you sure that's what you wanted? Here's a reminder: You need to draw your clip in a manner, where the first point of your clip is the upper left, then going clockwise from there.")
	elseif debfry > -270 and debfry < -90 aegisub.debug.out("Uh-oh! Seems like your text was mirrored! Are you sure that's what you wanted? Here's a reminder: You need to draw your clip in a manner, where the first point of your clip is the upper left, then going clockwise from there.")
	elseif debfrx > 90 and debfrx < 270 aegisub.debug.out("Uh-oh! Seems like your text was mirrored! Are you sure that's what you wanted? Here's a reminder: You need to draw your clip in a manner, where the first point of your clip is the upper left, then going clockwise from there.")
	elseif debfrx > -270 and debfrx < -90 aegisub.debug.out("Uh-oh! Seems like your text was mirrored! Are you sure that's what you wanted? Here's a reminder: You need to draw your clip in a manner, where the first point of your clip is the upper left, then going clockwise from there.")
	elseif debfrz > 90 or debfrz < -90 aegisub.debug.out("Uh-oh! Seems like your text was rotated a lot! Are you sure that's what you wanted? Here's a reminder: You need to draw your clip in a manner, where the first point of your clip is the upper left, then going clockwise from there.")

aegi3 = (sub, sel) ->
	for si, li in ipairs(sel)
		line = sub[li]
		result = perspective(line, false, false, true)
		line.text = delete_old_tag(line)
		line.text = line.text\gsub("\\clip", result.."\\clip")
		sub[li] = line
	if debfry > 90 and debfry < 270 aegisub.debug.out("Uh-oh! Seems like your text was mirrored! Are you sure that's what you wanted? Here's a reminder: You need to draw your clip in a manner, where the first point of your clip is the upper left, then going clockwise from there.")
	elseif debfry > -270 and debfry < -90 aegisub.debug.out("Uh-oh! Seems like your text was mirrored! Are you sure that's what you wanted? Here's a reminder: You need to draw your clip in a manner, where the first point of your clip is the upper left, then going clockwise from there.")
	elseif debfrx > 90 and debfrx < 270 aegisub.debug.out("Uh-oh! Seems like your text was mirrored! Are you sure that's what you wanted? Here's a reminder: You need to draw your clip in a manner, where the first point of your clip is the upper left, then going clockwise from there.")
	elseif debfrx > -270 and debfrx < -90 aegisub.debug.out("Uh-oh! Seems like your text was mirrored! Are you sure that's what you wanted? Here's a reminder: You need to draw your clip in a manner, where the first point of your clip is the upper left, then going clockwise from there.")
	elseif debfrz > 90 or debfrz < -90 aegisub.debug.out("Uh-oh! Seems like your text was rotated a lot! Are you sure that's what you wanted? Here's a reminder: You need to draw your clip in a manner, where the first point of your clip is the upper left, then going clockwise from there.")

aegisub.register_macro("Perspective/Transform for target org", "Transform for target org", aegi1)
aegisub.register_macro("Perspective/Transforms near center of tetragon", "Transforms near center of tetragon", aegi2)
aegisub.register_macro("Perspective/Transforms with target ratio", "Transforms with target ratio", aegi3)
