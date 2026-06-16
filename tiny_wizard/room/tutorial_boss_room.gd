extends Room


signal tutorial_boss_defeated

const BOSS_HEALTH_UI_SCRIPT := preload("res://tiny_wizard/gui/boss_health_ui/boss_health_ui.gd")
const EXIT_BLACK_HOLE_CANDIDATES := [
	Vector2(812, 190),
	Vector2(812, 420),
	Vector2(512, 180),
	Vector2(212, 190),
	Vector2(212, 420),
]

var _boss_defeated := false
var _reward_drop_origin := Vector2.ZERO
var _boss_health_ui: CanvasLayer
var _boss_node: Node

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
	if _boss_health_ui != null and not _boss_defeated and _boss_node != null and is_instance_valid(_boss_node):
		_boss_health_ui.call("show_bar")


func _on_enemies_child_exiting_tree(node: Node) -> void:
	super._on_enemies_child_exiting_tree(node)
	if _boss_defeated:
		return
	if $Enemies.get_child_count() != 1:
		return

	_complete_boss_defeat(node)


func activate_exit_black_hole(avoid_global_position: Variant = null) -> void:
	if exit_black_hole != null:
		exit_black_hole.global_position = _choose_exit_black_hole_position(avoid_global_position)
		exit_black_hole.set_active(true)


func get_reward_drop_origin() -> Vector2:
	if _reward_drop_origin == Vector2.ZERO:
		return get_room_global_position() + ROOM_SIZE * 0.5
	return _reward_drop_origin


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
	_complete_boss_defeat(_boss_node)


func _complete_boss_defeat(node: Node) -> void:
	if _boss_defeated:
		return

	_boss_defeated = true
	if _boss_health_ui != null:
		_boss_health_ui.call("hide_bar")
	if node is Node2D:
		_reward_drop_origin = (node as Node2D).global_position
	else:
		_reward_drop_origin = get_room_global_position() + ROOM_SIZE * 0.5
	tutorial_boss_defeated.emit()


func _choose_exit_black_hole_position(avoid_global_position: Variant) -> Vector2:
	if not avoid_global_position is Vector2:
		return get_room_global_position() + Vector2(812, 420)

	var avoid_position := avoid_global_position as Vector2
	var best_position := get_room_global_position() + EXIT_BLACK_HOLE_CANDIDATES[0]
	var best_distance := -1.0
	for candidate_local: Vector2 in EXIT_BLACK_HOLE_CANDIDATES:
		var candidate_global := get_room_global_position() + candidate_local
		var distance := candidate_global.distance_squared_to(avoid_position)
		if distance > best_distance:
			best_distance = distance
			best_position = candidate_global

	return best_position
