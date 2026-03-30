extends Control

signal parry_input_received(input_type: String) # "parry", "dodge", or "miss"

var _active := false
var _ring_radius: float = 100.0
var _target_radius: float = 25.0
var _window_duration: float = 0.4
var _shrink_tween: Tween = null
var _result_received := false
var _ring_color := Color(1.0, 0.3, 0.3)
var _flash_color := Color.WHITE
var _show_flash := false
var _flash_timer := 0.0
var _prompt_label: Label = null

func _ready() -> void:
	visible = false
	custom_minimum_size = Vector2(250, 250)
	size = Vector2(250, 250)

	_prompt_label = Label.new()
	_prompt_label.text = "[Z] Parry    [X] Dodge"
	_prompt_label.add_theme_font_size_override("font_size", 14)
	_prompt_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	_prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt_label.position = Vector2(-50, 120)
	_prompt_label.size = Vector2(350, 30)
	add_child(_prompt_label)

func start_indicator(window: float, parry_bonus: float) -> void:
	_window_duration = window + parry_bonus
	_ring_radius = 100.0
	_result_received = false
	_show_flash = false
	_ring_color = Color(1.0, 0.3, 0.3)
	_active = true
	visible = true

	# Position at center of screen
	position = Vector2(480 - 125, 200)

	# Shrink the ring over the delay + window duration
	if _shrink_tween and _shrink_tween.is_running():
		_shrink_tween.kill()
	_shrink_tween = create_tween()
	_shrink_tween.tween_property(self, "_ring_radius", _target_radius, _window_duration)
	_shrink_tween.tween_callback(_on_window_expired)

	queue_redraw()

func _on_window_expired() -> void:
	if not _result_received:
		_result_received = true
		_show_result_flash(Color.RED)
		parry_input_received.emit("miss")

func _show_result_flash(color: Color) -> void:
	_flash_color = color
	_show_flash = true
	_flash_timer = 0.3
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
		# Check if timing is good (ring is close to target)
		var distance: float = absf(_ring_radius - _target_radius)
		var max_distance := 100.0 - _target_radius
		if distance < max_distance * 0.4:
			_show_result_flash(Color.GREEN)
			parry_input_received.emit("parry")
		else:
			_show_result_flash(Color.RED)
			parry_input_received.emit("miss")
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("dodge"):
		_result_received = true
		if _shrink_tween and _shrink_tween.is_running():
			_shrink_tween.kill()
		# Dodge has wider window
		var distance: float = absf(_ring_radius - _target_radius)
		var max_distance := 100.0 - _target_radius
		if distance < max_distance * 0.7:
			_show_result_flash(Color.CYAN)
			parry_input_received.emit("dodge")
		else:
			_show_result_flash(Color.RED)
			parry_input_received.emit("miss")
		get_viewport().set_input_as_handled()

func _draw() -> void:
	if not _active:
		return
	var center := Vector2(125, 100)

	if _show_flash:
		draw_circle(center, 50, Color(_flash_color, 0.4))
		return

	# Target zone (static inner circle)
	draw_arc(center, _target_radius, 0, TAU, 64, Color(1, 1, 1, 0.6), 2.0)
	draw_circle(center, _target_radius * 0.3, Color(1, 1, 1, 0.2))

	# Shrinking ring
	var ring_alpha := 0.8
	draw_arc(center, _ring_radius, 0, TAU, 64, Color(_ring_color, ring_alpha), 3.0)
