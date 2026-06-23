class_name BuildItemPickup
extends Node2D

signal item_installed(item_id: StringName)

@export var definition: BuildItemDefinition

var _candidate_character: Node2D
var _consumed := false

@onready var pickup_area: Area2D = $PickupArea
@onready var prompt: Label = $Prompt
@onready var item_label: Label = $ItemLabel


func _ready() -> void:
	prompt.visible = false
	_refresh_label()
	pickup_area.body_entered.connect(_on_body_entered)
	pickup_area.body_exited.connect(_on_body_exited)


func _process(_delta: float) -> void:
	if not _consumed and _candidate_character != null and Input.is_action_just_pressed("interact"):
		try_pick_up(_candidate_character)


func setup(item_definition: BuildItemDefinition) -> void:
	definition = item_definition
	if is_node_ready():
		_refresh_label()


func try_pick_up(character: Node) -> BuildInstallResult:
	var controller := character.get_node_or_null("TiemuBuildController") as TiemuBuildController if character != null else null
	if controller == null:
		return _failure_result("TiemuBuildController is required")
	var result := controller.install(definition)
	if result.is_success():
		_consumed = true
		item_installed.emit(definition.id)
		queue_free()
	return result


func _failure_result(reason: String) -> BuildInstallResult:
	var result := BuildInstallResult.new()
	result.status = BuildInstallResult.Status.INCOMPATIBLE
	result.item = definition
	result.message = reason
	return result


func _refresh_label() -> void:
	item_label.text = definition.display_name if definition != null else "Build Item"


func _on_body_entered(body: Node2D) -> void:
	if body.get_node_or_null("TiemuBuildController") == null:
		return
	_candidate_character = body
	prompt.visible = true


func _on_body_exited(body: Node2D) -> void:
	if body != _candidate_character:
		return
	_candidate_character = null
	prompt.visible = false
