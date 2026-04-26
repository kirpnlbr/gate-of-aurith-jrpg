extends Node2D

signal parry_phase_complete(result: Dictionary)

enum ParryState { IDLE, WINDUP, FLASH_CUE, WINDOW_OPEN, HIT_RESOLVING, RESETTING, PHASE_DONE }

var current_state: ParryState = ParryState.IDLE
var current_pattern: AttackPattern = null
var current_hit_index: int = 0
var target_character: Dictionary = {}
var attacker: Dictionary = {}
var parry_bonus: float = 0.0

var hits_parried: int = 0
var hits_dodged: int = 0
var hits_missed: int = 0
var total_damage: int = 0
var total_hits: int = 0

var indicator: Control = null
var action_text_box: Control = null
var effects: BattleEffects = null
var _waiting_for_input := false
var _current_hit_damage: int = 0

# Procedural motion state
var _attacker_origin: Vector2 = Vector2.ZERO
var _windup_timer: float = 0.0
var _windup_duration: float = 0.0
var _window_timer: float = 0.0
var _window_duration: float = 0.0
var _flash_cue_timer: float = 0.0
const FLASH_CUE_DURATION := 0.12
const PULLBACK_DISTANCE := 20.0
const LUNGE_DISTANCE := 45.0
const WINDUP_SCALE := 1.08

# Frame animation (used when sprites exist, layered on top of procedural motion)
var _atk_frames: Array = []
var _anim_frame_idx: int = 0
var _anim_timer: float = 0.0
var _windup_frame_dur: float = 0.0
var _hit_frame_count: int = 0
var _windup_frame_count: int = 0  # frames allocated to wind-up phase
var _strike_frame_start: int = 0  # global index where strike frames begin
var _strike_frame_count: int = 0  # frames allocated to strike phase

func setup(indicator_node: Control, text_box: Control, battle_effects: BattleEffects = null) -> void:
	indicator = indicator_node
	action_text_box = text_box
	effects = battle_effects
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
	# Count only real hits (exclude feints with window <= 0) so all_parried is accurate
	total_hits = 0
	for h in pattern.hits:
		if h.get("window", 0.3) > 0.0:
			total_hits += 1

	# Store attacker origin for procedural motion
	if atk.has("sprite") and atk.sprite:
		_attacker_origin = atk.sprite.position

	# Load attack animation frames if available
	_atk_frames = []
	if atk.has("animations"):
		var anims: Dictionary = atk.animations
		if anims.has("attack_patterns"):
			var ap: Dictionary = anims.attack_patterns
			if ap.has(pattern.pattern_name):
				_atk_frames = ap[pattern.pattern_name]

	# Display attack announcement
	var text: String = pattern.action_text
	text = text.replace("{attacker}", atk.data.enemy_name)
	text = text.replace("{target}", target.data.character_name)
	if action_text_box:
		action_text_box.display(text)

	_start_next_hit()

func _start_next_hit() -> void:
	if current_hit_index >= current_pattern.hits.size():
		_finish_phase()
		return

	var hit: Dictionary = current_pattern.hits[current_hit_index]
	var delay: float = hit.get("delay", 0.5)
	var window: float = hit.get("window", 0.3)

	_waiting_for_input = false
	_current_hit_damage = _calculate_hit_damage(hit)

	if window <= 0.0:
		# Feint — do a fake wind-up then skip
		Sfx.play("feint")
		_start_feint(delay)
		return

	# Start wind-up phase
	Sfx.play("enemy_windup")
	_windup_duration = delay
	_windup_timer = 0.0
	_window_duration = window + parry_bonus
	current_state = ParryState.WINDUP

	# Reset sprite to origin and begin pull-back
	if attacker.has("sprite") and attacker.sprite:
		attacker.sprite.position = _attacker_origin

	# Setup frame animation — split frames between wind-up and strike
	_anim_frame_idx = 0
	_anim_timer = 0.0
	_hit_frame_count = _get_frames_for_hit(current_hit_index)
	# Wind-up gets ~60% of frames, strike gets ~40%
	_windup_frame_count = int(ceili(float(_hit_frame_count) * 0.6))
	_strike_frame_count = _hit_frame_count - _windup_frame_count
	_strike_frame_start = _get_frame_offset(current_hit_index) + _windup_frame_count
	if _windup_frame_count > 0 and _windup_duration > 0:
		_windup_frame_dur = _windup_duration / float(_windup_frame_count)
	else:
		_windup_frame_dur = 0.0
	# Set the first wind-up frame immediately
	if _hit_frame_count > 0 and not _atk_frames.is_empty():
		var first_idx: int = _get_frame_offset(current_hit_index)
		if first_idx < _atk_frames.size():
			_set_entity_texture(attacker, _atk_frames[first_idx])

