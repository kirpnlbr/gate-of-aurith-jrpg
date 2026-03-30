extends Node2D

const TILE_SIZE := 48
const MAP_COLS := 25
const MAP_ROWS := 35

var main_node: Node2D = null
var map_grid: Array = [] # 2D [row][col] of int: 0=floor, 1=wall
var encounter_zones: Array[EncounterZone] = []
var player_node: Node2D = null
var player_start := Vector2i(12, 2)

# Colors
const COLOR_FLOOR := Color(0.18, 0.18, 0.25)
const COLOR_WALL := Color(0.08, 0.08, 0.12)
const COLOR_DOOR := Color(0.25, 0.2, 0.15)
const COLOR_ENCOUNTER := Color(0.3, 0.12, 0.12)
const COLOR_BOSS_FLOOR := Color(0.2, 0.1, 0.1)

var _needs_intro := false

func init(main: Node2D) -> void:
	main_node = main
	_build_dungeon()
	_setup_encounters()
	_render_map()
	_spawn_player()
	_needs_intro = true

func _ready() -> void:
	if _needs_intro:
		_needs_intro = false
		_show_intro()

func _build_dungeon() -> void:
	# Initialize all walls
	map_grid.clear()
	for r in range(MAP_ROWS):
		var row: Array = []
		for c in range(MAP_COLS):
			row.append(1) # wall
		map_grid.append(row)

	# Room 1: Start Room (cols 8-16, rows 1-6)
	_carve_room(8, 1, 16, 6)

	# Corridor 1 (cols 11-13, rows 7-9)
	_carve_room(11, 7, 13, 9)

	# Room 2: Hall of Echoes (cols 6-18, rows 10-15)
	_carve_room(6, 10, 18, 15)

	# Corridor 2 (cols 11-13, rows 16-18)
	_carve_room(11, 16, 13, 18)

	# Room 3: Wraith Corridor (cols 4-20, rows 19-22)
	_carve_room(4, 19, 20, 22)

	# Corridor 3 (cols 11-13, rows 23-25)
	_carve_room(11, 23, 13, 25)

	# Room 4: Golem Chamber (cols 7-17, rows 26-29)
	_carve_room(7, 26, 17, 29)

	# Corridor 4 (cols 11-13, rows 30-31)
	_carve_room(11, 30, 13, 31)

	# Room 5: Boss Arena (cols 5-19, rows 32-34)
	_carve_room(5, 32, 19, 34)

func _carve_room(left: int, top: int, right: int, bottom: int) -> void:
	for r in range(top, bottom + 1):
		for c in range(left, right + 1):
			if r >= 0 and r < MAP_ROWS and c >= 0 and c < MAP_COLS:
				map_grid[r][c] = 0

func _setup_encounters() -> void:
	# Encounter 1: 2x Goblin in Room 2
	var enc1 := EncounterZone.new()
	enc1.id = 1
	enc1.grid_positions = [Vector2i(12, 12), Vector2i(11, 12), Vector2i(13, 12),
						   Vector2i(12, 13), Vector2i(11, 13), Vector2i(13, 13)]
	enc1.enemy_group = _create_goblin_group()
	encounter_zones.append(enc1)

	# Encounter 2: 2x Wraith in Room 3
	var enc2 := EncounterZone.new()
	enc2.id = 2
	enc2.grid_positions = [Vector2i(12, 20), Vector2i(11, 20), Vector2i(13, 20),
						   Vector2i(12, 21), Vector2i(11, 21), Vector2i(13, 21)]
	enc2.enemy_group = _create_wraith_group()
	encounter_zones.append(enc2)

	# Encounter 3: Golem + Goblin in Room 4
	var enc3 := EncounterZone.new()
	enc3.id = 3
	enc3.grid_positions = [Vector2i(12, 27), Vector2i(11, 27), Vector2i(13, 27),
						   Vector2i(12, 28), Vector2i(11, 28), Vector2i(13, 28)]
	enc3.enemy_group = _create_golem_group()
	encounter_zones.append(enc3)

	# Boss: Dark Knight in Room 5
	var boss_enc := EncounterZone.new()
	boss_enc.id = 4
	boss_enc.is_boss = true
	boss_enc.grid_positions = [Vector2i(12, 33), Vector2i(11, 33), Vector2i(13, 33),
							   Vector2i(12, 34), Vector2i(11, 34), Vector2i(13, 34)]
	boss_enc.enemy_group = _create_boss_group()
	encounter_zones.append(boss_enc)

