class_name Chapter5LinearProjectile
extends Area2D


@export var speed := 320.0
@export var damage := 1
@export var lifetime := 1.8

var _direction := Vector2.RIGHT
var _finished := false
var _hit_ids := {}

@onready var sprite := $Sprite2D as Sprite2D


func setup(direction: Vector2, new_damage := -1, new_speed := -1.0) -> void:
	if direction.length() > 0.01:
		_direction = direction.normalized()
	if new_damage > 0:
		damage = new_damage
	if new_speed > 0.0:
		speed = new_speed
	if sprite != null:
		sprite.rotation = _direction.angle()


func _ready() -> void:
	collision_layer = 4
	collision_mask = 2
	monitoring = true
	body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	if _finished:
		return
	lifetime -= delta
	if lifetime <= 0.0:
		_finish()
		return
	global_position += _direction * speed * delta


func _on_body_entered(body: Node) -> void:
	if _finished or body == null or not body.has_method("hit"):
		return
	var id := body.get_instance_id()
	if _hit_ids.has(id):
		return
	_hit_ids[id] = true
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
