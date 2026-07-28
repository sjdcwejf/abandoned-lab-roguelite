extends LabBeamWeapon


@export var beam_sheet: Texture2D

@onready var weapon_sprite = get_node_or_null("WeaponSprite")

var _beam_frames: Array[Texture2D] = []
var _beam_visual_time := 0.0


func _ready() -> void:
	super._ready()
	_build_beam_frames()


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if not _is_firing or _beam_frames.is_empty() or beam == null:
		return
	_beam_visual_time += delta
	var frame_index := int(floor(_beam_visual_time * 14.0)) % _beam_frames.size()
	beam.texture = _beam_frames[frame_index]


func primary_pressed() -> void:
	var was_firing := _is_firing
	super.primary_pressed()
	if not was_firing and weapon_sprite != null:
		weapon_sprite.play_loop(1, 2, 14.0)


func primary_released() -> void:
	super.primary_released()
	if weapon_sprite != null:
		weapon_sprite.stop_playback(false)
		weapon_sprite.play_once(0.1, 3, 3, 0)


func unequip() -> void:
	if weapon_sprite != null:
		weapon_sprite.stop_playback()
	super.unequip()


func _build_beam_frames() -> void:
	_beam_frames.clear()
	if beam_sheet == null:
		return
	for frame_index in range(2):
		var frame_texture := AtlasTexture.new()
		frame_texture.atlas = beam_sheet
		frame_texture.region = Rect2(frame_index * 128, 0, 128, 8)
		_beam_frames.append(frame_texture)
	if beam != null and not _beam_frames.is_empty():
		beam.texture = _beam_frames[0]