# ── Enemy Factories ──────────────────────────────────────────────────

func _create_goblin_data() -> EnemyData:
	var goblin := EnemyData.new()
	goblin.enemy_name = "Goblin"
	goblin.max_hp = 40
	goblin.attack = 10
	goblin.defense = 6
	goblin.magic_defense = 4
	goblin.speed = 8
	goblin.xp_reward = 15
	goblin.element_weakness = "fire"
	goblin.element_resistance = "earth"
	goblin.battle_color = Color(0.4, 0.5, 0.3)
	goblin.sprite_path = "res://assets/sprites/battle/goblin.png"

	var slash := AttackPattern.new()
	slash.pattern_name = "Goblin Slash"
	slash.hits = [{"delay": 0.8, "window": 0.4, "damage_pct": 1.0}]
	slash.action_text = "{attacker} slashes at {target}!"

	var double_strike := AttackPattern.new()
	double_strike.pattern_name = "Double Strike"
	double_strike.hits = [
		{"delay": 0.6, "window": 0.3, "damage_pct": 0.5},
		{"delay": 0.4, "window": 0.3, "damage_pct": 0.5},
	]
	double_strike.action_text = "{attacker} strikes twice at {target}!"

	goblin.attack_patterns = [slash, double_strike]
	return goblin

func _create_wraith_data() -> EnemyData:
	var wraith := EnemyData.new()
	wraith.enemy_name = "Wraith"
	wraith.max_hp = 55
	wraith.attack = 14
	wraith.defense = 4
	wraith.magic_defense = 12
	wraith.speed = 13
	wraith.xp_reward = 25
	wraith.element_weakness = "lightning"
	wraith.element_resistance = ""
	wraith.battle_color = Color(0.5, 0.2, 0.6)
	wraith.sprite_scale = 1.1
	wraith.sprite_path = "res://assets/sprites/battle/wraith.png"

	var triple := AttackPattern.new()
	triple.pattern_name = "Spectral Claw"
	triple.hits = [
		{"delay": 0.5, "window": 0.25, "damage_pct": 0.35},
		{"delay": 0.3, "window": 0.22, "damage_pct": 0.3},
		{"delay": 0.3, "window": 0.22, "damage_pct": 0.35},
	]
	triple.action_text = "{attacker} unleashes Spectral Claws at {target}!"

	var delayed := AttackPattern.new()
	delayed.pattern_name = "Delayed Haunt"
	delayed.hits = [
		{"delay": 0.4, "window": 0.0, "damage_pct": 0.0}, # feint
		{"delay": 1.2, "window": 0.3, "damage_pct": 1.2},
	]
	delayed.action_text = "{attacker} haunts {target} with a spectral strike!"

	wraith.attack_patterns = [triple, delayed]
	return wraith

func _create_golem_data() -> EnemyData:
	var golem := EnemyData.new()
	golem.enemy_name = "Stone Golem"
	golem.max_hp = 80
	golem.attack = 18
	golem.defense = 16
	golem.magic_defense = 6
	golem.speed = 5
	golem.xp_reward = 30
	golem.element_weakness = "water"
	golem.element_resistance = "fire"
	golem.battle_color = Color(0.5, 0.4, 0.3)
	golem.sprite_scale = 1.3
	golem.sprite_path = "res://assets/sprites/battle/golem.png"

	var slam := AttackPattern.new()
	slam.pattern_name = "Ground Slam"
	slam.hits = [{"delay": 1.0, "window": 0.35, "damage_pct": 1.3}]
	slam.action_text = "{attacker} slams the ground beneath {target}!"

	var toss := AttackPattern.new()
	toss.pattern_name = "Boulder Toss"
	toss.hits = [{"delay": 0.7, "window": 0.3, "damage_pct": 1.0}]
	toss.action_text = "{attacker} hurls a boulder at {target}!"

	golem.attack_patterns = [slam, toss]
	return golem

