class_name RelicSellDialog
extends PanelContainer

signal relic_selected(relic_id: StringName)
signal cancelled

var _sellable_relics: Array[Dictionary] = []

@onready var list_container: VBoxContainer = $MarginContainer/VBoxContainer/ScrollContainer/List
@onready var empty_label: Label = $MarginContainer/VBoxContainer/Empty
@onready var cancel_button: Button = $MarginContainer/VBoxContainer/Cancel


func _ready() -> void:
	cancel_button.pressed.connect(_on_cancel_pressed)
	_rebuild_list()


func setup(sellable_relics: Array[Dictionary]) -> void:
	_sellable_relics = sellable_relics.duplicate()
	if is_node_ready():
		_rebuild_list()


func _rebuild_list() -> void:
	var children: Array[Node] = list_container.get_children()
	for child_node in children:
		child_node.queue_free()

	empty_label.visible = _sellable_relics.is_empty()
	for relic_data in _sellable_relics:
		var relic_id: StringName = relic_data.get("relic_id", &"")
		if relic_id == &"":
			continue
		var sell_price := int(relic_data.get("sell_price", 10))
		var display_name := _resolve_display_name(relic_data)
		var button := Button.new()
		button.text = "%s  +%d 原质" % [display_name, sell_price]
		button.custom_minimum_size = Vector2(220.0, 32.0)
		button.pressed.connect(_on_relic_button_pressed.bind(relic_id))
		list_container.add_child(button)


func _resolve_display_name(relic_data: Dictionary) -> String:
	var display_name := str(relic_data.get("display_name", ""))
	if display_name != "":
		return display_name
	var placeholder_text := str(relic_data.get("placeholder_text", ""))
	if placeholder_text != "":
		return placeholder_text
	return str(relic_data.get("relic_id", "unknown_relic"))


func _on_relic_button_pressed(relic_id: StringName) -> void:
	relic_selected.emit(relic_id)


func _on_cancel_pressed() -> void:
	cancelled.emit()
