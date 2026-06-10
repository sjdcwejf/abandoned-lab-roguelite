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
