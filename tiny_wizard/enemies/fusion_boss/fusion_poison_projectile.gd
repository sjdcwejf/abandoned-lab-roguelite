extends Area2D


@export var speed := 230.0
@export var damage := 1
@export var lifetime := 2.4

var _direction := Vector2.RIGHT
var _has_hit_target := false


func setup(direction: Vector2) -> void:
	if direction.length() > 0.01:
		_direction = direction.normalized()
	rotation = _direction.angle()


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()
		return

	global_position += _direction * speed * delta


func _on_body_entered(body: Node) -> void:
	if _has_hit_target:
		return
	if not body.has_method("hit"):
		return

	_has_hit_target = true
	body.call("hit", damage, _direction)
	queue_free()
