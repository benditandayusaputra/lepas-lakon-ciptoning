extends Node
## Alur permainan: babak, pindah adegan dengan sapuan gunungan, input, pengaturan, simpanan.

const GAME_SCENE := "res://scenes/game.tscn"
const TITLE_SCENE := "res://scenes/title.tscn"
const CREDITS_SCENE := "res://scenes/credits.tscn"
const PEMBUKA_SCENE := "res://scenes/pembuka.tscn"
const SAVE_PATH := "user://lepas_ciptoning.cfg"

var babak := 0
var babak_terbuka := 5
## Babak terakhir yang dimainkan, untuk tombol Lanjutkan.
var babak_terakhir := -1
## "" saat masuk kredit dari menu, atau nama ending yang baru dicapai.
var ending := ""
var menu_open := false
var stats := {"waktu": 0.0, "mati": 0}
var settings := {"musik": 0.8, "efek": 0.9, "kedip": true, "butiran": true, "kesulitan": 1, "cerita_otomatis": false}

const KESULITAN := ["Mudah", "Sedang", "Sulit", "Pati Geni"]
const NYAWA := [7, 5, 3, 1]
## Mode Pati Geni: satu nyawa, tanpa pathok; mati berarti lakon diulang dari babak 1.
const PATI_GENI := 3
## Tingkat kesulitan: 0 Mudah, 1 Sedang, 2 Sulit (tersimpan di pengaturan).
var kesulitan: int:
	get:
		return clampi(int(settings.get("kesulitan", 1)), 0, 3)
	set(v):
		settings["kesulitan"] = clampi(v, 0, 3)
## Nyawa tersisa di babak ini; habis berarti babak diulang dari awal.
var nyawa := 5
## Bawaan saat babak dimasuki, untuk mengulang babak.
var bawaan_awal: Array = []

var _fade_layer: CanvasLayer
var _fade: ColorRect
var _gunungan: Sprite2D = null
var _gunungan_w := 0.0
var _busy := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_input()
	Art.theme()
	_load()
	_fade_layer = CanvasLayer.new()
	_fade_layer.layer = 100
	add_child(_fade_layer)
	_fade = ColorRect.new()
	_fade.color = Color(Art.BG, 0.0)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade_layer.add_child(_fade)
	# Gambar gunungan (assets/wayang/gunungan.png) membuat pergantian adegan menjadi sapuan kayon.
	var g := Art.wayang("gunungan")
	if g:
		_gunungan = Sprite2D.new()
		var k := 330.0 / float(g.get_height())
		_gunungan.texture = g
		_gunungan.scale = Vector2(k, k)
		_gunungan.material = Art.siluet_material(Art.HITAM)
		_gunungan.visible = false
		_gunungan_w = g.get_width() * k
		_fade_layer.add_child(_gunungan)
	apply_settings.call_deferred()
	_test_args.call_deferred()


## Uji cepat dari baris perintah: godot --path . -- --babak=3 --keluar=10
var debug_bot := false


func _test_args() -> void:
	var bot := false
	for a in OS.get_cmdline_user_args():
		if a == "--bot":
			bot = true
			debug_bot = true
		if a.begins_with("--kesulitan="):
			kesulitan = int(a.get_slice("=", 1))
		if a.begins_with("--babak="):
			start_babak(int(a.get_slice("=", 1)) - 1, true)
		elif a.begins_with("--keluar="):
			get_tree().create_timer(float(a.get_slice("=", 1)), true, false, true).timeout.connect(_uji_selesai)
	if bot and ResourceLoader.exists("res://scripts/uji/bot.gd"):
		var b: Node = (load("res://scripts/uji/bot.gd") as GDScript).new()
		add_child(b)


func _uji_selesai() -> void:
	var scene := get_tree().current_scene
	var info := "UJI adegan=%s babak=%d bobot=%d bawaan=%s mati=%d" % [scene.name if scene else "-", babak + 1, Bobot.total(), str(Bobot.bawaan), int(stats["mati"])]
	if scene and scene.get("player") != null:
		var p: Node2D = scene.get("player")
		info += " posisi=%s" % str(p.global_position)
	print(info)
	get_tree().quit()


