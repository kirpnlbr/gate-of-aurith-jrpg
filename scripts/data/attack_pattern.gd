class_name AttackPattern
extends Resource

@export var pattern_name: String = ""
@export var hits: Array[Dictionary] = []
# Each hit dictionary: { "delay": float, "window": float, "damage_pct": float }
# delay = seconds before this hit's parry window appears
# window = how long the parry window is open (seconds), 0.0 = feint
# damage_pct = percentage of attacker's ATK this hit deals (1.0 = 100%)
@export var action_text: String = ""
@export var is_aoe: bool = false # if true, hits each party member sequentially
@export var is_team_attack: bool = false # if true, hits random party members; full parry = whole party counters
@export var is_melee: bool = false # if true, attacker lunges close to target instead of a small step
