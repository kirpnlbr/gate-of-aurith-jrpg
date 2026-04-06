extends Node2D

signal battle_finished(result: String)

enum BattleState {
	STARTING,
	TURN_START,
	PLAYER_SELECT,
	PLAYER_TARGET,
	PLAYER_EXECUTE,
	ENEMY_TURN_START,
	PARRY_PHASE,
	ENEMY_EXECUTE,
	CHECK_DEATH,
	VICTORY,
	DEFEAT,
}

var state: BattleState = BattleState.STARTING
var main_node: Node2D = null
var party_state: PartyState = null
var is_boss: bool = false

# Battle entities
var party: Array[Dictionary] = []
var enemies: Array[Dictionary] = []
var turn_order: TurnOrder = TurnOrder.new()
var current_turn: Dictionary = {}

# Pending action
var pending_action: String = ""
var pending_skill: SkillData = null
var pending_item_data: ItemData = null
var pending_item_index: int = -1
var pending_target_type: String = ""

# Stance
var gustave_stance: String = "greatsword"

# Buffs tracking: character dict gets "buffs" dict with keys like "buff_def": turns_remaining

# UI references
var action_text_box: Control = null
var action_menu: Control = null
var skill_menu: Control = null
var item_menu: Control = null
var target_selector: Node2D = null
var parry_indicator: Control = null
var parry_system: Node2D = null
var hud_node: Control = null

# Sprite containers
var party_sprites: Array[Sprite2D] = []
var enemy_sprites: Array[Sprite2D] = []

# Turn order display
var turn_order_label: Label = null  # kept for fallback reference
var _turn_order_container: HBoxContainer = null
var status_panel: HBoxContainer = null

# Status panel cached references
var _hp_bars: Array[ProgressBar] = []
var _hp_trail_bars: Array[ProgressBar] = []
var _hp_labels: Array[Label] = []
var _ap_bars: Array[ProgressBar] = []
var _ap_labels: Array[Label] = []
var _enemy_hp_bars: Array[ProgressBar] = []
var _enemy_hp_trail_bars: Array[ProgressBar] = []
var _enemy_hp_labels: Array[Label] = []
var _enemy_status_containers: Array[HBoxContainer] = []
var _party_status_containers: Array[HBoxContainer] = []

const ACTION_TEXT_DELAY := 0.8
const IDLE_FRAME_INTERVAL := 0.25
const PARTY_SPRITE_HEIGHT := 100.0
const ENEMY_SPRITE_BASE_HEIGHT := 80.0
const COUNTER_POWER := 16

# Viewport-relative layout (computed in _compute_layout)
var _vp_size := Vector2(960, 540)  # fallback
var PARTY_X := 180.0
var ENEMY_X := 700.0
var PARTY_Y_POSITIONS: Array[float] = [140.0, 265.0, 390.0]
var ENEMY_Y_START := 200.0
var ENEMY_Y_START_SINGLE := 250.0
var ENEMY_SPACING := 100.0
var STATUS_PANEL_X := 480.0
var STATUS_PANEL_Y := 30.0

var _idle_timer: float = 0.0
var _idle_frame_index: int = 0
var _sprite_material: ShaderMaterial = null
var effects: BattleEffects = null

# Turn indicator
var _turn_indicator: Polygon2D = null
var _turn_indicator_tween: Tween = null

# ── VFX Mapping ──────────────────────────────────────────────────────
# Element -> {projectile_vfx, impact_tint, uses_orb_or_shard_or_wave_or_eruption}
const ELEMENT_VFX := {
	"fire": {"proj": "proj_orb", "impact": "impact_burst", "tint": Color(1.0, 0.4, 0.1)},
	"ice": {"proj": "proj_shard", "impact": "impact_burst", "tint": Color(0.3, 0.8, 1.0)},
	"lightning": {"proj": "proj_shard", "impact": "impact_burst", "tint": Color(1.0, 0.95, 0.4)},
	"water": {"proj": "wave_sweep", "impact": "impact_burst", "tint": Color(0.2, 0.6, 1.0)},
	"lava": {"proj": "eruption", "impact": "impact_burst", "tint": Color(1.0, 0.3, 0.0)},
	"none": {"proj": "", "impact": "impact_burst", "tint": Color.WHITE},
}
# Skill name overrides for VFX that don't follow element defaults
const SKILL_VFX_OVERRIDE := {
	"Inferno": {"proj": "wave_sweep", "tint": Color(1.0, 0.4, 0.1)},
	"Tidal Wave": {"proj": "wave_sweep", "tint": Color(0.2, 0.6, 1.0)},
	"Lava Burst": {"proj": "eruption", "tint": Color(1.0, 0.3, 0.0)},
	"Heavy Slash": {"proj": "slash_arc", "tint": Color(1.0, 0.85, 0.3)},
	"Whirlwind": {"proj": "slash_arc", "tint": Color(1.0, 0.85, 0.3)},
}
# Sage summon VFX
const SUMMON_VFX := {
	"Phoenix Manifestation": {"vfx": "summon_winged", "tint": Color(1.0, 0.7, 0.2)},
	"Phoenix Rise": {"vfx": "summon_winged", "tint": Color(1.0, 0.7, 0.2)},
	"Leviathan Manifestation": {"vfx": "summon_serpent", "tint": Color(0.2, 0.6, 1.0)},
	"Thunderbird Manifestation": {"vfx": "summon_winged", "tint": Color(1.0, 0.95, 0.4)},
	"Griffin Manifestation": {"vfx": "summon_winged", "tint": Color(0.3, 1.0, 0.5)},
	"Golem Manifestation": {"vfx": "summon_beast", "tint": Color(0.8, 0.6, 0.2)},
	"Basilisk Manifestation": {"vfx": "summon_serpent", "tint": Color(0.6, 0.2, 0.8)},
}
const BUFF_AURA_TINT := {
	"buff_spd": Color(0.3, 1.0, 0.5),
	"buff_def": Color(0.8, 0.6, 0.2),
	"buff_atk": Color(1.0, 0.4, 0.4),
	"debuff_def": Color(0.6, 0.2, 0.8),
	"taunt": Color(1.0, 0.3, 0.3),
}

func init(main: Node2D, ps: PartyState, enemy_group: Array, boss: bool) -> void:
	main_node = main
	party_state = ps
	is_boss = boss
	gustave_stance = ps.gustave_stance

	# Build party battle data
	party.clear()
	for ch in ps.characters:
		var battle_ch: Dictionary = {
			"data": ch.data,
			"current_hp": ch.current_hp,
			"current_ap": ch.current_ap,
			"level": ch.level,
			"sprite": null,
			"defending": false,
			"buffs": {},
		}
		party.append(battle_ch)

	# Apply Gustave stance
	_apply_gustave_stance()

	# Build enemy battle data
	enemies.clear()
	for enemy_data in enemy_group:
		var ed: EnemyData = enemy_data as EnemyData
		enemies.append({
			"data": ed,
			"current_hp": ed.max_hp,
			"sprite": null,
			"buffs": {},
		})

func _ready() -> void:
	_build_battle_scene()
	_enter_state(BattleState.STARTING)

func _process(delta: float) -> void:
	# Cycle idle frames for all party members and enemies during non-animation states
	if state == BattleState.PLAYER_SELECT or state == BattleState.TURN_START or state == BattleState.PLAYER_TARGET:
		_idle_timer += delta
		if _idle_timer >= IDLE_FRAME_INTERVAL:
			_idle_timer -= IDLE_FRAME_INTERVAL
			_idle_frame_index += 1
			for i in range(party.size()):
				var ch_dict: Dictionary = party[i]
				if int(ch_dict.current_hp) <= 0:
					continue
				if not ch_dict.has("animations"):
					continue
				var anims: Dictionary = ch_dict.animations
				if not anims.has("idle"):
					continue
				var idle_arr: Array = anims.idle
				if idle_arr.is_empty() or ch_dict.sprite == null:
					continue
				var idx: int = _idle_frame_index % idle_arr.size()
				_set_entity_texture(ch_dict, idle_arr[idx])
			# Enemy idle cycling
			for e in enemies:
				if int(e.current_hp) <= 0:
					continue
				if not e.has("animations"):
					continue
				var anims: Dictionary = e.animations
				if not anims.has("idle"):
					continue
				var idle_arr: Array = anims.idle
				if idle_arr.is_empty() or e.sprite == null:
					continue
				var idx: int = _idle_frame_index % idle_arr.size()
				_set_entity_texture(e, idle_arr[idx])

var _battle_layer: CanvasLayer = null
var _sprite_root: Node2D = null

func _compute_layout() -> void:
	_vp_size = get_viewport().get_visible_rect().size
	if _vp_size.x <= 0 or _vp_size.y <= 0:
		_vp_size = Vector2(960, 540)
	var w := _vp_size.x
	var h := _vp_size.y
	PARTY_X = w * 0.1875            # 180 / 960
	ENEMY_X = w * 0.729             # 700 / 960
	STATUS_PANEL_X = w * 0.5
	STATUS_PANEL_Y = h * 0.056      # 30 / 540

	# Party Y: evenly distribute 3 slots in the middle vertical band
	var party_top := h * 0.26       # 140 / 540
	var party_bot := h * 0.72       # 390 / 540
	PARTY_Y_POSITIONS = [party_top, (party_top + party_bot) * 0.5, party_bot]

	# Enemy Y: compute based on enemy count to guarantee all fit on screen
	# UI is below sprites now: sprite half-height + bar(6) + label(16) + status(14) ≈ ~75px below center
	var enemy_top := h * 0.15       # top margin for first enemy
	var enemy_bot := h * 0.78       # bottom bound (leave room for below-sprite UI)
	var enemy_count := enemies.size()
	if enemy_count <= 1:
		ENEMY_Y_START_SINGLE = (enemy_top + enemy_bot) * 0.5
		ENEMY_Y_START = enemy_top
		ENEMY_SPACING = 120.0
	else:
		var max_spacing := 130.0
		var raw_spacing := (enemy_bot - enemy_top) / float(enemy_count - 1)
		ENEMY_SPACING = min(raw_spacing, max_spacing)
		# Center the group vertically between enemy_top and enemy_bot
		var group_height := ENEMY_SPACING * (enemy_count - 1)
		var mid := (enemy_top + enemy_bot) * 0.5
		ENEMY_Y_START = mid - group_height * 0.5
		ENEMY_Y_START_SINGLE = mid

