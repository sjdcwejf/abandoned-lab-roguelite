class_name LabRavenMerchant
extends Node2D


const CURRENCY_NAME := "Protomatter Fragment"
const CURRENCY_DISPLAY_NAME := "原质"
const CURRENCY_ITEM := preload("res://tiny_wizard/items/protomatter_fragment/protomatter_fragment.tres")
const RELIC_NAME := "Relic"
const RELIC_DISPLAY_NAME := "遗物"
const RELIC_ITEM := preload("res://tiny_wizard/items/relic/relic.tres")
const RELIC_RECYCLE_VALUE := 5
const CHINESE_FONT_BOOTSTRAP := preload("res://tiny_wizard/gui/chinese_font_bootstrap.gd")
const INTERACTION_FEEDBACK := preload("res://tiny_wizard/gui/interaction_feedback.gd")
const WEAPON_CHOICE_OVERLAY := preload("res://tiny_wizard/gui/weapon_choice_overlay/weapon_choice_overlay.gd")
const WEAPON_CATALOG := preload("res://tiny_wizard/player/weapons/weapon_catalog.gd")
const OFFER_NONE := "none"
const OFFER_WEAPON := "weapon"
const OFFER_RELIC_RECYCLE := "relic_recycle"

@export var merchant_title := "渡鸦检疫军械库"
@export_multiline var merchant_message := "A-03 信号就在前方。补好神经接口，数清你的炸药。"
@export_range(0, 99, 1) var weapon_cost := 1
@export var equip_purchase_immediately := true
@export var use_weapon_comparison := true

var _candidate_character: Node2D
var _dialog_open := false
var _selected_offer_type := OFFER_NONE
var _available_offers: Array[Dictionary] = []
var _selected_offer_index := 0
var _selected_weapon_scene: PackedScene
var _selected_weapon_name := ""
var _offer_preview_instance: Node2D
var _awaiting_weapon_replacement := false
var _retired_weapon_keys := {}
var _choice_overlay: LabWeaponChoiceOverlay
var _visual_time := 0.0

@onready var interact_area: Area2D = $InteractArea
@onready var prompt: CanvasItem = $Prompt
@onready var dialog_panel: Control = $DialogPanel
@onready var title_label: Label = $DialogPanel/MarginContainer/VBoxContainer/Title
@onready var message_label: Label = $DialogPanel/MarginContainer/VBoxContainer/Message
@onready var stock_label: Label = $DialogPanel/MarginContainer/VBoxContainer/Stock
@onready var status_label: Label = $DialogPanel/MarginContainer/VBoxContainer/Status
@onready var hint_label: Label = $DialogPanel/MarginContainer/VBoxContainer/Hint
@onready var status_light: CanvasItem = get_node_or_null("CounterStatusLight") as CanvasItem
@onready var offer_preview: Node2D = $OfferPreview
@onready var raven_sprite: Sprite2D = get_node_or_null("RavenSprite") as Sprite2D
@onready var counter_sprite: Sprite2D = get_node_or_null("CounterSprite") as Sprite2D
@onready var counter_scan_line: Polygon2D = get_node_or_null("CounterScanLine") as Polygon2D


func _ready() -> void:
	CHINESE_FONT_BOOTSTRAP.apply_to_tree(self)
	prompt.visible = false
	dialog_panel.visible = false
	title_label.text = merchant_title
	message_label.text = merchant_message
	stock_label.text = ""
	status_label.text = ""
	interact_area.body_entered.connect(_on_interact_area_body_entered)
	interact_area.body_exited.connect(_on_interact_area_body_exited)


func _process(_delta: float) -> void:
	_update_idle_visuals(_delta)
	if _candidate_character == null:
		return
	if _has_active_choice_overlay():
		return
	if _dialog_open and _awaiting_weapon_replacement:
		var replacement_slot := _get_pressed_replacement_slot()
		if replacement_slot >= 0:
			_try_purchase(_candidate_character, replacement_slot)
		return
	if _dialog_open and _handle_offer_selection_input(_candidate_character):
		return
	if Input.is_action_just_pressed("interact"):
		if _dialog_open:
			_try_purchase(_candidate_character)
		else:
			_open_armory(_candidate_character)


