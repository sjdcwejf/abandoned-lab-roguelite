extends QuiverCharacter

@export var gui_path: NodePath

signal respawn_requested

var arrow_types = {
	'normal': preload("res://tiny_wizard/player/weapon/bullet/arrow.tscn"),
	'violet': preload("res://tiny_wizard/player/weapon/bullet/violet_arrow.tscn"),
}

func hit(damage:=1, from:=Vector2.ZERO):
	var life_before := character_stats.current_life if character_stats != null else -1
	var shield_before := int(character_stats.get("current_shield")) if character_stats != null and "current_shield" in character_stats else 0
	var ability_controller := get_node_or_null("AbilityController") as LabPlayerAbilityController
	if ability_controller != null:
		if ability_controller.should_ignore_damage():
			return
		damage = ability_controller.modify_incoming_damage(int(damage))

	super.hit(damage, from)
	var build_controller := get_node_or_null("TiemuBuildController") as TiemuBuildController
	var shield_after := int(character_stats.get("current_shield")) if character_stats != null and "current_shield" in character_stats else 0
	var received_amount := maxi(0, life_before - character_stats.current_life) + maxi(0, shield_before - shield_after) if character_stats != null else 0
	if build_controller != null and received_amount > 0:
		var event := CombatEvent.new()
		event.event_type = CombatEvent.EventType.DAMAGE_DEALT
		event.target = self
		event.source = self
		event.base_amount = damage
		event.final_amount = received_amount
		event.hit_position = global_position
		event.tags = [&"incoming_damage"]
		build_controller.dispatch_combat_event(event)
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


func change_arrow(arrow_scene):
	$Visual/DistanceWeapon.bullet_scene = arrow_scene
#	inventory.current_arrow = arrow_scene.instantiate().icon
	var gui = get_node_or_null(gui_path)
	if gui != null:
		gui.change_arrow_texture(arrow_scene.instantiate().icon)
