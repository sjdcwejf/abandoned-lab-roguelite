class_name CharacterSelectScreen
extends CanvasLayer


signal character_selected(character_id: String)

const EXPERIMENTER_ID := "experimenter"
const TECHNICIAN_ID := "containment_technician"

@onready var experimenter_card: Button = $Root/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/Choices/ExperimenterCard
@onready var technician_card: Button = $Root/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/Choices/TechnicianCard


func _ready() -> void:
	experimenter_card.pressed.connect(_on_experimenter_pressed)
	technician_card.pressed.connect(_on_technician_pressed)


func _on_experimenter_pressed() -> void:
	character_selected.emit(EXPERIMENTER_ID)


func _on_technician_pressed() -> void:
	character_selected.emit(TECHNICIAN_ID)
