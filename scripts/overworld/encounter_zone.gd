class_name EncounterZone
extends RefCounted

var id: int
var grid_positions: Array[Vector2i] = []
var enemy_group: Array = [] # Array of EnemyData
var is_boss: bool = false
var defeated: bool = false
