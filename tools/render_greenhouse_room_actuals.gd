extends SceneTree


const ROOMS := [
	{
		"scene": "res://tiny_wizard/room/room_types/lab_greenhouse_start_room.tscn",
		"output": "res://docs/previews/greenhouse_entry_room_actual.png",
	},
	{
		"scene": "res://tiny_wizard/room/room_types/lab_greenhouse_spore_event_room.tscn",
		"output": "res://docs/previews/spore_contamination_room_actual.png",
	},
	{
		"scene": "res://tiny_wizard/room/room_types/lab_greenhouse_combat_room.tscn",
		"output": "res://docs/previews/cultivation_chamber_room_actual.png",
	},
	{
		"scene": "res://tiny_wizard/room/room_types/lab_greenhouse_reward_room.tscn",
		"output": "res://docs/previews/greenhouse_reward_room_actual.png",
	},
	{
		"scene": "res://tiny_wizard/room/room_types/lab_greenhouse_merchant_room.tscn",
		"output": "res://docs/previews/greenhouse_boss_antechamber_actual.png",
	},
]


func _initialize() -> void:
	call_deferred("_render_rooms")


func _render_rooms() -> void:
	for spec in ROOMS:
		var packed := load(str(spec["scene"])) as PackedScene
		if packed == null:
			push_error("Failed to load room scene: %s" % spec["scene"])
			quit(1)
			return

		var output_absolute := ProjectSettings.globalize_path(str(spec["output"]))
		DirAccess.make_dir_recursive_absolute(output_absolute.get_base_dir())

		var viewport := SubViewport.new()
		viewport.size = Vector2i(1024, 600)
		viewport.transparent_bg = false
		viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		root.add_child(viewport)

		var room := packed.instantiate()
		room.position = Vector2.ZERO
		viewport.add_child(room)

		await process_frame
		await process_frame
		await process_frame
		RenderingServer.force_draw()

		var texture := viewport.get_texture()
		if texture == null:
			push_error("Failed to read viewport texture. Use a real display driver, for example: --display-driver macos --rendering-driver opengl3")
			viewport.queue_free()
			quit(1)
			return

		var image := texture.get_image()
		if image == null:
			push_error("Failed to read viewport image. Use a real display driver, for example: --display-driver macos --rendering-driver opengl3")
			viewport.queue_free()
			quit(1)
			return
		var error := image.save_png(output_absolute)
		viewport.queue_free()
		if error != OK:
			push_error("Failed to save greenhouse room screenshot: %s" % output_absolute)
			quit(1)
			return
		print("Saved actual greenhouse render: %s" % output_absolute)

	quit(0)
