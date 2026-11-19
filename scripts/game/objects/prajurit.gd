class_name Prajurit
extends Node2D
## Prajurit keraton. Membungkuk dan membuka gerbang bagi pemakai mahkota.

var bowed := false
var _fig: Sprite2D


func _ready() -> void:
	_fig = Art.figure("prajurit", Vector2i(31, 1), 36.0)
	if Art.arah("prajurit") > 0:
		_fig.flip_h = true
	add_child(_fig)
	# Tombak.
	var spear := Art.rect(Vector2(2, 46), Art.HITAM)
	spear.position = Vector2(-12, -46)
	add_child(spear)


func bow() -> void:
	if bowed:
		return
	bowed = true
	Sfx.play("kepyak", -8.0)
	var tw := create_tween()
	tw.tween_property(self, "rotation", -0.35, 0.6).set_trans(Tween.TRANS_SINE)


func refuse() -> void:
	var tw := create_tween()
	tw.tween_property(self, "position:x", position.x + 3.0, 0.08)
	tw.tween_property(self, "position:x", position.x, 0.08)
