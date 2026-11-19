class_name Arjuna
extends CharacterBody2D
## Arjuna, wayang yang dimainkan pemain.
##
## Semua kemampuan gerak membaca Bobot: makin berat bawaan, makin pendek lompatan, makin lambat
## langkah, makin bising, makin rendah batas jatuh, dan makin besar serta kabur bayangannya.

signal mati(sebab: String)

const WALK := 95.0
const ACCEL := 900.0
const AIR_ACCEL := 650.0
const FRICTION := 1200.0
const JUMP_V := 360.0
const G_UP := 900.0
const G_DOWN := 1250.0
const MAX_FALL := 460.0
const GLIDE_FALL := 55.0
const COYOTE := 0.1
const BUFFER := 0.12
const CLIMB := 70.0
const BASE_H := 36.0
## Ukuran tabrakan per tingkat bayangan: tipis, sedang, besar.
const HITBOX := [Vector2(10, 24), Vector2(12, 36), Vector2(14, 50)]

var level: Node = null
var facing := 1
var dead := false
var frozen := false
var move_vx := 0.0
var climbing: Area2D = null

var _coyote := 0.0
var _buffer := 0.0
var _step := 0.0
var _was_on_floor := true
var _floor_y := 0.0
var _invuln := 0.0
var _knock := 0.0
var _tier := -1
var _visual_scale := 1.0
var _native_facing := 1
## Bila > 0, skala bayangan dipaksa (ending Kelir Peteng).
var scale_override := 0.0

var _shape: RectangleShape2D
var _shape_node: CollisionShape2D
var _rig: Node2D
var _body: Sprite2D
var _body_mat: ShaderMaterial
var _body_y := 0.0
var _items: Node2D
var _flame: Sprite2D
var _tuding: Line2D
var _sensor: Area2D


func _ready() -> void:
	add_to_group("arjuna")
	collision_layer = 2
	collision_mask = 1 | 16
	floor_snap_length = 4.0
	floor_max_angle = deg_to_rad(50)
	_shape = RectangleShape2D.new()
	_shape_node = CollisionShape2D.new()
	_shape_node.shape = _shape
	add_child(_shape_node)

	_rig = Node2D.new()
	add_child(_rig)
	_tuding = Line2D.new()
	_tuding.width = 1.0
	_tuding.default_color = Art.HITAM
	_tuding.points = PackedVector2Array([Vector2(7, -BASE_H * 0.55), Vector2(9, 6)])
	_rig.add_child(_tuding)
	_body = Art.figure("arjuna", Vector2i(29, 0), BASE_H)
	_body_mat = _body.material as ShaderMaterial
	_body_y = _body.position.y
	_native_facing = Art.arah("arjuna")
	_rig.add_child(_body)
	_items = Node2D.new()
	_rig.add_child(_items)
	_flame = Art.glow(Art.API, 34.0)
	_flame.visible = false
	add_child(_flame)

	_sensor = Area2D.new()
	_sensor.collision_layer = 0
	_sensor.collision_mask = 4 | 8
	_sensor.monitorable = false
	var sshape := CollisionShape2D.new()
	var srect := RectangleShape2D.new()
	srect.size = Vector2(8, 20)
	sshape.shape = srect
	sshape.position = Vector2(0, -10)
	_sensor.add_child(sshape)
	add_child(_sensor)

	Bobot.berubah.connect(_on_bobot)
	_apply_tier(Bobot.tingkat())
	_visual_scale = Bobot.skala_bayangan()
	_rebuild_items()
	_floor_y = global_position.y


# --- bayangan -----------------------------------------------------------------

func tier() -> int:
	return _tier


func height() -> float:
	return _shape.size.y


func center() -> Vector2:
	return global_position + Vector2(0, -_shape.size.y / 2.0)


func _apply_tier(t: int) -> void:
	_tier = t
	var size: Vector2 = HITBOX[t]
	_shape.size = size
	_shape_node.position = Vector2(0, -size.y / 2.0)


