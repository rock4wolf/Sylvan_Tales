extends SceneTree

const GameRules = preload("res://scripts/game_rules.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var first_rules = GameRules.new(701)
	var repeated_rules = GameRules.new(701)
	var check = first_rules.ability_check(2, 15, 2, true)
	assert(check == repeated_rules.ability_check(2, 15, 2, true))
	assert(check["modifier"] == 4)
	assert(check["total"] == check["die"] + 4)
	assert(check["success"] == (check["total"] >= 15))

	var advantage = GameRules.new(702).ability_check(0, 0, 0, false, true)
	assert(advantage["rolls"].size() == 2)
	assert(advantage["die"] == maxi(advantage["rolls"][0], advantage["rolls"][1]))
	var cancelled_a = GameRules.new(703).ability_check(0, 0, 0, false, true, true)
	var cancelled_b = GameRules.new(703).ability_check(0, 0)
	assert(cancelled_a == cancelled_b)

	var saw_natural_one := false
	var saw_natural_twenty := false
	for sample_index in range(200):
		var attack = GameRules.new(sample_index).attack_roll(0, 30)
		if attack["die"] == 1:
			saw_natural_one = true
			assert(not attack["hit"])
		if attack["die"] == 20:
			saw_natural_twenty = true
			assert(attack["hit"] and attack["critical"])
	assert(saw_natural_one and saw_natural_twenty)

	var initiative = GameRules.new(704).initiative(3)
	assert(initiative["total"] == initiative["die"] + 3)
	var save = GameRules.new(706).saving_throw(2, 12, 2, true)
	assert(save["modifier"] == 4)
	assert(save["success"] == (save["total"] >= 12))
	var critical_damage = GameRules.new(705).damage_roll(1, 6, 2, true)
	assert(critical_damage["rolls"].size() == 2)
	assert(critical_damage["total"] == critical_damage["rolls"][0] + critical_damage["rolls"][1] + 2)
	var special = GameRules.new(707).special_situation()
	assert(special["die"] >= 1 and special["die"] <= 6)
	print("GameRules checks passed")
	quit()