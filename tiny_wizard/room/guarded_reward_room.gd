extends Room


func _ready() -> void:
	super._ready()
	if not is_cleared and $Enemies.get_child_count() > 0:
		_set_reward_chests_locked(true)


func _on_room_cleared() -> void:
	_set_reward_chests_locked(false)


func _set_reward_chests_locked(locked: bool) -> void:
	_set_chests_locked_recursive(self, locked)


func _set_chests_locked_recursive(root: Node, locked: bool) -> void:
	if root is LabChest:
		(root as LabChest).set_room_locked(locked)

	for child in root.get_children():
		_set_chests_locked_recursive(child, locked)