func _build_battle_scene() -> void:
	_compute_layout()

	# Load combined shader (magenta discard + hit flash)
	var shader_path := "res://assets/sprites/battle/hit_flash.gdshader"
	if ResourceLoader.exists(shader_path):
		var shader: Shader = load(shader_path) as Shader
		if shader:
			_sprite_material = ShaderMaterial.new()
			_sprite_material.shader = shader

	# Put ALL battle visuals in a CanvasLayer so they render independent of any camera
	_battle_layer = CanvasLayer.new()
	_battle_layer.layer = 5
	add_child(_battle_layer)

	# Sprite root inside the canvas layer
	_sprite_root = Node2D.new()
	_battle_layer.add_child(_sprite_root)

	# Background
	var bg := ColorRect.new()
	bg.color = Color(0.08, 0.1, 0.18)
	bg.size = _vp_size
	_battle_layer.add_child(bg)
	# Move bg behind sprites
	_battle_layer.move_child(bg, 0)

	# Party sprites (right side)
	for i in range(party.size()):
		var ch: Dictionary = party[i]
		var data: CharacterData = ch.data as CharacterData
		var sprite := Sprite2D.new()

		# Load frame-based animations
		# Use alt idle for Gustave if starting in greatshield stance
		var idle_path: String = data.sprite_idle
		if data.character_name == "Gustave" and gustave_stance == "greatshield":
			idle_path = data.sprite_idle_alt
		var idle_frames: Array = _load_frames_from_folder(idle_path)
		var attack_frames: Array = _load_frames_from_folder(data.sprite_attack)
		# Use alt parry/counter for Gustave if starting in greatshield stance
		var parry_path: String = data.sprite_parry
		var counter_path: String = data.sprite_counter
		if data.character_name == "Gustave" and gustave_stance == "greatshield":
			if data.sprite_parry_alt != "":
				parry_path = data.sprite_parry_alt
			if data.sprite_counter_alt != "":
				counter_path = data.sprite_counter_alt
		var parry_frames: Array = _load_frames_from_folder(parry_path)
		var counter_frames: Array = _load_frames_from_folder(counter_path)
		ch["animations"] = {
			"idle": idle_frames,
			"attack": attack_frames,
			"parry": parry_frames,
			"counter": counter_frames,
		}
		# Set initial texture from first idle frame, or fallback to colored rect
		ch["target_height"] = PARTY_SPRITE_HEIGHT
		if not idle_frames.is_empty():
			sprite.texture = idle_frames[0]
			_apply_sprite_scale(sprite, idle_frames[0], PARTY_SPRITE_HEIGHT)
		else:
			var rect_img := Image.create(40, 60, false, Image.FORMAT_RGBA8)
			rect_img.fill(data.battle_color)
			sprite.texture = ImageTexture.create_from_image(rect_img)
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		if _sprite_material:
			sprite.material = _sprite_material.duplicate()
		sprite.position = Vector2(PARTY_X, PARTY_Y_POSITIONS[i])
		_sprite_root.add_child(sprite)
		ch.sprite = sprite
		party_sprites.append(sprite)

		# Party status effect icon container (above sprite)
		var p_status_container := HBoxContainer.new()
		p_status_container.position = Vector2(sprite.position.x - 25, sprite.position.y - 65)
		p_status_container.size = Vector2(100, 16)
		p_status_container.add_theme_constant_override("separation", 1)
		_sprite_root.add_child(p_status_container)
		_party_status_containers.append(p_status_container)

	# Enemy sprites (left side)
	var enemy_y_start: float = ENEMY_Y_START
	if enemies.size() == 1:
		enemy_y_start = ENEMY_Y_START_SINGLE
	for i in range(enemies.size()):
		var edict: Dictionary = enemies[i]
		var edata: EnemyData = edict.data as EnemyData
		var sprite := Sprite2D.new()

		# Load enemy animations (idle + per-attack-pattern)
		var enemy_idle_frames: Array = _load_frames_from_folder(edata.sprite_idle)
		var attack_anims: Dictionary = {}
		for pattern in edata.attack_patterns:
			var p: AttackPattern = pattern as AttackPattern
			if edata.attack_sprite_map.has(p.pattern_name):
				var folder: String = edata.attack_sprite_map[p.pattern_name]
				attack_anims[p.pattern_name] = _load_frames_from_folder(folder)
		edict["animations"] = {
			"idle": enemy_idle_frames,
			"attack_patterns": attack_anims,
		}

		# Set initial texture: prefer idle frames, fallback to static sprite
		var enemy_target_h: float = ENEMY_SPRITE_BASE_HEIGHT * edata.sprite_scale
		edict["target_height"] = enemy_target_h
		if not enemy_idle_frames.is_empty():
			sprite.texture = enemy_idle_frames[0]
			_apply_sprite_scale(sprite, enemy_idle_frames[0], enemy_target_h)
		else:
			var tex: Texture2D = _load_sprite_texture(edata.sprite_path)
			if tex:
				sprite.texture = tex
				_apply_sprite_scale(sprite, tex, enemy_target_h)
			else:
				var w: int = int(50 * edata.sprite_scale)
				var h: int = int(70 * edata.sprite_scale)
				var rect_img := Image.create(w, h, false, Image.FORMAT_RGBA8)
				rect_img.fill(edata.battle_color)
				sprite.texture = ImageTexture.create_from_image(rect_img)
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		if _sprite_material:
			sprite.material = _sprite_material.duplicate()
		sprite.position = Vector2(ENEMY_X, enemy_y_start + i * ENEMY_SPACING)
		_sprite_root.add_child(sprite)
		edict.sprite = sprite
		enemy_sprites.append(sprite)

		# Enemy HP bar — positioned below sprite to avoid overlap
		var bar_width: float = 120.0
		var bar_x: float = sprite.position.x - bar_width * 0.5
		var sprite_half_h: float = enemy_target_h * 0.5
		var bar_y: float = sprite.position.y + sprite_half_h + 6

		# Layout (top to bottom): HP bar → name + HP text (below sprite)

		# Trail bar (damage trail — distinct orange on dark background)
		var ehp_trail := ProgressBar.new()
		ehp_trail.min_value = 0
		ehp_trail.max_value = edata.max_hp
		ehp_trail.value = edata.max_hp
		ehp_trail.position = Vector2(bar_x, bar_y)
		ehp_trail.size = Vector2(bar_width, 6)
		ehp_trail.show_percentage = false
		var et_bg := StyleBoxFlat.new()
		et_bg.bg_color = Color(0.1, 0.1, 0.15)
		et_bg.set_corner_radius_all(2)
		et_bg.border_color = Color(0.3, 0.3, 0.4)
		et_bg.set_border_width_all(1)
		ehp_trail.add_theme_stylebox_override("background", et_bg)
		var et_fill := StyleBoxFlat.new()
		et_fill.bg_color = Color(0.9, 0.45, 0.1)
		et_fill.set_corner_radius_all(2)
		ehp_trail.add_theme_stylebox_override("fill", et_fill)
		_sprite_root.add_child(ehp_trail)
		_enemy_hp_trail_bars.append(ehp_trail)

		# Main HP bar (bright green on transparent — overlays the trail)
		var ehp_bar := ProgressBar.new()
		ehp_bar.min_value = 0
		ehp_bar.max_value = edata.max_hp
		ehp_bar.value = edata.max_hp
		ehp_bar.position = Vector2(bar_x, bar_y)
		ehp_bar.size = Vector2(bar_width, 6)
		ehp_bar.show_percentage = false
		var ehp_bg := StyleBoxFlat.new()
		ehp_bg.bg_color = Color(0, 0, 0, 0)
		ehp_bg.set_corner_radius_all(2)
		ehp_bar.add_theme_stylebox_override("background", ehp_bg)
		var ehp_fill := StyleBoxFlat.new()
		ehp_fill.bg_color = Color(0.2, 0.85, 0.3)
		ehp_fill.set_corner_radius_all(2)
		ehp_bar.add_theme_stylebox_override("fill", ehp_fill)
		_sprite_root.add_child(ehp_bar)
		_enemy_hp_bars.append(ehp_bar)

		# Name + HP label combined (below bar) — fixed width, centered on sprite
		var lbl_width: float = 160.0
		var ehp_lbl := Label.new()
		ehp_lbl.text = "%s  %d/%d" % [edata.enemy_name, edata.max_hp, edata.max_hp]
		ehp_lbl.add_theme_font_size_override("font_size", 10)
		ehp_lbl.add_theme_color_override("font_color", Color(0.85, 0.85, 0.9))
		ehp_lbl.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
		ehp_lbl.add_theme_constant_override("shadow_offset_x", 1)
		ehp_lbl.add_theme_constant_override("shadow_offset_y", 1)
		ehp_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		ehp_lbl.position = Vector2(sprite.position.x - lbl_width * 0.5, bar_y + 7)
		ehp_lbl.size = Vector2(lbl_width, 16)
		ehp_lbl.clip_text = true
		_sprite_root.add_child(ehp_lbl)
		_enemy_hp_labels.append(ehp_lbl)

		# Status effect icon container (below name)
		var status_container := HBoxContainer.new()
		status_container.position = Vector2(bar_x - 5, bar_y + 23)
		status_container.size = Vector2(bar_width + 10, 14)
		status_container.add_theme_constant_override("separation", 1)
		_sprite_root.add_child(status_container)
		_enemy_status_containers.append(status_container)

	# Turn indicator (gold arrow above active entity)
	_turn_indicator = Polygon2D.new()
	_turn_indicator.polygon = PackedVector2Array([Vector2(-8, 0), Vector2(8, 0), Vector2(0, 10)])
	_turn_indicator.color = Color.GOLD
	_turn_indicator.visible = false
	_turn_indicator.z_index = 10
	_sprite_root.add_child(_turn_indicator)

	# CanvasLayer for HUD (above the battle layer)
	var canvas := CanvasLayer.new()
	canvas.layer = 10
	add_child(canvas)

	# HUD root
	hud_node = Control.new()
	hud_node.set_anchors_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(hud_node)

	# Turn order display (styled top bar)
	var turn_bar_bg := PanelContainer.new()
	turn_bar_bg.position = Vector2(12, 6)
	turn_bar_bg.name = "TurnOrderBar"
	var tb_style := StyleBoxFlat.new()
	tb_style.bg_color = Color(0.05, 0.06, 0.12, 0.8)
	tb_style.border_color = Color(0.25, 0.25, 0.45, 0.5)
	tb_style.set_border_width_all(1)
	tb_style.set_corner_radius_all(4)
	tb_style.content_margin_left = 8
	tb_style.content_margin_right = 8
	tb_style.content_margin_top = 4
	tb_style.content_margin_bottom = 4
	turn_bar_bg.add_theme_stylebox_override("panel", tb_style)
	hud_node.add_child(turn_bar_bg)

	_turn_order_container = HBoxContainer.new()
	_turn_order_container.add_theme_constant_override("separation", 4)
	turn_bar_bg.add_child(_turn_order_container)

	# Party status panel (top, horizontal layout)
	var status_bg := PanelContainer.new()
	status_bg.position = Vector2(STATUS_PANEL_X, STATUS_PANEL_Y)
	status_bg.name = "StatusPanelBG"
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.06, 0.07, 0.14, 0.85)
	panel_style.border_color = Color(0.3, 0.3, 0.5, 0.6)
	panel_style.set_border_width_all(1)
	panel_style.set_corner_radius_all(4)
	panel_style.content_margin_left = 10
	panel_style.content_margin_right = 10
	panel_style.content_margin_top = 6
	panel_style.content_margin_bottom = 6
	status_bg.add_theme_stylebox_override("panel", panel_style)
	hud_node.add_child(status_bg)

	status_panel = HBoxContainer.new()
	status_panel.name = "StatusPanel"
	status_panel.add_theme_constant_override("separation", 10)
	status_bg.add_child(status_panel)
	_build_status_panel()

	# Action text box
	action_text_box = PanelContainer.new()
	action_text_box.name = "ActionTextBox"
	var atb_script: GDScript = load("res://scripts/ui/action_text_box.gd")
	action_text_box.set_script(atb_script)
	hud_node.add_child(action_text_box)

	# Action menu
	action_menu = VBoxContainer.new()
	action_menu.name = "ActionMenu"
	var am_script: GDScript = load("res://scripts/ui/action_menu.gd")
	action_menu.set_script(am_script)
	hud_node.add_child(action_menu)
	action_menu.action_selected.connect(_on_action_selected)
	action_menu.highlight_changed.connect(_on_menu_description)

	# Skill menu
	skill_menu = VBoxContainer.new()
	skill_menu.name = "SkillMenu"
	var sm_script: GDScript = load("res://scripts/ui/skill_menu.gd")
	skill_menu.set_script(sm_script)
	hud_node.add_child(skill_menu)
	skill_menu.skill_selected.connect(_on_skill_selected)
	skill_menu.cancelled.connect(_on_submenu_cancelled)
	skill_menu.highlight_changed.connect(_on_menu_description)

	# Item menu
	item_menu = VBoxContainer.new()
	item_menu.name = "ItemMenu"
	var im_script: GDScript = load("res://scripts/ui/item_menu.gd")
	item_menu.set_script(im_script)
	hud_node.add_child(item_menu)
	item_menu.item_selected.connect(_on_item_selected)
	item_menu.cancelled.connect(_on_submenu_cancelled)
	item_menu.highlight_changed.connect(_on_menu_description)

	# Target selector (in sprite space)
	target_selector = Node2D.new()
	target_selector.name = "TargetSelector"
	var ts_script: GDScript = load("res://scripts/ui/target_selector.gd")
	target_selector.set_script(ts_script)
	_sprite_root.add_child(target_selector)
	target_selector.target_selected.connect(_on_target_selected)
	target_selector.cancelled.connect(_on_target_cancelled)

	# Parry indicator
	parry_indicator = Control.new()
	parry_indicator.name = "ParryIndicator"
	var pi_script: GDScript = load("res://scripts/ui/parry_indicator.gd")
	parry_indicator.set_script(pi_script)
	hud_node.add_child(parry_indicator)

	# Parry system
	parry_system = Node2D.new()
	parry_system.name = "ParrySystem"
	var ps_script: GDScript = load("res://scripts/battle/parry_system.gd")
	parry_system.set_script(ps_script)
	_sprite_root.add_child(parry_system)
	# Battle effects system (shake, damage numbers, hit flash)
	effects = BattleEffects.new()
	effects.name = "BattleEffects"
	add_child(effects)
	effects.setup(_sprite_root, canvas)

	parry_system.setup(parry_indicator, action_text_box, effects)
	parry_system.parry_phase_complete.connect(_on_parry_phase_complete)

