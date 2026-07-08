class_name DataCoreEventRoom
extends Room


const INTERACTION_FEEDBACK := preload("res://tiny_wizard/gui/interaction_feedback.gd")

@export_multiline var event_objective_text := "处理数据终端，并清理房内异常单位。"
@export var event_target_label := "数据终端"
@export var event_completion_text := "封锁解除：数据终端已同步。"
@export var event_target_success_message := "目标完成。"


func _ready() -> void:
	super._ready()
	set_meta("event_objective_text", event_objective_text)
	set_meta("event_target_label", event_target_label)
	set_meta("event_completion_text", event_completion_text)
	_register_authored_targets(self)


func _register_authored_targets(root: Node) -> void:
	if root == null:
		return

	if root.is_in_group("room_event_targets") and root.has_signal("pollution_source_destroyed"):
		register_pollution_source(root)
		var feedback_callable := Callable(self, "_on_event_target_completed")
		if not root.is_connected("pollution_source_destroyed", feedback_callable):
			root.connect("pollution_source_destroyed", feedback_callable)

	for child in root.get_children():
		_register_authored_targets(child)


func _on_event_target_completed(_source: Node) -> void:
	if event_target_success_message != "":
		INTERACTION_FEEDBACK.show_from(self, event_target_success_message, 1.35)
