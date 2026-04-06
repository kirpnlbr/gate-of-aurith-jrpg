class_name BattleEffects
extends Node2D

# ── Screen Shake ─────────────────────────────────────────────────────
var _trauma: float = 0.0
var _noise := FastNoiseLite.new()
var _noise_y: int = 0
var _shake_target: Node2D = null

const SHAKE_DECAY := 2.5
const SHAKE_MAX_OFFSET := Vector2(8.0, 6.0)

# ── Damage Number Layer ──────────────────────────────────────────────
var _number_layer: CanvasLayer = null

# ── VFX System ───────────────────────────────────────────────────────
const VFX_BASE := "res://assets/sprites/battle/frames/vfx/"
const VFX_HEIGHT := 80.0  # Target display height for VFX overlays
var _vfx_cache: Dictionary = {}  # folder_name -> Array[Texture2D]
var _active_auras: Dictionary = {}  # entity sprite instance_id -> Sprite2D

func setup(sprite_root: Node2D, hud_layer: CanvasLayer) -> void:
	_shake_target = sprite_root
	_noise.seed = randi()
	_noise.frequency = 0.8
	_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	if hud_layer:
		_number_layer = hud_layer

func _process(delta: float) -> void:
	if _trauma > 0 and _shake_target:
		_trauma = maxf(_trauma - SHAKE_DECAY * delta, 0.0)
		var shake_amount: float = _trauma * _trauma
		_noise_y += 1
		_shake_target.position = Vector2(
			SHAKE_MAX_OFFSET.x * shake_amount * _noise.get_noise_2d(float(_noise.seed), float(_noise_y)),
			SHAKE_MAX_OFFSET.y * shake_amount * _noise.get_noise_2d(float(_noise.seed * 2), float(_noise_y))
		)
	elif _shake_target and _shake_target.position != Vector2.ZERO:
		_shake_target.position = Vector2.ZERO

# ── Public API ───────────────────────────────────────────────────────

func add_trauma(amount: float) -> void:
	_trauma = minf(_trauma + amount, 1.0)

func hit_stop(duration: float = 0.08) -> void:
	Engine.time_scale = 0.05
	await get_tree().create_timer(duration, false, false, true).timeout
	Engine.time_scale = 1.0

func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		Engine.time_scale = 1.0

func flash_sprite(sprite: Sprite2D, duration: float = 0.12) -> void:
	if sprite == null or not is_instance_valid(sprite) or sprite.material == null:
		return
	if not sprite.material is ShaderMaterial:
		return
	var mat: ShaderMaterial = sprite.material as ShaderMaterial
	mat.set_shader_parameter("flash_active", true)
	mat.set_shader_parameter("flash_intensity", 1.0)
	await get_tree().create_timer(duration).timeout
	if is_instance_valid(sprite) and sprite.material is ShaderMaterial:
		(sprite.material as ShaderMaterial).set_shader_parameter("flash_active", false)

func knockback_sprite(sprite: Sprite2D, direction: float = 1.0, distance: float = 15.0) -> void:
	if sprite == null or not is_instance_valid(sprite):
		return
	var original_pos: Vector2 = sprite.position
	var offset := Vector2(distance * direction, 0)
	var tween := create_tween()
	tween.tween_property(sprite, "position", original_pos + offset, 0.06) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(sprite, "position", original_pos, 0.15) \
		.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)

func step_forward(sprite: Sprite2D, target_x: float, duration: float = 0.2) -> void:
	if sprite == null:
		return
	var original_pos: Vector2 = sprite.position
	var step_amount: float = (target_x - sprite.position.x) * 0.35
	var step_pos := Vector2(sprite.position.x + step_amount, sprite.position.y)
	var tween := create_tween()
	tween.tween_property(sprite, "position", step_pos, duration) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	await tween.finished

## Move the sprite right in front of the target (melee close-range positioning).
## Moves both X and Y so the attacker ends up directly in front of the target.
## gap_px is the pixel distance to stop short of the target so sprites don't overlap.
func step_close(sprite: Sprite2D, target_pos: Vector2, gap_px: float = 55.0, duration: float = 0.18) -> void:
	if sprite == null:
		return
	var direction := signf(target_pos.x - sprite.position.x)
	var close_x: float = target_pos.x - direction * gap_px
	var close_pos := Vector2(close_x, target_pos.y)
	var tween := create_tween()
	tween.tween_property(sprite, "position", close_pos, duration) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	await tween.finished