func _create_boss_data() -> EnemyData:
	var boss := EnemyData.new()
	boss.enemy_name = "Dark Knight"
	boss.max_hp = 200
	boss.attack = 22
	boss.defense = 14
	boss.magic_defense = 10
	boss.speed = 11
	boss.xp_reward = 100
	boss.element_weakness = "lightning"
	boss.element_resistance = "earth"
	boss.battle_color = Color(0.15, 0.15, 0.2)
	boss.boss = true
	boss.sprite_scale = 1.5
	boss.sprite_path = "res://assets/sprites/battle/boss_dark_knight.png"

	var combo := AttackPattern.new()
	combo.pattern_name = "Blade Combo"
	combo.hits = [
		{"delay": 0.6, "window": 0.3, "damage_pct": 0.25},
		{"delay": 0.25, "window": 0.22, "damage_pct": 0.2},
		{"delay": 0.25, "window": 0.22, "damage_pct": 0.2},
		{"delay": 0.25, "window": 0.22, "damage_pct": 0.15},
		{"delay": 0.5, "window": 0.25, "damage_pct": 0.2},
	]
	combo.action_text = "{attacker} unleashes a relentless Blade Combo on {target}!"

	var thrust := AttackPattern.new()
	thrust.pattern_name = "Delayed Thrust"
	thrust.hits = [
		{"delay": 0.3, "window": 0.0, "damage_pct": 0.0}, # feint
		{"delay": 1.5, "window": 0.25, "damage_pct": 1.5},
	]
	thrust.action_text = "{attacker} feints, then thrusts at {target}!"

	var cleave := AttackPattern.new()
	cleave.pattern_name = "Dark Cleave"
	cleave.is_aoe = true
	cleave.hits = [{"delay": 0.5, "window": 0.3, "damage_pct": 0.8}]
	cleave.action_text = "{attacker} unleashes Dark Cleave on the entire party!"

	boss.attack_patterns = [combo, thrust, cleave]
	return boss

func _create_goblin_group() -> Array:
	return [_create_goblin_data(), _create_goblin_data()]

func _create_wraith_group() -> Array:
	return [_create_wraith_data(), _create_wraith_data()]

func _create_golem_group() -> Array:
	return [_create_golem_data(), _create_goblin_data()]

func _create_boss_group() -> Array:
	return [_create_boss_data()]

# ── Map Rendering ────────────────────────────────────────────────────

func _render_map() -> void:
	var ground := Node2D.new()
	ground.name = "Ground"
	add_child(ground)

	for r in range(MAP_ROWS):
		for c in range(MAP_COLS):
			var rect := ColorRect.new()
			rect.size = Vector2(TILE_SIZE, TILE_SIZE)
			rect.position = Vector2(c * TILE_SIZE, r * TILE_SIZE)

			if map_grid[r][c] == 1:
				rect.color = COLOR_WALL
			else:
				rect.color = COLOR_FLOOR
				# Check if this is an encounter zone
				var in_encounter := false
				for enc in encounter_zones:
					if not enc.defeated:
						for gp in enc.grid_positions:
							if gp.x == c and gp.y == r:
								if enc.is_boss:
									rect.color = COLOR_BOSS_FLOOR
								else:
									rect.color = COLOR_ENCOUNTER
								in_encounter = true
								break
					if in_encounter:
						break

			ground.add_child(rect)

	# Room labels
	_add_room_label("Start Chamber", Vector2i(10, 1))
	_add_room_label("Hall of Echoes", Vector2i(9, 10))
	_add_room_label("Wraith Corridor", Vector2i(9, 19))
	_add_room_label("Golem Chamber", Vector2i(9, 26))
	_add_room_label("Boss Arena", Vector2i(9, 32))

func _add_room_label(text: String, grid_pos: Vector2i) -> void:
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 10)
	lbl.add_theme_color_override("font_color", Color(0.35, 0.35, 0.45))
	lbl.position = Vector2(grid_pos.x * TILE_SIZE, grid_pos.y * TILE_SIZE - 14)
	add_child(lbl)

