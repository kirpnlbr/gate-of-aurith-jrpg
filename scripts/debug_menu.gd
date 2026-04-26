extends CanvasLayer

## Debug / dev menu. Toggle with F1. Provides cheats and a test arena
## for invoking battles with hand-picked enemy groups.

const AUDIO_STEP_DB := 3.0
const AUDIO_BUS_MASTER := "Master"
const AUDIO_BUS_MUSIC := "Music"
const AUDIO_BUS_SFX := "SFX"
const AUDIO_BUS_UI := "UI"

var main_node: Node2D = null
var _panel: PanelContainer = null
var _vbox: VBoxContainer = null
var _visible := false
var _god_mode := false

# Enemy picker state
var _arena_enemies: Array = [] # Array of EnemyData to fight
var _arena_scroll: ScrollContainer = null
var _arena_list_label: Label = null
var _bg: ColorRect = null
var _audio_status_label: Label = null

# ── Setup ────────────────────────────────────────────────────────────

func init(main: Node2D) -> void:
	main_node = main
	layer = 200
	_build_ui()
	_set_menu_visible(false)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F1:
			_toggle()
			get_viewport().set_input_as_handled()

func _toggle() -> void:
	_visible = not _visible
	_set_menu_visible(_visible)
	get_tree().paused = _visible

func _set_menu_visible(show: bool) -> void:
	if _bg:
		_bg.visible = show
	if _panel:
		_panel.visible = show

# ── UI Construction ──────────────────────────────────────────────────

func _build_ui() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	_bg = ColorRect.new()
	_bg.color = Color(0, 0, 0, 0.5)
	_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	_bg.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_bg)

	_panel = PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.08, 0.14, 0.95)
	style.border_color = Color(0.6, 0.4, 0.1)
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_width_left = 2
	style.border_width_right = 2
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	_panel.add_theme_stylebox_override("panel", style)
	_panel.set_anchors_preset(Control.PRESET_CENTER)
	_panel.offset_left = -260
	_panel.offset_right = 260
	_panel.offset_top = -240
	_panel.offset_bottom = 240
	add_child(_panel)

	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_panel.add_child(scroll)

	_vbox = VBoxContainer.new()
	_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_vbox)

	# Title
	_add_label("DEBUG MENU  [F1 to close]", 20, Color.GOLD)
	_add_separator()

	# ── Cheats Section ───────────────────────────────────────────────
	_add_label("CHEATS", 16, Color(0.8, 0.6, 0.2))
	_add_button("Full Heal (HP + AP)", _on_full_heal)
	_add_button("Level Up All (+1)", _on_level_up)
	_add_button("Level Up All (+5)", _on_level_up_5)
	_add_button("Max Items (99 of each)", _on_max_items)
	_add_button("Toggle God Mode", _on_toggle_god_mode)
	_add_separator()

	# ── Audio Section ────────────────────────────────────────────────
	_add_label("AUDIO", 16, Color(0.8, 0.6, 0.2))
	_audio_status_label = _add_label("", 12, Color(0.75, 0.85, 0.75))
	_refresh_audio_status()
	_add_label("Shortcuts: Ctrl+- quieter, Ctrl+= louder, Ctrl+0 reset", 11, Color(0.6, 0.6, 0.75))

	var master_controls := HBoxContainer.new()
	_vbox.add_child(master_controls)
	_add_inline_button(master_controls, "Master -", _on_master_volume_down)
	_add_inline_button(master_controls, "Master +", _on_master_volume_up)
	_add_inline_button(master_controls, "Mute All", _on_toggle_master_mute)

	var music_controls := HBoxContainer.new()
	_vbox.add_child(music_controls)
	_add_inline_button(music_controls, "Music -", _on_music_volume_down)
	_add_inline_button(music_controls, "Music +", _on_music_volume_up)

	var sfx_controls := HBoxContainer.new()
	_vbox.add_child(sfx_controls)
	_add_inline_button(sfx_controls, "SFX -", _on_sfx_volume_down)
	_add_inline_button(sfx_controls, "SFX +", _on_sfx_volume_up)
	_add_inline_button(sfx_controls, "UI -", _on_ui_volume_down)
	_add_inline_button(sfx_controls, "UI +", _on_ui_volume_up)

	_add_button("Reset Audio Defaults", _on_reset_audio)
	_add_separator()

	# ── Overworld Section ────────────────────────────────────────────
	_add_label("OVERWORLD", 16, Color(0.8, 0.6, 0.2))
	_add_button("Skip All Encounters", _on_skip_all_encounters)
	_add_button("Reset All Encounters", _on_reset_encounters)
	_add_button("Teleport to Boss Room", _on_teleport_boss)
	_add_separator()

	# ── Test Arena Section ───────────────────────────────────────────
	_add_label("TEST ARENA", 16, Color(0.8, 0.6, 0.2))
	_add_label("Pick enemies then hit FIGHT:", 12, Color(0.6, 0.6, 0.7))

	var enemy_grid := GridContainer.new()
	enemy_grid.columns = 2
	_vbox.add_child(enemy_grid)

	for entry in _get_enemy_catalog():
		var btn := Button.new()
		btn.text = "+ " + entry.name
		btn.add_theme_font_size_override("font_size", 12)
		btn.pressed.connect(_on_add_arena_enemy.bind(entry.name))
		enemy_grid.add_child(btn)

	_arena_list_label = Label.new()
	_arena_list_label.text = "Enemies: (none)"
	_arena_list_label.add_theme_font_size_override("font_size", 12)
	_arena_list_label.add_theme_color_override("font_color", Color(0.7, 0.8, 0.7))
	_arena_list_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	_vbox.add_child(_arena_list_label)

	var arena_actions := HBoxContainer.new()
	_vbox.add_child(arena_actions)

	var fight_btn := Button.new()
	fight_btn.text = "FIGHT!"
	fight_btn.add_theme_font_size_override("font_size", 14)
	fight_btn.add_theme_color_override("font_color", Color.RED)
	fight_btn.pressed.connect(_on_arena_fight)
	arena_actions.add_child(fight_btn)

	var fight_boss_btn := Button.new()
	fight_boss_btn.text = "FIGHT (as Boss)"
	fight_boss_btn.add_theme_font_size_override("font_size", 14)
	fight_boss_btn.add_theme_color_override("font_color", Color(0.8, 0.2, 0.2))
	fight_boss_btn.pressed.connect(_on_arena_fight_boss)
	arena_actions.add_child(fight_boss_btn)

	var clear_btn := Button.new()
	clear_btn.text = "Clear"
	clear_btn.add_theme_font_size_override("font_size", 12)
	clear_btn.pressed.connect(_on_arena_clear)
	arena_actions.add_child(clear_btn)

	_add_separator()

	# ── Quick Fights ─────────────────────────────────────────────────
	_add_label("QUICK FIGHTS", 16, Color(0.8, 0.6, 0.2))
	_add_button("2x Goblin", _on_fight_goblins)
	_add_button("2x Wraith", _on_fight_wraiths)
	_add_button("Golem + Goblin", _on_fight_golem)
	_add_button("Dark Knight (Boss)", _on_fight_boss)

