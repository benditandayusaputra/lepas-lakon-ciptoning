class_name Papan
extends StaticBody2D
## Papan rapuh: patah bila dipijak dengan Bobot 3 ke atas, atau dilewati celeng.

const BREAK_BOBOT := 3

var cells := 1
var broken := false
var _shape: CollisionShape2D
var _visual: Node2D
var _crack := -1.0


func _ready() -> void:
	add_to_group("papan")
	add_to_group("reset")
	collision_layer = 1
	collision_mask = 0
	var w := cells * 16.0
	_shape = CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = Vector2(w, 6)
	_shape.shape = r
	_shape.position = Vector2(w / 2.0, 3)
	add_child(_shape)
	_visual = Node2D.new()
	add_child(_visual)
	for i in cells * 2:
		var plank := Art.rect(Vector2(7, 5), Art.HITAM)
		plank.position = Vector2(i * 8.0 + 0.5, 0.5 + (i % 3) * 0.4)
		_visual.add_child(plank)
	var rope := Art.rect(Vector2(w, 1), Art.HITAM)
	rope.position = Vector2(0, -1)
	_visual.add_child(rope)


func stepped(bobot: int) -> void:
	if broken or _crack >= 0.0:
		return
	if bobot >= int(Game.pilih([4, BREAK_BOBOT, BREAK_BOBOT])):
		_crack = 0.35
		Sfx.play("retak", -2.0)


func smash() -> void:
	if broken:
		return
	_break()


func _physics_process(delta: float) -> void:
	if _crack >= 0.0 and not broken:
		_crack -= delta
		_visual.position.x = sin(_crack * 80.0) * 1.0
		if _crack <= 0.0:
			_break()


func _break() -> void:
	broken = true
	_crack = -1.0
	_shape.set_deferred("disabled", true)
	Sfx.play("patah", 0.0)
	var tw := create_tween().set_parallel()
	tw.tween_property(_visual, "position:y", 120.0, 0.7).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_property(_visual, "modulate:a", 0.0, 0.7)


func reset_state() -> void:
	broken = false
	_crack = -1.0
	_shape.set_deferred("disabled", false)
	_visual.position = Vector2.ZERO
	_visual.modulate.a = 1.0
