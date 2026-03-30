extends Node2D

enum GameState { TITLE, OVERWORLD, BATTLE_TRANSITION, BATTLE, BATTLE_VICTORY, GAME_OVER }

var state: GameState = GameState.TITLE
var party_state: PartyState = null
var current_scene: Node = null
var transition_overlay: ColorRect = null
var transition_layer: CanvasLayer = null
var _title_tween: Tween = null

func _ready() -> void:
	party_state = PartyState.new()
	party_state.setup()
	_create_transition_overlay()
	_show_title()

func _create_transition_overlay() -> void:
	transition_layer = CanvasLayer.new()
	transition_layer.layer = 100
	add_child(transition_layer)
	transition_overlay = ColorRect.new()
	transition_overlay.color = Color(0, 0, 0, 0)
	transition_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	transition_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	transition_layer.add_child(transition_overlay)

func _show_title() -> void:
	state = GameState.TITLE
	_clear_current_scene()
	var title := _create_title_screen()
	_set_current_scene(title)

func _create_title_screen() -> Node2D:
	var root := Node2D.new()
	root.name = "TitleScreen"

	# Background
	var bg := ColorRect.new()
	bg.color = Color(0.05, 0.05, 0.15)
	bg.position = Vector2.ZERO
	bg.size = Vector2(960, 540)
	root.add_child(bg)

	# Title
	var title_label := Label.new()
	title_label.text = "GATE OF AURITH"
	title_label.add_theme_font_size_override("font_size", 48)
	title_label.add_theme_color_override("font_color", Color.GOLD)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.position = Vector2(230, 140)
	title_label.size = Vector2(500, 60)
	root.add_child(title_label)

	# Subtitle
	var sub_label := Label.new()
	sub_label.text = "~ The Rift Chapters ~"
	sub_label.add_theme_font_size_override("font_size", 20)
	sub_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.9))
	sub_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub_label.position = Vector2(330, 210)
	sub_label.size = Vector2(300, 30)
	root.add_child(sub_label)

	# Press start
	var start_label := Label.new()
	start_label.text = "Press ENTER or SPACE to begin"
	start_label.add_theme_font_size_override("font_size", 16)
	start_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	start_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	start_label.position = Vector2(280, 350)
	start_label.size = Vector2(400, 30)
	root.add_child(start_label)

	# Blink the start label
	_title_tween = create_tween().set_loops()
	_title_tween.tween_property(start_label, "modulate:a", 0.3, 0.8)
	_title_tween.tween_property(start_label, "modulate:a", 1.0, 0.8)

	return root

func _input(event: InputEvent) -> void:
	if state == GameState.TITLE:
		if event.is_action_pressed("confirm"):
			_start_game()

func _start_game() -> void:
	if _title_tween:
		_title_tween.kill()
		_title_tween = null
	await _fade_out(0.5)
	_clear_current_scene()
	_load_overworld()
	await _fade_in(0.5)

func _load_overworld() -> void:
	state = GameState.OVERWORLD
	var overworld_scene := load("res://scenes/overworld.tscn") as PackedScene
	var overworld := overworld_scene.instantiate()
	overworld.init(self)
	_set_current_scene(overworld)

func start_battle(encounter_id: int, enemy_group: Array, is_boss: bool) -> void:
	if state != GameState.OVERWORLD:
		return
	state = GameState.BATTLE_TRANSITION
	await _fade_out(0.3)
	var overworld_ref := current_scene
	if overworld_ref:
		overworld_ref.visible = false
		overworld_ref.set_process(false)
		overworld_ref.set_process_input(false)

	var battle_scene := load("res://scenes/battle.tscn") as PackedScene
	var battle := battle_scene.instantiate()
	battle.init(self, party_state, enemy_group, is_boss)
	add_child(battle)
	battle.battle_finished.connect(_on_battle_finished.bind(encounter_id, overworld_ref))
	state = GameState.BATTLE
	await _fade_in(0.3)

func _on_battle_finished(result: String, encounter_id: int, overworld_ref: Node) -> void:
	await _fade_out(0.3)
	# Remove battle scene
	for child in get_children():
		if child.name == "Battle" or child.name == "BattleManager":
			child.queue_free()

	if result == "victory":
		state = GameState.OVERWORLD
		if overworld_ref and is_instance_valid(overworld_ref):
			overworld_ref.visible = true
			overworld_ref.set_process(true)
			overworld_ref.set_process_input(true)
			overworld_ref.on_battle_won(encounter_id)
		await _fade_in(0.3)
	elif result == "defeat":
		state = GameState.GAME_OVER
		_show_game_over()
		await _fade_in(0.5)

func _show_game_over() -> void:
	_clear_current_scene()
	var root := Node2D.new()
	root.name = "GameOver"

	var bg := ColorRect.new()
	bg.color = Color(0.15, 0.02, 0.02)
	bg.size = Vector2(960, 540)
	root.add_child(bg)

	var label := Label.new()
	label.text = "GAME OVER"
	label.add_theme_font_size_override("font_size", 48)
	label.add_theme_color_override("font_color", Color.RED)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.position = Vector2(280, 200)
	label.size = Vector2(400, 60)
	root.add_child(label)

	var retry_label := Label.new()
	retry_label.text = "Press ENTER to return to title"
	retry_label.add_theme_font_size_override("font_size", 16)
	retry_label.add_theme_color_override("font_color", Color(0.7, 0.4, 0.4))
	retry_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	retry_label.position = Vector2(310, 320)
	retry_label.size = Vector2(340, 30)
	root.add_child(retry_label)

	_set_current_scene(root)

func _unhandled_input(event: InputEvent) -> void:
	if state == GameState.GAME_OVER and event.is_action_pressed("confirm"):
		party_state = PartyState.new()
		party_state.setup()
		await _fade_out(0.5)
		_show_title()
		await _fade_in(0.5)

# ── Scene management ─────────────────────────────────────────────────
func _set_current_scene(node: Node) -> void:
	current_scene = node
	add_child(node)

func _clear_current_scene() -> void:
	if current_scene and is_instance_valid(current_scene):
		current_scene.queue_free()
		current_scene = null

# ── Transitions ──────────────────────────────────────────────────────
func _fade_out(duration: float) -> void:
	var tween := create_tween()
	tween.tween_property(transition_overlay, "color:a", 1.0, duration)
	await tween.finished

func _fade_in(duration: float) -> void:
	var tween := create_tween()
	tween.tween_property(transition_overlay, "color:a", 0.0, duration)
	await tween.finished
