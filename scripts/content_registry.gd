extends RefCounted

const CONTENT_PATH := "res://content/phase_two.json"
const DAMAGE_DIE_SIDES := [4, 6, 8, 10, 12, 20]
const SKILLS := ["Acrobatics", "Animal Handling", "Arcana", "Athletics", "Deception", "History", "Insight", "Intimidation", "Investigation", "Medicine", "Nature", "Perception", "Performance", "Persuasion", "Religion", "Sleight of Hand", "Stealth", "Survival"]

var content: Dictionary = {}

func load_content(path: String = CONTENT_PATH) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {"ok": false, "errors": ["No existe el archivo de contenido: %s" % path]}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {"ok": false, "errors": ["No se pudo leer el archivo de contenido."]}
	var parser := JSON.new()
	var parse_result := parser.parse(file.get_as_text())
	file.close()
	if parse_result != OK:
		return {"ok": false, "errors": ["JSON inválido: %s" % parser.get_error_message()]}
	var errors := validate_content(parser.data)
	if not errors.is_empty():
		return {"ok": false, "errors": errors}
	content = parser.data
	return {"ok": true, "errors": []}

func validate_content(candidate: Variant) -> Array[String]:
	var errors: Array[String] = []
	if typeof(candidate) != TYPE_DICTIONARY:
		return ["La raíz del contenido debe ser un objeto."]
	if candidate.get("schema_version") != 1:
		errors.append("Versión de contenido no compatible.")
	for section in ["species", "backgrounds", "classes", "archetypes", "factions", "npcs", "enemies", "items", "quests", "regions", "biomes", "mounts", "points_of_interest", "encounters", "loot_tables", "dialogue"]:
		if typeof(candidate.get(section)) != TYPE_DICTIONARY:
			errors.append("Falta la sección de datos '%s'." % section)
	if not errors.is_empty():
		return errors
	for species_id in candidate["species"]:
		var species: Variant = candidate["species"][species_id]
		if typeof(species) != TYPE_DICTIONARY or typeof(species.get("name")) != TYPE_STRING or species.get("size") not in ["Small", "Medium"] or not _is_whole_number(species.get("speed")) or species["speed"] <= 0:
			errors.append("Definición de especie inválida: %s." % species_id)
	for background_id in candidate["backgrounds"]:
		var background: Variant = candidate["backgrounds"][background_id]
		if typeof(background) != TYPE_DICTIONARY or typeof(background.get("name")) != TYPE_STRING or typeof(background.get("skills")) != TYPE_ARRAY:
			errors.append("Definición de trasfondo inválida: %s." % background_id)
	for class_id in candidate["classes"]:
		var character_class: Variant = candidate["classes"][class_id]
		if typeof(character_class) != TYPE_DICTIONARY or typeof(character_class.get("name")) != TYPE_STRING or not candidate["archetypes"].has(character_class.get("base_archetype", "")):
			errors.append("Definición de clase o arquetipo base inválido: %s." % class_id)
		elif character_class.get("attack_ability") not in ["str", "dex", "con", "int", "wis", "cha"] or not _is_whole_number(character_class.get("attack_bonus")) or not _is_supported_damage_die(character_class.get("damage_die")) or not _is_whole_number(character_class.get("hit_die")):
			errors.append("Estadísticas de clase inválidas: %s." % class_id)
		if typeof(character_class) == TYPE_DICTIONARY and character_class.has("cantrip"):
			var cantrip: Variant = character_class["cantrip"]
			if typeof(cantrip) != TYPE_DICTIONARY or typeof(cantrip.get("name")) != TYPE_STRING or cantrip.get("kind") not in ["attack", "save"] or cantrip.get("ability") not in ["str", "dex", "con", "int", "wis", "cha"] or not _is_supported_damage_die(cantrip.get("damage_die")) or not _is_whole_number(cantrip.get("range_ft")) or cantrip["range_ft"] <= 0 or (cantrip.get("kind") == "save" and cantrip.get("save_ability") not in ["str", "dex", "con", "int", "wis", "cha"]):
				errors.append("Truco o valores inválidos en la clase '%s'." % class_id)
	for biome_id in candidate["biomes"]:
		var biome: Variant = candidate["biomes"][biome_id]
		if typeof(biome) != TYPE_DICTIONARY or typeof(biome.get("name")) != TYPE_STRING or typeof(biome.get("difficult")) != TYPE_BOOL or typeof(biome.get("water")) != TYPE_BOOL:
			errors.append("Definición de bioma inválida: %s." % biome_id)
		elif not candidate["encounters"].has(biome.get("encounter_table", "")):
			errors.append("El bioma '%s' refiere una tabla de encuentros inexistente." % biome_id)
	for mount_id in candidate["mounts"]:
		var mount: Variant = candidate["mounts"][mount_id]
		if typeof(mount) != TYPE_DICTIONARY or typeof(mount.get("name")) != TYPE_STRING or not _is_whole_number(mount.get("price")) or typeof(mount.get("bonus_min")) not in [TYPE_INT, TYPE_FLOAT] or typeof(mount.get("bonus_max")) not in [TYPE_INT, TYPE_FLOAT]:
			errors.append("Definición de montura inválida: %s." % mount_id)
		elif mount["bonus_min"] < 0 or mount["bonus_min"] > mount["bonus_max"]:
			errors.append("Velocidad de montura inválida: %s." % mount_id)
	for poi_id in candidate["points_of_interest"]:
		var point: Variant = candidate["points_of_interest"][poi_id]
		if typeof(point) != TYPE_DICTIONARY or typeof(point.get("name")) != TYPE_STRING or typeof(point.get("description")) != TYPE_STRING or point.get("category") not in ["settlement", "site", "dungeon", "service"]:
			errors.append("Definición de punto de interés inválida: %s." % poi_id)
		else:
			if point.has("interior"):
				var interior: Variant = point["interior"]
				if typeof(interior) != TYPE_DICTIONARY or typeof(interior.get("buildings", [])) != TYPE_ARRAY or typeof(interior.get("npcs", [])) != TYPE_ARRAY or typeof(interior.get("quests", [])) != TYPE_ARRAY or typeof(interior.get("conversations", [])) != TYPE_ARRAY:
					errors.append("Interior inválido en punto de interés '%s'." % poi_id)
				else:
					for building in interior.get("buildings", []):
						if typeof(building) != TYPE_DICTIONARY or typeof(building.get("name")) != TYPE_STRING or typeof(building.get("description")) != TYPE_STRING or building["name"].is_empty():
							errors.append("Edificio inválido en punto de interés '%s'." % poi_id)
					for npc_id in interior.get("npcs", []):
						if typeof(npc_id) != TYPE_STRING or not candidate["npcs"].has(npc_id):
							errors.append("NPC inexistente en interior de '%s'." % poi_id)
					for quest_id in interior.get("quests", []):
						if typeof(quest_id) != TYPE_STRING or not candidate["quests"].has(quest_id):
							errors.append("Misión inexistente en interior de '%s'." % poi_id)
					var conversation_ids: Dictionary = {}
					for conversation in interior.get("conversations", []):
						if typeof(conversation) != TYPE_DICTIONARY or typeof(conversation.get("id")) != TYPE_STRING or typeof(conversation.get("npc")) != TYPE_STRING or typeof(conversation.get("label")) != TYPE_STRING:
							errors.append("Conversación inválida en interior de '%s'." % poi_id)
							continue
						var dialogue_id: String = conversation["id"]
						var dialogue_definition: Variant = candidate["dialogue"].get(dialogue_id, {})
						if dialogue_id.is_empty() or conversation_ids.has(dialogue_id) or not candidate["npcs"].has(conversation["npc"]) or typeof(dialogue_definition) != TYPE_DICTIONARY or conversation["label"].is_empty() or typeof(dialogue_definition.get("text")) != TYPE_STRING or dialogue_definition.get("text", "").is_empty():
							errors.append("Referencia inválida de conversación en interior de '%s'." % poi_id)
						conversation_ids[dialogue_id] = true
			if typeof(point.get("services", [])) != TYPE_ARRAY:
				errors.append("Servicios inválidos en punto de interés '%s'." % poi_id)
			else:
				for service in point.get("services", []):
					if service not in ["mounts", "long_rest"]:
						errors.append("Servicio '%s' desconocido en punto de interés '%s'." % [service, poi_id])
			if typeof(point.get("interactions", [])) != TYPE_ARRAY:
				errors.append("Interacciones inválidas en punto de interés '%s'." % poi_id)
			else:
				var interaction_ids: Dictionary = {}
				for interaction in point.get("interactions", []):
					if typeof(interaction) != TYPE_DICTIONARY or typeof(interaction.get("id")) != TYPE_STRING or typeof(interaction.get("label")) != TYPE_STRING or typeof(interaction.get("skill")) != TYPE_STRING or typeof(interaction.get("ability")) != TYPE_STRING or typeof(interaction.get("success")) != TYPE_STRING or typeof(interaction.get("failure")) != TYPE_STRING or not _is_whole_number(interaction.get("dc")):
						errors.append("Interacción inválida en punto de interés '%s'." % poi_id)
						continue
					if interaction["id"].is_empty() or interaction_ids.has(interaction["id"]):
						errors.append("ID vacío o duplicado en interacciones de '%s'." % poi_id)
					interaction_ids[interaction["id"]] = true
					if interaction["label"].is_empty() or interaction["skill"] not in SKILLS or interaction["ability"] not in ["str", "dex", "con", "int", "wis", "cha"] or interaction["dc"] < 1 or interaction["dc"] > 30 or interaction["success"].is_empty() or interaction["failure"].is_empty():
						errors.append("Reglas inválidas en interacción de punto de interés '%s'." % poi_id)
					if interaction.has("success_effect"):
						var effect: Variant = interaction["success_effect"]
						if typeof(effect) != TYPE_DICTIONARY or effect.get("type") != "reputation" or typeof(effect.get("faction")) != TYPE_STRING or not candidate["factions"].has(effect.get("faction", "")) or not _is_whole_number(effect.get("amount")) or effect["amount"] == 0 or absi(int(effect["amount"])) > 100:
							errors.append("Efecto de éxito inválido en interacción de '%s'." % poi_id)
	var factions: Dictionary = candidate["factions"]
	for faction_id in factions:
		var faction: Variant = factions[faction_id]
		if typeof(faction) != TYPE_DICTIONARY or typeof(faction.get("name")) != TYPE_STRING or typeof(faction.get("alignment")) != TYPE_STRING or typeof(faction.get("goal")) != TYPE_STRING or typeof(faction.get("relations")) != TYPE_DICTIONARY or not _is_whole_number(faction.get("minimum")) or not _is_whole_number(faction.get("maximum")):
			errors.append("Límites de reputación inválidos en la facción '%s'." % faction_id)
		elif faction["minimum"] > faction["maximum"]:
			errors.append("Rango de reputación invertido en la facción '%s'." % faction_id)
		elif faction["minimum"] < -100 or faction["maximum"] > 100:
			errors.append("La reputación de '%s' debe permanecer entre -100 y 100." % faction_id)
		else:
			for other_faction in faction["relations"]:
				if not factions.has(other_faction) or not _is_whole_number(faction["relations"][other_faction]) or faction["relations"][other_faction] < -100 or faction["relations"][other_faction] > 100:
					errors.append("Relación inválida entre '%s' y '%s'." % [faction_id, other_faction])
	var npcs: Dictionary = candidate["npcs"]
	for npc_id in npcs:
		var npc: Variant = npcs[npc_id]
		if typeof(npc) != TYPE_DICTIONARY or not factions.has(npc.get("faction", "")):
			errors.append("El NPC '%s' refiere una facción inexistente." % npc_id)
	for item_id in candidate["items"]:
		var item: Variant = candidate["items"][item_id]
		if typeof(item) != TYPE_DICTIONARY or typeof(item.get("name")) != TYPE_STRING or item.get("kind") not in ["consumable", "shield", "quest", "material"]:
			errors.append("Tipo inválido en el objeto '%s'." % item_id)

	var archetypes: Dictionary = candidate["archetypes"]
	for identifier in archetypes:
		var archetype: Variant = archetypes[identifier]
		if typeof(archetype) != TYPE_DICTIONARY:
			errors.append("Arquetipo inválido: %s." % identifier)
			continue
		var missing_archetype_field := false
		for key in ["name", "hp", "abilities", "skills", "masteries", "weapon", "armor", "attack_ability", "attack_bonus", "damage_die"]:
			if not archetype.has(key):
				errors.append("Falta '%s' en el arquetipo '%s'." % [key, identifier])
				missing_archetype_field = true
		if missing_archetype_field:
			continue
		if typeof(archetype["abilities"]) != TYPE_DICTIONARY:
			errors.append("Atributos inválidos en el arquetipo '%s'." % identifier)
			continue
		if typeof(archetype["name"]) != TYPE_STRING or not _is_whole_number(archetype["hp"]) or archetype["hp"] <= 0 or typeof(archetype["skills"]) != TYPE_ARRAY or typeof(archetype["masteries"]) != TYPE_ARRAY:
			errors.append("Estadísticas inválidas en el arquetipo '%s'." % identifier)
		elif not archetype["abilities"].has(archetype["attack_ability"]):
			errors.append("Atributo de ataque desconocido en el arquetipo '%s'." % identifier)
		for key in ["str", "dex", "con", "int", "wis", "cha"]:
			if typeof(archetype["abilities"].get(key)) not in [TYPE_INT, TYPE_FLOAT]:
				errors.append("Atributo '%s' inválido en el arquetipo '%s'." % [key, identifier])
		if not _is_whole_number(archetype["attack_bonus"]) or not _is_supported_damage_die(archetype["damage_die"]):
			errors.append("Ataque inválido en el arquetipo '%s'." % identifier)

	var enemies: Dictionary = candidate["enemies"]
	var loot_tables: Dictionary = candidate["loot_tables"]
	for identifier in enemies:
		var enemy: Variant = enemies[identifier]
		if typeof(enemy) != TYPE_DICTIONARY:
			errors.append("Enemigo inválido: %s." % identifier)
			continue
		if enemy.get("behavior") not in ["aggressive", "skirmisher"] or enemy.get("size") not in ["Tiny", "Small", "Medium", "Large", "Huge", "Gargantuan"] or typeof(enemy.get("loot_table")) != TYPE_STRING or typeof(enemy.get("study_clue")) != TYPE_STRING or enemy["study_clue"].is_empty():
			errors.append("Enemigo o comportamiento inválido: %s." % identifier)
			continue
		var enemy_numbers_valid := true
		for key in ["hp", "ac", "attack_bonus", "damage_die", "str", "dex", "con", "range", "study_dc"]:
			if not _is_whole_number(enemy.get(key)):
				enemy_numbers_valid = false
		if not enemy_numbers_valid or enemy["hp"] <= 0 or enemy["range"] < 1 or enemy["study_dc"] < 1 or enemy["study_dc"] > 30 or not _is_supported_damage_die(enemy["damage_die"]):
			errors.append("Estadísticas inválidas en el enemigo '%s'." % identifier)
		if not loot_tables.has(enemy.get("loot_table", "")):
			errors.append("El enemigo '%s' refiere una tabla de botín inexistente." % identifier)

	var quests: Dictionary = candidate["quests"]
	for identifier in quests:
		var quest: Variant = quests[identifier]
		if typeof(quest) != TYPE_DICTIONARY or typeof(quest.get("name")) != TYPE_STRING or typeof(quest.get("next")) != TYPE_STRING:
			errors.append("Definición de misión inválida: %s." % identifier)
			continue
		var next_quest: String = quest["next"]
		if not next_quest.is_empty() and not quests.has(next_quest):
			errors.append("La misión '%s' enlaza una misión inexistente '%s'." % [identifier, next_quest])

	for identifier in candidate["regions"]:
		var region: Variant = candidate["regions"][identifier]
		if typeof(region) != TYPE_DICTIONARY:
			errors.append("Definición de región inválida: %s." % identifier)
			continue
		if not quests.has(region.get("unlock_quest", "")):
			errors.append("La región '%s' requiere una misión inexistente." % identifier)
		if not candidate["encounters"].has(region.get("encounter_table", "")):
			errors.append("La región '%s' refiere una tabla de encuentros inexistente." % identifier)

	for table_id in candidate["encounters"]:
		var entries: Variant = candidate["encounters"][table_id]
		if typeof(entries) != TYPE_ARRAY or entries.is_empty():
			errors.append("La tabla de encuentros '%s' debe tener entradas." % table_id)
			continue
		for entry in entries:
			if typeof(entry) != TYPE_DICTIONARY or (entry.get("enemy") != "none" and not enemies.has(entry.get("enemy", ""))):
				errors.append("La tabla de encuentros '%s' refiere un enemigo inexistente." % table_id)
			elif not _is_whole_number(entry.get("weight")) or entry["weight"] <= 0:
				errors.append("Peso inválido en la tabla de encuentros '%s'." % table_id)

	for table_id in loot_tables:
		var entries: Variant = loot_tables[table_id]
		if typeof(entries) != TYPE_ARRAY or entries.is_empty():
			errors.append("La tabla de botín '%s' debe tener entradas." % table_id)
			continue
		for entry in entries:
			if typeof(entry) != TYPE_DICTIONARY or not candidate["items"].has(entry.get("item", "")):
				errors.append("La tabla de botín '%s' refiere un objeto inexistente." % table_id)
			elif not _is_whole_number(entry.get("weight")) or entry["weight"] <= 0:
				errors.append("Peso inválido en la tabla de botín '%s'." % table_id)
			elif not _is_whole_number(entry.get("quantity")) or entry["quantity"] <= 0:
				errors.append("Cantidad inválida en la tabla de botín '%s'." % table_id)
	for dialogue_id in candidate["dialogue"]:
		var dialogue: Variant = candidate["dialogue"][dialogue_id]
		if typeof(dialogue) != TYPE_DICTIONARY:
			errors.append("Diálogo inválido: %s." % dialogue_id)
			continue
		if typeof(dialogue.get("requires_quest", "")) != TYPE_STRING or typeof(dialogue.get("requires_min_reputation", {})) != TYPE_DICTIONARY or typeof(dialogue.get("relationship_delta", {})) != TYPE_DICTIONARY or typeof(dialogue.get("reputation_delta", {})) != TYPE_DICTIONARY:
			errors.append("Condiciones inválidas en el diálogo '%s'." % dialogue_id)
			continue
		if dialogue.has("text") and (typeof(dialogue["text"]) != TYPE_STRING or dialogue["text"].is_empty()):
			errors.append("Texto inválido en el diálogo '%s'." % dialogue_id)
		var required_quest: String = dialogue.get("requires_quest", "")
		if not required_quest.is_empty() and not quests.has(required_quest):
			errors.append("El diálogo '%s' requiere una misión inexistente." % dialogue_id)
		for faction_id in dialogue.get("requires_min_reputation", {}):
			if not factions.has(faction_id) or not _is_whole_number(dialogue["requires_min_reputation"][faction_id]):
				errors.append("El diálogo '%s' requiere una facción inexistente." % dialogue_id)
		for npc_id in dialogue.get("relationship_delta", {}):
			if not npcs.has(npc_id) or not _is_whole_number(dialogue["relationship_delta"][npc_id]):
				errors.append("El diálogo '%s' modifica un NPC inexistente." % dialogue_id)
		for faction_id in dialogue.get("reputation_delta", {}):
			if not factions.has(faction_id) or not _is_whole_number(dialogue["reputation_delta"][faction_id]):
				errors.append("El diálogo '%s' modifica una facción inexistente." % dialogue_id)
	return errors

func roll_weighted(entries: Array, rng: RandomNumberGenerator) -> Dictionary:
	if entries.is_empty(): return {}
	var total_weight := 0
	for entry in entries:
		total_weight += int(entry["weight"])
	if total_weight <= 0: return {}
	var roll := rng.randi_range(1, total_weight)
	var recorded_roll := roll
	for entry in entries:
		roll -= int(entry["weight"])
		if roll <= 0:
			var selected: Dictionary = entry.duplicate(true)
			selected["roll"] = recorded_roll
			return selected
	var fallback: Dictionary = entries.back().duplicate(true)
	fallback["roll"] = recorded_roll
	return fallback

func _is_whole_number(value: Variant) -> bool:
	if typeof(value) not in [TYPE_INT, TYPE_FLOAT]:
		return false
	var numeric_value := float(value)
	return is_finite(numeric_value) and floorf(numeric_value) == numeric_value

func _is_supported_damage_die(value: Variant) -> bool:
	return _is_whole_number(value) and int(value) in DAMAGE_DIE_SIDES
