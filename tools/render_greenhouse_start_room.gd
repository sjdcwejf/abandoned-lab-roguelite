extends SceneTree


const START_ROOM_SCENE := preload("res://tiny_wizard/room/room_types/lab_greenhouse_start_room.tscn")
const OUTPUT_PATH := "res://docs/previews/greenhouse_start_room_actual.png"


func _initialize() -> void:
	call_deferred("_render_room")


func _render_room() -> void:
	var output_absolute := ProjectSettings.globalize_path(OUTPUT_PATH)
	DirAccess.make_dir_recursive_absolute(output_absolute.get_base_dir())

	var viewport := SubViewport.new()
	viewport.size = Vector2i(1024, 600)
	viewport.transparent_bg = false
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)

	var room := START_ROOM_SCENE.instantiate()
	room.position = Vector2.ZERO
	viewport.add_child(room)

	await process_frame
	await process_frame
	RenderingServer.force_draw()

	var image := viewport.get_texture().get_image()
	var error := image.save_png(output_absolute)
	if error != OK:
		push_error("Failed to save greenhouse start room screenshot: %s" % output_absolute)
		quit(1)
		return

	print("Saved greenhouse start room actual render: %s" % output_absolute)
	quit(0)
