extends ProtomatterDropEnemy


@export var hook_damage := 2
@export var driver_damage := 2
@export var sweep_damage := 1

var _pending_attack := &"hook_slam"

@onready var body_sprite := $Visual/BodySprite as AnimatedSprite2D


func _ready() -> void:
	super._ready()
	set_meta("exosuit_enemy", true)
	set_meta("elite_enemy", true)


func set_speed_multiplier(multiplier: float) -> void:
	if physics_stats != null:
		physics_stats.max_speed = 38.0 * multiplier


func play_idle() -> void:
	if body_sprite != null and body_sprite.animation != &"idle":
		body_sprite.play(&"idle")


func play_windup(attack_name: StringName, duration: float) -> void:
	_pending_attack = attack_name
	match attack_name:
		&"hook_slam":
			_spawn_rect_warning(Rect2(Vector2(-158.0, -106.0), Vector2(118.0, 148.0)), duration)
		&"driver_slam":
			_spawn_rect_warning(Rect2(Vector2(34.0, -90.0), Vector2(176.0, 96.0)), duration)
		&"pendulum_sweep":
			_spawn_rect_warning(Rect2(Vector2(-178.0, -100.0), Vector2(356.0, 136.0)), duration)
	if body_sprite != null:
		body_sprite.play(attack_name)
		body_sprite.frame = 0
		body_sprite.pause()


func begin_attack(attack_name: StringName) -> void:
	_pending_attack = attack_name
	if body_sprite != null:
		body_sprite.play(attack_name)


func execute_attack(attack_name: StringName) -> void:
	match attack_name:
		&"hook_slam":
			_damage_rect(Rect2(Vector2(-158.0, -106.0), Vector2(118.0, 148.0)), hook_damage, Vector2.LEFT)
		&"driver_slam":
			_damage_rect(Rect2(Vector2(34.0, -90.0), Vector2(176.0, 96.0)), driver_damage, Vector2.RIGHT)
		&"pendulum_sweep":
			_damage_rect(Rect2(Vector2(-178.0, -100.0), Vector2(356.0, 136.0)), sweep_damage, Vector2.ZERO)


func finish_attack() -> void:
	play_idle()


func _damage_rect(local_rect: Rect2, damage: int, impulse: Vector2) -> void:
	var shape := RectangleShape2D.new()
	shape.size = local_rect.size
	var center := global_position + local_rect.position + local_rect.size * 0.5
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = shape
	query.transform = Transform2D(0.0, center)
	query.collision_mask = 2
	query.exclude = [get_rid()]
	for result: Dictionary in get_world_2d().direct_space_state.intersect_shape(query, 8):
		var target := result.get("collider") as Node
		if target == null or not target.has_method("hit"):
			continue
		target.call("hit", damage, impulse)


func _spawn_rect_warning(local_rect: Rect2, duration: float) -> void:
	var warning := Line2D.new()
	warning.name = "SecurityGantryAttackWarning"
	warning.z_index = -1
	warning.width = 5.0
	warning.default_color = Color(1.0, 0.58, 0.22, 0.72)
	warning.closed = true
	warning.points = PackedVector2Array([
		local_rect.position,
		Vector2(local_rect.end.x, local_rect.position.y),
		local_rect.end,
		Vector2(local_rect.position.x, local_rect.end.y),
	])
	add_child(warning)
	var tween := warning.create_tween()
	tween.tween_property(warning, "modulate", Color(1.0, 0.76, 0.36, 0.08), duration)
	tween.tween_callback(warning.queue_free)
