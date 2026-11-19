class_name Buta
extends CharacterBody2D
## Buta: raksasa prajurit Niwatakawaca.
##
## Tidur sampai mendengar langkah atau melihat cahaya. Saat bangun ia berpatroli, mengejar bila
## melihat Arjuna, atau berjalan ke pelita yang tergeletak lalu terpesona di sana.
## Jarak pandangnya bergantung pada besar bayangan Arjuna.

enum S { TIDUR, PATROLI, KEJAR, TERPESONA, PINGSAN }

const PATROL_V := 32.0
const CHASE_V := 92.0
const LURE_V := 46.0
const GRAV := 1200.0
## Pelita yang dibawa membangunkan dari dekat, pelita yang ditaruh menyala tenang dan memanggil dari jauh.
const WAKE_CARRIED := 120.0
const WAKE_DROPPED := 200.0
const LURE_RANGE := 340.0
const PATROL_RANGE := 64.0
const SIZE := Vector2(22, 42)

var level: Node = null
var start_sleeping := false
var state := S.PATROLI
var home := Vector2.ZERO
var facing := -1

var _start := Vector2.ZERO
var _wait := 0.0
var _lost := 0.0
var _stun := 0.0
var _lure: Node2D = null
var _fig: Sprite2D
var _eye: Sprite2D
var _hit: Area2D
var _t := 0.0


func _ready() -> void:
	add_to_group("buta")
	add_to_group("reset")
	collision_layer = 32
	collision_mask = 1
	floor_snap_length = 4.0
	var cs := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = SIZE
	cs.shape = r
	cs.position = Vector2(0, -SIZE.y / 2.0)
	add_child(cs)
	_fig = Art.figure("buta", Vector2i(30, 8), 48.0)
	add_child(_fig)
	_eye = Art.glow(Color(1.0, 0.45, 0.2), 10.0)
	_eye.position = Vector2(-6, -38)
	add_child(_eye)
	_hit = Area2D.new()
	_hit.collision_layer = 0
	_hit.collision_mask = 2
	var hs := CollisionShape2D.new()
	var hr := RectangleShape2D.new()
	hr.size = SIZE - Vector2(4, 6)
	hs.shape = hr
	hs.position = Vector2(0, -SIZE.y / 2.0 + 2.0)
	_hit.add_child(hs)
	add_child(_hit)
	_start = position
	home = position
	state = S.TIDUR if start_sleeping else S.PATROLI


func reset_state() -> void:
	position = _start
	home = _start
	velocity = Vector2.ZERO
	facing = -1
	_lure = null
	_wait = 0.0
	_stun = 0.0
	_lost = 0.0
	state = S.TIDUR if start_sleeping else S.PATROLI


## Suara langkah atau benda jatuh di dekatnya.
func hear(pos: Vector2, radius: float) -> void:
	radius *= float(Game.pilih([0.8, 1.0, 1.25]))
	if state != S.TIDUR:
		return
	if global_position.distance_to(pos) <= radius:
		_wake(pos)


func _wake(toward: Vector2) -> void:
	state = S.PATROLI
	home = global_position
	facing = 1 if toward.x > global_position.x else -1
	_wait = 0.7
	Sfx.play("geram", -2.0, 0.55)
	Sfx.play("buta", -10.0, 0.6)


func stun() -> void:
	state = S.PINGSAN
	_stun = 2.0
	velocity.x = 0.0


func _physics_process(delta: float) -> void:
	_t += delta
	velocity.y = minf(velocity.y + GRAV * delta, 500.0)
	var vx := 0.0
	match state:
		S.TIDUR:
			_check_light_wake()
		S.PINGSAN:
			_stun -= delta
			if _stun <= 0.0:
				state = S.PATROLI
				home = global_position
		S.PATROLI:
			vx = _patrol(delta)
		S.KEJAR:
			vx = _chase(delta)
		S.TERPESONA:
			vx = _lured()
	if _wait > 0.0:
		_wait -= delta
		vx = 0.0
	velocity.x = vx
	move_and_slide()
	_check_contact()
	_update_visual()
	if level and global_position.y > float(level.get("death_y")) + 100.0:
		set_physics_process(false)
		visible = false


func _check_light_wake() -> void:
	if not level:
		return
	var p: Arjuna = level.get("player")
	if p and not p.dead and Bobot.punya("pelita"):
		if global_position.distance_to(p.center()) <= WAKE_CARRIED * float(Game.pilih([0.8, 1.0, 1.25])):
			_wake(p.center())
			return
	for b in get_tree().get_nodes_in_group("cahaya"):
		var n := b as Node2D
		if n and global_position.distance_to(n.global_position) <= WAKE_DROPPED:
			_wake(n.global_position)
			return


