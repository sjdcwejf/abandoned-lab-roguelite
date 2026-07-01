extends "res://tiny_wizard/enemies/protomatter_drop_enemy.gd"


const CRYO_ZONE_SCENE := preload("res://tiny_wizard/interactable_objects/cryo_zone/cryo_zone.tscn")

@export var death_cryo_zone_radius := 96.0
@export var death_cryo_zone_duration := 4.0


func _ready() -> void:
	super._ready()
	set_meta("cryo_enemy", true)
	set_meta("elite_enemy", true)


func die() -> void:
	_spawn_death_cryo_zone()
	super.die()


func _spawn_death_cryo_zone() -> void:
	var drop_parent := _get_drop_parent()
	if drop_parent == null:
		return

	var zone := CRYO_ZONE_SCENE.instantiate() as Node2D
	if zone == null:
		return
	zone.set("radius", death_cryo_zone_radius)
	zone.set("duration", death_cryo_zone_duration)
	zone.set("show_player_feedback", false)
	if drop_parent is Node2D:
		zone.position = (drop_parent as Node2D).to_local(global_position)
	else:
		zone.global_position = global_position
	drop_parent.call_deferred("add_child", zone)

