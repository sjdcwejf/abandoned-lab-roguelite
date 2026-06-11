extends CanvasLayer


const WEAPON_BACKPACK_UI_SCRIPT := preload("res://tiny_wizard/gui/weapon_backpack_ui/weapon_backpack_ui.gd")

@export var inventory : QuiverInventory

var _weapon_backpack_ui: WeaponBackpackUI


func _ready() -> void:
	_weapon_backpack_ui = WEAPON_BACKPACK_UI_SCRIPT.new()
	_weapon_backpack_ui.name = "WeaponBackpackUI"
	add_child(_weapon_backpack_ui)


func change_arrow_texture(new_texture):
	%ArrowUITexture.texture = new_texture


func bind_weapon_holder(weapon_holder: Node) -> void:
	if _weapon_backpack_ui == null:
		return
	_weapon_backpack_ui.bind_weapon_holder(weapon_holder)


func bind_character_stats(new_stats: QuiverCharacterStats) -> void:
	var hearts_ui := get_node_or_null("TopUI/TextureRect/MarginContainer/HBoxContainer/HeartsUI")
	if hearts_ui == null:
		return
	if hearts_ui.has_method("bind_player_stats"):
		hearts_ui.call("bind_player_stats", new_stats)


func bind_inventory(new_inventory: QuiverInventory) -> void:
	inventory = new_inventory
	var inventory_ui := get_node_or_null("TopUI/TextureRect/MarginContainer/HBoxContainer/InventoryUI")
	if inventory_ui == null:
		return
	if inventory_ui.has_method("bind_inventory"):
		inventory_ui.call("bind_inventory", inventory)
