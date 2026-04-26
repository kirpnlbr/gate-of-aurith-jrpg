extends Node

## Centralized sound effect manager.
## Autoloaded as "Sfx" — call Sfx.play("hit_physical") from anywhere.

const SFX_BASE := "res://assets/audio/sfx/"
const BUS_MASTER := "Master"
const BUS_MUSIC := "Music"
const BUS_SFX := "SFX"
const BUS_UI := "UI"
const MIN_VOLUME_DB := -40.0
const MAX_VOLUME_DB := 6.0
const DEFAULT_BUS_VOLUMES_DB := {
	BUS_MASTER: -8.0,
	BUS_MUSIC: -12.0,
	BUS_SFX: -5.0,
	BUS_UI: -7.0,
}
const DEBUG_VOLUME_STEP_DB := 3.0

# ── Audio Bus Layout ─────────────────────────────────────────────────
var _bus_master: int = -1
var _bus_music: int = -1
var _bus_sfx: int = -1
var _bus_ui: int = -1

# ── Preloaded Streams ────────────────────────────────────────────────
var _streams: Dictionary = {}  # name -> AudioStream

# ── Sound Catalog ────────────────────────────────────────────────────
const CATALOG: Dictionary = {
	# Combat - Melee
	"hit_physical":    "combat/hit_physical_1.wav",
	"hit_physical_2":  "combat/hit_physical_2.wav",
	"hit_physical_3":  "combat/hit_physical_3.wav",
	"counter_hit":     "combat/counter_hit.ogg",
	"counter_hit_physical": "combat/counter_hit_physical.wav",
	"sword_swoosh":    "combat/sword_swoosh.wav",
	"heavy_swoosh":    "combat/heavy_swoosh.wav",
	"slash_arc":       "combat/slash_arc.wav",
	"sword_swing_pro": "combat/sword_swing_pro.wav",
	"sword_impact_pro":"combat/sword_impact_pro.wav",

	# Combat - Impacts & Effects
	"impact_heavy":    "combat/impact_heavy_1.wav",
	"impact_heavy_2":  "combat/impact_heavy_2.wav",
	"knockback":       "combat/knockback.wav",
	"screen_shake":    "combat/screen_shake.wav",

	# Combat - Actions
	"stance_to_shield":"combat/stance_switch.wav",
	"stance_to_sword": "combat/stance_switch_2.wav",
	"taunt":           "combat/taunt.wav",
	"taunt_2":         "combat/taunt_2.wav",
	"defend":          "combat/defend.ogg",
	"shield_bash":     "combat/shield_bash.wav",
	"shield_slam":     "combat/shield_slam.wav",

	# Parry System
	"parry_ting":      "parry/parry_ting.wav",
	"parry_ting_2":    "parry/parry_ting_synth2.wav",
	"parry_bell":      "parry/parry_bell.wav",
	"shield_block":    "parry/shield_block.wav",
	"window_open":     "parry/window_open.wav",
	"flash_cue":       "parry/flash_cue.wav",
	"hit_taken":       "parry/hit_taken.ogg",
	"enemy_windup":    "parry/enemy_windup.wav",
	"feint":           "parry/feint.wav",
	"dodge":           "parry/dodge.wav",
	"ap_gain":         "parry/ap_gain.wav",

	# Magic - Fire (crackling, explosive)
	"fire_cast":       "magic/fire_cast.wav",
	"fire_crackle":    "magic/fire_crackle.ogg",
	"fire_impact":     "magic/fire_impact.ogg",

	# Magic - Ice (crystalline, shattering)
	"ice_cast":        "magic/ice_cast.wav",
	"ice_impact":      "magic/ice_impact.wav",

	# Magic - Thunder (proper zap spell sounds)
	"thunder_cast":    "magic/thunder_cast.ogg",
	"thunder_bolt":    "magic/thunder_bolt.ogg",
	"thunder_impact":  "magic/thunder_impact.ogg",
	"thunder_rumble":  "magic/thunder_rumble.ogg",
	"thunder_strike":  "magic/thunder_strike.wav",

	# Magic - Water (splash, wave)
	"water_cast":      "magic/water_cast.wav",
	"water_impact":    "magic/water_impact.ogg",
	"water_splash":    "magic/water_splash.ogg",

	# Magic - Generic
	"spell_cast":      "magic/spell_cast.ogg",
	"spell_impact":    "magic/spell_impact.ogg",
	"projectile":      "magic/projectile_1.ogg",
	"projectile_2":    "magic/projectile_2.ogg",
	"lava_eruption":   "magic/lava_eruption.ogg",
	"counter_magic":   "magic/counter_magic.wav",
	"counter_magic_alt":"magic/counter_magic_alt.wav",

	# Magic - Support
	"buff_apply":      "magic/buff_apply.ogg",
	"heal":            "magic/heal.wav",
	"summon":          "magic/summon.ogg",
	"burn_tick":       "magic/burn_tick.ogg",
	"status_apply":    "magic/status_apply.ogg",

	# Death
	"enemy_death":     "death/enemy_death.ogg",
	"party_death":     "death/party_death.ogg",

	# UI
	"menu_move":       "ui/menu_move.wav",
	"menu_select":     "ui/menu_select.wav",
	"menu_cancel":     "ui/menu_cancel.wav",
	"item_pickup":     "ui/item_pickup.wav",
	"item_use":        "ui/item_use.wav",
	"victory":         "ui/victory.wav",
	"defeat":          "ui/defeat.wav",
	"battle_encounter":"ui/battle_encounter.wav",
	"xp_gain":         "ui/xp_gain.ogg",

	# Movement
	"footstep":        "movement/footstep.ogg",
	"step_forward":    "movement/step_forward.ogg",
}

