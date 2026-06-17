class_name CharacterSelectScreen
extends CanvasLayer


signal character_selected(character_id: String)

const CHINESE_FONT_BOOTSTRAP := preload("res://tiny_wizard/gui/chinese_font_bootstrap.gd")
const TIEMU_ID := "tiemu"
const LIUYING_ID := "liuying"
const FENGQUN_ID := "fengqun"
const SHITONG_ID := "shitong"

@onready var tiemu_card: Button = $Root/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/Choices/TiemuCard
@onready var liuying_card: Button = $Root/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/Choices/LiuyingCard
@onready var fengqun_card: Button = $Root/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/Choices/FengqunCard
@onready var shitong_card: Button = $Root/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/Choices/ShitongCard


func _ready() -> void:
	CHINESE_FONT_BOOTSTRAP.apply_to_tree(self)
	tiemu_card.pressed.connect(_on_tiemu_pressed)
	liuying_card.pressed.connect(_on_liuying_pressed)
	fengqun_card.pressed.connect(_on_fengqun_pressed)
	shitong_card.pressed.connect(_on_shitong_pressed)


func _on_tiemu_pressed() -> void:
	character_selected.emit(TIEMU_ID)


func _on_liuying_pressed() -> void:
	character_selected.emit(LIUYING_ID)


func _on_fengqun_pressed() -> void:
	character_selected.emit(FENGQUN_ID)


func _on_shitong_pressed() -> void:
	character_selected.emit(SHITONG_ID)
