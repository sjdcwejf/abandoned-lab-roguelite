extends SceneTree


const SCENES := [
	"res://tiny_wizard/room/visuals/greenhouse_room_overlay.tscn",
	"res://tiny_wizard/room/room_types/lab_greenhouse_start_room.tscn",
	"res://tiny_wizard/room/room_types/lab_greenhouse_combat_room.tscn",
	"res://tiny_wizard/room/room_types/lab_greenhouse_spore_event_room.tscn",
	"res://tiny_wizard/room/room_types/lab_greenhouse_reward_room.tscn",
	"res://tiny_wizard/room/room_types/lab_greenhouse_weapon_room.tscn",
	"res://tiny_wizard/room/room_types/lab_greenhouse_merchant_room.tscn",
	"res://tiny_wizard/room/room_types/lab_greenhouse_boss_room.tscn",
]


func _initialize() -> void:
	var has_error := false
	for scene_path in SCENES:
		var packed := load(scene_path) as PackedScene
		if packed == null:
			push_error("Failed to load greenhouse scene: %s" % scene_path)
			has_error = true
			continue

		var instance := packed.instantiate()
		if instance == null:
			push_error("Failed to instantiate greenhouse scene: %s" % scene_path)
			has_error = true
			continue

		instance.queue_free()

	if has_error:
		quit(1)
		return

	print("Greenhouse scene load check passed.")
	quit(0)