# ── UI Helpers ───────────────────────────────────────────────────────

func _add_label(text: String, size: int, color: Color) -> Label:
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", size)
	lbl.add_theme_color_override("font_color", color)
	_vbox.add_child(lbl)
	return lbl

func _add_button(text: String, callback: Callable) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.add_theme_font_size_override("font_size", 13)
	btn.pressed.connect(callback)
	_vbox.add_child(btn)
	return btn

func _add_inline_button(parent: BoxContainer, text: String, callback: Callable) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(96, 0)
	btn.add_theme_font_size_override("font_size", 12)
	btn.pressed.connect(callback)
	parent.add_child(btn)
	return btn

func _add_separator() -> void:
	var sep := HSeparator.new()
	sep.add_theme_constant_override("separation", 8)
	_vbox.add_child(sep)

# ── Cheat Callbacks ──────────────────────────────────────────────────

func _on_full_heal() -> void:
	if main_node and main_node.party_state:
		main_node.party_state.heal_party_full()
		_flash_message("Party fully healed!")

func _on_level_up() -> void:
	if main_node and main_node.party_state:
		var msgs: Array[String] = main_node.party_state.add_xp(50)
		_flash_message("\n".join(msgs) if msgs.size() > 0 else "XP added!")

func _on_level_up_5() -> void:
	if main_node and main_node.party_state:
		var all_msgs: Array[String] = []
		for i in range(5):
			var msgs: Array[String] = main_node.party_state.add_xp(50)
			all_msgs.append_array(msgs)
		_flash_message("\n".join(all_msgs) if all_msgs.size() > 0 else "XP added!")

