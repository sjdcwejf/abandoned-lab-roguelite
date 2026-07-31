extends ProtomatterDropEnemy


const RIVET_PROJECTILE_SCENE := preload("res://tiny_wizard/enemies/rivet_inspection_rig/rivet_projectile.tscn")

@export var burst_warning_length := 360.0
@export var muzzle_offset := Vector2(34.0, -38.0)

var _burst_direction := Vector2.RIGHT

@onready var body_sprite := $Visual/BodySprite as AnimatedSprite2D


func _ready() -> void:
	super._ready()
	set_meta("exosuit_enemy", true)


func set_speed_multiplier(multiplier: float) -> void:
	if physics_stats != null:
		physics_stats.max_speed = 62.0 * multiplier


func play_idle() -> void:
	if body_sprite != null and body_sprite.animation != &"idle":
		body_sprite.play(&"idle")


func play_windup(direction: Vector2, duration: float) -> void:
	_burst_direction = _normalized_direction(direction)
	if body_sprite != null:
		body_sprite.play(&"burst_left" if _burst_direction.x < 0.0 else &"burst_right")
		body_sprite.frame = 0
		body_sprite.pause()
	_spawn_line_warning(_burst_direction, burst_warning_length, 4.0, Color(1.0, 0.62, 0.28, 0.72), duration)


func begin_burst(direction: Vector2) -> void:
	_burst_direction = _normalized_direction(direction)
	if body_sprite != null:
		body_sprite.play(&"burst_left" if _burst_direction.x < 0.0 else &"burst_right")


func fire_rivet(target_position: Vector2) -> void:
	var effect_parent := _get_drop_parent()
	if effect_parent == null:
		return
	var offset := muzzle_offset
	if _burst_direction.x < 0.0:
		offset.x = -absf(offset.x)
	else:
		offset.x = absf(offset.x)
	var origin := global_position + offset
	var direction := origin.direction_to(target_position)
	if direction.length() < 0.01:
		direction = _burst_direction
	var projectile := RIVET_PROJECTILE_SCENE.instantiate() as Node2D
	if projectile == null:
		return
	if effect_parent is Node2D:
		projectile.position = (effect_parent as Node2D).to_local(origin)
	else:
		projectile.global_position = origin
	projectile.call("setup", direction)
	effect_parent.add_child(projectile)


func finish_attack() -> void:
	play_idle()


func _normalized_direction(direction: Vector2) -> Vector2:
	var normalized := direction.normalized()
	if normalized.length() < 0.01:
		normalized = Vector2.RIGHT
	return normalized


func _spawn_line_warning(direction: Vector2, length: float, width: float, color: Color, duration: float) -> void:
	var normalized := _normalized_direction(direction)
	var warning := Line2D.new()
	warning.name = "RivetBurstWarning"
	warning.z_index = -1
	warning.width = width
	warning.default_color = color
	warning.points = PackedVector2Array([
		Vector2(0.0, -38.0),
		Vector2(0.0, -38.0) + normalized * length,
	])
	add_child(warning)
	var tween := warning.create_tween()
	tween.tween_property(warning, "modulate", Color(color.r, color.g, color.b, 0.08), duration)
	tween.tween_callback(warning.queue_free)