func _update_idle_visuals(delta: float) -> void:
	_visual_time += delta
	var slow_pulse := (sin(_visual_time * 2.6) + 1.0) * 0.5
	var fast_pulse := (sin(_visual_time * 7.2) + 1.0) * 0.5

	if raven_sprite != null:
		raven_sprite.position.y = -40.0 + sin(_visual_time * 1.8) * 0.5

	if counter_sprite != null:
		counter_sprite.position.y = -24.0 + sin(_visual_time * 1.4) * 0.18

	if counter_scan_line != null:
		counter_scan_line.position.x = 58.0 + lerpf(-4.0, 4.0, slow_pulse)
		counter_scan_line.color = Color(0.52, 1.0, 1.0, 0.18 + 0.16 * fast_pulse)

	if status_light is Polygon2D and not _dialog_open:
		var light := status_light as Polygon2D
		light.color = Color(0.22 + 0.08 * slow_pulse, 0.78 + 0.16 * slow_pulse, 0.84 + 0.1 * slow_pulse, 1.0)


func _on_interact_area_body_entered(body: Node2D) -> void:
	if not body.has_node("Visual/WeaponHolder"):
		return
	_candidate_character = body
	if prompt is Label:
		(prompt as Label).text = "按 F 交易"
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
	if not _dialog_open:
		_awaiting_weapon_replacement = false
		_close_choice_overlay()
	dialog_panel.visible = _dialog_open
	if status_light is Polygon2D:
		var light := status_light as Polygon2D
		light.color = Color(0.65, 1.0, 0.62, 1.0) if _dialog_open else Color(0.28, 0.9, 0.95, 1.0)


func _refresh_offer(character: Node2D) -> void:
	_awaiting_weapon_replacement = false
	_available_offers = _build_available_offers(character)
	if _available_offers.is_empty():
		_show_empty_stock(character)
		return

	_selected_offer_index = clampi(_selected_offer_index, 0, _available_offers.size() - 1)
	_apply_selected_offer(character)


func _apply_selected_offer(character: Node2D) -> void:
	if _available_offers.is_empty():
		_show_empty_stock(character)
		return

	var selected_offer := _available_offers[_selected_offer_index]
	_selected_offer_type = str(selected_offer.get("type", OFFER_NONE))
	_selected_weapon_scene = selected_offer.get("scene") as PackedScene
	_selected_weapon_name = str(selected_offer.get("name", ""))

	if _selected_offer_type == OFFER_WEAPON:
		_build_offer_preview(_selected_weapon_scene)
	else:
		_clear_offer_preview()

	stock_label.text = _build_stock_list_text()
	var currency_count := _get_currency_count(character)
	var relic_count := _get_relic_count(character)

	if _selected_offer_type == OFFER_RELIC_RECYCLE:
		var weapon_stock_note := ""
		if not _has_weapon_offer_available():
			weapon_stock_note = "\n当前无武器可供购买；原质可用于购买后续武器。"
		status_label.text = "你持有 %d 个%s、%d 个%s。回收 1 个%s可换取 %d 个%s。" % [
			currency_count,
			CURRENCY_DISPLAY_NAME,
			relic_count,
			RELIC_DISPLAY_NAME,
			RELIC_DISPLAY_NAME,
			RELIC_RECYCLE_VALUE,
			CURRENCY_DISPLAY_NAME,
		] + weapon_stock_note
		hint_label.text = "↑ / ↓ 选择项目，按 F 回收遗物。"
		return

	var quick_slots_full := _are_quick_slots_full(character)
	var can_afford := weapon_cost <= 0 or currency_count >= weapon_cost
	var slot_note := "购买后需选择替换槽位。" if quick_slots_full else "购买前会打开武器对比。"
	if not can_afford:
		status_label.text = "原质不足：需要 %d 个%s，你现在有 %d 个。" % [
			weapon_cost,
			CURRENCY_DISPLAY_NAME,
			currency_count,
		]
		hint_label.text = "清理样本获取原质，或回收遗物后再交易。"
	elif weapon_cost <= 0:
		status_label.text = "当前选择：%s。免费领取。%s" % [_selected_weapon_name, slot_note]
		hint_label.text = "↑ / ↓ 选择项目，按 F 领取。"
	else:
		status_label.text = "当前选择：%s。价格：%d 个%s。%s" % [
			_selected_weapon_name,
			weapon_cost,
			CURRENCY_DISPLAY_NAME,
			slot_note,
		]
		hint_label.text = "↑ / ↓ 选择项目，按 F 购买。列表前四项可按 1 / 2 / 3 / 4 快速选择。"


