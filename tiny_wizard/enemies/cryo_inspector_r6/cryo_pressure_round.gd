extends Area2D


@export var speed := 285.0
@export var damage := 1
@export var lifetime := 2.5
@export var slow_duration := 0.85
@export_range(0.2, 1.0, 0.01) var slow_multiplier := 0.66

var _direction := Vector2.RIGHT
var _finished := false

@onready var sprite := $AnimatedSprite2D as AnimatedSprite2D


func setup(direction: Vector2) -> void:
	if direction.length() > 0.01:
		_direction = direction.normalized()
	rotation = _direction.angle()


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	if sprite != null:
		sprite.animation_finished.connect(_on_animation_finished)


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
		LabStatusEffectController.apply_slow(body, slow_duration, slow_multiplier)
	_finish()


func _finish() -> void:
	if _finished:
		return
	_finished = true
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)
	set_deferred("collision_layer", 0)
	set_deferred("collision_mask", 0)
	if sprite != null:
		sprite.play(&"impact")
	else:
		queue_free()


func _on_animation_finished() -> void:
	if _finished:
		queue_free()


func deflect_by_melee(_deflect_direction := Vector2.ZERO) -> void:
	_finish()
