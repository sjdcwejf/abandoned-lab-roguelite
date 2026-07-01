extends SceneTree


const SCENES := [
	"res://tiny_wizard/interactable_objects/cryo_zone/cryo_zone.tscn",
	"res://tiny_wizard/interactable_objects/cryo_pod/cryo_pod.tscn",
	"res://tiny_wizard/enemies/frostbitten_infected/frostbitten_infected.tscn",
	"res://tiny_wizard/enemies/stasis_crawler/stasis_crawler.tscn",
	"res://tiny_wizard/enemies/cryo_spitter/cryo_projectile.tscn",
	"res://tiny_wizard/enemies/cryo_spitter/cryo_spitter.tscn",
	"res://tiny_wizard/enemies/ice_core_guardian/ice_core_guardian.tscn",
	"res://tiny_wizard/enemies/subject_zero_cryo/subject_zero_cryo.tscn",
	"res://tiny_wizard/room/room_types/lab_cryo_start_room.tscn",
	"res://tiny_wizard/room/room_types/lab_cryo_combat_room.tscn",
	"res://tiny_wizard/room/room_types/lab_cryo_pod_room.tscn",
	"res://tiny_wizard/room/room_types/lab_cryo_vent_room.tscn",
	"res://tiny_wizard/room/room_types/lab_cryo_reward_room.tscn",
	"res://tiny_wizard/room/room_types/lab_cryo_elite_room.tscn",
	"res://tiny_wizard/room/room_types/lab_cryo_boss_antechamber.tscn",
	"res://tiny_wizard/room/room_types/lab_cryo_boss_room.tscn",
]

const RESOURCES := [
	"res://tiny_wizard/build/chapter3_relics/condensation_protocol.tres",
	"res://tiny_wizard/build/chapter3_relics/stasis_protocol.tres",
	"res://tiny_wizard/build/chapter3_relics/thermal_lining.tres",
	"res://tiny_wizard/build/chapter3_relics/broken_coolant_valve.tres",
	"res://tiny_wizard/build/chapter3_relics/stasis_tag.tres",
]


func _initialize() -> void:
	var has_error := false
	for scene_path in SCENES:
		var packed := load(scene_path) as PackedScene
		if packed == null:
			push_error("Failed to load cryogenic scene: %s" % scene_path)
			has_error = true
			continue

		var instance := packed.instantiate()
		if instance == null:
			push_error("Failed to instantiate cryogenic scene: %s" % scene_path)
			has_error = true
			continue

		instance.queue_free()

	for resource_path in RESOURCES:
		var resource := load(resource_path)
		if resource == null:
			push_error("Failed to load cryogenic resource: %s" % resource_path)
			has_error = true

	if has_error:
		quit(1)
		return

	print("Cryogenic chapter load check passed.")
	quit(0)
