class_name LabRavenMerchant
extends Node2D


@export var merchant_title := "RAVEN ARMORY"
@export_multiline var merchant_message := "Boss signal ahead. Patch your nerves and count your charges.\n\nShop stock is locked for this build. Bring Research Data and Protomatter when the armory opens."

var _candidate_character: Node2D
var _dialog_open := false

@onready var interact_area: Area2D = $InteractArea
@onready var prompt: CanvasItem = $Prompt
@onready var dialog_panel: Control = $DialogPanel
@onready var title_label: Label = $DialogPanel/MarginContainer/VBoxContainer/Title
@onready var message_label: Label = $DialogPanel/MarginContainer/VBoxContainer/Message
@onready var status_light: CanvasItem = $Console/StatusLight


func _ready() -> void:
	prompt.visible = false
	dialog_panel.visible = false
	title_label.text = merchant_title
	message_label.text = merchant_message
	interact_area.body_entered.connect(_on_interact_area_body_entered)
	interact_area.body_exited.connect(_on_interact_area_body_exited)


func _process(_delta: float) -> void:
	if _candidate_character == null:
		return
	if Input.is_action_just_pressed("interact"):
		_set_dialog_open(not _dialog_open)


func _on_interact_area_body_entered(body: Node2D) -> void:
	if not body.has_node("Visual/WeaponHolder"):
		return
	_candidate_character = body
	prompt.visible = true


func _on_interact_area_body_exited(body: Node2D) -> void:
	if body != _candidate_character:
		return
	_candidate_character = null
	prompt.visible = false
	_set_dialog_open(false)


func _set_dialog_open(open: bool) -> void:
	_dialog_open = open
	dialog_panel.visible = _dialog_open
	if status_light is Polygon2D:
		var light := status_light as Polygon2D
		light.color = Color(0.65, 1.0, 0.62, 1.0) if _dialog_open else Color(0.28, 0.9, 0.95, 1.0)