# Map element names to cast SFX
const ELEMENT_CAST_MAP: Dictionary = {
	"fire":    "fire_cast",
	"ice":     "ice_cast",
	"thunder": "thunder_bolt",
	"water":   "water_cast",
	"lava":    "fire_cast",
	"wind":    "sword_swoosh",
	"earth":   "impact_heavy",
}

# Map element names to impact SFX (distinct per element!)
const ELEMENT_IMPACT_MAP: Dictionary = {
	"fire":    "fire_impact",
	"ice":     "ice_impact",
	"thunder": "thunder_impact",
	"water":   "water_impact",
	"lava":    "lava_eruption",
	"wind":    "slash_arc",
	"earth":   "impact_heavy",
}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_buses()
	reset_bus_volumes()
	_preload_all()

func _setup_buses() -> void:
	_bus_master = AudioServer.get_bus_index(BUS_MASTER)
	_bus_music = _ensure_bus(BUS_MUSIC, BUS_MASTER)
	_bus_sfx = _ensure_bus(BUS_SFX, BUS_MASTER)
	_bus_ui = _ensure_bus(BUS_UI, BUS_MASTER)

func _ensure_bus(bus_name: String, send_name: String) -> int:
	var bus_index := AudioServer.get_bus_index(bus_name)
	if bus_index == -1:
		AudioServer.add_bus()
		bus_index = AudioServer.bus_count - 1
		AudioServer.set_bus_name(bus_index, bus_name)
	AudioServer.set_bus_send(bus_index, send_name)
	return bus_index

func _preload_all() -> void:
	for key in CATALOG:
		var path: String = SFX_BASE + CATALOG[key]
		if ResourceLoader.exists(path):
			_streams[key] = load(path) as AudioStream
		else:
			push_warning("SfxManager: missing audio file: " + path)

# ── Public API ───────────────────────────────────────────────────────

func play(sound_name: String, volume_db: float = 0.0, pitch_scale: float = 1.0) -> AudioStreamPlayer:
	if not _streams.has(sound_name):
		push_warning("SfxManager: unknown sound '" + sound_name + "'")
		return null
	var player := AudioStreamPlayer.new()
	player.stream = _streams[sound_name]
	player.volume_db = volume_db
	player.pitch_scale = pitch_scale
	player.bus = _get_bus_name(sound_name)
	player.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(player)
	player.play()
	player.finished.connect(player.queue_free)
	return player

func play_random(base_name: String, volume_db: float = 0.0, pitch_variation: float = 0.1) -> AudioStreamPlayer:
	var variants: Array[String] = [base_name]
	for suffix in ["_2", "_3", "_4", "_5"]:
		if _streams.has(base_name + suffix):
			variants.append(base_name + suffix)
	var chosen: String = variants[randi() % variants.size()]
	var pitch: float = 1.0 + randf_range(-pitch_variation, pitch_variation)
	return play(chosen, volume_db, pitch)

func play_element_cast(element: String, volume_db: float = 0.0) -> AudioStreamPlayer:
	var sound_name: String = ELEMENT_CAST_MAP.get(element.to_lower(), "spell_cast")
	return play(sound_name, volume_db)

func play_element_impact(element: String, volume_db: float = 0.0) -> AudioStreamPlayer:
	var sound_name: String = ELEMENT_IMPACT_MAP.get(element.to_lower(), "spell_impact")
	return play(sound_name, volume_db)

func play_ui(sound_name: String, volume_db: float = -3.0) -> AudioStreamPlayer:
	return play(sound_name, volume_db)

func set_bus_volume(bus_name: String, linear: float) -> void:
	var idx: int = AudioServer.get_bus_index(bus_name)
	if idx >= 0:
		AudioServer.set_bus_volume_db(idx, linear_to_db(linear))

func set_bus_volume_db(bus_name: String, volume_db: float) -> void:
	var idx: int = AudioServer.get_bus_index(bus_name)
	if idx >= 0:
		AudioServer.set_bus_volume_db(idx, clampf(volume_db, MIN_VOLUME_DB, MAX_VOLUME_DB))

