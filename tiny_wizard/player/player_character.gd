extends QuiverCharacter

@export var gui_path: NodePath

signal respawn_requested

func hit(damage:=1, from:=Vector2.ZERO):
	var event_tags := RelicCombatEventBus.get_event_tags(self)
	var ability_controller := get_node_or_null("AbilityController") as LabPlayerAbilityController
	if ability_controller != null:
		if ability_controller.should_ignore_damage():
			return
		damage = ability_controller.modify_incoming_damage(int(damage))
	var relic_controller := get_node_or_null("RelicController") as RelicController
	if relic_controller != null:
		damage = relic_controller.modify_incoming_damage(int(damage), {
			"from": from,
			"tags": event_tags,
		})

	super.hit(damage, from)
	if relic_controller != null and int(damage) > 0:
		RelicCombatEventBus.notify_character_damaged(self, int(damage), from, event_tags)
	if ability_controller != null:
		ability_controller.notify_damage_taken()
	$Visual/AnimationPlayer.play("Blink")


func _process(delta):
	if Input.is_action_just_pressed("drop_bomb"):
		(inventory as QuiverInventory).use_item(self, "Breach Charge")
#			inventory.add_to_item('bombs', -1)
#			var bomb = BOMB_SCENE.instantiate()
#			bomb.position = position
#			get_parent().add_child(bomb)


func die():
	respawn_requested.emit()
