extends Area2D


@export var damage := 2
@export var outbound_duration := 0.44
@export var hold_duration := 0.22
@export var return_duration := 0.44

var _origin := Vector2.ZERO
var _direction := Vector2.RIGHT
var _distance := 180.0
var _elapsed := 0.0
var _hit_player := false
var _finished := false

@onready var sprite := $AnimatedSprite2D as AnimatedSprite2D


func setup(origin: Vector2, direction: Vector2, distance := 180.0, new_damage := 2) -> void:
	_origin = origin
	_global_position_after_ready(origin)
	_direction = direction.normalized() if direction.length() > 0.01 else Vector2.RIGHT
	_distance = distance
	damage = new_damage
	if sprite != null:
		sprite.play(&"left" if _direction.x < 0.0 else &"right")


func _global_position_after_ready(value: Vector2) -> void:
	global_position = value


func _ready() -> void:
	z_index = 10
	collision_layer = 4
	collision_mask = 2
	monitoring = true
	body_entered.connect(_on_body_entered)
	if sprite != null:
		sprite.scale = Vector2(1.6, 1.6)
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		sprite.play(&"left" if _direction.x < 0.0 else &"right")


func _physics_process(delta: float) -> void:
	if _finished:
		return
	_elapsed += delta
	if _elapsed < outbound_duration:
		var outbound_ratio := _elapsed / outbound_duration
		global_position = _origin + _direction * _distance * ease(outbound_ratio, 0.72)
		return
	if _elapsed < outbound_duration + hold_duration:
		global_position = _origin + _direction * _distance
		return
	var return_ratio := (_elapsed - outbound_duration - hold_duration) / return_duration
	if return_ratio >= 1.0:
		_finish()
		return
	global_position = _origin + _direction * _distance * (1.0 - ease(return_ratio, 0.72))


func _on_body_entered(body: Node) -> void:
	if _finished or _hit_player:
		return
	if body.has_method("hit"):
		_hit_player = true
		body.call("hit", damage, _direction)


func _finish() -> void:
	if _finished:
		return
	_finished = true
	collision_layer = 0
	collision_mask = 0
	queue_free()
