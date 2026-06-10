class_name LabBlackHole
extends Area2D


signal entered(body: Node2D)

var _active := true


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	set_active(monitoring)


func set_active(active: bool) -> void:
	_active = active
	visible = active
	set_deferred("monitoring", active)
	set_deferred("monitorable", active)


func _on_body_entered(body: Node2D) -> void:
	if not _active:
		return
	if not body.has_node("Visual/WeaponHolder"):
		return
	entered.emit(body)
