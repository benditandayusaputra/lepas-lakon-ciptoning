extends Node2D
## Satu babak.
##
## Membangun peta ASCII (babak_maps.gd), kelir, latar berlapis, kabut, lalu menjalankan aturan:
## Bobot, ambil dan lepas, sesaji, pathok, kematian dan bangkit, kejar celeng, dan dua ending.

const T := 16
const GUST_ON := 2.2
const GUST_OFF := 1.0
const WIND := 60.0
const VISION := [48.0, 96.0, 420.0]
const GRASS := ["01", "02", "03", "04", "05", "06", "11", "12", "13", "14", "16", "18"]

var def: Dictionary
var map: Array
var W := 0
var H := 0
var death_y := 0.0
var player: Arjuna
var ending_busy := false

var _camera: Camera2D
var _kelir_mat: ShaderMaterial
var _post_mat: ShaderMaterial
var _fog_holder: Node2D
var _fog_mat: ShaderMaterial
var _layers: Array = []
var _layer_ref_y := 0.0
var _solid: TileMapLayer
var _bright := 1.0
var _spot := 0.0
var _dark_adapted := false
var _moon: Sprite2D = null
var _pal_from := {}
var _pal_to := {}

var _pathok: Array[Pathok] = []
var _sesaji: Array[Sesaji] = []
var _gates: Array[Gerbang] = []
var _keraton_gates: Array[Gerbang] = []
var _prajurit: Prajurit = null
var _refuse_t := 0.0
var _harta: Harta = null
var _celeng: Celeng = null
var _chase_x := -1.0
var _chase_end_x := -1.0
var _chase_started := false
var _chase_done := false
var _exit_x := -1.0
var _dahan: Array = []
var _wind_on := false
var _wind_t := 1.0
var _wind_fx: Array[CPUParticles2D] = []

var _snapshot := {}
var _finished := false
var _await_any := false

var _ui: CanvasLayer
var _prompt: Label
var _prompt_box: Control
var _tanda: Node2D
var _tanda_label: Label
var _tanda_t := 0.0
var _zoom := 1.0
var _hud_bobot: Label
## Dekorasi latar [node, rect]: memudar saat Arjuna lewat di depannya.
var _dekor: Array = []
var _hud_nyawa: HBoxContainer
var _hud_icons: HBoxContainer
var _hud_efek: Label
var _petunjuk: Array = []
var _end_label: Label
var _end_sub: Label
var _end_hint: Label
var _obj_box: VBoxContainer
var _obj_step: Label
var _step_i := -1
var _obj_delay := 5.0
var _obj_bright := 0.0
var _dancers: Array[Sprite2D] = []
var _pause_layer: CanvasLayer = null
var _pause_first: Button = null


func _ready() -> void:
	def = BabakDefs.get_def(Game.babak)
	map = BabakDefs.get_map(Game.babak)
	H = map.size()
	W = (map[0] as String).length()
	death_y = H * T + 48.0
	_petunjuk = []
	var batas := "Bobot %d" % int(Game.pilih([4, 3, 3]))
	for p in def["petunjuk"]:
		var arr: Array = p
		_petunjuk.append([arr[0], str(arr[1]).replace("Bobot 3", batas)])
	Game.bawaan_awal = Bobot.salin()
	_build_kelir()
	_build_tiles()
	_build_objects()
	_build_camera()
	_build_parallax()
	_build_fog()
	_build_post()
	_build_ui()
	Music.set_bypass(false)
	Music.play(str(def["musik"]))
	_take_snapshot(player.global_position)
	_show_petuah()
	# Kait uji untuk merekam trailer: langsung ke adegan akhir Tancep Kayon.
	if OS.get_cmdline_user_args().has("--uji-ending"):
		_uji_ending.call_deferred()


func _uji_ending() -> void:
	await get_tree().create_timer(1.0).timeout
	for s in _sesaji:
		if s.final:
			player.global_position = s.global_position + Vector2(-34, 0)
			player.velocity = Vector2.ZERO
			_camera.global_position = player.global_position + Vector2(0, -40)
			_camera.reset_smoothing()
	await get_tree().create_timer(1.0).timeout
	Bobot.setel([])
	_tancep_kayon()


# --- peta ---------------------------------------------------------------------

func cell(x: int, y: int) -> String:
	if y < 0:
		return "."
	if x < 0 or x >= W or y >= H:
		return "#"
	return (map[y] as String)[x]


func _feet(x: int, y: int) -> Vector2:
	return Vector2(x * T + T / 2.0, (y + 1) * T)


# --- membangun ----------------------------------------------------------------

func _build_kelir() -> void:
	var cl := CanvasLayer.new()
	cl.layer = -100
	add_child(cl)
	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_kelir_mat = ShaderMaterial.new()
	_kelir_mat.shader = Art.KELIR_SHADER
	var pal: Dictionary = Art.PATHET[str(def["pathet"])]
	_apply_palette(pal)
	_pal_from = pal
	_bright = float(def["terang"])
	_kelir_mat.set_shader_parameter("brightness", _bright)
	_kelir_mat.set_shader_parameter("flicker_amount", 1.0 if bool(Game.settings["kedip"]) else 0.15)
	bg.material = _kelir_mat
	cl.add_child(bg)


func _apply_palette(pal: Dictionary) -> void:
	_kelir_mat.set_shader_parameter("hot", pal["hot"])
	_kelir_mat.set_shader_parameter("mid", pal["mid"])
	_kelir_mat.set_shader_parameter("edge", pal["edge"])


