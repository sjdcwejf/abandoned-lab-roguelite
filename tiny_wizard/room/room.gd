@tool
class_name Room
extends Node2D

enum Direction {RIGHT, DOWN, LEFT, UP}
enum Status {UNEXPLORED, EXPLORED}

const ROOM_SIZE = Vector2(1024,600)
const OBJECTIVE_CLEAR_ENEMIES := "CLEAR_ENEMIES"
const OBJECTIVE_DESTROY_TARGETS := "DESTROY_TARGETS"
const OBJECTIVE_INTERACT_TARGETS := "INTERACT_TARGETS"
const OBJECTIVE_READ_ARCHIVE := "READ_ARCHIVE"
const OBJECTIVE_CHOOSE_REWARD := "CHOOSE_REWARD"
const OBJECTIVE_SHOP := "SHOP"
const OBJECTIVE_BOSS := "BOSS"
const ROOM_STATE_NOT_VISITED := "NOT_VISITED"
const ROOM_STATE_IN_PROGRESS := "IN_PROGRESS"
const ROOM_STATE_COMPLETED := "COMPLETED"
const ROOM_STATE_REWARD_CLAIMED := "REWARD_CLAIMED"

const OPEN_DOORS = [
	preload("res://tiny_wizard/assets/placeholder_art/doors/right_door.png"),
	preload("res://tiny_wizard/assets/placeholder_art/doors/down_door.png"),
	preload("res://tiny_wizard/assets/placeholder_art/doors/left_door.png"),
	preload("res://tiny_wizard/assets/placeholder_art/doors/up_door.png"),
]

const CLOSED_DOORS = [
	preload("res://tiny_wizard/assets/placeholder_art/doors/right_door_closed.png"),
	preload("res://tiny_wizard/assets/placeholder_art/doors/down_door_closed.png"),
	preload("res://tiny_wizard/assets/placeholder_art/doors/left_door_closed.png"),
	preload("res://tiny_wizard/assets/placeholder_art/doors/up_door_closed.png"),
]

const PLAYER_CHARACTER = preload("res://tiny_wizard/player/player_character.tscn")
const GUI_SCENE = preload("res://tiny_wizard/gui/gui.tscn")

@onready var doors = [
	$RoomWalls/RightDoor,
	$RoomWalls/DownDoor,
	$RoomWalls/LeftDoor,
	$RoomWalls/UpDoor,
]

@onready var spawn_points = [
	$RightSpawnPoint,
	$DownSpawnPoint,
	$LeftSpawnPoint,
	$UpSpawnPoint,
]


@export var hide_right_door := false
@export var hide_down_door := false
@export var hide_left_door := false
@export var hide_up_door := false
@export var lock_chests_until_cleared := true

var room_pos := Vector2i.ZERO
var lab_room_type := "combat"
var lab_room_label := "战斗房"
var is_cleared := false
var room_state := ROOM_STATE_NOT_VISITED
var room_objective: Dictionary = {}
var reward_claimed := false
var objective_initial_enemy_count := 0
var pollution_source_total := 0
var pollution_source_remaining := 0

signal door_entered(direction)
signal room_cleared(room: Room)
signal objective_progress_changed(room: Room)

func _ready():
	_normalize_room_blockers(self)
	_ensure_default_room_objective()
	call_deferred("_connect_archive_terminals")
	objective_initial_enemy_count = get_remaining_enemy_count()
	if get_tree().current_scene != self:
		_set_enemies_active(false)
	_update_room_chest_locks()
	# This spawns the player if launching the scene from the editor
	# This allows to run the room and test it without having to launch the game
	if get_tree().current_scene == self:
		var player_node = PLAYER_CHARACTER.instantiate()
		add_child(player_node)
		player_node.position = spawn_points[0].position
		enter_room()
		var gui = GUI_SCENE.instantiate()
		add_child(gui)
		player_node.gui_path = gui.get_path()


func _normalize_room_blockers(root: Node) -> void:
	for child in root.get_children():
		var child_name := String(child.name).to_lower()
		if _is_solid_blocking_prop(child):
			_make_node_blocking(child)
		elif child_name.contains("blocker") and not child_name.contains("door"):
			_make_node_nonblocking(child)
		_normalize_room_blockers(child)


func _is_solid_blocking_prop(node: Node) -> bool:
	var node_name := String(node.name).to_lower()
	return node.is_in_group("solid_blocking_prop") \
		or bool(node.get_meta("solid_blocking_prop", false)) \
		or node_name.contains("solidblocker") \
		or node_name.contains("solid_blocking") \
		or node_name.contains("solidprop")


