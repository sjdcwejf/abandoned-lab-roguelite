extends QuiverCharacterStats

# This extension adds shield to the character stats

@export_range(1.0, 999.0, 1.0) var max_energy := 100.0:
	set(value):
		max_energy = maxf(1.0, value)
		if current_energy > max_energy:
			current_energy = max_energy
		stats_changed.emit()

@export_range(0.0, 999.0, 0.5) var energy_regen_per_second := 10.0:
	set(value):
		energy_regen_per_second = maxf(0.0, value)
		stats_changed.emit()

var current_shield := 0:
	set(value):
		if value < 0:
			value = 0
		current_shield = value
		stats_changed.emit()

var current_energy := 100.0:
	set(value):
		current_energy = clampf(value, 0.0, max_energy)
		stats_changed.emit()


func set_life_to_max():
	super.set_life_to_max()
	set_energy_to_max()


func set_energy_to_max() -> void:
	current_energy = max_energy


func spend_energy(amount: float) -> bool:
	if amount <= 0.0:
		return true
	if current_energy + 0.001 < amount:
		return false
	current_energy -= amount
	return true


func restore_energy(amount: float) -> void:
	if amount <= 0.0 or current_energy >= max_energy:
		return
	current_energy += amount


# Redefine damage to take into consideration the shield
func damage(amount:int):
	if current_shield > 0:
		amount -= current_shield
		
		if amount > 0:
			current_shield = 0
			super.damage(amount)
		else:
			current_shield = -amount
		
	else:
		super.damage(amount)
