extends Room


@export var completion_message := "TARGET SYNC COMPLETE"

var _targets: Array[Node] = []

@onready var status_label: Label = get_node_or_null("CalibrationZone/StatusPanel/StatusText") as Label


func _ready() -> void:
	super._ready()
	_collect_targets()
	_update_status()


func enter_room() -> void:
	if is_cleared:
		return
	close_door(Direction.RIGHT)
	_update_status()


func _collect_targets() -> void:
	_targets.clear()
	for child in get_tree().get_nodes_in_group("tutorial_targets"):
		if child is Node and is_ancestor_of(child) and child.has_signal("target_activated"):
			var target: Node = child
			_targets.append(target)
			var activated_callable := Callable(self, "_on_target_activated")
			if not target.is_connected("target_activated", activated_callable):
				target.connect("target_activated", activated_callable)


func _on_target_activated(_target: Node) -> void:
	_update_status()
	if _all_targets_active():
		open_door(Direction.RIGHT)
		_mark_room_cleared()


func _all_targets_active() -> bool:
	if _targets.is_empty():
		return false
	for target in _targets:
		if target == null or not bool(target.get("activated")):
			return false
	return true


func _update_status() -> void:
	if status_label == null:
		return
	var active_count := 0
	for target in _targets:
		if target != null and bool(target.get("activated")):
			active_count += 1

	if _targets.is_empty():
		status_label.text = "TARGET ARRAY OFFLINE"
	elif active_count >= _targets.size():
		status_label.text = completion_message
	else:
		status_label.text = "CALIBRATE TARGETS %d/%d" % [active_count, _targets.size()]
