class_name Chapter5R7Executor
extends ProtomatterDropEnemy

const PROJECTILE_SCENE := preload("res://tiny_wizard/enemies/chapter5_linear_projectile.tscn")
const TELEGRAPH := preload("res://tiny_wizard/enemies/chapter5_pixel_telegraph.gd")
const IDLE_TEXTURE := preload("res://tiny_wizard/assets/art/enemies/chapter5/r7_executor/r7_executor_idle_80x80.png")
const PROJECTILE_TEXTURE := preload("res://tiny_wizard/assets/art/enemies/chapter5/r7_executor/r7_executor_three_round_12x8_4f.png")
const ATTACK_LEFT := preload("res://tiny_wizard/assets/art/enemies/chapter5/r7_executor/r7_executor_attack_left_80x80_8f.png")
const ATTACK_RIGHT := preload("res://tiny_wizard/assets/art/enemies/chapter5/r7_executor/r7_executor_attack_right_80x80_8f.png")
const ATTACK_UP := preload("res://tiny_wizard/assets/art/enemies/chapter5/r7_executor/r7_executor_attack_up_80x80_8f.png")
const ATTACK_DOWN := preload("res://tiny_wizard/assets/art/enemies/chapter5/r7_executor/r7_executor_attack_down_80x80_8f.png")

@export var attack_damage := 1
@export var projectile_speed := 265.0
@export var attack_duration := 0.9
@export var lane_spacing := 16.0

var _attack_active := false
var _attack_elapsed := 0.0
var _attack_direction := Vector2.RIGHT

@onready var body_sprite := $Visual/BodySprite as Sprite2D


func _ready() -> void:
	super._ready()
	add_to_group("chapter5_r7_executors")
	set_meta("chapter5_enemy_id", "r7_executor")
	play_idle()


func _process(delta: float) -> void:
	if not _attack_active:
		return
	_attack_elapsed += delta
	if body_sprite != null:
		body_sprite.frame = mini(7, int(floor(_attack_elapsed / attack_duration * 8.0)))
	if _attack_elapsed >= attack_duration:
		_attack_active = false
		play_idle()


func set_speed_multiplier(multiplier: float) -> void:
	if physics_stats != null:
		physics_stats.max_speed = 30.0 * multiplier


func play_idle() -> void:
	if body_sprite == null:
		return
	body_sprite.texture = IDLE_TEXTURE
	body_sprite.hframes = 1
	body_sprite.frame = 0


func play_windup(direction: Vector2, duration: float) -> void:
	_attack_direction = _normalized_direction(direction)
	_attack_active = false
	_attack_elapsed = 0.0
	if body_sprite != null:
		body_sprite.texture = _attack_texture(_direction_name(_attack_direction))
		body_sprite.hframes = 8
		body_sprite.frame = 0
	TELEGRAPH.spawn_parallel(self, Vector2(0.0, -38.0), _attack_direction, 330.0, lane_spacing, 3, duration)


func begin_attack(direction: Vector2) -> void:
	_attack_direction = _normalized_direction(direction)
	_attack_active = true
	_attack_elapsed = 0.0
	_fire_three_round()


func finish_attack() -> void:
	_attack_active = false
	play_idle()


func _attack_texture(direction: StringName) -> Texture2D:
	match direction:
		&"left":
			return ATTACK_LEFT
		&"up":
			return ATTACK_UP
		&"down":
			return ATTACK_DOWN
	return ATTACK_RIGHT


func _direction_name(direction: Vector2) -> StringName:
	if absf(direction.x) >= absf(direction.y):
		return &"left" if direction.x < 0.0 else &"right"
	return &"up" if direction.y < 0.0 else &"down"


func _normalized_direction(direction: Vector2) -> Vector2:
	var normalized := direction.normalized()
	return normalized if normalized.length() > 0.01 else Vector2.RIGHT


func _fire_three_round() -> void:
	var effect_parent := _get_drop_parent()
	if effect_parent == null:
		return
	var origin := global_position + Vector2(0.0, -38.0)
	var perpendicular := Vector2(-_attack_direction.y, _attack_direction.x)
	for index in range(3):
		var offset := perpendicular * (float(index) - 1.0) * lane_spacing
		var projectile := PROJECTILE_SCENE.instantiate() as Chapter5LinearProjectile
		if projectile == null:
			continue
		var projectile_sprite := projectile.get_node_or_null("Sprite2D") as Sprite2D
		if projectile_sprite != null:
			projectile_sprite.texture = PROJECTILE_TEXTURE
			projectile_sprite.hframes = 4
		if effect_parent is Node2D:
			projectile.position = (effect_parent as Node2D).to_local(origin + offset)
		else:
			projectile.global_position = origin + offset
		projectile.call("setup", _attack_direction, attack_damage, projectile_speed)
		effect_parent.call_deferred("add_child", projectile)
