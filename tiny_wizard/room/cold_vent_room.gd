class_name ColdVentRoom
extends Room


const CRYO_ZONE_SCENE := preload("res://tiny_wizard/interactable_objects/cryo_zone/cryo_zone.tscn")

@export var vent_interval := 4.2
@export var vent_warning_duration := 0.75
@export var vent_zone_duration := 2.1

var _active_room := false
var _vent_timer := 0.8


func _ready() -> void:
	super._ready()
	set_process(true)


func enter_room() -> void:
	_active_room = true
	_vent_timer = 0.8
	super.enter_room()


func _on_room_cleared() -> void:
	_active_room = false


func _process(delta: float) -> void:
	if not _active_room or is_cleared:
		return
	_vent_timer -= delta
	if _vent_timer > 0.0:
		return
	_vent_timer = vent_interval
	_trigger_vents()


func _trigger_vents() -> void:
	var vents := _collect_vents(self)
	if vents.is_empty():
		return
	for vent in vents:
		_show_vent_warning(vent)
	await get_tree().create_timer(vent_warning_duration, false).timeout
	if not is_inside_tree() or not _active_room or is_cleared:
		return
	for vent in vents:
		_spawn_vent_zone(vent)


func _collect_vents(root: Node) -> Array[Node2D]:
	var result: Array[Node2D] = []
	if root is Node2D and root.is_in_group("cryo_vents"):
		result.append(root as Node2D)
	for child in root.get_children():
		result.append_array(_collect_vents(child))
	return result


func _show_vent_warning(vent: Node2D) -> void:
	var warning := Line2D.new()
	warning.name = "冷气喷口预警"
	warning.z_index = 20
	warning.width = 5.0
	warning.default_color = Color(0.46, 0.84, 1.0, 0.85)
	warning.closed = true
	warning.points = PackedVector2Array([
		Vector2(-70, -42),
		Vector2(70, -42),
		Vector2(70, 42),
		Vector2(-70, 42),
	])
	vent.add_child(warning)
	var tween := warning.create_tween()
	tween.tween_property(warning, "modulate", Color(1, 1, 1, 0.12), vent_warning_duration)
	tween.tween_callback(warning.queue_free)


func _spawn_vent_zone(vent: Node2D) -> void:
	var zone := CRYO_ZONE_SCENE.instantiate() as LabCryoZone
	if zone == null:
		return
	zone.show_player_feedback = true
	zone.setup_rect(Vector2(152, 94), vent_zone_duration)
	zone.position = vent.position
	add_child(zone)
