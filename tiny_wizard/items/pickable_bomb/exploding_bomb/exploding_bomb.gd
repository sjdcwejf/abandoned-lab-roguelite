extends Node2D

var active = true

func _ready():
	tree_exiting.connect(_on_tree_exiting)

func explode():
	
	play_anim()
	
	var exploding_area : Area2D = $RigidBody2D/ExplodingArea
	
	var explode_position = $RigidBody2D.global_position
	
	for thing in exploding_area.get_overlapping_bodies():
		if thing != $RigidBody2D:
			if thing.has_method("hit"):
				thing.hit(2, explode_position.direction_to(thing.global_position))
			elif thing.has_method("apply_impulse"):
				thing.apply_impulse(explode_position.direction_to(thing.global_position)*20000/explode_position.distance_to(thing.global_position))

func play_anim():
	($RigidBody2D/AnimatedSprite2D as AnimatedSprite2D).play("explosion")

func _on_tree_exiting():
	var target_parent := get_parent()
	var ground_trace = $RigidBody2D/GroundBombTrace
	var trace_parent = ground_trace.get_parent()
	if target_parent == null or trace_parent == null:
		return

	var pos = ground_trace.global_position
	trace_parent.remove_child(ground_trace)
	target_parent.call_deferred("add_child", ground_trace)
	ground_trace.set_deferred("global_position", pos)
