class_name Kirata
extends Node2D
## Pemburu Kirata: membidik Arjuna dari ketinggian. Garis bidikan terlihat sebelum panah
## dilepas dan batu menghalangi panahnya. Barang berkilau yang tergeletak (mahkota, emas)
## dibidik lebih dulu dan hancur terkena panah: setiap umpan membeli satu tarikan napas.
## Saat Arjuna sudah dekat, busurnya diturunkan: menang tanpa merendahkan.

const AIM := 1.0
const COOL := 1.15
const RANGE := 760.0
const NEAR := 96.0

var level: Node = null
## Jangkauan bidik; Kirata yang menjaga bagian pendek memakai jangkauan lebih dekat.
var jangkau := RANGE
var _aiming := false
var _t := 1.5
var _target: Node2D = null
var _line: Line2D
var _fig: Sprite2D
var _bow: Line2D
var _lowered := false


func _ready() -> void:
	add_to_group("reset")
	add_to_group("kirata")
	_fig = Art.figure("kirata", Vector2i(29, 0), 40.0)
	_fig.flip_h = Art.arah("kirata") > 0
	add_child(_fig)
	_bow = Line2D.new()
	_bow.width = 1.5
	_bow.default_color = Art.HITAM
	var pts := PackedVector2Array()
	for i in 9:
		var a := -PI / 2.0 + PI * float(i) / 8.0
		pts.append(Vector2(-10.0 - cos(a) * 6.0, -24.0 + sin(a) * 12.0))
	_bow.points = pts
	add_child(_bow)
	_line = Line2D.new()
	_line.width = 1.0
	_line.default_color = Color(Art.HITAM, 0.6)
	_line.visible = false
	_line.z_index = 4
	add_child(_line)


func bow_point() -> Vector2:
	return global_position + Vector2(-12, -24)


func reset_state() -> void:
	_aiming = false
	_t = 1.5
	_target = null
	_line.visible = false


func _physics_process(delta: float) -> void:
	if level == null:
		return
	var p: Arjuna = level.get("player")
	if p == null or p.dead or bool(level.get("ending_busy")):
		_line.visible = false
		_aiming = false
		return
	if p.global_position.distance_to(global_position) < NEAR:
		if not _lowered:
			_lowered = true
			_line.visible = false
			_aiming = false
			create_tween().tween_property(_bow, "rotation", 0.9, 0.8)
		return
	if p.global_position.x > global_position.x + 40.0:
		_line.visible = false
		return
	_t -= delta
	if not _aiming:
		if _t <= 0.0:
			_target = _choose(p)
			if _target:
				_aiming = true
				_t = float(Game.pilih([1.4, AIM, 0.85]))
				Sfx.play("tali", -6.0, 0.6)
			else:
				_t = 0.4
		return
	if _target == null or not is_instance_valid(_target) or not _target.is_inside_tree():
		_aiming = false
		_line.visible = false
		_t = 0.5
		return
	var tp := _target_point(_target)
	_line.visible = true
	_line.points = PackedVector2Array([to_local(bow_point()), to_local(tp)])
	_line.default_color = Color(Art.HITAM, 0.35 + 0.4 * absf(sin(_t * 18.0)))
	if _t <= 0.0:
		_fire(tp)
		_aiming = false
		_line.visible = false
		_t = float(Game.pilih([1.5, COOL, 1.0]))


func _choose(p: Arjuna) -> Node2D:
	var best: Node2D = null
	var best_d := jangkau
	for b in get_tree().get_nodes_in_group("barang"):
		var item := b as Barang
		if item == null or not item.dari_pemain or not Bobot.berwarna(item.id):
			continue
		var d := item.global_position.distance_to(global_position)
		if d < best_d and item.global_position.x <= global_position.x + 40.0:
			best = item
			best_d = d
	if best:
		return best
	if p.global_position.distance_to(global_position) > jangkau:
		return null
	return p


func _target_point(t: Node2D) -> Vector2:
	if t is Arjuna:
		return (t as Arjuna).center()
	return t.global_position + Vector2(0, -5)


func _fire(tp: Vector2) -> void:
	if Game.debug_bot:
		print("KIRATA %d tembak t=%.2f" % [int(position.x / 16.0), Time.get_ticks_msec() / 1000.0])
	Sfx.play("panah", -2.0, 1.6)
	var space := get_world_2d().direct_space_state
	var q := PhysicsRayQueryParameters2D.create(bow_point(), tp, 1)
	var hit := space.intersect_ray(q)
	_tracer(bow_point(), tp if hit.is_empty() else hit["position"])
	if not hit.is_empty():
		var hp: Vector2 = hit["position"]
		Art.burst(get_parent(), hp, Art.API, 6, Art.SPARK_TEX, 40.0)
		Sfx.play("panah", -8.0, 0.8)
		return
	if _target is Arjuna:
		(_target as Arjuna).hit(self)
	else:
		Art.burst(get_parent(), tp, Art.EMAS, 14, Art.SPARK_TEX, 60.0)
		Sfx.play("kepyak", -6.0, 1.3)
		Sfx.play("tameng_pecah", -10.0, 1.4)
		_target.queue_free()
		_target = null


## Jejak panah sekilas supaya tembakan terbaca.
func _tracer(from: Vector2, to: Vector2) -> void:
	var par := get_parent() as Node2D
	if par == null:
		return
	var l := Line2D.new()
	l.width = 1.6
	l.default_color = Art.HITAM
	l.points = PackedVector2Array([par.to_local(from), par.to_local(to)])
	l.z_index = 4
	par.add_child(l)
	var tw := l.create_tween()
	tw.tween_property(l, "modulate:a", 0.0, 0.3)
	tw.tween_callback(l.queue_free)