func _on_max_items() -> void:
	if main_node and main_node.party_state:
		for item in main_node.party_state.items:
			item.quantity = 99
		_flash_message("All items set to 99!")

func _on_toggle_god_mode() -> void:
	_god_mode = not _god_mode
	_flash_message("God Mode: " + ("ON" if _god_mode else "OFF"))

func _refresh_audio_status() -> void:
	if _audio_status_label:
		_audio_status_label.text = Sfx.get_volume_summary()

func _adjust_audio(bus_name: String, delta_db: float) -> void:
	var volume_db := Sfx.adjust_bus_volume_db(bus_name, delta_db)
	_refresh_audio_status()
	_flash_message("%s volume: %+.1f dB" % [bus_name, volume_db])

func _on_master_volume_down() -> void:
	_adjust_audio(AUDIO_BUS_MASTER, -AUDIO_STEP_DB)

func _on_master_volume_up() -> void:
	_adjust_audio(AUDIO_BUS_MASTER, AUDIO_STEP_DB)

func _on_toggle_master_mute() -> void:
	var muted := Sfx.toggle_bus_mute(AUDIO_BUS_MASTER)
	_refresh_audio_status()
	_flash_message("Master mute: " + ("ON" if muted else "OFF"))

func _on_music_volume_down() -> void:
	_adjust_audio(AUDIO_BUS_MUSIC, -AUDIO_STEP_DB)

func _on_music_volume_up() -> void:
	_adjust_audio(AUDIO_BUS_MUSIC, AUDIO_STEP_DB)

func _on_sfx_volume_down() -> void:
	_adjust_audio(AUDIO_BUS_SFX, -AUDIO_STEP_DB)

func _on_sfx_volume_up() -> void:
	_adjust_audio(AUDIO_BUS_SFX, AUDIO_STEP_DB)

func _on_ui_volume_down() -> void:
	_adjust_audio(AUDIO_BUS_UI, -AUDIO_STEP_DB)

func _on_ui_volume_up() -> void:
	_adjust_audio(AUDIO_BUS_UI, AUDIO_STEP_DB)

func _on_reset_audio() -> void:
	Sfx.reset_bus_volumes()
	_refresh_audio_status()
	_flash_message("Audio reset to defaults")

# ── Overworld Callbacks ──────────────────────────────────────────────

func _get_overworld() -> Node:
	if main_node and main_node.state == main_node.GameState.OVERWORLD and main_node.current_scene:
		return main_node.current_scene
	return null

func _on_skip_all_encounters() -> void:
	var ow := _get_overworld()
	if ow:
		for enc in ow.encounter_zones:
			enc.defeated = true
		ow._update_encounter_visuals()
		_flash_message("All encounters marked defeated!")
	else:
		_flash_message("Must be in overworld!")

func _on_reset_encounters() -> void:
	var ow := _get_overworld()
	if ow:
		for enc in ow.encounter_zones:
			enc.defeated = false
		ow._update_encounter_visuals()
		# Re-render encounter colors
		for enc in ow.encounter_zones:
			for gp in enc.grid_positions:
				var color: Color = ow.COLOR_BOSS_FLOOR if enc.is_boss else ow.COLOR_ENCOUNTER
				ow._fill_tile(ow._map_image, gp.x, gp.y, color)
		ow._map_texture.update(ow._map_image)
		_flash_message("All encounters reset!")
	else:
		_flash_message("Must be in overworld!")

func _on_teleport_boss() -> void:
	var ow := _get_overworld()
	if ow and ow.player_node:
		var target := Vector2i(12, 32)
		ow.player_node.grid_pos = target
		ow.player_node.position = ow.player_node.grid_to_world(target)
		_flash_message("Teleported to Boss Arena!")
	else:
		_flash_message("Must be in overworld!")

# ── Arena / Custom Fight ─────────────────────────────────────────────

func _get_enemy_catalog() -> Array[Dictionary]:
	return [
		{"name": "Goblin"},
		{"name": "Wraith"},
		{"name": "Stone Golem"},
		{"name": "Dark Knight"},
	]

