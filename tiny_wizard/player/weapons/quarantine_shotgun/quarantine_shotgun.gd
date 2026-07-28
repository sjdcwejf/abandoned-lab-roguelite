class_name LabQuarantineShotgun
extends LabProjectileWeapon


@export_range(1, 9, 2) var pellet_count := 5
@export_range(0.0, 60.0, 1.0) var spread_degrees := 30.0

@onready var weapon_visual: Node2D = $WeaponVisual
@onready var weapon_sprite = $WeaponVisual/WeaponSprite
@onready var muzzle_flash: CanvasItem = $MuzzleFlash

var _visual_rest_position := Vector2.ZERO
var _recoil_tween: Tween


func _ready() -> void:
	_visual_rest_position = weapon_visual.position
	muzzle_flash.visible = false


func fire_projectile() -> bool:
	if _cooldown_timer > 0.0 or projectile_scene == null:
		return false

	var spawn_parent := get_spawn_parent()
	if spawn_parent == null:
		return false

	var shot_count := maxi(1, pellet_count)
	for pellet_index in range(shot_count):
		var pellet_direction := aim_direction
		if shot_count > 1:
			var spread_ratio := float(pellet_index) / float(shot_count - 1)
			var angle_offset := deg_to_rad(lerpf(-spread_degrees * 0.5, spread_degrees * 0.5, spread_ratio))
			pellet_direction = aim_direction.rotated(angle_offset)

		var projectile := projectile_scene.instantiate()
		spawn_parent.add_child(projectile)
		if projectile is Node2D:
			projectile.global_position = get_fire_origin()
			projectile.global_rotation = pellet_direction.angle()
		if projectile.has_method("launch"):
			projectile.launch(pellet_direction, owner_character, damage, projectile_speed, collision_mask)

	_cooldown_timer = cooldown * get_fire_cooldown_multiplier()
	_play_recoil()
	return true


func _play_recoil() -> void:
	if weapon_visual == null or muzzle_flash == null:
		return
	if _recoil_tween != null and _recoil_tween.is_valid():
		_recoil_tween.kill()

	weapon_visual.position = _visual_rest_position
	weapon_sprite.play_once(0.22)
	muzzle_flash.visible = true
	muzzle_flash.scale = Vector2(0.7, 0.7)
	muzzle_flash.modulate.a = 1.0

	_recoil_tween = create_tween()
	_recoil_tween.set_parallel(true)
	_recoil_tween.tween_property(weapon_visual, "position", _visual_rest_position + Vector2(-8, 0), 0.045)
	_recoil_tween.tween_property(muzzle_flash, "scale", Vector2(1.25, 1.25), 0.055)
	_recoil_tween.tween_property(muzzle_flash, "modulate:a", 0.0, 0.075)
	_recoil_tween.chain().set_parallel(true)
	_recoil_tween.tween_property(weapon_visual, "position", _visual_rest_position, 0.11).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_recoil_tween.tween_callback(func() -> void: muzzle_flash.visible = false)


func unequip() -> void:
	if weapon_sprite != null:
		weapon_sprite.stop_playback()
	super.unequip()
