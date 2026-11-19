extends Control
## Layar judul: kelir, gunungan, dan menu.

var _menu: VBoxContainer
var _panel: Control = null
var _first: Button = null


func _ready() -> void:
	theme = Art.theme()
	Music.set_bypass(true)
	Music.play("judul")
	_build_background()
	_build_title()
	_show_main()
	if OS.get_cmdline_user_args().has("--layar-kesulitan"):
		_show_kesulitan(_mulai_baru)
	# Untuk membuat gambar sampul: godot --path . -- --sampul (menu disembunyikan).
	if OS.get_cmdline_user_args().has("--sampul") and _panel:
		_panel.visible = false


func _build_background() -> void:
	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mat := ShaderMaterial.new()
	mat.shader = Art.KELIR_SHADER
	var pal: Dictionary = Art.PATHET["nem"]
	mat.set_shader_parameter("hot", pal["hot"])
	mat.set_shader_parameter("mid", pal["mid"])
	mat.set_shader_parameter("edge", pal["edge"])
	mat.set_shader_parameter("lamp_uv", Vector2(0.3, 0.32))
	mat.set_shader_parameter("flicker_amount", 1.0 if bool(Game.settings["kedip"]) else 0.15)
	bg.material = mat
	add_child(bg)
	var stage := Node2D.new()
	add_child(stage)
	var g := Art.gunungan(250.0)
	Art.warnai(g)
	g.position = Vector2(190, 330)
	stage.add_child(g)
	var ground := Art.rect(Vector2(640, 40), Art.HITAM)
	ground.position = Vector2(0, 330)
	stage.add_child(ground)
	var arjuna := Art.figure("arjuna", Vector2i(29, 0), 44.0)
	Art.warnai(arjuna)
	arjuna.position += Vector2(300, 331)
	arjuna.flip_h = Art.arah("arjuna") < 0
	stage.add_child(arjuna)
	var post := ColorRect.new()
	post.set_anchors_preset(Control.PRESET_FULL_RECT)
	post.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var pm := ShaderMaterial.new()
	pm.shader = Art.POST_SHADER
	pm.set_shader_parameter("grain", 0.06 if bool(Game.settings["butiran"]) else 0.0)
	pm.set_shader_parameter("vignette", 0.5)
	post.material = pm
	add_child(post)


func _build_title() -> void:
	var box := VBoxContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_theme_constant_override("separation", -6)
	Art.place(box, Control.PRESET_TOP_RIGHT, Rect2(-300, 34, 280, 120))
	add_child(box)
	var t1 := Art.ink_label("LEPAS", 64)
	var t2 := Art.ink_label("Lakon Ciptoning", 24)
	var t3 := Art.ink_label("Sugih tanpa bandha, digdaya tanpa aji.", 14)
	var jeda := Control.new()
	jeda.custom_minimum_size = Vector2(0, 16)
	jeda.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for l in [t1, t2, jeda, t3]:
		if l is Label:
			(l as Label).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		box.add_child(l)


func _clear_panel() -> void:
	if _panel:
		remove_child(_panel)
		_panel.queue_free()
		_panel = null
	_first = null


func _new_panel() -> VBoxContainer:
	_clear_panel()
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 2)
	Art.place(box, Control.PRESET_TOP_RIGHT, Rect2(-300, 150, 280, 200))
	add_child(box)
	_panel = box
	return box


func _button(parent: Container, text: String, cb: Callable, font_size := 20) -> Button:
	var b := Button.new()
	b.text = text
	b.add_theme_font_size_override("font_size", font_size)
	b.pressed.connect(cb)
	b.focus_entered.connect(_on_focus)
	parent.add_child(b)
	if _first == null:
		_first = b
	return b


func _on_focus() -> void:
	Sfx.play("ui_move", -14.0)


func _show_main() -> void:
	var box := _new_panel()
	# Menu lebih rapat bila ada tombol Lanjutkan, supaya tidak menabrak judul.
	var fs := 20
	var n := 5 + (1 if Game.babak_terakhir > 0 else 0) + (0 if OS.has_feature("web") else 1)
	if n >= 6:
		fs = 17
		box.add_theme_constant_override("separation", 0)
		box.position.y += 8.0
	if Game.babak_terakhir > 0:
		var d := BabakDefs.get_def(Game.babak_terakhir)
		_button(box, "Lanjutkan: %s" % str(d["nama"]), _on_continue, 16)
	_button(box, "Mulai", _on_start, fs)
	_button(box, "Pilih babak", _show_babak, fs)
	_button(box, "Pengaturan", _show_settings, fs)
	_button(box, "Kontrol", _show_controls, fs)
	_button(box, "Kredit", _on_credits, fs)
	if not OS.has_feature("web"):
		_button(box, "Keluar", _on_quit, fs)
	_first.grab_focus.call_deferred()


