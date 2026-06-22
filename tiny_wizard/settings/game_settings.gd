extends Node


signal volume_changed(bus_name: String, linear_value: float)
signal settings_loaded

const SETTINGS_PATH := "user://settings.cfg"
const BUS_NAMES := ["Master", "Music", "SFX"]
const DEFAULT_VOLUMES := {
	"Master": 0.8,
	"Music": 0.7,
	"SFX": 0.85,
}

var _volumes := DEFAULT_VOLUMES.duplicate()


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


func get_bus_volume(bus_name: String) -> float:
	return float(_volumes.get(bus_name, DEFAULT_VOLUMES.get(bus_name, 1.0)))


func load_settings(path := SETTINGS_PATH) -> void:
	_volumes = DEFAULT_VOLUMES.duplicate()
	var config := ConfigFile.new()
	var load_error := config.load(path)
	if load_error != OK and load_error != ERR_FILE_NOT_FOUND:
		push_warning("无法读取设置文件：%s（错误码 %d）" % [path, load_error])

	for bus_name in BUS_NAMES:
		var saved_value := float(config.get_value("audio", bus_name.to_lower(), _volumes[bus_name]))
		_volumes[bus_name] = clampf(saved_value, 0.0, 1.0)
		_apply_bus_volume(bus_name, _volumes[bus_name])

	settings_loaded.emit()


func save_settings(path := SETTINGS_PATH) -> int:
	var config := ConfigFile.new()
	for bus_name in BUS_NAMES:
		config.set_value("audio", bus_name.to_lower(), get_bus_volume(bus_name))
	var save_error := config.save(path)
	if save_error != OK:
		push_warning("无法保存设置文件：%s（错误码 %d）" % [path, save_error])
	return save_error


func reset_audio_defaults(save_immediately := true) -> void:
	for bus_name in BUS_NAMES:
		set_bus_volume(bus_name, float(DEFAULT_VOLUMES[bus_name]), false)
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
