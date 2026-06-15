class_name CharacterSelectScreen
extends CanvasLayer


signal character_selected(character_id: String)

const CHINESE_FONT_BOOTSTRAP := preload("res://tiny_wizard/gui/chinese_font_bootstrap.gd")
const PANSHI_ID := "panshi"
const LIUYING_ID := "liuying"
const HUISHENG_ID := "huisheng"
const SHITONG_ID := "shitong"
const EXPERIMENTER_ID := PANSHI_ID
const TECHNICIAN_ID := LIUYING_ID
const LEGACY_EXPERIMENTER_ID := "experimenter"
const LEGACY_TECHNICIAN_ID := "containment_technician"

@onready var experimenter_card: Button = $Root/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/Choices/ExperimenterCard
@onready var technician_card: Button = $Root/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/Choices/TechnicianCard
@onready var echo_card: Button = $Root/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/Choices/EchoCard
@onready var shitong_card: Button = $Root/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/Choices/ShitongCard


func _ready() -> void:
	CHINESE_FONT_BOOTSTRAP.apply_to_tree(self)
	experimenter_card.pressed.connect(_on_experimenter_pressed)
	technician_card.pressed.connect(_on_technician_pressed)
	echo_card.pressed.connect(_on_echo_pressed)
	shitong_card.pressed.connect(_on_shitong_pressed)


func _on_experimenter_pressed() -> void:
	character_selected.emit(PANSHI_ID)


func _on_technician_pressed() -> void:
	character_selected.emit(LIUYING_ID)


func _on_echo_pressed() -> void:
	character_selected.emit(HUISHENG_ID)


func _on_shitong_pressed() -> void:
	character_selected.emit(SHITONG_ID)
