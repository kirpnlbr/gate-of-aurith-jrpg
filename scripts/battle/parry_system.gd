extends Node2D

signal parry_phase_complete(result: Dictionary)

enum ParryState { IDLE, WAITING, WINDOW_OPEN, HIT_RESOLVED, PHASE_DONE }

var current_state: ParryState = ParryState.IDLE
var current_pattern: AttackPattern = null
var current_hit_index: int = 0
var delay_timer: float = 0.0
var target_character: Dictionary = {}
var attacker: Dictionary = {}
var parry_bonus: float = 0.0

var hits_parried: int = 0
var hits_dodged: int = 0
var hits_missed: int = 0
var total_damage: int = 0
var total_hits: int = 0

var indicator: Control = null # ParryIndicator node
var action_text_box: Control = null
var _waiting_for_input := false
var _current_hit_damage: int = 0

func setup(indicator_node: Control, text_box: Control) -> void:
	indicator = indicator_node
	action_text_box = text_box
	if indicator:
		indicator.parry_input_received.connect(_on_parry_input)

func start_phase(atk: Dictionary, target: Dictionary, pattern: AttackPattern, bonus: float) -> void:
	attacker = atk
	target_character = target
	current_pattern = pattern
	parry_bonus = bonus
	current_hit_index = 0
	hits_parried = 0
	hits_dodged = 0
	hits_missed = 0
	total_damage = 0
	total_hits = pattern.hits.size()

	# Display attack announcement
	var text: String = pattern.action_text
	text = text.replace("{attacker}", atk.data.enemy_name)
	text = text.replace("{target}", target.data.character_name)
	if action_text_box:
		action_text_box.display(text)

	# Start first hit
	_start_next_hit()

func _start_next_hit() -> void:
	if current_hit_index >= current_pattern.hits.size():
		_finish_phase()
		return

	var hit: Dictionary = current_pattern.hits[current_hit_index]
	delay_timer = hit.get("delay", 0.5)
	current_state = ParryState.WAITING
	_waiting_for_input = false

	# Calculate damage for this hit
	var def: int = target_character.data.defense
	if target_character.has("buffs") and target_character.buffs.has("buff_def"):
		def = int(def * 1.3)
	if target_character.has("defending") and target_character.defending:
		def = int(def * 2.0)
	_current_hit_damage = DamageCalculator.calculate_enemy_damage(
		attacker.data.attack, def, hit.get("damage_pct", 1.0))

func _process(delta: float) -> void:
	match current_state:
		ParryState.WAITING:
			delay_timer -= delta
			if delay_timer <= 0:
				var hit: Dictionary = current_pattern.hits[current_hit_index]
				var window: float = hit.get("window", 0.3)
				if window <= 0.0:
					# Feint — no real hit, skip to next
					current_hit_index += 1
					_start_next_hit()
				else:
					current_state = ParryState.WINDOW_OPEN
					_waiting_for_input = true
					if indicator:
						indicator.start_indicator(window, parry_bonus)
		ParryState.WINDOW_OPEN:
			pass # waiting for input from indicator
		ParryState.HIT_RESOLVED:
			current_hit_index += 1
			_start_next_hit()

func _on_parry_input(input_type: String) -> void:
	if not _waiting_for_input:
		return
	_waiting_for_input = false

	if indicator:
		indicator.stop_indicator()

	match input_type:
		"parry":
			hits_parried += 1
			# Grant AP
			if target_character.has("current_ap"):
				target_character.current_ap = mini(
					target_character.current_ap + 1,
					target_character.data.max_ap)
			if action_text_box:
				action_text_box.display("Perfect Parry! %s takes no damage and gains 1 AP!" % target_character.data.character_name)
		"dodge":
			hits_dodged += 1
			if action_text_box:
				action_text_box.display("%s dodges the attack!" % target_character.data.character_name)
		"miss":
			hits_missed += 1
			total_damage += _current_hit_damage
			target_character.current_hp = maxi(0, target_character.current_hp - _current_hit_damage)
			if action_text_box:
				action_text_box.display("%s takes %d damage!" % [target_character.data.character_name, _current_hit_damage])

	# Flash the target sprite
	if target_character.has("sprite") and target_character.sprite:
		var sprite: Sprite2D = target_character.sprite
		if input_type == "miss":
			_flash_sprite(sprite, Color.RED)
		elif input_type == "parry":
			_flash_sprite(sprite, Color.GREEN)
		else:
			_flash_sprite(sprite, Color.CYAN)

	# Brief pause before next hit
	await get_tree().create_timer(0.6).timeout
	current_state = ParryState.HIT_RESOLVED

func _flash_sprite(sprite: Sprite2D, color: Color) -> void:
	var original := sprite.modulate
	sprite.modulate = color
	var tween := create_tween()
	tween.tween_property(sprite, "modulate", original, 0.3)

func _finish_phase() -> void:
	current_state = ParryState.IDLE
	var all_parried := (hits_parried == total_hits and total_hits > 0)
	parry_phase_complete.emit({
		"total_damage": total_damage,
		"hits_parried": hits_parried,
		"hits_dodged": hits_dodged,
		"hits_missed": hits_missed,
		"all_parried": all_parried,
	})
