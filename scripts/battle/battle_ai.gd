class_name BattleAI
extends RefCounted

static func choose_action(enemy: Dictionary, party: Array[Dictionary]) -> Dictionary:
	if enemy.data.attack_patterns.is_empty():
		return {"pattern": null, "target": {}}
	var pattern: AttackPattern = enemy.data.attack_patterns.pick_random()
	var target := _pick_target(party)
	return {"pattern": pattern, "target": target}

static func _pick_target(party: Array[Dictionary]) -> Dictionary:
	var alive: Array[Dictionary] = []
	for p in party:
		if p.current_hp > 0:
			alive.append(p)
	if alive.is_empty():
		return {}
	# Check for taunt
	for p in alive:
		if p.has("buffs") and p.buffs.has("taunt") and p.buffs.taunt > 0:
			return p
	return alive.pick_random()
