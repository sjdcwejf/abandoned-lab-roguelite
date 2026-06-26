class_name RelicHudEntry
extends HBoxContainer

@onready var icon_rect: TextureRect = $IconSlot/Icon
@onready var name_label: Label = $NameLabel
@onready var stack_label: Label = $StackLabel


func set_relic_data(relic_data: Dictionary) -> void:
	var icon := relic_data.get("icon", null) as Texture2D
	icon_rect.texture = icon

	var display_text := str(relic_data.get("display_name", ""))
	if display_text == "":
		display_text = str(relic_data.get("placeholder_text", ""))
	if display_text == "":
		display_text = str(relic_data.get("relic_id", ""))
	name_label.text = display_text

	var stack_count := int(relic_data.get("stack_count", 0))
	stack_label.text = "x%d" % stack_count if stack_count > 1 else ""


func set_synergy_data(synergy_data: Dictionary) -> void:
	icon_rect.texture = null

	var display_text := str(synergy_data.get("display_name", ""))
	if display_text == "":
		display_text = str(synergy_data.get("placeholder_text", ""))
	if display_text == "":
		display_text = str(synergy_data.get("synergy_id", ""))
	name_label.text = "[融合] %s" % display_text

	var tier := int(synergy_data.get("tier", 0))
	stack_label.text = "T%d" % tier if tier > 1 else ""
