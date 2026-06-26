class_name LabPauseMenu
extends Control


const MAIN_MENU_SCENE := "res://tiny_wizard/gui/main_menu/main_menu.tscn"
const CHINESE_FONT_BOOTSTRAP := preload("res://tiny_wizard/gui/chinese_font_bootstrap.gd")

@onready var pause_panel: PanelContainer = %PausePanel
@onready var resume_button: Button = %ResumeButton
@onready var settings_button: Button = %SettingsButton
@onready var restart_button: Button = %RestartButton
@onready var main_menu_button: Button = %MainMenuButton
@onready var audio_settings: LabAudioSettingsPanel = %AudioSettingsPanel
@onready var return_confirmation: PanelContainer = %ReturnConfirmation
@onready var confirm_return_button: Button = %ConfirmReturnButton
@onready var cancel_return_button: Button = %CancelReturnButton
@onready var restart_confirmation: PanelContainer = %RestartConfirmation
@onready var confirm_restart_button: Button = %ConfirmRestartButton
@onready var cancel_restart_button: Button = %CancelRestartButton
@onready var status_label: Label = $Center/PausePanel/Margin/Layout/Status
@onready var title_label: Label = $Center/PausePanel/Margin/Layout/Title
@onready var hint_label: Label = $Center/PausePanel/Margin/Layout/Hint
@onready var return_title_label: Label = $Center/ReturnConfirmation/Margin/Layout/Title
@onready var return_description_label: Label = $Center/ReturnConfirmation/Margin/Layout/Description
@onready var restart_title_label: Label = $Center/RestartConfirmation/Margin/Layout/Title
@onready var restart_description_label: Label = $Center/RestartConfirmation/Margin/Layout/Description


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	CHINESE_FONT_BOOTSTRAP.apply_to_tree(self)
	resume_button.pressed.connect(resume_game)
	settings_button.pressed.connect(_show_audio_settings)
	restart_button.pressed.connect(_show_restart_confirmation)
	main_menu_button.pressed.connect(_show_return_confirmation)
	audio_settings.back_requested.connect(_show_pause_actions)
	confirm_return_button.pressed.connect(_return_to_main_menu)
	cancel_return_button.pressed.connect(_show_pause_actions)
	confirm_restart_button.pressed.connect(_restart_current_run)
	cancel_restart_button.pressed.connect(_show_pause_actions)
	GameSettings.language_changed.connect(_on_language_changed)
	_refresh_texts()
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
	if audio_settings.visible or return_confirmation.visible or restart_confirmation.visible:
		_show_pause_actions()
		return
	resume_game()


func _show_audio_settings() -> void:
	pause_panel.visible = false
	return_confirmation.visible = false
	restart_confirmation.visible = false
	audio_settings.show_settings()


func _show_return_confirmation() -> void:
	pause_panel.visible = false
	audio_settings.visible = false
	restart_confirmation.visible = false
	return_confirmation.visible = true
	cancel_return_button.grab_focus()


func _show_restart_confirmation() -> void:
	pause_panel.visible = false
	audio_settings.visible = false
	return_confirmation.visible = false
	restart_confirmation.visible = true
	cancel_restart_button.grab_focus()


func _show_pause_actions() -> void:
	pause_panel.visible = true
	audio_settings.visible = false
	return_confirmation.visible = false
	restart_confirmation.visible = false
	if visible:
		resume_button.grab_focus()


func _return_to_main_menu() -> void:
	GameSettings.save_settings()
	visible = false
	get_tree().paused = false
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)


func _restart_current_run() -> void:
	GameSettings.save_settings()
	visible = false
	get_tree().paused = false
	get_tree().reload_current_scene()


func _refresh_texts() -> void:
	status_label.text = GameSettings.tr_ui("pause_status")
	title_label.text = GameSettings.tr_ui("pause_title")
	resume_button.text = GameSettings.tr_ui("resume_game")
	settings_button.text = GameSettings.tr_ui("settings")
	restart_button.text = GameSettings.tr_ui("restart_run")
	main_menu_button.text = GameSettings.tr_ui("return_main_menu")
	hint_label.text = GameSettings.tr_ui("pause_hint")
	return_title_label.text = GameSettings.tr_ui("return_confirm_title")
	return_description_label.text = GameSettings.tr_ui("return_confirm_desc")
	confirm_return_button.text = GameSettings.tr_ui("confirm_return")
	cancel_return_button.text = GameSettings.tr_ui("cancel")
	restart_title_label.text = GameSettings.tr_ui("restart_confirm_title")
	restart_description_label.text = GameSettings.tr_ui("restart_confirm_desc")
	confirm_restart_button.text = GameSettings.tr_ui("confirm_restart")
	cancel_restart_button.text = GameSettings.tr_ui("cancel")


func _on_language_changed(_language_code: String) -> void:
	_refresh_texts()
