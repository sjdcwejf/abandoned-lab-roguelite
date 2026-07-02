class_name CryoPodRoom
extends Room


var cryo_pod_total := 0
var cryo_pod_remaining := 0


func _ready() -> void:
	super._ready()
	set_meta("event_objective_text", "检查冷冻舱 0/3，并清除释放出的封存样本。")
	set_meta("event_target_label", "冷冻舱")
	set_meta("event_completion_text", "封锁解除：冷冻舱已检查。")
	_register_authored_cryo_pods(self)


func has_pending_room_event_objectives() -> bool:
	return super.has_pending_room_event_objectives() or cryo_pod_remaining > 0


func has_cryo_pod_objective() -> bool:
	return cryo_pod_total > 0


func get_cryo_pod_total() -> int:
	return cryo_pod_total


func get_cryo_pod_remaining() -> int:
	if is_cleared:
		return 0
	return cryo_pod_remaining


func _register_authored_cryo_pods(root: Node) -> void:
	if root == null:
		return
	if root is LabCryoPod:
		_register_cryo_pod(root as LabCryoPod)
	for child in root.get_children():
		_register_authored_cryo_pods(child)


func _register_cryo_pod(pod: LabCryoPod) -> void:
	if pod == null:
		return
	cryo_pod_total += 1
	cryo_pod_remaining += 1
	lab_room_type = "cryo_pod"
	var checked_callable := Callable(self, "_on_cryo_pod_checked")
	if not pod.cryo_pod_checked.is_connected(checked_callable):
		pod.cryo_pod_checked.connect(checked_callable)
	objective_progress_changed.emit(self)


func _on_cryo_pod_checked(_pod: LabCryoPod) -> void:
	cryo_pod_remaining = maxi(0, cryo_pod_remaining - 1)
	objective_progress_changed.emit(self)
	call_deferred("_try_finish_room_clear")