func get_bus_volume_db(bus_name: String) -> float:
	var idx: int = AudioServer.get_bus_index(bus_name)
	if idx >= 0:
		return AudioServer.get_bus_volume_db(idx)
	return 0.0

func adjust_bus_volume_db(bus_name: String, delta_db: float) -> float:
	var next_volume := get_bus_volume_db(bus_name) + delta_db
	set_bus_volume_db(bus_name, next_volume)
	return get_bus_volume_db(bus_name)

func set_bus_mute(bus_name: String, muted: bool) -> void:
	var idx: int = AudioServer.get_bus_index(bus_name)
	if idx >= 0:
		AudioServer.set_bus_mute(idx, muted)

func is_bus_muted(bus_name: String) -> bool:
	var idx: int = AudioServer.get_bus_index(bus_name)
	if idx >= 0:
		return AudioServer.is_bus_mute(idx)
	return false

func toggle_bus_mute(bus_name: String) -> bool:
	var muted := not is_bus_muted(bus_name)
	set_bus_mute(bus_name, muted)
	return muted

func reset_bus_volumes() -> void:
	for bus_name in DEFAULT_BUS_VOLUMES_DB:
		set_bus_volume_db(bus_name, DEFAULT_BUS_VOLUMES_DB[bus_name])
		set_bus_mute(bus_name, false)

func get_volume_summary() -> String:
	return "Master %sdB | Music %sdB | SFX %sdB | UI %sdB" % [
		_format_db(get_bus_volume_db(BUS_MASTER)),
		_format_db(get_bus_volume_db(BUS_MUSIC)),
		_format_db(get_bus_volume_db(BUS_SFX)),
		_format_db(get_bus_volume_db(BUS_UI)),
	]

func _get_bus_name(sound_name: String) -> String:
	if sound_name.begins_with("menu_") or sound_name in ["victory", "defeat", "battle_encounter", "item_pickup", "item_use", "xp_gain"]:
		return BUS_UI
	return BUS_SFX

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.ctrl_pressed:
		match event.keycode:
			KEY_MINUS:
				_print_volume_change(BUS_MASTER, adjust_bus_volume_db(BUS_MASTER, -DEBUG_VOLUME_STEP_DB))
				get_viewport().set_input_as_handled()
			KEY_EQUAL:
				_print_volume_change(BUS_MASTER, adjust_bus_volume_db(BUS_MASTER, DEBUG_VOLUME_STEP_DB))
				get_viewport().set_input_as_handled()
			KEY_0:
				reset_bus_volumes()
				print("Audio reset: %s" % get_volume_summary())
				get_viewport().set_input_as_handled()

func _format_db(volume_db: float) -> String:
	return "%+.1f" % volume_db

func _print_volume_change(bus_name: String, volume_db: float) -> void:
	print("%s volume: %sdB" % [bus_name, _format_db(volume_db)])

# ── BGM System ───────────────────────────────────────────────────────

const MUSIC_BASE := "res://assets/audio/music/"
const BGM_TRACKS: Dictionary = {
	"overworld":     "overworld.ogg",
	"battle":        "battle_theme.mp3",
	"battle_intro":  "battle_intro.mp3",
	"boss":          "boss_battle.ogg",
}

var _bgm_player: AudioStreamPlayer = null
var _current_bgm: String = ""

func play_bgm(track_name: String, volume_db: float = -6.0, fade_in: float = 0.5) -> void:
	if track_name == _current_bgm:
		return
	stop_bgm(0.3)
	await get_tree().create_timer(0.35).timeout
	if not BGM_TRACKS.has(track_name):
		push_warning("SfxManager: unknown BGM track '" + track_name + "'")
		return
	var path: String = MUSIC_BASE + BGM_TRACKS[track_name]
	if not ResourceLoader.exists(path):
		push_warning("SfxManager: missing BGM file: " + path)
		return
	_bgm_player = AudioStreamPlayer.new()
	var stream = load(path)
	if stream is AudioStreamOggVorbis:
		stream.loop = true
	elif stream is AudioStreamMP3:
		stream.loop = true
	_bgm_player.stream = stream
	_bgm_player.bus = BUS_MUSIC
	_bgm_player.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_bgm_player)
	_current_bgm = track_name
	# Fade in
	_bgm_player.volume_db = -40.0
	_bgm_player.play()
	var tween := create_tween()
	tween.tween_property(_bgm_player, "volume_db", volume_db, fade_in)

func stop_bgm(fade_out: float = 0.5) -> void:
	if _bgm_player == null or not is_instance_valid(_bgm_player):
		_current_bgm = ""
		return
	_current_bgm = ""
	var player := _bgm_player
	_bgm_player = null
	var tween := create_tween()
	tween.tween_property(player, "volume_db", -40.0, fade_out)
	tween.tween_callback(player.queue_free)
