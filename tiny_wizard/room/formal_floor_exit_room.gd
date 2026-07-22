extends Room


const EXIT_LOCAL_POSITION := Vector2(812, 190)

@onready var exit_black_hole := $ExitBlackHole as LabBlackHole


func _ready() -> void:
	super._ready()
	if exit_black_hole != null:
		exit_black_hole.set_active(false)


func _on_room_cleared() -> void:
	if exit_black_hole == null:
		return
	exit_black_hole.global_position = get_room_global_position() + EXIT_LOCAL_POSITION
	exit_black_hole.set_active(true)
