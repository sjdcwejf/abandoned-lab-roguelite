class_name LabProtomatterCorrosionRound
extends LabProjectile


const STATUS_EFFECT_CONTROLLER := preload("res://tiny_wizard/status_effects/status_effect_controller.gd")

@export var impact_scene: PackedScene
@export var corrosion_duration := 3.0
@export_range(1, 6, 1) var corrosion_tick_damage := 1
@export var corrosion_tick_interval := 1.0
@export var corrosion_visual_color := Color(0.39, 1.0, 0.32, 0.86)


func _hit_collider(target: Object) -> void:
	var damage_target := _find_damage_target(target)
	if damage_target != null:
		var final_damage := damage + WEAPON_AFFIX_SERVICE.roll_extra_hit_damage(weapon_affixes)
		var hit_from := Vector2.ZERO
		if damage_target is Node2D:
			hit_from = ((damage_target as Node2D).global_position - global_position).normalized() * knockback_multiplier
		damage_target.hit(final_damage, hit_from)
		STATUS_EFFECT_CONTROLLER.apply_damage_over_time(
			damage_target,
			STATUS_EFFECT_CONTROLLER.STATUS_CORROSION,
			corrosion_duration,
			corrosion_tick_damage,
			corrosion_tick_interval,
			corrosion_visual_color
		)
		_notify_owner_weapon_hit(damage_target, final_damage)

	_spawn_impact()
	queue_free()


func _spawn_impact() -> void:
	if impact_scene == null:
		return
	var spawn_parent := get_spawn_parent()
	if spawn_parent == null:
		return
	var impact := impact_scene.instantiate()
	spawn_parent.add_child(impact)
	if impact is Node2D:
		(impact as Node2D).global_position = global_position
		(impact as Node2D).global_rotation = direction.angle()


func get_spawn_parent() -> Node:
	var tree := get_tree()
	if tree != null and tree.current_scene != null:
		return tree.current_scene
	if get_parent() != null:
		return get_parent()
	return null
