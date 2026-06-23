class_name TiemuBuildPanel
extends CanvasLayer

@export var toggle_key: Key = KEY_F8

var _controller: TiemuBuildController

@onready var _content_label: Label = %ContentLabel
@onready var _close_button: Button = %CloseButton


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_close_button.pressed.connect(close)
	var parent_controller := get_parent().get_node_or_null("TiemuBuildController") as TiemuBuildController
	bind_controller(parent_controller)
	_refresh()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == toggle_key:
			visible = not visible
			if visible:
				_refresh()
			get_viewport().set_input_as_handled()
		elif visible and event.keycode == KEY_ESCAPE:
			close()
			get_viewport().set_input_as_handled()


func bind_controller(controller: TiemuBuildController) -> void:
	if _controller != null:
		var build_callable := Callable(self, "_refresh")
		var stats_callable := Callable(self, "_on_derived_stats_changed")
		if _controller.build_changed.is_connected(build_callable):
			_controller.build_changed.disconnect(build_callable)
		if _controller.derived_stats_changed.is_connected(stats_callable):
			_controller.derived_stats_changed.disconnect(stats_callable)
	_controller = controller
	if _controller != null:
		_controller.build_changed.connect(_refresh)
		_controller.derived_stats_changed.connect(_on_derived_stats_changed)
	_refresh()


func close() -> void:
	visible = false


func _on_derived_stats_changed(_snapshot: Dictionary) -> void:
	_refresh()


func _refresh() -> void:
	if not is_node_ready() or _content_label == null:
		return
	if _controller == null:
		_content_label.text = "No TiemuBuildController bound."
		return
	_content_label.text = _format_snapshot(_controller.get_build_snapshot())


func _format_snapshot(snapshot: Dictionary) -> String:
	var sections := PackedStringArray()
	sections.append("INSTALLED ORGANS\n%s" % _format_items(snapshot.get("installed_organs", [])))
	sections.append("INSTALLED RELICS\n%s" % _format_items(snapshot.get("installed_relics", [])))
	sections.append("TAG COUNTS\n%s" % _format_counts(snapshot.get("tag_counts", {})))
	sections.append("ACTIVE SYNERGIES\n%s" % _format_ids(snapshot.get("active_synergy_ids", [])))
	sections.append("DERIVED STAT MODIFIERS\n%s" % _format_stats(snapshot.get("derived_stats", {})))
	return "\n\n".join(sections)


func _format_items(items: Array) -> String:
	if items.is_empty():
		return "  (none)"
	var lines := PackedStringArray()
	for item in items:
		var display_name := str(item.get("display_name", ""))
		var item_id := str(item.get("item_id", ""))
		var label := display_name if not display_name.is_empty() else item_id
		lines.append("  [%d] %s (%s) x%d" % [
			int(item.get("slot_index", -1)),
			label,
			item_id,
			int(item.get("stack_count", 0)),
		])
	return "\n".join(lines)


func _format_counts(counts: Dictionary) -> String:
	if counts.is_empty():
		return "  (none)"
	var keys := counts.keys()
	keys.sort()
	var lines := PackedStringArray()
	for key in keys:
		lines.append("  %s: %d" % [key, int(counts[key])])
	return "\n".join(lines)


func _format_ids(ids: Array) -> String:
	if ids.is_empty():
		return "  (none)"
	var values := PackedStringArray()
	for id in ids:
		values.append(str(id))
	values.sort()
	var lines := PackedStringArray()
	for value in values:
		lines.append("  %s" % value)
	return "\n".join(lines)


func _format_stats(stats: Dictionary) -> String:
	if stats.is_empty():
		return "  (none)"
	var keys := stats.keys()
	keys.sort()
	var lines := PackedStringArray()
	for key in keys:
		var values: Dictionary = stats[key]
		var line := "  %s: add=%s multiply=%s" % [key, values.get("add", 0.0), values.get("multiply", 1.0)]
		if values.get("override") != null:
			line += " override=%s (priority %d)" % [values["override"], int(values.get("override_priority", 0))]
		lines.append(line)
	return "\n".join(lines)
