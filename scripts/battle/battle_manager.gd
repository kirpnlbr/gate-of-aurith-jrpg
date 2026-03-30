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
var turn_order_container: HBoxContainer = null
var status_panel: VBoxContainer = null

const ACTION_TEXT_DELAY := 0.8
const PARTY_X := 180.0
const ENEMY_X := 700.0
const IDLE_FRAME_INTERVAL := 0.25 # seconds per idle frame

var _idle_timer: float = 0.0
var _idle_frame_index: int = 0

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
	# Cycle idle frames for all party members during non-animation states
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
				ch_dict.sprite.texture = idle_arr[idx]

var _battle_layer: CanvasLayer = null
var _sprite_root: Node2D = null

func _build_battle_scene() -> void:
	print("[BATTLE] _build_battle_scene START, party=%d enemies=%d" % [party.size(), enemies.size()])

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
	bg.size = Vector2(960, 540)
	_battle_layer.add_child(bg)
	# Move bg behind sprites
	_battle_layer.move_child(bg, 0)

	# Party sprites (right side)
	var party_y_positions := [160.0, 260.0, 360.0]
	for i in range(party.size()):
		var ch: Dictionary = party[i]
		var data: CharacterData = ch.data as CharacterData
		var sprite := Sprite2D.new()

		# Load frame-based animations
		var idle_frames: Array = _load_frames_from_folder(data.sprite_idle)
		var attack_frames: Array = _load_frames_from_folder(data.sprite_attack)
		ch["animations"] = {
			"idle": idle_frames,
			"attack": attack_frames,
		}
		print("[BATTLE] %s: idle=%d attack=%d" % [data.character_name, idle_frames.size(), attack_frames.size()])

		# Set initial texture from first idle frame, or fallback to colored rect
		if not idle_frames.is_empty():
			sprite.texture = idle_frames[0]
			var tex_h: float = float(idle_frames[0].get_height())
			var target_h := 100.0
			var s: float = target_h / tex_h
			sprite.scale = Vector2(s, s)
		else:
			var rect_img := Image.create(40, 60, false, Image.FORMAT_RGBA8)
			rect_img.fill(data.battle_color)
			sprite.texture = ImageTexture.create_from_image(rect_img)
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		sprite.position = Vector2(PARTY_X, party_y_positions[i])
		_sprite_root.add_child(sprite)
		ch.sprite = sprite
		party_sprites.append(sprite)

		# Name label above sprite
		var name_lbl := Label.new()
		name_lbl.text = data.character_name
		name_lbl.add_theme_font_size_override("font_size", 12)
		name_lbl.add_theme_color_override("font_color", data.battle_color)
		name_lbl.position = Vector2(sprite.position.x - 25, sprite.position.y - 65)
		name_lbl.size = Vector2(80, 20)
		_sprite_root.add_child(name_lbl)

	# Enemy sprites (left side)
	var enemy_y_start := 200.0
	var enemy_spacing := 100.0
	if enemies.size() == 1:
		enemy_y_start = 250.0
	for i in range(enemies.size()):
		var edict: Dictionary = enemies[i]
		var edata: EnemyData = edict.data as EnemyData
		var sprite := Sprite2D.new()
		var tex: Texture2D = _load_sprite_texture(edata.sprite_path)
		if tex:
			sprite.texture = tex
			var tex_h: float = float(tex.get_height())
			var target_h: float = 80.0 * edata.sprite_scale
			var s: float = target_h / tex_h
			sprite.scale = Vector2(s, s)
		else:
			var w: int = int(50 * edata.sprite_scale)
			var h: int = int(70 * edata.sprite_scale)
			var rect_img := Image.create(w, h, false, Image.FORMAT_RGBA8)
			rect_img.fill(edata.battle_color)
			sprite.texture = ImageTexture.create_from_image(rect_img)
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		sprite.position = Vector2(ENEMY_X, enemy_y_start + i * enemy_spacing)
		_sprite_root.add_child(sprite)
		edict.sprite = sprite
		enemy_sprites.append(sprite)

		# Name label
		var name_lbl := Label.new()
		name_lbl.text = edata.enemy_name
		name_lbl.add_theme_font_size_override("font_size", 12)
		name_lbl.add_theme_color_override("font_color", edata.battle_color)
		name_lbl.position = Vector2(sprite.position.x - 30, sprite.position.y - 55)
		name_lbl.size = Vector2(100, 20)
		_sprite_root.add_child(name_lbl)

	print("[BATTLE] Sprites done, starting HUD")
	# CanvasLayer for HUD (above the battle layer)
	var canvas := CanvasLayer.new()
	canvas.layer = 10
	add_child(canvas)

	# HUD root
	hud_node = Control.new()
	hud_node.set_anchors_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(hud_node)

	# Turn order display (top bar)
	turn_order_container = HBoxContainer.new()
	turn_order_container.position = Vector2(16, 8)
	hud_node.add_child(turn_order_container)

	# Party status panel (right side)
	status_panel = VBoxContainer.new()
	status_panel.position = Vector2(720, 16)
	status_panel.name = "StatusPanel"
	hud_node.add_child(status_panel)
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

	# Skill menu
	skill_menu = VBoxContainer.new()
	skill_menu.name = "SkillMenu"
	var sm_script: GDScript = load("res://scripts/ui/skill_menu.gd")
	skill_menu.set_script(sm_script)
	hud_node.add_child(skill_menu)
	skill_menu.skill_selected.connect(_on_skill_selected)
	skill_menu.cancelled.connect(_on_submenu_cancelled)

	# Item menu
	item_menu = VBoxContainer.new()
	item_menu.name = "ItemMenu"
	var im_script: GDScript = load("res://scripts/ui/item_menu.gd")
	item_menu.set_script(im_script)
	hud_node.add_child(item_menu)
	item_menu.item_selected.connect(_on_item_selected)
	item_menu.cancelled.connect(_on_submenu_cancelled)

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
	parry_system.setup(parry_indicator, action_text_box)
	parry_system.parry_phase_complete.connect(_on_parry_phase_complete)