func _make_tileset() -> TileSet:
	var img := Image.create(32, 16, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	img.fill_rect(Rect2i(0, 0, 16, 16), Color.WHITE)
	img.fill_rect(Rect2i(16, 0, 16, 4), Color.WHITE)
	var tex := ImageTexture.create_from_image(img)
	var ts := TileSet.new()
	ts.tile_size = Vector2i(T, T)
	ts.add_physics_layer()
	ts.set_physics_layer_collision_layer(0, 1)
	ts.set_physics_layer_collision_mask(0, 0)
	var src := TileSetAtlasSource.new()
	src.texture = tex
	src.texture_region_size = Vector2i(T, T)
	ts.add_source(src, 0)
	src.create_tile(Vector2i(0, 0))
	var td := src.get_tile_data(Vector2i(0, 0), 0)
	td.add_collision_polygon(0)
	td.set_collision_polygon_points(0, 0, PackedVector2Array([Vector2(-8, -8), Vector2(8, -8), Vector2(8, 8), Vector2(-8, 8)]))
	src.create_tile(Vector2i(1, 0))
	var to := src.get_tile_data(Vector2i(1, 0), 0)
	to.add_collision_polygon(0)
	to.set_collision_polygon_points(0, 0, PackedVector2Array([Vector2(-8, -8), Vector2(8, -8), Vector2(8, -4), Vector2(-8, -4)]))
	to.set_collision_polygon_one_way(0, 0, true)
	return ts


func _build_tiles() -> void:
	_solid = TileMapLayer.new()
	_solid.tile_set = _make_tileset()
	_solid.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_solid.modulate = Art.HITAM
	add_child(_solid)
	for y in H:
		for x in W:
			var ch := cell(x, y)
			if ch == "#":
				_solid.set_cell(Vector2i(x, y), 0, Vector2i(0, 0))
			elif ch == "-":
				_solid.set_cell(Vector2i(x, y), 0, Vector2i(1, 0))
	_build_grass()


## Rumput hitam di tepi atas tanah. Sebagian di depan Arjuna, seperti dahan dekat kamera.
func _build_grass() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 4242 + Game.babak
	var mat := Art.siluet_material(Art.HITAM)
	for x in W:
		for y in range(1, H):
			if cell(x, y) != "#" or cell(x, y - 1) == "#" or cell(x, y - 1) == "~":
				continue
			if rng.randf() > 0.5:
				continue
			var t := Art.tex("res://assets/foliage/grass_%s.png" % GRASS[rng.randi() % GRASS.size()])
			if t == null:
				continue
			var s := Sprite2D.new()
			s.texture = t
			var h := rng.randf_range(9.0, 18.0)
			var k := h / float(t.get_height())
			s.scale = Vector2(k * rng.randf_range(0.9, 1.4), k)
			s.position = Vector2(x * T + rng.randf_range(2.0, 14.0), y * T + 2.0 - h / 2.0)
			s.material = mat
			s.z_index = 3 if rng.randf() < 0.25 else -1
			add_child(s)
	_build_roots(rng)


## Akar gantung di bawah atap dan jembatan supaya tidak tampak seperti balok melayang.
func _build_roots(rng: RandomNumberGenerator) -> void:
	for x in W:
		for y in range(0, H - 1):
			if cell(x, y) != "#" or cell(x, y + 1) == "#":
				continue
			for i in rng.randi_range(1, 3):
				if rng.randf() < 0.35:
					continue
				var akar := Line2D.new()
				akar.width = rng.randf_range(1.0, 2.2)
				akar.default_color = Art.HITAM
				akar.begin_cap_mode = Line2D.LINE_CAP_ROUND
				akar.end_cap_mode = Line2D.LINE_CAP_ROUND
				var x0 := x * T + rng.randf_range(1.0, 15.0)
				var top := float((y + 1) * T) - 1.0
				var len := rng.randf_range(4.0, 15.0)
				var sway := rng.randf_range(-3.0, 3.0)
				akar.add_point(Vector2(x0, top))
				akar.add_point(Vector2(x0 + sway * 0.6, top + len * 0.55))
				akar.add_point(Vector2(x0 + sway, top + len))
				akar.width_curve = _taper()
				akar.z_index = -1
				add_child(akar)


var _taper_curve: Curve = null


func _taper() -> Curve:
	if _taper_curve == null:
		_taper_curve = Curve.new()
		_taper_curve.add_point(Vector2(0.0, 1.0))
		_taper_curve.add_point(Vector2(1.0, 0.25))
	return _taper_curve


func _build_objects() -> void:
	var spawn := Vector2(T * 3, T * 4)
	var gate_cols := {}
	var wind_rect := Rect2()
	var has_wind := false
	for y in H:
		for x in W:
			var ch := cell(x, y)
			var feet := _feet(x, y)
			match ch:
				"P":
					spawn = feet
				"K":
					var k := Pathok.new()
					k.position = feet
					add_child(k)
					_pathok.append(k)
				"S", "F":
					var s := Sesaji.new()
					s.final = ch == "F"
					s.position = feet
					s.z_index = 1
					add_child(s)
					_sesaji.append(s)
				"G", "g":
					if not gate_cols.has(x):
						gate_cols[x] = [y, y, ch]
					else:
						gate_cols[x][0] = mini(gate_cols[x][0], y)
						gate_cols[x][1] = maxi(gate_cols[x][1], y)
				"R":
					_prajurit = Prajurit.new()
					_prajurit.position = feet
					add_child(_prajurit)
				"E":
					_exit_x = x * T
				"^", "X":
					if cell(x - 1, y) != ch:
						_make_duri(x, y, ch)
				"~":
					if cell(x - 1, y) != "~":
						_make_papan(x, y)
				"W":
					var r := Rect2(x * T, y * T, T, T)
					if has_wind:
						wind_rect = wind_rect.merge(r)
					else:
						wind_rect = r
						has_wind = true
				"a":
					var trap := PanahTrap.new()
					trap.arah = int(def["panah_arah"])
					trap.level = self
					trap.position = feet
					add_child(trap)
				"z", "b":
					var bu := Buta.new()
					bu.level = self
					bu.start_sleeping = ch == "z"
					bu.position = feet
					bu.z_index = 1
					add_child(bu)
				"D":
					_make_dahan(x, y)
				"C":
					_chase_x = x * T
				"c":
					_chase_end_x = x * T
				"k", "j":
					var ki := Kirata.new()
					ki.level = self
					if ch == "j":
						ki.jangkau = 360.0
					ki.position = feet
					ki.z_index = 1
					add_child(ki)
				"H":
					_harta = Harta.new()
					_harta.position = feet
					_harta.z_index = 1
					add_child(_harta)
				"p":
					spawn_barang("pelita", feet)
				"s":
					spawn_barang("selendang", feet)
				"e":
					spawn_barang("emas", feet)
				"t":
					spawn_barang("tameng", feet)
				"o":
					spawn_barang("terompah", feet)
				"m":
					spawn_barang("mahkota", feet)
				"J":
					_make_joglo(feet)
				"T":
					_make_tree("treeDead", feet, 120.0)
				"Y":
					_make_tree("tree", feet, 110.0)
	for gx in gate_cols:
		var info: Array = gate_cols[gx]
		var g := Gerbang.new()
		g.cells = int(info[1]) - int(info[0]) + 1
		g.jenis = "keraton" if str(info[2]) == "g" else "sesaji"
		g.position = Vector2(int(gx) * T + T / 2.0, (int(info[1]) + 1) * T)
		add_child(g)
		if g.jenis == "keraton":
			_keraton_gates.append(g)
		else:
			_gates.append(g)
	if has_wind:
		_make_wind(wind_rect)
	if _chase_x >= 0.0:
		_celeng = Celeng.new()
		_celeng.level = self
		_celeng.z_index = 2
		add_child(_celeng)
		_celeng.reset_state()

	player = Arjuna.new()
	player.level = self
	player.position = spawn
	player.z_index = 2
	add_child(player)
	player.mati.connect(_on_player_died)


func _make_duri(x0: int, y: int, ch: String) -> void:
	var n := 0
	while cell(x0 + n, y) == ch:
		n += 1
	var area := Area2D.new()
	area.add_to_group("duri")
	area.set_meta("kecil", ch == "^")
	area.collision_layer = 4
	area.collision_mask = 0
	area.monitoring = false
	var cs := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	var h := 6.0 if ch == "^" else 12.0
	r.size = Vector2(n * T - 4.0, h)
	cs.shape = r
	cs.position = Vector2(n * T / 2.0, (y + 1) * T - h / 2.0)
	cs.position.x += x0 * T
	area.add_child(cs)
	add_child(area)
	var poly := Polygon2D.new()
	var pts := PackedVector2Array()
	var spike_w := 4.0 if ch == "^" else 8.0
	var count := int(n * T / spike_w)
	var base_y := (y + 1) * T
	pts.append(Vector2(x0 * T, base_y))
	for i in count:
		var sx := x0 * T + i * spike_w
		pts.append(Vector2(sx + spike_w / 2.0, base_y - h - (i % 2) * 2.0))
		pts.append(Vector2(sx + spike_w, base_y))
	poly.polygon = pts
	poly.color = Art.HITAM
	poly.z_index = 1
	add_child(poly)


func _make_papan(x0: int, y: int) -> void:
	var n := 0
	while cell(x0 + n, y) == "~":
		n += 1
	var p := Papan.new()
	p.cells = n
	p.position = Vector2(x0 * T, y * T)
	add_child(p)


func _make_dahan(x: int, y: int) -> void:
	var anchor := Vector2(x * T - 7.0, (y + 1) * T)
	var gy := y + 1
	while gy < H and cell(x - 1, gy) != "#":
		gy += 1
	var rope_len := gy * T - anchor.y - 2.0
	_dahan.append({"pos": anchor, "len": rope_len, "sisi": 1})
	var branch := Line2D.new()
	branch.width = 3.0
	branch.default_color = Art.HITAM
	branch.points = PackedVector2Array([anchor + Vector2(10, 2), anchor + Vector2(-2, -3), anchor + Vector2(-14, -10)])
	branch.z_index = 1
	add_child(branch)
	var twig := Line2D.new()
	twig.width = 1.5
	twig.default_color = Art.HITAM
	twig.points = PackedVector2Array([anchor + Vector2(-6, -6), anchor + Vector2(-9, -16)])
	twig.z_index = 1
	add_child(twig)


func _make_wind(r: Rect2) -> void:
	var area := Area2D.new()
	area.add_to_group("angin")
	area.collision_layer = 8
	area.collision_mask = 0
	area.monitoring = false
	var cs := CollisionShape2D.new()
	var rs := RectangleShape2D.new()
	rs.size = r.size
	cs.shape = rs
	cs.position = r.get_center()
	area.add_child(cs)
	add_child(area)
	var dir := float(int(def["angin"]))
	var fx := CPUParticles2D.new()
	fx.texture = Art.SMOKE_TEX
	fx.amount = 40
	fx.lifetime = 1.6
	fx.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	fx.emission_rect_extents = Vector2(8, r.size.y / 2.0)
	fx.position = Vector2(r.position.x if dir > 0.0 else r.end.x, r.get_center().y)
	fx.direction = Vector2(dir, -0.1)
	fx.spread = 8.0
	fx.gravity = Vector2(0, 10)
	fx.initial_velocity_min = 160.0
	fx.initial_velocity_max = 240.0
	fx.scale_amount_min = 0.01
	fx.scale_amount_max = 0.025
	fx.color = Color(Art.HITAM, 0.45)
	fx.emitting = false
	fx.z_index = 3
	add_child(fx)
	_wind_fx.append(fx)


func _make_joglo(feet: Vector2) -> void:
	var holder := Node2D.new()
	holder.position = feet
	holder.z_index = -2
	add_child(holder)
	_dekor.append([holder, Rect2(feet + Vector2(-66, -82), Vector2(132, 82))])
	var col := Color(Art.HITAM, 0.5)
	var parts := [
		PackedVector2Array([Vector2(-66, -38), Vector2(66, -38), Vector2(46, -54), Vector2(-46, -54)]),
		PackedVector2Array([Vector2(-32, -54), Vector2(32, -54), Vector2(14, -78), Vector2(-14, -78)]),
	]
	for pts in parts:
		var poly := Polygon2D.new()
		poly.polygon = pts
		poly.color = col
		holder.add_child(poly)
	for px in [-44.0, -16.0, 14.0, 42.0]:
		var pillar := Art.rect(Vector2(3, 38), col)
		pillar.position = Vector2(px, -38)
		holder.add_child(pillar)
	var ridge := Art.rect(Vector2(30, 3), col)
	ridge.position = Vector2(-15, -80)
	holder.add_child(ridge)
	var floor_r := Art.rect(Vector2(110, 4), col)
	floor_r.position = Vector2(-55, -4)
	holder.add_child(floor_r)


func _make_tree(file_name: String, feet: Vector2, height: float) -> void:
	var t := Art.tex("res://assets/bg/%s.png" % file_name)
	if t == null:
		return
	var s := Sprite2D.new()
	s.texture = t
	var k := height / float(t.get_height())
	s.scale = Vector2(k, k)
	s.position = feet + Vector2(0, -height / 2.0 + 4.0)
	s.material = Art.siluet_material(Color(Art.HITAM, 0.55), 1.0)
	s.z_index = -2
	add_child(s)
	var w := float(t.get_width()) * k * 0.7
	_dekor.append([s, Rect2(s.position - Vector2(w / 2.0, height / 2.0), Vector2(w, height))])


func _build_camera() -> void:
	_camera = Camera2D.new()
	_camera.limit_left = 0
	_camera.limit_top = 0
	_camera.limit_right = W * T
	_camera.limit_bottom = H * T
	_camera.position_smoothing_enabled = true
	_camera.position_smoothing_speed = 5.0
	add_child(_camera)
	_camera.position = player.position + Vector2(0, -50)
	_camera.make_current()
	_camera.reset_smoothing()
	_camera.force_update_scroll()


func _cam_top_left() -> Vector2:
	var view := get_viewport_rect().size
	var c := _camera.get_screen_center_position()
	return c - view / (2.0 * _camera.zoom.x)


## Latar berlapis: bayangan yang makin pucat dan kabur makin jauh dari kelir.
func _build_parallax() -> void:
	var view := get_viewport_rect().size
	var theme := str(def["latar"])
	var rng := RandomNumberGenerator.new()
	rng.seed = 77 + Game.babak
	var tl := _cam_top_left()
	_layer_ref_y = tl.y
	var far_strip := "hills"
	var mid_pool: Array = ["tree", "treeDead"]
	var mid_rot := 0.0
	var mid_gap := Vector2(70, 160)
	match theme:
		"keraton":
			far_strip = "hills"
			mid_pool = ["treeLong", "tree", "bush1", "bush2", "fence", "treeLong"]
		"hutan":
			far_strip = "hillsLarge"
			mid_pool = ["treePine", "treeDead", "treeLong", "treePine", "treeDead"]
			mid_gap = Vector2(45, 110)
		"badai":
			far_strip = "hills"
			mid_pool = ["treeDead", "treeDead", "bush3", "treeLong"]
			mid_rot = 0.16
		"lereng":
			far_strip = "mountains"
			mid_pool = ["tree", "treeDead", "bush2", "treePine"]
		"gunung":
			far_strip = "mountains"
			mid_pool = ["treePine", "bush4", "treeDead"]
			mid_gap = Vector2(110, 220)
	# Lapisan jauh.
	var far := _new_layer(0.12, -40)
	var far_mat := Art.siluet_material(Color(Art.HITAM, 0.22), 2.5)
	var strip := Art.tex("res://assets/bg/%s.png" % far_strip)
	var span_far := (W * T - view.x) * 0.12 + view.x + 400.0
	if strip:
		var sh := 170.0
		var k := sh / float(strip.get_height())
		var sw := strip.get_width() * k
		var x := -200.0
		while x < span_far:
			var s := Sprite2D.new()
			s.texture = strip
			s.scale = Vector2(k, k)
			s.position = Vector2(x + sw / 2.0, 300.0 + _layer_ref_y * 0.12 - sh / 2.0)
			s.material = far_mat
			far.add_child(s)
			x += sw - 2.0
	if theme == "gunung":
		for i in 3:
			var mt := Art.tex("res://assets/bg/mountain%s.png" % ["A", "B", "C"][i])
			if mt:
				var ms := Sprite2D.new()
				ms.texture = mt
				var mh := rng.randf_range(200.0, 260.0)
				var mk := mh / float(mt.get_height())
				ms.scale = Vector2(mk, mk)
				ms.position = Vector2(120.0 + i * 260.0, 290.0 + _layer_ref_y * 0.12 - mh / 2.0)
				ms.material = far_mat
				far.add_child(ms)
	if theme == "hutan":
		var moon_t := Art.tex("res://assets/bg/moonFull.png")
		if moon_t:
			_moon = Sprite2D.new()
			_moon.texture = moon_t
			_moon.scale = Vector2(0.4, 0.4)
			_moon.position = Vector2(470.0, 80.0 + _layer_ref_y * 0.12)
			_moon.modulate = Color(Art.PAPER, 0.0)
			far.add_child(_moon)
	# Lapisan tengah.
	var mid := _new_layer(0.38, -30)
	var mid_mat := Art.siluet_material(Color(Art.HITAM, 0.45), 1.2)
	var span_mid := (W * T - view.x) * 0.38 + view.x + 300.0
	var mx := -100.0
	while mx < span_mid:
		var sprite_name: String = mid_pool[rng.randi() % mid_pool.size()]
		var tt := Art.tex("res://assets/bg/%s.png" % sprite_name)
		if tt:
			var s2 := Sprite2D.new()
			s2.texture = tt
			var th := rng.randf_range(110.0, 190.0)
			if sprite_name.begins_with("bush") or sprite_name == "fence":
				th = rng.randf_range(40.0, 70.0)
			var tk := th / float(tt.get_height())
			s2.scale = Vector2(tk * (1.0 if rng.randf() < 0.5 else -1.0), tk)
			s2.position = Vector2(mx, 336.0 + _layer_ref_y * 0.38 - th / 2.0)
			s2.rotation = mid_rot * rng.randf_range(0.5, 1.0)
			s2.material = mid_mat
			mid.add_child(s2)
		mx += rng.randf_range(mid_gap.x, mid_gap.y)
	# Goro-goro: panakawan menari di latar.
	if theme == "badai":
		var pt := Art.wayang("panakawan")
		if pt:
			var dmat := Art.siluet_material(Color(Art.HITAM, 0.5), 1.0)
			for i in 3:
				var d := Sprite2D.new()
				d.texture = pt
				var dh := 70.0
				var dk := dh / float(pt.get_height())
				d.scale = Vector2(dk, dk)
				d.position = Vector2(260.0 + i * 330.0, 330.0 + _layer_ref_y * 0.38 - dh / 2.0)
				d.material = dmat
				d.set_meta("y0", d.position.y)
				d.set_meta("ph", float(i) * 1.7)
				mid.add_child(d)
				_dancers.append(d)


func _update_dancers() -> void:
	if _dancers.is_empty():
		return
	var t := Time.get_ticks_msec() / 1000.0
	for d in _dancers:
		var ph: float = d.get_meta("ph", 0.0)
		var y0: float = d.get_meta("y0", d.position.y)
		d.position.y = y0 - absf(sin(t * 5.0 + ph)) * 6.0
		d.rotation = sin(t * 2.5 + ph) * 0.06


func _new_layer(s: float, z: int) -> Node2D:
	var n := Node2D.new()
	n.z_index = z
	add_child(n)
	_layers.append({"node": n, "s": s})
	return n


func _build_fog() -> void:
	_fog_holder = Node2D.new()
	_fog_holder.z_index = -20
	add_child(_fog_holder)
	var fog := ColorRect.new()
	fog.size = Vector2(760, 470)
	fog.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fog_mat = ShaderMaterial.new()
	_fog_mat.shader = Art.KABUT_SHADER
	var pal: Dictionary = Art.PATHET[str(def["pathet"])]
	var hot: Color = pal["hot"]
	var a := 0.07 if bool(def["gelap"]) else 0.2
	_fog_mat.set_shader_parameter("fog_color", Color(hot, a))
	_fog_mat.set_shader_parameter("rect_size", fog.size)
	_fog_mat.set_shader_parameter("drift", 14.0 if int(def["angin"]) != 0 else 6.0)
	fog.material = _fog_mat
	_fog_holder.add_child(fog)


func _build_post() -> void:
	var cl := CanvasLayer.new()
	cl.layer = 30
	add_child(cl)
	var r := ColorRect.new()
	r.set_anchors_preset(Control.PRESET_FULL_RECT)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_post_mat = ShaderMaterial.new()
	_post_mat.shader = Art.POST_SHADER
	_post_mat.set_shader_parameter("grain", 0.06 if bool(Game.settings["butiran"]) else 0.0)
	_post_mat.set_shader_parameter("vignette", 0.55)
	_post_mat.set_shader_parameter("darkness", 0.0)
	r.material = _post_mat
	cl.add_child(r)


func _build_ui() -> void:
	_ui = CanvasLayer.new()
	_ui.layer = 40
	add_child(_ui)
	_build_hud()
	var holder := CenterContainer.new()
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	Art.place(holder, Control.PRESET_CENTER_BOTTOM, Rect2(-320, -50, 640, 38))
	_ui.add_child(holder)
	var panel := PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(Art.HITAM, 0.72)
	sb.border_color = Color(Art.EMAS, 0.85)
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(6)
	sb.content_margin_left = 12.0
	sb.content_margin_right = 12.0
	sb.content_margin_top = 3.0
	sb.content_margin_bottom = 4.0
	panel.add_theme_stylebox_override("panel", sb)
	holder.add_child(panel)
	_prompt = Art.label("", 17, Art.PAPER)
	_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel.add_child(_prompt)
	_prompt_box = holder
	_prompt_box.modulate.a = 0.0
	# Tanda tombol di atas benda yang bisa dipakai.
	_tanda = Node2D.new()
	_tanda.z_index = 9
	_tanda.visible = false
	add_child(_tanda)
	var g := Art.glow(Art.EMAS, 34.0)
	_tanda.add_child(g)
	_tanda_label = Art.label("E", 13, Art.PAPER)
	_tanda_label.add_theme_color_override("font_outline_color", Art.HITAM)
	_tanda_label.add_theme_constant_override("outline_size", 5)
	_tanda_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_tanda_label.position = Vector2(-12, -10)
	_tanda_label.size = Vector2(24, 20)
	_tanda.add_child(_tanda_label)
	_end_label = Art.label("", 40, Art.PAPER)
	_end_sub = Art.label("", 20, Art.PAPER)
	_end_hint = Art.label("", 14, Art.TEXT_DIM)
	var y := 120.0
	for l in [_end_label, _end_sub, _end_hint]:
		var lab: Label = l
		lab.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lab.modulate.a = 0.0
		lab.add_theme_color_override("font_outline_color", Color(Art.HITAM, 0.6))
		lab.add_theme_constant_override("outline_size", 6)
		Art.place(lab, Control.PRESET_CENTER_TOP, Rect2(-300, y, 600, 50))
		_ui.add_child(lab)
		y += 50.0 if lab == _end_label else 34.0
	_build_objective()


## Tujuan babak di pojok kiri atas, dengan langkah yang berganti mengikuti posisi Arjuna.
func _build_objective() -> void:
	_obj_box = VBoxContainer.new()
	_obj_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_obj_box.add_theme_constant_override("separation", -2)
	Art.place(_obj_box, Control.PRESET_TOP_LEFT, Rect2(14, 8, 420, 60))
	_obj_box.modulate.a = 0.0
	_ui.add_child(_obj_box)
	var head := Art.ink_label("Tujuan: " + str(def.get("tujuan", "")), 15)
	_obj_step = Art.ink_label("", 13)
	for l in [head, _obj_step]:
		var lab: Label = l
		lab.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lab.custom_minimum_size = Vector2(420, 0)
		if bool(def["gelap"]):
			lab.add_theme_color_override("font_color", Art.PAPER)
			lab.add_theme_color_override("font_outline_color", Color(Art.HITAM, 0.7))
		_obj_box.add_child(lab)


func _update_objective(delta: float) -> void:
	if _obj_delay > 0.0:
		_obj_delay -= delta
		if _obj_delay <= 0.0:
			_obj_bright = 8.0
		return
	var tile := int(player.global_position.x / T)
	var steps: Array = def.get("langkah", [])
	var idx := _step_i
	for i in steps.size():
		var st: Array = steps[i]
		if tile >= int(st[0]) and i > idx:
			idx = i
	if idx != _step_i and idx >= 0:
		_step_i = idx
		var cur: Array = steps[idx]
		_obj_step.text = "  " + str(cur[1])
		_obj_bright = 4.0
		if _obj_box.modulate.a > 0.3:
			Sfx.play("kepyak", -16.0, 1.4)
	_obj_bright -= delta
	var target := 1.0 if _obj_bright > 0.0 else 0.55
	if ending_busy:
		target = 0.0
	_obj_box.modulate.a = move_toward(_obj_box.modulate.a, target, delta * 1.5)


func objective_text() -> String:
	var t := "Tujuan: " + str(def.get("tujuan", ""))
	if _obj_step and _obj_step.text.strip_edges() != "":
		t += "\n" + _obj_step.text.strip_edges()
	return t


func _show_petuah() -> void:
	var box := VBoxContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	Art.place(box, Control.PRESET_CENTER_TOP, Rect2(-300, 52, 600, 150))
	_ui.add_child(box)
	var head := Art.ink_label("Babak %d   %s" % [Game.babak + 1, str(def["nama"])], 15)
	var big := Art.ink_label(str(def["petuah"]), 40)
	var small := Art.ink_label(str(def["arti"]), 18)
	for l in [head, big, small]:
		var lab: Label = l
		lab.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		box.add_child(lab)
	if bool(def["gelap"]):
		for l in [head, big, small]:
			var lab2: Label = l
			lab2.add_theme_color_override("font_color", Art.PAPER)
			lab2.add_theme_color_override("font_outline_color", Color(Art.HITAM, 0.7))
	box.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(box, "modulate:a", 1.0, 1.2)
	tw.tween_interval(2.8)
	tw.tween_property(box, "modulate:a", 0.0, 1.5)
	tw.tween_callback(box.queue_free)


# --- jalan setiap frame -------------------------------------------------------

func _process(delta: float) -> void:
	if player == null:
		return
	if not ending_busy:
		var look := Vector2(float(player.facing) * 36.0, -50.0)
		_camera.position = player.global_position + look
	var tl := _cam_top_left()
	for layer in _layers:
		var n: Node2D = layer["node"]
		n.position = tl * (1.0 - float(layer["s"]))
	_fog_holder.position = tl - Vector2(60, 55)
	_fog_mat.set_shader_parameter("world_offset", _fog_holder.position)
	_update_kelir(tl, delta)
	_update_wind(delta)
	_update_prompt(delta)
	_update_objective(delta)
	_update_dancers()
	if ending_busy or player.dead:
		return
	_check_pathok()
	_check_gates(delta)
	_check_exit()
	_check_chase()


func _physics_process(_delta: float) -> void:
	if player == null or player.dead or ending_busy:
		return
	for a in player.zones():
		if a.is_in_group("duri"):
			if bool(a.get_meta("kecil", false)) and Bobot.punya("terompah"):
				continue
			# Tepat setelah bangkit, data tumpang-tindih masih dari tempat mati: jangan mati dua kali.
			if player.kebal():
				continue
			player.die("duri")
			return
	if player.is_on_floor():
		for i in player.get_slide_collision_count():
			var col := player.get_slide_collision(i).get_collider()
			if col is Papan:
				(col as Papan).stepped(Bobot.total())


func _update_kelir(tl: Vector2, delta: float) -> void:
	var view := get_viewport_rect().size
	var ls := lights()
	var want := 0.0
	if not ls.is_empty():
		var lp: Vector2 = ls[0]
		_kelir_mat.set_shader_parameter("spot_uv", (lp - tl) * _camera.zoom.x / view)
		want = 1.15 if bool(def["gelap"]) else 0.3
	_spot = move_toward(_spot, want, delta * 1.5)
	_kelir_mat.set_shader_parameter("spot_strength", _spot)
	_kelir_mat.set_shader_parameter("brightness", _bright)


func _update_wind(delta: float) -> void:
	if int(def["angin"]) == 0:
		return
	_wind_t -= delta
	if _wind_t <= 0.0:
		_wind_on = not _wind_on
		_wind_t = float(Game.pilih([2.6, GUST_ON, 1.9])) if _wind_on else float(Game.pilih([0.8, GUST_OFF, 1.2]))
		for fx in _wind_fx:
			fx.emitting = _wind_on
		if _wind_on:
			Sfx.play("angin", -6.0, 0.6)


func _update_prompt(delta: float) -> void:
	var px := player.global_position.x
	var text := ""
	var ctx := {}
	if not ending_busy and not player.dead:
		ctx = _konteks_aksi()
		if not ctx.is_empty():
			text = str(ctx["teks"])
		else:
			for p in _petunjuk:
				var arr: Array = p
				var x := float(arr[0]) * T + 8.0
				if absf(px - x) < 56.0:
					text = str(arr[1])
	if text != "":
		_prompt.text = text
	var target := 1.0 if text != "" else 0.0
	_prompt_box.modulate.a = move_toward(_prompt_box.modulate.a, target, delta * 4.0)
	# Tanda tombol melayang di atas benda, kamera mendekat sedikit.
	var tombol := str(ctx.get("tombol", ""))
	_tanda_t += delta
	if tombol != "":
		_tanda.visible = true
		_tanda_label.text = tombol
		_tanda.global_position = (ctx["pos"] as Vector2) + Vector2(0, sin(_tanda_t * 5.0) * 2.5)
		_tanda.scale = Vector2.ONE * (1.0 + 0.08 * sin(_tanda_t * 9.0))
	else:
		_tanda.visible = false
	_fade_dekor(delta)
	var zt := 1.14 if tombol != "" else 1.0
	_zoom = move_toward(_zoom, zt, delta * 0.5)
	_camera.zoom = Vector2.ONE * _zoom


func _fade_dekor(delta: float) -> void:
	var c := player.center()
	for d in _dekor:
		var n := d[0] as CanvasItem
		if n == null or not is_instance_valid(n):
			continue
		var target := 0.4 if (d[1] as Rect2).has_point(c) else 1.0
		n.modulate.a = move_toward(n.modulate.a, target, delta * 3.0)


## Panel Bobot di pojok kanan atas: apa yang dibawa dan apa akibatnya.
func _build_hud() -> void:
	var panel := PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(Art.HITAM, 0.6)
	sb.border_color = Color(Art.EMAS, 0.6)
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(5)
	sb.content_margin_left = 8.0
	sb.content_margin_right = 8.0
	sb.content_margin_top = 3.0
	sb.content_margin_bottom = 4.0
	panel.add_theme_stylebox_override("panel", sb)
	Art.place(panel, Control.PRESET_TOP_RIGHT, Rect2(-180, 8, 172, 50))
	_ui.add_child(panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 0)
	panel.add_child(v)
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 6)
	v.add_child(top)
	_hud_bobot = Art.label("Bobot 0", 15, Art.EMAS_TERANG)
	top.add_child(_hud_bobot)
	_hud_icons = HBoxContainer.new()
	_hud_icons.add_theme_constant_override("separation", 2)
	_hud_icons.alignment = BoxContainer.ALIGNMENT_END
	_hud_icons.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(_hud_icons)
	_hud_efek = Art.label("", 11, Art.PAPER)
	v.add_child(_hud_efek)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 2)
	v.add_child(row)
	var ln := Art.label("Nyawa", 11, Art.PAPER)
	row.add_child(ln)
	_hud_nyawa = HBoxContainer.new()
	_hud_nyawa.add_theme_constant_override("separation", 1)
	row.add_child(_hud_nyawa)
	var lk := Art.label(Game.nama_kesulitan(), 11, Art.EMAS_TERANG)
	lk.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lk.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(lk)
	_update_nyawa()
	Bobot.berubah.connect(_on_bobot_hud)
	_on_bobot_hud(Bobot.total(), false)