## Bayangan hanya membesar bila ada ruang, supaya tidak terjepit di lorong rendah.
func _update_tier() -> void:
	var want := Bobot.tingkat()
	if want == _tier:
		return
	if want < _tier:
		_apply_tier(want)
		return
	var size: Vector2 = HITBOX[want]
	var q := PhysicsShapeQueryParameters2D.new()
	var r := RectangleShape2D.new()
	r.size = size - Vector2(2, 2)
	q.shape = r
	q.transform = Transform2D(0.0, global_position + Vector2(0, -size.y / 2.0 - 1.0))
	q.collision_mask = 1 | 16
	var ex: Array[RID] = [get_rid()]
	q.exclude = ex
	if get_world_2d().direct_space_state.intersect_shape(q, 1).is_empty():
		_apply_tier(want)


func _on_bobot(_total: int) -> void:
	_rebuild_items()


## Barang bawaan tampil menempel di tubuh, jadi pemain tahu isinya tanpa menu.
func _rebuild_items() -> void:
	for c in _items.get_children():
		_items.remove_child(c)
		c.queue_free()
	var emas_i := 0
	for id in Bobot.bawaan:
		var s := Sprite2D.new()
		s.texture = Bobot.icon(id)
		s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		var k := 9.0 / float(s.texture.get_height())
		s.scale = Vector2(k, k)
		var tint := Art.HITAM
		if Bobot.berwarna(id):
			tint = Art.EMAS
		s.material = Art.siluet_material(tint)
		match id:
			"mahkota":
				s.position = Vector2(0, -BASE_H - 3)
			"tameng":
				s.position = Vector2(6, -BASE_H * 0.45)
				s.scale *= 1.3
			"pelita":
				s.position = Vector2(9, -BASE_H * 0.62)
			"selendang":
				s.position = Vector2(-7, -BASE_H * 0.62)
				s.rotation = -0.4
			"terompah":
				s.position = Vector2(0, -2)
				s.scale *= 0.8
			"emas":
				s.position = Vector2(-6, -BASE_H * 0.35 - emas_i * 3.0)
				s.scale *= 0.7
				emas_i += 1
		_items.add_child(s)
	_flame.visible = Bobot.punya("pelita")


# --- gerak --------------------------------------------------------------------

func _physics_process(delta: float) -> void:
	if dead:
		return
	_invuln = maxf(_invuln - delta, 0.0)
	_update_tier()
	if climbing:
		_climb(delta)
		_update_visuals(delta)
		return

	var dir := 0.0
	if not frozen:
		dir = Input.get_axis("move_left", "move_right")
	var speed := WALK * Bobot.lari_mult()

	if _knock > 0.0:
		_knock -= delta
		move_vx = move_toward(move_vx, 0.0, 300.0 * delta)
	elif dir != 0.0:
		var acc := ACCEL if is_on_floor() else AIR_ACCEL
		move_vx = move_toward(move_vx, dir * speed, acc * delta)
		facing = 1 if dir > 0.0 else -1
	else:
		var fr := FRICTION if is_on_floor() else AIR_ACCEL
		move_vx = move_toward(move_vx, 0.0, fr * delta)

	var g := G_UP if velocity.y < 0.0 else G_DOWN
	var max_fall := MAX_FALL
	if Bobot.punya("selendang") and not frozen and Input.is_action_pressed("jump") and velocity.y > 0.0:
		max_fall = GLIDE_FALL
	velocity.y = minf(velocity.y + g * delta, max_fall)

	if is_on_floor():
		_coyote = COYOTE
	else:
		_coyote -= delta
	_buffer -= delta
	if not frozen and Input.is_action_just_pressed("jump"):
		_buffer = BUFFER
	if _buffer > 0.0 and _coyote > 0.0:
		velocity.y = -JUMP_V * sqrt(Bobot.lompat_mult())
		_coyote = 0.0
		_buffer = 0.0
		Sfx.play("lompat", -10.0, 1.2 - 0.04 * Bobot.total())
	if not frozen and Input.is_action_just_released("jump") and velocity.y < 0.0:
		velocity.y *= 0.5

	velocity.x = move_vx + _wind_push()
	move_and_slide()
	if is_on_wall() and _knock <= 0.0:
		move_vx = clampf(move_vx, -speed, speed)

	var on_floor := is_on_floor()
	if on_floor and not _was_on_floor:
		_landed()
	elif on_floor:
		_floor_y = global_position.y
	_was_on_floor = on_floor

	if not frozen:
		if Input.is_action_just_pressed("aksi") and level:
			level.call("try_aksi")
		if Input.is_action_just_pressed("lepas") and level:
			level.call("try_lepas")
		_try_grab_tali()

	_footsteps(delta)
	_update_visuals(delta)
	if level and global_position.y > float(level.get("death_y")):
		die("jatuh")


