extends Node2D

const TILE_SIZE := 48
const MAP_COLS := 25
const MAP_ROWS := 35

var main_node: Node2D = null
var map_grid: Array = [] # 2D [row][col] of int: 0=floor, 1=wall
var encounter_zones: Array[EncounterZone] = []
var player_node: Node2D = null
var player_start := Vector2i(12, 2)

# Map rendering - single texture instead of per-tile nodes
var _map_image: Image = null
var _map_texture: ImageTexture = null
var _map_sprite: Sprite2D = null

# Tile images (loaded at render time, scaled to TILE_SIZE)
var _tile_floors: Array = []   # floor_1..floor_4, picked by position for variety
var _tile_wall: Image = null
var _tile_encounter: Image = null   # floor tinted red — danger zones
var _tile_boss: Image = null        # floor tinted deep purple — boss arena

var _needs_intro := false
var tutorial_ui: CanvasLayer = null
var _tutorial_textures: Dictionary = {}
var _tutorial_pages: Array = []
var _tutorial_page_index := 0
var _tutorial_title_label: Label = null
var _tutorial_body_label: RichTextLabel = null
var _tutorial_image_row: HBoxContainer = null
var _tutorial_previous_button: Button = null
var _tutorial_page_indicator: Label = null
var _tutorial_next_button: Button = null
var _tutorial_root: Control = null
var _tutorial_border: PanelContainer = null
var _tutorial_panel: PanelContainer = null

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

	# Place enemy sprites on the overworld
	_spawn_encounter_sprites()

# ── Encounter Sprites ────────────────────────────────────────────────

const ENEMY_SPRITE_HEIGHT := 72.0  # ~1.5 tiles tall, imposing presence

