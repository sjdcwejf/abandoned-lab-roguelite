extends "res://top-down-shooter-core/gui/player_ui/player_ui.gd"

const HEART_SCENE = preload("res://tiny_wizard/gui/life_ui/heart/heart.tscn")

var max_life := 0
var heart_slots := 0
var shield_slots := 0

enum {EMPTY, HALF, FULL, FULL_SHIELD, HALF_SHIELD}

@onready var heart_container = $HBoxContainer/HeartContainer
@onready var shield_container = $HBoxContainer/ShieldContainer

func _ready():
	super._ready()
	update_ui()


func bind_player_stats(new_stats: QuiverCharacterStats) -> void:
	var update_callable := Callable(self, "update_ui")
	if player_stats is QuiverCharacterStats and player_stats.stats_changed.is_connected(update_callable):
		player_stats.stats_changed.disconnect(update_callable)

	player_stats = new_stats
	max_life = 0
	_set_heart_slot_count(0)
	_set_shield_slot_count(0)
	if player_stats is QuiverCharacterStats and not player_stats.stats_changed.is_connected(update_callable):
		player_stats.stats_changed.connect(update_callable)
	update_ui()


func update_ui():
	if player_stats == null:
		return

	var max_life_value := int(player_stats.max_life)
	var current_life := clampi(int(player_stats.current_life), 0, max_life_value)

	var needed_heart_slots := ceili(float(current_life) / 2.0)
	_set_heart_slot_count(needed_heart_slots)
	max_life = max_life_value
		
	var life := current_life
	var odd_life_cap_is_full: bool = max_life_value % 2 == 1 and current_life >= max_life_value
	
	var heart_index := 0
	for heart in heart_container.get_children():
		if odd_life_cap_is_full and heart_index == heart_slots - 1:
			heart.set_state(FULL)
			heart_index += 1
			continue
		if life>=2:
			heart.set_state(FULL)
			life-=2
		elif life == 1:
			heart.set_state(HALF)
			life -= 1
		elif life <= 0:
			heart.set_state(EMPTY)
		heart_index += 1
			
	var shield_count := 0
	if "current_shield" in player_stats:
		shield_count = int(player_stats.get("current_shield"))
	_set_shield_slot_count(ceili(float(shield_count) / 2.0))

	for shield in shield_container.get_children():
		if shield_count >= 2:
			shield.set_state(FULL_SHIELD)
			shield_count -= 2
		elif shield_count == 1:
			shield.set_state(HALF_SHIELD)
			shield_count -= 1


func _set_heart_slot_count(target_count: int) -> void:
	target_count = maxi(0, target_count)
	while heart_container.get_child_count() > target_count:
		var child := heart_container.get_child(heart_container.get_child_count() - 1)
		heart_container.remove_child(child)
		child.queue_free()

	while heart_container.get_child_count() < target_count:
		var heart = HEART_SCENE.instantiate()
		heart_container.add_child(heart)

	heart_slots = target_count


func _set_shield_slot_count(target_count: int) -> void:
	target_count = maxi(0, target_count)
	while shield_container.get_child_count() > target_count:
		var child := shield_container.get_child(shield_container.get_child_count() - 1)
		shield_container.remove_child(child)
		child.queue_free()

	while shield_container.get_child_count() < target_count:
		var shield = HEART_SCENE.instantiate()
		shield_container.add_child(shield)

	shield_slots = target_count