func _show_empty_stock(character: Node2D) -> void:
	_selected_offer_type = OFFER_NONE
	_selected_weapon_scene = null
	_selected_weapon_name = ""
	_available_offers.clear()
	_clear_offer_preview()

	var currency_count := _get_currency_count(character)
	var relic_count := _get_relic_count(character)
	stock_label.text = "库存：当前无武器可供购买。"
	status_label.text = "你持有 %d 个%s、%d 个%s。%s可用于购买武器。" % [
		currency_count,
		CURRENCY_DISPLAY_NAME,
		relic_count,
		RELIC_DISPLAY_NAME,
		CURRENCY_DISPLAY_NAME,
	]
	hint_label.text = "本商人没有新的武器库存。离开商店，前往下一处渡鸦军械终端。"


func _try_purchase(character: Node2D, replacement_slot := -1) -> void:
	var validation := _validate_purchase(character)
	if not bool(validation.get("ok", false)):
		status_label.text = str(validation.get("message", "交易失败。"))
		INTERACTION_FEEDBACK.show_from(self, status_label.text, 1.4)
		if bool(validation.get("refresh", false)):
			_refresh_offer(character)
		return

	if _selected_offer_type == OFFER_RELIC_RECYCLE:
		_complete_relic_recycle(character, validation)
		return

	if _selected_offer_type == OFFER_WEAPON and replacement_slot < 0 and _are_quick_slots_full(character):
		_enter_weapon_replacement_mode()
		return

	if _selected_offer_type == OFFER_WEAPON and use_weapon_comparison and replacement_slot < 0:
		_show_purchase_comparison(character, validation.get("weapon_holder") as Node)
		return

	_complete_purchase(character, replacement_slot)


func _validate_purchase(character: Node2D) -> Dictionary:
	if _selected_offer_type == OFFER_NONE:
		return {"ok": false, "message": "当前无武器可供购买。原质可用于购买武器。"}

	var inventory := character.get("inventory") as QuiverInventory
	if inventory == null:
		return {"ok": false, "message": "未检测到背包连接。渡鸦拒绝交易。"}

	if _selected_offer_type == OFFER_RELIC_RECYCLE:
		var relic_count := _get_relic_count(character)
		if relic_count <= 0:
			return {"ok": false, "message": "你没有可回收的遗物。击败关卡 Boss 后再回来。"}
		if not _can_receive_currency(inventory):
			return {"ok": false, "message": "背包没有空间接收原质。"}
		return {
			"ok": true,
			"inventory": inventory,
		}

	if _selected_offer_type == OFFER_WEAPON and _selected_weapon_scene == null:
		return {"ok": false, "message": "渡鸦暂时没有可售武器。"}

	var currency_count := int(inventory.get_item_amount(CURRENCY_NAME))
	if currency_count < weapon_cost:
		return {
			"ok": false,
			"message": "需要 %d 个%s，你现在有 %d 个。" % [weapon_cost, CURRENCY_DISPLAY_NAME, currency_count],
		}

	var weapon_holder := character.get_node_or_null("Visual/WeaponHolder")
	if weapon_holder == null or not weapon_holder.has_method("add_weapon_scene"):
		return {"ok": false, "message": "未检测到武器挂架。"}
	if weapon_holder.has_method("has_weapon_scene") and bool(weapon_holder.call("has_weapon_scene", _selected_weapon_scene)):
		return {
			"ok": false,
			"message": "你已经拥有 %s。渡鸦换了一件货。" % _selected_weapon_name,
			"refresh": true,
		}

	return {
		"ok": true,
		"inventory": inventory,
		"weapon_holder": weapon_holder,
	}


func _show_purchase_comparison(character: Node2D, weapon_holder: Node) -> void:
	if _has_active_choice_overlay():
		return

	var has_free_slot := true
	if weapon_holder.has_method("has_free_quick_slot"):
		has_free_slot = bool(weapon_holder.call("has_free_quick_slot"))

	var price_text := "价格：免费"
	if weapon_cost > 0:
		price_text = "价格：%d 个%s" % [weapon_cost, CURRENCY_DISPLAY_NAME]

	_choice_overlay = WEAPON_CHOICE_OVERLAY.present(self, {
		"weapon_holder": weapon_holder,
		"weapon_scene": _selected_weapon_scene,
		"title": "渡鸦交易确认",
		"action": "购买",
		"cost": price_text,
		"allow_empty_slot": has_free_slot,
	})
	var active_overlay := _choice_overlay
	_choice_overlay.tree_exiting.connect(func() -> void:
		if _choice_overlay == active_overlay:
			_choice_overlay = null
	)
	_choice_overlay.confirmed.connect(func(slot_index: int) -> void:
		_choice_overlay = null
		if is_instance_valid(character):
			_complete_purchase(character, slot_index)
	)
	_choice_overlay.cancelled.connect(func() -> void:
		_choice_overlay = null
		status_label.text = "交易已取消，未消耗%s。" % CURRENCY_DISPLAY_NAME
	)


