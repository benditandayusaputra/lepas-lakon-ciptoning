class_name Panah
extends Area2D
## Anak panah. Hilang saat mengenai tanah atau setelah terbang jauh.

var velocity := Vector2.ZERO
var level: Node = null
var life := 3.0


func _ready() -> void:
	add_to_group("panah")
	collision_layer = 4
	collision_mask = 1 | 2
	var cs := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = Vector2(12, 2)
	cs.shape = r
	add_child(cs)
	var line := Line2D.new()
	line.width = 1.5
	line.default_color = Art.HITAM
	line.points = PackedVector2Array([Vector2(-8, 0), Vector2(8, 0)])
	add_child(line)
	var tip := Art.rect(Vector2(3, 3), Art.HITAM, true)
	tip.position = Vector2(8.0, 0)
	add_child(tip)
	if velocity.x < 0.0:
		scale.x = -1.0
	body_entered.connect(_on_body)


func _physics_process(delta: float) -> void:
	position += velocity * delta
	life -= delta
	if life <= 0.0:
		queue_free()


func _on_body(body: Node) -> void:
	if body is Arjuna:
		(body as Arjuna).hit(self)
		queue_free()
	elif body is TileMapLayer or body is StaticBody2D:
		Sfx.play("panah", -14.0, 0.8)
		queue_free()