## Ikon blencong: menyala untuk nyawa tersisa, redup untuk yang sudah hilang.
func _update_nyawa() -> void:
	if _hud_nyawa == null or not is_instance_valid(_hud_nyawa):
		return
	for c in _hud_nyawa.get_children():
		c.queue_free()
	for i in Game.nyawa_penuh():
		var t := TextureRect.new()
		t.texture = Bobot.icon("pelita")
		t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		t.custom_minimum_size = Vector2(11, 11)
		t.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		t.modulate = Art.EMAS if i < Game.nyawa else Color(1, 1, 1, 0.22)
		_hud_nyawa.add_child(t)


func _on_bobot_hud(total: int, kilat := true) -> void:
	if _hud_bobot == null or not is_instance_valid(_hud_bobot):
		return
	_hud_bobot.text = "Bobot %d" % total
	for c in _hud_icons.get_children():
		c.queue_free()
	for id in Bobot.bawaan:
		var t := TextureRect.new()
		t.texture = Bobot.icon(id)
		t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		t.custom_minimum_size = Vector2(14, 14)
		t.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		t.modulate = Art.EMAS if Bobot.berwarna(id) else Art.PAPER
		_hud_icons.add_child(t)
	var suara := Bobot.suara()
	var keras := "pelan" if suara <= 40.0 else ("sedang" if suara <= 80.0 else "keras")
	var bayang: String = ["tipis", "sedang", "besar"][Bobot.tingkat()]
	_hud_efek.text = "Lompat %d%%  Langkah %d%%\nSuara %s  Bayangan %s" % [roundi(Bobot.lompat_mult() * 100.0), roundi(Bobot.lari_mult() * 100.0), keras, bayang]
	if kilat:
		_hud_bobot.modulate = Color(1.8, 1.5, 1.0)
		create_tween().tween_property(_hud_bobot, "modulate", Color.WHITE, 0.6)


