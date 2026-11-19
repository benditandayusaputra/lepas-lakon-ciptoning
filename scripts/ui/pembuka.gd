extends Control
## Pembukaan lakon: kelir dibuka, dalang membuka cerita, gunungan dicabut, babak pertama dimulai.
## Baris cerita muncul satu per satu setiap kali pemain mengeklik atau menekan Spasi/Enter.
## Mode Otomatis (bawaan mati) memunculkan baris sendiri dengan jeda yang cukup untuk dibaca.
## Esc atau tombol Lewati langsung memulai babak.

const BARIS := [
	"Kelir dibuka. Blencong menyala.",
	"Arjuna, ksatria Amarta, hendak bertapa di puncak Indrakila.",
	"Ia berangkat membawa mahkota, tameng, dan terompah.",
	"Namun jalan menuju tapa tidak memberi tempat bagi beban.",
	"Setiap yang dibawa memperberat langkah.",
	"Setiap yang dilepas membuka jalan.",
]
## Jeda baca untuk mode Otomatis: dasar + per huruf.
const JEDA_DASAR := 2.4
const JEDA_HURUF := 0.055

var _labels: Array[Label] = []
var _t := 0.0
var _shown := 0
var _done := false
var _gunungan: Node2D
var _arjuna: Sprite2D
var _hint: Label
var _otomatis := false
var _tunggu := 0.0
var _tombol_otomatis: Button


func _ready() -> void:
	theme = Art.theme()
	Music.set_bypass(true)
	Music.play("judul")
	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mat := ShaderMaterial.new()
	mat.shader = Art.KELIR_SHADER
	var pal: Dictionary = Art.PATHET["nem"]
	mat.set_shader_parameter("hot", pal["hot"])
	mat.set_shader_parameter("mid", pal["mid"])
	mat.set_shader_parameter("edge", pal["edge"])
	mat.set_shader_parameter("lamp_uv", Vector2(0.5, 0.3))
	mat.set_shader_parameter("flicker_amount", 1.0 if bool(Game.settings["kedip"]) else 0.15)
	bg.material = mat
	add_child(bg)

	var stage := Node2D.new()
	add_child(stage)
	var ground := Art.rect(Vector2(640, 40), Art.HITAM)
	ground.position = Vector2(0, 330)
	stage.add_child(ground)
	_arjuna = Art.figure("arjuna", Vector2i(29, 0), 44.0)
	Art.warnai(_arjuna)
	_arjuna.position += Vector2(170, 331)
	_arjuna.flip_h = Art.arah("arjuna") < 0
	_arjuna.modulate.a = 0.0
	stage.add_child(_arjuna)
	_gunungan = Art.gunungan(170.0)
	Art.warnai(_gunungan)
	_gunungan.position = Vector2(320, 335)
	stage.add_child(_gunungan)

	var box := VBoxContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_theme_constant_override("separation", 2)
	Art.place(box, Control.PRESET_CENTER_TOP, Rect2(-300, 18, 600, 160))
	add_child(box)
	for line in BARIS:
		var l := Art.ink_label(str(line), 16)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.modulate.a = 0.0
		box.add_child(l)
		_labels.append(l)

	_hint = Art.ink_label("Klik atau tekan Spasi untuk lanjut", 12)
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	Art.place(_hint, Control.PRESET_CENTER_TOP, Rect2(-220, 146, 440, 18))
	add_child(_hint)

	var bar := HBoxContainer.new()
	bar.add_theme_constant_override("separation", 6)
	bar.alignment = BoxContainer.ALIGNMENT_END
	Art.place(bar, Control.PRESET_BOTTOM_RIGHT, Rect2(-240, -60, 230, 26))
	add_child(bar)
	_otomatis = bool(Game.settings.get("cerita_otomatis", false))
	if OS.get_cmdline_user_args().has("--cerita-otomatis"):
		_otomatis = true
	_tombol_otomatis = _tombol(bar, "", _toggle_otomatis)
	_tombol(bar, "Lewati", _selesai)
	_segarkan_tombol()
	Sfx.play("gong", -4.0, 0.9)


func _tombol(parent: Control, teks: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = teks
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_size_override("font_size", 13)
	b.pressed.connect(cb)
	parent.add_child(b)
	return b


func _segarkan_tombol() -> void:
	_tombol_otomatis.text = "Otomatis: %s" % ("Nyala" if _otomatis else "Mati")


func _toggle_otomatis() -> void:
	_otomatis = not _otomatis
	Game.settings["cerita_otomatis"] = _otomatis
	Game._save()
	_segarkan_tombol()
	Sfx.play("ui_move", -10.0)
	_tunggu = 0.0


func _process(delta: float) -> void:
	if _done:
		return
	_t += delta
	# Baris pertama muncul sendiri sebagai pembuka.
	if _shown == 0 and _t > 0.8:
		_lanjut()
	_hint.modulate.a = 0.45 + 0.35 * sin(_t * 3.0)
	if _otomatis and _shown > 0:
		_tunggu += delta
		var baris_akhir := str(BARIS[_shown - 1])
		if _tunggu >= JEDA_DASAR + JEDA_HURUF * float(baris_akhir.length()):
			_lanjut()


## Munculkan baris berikutnya; setelah baris terakhir, lakon dimulai.
func _lanjut() -> void:
	_tunggu = 0.0
	if _shown >= _labels.size():
		_selesai()
		return
	for i in _shown:
		create_tween().tween_property(_labels[i], "modulate:a", 0.55, 0.5)
	var l := _labels[_shown]
	create_tween().tween_property(l, "modulate:a", 1.0, 0.8)
	Sfx.play("keprak", -12.0, 1.0 + 0.05 * float(_shown))
	if _shown == 2:
		create_tween().tween_property(_arjuna, "modulate:a", 1.0, 1.2)
	_shown += 1
	if _shown >= _labels.size():
		_hint.text = "Klik atau tekan Spasi untuk memulai lakon"


func _unhandled_input(event: InputEvent) -> void:
	if _done or _t < 0.5:
		return
	if event.is_action_pressed("pause") or (event is InputEventKey and (event as InputEventKey).keycode == KEY_ESCAPE and event.is_pressed()):
		get_viewport().set_input_as_handled()
		_selesai()
		return
	var lanjut := false
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		lanjut = mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT
	elif event is InputEventKey:
		var k := event as InputEventKey
		lanjut = k.pressed and not k.echo and k.keycode in [KEY_SPACE, KEY_ENTER, KEY_KP_ENTER, KEY_E, KEY_J, KEY_RIGHT, KEY_D]
	elif event is InputEventJoypadButton:
		var jb := event as InputEventJoypadButton
		lanjut = jb.pressed and jb.button_index == JOY_BUTTON_A
	if lanjut:
		get_viewport().set_input_as_handled()
		_lanjut()


## Gunungan dicabut, lakon dimulai.
func _selesai() -> void:
	if _done:
		return
	_done = true
	Sfx.play("kepyak", -8.0)
	var tw := create_tween()
	tw.tween_property(_gunungan, "position:y", -260.0, 0.9).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tw.parallel().tween_property(_hint, "modulate:a", 0.0, 0.3)
	set_process(false)
	tw.tween_callback(_mulai)


func _mulai() -> void:
	Game.start_babak(0, true)
