class_name PartyState
extends RefCounted

var characters: Array[Dictionary] = []
# Each: { "data": CharacterData, "current_hp": int, "current_ap": int, "level": int, "xp": int }
var items: Array[Dictionary] = []
# Each: { "data": ItemData, "quantity": int }
var gustave_stance: String = "greatsword" # or "greatshield"

func setup() -> void:
	_init_characters()
	_init_items()

func _init_characters() -> void:
	characters.clear()
	# Mage - Glass cannon, elemental magic
	var mage_data := CharacterData.new()
	mage_data.character_name = "Mage"
	mage_data.max_hp = 60
	mage_data.max_ap = 40
	mage_data.attack = 8
	mage_data.defense = 5
	mage_data.magic_attack = 18
	mage_data.magic_defense = 12
	mage_data.speed = 14
	mage_data.battle_color = Color(0.3, 0.5, 1.0) # blue
	mage_data.sprite_idle = "res://assets/sprites/battle/frames/mage_idle"
	mage_data.sprite_attack = "res://assets/sprites/battle/frames/mage_attack"
	mage_data.sprite_parry = "res://assets/sprites/battle/frames/mage_parry"
	mage_data.sprite_counter = "res://assets/sprites/battle/frames/mage_counter"
	mage_data.sprite_defend = "res://assets/sprites/battle/frames/mage_defend"
	mage_data.defend_hold_frame = 5
	mage_data.sprite_skill = "res://assets/sprites/battle/frames/mage_fireball"
	mage_data.skill_sprite_map = {
		"Fireball": "res://assets/sprites/battle/frames/mage_fireball",
		"Inferno": "res://assets/sprites/battle/frames/mage_inferno",
		"Thunder Pulse": "res://assets/sprites/battle/frames/mage_thunder",
		"Ice Lance": "res://assets/sprites/battle/frames/mage_ice_lance",
		"Tidal Wave": "res://assets/sprites/battle/frames/mage_tidal_wave",
		"Lava Burst": "res://assets/sprites/battle/frames/mage_lava_burst",
	}
	mage_data.skills = _create_mage_skills()

	# Gustave - Tank/hybrid with stance switching
	var gustave_data := CharacterData.new()
	gustave_data.character_name = "Gustave"
	gustave_data.max_hp = 100
	gustave_data.max_ap = 20
	gustave_data.attack = 15
	gustave_data.defense = 14
	gustave_data.magic_attack = 6
	gustave_data.magic_defense = 8
	gustave_data.speed = 10
	gustave_data.battle_color = Color(0.9, 0.2, 0.2) # red
	gustave_data.sprite_idle = "res://assets/sprites/battle/frames/gustave_idle"
	gustave_data.sprite_idle_alt = "res://assets/sprites/battle/frames/gustave_idle_alt"
	gustave_data.sprite_attack = "res://assets/sprites/battle/frames/gustave_attack"
	gustave_data.sprite_parry = "res://assets/sprites/battle/frames/gustave_parry"
	gustave_data.sprite_parry_alt = "res://assets/sprites/battle/frames/gustave_parry_alt"
	gustave_data.sprite_counter = "res://assets/sprites/battle/frames/gustave_counter"
	gustave_data.sprite_counter_alt = "res://assets/sprites/battle/frames/gustave_counter_alt"
	gustave_data.sprite_defend = "res://assets/sprites/battle/frames/gustave_defend"
	gustave_data.sprite_defend_alt = "res://assets/sprites/battle/frames/gustave_defend_alt"
	gustave_data.defend_hold_frame = 5
	gustave_data.defend_hold_frame_alt = 7
	gustave_data.sprite_skill = "res://assets/sprites/battle/frames/gustave_attack"
	gustave_data.skill_sprite_map = {
		"Heavy Slash": "res://assets/sprites/battle/frames/gustave_heavy_slash",
		"Whirlwind": "res://assets/sprites/battle/frames/gustave_whirlwind",
		"Taunt": "res://assets/sprites/battle/frames/gustave_taunt",
		"Aegis Beam": "res://assets/sprites/battle/frames/gustave_aegis_beam",
		"Bulwark": "res://assets/sprites/battle/frames/gustave_bulwark",
		"_stance_to_shield": "res://assets/sprites/battle/frames/gustave_stance_switch",
		"_stance_to_sword": "res://assets/sprites/battle/frames/gustave_stance_switch_back",
	}
	gustave_data.skills = _create_gustave_skills()

	# Sage - Support, manifestation summons
	var sage_data := CharacterData.new()
	sage_data.character_name = "Sage"
	sage_data.max_hp = 75
	sage_data.max_ap = 35
	sage_data.attack = 6
	sage_data.defense = 8
	sage_data.magic_attack = 14
	sage_data.magic_defense = 14
	sage_data.speed = 12
	sage_data.battle_color = Color(0.2, 0.8, 0.3) # green
	sage_data.sprite_idle = "res://assets/sprites/battle/frames/sage_idle"
	sage_data.sprite_attack = "res://assets/sprites/battle/frames/sage_attack"
	sage_data.sprite_parry = "res://assets/sprites/battle/frames/sage_parry"
	sage_data.sprite_counter = "res://assets/sprites/battle/frames/sage_counter"
	sage_data.sprite_defend = "res://assets/sprites/battle/frames/sage_defend"
	sage_data.defend_hold_frame = 6
	sage_data.sprite_skill = "res://assets/sprites/battle/frames/sage_attack"
	sage_data.skill_sprite_map = {
		"Phoenix Manifestation": "res://assets/sprites/battle/frames/sage_phoenix",
		"Phoenix Rise": "res://assets/sprites/battle/frames/sage_phoenix",
		"Leviathan Manifestation": "res://assets/sprites/battle/frames/sage_leviathan",
		"Thunderbird Manifestation": "res://assets/sprites/battle/frames/sage_thunderbird",
		"Griffin Manifestation": "res://assets/sprites/battle/frames/sage_buff",
		"Golem Manifestation": "res://assets/sprites/battle/frames/sage_buff",
		"Basilisk Manifestation": "res://assets/sprites/battle/frames/sage_basilisk",
	}
	sage_data.skills = _create_sage_skills()

	for data in [mage_data, gustave_data, sage_data]:
		characters.append({
			"data": data,
			"current_hp": data.max_hp,
			"current_ap": data.max_ap,
			"level": 1,
			"xp": 0,
		})

