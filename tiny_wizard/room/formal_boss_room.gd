extends Room


@onready var exit_black_hole := $ExitBlackHole as LabBlackHole


func _ready() -> void:
	super._ready()
	if exit_black_hole != null:
		exit_black_hole.set_active(false)


func _on_room_cleared() -> void:
	if exit_black_hole != null:
		exit_black_hole.set_active(true)
