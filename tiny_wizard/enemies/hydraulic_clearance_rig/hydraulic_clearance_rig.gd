class_name Chapter5HydraulicClearanceRig
extends ProtomatterDropEnemy

const TELEGRAPH := preload("res://tiny_wizard/enemies/chapter5_pixel_telegraph.gd")
const IDLE_LEFT := preload("res://tiny_wizard/assets/art/enemies/chapter5/hydraulic_clearance_rig/hydraulic_clearance_rig_idle_left_80x64.png")
const IDLE_RIGHT := preload("res://tiny_wizard/assets/art/enemies/chapter5/hydraulic_clearance_rig/hydraulic_clearance_rig_idle_right_80x64.png")
const ATTACK_LEFT := preload("res://tiny_wizard/assets/art/enemies/chapter5/hydraulic_clearance_rig/hydraulic_clearance_rig_attack_left_80x64_10f.png")
const ATTACK_RIGHT := preload("res://tiny_wizard/assets/art/enemies/chapter5/hydraulic_clearance_rig/hydraulic_clearance_rig_attack_right_80x64_10f.png")

@export var attack_damage := 2
@export var attack_range := 92.0
@export var attack_width := 48.0
@export var attack_duration := 1.02

var _attack_active := false
var _attack_elapsed := 0.0
var _attack_direction := Vector2.RIGHT
var _damage_done := false

@onready var body_sprite := $Visual/BodySprite as Sprite2D


func _ready() -> void:
	super._ready()
	add_to_group("chapter5_hydraulic_clearance_rigs")
	set_meta("chapter5_enemy_id", "hydraulic_clearance_rig")
	play_idle()


func _process(delta: float) -> void:
	if not _attack_active:
		return
	_attack_elapsed += delta
	if body_sprite != null:
		body_sprite.frame = mini(9, int(floor(_attack_elapsed / attack_duration * 10.0)))
	if not _damage_done and _attack_elapsed >= 0.56:
		_damage_done = true
		_damage_front()
	if _attack_elapsed >= attack_duration:
		_attack_active = false
		play_idle(_attack_direction)


func set_speed_multiplier(multiplier: float) -> void:
	if physics_stats != null:
		physics_stats.max_speed = 54.0 * multiplier


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
	_damage_done = false
	if body_sprite != null:
		body_sprite.texture = ATTACK_LEFT if _attack_direction.x < 0.0 else ATTACK_RIGHT
		body_sprite.hframes = 10
		body_sprite.frame = 0
	TELEGRAPH.spawn_line(self, Vector2(0.0, -26.0), _attack_direction, attack_range, duration, 4.0, Color(0.58, 0.3, 0.12, 0.9))


func begin_attack(direction: Vector2) -> void:
	_attack_direction = _normalized_direction(direction)
	_attack_active = true
	_attack_elapsed = 0.0
	_damage_done = false


func finish_attack() -> void:
	_attack_active = false
	play_idle(_attack_direction)


func _damage_front() -> void:
	var origin := global_position + Vector2(0.0, -26.0)
	var center := origin + _attack_direction * (attack_range * 0.5)
	var shape := RectangleShape2D.new()
	shape.size = Vector2(attack_range, attack_width)
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = shape
	query.transform = Transform2D(_attack_direction.angle(), center)
	query.collision_mask = 2
	query.exclude = [get_rid()]
	for result: Dictionary in get_world_2d().direct_space_state.intersect_shape(query, 8):
		var target := result.get("collider") as Node
		if target != null and target.has_method("hit"):
			target.call("hit", attack_damage, _attack_direction)


func _normalized_direction(direction: Vector2) -> Vector2:
	var normalized := direction.normalized()
	return normalized if normalized.length() > 0.01 else Vector2.RIGHT