func _spawn_encounter_sprites() -> void:
	for enc in encounter_zones:
		if enc.defeated:
			continue
		# Use the first enemy's idle sprite
		var enemy_data: EnemyData = enc.enemy_group[0]
		var idle_path: String = enemy_data.sprite_idle + "/frame_0.png"
		var tex := load(idle_path) as Texture2D
		if tex == null:
			push_warning("Overworld: missing enemy sprite: %s" % idle_path)
			continue

		# Place at center of encounter zone
		var center: Vector2i = enc.grid_positions[0]
		var spr := Sprite2D.new()
		spr.texture = tex
		var s := ENEMY_SPRITE_HEIGHT / float(tex.get_height())
		spr.scale = Vector2(s, s)
		spr.position = Vector2(
			center.x * TILE_SIZE + TILE_SIZE * 0.5,
			center.y * TILE_SIZE + TILE_SIZE * 0.5
		)
		spr.z_index = center.y + 1  # render above floor
		add_child(spr)
		enc.overworld_sprite = spr

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
	goblin.sprite_idle = "res://assets/sprites/battle/frames/goblin_idle"
	goblin.sprite_defend = "res://assets/sprites/battle/frames/goblin_defend"
	goblin.defend_hold_frame = 5
	goblin.attack_sprite_map = {
		"Goblin Slash": "res://assets/sprites/battle/frames/goblin_slash",
		"Double Strike": "res://assets/sprites/battle/frames/goblin_double_strike",
	}

	var slash := AttackPattern.new()
	slash.pattern_name = "Goblin Slash"
	slash.is_melee = true
	slash.hits = [{"delay": 0.8, "window": 0.48, "damage_pct": 1.0}]
	slash.action_text = "{attacker} slashes at {target}!"

	var double_strike := AttackPattern.new()
	double_strike.pattern_name = "Double Strike"
	double_strike.is_melee = true
	double_strike.hits = [
		{"delay": 0.6, "window": 0.38, "damage_pct": 0.5},
		{"delay": 0.4, "window": 0.38, "damage_pct": 0.5},
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
	wraith.sprite_idle = "res://assets/sprites/battle/frames/wraith_idle"
	wraith.sprite_defend = "res://assets/sprites/battle/frames/wraith_defend"
	wraith.defend_hold_frame = 5
	wraith.attack_sprite_map = {
		"Spectral Claw": "res://assets/sprites/battle/frames/wraith_spectral_claw",
		"Delayed Haunt": "res://assets/sprites/battle/frames/wraith_delayed_haunt",
	}

	var triple := AttackPattern.new()
	triple.pattern_name = "Spectral Claw"
	triple.is_melee = true
	triple.hits = [
		{"delay": 0.5, "window": 0.33, "damage_pct": 0.35},
		{"delay": 0.3, "window": 0.30, "damage_pct": 0.3},
		{"delay": 0.3, "window": 0.30, "damage_pct": 0.35},
	]
	triple.action_text = "{attacker} unleashes Spectral Claws at {target}!"

	var delayed := AttackPattern.new()
	delayed.pattern_name = "Delayed Haunt"
	delayed.hits = [
		{"delay": 0.4, "window": 0.0, "damage_pct": 0.0}, # feint
		{"delay": 1.2, "window": 0.38, "damage_pct": 1.2},
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
	golem.sprite_idle = "res://assets/sprites/battle/frames/golem_idle"
	golem.sprite_defend = "res://assets/sprites/battle/frames/golem_defend"
	golem.defend_hold_frame = 7
	golem.attack_sprite_map = {
		"Ground Slam": "res://assets/sprites/battle/frames/golem_ground_slam",
		"Boulder Toss": "res://assets/sprites/battle/frames/golem_boulder_toss",
	}

	var slam := AttackPattern.new()
	slam.pattern_name = "Ground Slam"
	slam.is_melee = true
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
	golem.attack_sprite_map["Earthquake"] = "res://assets/sprites/battle/frames/golem_earthquake"

	golem.attack_patterns = [slam, toss, quake]
	return golem

func _create_boss_data() -> EnemyData:
	var boss := EnemyData.new()
	boss.enemy_name = "Dark Knight"
	boss.max_hp = 320
	boss.attack = 28
	boss.defense = 16
	boss.magic_defense = 12
	boss.speed = 13
	boss.xp_reward = 100
	boss.element_weakness = "lightning"
	boss.element_resistance = "earth"
	boss.battle_color = Color(0.15, 0.15, 0.2)
	boss.boss = true
	boss.sprite_scale = 2.0
	boss.sprite_path = "res://assets/sprites/battle/boss_dark_knight.png"
	boss.sprite_idle = "res://assets/sprites/battle/frames/dark_knight_idle"
	boss.sprite_defend = "res://assets/sprites/battle/frames/dark_knight_defend"
	boss.defend_hold_frame = 7
	boss.attack_sprite_map = {
		"Blade Combo": "res://assets/sprites/battle/frames/dark_knight_blade_combo",
		"Delayed Thrust": "res://assets/sprites/battle/frames/dark_knight_delayed_thrust",
		"Dark Cleave": "res://assets/sprites/battle/frames/dark_knight_dark_cleave",
		"Shadow Rend": "res://assets/sprites/battle/frames/dark_knight_shadow_rend",
	}

	# 5-hit combo with a feint mixed in — hit 3 is a fake-out
	var combo := AttackPattern.new()
	combo.pattern_name = "Blade Combo"
	combo.is_melee = true
	combo.hits = [
		{"delay": 0.55, "window": 0.33, "damage_pct": 0.2},
		{"delay": 0.22, "window": 0.28, "damage_pct": 0.2},
		{"delay": 0.3, "window": 0.0, "damage_pct": 0.0},  # feint mid-combo
		{"delay": 0.2, "window": 0.26, "damage_pct": 0.25},
		{"delay": 0.45, "window": 0.30, "damage_pct": 0.35},
	]
	combo.action_text = "{attacker} unleashes a relentless Blade Combo on {target}!"

	# Double feint into massive hit
	var thrust := AttackPattern.new()
	thrust.pattern_name = "Delayed Thrust"
	thrust.is_melee = true
	thrust.hits = [
		{"delay": 0.3, "window": 0.0, "damage_pct": 0.0},  # feint 1
		{"delay": 0.4, "window": 0.0, "damage_pct": 0.0},  # feint 2
		{"delay": 1.2, "window": 0.30, "damage_pct": 1.8},  # real hit
	]
	thrust.action_text = "{attacker} feints twice, then thrusts at {target}!"

	# Team-wide attack: 3 hits targeting random party members
	var cleave := AttackPattern.new()
	cleave.pattern_name = "Dark Cleave"
	cleave.is_melee = true
	cleave.is_team_attack = true
	cleave.hits = [
		{"delay": 0.6, "window": 0.32, "damage_pct": 0.5},
		{"delay": 0.3, "window": 0.30, "damage_pct": 0.5},
		{"delay": 0.4, "window": 0.30, "damage_pct": 0.6},
	]
	cleave.action_text = "{attacker} unleashes Dark Cleave across the party!"

	# Single-target fast 3-hit with tight windows
	var rend := AttackPattern.new()
	rend.pattern_name = "Shadow Rend"
	rend.is_melee = true
	rend.hits = [
		{"delay": 0.4, "window": 0.28, "damage_pct": 0.4},
		{"delay": 0.2, "window": 0.26, "damage_pct": 0.4},
		{"delay": 0.3, "window": 0.26, "damage_pct": 0.5},
	]
	rend.action_text = "{attacker} tears through {target} with Shadow Rend!"

	# Team-wide: feint into multi-hit chaos
	var onslaught := AttackPattern.new()
	onslaught.pattern_name = "Abyssal Onslaught"
	onslaught.is_team_attack = true
	onslaught.hits = [
		{"delay": 0.4, "window": 0.0, "damage_pct": 0.0},   # feint
		{"delay": 0.35, "window": 0.28, "damage_pct": 0.35},
		{"delay": 0.25, "window": 0.26, "damage_pct": 0.35},
		{"delay": 0.25, "window": 0.26, "damage_pct": 0.35},
		{"delay": 0.5, "window": 0.30, "damage_pct": 0.5},
	]
	onslaught.action_text = "{attacker} unleashes Abyssal Onslaught on the party!"
	boss.attack_sprite_map["Abyssal Onslaught"] = "res://assets/sprites/battle/frames/dark_knight_onslaught"

	boss.attack_patterns = [combo, thrust, cleave, rend, onslaught]
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

func _load_tiles() -> void:
	var base := "res://assets/sprites/overworld/tiles/"
	for i in range(1, 5):
		var img := Image.load_from_file(base + "floor_%d.png" % i)
		img.resize(TILE_SIZE, TILE_SIZE, Image.INTERPOLATE_NEAREST)
		_tile_floors.append(img)

	_tile_wall = Image.load_from_file(base + "wall_mid.png")
	_tile_wall.resize(TILE_SIZE, TILE_SIZE, Image.INTERPOLATE_NEAREST)

	_tile_encounter = _tile_floors[0].duplicate()
	_tint_image(_tile_encounter, Color(1.6, 0.5, 0.5))

	_tile_boss = _tile_floors[0].duplicate()
	_tint_image(_tile_boss, Color(1.0, 0.35, 1.5))

func _tint_image(img: Image, tint: Color) -> void:
	for y in range(img.get_height()):
		for x in range(img.get_width()):
			var p := img.get_pixel(x, y)
			img.set_pixel(x, y, Color(
				clampf(p.r * tint.r, 0.0, 1.0),
				clampf(p.g * tint.g, 0.0, 1.0),
				clampf(p.b * tint.b, 0.0, 1.0),
				p.a
			))

func _render_map() -> void:
	_load_tiles()
	_map_image = Image.create(MAP_COLS * TILE_SIZE, MAP_ROWS * TILE_SIZE, false, Image.FORMAT_RGBA8)

	for r in range(MAP_ROWS):
		for c in range(MAP_COLS):
			var tile: Image
			if map_grid[r][c] == 1:
				tile = _tile_wall
			else:
				tile = _tile_floors[(c * 3 + r * 7) % _tile_floors.size()]
				for enc in encounter_zones:
					if not enc.defeated:
						for gp in enc.grid_positions:
							if gp.x == c and gp.y == r:
								tile = _tile_boss if enc.is_boss else _tile_encounter
								break

			_fill_tile(_map_image, c, r, tile)

	_map_texture = ImageTexture.create_from_image(_map_image)
	_map_sprite = Sprite2D.new()
	_map_sprite.name = "Ground"
	_map_sprite.texture = _map_texture
	_map_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_map_sprite.centered = false
	add_child(_map_sprite)

	# Room labels
	_add_room_label("Start Chamber", Vector2i(10, 1))
	_add_room_label("Hall of Echoes", Vector2i(9, 10))
	_add_room_label("Wraith Corridor", Vector2i(9, 19))
	_add_room_label("Golem Chamber", Vector2i(9, 26))
	_add_room_label("Boss Arena", Vector2i(9, 32))

func _fill_tile(img: Image, col: int, row: int, tile: Image) -> void:
	var x0: int = col * TILE_SIZE
	var y0: int = row * TILE_SIZE
	img.blit_rect(tile, Rect2i(0, 0, TILE_SIZE, TILE_SIZE), Vector2i(x0, y0))

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
	player_node.frozen = true
	if tutorial_ui != null and is_instance_valid(tutorial_ui):
		tutorial_ui.queue_free()
	_tutorial_textures = _build_tutorial_textures()
	_tutorial_pages = _build_tutorial_pages()
	_tutorial_page_index = 0
	tutorial_ui = _build_tutorial_ui()
	add_child(tutorial_ui)
	_render_tutorial_page()

func _on_tutorial_closed() -> void:
	if tutorial_ui != null and is_instance_valid(tutorial_ui):
		tutorial_ui.queue_free()
	tutorial_ui = null
	_tutorial_textures.clear()
	_tutorial_pages.clear()
	player_node.frozen = false

func _build_tutorial_ui() -> CanvasLayer:
	var overlay_color := Color(0.0, 0.0, 0.05, 0.82)
	var panel_color := Color(0.055, 0.045, 0.09, 0.97)
	var accent_color := Color(0.91, 0.76, 0.35, 1.0)
	var body_color := Color(0.93, 0.89, 0.78, 1.0)

	var layer := CanvasLayer.new()
	layer.layer = 100
	layer.process_mode = Node.PROCESS_MODE_ALWAYS

	_tutorial_root = Control.new()
	_tutorial_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_tutorial_root.mouse_filter = Control.MOUSE_FILTER_STOP
	layer.add_child(_tutorial_root)

	var overlay := ColorRect.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.color = overlay_color
	_tutorial_root.add_child(overlay)

	_tutorial_border = PanelContainer.new()
	_tutorial_border.add_theme_stylebox_override("panel", _make_tutorial_style(accent_color, Color(0, 0, 0, 0), 3))
	_tutorial_root.add_child(_tutorial_border)

	_tutorial_panel = PanelContainer.new()
	_tutorial_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	_tutorial_panel.offset_left = 3
	_tutorial_panel.offset_top = 3
	_tutorial_panel.offset_right = -3
	_tutorial_panel.offset_bottom = -3
	_tutorial_panel.add_theme_stylebox_override("panel", _make_tutorial_style(accent_color, panel_color, 0))
	_tutorial_border.add_child(_tutorial_panel)

	var panel_margin := MarginContainer.new()
	panel_margin.add_theme_constant_override("margin_left", 22)
	panel_margin.add_theme_constant_override("margin_top", 18)
	panel_margin.add_theme_constant_override("margin_right", 22)
	panel_margin.add_theme_constant_override("margin_bottom", 18)
	_tutorial_panel.add_child(panel_margin)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 12)
	panel_margin.add_child(content)

	var top_row := HBoxContainer.new()
	content.add_child(top_row)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_row.add_child(spacer)

	var skip_button := _make_tutorial_button("Skip Tutorial", accent_color)
	skip_button.pressed.connect(_on_tutorial_closed)
	top_row.add_child(skip_button)

	_tutorial_title_label = Label.new()
	_tutorial_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_tutorial_title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_tutorial_title_label.add_theme_color_override("font_color", accent_color)
	_tutorial_title_label.add_theme_font_size_override("font_size", 26)
	content.add_child(_tutorial_title_label)

	var top_separator := ColorRect.new()
	top_separator.custom_minimum_size = Vector2(0, 2)
	top_separator.color = accent_color
	content.add_child(top_separator)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus = true
	content.add_child(scroll)

	var scroll_content := VBoxContainer.new()
	scroll_content.add_theme_constant_override("separation", 18)
	scroll_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(scroll_content)

	_tutorial_body_label = RichTextLabel.new()
	_tutorial_body_label.bbcode_enabled = true
	_tutorial_body_label.fit_content = true
	_tutorial_body_label.scroll_active = false
	_tutorial_body_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_tutorial_body_label.add_theme_color_override("default_color", body_color)
	_tutorial_body_label.add_theme_font_size_override("normal_font_size", 15)
	_tutorial_body_label.add_theme_font_size_override("italics_font_size", 15)
	_tutorial_body_label.add_theme_font_size_override("bold_font_size", 15)
	scroll_content.add_child(_tutorial_body_label)

	_tutorial_image_row = HBoxContainer.new()
	_tutorial_image_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_tutorial_image_row.add_theme_constant_override("separation", 18)
	scroll_content.add_child(_tutorial_image_row)

	var bottom_separator := ColorRect.new()
	bottom_separator.custom_minimum_size = Vector2(0, 2)
	bottom_separator.color = Color(accent_color.r, accent_color.g, accent_color.b, 0.35)
	content.add_child(bottom_separator)

	var nav_row := HBoxContainer.new()
	nav_row.alignment = BoxContainer.ALIGNMENT_CENTER
	nav_row.add_theme_constant_override("separation", 18)
	content.add_child(nav_row)

	_tutorial_previous_button = _make_tutorial_button("Previous", accent_color)
	_tutorial_previous_button.pressed.connect(_tutorial_previous_page)
	nav_row.add_child(_tutorial_previous_button)

	_tutorial_page_indicator = Label.new()
	_tutorial_page_indicator.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_tutorial_page_indicator.custom_minimum_size = Vector2(120, 0)
	_tutorial_page_indicator.add_theme_color_override("font_color", body_color)
	_tutorial_page_indicator.add_theme_font_size_override("font_size", 15)
	nav_row.add_child(_tutorial_page_indicator)

	_tutorial_next_button = _make_tutorial_button("Next", accent_color)
	_tutorial_next_button.pressed.connect(_tutorial_next_page)
	nav_row.add_child(_tutorial_next_button)

	_tutorial_root.gui_input.connect(_on_tutorial_gui_input)
	_tutorial_root.resized.connect(_layout_tutorial_ui)
	_layout_tutorial_ui()
	return layer

func _layout_tutorial_ui() -> void:
	if _tutorial_root == null or _tutorial_border == null or _tutorial_panel == null:
		return

	var viewport_size: Vector2 = get_viewport_rect().size
	var margin: float = clampf(minf(viewport_size.x, viewport_size.y) * 0.05, 16.0, 40.0)
	var width: float = clampf(viewport_size.x - margin * 2.0, 320.0, 680.0)
	var height: float = clampf(viewport_size.y - margin * 2.0, 300.0, 470.0)
	_tutorial_border.size = Vector2(width + 6.0, height + 6.0)
	_tutorial_border.position = (viewport_size - _tutorial_border.size) * 0.5

func _render_tutorial_page() -> void:
	if _tutorial_pages.is_empty():
		return

	_tutorial_page_index = clampi(_tutorial_page_index, 0, _tutorial_pages.size() - 1)
	var page: Dictionary = _tutorial_pages[_tutorial_page_index]

	_tutorial_title_label.text = str(page.get("title", "Tutorial"))
	_tutorial_body_label.clear()
	_tutorial_body_label.push_paragraph(HORIZONTAL_ALIGNMENT_CENTER)
	_tutorial_body_label.append_text(str(page.get("body", "")))
	_tutorial_body_label.pop()

	for child in _tutorial_image_row.get_children():
		child.queue_free()

	var images: Array = page.get("images", []) as Array
	for image_variant in images:
		var image_data: Dictionary = image_variant
		var tile := _build_tutorial_image_tile(image_data)
		if tile != null:
			_tutorial_image_row.add_child(tile)

	_tutorial_image_row.visible = _tutorial_image_row.get_child_count() > 0
	_tutorial_previous_button.visible = _tutorial_page_index > 0
	_tutorial_page_indicator.text = "%d / %d" % [_tutorial_page_index + 1, _tutorial_pages.size()]
	if page.has("next_label"):
		_tutorial_next_button.text = str(page["next_label"])
	elif _tutorial_page_index < _tutorial_pages.size() - 1:
		_tutorial_next_button.text = "Next"
	else:
		_tutorial_next_button.text = "Enter the Dungeon"

func _tutorial_next_page() -> void:
	if _tutorial_page_index >= _tutorial_pages.size() - 1:
		_on_tutorial_closed()
		return
	_tutorial_page_index += 1
	_render_tutorial_page()

func _tutorial_previous_page() -> void:
	if _tutorial_page_index <= 0:
		return
	_tutorial_page_index -= 1
	_render_tutorial_page()

func _on_tutorial_gui_input(event: InputEvent) -> void:
	var key_event := event as InputEventKey
	if key_event == null or not key_event.pressed or key_event.echo:
		return

	if key_event.keycode == KEY_ESCAPE:
		_on_tutorial_closed()
	elif key_event.keycode == KEY_ENTER or key_event.keycode == KEY_KP_ENTER or key_event.keycode == KEY_SPACE or key_event.keycode == KEY_RIGHT:
		_tutorial_next_page()
	elif key_event.keycode == KEY_BACKSPACE or key_event.keycode == KEY_LEFT:
		_tutorial_previous_page()
	get_viewport().set_input_as_handled()

func _unhandled_input(event: InputEvent) -> void:
	if tutorial_ui == null or not is_instance_valid(tutorial_ui):
		return

	var key_event := event as InputEventKey
	if key_event == null or not key_event.pressed or key_event.echo:
		return

	if key_event.keycode == KEY_ESCAPE:
		_on_tutorial_closed()
	elif key_event.keycode == KEY_ENTER or key_event.keycode == KEY_KP_ENTER or key_event.keycode == KEY_SPACE or key_event.keycode == KEY_RIGHT:
		_tutorial_next_page()
	elif key_event.keycode == KEY_BACKSPACE or key_event.keycode == KEY_LEFT:
		_tutorial_previous_page()
	else:
		return

	get_viewport().set_input_as_handled()

func _build_tutorial_image_tile(image_data: Dictionary) -> Control:
	var texture_key: String = str(image_data.get("key", ""))
	if texture_key.is_empty() or not _tutorial_textures.has(texture_key):
		return null

	var texture: Texture2D = _tutorial_textures[texture_key]
	if texture == null:
		return null

	var wrapper := VBoxContainer.new()
	wrapper.add_theme_constant_override("separation", 8)
	wrapper.custom_minimum_size = Vector2(116, 0)

	var frame := PanelContainer.new()
	frame.add_theme_stylebox_override("panel", _make_tutorial_style(Color(0.91, 0.76, 0.35, 1.0), Color(0.1, 0.08, 0.12, 0.92), 2))
	frame.custom_minimum_size = Vector2(100, 100)
	wrapper.add_child(frame)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	frame.add_child(margin)

	var texture_rect := TextureRect.new()
	texture_rect.texture = texture
	texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var image_size: float = float(image_data.get("size", 48))
	texture_rect.custom_minimum_size = Vector2(image_size, image_size)
	texture_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var image_modulate: Color = image_data.get("modulate", Color.WHITE) as Color
	texture_rect.modulate = image_modulate
	margin.add_child(texture_rect)

	var caption := Label.new()
	caption.text = str(image_data.get("caption", ""))
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	caption.add_theme_color_override("font_color", Color(0.76, 0.71, 0.62, 1.0))
	caption.add_theme_font_size_override("font_size", 13)
	wrapper.add_child(caption)

	return wrapper

func _make_tutorial_button(text: String, border_color: Color) -> Button:
	var button := Button.new()
	button.text = text
	button.focus_mode = Control.FOCUS_CLICK
	button.custom_minimum_size = Vector2(132, 42)
	button.add_theme_color_override("font_color", border_color)
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_color_override("font_pressed_color", Color.WHITE)
	button.add_theme_font_size_override("font_size", 15)
	button.add_theme_stylebox_override("normal", _make_tutorial_style(border_color, Color(0.12, 0.09, 0.16, 1.0), 2))
	button.add_theme_stylebox_override("hover", _make_tutorial_style(border_color, Color(0.18, 0.13, 0.22, 1.0), 2))
	button.add_theme_stylebox_override("pressed", _make_tutorial_style(border_color, Color(0.08, 0.06, 0.11, 1.0), 2))
	button.add_theme_stylebox_override("focus", _make_tutorial_style(Color.WHITE, Color(0.18, 0.13, 0.22, 1.0), 2))
	return button

func _make_tutorial_style(border_color: Color, fill_color: Color, border_width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill_color
	style.border_color = border_color
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(6)
	style.set_content_margin_all(10)
	return style

func _build_tutorial_pages() -> Array[Dictionary]:
	return [
		{
			"title": "Gate of Aurith",
			"body": "[center]The rift beneath Aurith has opened again. Guide the party through the dungeon, survive each encounter, and bring down the force waiting in the depths.[/center]",
			"images": [
				{"key": "mage", "caption": "Mage", "size": 52},
				{"key": "sage", "caption": "Sage", "size": 52},
				{"key": "gustave", "caption": "Gustave", "size": 52}
			]
		},
		{
			"title": "Exploration Controls",
			"body": "[center][color=#e7c66f]WASD / Arrow Keys[/color] move the party one tile at a time. Press [color=#e7c66f]Tab[/color] to cycle the leader. The whole party follows behind, so use the front character you want to showcase while exploring.[/center]",
			"images": [
				{"key": "mage", "caption": "Leader", "size": 52},
				{"key": "floor", "caption": "Safe floor", "size": 52},
				{"key": "wall", "caption": "Walls block movement", "size": 52}
			]
		},
		{
			"title": "Danger Tiles",
			"body": "[center]Colored floor zones mark active encounters. Step onto one to start a battle. Clear the normal fights to reach the [color=#e7c66f]boss arena[/color] at the bottom of the dungeon and seal the rift.[/center]",
			"images": [
				{"key": "encounter", "caption": "Encounter zone", "size": 52, "modulate": Color(1.0, 0.55, 0.55)},
				{"key": "goblin", "caption": "Standard foes", "size": 52},
				{"key": "boss", "caption": "Boss zone", "size": 52, "modulate": Color(0.72, 0.5, 1.0)}
			]
		},
		{
			"title": "Battle Commands",
			"body": "[center]Each turn, choose from [color=#e7c66f]Attack[/color], [color=#e7c66f]Skill[/color], [color=#e7c66f]Item[/color], [color=#e7c66f]Defend[/color], or [color=#e7c66f]Stance[/color]. Use [color=#e7c66f]Enter / Space[/color] to confirm and [color=#e7c66f]Escape / X[/color] to cancel while browsing targets or menus.[/center]",
			"images": [
				{"key": "mage_spell", "caption": "Skills spend AP", "size": 52},
				{"key": "sage_spell", "caption": "Heal or exploit weakness", "size": 52},
				{"key": "gustave_attack", "caption": "Physical pressure", "size": 52}
			]
		},
		{
			"title": "Parry and Dodge",
			"body": "[center]Enemy attacks open a timing window. Press [color=#e7c66f]Z[/color] to [color=#e7c66f]Parry[/color] for a counter or [color=#e7c66f]X[/color] to [color=#e7c66f]Dodge[/color] for safety. Defending reduces damage, but a defending character cannot parry or dodge until their next turn.[/center]",
			"images": [
				{"key": "parry_ring", "caption": "Watch the ring", "size": 56},
				{"key": "goblin_slash", "caption": "React to attack tells", "size": 52},
				{"key": "gustave_guard", "caption": "Defend trades reaction for safety", "size": 52}
			]
		},
		{
			"title": "Elements and Roles",
			"body": "[center]The party wins by matching tools to the enemy. The Mage brings strong elemental damage, the Sage supports with healing and magic, and Gustave anchors the front line. Exploit enemy weaknesses to end fights before they overwhelm the party.[/center]",
			"images": [
				{"key": "mage_spell", "caption": "Mage", "size": 52},
				{"key": "sage_spell", "caption": "Sage", "size": 52},
				{"key": "wraith", "caption": "Some enemies resist magic types", "size": 52}
			]
		},
		{
			"title": "Gustave's Stance",
			"body": "[center]Gustave can switch between [color=#e7c66f]Greatsword[/color] and [color=#e7c66f]Greatshield[/color]. Greatsword deals more damage but takes harder hits. Greatshield lowers damage taken and enlarges the parry window, but his offense drops.[/center]",
			"images": [
				{"key": "gustave_attack", "caption": "Greatsword", "size": 52},
				{"key": "gustave_guard", "caption": "Greatshield", "size": 52},
				{"key": "golem", "caption": "Swap for the matchup", "size": 52}
			]
		},
		{
			"title": "Press On",
			"body": "[center]Victory fully restores the party, so stay aggressive and master the parry rhythm. Reach the final chamber, defeat the Dark Knight, and close the Gate of Aurith.[/center]",
			"images": [
				{"key": "dark_knight", "caption": "Final threat", "size": 56},
				{"key": "boss", "caption": "Bottom chamber", "size": 52, "modulate": Color(0.72, 0.5, 1.0)}
			],
			"next_label": "Enter the Dungeon"
		}
	]

func _build_tutorial_textures() -> Dictionary:
	return {
		"mage": _load_texture("res://assets/sprites/overworld/mage/mage_down_idle.png"),
		"sage": _load_texture("res://assets/sprites/overworld/sage/sage_down_idle.png"),
		"gustave": _load_texture("res://assets/sprites/overworld/gustave/gustave_down_idle.png"),
		"floor": _load_texture("res://assets/sprites/overworld/tiles/floor_1.png"),
		"wall": _load_texture("res://assets/sprites/overworld/tiles/wall_mid.png"),
		"parry_ring": _load_texture("res://assets/sprites/ui/parry_ring.png"),
		"encounter": _load_texture("res://assets/sprites/overworld/tiles/floor_1.png"),
		"boss": _load_texture("res://assets/sprites/overworld/tiles/floor_1.png"),
		"goblin": _load_frame_texture("res://assets/sprites/battle/frames/goblin_idle/frame_0.png"),
		"wraith": _load_frame_texture("res://assets/sprites/battle/frames/wraith_idle/frame_0.png"),
		"golem": _load_frame_texture("res://assets/sprites/battle/frames/golem_idle/frame_0.png"),
		"dark_knight": _load_frame_texture("res://assets/sprites/battle/frames/dark_knight_idle/frame_0.png"),
		"goblin_slash": _load_frame_texture("res://assets/sprites/battle/frames/goblin_slash/frame_0.png"),
		"mage_spell": _load_frame_texture("res://assets/sprites/battle/frames/mage_fireball/frame_0.png"),
		"sage_spell": _load_frame_texture("res://assets/sprites/battle/frames/sage_buff/frame_0.png"),
		"gustave_attack": _load_frame_texture("res://assets/sprites/battle/frames/gustave_attack/frame_0.png"),
		"gustave_guard": _load_frame_texture("res://assets/sprites/battle/frames/gustave_defend_alt/frame_0.png")
	}

func _load_texture(path: String) -> Texture2D:
	if not ResourceLoader.exists(path):
		return null
	return load(path) as Texture2D

func _load_frame_texture(path: String) -> Texture2D:
	return _load_texture(path)

# ── Public API ───────────────────────────────────────────────────────

func is_walkable(col: int, row: int) -> bool:
	if col < 0 or col >= MAP_COLS or row < 0 or row >= MAP_ROWS:
		return false
	return map_grid[row][col] == 0

func on_player_moved(grid_pos: Vector2i) -> void:
	# Encounters now trigger via try_trigger_encounter_at before movement,
	# but leave this hook in place for future tile-entry events.
	pass

func try_trigger_encounter_at(grid_pos: Vector2i) -> bool:
	for enc in encounter_zones:
		if enc.defeated:
			continue
		for gp in enc.grid_positions:
			if gp == grid_pos:
				player_node.frozen = true
				Sfx.play("battle_encounter", -5.0)
				main_node.start_battle(enc.id, enc.enemy_group, enc.is_boss)
				return true
	return false

func on_battle_won(encounter_id: int) -> void:
	for enc in encounter_zones:
		if enc.id == encounter_id:
			enc.defeated = true
			if enc.overworld_sprite:
				enc.overworld_sprite.queue_free()
				enc.overworld_sprite = null
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
	if _map_image == null or _map_texture == null:
		return
	# Only repaint tiles belonging to defeated encounters
	for enc in encounter_zones:
		if enc.defeated:
			for gp in enc.grid_positions:
				var tile: Image = _tile_floors[(gp.x * 3 + gp.y * 7) % _tile_floors.size()]
				_fill_tile(_map_image, gp.x, gp.y, tile)
	_map_texture.update(_map_image)

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