func _init_items() -> void:
	items.clear()
	var potion := ItemData.new()
	potion.item_name = "Potion"
	potion.effect_type = "heal_hp"
	potion.value = 30
	potion.target_type = "single_ally"
	potion.description = "Restore 30 HP to one ally."
	potion.action_text = "{user} uses Potion on {target}! Restored {value} HP!"
	items.append({"data": potion, "quantity": 3})

	var ether := ItemData.new()
	ether.item_name = "Ether"
	ether.effect_type = "heal_ap"
	ether.value = 15
	ether.target_type = "single_ally"
	ether.description = "Restore 15 AP to one ally."
	ether.action_text = "{user} uses Ether on {target}! Restored {value} AP!"
	items.append({"data": ether, "quantity": 4})

	var revive := ItemData.new()
	revive.item_name = "Revive Crystal"
	revive.effect_type = "revive"
	revive.value = 50 # revive at 50% HP
	revive.target_type = "single_ally"
	revive.description = "Revive a fallen ally at 50% HP."
	revive.action_text = "{user} uses Revive Crystal on {target}! {target} is back on their feet!"
	items.append({"data": revive, "quantity": 1})

# ── Mage Skills ──────────────────────────────────────────────────────
func _create_mage_skills() -> Array[Resource]:
	var skills: Array[Resource] = []

	var fireball := SkillData.new()
	fireball.skill_name = "Fireball"
	fireball.ap_cost = 6
	fireball.power = 14
	fireball.element = "fire"
	fireball.target_type = "single_enemy"
	fireball.effect_type = "damage"
	fireball.description = "Hurl a fireball at one enemy. Fire element. May inflict Ablaze (DoT)."
	fireball.action_text = "Mage casts Fireball! {target} takes {value} fire damage!"
	fireball.status_effect = "ablaze"
	fireball.status_effect_chance = 0.25
	skills.append(fireball)

	var inferno := SkillData.new()
	inferno.skill_name = "Inferno"
	inferno.ap_cost = 12
	inferno.power = 10
	inferno.element = "fire"
	inferno.target_type = "all_enemies"
	inferno.effect_type = "damage"
	inferno.description = "Engulf all enemies in flames. Fire element. May inflict Ablaze (DoT)."
	inferno.action_text = "Mage unleashes Inferno! All enemies take {value} fire damage!"
	inferno.status_effect = "ablaze"
	inferno.status_effect_chance = 0.2
	skills.append(inferno)

	var thunder := SkillData.new()
	thunder.skill_name = "Thunder Pulse"
	thunder.ap_cost = 8
	thunder.power = 16
	thunder.element = "lightning"
	thunder.target_type = "single_enemy"
	thunder.effect_type = "damage"
	thunder.description = "Strike one enemy with lightning. Lightning element. May inflict Shocked (skip turn)."
	thunder.action_text = "Mage calls down Thunder Pulse! {target} takes {value} lightning damage!"
	thunder.status_effect = "shocked"
	thunder.status_effect_chance = 0.2
	skills.append(thunder)

	var ice_lance := SkillData.new()
	ice_lance.skill_name = "Ice Lance"
	ice_lance.ap_cost = 7
	ice_lance.power = 13
	ice_lance.element = "ice"
	ice_lance.target_type = "single_enemy"
	ice_lance.effect_type = "damage"
	ice_lance.description = "Pierce one enemy with ice. Ice element. May inflict Chilled (slow)."
	ice_lance.action_text = "Mage hurls an Ice Lance! {target} takes {value} ice damage!"
	ice_lance.status_effect = "chilled"
	ice_lance.status_effect_chance = 0.3
	skills.append(ice_lance)

	var tidal_wave := SkillData.new()
	tidal_wave.skill_name = "Tidal Wave"
	tidal_wave.ap_cost = 10
	tidal_wave.power = 12
	tidal_wave.element = "water"
	tidal_wave.target_type = "all_enemies"
	tidal_wave.effect_type = "damage"
	tidal_wave.description = "Crash a wave into all enemies. Water element. May inflict Soaked (DEF down)."
	tidal_wave.action_text = "Mage summons a Tidal Wave! All enemies take {value} water damage!"
	tidal_wave.status_effect = "soaked"
	tidal_wave.status_effect_chance = 0.2
	skills.append(tidal_wave)

	var lava_burst := SkillData.new()
	lava_burst.skill_name = "Lava Burst"
	lava_burst.ap_cost = 14
	lava_burst.power = 20
	lava_burst.element = "lava"
	lava_burst.target_type = "single_enemy"
	lava_burst.effect_type = "damage"
	lava_burst.description = "Erupt molten lava on one enemy. Lava element. High power. Inflicts Ablaze (DoT)."
	lava_burst.action_text = "Mage erupts with Lava Burst! {target} takes {value} lava damage!"
	lava_burst.status_effect = "ablaze"
	lava_burst.status_effect_chance = 0.4
	skills.append(lava_burst)

	return skills