func _spawn_player() -> void:
	var player_script: GDScript = load("res://scripts/overworld/overworld_player.gd")
	player_node = Node2D.new()
	player_node.set_script(player_script)
	player_node.name = "Player"
	add_child(player_node)
	player_node.init(self, player_start)
	player_node.add_to_group("player")

	# Camera follows player
	var cam := Camera2D.new()
	cam.zoom = Vector2(1.5, 1.5)
	cam.limit_left = 0
	cam.limit_top = 0
	cam.limit_right = MAP_COLS * TILE_SIZE
	cam.limit_bottom = MAP_ROWS * TILE_SIZE
	player_node.add_child(cam)

func _show_intro() -> void:
	# Create a brief intro text overlay
	var overlay := CanvasLayer.new()
	overlay.layer = 50
	add_child(overlay)

	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.05, 0.12, 0.92)
	style.border_color = Color(0.4, 0.4, 0.6)
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_width_left = 2
	style.border_width_right = 2
	style.content_margin_left = 20
	style.content_margin_right = 20
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	panel.add_theme_stylebox_override("panel", style)
	panel.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	panel.offset_top = -100
	panel.offset_bottom = -20
	panel.offset_left = -200
	panel.offset_right = 200
	overlay.add_child(panel)

	var lbl := Label.new()
	lbl.text = "The rift grows stronger...\nNavigate the dungeon. Danger awaits.\n\n[WASD / Arrows to move]"
	lbl.add_theme_font_size_override("font_size", 14)
	lbl.add_theme_color_override("font_color", Color(0.8, 0.8, 0.9))
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel.add_child(lbl)

	player_node.frozen = true
	# Wait up to 3 seconds but allow skipping with confirm
	var elapsed: float = 0.0
	while elapsed < 3.0:
		await get_tree().process_frame
		elapsed += get_process_delta_time()
		if Input.is_action_just_pressed("confirm"):
			break
	player_node.frozen = false
	overlay.queue_free()

# ── Public API ───────────────────────────────────────────────────────

func is_walkable(col: int, row: int) -> bool:
	if col < 0 or col >= MAP_COLS or row < 0 or row >= MAP_ROWS:
		return false
	return map_grid[row][col] == 0

func on_player_moved(grid_pos: Vector2i) -> void:
	for enc in encounter_zones:
		if enc.defeated:
			continue
		for gp in enc.grid_positions:
			if gp == grid_pos:
				player_node.frozen = true
				main_node.start_battle(enc.id, enc.enemy_group, enc.is_boss)
				return

func on_battle_won(encounter_id: int) -> void:
	for enc in encounter_zones:
		if enc.id == encounter_id:
			enc.defeated = true
			break
	# Re-render encounter zone colors
	_update_encounter_visuals()
	player_node.frozen = false

	# Check if boss was defeated (victory condition)
	for enc in encounter_zones:
		if enc.is_boss and enc.defeated:
			_show_game_complete()
			return

func _update_encounter_visuals() -> void:
	var ground: Node2D = get_node("Ground")
	var child_index := 0
	for r in range(MAP_ROWS):
		for c in range(MAP_COLS):
			var rect: ColorRect = ground.get_child(child_index) as ColorRect
			if map_grid[r][c] == 0:
				var in_active_encounter := false
				for enc in encounter_zones:
					if not enc.defeated:
						for gp in enc.grid_positions:
							if gp.x == c and gp.y == r:
								in_active_encounter = true
								break
					if in_active_encounter:
						break
				if not in_active_encounter:
					rect.color = COLOR_FLOOR
			child_index += 1

func _show_game_complete() -> void:
	player_node.frozen = true
	var overlay := CanvasLayer.new()
	overlay.layer = 50
	add_child(overlay)

	var bg := ColorRect.new()
	bg.color = Color(0, 0, 0, 0.7)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(bg)

	var lbl := Label.new()
	lbl.text = "THE RIFT IS SEALED\n\nThe Gate of Aurith falls silent.\nThe darkness recedes... for now.\n\n~ Thank you for playing ~"
	lbl.add_theme_font_size_override("font_size", 24)
	lbl.add_theme_color_override("font_color", Color.GOLD)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.set_anchors_preset(Control.PRESET_CENTER)
	lbl.offset_left = -250
	lbl.offset_right = 250
	lbl.offset_top = -100
	lbl.offset_bottom = 100
	overlay.add_child(lbl)
