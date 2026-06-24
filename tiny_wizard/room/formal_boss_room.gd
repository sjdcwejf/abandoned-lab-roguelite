extends Room


const BOSS_HEALTH_UI_SCRIPT := preload("res://tiny_wizard/gui/boss_health_ui/boss_health_ui.gd")
const EXIT_BLACK_HOLE_CANDIDATES := [
	Vector2(812, 190),
	Vector2(812, 420),
	Vector2(512, 180),
	Vector2(212, 190),
	Vector2(212, 420),
]

var _boss_health_ui: CanvasLayer
var _boss_node: Node
var _boss_defeat_position := Vector2.ZERO

@onready var exit_black_hole := $ExitBlackHole as LabBlackHole


func _ready() -> void:
	super._ready()
	if exit_black_hole != null:
		exit_black_hole.set_active(false)
	_boss_node = $Enemies.get_node_or_null("PrototypeBoss")
	_setup_boss_health_ui()
	_connect_boss_signals()


func enter_room() -> void:
	super.enter_room()
	if _boss_health_ui != null and not is_cleared and _boss_node != null and is_instance_valid(_boss_node):
		_boss_health_ui.call("show_bar")


func _on_room_cleared() -> void:
	if _boss_health_ui != null:
		_boss_health_ui.call("hide_bar")
	if exit_black_hole != null:
		exit_black_hole.global_position = _choose_exit_black_hole_position(_find_player_global_position())
		exit_black_hole.set_active(true)


func _setup_boss_health_ui() -> void:
	_boss_health_ui = BOSS_HEALTH_UI_SCRIPT.new() as CanvasLayer
	if _boss_health_ui == null:
		return
	add_child(_boss_health_ui)
	if _boss_node != null:
		_boss_health_ui.call("bind_boss", _boss_node)


func _connect_boss_signals() -> void:
	if _boss_node == null or not _boss_node.has_signal("boss_defeated"):
		return

	var defeated_callable := Callable(self, "_on_boss_defeated")
	if not _boss_node.is_connected("boss_defeated", defeated_callable):
		_boss_node.connect("boss_defeated", defeated_callable)


func _on_boss_defeated() -> void:
	if _boss_node is Node2D:
		_boss_defeat_position = (_boss_node as Node2D).global_position
	for direction in [Direction.RIGHT, Direction.DOWN, Direction.LEFT, Direction.UP]:
		open_door(direction)
	_mark_room_cleared()


func _choose_exit_black_hole_position(player_global_position: Variant = null) -> Vector2:
	var avoid_positions: Array[Vector2] = []
	if player_global_position is Vector2:
		avoid_positions.append(player_global_position as Vector2)
	if _boss_defeat_position != Vector2.ZERO:
		avoid_positions.append(_boss_defeat_position)
	if avoid_positions.is_empty():
		return get_room_global_position() + Vector2(812, 420)

	var best_position := get_room_global_position() + EXIT_BLACK_HOLE_CANDIDATES[0]
	var best_score := -1.0
	for candidate_local: Vector2 in EXIT_BLACK_HOLE_CANDIDATES:
		var candidate_global := get_room_global_position() + candidate_local
		var candidate_score := INF
		for avoid_position: Vector2 in avoid_positions:
			candidate_score = minf(candidate_score, candidate_global.distance_squared_to(avoid_position))
		if candidate_score > best_score:
			best_score = candidate_score
			best_position = candidate_global

	return best_position


func _find_player_global_position() -> Variant:
	var player := _find_player_node(get_tree().current_scene)
	if player == null:
		return null
	return player.global_position


func _find_player_node(root: Node) -> Node2D:
	if root == null:
		return null
	if root is Node2D and root.has_node("Visual/WeaponHolder"):
		return root as Node2D
	for child in root.get_children():
		var player := _find_player_node(child)
		if player != null:
			return player
	return null
