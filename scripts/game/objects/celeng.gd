class_name Celeng
extends CharacterBody2D
## Celeng Mamangmurka: babi hutan raksasa yang mengejar Arjuna di babak 4.
## Sedikit lebih cepat dari Arjuna yang membawa Bobot 3. Menjebol papan rapuh, tertahan di
## mulut lorong rendah, dan berhenti sejenak mengendus barang yang dilempar ke jalurnya.

const SIZE := Vector2(40, 40)
const SPEED := 88.0
const CATCHUP := 160.0
const FAR := 170.0
const GRAV := 1300.0

var level: Node = null
var active := false
var _sniff := 0.0
var _sniff_x := -1.0
var _respawn := -1.0
var _fig: Sprite2D
var _eye: Sprite2D
var _dust: CPUParticles2D
var _t := 0.0


func _ready() -> void:
	add_to_group("reset")
	collision_layer = 32
	collision_mask = 1
	floor_snap_length = 6.0
	var cs := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = SIZE
	cs.shape = r
	cs.position = Vector2(0, -SIZE.y / 2.0)
	add_child(cs)
	_fig = Art.figure("celeng", Vector2i(29, 7), 54.0)
	_fig.flip_h = Art.arah("celeng") < 0
	add_child(_fig)
	_eye = Art.glow(Color(1.0, 0.4, 0.15), 12.0)
	_eye.position = Vector2(30, -36)
	add_child(_eye)
	_dust = CPUParticles2D.new()
	_dust.texture = Art.SMOKE_TEX
	_dust.amount = 10
	_dust.lifetime = 0.7
	_dust.direction = Vector2(-1, -0.5)
	_dust.spread = 30.0
	_dust.initial_velocity_min = 20.0
	_dust.initial_velocity_max = 50.0
	_dust.scale_amount_min = 0.03
	_dust.scale_amount_max = 0.06
	_dust.color = Color(Art.HITAM, 0.35)
	_dust.position = Vector2(-16, -2)
	_dust.emitting = false
	add_child(_dust)
	visible = false


func start_chase(pos: Vector2) -> void:
	global_position = pos
	velocity = Vector2.ZERO
	active = true
	visible = true
	modulate.a = 1.0
	_sniff = 0.0
	_sniff_x = -1.0
	_dust.emitting = true
	Sfx.play("geram", 4.0, 0.35)
	Sfx.play("keprak", -2.0, 0.7)


func stop_chase() -> void:
	active = false
	_dust.emitting = false
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 1.5)
	tw.tween_callback(_hide)


func _hide() -> void:
	visible = false


func reset_state() -> void:
	active = false
	visible = false
	_respawn = -1.0
	_dust.emitting = false
	velocity = Vector2.ZERO
	global_position = Vector2(-500, -500)


## Barang yang dilempar ke depan celeng membuatnya berhenti mengendus.
func on_item(item: Node2D) -> void:
	if not active:
		return
	var dx := item.global_position.x - global_position.x
	if dx > -10.0 and dx < 320.0:
		_sniff_x = item.global_position.x


func _physics_process(delta: float) -> void:
	_t += delta
	if _respawn >= 0.0:
		_respawn -= delta
		if _respawn < 0.0:
			_come_back()
		return
	if not active:
		return
	var p: Arjuna = level.get("player")
	if p == null:
		return
	velocity.y = minf(velocity.y + GRAV * delta, 600.0)
	var speed := float(Game.pilih([80.0, SPEED, 93.0]))
	if p.global_position.x - global_position.x > FAR:
		speed = CATCHUP
	if _sniff_x >= 0.0 and absf(global_position.x - _sniff_x) < 14.0:
		_sniff = 0.9
		_sniff_x = -1.0
		Sfx.play("geram", -6.0, 0.8)
	if _sniff > 0.0:
		_sniff -= delta
		speed = 0.0
	velocity.x = speed
	if is_on_wall() and is_on_floor():
		velocity.y = -340.0
	move_and_slide()
	for i in get_slide_collision_count():
		var col := get_slide_collision(i).get_collider()
		if col is Papan:
			(col as Papan).smash()
	if not p.dead:
		var r := Rect2(global_position - Vector2(SIZE.x / 2.0, SIZE.y), SIZE).grow(-3.0)
		var w: float = Arjuna.HITBOX[p.tier()].x
		var pr := Rect2(p.global_position.x - w / 2.0, p.global_position.y - p.height(), w, p.height())
		if r.intersects(pr):
			p.hit(self, false)
	if global_position.y > float(level.get("death_y")):
		_respawn = 1.2
		visible = false
	_fig.rotation = sin(_t * 18.0) * 0.05
	_fig.position.y = -27.0 - absf(sin(_t * 18.0)) * 2.0


func _come_back() -> void:
	var p: Arjuna = level.get("player")
	if p == null or not active:
		return
	visible = true
	global_position = Vector2(p.global_position.x - 260.0, p.global_position.y - 30.0)
	velocity = Vector2.ZERO
	Sfx.play("geram", 2.0, 0.4)
