class_name LabChest
extends QuiverInteractableObject

@export var items := []
@export var physics_body_path := NodePath("RigidBody2D")

var _room_locked := false
var _opened := false


func _ready():
	super._ready()
	action.items = items
	_apply_room_lock()


func set_room_locked(locked: bool) -> void:
	_room_locked = locked
	_apply_room_lock()


func is_room_locked() -> bool:
	return _room_locked


func mark_opened() -> void:
	if _opened:
		return
	_opened = true
	_room_locked = false
	_freeze_physics_body()
	_apply_room_lock()


func is_opened() -> bool:
	return _opened


func _apply_room_lock() -> void:
	if action != null:
		action.active = not _room_locked and not _opened

	modulate = Color(0.45, 0.5, 0.54, 0.88) if _room_locked and not _opened else Color.WHITE


func _freeze_physics_body() -> void:
	var body := get_node_or_null(physics_body_path) as RigidBody2D
	if body == null:
		return

	body.linear_velocity = Vector2.ZERO
	body.angular_velocity = 0.0
	body.freeze = true
	body.freeze_mode = RigidBody2D.FREEZE_MODE_STATIC
	body.contact_monitor = false
