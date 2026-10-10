extends SceneTree

const ContentRegistry = preload("res://scripts/content_registry.gd")
const GameRules = preload("res://scripts/game_rules.gd")
const TRIALS := 500
# shortcut: assumes equipped shield and one tonic, but no movement, party or terrain; replace with encounter playtests.

func _initialize() -> void:
	var registry = ContentRegistry.new()
	assert(registry.load_content()["ok"])
	var content: Dictionary = registry.content
	for class_id in content["classes"]:
		var character_class: Dictionary = content["classes"][class_id]
		var archetype: Dictionary = content["archetypes"][character_class["base_archetype"]]
		var abilities: Dictionary = archetype["abilities"]
		var hit_points: int = character_class["hit_die"] + floori(float(abilities["con"] - 10) / 2.0)
		var damage_modifier: int = floori(float(abilities[character_class["attack_ability"]] - 10) / 2.0)
		var player_armor_class: int = 11 + floori(float(abilities["dex"] - 10) / 2.0) + 2
		for enemy_id in content["enemies"]:
			var wins := 0
			for seed_value in range(TRIALS):
				if _duel(content["enemies"][enemy_id], character_class, archetype, abilities, hit_points, player_armor_class, damage_modifier, seed_value):
					wins += 1
			print("%s vs %s: %d%% wins" % [class_id, enemy_id, roundi(100.0 * wins / TRIALS)])
			assert(wins >= 0 and wins <= TRIALS)
	quit()

func _duel(enemy: Dictionary, character_class: Dictionary, archetype: Dictionary, abilities: Dictionary, player_hp: int, player_armor_class: int, damage_modifier: int, seed_value: int) -> bool:
	var rules = GameRules.new(seed_value)
	var player_initiative: int = rules.initiative(floori(float(abilities["dex"] - 10) / 2.0))["total"]
	var enemy_initiative: int = rules.initiative(floori(float(enemy["dex"] - 10) / 2.0))["total"]
	var player_turn := player_initiative >= enemy_initiative
	var enemy_hp: int = enemy["hp"]
	var remaining_player_hp := player_hp
	var tonic_used := false
	for _turn in range(40):
		if player_turn:
			if not tonic_used and remaining_player_hp <= 4:
				remaining_player_hp = mini(player_hp, remaining_player_hp + rules.damage_roll(2, 4, 2)["total"])
				tonic_used = true
			elif character_class.has("cantrip"):
				var cantrip: Dictionary = character_class["cantrip"]
				if cantrip["kind"] == "attack":
					var spell_bonus: int = floori(float(abilities[cantrip["ability"]] - 10) / 2.0) + 2
					var spell_attack: Dictionary = rules.attack_roll(spell_bonus, enemy["ac"], false, cantrip["range_ft"] > 5)
					if spell_attack["hit"]:
						enemy_hp -= rules.damage_roll(1, cantrip["damage_die"], 0, spell_attack["critical"])["total"]
				else:
					var save_dc: int = 8 + floori(float(abilities[cantrip["ability"]] - 10) / 2.0) + 2
					var enemy_save: Dictionary = rules.saving_throw(floori(float(enemy[cantrip["save_ability"]] - 10) / 2.0), save_dc)
					if not enemy_save["success"]:
						enemy_hp -= rules.damage_roll(1, cantrip["damage_die"], 0)["total"]
			else:
				var attack: Dictionary = rules.attack_roll(character_class["attack_bonus"], enemy["ac"])
				if attack["hit"]:
					enemy_hp -= rules.damage_roll(1, character_class["damage_die"], damage_modifier, attack["critical"])["total"]
		else:
			var disadvantaged: bool = enemy["behavior"] == "skirmisher"
			var attack: Dictionary = rules.attack_roll(enemy["attack_bonus"], player_armor_class, false, disadvantaged)
			if attack["hit"]:
				remaining_player_hp -= rules.damage_roll(1, enemy["damage_die"], 1)["total"]
		if enemy_hp <= 0 or remaining_player_hp <= 0:
			break
		player_turn = not player_turn
	return enemy_hp <= 0
