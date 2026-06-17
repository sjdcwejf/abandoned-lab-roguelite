class_name LabChineseFontBootstrap
extends RefCounted


const TEST_GLYPHS := "中文铁幕流影蜂群蚀瞳"

static var _installed := false
static var _installed_font_path := ""
static var _ui_font: FontFile


static func install() -> void:
	if _installed:
		return

	var font := _load_first_available_font()
	if font == null:
		push_warning("没有找到可用中文 UI 字体，中文可能显示异常。")
		_installed = true
		return

	_ui_font = font
	ThemeDB.set_fallback_font(font)
	ThemeDB.set_fallback_font_size(14)
	_install_project_theme(font)
	_installed = true


static func get_installed_font_path() -> String:
	return _installed_font_path


static func apply_to_tree(root: Node) -> void:
	install()
	if root == null or _ui_font == null:
		return
	_apply_to_node(root)


static func get_ui_font() -> FontFile:
	install()
	return _ui_font


static func _install_project_theme(font: FontFile) -> void:
	if not ThemeDB.has_method("set_project_theme"):
		return

	var theme := Theme.new()
	theme.default_font = font
	theme.default_font_size = 14
	ThemeDB.call("set_project_theme", theme)


static func _apply_to_node(node: Node) -> void:
	if node is Control:
		_apply_to_control(node as Control)

	for child in node.get_children():
		_apply_to_node(child)


static func _apply_to_control(control: Control) -> void:
	control.add_theme_font_override("font", _ui_font)
	control.add_theme_font_override("normal_font", _ui_font)
	control.add_theme_font_override("bold_font", _ui_font)
	control.add_theme_font_override("italics_font", _ui_font)
	control.add_theme_font_override("bold_italics_font", _ui_font)
	control.add_theme_font_override("mono_font", _ui_font)


static func _load_first_available_font() -> FontFile:
	for path in _get_candidate_paths():
		if not FileAccess.file_exists(path):
			continue

		var font := FontFile.new()
		var error := font.load_dynamic_font(path)
		if error != OK:
			continue
		if not _supports_required_glyphs(font):
			continue

		_installed_font_path = path
		return font

	return null


static func _supports_required_glyphs(font: FontFile) -> bool:
	for index in range(TEST_GLYPHS.length()):
		if not font.has_char(TEST_GLYPHS.unicode_at(index)):
			return false
	return true


static func _get_candidate_paths() -> Array[String]:
	return [
		# Project-local fonts should be preferred if we add an open-source font later.
		"res://tiny_wizard/assets/fonts/NotoSansSC-Regular.otf",
		"res://tiny_wizard/assets/fonts/NotoSansCJKsc-Regular.otf",
		"res://tiny_wizard/assets/fonts/SourceHanSansSC-Regular.otf",
		"res://tiny_wizard/assets/fonts/SourceHanSansCN-Regular.otf",
		# macOS.
		"/System/Library/Fonts/STHeiti Medium.ttc",
		"/System/Library/Fonts/STHeiti Light.ttc",
		"/System/Library/Fonts/Supplemental/Songti.ttc",
		"/System/Library/Fonts/CJKSymbolsFallback.ttc",
		# Windows.
		"C:/Windows/Fonts/msyh.ttc",
		"C:/Windows/Fonts/msyh.ttf",
		"C:/Windows/Fonts/simhei.ttf",
		"C:/Windows/Fonts/simsun.ttc",
		# Linux common packages.
		"/usr/share/fonts/opentype/noto/NotoSansCJK-Regular.ttc",
		"/usr/share/fonts/opentype/noto/NotoSansCJKsc-Regular.otf",
		"/usr/share/fonts/truetype/noto/NotoSansCJK-Regular.ttc",
		"/usr/share/fonts/truetype/noto/NotoSansSC-Regular.otf",
		"/usr/share/fonts/opentype/source-han-sans/SourceHanSansSC-Regular.otf",
		"/usr/share/fonts/adobe-source-han-sans/SourceHanSansSC-Regular.otf",
	]
