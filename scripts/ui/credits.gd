extends Control
## Kredit dan layar ending.

const ENDINGS := {
	"tancep": ["Tancep Kayon", "Arjuna sampai di puncak dengan tangan kosong. Lakon selesai."],
	"kantong": ["Kantong Bolong", "Sejak awal tidak satu keping emas pun diambil. Memberi tanpa sisa."],
}

const CREDITS := [
	["LEPAS: Lakon Ciptoning", 26],
	["Game Development Dinamik-21. Tema: Less is More, More is Worse.", 15],
	["", 8],
	["Tim", 18],
	["Zahra Illiyin (Ketua)", 16],
	["Jessica Anabella", 16],
	["Made Kevin Darmawan", 16],
	["Bendi Tandayu Saputra", 16],
	["Rivaldi Gunawan Yusuf", 16],
	["BINUS University", 14],
	["", 10],
	["Wayang", 18],
	["Yale University Art Gallery, The Dr. Walter Angst and Sir Henry Angest Collection. Domain publik (CC0).", 14],
	["Set Kyai Nugroho (Yogyakarta, 1913), Ki Kertiwanda dan Ki Bekel Prawirasucitra:", 14],
	["Arjuna Bertapa, Gunungan, Kumbakarna, Dursasana (Marto Suwondo), Sengkuni (Marto Suwondo),", 14],
	["Semar dan panakawan (Ki Kertiwanda, 1920).", 14],
	["Arjuna dari set Kyai Drajat (Surakarta, abad ke-19). Wek atau Babi (Bali, awal abad ke-20).", 14],
	["", 8],
	["Musik", 18],
	["\"Javanese Court Gamelan 1 - Indonesia\" oleh RTB45, Freesound, CC-BY 4.0.", 14],
	["\"Gender Wayang\" (1928), rekaman tradisional, domain publik (Wikimedia Commons).", 14],
	["Musik pengganti: Kenney Music Loops (CC0).", 14],
	["", 8],
	["Gambar dan suara", 18],
	["Kenney: Background Elements Remastered, Foliage Sprites, 1-Bit Pack, Particle Pack,", 14],
	["Impact Sounds, RPG Audio, Interface Sounds. Semua CC0.", 14],
	["Font Cormorant Garamond (SIL Open Font License).", 14],
	["", 8],
	["Rujukan", 18],
	["Lakon Begawan Ciptoning (Mintaraga), dari kakawin Arjunawiwaha karya Empu Kanwa.", 14],
	["Petuah R.M.P. Sosrokartono: sugih tanpa bandha, digdaya tanpa aji, nglurug tanpa bala,", 14],
	["menang tanpa ngasorake, trima mawi pasrah.", 14],
	["", 8],
	["Dibuat dengan Godot Engine. Tidak ada aset buatan AI generatif.", 14],
]

var _scroll: ScrollContainer
var _speed := 14.0
var _hold := 2.5
var _acc := 0.0


func _ready() -> void:
	theme = Art.theme()
	var ended := Game.ending != ""
	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mat := ShaderMaterial.new()
	mat.shader = Art.KELIR_SHADER
	var pal: Dictionary = Art.PATHET["fajar" if ended else "nem"]
	mat.set_shader_parameter("hot", pal["hot"])
	mat.set_shader_parameter("mid", pal["mid"])
	mat.set_shader_parameter("edge", pal["edge"])
	mat.set_shader_parameter("flicker_amount", 1.0 if bool(Game.settings["kedip"]) else 0.15)
	bg.material = mat
	add_child(bg)
	var stage := Node2D.new()
	add_child(stage)
	var g := Art.gunungan(200.0, Color(Art.HITAM, 0.18))
	g.position = Vector2(320, 340)
	stage.add_child(g)

	_scroll = ScrollContainer.new()
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	Art.place(_scroll, Control.PRESET_CENTER, Rect2(-300, -150, 600, 270))
	add_child(_scroll)
	var box := VBoxContainer.new()
	box.custom_minimum_size = Vector2(600, 0)
	box.add_theme_constant_override("separation", 2)
	_scroll.add_child(box)
	if ended:
		var info: Array = ENDINGS.get(Game.ending, ["Tancep Kayon", ""])
		_add(box, "Ending", 15)
		_add(box, str(info[0]), 34)
		_add(box, str(info[1]), 15)
		var secs := int(float(Game.stats["waktu"]))
		_add(box, "Waktu %d menit %d detik. Mati %d kali." % [secs / 60, secs % 60, int(Game.stats["mati"])], 14)
		_add(box, "", 30)
	for c in CREDITS:
		var row: Array = c
		_add(box, str(row[0]), int(row[1]))
	_add(box, "", 40)

	var back := Button.new()
	back.text = "Kembali ke menu"
	back.add_theme_font_size_override("font_size", 18)
	# Diberi jarak dari tepi bawah supaya tidak terpotong di embed browser.
	Art.place(back, Control.PRESET_CENTER_BOTTOM, Rect2(-110, -58, 220, 30))
	back.grow_vertical = Control.GROW_DIRECTION_BEGIN
	back.pressed.connect(_on_back)
	add_child(back)
	back.grab_focus.call_deferred()
	Music.set_bypass(true)
	Music.play("fajar" if ended else "judul")


func _add(box: VBoxContainer, text: String, font_size: int) -> void:
	var l := Art.ink_label(text, font_size)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(600, 0)
	box.add_child(l)


func _process(delta: float) -> void:
	if _hold > 0.0:
		_hold -= delta
		return
	_acc += _speed * delta
	if _acc >= 1.0:
		var step := int(_acc)
		_acc -= float(step)
		_scroll.scroll_vertical += step


func _on_back() -> void:
	Sfx.play("ui_back", -6.0)
	Game.go_title()