func _make_node_blocking(node: Node) -> void:
	if node is CollisionObject2D:
		var collision_object := node as CollisionObject2D
		collision_object.collision_layer = 1
		collision_object.collision_mask = 15
	if node is CollisionShape2D:
		(node as CollisionShape2D).disabled = false
	for child in node.get_children():
		_make_node_blocking(child)


func _make_node_nonblocking(node: Node) -> void:
	if node is CollisionObject2D:
		var collision_object := node as CollisionObject2D
		collision_object.collision_layer = 0
		collision_object.collision_mask = 0
	if node is CollisionShape2D:
		(node as CollisionShape2D).disabled = true
	for child in node.get_children():
		_make_node_nonblocking(child)

# Get the position of the room on the level matrix: (0,0), (0,1)...
func get_room_matrix_position()->Vector2i:
	return room_pos

func get_room_global_position()->Vector2:
	return global_position

func get_room_rect()->Rect2:
	return Rect2(
		global_position,
		ROOM_SIZE
	)

func update_doors():
	if hide_right_door: _hide_door(Direction.RIGHT)
	if hide_down_door: _hide_door(Direction.DOWN)
	if hide_left_door: _hide_door(Direction.LEFT)
	if hide_up_door: _hide_door(Direction.UP)

func get_spawning_point(direction):
	var dir = Direction.UP
	if direction.x > 0:
		dir = Direction.RIGHT
	if direction.y > 0:
		dir = Direction.DOWN
	if direction.x < 0:
		dir = Direction.LEFT
	
	return spawn_points[dir]

func enter_room():
	if is_cleared:
		if room_state != ROOM_STATE_REWARD_CLAIMED:
			room_state = ROOM_STATE_COMPLETED
		for d in [Direction.RIGHT, Direction.DOWN, Direction.LEFT, Direction.UP]:
			open_door(d)
		_update_room_chest_locks()
		return

	if room_state == ROOM_STATE_NOT_VISITED:
		room_state = ROOM_STATE_IN_PROGRESS

	var enemies = $Enemies.get_children()
	objective_initial_enemy_count = maxi(objective_initial_enemy_count, enemies.size())
	objective_progress_changed.emit(self)
	if get_room_objective_type() == OBJECTIVE_READ_ARCHIVE:
		_connect_archive_terminals()
		_update_room_chest_locks()
		for d in [Direction.RIGHT, Direction.DOWN, Direction.LEFT, Direction.UP]:
			close_door(d)
		return
	if not is_cleared and (enemies.size() > 0 or has_pending_room_event_objectives()):
		# Wake up Enemies
		if enemies.size() > 0:
			_set_enemies_active(true, true)
		_update_room_chest_locks()
		
		# Close doors
		for d in [Direction.RIGHT, Direction.DOWN, Direction.LEFT, Direction.UP]:
			close_door(d)
		if enemies.size() == 0:
			call_deferred("_try_finish_room_clear")
	elif enemies.size() == 0:
		for d in [Direction.RIGHT, Direction.DOWN, Direction.LEFT, Direction.UP]:
			open_door(d)
		_mark_room_cleared()

func enter_door(_body, door_direction):
	if _is_door_hidden(_direction_to_index(door_direction)):
		return
	door_entered.emit(door_direction)

func _hide_door(direction):
	var door = doors[direction]
	door.get_node("Locker").collision_layer = 1
	door.get_node("Area2D").monitoring = false
	door.visible = false

func close_door(direction:Direction):
	if _is_door_hidden(direction):
		return
	doors[direction].texture = CLOSED_DOORS[direction]
	(doors[direction].get_node("Locker") as StaticBody2D).collision_layer = 1

func open_door(direction:Direction):
	if _is_door_hidden(direction):
		return
	doors[direction].texture = OPEN_DOORS[direction]
	(doors[direction].get_node("Locker") as StaticBody2D).collision_layer = 0


func _on_enemies_child_exiting_tree(node):
	call_deferred("_emit_objective_progress_changed")
	call_deferred("_try_finish_room_clear")


func _mark_room_cleared() -> void:
	if is_cleared:
		return
	is_cleared = true
	if room_state != ROOM_STATE_REWARD_CLAIMED:
		room_state = ROOM_STATE_COMPLETED
	_update_room_chest_locks()
	_on_room_cleared()


func _connect_archive_terminals() -> void:
	_connect_archive_terminals_recursive(self)


func _connect_archive_terminals_recursive(root: Node) -> void:
	for child in root.get_children():
		if child.has_signal("archive_read"):
			var callable := Callable(self, "_on_archive_terminal_read")
			if not child.is_connected("archive_read", callable):
				child.connect("archive_read", callable)
		_connect_archive_terminals_recursive(child)


