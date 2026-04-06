extends VBoxContainer

signal skill_selected(skill: Resource)
signal cancelled
signal highlight_changed(description: String)

var _skills: Array[Resource] = []
var _current_ap: int = 0
var _active := false
var _current_index := 0
var _skill_buttons: Array[Button] = []
var _cooldown: int = 0

func _ready() -> void:
	# Position next to action menu (right of it, above action text box)
	position = Vector2(148, 310)
	custom_minimum_size = Vector2(200, 0)
	visible = false

func show_skills(skills: Array[Resource], current_ap: int, stance: String = "") -> void:
	_clear()
	_skills = []
	_current_ap = current_ap
	_current_index = 0
	_skill_buttons.clear()
	_cooldown = 3

	for skill_res in skills:
		var skill: SkillData = skill_res as SkillData
		if skill == null:
			continue
		if skill.required_stance != "" and skill.required_stance != stance:
			continue
		_skills.append(skill)
		var btn := Button.new()
		var can_afford := current_ap >= skill.ap_cost
		btn.text = "%s (AP: %d)" % [skill.skill_name, skill.ap_cost]
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.focus_mode = Control.FOCUS_NONE
		btn.add_theme_font_size_override("font_size", 13)

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

		if can_afford:
			btn.add_theme_color_override("font_color", Color.WHITE)
		else:
			btn.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4))

		add_child(btn)
		_skill_buttons.append(btn)

	visible = true
	_active = true
	_update_highlight()
	_emit_current_description()

func _clear() -> void:
	for child in get_children():
		child.queue_free()
	_skill_buttons.clear()

func hide_menu() -> void:
	visible = false
	_active = false

func _update_highlight() -> void:
	for i in range(_skill_buttons.size()):
		var btn: Button = _skill_buttons[i]
		var base_text: String = btn.text.trim_prefix("> ")
		if i == _current_index:
			btn.text = "> " + base_text
			var skill: SkillData = _skills[i] as SkillData
			if _current_ap >= skill.ap_cost:
				btn.add_theme_color_override("font_color", Color.GOLD)
			else:
				btn.add_theme_color_override("font_color", Color(0.6, 0.3, 0.3))
		else:
			btn.text = base_text
			var skill: SkillData = _skills[i] as SkillData
			if _current_ap >= skill.ap_cost:
				btn.add_theme_color_override("font_color", Color.WHITE)
			else:
				btn.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4))

func _emit_current_description() -> void:
	if _current_index < _skills.size():
		var skill: SkillData = _skills[_current_index] as SkillData
		var desc: String = skill.description if skill.description != "" else skill.skill_name
		var ap_info := "  [AP: %d]" % skill.ap_cost
		highlight_changed.emit(desc + ap_info)

func _process(_delta: float) -> void:
	if not _active:
		return
	if _cooldown > 0:
		_cooldown -= 1
		return
	if Input.is_action_just_pressed("move_up"):
		_current_index = (_current_index - 1)
		if _current_index < 0:
			_current_index = _skill_buttons.size() - 1
		_update_highlight()
		_emit_current_description()
		Sfx.play_ui("menu_move")
	elif Input.is_action_just_pressed("move_down"):
		_current_index = (_current_index + 1) % _skill_buttons.size()
		_update_highlight()
		_emit_current_description()
		Sfx.play_ui("menu_move")
	elif Input.is_action_just_pressed("confirm"):
		var skill: SkillData = _skills[_current_index] as SkillData
		if _current_ap >= skill.ap_cost:
			Sfx.play_ui("menu_select")
			_active = false
			skill_selected.emit(skill)
	elif Input.is_action_just_pressed("cancel"):
		Sfx.play_ui("menu_cancel")
		_active = false
		cancelled.emit()
