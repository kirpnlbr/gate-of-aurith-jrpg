extends VBoxContainer

signal action_selected(action_type: String)

var buttons: Dictionary = {}
var _active := false
var _current_index := 0
var _visible_buttons: Array[Button] = []
var _cooldown: int = 0

func _ready() -> void:
	position = Vector2(16, 260)
	custom_minimum_size = Vector2(160, 0)

	var actions := ["Attack", "Skill", "Item", "Defend", "Stance Switch"]
	for action_name in actions:
		var btn := Button.new()
		btn.text = action_name
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.focus_mode = Control.FOCUS_NONE
		var style := StyleBoxFlat.new()
		style.bg_color = Color(0.1, 0.1, 0.2, 0.9)
		style.border_color = Color(0.3, 0.3, 0.5)
		style.border_width_left = 2
		style.border_width_right = 2
		style.border_width_top = 1
		style.border_width_bottom = 1
		style.content_margin_left = 12
		style.content_margin_right = 12
		style.content_margin_top = 4
		style.content_margin_bottom = 4
		btn.add_theme_stylebox_override("normal", style)

		var hover_style: StyleBoxFlat = style.duplicate() as StyleBoxFlat
		hover_style.bg_color = Color(0.2, 0.2, 0.4, 0.95)
		hover_style.border_color = Color.GOLD
		btn.add_theme_stylebox_override("hover", hover_style)
		btn.add_theme_stylebox_override("focus", hover_style)

		btn.add_theme_font_size_override("font_size", 14)
		btn.add_theme_color_override("font_color", Color.WHITE)
		btn.add_theme_color_override("font_hover_color", Color.GOLD)
		btn.add_theme_color_override("font_focus_color", Color.GOLD)

		var key: String = action_name.to_lower().replace(" ", "_")
		buttons[key] = btn
		add_child(btn)

	visible = false

func show_menu(character_name: String) -> void:
	visible = true
	_active = true
	_cooldown = 3  # skip a few frames before accepting input
	_current_index = 0
	buttons["stance_switch"].visible = (character_name == "Gustave")
	_rebuild_visible_buttons()
	_update_highlight()

func hide_menu() -> void:
	visible = false
	_active = false

func _rebuild_visible_buttons() -> void:
	_visible_buttons.clear()
	for key in buttons:
		if buttons[key].visible:
			_visible_buttons.append(buttons[key])

func _update_highlight() -> void:
	for i in range(_visible_buttons.size()):
		var btn: Button = _visible_buttons[i]
		if i == _current_index:
			btn.add_theme_color_override("font_color", Color.GOLD)
			btn.text = "> " + btn.text.trim_prefix("> ")
		else:
			btn.add_theme_color_override("font_color", Color.WHITE)
			btn.text = btn.text.trim_prefix("> ")

func _process(_delta: float) -> void:
	if not _active:
		return
	if _cooldown > 0:
		_cooldown -= 1
		return
	if Input.is_action_just_pressed("move_up"):
		_current_index = (_current_index - 1)
		if _current_index < 0:
			_current_index = _visible_buttons.size() - 1
		_update_highlight()
	elif Input.is_action_just_pressed("move_down"):
		_current_index = (_current_index + 1) % _visible_buttons.size()
		_update_highlight()
	elif Input.is_action_just_pressed("confirm"):
		_active = false
		var btn: Button = _visible_buttons[_current_index]
		var key: String = btn.text.trim_prefix("> ").to_lower().replace(" ", "_")
		action_selected.emit(key)