func _build_status_panel() -> void:
	for i in range(party.size()):
		var ch: Dictionary = party[i]
		var data: CharacterData = ch.data as CharacterData
		var row := HBoxContainer.new()
		row.custom_minimum_size = Vector2(220, 0)

		var name_lbl := Label.new()
		name_lbl.text = data.character_name
		name_lbl.add_theme_font_size_override("font_size", 12)
		name_lbl.add_theme_color_override("font_color", data.battle_color)
		name_lbl.custom_minimum_size = Vector2(70, 0)
		row.add_child(name_lbl)

		# HP bar
		var hp_bar := ProgressBar.new()
		hp_bar.min_value = 0
		hp_bar.max_value = data.max_hp
		hp_bar.value = int(ch.current_hp)
		hp_bar.custom_minimum_size = Vector2(60, 14)
		hp_bar.show_percentage = false
		var hp_style := StyleBoxFlat.new()
		hp_style.bg_color = Color(0.6, 0.15, 0.15)
		hp_bar.add_theme_stylebox_override("background", hp_style)
		var hp_fill := StyleBoxFlat.new()
		hp_fill.bg_color = Color(0.2, 0.8, 0.2)
		hp_bar.add_theme_stylebox_override("fill", hp_fill)
		row.add_child(hp_bar)

		var hp_lbl := Label.new()
		hp_lbl.text = " %d" % int(ch.current_hp)
		hp_lbl.add_theme_font_size_override("font_size", 11)
		row.add_child(hp_lbl)

		# AP bar
		var ap_bar := ProgressBar.new()
		ap_bar.min_value = 0
		ap_bar.max_value = data.max_ap
		ap_bar.value = int(ch.current_ap)
		ap_bar.custom_minimum_size = Vector2(40, 14)
		ap_bar.show_percentage = false
		var ap_style := StyleBoxFlat.new()
		ap_style.bg_color = Color(0.15, 0.15, 0.5)
		ap_bar.add_theme_stylebox_override("background", ap_style)
		var ap_fill := StyleBoxFlat.new()
		ap_fill.bg_color = Color(0.3, 0.3, 0.9)
		ap_bar.add_theme_stylebox_override("fill", ap_fill)
		row.add_child(ap_bar)

		var ap_lbl := Label.new()
		ap_lbl.text = " %d" % int(ch.current_ap)
		ap_lbl.add_theme_font_size_override("font_size", 11)
		ap_lbl.add_theme_color_override("font_color", Color(0.5, 0.5, 1.0))
		row.add_child(ap_lbl)

		status_panel.add_child(row)

