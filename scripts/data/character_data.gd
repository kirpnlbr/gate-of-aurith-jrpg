class_name CharacterData
extends Resource

@export var character_name: String = ""
@export var max_hp: int = 100
@export var max_ap: int = 20
@export var attack: int = 10
@export var defense: int = 10
@export var magic_attack: int = 10
@export var magic_defense: int = 10
@export var speed: int = 10
@export var skills: Array[Resource] = []
@export var parry_window_bonus: float = 0.0
@export var battle_color: Color = Color.WHITE
@export var sprite_idle: String = "" # folder path like "res://assets/sprites/battle/frames/sage_idle"
@export var sprite_idle_alt: String = "" # alternate idle (e.g. Gustave greatshield stance)
@export var sprite_attack: String = "" # folder path for basic attack frames
@export var sprite_parry: String = "" # folder path for parry animation frames
@export var sprite_parry_alt: String = "" # alternate parry (e.g. Gustave greatshield stance)
@export var sprite_counter: String = "" # folder path for counterattack animation frames
@export var sprite_counter_alt: String = "" # alternate counter (e.g. Gustave greatshield stance)
@export var sprite_defend: String = ""      # folder path for defend animation frames
@export var sprite_defend_alt: String = "" # alternate defend (e.g. Gustave greatshield stance)
@export var defend_hold_frame: int = 0     # frame index to hold on after intro plays
@export var defend_hold_frame_alt: int = 0
@export var sprite_skill: String = "" # fallback single-skill folder
@export var skill_sprite_map: Dictionary = {} # { "Fireball": "res://...frames/mage_fireball", ... }
