extends Node
## Bot uji otomatis (tidak ikut di build). Menjalankan rencana langkah per babak dan
## mencetak hasilnya. Jalankan: godot --headless --path . -- --babak=1 --bot --keluar=120

const PLANS := {
	1: [["ke", 25.0], ["ke", 42.6], ["lepas"], ["mundur", 26.0], ["ke", 60.0], ["ke", 100.6], ["ke", 116.6], ["ke", 121.6], ["tunggu_panah"], ["ceruk", 125.0], ["ceruk", 131.0], ["ceruk", 137.0], ["ke", 147.0]],
	2: [["ke", 6.6], ["ambil"], ["ke", 27.55], ["lepas"], ["tunggu", 6.0], ["laporan"], ["mundur", 40.0], ["ke", 49.0], ["ke", 53.6], ["tunggu_panah"], ["ceruk", 58.0], ["ceruk", 64.0], ["ceruk", 70.0], ["ke", 77.0], ["lepas"], ["ke", 99.5], ["ke", 103.6], ["tunggu_panah"],
		["ceruk", 108.0], ["ceruk", 114.0], ["ceruk", 120.0], ["ke", 137.0]],
	3: [["ke", 8.6], ["ambil"], ["ke", 22.0], ["layang", 37.0], ["ke", 46.2], ["lepas"], ["panjat"], ["ke", 67.4], ["layang", 0.0], ["ke", 77.4], ["layang", 0.0],
		["ke", 87.4], ["layang", 0.0], ["ke", 105.0]],
	4: [["ke", 50.0, true], ["lempar"], ["ke", 122.6, true], ["lompat_di", 123.0], ["ke", 151.0], ["lompat_di", 152.0], ["ke", 156.0], ["lompat_di", 157.0], ["ke", 166.0]],
	5: [["ke", 25.0], ["ke", 38.2], ["lindung", 45.2], ["lindung", 52.2], ["lindung", 59.2], ["lindung", 66.2], ["lindung", 79.0],
		["ke", 86.7], ["ambil"], ["layang", 0.0], ["ke", 105.2], ["lepas"], ["panjat_tunggu", 15.0], ["lindung", 112.2, true], ["lindung", 125.2],
		["lindung", 133.2], ["lindung", 141.2], ["lindung", 149.2], ["lindung", 160.2], ["lindung", 172.0], ["ke", 192.5], ["lepas"], ["tunggu", 12.0]],
}

