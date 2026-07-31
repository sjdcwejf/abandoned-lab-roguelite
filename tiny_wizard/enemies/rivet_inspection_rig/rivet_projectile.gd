extends Area2D


@export var speed := 315.0
@export var damage := 1
@export var lifetime := 1.8

var _direction := Vector2.RIGHT
var _finished := false

@onready var sprite := $AnimatedSprite2D as AnimatedSprite2D


func setup(direction: Vector2) -> void:
	if direction.length() > 0.01:
		_direction = direction.normalized()
	if sprite != null:
		sprite.play(&"left" if _direction.x < 0.0 else &"right")


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	if sprite != null:
		sprite.play(&"left" if _direction.x < 0.0 else &"right")


func _physics_process(delta: float) -> void:
	if _finished:
		return
	lifetime -= delta
	if lifetime <= 0.0:
		_finish()
		return
	global_position += _direction * speed * delta


func _on_body_entered(body: Node) -> void:
	if _finished:
		return
	if body.has_method("hit"):
		body.call("hit", damage, _direction)
	_finish()


func _finish() -> void:
	if _finished:
		return
	_finished = true
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)
	set_deferred("collision_layer", 0)
	set_deferred("collision_mask", 0)
	queue_free()


func deflect_by_melee(_deflect_direction := Vector2.ZERO) -> void:
	_finish()