# ── Gustave Skills ───────────────────────────────────────────────────
func _create_gustave_skills() -> Array[Resource]:
	var skills: Array[Resource] = []

	var heavy_slash := SkillData.new()
	heavy_slash.skill_name = "Heavy Slash"
	heavy_slash.ap_cost = 5
	heavy_slash.power = 16
	heavy_slash.element = "none"
	heavy_slash.target_type = "single_enemy"
	heavy_slash.effect_type = "damage"
	heavy_slash.required_stance = "greatsword"
	heavy_slash.description = "A powerful overhead strike on one enemy. Greatsword only."
	heavy_slash.action_text = "Gustave delivers a Heavy Slash! {target} takes {value} damage!"
	skills.append(heavy_slash)

	var whirlwind := SkillData.new()
	whirlwind.skill_name = "Whirlwind"
	whirlwind.ap_cost = 10
	whirlwind.power = 10
	whirlwind.element = "none"
	whirlwind.target_type = "all_enemies"
	whirlwind.effect_type = "damage"
	whirlwind.is_melee = true
	whirlwind.required_stance = "greatsword"
	whirlwind.description = "Spin attack hitting all enemies. Greatsword only."
	whirlwind.action_text = "Gustave spins with Whirlwind! All enemies take {value} damage!"
	skills.append(whirlwind)

	var stance_switch := SkillData.new()
	stance_switch.skill_name = "Stance Switch"
	stance_switch.ap_cost = 0
	stance_switch.power = 0
	stance_switch.element = "none"
	stance_switch.target_type = "self"
	stance_switch.effect_type = "stance_switch"
	stance_switch.description = "Switch between Greatsword (more damage dealt/taken) and Greatshield (less damage dealt/taken, bigger parry window). Free action."
	stance_switch.action_text = "Gustave switches stance!"
	skills.append(stance_switch)

	var taunt := SkillData.new()
	taunt.skill_name = "Taunt"
	taunt.ap_cost = 4
	taunt.power = 0
	taunt.element = "none"
	taunt.target_type = "self"
	taunt.effect_type = "taunt"
	taunt.buff_duration = 2
	taunt.required_stance = "greatshield"
	taunt.description = "Force all enemies to target Gustave for 2 turns. Greatshield only."
	taunt.action_text = "Gustave taunts the enemy! All attacks will target Gustave for 2 turns!"
	skills.append(taunt)

	var aegis_beam := SkillData.new()
	aegis_beam.skill_name = "Aegis Beam"
	aegis_beam.ap_cost = 4
	aegis_beam.power = 12
	aegis_beam.element = "none"
	aegis_beam.target_type = "single_enemy"
	aegis_beam.effect_type = "damage"
	aegis_beam.required_stance = "greatshield"
	aegis_beam.description = "Channel force through the greatshield. The cross emblem fires a golden energy beam at one enemy. Greatshield only."
	aegis_beam.action_text = "Gustave's shield blazes with light! {target} takes {value} damage!"
	skills.append(aegis_beam)

	var bulwark := SkillData.new()
	bulwark.skill_name = "Bulwark"
	bulwark.ap_cost = 8
	bulwark.power = 8
	bulwark.element = "none"
	bulwark.target_type = "all_enemies"
	bulwark.effect_type = "damage"
	bulwark.required_stance = "greatshield"
	bulwark.description = "Slam the shield into the ground, sending a shockwave through all enemies. Greatshield only."
	bulwark.action_text = "Gustave slams his shield down! All enemies take {value} damage!"
	skills.append(bulwark)

	return skills