func _on_archive_terminal_read(_terminal: Node) -> void:
	if is_cleared:
		return
	if get_room_objective_type() != OBJECTIVE_READ_ARCHIVE:
		return
	for d in [Direction.RIGHT, Direction.DOWN, Direction.LEFT, Direction.UP]:
		open_door(d)
	_mark_room_cleared()
	objective_progress_changed.emit(self)
	RelicCombatEventBus.notify_room_cleared(self)
	room_cleared.emit(self)


func _on_room_cleared() -> void:
	pass


func set_room_objective(objective: Dictionary) -> void:
	room_objective = objective.duplicate(true)
	if room_objective.has("objective_text"):
		set_meta("event_objective_text", str(room_objective.get("objective_text", "")))
	if room_objective.has("target_label"):
		set_meta("event_target_label", str(room_objective.get("target_label", "")))
	if room_objective.has("completion_text"):
		set_meta("event_completion_text", str(room_objective.get("completion_text", "")))


func get_room_objective() -> Dictionary:
	_ensure_default_room_objective()
	return room_objective


func get_room_objective_type() -> String:
	_ensure_default_room_objective()
	return str(room_objective.get("type", OBJECTIVE_CLEAR_ENEMIES))


func get_room_state() -> String:
	return room_state


func mark_reward_claimed() -> void:
	reward_claimed = true
	room_state = ROOM_STATE_REWARD_CLAIMED
	objective_progress_changed.emit(self)


func has_reward_claimed() -> bool:
	return reward_claimed


func get_event_target_label() -> String:
	if has_meta("event_target_label"):
		return str(get_meta("event_target_label"))
	_ensure_default_room_objective()
	return str(room_objective.get("target_label", "目标"))


func get_event_target_total() -> int:
	if has_method("get_cryo_pod_total") and bool(call("has_cryo_pod_objective")):
		return int(call("get_cryo_pod_total"))
	if pollution_source_total > 0:
		return pollution_source_total
	_ensure_default_room_objective()
	return int(room_objective.get("target_total", 0))


func get_event_target_remaining() -> int:
	if is_cleared:
		return 0
	if has_method("get_cryo_pod_remaining") and has_method("has_cryo_pod_objective") and bool(call("has_cryo_pod_objective")):
		return int(call("get_cryo_pod_remaining"))
	if pollution_source_total > 0:
		return pollution_source_remaining
	_ensure_default_room_objective()
	return int(room_objective.get("target_remaining", 0))


func register_pollution_source(source: Node) -> void:
	if source == null:
		return

	pollution_source_total += 1
	pollution_source_remaining += 1
	lab_room_type = "pollution" if lab_room_type == "combat" else lab_room_type
	if room_objective.is_empty() or get_room_objective_type() == OBJECTIVE_CLEAR_ENEMIES:
		set_room_objective(_make_default_objective())

	var destroyed_callable := Callable(self, "_on_pollution_source_destroyed")
	if source.has_signal("pollution_source_destroyed") and not source.is_connected("pollution_source_destroyed", destroyed_callable):
		source.connect("pollution_source_destroyed", destroyed_callable)
	objective_progress_changed.emit(self)


func has_pending_room_event_objectives() -> bool:
	return get_event_target_remaining() > 0


func has_pollution_source_objective() -> bool:
	return pollution_source_total > 0


func get_pollution_source_total() -> int:
	return pollution_source_total


func get_pollution_source_remaining() -> int:
	if is_cleared:
		return 0
	return pollution_source_remaining


func get_remaining_enemy_count() -> int:
	if is_cleared or not has_node("Enemies"):
		return 0
	return $Enemies.get_child_count()


func get_objective_initial_enemy_count() -> int:
	return objective_initial_enemy_count


func has_enemy_clear_objective() -> bool:
	if get_room_objective_type() in [OBJECTIVE_CLEAR_ENEMIES, OBJECTIVE_DESTROY_TARGETS, OBJECTIVE_INTERACT_TARGETS, OBJECTIVE_BOSS]:
		return objective_initial_enemy_count > 0 or get_remaining_enemy_count() > 0
	if lab_room_type in ["combat", "pollution", "reward", "boss", "cryo_pod", "cryo_vent", "elite"]:
		return objective_initial_enemy_count > 0 or get_remaining_enemy_count() > 0
	return false


func _on_pollution_source_destroyed(_source: Node) -> void:
	pollution_source_remaining = maxi(0, pollution_source_remaining - 1)
	objective_progress_changed.emit(self)
	call_deferred("_try_finish_room_clear")