func _update_status_panel() -> void:
	if status_panel == null or status_panel.get_child_count() == 0:
		return
	for i in range(party.size()):
		if i >= status_panel.get_child_count():
			break
		var ch: Dictionary = party[i]
		var data: CharacterData = ch.data as CharacterData
		var row: HBoxContainer = status_panel.get_child(i) as HBoxContainer
		if row == null or row.get_child_count() < 5:
			continue
		# [0]=name, [1]=hp_bar, [2]=hp_lbl, [3]=ap_bar, [4]=ap_lbl
		var hp_bar: ProgressBar = row.get_child(1) as ProgressBar
		hp_bar.max_value = data.max_hp
		hp_bar.value = int(ch.current_hp)
		var hp_lbl: Label = row.get_child(2) as Label
		hp_lbl.text = " %d" % int(ch.current_hp)
		var ap_bar: ProgressBar = row.get_child(3) as ProgressBar
		ap_bar.max_value = data.max_ap
		ap_bar.value = int(ch.current_ap)
		var ap_lbl: Label = row.get_child(4) as Label
		ap_lbl.text = " %d" % int(ch.current_ap)

func _update_turn_order_display() -> void:
	# Clear existing
	for child in turn_order_container.get_children():
		child.queue_free()
	# Add current turn indicator
	if current_turn and not current_turn.is_empty():
		var current_name: String
		if current_turn.is_player:
			current_name = current_turn.entity.data.character_name
		else:
			current_name = current_turn.entity.data.enemy_name
		var current_lbl := Label.new()
		current_lbl.text = "[%s]" % current_name
		current_lbl.add_theme_font_size_override("font_size", 13)
		current_lbl.add_theme_color_override("font_color", Color.GOLD)
		turn_order_container.add_child(current_lbl)

	# Remaining queue
	var names := turn_order.get_order_names()
	for n in names:
		var arrow := Label.new()
		arrow.text = " > "
		arrow.add_theme_font_size_override("font_size", 12)
		arrow.add_theme_color_override("font_color", Color(0.4, 0.4, 0.5))
		turn_order_container.add_child(arrow)

		var lbl := Label.new()
		lbl.text = n
		lbl.add_theme_font_size_override("font_size", 12)
		lbl.add_theme_color_override("font_color", Color(0.7, 0.7, 0.8))
		turn_order_container.add_child(lbl)

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

	_update_turn_order_display()
	_update_status_panel()

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
			skill_menu.show_skills(ch.data.skills, ch.current_ap)
		"item":
			item_menu.show_items(party_state.items)
		"defend":
			_execute_defend()
		"stance_switch":
			_execute_stance_switch()

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
	# Gustave stance modifier
	if ch.data.character_name == "Gustave":
		if gustave_stance == "greatsword":
			atk = int(atk * 1.3)
		else:
			atk = int(atk * 0.7)
	var damage := DamageCalculator.calculate_physical(atk, target.data.defense)
	target.current_hp = maxi(0, target.current_hp - damage)

	var text := "%s attacks %s for %d damage!" % [ch.data.character_name, target.data.enemy_name, damage]
	action_text_box.display(text)
	_flash_sprite(target.sprite, Color.RED)
	_update_status_panel()
	await _play_animation(ch, "attack", 0.8)
	_swap_to_idle_sprite(ch)
	_enter_state(BattleState.CHECK_DEATH)

