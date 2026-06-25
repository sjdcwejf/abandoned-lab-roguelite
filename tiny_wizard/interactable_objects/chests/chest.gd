class_name LabChest
extends QuiverInteractableObject

@export var items := []
@export var physics_body_path := NodePath("RigidBody2D")

var _room_locked := false
var _opened := false


func _ready():
	super._ready()
	action.items = items
	_stabilize_physics_body()
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


func get_interaction_prompt(character: QuiverCharacter) -> String:
	if _opened:
		return ""
	if _room_locked:
		return "清理样本后解锁"
	if _is_key_locked() and not _character_has_key(character):
		return "需要生物识别钥"
	return "按 F 打开补给箱"


func get_interaction_block_message(character: QuiverCharacter) -> String:
	if _opened:
		return "补给箱已经打开。"
	if _room_locked:
		return "清理当前房间目标后，补给箱才会解锁。"
	if _is_key_locked() and not _character_has_key(character):
		return "需要生物识别钥才能打开。"
	return ""


func _apply_room_lock() -> void:
	if action != null:
		action.active = not _room_locked and not _opened

	modulate = Color(0.45, 0.5, 0.54, 0.88) if _room_locked and not _opened else Color.WHITE


func _is_key_locked() -> bool:
	if action == null:
		return false
	return bool(action.get("locked"))


func _character_has_key(character: QuiverCharacter) -> bool:
	if character == null or character.inventory == null:
		return false
	return int((character.inventory as QuiverInventory).get_item_amount("Biometric Key")) > 0


func _freeze_physics_body() -> void:
	_stabilize_physics_body()
	var body := get_node_or_null(physics_body_path) as RigidBody2D
	if body == null:
		return

	body.contact_monitor = false
	body.collision_layer = 0
	body.collision_mask = 0
	_disable_collision_shapes(body)


func _stabilize_physics_body() -> void:
	var body := get_node_or_null(physics_body_path) as RigidBody2D
	if body == null:
		return

	body.linear_velocity = Vector2.ZERO
	body.angular_velocity = 0.0
	body.freeze = true
	body.freeze_mode = RigidBody2D.FREEZE_MODE_STATIC
	body.lock_rotation = true
	body.contact_monitor = true
	body.max_contacts_reported = 8


func _disable_collision_shapes(root: Node) -> void:
	for child in root.get_children():
		if child is CollisionShape2D:
			(child as CollisionShape2D).set_deferred("disabled", true)
		_disable_collision_shapes(child)
