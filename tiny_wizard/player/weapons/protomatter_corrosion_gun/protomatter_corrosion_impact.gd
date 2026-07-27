extends Node2D


@onready var sprite: Sprite2D = $Sprite2D

var _impact_tween: Tween


func _ready() -> void:
	if sprite == null:
		queue_free()
		return

	_impact_tween = create_tween()
	_impact_tween.set_parallel(true)
	_impact_tween.tween_property(sprite, "scale", Vector2(1.22, 1.22), 0.16)
	_impact_tween.tween_property(sprite, "modulate:a", 0.0, 0.18)
	_impact_tween.chain().tween_callback(queue_free)
