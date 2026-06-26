extends QuiverInteractMechanic

const CHINESE_FONT_BOOTSTRAP := preload("res://tiny_wizard/gui/chinese_font_bootstrap.gd")
const INTERACTION_FEEDBACK := preload("res://tiny_wizard/gui/interaction_feedback.gd")

# An example of QuiverInteractMechanic that triggers when a character collide with the object's body

# The path to the body of the object (should be a RigidBody2D)
@export var object_body_path : NodePath
@export var overlap_query_interval := 0.08
@export var repeat_interact_cooldown := 0.28
@export var require_interact_input := false
@export var prompt_text := "按 F 交互"
@export var prompt_offset := Vector2(-68, -58)

# Hold the body node
var _object_body : RigidBody2D
var _collision_shapes: Array[CollisionShape2D] = []
var _overlap_query_timer := 0.0
var _last_interact_msec_by_id := {}
var _candidate_character: QuiverCharacter
var _prompt_label: Label


func _ready():
	var node = get_node(object_body_path)
	if node is RigidBody2D:
		_object_body = node

		# This is to make sure the contact with the character will be reported
		_object_body.contact_monitor = true
		_object_body.max_contacts_reported = 8
 
		_object_body.body_entered.connect(self._body_entered)
		_object_body.body_exited.connect(self._body_exited)
		_collect_collision_shapes(_object_body)
		set_physics_process(true)
		set_process(require_interact_input)
		if require_interact_input:
			_create_prompt_label()
		
	else:
		printerr("interact_on_collide: rigidbody_path doesn't give access to a RigidDynamicBody node")


func _process(_delta: float) -> void:
	if not require_interact_input:
		return
	if _candidate_character == null:
		return
	if Input.is_action_just_pressed("interact"):
		_try_input_interact(_candidate_character)


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
		if require_interact_input:
			_set_candidate(body)
		else:
			_interact_if_ready(body)


func _body_exited(body):
	if require_interact_input and body == _candidate_character:
		_set_candidate(null)


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
				if require_interact_input:
					_set_candidate(collider)
				else:
					_interact_if_ready(collider)
				return
	if require_interact_input:
		_set_candidate(null)


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


func _try_input_interact(character: QuiverCharacter) -> void:
	var block_message := _get_interaction_block_message(character)
	if block_message != "":
		INTERACTION_FEEDBACK.show_from(self, block_message, 1.4)
		_refresh_prompt()
		return
	_interact_if_ready(character)


func _set_candidate(character: QuiverCharacter) -> void:
	if _candidate_character == character:
		_refresh_prompt()
		return
	_candidate_character = character
	_refresh_prompt()


func _refresh_prompt() -> void:
	if _prompt_label == null:
		return
	if _candidate_character == null:
		_prompt_label.visible = false
		return
	var text := _get_interaction_prompt(_candidate_character)
	_prompt_label.text = text
	_prompt_label.visible = text != ""


func _get_interaction_prompt(character: QuiverCharacter) -> String:
	var interactable := get_parent()
	if interactable != null and interactable.has_method("get_interaction_prompt"):
		return str(interactable.call("get_interaction_prompt", character))
	return prompt_text


func _get_interaction_block_message(character: QuiverCharacter) -> String:
	var interactable := get_parent()
	if interactable != null and interactable.has_method("get_interaction_block_message"):
		return str(interactable.call("get_interaction_block_message", character))
	return ""


func _create_prompt_label() -> void:
	var prompt_parent := get_parent()
	if prompt_parent == null or not (prompt_parent is Node2D):
		return
	_prompt_label = Label.new()
	_prompt_label.name = "InteractionPrompt"
	_prompt_label.visible = false
	_prompt_label.position = prompt_offset
	_prompt_label.z_index = 120
	_prompt_label.text = prompt_text
	_prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_prompt_label.size = Vector2(136, 26)
	_prompt_label.add_theme_color_override("font_color", Color(0.78, 0.98, 1.0, 1))
	_prompt_label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.86))
	_prompt_label.add_theme_constant_override("shadow_offset_x", 1)
	_prompt_label.add_theme_constant_override("shadow_offset_y", 1)
	_prompt_label.add_theme_font_size_override("font_size", 13)
	prompt_parent.add_child(_prompt_label)
	CHINESE_FONT_BOOTSTRAP.apply_to_tree(_prompt_label)


func _collect_collision_shapes(root: Node) -> void:
	for child in root.get_children():
		if child is CollisionShape2D:
			_collision_shapes.append(child as CollisionShape2D)
		_collect_collision_shapes(child)