func _show_babak() -> void:
	Sfx.play("ui_confirm", -10.0)
	var box := _new_panel()
	for i in BabakDefs.count():
		var d := BabakDefs.get_def(i)
		var b := _button(box, "%d. %s" % [i + 1, str(d["nama"])], _start_babak.bind(i), 17)
		b.disabled = i >= Game.babak_terbuka
	_button(box, "Kembali", _show_main, 17)
	_first.grab_focus.call_deferred()


func _show_settings() -> void:
	Sfx.play("ui_confirm", -10.0)
	var box := _new_panel()
	box.add_child(_slider_row("Musik", "musik"))
	box.add_child(_slider_row("Efek suara", "efek"))
	box.add_child(_check_row("Kedip blencong", "kedip"))
	box.add_child(_check_row("Butiran film", "butiran"))
	_button(box, "Kesulitan: %s" % Game.nama_kesulitan(), _ganti_kesulitan, 17)
	_button(box, "Kembali", _show_main, 17)
	_first.grab_focus.call_deferred()


func _ganti_kesulitan() -> void:
	Game.kesulitan = (Game.kesulitan + 1) % 4
	Game._save()
	_show_settings()


func _slider_row(text: String, key: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	var l := Art.ink_label(text, 16)
	l.custom_minimum_size = Vector2(110, 0)
	row.add_child(l)
	var s := HSlider.new()
	s.min_value = 0.0
	s.max_value = 1.0
	s.step = 0.05
	s.value = float(Game.settings[key])
	s.custom_minimum_size = Vector2(140, 20)
	s.value_changed.connect(_on_slider.bind(key))
	row.add_child(s)
	return row


func _check_row(text: String, key: String) -> CheckButton:
	var c := CheckButton.new()
	c.text = text
	c.button_pressed = bool(Game.settings[key])
	c.add_theme_color_override("font_color", Art.TEXT_INK)
	c.add_theme_font_size_override("font_size", 16)
	c.toggled.connect(_on_check.bind(key))
	return c


func _on_slider(value: float, key: String) -> void:
	Game.set_setting(key, value)


func _on_check(on: bool, key: String) -> void:
	Game.set_setting(key, on)
	Sfx.play("ui_move", -10.0)


func _show_controls() -> void:
	Sfx.play("ui_confirm", -10.0)
	var box := _new_panel()
	var lines := [
		"A / D   jalan",
		"Spasi   lompat (tahan saat jatuh: melayang)",
		"E   ambil barang",
		"Q   lepas barang teratas",
		"Q di depan sesaji   persembahkan",
		"W / S   panjat tali",
		"Esc   jeda      F   layar penuh",
	]
	for t in lines:
		box.add_child(Art.ink_label(str(t), 15))
	_button(box, "Kembali", _show_main, 17)
	_first.grab_focus.call_deferred()


func _on_start() -> void:
	Sfx.play("ui_confirm", -6.0)
	_show_kesulitan(_mulai_baru)


func _mulai_baru() -> void:
	Music.set_bypass(false)
	Game.new_game()


## Pilih tingkat kesulitan sebelum bermain.
func _show_kesulitan(lanjut: Callable) -> void:
	var box := _new_panel()
	# Lebih rapat supaya keterangan Pati Geni dan tombol Kembali tidak turun ke tanah.
	box.add_theme_constant_override("separation", -1)
	box.position.y -= 4.0
	var judul := Art.ink_label("Tingkat kesulitan", 16)
	judul.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(judul)
	var pilihan := []
	for i in 4:
		var teks := "%s  (%d nyawa)" % [Game.KESULITAN[i], Game.NYAWA[i]]
		var b := _button(box, teks, _pilih_kesulitan.bind(i, lanjut), 15)
		pilihan.append(b)
		if i == Game.PATI_GENI:
			# Keterangan dipisah ke baris kecil supaya tidak terpotong tepi layar.
			var ket := Art.ink_label("Mati sekali, lakon diulang dari Babak 1", 12)
			ket.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			box.add_child(ket)
	_button(box, "Kembali", _show_main, 15)
	(pilihan[Game.kesulitan] as Button).grab_focus.call_deferred()


func _pilih_kesulitan(i: int, lanjut: Callable) -> void:
	Sfx.play("ui_confirm", -6.0)
	Game.kesulitan = i
	Game._save()
	lanjut.call()


func _on_continue() -> void:
	Sfx.play("ui_confirm", -6.0)
	_show_kesulitan(_lanjut_babak)


func _lanjut_babak() -> void:
	Music.set_bypass(false)
	# Pati Geni selalu dimulai dari babak pertama.
	Game.start_babak(0 if Game.pati_geni() else Game.babak_terakhir, true)


func _start_babak(i: int) -> void:
	Sfx.play("ui_confirm", -6.0)
	Music.set_bypass(false)
	Game.start_babak(i, i == 0)


func _on_credits() -> void:
	Sfx.play("ui_confirm", -6.0)
	Game.go_credits()


func _on_quit() -> void:
	get_tree().quit()
