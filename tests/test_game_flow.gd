extends SceneTree

const Game = preload("res://scripts/game.gd")
const CampaignState = preload("res://scripts/campaign_state.gd")
const GameRules = preload("res://scripts/game_rules.gd")
const TEST_SAVE := "user://phase_one_flow_test.json"

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var game = Game.new()
	root.add_child(game)
	game.campaign.start_new("Prueba")
	assert(game._find_path(Vector2i(3, 3), Vector2i(3, 4), 4).size() == 1)
	assert(game._find_path(Vector2i(3, 3), Vector2i(5, 3), 4).is_empty())
	assert(game._find_path(Vector2i(3, 3), Vector2i(6, 3), 4).is_empty())
	game._on_cell_clicked(Vector2i(1, 2))
	assert(game.selected_id.is_empty())
	assert(game._chebyshev(game._player_position(), Vector2i(1, 2)) <= 1)
	game._on_cell_clicked(Vector2i(1, 2))
	assert(game.selected_id == "scholar")
	game._talk_to_scholar()
	assert(game.campaign.data["quest_stage"] == 1)
	game.rules = GameRules.new(_success_seed(4, 13))
	game._force_gate()
	_roll_pending(game)
	assert(game.campaign.data["world"]["gate_open"])
	game._enter_archive()
	assert(game.campaign.data["place"] == "archive")
	game.rules = GameRules.new(_success_seed(3, 12))
	game._search_ledger()
	_roll_pending(game)
	assert(game.campaign.data["quest_complete"])
	assert(game._item_index("sealed_ledger") >= 0)
	game._leave_archive()
	game._recruit_scholar()
	assert(game.campaign.data["party"] == ["Mira"])

	game.rules = GameRules.new(_success_seed(4, 13))
	game._search_cache()
	_roll_pending(game)
	assert(game.campaign.data["world"]["chest_searched"])
	assert(game._item_index("tonic") >= 0)
	game.campaign.data["character"]["hp"] = 5
	game._use_item("tonic")
	_roll_pending(game)
	assert(game.campaign.data["character"]["hp"] > 5)
	game._equip_shield("buckler")
	assert(game._armor_class() == 15)
	game.campaign.data["character"]["equipment"]["shield"] = false
	game.campaign.data["character"]["dex"] = 16
	assert(game._armor_class() == 14)
	game.campaign.data["character"]["dex"] = 14
	game.campaign.data["character"]["equipment"]["shield"] = true
	game._discard_item("tonic")
	assert(game._item_index("tonic") == -1)
	for tab in ["character", "inventory", "journal"]:
		game.current_tab = tab
		game._show_world()
	game.rules = GameRules.new(_success_seed(4, 13))
	game._attempt_stealth()
	_roll_pending(game)
	assert(game.campaign.data["world"]["watcher_bypassed"])
	game.campaign.data["world"]["watcher_bypassed"] = false
	game.rules = GameRules.new(_failure_seed(4, 13))
	game._attempt_stealth()
	_roll_pending(game)
	assert(game.campaign.data["combat"]["active"])
	assert(game.campaign.data["combat"]["enemy_id"] == "watcher")
	assert(game.campaign.data["combat"]["enemy_initiative_rolls"].size() == 2)
	game.campaign.data["world"]["watcher_bypassed"] = true
	game.campaign.data["combat"]["active"] = false

	game.campaign.data["character"]["position"] = [6, 4]
	game.campaign.data["character"]["hp"] = 30
	game.campaign.data["character"]["max_hp"] = 30
	game.rules = GameRules.new(_initiative_seed())
	game._start_combat("guard", false)
	_roll_pending(game)
	assert(game.campaign.data["combat"]["active"])
	assert(game.campaign.data["combat"]["player_turn"])
	game.rules = GameRules.new(_topple_seed())
	game._player_attack(true)
	_roll_pending(game)
	assert(game.campaign.data["combat"]["enemy_prone"])
	var tonic_before: int = game.campaign.data["inventory"][game._item_index("tonic")]["quantity"]
	game._use_item("tonic")
	assert(game.campaign.data["inventory"][game._item_index("tonic")]["quantity"] == tonic_before)
	assert(game.campaign.save_game(TEST_SAVE))
	var mid_combat = CampaignState.new()
	assert(mid_combat.load_game(TEST_SAVE)["ok"])
	assert(mid_combat.data["combat"]["active"])
	assert(mid_combat.data["combat"]["enemy_prone"])
	for suffix in ["", ".tmp", ".bak"]:
		var path: String = TEST_SAVE + str(suffix)
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	game._end_player_turn()
	assert(not game.campaign.data["combat"]["enemy_prone"])
	for round_index in range(8):
		if not game.campaign.data["combat"]["active"]: break
		game.rules = GameRules.new(_attack_seed())
		game._player_attack()
		_roll_pending(game)
		if game.campaign.data["combat"]["active"]:
			game._end_player_turn()
	assert(not game.campaign.data["combat"]["active"])
	assert(game.campaign.data["world"]["guard_defeated"])

	for suffix in ["", ".tmp", ".bak"]:
		var path: String = TEST_SAVE + str(suffix)
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	assert(game.campaign.save_game(TEST_SAVE))
	var restored = CampaignState.new()
	assert(restored.load_game(TEST_SAVE)["ok"])
	assert(restored.data["quest_complete"])
	assert(restored.data["party"] == ["Mira"])
	assert(restored.data["world"]["chest_searched"])
	assert(restored.data["world"]["watcher_bypassed"])
	assert(restored.data["character"]["equipment"]["shield"])
	assert(restored.data["inventory"].any(func(item: Dictionary) -> bool: return item["id"] == "sealed_ledger"))
	assert(restored.data["combat"]["enemy_hp"] == 0)
	var persuasion_game = Game.new()
	root.add_child(persuasion_game)
	persuasion_game.campaign.start_new("Persuasión")
	persuasion_game.rules = GameRules.new(_success_seed(4, 13))
	persuasion_game._persuade_guard()
	_roll_pending(persuasion_game)
	assert(persuasion_game.campaign.data["world"]["guard_state"] == "neutral")
	assert(persuasion_game.campaign.data["world"]["gate_open"])
	var combat_talk = Game.new()
	root.add_child(combat_talk)
	combat_talk.campaign.start_new("Negociación")
	combat_talk.campaign.data["combat"] = {
		"active": true, "enemy_id": "guard", "enemy_position": [7, 4], "enemy_hp": 10,
		"enemy_prone": false, "ally_action_used": false, "player_initiative": 12,
		"enemy_initiative": 8, "player_turn": true, "round": 1, "movement_left": 6,
		"action_used": false
	}
	combat_talk.rules = GameRules.new(_success_seed(4, 13))
	combat_talk._persuade_guard()
	_roll_pending(combat_talk)
	assert(not combat_talk.campaign.data["combat"]["active"])
	assert(combat_talk.campaign.data["world"]["guard_state"] == "neutral")
	for suffix in ["", ".tmp", ".bak"]:
		var path: String = TEST_SAVE + str(suffix)
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	print("Game flow checks passed")
	quit()

