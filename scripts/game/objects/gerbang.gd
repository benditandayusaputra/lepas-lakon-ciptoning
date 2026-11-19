class_name Gerbang
extends StaticBody2D
## Gerbang kayu yang menutup jalan. Jenis "keraton" dibuka prajurit untuk pemakai mahkota,
## jenis "sesaji" terbuka bila Arjuna tidak lagi membawa barang syarat babak itu.

var jenis := "sesaji"
var cells := 4
var is_open := false
var _shape: CollisionShape2D
var _visual: Node2D


func _ready() -> void:
	collision_layer = 1
	collision_mask = 0
	var h := cells * 16.0
	_shape = CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = Vector2(14, h)
	_shape.shape = r
	_shape.position = Vector2(0, -h / 2.0)
	add_child(_shape)
	_visual = Node2D.new()
	add_child(_visual)
	for i in 4:
		var bar := Art.rect(Vector2(2, h), Art.HITAM)
		bar.position = Vector2(-7 + i * 4.0, -h)
		_visual.add_child(bar)
	for j in 3:
		var cross := Art.rect(Vector2(14, 2), Art.HITAM)
		cross.position = Vector2(-7, -h + 6 + j * (h - 12) / 2.0)
		_visual.add_child(cross)


func open() -> void:
	if is_open:
		return
	is_open = true
	_shape.set_deferred("disabled", true)
	Sfx.play("gerbang", -4.0)
	var tw := create_tween()
	tw.tween_property(_visual, "position:y", -cells * 16.0 + 4.0, 1.2).set_trans(Tween.TRANS_SINE)
