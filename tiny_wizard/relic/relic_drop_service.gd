class_name RelicDropService
extends RefCounted

const RELIC_PICKUP_SCENE := preload("res://tiny_wizard/interactable_objects/relic_pickup/relic_pickup.tscn")


static func try_drop_relic_from_pool(
	drop_parent: Node,
	relic_controller: RelicController,
	global_position: Vector2,
	pool_tag: StringName = &"",
	rng: RandomNumberGenerator = null
) -> bool:
	if drop_parent == null or relic_controller == null:
		return false

	var definition := BuildPoolResolver.pick_random_relic(relic_controller, rng, pool_tag)
	if definition == null:
		return false

	return drop_relic_definition(drop_parent, definition, global_position)


static func drop_relic_definition(
	drop_parent: Node,
	definition: BuildItemDefinition,
	global_position: Vector2
) -> bool:
	if drop_parent == null or definition == null:
		return false

	var relic_pickup := RELIC_PICKUP_SCENE.instantiate() as RelicPickup
	if relic_pickup == null:
		return false

	relic_pickup.relic_definition = definition
	if drop_parent is Node2D:
		relic_pickup.position = (drop_parent as Node2D).to_local(global_position)
	else:
		relic_pickup.global_position = global_position
	drop_parent.call_deferred("add_child", relic_pickup)
	return true


static func find_relic_controller(root: Node) -> RelicController:
	if root == null:
		return null
	if root is RelicController:
		return root as RelicController

	var direct := root.get_node_or_null("RelicController") as RelicController
	if direct != null:
		return direct

	for child in root.get_children():
		var found := find_relic_controller(child)
		if found != null:
			return found
	return null
