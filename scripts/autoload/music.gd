extends Node
## Musik yang ikut memikul beban.
##
## Rekaman gamelan dipakai bila filenya ada:
##   assets/audio/music/gamelan.ogg atau gamelan.mp3  (musik utama, Javanese Court Gamelan 1, CC-BY 4.0)
##   assets/audio/music/gender.ogg   (babak 5 dan ending, Gender Wayang 1928, domain publik)
## Kalau belum ada, dipakai loop Kenney (CC0) sebagai pengganti.
##
## Bus Music melewati filter low-pass yang dikendalikan Bobot: makin berat bawaan, makin pengap.
## Setiap barang yang dilepas membuka filter satu langkah.

const G := "res://assets/audio/music/"
const TRACKS := {
	"judul": [G + "gamelan.ogg", G + "gamelan.mp3", G + "sad_descent.ogg"],
	"babak": [G + "gamelan.ogg", G + "gamelan.mp3", G + "infinite_descent.ogg"],
	"badai": [G + "gamelan_sampak.ogg", G + "gamelan.ogg", G + "gamelan.mp3", G + "flowing_rocks.ogg"],
	"kejar": [G + "kejar.ogg", G + "gamelan.ogg", G + "gamelan.mp3", G + "flowing_rocks.ogg"],
	"fajar": [G + "gender.ogg", G + "sad_descent.ogg"],
}
## Gamelan yang sama dimainkan lebih cepat untuk badai dan pengejaran.
const PITCH := {"badai": 1.06, "kejar": 1.14}
## Frekuensi potong per Bobot (indeks = Bobot, lebih dari 7 memakai nilai terakhir).
const CUTOFFS := [20000.0, 12000.0, 7000.0, 4200.0, 2800.0, 1900.0, 1200.0, 800.0]

var _player: AudioStreamPlayer
var _lowpass: AudioEffectLowPassFilter
var _current := ""
var _buses_ready := false
var _bypass := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	ensure_buses()
	_player = AudioStreamPlayer.new()
	_player.bus = "Music"
	_player.volume_db = -6.0
	add_child(_player)
	Bobot.berubah.connect(_on_bobot)


func ensure_buses() -> void:
	if _buses_ready:
		return
	_buses_ready = true
	var music := _bus("Music")
	_bus("SFX")
	_lowpass = AudioEffectLowPassFilter.new()
	_lowpass.cutoff_hz = 20000.0
	AudioServer.add_bus_effect(music, _lowpass)


func _bus(bus_name: String) -> int:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx == -1:
		AudioServer.add_bus()
		idx = AudioServer.bus_count - 1
		AudioServer.set_bus_name(idx, bus_name)
		AudioServer.set_bus_send(idx, "Master")
	return idx


func play(track: String, volume_db := -6.0) -> void:
	var path := ""
	for p in TRACKS.get(track, []):
		if ResourceLoader.exists(p):
			path = p
			break
	if path == "":
		return
	var pitch: float = PITCH.get(track, 1.0)
	if path == _current and _player.playing:
		create_tween().tween_property(_player, "volume_db", volume_db, 1.0)
		create_tween().tween_property(_player, "pitch_scale", pitch, 1.5)
		return
	_current = path
	_player.stream = _looped(load(path))
	_player.volume_db = volume_db
	_player.pitch_scale = pitch
	_player.play()
	update_bobot(false)


## Mode tanpa filter (layar judul, ending).
func set_bypass(on: bool) -> void:
	_bypass = on
	update_bobot(true)


func update_bobot(animated := true) -> void:
	var t := Bobot.total()
	var cutoff: float = CUTOFFS[clampi(t, 0, CUTOFFS.size() - 1)]
	if _bypass:
		cutoff = 20000.0
	if animated:
		create_tween().tween_property(_lowpass, "cutoff_hz", cutoff, 2.0)
	else:
		_lowpass.cutoff_hz = cutoff


func _on_bobot(_total: int) -> void:
	update_bobot(true)


func fade_out(duration := 2.0) -> void:
	var t := create_tween()
	t.tween_property(_player, "volume_db", -60.0, duration)
	await t.finished
	_player.stop()
	_current = ""


func stop_now() -> void:
	_player.stop()
	_current = ""


func set_volume(bus_name: String, linear: float) -> void:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx != -1:
		AudioServer.set_bus_volume_db(idx, linear_to_db(maxf(linear, 0.0001)))


func _looped(stream: AudioStream) -> AudioStream:
	if stream is AudioStreamOggVorbis:
		(stream as AudioStreamOggVorbis).loop = true
	elif stream is AudioStreamMP3:
		(stream as AudioStreamMP3).loop = true
	elif stream is AudioStreamWAV:
		var w := stream as AudioStreamWAV
		w.loop_mode = AudioStreamWAV.LOOP_FORWARD
		w.loop_end = int(w.get_length() * w.mix_rate)
	return stream