## Aksi yang bisa dilakukan saat ini, untuk petunjuk dan tanda tombol.
func _konteks_aksi() -> Dictionary:
	if player.climbing:
		return {"teks": "W / S  panjat naik turun      Spasi  lepas tali"}
	var s := _near_sesaji()
	if s:
		var terima: Array = def["terima"]
		if s.final:
			terima = Bobot.DATA.keys()
		for id in Bobot.salin():
			if terima.has(id):
				var apa := "semua bawaan" if s.final else Bobot.nama(id)
				return {"teks": "Q  persembahkan %s di sesaji" % apa, "tombol": "Q", "pos": s.global_position + Vector2(0, -54)}
	var d := _near_dahan()
	if not d.is_empty() and Bobot.atas() == "selendang":
		return {"teks": "Q  ikat selendang di dahan", "tombol": "Q", "pos": (d["pos"] as Vector2) + Vector2(0, -20)}
	if _harta and _harta.visible and player.global_position.distance_to(_harta.global_position) < 30.0:
		return {"teks": "E  ambil harta  (godaan terakhir)", "tombol": "E", "pos": _harta.global_position + Vector2(0, -48)}
	var best: Barang = null
	var best_d := 34.0
	for b in get_tree().get_nodes_in_group("barang"):
		var item := b as Barang
		if item == null or item.tied:
			continue
		var dd := Vector2(absf(item.global_position.x - player.global_position.x), absf(item.global_position.y - player.global_position.y) * 0.6).length()
		if dd < best_d:
			best_d = dd
			best = item
	if best:
		var w := int(Bobot.DATA[best.id]["bobot"])
		return {"teks": "E  ambil %s  (+%d Bobot)" % [Bobot.nama(best.id), w], "tombol": "E", "pos": best.global_position + Vector2(0, -22)}
	for a in player.zones():
		if a.is_in_group("tali"):
			return {"teks": "W  panjat tali", "tombol": "W", "pos": player.center() + Vector2(0, -34)}
	return {}