func _landed() -> void:
	var drop := global_position.y - _floor_y
	_floor_y = global_position.y
	if drop > Bobot.jatuh_aman():
		die("jatuh")
		return
	if drop > 20.0:
		var vol := -14.0 + minf(drop / 8.0, 10.0)
		Sfx.play("mendarat", vol, 1.1 - 0.04 * Bobot.total())
		if level:
			level.call("noise", global_position, Bobot.suara() * 1.2)
	if drop > 40.0:
		Sfx.play("keprak", -12.0)


func _wind_push() -> float:
	if not level:
		return 0.0
	var push := 0.0
	for a in _sensor.get_overlapping_areas():
		if a.is_in_group("angin"):
			push = float(level.call("wind_force"))
			break
	if push != 0.0 and Bobot.punya("selendang"):
		push *= 2.5
	return push


func _try_grab_tali() -> void:
	if climbing or frozen:
		return
	if not (Input.is_action_pressed("move_up") or (Input.is_action_pressed("move_down") and not is_on_floor())):
		return
	for a in _sensor.get_overlapping_areas():
		if a.is_in_group("tali"):
			climbing = a
			velocity = Vector2.ZERO
			move_vx = 0.0
			facing = int(a.get_meta("sisi", 1))
			Sfx.play("tali", -10.0)
			return


func _climb(delta: float) -> void:
	var rope := climbing
	var rx: float = rope.get_meta("x", global_position.x)
	var top: float = rope.get_meta("top", global_position.y)
	global_position.x = move_toward(global_position.x, rx, 120.0 * delta)
	var v := 0.0
	if not frozen:
		v = Input.get_axis("move_up", "move_down") * CLIMB
	velocity = Vector2(0, v)
	move_and_slide()
	_floor_y = global_position.y
	var leave := false
	if not frozen and Input.is_action_just_pressed("jump") and not Input.is_action_pressed("move_up"):
		leave = true
		velocity.y = -200.0 * sqrt(Bobot.lompat_mult())
		move_vx = Input.get_axis("move_left", "move_right") * 80.0
	elif global_position.y - height() <= top and v < 0.0:
		# Sampai di ujung atas: melompat ke atas tebing.
		leave = true
		velocity.y = -300.0
		move_vx = float(facing) * 70.0
	elif is_on_floor() and v > 0.0:
		leave = true
	if leave:
		climbing = null
		_was_on_floor = false


func _footsteps(delta: float) -> void:
	if not is_on_floor() or absf(move_vx) < 10.0:
		_step = 0.0
		return
	_step -= delta
	if _step <= 0.0:
		_step = 0.32
		var t := Bobot.total()
		if Bobot.punya("terompah"):
			Sfx.play("langkah_kayu", -8.0 + t * 0.6, 1.3)
		else:
			Sfx.play("langkah", -20.0 + t * 1.2, 1.0 - t * 0.03)
		if level:
			level.call("noise", global_position, Bobot.suara())