func _create_enemy_by_name(enemy_name: String) -> EnemyData:
	# We reuse the same factory methods from overworld, but since they're
	# instance methods on the overworld node, we duplicate the data here.
	var ow := _get_overworld()
	if ow:
		match enemy_name:
			"Goblin":
				return ow._create_goblin_data()
			"Wraith":
				return ow._create_wraith_data()
			"Stone Golem":
				return ow._create_golem_data()
			"Dark Knight":
				return ow._create_boss_data()
	# Fallback: create inline if overworld isn't available
	return _create_enemy_fallback(enemy_name)

func _create_enemy_fallback(enemy_name: String) -> EnemyData:
	# Minimal fallback enemy definitions so arena works from any state.
	# These mirror the overworld factories.
	var ed := EnemyData.new()
	match enemy_name:
		"Goblin":
			ed.enemy_name = "Goblin"
			ed.max_hp = 40; ed.attack = 10; ed.defense = 6
			ed.magic_defense = 4; ed.speed = 8; ed.xp_reward = 15
			ed.element_weakness = "fire"; ed.element_resistance = "earth"
			ed.battle_color = Color(0.4, 0.5, 0.3)
			ed.sprite_path = "res://assets/sprites/battle/goblin.png"
			ed.sprite_idle = "res://assets/sprites/battle/frames/goblin_idle"
			ed.attack_sprite_map = {
				"Goblin Slash": "res://assets/sprites/battle/frames/goblin_slash",
				"Double Strike": "res://assets/sprites/battle/frames/goblin_double_strike",
			}
			var slash := AttackPattern.new()
			slash.pattern_name = "Goblin Slash"
			slash.hits = [{"delay": 0.8, "window": 0.48, "damage_pct": 1.0}]
			slash.action_text = "{attacker} slashes at {target}!"
			var double_s := AttackPattern.new()
			double_s.pattern_name = "Double Strike"
			double_s.hits = [
				{"delay": 0.6, "window": 0.38, "damage_pct": 0.5},
				{"delay": 0.4, "window": 0.38, "damage_pct": 0.5},
			]
			double_s.action_text = "{attacker} strikes twice at {target}!"
			ed.attack_patterns = [slash, double_s]
		"Wraith":
			ed.enemy_name = "Wraith"
			ed.max_hp = 55; ed.attack = 14; ed.defense = 4
			ed.magic_defense = 12; ed.speed = 13; ed.xp_reward = 25
			ed.element_weakness = "lightning"
			ed.battle_color = Color(0.5, 0.2, 0.6)
			ed.sprite_scale = 1.1
			ed.sprite_path = "res://assets/sprites/battle/wraith.png"
			ed.sprite_idle = "res://assets/sprites/battle/frames/wraith_idle"
			ed.attack_sprite_map = {
				"Spectral Claw": "res://assets/sprites/battle/frames/wraith_spectral_claw",
				"Delayed Haunt": "res://assets/sprites/battle/frames/wraith_delayed_haunt",
			}
			var claw := AttackPattern.new()
			claw.pattern_name = "Spectral Claw"
			claw.hits = [
				{"delay": 0.5, "window": 0.33, "damage_pct": 0.35},
				{"delay": 0.3, "window": 0.30, "damage_pct": 0.3},
				{"delay": 0.3, "window": 0.30, "damage_pct": 0.35},
			]
			claw.action_text = "{attacker} unleashes Spectral Claws at {target}!"
			var haunt := AttackPattern.new()
			haunt.pattern_name = "Delayed Haunt"
			haunt.hits = [
				{"delay": 0.4, "window": 0.0, "damage_pct": 0.0},
				{"delay": 1.2, "window": 0.38, "damage_pct": 1.2},
			]
			haunt.action_text = "{attacker} haunts {target} with a spectral strike!"
			ed.attack_patterns = [claw, haunt]
		"Stone Golem":
			ed.enemy_name = "Stone Golem"
			ed.max_hp = 80; ed.attack = 18; ed.defense = 16
			ed.magic_defense = 6; ed.speed = 5; ed.xp_reward = 30
			ed.element_weakness = "water"; ed.element_resistance = "fire"
			ed.battle_color = Color(0.5, 0.4, 0.3)
			ed.sprite_scale = 1.3
			ed.sprite_path = "res://assets/sprites/battle/golem.png"
			ed.sprite_idle = "res://assets/sprites/battle/frames/golem_idle"
			ed.attack_sprite_map = {
				"Ground Slam": "res://assets/sprites/battle/frames/golem_ground_slam",
				"Boulder Toss": "res://assets/sprites/battle/frames/golem_boulder_toss",
				"Earthquake": "res://assets/sprites/battle/frames/golem_earthquake",
			}
			var slam := AttackPattern.new()
			slam.pattern_name = "Ground Slam"
			slam.hits = [{"delay": 1.0, "window": 0.43, "damage_pct": 1.3}]
			slam.action_text = "{attacker} slams the ground beneath {target}!"
			var toss := AttackPattern.new()
			toss.pattern_name = "Boulder Toss"
			toss.hits = [{"delay": 0.7, "window": 0.38, "damage_pct": 1.0}]
			toss.action_text = "{attacker} hurls a boulder at {target}!"
			var quake := AttackPattern.new()
			quake.pattern_name = "Earthquake"
			quake.is_team_attack = true
			quake.hits = [
				{"delay": 1.2, "window": 0.38, "damage_pct": 0.7},
				{"delay": 0.5, "window": 0.36, "damage_pct": 0.6},
			]
			quake.action_text = "{attacker} shakes the earth beneath the party!"
			ed.attack_patterns = [slam, toss, quake]
		"Dark Knight":
			ed.enemy_name = "Dark Knight"
			ed.max_hp = 320; ed.attack = 28; ed.defense = 16
			ed.magic_defense = 12; ed.speed = 13; ed.xp_reward = 100
			ed.element_weakness = "lightning"; ed.element_resistance = "earth"
			ed.battle_color = Color(0.15, 0.15, 0.2)
			ed.boss = true; ed.sprite_scale = 1.5
			ed.sprite_path = "res://assets/sprites/battle/boss_dark_knight.png"
			ed.sprite_idle = "res://assets/sprites/battle/frames/dark_knight_idle"
			ed.attack_sprite_map = {
				"Blade Combo": "res://assets/sprites/battle/frames/dark_knight_blade_combo",
				"Delayed Thrust": "res://assets/sprites/battle/frames/dark_knight_delayed_thrust",
				"Dark Cleave": "res://assets/sprites/battle/frames/dark_knight_dark_cleave",
				"Shadow Rend": "res://assets/sprites/battle/frames/dark_knight_shadow_rend",
				"Abyssal Onslaught": "res://assets/sprites/battle/frames/dark_knight_onslaught",
			}
			var combo := AttackPattern.new()
			combo.pattern_name = "Blade Combo"
			combo.hits = [
				{"delay": 0.55, "window": 0.33, "damage_pct": 0.2},
				{"delay": 0.22, "window": 0.28, "damage_pct": 0.2},
				{"delay": 0.3, "window": 0.0, "damage_pct": 0.0},
				{"delay": 0.2, "window": 0.26, "damage_pct": 0.25},
				{"delay": 0.45, "window": 0.30, "damage_pct": 0.35},
			]
			combo.action_text = "{attacker} unleashes a relentless Blade Combo on {target}!"
			var thrust := AttackPattern.new()
			thrust.pattern_name = "Delayed Thrust"
			thrust.hits = [
				{"delay": 0.3, "window": 0.0, "damage_pct": 0.0},
				{"delay": 0.4, "window": 0.0, "damage_pct": 0.0},
				{"delay": 1.2, "window": 0.30, "damage_pct": 1.8},
			]
			thrust.action_text = "{attacker} feints twice, then thrusts at {target}!"
			var cleave := AttackPattern.new()
			cleave.pattern_name = "Dark Cleave"
			cleave.is_team_attack = true
			cleave.hits = [
				{"delay": 0.6, "window": 0.32, "damage_pct": 0.5},
				{"delay": 0.3, "window": 0.30, "damage_pct": 0.5},
				{"delay": 0.4, "window": 0.30, "damage_pct": 0.6},
			]
			cleave.action_text = "{attacker} unleashes Dark Cleave across the party!"
			var rend := AttackPattern.new()
			rend.pattern_name = "Shadow Rend"
			rend.hits = [
				{"delay": 0.4, "window": 0.28, "damage_pct": 0.4},
				{"delay": 0.2, "window": 0.26, "damage_pct": 0.4},
				{"delay": 0.3, "window": 0.26, "damage_pct": 0.5},
			]
			rend.action_text = "{attacker} tears through {target} with Shadow Rend!"
			var onslaught := AttackPattern.new()
			onslaught.pattern_name = "Abyssal Onslaught"
			onslaught.is_team_attack = true
			onslaught.hits = [
				{"delay": 0.4, "window": 0.0, "damage_pct": 0.0},
				{"delay": 0.35, "window": 0.28, "damage_pct": 0.35},
				{"delay": 0.25, "window": 0.26, "damage_pct": 0.35},
				{"delay": 0.25, "window": 0.26, "damage_pct": 0.35},
				{"delay": 0.5, "window": 0.30, "damage_pct": 0.5},
			]
			onslaught.action_text = "{attacker} unleashes Abyssal Onslaught on the party!"
			ed.attack_patterns = [combo, thrust, cleave, rend, onslaught]
	return ed