func _start_feint(duration: float) -> void:
	current_state = ParryState.RESETTING # prevent _process interference during feint
	if attacker.has("sprite") and attacker.sprite and is_instance_valid(attacker.sprite):
		var sprite: Sprite2D = attacker.sprite
		var pullback_pos := _attacker_origin + Vector2(PULLBACK_DISTANCE, 0)
		var tween := create_tween()
		tween.tween_property(sprite, "position", pullback_pos, duration * 0.6) \
			.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
		tween.tween_interval(duration * 0.25)
		tween.tween_property(sprite, "position", _attacker_origin, duration * 0.15) \
			.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
		await tween.finished
	else:
		await get_tree().create_timer(maxf(duration, 0.1)).timeout
	current_hit_index += 1
	_start_next_hit()

func _process(delta: float) -> void:
	match current_state:
		ParryState.WINDUP:
			if _windup_duration <= 0:
				current_state = ParryState.FLASH_CUE
				_flash_cue_timer = 0.0
				return
			_windup_timer += delta
			var progress: float = clampf(_windup_timer / _windup_duration, 0.0, 1.0)

			# Procedural pull-back motion
			if attacker.has("sprite") and attacker.sprite and is_instance_valid(attacker.sprite):
				var sprite: Sprite2D = attacker.sprite
				var ease_progress: float = progress * progress
				var pullback := _attacker_origin + Vector2(PULLBACK_DISTANCE * ease_progress, 0)
				sprite.position = pullback
				var s_base: float = 1.0
				if attacker.has("target_height") and sprite.texture:
					var tex_h: float = float(sprite.texture.get_height())
					if tex_h > 0:
						s_base = attacker.target_height / tex_h
				var scale_boost: float = 1.0 + (WINDUP_SCALE - 1.0) * ease_progress
				sprite.scale = Vector2(s_base * scale_boost, s_base * scale_boost)

			# Advance wind-up frames only (first portion of animation)
			if _windup_frame_count > 0 and _windup_frame_dur > 0:
				_anim_timer += delta
				if _anim_timer >= _windup_frame_dur:
					_anim_timer -= _windup_frame_dur
					if _anim_frame_idx < _windup_frame_count - 1:
						_anim_frame_idx += 1
						var global_idx: int = _get_frame_offset(current_hit_index) + _anim_frame_idx
						if global_idx < _atk_frames.size():
							_set_entity_texture(attacker, _atk_frames[global_idx])

			# Transition to flash cue when wind-up complete
			if _windup_timer >= _windup_duration:
				current_state = ParryState.FLASH_CUE
				_flash_cue_timer = 0.0
				_anim_frame_idx = 0
				_anim_timer = 0.0
				# Show first strike frame at flash moment
				if _strike_frame_count > 0 and _strike_frame_start < _atk_frames.size():
					_set_entity_texture(attacker, _atk_frames[_strike_frame_start])
				# Flash the enemy sprite — "REACT NOW" cue
				Sfx.play("flash_cue")
				if effects and attacker.has("sprite") and attacker.sprite:
					effects.flash_sprite(attacker.sprite, FLASH_CUE_DURATION)

		ParryState.FLASH_CUE:
			_flash_cue_timer += delta
			if _flash_cue_timer >= FLASH_CUE_DURATION:
				# Open parry window and lunge
				Sfx.play("window_open")
				current_state = ParryState.WINDOW_OPEN
				_waiting_for_input = true
				_window_timer = 0.0
				_lunge_at_target()
				# Don't show the parry ring when the target is defending — can't react while bracing
				if not target_character.get("defending", false):
					if indicator:
						var tgt_pos := Vector2(100, 300)
						if not target_character.is_empty() and target_character.has("sprite") and target_character.sprite and is_instance_valid(target_character.sprite):
							tgt_pos = target_character.sprite.position
						indicator.start_indicator(_window_duration, 0.0, tgt_pos)

		ParryState.WINDOW_OPEN:
			_window_timer += delta
			# Advance strike frames during the parry window
			if _strike_frame_count > 1 and _window_duration > 0:
				var strike_frame_dur: float = _window_duration / float(_strike_frame_count)
				_anim_timer += delta
				if _anim_timer >= strike_frame_dur:
					_anim_timer -= strike_frame_dur
					_anim_frame_idx += 1
					if _anim_frame_idx < _strike_frame_count:
						var global_idx: int = _strike_frame_start + _anim_frame_idx
						if global_idx < _atk_frames.size():
							_set_entity_texture(attacker, _atk_frames[global_idx])
			# Window expired — auto miss
			if _window_timer >= _window_duration and _waiting_for_input:
				if indicator:
					indicator.stop_indicator()
				_on_parry_input("miss")

		ParryState.RESETTING:
			pass # waiting for reset tween callback, do nothing

