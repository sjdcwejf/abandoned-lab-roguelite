class_name Chapter5IndexPursuer
extends ProtomatterDropEnemy


signal index_shot(source: Node, origin: Vector2, direction: Vector2, target_position: Vector2)

const PROJECTILE_SCENE := preload("res://tiny_wizard/enemies/chapter5_linear_projectile.tscn")
const TELEGRAPH := preload("res://tiny_wizard/enemies/chapter5_pixel_telegraph.gd")
const IDLE_LEFT := preload("res://tiny_wizard/assets/art/enemies/chapter5/index_pursuer/index_pursuer_idle_left_64x64.png")
const IDLE_RIGHT := preload("res://tiny_wizard/assets/art/enemies/chapter5/index_pursuer/index_pursuer_idle_right_64x64.png")
const ATTACK_LEFT := preload("res://tiny_wizard/assets/art/enemies/chapter5/index_pursuer/index_pursuer_attack_left_64x64_8f.png")
const ATTACK_RIGHT := preload("res://tiny_wizard/assets/art/enemies/chapter5/index_pursuer/index_pursuer_attack_right_64x64_8f.png")
const NAIL_LEFT := preload("res://tiny_wizard/assets/art/enemies/chapter5/index_pursuer/index_pursuer_nail_left_14x8_4f.png")
const NAIL_RIGHT := preload("res://tiny_wizard/assets/art/enemies/chapter5/index_pursuer/index_pursuer_nail_right_14x8_4f.png")

@export var attack_duration := 0.82
@export var attack_damage := 1
@export var projectile_speed := 330.0
@export var projectile_lifetime := 1.6

var _attack_active := false
var _attack_elapsed := 0.0
var _attack_direction := Vector2.RIGHT
var _attack_target := Vector2.ZERO

@onready var body_sprite := $Visual/BodySprite as Sprite2D


func _ready() -> void:
	super._ready()
	add_to_group("chapter5_index_pursuers")
	set_meta("chapter5_enemy_id", "index_pursuer")
	play_idle()


func _process(delta: float) -> void:
	if not _attack_active:
		return
	_attack_elapsed += delta
	if body_sprite == null:
		return
	body_sprite.frame = mini(7, int(floor(_attack_elapsed / attack_duration * 8.0)))


func set_speed_multiplier(multiplier: float) -> void:
	if physics_stats != null:
		physics_stats.max_speed = 62.0 * multiplier


func play_idle(direction := Vector2.RIGHT) -> void:
	if body_sprite == null:
		return
	body_sprite.texture = IDLE_LEFT if direction.x < 0.0 else IDLE_RIGHT
	body_sprite.hframes = 1
	body_sprite.frame = 0


func play_windup(direction: Vector2, duration: float) -> void:
	_attack_direction = _normalized_direction(direction)
	_attack_active = false
	_attack_elapsed = 0.0
	if body_sprite != null:
		body_sprite.texture = ATTACK_LEFT if _attack_direction.x < 0.0 else ATTACK_RIGHT
		body_sprite.hframes = 8
		body_sprite.frame = 0
		body_sprite.flip_h = false
	TELEGRAPH.spawn_line(self, Vector2(0.0, -33.0), _attack_direction, 310.0, duration, 3.0)


func begin_attack(direction: Vector2, target_position: Vector2) -> void:
	_attack_direction = _normalized_direction(direction)
	_attack_target = target_position
	_attack_active = true
	_attack_elapsed = 0.0


func fire_nail() -> void:
	var effect_parent := _get_drop_parent()
	if effect_parent == null:
		return
	var origin := global_position + Vector2(0.0, -33.0) + _attack_direction * 20.0
	var direction := origin.direction_to(_attack_target)
	if direction.length() < 0.01:
		direction = _attack_direction
	var projectile := PROJECTILE_SCENE.instantiate() as Chapter5LinearProjectile
	if projectile == null:
		return
	var projectile_sprite := projectile.get_node_or_null("Sprite2D") as Sprite2D
	if projectile_sprite != null:
		projectile_sprite.texture = NAIL_LEFT if direction.x < 0.0 else NAIL_RIGHT
		projectile_sprite.hframes = 4
	if effect_parent is Node2D:
		projectile.position = (effect_parent as Node2D).to_local(origin)
	else:
		projectile.global_position = origin
	projectile.call("setup", direction, attack_damage, projectile_speed)
	projectile.lifetime = projectile_lifetime
	effect_parent.call_deferred("add_child", projectile)
	index_shot.emit(self, origin, direction, _attack_target)


func finish_attack() -> void:
	_attack_active = false
	_attack_elapsed = 0.0
	play_idle(_attack_direction)


func _normalized_direction(direction: Vector2) -> Vector2:
	var normalized := direction.normalized()
	return normalized if normalized.length() > 0.01 else Vector2.RIGHT