func _try_finish_room_clear() -> void:
	if is_cleared:
		return
	if get_remaining_enemy_count() > 0:
		return
	if has_pending_room_event_objectives():
		return

	for d in [Direction.RIGHT, Direction.DOWN, Direction.LEFT, Direction.UP]:
		open_door(d)
	_mark_room_cleared()


func _emit_objective_progress_changed() -> void:
	if is_inside_tree():
		objective_progress_changed.emit(self)


func _set_enemies_active(active: bool, deferred := false) -> void:
	if not has_node("Enemies"):
		return

	var next_mode := Node.PROCESS_MODE_INHERIT if active else Node.PROCESS_MODE_DISABLED
	for enemy in $Enemies.get_children():
		if deferred:
			enemy.set_deferred("process_mode", next_mode)
		else:
			enemy.process_mode = next_mode


func _update_room_chest_locks() -> void:
	if not lock_chests_until_cleared:
		_set_chests_locked_recursive(self, false)
		return
	if not has_node("Enemies"):
		_set_chests_locked_recursive(self, false)
		return

	var should_lock := not is_cleared and ($Enemies.get_child_count() > 0 or has_pending_room_event_objectives())
	_set_chests_locked_recursive(self, should_lock)


func _set_chests_locked_recursive(root: Node, locked: bool) -> void:
	if root is LabChest:
		(root as LabChest).set_room_locked(locked)

	for child in root.get_children():
		_set_chests_locked_recursive(child, locked)


func _is_door_hidden(direction: Direction) -> bool:
	match direction:
		Direction.RIGHT:
			return hide_right_door
		Direction.DOWN:
			return hide_down_door
		Direction.LEFT:
			return hide_left_door
		Direction.UP:
			return hide_up_door
	return true


func _direction_to_index(direction: Vector2) -> Direction:
	if direction.x > 0:
		return Direction.RIGHT
	if direction.y > 0:
		return Direction.DOWN
	if direction.x < 0:
		return Direction.LEFT
	return Direction.UP


func _ensure_default_room_objective() -> void:
	if room_objective.is_empty():
		room_objective = _make_default_objective()


func _make_default_objective() -> Dictionary:
	match lab_room_type:
		"start":
			return {
				"type": OBJECTIVE_CLEAR_ENEMIES,
				"objective_text": "进入当前区域。",
				"completion_text": "区域入口已确认。",
			}
		"pollution":
			return {
				"type": OBJECTIVE_DESTROY_TARGETS,
				"objective_text": "摧毁目标 0/3，并清除房内敌人。",
				"target_label": "目标",
				"target_total": 3,
				"completion_text": "封锁解除：目标已清除。",
			}
		"data_comm":
			return {
				"type": OBJECTIVE_INTERACT_TARGETS,
				"objective_text": "重启通讯终端 0/3。",
				"target_label": "通讯终端",
				"target_total": 3,
				"completion_text": "封锁解除：通讯终端已重启。",
			}
		"data_satellite":
			return {
				"type": OBJECTIVE_INTERACT_TARGETS,
				"objective_text": "关闭控制节点 0/3。",
				"target_label": "控制节点",
				"target_total": 3,
				"completion_text": "封锁解除：控制节点已关闭。",
			}
		"cryo_pod":
			return {
				"type": OBJECTIVE_INTERACT_TARGETS,
				"objective_text": "检查冷冻舱 0/3。",
				"target_label": "冷冻舱",
				"target_total": 3,
				"completion_text": "封锁解除：冷冻舱已检查。",
			}
		"weapon":
			return {
				"type": OBJECTIVE_CHOOSE_REWARD,
				"objective_text": "选择一件武器。",
				"completion_text": "武器选择已完成。",
			}
		"merchant":
			return {
				"type": OBJECTIVE_SHOP,
				"objective_text": "整备补给。",
				"completion_text": "补给窗口已开启。",
			}
		"archive":
			return {
				"type": OBJECTIVE_READ_ARCHIVE,
				"objective_text": "激活数据终端。",
				"completion_text": "数据节点已清除。",
			}
		"final_interrogation":
			return {
				"type": OBJECTIVE_READ_ARCHIVE,
				"objective_text": "激活核心终端。",
				"completion_text": "核心干扰已清除。出口已开启。",
			}
		"boss":
			return {
				"type": OBJECTIVE_BOSS,
				"objective_text": "击败 Boss。",
				"completion_text": "Boss 已击败。",
			}
	return {
		"type": OBJECTIVE_CLEAR_ENEMIES,
		"objective_text": "清除所有敌人。",
		"completion_text": "封锁解除。",
	}
