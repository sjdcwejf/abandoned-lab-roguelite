extends LabWeapon


@export var range := 760.0
@export_range(1, 10, 1) var damage := 1
@export var damage_interval := 0.12
@export_flags_2d_physics var collision_mask := 73

var _is_firing := false
var _damage_timer := 0.0

@onready var beam: Line2D = $Beam
@onready var muzzle_flash: Polygon2D = $MuzzleFlash


func _ready() -> void:
	beam.visible = false
	beam.top_level = true
	beam.z_index = 20
	muzzle_flash.visible = false


func _physics_process(delta: float) -> void:
	if not _is_firing:
		beam.visible = false
		muzzle_flash.visible = false
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
	super.unequip()


func _update_beam() -> void:
	var start := _get_fire_origin()
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

	muzzle_flash.global_position = start
	muzzle_flash.global_rotation = aim_direction.angle()
	muzzle_flash.visible = true


func _get_fire_origin() -> Vector2:
	if owner_character != null:
		return owner_character.global_position + aim_direction * 22.0
	return global_position


func _try_damage(target: Object, start: Vector2) -> void:
	if _damage_timer > 0.0:
		return

	var damage_target := _find_damage_target(target)
	if damage_target == null:
		return

	var hit_from := Vector2.ZERO
	if damage_target is Node2D:
		hit_from = ((damage_target as Node2D).global_position - start).normalized()
	damage_target.hit(damage, hit_from)
	_damage_timer = damage_interval


func _find_damage_target(target: Object) -> Object:
	if target == null:
		return null
	if target.has_method("hit"):
		return target
	if not target is Node:
		return null

	var current := (target as Node).get_parent()
	while current != null:
		if current.has_method("hit"):
			return current
		current = current.get_parent()
	return null