func _update_visuals(delta: float) -> void:
	var target := Bobot.skala_bayangan()
	if scale_override > 0.0:
		_visual_scale = scale_override
	else:
		_visual_scale = move_toward(_visual_scale, target, delta * 1.5)
	_rig.scale = Vector2(_visual_scale, _visual_scale)
	var flip := facing != _native_facing
	_body.flip_h = flip
	_items.scale.x = float(facing)
	_tuding.scale.x = float(facing)
	var screen_blur := (_visual_scale - 1.0) * 4.0
	if _body.scale.y > 0.0:
		_body_mat.set_shader_parameter("blur", screen_blur / (_body.scale.y * _visual_scale))
	var t := Time.get_ticks_msec() / 1000.0
	if climbing:
		_body.position.y = _body_y
		_rig.rotation = sin(t * 8.0) * 0.03
	elif is_on_floor() and absf(move_vx) > 10.0:
		_body.position.y = _body_y - absf(sin(t * 11.0)) * 1.5
		_rig.rotation = sin(t * 11.0) * 0.05
	else:
		_body.position.y = _body_y
		_rig.rotation = lerp_angle(_rig.rotation, 0.06 * float(facing) * signf(velocity.y), 0.2)
	if _invuln > 0.0:
		_rig.modulate.a = 0.5 if int(_invuln * 16.0) % 2 == 0 else 1.0
	else:
		_rig.modulate.a = 1.0
	if _flame.visible:
		_flame.position = Vector2(9.0 * float(facing), -BASE_H * 0.62) * _visual_scale
		var k := 1.0 + sin(t * 9.0) * 0.08 + sin(t * 23.0) * 0.05
		_flame.scale = Vector2.ONE * (34.0 / float(Art.LIGHT_TEX.get_width())) * k


# --- kena, mati, bangkit ------------------------------------------------------

## Diserang (buta, panah, celeng). Tameng menahan satu serangan lalu pecah.
func hit(source: Node2D, bisa_ditahan := true) -> void:
	if dead or _invuln > 0.0:
		return
	if bisa_ditahan and Bobot.punya("tameng"):
		Bobot.hapus("tameng")
		_invuln = 1.2
		_knock = 0.25
		var away := signf(global_position.x - source.global_position.x)
		if away == 0.0:
			away = -float(facing)
		move_vx = away * 120.0
		velocity.y = -150.0
		Sfx.play("tameng_pecah", -2.0)
		Art.burst(get_parent(), center(), Art.API, 12)
		if source.has_method("stun"):
			source.call("stun")
		return
	die("diserang")


## Kebal sesaat (setelah bangkit atau tameng pecah).
func kebal() -> bool:
	return _invuln > 0.0


func die(sebab := "") -> void:
	if dead:
		return
	dead = true
	climbing = null
	Sfx.play("mati", -4.0)
	Art.burst(get_parent(), center(), Art.HITAM, 18, Art.STAR_TEX, 90.0)
	visible = false
	velocity = Vector2.ZERO
	mati.emit(sebab)


func respawn(at: Vector2) -> void:
	global_position = at
	velocity = Vector2.ZERO
	move_vx = 0.0
	_knock = 0.0
	_coyote = 0.0
	_buffer = 0.0
	climbing = null
	dead = false
	frozen = false
	visible = true
	_floor_y = at.y
	_was_on_floor = true
	_invuln = 0.5
	_apply_tier(Bobot.tingkat())
	_visual_scale = Bobot.skala_bayangan()
	_rebuild_items()


func zones() -> Array[Area2D]:
	return _sensor.get_overlapping_areas()


func is_moving() -> bool:
	return absf(move_vx) > 10.0


func set_visual_scale(s: float) -> void:
	_visual_scale = s
	_rig.scale = Vector2(s, s)


func rig() -> Node2D:
	return _rig
