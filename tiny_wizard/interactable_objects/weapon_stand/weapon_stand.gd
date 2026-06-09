extends Node2D


@export var weapon_scene: PackedScene
@export var weapon_label := "Test Sword"
@export var equip_on_pickup := false

var _candidate_character: Node2D
var _picked_up := false

@onready var pickup_area: Area2D = $PickupArea
@onready var prompt: CanvasItem = $Prompt
@onready var weapon_preview: CanvasItem = $WeaponPreview
@onready var stand_light: CanvasItem = $StandLight


func _ready() -> void:
	prompt.visible = false
	pickup_area.body_entered.connect(_on_pickup_area_body_entered)
	pickup_area.body_exited.connect(_on_pickup_area_body_exited)


func _process(_delta: float) -> void:
	if _picked_up or _candidate_character == null:
		return
	if Input.is_action_just_pressed("interact"):
		_pick_up(_candidate_character)


func _pick_up(character: Node2D) -> void:
	if weapon_scene == null:
		return

	var weapon_holder := character.get_node_or_null("Visual/WeaponHolder")
	if weapon_holder == null or not weapon_holder.has_method("add_weapon_scene"):
		return

	var slot_index := int(weapon_holder.add_weapon_scene(weapon_scene, equip_on_pickup))
	if slot_index < 0:
		return

	_picked_up = true
	prompt.visible = false
	weapon_preview.visible = false
	stand_light.visible = false
	pickup_area.monitoring = false
	print("%s added to weapon slot %d." % [weapon_label, slot_index + 1])


func _on_pickup_area_body_entered(body: Node2D) -> void:
	if _picked_up or not body.has_node("Visual/WeaponHolder"):
		return
	_candidate_character = body
	prompt.visible = true


func _on_pickup_area_body_exited(body: Node2D) -> void:
	if body != _candidate_character:
		return
	_candidate_character = null
	prompt.visible = false
