class_name Barang
extends CharacterBody2D
## Barang yang tergeletak di dunia.
##
## Barang yang dilepas tidak hilang: ia jatuh ke dunia dan menjadi alat. Tameng menjadi pijakan,
## pelita menjadi umpan cahaya, selendang menjadi tali, terompah menjadi pengalih bunyi.
## Titik asal node ada di dasar barang.

const GRAV := 1100.0
const SIZES := {
	"tameng": Vector2(18, 16),
	"mahkota": Vector2(12, 10),
	"pelita": Vector2(8, 12),
	"selendang": Vector2(10, 8),
	"terompah": Vector2(10, 6),
	"emas": Vector2(8, 8),
}

var id := ""
var level: Node = null
var tied := false
var anchor := Vector2.ZERO
var thrown := false
## Dilepas oleh Arjuna (bukan barang bawaan peta): bisa menjadi umpan Kirata.
var dari_pemain := false

var _size := Vector2(8, 8)
var _sprite: Sprite2D
var _glow: Sprite2D
var _solid_pending := false
var _tali_line: Line2D
var _t := 0.0


func setup(item_id: String, lvl: Node) -> void:
	id = item_id
	level = lvl


func _ready() -> void:
	add_to_group("barang")
	_size = SIZES.get(id, Vector2(8, 8))
	collision_layer = 0
	collision_mask = 1
	floor_snap_length = 2.0
	var shape := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = _size
	shape.shape = r
	shape.position = Vector2(0, -_size.y / 2.0)
	add_child(shape)

	_sprite = Sprite2D.new()
	_sprite.texture = Bobot.icon(id)
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var k := (_size.y + 4.0) / float(_sprite.texture.get_height())
	_sprite.scale = Vector2(k, k)
	_sprite.position = Vector2(0, -(_size.y + 4.0) / 2.0 + 2.0)
	var tint := Art.HITAM
	if Bobot.berwarna(id):
		tint = Art.EMAS
	_sprite.material = Art.siluet_material(tint)
	add_child(_sprite)

	if id == "pelita":
		add_to_group("cahaya")
		_glow = Art.glow(Art.API, 70.0)
		_glow.position = Vector2(0, -_size.y)
		add_child(_glow)
	elif Bobot.berwarna(id):
		_glow = Art.glow(Art.EMAS, 26.0)
		_glow.position = Vector2(0, -_size.y / 2.0)
		add_child(_glow)

	if id == "tameng":
		_solid_pending = true
	if tied:
		_make_tali()


func is_light() -> bool:
	return id == "pelita" and not tied


func _physics_process(delta: float) -> void:
	_t += delta
	if _glow:
		var base := 70.0 if id == "pelita" else 26.0
		var flick := 1.0 + sin(_t * 9.0) * 0.08 + sin(_t * 21.0 + 1.7) * 0.05
		if Bobot.berwarna(id):
			flick = 0.8 + 0.35 * maxf(0.0, sin(_t * 2.3))
		_glow.scale = Vector2.ONE * (base / float(Art.LIGHT_TEX.get_width())) * flick
	if tied:
		return
	velocity.y = minf(velocity.y + GRAV * delta, 500.0)
	if is_on_floor():
		velocity.x = move_toward(velocity.x, 0.0, 700.0 * delta)
	move_and_slide()
	if thrown and is_on_floor():
		thrown = false
		_on_land()
	if _solid_pending and not _overlaps_arjuna():
		_solid_pending = false
		collision_layer = 16
	if level and global_position.y > float(level.get("death_y")) + 200.0:
		queue_free()


func _on_land() -> void:
	if not level:
		return
	if id == "terompah":
		Sfx.play("langkah_kayu", 2.0, 0.8)
		Sfx.play("keprak", -6.0, 0.9)
		level.call("noise", global_position, 240.0)
		level.call("item_landed", self)
	else:
		Sfx.play("lepas", -6.0)
		level.call("noise", global_position, 60.0)
		level.call("item_landed", self)


func rect() -> Rect2:
	return Rect2(global_position - Vector2(_size.x / 2.0, _size.y), _size)


func _overlaps_arjuna() -> bool:
	if not level:
		return false
	var p: Arjuna = level.get("player")
	if p == null or p.dead:
		return false
	var w: float = Arjuna.HITBOX[p.tier()].x
	var pr := Rect2(p.global_position.x - w / 2.0, p.global_position.y - p.height(), w, p.height())
	return pr.intersects(rect().grow(1.0))


## Selendang yang dilempar ke dahan: tergantung menjadi tali panjat.
func tie_to(anchor_pos: Vector2, rope_len: float, side: int) -> void:
	tied = true
	anchor = anchor_pos
	set_meta("len", rope_len)
	set_meta("sisi", side)
	velocity = Vector2.ZERO
	collision_mask = 0
	global_position = anchor_pos
	if is_inside_tree():
		_make_tali()


func _make_tali() -> void:
	var rope_len: float = get_meta("len", 112.0)
	var side: int = get_meta("sisi", 1)
	_sprite.position = Vector2(0, 0)
	_tali_line = Line2D.new()
	_tali_line.width = 2.5
	_tali_line.default_color = Art.HITAM
	var pts := PackedVector2Array()
	var n := 10
	for i in n + 1:
		var y := rope_len * float(i) / float(n)
		pts.append(Vector2(sin(float(i) * 0.9) * 1.5, y))
	_tali_line.points = pts
	add_child(_tali_line)
	var area := Area2D.new()
	area.add_to_group("tali")
	area.collision_layer = 8
	area.collision_mask = 0
	area.monitoring = false
	var cs := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = Vector2(24, rope_len)
	cs.shape = r
	cs.position = Vector2(0, rope_len / 2.0)
	area.add_child(cs)
	area.set_meta("x", global_position.x)
	area.set_meta("top", global_position.y)
	area.set_meta("sisi", side)
	add_child(area)


func snapshot() -> Dictionary:
	return {
		"id": id,
		"pos": global_position,
		"tied": tied,
		"len": get_meta("len", 0.0),
		"sisi": get_meta("sisi", 1),
		"dari_pemain": dari_pemain,
	}
