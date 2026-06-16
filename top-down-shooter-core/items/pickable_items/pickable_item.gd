@tool
extends QuiverInteractableObject
class_name QuiverPickableItem

# The pickable item is a specific interactable object that holds a QuiverItem.
# It can be interacted (to pick it up, or use it instantly) as an interactable object.

# The corresponding item
@export var item: QuiverItem
@export var stabilize_physics_body := true
@export var physics_body_path := NodePath("RigidBody2D")


func _ready():
	super._ready()
	if stabilize_physics_body:
		_stabilize_physics_body()


func _get_configuration_warnings():
	var warnings = super._get_configuration_warnings()
	if not item is QuiverItem:
		warnings.append("item from PickableItem should be of type QuiverItem")
	return warnings


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
