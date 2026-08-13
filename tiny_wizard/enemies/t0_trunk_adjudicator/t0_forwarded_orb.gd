extends Area2D


@export var speed := 260.0
@export var damage := 1

var _start := Vector2.ZERO
var _relay := Vector2.ZERO
var _target := Vector2.ZERO
var _elapsed := 0.0
var _finished := false
var _hit_player := false


func setup(start: Vector2, relay: Vector2, target: Vector2) -> void:
	_start = start
	_relay = relay
	_target = target


func _ready() -> void:
	collision_layer = 4
	collision_mask = 2
	global_position = _start
	body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	if _finished:
		return
	_elapsed += delta
	var first_distance := _start.distance_to(_relay)
	var second_distance := _relay.distance_to(_target)
	var total_distance := maxf(1.0, first_distance + second_distance)
	var first_duration := first_distance / speed
	var total_duration := total_distance / speed
	if _elapsed >= total_duration:
		_finish()
		return
	if _elapsed < first_duration:
		global_position = _start.lerp(_relay, _elapsed / maxf(0.01, first_duration))
	else:
		global_position = _relay.lerp(_target, (_elapsed - first_duration) / maxf(0.01, total_duration - first_duration))


func _on_body_entered(body: Node) -> void:
	if _finished or _hit_player or body == null or not body.has_method("hit"):
		return
	_hit_player = true
	body.call("hit", damage, global_position.direction_to(body.global_position))


func _finish() -> void:
	if _finished:
		return
	_finished = true
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)
	set_deferred("collision_layer", 0)
	set_deferred("collision_mask", 0)
	queue_free()