func _complete_purchase(character: Node2D, replacement_slot := -1) -> void:
	var validation := _validate_purchase(character)
	if not bool(validation.get("ok", false)):
		status_label.text = str(validation.get("message", "交易失败。"))
		INTERACTION_FEEDBACK.show_from(self, status_label.text, 1.4)
		if bool(validation.get("refresh", false)):
			_refresh_offer(character)
		return

	var inventory := validation.get("inventory") as QuiverInventory
	var weapon_holder := validation.get("weapon_holder") as Node
	if inventory == null or weapon_holder == null:
		status_label.text = "交易连接中断。"
		return

	var purchased_scene := _selected_weapon_scene
	var purchased_name := _selected_weapon_name
	var replaced_weapon_name := ""
	var replaced_weapon_scene: PackedScene
	var slot_index := -1
	if weapon_holder.has_method("has_free_quick_slot") and not bool(weapon_holder.call("has_free_quick_slot")):
		if replacement_slot < 0:
			_enter_weapon_replacement_mode()
			return
		if not weapon_holder.has_method("replace_weapon_scene_in_slot"):
			status_label.text = "武器栏已满，当前挂架不支持替换。"
			return
		if weapon_holder.has_method("get_weapon_display_name_at_slot"):
			replaced_weapon_name = str(weapon_holder.call("get_weapon_display_name_at_slot", replacement_slot))
		replaced_weapon_scene = _get_weapon_scene_at_slot(weapon_holder, replacement_slot)
		slot_index = int(weapon_holder.call("replace_weapon_scene_in_slot", purchased_scene, replacement_slot))
	else:
		slot_index = int(weapon_holder.add_weapon_scene(purchased_scene, equip_purchase_immediately))
	if slot_index < 0:
		status_label.text = "武器转移失败。"
		return

	if weapon_cost > 0:
		inventory.remove_item(CURRENCY_NAME, weapon_cost)
	if replaced_weapon_scene != null:
		_retire_weapon_scene(weapon_holder, replaced_weapon_scene)

	_refresh_offer(character)
	var no_weapon_stock_after_purchase := not _has_weapon_offer_available()
	if replaced_weapon_name != "":
		status_label.text = "已获得 %s，替换了 %s，并装备到 %d 号位。" % [purchased_name, replaced_weapon_name, slot_index + 1]
	elif weapon_cost <= 0:
		status_label.text = "已领取 %s，加入 %d 号位。" % [purchased_name, slot_index + 1]
	else:
		status_label.text = "已购买 %s，加入 %d 号位。" % [purchased_name, slot_index + 1]
	if no_weapon_stock_after_purchase:
		status_label.text += "\n当前无武器可供购买。%s可用于购买武器。" % CURRENCY_DISPLAY_NAME
		hint_label.text = "本商人没有新的武器库存。仍可回收遗物换取原质。"
	INTERACTION_FEEDBACK.show_from(self, "交易完成：%s。" % purchased_name, 1.35)


func _complete_relic_recycle(character: Node2D, validation: Dictionary) -> void:
	var inventory := validation.get("inventory") as QuiverInventory
	if inventory == null:
		status_label.text = "回收失败：未检测到背包连接。"
		return

	if _get_relic_count(character) <= 0:
		status_label.text = "你没有可回收的遗物。"
		return

	var recycled := _remove_one_relic(character, inventory)
	if not recycled:
		status_label.text = "回收失败：遗物状态已变化。"
		_refresh_offer(character)
		return

	var added := inventory.add_item(CURRENCY_ITEM, RELIC_RECYCLE_VALUE)
	if not added:
		if RELIC_ITEM != null and _get_relic_controller(character) == null:
			inventory.add_item(RELIC_ITEM, 1)
		status_label.text = "回收失败：背包无法接收原质。"
		INTERACTION_FEEDBACK.show_from(self, status_label.text, 1.35)
		return

	_refresh_offer(character)
	status_label.text = "已回收 1 个%s，获得 %d 个%s。" % [
		RELIC_DISPLAY_NAME,
		RELIC_RECYCLE_VALUE,
		CURRENCY_DISPLAY_NAME,
	]
	INTERACTION_FEEDBACK.show_from(self, "回收完成：+%d %s。" % [RELIC_RECYCLE_VALUE, CURRENCY_DISPLAY_NAME], 1.35)