func _find_lure() -> Node2D:
	if not level:
		return null
	var best: Node2D = null
	var best_d := LURE_RANGE
	for b in get_tree().get_nodes_in_group("cahaya"):
		var n := b as Node2D
		if n == null or not n.is_inside_tree():
			continue
		var d := global_position.distance_to(n.global_position)
		if d < best_d:
			best_d = d
			best = n
	return best


func _patrol(_delta: float) -> float:
	var lure := _find_lure()
	if lure:
		_lure = lure
		state = S.TERPESONA
		return 0.0
	if _sees_player():
		state = S.KEJAR
		_lost = 0.0
		Sfx.play("geram", 0.0, 0.5)
		return 0.0
	if global_position.x > home.x + PATROL_RANGE:
		facing = -1
	elif global_position.x < home.x - PATROL_RANGE:
		facing = 1
	if is_on_wall() or not _floor_ahead():
		facing = -facing
		_wait = 0.5
		return 0.0
	return PATROL_V * float(facing)


func _chase(delta: float) -> float:
	var p: Arjuna = level.get("player")
	if p == null or p.dead:
		state = S.PATROLI
		home = global_position
		return 0.0
	if _sees_player():
		_lost = 0.0
	else:
		_lost += delta
		var lure := _find_lure()
		if lure:
			_lure = lure
			state = S.TERPESONA
			return 0.0
		if _lost > 1.6:
			state = S.PATROLI
			home = global_position
			return 0.0
	facing = 1 if p.global_position.x > global_position.x else -1
	if not _floor_ahead():
		return 0.0
	return CHASE_V * float(facing)


func _lured() -> float:
	if _lure == null or not is_instance_valid(_lure) or not _lure.is_inside_tree():
		_lure = null
		state = S.PATROLI
		home = global_position
		return 0.0
	var dx := _lure.global_position.x - global_position.x
	if absf(dx) < 12.0:
		return 0.0
	facing = 1 if dx > 0.0 else -1
	var below := _lure.global_position.y > global_position.y + 8.0
	if not _floor_ahead() and not below:
		return 0.0
	return LURE_V * float(facing)


func _floor_ahead() -> bool:
	var space := get_world_2d().direct_space_state
	var from := global_position + Vector2(14.0 * float(facing), -4.0)
	var q := PhysicsRayQueryParameters2D.create(from, from + Vector2(0, 24), 1)
	return not space.intersect_ray(q).is_empty()


func _sees_player() -> bool:
	if not level:
		return false
	var p: Arjuna = level.get("player")
	if p == null or p.dead:
		return false
	var dx := p.global_position.x - global_position.x
	if absf(dx) > 18.0 and signf(dx) != float(facing):
		return false
	var dist := absf(dx)
	var vision: float = level.call("vision_range")
	if state == S.TERPESONA:
		vision = 24.0
	if dist > vision:
		return false
	if absf(p.global_position.y - global_position.y) > 60.0:
		return false
	var space := get_world_2d().direct_space_state
	var q := PhysicsRayQueryParameters2D.create(global_position + Vector2(0, -36), p.center(), 1)
	return space.intersect_ray(q).is_empty()


func _check_contact() -> void:
	if state == S.PINGSAN:
		return
	for b in _hit.get_overlapping_bodies():
		if b is Arjuna:
			if state == S.TIDUR:
				_wake(b.global_position)
			(b as Arjuna).hit(self)


func _update_visual() -> void:
	_fig.flip_h = facing != Art.arah("buta")
	_eye.position.x = 6.0 * float(facing)
	match state:
		S.TIDUR:
			_eye.visible = false
			_fig.rotation = 0.0
			_fig.scale.y = absf(_fig.scale.x) * (0.96 + 0.02 * sin(_t * 1.6))
		S.PINGSAN:
			_eye.visible = false
			_fig.rotation = 0.25 * float(-facing)
		S.KEJAR:
			_eye.visible = true
			_fig.rotation = 0.12 * float(facing) + sin(_t * 14.0) * 0.04
			_fig.scale.y = absf(_fig.scale.x)
		_:
			_eye.visible = true
			_fig.rotation = sin(_t * 5.0) * 0.03
			_fig.scale.y = absf(_fig.scale.x)
