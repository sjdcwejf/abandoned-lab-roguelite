class_name LabPauseMenu
extends Control


const MAIN_MENU_SCENE := "res://tiny_wizard/gui/main_menu/main_menu.tscn"
const CHINESE_FONT_BOOTSTRAP := preload("res://tiny_wizard/gui/chinese_font_bootstrap.gd")

@onready var pause_panel: PanelContainer = %PausePanel
@onready var resume_button: Button = %ResumeButton
@onready var settings_button: Button = %SettingsButton
@onready var main_menu_button: Button = %MainMenuButton
@onready var audio_settings: LabAudioSettingsPanel = %AudioSettingsPanel
@onready var return_confirmation: PanelContainer = %ReturnConfirmation
@onready var confirm_return_button: Button = %ConfirmReturnButton
@onready var cancel_return_button: Button = %CancelReturnButton


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	CHINESE_FONT_BOOTSTRAP.apply_to_tree(self)
	resume_button.pressed.connect(resume_game)
	settings_button.pressed.connect(_show_audio_settings)
	main_menu_button.pressed.connect(_show_return_confirmation)
	audio_settings.back_requested.connect(_show_pause_actions)
	confirm_return_button.pressed.connect(_return_to_main_menu)
	cancel_return_button.pressed.connect(_show_pause_actions)
	visible = false
	_show_pause_actions()


func open_menu() -> void:
	if visible:
		return
	visible = true
	_show_pause_actions()
	get_tree().paused = true
	resume_button.grab_focus()


func resume_game() -> void:
	if not visible:
		return
	visible = false
	get_tree().paused = false


func is_open() -> bool:
	return visible


func handle_escape() -> void:
	if audio_settings.visible or return_confirmation.visible:
		_show_pause_actions()
		return
	resume_game()


func _show_audio_settings() -> void:
	pause_panel.visible = false
	return_confirmation.visible = false
	audio_settings.show_settings()


func _show_return_confirmation() -> void:
	pause_panel.visible = false
	audio_settings.visible = false
	return_confirmation.visible = true
	cancel_return_button.grab_focus()


func _show_pause_actions() -> void:
	pause_panel.visible = true
	audio_settings.visible = false
	return_confirmation.visible = false
	if visible:
		resume_button.grab_focus()


func _return_to_main_menu() -> void:
	GameSettings.save_settings()
	visible = false
	get_tree().paused = false
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)
