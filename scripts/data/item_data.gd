class_name ItemData
extends Resource

@export var item_name: String = ""
@export var effect_type: String = "heal_hp" # heal_hp, heal_ap, revive
@export var value: int = 30
@export var target_type: String = "single_ally" # single_ally, all_allies
@export var description: String = ""
@export var action_text: String = ""
