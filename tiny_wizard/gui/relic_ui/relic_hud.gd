class_name RelicHUD
extends Control

const ENTRY_SCENE := preload("res://tiny_wizard/gui/relic_ui/relic_hud_entry.tscn")

var _relic_controller: RelicController

@onready var list: VBoxContainer = $MarginContainer/List


func _ready() -> void:
	_refresh()


func bind_relic_controller(controller: RelicController) -> void:
	if _relic_controller != null and is_instance_valid(_relic_controller):
		var refresh_callable := Callable(self, "_refresh")
		if _relic_controller.relics_changed.is_connected(refresh_callable):
			_relic_controller.relics_changed.disconnect(refresh_callable)

	_relic_controller = controller

	if _relic_controller != null:
		var refresh_callable := Callable(self, "_refresh")
		if not _relic_controller.relics_changed.is_connected(refresh_callable):
			_relic_controller.relics_changed.connect(refresh_callable)

	_refresh()


func _refresh() -> void:
	if not is_node_ready():
		return

	for child in list.get_children():
		child.queue_free()

	if _relic_controller == null or not is_instance_valid(_relic_controller):
		return

	var snapshot := _relic_controller.get_relic_snapshot()
	var relics := snapshot.get("relics", []) as Array
	for relic_data in relics:
		var entry := ENTRY_SCENE.instantiate() as RelicHudEntry
		if entry == null:
			continue
		list.add_child(entry)
		entry.set_relic_data(relic_data)

	var synergies := snapshot.get("synergies", []) as Array
	for synergy_data in synergies:
		var entry := ENTRY_SCENE.instantiate() as RelicHudEntry
		if entry == null:
			continue
		list.add_child(entry)
		entry.set_synergy_data(synergy_data)