func _make_bar(max_val: float, cur_val: float, bar_color: Color, bg_color: Color) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.min_value = 0
	bar.max_value = max_val
	bar.value = cur_val
	bar.custom_minimum_size = Vector2(70, 0)
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	bar.show_percentage = false
	var bg_sb := StyleBoxFlat.new()
	bg_sb.bg_color = bg_color
	bg_sb.set_corner_radius_all(2)
	bg_sb.content_margin_top = 3
	bg_sb.content_margin_bottom = 3
	bg_sb.content_margin_left = 0
	bg_sb.content_margin_right = 0
	bar.add_theme_stylebox_override("background", bg_sb)
	var fill_sb := StyleBoxFlat.new()
	fill_sb.bg_color = bar_color
	fill_sb.set_corner_radius_all(2)
	fill_sb.content_margin_top = 3
	fill_sb.content_margin_bottom = 3
	fill_sb.content_margin_left = 0
	fill_sb.content_margin_right = 0
	bar.add_theme_stylebox_override("fill", fill_sb)
	return bar

func _build_status_panel() -> void:
	_hp_bars.clear()
	_hp_trail_bars.clear()
	_hp_labels.clear()
	_ap_bars.clear()
	_ap_labels.clear()

	for i in range(party.size()):
		var ch: Dictionary = party[i]
		var data: CharacterData = ch.data as CharacterData

		# Per-character vertical column
		var char_col := VBoxContainer.new()
		char_col.add_theme_constant_override("separation", 2)
		char_col.custom_minimum_size = Vector2(130, 0)

		# Character name
		var name_lbl := Label.new()
		name_lbl.text = _get_hud_name(data)
		name_lbl.add_theme_font_size_override("font_size", 11)
		name_lbl.add_theme_color_override("font_color", data.battle_color)
		name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		char_col.add_child(name_lbl)
		ch["status_name_label"] = name_lbl

		# HP row
		var hp_row := HBoxContainer.new()
		hp_row.add_theme_constant_override("separation", 4)

		var hp_tag := Label.new()
		hp_tag.text = "HP"
		hp_tag.add_theme_font_size_override("font_size", 9)
		hp_tag.add_theme_color_override("font_color", Color(0.45, 0.85, 0.45))
		hp_row.add_child(hp_tag)

		# Trail bar (orange, behind green)
		var hp_trail := _make_bar(data.max_hp, ch.current_hp, Color(0.9, 0.3, 0.1), Color(0.15, 0.08, 0.08))
		_hp_trail_bars.append(hp_trail)
		# Stack HP + trail using a MarginContainer so they overlap
		var hp_stack := Control.new()
		hp_stack.custom_minimum_size = Vector2(70, 14)
		hp_stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hp_trail.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		hp_stack.add_child(hp_trail)

		var hp_bar := _make_bar(data.max_hp, ch.current_hp, Color(0.2, 0.8, 0.2), Color(0, 0, 0, 0))
		hp_bar.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		hp_stack.add_child(hp_bar)
		_hp_bars.append(hp_bar)

		hp_row.add_child(hp_stack)

		var hp_lbl := Label.new()
		hp_lbl.text = "%d" % int(ch.current_hp)
		hp_lbl.add_theme_font_size_override("font_size", 9)
		hp_lbl.add_theme_color_override("font_color", Color(0.75, 0.75, 0.75))
		hp_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		hp_lbl.custom_minimum_size = Vector2(28, 0)
		hp_row.add_child(hp_lbl)
		_hp_labels.append(hp_lbl)

		char_col.add_child(hp_row)

		# AP row
		var ap_row := HBoxContainer.new()
		ap_row.add_theme_constant_override("separation", 4)

		var ap_tag := Label.new()
		ap_tag.text = "AP"
		ap_tag.add_theme_font_size_override("font_size", 9)
		ap_tag.add_theme_color_override("font_color", Color(0.45, 0.45, 1.0))
		ap_row.add_child(ap_tag)

		var ap_bar := _make_bar(data.max_ap, ch.current_ap, Color(0.3, 0.4, 0.95), Color(0.1, 0.1, 0.28))
		var ap_stack := Control.new()
		ap_stack.custom_minimum_size = Vector2(70, 14)
		ap_stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		ap_bar.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		ap_stack.add_child(ap_bar)
		_ap_bars.append(ap_bar)

		ap_row.add_child(ap_stack)

		var ap_lbl := Label.new()
		ap_lbl.text = "%d" % int(ch.current_ap)
		ap_lbl.add_theme_font_size_override("font_size", 9)
		ap_lbl.add_theme_color_override("font_color", Color(0.6, 0.6, 1.0))
		ap_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		ap_lbl.custom_minimum_size = Vector2(28, 0)
		ap_row.add_child(ap_lbl)
		_ap_labels.append(ap_lbl)

		char_col.add_child(ap_row)
		status_panel.add_child(char_col)

		# Thin vertical separator between characters
		if i < party.size() - 1:
			var sep := VSeparator.new()
			sep.add_theme_constant_override("separation", 0)
			var sep_style := StyleBoxFlat.new()
			sep_style.bg_color = Color(0.3, 0.3, 0.5, 0.4)
			sep_style.set_content_margin_all(0)
			sep.add_theme_stylebox_override("separator", sep_style)
			status_panel.add_child(sep)

func _update_status_panel() -> void:
	for i in range(party.size()):
		if i >= _hp_bars.size():
			break
		var ch: Dictionary = party[i]
		var data: CharacterData = ch.data as CharacterData
		_hp_bars[i].max_value = data.max_hp
		_hp_bars[i].value = int(ch.current_hp)
		_hp_labels[i].text = "%d" % int(ch.current_hp)
		# Trail bar catches up with a delay
		if i < _hp_trail_bars.size():
			_hp_trail_bars[i].max_value = data.max_hp
			var tween := create_tween()
			tween.tween_property(_hp_trail_bars[i], "value", float(ch.current_hp), 0.5) \
				.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
		_ap_bars[i].max_value = data.max_ap
		_ap_bars[i].value = int(ch.current_ap)
		_ap_labels[i].text = "%d" % int(ch.current_ap)
		# Update status effect icons
		if i < _party_status_containers.size():
			_update_status_icons(_party_status_containers[i], ch)
	_update_enemy_hp_bars()

func _update_enemy_hp_bars() -> void:
	for i in range(enemies.size()):
		if i >= _enemy_hp_bars.size():
			break
		var e: Dictionary = enemies[i]
		var edata: EnemyData = e.data as EnemyData
		_enemy_hp_bars[i].max_value = edata.max_hp
		_enemy_hp_bars[i].value = int(e.current_hp)
		_enemy_hp_labels[i].text = "%s  %d/%d" % [edata.enemy_name, int(e.current_hp), edata.max_hp]
		# Trail catches up
		if i < _enemy_hp_trail_bars.size():
			_enemy_hp_trail_bars[i].max_value = edata.max_hp
			var tween := create_tween()
			tween.tween_property(_enemy_hp_trail_bars[i], "value", float(e.current_hp), 0.5) \
				.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
		# Update status effect icons
		if i < _enemy_status_containers.size():
			_update_status_icons(_enemy_status_containers[i], e)
		# Hide bars for dead enemies
		if int(e.current_hp) <= 0:
			_enemy_hp_bars[i].visible = false
			_enemy_hp_trail_bars[i].visible = false
			_enemy_hp_labels[i].visible = false
			if i < _enemy_status_containers.size():
				_enemy_status_containers[i].visible = false

func _update_turn_order_display() -> void:
	if _turn_order_container == null:
		return

	# Clear previous entries
	for child in _turn_order_container.get_children():
		child.queue_free()

	# Build current turn entry
	var entries: Array[Dictionary] = []
	if current_turn and not current_turn.is_empty():
		var ct_name: String
		var ct_color: Color
		var ct_is_player: bool = current_turn.is_player
		if ct_is_player:
			ct_name = current_turn.entity.data.character_name
			ct_color = current_turn.entity.data.battle_color
		else:
			ct_name = current_turn.entity.data.enemy_name
			ct_color = current_turn.entity.data.battle_color
		entries.append({"name": ct_name, "color": ct_color, "is_player": ct_is_player, "active": true})

	# Remaining turns
	for entry in turn_order.get_order_entries():
		entry["active"] = false
		entries.append(entry)

	for i in entries.size():
		var entry: Dictionary = entries[i]
		var is_active: bool = entry.get("active", false)

		# Add separator arrow between entries
		if i > 0:
			var arrow := Label.new()
			arrow.text = ">"
			arrow.add_theme_font_size_override("font_size", 11)
			arrow.add_theme_color_override("font_color", Color(0.4, 0.4, 0.55))
			_turn_order_container.add_child(arrow)

		# Styled box for each character
		var box := PanelContainer.new()
		var box_style := StyleBoxFlat.new()
		var base_color: Color = entry.color
		if is_active:
			box_style.bg_color = Color(base_color.r * 0.3, base_color.g * 0.3, base_color.b * 0.3, 0.7)
			box_style.border_color = base_color.lightened(0.2)
			box_style.set_border_width_all(1)
		else:
			box_style.bg_color = Color(0.08, 0.08, 0.15, 0.5)
			box_style.border_color = Color(base_color.r * 0.4, base_color.g * 0.4, base_color.b * 0.4, 0.4)
			box_style.set_border_width_all(1)
		box_style.set_corner_radius_all(3)
		box_style.content_margin_left = 6
		box_style.content_margin_right = 6
		box_style.content_margin_top = 2
		box_style.content_margin_bottom = 2
		box.add_theme_stylebox_override("panel", box_style)

		var lbl := Label.new()
		lbl.text = entry.name
		lbl.add_theme_font_size_override("font_size", 11)
		if is_active:
			lbl.add_theme_color_override("font_color", base_color.lightened(0.3))
		else:
			lbl.add_theme_color_override("font_color", Color(base_color.r * 0.7, base_color.g * 0.7, base_color.b * 0.7, 0.8))
		box.add_child(lbl)
		_turn_order_container.add_child(box)

