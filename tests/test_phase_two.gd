extends SceneTree

const Game = preload("res://scripts/game.gd")
const CampaignState = preload("res://scripts/campaign_state.gd")
const ContentRegistry = preload("res://scripts/content_registry.gd")
const GameRules = preload("res://scripts/game_rules.gd")
const TEST_SAVE := "user://phase_two_test.json"

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var registry = ContentRegistry.new()
	assert(registry.load_content()["ok"])
	var scout = CampaignState.new()
	scout.start_new("Nara", "scout", registry.content["archetypes"]["scout"])
	assert(scout.data["character"]["archetype_id"] == "scout")
	assert(scout.data["character"]["hp"] == 11)
	assert(scout.data["character"]["dex"] == 16)
	assert(scout.data["character"]["class_id"] == "ranger")

	var game = Game.new()
	root.add_child(game)
	game.campaign.start_new("Alpha")
	game._talk_to_scholar()
	game.campaign.data["place"] = "archive"
	game.rules = GameRules.new(_success_seed(3, 12))
	game._search_ledger()
	_roll_pending(game)
	assert(game.campaign.data["quests"]["sealed_ledger"] == "completed")
	assert(game.campaign.data["quests"]["causeway_markers"] == "active")
	assert(game._dialogue_available("share_route"))
	game._travel_to_causeway()
	assert(game.campaign.data["place"] == "causeway")
	assert(game.campaign.data["reputation"]["wayfarers"] == 1)
	assert(game.campaign.data["relationships"]["mira"] == 1)

	game.rules = GameRules.new(_none_encounter_seed(registry))
	game._trigger_encounter("causeway")
	assert(game.campaign.data["encounters"]["causeway"]["resolved"])
	assert(not game.campaign.data["combat"]["active"])
	var encounter_roll: int = game.campaign.data["encounters"]["causeway"]["roll"]
	game._trigger_encounter("causeway")
	assert(game.campaign.data["encounters"]["causeway"]["roll"] == encounter_roll)
	assert(game.campaign.save_game(TEST_SAVE))
	var restored = CampaignState.new()
	assert(restored.load_game(TEST_SAVE)["ok"])
	assert(restored.data["encounters"]["causeway"]["roll"] == encounter_roll)
	assert(restored.data["reputation"]["wayfarers"] == 1)

	game.rules = GameRules.new(_success_seed(3, 13))
	game._search_markers()
	_roll_pending(game)
	assert(game.campaign.data["quests"]["causeway_markers"] == "completed")
	assert(game.campaign.data["quests"]["restore_beacon"] == "active")
	assert(game.campaign.data["regions"]["beacon"])
	assert(game._item_index("trail_token") >= 0)
	game._travel_to_beacon()
	game.rules = GameRules.new(_success_seed(3, 14))
	game._restore_beacon()
	_roll_pending(game)
	assert(game.campaign.data["quests"]["restore_beacon"] == "completed")
	assert(game.campaign.data["active_quest"].is_empty())
	assert(game.campaign.data["reputation"]["wayfarers"] == 2)
	assert(game.campaign.data["relationships"]["mira"] == 2)
	game._discard_item("trail_token")
	assert(game._item_index("trail_token") >= 0)

	var slinger_game = Game.new()
	root.add_child(slinger_game)
	slinger_game.campaign.start_new("Táctica")
	slinger_game.campaign.data["place"] = "causeway"
	slinger_game.campaign.data["character"]["position"] = [4, 4]
	slinger_game.campaign.data["character"]["hp"] = 30
	slinger_game.campaign.data["character"]["max_hp"] = 30
	slinger_game.rules = GameRules.new(_initiative_seed())
	slinger_game._start_combat("slinger", false)
	_roll_pending(slinger_game)
	slinger_game.campaign.data["combat"]["enemy_position"] = [5, 4]
	slinger_game.campaign.data["combat"]["player_turn"] = false
	slinger_game.rules = GameRules.new(831)
	slinger_game._enemy_turn()
	assert(slinger_game._chebyshev(slinger_game._enemy_position(), slinger_game._player_position()) >= 2)

	var ally_game = Game.new()
	root.add_child(ally_game)
	ally_game.campaign.start_new("Grupo")
	ally_game.campaign.data["party"].append("Mira")
	ally_game.campaign.data["character"]["position"] = [6, 4]
	ally_game.campaign.data["character"]["hp"] = 30
	ally_game.campaign.data["character"]["max_hp"] = 30
	ally_game.rules = GameRules.new(_initiative_seed())
	ally_game._start_combat("guard", false)
	_roll_pending(ally_game)
	ally_game.campaign.data["combat"]["player_turn"] = true
	var previous_hp: int = ally_game.campaign.data["combat"]["enemy_hp"]
	ally_game.rules = GameRules.new(_companion_seed())
	ally_game._companion_attack()
	_roll_pending(ally_game)
	assert(ally_game.campaign.data["combat"]["ally_action_used"])
	assert(ally_game.campaign.data["combat"]["enemy_hp"] < previous_hp)
	assert(ally_game.campaign.save_game(TEST_SAVE))
	var active_save = CampaignState.new()
	assert(active_save.load_game(TEST_SAVE)["ok"])
	assert(active_save.data["combat"]["ally_action_used"])
	ally_game._end_player_turn()
	assert(not ally_game.campaign.data["combat"]["ally_action_used"])

	for suffix in ["", ".tmp", ".bak"]:
		var path: String = TEST_SAVE + str(suffix)
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	print("Phase two checks passed")
	quit()

func _success_seed(modifier: int, dc: int) -> int:
	for sample_index in range(500):
		if GameRules.new(sample_index).ability_check(modifier, dc)["success"]:
			return sample_index
	return -1

func _none_encounter_seed(registry: ContentRegistry) -> int:
	for sample_index in range(500):
		var rng := RandomNumberGenerator.new()
		rng.seed = sample_index
		var result: Dictionary = registry.roll_weighted(registry.content["encounters"]["causeway_patrol"], rng)
		if result["enemy"] == "none":
			return sample_index
	return -1

func _initiative_seed() -> int:
	for sample_index in range(500):
		var dice = GameRules.new(sample_index)
		if dice.initiative(2)["total"] >= dice.initiative(1)["total"]:
			return sample_index
	return -1

func _companion_seed() -> int:
	for sample_index in range(500):
		var dice = GameRules.new(sample_index)
		var attack: Dictionary = dice.attack_roll(3, 14)
		var damage: Dictionary = dice.damage_roll(1, 6, 1, attack["critical"])
		if attack["hit"] and damage["total"] < 10:
			return sample_index
	return -1

func _roll_pending(game) -> void:
	while not game.pending_roll.is_empty():
		game._resolve_pending_roll()