func step_back(sprite: Sprite2D, original_pos: Vector2, duration: float = 0.25) -> void:
	if sprite == null:
		return
	var tween := create_tween()
	tween.tween_property(sprite, "position", original_pos, duration) \
		.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)
	await tween.finished

# ── Damage Numbers ───────────────────────────────────────────────────

func spawn_damage_number(world_pos: Vector2, value: int, color: Color = Color.WHITE, prefix: String = "", is_crit: bool = false) -> void:
	if _number_layer == null:
		return
	var label := Label.new()
	var display_text: String = prefix + str(value) if prefix == "" else prefix
	if prefix == "" :
		display_text = str(value)
	elif prefix != "" and value > 0:
		display_text = prefix + "\n" + str(value)
	else:
		display_text = prefix
	label.text = display_text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", color)
	var font_size: int = 18 if not is_crit else 24
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	label.add_theme_constant_override("outline_size", 3)
	label.position = world_pos + Vector2(-30, -40)
	label.z_index = 100
	label.pivot_offset = Vector2(30, 10)
	_number_layer.add_child(label)

	var start_scale := Vector2(1.0, 1.0)
	if is_crit:
		start_scale = Vector2(1.8, 1.8)
	label.scale = start_scale

	var drift := Vector2(randf_range(-20, 20), -50)
	var tween := create_tween().set_parallel(true)
	tween.tween_property(label, "position", label.position + drift, 0.9) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(label, "modulate:a", 0.0, 0.9) \
		.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	if is_crit:
		tween.tween_property(label, "scale", Vector2(1.0, 1.0), 0.25) \
			.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	await tween.finished
	if is_instance_valid(label):
		label.queue_free()

func spawn_text_popup(world_pos: Vector2, text: String, color: Color = Color.GOLD, font_size: int = 20) -> void:
	if _number_layer == null:
		return
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", color)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	label.add_theme_constant_override("outline_size", 4)
	label.position = world_pos + Vector2(-40, -55)
	label.z_index = 100
	label.scale = Vector2(1.4, 1.4)
	label.pivot_offset = Vector2(40, 10)
	_number_layer.add_child(label)

	var tween := create_tween().set_parallel(true)
	tween.tween_property(label, "position:y", label.position.y - 30, 0.7) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(label, "scale", Vector2(1.0, 1.0), 0.2) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_property(label, "modulate:a", 0.0, 0.7) \
		.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	await tween.finished
	if is_instance_valid(label):
		label.queue_free()

# ── Death Effects ────────────────────────────────────────────────────

func play_enemy_death(sprite: Sprite2D) -> void:
	if sprite == null:
		return
	# White flash
	flash_sprite(sprite, 0.15)
	await get_tree().create_timer(0.15).timeout
	# Dissolve
	var tween := create_tween()
	tween.tween_property(sprite, "modulate:a", 0.0, 0.4) \
		.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	add_trauma(0.2)
	await tween.finished
	sprite.visible = false

func play_party_death(sprite: Sprite2D) -> void:
	if sprite == null:
		return
	# Rapid flicker
	for i in range(6):
		sprite.visible = !sprite.visible
		await get_tree().create_timer(0.07).timeout
	sprite.visible = true
	# Fade to ghostly
	var tween := create_tween()
	tween.tween_property(sprite, "modulate:a", 0.2, 0.3)
	await tween.finished

# ── VFX Overlay System ───────────────────────────────────────────────

func _load_vfx_frames(folder_name: String) -> Array:
	if _vfx_cache.has(folder_name):
		return _vfx_cache[folder_name]
	var frames: Array = []
	var folder_path: String = VFX_BASE + folder_name
	var i: int = 0
	while i < 20:
		var frame_path: String = folder_path + "/frame_" + str(i) + ".png"
		if not ResourceLoader.exists(frame_path):
			break
		var tex: Texture2D = load(frame_path) as Texture2D
		if tex:
			frames.append(tex)
		i += 1
	_vfx_cache[folder_name] = frames
	return frames

func _create_vfx_sprite(pos: Vector2, tint: Color, height: float = VFX_HEIGHT) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.position = pos
	sprite.modulate = tint
	sprite.z_index = 50
	if _shake_target:
		_shake_target.add_child(sprite)
	else:
		add_child(sprite)
	return sprite

