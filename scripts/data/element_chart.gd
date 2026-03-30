class_name ElementChart

# Returns damage multiplier based on attack element vs target weakness/resistance
# 1.5 = super effective, 0.5 = resisted, 1.0 = neutral
static func get_multiplier(attack_element: String, target_weakness: String, target_resistance: String) -> float:
	if attack_element == "none" or attack_element == "":
		return 1.0
	if attack_element == target_weakness:
		return 1.5
	if attack_element == target_resistance:
		return 0.5
	# Compound element bonuses
	var compound_strengths: Dictionary = {
		"lava": ["ice", "wood"],
		"ice": ["wind", "earth"],
		"wood": ["water", "earth"],
		"storm": ["water", "wind"],
	}
	if compound_strengths.has(attack_element):
		if target_weakness in compound_strengths[attack_element]:
			return 1.75
	return 1.0
