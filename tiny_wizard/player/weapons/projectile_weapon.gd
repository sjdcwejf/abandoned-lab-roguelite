class_name LabProjectileWeapon
extends LabWeapon


@export var projectile_scene: PackedScene
@export_range(1, 10, 1) var damage := 1
@export var projectile_speed := 560.0
@export var cooldown := 0.22
@export_flags_2d_physics var collision_mask := 73

var _cooldown_timer := 0.0


func _physics_process(delta: float) -> void:
	if _cooldown_timer > 0.0:
		_cooldown_timer -= delta


func primary_pressed() -> void:
	fire_projectile()


func fire_projectile() -> bool:
	if _cooldown_timer > 0.0 or projectile_scene == null:
		return false

	var projectile := projectile_scene.instantiate()
	var spawn_parent := get_spawn_parent()
	if spawn_parent == null:
		return false

	spawn_parent.add_child(projectile)
	if projectile is Node2D:
		(projectile as Node2D).global_position = get_fire_origin()
		(projectile as Node2D).global_rotation = aim_direction.angle()
	if projectile.has_method("launch"):
		projectile.launch(aim_direction, owner_character, damage, projectile_speed, collision_mask)

	_cooldown_timer = cooldown
	return true
