extends QuiverPickItemAction


const INTERACTION_FEEDBACK := preload("res://tiny_wizard/gui/interaction_feedback.gd")


func pick_item(pickable_item: QuiverPickableItem, character: QuiverCharacter):
	var next_action = get_node_or_null("OnFailure")
	var item := pickable_item.item
	var success := false

	if character.can_grab_items and character.inventory != null and item != null:
		success = bool(character.inventory.add_item(item))

	if success:
		next_action = get_node_or_null("OnSuccess")
		if _should_show_pickup_feedback(pickable_item):
			INTERACTION_FEEDBACK.show_from(pickable_item, _success_message(item), 1.25)
	else:
		if _should_show_pickup_feedback(pickable_item):
			INTERACTION_FEEDBACK.show_from(pickable_item, _failure_message(item, character), 1.25)

	if next_action is QuiverInteractableObjectAction:
		next_action.trigger(pickable_item, character)


func _should_show_pickup_feedback(pickable_item: QuiverPickableItem) -> bool:
	var node: Node = pickable_item
	while node != null:
		var room_type = node.get("lab_room_type")
		if room_type is String:
			return String(room_type).begins_with("tutorial")
		node = node.get_parent()
	return false


func _success_message(item: QuiverItem) -> String:
	match item.name:
		"Protomatter Fragment":
			return "回收原质碎片。"
		"Breach Charge":
			return "获得破障炸药。"
		"Biometric Key":
			return "获得生物识别钥。"
		_:
			return "已拾取：%s。" % _display_name(item)


func _failure_message(item: QuiverItem, character: QuiverCharacter) -> String:
	if not character.can_grab_items:
		return "当前无法拾取。"
	return "背包无法接收：%s。" % _display_name(item)


func _display_name(item: QuiverItem) -> String:
	if item == null or item.name == "":
		return "未知物资"
	match item.name:
		"Protomatter Fragment":
			return "原质碎片"
		"Breach Charge":
			return "破障炸药"
		"Biometric Key":
			return "生物识别钥"
		_:
			return item.name