# ── State Machine ────────────────────────────────────────────────────

func _enter_state(new_state: BattleState) -> void:
	state = new_state
	match state:
		BattleState.STARTING:
			_do_starting()
		BattleState.TURN_START:
			_do_turn_start()
		BattleState.PLAYER_SELECT:
			_do_player_select()
		BattleState.ENEMY_TURN_START:
			_do_enemy_turn()
		BattleState.CHECK_DEATH:
			_do_check_death()
		BattleState.VICTORY:
			_do_victory()
		BattleState.DEFEAT:
			_do_defeat()

func _wait_skippable(duration: float) -> void:
	var elapsed: float = 0.0
	while elapsed < duration:
		await get_tree().process_frame
		elapsed += get_process_delta_time()
		if Input.is_action_just_pressed("confirm"):
			break

func _do_starting() -> void:
	var encounter_text := "Enemies appear!"
	if is_boss:
		encounter_text = "A powerful foe blocks your path!"
	action_text_box.display(encounter_text)
	await get_tree().create_timer(1.0).timeout
	turn_order.calculate(party, enemies)
	_enter_state(BattleState.TURN_START)

func _do_turn_start() -> void:
	if turn_order.is_round_over():
		# New round — tick down buffs
		_tick_buffs()
		# Reset defend flags
		for ch in party:
			ch.defending = false
		turn_order.calculate(party, enemies)

	current_turn = turn_order.get_next()
	if current_turn.is_empty():
		return

	# Show turn indicator on active entity
	var active_entity: Dictionary = current_turn.entity
	if active_entity.sprite:
		_show_turn_indicator(active_entity.sprite)

	_update_turn_order_display()
	_update_status_panel()

	# Check for shocked (paralysis) — skip turn
	var entity: Dictionary = current_turn.entity
	if entity.has("buffs") and entity.buffs.has("shocked"):
		var entity_name: String
		if current_turn.is_player:
			entity_name = entity.data.character_name
		else:
			entity_name = entity.data.enemy_name
		action_text_box.display("%s is paralyzed and can't move!" % entity_name)
		if effects and entity.sprite:
			effects.spawn_text_popup(entity.sprite.position, "PARALYZED!", Color(1.0, 1.0, 0.3))
		entity.buffs.erase("shocked")
		await get_tree().create_timer(ACTION_TEXT_DELAY).timeout
		_enter_state(BattleState.TURN_START)
		return

	if current_turn.is_player:
		_enter_state(BattleState.PLAYER_SELECT)
	else:
		_enter_state(BattleState.ENEMY_TURN_START)

func _do_player_select() -> void:
	var ch: Dictionary = current_turn.entity
	if int(ch.current_hp) <= 0:
		_enter_state(BattleState.TURN_START)
		return
	action_text_box.display("%s's turn. Choose an action!" % ch.data.character_name)
	# Wait one frame so any lingering input from previous action doesn't immediately trigger menu
	await get_tree().process_frame
	if state != BattleState.PLAYER_SELECT:
		return
	action_menu.show_menu(ch.data.character_name)

func _on_action_selected(action_type: String) -> void:
	if state != BattleState.PLAYER_SELECT:
		return
	action_menu.hide_menu()
	pending_action = action_type

	match action_type:
		"attack":
			pending_target_type = "single_enemy"
			_show_enemy_targets()
		"skill":
			var ch: Dictionary = current_turn.entity
			var stance: String = gustave_stance if ch.data.character_name == "Gustave" else ""
			skill_menu.show_skills(ch.data.skills, ch.current_ap, stance)
		"item":
			item_menu.show_items(party_state.items)
		"defend":
			_execute_defend()

func _on_skill_selected(skill: Resource) -> void:
	pending_skill = skill as SkillData
	skill_menu.hide_menu()
	pending_target_type = pending_skill.target_type

	match pending_skill.target_type:
		"single_enemy":
			_show_enemy_targets()
		"all_enemies":
			_execute_skill_all_enemies()
		"single_ally":
			_show_ally_targets()
		"all_allies":
			_execute_skill_all_allies()
		"self":
			_execute_skill_self()

func _on_item_selected(item_d: Resource, item_index: int) -> void:
	pending_item_data = item_d as ItemData
	pending_item_index = item_index
	item_menu.hide_menu()

	match pending_item_data.target_type:
		"single_ally":
			_show_ally_targets()
		"all_allies":
			_execute_item_all_allies()

func _on_submenu_cancelled() -> void:
	skill_menu.hide_menu()
	item_menu.hide_menu()
	var ch: Dictionary = current_turn.entity
	action_menu.show_menu(ch.data.character_name)

func _on_menu_description(description: String) -> void:
	if action_text_box:
		action_text_box.display(description)

func _show_enemy_targets() -> void:
	state = BattleState.PLAYER_TARGET
	var targets: Array[Dictionary] = []
	for e in enemies:
		if e.current_hp > 0:
			targets.append({"node": e.sprite, "data": e})
	target_selector.show_targets(targets)

func _show_ally_targets() -> void:
	state = BattleState.PLAYER_TARGET
	var targets: Array[Dictionary] = []
	for p in party:
		if pending_action == "item" and pending_item_data and pending_item_data.effect_type == "revive":
			# Only show dead allies for revive
			if p.current_hp <= 0:
				targets.append({"node": p.sprite, "data": p})
		elif pending_skill and pending_skill.effect_type == "revive":
			if p.current_hp <= 0:
				targets.append({"node": p.sprite, "data": p})
		else:
			if p.current_hp > 0:
				targets.append({"node": p.sprite, "data": p})
	if targets.is_empty():
		action_text_box.display("No valid targets!")
		await get_tree().create_timer(0.5).timeout
		_enter_state(BattleState.PLAYER_SELECT)
		return
	target_selector.show_targets(targets)

func _on_target_selected(index: int) -> void:
	if state != BattleState.PLAYER_TARGET:
		return
	target_selector.hide_selector()
	state = BattleState.PLAYER_EXECUTE

	match pending_action:
		"attack":
			var alive_enemies: Array[Dictionary] = []
			for e in enemies:
				if e.current_hp > 0:
					alive_enemies.append(e)
			if index < alive_enemies.size():
				_execute_attack(alive_enemies[index])
		"skill":
			if pending_target_type == "single_enemy":
				var alive_enemies: Array[Dictionary] = []
				for e in enemies:
					if e.current_hp > 0:
						alive_enemies.append(e)
				if index < alive_enemies.size():
					_execute_skill_single(alive_enemies[index])
			elif pending_target_type == "single_ally":
				var alive_allies: Array[Dictionary] = []
				for p in party:
					if pending_skill and pending_skill.effect_type == "revive":
						if p.current_hp <= 0:
							alive_allies.append(p)
					else:
						if p.current_hp > 0:
							alive_allies.append(p)
				if index < alive_allies.size():
					_execute_skill_single(alive_allies[index])
		"item":
			var valid_allies: Array[Dictionary] = []
			for p in party:
				if pending_item_data and pending_item_data.effect_type == "revive":
					if p.current_hp <= 0:
						valid_allies.append(p)
				else:
					if p.current_hp > 0:
						valid_allies.append(p)
			if index < valid_allies.size():
				_execute_item_single(valid_allies[index])

func _on_target_cancelled() -> void:
	_enter_state(BattleState.PLAYER_SELECT)

# ── Player Actions ───────────────────────────────────────────────────

func _execute_attack(target: Dictionary) -> void:
	var ch: Dictionary = current_turn.entity
	var atk: int = ch.data.attack
	var damage := DamageCalculator.calculate_physical(atk, _get_effective_def(target))
	if ch.has("stance_damage_mult"):
		damage = maxi(1, int(damage * ch.stance_damage_mult))
	target.current_hp = maxi(0, target.current_hp - damage)

	var text := "%s attacks %s for %d damage!" % [ch.data.character_name, target.data.enemy_name, damage]
	action_text_box.display(text)

	var original_pos: Vector2 = ch.sprite.position if ch.sprite else Vector2.ZERO
	var target_pos: Vector2 = target.sprite.position if target.sprite else Vector2(ENEMY_X, 0)
	var is_melee_attacker: bool = ch.data.character_name == "Gustave"
	# Gustave: step close (melee). Mage/Sage: step forward (mid-range) + projectile.
	if effects and ch.sprite:
		Sfx.play("step_forward")
		if is_melee_attacker:
			await effects.step_close(ch.sprite, target_pos)
		else:
			await effects.step_forward(ch.sprite, target_pos.x)
	# Play attack animation
	Sfx.play("sword_swoosh")
	await _play_animation(ch, "attack", 0.5)
	# Ranged basic attack: fire a small projectile
	if not is_melee_attacker and effects and ch.sprite:
		Sfx.play("projectile")
		await effects.play_projectile("proj_orb", ch.sprite.position, target_pos, Color.WHITE, 0.3, 40.0)
	# VFX: slash arc + physical impact
	if effects:
		Sfx.play("slash_arc")
		effects.play_vfx("slash_arc", target_pos, Color.WHITE, 0.3, 60.0)
	# Impact effects
	if effects:
		Sfx.play_random("hit_physical")
		effects.flash_sprite(target.sprite)
		effects.knockback_sprite(target.sprite, 1.0)
		effects.play_vfx("impact_burst", target_pos, Color.WHITE, 0.4, 50.0)
		effects.spawn_damage_number(target_pos, damage)
		effects.add_trauma(0.25)
		await effects.hit_stop(0.06)
	_update_status_panel()
	# Step back
	if effects and ch.sprite:
		await effects.step_back(ch.sprite, original_pos)
	_swap_to_idle_sprite(ch)
	_enter_state(BattleState.CHECK_DEATH)

func _execute_defend() -> void:
	var ch: Dictionary = current_turn.entity
	ch.defending = true
	Sfx.play("defend")
	action_text_box.display("%s takes a defensive stance! Damage reduced this round!" % ch.data.character_name)
	await get_tree().create_timer(ACTION_TEXT_DELAY).timeout
	_enter_state(BattleState.CHECK_DEATH)

