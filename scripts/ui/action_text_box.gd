extends PanelContainer

var label: RichTextLabel = null
var _tween: Tween = null
var _char_count: int = 0
const CHARS_PER_SECOND := 60.0

func _ready() -> void:
	# Style the panel
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.05, 0.12, 0.92)
	style.border_color = Color(0.4, 0.4, 0.6)
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_width_left = 2
	style.border_width_right = 2
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	add_theme_stylebox_override("panel", style)

	# Position at bottom of screen
	set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	custom_minimum_size = Vector2(0, 70)
	offset_top = -70
	offset_bottom = 0
	offset_left = 16
	offset_right = -16

	# Create label
	label = RichTextLabel.new()
	label.name = "ActionLabel"
	label.bbcode_enabled = true
	label.fit_content = true
	label.add_theme_font_size_override("normal_font_size", 16)
	label.add_theme_color_override("default_color", Color.WHITE)
	add_child(label)

func display(text: String) -> void:
	if _tween and _tween.is_running():
		_tween.kill()
	label.text = text
	label.visible_characters = -1

func display_instant(text: String) -> void:
	if _tween and _tween.is_running():
		_tween.kill()
	label.text = text
	label.visible_characters = -1

func skip_typewriter() -> void:
	if _tween and _tween.is_running():
		_tween.kill()
		label.visible_characters = -1

func is_typing() -> bool:
	return _tween != null and _tween.is_running()

func clear_text() -> void:
	if _tween and _tween.is_running():
		_tween.kill()
	label.text = ""
