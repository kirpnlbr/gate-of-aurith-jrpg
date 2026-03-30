class_name SkillData
extends Resource

@export var skill_name: String = ""
@export var ap_cost: int = 5
@export var power: int = 10
@export var element: String = "none"
@export var target_type: String = "single_enemy" # single_enemy, all_enemies, single_ally, all_allies, self
@export var effect_type: String = "damage" # damage, heal, buff_atk, buff_def, buff_spd, debuff_def, revive, taunt, stance_switch
@export var description: String = ""
@export var action_text: String = "" # e.g. "{user} casts {skill}! {target} takes {value} damage!"
@export var buff_duration: int = 0 # turns the buff/debuff lasts
