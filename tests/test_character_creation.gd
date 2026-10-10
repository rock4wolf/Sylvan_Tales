extends SceneTree

const CampaignState = preload("res://scripts/campaign_state.gd")
const ContentRegistry = preload("res://scripts/content_registry.gd")

func _initialize() -> void:
	var registry = ContentRegistry.new()
	assert(registry.load_content()["ok"])
	assert(registry.content["species"].size() == 7)
	assert(registry.content["backgrounds"].size() == 5)
	assert(registry.content["classes"].size() == 4)
	for species_id in registry.content["species"]:
		for background_id in registry.content["backgrounds"]:
			for class_id in registry.content["classes"]:
				var class_definition: Dictionary = registry.content["classes"][class_id]
				var archetype_id: String = class_definition["base_archetype"]
				var state = CampaignState.new()
				state.start_new("Prueba", archetype_id, registry.content["archetypes"][archetype_id], species_id, registry.content["species"][species_id], background_id, registry.content["backgrounds"][background_id], class_id, class_definition)
				var character: Dictionary = state.data["character"]
				assert(character["species_id"] == species_id)
				assert(character["background_id"] == background_id)
				assert(character["class_id"] == class_id)
				assert(character["hp"] == class_definition["hit_die"] + floori(float(character["con"] - 10) / 2.0))
				assert(character["attack_ability"] == class_definition["attack_ability"])
				assert(character["attack_bonus"] == class_definition["attack_bonus"])
				assert(character["damage_die"] == class_definition["damage_die"])
				assert(character["equipment"]["weapon"] == class_definition["weapon"])
				for skill in registry.content["backgrounds"][background_id]["skills"]:
					assert(skill in character["skills"])
				assert(character["skills"].size() == Array(character["skills"].duplicate()).reduce(func(count: int, skill: String) -> int: return count + int(character["skills"].count(skill) == 1), 0))
	print("CharacterCreation checks passed · 140 combinations")
	quit()
