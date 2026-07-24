extends Room


const EXIT_LOCAL_POSITION := Vector2(812, 190)
const ELITE_RELIC_DROP_LOCAL_POSITION := Vector2(512, 320)
const PROTOMATTER_FRAGMENT_ITEM := preload("res://tiny_wizard/items/protomatter_fragment/protomatter_fragment.tres")
const RELIC_DROP_SERVICE := preload("res://tiny_wizard/relic/relic_drop_service.gd")
const INTERACTION_FEEDBACK := preload("res://tiny_wizard/gui/interaction_feedback.gd")

@export_range(0, 99, 1) var elite_protomatter_min := 3
@export_range(0, 99, 1) var elite_protomatter_max := 5
@export_range(0.0, 1.0, 0.01) var elite_relic_drop_chance := 0.35
@export var elite_relic_pool_tag: StringName = &"cryo_relic"

var _elite_reward_claimed := false
var _exit_activated := false
var _relic_controller: RelicController
var _debug_progression_context := {}

@onready var exit_black_hole := $ExitBlackHole as LabBlackHole


func _ready() -> void:
	super._ready()
	if exit_black_hole != null:
		exit_black_hole.set_active(false)


func set_relic_controller(controller: RelicController) -> void:
	_relic_controller = controller


func set_debug_progression_context(context: Dictionary) -> void:
	_debug_progression_context = context.duplicate(true)


func _on_room_cleared() -> void:
	_grant_elite_reward_once()
	_activate_exit_once()


func _grant_elite_reward_once() -> void:
	if _elite_reward_claimed:
		return
	_elite_reward_claimed = true

	if _debug_progression_rewards_blocked():
		return
	set_meta("elite_reward_claimed", true)
	set_meta("floor_completion_claimed", true)

	var reward_min := mini(elite_protomatter_min, elite_protomatter_max)
	var reward_max := maxi(elite_protomatter_min, elite_protomatter_max)
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var protomatter_amount := rng.randi_range(reward_min, reward_max)
	var player := _find_player_node(get_tree().current_scene)
	var granted_protomatter := _grant_protomatter(player, protomatter_amount)
	var dropped_relic := _try_drop_elite_relic(player, rng)

	if granted_protomatter or dropped_relic:
		var message := "+%d 原质" % protomatter_amount
		if dropped_relic:
			message += "\n第三章遗物样本已析出"
		INTERACTION_FEEDBACK.show_from(self, message, 1.45)


func _debug_progression_rewards_blocked() -> bool:
	if _debug_progression_context.is_empty():
		return false
	if not bool(_debug_progression_context.get("debug_mode", false)):
		return false
	return not bool(_debug_progression_context.get("debug_progression_rewards_enabled", false))


func _grant_protomatter(player: Node2D, amount: int) -> bool:
	if player == null or amount <= 0:
		return false
	var inventory := player.get("inventory") as QuiverInventory
	if inventory == null:
		return false
	return bool(inventory.add_item(PROTOMATTER_FRAGMENT_ITEM, amount))


func _try_drop_elite_relic(player: Node2D, rng: RandomNumberGenerator) -> bool:
	if elite_relic_drop_chance <= 0.0:
		return false
	if rng.randf() > elite_relic_drop_chance:
		return false
	if _relic_controller == null and player != null:
		_relic_controller = player.get_node_or_null("RelicController") as RelicController
	if _relic_controller == null:
		return false
	return bool(RELIC_DROP_SERVICE.try_drop_relic_from_pool(
		self,
		_relic_controller,
		get_room_global_position() + ELITE_RELIC_DROP_LOCAL_POSITION,
		elite_relic_pool_tag,
		rng
	))


func _activate_exit_once() -> void:
	if _exit_activated:
		return
	if exit_black_hole == null:
		return
	_exit_activated = true
	exit_black_hole.global_position = get_room_global_position() + EXIT_LOCAL_POSITION
	exit_black_hole.set_active(true)


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
