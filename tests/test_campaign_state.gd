extends SceneTree

const CampaignState = preload("res://scripts/campaign_state.gd")
const TEST_SAVE := "user://phase_one_state_test.json"

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var absolute_test_save := ProjectSettings.globalize_path(TEST_SAVE)
	for suffix in ["", ".tmp", ".bak"]:
		if FileAccess.file_exists(TEST_SAVE + suffix):
			DirAccess.remove_absolute(absolute_test_save + suffix)

	var original = CampaignState.new()
	original.start_new("Ari")
	original.data["character"]["hp"] = 7
	original.data["world"]["gate_open"] = true
	original.data["world"]["poi_outcomes"] = {"town": {"market_rumors": {"success": true, "text": "Rutas compartidas · 12 +2 = 14"}}}
	original.data["party"].append("Mira")
	assert(original.save_game(TEST_SAVE))

	var restored = CampaignState.new()
	assert(restored.load_game(TEST_SAVE)["ok"])
	assert(restored.data == original.data)

	var corrupt = FileAccess.open(TEST_SAVE, FileAccess.WRITE)
	corrupt.store_string("not a save")
	corrupt.close()
	var previous_state: Dictionary = restored.data.duplicate(true)
	assert(not restored.load_game(TEST_SAVE)["ok"])
	assert(restored.data == previous_state)
	var legacy_data: Dictionary = original.data.duplicate(true)
	legacy_data["character"].erase("archetype_id")
	for key in ["active_quest", "quests", "reputation", "relationships", "regions", "visited_regions", "encounters"]:
		legacy_data.erase(key)
	for key in ["watcher_defeated", "scholar_met", "ledger_revealed", "ledger_found", "ally_recruited"]:
		legacy_data["world"].erase(key)
	legacy_data["world"].erase("poi_outcomes")
	legacy_data["combat"] = {"active": false}
	corrupt = FileAccess.open(TEST_SAVE, FileAccess.WRITE)
	corrupt.store_string(JSON.stringify({"version": 1, "data": legacy_data}))
	corrupt.close()
	assert(restored.load_game(TEST_SAVE)["ok"])
	assert(restored.data["character"]["archetype_id"] == "vanguard")
	assert(restored.data["quests"]["sealed_ledger"] == "available")
	assert(restored.data["regions"]["ruins"])
	assert(restored.data["world"]["poi_outcomes"].is_empty())
	previous_state = restored.data.duplicate(true)
	var invalid_data: Dictionary = original.data.duplicate(true)
	invalid_data["world"] = {}
	corrupt = FileAccess.open(TEST_SAVE, FileAccess.WRITE)
	corrupt.store_string(JSON.stringify({"version": 1, "data": invalid_data}))
	corrupt.close()
	assert(not restored.load_game(TEST_SAVE)["ok"])
	assert(restored.data == previous_state)
	var version_two: Dictionary = original.data.duplicate(true)
	version_two["world"].erase("poi_outcomes")
	corrupt = FileAccess.open(TEST_SAVE, FileAccess.WRITE)
	corrupt.store_string(JSON.stringify({"version": 2, "data": version_two}))
	corrupt.close()
	assert(restored.load_game(TEST_SAVE)["ok"])
	assert(restored.data["world"]["poi_outcomes"].is_empty())
	var outcome_round_trip = CampaignState.new()
	outcome_round_trip.start_new("Persistente")
	outcome_round_trip.data["world"]["poi_outcomes"] = original.data["world"]["poi_outcomes"].duplicate(true)
	assert(outcome_round_trip.save_game(TEST_SAVE))
	assert(restored.load_game(TEST_SAVE)["ok"])
	assert(restored.data["world"]["poi_outcomes"] == outcome_round_trip.data["world"]["poi_outcomes"])

	for suffix in ["", ".tmp", ".bak"]:
		if FileAccess.file_exists(TEST_SAVE + suffix):
			DirAccess.remove_absolute(absolute_test_save + suffix)
	print("CampaignState checks passed")
	quit()