func _enter_weapon_replacement_mode() -> void:
	_awaiting_weapon_replacement = true
	status_label.text = "武器栏已满：请选择要替换的槽位。确认前不会扣除%s。" % CURRENCY_DISPLAY_NAME
	hint_label.text = "按 1 / 2 / 3 / 4 替换对应武器并购买。"


func _handle_offer_selection_input(character: Node2D) -> bool:
	if _available_offers.is_empty():
		return false

	if InputMap.has_action("ui_up") and Input.is_action_just_pressed("ui_up"):
		_select_offer_index(_selected_offer_index - 1, character)
		return true
	if InputMap.has_action("ui_down") and Input.is_action_just_pressed("ui_down"):
		_select_offer_index(_selected_offer_index + 1, character)
		return true

	var max_direct_slots := mini(4, _available_offers.size())
	for offer_index in range(max_direct_slots):
		var action_name := "weapon_slot_%d" % (offer_index + 1)
		if InputMap.has_action(action_name) and Input.is_action_just_pressed(action_name):
			_select_offer_index(offer_index, character)
			return true
	return false


func _select_offer_index(next_index: int, character: Node2D) -> void:
	if _available_offers.is_empty():
		return
	_selected_offer_index = wrapi(next_index, 0, _available_offers.size())
	_awaiting_weapon_replacement = false
	_apply_selected_offer(character)


func _has_active_choice_overlay() -> bool:
	if _choice_overlay == null:
		return false
	if is_instance_valid(_choice_overlay):
		return true
	_choice_overlay = null
	return false


func _close_choice_overlay() -> void:
	if _choice_overlay == null:
		return
	if is_instance_valid(_choice_overlay):
		_choice_overlay.queue_free()
	_choice_overlay = null


func _get_pressed_replacement_slot() -> int:
	for slot_index in range(4):
		var action_name := "weapon_slot_%d" % (slot_index + 1)
		if InputMap.has_action(action_name) and Input.is_action_just_pressed(action_name):
			return slot_index
	return -1


func _are_quick_slots_full(character: Node2D) -> bool:
	var weapon_holder := character.get_node_or_null("Visual/WeaponHolder")
	if weapon_holder == null or not weapon_holder.has_method("has_free_quick_slot"):
		return false
	return not bool(weapon_holder.call("has_free_quick_slot"))


func _build_available_offers(character: Node2D) -> Array[Dictionary]:
	var offers: Array[Dictionary] = []
	for weapon_scene in _get_available_weapon_scenes(character):
		offers.append({
			"type": OFFER_WEAPON,
			"scene": weapon_scene,
			"name": _get_weapon_name(weapon_scene),
		})
	offers.append({
		"type": OFFER_RELIC_RECYCLE,
		"name": "回收%s" % RELIC_DISPLAY_NAME,
	})
	return offers


func _get_available_weapon_scenes(character: Node2D) -> Array[PackedScene]:
	var available: Array[PackedScene] = []
	var weapon_holder := character.get_node_or_null("Visual/WeaponHolder")
	if weapon_holder == null:
		return available

	var owned := {}
	if weapon_holder.has_method("get_owned_weapon_scene_keys"):
		owned = weapon_holder.call("get_owned_weapon_scene_keys") as Dictionary

	for stock_entry in WEAPON_CATALOG.get_weapon_pool_for_context(self):
		var weapon_scene: PackedScene = stock_entry as PackedScene
		if weapon_scene == null:
			continue

		var weapon_key := WEAPON_CATALOG.get_weapon_key(weapon_scene, weapon_holder)
		if _retired_weapon_keys.has(weapon_key):
			continue
		if not owned.has(weapon_key):
			available.append(weapon_scene)

	return available