func _reset_and_advance() -> void:
	current_state = ParryState.RESETTING
	if attacker.has("sprite") and attacker.sprite and is_instance_valid(attacker.sprite):
		var tween := create_tween()
		tween.tween_property(attacker.sprite, "position", _attacker_origin, 0.15) \
			.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)
		if attacker.has("target_height") and attacker.sprite.texture:
			var s_base: float = attacker.target_height / float(attacker.sprite.texture.get_height())
			tween.parallel().tween_property(attacker.sprite, "scale", Vector2(s_base, s_base), 0.15)
		await tween.finished
	else:
		await get_tree().create_timer(0.15).timeout
	current_hit_index += 1
	_start_next_hit()

func _lunge_at_target() -> void:
	if attacker.is_empty() or not attacker.has("sprite") or attacker.sprite == null or not is_instance_valid(attacker.sprite):
		return
	var sprite: Sprite2D = attacker.sprite
	var lunge_pos: Vector2
	if current_pattern and current_pattern.is_melee and not target_character.is_empty() and target_character.has("sprite") and target_character.sprite:
		# Melee: lunge right in front of the target (with gap so sprites don't overlap)
		var gap := 55.0
		lunge_pos = Vector2(target_character.sprite.position.x + gap, target_character.sprite.position.y)
	else:
		# Ranged: small fixed lunge toward party
		lunge_pos = _attacker_origin - Vector2(LUNGE_DISTANCE, 0)
	var tween := create_tween()
	tween.tween_property(sprite, "position", lunge_pos, 0.08) \
		.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)

func _get_frames_for_hit(_hit_index: int) -> int:
	if _atk_frames.is_empty():
		return 0
	# Count real hits (non-feint) in current pattern for frame distribution
	var real_hit_count: int = 0
	for h in current_pattern.hits:
		if h.get("window", 0.3) > 0.0:
			real_hit_count += 1
	if real_hit_count == 0:
		return 0
	return maxi(_atk_frames.size() / real_hit_count, 1)

func _get_frame_offset(hit_index: int) -> int:
	if _atk_frames.is_empty():
		return 0
	# Count real hits before this index to get correct frame offset
	var real_hits_before: int = 0
	for i in range(mini(hit_index, current_pattern.hits.size())):
		if current_pattern.hits[i].get("window", 0.3) > 0.0:
			real_hits_before += 1
	var per_hit: int = _get_frames_for_hit(hit_index)
	return mini(real_hits_before * per_hit, _atk_frames.size() - 1)

func _calculate_hit_damage(hit: Dictionary) -> int:
	if target_character.is_empty() or not target_character.has("data") or target_character.data == null:
		return 0
	if attacker.is_empty() or not attacker.has("data") or attacker.data == null:
		return 0
	var def: int = target_character.data.defense
	if target_character.has("buffs") and target_character.buffs.has("buff_def"):
		def = int(def * 1.3)
	if target_character.has("defending") and target_character.defending:
		def = int(def * 1.5)
	var dmg := DamageCalculator.calculate_enemy_damage(
		attacker.data.attack, def, hit.get("damage_pct", 1.0))
	if target_character.has("stance_damage_taken_mult"):
		dmg = maxi(1, int(dmg * target_character.stance_damage_taken_mult))
	return dmg

# ── Parry Input Handling ─────────────────────────────────────────────

