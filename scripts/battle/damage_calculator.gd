class_name DamageCalculator
extends RefCounted

static func calculate_physical(attacker_atk: int, defender_def: int, power: int = 10) -> int:
	var raw := (attacker_atk * power / 10.0) - (defender_def / 2.0)
	raw *= randf_range(0.8, 1.2)
	return maxi(1, int(raw))

static func calculate_magical(attacker_matk: int, defender_mdef: int, power: int, element: String, target_weakness: String, target_resistance: String) -> int:
	var raw := (attacker_matk * power / 10.0) - (defender_mdef / 2.0)
	raw *= ElementChart.get_multiplier(element, target_weakness, target_resistance)
	raw *= randf_range(0.8, 1.2)
	return maxi(1, int(raw))

static func calculate_heal(healer_matk: int, power: int) -> int:
	var raw := healer_matk * power / 8.0
	raw *= randf_range(0.9, 1.1)
	return maxi(1, int(raw))

static func calculate_enemy_damage(attacker_atk: int, defender_def: int, damage_pct: float) -> int:
	var raw := (attacker_atk * damage_pct) - (defender_def / 2.0)
	raw *= randf_range(0.8, 1.2)
	return maxi(1, int(raw))