func _execute_defend() -> void:
	var ch: Dictionary = current_turn.entity
	ch.defending = true
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
		action_text_box.display("Gustave switches to Greatshield Mode! Defense greatly increased!")
		# Swap idle frames to shield stance
		var shield_idle: Array = _load_frames_from_folder(data.sprite_idle_alt)
		if not shield_idle.is_empty() and ch.has("animations"):
			ch.animations.idle = shield_idle
	else:
		gustave_stance = "greatsword"
		party_state.gustave_stance = "greatsword"
		anim_key = "_stance_to_sword"
		action_text_box.display("Gustave switches to Greatsword Mode! Attack power greatly increased!")
		# Swap idle frames back to sword stance
		var sword_idle: Array = _load_frames_from_folder(data.sprite_idle)
		if not sword_idle.is_empty() and ch.has("animations"):
			ch.animations.idle = sword_idle
	_apply_gustave_stance()
	_update_status_panel()
	await _play_skill_animation(ch, anim_key, 1.0)
	_swap_to_idle_sprite(ch)
	_enter_state(BattleState.CHECK_DEATH)

func _execute_skill_single(target: Dictionary) -> void:
	var ch: Dictionary = current_turn.entity
	var skill: SkillData = pending_skill
	ch.current_ap -= skill.ap_cost

	var text := skill.action_text
	var is_enemy := enemies.has(target)

	match skill.effect_type:
		"damage":
			var damage: int
			if skill.element != "none" and skill.element != "":
				var weakness := ""
				var resistance := ""
				if is_enemy:
					weakness = target.data.element_weakness
					resistance = target.data.element_resistance
				damage = DamageCalculator.calculate_magical(
					ch.data.magic_attack, target.data.magic_defense,
					skill.power, skill.element, weakness, resistance)
			else:
				damage = DamageCalculator.calculate_physical(ch.data.attack, target.data.defense, skill.power)
			target.current_hp = maxi(0, target.current_hp - damage)
			text = text.replace("{target}", target.data.enemy_name if is_enemy else target.data.character_name)
			text = text.replace("{value}", str(damage))
			_flash_sprite(target.sprite, Color.RED)
		"heal":
			var heal_amount := DamageCalculator.calculate_heal(ch.data.magic_attack, skill.power)
			target.current_hp = mini(target.current_hp + heal_amount, target.data.max_hp)
			text = text.replace("{target}", target.data.character_name)
			text = text.replace("{value}", str(heal_amount))
			_flash_sprite(target.sprite, Color.GREEN)
		"revive":
			var revive_hp: int = int(target.data.max_hp * 0.3)
			target.current_hp = revive_hp
			text = text.replace("{target}", target.data.character_name)
			_flash_sprite(target.sprite, Color.GOLD)
		"debuff_def":
			if not target.has("buffs"):
				target["buffs"] = {}
			target.buffs["debuff_def"] = skill.buff_duration
			text = text.replace("{target}", target.data.enemy_name if is_enemy else target.data.character_name)

	text = text.replace("{user}", ch.data.character_name)
	text = text.replace("{skill}", skill.skill_name)
	action_text_box.display(text)
	_update_status_panel()
	await _play_skill_animation(ch, skill.skill_name, 1.2)
	_swap_to_idle_sprite(ch)
	_enter_state(BattleState.CHECK_DEATH)

func _execute_skill_all_enemies() -> void:
	var ch: Dictionary = current_turn.entity
	var skill: SkillData = pending_skill
	ch.current_ap -= skill.ap_cost
	state = BattleState.PLAYER_EXECUTE

	var total_damage := 0
	for e in enemies:
		if e.current_hp <= 0:
			continue
		var damage: int
		if skill.element != "none":
			damage = DamageCalculator.calculate_magical(
				ch.data.magic_attack, e.data.magic_defense,
				skill.power, skill.element, e.data.element_weakness, e.data.element_resistance)
		else:
			damage = DamageCalculator.calculate_physical(ch.data.attack, e.data.defense, skill.power)
		e.current_hp = maxi(0, e.current_hp - damage)
		total_damage += damage
		_flash_sprite(e.sprite, Color.RED)

	var text := skill.action_text.replace("{value}", str(total_damage))
	text = text.replace("{user}", ch.data.character_name)
	action_text_box.display(text)
	_update_status_panel()
	await _play_skill_animation(ch, skill.skill_name, 1.2)
	_swap_to_idle_sprite(ch)
	_enter_state(BattleState.CHECK_DEATH)

