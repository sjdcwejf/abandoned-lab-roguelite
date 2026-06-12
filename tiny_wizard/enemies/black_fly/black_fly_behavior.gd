extends QuiverCharacterBehavior


const DECOY_GROUP := "lab_decoy_targets"
const META_DECOY_EXPIRES_AT := "lab_decoy_expires_at"
const SPEED = .6
const CHANGE_DIRECTION_TIME = 1.0

@export var decoy_detection_radius := 260.0
@export var decoy_chase_weight := 5.0

var _t := randf()*CHANGE_DIRECTION_TIME


func _process(delta):	
	var decoy: Node2D = _get_nearest_decoy()
	if decoy != null:
		action.moving_direction = global_position.direction_to(decoy.global_position) * decoy_chase_weight
		return

	_t -= delta
	if _t <= 0:
		action.moving_direction = Vector2.RIGHT.rotated(randf()*2*PI)
		_t = CHANGE_DIRECTION_TIME

func on_wall_collision(collision: KinematicCollision2D)->void:
	action.moving_direction = collision.get_normal()


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
