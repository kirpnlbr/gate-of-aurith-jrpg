class_name TurnOrder
extends RefCounted

var queue: Array[Dictionary] = []

func calculate(party: Array[Dictionary], enemies: Array[Dictionary]) -> void:
	queue.clear()
	for p in party:
		if p.current_hp > 0:
			var spd: int = p.data.speed
			# Apply speed buff if active
			if p.has("buffs") and p.buffs.has("buff_spd"):
				spd = int(spd * 1.3)
			# Apply chilled slow
			if p.has("buffs") and p.buffs.has("chilled"):
				spd = int(spd * 0.75)
			queue.append({"entity": p, "is_player": true, "speed": spd})
	for e in enemies:
		if e.current_hp > 0:
			var spd: int = e.data.speed
			if e.has("buffs") and e.buffs.has("buff_spd"):
				spd = int(spd * 1.3)
			if e.has("buffs") and e.buffs.has("chilled"):
				spd = int(spd * 0.75)
			queue.append({"entity": e, "is_player": false, "speed": spd})
	queue.sort_custom(func(a, b): return a.speed > b.speed)

func get_next() -> Dictionary:
	if queue.is_empty():
		return {}
	return queue.pop_front()

func is_round_over() -> bool:
	return queue.is_empty()

func get_order_names() -> Array[String]:
	var names: Array[String] = []
	for entry in queue:
		if entry.is_player:
			names.append(entry.entity.data.character_name)
		else:
			names.append(entry.entity.data.enemy_name)
	return names

## Returns an array of { "name": String, "color": Color, "is_player": bool }
func get_order_entries() -> Array[Dictionary]:
	var entries: Array[Dictionary] = []
	for entry in queue:
		if entry.is_player:
			entries.append({
				"name": entry.entity.data.character_name,
				"color": entry.entity.data.battle_color,
				"is_player": true,
			})
		else:
			entries.append({
				"name": entry.entity.data.enemy_name,
				"color": entry.entity.data.battle_color,
				"is_player": false,
			})
	return entries