func _execute_skill_all_allies() -> void:
	var ch: Dictionary = current_turn.entity
	var skill: SkillData = pending_skill
	ch.current_ap -= skill.ap_cost
	state = BattleState.PLAYER_EXECUTE

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
	await _play_skill_animation(ch, skill.skill_name, 1.2)
	_swap_to_idle_sprite(ch)
	_enter_state(BattleState.CHECK_DEATH)

func _execute_skill_self() -> void:
	var ch: Dictionary = current_turn.entity
	var skill: SkillData = pending_skill
	ch.current_ap -= skill.ap_cost
	state = BattleState.PLAYER_EXECUTE

	match skill.effect_type:
		"taunt":
			if not ch.has("buffs"):
				ch["buffs"] = {}
			ch.buffs["taunt"] = skill.buff_duration

	var text := skill.action_text.replace("{user}", ch.data.character_name)
	action_text_box.display(text)
	_update_status_panel()
	await _play_skill_animation(ch, skill.skill_name, 1.2)
	_swap_to_idle_sprite(ch)
	_enter_state(BattleState.CHECK_DEATH)

func _execute_item_single(target: Dictionary) -> void:
	var ch: Dictionary = current_turn.entity
	var item: ItemData = pending_item_data
	state = BattleState.PLAYER_EXECUTE

	# Consume item
	for item_entry in party_state.items:
		if item_entry.data == item or item_entry.data.item_name == item.item_name:
			item_entry.quantity -= 1
			break

	match item.effect_type:
		"heal_hp":
			target.current_hp = mini(target.current_hp + item.value, target.data.max_hp)
			_flash_sprite(target.sprite, Color.GREEN)
		"heal_ap":
			target.current_ap = mini(target.current_ap + item.value, target.data.max_ap)
			_flash_sprite(target.sprite, Color.CYAN)
		"revive":
			var revive_hp: int = int(target.data.max_hp * item.value / 100.0)
			target.current_hp = revive_hp
			_flash_sprite(target.sprite, Color.GOLD)

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

	if pattern.is_aoe:
		# AoE: attack each alive party member sequentially
		await _execute_aoe_attack(enemy, pattern)
	else:
		parry_system.start_phase(enemy, target, pattern, bonus)

func _execute_aoe_attack(enemy: Dictionary, pattern: AttackPattern) -> void:
	action_text_box.display("%s unleashes %s on the entire party!" % [enemy.data.enemy_name, pattern.pattern_name])
	await get_tree().create_timer(0.8).timeout

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

		# Wait for this parry phase to complete
		var result_received := false
		var phase_result: Dictionary = {}

		var callback: Callable = func(result: Dictionary) -> void:
			result_received = true
			phase_result = result

		# Temporarily connect for this one phase
		if parry_system.parry_phase_complete.is_connected(_on_parry_phase_complete):
			parry_system.parry_phase_complete.disconnect(_on_parry_phase_complete)

		parry_system.parry_phase_complete.connect(callback, CONNECT_ONE_SHOT)
		parry_system.start_phase(enemy, p, single_pattern, bonus)

		while not result_received:
			await get_tree().process_frame

		# Handle counterattack for this target
		if phase_result.get("all_parried", false):
			var counter_dmg := DamageCalculator.calculate_physical(p.data.attack, enemy.data.defense, 8)
			enemy.current_hp = maxi(0, enemy.current_hp - counter_dmg)
			action_text_box.display("%s counters for %d damage!" % [p.data.character_name, counter_dmg])
			_flash_sprite(enemy.sprite, Color.YELLOW)
			await get_tree().create_timer(0.6).timeout

	# Reconnect the normal handler
	if not parry_system.parry_phase_complete.is_connected(_on_parry_phase_complete):
		parry_system.parry_phase_complete.connect(_on_parry_phase_complete)

	_update_status_panel()
	_enter_state(BattleState.CHECK_DEATH)

