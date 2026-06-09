class_name LabBeamWeapon
extends LabWeapon


@export var range := 760.0
@export_range(1, 10, 1) var damage := 1
@export var damage_interval := 0.12
@export_flags_2d_physics var collision_mask := 73

var _is_firing := false
var _damage_timer := 0.0

@onready var beam: Line2D = get_node_or_null("Beam") as Line2D
@onready var muzzle_flash: Polygon2D = get_node_or_null("MuzzleFlash") as Polygon2D


func _ready() -> void:
	if beam != null:
		beam.visible = false
		beam.top_level = true
		beam.z_index = 20
	if muzzle_flash != null:
		muzzle_flash.visible = false


func _physics_process(delta: float) -> void:
	if not _is_firing:
		_hide_beam()
		_damage_timer = 0.0
		return

	_damage_timer -= delta
	_update_beam()


func primary_pressed() -> void:
	_is_firing = true


func primary_released() -> void:
	_is_firing = false


func unequip() -> void:
	_is_firing = false
	_hide_beam()
	super.unequip()


func _update_beam() -> void:
	if beam == null:
		return

	var start := get_fire_origin()
	var end := start + aim_direction * range
	var query := PhysicsRayQueryParameters2D.create(start, end)
	query.collision_mask = collision_mask
	if owner_character is CollisionObject2D:
		query.exclude = [(owner_character as CollisionObject2D).get_rid()]

	var result := get_world_2d().direct_space_state.intersect_ray(query)
	if result.size() > 0:
		end = result["position"]
		_try_damage(result["collider"], start)

	beam.global_position = Vector2.ZERO
	beam.global_rotation = 0.0
	beam.global_scale = Vector2.ONE
	beam.points = PackedVector2Array([start, end])
	beam.visible = true

	if muzzle_flash != null:
		muzzle_flash.global_position = start
		muzzle_flash.global_rotation = aim_direction.angle()
		muzzle_flash.visible = true


func _hide_beam() -> void:
	if beam != null:
		beam.visible = false
	if muzzle_flash != null:
		muzzle_flash.visible = false


func _try_damage(target: Object, start: Vector2) -> void:
	if _damage_timer > 0.0:
		return

	if apply_damage_to_target(target, damage, Vector2.ZERO, start):
		_damage_timer = damage_interval