func _execute_stance_switch() -> void:
	var ch: Dictionary = current_turn.entity
	var data: CharacterData = ch.data as CharacterData
	var anim_key: String
	if gustave_stance == "greatsword":
		gustave_stance = "greatshield"
		party_state.gustave_stance = "greatshield"
		anim_key = "_stance_to_shield"
		action_text_box.display("Gustave switches to Greatshield Mode! Takes less damage, bigger parry window, but deals less damage!")
		# Swap animations to shield stance
		if ch.has("animations"):
			var shield_idle: Array = _load_frames_from_folder(data.sprite_idle_alt)
			if not shield_idle.is_empty():
				ch.animations.idle = shield_idle
			if data.sprite_parry_alt != "":
				var shield_parry: Array = _load_frames_from_folder(data.sprite_parry_alt)
				if not shield_parry.is_empty():
					ch.animations.parry = shield_parry
			if data.sprite_counter_alt != "":
				var shield_counter: Array = _load_frames_from_folder(data.sprite_counter_alt)
				if not shield_counter.is_empty():
					ch.animations.counter = shield_counter
	else:
		gustave_stance = "greatsword"
		party_state.gustave_stance = "greatsword"
		anim_key = "_stance_to_sword"
		action_text_box.display("Gustave switches to Greatsword Mode! Deals more damage, but takes more damage and shorter parry window!")
		# Swap animations back to sword stance
		if ch.has("animations"):
			var sword_idle: Array = _load_frames_from_folder(data.sprite_idle)
			if not sword_idle.is_empty():
				ch.animations.idle = sword_idle
			var sword_parry: Array = _load_frames_from_folder(data.sprite_parry)
			if not sword_parry.is_empty():
				ch.animations.parry = sword_parry
			var sword_counter: Array = _load_frames_from_folder(data.sprite_counter)
			if not sword_counter.is_empty():
				ch.animations.counter = sword_counter
	_apply_gustave_stance()
	# Update display name label for stance
	if ch.has("status_name_label") and ch.status_name_label != null:
		ch.status_name_label.text = _get_hud_name(data)
	_update_status_panel()
	if gustave_stance == "greatshield":
		Sfx.play("stance_to_shield")  # ascending shimmer — energy expands into shield
	else:
		Sfx.play("stance_to_sword")   # descending shimmer — energy condenses into blade
	await _play_skill_animation(ch, anim_key, 1.0)
	_swap_to_idle_sprite(ch)
	_enter_state(BattleState.CHECK_DEATH)

func _execute_skill_single(target: Dictionary) -> void:
	var ch: Dictionary = current_turn.entity
	var skill: SkillData = pending_skill
	ch.current_ap -= skill.ap_cost

	var text := skill.action_text
	var is_enemy := enemies.has(target)
	var target_pos: Vector2 = target.sprite.position if target.sprite else Vector2.ZERO

	# Step forward for damage skills (close for melee, partial for ranged)
	var original_pos: Vector2 = ch.sprite.position if ch.sprite else Vector2.ZERO
	if skill.effect_type == "damage" and effects and ch.sprite and target.sprite:
		if skill.is_melee:
			Sfx.play("step_forward")
			await effects.step_close(ch.sprite, target.sprite.position)
		else:
			Sfx.play("step_forward")
			await effects.step_forward(ch.sprite, target.sprite.position.x)

	match skill.effect_type:
		"damage":
			var damage: int
			var multiplier: float = 1.0
			if skill.element != "none" and skill.element != "":
				var weakness := ""
				var resistance := ""
				if is_enemy:
					weakness = target.data.element_weakness
					resistance = target.data.element_resistance
				multiplier = ElementChart.get_multiplier(skill.element, weakness, resistance)
				damage = DamageCalculator.calculate_magical(
					ch.data.magic_attack, _get_effective_mdef(target),
					skill.power, skill.element, weakness, resistance)
			else:
				damage = DamageCalculator.calculate_physical(ch.data.attack, _get_effective_def(target), skill.power)
			if ch.has("stance_damage_mult"):
				damage = maxi(1, int(damage * ch.stance_damage_mult))
			target.current_hp = maxi(0, target.current_hp - damage)
			text = text.replace("{target}", target.data.enemy_name if is_enemy else target.data.character_name)
			text = text.replace("{value}", str(damage))
			# Determine damage number color based on element effectiveness
			var dmg_color := Color.WHITE
			var dmg_prefix := ""
			if multiplier >= 1.5:
				dmg_color = Color(1.0, 0.6, 0.1) # orange
				dmg_prefix = "WEAK!"
			elif multiplier <= 0.5:
				dmg_color = Color(0.5, 0.5, 0.7) # blue-gray
				dmg_prefix = "RESIST"
			if effects:
				# Summon VFX for sage skills
				if SUMMON_VFX.has(skill.skill_name):
					var sv: Dictionary = SUMMON_VFX[skill.skill_name]
					var summon_pos: Vector2 = ch.sprite.position + Vector2(0, -40) if ch.sprite else Vector2.ZERO
					Sfx.play("summon")
					effects.play_vfx(sv.vfx, summon_pos, sv.tint, 0.8, 100.0)
				# Play element/skill-specific cast SFX
				var _elem_for_sfx: String = skill.element if skill.element != "" else "none"
				if _elem_for_sfx != "none":
					Sfx.play_element_cast(_elem_for_sfx)
				elif skill.skill_name == "Aegis Beam":
					Sfx.play("shield_bash")
				elif skill.skill_name == "Bulwark":
					Sfx.play("shield_slam")
				elif ch.data.character_name == "Gustave":
					Sfx.play("heavy_swoosh")
				else:
					Sfx.play("spell_cast")
				await _play_skill_animation(ch, skill.skill_name, 0.8)
				# Projectile VFX for elemental skills
				var elem: String = skill.element if skill.element != "" else "none"
				var vfx_info: Dictionary = SKILL_VFX_OVERRIDE.get(skill.skill_name, ELEMENT_VFX.get(elem, {}))
				var proj_name: String = vfx_info.get("proj", "")
				var vfx_tint: Color = vfx_info.get("tint", Color.WHITE)
				if proj_name != "" and ch.sprite:
					Sfx.play("projectile")
					if proj_name == "eruption":
						# Eruption plays at target position (from below)
						effects.play_vfx(proj_name, target_pos + Vector2(0, 20), vfx_tint, 0.5, 90.0)
						await get_tree().create_timer(0.25).timeout
					else:
						await effects.play_projectile(proj_name, ch.sprite.position, target_pos, vfx_tint, 0.4, 60.0)
				Sfx.play_element_impact(elem)
				effects.flash_sprite(target.sprite)
				effects.knockback_sprite(target.sprite, 1.0 if is_enemy else -1.0)
				# Impact burst
				var impact_tint: Color = ELEMENT_VFX.get(elem, {}).get("tint", Color.WHITE)
				effects.play_vfx("impact_burst", target_pos, impact_tint, 0.4, 50.0)
				effects.spawn_damage_number(target_pos, damage, dmg_color, dmg_prefix, multiplier >= 1.5)
				effects.add_trauma(0.3)
				await effects.hit_stop(0.07)
			# Apply status effect
			_apply_status_effect(skill, target)
		"heal":
			var heal_amount := DamageCalculator.calculate_heal(ch.data.magic_attack, skill.power)
			target.current_hp = mini(target.current_hp + heal_amount, target.data.max_hp)
			text = text.replace("{target}", target.data.character_name)
			text = text.replace("{value}", str(heal_amount))
			# Summon VFX (Phoenix)
			if effects and SUMMON_VFX.has(skill.skill_name):
				var sv: Dictionary = SUMMON_VFX[skill.skill_name]
				var summon_pos: Vector2 = ch.sprite.position + Vector2(0, -40) if ch.sprite else Vector2.ZERO
				Sfx.play("summon")
				effects.play_vfx(sv.vfx, summon_pos, sv.tint, 0.8, 100.0)
			await _play_skill_animation(ch, skill.skill_name, 1.0)
			Sfx.play("heal")
			if effects:
				effects.play_vfx("heal_shimmer", target_pos, Color(0.3, 1.0, 0.5), 0.7, 80.0)
				effects.spawn_damage_number(target_pos, heal_amount, Color.GREEN)
		"revive":
			var revive_hp: int = int(target.data.max_hp * 0.3)
			target.current_hp = revive_hp
			text = text.replace("{target}", target.data.character_name)
			if effects and SUMMON_VFX.has(skill.skill_name):
				var sv: Dictionary = SUMMON_VFX[skill.skill_name]
				var summon_pos: Vector2 = ch.sprite.position + Vector2(0, -40) if ch.sprite else Vector2.ZERO
				Sfx.play("summon")
				effects.play_vfx(sv.vfx, summon_pos, sv.tint, 0.8, 100.0)
			await _play_skill_animation(ch, skill.skill_name, 1.0)
			Sfx.play("heal")
			if effects:
				effects.play_vfx("heal_shimmer", target_pos, Color(1.0, 0.85, 0.3), 0.7, 80.0)
				effects.spawn_text_popup(target_pos, "REVIVE!", Color.GOLD)
		"debuff_def":
			if not target.has("buffs"):
				target["buffs"] = {}
			target.buffs["debuff_def"] = skill.buff_duration
			text = text.replace("{target}", target.data.enemy_name if is_enemy else target.data.character_name)
			if effects and SUMMON_VFX.has(skill.skill_name):
				var sv: Dictionary = SUMMON_VFX[skill.skill_name]
				var summon_pos: Vector2 = ch.sprite.position + Vector2(0, -40) if ch.sprite else Vector2.ZERO
				Sfx.play("summon")
				effects.play_vfx(sv.vfx, summon_pos, sv.tint, 0.8, 100.0)
			await _play_skill_animation(ch, skill.skill_name, 1.0)
			Sfx.play("buff_apply")
			if effects:
				effects.start_aura(target.sprite, "aura_buff", BUFF_AURA_TINT["debuff_def"])
				effects.spawn_text_popup(target_pos, "DEF DOWN!", Color(1.0, 0.3, 0.3))

	text = text.replace("{user}", ch.data.character_name)
	text = text.replace("{skill}", skill.skill_name)
	action_text_box.display(text)
	_update_status_panel()
	# Step back for damage skills
	if skill.effect_type == "damage" and effects and ch.sprite:
		await effects.step_back(ch.sprite, original_pos)
	_swap_to_idle_sprite(ch)
	_enter_state(BattleState.CHECK_DEATH)

