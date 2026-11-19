extends Node
## Efek suara bergaya dalang. Semua file ada di assets/audio/sfx (Kenney, CC0).
## Untuk mengganti suara (misalnya keprak atau gong rekaman sendiri), taruh file baru dengan nama
## yang sama, atau ubah daftar di bawah.

const DIR := "res://assets/audio/sfx/"

const SOUNDS := {
	"lompat": ["impactSoft_medium_000.ogg"],
	"mendarat": ["impactSoft_heavy_000.ogg"],
	"langkah": ["footstep00.ogg", "footstep01.ogg", "footstep02.ogg"],
	"langkah_kayu": ["impactWood_light_000.ogg", "impactWood_light_001.ogg", "impactWood_light_002.ogg", "impactWood_light_003.ogg"],
	"keprak": ["impactWood_heavy_001.ogg", "impactPlank_medium_000.ogg"],
	"kepyak": ["impactMetal_light_000.ogg", "impactMetal_light_001.ogg", "impactMetal_light_002.ogg"],
	"gong": ["impactBell_heavy_001.ogg", "impactBell_heavy_000.ogg"],
	"mati": ["impactPunch_heavy_000.ogg"],
	"ambil": ["handleSmallLeather.ogg", "cloth2.ogg"],
	"lepas": ["dropLeather.ogg"],
	"lempar": ["cloth1.ogg", "cloth3.ogg"],
	"emas": ["glass_001.ogg"],
	"tameng_pecah": ["impactMetal_heavy_000.ogg", "impactMetal_heavy_002.ogg"],
	"panah": ["impactPlank_medium_000.ogg"],
	"retak": ["creak1.ogg", "creak2.ogg"],
	"patah": ["impactWood_heavy_001.ogg"],
	"gerbang": ["doorOpen_1.ogg"],
	"sesaji": ["bong_001.ogg"],
	"pathok": ["maximize_003.ogg"],
	"buta": ["metalPot1.ogg"],
	"geram": ["impactSoft_heavy_000.ogg"],
	"angin": ["cloth4.ogg", "cloth3.ogg"],
	"tali": ["cloth2.ogg", "cloth4.ogg"],
	"ui_move": ["select_001.ogg"],
	"ui_confirm": ["confirmation_001.ogg"],
	"ui_back": ["back_001.ogg"],
}

var _streams := {}
var _players: Array[AudioStreamPlayer] = []
var _next := 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	Music.ensure_buses()
	for key in SOUNDS:
		var list: Array = []
		for f in SOUNDS[key]:
			var path: String = DIR + str(f)
			if ResourceLoader.exists(path):
				list.append(load(path))
		_streams[key] = list
	for i in 14:
		var p := AudioStreamPlayer.new()
		p.bus = "SFX"
		add_child(p)
		_players.append(p)


func play(key: String, volume_db := 0.0, pitch := 1.0, pitch_rand := 0.06) -> void:
	var list: Array = _streams.get(key, [])
	if list.is_empty():
		return
	var p := _players[_next]
	_next = (_next + 1) % _players.size()
	p.stream = list[randi() % list.size()]
	p.volume_db = volume_db
	p.pitch_scale = maxf(0.05, pitch * randf_range(1.0 - pitch_rand, 1.0 + pitch_rand))
	p.play()
