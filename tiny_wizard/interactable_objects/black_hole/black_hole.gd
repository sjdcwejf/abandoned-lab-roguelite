class_name LabBlackHole
extends Area2D


signal entered(body: Node2D)

@export_range(0.0, 2.0, 0.05) var activation_grace_seconds := 0.35

var _active := true
var _activated_at_msec := -1000000.0


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	set_active(monitoring)


func set_active(active: bool) -> void:
	_active = active
	if active:
		_activated_at_msec = Time.get_ticks_msec()
	visible = active
	set_deferred("monitoring", active)
	set_deferred("monitorable", active)


func _on_body_entered(body: Node2D) -> void:
	if not _active:
		return
	if _is_in_activation_grace():
		return
	if not body.has_node("Visual/WeaponHolder"):
		return
	entered.emit(body)


func _is_in_activation_grace() -> bool:
	if activation_grace_seconds <= 0.0:
		return false
	var elapsed_seconds := (Time.get_ticks_msec() - _activated_at_msec) / 1000.0
	return elapsed_seconds < activation_grace_seconds
