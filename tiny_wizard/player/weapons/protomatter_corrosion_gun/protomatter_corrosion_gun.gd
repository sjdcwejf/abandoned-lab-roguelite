class_name LabProtomatterCorrosionGun
extends LabProjectileWeapon


@onready var weapon_sprite = $WeaponSprite
@onready var muzzle_flash: CanvasItem = $MuzzleFlash

var _sprite_rest_position := Vector2.ZERO
var _fire_tween: Tween


func _ready() -> void:
	_sprite_rest_position = weapon_sprite.position
	muzzle_flash.visible = false


func fire_projectile() -> bool:
	var fired := super.fire_projectile()
	if fired:
		_play_fire_feedback()
	return fired


func _play_fire_feedback() -> void:
	if _fire_tween != null and _fire_tween.is_valid():
		_fire_tween.kill()

	weapon_sprite.position = _sprite_rest_position
	weapon_sprite.play_once(0.18)
	muzzle_flash.visible = true
	muzzle_flash.modulate.a = 1.0
	muzzle_flash.scale = Vector2(0.85, 0.85)

	_fire_tween = create_tween()
	_fire_tween.set_parallel(true)
	_fire_tween.tween_property(weapon_sprite, "position", _sprite_rest_position + Vector2(-4, 0), 0.04)
	_fire_tween.tween_property(muzzle_flash, "scale", Vector2(1.15, 1.15), 0.05)
	_fire_tween.tween_property(muzzle_flash, "modulate:a", 0.0, 0.08)
	_fire_tween.chain().set_parallel(true)
	_fire_tween.tween_property(weapon_sprite, "position", _sprite_rest_position, 0.08).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_fire_tween.tween_callback(_restore_idle_visual)


func _restore_idle_visual() -> void:
	weapon_sprite.stop_playback()
	muzzle_flash.visible = false
