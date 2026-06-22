class_name LabAudioSettingsPanel
extends PanelContainer


signal back_requested

const CHINESE_FONT_BOOTSTRAP := preload("res://tiny_wizard/gui/chinese_font_bootstrap.gd")

@onready var master_slider: HSlider = %MasterSlider
@onready var music_slider: HSlider = %MusicSlider
@onready var sfx_slider: HSlider = %SFXSlider
@onready var master_value: Label = %MasterValue
@onready var music_value: Label = %MusicValue
@onready var sfx_value: Label = %SFXValue
@onready var restore_button: Button = %RestoreButton
@onready var back_button: Button = %BackButton


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	CHINESE_FONT_BOOTSTRAP.apply_to_tree(self)
	master_slider.value_changed.connect(_on_master_changed)
	music_slider.value_changed.connect(_on_music_changed)
	sfx_slider.value_changed.connect(_on_sfx_changed)
	master_slider.drag_ended.connect(_on_slider_drag_ended)
	music_slider.drag_ended.connect(_on_slider_drag_ended)
	sfx_slider.drag_ended.connect(_on_slider_drag_ended)
	restore_button.pressed.connect(_on_restore_pressed)
	back_button.pressed.connect(_on_back_pressed)
	sync_from_settings()


func show_settings() -> void:
	sync_from_settings()
	visible = true
	master_slider.grab_focus()


func sync_from_settings() -> void:
	_set_slider_without_signal(master_slider, GameSettings.get_bus_volume("Master") * 100.0)
	_set_slider_without_signal(music_slider, GameSettings.get_bus_volume("Music") * 100.0)
	_set_slider_without_signal(sfx_slider, GameSettings.get_bus_volume("SFX") * 100.0)
	_refresh_value_labels()


func _on_master_changed(value: float) -> void:
	GameSettings.set_bus_volume("Master", value / 100.0, false)
	master_value.text = _format_percent(value)


func _on_music_changed(value: float) -> void:
	GameSettings.set_bus_volume("Music", value / 100.0, false)
	music_value.text = _format_percent(value)


func _on_sfx_changed(value: float) -> void:
	GameSettings.set_bus_volume("SFX", value / 100.0, false)
	sfx_value.text = _format_percent(value)


func _on_slider_drag_ended(_value_changed: bool) -> void:
	GameSettings.save_settings()


func _on_restore_pressed() -> void:
	GameSettings.reset_audio_defaults(true)
	sync_from_settings()


func _on_back_pressed() -> void:
	GameSettings.save_settings()
	visible = false
	back_requested.emit()


func _set_slider_without_signal(slider: HSlider, value: float) -> void:
	slider.set_value_no_signal(clampf(value, slider.min_value, slider.max_value))


func _refresh_value_labels() -> void:
	master_value.text = _format_percent(master_slider.value)
	music_value.text = _format_percent(music_slider.value)
	sfx_value.text = _format_percent(sfx_slider.value)


func _format_percent(value: float) -> String:
	return "%d%%" % roundi(value)
