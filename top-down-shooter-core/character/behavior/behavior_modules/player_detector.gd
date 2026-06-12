extends Area2D

const DECOY_GROUP := "lab_decoy_targets"
const META_DECOY_EXPIRES_AT := "lab_decoy_expires_at"

@export var decoy_detection_radius := 280.0

var player: QuiverCharacter = null

func player_is_in_range()->bool:
	return _get_priority_target() != null

func get_player_position()->Vector2:
	var target: Node2D = _get_priority_target()
	if target != null:
		return target.global_position
	printerr("Error: PlayerDetector.get_player_position() -> player is not in range, returning Vector2.ZERO")
	return Vector2.ZERO


func _get_priority_target() -> Node2D:
	var decoy: Node2D = _get_nearest_decoy()
	if decoy != null:
		return decoy
	return player


func _get_nearest_decoy() -> Node2D:
	if not is_inside_tree():
		return null

	var nearest_decoy: Node2D = null
	var nearest_distance := INF
	var decoy_nodes: Array[Node] = get_tree().get_nodes_in_group(DECOY_GROUP)
	for decoy_node: Node in decoy_nodes:
		var decoy: Node2D = decoy_node as Node2D
		if decoy == null or not is_instance_valid(decoy):
			continue
		if decoy.has_meta(META_DECOY_EXPIRES_AT) and int(decoy.get_meta(META_DECOY_EXPIRES_AT)) < Time.get_ticks_msec():
			continue

		var distance := global_position.distance_to(decoy.global_position)
		if distance > decoy_detection_radius or distance >= nearest_distance:
			continue
		nearest_decoy = decoy
		nearest_distance = distance

	return nearest_decoy

func _on_player_detector_body_entered(body):
	if body is QuiverCharacter:
		player = body


func _on_player_detector_body_exited(body):
	if body == player:
		player = null
