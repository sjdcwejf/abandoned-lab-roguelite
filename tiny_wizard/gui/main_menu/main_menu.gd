extends Control


const GAME_SCENE := "res://tiny_wizard/main.tscn"
const CHINESE_FONT_BOOTSTRAP := preload("res://tiny_wizard/gui/chinese_font_bootstrap.gd")

@onready var main_actions: VBoxContainer = %MainActions
@onready var start_button: Button = %StartButton
@onready var settings_button: Button = %SettingsButton
@onready var quit_button: Button = %QuitButton
@onready var settings_center: CenterContainer = %SettingsCenter
@onready var audio_settings: LabAudioSettingsPanel = %AudioSettingsPanel


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().paused = false
	CHINESE_FONT_BOOTSTRAP.install()
	CHINESE_FONT_BOOTSTRAP.apply_to_tree(self)
	start_button.pressed.connect(_on_start_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	audio_settings.back_requested.connect(_on_settings_back_requested)
	main_actions.visible = true
	settings_center.visible = false
	start_button.grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("pause_game"):
		return
	if settings_center.visible:
		_on_settings_back_requested()
		get_viewport().set_input_as_handled()


func _on_start_pressed() -> void:
	get_tree().change_scene_to_file(GAME_SCENE)


func _on_settings_pressed() -> void:
	main_actions.visible = false
	settings_center.visible = true
	audio_settings.show_settings()


func _on_settings_back_requested() -> void:
	audio_settings.visible = false
	settings_center.visible = false
	main_actions.visible = true
	settings_button.grab_focus()


func _on_quit_pressed() -> void:
	get_tree().quit()
