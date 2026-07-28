extends LabProjectileWeapon


@onready var weapon_sprite = get_node_or_null("WeaponSprite")


func fire_projectile() -> bool:
	var fired := super.fire_projectile()
	if fired and weapon_sprite != null:
		weapon_sprite.play_once(0.11)
	return fired


func unequip() -> void:
	if weapon_sprite != null:
		weapon_sprite.stop_playback()
	super.unequip()
