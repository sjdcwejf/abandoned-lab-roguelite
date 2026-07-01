class_name GreenhouseSporeEventRoom
extends Room


func _ready() -> void:
	super._ready()
	_register_authored_spore_pods(self)


func _register_authored_spore_pods(root: Node) -> void:
	if root == null:
		return

	if root.is_in_group("room_event_targets") and root.has_signal("pollution_source_destroyed"):
		register_pollution_source(root)

	for child in root.get_children():
		_register_authored_spore_pods(child)
