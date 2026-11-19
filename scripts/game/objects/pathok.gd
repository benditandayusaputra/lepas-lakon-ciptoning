class_name Pathok
extends Node2D
## Pathok: tonggak kayu tempat Arjuna bangkit lagi setelah mati.

var active := false
var _flame: Sprite2D


func _ready() -> void:
	add_to_group("pathok")
	var post := Art.rect(Vector2(3, 20), Art.HITAM)
	post.position = Vector2(-1.5, -20)
	add_child(post)
	var cap := Art.rect(Vector2(7, 3), Art.HITAM)
	cap.position = Vector2(-3.5, -21)
	add_child(cap)
	_flame = Art.glow(Art.API, 22.0)
	_flame.position = Vector2(0, -24)
	_flame.modulate.a = 0.0
	add_child(_flame)


func activate() -> void:
	if active:
		return
	active = true
	Sfx.play("pathok", -14.0)
	create_tween().tween_property(_flame, "modulate:a", 1.0, 0.6)