var _plan: Array = []
var _i := 0
var _t := 0.0
var _hold_jump := 0.0
var _last_x := 0.0
var _stuck := 0.0
var _babak_start := 0
var _done := false
var _start_mati := 0
var _phase := 0
var _x0 := 0.0
var _pt := 0.0
var _was_dead := false
var _deaths_logged := 0
var _aim_prev := {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_babak_start = Game.babak
	var base: Array = PLANS.get(Game.babak + 1, [])
	if OS.get_cmdline_user_args().has("--uji-nyawa"):
		base = [["ke", 6.6], ["ambil"], ["ke", 77.0], ["tunggu", 60.0]]
	if OS.get_cmdline_user_args().has("--uji-duri"):
		base = [["lepas"], ["ke", 16.0], ["tunggu", 30.0]]
	_plan = base.duplicate(true)
	print("BOT mulai babak %d, %d langkah" % [Game.babak + 1, _plan.size()])


func _player() -> Arjuna:
	var s := get_tree().current_scene
	if s == null or s.name != "Level":
		return null
	return s.get("player")


func _release_all() -> void:
	for a in ["move_left", "move_right", "jump", "aksi", "lepas", "move_up", "move_down"]:
		Input.action_release(a)


func _physics_process(delta: float) -> void:
	if _done:
		return
	if Game.babak != _babak_start or Game.ending != "":
		_finish("SELESAI babak %d -> babak %d ending=%s mati=%d" % [_babak_start + 1, Game.babak + 1, Game.ending, int(Game.stats["mati"]) - _start_mati])
		return
	var p := _player()
	if p == null:
		return
	if _t == 0.0 and _i == 0:
		_start_mati = int(Game.stats["mati"])
	_t += delta
	if p.dead and not _was_dead and _deaths_logged < 8:
		_deaths_logged += 1
		var near := ""
		for b in get_tree().get_nodes_in_group("buta"):
			var bu := b as Buta
			near += " buta(state=%d x=%.1f y=%.0f)" % [bu.state, bu.global_position.x / 16.0, bu.global_position.y]
		print("BOT MATI di x=%.1f y=%.0f vy=%.0f bobot=%d langkah=%d fase=%d t=%.2f%s" % [p.global_position.x / 16.0, p.global_position.y, p.velocity.y, Bobot.total(), _i, _phase, Time.get_ticks_msec() / 1000.0, near])
	_was_dead = p.dead
	if p.dead or bool(get_tree().current_scene.get("ending_busy")):
		_release_all()
		return
	if _hold_jump > 0.0:
		_hold_jump -= delta
		if _hold_jump <= 0.0:
			Input.action_release("jump")
	if _i >= _plan.size():
		_release_all()
		return
	var step: Array = _plan[_i]
	var kind := str(step[0])
	var tile := p.global_position.x / 16.0
	match kind:
		"ke":
			var target := float(step[1])
			if tile >= target:
				Input.action_release("move_right")
				_next(p)
				return
			Input.action_press("move_right")
			if target - tile > 1.0:
				_auto_jump(p)
			_check_stuck(p, delta)
		"mundur":
			if _phase == 0:
				_x0 = p.global_position.x
				_phase = 1
			if p.global_position.x <= _x0 - float(step[1]):
				Input.action_release("move_left")
				_next(p)
				return
			Input.action_press("move_left")
		"lepas", "ambil":
			var act := "lepas" if kind == "lepas" else "aksi"
			Input.action_release("move_right")
			if _t > 0.25:
				Input.action_press(act)
			if _t > 0.35:
				Input.action_release(act)
				_next(p)
		"lempar":
			Input.action_press("move_right")
			Input.action_press("lepas")
			if _t > 0.1:
				Input.action_release("lepas")
				_next(p)
		"laporan":
			for b in get_tree().get_nodes_in_group("buta"):
				var bu := b as Buta
				print("BOT buta state=%d x=%.1f y=%.1f" % [bu.state, bu.global_position.x / 16.0, bu.global_position.y])
			for b in get_tree().get_nodes_in_group("barang"):
				var it := b as Barang
				print("BOT barang %s x=%.1f y=%.1f" % [it.id, it.global_position.x / 16.0, it.global_position.y])
			_next(p)
		"ceruk":
			# Lorong panah: masuk ceruk, tunggu panah lewat di atas kepala, lalu lanjut.
			if _phase == 0:
				if tile >= float(step[1]) - 0.2:
					Input.action_release("move_right")
					_phase = 1
				else:
					Input.action_press("move_right")
					if p.is_on_floor() and p.is_on_wall() and _hold_jump <= 0.0:
						Input.action_press("jump")
						_hold_jump = 0.35
					_check_stuck(p, delta)
			else:
				_pt += delta
				var passed := false
				for a in get_tree().get_nodes_in_group("panah"):
					var ax: float = (a as Node2D).global_position.x
					if ax < p.global_position.x - 4.0 and ax > p.global_position.x - 40.0:
						passed = true
				if (passed and _pt > 0.2) or _pt > 6.0:
					_next(p)
		"lindung":
			# Di balik batu: tunggu Kirata melepas panah, lalu lari ke perlindungan berikutnya.
			if _phase == 0:
				Input.action_release("move_right")
				_pt += delta
				var fired := false
				for k in get_tree().get_nodes_in_group("kirata"):
					var aiming := bool(k.get("_aiming"))
					var key := k.get_instance_id()
					if bool(_aim_prev.get(key, false)) and not aiming and k.get("_target") == p:
						fired = true
					_aim_prev[key] = aiming
				if fired or _pt > 4.0 or (step.size() > 2 and bool(step[2])):
					_phase = 1
					print("BOT lari t=%.2f dari x=%.1f" % [Time.get_ticks_msec() / 1000.0, tile])
			else:
				if tile >= float(step[1]) - 0.2:
					Input.action_release("move_right")
					_next(p)
					return
				Input.action_press("move_right")
				if p.is_on_floor() and p.is_on_wall() and _hold_jump <= 0.0:
					Input.action_press("jump")
					_hold_jump = 0.35
				_check_stuck(p, delta)
		"panjat_tunggu":
			# Panjat sampai tepat di bawah bibir tebing, tunggu panah lewat, lalu naik.
			_pt += delta
			if _phase == 0:
				Input.action_press("move_up")
				if p.climbing:
					_phase = 1
				elif _pt > 6.0:
					_next(p)
			elif _phase == 1:
				if p.global_position.y > float(step[1]) * 16.0:
					Input.action_press("move_up")
				else:
					Input.action_release("move_up")
					_phase = 2
					_pt = 0.0
			elif _phase == 2:
				var fired2 := false
				for k in get_tree().get_nodes_in_group("kirata"):
					var aiming2 := bool(k.get("_aiming"))
					var key2 := k.get_instance_id()
					if bool(_aim_prev.get(key2, false)) and not aiming2 and k.get("_target") == p:
						fired2 = true
					_aim_prev[key2] = aiming2
				if fired2 or _pt > 4.0:
					_phase = 3
			else:
				Input.action_press("move_up")
				if p.climbing == null:
					Input.action_release("move_up")
					_next(p)
		"tunggu_panah":
			# Tunggu panah habis terbang tepat di depan, lalu lari ke ceruk pertama.
			_release_all()
			var dekat := false
			for a in get_tree().get_nodes_in_group("panah"):
				var ax: float = (a as Node2D).global_position.x
				if ax >= p.global_position.x and ax <= p.global_position.x + 80.0:
					dekat = true
			if dekat:
				_phase = 1
			elif _phase == 1 or _t > 6.0:
				_next(p)
		"lompat_di":
			Input.action_press("move_right")
			if tile >= float(step[1]) and p.is_on_floor() and _hold_jump <= 0.0:
				Input.action_press("jump")
				_hold_jump = 0.35
				_next(p)
		"tunggu":
			_release_all()
			if _t > float(step[1]):
				_next(p)
		"layang":
			var lvl := get_tree().current_scene
			if _phase == 0:
				Input.action_release("move_right")
				if bool(lvl.get("_wind_on")) or _t > 5.0:
					Input.action_press("move_right")
					Input.action_press("jump")
					_phase = 1
					_pt = 0.0
			else:
				_pt += delta
				if p.is_on_floor() and _pt > 0.4:
					Input.action_release("jump")
					_next(p)
				elif _pt > 8.0:
					_next(p)
		"panjat":
			_pt += delta
			if _phase == 0:
				Input.action_press("move_up")
				if p.climbing:
					_phase = 1
			elif _phase == 1:
				if p.climbing == null:
					Input.action_release("move_up")
					Input.action_press("move_right")
					_phase = 2
					_pt = 0.0
			elif _pt > 1.0:
				Input.action_release("move_right")
				_next(p)
			if _phase < 2 and _pt > 12.0:
				Input.action_release("move_up")
				_next(p)


func _next(p: Arjuna) -> void:
	print("BOT langkah %d %s selesai, x=%.1f bobot=%d bawaan=%s mati=%d" % [_i, str(_plan[_i]), p.global_position.x / 16.0, Bobot.total(), str(Bobot.bawaan), int(Game.stats["mati"]) - _start_mati])
	_i += 1
	_t = 0.0
	_stuck = 0.0
	_phase = 0
	_pt = 0.0


func _auto_jump(p: Arjuna) -> void:
	if not p.is_on_floor() or _hold_jump > 0.0:
		return
	var need := p.is_on_wall()
	if not need:
		var space := p.get_world_2d().direct_space_state
		var from := p.global_position + Vector2(-3.0 * float(p.facing), -2.0)
		var q := PhysicsRayQueryParameters2D.create(from, from + Vector2(0, 40), 1)
		need = space.intersect_ray(q).is_empty()
	if need:
		Input.action_press("jump")
		_hold_jump = 0.35


func _check_stuck(p: Arjuna, delta: float) -> void:
	if absf(p.global_position.x - _last_x) < 0.5:
		_stuck += delta
	else:
		_stuck = 0.0
	_last_x = p.global_position.x
	if _stuck > 6.0:
		_finish("MACET babak %d di x=%.1f langkah %d bobot=%d bawaan=%s" % [Game.babak + 1, p.global_position.x / 16.0, _i, Bobot.total(), str(Bobot.bawaan)])


func _finish(msg: String) -> void:
	_done = true
	_release_all()
	print("BOT " + msg)
