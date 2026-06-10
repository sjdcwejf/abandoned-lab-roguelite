class_name LabChest
extends QuiverInteractableObject

@export var items := []

var _room_locked := false


func _ready():
	super._ready()
	action.items = items
	_apply_room_lock()


func set_room_locked(locked: bool) -> void:
	_room_locked = locked
	_apply_room_lock()


func is_room_locked() -> bool:
	return _room_locked


func _apply_room_lock() -> void:
	if action != null:
		action.active = not _room_locked

	modulate = Color(0.45, 0.5, 0.54, 0.88) if _room_locked else Color.WHITE
