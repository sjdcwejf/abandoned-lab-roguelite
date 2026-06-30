extends Room


const CHINESE_FONT_BOOTSTRAP := preload("res://tiny_wizard/gui/chinese_font_bootstrap.gd")

var _choice_made := false
var _relic_controller: RelicController
var _next_chapter_title := "下一章"

@onready var exit_black_hole: LabBlackHole = get_node_or_null("ExitBlackHole") as LabBlackHole
@onready var relic_choices: Node = get_node_or_null("RelicChoices")
@onready var status_label: Label = get_node_or_null("StatusLabel") as Label
@onready var chapter_label: Label = get_node_or_null("ChapterLabel") as Label
@onready var archive_label: Label = get_node_or_null("ArchiveLabel") as Label


func _ready() -> void:
	lock_chests_until_cleared = false
	super._ready()
	CHINESE_FONT_BOOTSTRAP.apply_to_tree(self)
	_configure_text()
	_connect_relic_choices()
	if exit_black_hole != null:
		exit_black_hole.enter_prompt_text = "按 F 进入%s" % _next_chapter_title
		exit_black_hole.stabilizing_text = "下一区域入口稳定中。"
		exit_black_hole.set_active(false)


func set_relic_controller(controller: RelicController) -> void:
	_relic_controller = controller
	_update_status()


func enter_room() -> void:
	super.enter_room()
	_update_status()


func _configure_text() -> void:
	var completed_chapter := str(get_meta("completed_chapter_title", "第一章：极渊前哨基地"))
	var next_chapter := str(get_meta("next_chapter_title", "第二章：生态温室"))
	_next_chapter_title = next_chapter
	if chapter_label != null:
		chapter_label.text = "%s 已完成\n临时安全屋 / 渡鸦据点已解锁" % completed_chapter
	if archive_label != null:
		archive_label.text = "档案终端：前哨记录已归档。\n渡鸦备注：进入 %s 前，选择一个遗物作为下一章构筑起点。" % next_chapter


func _connect_relic_choices() -> void:
	if relic_choices == null:
		return

	for child in relic_choices.get_children():
		var pickup := child as RelicPickup
		if pickup == null:
			continue
		var picked_callable := Callable(self, "_on_relic_choice_picked")
		if not pickup.picked_up.is_connected(picked_callable):
			pickup.picked_up.connect(picked_callable)


func _on_relic_choice_picked(definition: BuildItemDefinition) -> void:
	if _choice_made:
		return

	_choice_made = true
	var relic_name := _get_relic_name(definition)
	_remove_unpicked_relic_choices(definition)
	if exit_black_hole != null:
		exit_black_hole.set_active(true)
	_update_status("已选择遗物：%s。渡鸦据点补给完成，%s 入口已稳定。" % [relic_name, _next_chapter_title])


func _remove_unpicked_relic_choices(picked_definition: BuildItemDefinition) -> void:
	if relic_choices == null:
		return

	for child in relic_choices.get_children():
		var pickup := child as RelicPickup
		if pickup == null:
			continue
		if pickup.relic_definition == picked_definition:
			continue
		pickup.queue_free()


func _update_status(override_text := "") -> void:
	if status_label == null:
		return
	if override_text != "":
		status_label.text = override_text
		return
	if _choice_made:
		status_label.text = "%s 入口已稳定。整理补给后，进入下一章。" % _next_chapter_title
		return

	var relic_count := 0
	if _relic_controller != null:
		relic_count = _relic_controller.get_total_relic_count()
	status_label.text = "当前遗物：%d。请选择 1 个遗物，随后开启%s入口。" % [relic_count, _next_chapter_title]


func _get_relic_name(definition: BuildItemDefinition) -> String:
	if definition == null:
		return "未知遗物"
	if definition.display_name != "":
		return definition.display_name
	if definition.placeholder_text != "":
		return definition.placeholder_text
	return str(definition.item_id)