func _process(delta: float) -> void:
	if get_tree().current_scene and get_tree().current_scene.name == "Level" and not get_tree().paused:
		stats["waktu"] += delta


func _unhandled_input(event: InputEvent) -> void:
	# Saat jeda, adegan babak tidak menerima input, jadi tombol jeda diteruskan dari sini.
	if event.is_action_pressed("pause") and get_tree().paused and menu_open:
		var scene := get_tree().current_scene
		if scene and scene.has_method("_toggle_pause"):
			get_viewport().set_input_as_handled()
			scene.call("_toggle_pause")
		return
	if event.is_action_pressed("fullscreen"):
		var mode := DisplayServer.window_get_mode()
		if mode == DisplayServer.WINDOW_MODE_FULLSCREEN:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		else:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)


# --- alur ---------------------------------------------------------------------

func new_game() -> void:
	go(PEMBUKA_SCENE)


## Mulai babak tertentu dengan bawaan awal babak itu (dipakai juga oleh Pilih Babak).
## Nilai sesuai tingkat kesulitan: arr = [mudah, sedang, sulit].
func pilih(arr: Array) -> Variant:
	return arr[mini(kesulitan, arr.size() - 1)]


func pati_geni() -> bool:
	return kesulitan == PATI_GENI


func nyawa_penuh() -> int:
	return int(NYAWA[kesulitan])


func nama_kesulitan() -> String:
	return str(KESULITAN[kesulitan])


## Nyawa habis: babak yang sama dimulai lagi dari awal dengan bawaan saat masuk.
func ulang_babak() -> void:
	if debug_bot:
		print("ULANG BABAK %d dengan bawaan %s" % [babak + 1, str(bawaan_awal)])
	if pati_geni():
		start_babak(0, true)
		return
	Bobot.setel(bawaan_awal)
	nyawa = nyawa_penuh()
	go(GAME_SCENE)


func start_babak(index: int, fresh := false) -> void:
	nyawa = nyawa_penuh()
	babak = clampi(index, 0, BabakDefs.count() - 1)
	Bobot.setel(BabakDefs.start_bawaan(babak))
	if fresh or babak == 0:
		Bobot.emas_pernah = false
		stats = {"waktu": 0.0, "mati": 0}
	ending = ""
	babak_terakhir = babak
	_save()
	go(GAME_SCENE)


## Babak selesai: bawaan terbawa apa adanya ke babak berikutnya.
func complete_babak() -> void:
	nyawa = nyawa_penuh()
	babak += 1
	babak_terbuka = maxi(babak_terbuka, babak + 1)
	babak_terakhir = mini(babak, BabakDefs.count() - 1)
	_save()
	if babak >= BabakDefs.count():
		finish("tancep")
	else:
		go(GAME_SCENE)


func finish(ending_name: String) -> void:
	ending = ending_name
	go(CREDITS_SCENE, 1.2)


func go_title() -> void:
	ending = ""
	go(TITLE_SCENE)


func go_credits() -> void:
	ending = ""
	go(CREDITS_SCENE)


func go(scene_path: String, fade_time := 0.35) -> void:
	if _busy:
		return
	_busy = true
	menu_open = false
	Sfx.play("keprak", -4.0)
	await _cover(fade_time)
	get_tree().paused = false
	get_tree().change_scene_to_file(scene_path)
	await get_tree().process_frame
	await _uncover(fade_time)
	_busy = false


## Sapuan cepat tanpa ganti adegan (kematian). at_middle dipanggil saat layar tertutup.
func wipe(at_middle: Callable, duration := 0.7) -> void:
	await _cover(duration * 0.5)
	at_middle.call()
	await get_tree().process_frame
	await _uncover(duration * 0.5)