func _build_stock_list_text() -> String:
	var lines := ["库存："]
	for index in range(_available_offers.size()):
		var offer := _available_offers[index]
		var marker := ">" if index == _selected_offer_index else " "
		var direct_key := "%d" % (index + 1) if index < 4 else "-"
		var offer_type := str(offer.get("type", OFFER_NONE))
		if offer_type == OFFER_WEAPON:
			var price := "免费" if weapon_cost <= 0 else "%d %s" % [weapon_cost, CURRENCY_DISPLAY_NAME]
			lines.append("%s [%s] %s  /  %s" % [
				marker,
				direct_key,
				str(offer.get("name", "未知武器")),
				price,
			])
		elif offer_type == OFFER_RELIC_RECYCLE:
			lines.append("%s [%s] 回收%s  /  +%d %s" % [
				marker,
				direct_key,
				RELIC_DISPLAY_NAME,
				RELIC_RECYCLE_VALUE,
				CURRENCY_DISPLAY_NAME,
			])
	return "\n".join(lines)


func _has_weapon_offer_available() -> bool:
	for offer in _available_offers:
		if str(offer.get("type", OFFER_NONE)) == OFFER_WEAPON:
			return true
	return false


func _get_weapon_scene_at_slot(weapon_holder: Node, slot_index: int) -> PackedScene:
	var weapon_scenes := weapon_holder.get("weapon_scenes") as Array
	if weapon_scenes == null or slot_index < 0 or slot_index >= weapon_scenes.size():
		return null
	return weapon_scenes[slot_index] as PackedScene


func _retire_weapon_scene(weapon_holder: Node, weapon_scene: PackedScene) -> void:
	if weapon_scene == null:
		return
	var weapon_key := weapon_scene.resource_path
	if weapon_holder.has_method("get_weapon_scene_key"):
		weapon_key = str(weapon_holder.call("get_weapon_scene_key", weapon_scene))
	if weapon_key != "":
		_retired_weapon_keys[weapon_key] = true


func _get_currency_count(character: Node2D) -> int:
	var inventory := character.get("inventory") as QuiverInventory
	if inventory == null:
		return 0
	return int(inventory.get_item_amount(CURRENCY_NAME))


func _get_relic_count(character: Node2D) -> int:
	var inventory := character.get("inventory") as QuiverInventory
	var relic_count := 0
	if inventory != null:
		relic_count += int(inventory.get_item_amount(RELIC_NAME))
	var relic_controller := _get_relic_controller(character)
	if relic_controller != null:
		relic_count += int(relic_controller.get_total_relic_count())
	return relic_count


func _get_relic_controller(character: Node2D) -> RelicController:
	if character == null:
		return null
	return character.get_node_or_null("RelicController") as RelicController


func _remove_one_relic(character: Node2D, inventory: QuiverInventory) -> bool:
	var relic_controller := _get_relic_controller(character)
	if relic_controller != null:
		var relic_id := relic_controller.get_first_relic_id()
		if relic_id != &"":
			return relic_controller.remove_one_relic(relic_id)
	if inventory != null and int(inventory.get_item_amount(RELIC_NAME)) > 0:
		inventory.remove_item(RELIC_NAME, 1)
		return true
	return false


func _can_receive_currency(inventory: QuiverInventory) -> bool:
	if inventory == null or CURRENCY_ITEM == null:
		return false
	var room_left := int(inventory.call("_room_left_for_item", CURRENCY_ITEM))
	return room_left == -1 or room_left >= RELIC_RECYCLE_VALUE


func _get_weapon_name(weapon_scene: PackedScene) -> String:
	return WEAPON_CATALOG.get_weapon_display_name(weapon_scene)


func _build_offer_preview(weapon_scene: PackedScene) -> void:
	_clear_offer_preview()
	if weapon_scene == null:
		return

	_offer_preview_instance = weapon_scene.instantiate() as Node2D
	if _offer_preview_instance == null:
		return

	offer_preview.add_child(_offer_preview_instance)
	_offer_preview_instance.position = Vector2.ZERO
	_offer_preview_instance.rotation = -0.2
	_offer_preview_instance.scale = Vector2(0.45, 0.45)
	_disable_preview_interaction(_offer_preview_instance)


func _clear_offer_preview() -> void:
	if offer_preview == null:
		return
	for child in offer_preview.get_children():
		child.queue_free()
	_offer_preview_instance = null


func _disable_preview_interaction(root: Node) -> void:
	root.process_mode = Node.PROCESS_MODE_DISABLED
	if root is CollisionObject2D:
		var collision_object := root as CollisionObject2D
		collision_object.collision_layer = 0
		collision_object.collision_mask = 0
		if collision_object is Area2D:
			(collision_object as Area2D).monitoring = false
			(collision_object as Area2D).monitorable = false

	if root is CollisionShape2D:
		(root as CollisionShape2D).disabled = true

	for child in root.get_children():
		_disable_preview_interaction(child)
