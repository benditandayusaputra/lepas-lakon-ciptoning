class_name Sesaji
extends Node2D
## Sesaji: tempat mempersembahkan barang. Semar duduk di sampingnya tanpa berkata apa-apa.
## Mempersembahkan berarti melepas selamanya, dan sekaligus menjadi pathok.

var final := false
var _glow: Sprite2D
var _t := 0.0


func _ready() -> void:
	add_to_group("sesaji")
	# Meja sesaji: papan dan dua kaki.
	var top := Art.rect(Vector2(26, 3), Art.HITAM)
	top.position = Vector2(-13, -12)
	add_child(top)
	for lx in [-11.0, 8.0]:
		var leg := Art.rect(Vector2(3, 10), Art.HITAM)
		leg.position = Vector2(lx, -10)
		add_child(leg)
	# Mangkuk dan dupa.
	var bowl := Sprite2D.new()
	bowl.texture = Art.icon(38, 11)
	bowl.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	bowl.scale = Vector2(0.7, 0.7)
	bowl.position = Vector2(-4, -18)
	bowl.material = Art.siluet_material(Art.HITAM)
	add_child(bowl)
	var stick := Art.rect(Vector2(1, 9), Art.HITAM)
	stick.position = Vector2(7, -21)
	add_child(stick)
	_glow = Art.glow(Art.API, 60.0 if not final else 110.0)
	_glow.position = Vector2(7, -22)
	add_child(_glow)
	# Semar, pemandu tanpa kata.
	var semar := Art.figure("semar", Vector2i(30, 2), 30.0)
	semar.position.x = -26
	if Art.arah("semar") < 0:
		semar.flip_h = true
	add_child(semar)


func _process(delta: float) -> void:
	_t += delta
	var k := 1.0 + sin(_t * 3.0) * 0.06 + sin(_t * 11.0) * 0.03
	var base := 60.0 if not final else 110.0
	_glow.scale = Vector2.ONE * (base / float(Art.LIGHT_TEX.get_width())) * k


func flash() -> void:
	Art.burst(get_parent(), global_position + Vector2(0, -20), Art.API, 22, Art.SPARK_TEX, 70.0)
	var tw := create_tween()
	tw.tween_property(_glow, "modulate:a", 2.0, 0.15)
	tw.tween_property(_glow, "modulate:a", 1.0, 0.8)