func _size_vfx_sprite(sprite: Sprite2D, tex: Texture2D, height: float) -> void:
	if tex.get_height() > 0:
		var s: float = height / float(tex.get_height())
		sprite.scale = Vector2(s, s)

## Play a VFX animation at a position. Non-blocking (fire and forget).
func play_vfx(folder_name: String, pos: Vector2, tint: Color = Color.WHITE, duration: float = 0.6, height: float = VFX_HEIGHT) -> void:
	var frames := _load_vfx_frames(folder_name)
	if frames.is_empty():
		return
	var sprite := _create_vfx_sprite(pos, tint, height)
	sprite.texture = frames[0]
	_size_vfx_sprite(sprite, frames[0], height)
	var frame_dur: float = duration / frames.size()
	for f_idx in range(frames.size()):
		sprite.texture = frames[f_idx]
		_size_vfx_sprite(sprite, frames[f_idx], height)
		await get_tree().create_timer(frame_dur).timeout
		if not is_instance_valid(sprite):
			return
	sprite.queue_free()

## Play a VFX and await it (blocking version).
func play_vfx_await(folder_name: String, pos: Vector2, tint: Color = Color.WHITE, duration: float = 0.6, height: float = VFX_HEIGHT) -> void:
	await play_vfx(folder_name, pos, tint, duration, height)

## Play a projectile VFX that travels from start_pos to end_pos.
func play_projectile(folder_name: String, start_pos: Vector2, end_pos: Vector2, tint: Color = Color.WHITE, duration: float = 0.5, height: float = 60.0) -> void:
	var frames := _load_vfx_frames(folder_name)
	if frames.is_empty():
		return
	var sprite := _create_vfx_sprite(start_pos, tint, height)
	sprite.texture = frames[0]
	_size_vfx_sprite(sprite, frames[0], height)
	# Flip if traveling right-to-left (enemy attacking party)
	if end_pos.x < start_pos.x:
		sprite.flip_h = true
	# Animate frames + tween position simultaneously
	var tween := create_tween()
	tween.tween_property(sprite, "position", end_pos, duration) \
		.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	var frame_dur: float = duration / frames.size()
	for f_idx in range(frames.size()):
		sprite.texture = frames[f_idx]
		_size_vfx_sprite(sprite, frames[f_idx], height)
		await get_tree().create_timer(frame_dur).timeout
		if not is_instance_valid(sprite):
			return
	sprite.queue_free()

## Start a looping aura VFX on an entity. Returns immediately.
func start_aura(entity_sprite: Sprite2D, folder_name: String, tint: Color = Color.WHITE, height: float = VFX_HEIGHT) -> void:
	if entity_sprite == null or not is_instance_valid(entity_sprite):
		return
	var key: int = entity_sprite.get_instance_id()
	# Remove existing aura on this entity first
	stop_aura(entity_sprite)
	var frames := _load_vfx_frames(folder_name)
	if frames.is_empty():
		return
	var sprite := _create_vfx_sprite(entity_sprite.position, tint, height)
	sprite.texture = frames[0]
	_size_vfx_sprite(sprite, frames[0], height)
	_active_auras[key] = sprite
	# Loop in background
	_run_aura_loop(sprite, frames, key, height)

func _run_aura_loop(sprite: Sprite2D, frames: Array, key: int, height: float) -> void:
	while is_instance_valid(sprite) and _active_auras.has(key) and _active_auras[key] == sprite:
		for f_idx in range(frames.size()):
			if not is_instance_valid(sprite) or not _active_auras.has(key) or _active_auras[key] != sprite:
				return
			sprite.texture = frames[f_idx]
			_size_vfx_sprite(sprite, frames[f_idx], height)
			await get_tree().create_timer(0.12).timeout

## Stop and remove an aura VFX from an entity.
func stop_aura(entity_sprite: Sprite2D) -> void:
	if entity_sprite == null:
		return
	var key: int = entity_sprite.get_instance_id()
	if _active_auras.has(key):
		var old_sprite: Sprite2D = _active_auras[key]
		_active_auras.erase(key)
		if is_instance_valid(old_sprite):
			old_sprite.queue_free()

## Stop all active auras (call on battle end).
func stop_all_auras() -> void:
	for key in _active_auras.keys():
		var sprite: Sprite2D = _active_auras[key]
		if is_instance_valid(sprite):
			sprite.queue_free()
	_active_auras.clear()
