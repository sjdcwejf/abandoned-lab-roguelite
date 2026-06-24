extends Control


const GAME_SCENE := "res://tiny_wizard/main.tscn"
const CHINESE_FONT_BOOTSTRAP := preload("res://tiny_wizard/gui/chinese_font_bootstrap.gd")

@onready var main_actions: VBoxContainer = %MainActions
@onready var start_button: Button = %StartButton
@onready var settings_button: Button = %SettingsButton
@onready var quit_button: Button = %QuitButton
@onready var settings_center: CenterContainer = %SettingsCenter
@onready var audio_settings: LabAudioSettingsPanel = %AudioSettingsPanel
@onready var protocol_label: Label = $MainActions/Protocol
@onready var title_label: Label = $MainActions/Title
@onready var subtitle_label: Label = $MainActions/EnglishTitle
@onready var status_label: Label = $MainActions/Status
@onready var version_label: Label = $Version


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().paused = false
	CHINESE_FONT_BOOTSTRAP.install()
	CHINESE_FONT_BOOTSTRAP.apply_to_tree(self)
	start_button.pressed.connect(_on_start_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	audio_settings.back_requested.connect(_on_settings_back_requested)
	GameSettings.language_changed.connect(_on_language_changed)
	_refresh_texts()
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


func _refresh_texts() -> void:
	protocol_label.text = GameSettings.tr_ui("main_protocol")
	title_label.text = GameSettings.tr_ui("main_title")
	subtitle_label.text = GameSettings.tr_ui("main_subtitle")
	status_label.text = GameSettings.tr_ui("main_status")
	start_button.text = GameSettings.tr_ui("main_start")
	settings_button.text = GameSettings.tr_ui("settings")
	quit_button.text = GameSettings.tr_ui("main_quit")
	version_label.text = GameSettings.tr_ui("version")


func _on_language_changed(_language_code: String) -> void:
	_refresh_texts()
