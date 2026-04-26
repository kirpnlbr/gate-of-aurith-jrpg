class_name EnemyData
extends Resource

@export var enemy_name: String = ""
@export var max_hp: int = 50
@export var attack: int = 10
@export var defense: int = 5
@export var magic_defense: int = 5
@export var speed: int = 8
@export var xp_reward: int = 10
@export var attack_patterns: Array[Resource] = []
@export var element_weakness: String = "none"
@export var element_resistance: String = "none"
@export var battle_color: Color = Color.GRAY
@export var boss: bool = false
@export var sprite_scale: float = 1.0
@export var sprite_path: String = ""
@export var sprite_idle: String = "" # folder path for idle animation frames
@export var sprite_defend: String = "" # folder path for defend animation frames
@export var defend_hold_frame: int = 0 # frame index to hold on during defensive stance
@export var attack_sprite_map: Dictionary = {} # { "Goblin Slash": "res://...frames/goblin_slash" }