# ── Sage Skills (Manifestations) ────────────────────────────────────
func _create_sage_skills() -> Array[Resource]:
	var skills: Array[Resource] = []

	var phoenix := SkillData.new()
	phoenix.skill_name = "Phoenix Manifestation"
	phoenix.ap_cost = 12
	phoenix.power = 18
	phoenix.element = "none"
	phoenix.target_type = "single_ally"
	phoenix.effect_type = "heal"
	phoenix.description = "Heal one ally with phoenix fire."
	phoenix.action_text = "Sage summons Phoenix Manifestation! {target} healed for {value} HP!"
	skills.append(phoenix)

	var phoenix_rise := SkillData.new()
	phoenix_rise.skill_name = "Phoenix Rise"
	phoenix_rise.ap_cost = 20
	phoenix_rise.power = 30
	phoenix_rise.element = "none"
	phoenix_rise.target_type = "single_ally"
	phoenix_rise.effect_type = "revive"
	phoenix_rise.description = "Revive a fallen ally at 30% HP."
	phoenix_rise.action_text = "Sage summons Phoenix Rise! {target} rises from defeat!"
	skills.append(phoenix_rise)

	var leviathan := SkillData.new()
	leviathan.skill_name = "Leviathan Manifestation"
	leviathan.ap_cost = 10
	leviathan.power = 15
	leviathan.element = "water"
	leviathan.target_type = "single_enemy"
	leviathan.effect_type = "damage"
	leviathan.description = "Summon Leviathan to strike one enemy. Water element. May inflict Soaked (DEF down)."
	leviathan.action_text = "Sage summons Leviathan! {target} takes {value} water damage!"
	leviathan.status_effect = "soaked"
	leviathan.status_effect_chance = 0.3
	skills.append(leviathan)

	var thunderbird := SkillData.new()
	thunderbird.skill_name = "Thunderbird Manifestation"
	thunderbird.ap_cost = 14
	thunderbird.power = 12
	thunderbird.element = "lightning"
	thunderbird.target_type = "all_enemies"
	thunderbird.effect_type = "damage"
	thunderbird.description = "Summon Thunderbird to strike all enemies. Lightning element. May inflict Shocked (skip turn)."
	thunderbird.action_text = "Sage summons Thunderbird! All enemies take {value} lightning damage!"
	thunderbird.status_effect = "shocked"
	thunderbird.status_effect_chance = 0.15
	skills.append(thunderbird)

	var griffin := SkillData.new()
	griffin.skill_name = "Griffin Manifestation"
	griffin.ap_cost = 8
	griffin.power = 0
	griffin.element = "none"
	griffin.target_type = "all_allies"
	griffin.effect_type = "buff_spd"
	griffin.buff_duration = 3
	griffin.description = "Boost entire party's speed for 3 turns."
	griffin.action_text = "Sage summons Griffin Manifestation! Party speed increased for 3 turns!"
	skills.append(griffin)

	var golem_m := SkillData.new()
	golem_m.skill_name = "Golem Manifestation"
	golem_m.ap_cost = 8
	golem_m.power = 0
	golem_m.element = "none"
	golem_m.target_type = "all_allies"
	golem_m.effect_type = "buff_def"
	golem_m.buff_duration = 3
	golem_m.description = "Boost entire party's defense for 3 turns."
	golem_m.action_text = "Sage summons Golem Manifestation! Party defense increased for 3 turns!"
	skills.append(golem_m)

	var basilisk := SkillData.new()
	basilisk.skill_name = "Basilisk Manifestation"
	basilisk.ap_cost = 10
	basilisk.power = 0
	basilisk.element = "none"
	basilisk.target_type = "single_enemy"
	basilisk.effect_type = "debuff_def"
	basilisk.buff_duration = 3
	basilisk.description = "Reduce one enemy's defense for 3 turns."
	basilisk.action_text = "Sage summons Basilisk Manifestation! {target}'s defense decreased for 3 turns!"
	skills.append(basilisk)

	return skills

# ── XP & Level Up ────────────────────────────────────────────────────
func add_xp(amount: int) -> Array[String]:
	var messages: Array[String] = []
	for ch in characters:
		if ch.current_hp <= 0:
			continue
		ch.xp += amount
		while ch.xp >= 50:
			ch.xp -= 50
			ch.level += 1
			ch.data.max_hp += 5
			ch.data.max_ap += 2
			ch.data.attack += 1
			ch.data.defense += 1
			ch.data.magic_attack += 1
			ch.data.magic_defense += 1
			ch.data.speed += 1
			ch.current_hp = ch.data.max_hp
			ch.current_ap = ch.data.max_ap
			messages.append("%s leveled up to Level %d!" % [ch.data.character_name, ch.level])
	return messages

func heal_party_full() -> void:
	for ch in characters:
		ch.current_hp = ch.data.max_hp
		ch.current_ap = ch.data.max_ap