func _check_pathok() -> void:
	if not player.is_on_floor():
		return
	for k in _pathok:
		if k.active:
			continue
		if absf(player.global_position.x - k.global_position.x) < 14.0 and absf(player.global_position.y - k.global_position.y) < 30.0:
			k.activate()
			_take_snapshot(k.global_position)


func _check_gates(delta: float) -> void:
	if _prajurit and not _prajurit.bowed:
		var d := player.global_position.distance_to(_prajurit.global_position)
		if d < 72.0:
			if Bobot.punya("mahkota"):
				_prajurit.bow()
				for g in _keraton_gates:
					g.open()
			else:
				_refuse_t -= delta
				if _refuse_t <= 0.0:
					_prajurit.refuse()
					_refuse_t = 2.0
	if _gates.is_empty():
		return
	var ok := true
	for id in def["syarat"]:
		if Bobot.punya(str(id)):
			ok = false
	if not ok:
		return
	for g in _gates:
		if not g.is_open and absf(player.global_position.x - g.global_position.x) < 160.0:
			g.open()
			if bool(def["gelap"]) and not _dark_adapted:
				_adapt_dark()


func _check_exit() -> void:
	if _finished or _exit_x < 0.0:
		return
	if player.global_position.x >= _exit_x:
		_finished = true
		ending_busy = true
		player.frozen = true
		Game.complete_babak()


