class_name LabWeaponSheetSprite
extends Sprite2D


signal playback_finished

@export_range(1, 32, 1) var animation_frames := 1
@export_range(1.0, 60.0, 1.0) var animation_fps := 18.0
@export var idle_frame := 0
@export var autoplay_loop := false
@export var autoplay_once := false
@export var free_parent_on_finish := false

var _playing := false
var _looping := false
var _elapsed := 0.0
var _duration := 0.0
var _start_frame := 0
var _end_frame := 0
var _return_frame := 0
var _return_texture: Texture2D
var _return_frame_count := 1


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_apply_frame_layout(animation_frames)
	frame = clampi(idle_frame, 0, maxi(0, hframes - 1))
	if autoplay_loop:
		play_loop(0, animation_frames - 1, animation_fps)
	elif autoplay_once:
		play_once(float(animation_frames) / animation_fps)
	else:
		set_process(false)


func play_once(
	duration: float,
	start_frame := 0,
	end_frame := -1,
	return_frame := -1
) -> void:
	_playing = true
	_looping = false
	_elapsed = 0.0
	_duration = maxf(duration, 0.01)
	_start_frame = clampi(start_frame, 0, maxi(0, hframes - 1))
	_end_frame = clampi(end_frame if end_frame >= 0 else hframes - 1, _start_frame, maxi(0, hframes - 1))
	_return_frame = clampi(return_frame if return_frame >= 0 else idle_frame, 0, maxi(0, hframes - 1))
	frame = _start_frame
	set_process(true)


func play_loop(start_frame := 0, end_frame := -1, fps := -1.0) -> void:
	_playing = true
	_looping = true
	_elapsed = 0.0
	_start_frame = clampi(start_frame, 0, maxi(0, hframes - 1))
	_end_frame = clampi(end_frame if end_frame >= 0 else hframes - 1, _start_frame, maxi(0, hframes - 1))
	var resolved_fps := fps if fps > 0.0 else animation_fps
	_duration = maxf(float(_end_frame - _start_frame + 1) / resolved_fps, 0.01)
	frame = _start_frame
	set_process(true)


func play_texture_once(
	new_texture: Texture2D,
	frame_count: int,
	duration: float,
	return_texture: Texture2D,
	return_count := 1
) -> void:
	texture = new_texture
	_apply_frame_layout(frame_count)
	_return_texture = return_texture
	_return_frame_count = maxi(1, return_count)
	play_once(duration, 0, frame_count - 1, 0)


func stop_playback(reset_to_idle := true) -> void:
	_playing = false
	_looping = false
	set_process(false)
	if _return_texture != null:
		texture = _return_texture
		_apply_frame_layout(_return_frame_count)
		_return_texture = null
		_return_frame_count = 1
	if reset_to_idle:
		frame = clampi(idle_frame, 0, maxi(0, hframes - 1))


func _process(delta: float) -> void:
	if not _playing:
		set_process(false)
		return

	_elapsed += delta
	if _looping:
		var loop_progress := fmod(_elapsed, _duration) / _duration
		_set_progress_frame(loop_progress)
		return

	var progress := clampf(_elapsed / _duration, 0.0, 1.0)
	_set_progress_frame(progress)
	if progress >= 1.0:
		_finish_playback()


func _set_progress_frame(progress: float) -> void:
	var frame_span := _end_frame - _start_frame
	frame = clampi(_start_frame + int(floor(progress * float(frame_span + 1))), _start_frame, _end_frame)


func _finish_playback() -> void:
	_playing = false
	set_process(false)
	if _return_texture != null:
		texture = _return_texture
		_apply_frame_layout(_return_frame_count)
		_return_texture = null
		_return_frame_count = 1
	frame = clampi(_return_frame, 0, maxi(0, hframes - 1))
	playback_finished.emit()
	if free_parent_on_finish:
		var parent := get_parent()
		if parent != null:
			parent.queue_free()


func _apply_frame_layout(frame_count: int) -> void:
	animation_frames = maxi(1, frame_count)
	hframes = animation_frames
	vframes = 1
