class_name CharacterSelectScreen
extends CanvasLayer


signal character_selected(character_id: String)

const PANSHI_ID := "panshi"
const LIUYING_ID := "liuying"
const HUISHENG_ID := "huisheng"
const EXPERIMENTER_ID := PANSHI_ID
const TECHNICIAN_ID := LIUYING_ID
const LEGACY_EXPERIMENTER_ID := "experimenter"
const LEGACY_TECHNICIAN_ID := "containment_technician"

@onready var experimenter_card: Button = $Root/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/Choices/ExperimenterCard
@onready var technician_card: Button = $Root/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/Choices/TechnicianCard
@onready var echo_card: Button = $Root/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/Choices/EchoCard


func _ready() -> void:
	experimenter_card.pressed.connect(_on_experimenter_pressed)
	technician_card.pressed.connect(_on_technician_pressed)
	echo_card.pressed.connect(_on_echo_pressed)


func _on_experimenter_pressed() -> void:
	character_selected.emit(PANSHI_ID)


func _on_technician_pressed() -> void:
	character_selected.emit(LIUYING_ID)


func _on_echo_pressed() -> void:
	character_selected.emit(HUISHENG_ID)
