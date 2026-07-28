extends LabMeleeWeapon


func _ready() -> void:
	hit_start_delay = 0.055
	visual_lunge_distance = 1.0
	slash_peak_alpha = 0.3
	slash_color = Color(0.98, 0.93, 0.68, 1.0)
	hit_flash_color = Color(1.0, 0.96, 0.78, 1.0)
	projectile_cut_color = Color(0.94, 0.96, 1.0, 0.9)
	super._ready()