func _on_parry_phase_complete(result: Dictionary) -> void:
	if state != BattleState.PARRY_PHASE:
		return

	# Counterattack if all hits were parried
	if result.get("all_parried", false):
		var ch: Dictionary = parry_system.target_character
		if not ch.is_empty():
			var enemy: Dictionary = current_turn.entity
			var counter_dmg := DamageCalculator.calculate_physical(ch.data.attack, enemy.data.defense, 8)
			enemy.current_hp = maxi(0, enemy.current_hp - counter_dmg)
			action_text_box.display("Full Parry! %s counters for %d damage!" % [ch.data.character_name, counter_dmg])
			_flash_sprite(enemy.sprite, Color.YELLOW)
			await get_tree().create_timer(ACTION_TEXT_DELAY).timeout

	_update_status_panel()
	_enter_state(BattleState.CHECK_DEATH)

# ── Death Check ──────────────────────────────────────────────────────

func _do_check_death() -> void:
	# Check enemy deaths
	for e in enemies:
		if e.current_hp <= 0 and e.sprite and e.sprite.visible:
			e.sprite.visible = false
			action_text_box.display("%s is defeated!" % e.data.enemy_name)
			await get_tree().create_timer(0.6).timeout

	# Check party deaths
	for p in party:
		if p.current_hp <= 0 and p.sprite and p.sprite.modulate.a > 0.3:
			p.sprite.modulate = Color(1, 1, 1, 0.2)
			action_text_box.display("%s falls in battle!" % p.data.character_name)
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
	action_text_box.display("Victory!")
	await get_tree().create_timer(1.0).timeout

	# Calculate XP
	var total_xp := 0
	for e in enemies:
		total_xp += e.data.xp_reward

	action_text_box.display("Gained %d experience points!" % total_xp)
	await get_tree().create_timer(ACTION_TEXT_DELAY).timeout

	# Apply XP and show level ups
	var level_msgs := party_state.add_xp(total_xp)
	for msg in level_msgs:
		action_text_box.display(msg)
		await get_tree().create_timer(ACTION_TEXT_DELAY).timeout

	# Sync battle state back to party_state
	_sync_to_party_state()

	await get_tree().create_timer(0.5).timeout
	battle_finished.emit("victory")

func _do_defeat() -> void:
	action_text_box.display("The party has been defeated...")
	await get_tree().create_timer(2.0).timeout
	battle_finished.emit("defeat")

# ── Helpers ──────────────────────────────────────────────────────────

func _apply_gustave_stance() -> void:
	# Find Gustave in party (index 1)
	if party.size() < 2:
		return
	var gustave: Dictionary = party[1]
	# Reset to base stats first (stored in the resource)
	gustave.data.parry_window_bonus = 0.0
	if gustave_stance == "greatshield":
		gustave.data.parry_window_bonus = 0.15

func _flash_sprite(sprite: Sprite2D, color: Color) -> void:
	if sprite == null:
		return
	var original := sprite.modulate
	sprite.modulate = color
	var tween := create_tween()
	tween.tween_property(sprite, "modulate", original, 0.3)

func _tick_buffs() -> void:
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

func _load_frames_from_folder(folder_path: String) -> Array:
	"""Load all frame_*.png files from a folder, in order."""
	var frames: Array = []
	if folder_path == "":
		return frames
	var i: int = 0
	while i < 20: # max 20 frames
		var frame_path: String = folder_path + "/frame_" + str(i) + ".png"
		if ResourceLoader.exists(frame_path):
			var tex: Texture2D = load(frame_path) as Texture2D
			if tex:
				frames.append(tex)
		i += 1
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
		if ch.sprite != null:
			ch.sprite.texture = frame_textures[f_idx]
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
				if ch.sprite != null:
					ch.sprite.texture = frames[f_idx]
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

func _swap_to_attack_sprite(ch: Dictionary) -> void:
	var frames: Array = _get_anim_frames(ch, "attack")
	if not frames.is_empty() and ch.sprite != null:
		ch.sprite.texture = frames[0]

func _swap_to_skill_sprite(ch: Dictionary) -> void:
	var frames: Array = _get_anim_frames(ch, "attack")
	if not frames.is_empty() and ch.sprite != null:
		ch.sprite.texture = frames[0]

func _swap_to_idle_sprite(ch: Dictionary) -> void:
	var frames: Array = _get_anim_frames(ch, "idle")
	if not frames.is_empty() and ch.sprite != null:
		ch.sprite.texture = frames[0]