func _on_add_arena_enemy(enemy_name: String) -> void:
	var ed := _create_enemy_by_name(enemy_name)
	if ed:
		_arena_enemies.append(ed)
		_update_arena_label()

func _on_arena_clear() -> void:
	_arena_enemies.clear()
	_update_arena_label()

func _update_arena_label() -> void:
	if _arena_enemies.is_empty():
		_arena_list_label.text = "Enemies: (none)"
	else:
		var names: Array[String] = []
		for ed in _arena_enemies:
			names.append(ed.enemy_name)
		_arena_list_label.text = "Enemies: " + ", ".join(names)

func _on_arena_fight() -> void:
	_start_arena_battle(false)

func _on_arena_fight_boss() -> void:
	_start_arena_battle(true)

func _start_arena_battle(as_boss: bool) -> void:
	if _arena_enemies.is_empty():
		_flash_message("Add at least one enemy first!")
		return
	if not main_node:
		_flash_message("No main node!")
		return
	# Close menu and unpause
	_visible = false
	_set_menu_visible(false)
	get_tree().paused = false
	# Force state to OVERWORLD so start_battle accepts the call
	if main_node.state != main_node.GameState.OVERWORLD:
		# If we're on the title screen or game over, we need an overworld first
		if main_node.state == main_node.GameState.TITLE or main_node.state == main_node.GameState.GAME_OVER:
			_flash_message("Start the game first!")
			return
		# If in battle already, can't start another
		if main_node.state == main_node.GameState.BATTLE or main_node.state == main_node.GameState.BATTLE_TRANSITION:
			_flash_message("Already in battle!")
			return
	var group: Array = _arena_enemies.duplicate()
	_arena_enemies.clear()
	_update_arena_label()
	main_node.start_battle(-1, group, as_boss)

