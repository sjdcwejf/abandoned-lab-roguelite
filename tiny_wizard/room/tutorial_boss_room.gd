extends Room


signal tutorial_boss_defeated

var _boss_defeated := false
var _reward_drop_origin := Vector2.ZERO

@onready var exit_black_hole := $ExitBlackHole as LabBlackHole


func _ready() -> void:
	super._ready()
	if exit_black_hole != null:
		exit_black_hole.set_active(false)


func _on_enemies_child_exiting_tree(node: Node) -> void:
	super._on_enemies_child_exiting_tree(node)
	if _boss_defeated:
		return
	if $Enemies.get_child_count() != 1:
		return

	_boss_defeated = true
	if node is Node2D:
		_reward_drop_origin = (node as Node2D).global_position
	else:
		_reward_drop_origin = get_room_global_position() + ROOM_SIZE * 0.5
	tutorial_boss_defeated.emit()


func activate_exit_black_hole() -> void:
	if exit_black_hole != null:
		exit_black_hole.set_active(true)


func get_reward_drop_origin() -> Vector2:
	if _reward_drop_origin == Vector2.ZERO:
		return get_room_global_position() + ROOM_SIZE * 0.5
	return _reward_drop_origin