func _check_chase() -> void:
	if _celeng == null:
		return
	if not _chase_started and player.global_position.x > _chase_x:
		_chase_started = true
		_celeng.start_chase(Vector2(player.global_position.x - 300.0, player.global_position.y - 20.0))
		Music.play("kejar")
	elif _chase_started and not _chase_done and _chase_end_x > 0.0 and player.global_position.x > _chase_end_x:
		_chase_done = true
		_celeng.stop_chase()
		Music.play(str(def["musik"]))


# --- layanan untuk benda lain --------------------------------------------------

## Sumber cahaya: Arjuna yang membawa pelita, dan pelita yang tergeletak.
func lights() -> Array:
	var out: Array = []
	if player and not player.dead and Bobot.punya("pelita"):
		out.append(player.center())
	for b in get_tree().get_nodes_in_group("cahaya"):
		var item := b as Barang
		if item and item.is_light():
			out.append(item.global_position + Vector2(0, -8))
	return out


## Jarak pandang buta, bergantung pada besar bayangan dan cahaya.
func vision_range() -> float:
	var v: float = VISION[player.tier()]
	if Bobot.punya("pelita"):
		v *= 2.0
	elif bool(def["gelap"]) and not _dark_adapted:
		v *= 0.67
	return v


func wind_force() -> float:
	if not _wind_on:
		return 0.0
	return WIND * float(int(def["angin"]))


func noise(pos: Vector2, radius: float) -> void:
	for b in get_tree().get_nodes_in_group("buta"):
		(b as Buta).hear(pos, radius)
	if radius >= 120.0:
		_noise_ring(pos, radius)


func _noise_ring(pos: Vector2, radius: float) -> void:
	var ring := Line2D.new()
	ring.width = 1.0
	ring.default_color = Color(Art.HITAM, 0.25)
	var pts := PackedVector2Array()
	for i in 33:
		var a := TAU * float(i) / 32.0
		pts.append(Vector2(cos(a), sin(a)) * radius)
	ring.points = pts
	ring.position = pos + Vector2(0, -6)
	ring.scale = Vector2(0.2, 0.2)
	ring.z_index = 4
	add_child(ring)
	var tw := ring.create_tween().set_parallel()
	tw.tween_property(ring, "scale", Vector2.ONE, 0.6).set_ease(Tween.EASE_OUT)
	tw.tween_property(ring, "modulate:a", 0.0, 0.6)
	tw.chain().tween_callback(ring.queue_free)


func item_landed(item: Node2D) -> void:
	if _celeng:
		_celeng.on_item(item)


func spawn_barang(id: String, pos: Vector2, tied := false, rope_len := 0.0, sisi := 1) -> Barang:
	var b := Barang.new()
	b.setup(id, self)
	b.position = pos
	b.z_index = 1
	if tied:
		b.tied = true
		b.set_meta("len", rope_len)
		b.set_meta("sisi", sisi)
	add_child(b)
	return b


func _point_solid(p: Vector2) -> bool:
	var q := PhysicsPointQueryParameters2D.new()
	q.position = p
	q.collision_mask = 1
	return not get_world_2d().direct_space_state.intersect_point(q, 1).is_empty()


# --- ambil dan lepas ----------------------------------------------------------

func try_aksi() -> void:
	if ending_busy or player == null or player.dead:
		return
	if _harta and _harta.visible and player.global_position.distance_to(_harta.global_position) < 30.0:
		_kelir_peteng()
		return
	var best: Barang = null
	var best_d := 34.0
	for b in get_tree().get_nodes_in_group("barang"):
		var item := b as Barang
		if item == null or item.tied:
			continue
		var dx := absf(item.global_position.x - player.global_position.x)
		var dy := absf(item.global_position.y - player.global_position.y)
		var d := Vector2(dx, dy * 0.6).length()
		if d < best_d:
			best_d = d
			best = item
	if best == null:
		return
	Bobot.ambil(best.id)
	_item_fx(best.global_position + Vector2(0, -4), best.id, true)
	if Bobot.berwarna(best.id):
		Sfx.play("emas", -4.0, 1.3)
	else:
		Sfx.play("ambil", -6.0)
	best.remove_from_group("barang")
	best.remove_from_group("cahaya")
	best.queue_free()


func try_lepas() -> void:
	if ending_busy or player == null or player.dead:
		return
	var s := _near_sesaji()
	if s:
		if s.final:
			_offer(s)
			if Bobot.kosong():
				_tancep_kayon()
			return
		if _offer(s):
			return
	var top := Bobot.atas()
	if top == "":
		return
	if top == "selendang":
		var d := _near_dahan()
		if not d.is_empty():
			_tie(d)
			return
	var id := Bobot.lepas_atas()
	_drop(id)


func _near_sesaji() -> Sesaji:
	for s in _sesaji:
		if absf(player.global_position.x - s.global_position.x) < 30.0 and absf(player.global_position.y - s.global_position.y) < 40.0:
			return s
	return null


