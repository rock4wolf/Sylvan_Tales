extends RefCounted

var rng := RandomNumberGenerator.new()

func _init(seed_value: int = -1) -> void:
	if seed_value == -1:
		rng.randomize()
	else:
		rng.seed = seed_value

func ability_check(ability_modifier: int, target_dc: int, proficiency_bonus: int = 0, proficient: bool = false, advantage: bool = false, disadvantage: bool = false) -> Dictionary:
	var result := _roll_d20(advantage, disadvantage)
	var modifier := ability_modifier + (proficiency_bonus if proficient else 0)
	result["modifier"] = modifier
	result["total"] = result["die"] + modifier
	result["target"] = target_dc
	result["success"] = result["total"] >= target_dc
	return result

func initiative(dexterity_modifier: int, advantage: bool = false, disadvantage: bool = false) -> Dictionary:
	var result := _roll_d20(advantage, disadvantage)
	result["modifier"] = dexterity_modifier
	result["total"] = result["die"] + dexterity_modifier
	return result

func saving_throw(ability_modifier: int, target_dc: int, proficiency_bonus: int = 0, proficient: bool = false, advantage: bool = false, disadvantage: bool = false) -> Dictionary:
	var result := _roll_d20(advantage, disadvantage)
	var modifier := ability_modifier + (proficiency_bonus if proficient else 0)
	result["modifier"] = modifier
	result["total"] = result["die"] + modifier
	result["target"] = target_dc
	result["success"] = result["total"] >= target_dc
	return result

func attack_roll(attack_modifier: int, target_ac: int, advantage: bool = false, disadvantage: bool = false) -> Dictionary:
	var result := _roll_d20(advantage, disadvantage)
	var natural_roll: int = result["die"]
	result["modifier"] = attack_modifier
	result["total"] = natural_roll + attack_modifier
	result["target"] = target_ac
	result["critical"] = natural_roll == 20
	result["hit"] = natural_roll == 20 or (natural_roll != 1 and result["total"] >= target_ac)
	return result

func damage_roll(dice_count: int, die_sides: int, modifier: int, critical: bool = false) -> Dictionary:
	var rolls: Array[int] = []
	var count := dice_count * (2 if critical else 1)
	var total := modifier
	for index in range(count):
		var die := rng.randi_range(1, die_sides)
		rolls.append(die)
		total += die
	return {"rolls": rolls, "modifier": modifier, "total": maxi(0, total), "die_sides": die_sides}

func special_situation() -> Dictionary:
	var die := rng.randi_range(1, 6)
	return {"rolls": [die], "die": die, "modifier": 0, "total": die}

func _roll_d20(advantage: bool, disadvantage: bool) -> Dictionary:
	var first_roll := rng.randi_range(1, 20)
	if advantage == disadvantage:
		return {"rolls": [first_roll], "die": first_roll}

	var second_roll := rng.randi_range(1, 20)
	var kept_roll := maxi(first_roll, second_roll) if advantage else mini(first_roll, second_roll)
	return {"rolls": [first_roll, second_roll], "die": kept_roll}
