extends SceneTree


const SCENES := [
	"res://tiny_wizard/interactable_objects/data_archive_terminal/data_archive_terminal.tscn",
	"res://tiny_wizard/room/room_types/lab_data_core_start_room.tscn",
	"res://tiny_wizard/room/room_types/lab_data_core_server_room.tscn",
	"res://tiny_wizard/room/room_types/lab_data_core_comm_room.tscn",
	"res://tiny_wizard/room/room_types/lab_data_core_comm_control_room.tscn",
	"res://tiny_wizard/room/room_types/lab_data_core_archive_room.tscn",
	"res://tiny_wizard/room/room_types/lab_data_core_supply_station_room.tscn",
	"res://tiny_wizard/room/room_types/lab_data_core_elite_room.tscn",
	"res://tiny_wizard/room/room_types/lab_data_core_boss_room.tscn",
	"res://tiny_wizard/enemies/index_pursuer/index_pursuer.tscn",
	"res://tiny_wizard/enemies/port_relay/port_relay.tscn",
	"res://tiny_wizard/enemies/hydraulic_clearance_rig/hydraulic_clearance_rig.tscn",
	"res://tiny_wizard/enemies/r7_executor/r7_executor.tscn",
	"res://tiny_wizard/enemies/t0_trunk_adjudicator/t0_trunk_adjudicator.tscn",
	"res://tiny_wizard/enemies/t0_trunk_adjudicator/t0_forwarded_orb.tscn",
	"res://tiny_wizard/enemies/t0_trunk_adjudicator/t0_compression_plate.tscn",
]

const SCRIPTS := [
	"res://tiny_wizard/enemies/chapter5_linear_projectile.gd",
	"res://tiny_wizard/enemies/chapter5_pixel_telegraph.gd",
	"res://tiny_wizard/enemies/index_pursuer/index_pursuer.gd",
	"res://tiny_wizard/enemies/index_pursuer/index_pursuer_behavior.gd",
	"res://tiny_wizard/enemies/port_relay/port_relay.gd",
	"res://tiny_wizard/enemies/port_relay/port_relay_behavior.gd",
	"res://tiny_wizard/enemies/hydraulic_clearance_rig/hydraulic_clearance_rig.gd",
	"res://tiny_wizard/enemies/hydraulic_clearance_rig/hydraulic_clearance_rig_behavior.gd",
	"res://tiny_wizard/enemies/r7_executor/r7_executor.gd",
	"res://tiny_wizard/enemies/r7_executor/r7_executor_behavior.gd",
	"res://tiny_wizard/enemies/t0_trunk_adjudicator/t0_trunk_adjudicator.gd",
	"res://tiny_wizard/enemies/t0_trunk_adjudicator/t0_behavior.gd",
	"res://tiny_wizard/enemies/t0_trunk_adjudicator/t0_compression_plate.gd",
	"res://tiny_wizard/enemies/t0_trunk_adjudicator/t0_forwarded_orb.gd",
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

		if not _validate_scene(scene_path, instance):
			has_error = true
		instance.free()

	for script_path in SCRIPTS:
		var script := load(script_path) as Script
		if script == null:
			push_error("Failed to load data core script: %s" % script_path)
			has_error = true

	if has_error:
		quit(1)
		return

	print("Data core scene load check passed.")
	quit(0)


func _validate_scene(scene_path: String, instance: Node) -> bool:
	match scene_path:
		"res://tiny_wizard/enemies/t0_trunk_adjudicator/t0_forwarded_orb.tscn":
			return _validate_projectile_frames(instance, 6, scene_path)
		"res://tiny_wizard/enemies/t0_trunk_adjudicator/t0_compression_plate.tscn":
			if not _validate_projectile_frames(instance, 4, scene_path):
				return false
			var shape_node := instance.get_node_or_null("CollisionShape2D") as CollisionShape2D
			var shape := shape_node.shape as RectangleShape2D if shape_node != null else null
			if shape == null or shape.size != Vector2(18.0, 12.0):
				push_error("T-0 compression plate collision does not match its visible 18x12 frame.")
				return false
			return true
		"res://tiny_wizard/room/room_types/lab_data_core_comm_room.tscn":
			return _validate_event_room(instance, "data_comm", "CommTargets", scene_path)
		"res://tiny_wizard/room/room_types/lab_data_core_comm_control_room.tscn":
			return _validate_event_room(instance, "data_comm_control", "ControlNodes", scene_path)
		"res://tiny_wizard/room/room_types/lab_data_core_elite_room.tscn":
			return _validate_elite_room(instance)
	return true


func _validate_projectile_frames(instance: Node, expected_count: int, scene_path: String) -> bool:
	var sprite := instance.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	if sprite == null or sprite.sprite_frames == null:
		push_error("T-0 projectile has no animated pixel sprite: %s" % scene_path)
		return false
	if sprite.sprite_frames.get_frame_count(&"travel") != expected_count:
		push_error("T-0 projectile frame count mismatch: %s" % scene_path)
		return false
	return true


func _validate_event_room(instance: Node, expected_type: String, targets_path: String, scene_path: String) -> bool:
	if str(instance.get("lab_room_type")) != expected_type:
		push_error("Data core event room type mismatch: %s" % scene_path)
		return false
	if str(instance.call("get_room_objective_type")) != "DESTROY_TARGETS":
		push_error("Data core event room must use attackable target objectives: %s" % scene_path)
		return false
	var targets := instance.get_node_or_null(targets_path)
	if targets == null or targets.get_child_count() != 3:
		push_error("Data core event room must contain three attackable targets: %s" % scene_path)
		return false
	var enemies := instance.get_node_or_null("Enemies")
	if enemies == null or enemies.get_child_count() != 2:
		push_error("Data core event room enemy count mismatch: %s" % scene_path)
		return false
	return true


func _validate_elite_room(instance: Node) -> bool:
	var terminal := instance.get_node_or_null("RavenAccessKeyTerminal") as CanvasItem
	if terminal == null or terminal.visible:
		push_error("Data core elite room inherited terminal is still visible.")
		return false
	var blocker := instance.get_node_or_null("TerminalBlocker") as CollisionObject2D
	if blocker == null or blocker.collision_layer != 0 or blocker.collision_mask != 0:
		push_error("Data core elite room inherited terminal blocker is still active.")
		return false
	var shape_node := instance.get_node_or_null("TerminalBlocker/CollisionShape2DRouteSafeA") as CollisionPolygon2D
	if shape_node == null or not shape_node.disabled:
		push_error("Data core elite room inherited terminal collision shape is still active.")
		return false
	return true
