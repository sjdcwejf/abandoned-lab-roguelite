extends SceneTree


const SCENES := [
	"res://tiny_wizard/interactable_objects/data_archive_terminal/data_archive_terminal.tscn",
	"res://tiny_wizard/room/room_types/lab_data_core_start_room.tscn",
	"res://tiny_wizard/room/room_types/lab_data_core_server_room.tscn",
	"res://tiny_wizard/room/room_types/lab_data_core_comm_room.tscn",
	"res://tiny_wizard/room/room_types/lab_data_core_satellite_room.tscn",
	"res://tiny_wizard/room/room_types/lab_data_core_archive_room.tscn",
	"res://tiny_wizard/room/room_types/lab_data_core_supply_station_room.tscn",
	"res://tiny_wizard/room/room_types/lab_data_core_boss_room.tscn",
]


func _initialize() -> void:
	var has_error := false
	for scene_path in SCENES:
		var packed := load(scene_path) as PackedScene
		if packed == null:
			push_error("Failed to load data core scene: %s" % scene_path)
			has_error = true
			continue

		var instance := packed.instantiate()
		if instance == null:
			push_error("Failed to instantiate data core scene: %s" % scene_path)
			has_error = true
			continue

		instance.queue_free()

	if has_error:
		quit(1)
		return

	print("Data core scene load check passed.")
	quit(0)
