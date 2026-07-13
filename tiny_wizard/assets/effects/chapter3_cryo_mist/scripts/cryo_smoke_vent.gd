class_name CryoSmokeVent
extends Node2D


const SMOKE_ROOT := "res://tiny_wizard/assets/effects/chapter3_cryo_mist/smoke"

@export_enum("smoke_bright_gray", "smoke_middle_gray") var smoke_group := "smoke_middle_gray"
@export_enum("smoke9", "smoke10") var smoke_name := "smoke9"
@export var alpha := 0.32
@export var animation_speed := 0.85
@export var sprite_scale := Vector2(1.0, 0.72)
@export var tint := Color(0.92, 0.98, 1.0, 1.0)
@export var intermittent := false
@export var active_seconds := 2.4
@export var pause_seconds := 2.8

var _sprite: AnimatedSprite2D
var _timer: Timer
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.randomize()
	_build_sprite()
	if intermittent:
		_start_cycle()


func configure(group_value: String, smoke_value: String, alpha_value: float, scale_value: Vector2, speed_value: float, tint_value: Color, intermittent_value: bool, active_value: float, pause_value: float) -> void:
	smoke_group = group_value
	smoke_name = smoke_value
	alpha = alpha_value
	sprite_scale = scale_value
	animation_speed = speed_value
	tint = tint_value
	intermittent = intermittent_value
	active_seconds = active_value
	pause_seconds = pause_value
	if is_inside_tree():
		_apply_sprite_settings()
		if intermittent and _timer == null:
			_start_cycle()


func _build_sprite() -> void:
	_sprite = AnimatedSprite2D.new()
	_sprite.name = "Smoke"
	_sprite.sprite_frames = _load_sprite_frames()
	_sprite.animation = "mist"
	_sprite.centered = true
	_sprite.z_as_relative = false
	_sprite.z_index = -1
	add_child(_sprite)
	_apply_sprite_settings()
	if _sprite.sprite_frames != null and _sprite.sprite_frames.get_frame_count("mist") > 0:
		_sprite.frame = _rng.randi_range(0, _sprite.sprite_frames.get_frame_count("mist") - 1)
	_sprite.flip_h = _rng.randf() > 0.5
	_sprite.play("mist")


func _apply_sprite_settings() -> void:
	if _sprite == null:
		return
	_sprite.modulate = Color(tint.r, tint.g, tint.b, clampf(alpha, 0.12, 0.62))
	_sprite.speed_scale = maxf(animation_speed, 0.72)
	_sprite.scale = sprite_scale * _rng.randf_range(0.96, 1.18)


func _load_sprite_frames() -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.add_animation("mist")
	frames.set_animation_loop("mist", true)
	frames.set_animation_speed("mist", 10.0)
	for path in _smoke_frame_paths():
		var texture := load(path) as Texture2D
		if texture != null:
			frames.add_frame("mist", texture)
	return frames


func _smoke_frame_paths() -> Array[String]:
	var directory_path := "%s/%s/%s" % [SMOKE_ROOT, smoke_group, smoke_name]
	var dir := DirAccess.open(directory_path)
	var paths: Array[String] = []
	if dir == null:
		return paths
	for file_name in dir.get_files():
		if file_name.ends_with(".png"):
			paths.append("%s/%s" % [directory_path, file_name])
	paths.sort_custom(Callable(self, "_compare_frame_paths"))
	return paths


func _compare_frame_paths(a: String, b: String) -> bool:
	return _frame_index(a) < _frame_index(b)


func _frame_index(path: String) -> int:
	var file_name := path.get_file().get_basename()
	var index_text := file_name.get_slice("_", 1)
	return int(index_text)


func _start_cycle() -> void:
	_timer = Timer.new()
	_timer.name = "MistCycleTimer"
	_timer.one_shot = true
	_timer.wait_time = active_seconds
	_timer.timeout.connect(_on_cycle_timer_timeout)
	add_child(_timer)
	_timer.start()


func _on_cycle_timer_timeout() -> void:
	if _sprite == null:
		return
	_sprite.visible = not _sprite.visible
	if _sprite.visible:
		_sprite.frame = _rng.randi_range(0, max(0, _sprite.sprite_frames.get_frame_count("mist") - 1))
		_sprite.play("mist")
		_timer.wait_time = active_seconds
	else:
		_timer.wait_time = pause_seconds
	_timer.start()
