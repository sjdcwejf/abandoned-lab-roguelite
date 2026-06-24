extends Node


signal volume_changed(bus_name: String, linear_value: float)
signal display_mode_changed(display_mode: String)
signal language_changed(language_code: String)
signal settings_loaded

const SETTINGS_PATH := "user://settings.cfg"
const BUS_NAMES := ["Master", "Music", "SFX"]
const DISPLAY_MODE_WINDOWED := "windowed"
const DISPLAY_MODE_FULLSCREEN := "fullscreen"
const DEFAULT_DISPLAY_MODE := DISPLAY_MODE_WINDOWED
const LANGUAGE_ZH := "zh"
const LANGUAGE_EN := "en"
const DEFAULT_LANGUAGE := LANGUAGE_ZH
const DEFAULT_VOLUMES := {
	"Master": 0.8,
	"Music": 0.7,
	"SFX": 0.85,
}
const UI_TEXT := {
	"main_protocol": {
		"zh": "弥赛亚动力 / 封存协议",
		"en": "Messiah Dynamics / Sealing Protocol",
	},
	"main_title": {
		"zh": "生化协议：熵区",
		"en": "Biochemical Protocol: Entropy Zone",
	},
	"main_subtitle": {
		"zh": "极渊岛地下封存设施 / 熵区接入终端",
		"en": "Abyss Island Containment Facility / Entropy Access Terminal",
	},
	"main_status": {
		"zh": "极渊岛地下设施信号恢复。封存对象等待唤醒。",
		"en": "Facility signal restored. Containment subjects await activation.",
	},
	"main_start": {
		"zh": "开始游戏",
		"en": "Start Game",
	},
	"settings": {
		"zh": "设置",
		"en": "Settings",
	},
	"main_quit": {
		"zh": "退出游戏",
		"en": "Quit Game",
	},
	"version": {
		"zh": "原型构建 0.1.59",
		"en": "Prototype Build 0.1.59",
	},
	"settings_title": {
		"zh": "设置",
		"en": "Settings",
	},
	"audio_section": {
		"zh": "音量",
		"en": "Audio",
	},
	"master_volume": {
		"zh": "主音量",
		"en": "Master",
	},
	"music_volume": {
		"zh": "音乐",
		"en": "Music",
	},
	"sfx_volume": {
		"zh": "音效",
		"en": "SFX",
	},
	"display_section": {
		"zh": "显示",
		"en": "Display",
	},
	"window_mode": {
		"zh": "显示模式",
		"en": "Window Mode",
	},
	"windowed": {
		"zh": "窗口",
		"en": "Windowed",
	},
	"fullscreen": {
		"zh": "全屏",
		"en": "Fullscreen",
	},
	"language_section": {
		"zh": "语言",
		"en": "Language",
	},
	"language": {
		"zh": "语言",
		"en": "Language",
	},
	"language_zh": {
		"zh": "中文",
		"en": "Chinese",
	},
	"language_en": {
		"zh": "英语",
		"en": "English",
	},
	"restore_defaults": {
		"zh": "恢复默认",
		"en": "Restore Defaults",
	},
	"back": {
		"zh": "返回",
		"en": "Back",
	},
	"pause_status": {
		"zh": "封存行动 / 暂停",
		"en": "Containment Run / Paused",
	},
	"pause_title": {
		"zh": "协议暂挂",
		"en": "Protocol Suspended",
	},
	"resume_game": {
		"zh": "继续游戏",
		"en": "Resume",
	},
	"restart_run": {
		"zh": "重新开始本局",
		"en": "Restart Run",
	},
	"return_main_menu": {
		"zh": "返回主菜单",
		"en": "Return to Main Menu",
	},
	"pause_hint": {
		"zh": "按 Esc 继续行动",
		"en": "Press Esc to resume",
	},
	"restart_confirm_title": {
		"zh": "重新开始本局？",
		"en": "Restart this run?",
	},
	"restart_confirm_desc": {
		"zh": "当前流程进度将丢失，并从角色选择重新开始。",
		"en": "Current progress will be lost and the run will restart from character selection.",
	},
	"confirm_restart": {
		"zh": "确认重开",
		"en": "Restart",
	},
	"return_confirm_title": {
		"zh": "终止本次封存行动？",
		"en": "Abort this containment run?",
	},
	"return_confirm_desc": {
		"zh": "当前流程进度将丢失，确认返回主菜单？",
		"en": "Current progress will be lost. Return to the main menu?",
	},
	"confirm_return": {
		"zh": "确认返回",
		"en": "Return",
	},
	"cancel": {
		"zh": "取消",
		"en": "Cancel",
	},
}

var _volumes := DEFAULT_VOLUMES.duplicate()
var _display_mode := DEFAULT_DISPLAY_MODE
var _language := DEFAULT_LANGUAGE


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_ensure_audio_buses()
	load_settings()


