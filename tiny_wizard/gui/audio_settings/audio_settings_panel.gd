class_name LabAudioSettingsPanel
extends PanelContainer


signal back_requested

const CHINESE_FONT_BOOTSTRAP := preload("res://tiny_wizard/gui/chinese_font_bootstrap.gd")

@onready var master_slider: HSlider = %MasterSlider
@onready var music_slider: HSlider = %MusicSlider
@onready var sfx_slider: HSlider = %SFXSlider
@onready var display_mode_option: OptionButton = %DisplayModeOption
@onready var language_option: OptionButton = %LanguageOption
@onready var title_label: Label = %SettingsTitle
@onready var audio_section_label: Label = %AudioSectionLabel
@onready var display_section_label: Label = %DisplaySectionLabel
@onready var language_section_label: Label = %LanguageSectionLabel
@onready var master_name_label: Label = %MasterNameLabel
@onready var music_name_label: Label = %MusicNameLabel
@onready var sfx_name_label: Label = %SFXNameLabel
@onready var display_mode_label: Label = %DisplayModeLabel
@onready var language_label: Label = %LanguageLabel
@onready var master_value: Label = %MasterValue
@onready var music_value: Label = %MusicValue
@onready var sfx_value: Label = %SFXValue
@onready var restore_button: Button = %RestoreButton
@onready var back_button: Button = %BackButton

var _syncing_options := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	CHINESE_FONT_BOOTSTRAP.apply_to_tree(self)
	_setup_options()
	master_slider.value_changed.connect(_on_master_changed)
	music_slider.value_changed.connect(_on_music_changed)
	sfx_slider.value_changed.connect(_on_sfx_changed)
	master_slider.drag_ended.connect(_on_slider_drag_ended)
	music_slider.drag_ended.connect(_on_slider_drag_ended)
	sfx_slider.drag_ended.connect(_on_slider_drag_ended)
	display_mode_option.item_selected.connect(_on_display_mode_selected)
	language_option.item_selected.connect(_on_language_selected)
	restore_button.pressed.connect(_on_restore_pressed)
	back_button.pressed.connect(_on_back_pressed)
	GameSettings.language_changed.connect(_on_language_changed)
	sync_from_settings()


func show_settings() -> void:
	sync_from_settings()
	visible = true
	master_slider.grab_focus()


func sync_from_settings() -> void:
	_set_slider_without_signal(master_slider, GameSettings.get_bus_volume("Master") * 100.0)
	_set_slider_without_signal(music_slider, GameSettings.get_bus_volume("Music") * 100.0)
	_set_slider_without_signal(sfx_slider, GameSettings.get_bus_volume("SFX") * 100.0)
	_syncing_options = true
	_refresh_texts()
	_select_option_by_metadata(display_mode_option, GameSettings.get_display_mode())
	_select_option_by_metadata(language_option, GameSettings.get_language())
	_syncing_options = false
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


func _on_display_mode_selected(index: int) -> void:
	if _syncing_options:
		return
	var mode := str(display_mode_option.get_item_metadata(index))
	GameSettings.set_display_mode(mode, true)


func _on_language_selected(index: int) -> void:
	if _syncing_options:
		return
	var language_code := str(language_option.get_item_metadata(index))
	GameSettings.set_language(language_code, true)
	sync_from_settings()


func _on_slider_drag_ended(_value_changed: bool) -> void:
	GameSettings.save_settings()


func _on_restore_pressed() -> void:
	GameSettings.reset_all_defaults(true)
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


func _setup_options() -> void:
	display_mode_option.clear()
	display_mode_option.add_item("")
	display_mode_option.set_item_metadata(0, GameSettings.DISPLAY_MODE_WINDOWED)
	display_mode_option.add_item("")
	display_mode_option.set_item_metadata(1, GameSettings.DISPLAY_MODE_FULLSCREEN)

	language_option.clear()
	language_option.add_item("")
	language_option.set_item_metadata(0, GameSettings.LANGUAGE_ZH)
	language_option.add_item("")
	language_option.set_item_metadata(1, GameSettings.LANGUAGE_EN)


func _refresh_texts() -> void:
	title_label.text = GameSettings.tr_ui("settings_title")
	audio_section_label.text = GameSettings.tr_ui("audio_section")
	display_section_label.text = GameSettings.tr_ui("display_section")
	language_section_label.text = GameSettings.tr_ui("language_section")
	master_name_label.text = GameSettings.tr_ui("master_volume")
	music_name_label.text = GameSettings.tr_ui("music_volume")
	sfx_name_label.text = GameSettings.tr_ui("sfx_volume")
	display_mode_label.text = GameSettings.tr_ui("window_mode")
	language_label.text = GameSettings.tr_ui("language")
	restore_button.text = GameSettings.tr_ui("restore_defaults")
	back_button.text = GameSettings.tr_ui("back")

	display_mode_option.set_item_text(0, GameSettings.tr_ui("windowed"))
	display_mode_option.set_item_text(1, GameSettings.tr_ui("fullscreen"))
	language_option.set_item_text(0, GameSettings.tr_ui("language_zh"))
	language_option.set_item_text(1, GameSettings.tr_ui("language_en"))


func _select_option_by_metadata(option: OptionButton, metadata: String) -> void:
	for index in range(option.get_item_count()):
		if str(option.get_item_metadata(index)) == metadata:
			option.select(index)
			return
	option.select(0)


func _on_language_changed(_language_code: String) -> void:
	_refresh_texts()
