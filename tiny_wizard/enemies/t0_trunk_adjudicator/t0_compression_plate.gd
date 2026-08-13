extends Area2D


@export var speed := 260.0
@export var damage := 1
var _direction := Vector2.RIGHT
var _finished := false
var _travelled := 0.0


func setup(direction: Vector2) -> void:
	_direction = direction.normalized() if direction.length() > 0.01 else Vector2.RIGHT


func _ready() -> void:
	collision_layer = 4
	collision_mask = 2
	var sprite := get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	if sprite != null:
		sprite.flip_h = _direction.x < 0.0
	body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	if _finished:
		return
	var step := speed * delta
	global_position += _direction * step
	_travelled += step
	if _travelled >= 760.0:
		_finish()


func _on_body_entered(body: Node) -> void:
	if _finished or body == null or not body.has_method("hit"):
		return
	body.call("hit", damage, _direction)


func _finish() -> void:
	if _finished:
		return
	_finished = true
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)
	set_deferred("collision_layer", 0)
	set_deferred("collision_mask", 0)
	queue_free()
