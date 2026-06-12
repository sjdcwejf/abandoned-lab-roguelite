extends Room


const BOSS_HEALTH_UI_SCRIPT := preload("res://tiny_wizard/gui/boss_health_ui/boss_health_ui.gd")

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
	if _boss_health_ui != null and not is_cleared and _boss_node != null and is_instance_valid(_boss_node):
		_boss_health_ui.call("show_bar")


func _on_room_cleared() -> void:
	if _boss_health_ui != null:
		_boss_health_ui.call("hide_bar")
	if exit_black_hole != null:
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
	for direction in [Direction.RIGHT, Direction.DOWN, Direction.LEFT, Direction.UP]:
		open_door(direction)
	_mark_room_cleared()