func _near_dahan() -> Dictionary:
	for d in _dahan:
		var info: Dictionary = d
		var pos: Vector2 = info["pos"]
		if absf(player.global_position.x - pos.x) < 48.0 and player.global_position.y > pos.y + 10.0:
			return info
	return {}


func _offer(s: Sesaji) -> bool:
	var terima: Array = def["terima"]
	if s.final:
		terima = Bobot.DATA.keys()
	var removed := 0
	for id in Bobot.salin():
		if terima.has(id):
			Bobot.hapus(id)
			removed += 1
	if removed == 0:
		return false
	s.flash()
	Sfx.play("gong", -2.0)
	Sfx.play("sesaji", -8.0)
	_take_snapshot(player.global_position)
	if bool(def["gelap"]) and not _dark_adapted and not Bobot.punya("pelita"):
		_adapt_dark()
	return true


func _tie(d: Dictionary) -> void:
	Bobot.lepas_atas()
	var b := spawn_barang("selendang", d["pos"], true, float(d["len"]), int(d["sisi"]))
	Sfx.play("tali", -2.0)
	Sfx.play("keprak", -10.0)
	Art.burst(self, b.global_position + Vector2(0, 6), Art.HITAM, 8, Art.SMOKE_TEX, 30.0)


func _drop(id: String) -> void:
	var feet := player.global_position
	var b: Barang
	if absf(player.move_vx) > 30.0 or not player.is_on_floor():
		var from := player.center() + Vector2(8.0 * float(player.facing), 0)
		if _point_solid(from + Vector2(0, -4)):
			from = player.center()
		b = spawn_barang(id, from)
		b.velocity = Vector2(140.0 * float(player.facing) + player.move_vx * 0.3, -160.0)
		Sfx.play("lempar", -6.0)
	else:
		var pos := feet + Vector2(12.0 * float(player.facing), -1.0)
		if _point_solid(pos + Vector2(0, -6)):
			pos = feet + Vector2(0, -1)
		b = spawn_barang(id, pos)
		Sfx.play("lepas", -6.0)
	b.thrown = true
	b.dari_pemain = true
	Sfx.play("keprak", -14.0, 1.3)
	_item_fx(b.global_position, id, false)


