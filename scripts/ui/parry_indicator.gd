extends Control

signal parry_input_received(input_type: String) # "parry", "dodge", or "miss"

var _active := false
var _ring_radius: float = 60.0
var _target_radius: float = 15.0
var _window_duration: float = 0.4
var _shrink_tween: Tween = null
var _result_received := false
var _flash_color := Color.WHITE
var _show_flash := false
var _flash_timer := 0.0
var _prompt_label: Label = null

const RING_START := 60.0
const RING_TARGET := 15.0

func _ready() -> void:
	visible = false
	custom_minimum_size = Vector2(140, 140)
	size = Vector2(140, 140)

	_prompt_label = Label.new()
	_prompt_label.text = "[Z] Parry  [X] Dodge"
	_prompt_label.add_theme_font_size_override("font_size", 11)
	_prompt_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8, 0.7))
	_prompt_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	_prompt_label.add_theme_constant_override("outline_size", 2)
	_prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt_label.position = Vector2(-10, 78)
	_prompt_label.size = Vector2(160, 20)
	add_child(_prompt_label)

func start_indicator(window: float, parry_bonus: float, target_pos: Vector2 = Vector2(100, 300)) -> void:
	_window_duration = window + parry_bonus
	_ring_radius = RING_START
	_result_received = false
	_show_flash = false
	_active = true
	visible = true

	# Position near the targeted party member, clamped to viewport
	var vp := get_viewport().get_visible_rect().size
	var desired := Vector2(target_pos.x - 70, target_pos.y - 50)
	desired.x = clampf(desired.x, 0.0, vp.x - size.x)
	desired.y = clampf(desired.y, 0.0, vp.y - size.y)
	position = desired

	if _shrink_tween and _shrink_tween.is_running():
		_shrink_tween.kill()
	_shrink_tween = create_tween()
	_shrink_tween.tween_property(self, "_ring_radius", RING_TARGET, _window_duration)
	# Don't auto-miss here — parry_system handles window expiry via its own timer
	queue_redraw()

func _show_result_flash(color: Color) -> void:
	_flash_color = color
	_show_flash = true
	_flash_timer = 0.25
	queue_redraw()

func stop_indicator() -> void:
	_active = false
	visible = false
	if _shrink_tween and _shrink_tween.is_running():
		_shrink_tween.kill()

func _process(delta: float) -> void:
	if not _active:
		return
	if _show_flash:
		_flash_timer -= delta
		if _flash_timer <= 0:
			_show_flash = false
			visible = false
			_active = false
		queue_redraw()
		return
	queue_redraw()

func _input(event: InputEvent) -> void:
	if not _active or _result_received:
		return
	if event.is_action_pressed("parry"):
		_result_received = true
		if _shrink_tween and _shrink_tween.is_running():
			_shrink_tween.kill()
		_show_result_flash(Color.GREEN)
		parry_input_received.emit("parry")
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("dodge"):
		_result_received = true
		if _shrink_tween and _shrink_tween.is_running():
			_shrink_tween.kill()
		_show_result_flash(Color.CYAN)
		parry_input_received.emit("dodge")
		get_viewport().set_input_as_handled()

func _draw() -> void:
	if not _active:
		return
	var center := Vector2(70, 40)

	if _show_flash:
		draw_circle(center, 30, Color(_flash_color, 0.35))
		return

	# Target zone
	draw_arc(center, RING_TARGET, 0, TAU, 48, Color(1, 1, 1, 0.4), 1.5)
	draw_circle(center, RING_TARGET * 0.3, Color(1, 1, 1, 0.15))

	# Shrinking ring with color gradient
	var max_distance := RING_START - RING_TARGET
	var distance: float = absf(_ring_radius - RING_TARGET)
	var ratio: float = clampf(distance / max_distance, 0.0, 1.0)
	var ring_color: Color
	if ratio < 0.4:
		ring_color = Color(0.2, 1.0, 0.3)
	elif ratio < 0.7:
		ring_color = Color(1.0, 0.9, 0.2)
	else:
		ring_color = Color(1.0, 0.25, 0.2)
	draw_arc(center, _ring_radius, 0, TAU, 48, Color(ring_color, 0.7), 2.5)