func _on_parry_input(input_type: String) -> void:
	if not _waiting_for_input:
		return
	# Can't parry or dodge while in a defensive stance — hit always lands (with reduced damage)
	if input_type != "miss" and target_character.get("defending", false):
		input_type = "miss"
	_waiting_for_input = false
	current_state = ParryState.HIT_RESOLVING

	if indicator:
		indicator.stop_indicator()

	var target_pos := Vector2.ZERO
	if not target_character.is_empty() and target_character.has("sprite") and target_character.sprite and is_instance_valid(target_character.sprite):
		target_pos = target_character.sprite.position

	# Safety: if target or attacker data is missing, just resolve as miss and move on
	if target_character.is_empty() or not target_character.has("data") or target_character.data == null:
		await get_tree().create_timer(0.3).timeout
		_reset_and_advance()
		return

	match input_type:
		"parry":
			hits_parried += 1
			Sfx.play_random("parry_ting")
			Sfx.play("ap_gain", -6.0)
			if target_character.has("current_ap"):
				target_character.current_ap = mini(
					target_character.current_ap + 1,
					target_character.data.max_ap)
			if action_text_box:
				action_text_box.display("Perfect Parry! %s takes no damage and gains 1 AP!" % target_character.data.character_name)
			if effects:
				effects.play_vfx("parry_spark", target_pos, Color.WHITE, 0.3, 50.0)
				effects.spawn_text_popup(target_pos, "PARRY!", Color(0.2, 1.0, 0.4), 22)
				effects.spawn_damage_number(target_pos + Vector2(30, 10), 1, Color.CYAN, "+AP")
				effects.add_trauma(0.15)
		"dodge":
			hits_dodged += 1
			Sfx.play("dodge")
			if action_text_box:
				action_text_box.display("%s dodges the attack!" % target_character.data.character_name)
			if effects:
				effects.spawn_text_popup(target_pos, "DODGE!", Color(0.3, 0.9, 1.0), 20)
		"miss":
			hits_missed += 1
			total_damage += _current_hit_damage
			target_character.current_hp = maxi(0, target_character.current_hp - _current_hit_damage)
			Sfx.play("hit_taken")
			if action_text_box:
				action_text_box.display("%s takes %d damage!" % [target_character.data.character_name, _current_hit_damage])
			if effects:
				# Slash arc + impact for enemy hit landing
				Sfx.play_random("hit_physical")
				effects.play_vfx("slash_arc", target_pos, Color(0.6, 0.1, 0.9), 0.25, 50.0)
				effects.flash_sprite(target_character.sprite)
				effects.knockback_sprite(target_character.sprite, -1.0)
				effects.play_vfx("impact_burst", target_pos, Color(0.6, 0.1, 0.9), 0.35, 45.0)
				effects.spawn_damage_number(target_pos, _current_hit_damage, Color(1.0, 0.3, 0.3))
				effects.add_trauma(0.3)
				await effects.hit_stop(0.06)

	# Visual feedback on the target sprite
	if not target_character.is_empty() and target_character.has("sprite") and target_character.sprite and is_instance_valid(target_character.sprite):
		if input_type == "parry":
			var played := await _play_parry_animation(target_character, 0.5)
			if not played and effects:
				effects.flash_sprite(target_character.sprite)
		elif input_type == "dodge":
			if effects:
				var sprite: Sprite2D = target_character.sprite
				var orig: Vector2 = sprite.position
				var tween := create_tween()
				tween.tween_property(sprite, "position", orig + Vector2(-15, 0), 0.08)
				tween.tween_property(sprite, "position", orig, 0.15)

	await get_tree().create_timer(0.4).timeout
	_reset_and_advance()

func _play_parry_animation(ch: Dictionary, duration: float) -> bool:
	if not ch.has("animations"):
		return false
	var anims: Dictionary = ch.get("animations") as Dictionary
	if not anims.has("parry"):
		return false
	var frames: Array = anims.get("parry") as Array
	if frames == null or frames.is_empty():
		return false
	var sprite: Sprite2D = ch.sprite
	if sprite == null:
		return false
	var frame_count: int = frames.size()
	var frame_duration: float = duration / frame_count
	for f_idx in range(frame_count):
		_set_entity_texture(ch, frames[f_idx])
		await get_tree().create_timer(frame_duration).timeout
	if anims.has("idle"):
		var idle_frames: Array = anims.get("idle") as Array
		if not idle_frames.is_empty():
			_set_entity_texture(ch, idle_frames[0])
	return true

func _reset_attacker_sprite() -> void:
	if attacker.is_empty() or not attacker.has("sprite") or attacker.sprite == null or not is_instance_valid(attacker.sprite):
		return
	# Reset position and scale
	attacker.sprite.position = _attacker_origin
	if attacker.has("target_height") and attacker.sprite.texture:
		var tex_h: float = float(attacker.sprite.texture.get_height())
		if tex_h > 0:
			var s_base: float = attacker.target_height / tex_h
			attacker.sprite.scale = Vector2(s_base, s_base)
	# Reset to idle texture
	if attacker.has("animations"):
		var anims: Dictionary = attacker.animations
		if anims.has("idle") and not anims.idle.is_empty():
			_set_entity_texture(attacker, anims.idle[0])
			return
	if attacker.has("data") and attacker.data.sprite_path != "":
		var tex = load(attacker.data.sprite_path) as Texture2D
		if tex:
			_set_entity_texture(attacker, tex)

func _set_entity_texture(entity: Dictionary, tex: Texture2D) -> void:
	if entity.is_empty() or not entity.has("sprite") or entity.sprite == null or tex == null:
		return
	if not is_instance_valid(entity.sprite):
		return
	entity.sprite.texture = tex
	if entity.has("target_height"):
		var tex_h: float = float(tex.get_height())
		if tex_h > 0:
			var s: float = entity.target_height / tex_h
			entity.sprite.scale = Vector2(s, s)

func _finish_phase() -> void:
	current_state = ParryState.IDLE
	_waiting_for_input = false
	_reset_attacker_sprite()
	var all_parried := (hits_parried == total_hits and total_hits > 0)
	parry_phase_complete.emit({
		"total_damage": total_damage,
		"hits_parried": hits_parried,
		"hits_dodged": hits_dodged,
		"hits_missed": hits_missed,
		"all_parried": all_parried,
	})
