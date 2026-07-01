class_name RelicPickup
extends Node2D

signal picked_up(relic_definition: BuildItemDefinition)

const CHINESE_FONT_BOOTSTRAP := preload("res://tiny_wizard/gui/chinese_font_bootstrap.gd")

@export var relic_definition: BuildItemDefinition

var _candidate_character: Node2D
var _picked_up := false

@onready var pickup_area: Area2D = $PickupArea
@onready var prompt: Label = $Prompt
@onready var name_label: Label = $NameLabel
@onready var icon_rect: TextureRect = $IconPanel/Icon


func _ready() -> void:
	CHINESE_FONT_BOOTSTRAP.apply_to_tree(self)
	prompt.visible = false
	_refresh_display()
	pickup_area.body_entered.connect(_on_pickup_area_body_entered)
	pickup_area.body_exited.connect(_on_pickup_area_body_exited)


func _process(_delta: float) -> void:
	if _picked_up or _candidate_character == null:
		return
	if Input.is_action_just_pressed("interact"):
		_try_pick_up(_candidate_character)


func _try_pick_up(character: Node2D) -> void:
	var relic_controller := _find_relic_controller(character)
	if relic_controller == null:
		print("Relic pickup failed: character has no RelicController.")
		return

	var can_add := relic_controller.can_add_relic(relic_definition)
	if not can_add.success:
		print("Relic pickup failed for %s: %s" % [_get_relic_id_text(), can_add.message])
		return

	var result := relic_controller.add_relic(relic_definition)
	if not result.success:
		print("Relic pickup failed for %s: %s" % [_get_relic_id_text(), result.message])
		return

	_picked_up = true
	pickup_area.set_deferred("monitoring", false)
	picked_up.emit(relic_definition)
	queue_free()


func _find_relic_controller(character: Node) -> RelicController:
	if character == null:
		return null
	var controller := character.get_node_or_null("RelicController") as RelicController
	if controller != null:
		return controller
	for child in character.get_children():
		controller = child as RelicController
		if controller != null:
			return controller
	return null


func _refresh_display() -> void:
	if relic_definition == null:
		name_label.text = "Unknown Relic"
		icon_rect.texture = null
		return

	name_label.text = _get_relic_display_name()
	icon_rect.texture = relic_definition.icon


func _get_relic_display_name() -> String:
	if relic_definition == null:
		return ""
	if relic_definition.display_name != "":
		return relic_definition.display_name
	if relic_definition.placeholder_text != "":
		return relic_definition.placeholder_text
	return str(relic_definition.item_id)


func _get_relic_id_text() -> String:
	if relic_definition == null:
		return "<null>"
	return str(relic_definition.item_id)


func _on_pickup_area_body_entered(body: Node2D) -> void:
	if _picked_up:
		return
	if _find_relic_controller(body) == null:
		return
	_candidate_character = body
	prompt.visible = true


func _on_pickup_area_body_exited(body: Node2D) -> void:
	if body != _candidate_character:
		return
	_candidate_character = null
	prompt.visible = false
