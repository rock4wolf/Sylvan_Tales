extends SceneTree

const ContentRegistry = preload("res://scripts/content_registry.gd")

func _initialize() -> void:
	var registry = ContentRegistry.new()
	var result: Dictionary = registry.load_content()
	assert(result["ok"], str(result["errors"]))
	assert(registry.content["archetypes"].size() >= 3)
	assert(registry.content["enemies"].has("slinger"))
	for poi_id in registry.content["points_of_interest"]:
		assert(not registry.content["points_of_interest"][poi_id].get("interactions", []).is_empty(), "POI sin interacción: %s" % poi_id)
		var poi: Dictionary = registry.content["points_of_interest"][poi_id]
		assert(not poi.get("interior", {}).get("buildings", []).is_empty(), "POI sin edificio interior: %s" % poi_id)

	var invalid: Dictionary = registry.content.duplicate(true)
	invalid["regions"]["causeway"]["encounter_table"] = "missing_table"
	var errors: Array[String] = registry.validate_content(invalid)
	assert(not errors.is_empty())
	assert(registry.content["regions"]["causeway"]["encounter_table"] == "causeway_patrol")
	var malformed: Dictionary = registry.content.duplicate(true)
	malformed["archetypes"]["vanguard"].erase("attack_ability")
	malformed["archetypes"]["scout"]["abilities"] = "not an object"
	malformed["quests"]["causeway_markers"] = "not an object"
	malformed["dialogue"]["share_route"]["relationship_delta"] = "mira"
	assert(not registry.validate_content(malformed).is_empty())
	var fractional: Dictionary = registry.content.duplicate(true)
	fractional["encounters"]["causeway_patrol"][0]["weight"] = 1.5
	assert(not registry.validate_content(fractional).is_empty())
	var missing_study_data: Dictionary = registry.content.duplicate(true)
	missing_study_data["enemies"]["guard"].erase("study_clue")
	assert(not registry.validate_content(missing_study_data).is_empty())
	var invalid_poi_service: Dictionary = registry.content.duplicate(true)
	invalid_poi_service["points_of_interest"]["inn"]["services"] = ["teleport"]
	assert(not registry.validate_content(invalid_poi_service).is_empty())
	var invalid_poi_interaction: Dictionary = registry.content.duplicate(true)
	invalid_poi_interaction["points_of_interest"]["farm"]["interactions"][0]["skill"] = "Flight"
	assert(not registry.validate_content(invalid_poi_interaction).is_empty())
	var invalid_poi_effect: Dictionary = registry.content.duplicate(true)
	invalid_poi_effect["points_of_interest"]["town"]["interactions"][0]["success_effect"]["faction"] = "missing_faction"
	assert(not registry.validate_content(invalid_poi_effect).is_empty())
	var invalid_poi_interior: Dictionary = registry.content.duplicate(true)
	invalid_poi_interior["points_of_interest"]["farm"]["interior"]["npcs"] = ["missing_npc"]
	assert(not registry.validate_content(invalid_poi_interior).is_empty())
	var invalid_poi_conversation: Dictionary = registry.content.duplicate(true)
	invalid_poi_conversation["points_of_interest"]["farm"]["interior"]["conversations"][0]["id"] = "missing_dialogue"
	assert(not registry.validate_content(invalid_poi_conversation).is_empty())
	var unsupported_damage_die: Dictionary = registry.content.duplicate(true)
	unsupported_damage_die["classes"]["fighter"]["damage_die"] = 7
	assert(not registry.validate_content(unsupported_damage_die).is_empty())

	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	var selected: Dictionary = registry.roll_weighted(registry.content["encounters"]["causeway_patrol"], rng)
	assert(selected["enemy"] in ["raider", "slinger", "none"])
	print("ContentRegistry checks passed")
	quit()