func _cover(t: float) -> void:
	var view := get_viewport().get_visible_rect().size
	var tw := create_tween()
	if _gunungan:
		_gunungan.visible = true
		_gunungan.position = Vector2(view.x + _gunungan_w, view.y / 2.0)
		tw.tween_property(_gunungan, "position:x", view.x / 2.0, maxf(t, 0.25)).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		tw.parallel().tween_property(_fade, "color:a", 1.0, maxf(t, 0.25))
	else:
		tw.tween_property(_fade, "color:a", 1.0, t)
	await tw.finished


func _uncover(t: float) -> void:
	var tw := create_tween()
	tw.tween_property(_fade, "color:a", 0.0, t)
	if _gunungan:
		tw.parallel().tween_property(_gunungan, "position:x", -_gunungan_w, maxf(t, 0.25)).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	await tw.finished
	if _gunungan:
		_gunungan.visible = false
	_fade.color = Color(Art.BG, 0.0)


func fade_to(color: Color, duration: float) -> void:
	_fade.color = Color(color, _fade.color.a)
	var t := create_tween()
	t.tween_property(_fade, "color:a", 1.0, duration)
	await t.finished


func clear_fade() -> void:
	_fade.color = Color(Art.BG, 0.0)


# --- pengaturan dan simpanan --------------------------------------------------

func set_setting(key: String, value: Variant) -> void:
	settings[key] = value
	apply_settings()
	_save()


func apply_settings() -> void:
	Music.set_volume("Music", float(settings["musik"]))
	Music.set_volume("SFX", float(settings["efek"]))


func _save() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("progres", "babak_terbuka", babak_terbuka)
	cfg.set_value("progres", "babak_terakhir", babak_terakhir)
	for k in settings:
		cfg.set_value("pengaturan", k, settings[k])
	cfg.save(SAVE_PATH)


func _load() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return
	babak_terbuka = maxi(5, int(cfg.get_value("progres", "babak_terbuka", 5)))
	babak_terakhir = int(cfg.get_value("progres", "babak_terakhir", -1))
	for k in settings.keys():
		settings[k] = cfg.get_value("pengaturan", k, settings[k])


# --- input --------------------------------------------------------------------

func _setup_input() -> void:
	_bind("move_left", [KEY_A, KEY_LEFT])
	_bind("move_right", [KEY_D, KEY_RIGHT])
	_bind("move_up", [KEY_W, KEY_UP])
	_bind("move_down", [KEY_S, KEY_DOWN])
	_bind("jump", [KEY_SPACE, KEY_W, KEY_UP])
	_bind("aksi", [KEY_E, KEY_J])
	_bind("lepas", [KEY_Q, KEY_K])
	_bind("pause", [KEY_ESCAPE, KEY_P])
	_bind("fullscreen", [KEY_F11, KEY_F])
	_bind_pad("move_left", JOY_BUTTON_DPAD_LEFT)
	_bind_pad("move_right", JOY_BUTTON_DPAD_RIGHT)
	_bind_pad("move_up", JOY_BUTTON_DPAD_UP)
	_bind_pad("move_down", JOY_BUTTON_DPAD_DOWN)
	_bind_pad("jump", JOY_BUTTON_A)
	_bind_pad("aksi", JOY_BUTTON_X)
	_bind_pad("lepas", JOY_BUTTON_B)
	_bind_pad("pause", JOY_BUTTON_START)
	_bind_axis("move_left", JOY_AXIS_LEFT_X, -1.0)
	_bind_axis("move_right", JOY_AXIS_LEFT_X, 1.0)
	_bind_axis("move_up", JOY_AXIS_LEFT_Y, -1.0)
	_bind_axis("move_down", JOY_AXIS_LEFT_Y, 1.0)


func _bind(action: String, keys: Array) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	for k in keys:
		var ev := InputEventKey.new()
		ev.physical_keycode = k
		InputMap.action_add_event(action, ev)


func _bind_pad(action: String, button: JoyButton) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	var ev := InputEventJoypadButton.new()
	ev.button_index = button
	InputMap.action_add_event(action, ev)


func _bind_axis(action: String, axis: JoyAxis, dir: float) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	var ev := InputEventJoypadMotion.new()
	ev.axis = axis
	ev.axis_value = dir
	InputMap.action_add_event(action, ev)