func _execute_skill_all_enemies() -> void:
	var ch: Dictionary = current_turn.entity
	var skill: SkillData = pending_skill
	ch.current_ap -= skill.ap_cost
	state = BattleState.PLAYER_EXECUTE

	# Step close for melee AoE (e.g. Whirlwind) — move to center of enemy group
	var _aoe_original_pos: Vector2 = ch.sprite.position if ch.sprite else Vector2.ZERO
	if skill.is_melee and effects and ch.sprite:
		# Compute center Y of alive enemies
		var center_y := _vp_size.y * 0.463
		var alive_count := 0
		var sum_y := 0.0
		for e in enemies:
			if e.current_hp > 0 and e.sprite:
				sum_y += e.sprite.position.y
				alive_count += 1
		if alive_count > 0:
			center_y = sum_y / float(alive_count)
		Sfx.play("step_forward")
		await effects.step_close(ch.sprite, Vector2(ENEMY_X, center_y))

	# Summon VFX for sage skills (Thunderbird, etc.)
	if effects and SUMMON_VFX.has(skill.skill_name):
		var sv: Dictionary = SUMMON_VFX[skill.skill_name]
		var summon_pos: Vector2 = ch.sprite.position + Vector2(0, -40) if ch.sprite else Vector2.ZERO
		Sfx.play("summon")
		effects.play_vfx(sv.vfx, summon_pos, sv.tint, 0.8, 100.0)

	# Play element/skill-specific cast SFX
	var _aoe_elem: String = skill.element if skill.element != "" else "none"
	if _aoe_elem != "none":
		Sfx.play_element_cast(_aoe_elem)
	elif skill.skill_name == "Bulwark":
		Sfx.play("shield_slam")
	elif ch.data.character_name == "Gustave":
		Sfx.play("heavy_swoosh")
	else:
		Sfx.play("spell_cast")
	await _play_skill_animation(ch, skill.skill_name, 0.9)

	# AOE wave VFX across enemy area
	var elem: String = skill.element if skill.element != "" else "none"
	var vfx_info: Dictionary = SKILL_VFX_OVERRIDE.get(skill.skill_name, ELEMENT_VFX.get(elem, {}))
	var aoe_proj: String = vfx_info.get("proj", "")
	var vfx_tint: Color = vfx_info.get("tint", Color.WHITE)
	if effects and aoe_proj != "":
		var aoe_center := Vector2(ENEMY_X, _vp_size.y * 0.463)
		effects.play_vfx(aoe_proj, aoe_center, vfx_tint, 0.5, 120.0)
		await get_tree().create_timer(0.2).timeout

	Sfx.play_element_impact(elem)
	var total_damage := 0
	for e in enemies:
		if e.current_hp <= 0:
			continue
		var damage: int
		var multiplier: float = 1.0
		if skill.element != "none":
			multiplier = ElementChart.get_multiplier(skill.element, e.data.element_weakness, e.data.element_resistance)
			damage = DamageCalculator.calculate_magical(
				ch.data.magic_attack, _get_effective_mdef(e),
				skill.power, skill.element, e.data.element_weakness, e.data.element_resistance)
		else:
			damage = DamageCalculator.calculate_physical(ch.data.attack, _get_effective_def(e), skill.power)
		if ch.has("stance_damage_mult"):
			damage = maxi(1, int(damage * ch.stance_damage_mult))
		e.current_hp = maxi(0, e.current_hp - damage)
		total_damage += damage
		if effects:
			effects.flash_sprite(e.sprite)
			effects.knockback_sprite(e.sprite)
			var dmg_color := Color.WHITE
			var dmg_prefix := ""
			if multiplier >= 1.5:
				dmg_color = Color(1.0, 0.6, 0.1)
				dmg_prefix = "WEAK!"
			elif multiplier <= 0.5:
				dmg_color = Color(0.5, 0.5, 0.7)
				dmg_prefix = "RESIST"
			var e_pos: Vector2 = e.sprite.position if e.sprite else Vector2.ZERO
			var impact_tint: Color = ELEMENT_VFX.get(elem, {}).get("tint", Color.WHITE)
			effects.play_vfx("impact_burst", e_pos, impact_tint, 0.35, 50.0)
			effects.spawn_damage_number(e_pos, damage, dmg_color, dmg_prefix, multiplier >= 1.5)
		# Apply status effect
		_apply_status_effect(skill, e)

	if effects:
		effects.add_trauma(0.4)
		await effects.hit_stop(0.08)

	var text := skill.action_text.replace("{value}", str(total_damage))
	text = text.replace("{user}", ch.data.character_name)
	action_text_box.display(text)
	_update_status_panel()
	# Step back for melee AoE
	if skill.is_melee and effects and ch.sprite:
		await effects.step_back(ch.sprite, _aoe_original_pos)
	_swap_to_idle_sprite(ch)
	_enter_state(BattleState.CHECK_DEATH)

func _execute_skill_all_allies() -> void:
	var ch: Dictionary = current_turn.entity
	var skill: SkillData = pending_skill
	ch.current_ap -= skill.ap_cost
	state = BattleState.PLAYER_EXECUTE

	var buff_label := {"buff_spd": "SPD UP!", "buff_def": "DEF UP!", "buff_atk": "ATK UP!"}
	match skill.effect_type:
		"buff_spd", "buff_def", "buff_atk":
			for p in party:
				if p.current_hp > 0:
					if not p.has("buffs"):
						p["buffs"] = {}
					p.buffs[skill.effect_type] = skill.buff_duration
	var text := skill.action_text.replace("{user}", ch.data.character_name)
	action_text_box.display(text)
	_update_status_panel()
	# Summon VFX (Griffin, Golem)
	if effects and SUMMON_VFX.has(skill.skill_name):
		var sv: Dictionary = SUMMON_VFX[skill.skill_name]
		var summon_pos: Vector2 = ch.sprite.position + Vector2(0, -40) if ch.sprite else Vector2.ZERO
		Sfx.play("summon")
		effects.play_vfx(sv.vfx, summon_pos, sv.tint, 0.8, 100.0)
	Sfx.play("buff_apply")
	await _play_skill_animation(ch, skill.skill_name, 1.2)
	# Show buff popup + start aura on each buffed party member
	if effects and buff_label.has(skill.effect_type):
		var aura_tint: Color = BUFF_AURA_TINT.get(skill.effect_type, Color.WHITE)
		for p in party:
			if p.current_hp > 0 and p.sprite:
				effects.spawn_text_popup(p.sprite.position, buff_label[skill.effect_type], Color(0.3, 0.8, 1.0))
				effects.start_aura(p.sprite, "aura_buff", aura_tint)
	_swap_to_idle_sprite(ch)
	_enter_state(BattleState.CHECK_DEATH)

func _execute_skill_self() -> void:
	var ch: Dictionary = current_turn.entity
	var skill: SkillData = pending_skill
	ch.current_ap -= skill.ap_cost
	state = BattleState.PLAYER_EXECUTE

	match skill.effect_type:
		"stance_switch":
			await _execute_stance_switch()
			return
		"taunt":
			if not ch.has("buffs"):
				ch["buffs"] = {}
			ch.buffs["taunt"] = skill.buff_duration

	var text := skill.action_text.replace("{user}", ch.data.character_name)
	action_text_box.display(text)
	_update_status_panel()
	Sfx.play_random("taunt")
	await _play_skill_animation(ch, skill.skill_name, 1.2)
	if effects and ch.sprite:
		effects.spawn_text_popup(ch.sprite.position, "TAUNT!", Color(1.0, 0.6, 0.0))
		effects.start_aura(ch.sprite, "aura_buff", BUFF_AURA_TINT["taunt"])
	_swap_to_idle_sprite(ch)
	_enter_state(BattleState.CHECK_DEATH)

func _execute_item_single(target: Dictionary) -> void:
	var ch: Dictionary = current_turn.entity
	var item: ItemData = pending_item_data
	state = BattleState.PLAYER_EXECUTE
	var target_pos: Vector2 = target.sprite.position if target.sprite else Vector2.ZERO

	# Consume item
	for item_entry in party_state.items:
		if item_entry.data == item or item_entry.data.item_name == item.item_name:
			item_entry.quantity -= 1
			break

	Sfx.play_ui("item_use")
	match item.effect_type:
		"heal_hp":
			target.current_hp = mini(target.current_hp + item.value, target.data.max_hp)
			Sfx.play("heal")
			if effects:
				effects.play_vfx("heal_shimmer", target_pos, Color(0.3, 1.0, 0.5), 0.6, 70.0)
				effects.spawn_damage_number(target_pos, item.value, Color.GREEN)
		"heal_ap":
			target.current_ap = mini(target.current_ap + item.value, target.data.max_ap)
			Sfx.play("ap_gain")
			if effects:
				effects.play_vfx("heal_shimmer", target_pos, Color(0.3, 0.6, 1.0), 0.6, 70.0)
				effects.spawn_damage_number(target_pos, item.value, Color.CYAN)
		"revive":
			var revive_hp: int = int(target.data.max_hp * item.value / 100.0)
			target.current_hp = revive_hp
			Sfx.play("heal")
			if effects:
				effects.play_vfx("heal_shimmer", target_pos, Color(1.0, 0.85, 0.3), 0.7, 80.0)
				effects.spawn_text_popup(target_pos, "REVIVE!", Color.GOLD)

	var text := item.action_text
	text = text.replace("{user}", ch.data.character_name)
	text = text.replace("{target}", target.data.character_name)
	text = text.replace("{item}", item.item_name)
	text = text.replace("{value}", str(item.value))
	action_text_box.display(text)
	_update_status_panel()
	await get_tree().create_timer(ACTION_TEXT_DELAY).timeout
	_enter_state(BattleState.CHECK_DEATH)

func _execute_item_all_allies() -> void:
	# Currently no all-ally items but structure is here
	_enter_state(BattleState.CHECK_DEATH)

# ── Enemy Turn ───────────────────────────────────────────────────────

func _do_enemy_turn() -> void:
	var enemy: Dictionary = current_turn.entity
	if enemy.current_hp <= 0:
		_enter_state(BattleState.TURN_START)
		return

	var action := BattleAI.choose_action(enemy, party)
	var pattern: AttackPattern = action.pattern
	var target: Dictionary = action.target

	if pattern == null or target.is_empty():
		_enter_state(BattleState.TURN_START)
		return

	state = BattleState.PARRY_PHASE

	# Calculate parry bonus
	var bonus := 0.0
	if target.data.character_name == "Gustave" and gustave_stance == "greatshield":
		bonus = 0.15

	if pattern.is_team_attack:
		await _execute_team_attack(enemy, pattern)
	elif pattern.is_aoe:
		await _execute_aoe_attack(enemy, pattern)
	else:
		parry_system.start_phase(enemy, target, pattern, bonus)

func _execute_aoe_attack(enemy: Dictionary, pattern: AttackPattern) -> void:
	action_text_box.display("%s unleashes %s on the entire party!" % [enemy.data.enemy_name, pattern.pattern_name])
	Sfx.play("impact_heavy")
	await get_tree().create_timer(0.8).timeout

	# Disconnect normal handler during sequential parry phases
	if parry_system.parry_phase_complete.is_connected(_on_parry_phase_complete):
		parry_system.parry_phase_complete.disconnect(_on_parry_phase_complete)

	for p in party:
		if p.current_hp <= 0:
			continue
		var bonus := 0.0
		if p.data.character_name == "Gustave" and gustave_stance == "greatshield":
			bonus = 0.15
		# Create a single-hit pattern for each target
		var single_pattern := AttackPattern.new()
		single_pattern.pattern_name = pattern.pattern_name
		single_pattern.hits = [{"delay": 0.5, "window": 0.3, "damage_pct": 0.8}]
		single_pattern.action_text = "%s strikes at {target}!" % enemy.data.enemy_name
		single_pattern.is_aoe = false
		single_pattern.is_melee = pattern.is_melee

		parry_system.start_phase(enemy, p, single_pattern, bonus)
		var phase_result: Dictionary = await parry_system.parry_phase_complete

		# Handle counterattack for this target
		if phase_result.get("all_parried", false):
			var counter_dmg := DamageCalculator.calculate_physical(p.data.attack, enemy.data.defense, COUNTER_POWER)
			enemy.current_hp = maxi(0, enemy.current_hp - counter_dmg)
			action_text_box.display("%s counters for %d damage!" % [p.data.character_name, counter_dmg])
			var counter_origin: Vector2 = p.sprite.position if p.sprite else Vector2.ZERO
			var enemy_pos := Vector2.ZERO
			if enemy.sprite and is_instance_valid(enemy.sprite):
				enemy_pos = enemy.sprite.position
			# Gustave lunges to enemy for melee counter
			if p.data.character_name == "Gustave" and effects and p.sprite:
				Sfx.play("step_forward")
				await effects.step_close(p.sprite, enemy_pos)
			if p.data.character_name == "Gustave":
				Sfx.play("heavy_swoosh")
			else:
				Sfx.play("spell_cast")
			await _play_animation(p, "counter", 0.6)
			if effects:
				if p.data.character_name == "Gustave":
					Sfx.play("counter_hit_physical")
				else:
					Sfx.play("counter_magic")
				effects.play_vfx("slash_arc", enemy_pos, Color.YELLOW, 0.25, 55.0)
				effects.flash_sprite(enemy.sprite)
				effects.knockback_sprite(enemy.sprite, -1.0)
				effects.play_vfx("impact_burst", enemy_pos, Color.YELLOW, 0.35, 45.0)
				effects.spawn_damage_number(enemy_pos, counter_dmg, Color.YELLOW, "", true)
				effects.add_trauma(0.35)
				await effects.hit_stop(0.08)
			# Step back for Gustave
			if p.data.character_name == "Gustave" and effects and p.sprite:
				await effects.step_back(p.sprite, counter_origin)
			_swap_to_idle_sprite(p)
			await get_tree().create_timer(0.4).timeout

	# Reconnect the normal handler
	if not parry_system.parry_phase_complete.is_connected(_on_parry_phase_complete):
		parry_system.parry_phase_complete.connect(_on_parry_phase_complete)

	_update_status_panel()
	_enter_state(BattleState.CHECK_DEATH)

