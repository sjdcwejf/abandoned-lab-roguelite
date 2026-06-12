extends "res://top-down-shooter-core/gui/player_ui/player_ui.gd"

const HEART_SCENE = preload("res://tiny_wizard/gui/life_ui/heart/heart.tscn")

var max_life := 0
var heart_slots := 0

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
	heart_slots = 0
	if player_stats is QuiverCharacterStats and not player_stats.stats_changed.is_connected(update_callable):
		player_stats.stats_changed.connect(update_callable)
	update_ui()


func update_ui():
	if player_stats == null:
		return

	# label.text = "%d/%d" % [player_stats.current_life, player_stats.max_life]
	
	var needed_heart_slots := ceili(float(player_stats.max_life) / 2.0)
	if needed_heart_slots != heart_slots:
		var difference := needed_heart_slots - heart_slots
		
		if difference > 0:
			for i in range(difference):
				# Create Heart
				var heart = HEART_SCENE.instantiate()
				heart_container.add_child(heart)
		else:
			var to_remove = []
			for i in range(-difference):
				to_remove.append(heart_container.get_child(i))
			for h in to_remove:
				heart_container.remove_child(h)
				h.queue_free()
		
		heart_slots = needed_heart_slots
		max_life = player_stats.max_life
		
	var life := int(player_stats.current_life)
	
	for heart in heart_container.get_children():
		if life>=2:
			heart.set_state(FULL)
			life-=2
		elif life == 1:
			heart.set_state(HALF)
			life -= 1
		elif life <= 0:
			heart.set_state(EMPTY)
			
	var shield_count := 0
	if "current_shield" in player_stats:
		shield_count = int(player_stats.get("current_shield"))
	var difference := ceili(float(shield_count) / 2.0) - shield_container.get_child_count()
	if difference > 0:
		for i in range(difference):
			var shield = HEART_SCENE.instantiate()
			shield_container.add_child(shield)
	else:
		var to_remove = []
		for i in range(-difference):
			to_remove.append(shield_container.get_child(i))
		for s in to_remove:
			shield_container.remove_child(s)
			s.queue_free()
	
	for shield in shield_container.get_children():
		
		if shield_count>=2:
			shield.set_state(FULL_SHIELD)
			shield_count-=2
		elif shield_count == 1:
			shield.set_state(HALF_SHIELD)
			shield_count -= 1
		elif shield_count <= 0:
			shield.set_state(EMPTY)
