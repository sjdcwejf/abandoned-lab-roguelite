extends QuiverInteractableObjectAction

const INTERACTION_FEEDBACK := preload("res://tiny_wizard/gui/interaction_feedback.gd")

# The items to spawn (an array of QuiverPickableItem packed scenes)
var items := [] 
# The path to the sprite to change it's texture to open
@export var chest_sprite: NodePath
# Enable this to create a locked chest that will consume a key to open
@export var locked:= false

@onready var chest = get_node(chest_sprite)

func trigger(object: QuiverInteractableObject, character: QuiverCharacter):
	var next_action = get_node_or_null("OnFailure")

	if active:
		if character.can_grab_items:
			
			if locked:
				if (character.inventory as QuiverInventory).get_item_amount("Biometric Key") > 0:
					character.inventory.remove_item("Biometric Key")
				else:
					INTERACTION_FEEDBACK.show_from(object, "需要生物识别钥才能打开。", 1.35)
					# We cannot open it so we stop here
					if next_action is QuiverInteractableObjectAction:
						# Trigger next action
						next_action.trigger(object, character)
					return
			
			# Opening the chest
			next_action = get_node_or_null("OnSuccess")
			# We don't want to open again after
			active = false
			# Visual opening
			chest.open()
			if object.has_method("mark_opened"):
				object.call("mark_opened")
			INTERACTION_FEEDBACK.show_from(object, "补给箱已打开。", 1.1)
			# Spawn items
			for item in items:
				if item is QuiverItem:
					var item_node = item.create_pickable_item()
					item_node.position = object.position + chest.get_parent().position
					object.call_deferred("add_sibling", item_node)
			_try_spawn_relic_reward(object, character)
	
	if next_action is QuiverInteractableObjectAction:
		# Trigger next action
		next_action.trigger(object, character)


func _try_spawn_relic_reward(object: QuiverInteractableObject, character: QuiverCharacter) -> void:
	if object == null or character == null:
		return
	if not bool(object.get("relic_reward_enabled")):
		return

	var chance := float(object.get("relic_reward_chance"))
	if chance <= 0.0 or randf() > chance:
		return

	var relic_controller := character.get_node_or_null("RelicController") as RelicController
	if relic_controller == null:
		return

	var drop_parent := object.get_parent()
	if drop_parent == null:
		drop_parent = object
	var drop_position := object.global_position
	if chest != null:
		drop_position = chest.global_position

	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var pool_tag := object.get("relic_pool_tag") as StringName
	var dropped := RelicDropService.try_drop_relic_from_pool(drop_parent, relic_controller, drop_position, pool_tag, rng)
	if not dropped:
		print("Chest relic reward skipped: no legal relic candidate.")
