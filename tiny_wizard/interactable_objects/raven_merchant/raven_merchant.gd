class_name LabRavenMerchant
extends Node2D


const CURRENCY_NAME := "Protomatter Fragment"
const CURRENCY_DISPLAY_NAME := "Protomatter"
const WEAPON_STOCK := [
	preload("res://tiny_wizard/player/weapons/laser_pointer/laser_pointer.tscn"),
	preload("res://tiny_wizard/player/weapons/containment_nailgun/containment_nailgun.tscn"),
	preload("res://tiny_wizard/player/weapons/energy_saber/energy_saber.tscn"),
	preload("res://tiny_wizard/player/weapons/power_gauntlets/power_gauntlets.tscn"),
	preload("res://tiny_wizard/player/weapons/test_sword/test_sword.tscn"),
]

@export var merchant_title := "RAVEN ARMORY"
@export_multiline var merchant_message := "Boss signal ahead. Patch your nerves and count your charges."
@export_range(0, 99, 1) var weapon_cost := 1
@export var equip_purchase_immediately := false

var _candidate_character: Node2D
var _dialog_open := false
var _selected_weapon_scene: PackedScene
var _selected_weapon_name := ""

@onready var interact_area: Area2D = $InteractArea
@onready var prompt: CanvasItem = $Prompt
@onready var dialog_panel: Control = $DialogPanel
@onready var title_label: Label = $DialogPanel/MarginContainer/VBoxContainer/Title
@onready var message_label: Label = $DialogPanel/MarginContainer/VBoxContainer/Message
@onready var stock_label: Label = $DialogPanel/MarginContainer/VBoxContainer/Stock
@onready var status_label: Label = $DialogPanel/MarginContainer/VBoxContainer/Status
@onready var hint_label: Label = $DialogPanel/MarginContainer/VBoxContainer/Hint
@onready var status_light: CanvasItem = $Console/StatusLight


func _ready() -> void:
	prompt.visible = false
	dialog_panel.visible = false
	title_label.text = merchant_title
	message_label.text = merchant_message
	stock_label.text = ""
	status_label.text = ""
	interact_area.body_entered.connect(_on_interact_area_body_entered)
	interact_area.body_exited.connect(_on_interact_area_body_exited)


func _process(_delta: float) -> void:
	if _candidate_character == null:
		return
	if Input.is_action_just_pressed("interact"):
		if _dialog_open:
			_try_purchase(_candidate_character)
		else:
			_open_armory(_candidate_character)


func _on_interact_area_body_entered(body: Node2D) -> void:
	if not body.has_node("Visual/WeaponHolder"):
		return
	_candidate_character = body
	prompt.visible = true


func _on_interact_area_body_exited(body: Node2D) -> void:
	if body != _candidate_character:
		return
	_candidate_character = null
	prompt.visible = false
	_set_dialog_open(false)


func _open_armory(character: Node2D) -> void:
	_refresh_offer(character)
	_set_dialog_open(true)


func _set_dialog_open(open: bool) -> void:
	_dialog_open = open
	dialog_panel.visible = _dialog_open
	if status_light is Polygon2D:
		var light := status_light as Polygon2D
		light.color = Color(0.65, 1.0, 0.62, 1.0) if _dialog_open else Color(0.28, 0.9, 0.95, 1.0)


func _refresh_offer(character: Node2D) -> void:
	_selected_weapon_scene = _pick_unowned_weapon(character)
	if _selected_weapon_scene == null:
		_selected_weapon_name = ""
		stock_label.text = "Stock: sold out for your current loadout."
		status_label.text = "Raven has nothing new to sell right now."
		hint_label.text = "Leave the safehouse when ready."
		return

	_selected_weapon_name = _get_weapon_name(_selected_weapon_scene)
	var currency_count := _get_currency_count(character)
	if weapon_cost <= 0:
		stock_label.text = "Stock: %s\nPrice: Free" % _selected_weapon_name
		status_label.text = "No %s required." % CURRENCY_DISPLAY_NAME
		hint_label.text = "Press F to claim."
	else:
		stock_label.text = "Stock: %s\nPrice: %d %s" % [_selected_weapon_name, weapon_cost, CURRENCY_DISPLAY_NAME]
		status_label.text = "You have %d %s." % [currency_count, CURRENCY_DISPLAY_NAME]
		hint_label.text = "Press F to buy."


func _try_purchase(character: Node2D) -> void:
	if _selected_weapon_scene == null:
		_set_dialog_open(false)
		return

	var inventory := character.get("inventory") as QuiverInventory
	if inventory == null:
		status_label.text = "No inventory link. Raven refuses the trade."
		return

	var currency_count := int(inventory.get_item_amount(CURRENCY_NAME))
	if currency_count < weapon_cost:
		status_label.text = "Need %d %s. You have %d." % [weapon_cost, CURRENCY_DISPLAY_NAME, currency_count]
		return

	var weapon_holder := character.get_node_or_null("Visual/WeaponHolder")
	if weapon_holder == null or not weapon_holder.has_method("add_weapon_scene"):
		status_label.text = "No weapon rig detected."
		return

	var purchased_scene := _selected_weapon_scene
	var purchased_name := _selected_weapon_name
	var slot_index := int(weapon_holder.add_weapon_scene(purchased_scene, equip_purchase_immediately))
	if slot_index < 0:
		status_label.text = "Weapon transfer failed."
		return

	if weapon_cost > 0:
		inventory.remove_item(CURRENCY_NAME, weapon_cost)

	_refresh_offer(character)
	if weapon_cost <= 0:
		status_label.text = "Claimed %s. Added to slot %d." % [purchased_name, slot_index + 1]
	else:
		status_label.text = "Purchased %s. Added to slot %d." % [purchased_name, slot_index + 1]


func _pick_unowned_weapon(character: Node2D) -> PackedScene:
	var weapon_holder := character.get_node_or_null("Visual/WeaponHolder")
	if weapon_holder == null:
		return null

	var owned := {}
	if weapon_holder.has_method("get_owned_weapon_scene_keys"):
		owned = weapon_holder.call("get_owned_weapon_scene_keys") as Dictionary

	for stock_entry in WEAPON_STOCK:
		var weapon_scene: PackedScene = stock_entry as PackedScene
		if weapon_scene == null:
			continue

		var weapon_key := weapon_scene.resource_path
		if weapon_holder.has_method("get_weapon_scene_key"):
			weapon_key = str(weapon_holder.call("get_weapon_scene_key", weapon_scene))
		if not owned.has(weapon_key):
			return weapon_scene

	return null


func _get_currency_count(character: Node2D) -> int:
	var inventory := character.get("inventory") as QuiverInventory
	if inventory == null:
		return 0
	return int(inventory.get_item_amount(CURRENCY_NAME))


func _get_weapon_name(weapon_scene: PackedScene) -> String:
	if weapon_scene == null:
		return "Unknown Weapon"

	var weapon_name := weapon_scene.resource_path.get_file().get_basename().replace("_", " ").capitalize()
	var weapon := weapon_scene.instantiate()
	if weapon is LabWeapon:
		weapon_name = (weapon as LabWeapon).get_inventory_display_name()
	weapon.free()
	return weapon_name
