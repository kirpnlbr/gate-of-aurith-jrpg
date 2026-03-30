extends Node2D

signal target_selected(index: int)
signal cancelled

var _targets: Array[Dictionary] = []
var _current_index := 0
var _active := false
var _arrow: Label = null
var _cooldown: int = 0

func _ready() -> void:
	_arrow = Label.new()
	_arrow.text = ">"
	_arrow.add_theme_font_size_override("font_size", 28)
	_arrow.add_theme_color_override("font_color", Color.YELLOW)
	_arrow.visible = false
	add_child(_arrow)

func show_targets(targets: Array[Dictionary]) -> void:
	_targets = targets
	_current_index = 0
	_active = true
	_cooldown = 3
	_arrow.visible = true
	_update_arrow()

func hide_selector() -> void:
	_active = false
	_arrow.visible = false

func _update_arrow() -> void:
	if _targets.is_empty():
		return
	var target_node = _targets[_current_index].get("node")
	if target_node:
		_arrow.position = target_node.position + Vector2(-30, -15)

func _process(_delta: float) -> void:
	if not _active:
		return
	if _cooldown > 0:
		_cooldown -= 1
		return
	if Input.is_action_just_pressed("move_left") or Input.is_action_just_pressed("move_up"):
		_current_index = (_current_index - 1)
		if _current_index < 0:
			_current_index = _targets.size() - 1
		_update_arrow()
	elif Input.is_action_just_pressed("move_right") or Input.is_action_just_pressed("move_down"):
		_current_index = (_current_index + 1) % _targets.size()
		_update_arrow()
	elif Input.is_action_just_pressed("confirm"):
		_active = false
		_arrow.visible = false
		target_selected.emit(_current_index)
	elif Input.is_action_just_pressed("cancel"):
		_active = false
		_arrow.visible = false
		cancelled.emit()
