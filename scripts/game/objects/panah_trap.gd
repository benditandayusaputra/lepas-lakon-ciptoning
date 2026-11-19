class_name PanahTrap
extends Node2D
## Jebakan panah di dinding lorong. Panah terbang mendatar setinggi dada.

const INTERVAL := 2.3
const SPEED := 210.0
const HEIGHT := 12.0
## Jarak terbang panah: sepanjang lorong saja, tidak sampai ke jembatan.
const RANGE := 300.0

var arah := -1
var level: Node = null
var _t := 0.8


func _ready() -> void:
	add_to_group("reset")
	var box := Art.rect(Vector2(8, 10), Art.HITAM)
	box.position = Vector2(-4, -HEIGHT - 5)
	add_child(box)


func _physics_process(delta: float) -> void:
	_t -= delta
	if _t <= 0.0:
		_t = float(Game.pilih([2.8, INTERVAL, 2.1]))
		_fire()


func _fire() -> void:
	var p := Panah.new()
	p.level = level
	p.velocity = Vector2(SPEED * float(arah), 0)
	p.life = RANGE / SPEED
	p.position = position + Vector2(0, -HEIGHT)
	get_parent().add_child(p)
	Sfx.play("panah", -10.0, 1.4)


func reset_state() -> void:
	_t = 0.8
