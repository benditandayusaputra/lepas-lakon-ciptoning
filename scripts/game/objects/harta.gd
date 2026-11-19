class_name Harta
extends Node2D
## Harta di puncak: godaan terakhir. Berkilau, dan tombol Aksi bekerja seperti biasa.

var _glows: Array[Sprite2D] = []
var _t := 0.0


func _ready() -> void:
	add_to_group("harta")
	var spots := [Vector2(-10, -4), Vector2(0, -6), Vector2(10, -4), Vector2(-5, -12), Vector2(5, -12), Vector2(0, -18)]
	for p in spots:
		var s := Sprite2D.new()
		s.texture = Art.icon(41, 3)
		s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		s.scale = Vector2(0.75, 0.75)
		s.position = p
		s.material = Art.siluet_material(Art.EMAS)
		add_child(s)
	var crown := Sprite2D.new()
	crown.texture = Art.icon(44, 2)
	crown.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	crown.position = Vector2(0, -27)
	crown.material = Art.siluet_material(Art.EMAS)
	add_child(crown)
	for i in 3:
		var g := Art.glow(Art.EMAS, 50.0)
		g.position = Vector2(-10 + i * 10, -14)
		add_child(g)
		_glows.append(g)


func _process(delta: float) -> void:
	_t += delta
	for i in _glows.size():
		var k := 0.7 + 0.4 * maxf(0.0, sin(_t * 2.1 + i * 1.7))
		_glows[i].scale = Vector2.ONE * (50.0 / float(Art.LIGHT_TEX.get_width())) * k
	if randf() < delta * 1.5:
		Art.burst(get_parent(), global_position + Vector2(randf_range(-12, 12), randf_range(-24, -4)), Art.EMAS_TERANG, 2, Art.SPARK_TEX, 20.0)