func _success_seed(modifier: int, target: int) -> int:
	for seed_value in range(200):
		if GameRules.new(seed_value).ability_check(modifier, target)["success"]:
			return seed_value
	return -1

func _failure_seed(modifier: int, target: int) -> int:
	for seed_value in range(200):
		if not GameRules.new(seed_value).ability_check(modifier, target)["success"]:
			return seed_value
	return -1

func _initiative_seed() -> int:
	for seed_value in range(200):
		var dice = GameRules.new(seed_value)
		if dice.initiative(2)["total"] >= dice.initiative(1)["total"]:
			return seed_value
	return -1

func _attack_seed() -> int:
	for seed_value in range(200):
		var dice = GameRules.new(seed_value)
		var attack: Dictionary = dice.attack_roll(4, 14)
		var damage: Dictionary = dice.damage_roll(1, 8, 2, attack["critical"])
		if attack["hit"] and damage["total"] >= 6:
			return seed_value
	return -1

func _topple_seed() -> int:
	for sample_index in range(200):
		var dice = GameRules.new(sample_index)
		var attack: Dictionary = dice.attack_roll(4, 14)
		var damage: Dictionary = dice.damage_roll(1, 8, 2, attack["critical"])
		var saving_throw: Dictionary = dice.saving_throw(3, 12)
		if attack["hit"] and damage["total"] < 10 and not saving_throw["success"]:
			return sample_index
	return -1

func _roll_pending(game: Game) -> void:
	while not game.pending_roll.is_empty():
		game._resolve_pending_roll()
