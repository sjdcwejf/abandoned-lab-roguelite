extends QuiverInteractMechanic

# An example of QuiverInteractMechanic that triggers when a character collide with the object's body

# The path to the body of the object (should be a RigidBody2D)
@export var object_body_path : NodePath
@export var overlap_query_interval := 0.08
@export var repeat_interact_cooldown := 0.28

# Hold the body node
var _object_body : RigidBody2D
var _collision_shapes: Array[CollisionShape2D] = []
var _overlap_query_timer := 0.0
var _last_interact_msec_by_id := {}


func _ready():
	var node = get_node(object_body_path)
	if node is RigidBody2D:
		_object_body = node

		# This is to make sure the contact with the character will be reported
		_object_body.contact_monitor = true
		_object_body.max_contacts_reported = 8
 
		_object_body.body_entered.connect(self._body_entered)
		_collect_collision_shapes(_object_body)
		set_physics_process(true)
		
	else:
		printerr("interact_on_collide: rigidbody_path doesn't give access to a RigidDynamicBody node")


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	if _object_body == null:
		return
	if overlap_query_interval <= 0.0:
		return

	_overlap_query_timer -= delta
	if _overlap_query_timer > 0.0:
		return
	_overlap_query_timer = overlap_query_interval
	_query_overlapping_character()


func _body_entered(body):
	if body is QuiverCharacter:
		# We trigger the action every time, the QuiverInteractableObjectAction will take care of handling if the corresponding character can interact
		_interact_if_ready(body)


func _query_overlapping_character() -> void:
	var space_state := get_world_2d().direct_space_state
	if space_state == null:
		return

	for collision_shape in _collision_shapes:
		if collision_shape == null or not is_instance_valid(collision_shape):
			continue
		if collision_shape.disabled or collision_shape.shape == null:
			continue

		var query := PhysicsShapeQueryParameters2D.new()
		query.shape = collision_shape.shape
		query.transform = collision_shape.global_transform
		query.collision_mask = _object_body.collision_mask
		query.exclude = [_object_body.get_rid()]
		query.collide_with_bodies = true
		query.collide_with_areas = false

		var results := space_state.intersect_shape(query, 8)
		for result in results:
			var collider = result.get("collider")
			if collider is QuiverCharacter:
				_interact_if_ready(collider)
				return


func _interact_if_ready(character: QuiverCharacter) -> void:
	if character == null:
		return

	var now := Time.get_ticks_msec()
	var character_id := character.get_instance_id()
	var last_time := int(_last_interact_msec_by_id.get(character_id, -999999))
	if float(now - last_time) < repeat_interact_cooldown * 1000.0:
		return

	_last_interact_msec_by_id[character_id] = now
	interact(character)


func _collect_collision_shapes(root: Node) -> void:
	for child in root.get_children():
		if child is CollisionShape2D:
			_collision_shapes.append(child as CollisionShape2D)
		_collect_collision_shapes(child)