func _execute_team_attack(enemy: Dictionary, pattern: AttackPattern) -> void:
	action_text_box.display("%s targets the whole party with %s!" % [enemy.data.enemy_name, pattern.pattern_name])
	await get_tree().create_timer(0.8).timeout

	# Disconnect normal handler during sequential parry phases
	if parry_system.parry_phase_complete.is_connected(_on_parry_phase_complete):
		parry_system.parry_phase_complete.disconnect(_on_parry_phase_complete)

	var all_hits_parried := true
	var real_hits_processed := 0
	var alive_party: Array[Dictionary] = []
	for p in party:
		if p.current_hp > 0:
			alive_party.append(p)

	# Each hit targets a random alive party member
	for hit_idx in range(pattern.hits.size()):
		var hit: Dictionary = pattern.hits[hit_idx]
		if alive_party.is_empty():
			break

		# Pick random target for this hit
		var target: Dictionary = alive_party.pick_random()

		# Skip feints
		if hit.get("window", 0.3) <= 0.0:
			var feint_pattern := AttackPattern.new()
			feint_pattern.pattern_name = pattern.pattern_name
			feint_pattern.hits = [hit]
			feint_pattern.action_text = "%s feints at {target}!" % enemy.data.enemy_name
			feint_pattern.is_melee = pattern.is_melee

			var bonus := 0.0
			if target.data.character_name == "Gustave" and gustave_stance == "greatshield":
				bonus = 0.15
			parry_system.start_phase(enemy, target, feint_pattern, bonus)
			await parry_system.parry_phase_complete
			continue

		# Create a single-hit pattern for this hit
		var single_pattern := AttackPattern.new()
		single_pattern.pattern_name = pattern.pattern_name
		single_pattern.hits = [hit]
		single_pattern.action_text = "%s strikes at {target}!" % enemy.data.enemy_name
		single_pattern.is_melee = pattern.is_melee

		var bonus := 0.0
		if target.data.character_name == "Gustave" and gustave_stance == "greatshield":
			bonus = 0.15
		parry_system.start_phase(enemy, target, single_pattern, bonus)
		var phase_result: Dictionary = await parry_system.parry_phase_complete

		real_hits_processed += 1
		if not phase_result.get("all_parried", false):
			all_hits_parried = false

		# Refresh alive list in case someone died
		alive_party.clear()
		for p in party:
			if p.current_hp > 0:
				alive_party.append(p)

	# Full team counter only if ALL real hits were processed and parried
	var expected_real_hits := total_hits_in_pattern(pattern)
	if all_hits_parried and real_hits_processed == expected_real_hits and expected_real_hits > 0:
		action_text_box.display("Full Party Parry! The whole team counterattacks!")
		if effects:
			effects.add_trauma(0.15)
		await get_tree().create_timer(0.5).timeout

		# Calculate all damage upfront
		var total_counter_dmg := 0
		var alive_counters: Array[Dictionary] = []
		for p in party:
			if p.current_hp <= 0:
				continue
			var counter_dmg := DamageCalculator.calculate_physical(p.data.attack, enemy.data.defense, COUNTER_POWER)
			enemy.current_hp = maxi(0, enemy.current_hp - counter_dmg)
			total_counter_dmg += counter_dmg
			alive_counters.append({"entity": p, "damage": counter_dmg})

		# Gustave lunges to enemy for melee counter
		var enemy_pos := Vector2.ZERO
		if enemy.sprite and is_instance_valid(enemy.sprite):
			enemy_pos = enemy.sprite.position
		var _gustave_counter_origin := Vector2.ZERO
		for entry in alive_counters:
			var p: Dictionary = entry.entity
			if p.data.character_name == "Gustave" and effects and p.sprite:
				_gustave_counter_origin = p.sprite.position
				Sfx.play("step_forward")
				await effects.step_close(p.sprite, enemy_pos)
				break

		# Play ALL counter animations simultaneously
		for entry in alive_counters:
			var p: Dictionary = entry.entity
			if p.data.character_name == "Gustave":
				Sfx.play("heavy_swoosh")
			else:
				Sfx.play("spell_cast")
			_play_animation(p, "counter", 0.5)  # fire-and-forget (no await)
		await get_tree().create_timer(0.5).timeout  # wait for animations to finish

		# One big simultaneous impact
		if effects:
			for entry in alive_counters:
				var p: Dictionary = entry.entity
				if p.data.character_name == "Gustave":
					Sfx.play("counter_hit_physical")
				else:
					Sfx.play("counter_magic")
				effects.spawn_damage_number(
					enemy_pos + Vector2(randf_range(-25, 25), randf_range(-20, 20)),
					entry.damage, Color.YELLOW, "", true)
			effects.play_vfx("slash_arc", enemy_pos, Color.YELLOW, 0.25, 65.0)
			effects.flash_sprite(enemy.sprite)
			effects.knockback_sprite(enemy.sprite, -1.0, 25.0)
			effects.play_vfx("impact_burst", enemy_pos, Color.YELLOW, 0.4, 55.0)
			effects.add_trauma(0.5)
			await effects.hit_stop(0.12)

		# Step Gustave back
		for entry in alive_counters:
			var p: Dictionary = entry.entity
			if p.data.character_name == "Gustave" and effects and p.sprite and _gustave_counter_origin != Vector2.ZERO:
				await effects.step_back(p.sprite, _gustave_counter_origin)
				break

		action_text_box.display("The party deals %d total damage!" % total_counter_dmg)
		for entry in alive_counters:
			_swap_to_idle_sprite(entry.entity)

	# Always reconnect normal handler
	if not parry_system.parry_phase_complete.is_connected(_on_parry_phase_complete):
		parry_system.parry_phase_complete.connect(_on_parry_phase_complete)

	_update_status_panel()
	_enter_state(BattleState.CHECK_DEATH)

func total_hits_in_pattern(pattern: AttackPattern) -> int:
	var count := 0
	for hit in pattern.hits:
		if hit.get("window", 0.3) > 0.0:
			count += 1
	return count

func _on_parry_phase_complete(result: Dictionary) -> void:
	if state != BattleState.PARRY_PHASE:
		return

	# Counterattack if all hits were parried
	if result.get("all_parried", false):
		var ch: Dictionary = parry_system.target_character
		if not ch.is_empty():
			var enemy: Dictionary = current_turn.entity
			var counter_dmg := DamageCalculator.calculate_physical(ch.data.attack, enemy.data.defense, COUNTER_POWER)
			enemy.current_hp = maxi(0, enemy.current_hp - counter_dmg)
			action_text_box.display("Full Parry! %s counters for %d damage!" % [ch.data.character_name, counter_dmg])
			var counter_origin: Vector2 = ch.sprite.position if ch.sprite else Vector2.ZERO
			var enemy_pos := Vector2.ZERO
			if enemy.sprite and is_instance_valid(enemy.sprite):
				enemy_pos = enemy.sprite.position
			# Gustave lunges to enemy for melee counter
			if ch.data.character_name == "Gustave" and effects and ch.sprite:
				Sfx.play("step_forward")
				await effects.step_close(ch.sprite, enemy_pos)
			# Character-specific counter SFX
			if ch.data.character_name == "Gustave":
				Sfx.play("heavy_swoosh")
			else:
				Sfx.play("spell_cast")
			await _play_animation(ch, "counter", 0.6)
			if effects:
				if ch.data.character_name == "Gustave":
					Sfx.play("counter_hit_physical")
				else:
					Sfx.play("counter_magic")
				effects.play_vfx("slash_arc", enemy_pos, Color.YELLOW, 0.25, 55.0)
				effects.flash_sprite(enemy.sprite)
				effects.knockback_sprite(enemy.sprite, -1.0)
				effects.play_vfx("impact_burst", enemy_pos, Color.YELLOW, 0.35, 45.0)
				effects.spawn_damage_number(enemy_pos, counter_dmg, Color.YELLOW, "", true)
				effects.add_trauma(0.4)
				await effects.hit_stop(0.1)
			# Step Gustave back
			if ch.data.character_name == "Gustave" and effects and ch.sprite:
				await effects.step_back(ch.sprite, counter_origin)
			_swap_to_idle_sprite(ch)
			await get_tree().create_timer(0.4).timeout

	_update_status_panel()
	_enter_state(BattleState.CHECK_DEATH)

# ── Death Check ──────────────────────────────────────────────────────

func _do_check_death() -> void:
	# Check enemy deaths
	for e in enemies:
		if e.current_hp <= 0 and e.sprite and e.sprite.visible:
			action_text_box.display("%s is defeated!" % e.data.enemy_name)
			Sfx.play("enemy_death")
			if effects:
				await effects.play_enemy_death(e.sprite)
			else:
				e.sprite.visible = false
				await get_tree().create_timer(0.6).timeout

	# Check party deaths
	for p in party:
		if p.current_hp <= 0 and p.sprite and p.sprite.modulate.a > 0.3:
			action_text_box.display("%s falls in battle!" % p.data.character_name)
			Sfx.play("party_death")
			if effects:
				await effects.play_party_death(p.sprite)
			else:
				p.sprite.modulate = Color(1, 1, 1, 0.2)
				await get_tree().create_timer(0.6).timeout

	# Victory check
	var all_enemies_dead := true
	for e in enemies:
		if e.current_hp > 0:
			all_enemies_dead = false
			break
	if all_enemies_dead:
		_enter_state(BattleState.VICTORY)
		return

	# Defeat check
	var all_party_dead := true
	for p in party:
		if p.current_hp > 0:
			all_party_dead = false
			break
	if all_party_dead:
		_enter_state(BattleState.DEFEAT)
		return

	_enter_state(BattleState.TURN_START)

# ── Victory / Defeat ────────────────────────────────────────────────

func _do_victory() -> void:
	_hide_turn_indicator()
	if effects:
		effects.stop_all_auras()
	action_text_box.display("Victory!")
	Sfx.play_ui("victory")
	await get_tree().create_timer(1.0).timeout

	# Calculate XP
	var total_xp := 0
	for e in enemies:
		total_xp += e.data.xp_reward

	Sfx.play_ui("xp_gain")
	action_text_box.display("Gained %d experience points!" % total_xp)
	await get_tree().create_timer(ACTION_TEXT_DELAY).timeout

	# Apply XP and show level ups
	var level_msgs := party_state.add_xp(total_xp)
	for msg in level_msgs:
		action_text_box.display(msg)
		await get_tree().create_timer(ACTION_TEXT_DELAY).timeout

	# Sync battle state back and fully heal party for next encounter
	_sync_to_party_state()
	party_state.heal_party_full()

	await get_tree().create_timer(0.5).timeout
	battle_finished.emit("victory")

func _do_defeat() -> void:
	_hide_turn_indicator()
	if effects:
		effects.stop_all_auras()
	action_text_box.display("The party has been defeated...")
	Sfx.play_ui("defeat")
	await get_tree().create_timer(2.0).timeout
	battle_finished.emit("defeat")

# ── Turn Indicator ───────────────────────────────────────────────────

