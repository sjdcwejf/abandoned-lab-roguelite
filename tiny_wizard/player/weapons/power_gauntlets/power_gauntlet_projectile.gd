extends LabProjectile


@export var impact_scene: PackedScene


func _hit_collider(target: Object) -> void:
	_spawn_impact()
	super._hit_collider(target)


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
