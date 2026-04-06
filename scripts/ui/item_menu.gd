extends VBoxContainer

signal item_selected(item_data: Resource, item_index: int)
signal cancelled
signal highlight_changed(description: String)

var _items: Array[Dictionary] = []
var _active := false
var _current_index := 0
var _item_buttons: Array[Button] = []
var _cooldown: int = 0

func _ready() -> void:
	# Position next to action menu (right of it, above action text box)
	position = Vector2(148, 310)
	custom_minimum_size = Vector2(200, 0)
	visible = false

func show_items(items: Array[Dictionary]) -> void:
	_clear()
	_items = []
	_current_index = 0
	_item_buttons.clear()
	_cooldown = 3

	for item_dict in items:
		if item_dict.quantity <= 0:
			continue
		_items.append(item_dict)
		var item: ItemData = item_dict.data as ItemData
		var btn := Button.new()
		btn.text = "%s x%d" % [item.item_name, item_dict.quantity]
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.focus_mode = Control.FOCUS_NONE
		btn.add_theme_font_size_override("font_size", 13)
		btn.add_theme_color_override("font_color", Color.WHITE)

		var style := StyleBoxFlat.new()
		style.bg_color = Color(0.08, 0.08, 0.18, 0.9)
		style.border_color = Color(0.3, 0.3, 0.5)
		style.border_width_left = 1
		style.border_width_right = 1
		style.border_width_top = 1
		style.border_width_bottom = 1
		style.content_margin_left = 8
		style.content_margin_right = 8
		style.content_margin_top = 3
		style.content_margin_bottom = 3
		btn.add_theme_stylebox_override("normal", style)

		add_child(btn)
		_item_buttons.append(btn)

	if _items.is_empty():
		var lbl := Label.new()
		lbl.text = "No items!"
		lbl.add_theme_font_size_override("font_size", 13)
		lbl.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		add_child(lbl)

	visible = true
	_active = true
	_update_highlight()
	_emit_current_description()

func _clear() -> void:
	for child in get_children():
		child.queue_free()
	_item_buttons.clear()

func hide_menu() -> void:
	visible = false
	_active = false

func _update_highlight() -> void:
	for i in range(_item_buttons.size()):
		var btn: Button = _item_buttons[i]
		var base_text: String = btn.text.trim_prefix("> ")
		if i == _current_index:
			btn.text = "> " + base_text
			btn.add_theme_color_override("font_color", Color.GOLD)
		else:
			btn.text = base_text
			btn.add_theme_color_override("font_color", Color.WHITE)

func _emit_current_description() -> void:
	if _items.is_empty():
		return
	if _current_index < _items.size():
		var item: ItemData = _items[_current_index].data as ItemData
		var desc: String = item.description if item.description != "" else item.item_name
		highlight_changed.emit(desc)

func _process(_delta: float) -> void:
	if not _active:
		return
	if _cooldown > 0:
		_cooldown -= 1
		return
	if _items.is_empty():
		if Input.is_action_just_pressed("cancel") or Input.is_action_just_pressed("confirm"):
			_active = false
			cancelled.emit()
		return
	if Input.is_action_just_pressed("move_up"):
		_current_index = (_current_index - 1)
		if _current_index < 0:
			_current_index = _item_buttons.size() - 1
		_update_highlight()
		_emit_current_description()
		Sfx.play_ui("menu_move")
	elif Input.is_action_just_pressed("move_down"):
		_current_index = (_current_index + 1) % _item_buttons.size()
		_update_highlight()
		_emit_current_description()
		Sfx.play_ui("menu_move")
	elif Input.is_action_just_pressed("confirm"):
		Sfx.play_ui("menu_select")
		_active = false
		var item_dict: Dictionary = _items[_current_index]
		item_selected.emit(item_dict.data, _current_index)
	elif Input.is_action_just_pressed("cancel"):
		Sfx.play_ui("menu_cancel")
		_active = false
		cancelled.emit()