func _show_turn_indicator(sprite: Sprite2D) -> void:
	if _turn_indicator == null or sprite == null:
		return
	_turn_indicator.visible = true
	var sprite_top: float = sprite.position.y - (sprite.texture.get_height() * sprite.scale.y * 0.5)
	var above_y: float = sprite_top - 12
	_turn_indicator.position = Vector2(sprite.position.x, above_y)
	if _turn_indicator_tween:
		_turn_indicator_tween.kill()
	_turn_indicator_tween = create_tween().set_loops()
	_turn_indicator_tween.tween_property(_turn_indicator, "position:y", above_y - 6, 0.4) \
		.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	_turn_indicator_tween.tween_property(_turn_indicator, "position:y", above_y, 0.4) \
		.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)

func _hide_turn_indicator() -> void:
	if _turn_indicator == null:
		return
	_turn_indicator.visible = false
	if _turn_indicator_tween:
		_turn_indicator_tween.kill()
		_turn_indicator_tween = null

# ── Helpers ──────────────────────────────────────────────────────────

func _get_display_name(data: CharacterData) -> String:
	if data.character_name == "Gustave":
		if gustave_stance == "greatshield":
			return "Gustave Greatshield"
		return "Gustave Greatsword"
	return data.character_name

func _get_hud_name(data: CharacterData) -> String:
	if data.character_name == "Gustave":
		if gustave_stance == "greatshield":
			return "Gustave (Shield)"
		return "Gustave (Sword)"
	return data.character_name

func _apply_gustave_stance() -> void:
	var gustave: Dictionary = {}
	for ch in party:
		if ch.data.character_name == "Gustave":
			gustave = ch
			break
	if gustave.is_empty():
		return
	if gustave_stance == "greatshield":
		gustave.data.parry_window_bonus = 0.15
		gustave["stance_damage_mult"] = 0.7
		gustave["stance_damage_taken_mult"] = 0.75
	else:
		gustave.data.parry_window_bonus = 0.0
		gustave["stance_damage_mult"] = 1.3
		gustave["stance_damage_taken_mult"] = 1.2

func _tick_buffs() -> void:
	# Tick DoT (ablaze) on all entities before decrementing durations
	for ch in party:
		if ch.has("buffs") and ch.buffs.has("ablaze") and int(ch.current_hp) > 0:
			var dot_dmg := maxi(1, int(ch.data.max_hp * 0.05))
			ch.current_hp = maxi(0, int(ch.current_hp) - dot_dmg)
			Sfx.play("burn_tick", -6.0)
			if effects and ch.sprite:
				effects.spawn_damage_number(ch.sprite.position, dot_dmg, Color(1.0, 0.4, 0.1), "BURN")
	for e in enemies:
		if e.has("buffs") and e.buffs.has("ablaze") and int(e.current_hp) > 0:
			var dot_dmg := maxi(1, int(e.data.max_hp * 0.05))
			e.current_hp = maxi(0, int(e.current_hp) - dot_dmg)
			Sfx.play("burn_tick", -6.0)
			if effects and e.sprite:
				effects.spawn_damage_number(e.sprite.position, dot_dmg, Color(1.0, 0.4, 0.1), "BURN")

	for ch in party:
		if not ch.has("buffs"):
			continue
		var expired: Array[String] = []
		for buff_key in ch.buffs:
			ch.buffs[buff_key] -= 1
			if ch.buffs[buff_key] <= 0:
				expired.append(buff_key)
		for key in expired:
			ch.buffs.erase(key)
			# Stop aura VFX when buff expires
			if effects and ch.sprite and BUFF_AURA_TINT.has(key):
				effects.stop_aura(ch.sprite)
	for e in enemies:
		if not e.has("buffs"):
			continue
		var expired: Array[String] = []
		for buff_key in e.buffs:
			e.buffs[buff_key] -= 1
			if e.buffs[buff_key] <= 0:
				expired.append(buff_key)
		for key in expired:
			e.buffs.erase(key)
			if effects and e.sprite and BUFF_AURA_TINT.has(key):
				effects.stop_aura(e.sprite)

# Status effect icon paths and popup colors
const STATUS_ICON_DIR := "res://assets/sprites/battle/status effects/"
const STATUS_DISPLAY := {
	"ablaze": {"icon": "ablaze.png", "color": Color(1.0, 0.4, 0.1)},
	"chilled": {"icon": "chilled.png", "color": Color(0.4, 0.8, 1.0)},
	"shocked": {"icon": "shocked.png", "color": Color(1.0, 1.0, 0.3)},
	"soaked": {"icon": "soaked.png", "color": Color(0.2, 0.5, 1.0)},
	"buff_atk": {"icon": "buff_atk.png", "color": Color(1.0, 0.6, 0.3)},
	"buff_def": {"icon": "buff_def.png", "color": Color(0.3, 0.8, 1.0)},
	"buff_spd": {"icon": "buff_spd.png", "color": Color(0.3, 1.0, 0.5)},
	"debuff_def": {"icon": "debuff_def.png", "color": Color(1.0, 0.3, 0.3)},
	"taunt": {"icon": "taunt.png", "color": Color(1.0, 0.6, 0.0)},
}

var _status_icon_cache: Dictionary = {} # icon filename -> Texture2D

func _load_status_icon(icon_name: String) -> Texture2D:
	if _status_icon_cache.has(icon_name):
		return _status_icon_cache[icon_name]
	var path: String = STATUS_ICON_DIR + icon_name
	if ResourceLoader.exists(path):
		var tex: Texture2D = load(path) as Texture2D
		_status_icon_cache[icon_name] = tex
		return tex
	return null

func _update_status_icons(container: HBoxContainer, entity: Dictionary) -> void:
	# Clear existing icons
	for child in container.get_children():
		child.queue_free()
	if not entity.has("buffs") or entity.buffs.is_empty():
		return
	for key in entity.buffs:
		if not STATUS_DISPLAY.has(key):
			continue
		var icon_file: String = STATUS_DISPLAY[key].icon
		var tex: Texture2D = _load_status_icon(icon_file)
		if tex == null:
			continue
		var icon_rect := TextureRect.new()
		icon_rect.texture = tex
		icon_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		icon_rect.custom_minimum_size = Vector2(14, 14)
		icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		container.add_child(icon_rect)

func _apply_status_effect(skill: SkillData, target: Dictionary) -> void:
	if skill.status_effect == "" or skill.status_effect_chance <= 0.0:
		return
	if randf() > skill.status_effect_chance:
		return
	if not target.has("buffs"):
		target["buffs"] = {}
	var duration: int = 3
	match skill.status_effect:
		"ablaze":
			duration = 3
		"chilled":
			duration = 2
		"shocked":
			duration = 1
		"soaked":
			duration = 2
	target.buffs[skill.status_effect] = duration
	Sfx.play("status_apply", -3.0)
	var target_pos: Vector2 = target.sprite.position if target.sprite else Vector2.ZERO
	if effects and STATUS_DISPLAY.has(skill.status_effect):
		var display: Dictionary = STATUS_DISPLAY[skill.status_effect]
		var popup_text: String = skill.status_effect.to_upper() + "!"
		effects.spawn_text_popup(target_pos + Vector2(0, 15), popup_text, display.color, 16)

	# Soaked applies immediate DEF down
	if skill.status_effect == "soaked" and not target.buffs.has("debuff_def"):
		target.buffs["debuff_def"] = 2

func _get_effective_def(entity: Dictionary) -> int:
	var base_def: int = entity.data.defense
	if entity.has("buffs"):
		if entity.buffs.has("buff_def"):
			base_def = int(base_def * 1.3)
		if entity.buffs.has("debuff_def") or entity.buffs.has("soaked"):
			base_def = int(base_def * 0.85)
	if entity.has("defending") and entity.defending:
		base_def = int(base_def * 1.5)
	return base_def

func _get_effective_mdef(entity: Dictionary) -> int:
	var base_mdef: int = entity.data.magic_defense
	if entity.has("buffs"):
		if entity.buffs.has("buff_def"):
			base_mdef = int(base_mdef * 1.3)
		if entity.buffs.has("debuff_def") or entity.buffs.has("soaked"):
			base_mdef = int(base_mdef * 0.85)
	return base_mdef

func _sync_to_party_state() -> void:
	for i in range(party.size()):
		party_state.characters[i].current_hp = party[i].current_hp
		party_state.characters[i].current_ap = party[i].current_ap

func _load_sprite_texture(path: String) -> Texture2D:
	if path == "":
		return null
	if not ResourceLoader.exists(path):
		push_warning("Sprite not found: " + path)
		return null
	var tex: Texture2D = load(path) as Texture2D
	return tex

var _frame_cache: Dictionary = {} # folder_path -> Array[Texture2D]

func _load_frames_from_folder(folder_path: String) -> Array:
	if folder_path == "":
		return []
	if _frame_cache.has(folder_path):
		return _frame_cache[folder_path]
	var frames: Array = []
	var i: int = 0
	while i < 20:
		var frame_path: String = folder_path + "/frame_" + str(i) + ".png"
		if not ResourceLoader.exists(frame_path):
			break
		var tex: Texture2D = load(frame_path) as Texture2D
		if tex:
			frames.append(tex)
		i += 1
	_frame_cache[folder_path] = frames
	return frames

func _play_animation(ch: Dictionary, anim_key: String, duration: float = 0.8) -> void:
	if ch.sprite == null:
		await get_tree().create_timer(duration).timeout
		return
	if not ch.has("animations"):
		await get_tree().create_timer(duration).timeout
		return
	var anims: Dictionary = ch.get("animations") as Dictionary
	if not anims.has(anim_key):
		await get_tree().create_timer(duration).timeout
		return
	var frame_textures: Array = anims.get(anim_key) as Array
	if frame_textures == null or frame_textures.is_empty():
		await get_tree().create_timer(duration).timeout
		return
	var frame_count: int = frame_textures.size()
	var frame_duration: float = duration / frame_count
	for f_idx in range(frame_count):
		_set_entity_texture(ch, frame_textures[f_idx])
		await get_tree().create_timer(frame_duration).timeout

func _play_skill_animation(ch: Dictionary, skill_name: String, duration: float = 1.2) -> void:
	var data: CharacterData = ch.data as CharacterData
	if data and data.skill_sprite_map.has(skill_name):
		var folder: String = data.skill_sprite_map[skill_name]
		var frames: Array = _load_frames_from_folder(folder)
		if not frames.is_empty():
			var frame_count: int = frames.size()
			var frame_duration: float = duration / frame_count
			for f_idx in range(frame_count):
				_set_entity_texture(ch, frames[f_idx])
				await get_tree().create_timer(frame_duration).timeout
			return
	# Fallback to generic attack animation
	await _play_animation(ch, "attack", duration)

func _get_anim_frames(ch: Dictionary, anim_key: String) -> Array:
	if not ch.has("animations"):
		return []
	var anims: Dictionary = ch.get("animations") as Dictionary
	if anims == null or not anims.has(anim_key):
		return []
	var arr = anims.get(anim_key)
	if arr is Array:
		return arr as Array
	return []

func _swap_to_idle_sprite(ch: Dictionary) -> void:
	var frames: Array = _get_anim_frames(ch, "idle")
	if not frames.is_empty():
		_set_entity_texture(ch, frames[0])

func _set_entity_texture(entity: Dictionary, tex: Texture2D) -> void:
	if not entity.has("sprite") or entity.sprite == null or tex == null:
		return
	entity.sprite.texture = tex
	if entity.has("target_height"):
		_apply_sprite_scale(entity.sprite, tex, entity.target_height)

static func _apply_sprite_scale(sprite: Sprite2D, tex: Texture2D, target_height: float) -> void:
	var tex_h: float = float(tex.get_height())
	if tex_h > 0:
		var s: float = target_height / tex_h
		sprite.scale = Vector2(s, s)
