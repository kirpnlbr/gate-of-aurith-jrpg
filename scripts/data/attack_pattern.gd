class_name AttackPattern
extends Resource

@export var pattern_name: String = ""
@export var hits: Array[Dictionary] = []
# Each hit dictionary: { "delay": float, "window": float, "damage_pct": float }
# delay = seconds before this hit's parry window appears
# window = how long the parry window is open (seconds), 0.0 = feint
# damage_pct = percentage of attacker's ATK this hit deals (1.0 = 100%)
@export var action_text: String = "" # e.g. "{attacker} slashes at {target}!"
@export var is_aoe: bool = false # if true, hits each party member sequentially
