class_name GreenhouseSporeEventRoom
extends Room


func _ready() -> void:
	super._ready()
	set_meta("event_objective_text", "摧毁孢子囊 0/3，并清除房内敌人。")
	set_meta("event_target_label", "孢子囊")
	set_meta("event_completion_text", "封锁解除：孢子囊已清除。")
	_register_authored_spore_pods(self)


func _register_authored_spore_pods(root: Node) -> void:
	if root == null:
		return

	if root.is_in_group("room_event_targets") and root.has_signal("pollution_source_destroyed"):
		register_pollution_source(root)

	for child in root.get_children():
		_register_authored_spore_pods(child)