# ── Quick Fight Callbacks ────────────────────────────────────────────

func _start_quick_fight(enemies: Array, is_boss: bool) -> void:
	_visible = false
	_set_menu_visible(false)
	get_tree().paused = false
	if not main_node or main_node.state != main_node.GameState.OVERWORLD:
		_flash_message("Must be in overworld!")
		return
	main_node.start_battle(-1, enemies, is_boss)

func _on_fight_goblins() -> void:
	var g1 := _create_enemy_by_name("Goblin")
	var g2 := _create_enemy_by_name("Goblin")
	_start_quick_fight([g1, g2], false)

func _on_fight_wraiths() -> void:
	var w1 := _create_enemy_by_name("Wraith")
	var w2 := _create_enemy_by_name("Wraith")
	_start_quick_fight([w1, w2], false)

func _on_fight_golem() -> void:
	var g := _create_enemy_by_name("Stone Golem")
	var gb := _create_enemy_by_name("Goblin")
	_start_quick_fight([g, gb], false)

func _on_fight_boss() -> void:
	var dk := _create_enemy_by_name("Dark Knight")
	_start_quick_fight([dk], true)

# ── God Mode Hook ────────────────────────────────────────────────────

func _process(_delta: float) -> void:
	if not _god_mode or not main_node or not main_node.party_state:
		return
	for ch in main_node.party_state.characters:
		ch.current_hp = ch.data.max_hp
		ch.current_ap = ch.data.max_ap

# ── Flash Message ────────────────────────────────────────────────────

func _flash_message(text: String) -> void:
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 16)
	lbl.add_theme_color_override("font_color", Color.GOLD)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.set_anchors_preset(Control.PRESET_CENTER_TOP)
	lbl.offset_top = 10
	lbl.offset_left = -200
	lbl.offset_right = 200
	add_child(lbl)

	var tw := create_tween()
	tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw.tween_interval(1.5)
	tw.tween_property(lbl, "modulate:a", 0.0, 0.5)
	tw.tween_callback(lbl.queue_free)