func set_bus_volume(bus_name: String, linear_value: float, save_immediately := false) -> void:
	if not BUS_NAMES.has(bus_name):
		push_warning("未知音频总线：%s" % bus_name)
		return

	var clamped_value := clampf(linear_value, 0.0, 1.0)
	_volumes[bus_name] = clamped_value
	_apply_bus_volume(bus_name, clamped_value)
	volume_changed.emit(bus_name, clamped_value)
	if save_immediately:
		save_settings()


func set_display_mode(display_mode: String, save_immediately := false) -> void:
	var next_mode := display_mode
	if next_mode != DISPLAY_MODE_FULLSCREEN:
		next_mode = DISPLAY_MODE_WINDOWED

	_display_mode = next_mode
	_apply_display_mode(_display_mode)
	display_mode_changed.emit(_display_mode)
	if save_immediately:
		save_settings()


func get_display_mode() -> String:
	return _display_mode


func set_language(language_code: String, save_immediately := false) -> void:
	var next_language := language_code
	if not [LANGUAGE_ZH, LANGUAGE_EN].has(next_language):
		next_language = DEFAULT_LANGUAGE

	if _language == next_language:
		if save_immediately:
			save_settings()
		return

	_language = next_language
	language_changed.emit(_language)
	if save_immediately:
		save_settings()


func get_language() -> String:
	return _language


func tr_ui(key: String) -> String:
	var entry = UI_TEXT.get(key, null)
	if not entry is Dictionary:
		return key
	var text_options := entry as Dictionary
	return str(text_options.get(_language, text_options.get(DEFAULT_LANGUAGE, key)))


func get_bus_volume(bus_name: String) -> float:
	return float(_volumes.get(bus_name, DEFAULT_VOLUMES.get(bus_name, 1.0)))


func load_settings(path := SETTINGS_PATH) -> void:
	_volumes = DEFAULT_VOLUMES.duplicate()
	_display_mode = DEFAULT_DISPLAY_MODE
	_language = DEFAULT_LANGUAGE
	var config := ConfigFile.new()
	var load_error := config.load(path)
	if load_error != OK and load_error != ERR_FILE_NOT_FOUND:
		push_warning("无法读取设置文件：%s（错误码 %d）" % [path, load_error])

	for bus_name in BUS_NAMES:
		var saved_value := float(config.get_value("audio", bus_name.to_lower(), _volumes[bus_name]))
		_volumes[bus_name] = clampf(saved_value, 0.0, 1.0)
		_apply_bus_volume(bus_name, _volumes[bus_name])

	_display_mode = str(config.get_value("display", "mode", DEFAULT_DISPLAY_MODE))
	if not [DISPLAY_MODE_WINDOWED, DISPLAY_MODE_FULLSCREEN].has(_display_mode):
		_display_mode = DEFAULT_DISPLAY_MODE
	_apply_display_mode(_display_mode)

	_language = str(config.get_value("language", "code", DEFAULT_LANGUAGE))
	if not [LANGUAGE_ZH, LANGUAGE_EN].has(_language):
		_language = DEFAULT_LANGUAGE

	settings_loaded.emit()


func save_settings(path := SETTINGS_PATH) -> int:
	var config := ConfigFile.new()
	for bus_name in BUS_NAMES:
		config.set_value("audio", bus_name.to_lower(), get_bus_volume(bus_name))
	config.set_value("display", "mode", get_display_mode())
	config.set_value("language", "code", get_language())
	var save_error := config.save(path)
	if save_error != OK:
		push_warning("无法保存设置文件：%s（错误码 %d）" % [path, save_error])
	return save_error


func reset_audio_defaults(save_immediately := true) -> void:
	for bus_name in BUS_NAMES:
		set_bus_volume(bus_name, float(DEFAULT_VOLUMES[bus_name]), false)
	if save_immediately:
		save_settings()


func reset_all_defaults(save_immediately := true) -> void:
	for bus_name in BUS_NAMES:
		set_bus_volume(bus_name, float(DEFAULT_VOLUMES[bus_name]), false)
	set_display_mode(DEFAULT_DISPLAY_MODE, false)
	set_language(DEFAULT_LANGUAGE, false)
	if save_immediately:
		save_settings()


func _ensure_audio_buses() -> void:
	for bus_name in ["Music", "SFX"]:
		if AudioServer.get_bus_index(bus_name) >= 0:
			continue
		AudioServer.add_bus()
		var bus_index := AudioServer.get_bus_count() - 1
		AudioServer.set_bus_name(bus_index, bus_name)
		AudioServer.set_bus_send(bus_index, "Master")


func _apply_bus_volume(bus_name: String, linear_value: float) -> void:
	var bus_index := AudioServer.get_bus_index(bus_name)
	if bus_index < 0:
		return
	var muted := linear_value <= 0.0001
	AudioServer.set_bus_mute(bus_index, muted)
	AudioServer.set_bus_volume_db(bus_index, linear_to_db(maxf(linear_value, 0.0001)))


func _apply_display_mode(display_mode: String) -> void:
	if display_mode == DISPLAY_MODE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