## Kilau saat barang diambil (cahaya menyusut ke tubuh Arjuna) atau dilepas (cahaya memancar).
func _item_fx(pos: Vector2, id: String, ambil: bool) -> void:
	var col: Color = Art.EMAS if Bobot.berwarna(id) else Art.EMAS_TERANG
	var target := player.center() if ambil else pos
	var g := Art.glow(col, 70.0 if ambil else 90.0)
	g.global_position = pos
	g.z_index = 6
	add_child(g)
	var base := g.scale
	g.scale = base * (1.4 if ambil else 0.3)
	var tw := g.create_tween().set_parallel(true)
	tw.tween_property(g, "global_position", target, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_property(g, "scale", base * (0.4 if ambil else 1.3), 0.45)
	tw.tween_property(g, "modulate:a", 0.0, 0.55).set_delay(0.1)
	tw.chain().tween_callback(g.queue_free)
	var ring := Line2D.new()
	ring.width = 1.6
	ring.default_color = Color(col, 0.9)
	ring.z_index = 6
	var pts := PackedVector2Array()
	for i in 29:
		var a := TAU * float(i) / 28.0
		pts.append(Vector2(cos(a), sin(a)) * 10.0)
	ring.points = pts
	ring.global_position = target
	add_child(ring)
	ring.scale = Vector2.ONE * (3.0 if ambil else 0.5)
	var tr := ring.create_tween().set_parallel(true)
	tr.tween_property(ring, "scale", Vector2.ONE * (0.3 if ambil else 3.2), 0.4).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tr.tween_property(ring, "modulate:a", 0.0, 0.45)
	tr.chain().tween_callback(ring.queue_free)
	Art.burst(self, pos, col, 10 if ambil else 16, Art.SPARK_TEX, 45.0 if ambil else 70.0)
	var w: int = int(Bobot.DATA[id]["bobot"])
	var tag := Art.ink_label(("+" if ambil else "-") + str(w) + " Bobot", 12)
	tag.z_index = 7
	tag.position = player.center() + Vector2(-22, -34)
	add_child(tag)
	var tt := tag.create_tween().set_parallel(true)
	tt.tween_property(tag, "position:y", tag.position.y - 18.0, 0.9)
	tt.tween_property(tag, "modulate:a", 0.0, 0.9).set_delay(0.3)
	tt.chain().tween_callback(tag.queue_free)


func _adapt_dark() -> void:
	_dark_adapted = true
	_bright = 0.0
	var tw := create_tween()
	tw.tween_interval(0.8)
	tw.tween_method(_set_bright, 0.0, 0.62, 3.0)
	if _moon:
		tw.parallel().tween_property(_moon, "modulate:a", 0.8, 3.0)


func _set_bright(v: float) -> void:
	_bright = v


func _set_flash(v: float) -> void:
	_kelir_mat.set_shader_parameter("flash", v)


func _set_darkness(v: float) -> void:
	_post_mat.set_shader_parameter("darkness", v)


func _blend_palette(t: float) -> void:
	for key in ["hot", "mid", "edge"]:
		var a: Color = _pal_from[key]
		var b: Color = _pal_to[key]
		_kelir_mat.set_shader_parameter(key, a.lerp(b, t))


# --- pathok, mati, bangkit ----------------------------------------------------

func _take_snapshot(pos: Vector2) -> void:
	var items: Array = []
	for b in get_tree().get_nodes_in_group("barang"):
		var item := b as Barang
		if item and not item.is_queued_for_deletion():
			items.append(item.snapshot())
	_snapshot = {"pos": pos, "bawaan": Bobot.salin(), "barang": items}


func _on_player_died(_sebab: String) -> void:
	Game.stats["mati"] = int(Game.stats["mati"]) + 1
	Game.nyawa -= 1
	_update_nyawa()
	Sfx.play("gong", -6.0, 0.9)
	var tw := create_tween()
	tw.tween_method(_set_flash, 0.5, 0.0, 0.6)
	await get_tree().create_timer(0.55).timeout
	if Game.nyawa <= 0:
		await _blencong_padam()
		return
	await Game.wipe(_restore, 0.7)


## Nyawa habis: blencong padam, babak diulang dari awal.
func _blencong_padam() -> void:
	ending_busy = true
	Sfx.play("gong", -2.0, 0.7)
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.modulate.a = 0.0
	Art.place(box, Control.PRESET_CENTER, Rect2(-280, -50, 560, 100))
	_ui.add_child(box)
	var l1 := Art.label("Blencong padam.", 30, Art.PAPER)
	l1.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(l1)
	var pesan := "Pati Geni gagal. Lakon diulang dari Jejer Amarta." if Game.pati_geni() else "Nyawa habis. Lakon diulang dari awal babak."
	var l2 := Art.label(pesan, 16, Art.EMAS_TERANG)
	l2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(l2)
	var tw := create_tween().set_parallel()
	tw.tween_property(box, "modulate:a", 1.0, 0.6)
	tw.tween_method(_set_bright, _bright, 0.15, 1.2)
	await get_tree().create_timer(2.4).timeout
	Game.ulang_babak()


func _restore() -> void:
	for b in get_tree().get_nodes_in_group("barang"):
		var n := b as Node
		n.remove_from_group("barang")
		n.remove_from_group("cahaya")
		n.queue_free()
	for p in get_tree().get_nodes_in_group("panah"):
		(p as Node).queue_free()
	for d in _snapshot["barang"]:
		var info: Dictionary = d
		var rb := spawn_barang(str(info["id"]), info["pos"], bool(info["tied"]), float(info["len"]), int(info["sisi"]))
		rb.dari_pemain = bool(info.get("dari_pemain", false))
	Bobot.setel(_snapshot["bawaan"])
	for r in get_tree().get_nodes_in_group("reset"):
		r.call("reset_state")
	var pos: Vector2 = _snapshot["pos"]
	player.respawn(pos)
	_camera.position = pos + Vector2(float(player.facing) * 36.0, -50.0)
	_camera.reset_smoothing()
	if _celeng and _chase_started and not _chase_done:
		if pos.x > _chase_x:
			get_tree().create_timer(1.0).timeout.connect(_restart_chase)
		else:
			_chase_started = false
			Music.play(str(def["musik"]))


func _restart_chase() -> void:
	if _chase_done or player == null or player.dead:
		return
	_celeng.start_chase(player.global_position + Vector2(-280.0, -20.0))


# --- ending -------------------------------------------------------------------

## Tancep Kayon: Arjuna duduk bertapa dengan tangan kosong, anugerah turun, gunungan ditancapkan.
func _tancep_kayon() -> void:
	ending_busy = true
	player.frozen = true
	var kantong := not Bobot.emas_pernah
	Music.fade_out(2.5)
	Sfx.play("gong", 0.0, 0.85)
	_pal_from = Art.PATHET[str(def["pathet"])]
	_pal_to = Art.PATHET["fajar"]
	var tw := create_tween().set_parallel()
	tw.tween_method(_set_bright, _bright, 1.3, 4.0)
	tw.tween_method(_blend_palette, 0.0, 1.0, 4.0)
	var beam := Art.glow(Color(1.0, 0.97, 0.85), 10.0)
	beam.scale = Vector2(70.0 / float(Art.LIGHT_TEX.get_width()), 420.0 / float(Art.LIGHT_TEX.get_height()))
	beam.position = player.global_position + Vector2(0, -170)
	beam.modulate.a = 0.0
	beam.z_index = 5
	add_child(beam)
	create_tween().tween_property(beam, "modulate:a", 0.9, 2.5)
	await get_tree().create_timer(1.6).timeout
	Art.burst(self, player.center(), Color(1.0, 0.96, 0.8), 30, Art.SPARK_TEX, 50.0)
	if Art.is_wayang("arjuna_tapa"):
		# Arjuna duduk bertapa: wayang Arjuna Bertapa koleksi Yale menggantikan wayang berjalan.
		var tapa := Art.figure("arjuna_tapa", Vector2i(29, 0), 72.0)
		Art.warnai(tapa)
		tapa.position += player.global_position + Vector2(0, 2)
		tapa.modulate.a = 0.0
		tapa.z_index = 3
		add_child(tapa)
		var swap := create_tween().set_parallel()
		swap.tween_property(tapa, "modulate:a", 1.0, 1.5)
		swap.tween_property(player, "modulate:a", 0.0, 1.2)
	await get_tree().create_timer(1.2).timeout
	var center_x := _camera.get_screen_center_position().x
	var g := Art.gunungan(170.0)
	Art.warnai(g)
	g.z_index = 6
	var target := Vector2(center_x + 90.0, player.global_position.y + 8.0)
	g.position = target + Vector2(0, -320)
	add_child(g)
	var drop := create_tween()
	drop.tween_property(g, "position", target, 1.6).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	await drop.finished
	Sfx.play("keprak", 0.0)
	Sfx.play("gong", 0.0, 0.7)
	_end_label.add_theme_color_override("font_color", Art.TEXT_INK)
	_end_label.add_theme_color_override("font_outline_color", Color(Art.PAPER, 0.8))
	_end_sub.add_theme_color_override("font_color", Art.TEXT_INK)
	_end_sub.add_theme_color_override("font_outline_color", Color(Art.PAPER, 0.8))
	_end_label.text = "Sugih tanpa bandha."
	_end_sub.text = "Kantong Bolong" if kantong else "Tancep kayon."
	var reveal := create_tween()
	reveal.tween_property(_end_label, "modulate:a", 1.0, 1.5)
	reveal.tween_property(_end_sub, "modulate:a", 1.0, 1.2)
	await get_tree().create_timer(5.5).timeout
	Game.finish("kantong" if kantong else "tancep")


## Kelir Peteng: mengambil harta di puncak. Bayangan menutupi seluruh kelir.
func _kelir_peteng() -> void:
	ending_busy = true
	player.frozen = true
	for i in 6:
		Bobot.ambil("emas")
	Sfx.play("emas", 0.0, 0.9)
	Sfx.play("emas", -2.0, 1.25)
	_harta.visible = false
	var start := player.rig().scale.x
	var tw := create_tween().set_parallel()
	tw.tween_property(player, "scale_override", 18.0, 4.0).from(start).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_method(_set_bright, _bright, 0.0, 4.0)
	tw.tween_method(_set_darkness, 0.0, 0.92, 4.5)
	await get_tree().create_timer(1.2).timeout
	Music.stop_now()
	await get_tree().create_timer(3.4).timeout
	_end_label.add_theme_color_override("font_color", Art.PAPER)
	_end_sub.add_theme_color_override("font_color", Art.TEXT_DIM)
	_end_label.text = "Lakon ora rampung."
	_end_sub.text = "Lakonnya tidak selesai."
	_end_hint.text = "Tekan tombol apa saja untuk mengulang dari pathok"
	var reveal := create_tween()
	reveal.tween_property(_end_label, "modulate:a", 1.0, 1.5)
	reveal.tween_property(_end_sub, "modulate:a", 1.0, 1.0)
	reveal.tween_interval(1.0)
	reveal.tween_property(_end_hint, "modulate:a", 1.0, 0.8)
	await reveal.finished
	_await_any = true


func _undo_peteng() -> void:
	_await_any = false
	for l in [_end_label, _end_sub, _end_hint]:
		(l as Label).modulate.a = 0.0
	await Game.wipe(_restore_after_peteng, 0.8)


func _restore_after_peteng() -> void:
	_set_darkness(0.0)
	_bright = float(def["terang"])
	player.scale_override = 0.0
	_harta.visible = true
	_restore()
	ending_busy = false
	Music.play(str(def["musik"]))


# --- jeda ---------------------------------------------------------------------

func _unhandled_input(event: InputEvent) -> void:
	if _await_any:
		var pressed := event.is_pressed() and not event.is_echo()
		if pressed and (event is InputEventKey or event is InputEventJoypadButton):
			get_viewport().set_input_as_handled()
			_undo_peteng()
		return
	if event.is_action_pressed("pause") and not ending_busy:
		get_viewport().set_input_as_handled()
		_toggle_pause()


func _toggle_pause() -> void:
	if _pause_layer == null:
		_build_pause()
	var paused := not get_tree().paused
	get_tree().paused = paused
	_pause_layer.visible = paused
	Game.menu_open = paused
	if paused:
		Sfx.play("ui_move", -8.0)
		_pause_first.grab_focus()


func _build_pause() -> void:
	_pause_layer = CanvasLayer.new()
	_pause_layer.layer = 60
	_pause_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_pause_layer)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.55)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_pause_layer.add_child(dim)
	var panel := PanelContainer.new()
	panel.theme = Art.theme()
	Art.place(panel, Control.PRESET_CENTER, Rect2(-140, -110, 280, 220))
	_pause_layer.add_child(panel)
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 6)
	panel.add_child(box)
	var title := Art.label("Jeda", 24, Art.TEXT)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)
	var obj := Art.label(str(def.get("tujuan", "")), 14, Art.TEXT_DIM)
	obj.name = "Tujuan"
	obj.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	obj.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	obj.custom_minimum_size = Vector2(240, 0)
	box.add_child(obj)
	var items := [["Lanjut", _on_resume], ["Ulang dari pathok", _on_retry], ["Menu utama", _on_menu]]
	if Game.pati_geni():
		items = [["Lanjut", _on_resume], ["Menu utama", _on_menu]]
	for it in items:
		var b := Button.new()
		b.text = str(it[0])
		b.add_theme_color_override("font_color", Art.TEXT)
		b.pressed.connect(it[1])
		box.add_child(b)
		if _pause_first == null:
			_pause_first = b


func _on_resume() -> void:
	_toggle_pause()


func _on_retry() -> void:
	_toggle_pause()
	if not player.dead:
		Game.nyawa -= 1
		_update_nyawa()
		if Game.nyawa <= 0:
			await _blencong_padam()
			return
		await Game.wipe(_restore, 0.7)


func _on_menu() -> void:
	get_tree().paused = false
	Game.go_title()
