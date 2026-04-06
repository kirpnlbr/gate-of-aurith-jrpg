extends PanelContainer

var label: RichTextLabel = null

func _ready() -> void:
	# Style the panel to match status panel aesthetic
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.07, 0.14, 0.9)
	style.border_color = Color(0.3, 0.3, 0.5, 0.6)
	style.set_border_width_all(1)
	style.set_corner_radius_all(6)
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	style.shadow_color = Color(0.1, 0.12, 0.3, 0.4)
	style.shadow_size = 4
	style.shadow_offset = Vector2(0, -2)
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
	label.text = text
	label.visible_characters = -1

func clear_text() -> void:
	label.text = ""
