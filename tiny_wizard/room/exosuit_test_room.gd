class_name ExosuitTestRoom
extends Room


func _ready() -> void:
	super._ready()
	set_meta("event_objective_text", "摧毁外骨骼测试节点，并清理房内敌人。")
	set_meta("event_target_label", "外骨骼测试节点")
	set_meta("event_completion_text", "封锁解除：外骨骼测试节点已摧毁。")
	_register_authored_test_nodes(self)


func _register_authored_test_nodes(root: Node) -> void:
	if root == null:
		return

	if root.is_in_group("room_event_targets") and root.has_signal("pollution_source_destroyed"):
		register_pollution_source(root)

	for child in root.get_children():
		_register_authored_test_nodes(child)
