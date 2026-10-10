extends RefCounted

const SAVE_PATH := "user://phase_one_save.json"
const SAVE_VERSION := 4

var data: Dictionary = {}

func start_new(character_name: String, archetype_id: String = "vanguard", archetype: Dictionary = {}, species_id: String = "human", species: Dictionary = {}, background_id: String = "farmer", background: Dictionary = {}, class_id: String = "", class_definition: Dictionary = {}) -> void:
	var seed_rng := RandomNumberGenerator.new()
	seed_rng.randomize()
	var selected_archetype := archetype if not archetype.is_empty() else {
		"hp": 12,
		"abilities": {"str": 15, "dex": 14, "con": 14, "int": 12, "wis": 13, "cha": 14},
		"skills": ["Athletics", "Stealth", "Perception", "Investigation", "Persuasion"],
		"masteries": ["Topple"],
		"weapon": "Hacha de batalla",
		"armor": "Cuero"
	}
	var selected_species := species if not species.is_empty() else {"name": "Humana", "size": "Medium", "speed": 30}
	var selected_background := background if not background.is_empty() else {"name": "Granjera", "skills": []}
	if class_id.is_empty():
		class_id = {"vanguard": "fighter", "scout": "ranger", "scholar": "wizard"}.get(archetype_id, "fighter")
	var selected_class := class_definition if not class_definition.is_empty() else {
		"attack_ability": selected_archetype.get("attack_ability", "str"),
		"attack_bonus": selected_archetype.get("attack_bonus", 4),
		"damage_die": selected_archetype.get("damage_die", 8),
		"weapon": selected_archetype.get("weapon", "Hacha de batalla"),
		"hit_die": selected_archetype.get("hp", 12)
	}
	var abilities: Dictionary = selected_archetype["abilities"]
	var skills: Array = selected_archetype["skills"].duplicate()
	for skill in selected_background.get("skills", []):
		if skill not in skills:
			skills.append(skill)
	var hit_points: int = int(selected_class["hit_die"]) + floori(float(abilities["con"] - 10) / 2.0)
	data = {
		"character": {
			"name": character_name.strip_edges() if not character_name.strip_edges().is_empty() else "Aventurera",
			"archetype_id": archetype_id,
			"species_id": species_id,
			"species_name": selected_species["name"],
			"size": selected_species["size"],
			"speed": selected_species["speed"],
			"background_id": background_id,
			"background_name": selected_background["name"],
			"class_id": class_id,
			"class_name": selected_class.get("name", class_id.capitalize()),
			"level": 1,
			"hp": hit_points,
			"max_hp": hit_points,
			"gold": 25,
			"mount": {"id": "", "speed_bonus": 0.0},
			"dex": abilities["dex"],
			"str": abilities["str"],
			"con": abilities["con"],
			"int": abilities["int"],
			"wis": abilities["wis"],
			"cha": abilities["cha"],
			"proficiency_bonus": 2,
			"skills": skills,
			"masteries": selected_archetype["masteries"].duplicate(),
			"attack_ability": selected_class["attack_ability"],
			"attack_bonus": selected_class["attack_bonus"],
			"damage_die": selected_class["damage_die"],
			"position": [3, 3],
			"equipment": {"weapon": selected_class["weapon"], "armor": selected_archetype["armor"], "shield": false}
		},
		"inventory": [
			{"id": "tonic", "name": "Tónico de campo", "kind": "consumable", "quantity": 1},
			{"id": "buckler", "name": "Broquel de madera", "kind": "shield", "quantity": 1}
		],
		"party": [],
		"place": "ruins",
		"travel": {
			"seed": seed_rng.randi(),
			"coordinate": [0, 0],
			"selected_coordinate": [0, 0],
			"pace": "normal",
			"world_minutes": 480.0,
			"hours_today": 0.0,
			"exhaustion": 0,
			"fatigue_checks": 0,
			"clock_playing": false,
			"time_scale": 1,
			"visited_hexes": ["0,0"],
			"hex_encounters": {},
			"selected_poi": ""
			,"poi_entered": ""
		},
		"quest_stage": 0,
		"quest_complete": false,
		"active_quest": "sealed_ledger",
		"quests": {"sealed_ledger": "available", "causeway_markers": "locked", "restore_beacon": "locked"},
		"reputation": {"wardens": 0, "wayfarers": 0},
		"relationships": {"mira": 0, "guard": 0},
		"regions": {"ruins": true, "archive": false, "causeway": false, "beacon": false},
		"visited_regions": ["ruins"],
		"encounters": {"causeway": {"resolved": false, "roll": -1}, "beacon": {"resolved": false, "roll": -1}},
		"journal": ["Investiga las ruinas y recupera el registro sellado."],
		"world": {
			"gate_open": false,
			"guard_state": "hostile",
			"guard_hp": 10,
			"guard_defeated": false,
			"persuasion_attempted": false,
			"chest_searched": false,
			"watcher_bypassed": false,
			"watcher_defeated": false,
			"scholar_met": false,
			"ledger_revealed": false,
			"ledger_found": false,
			"ally_recruited": false,
			"poi_outcomes": {}
		},
		"combat": {"active": false, "ally_action_used": false}
	}

func save_game(path: String = SAVE_PATH) -> bool:
	var temporary_path := path + ".tmp"
	var file := FileAccess.open(temporary_path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify({"version": SAVE_VERSION, "data": data}))
	file.flush()
	file.close()

	var destination := ProjectSettings.globalize_path(path)
	var temporary := ProjectSettings.globalize_path(temporary_path)
	var backup_path := path + ".bak"
	var backup := ProjectSettings.globalize_path(backup_path)
	var had_save := FileAccess.file_exists(path)
	if had_save:
		if FileAccess.file_exists(backup_path):
			DirAccess.remove_absolute(backup)
		if DirAccess.rename_absolute(destination, backup) != OK:
			DirAccess.remove_absolute(temporary)
			return false

	if DirAccess.rename_absolute(temporary, destination) != OK:
		if had_save:
			DirAccess.rename_absolute(backup, destination)
		return false
	if had_save:
		DirAccess.remove_absolute(backup)
	return true

func load_game(path: String = SAVE_PATH) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {"ok": false, "error": "No existe un guardado."}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {"ok": false, "error": "No se pudo leer el guardado."}
	var parser := JSON.new()
	var parse_error := parser.parse(file.get_as_text())
	file.close()
	if parse_error != OK or typeof(parser.data) != TYPE_DICTIONARY:
		return {"ok": false, "error": "El guardado está dañado o usa otra versión."}
	var candidate: Variant = parser.data.get("data")
	if parser.data.get("version") == 1:
		candidate = _migrate_v1(candidate)
		candidate = _migrate_v2(candidate)
		candidate = _migrate_v3(candidate)
	elif parser.data.get("version") == 2:
		candidate = _migrate_v2(candidate)
		candidate = _migrate_v3(candidate)
	elif parser.data.get("version") == 3:
		candidate = _migrate_v3(candidate)
	elif parser.data.get("version") != SAVE_VERSION:
		return {"ok": false, "error": "El guardado está dañado o usa otra versión."}
	if not _valid_state(candidate):
		return {"ok": false, "error": "El guardado no contiene una partida válida."}
	data = _normalize_state(candidate)
	return {"ok": true, "error": ""}

func _migrate_v1(candidate: Variant) -> Variant:
	if typeof(candidate) != TYPE_DICTIONARY:
		return candidate
	var migrated: Dictionary = candidate.duplicate(true)
	var character: Dictionary = migrated.get("character", {})
	character["archetype_id"] = "vanguard"
	character["species_id"] = "human"
	character["species_name"] = "Humana"
	character["size"] = "Medium"
	character["speed"] = 30
	character["background_id"] = "soldier"
	character["background_name"] = "Soldado"
	character["class_id"] = "fighter"
	character["class_name"] = "Guerrera"
	character["gold"] = character.get("gold", 25)
	character["mount"] = character.get("mount", {"id": "", "speed_bonus": 0.0})
	character["attack_ability"] = "str"
	character["attack_bonus"] = 4
	character["damage_die"] = 8
	if not character.has("masteries"):
		character["masteries"] = ["Topple"]
	migrated["character"] = character
	var world: Dictionary = migrated.get("world", {})
	for key in ["persuasion_attempted", "watcher_defeated", "scholar_met", "ledger_revealed", "ledger_found", "ally_recruited"]:
		if not world.has(key):
			world[key] = false
	world["poi_outcomes"] = world.get("poi_outcomes", {})
	migrated["world"] = world
	var complete: bool = migrated.get("quest_complete", false)
	var quests := {"sealed_ledger": "completed" if complete else "active" if migrated.get("quest_stage", 0) > 0 else "available", "causeway_markers": "active" if complete else "locked", "restore_beacon": "locked"}
	migrated["active_quest"] = "causeway_markers" if complete else "sealed_ledger"
	migrated["travel"] = {
		"seed": 1,
		"coordinate": [0, 0],
		"selected_coordinate": [0, 0],
		"pace": "normal",
		"world_minutes": 480.0,
		"hours_today": 0.0,
		"exhaustion": 0,
		"fatigue_checks": 0,
		"clock_playing": false,
		"time_scale": 1,
		"visited_hexes": ["0,0"],
		"hex_encounters": {},
		"selected_poi": ""
		,"poi_entered": ""
	}
	migrated["quests"] = quests
	migrated["reputation"] = {"wardens": 0, "wayfarers": 0}
	migrated["relationships"] = {"mira": 0, "guard": 0}
	migrated["regions"] = {"ruins": true, "archive": migrated.get("place") == "archive", "causeway": complete, "beacon": false}
	migrated["visited_regions"] = ["ruins"]
	if migrated.get("place") == "archive":
		migrated["visited_regions"].append("archive")
	migrated["encounters"] = {"causeway": {"resolved": false, "roll": -1}, "beacon": {"resolved": false, "roll": -1}}
	var combat: Dictionary = migrated.get("combat", {})
	combat["enemy_prone"] = combat.get("enemy_prone", false)
	combat["ally_action_used"] = combat.get("ally_action_used", false)
	combat["enemy_grappled"] = combat.get("enemy_grappled", false)
	combat["enemy_grapple_escape_dc"] = combat.get("enemy_grapple_escape_dc", 0)
	combat["dodging"] = combat.get("dodging", false)
	combat["helping"] = combat.get("helping", false)
	combat["disengaging"] = combat.get("disengaging", false)
	combat["enemy_reaction_used"] = combat.get("enemy_reaction_used", false)
	combat["readying"] = combat.get("readying", false)
	combat["hidden"] = combat.get("hidden", false)
	migrated["combat"] = combat
	return migrated

func _migrate_v2(candidate: Variant) -> Variant:
	if typeof(candidate) != TYPE_DICTIONARY:
		return candidate
	var migrated: Dictionary = candidate.duplicate(true)
	if typeof(migrated.get("world")) != TYPE_DICTIONARY:
		return candidate
	var world: Dictionary = migrated["world"]
	world["poi_outcomes"] = world.get("poi_outcomes", {})
	migrated["world"] = world
	return migrated

func _migrate_v3(candidate: Variant) -> Variant:
	if typeof(candidate) != TYPE_DICTIONARY:
		return candidate
	var migrated: Dictionary = candidate.duplicate(true)
	if typeof(migrated.get("combat")) != TYPE_DICTIONARY:
		return candidate
	var combat: Dictionary = migrated["combat"]
	if not combat.get("active", false):
		return migrated
	if typeof(migrated.get("character")) != TYPE_DICTIONARY or typeof(migrated.get("party")) != TYPE_ARRAY:
		return candidate
	var turn_order: Array[String] = ["player", "enemy"]
	if "Mira" in migrated.get("party", []) and not combat.get("ally_action_used", false):
		turn_order.append("ally")
	turn_order.sort_custom(func(first: String, second: String) -> bool:
		var first_initiative := int(combat.get("%s_initiative" % first, 0))
		var second_initiative := int(combat.get("%s_initiative" % second, 0))
		if first_initiative == second_initiative:
			return ["player", "ally", "enemy"].find(first) < ["player", "ally", "enemy"].find(second)
		return first_initiative > second_initiative
	)
	var active_turn := "player" if combat.get("player_turn", false) else "enemy"
	combat["turn_order"] = turn_order
	combat["turn_index"] = turn_order.find(active_turn)
	combat["active_turn"] = active_turn
	combat["ally_turn"] = false
	combat["ally_action_used"] = combat.get("ally_action_used", false)
	combat["ally_movement_left"] = 6
	combat["ally_hp"] = 12
	combat["ally_position"] = migrated["character"].get("position", [3, 3]).duplicate()
	migrated["combat"] = combat
	return migrated

func _valid_state(candidate: Variant) -> bool:
	if typeof(candidate) != TYPE_DICTIONARY:
		return false
	for key in ["character", "inventory", "party", "place", "travel", "quest_stage", "quest_complete", "active_quest", "quests", "reputation", "relationships", "regions", "visited_regions", "encounters", "journal", "world", "combat"]:
		if not candidate.has(key):
			return false
	if typeof(candidate["character"]) != TYPE_DICTIONARY or typeof(candidate["world"]) != TYPE_DICTIONARY:
		return false
	if typeof(candidate["inventory"]) != TYPE_ARRAY or typeof(candidate["party"]) != TYPE_ARRAY or typeof(candidate["journal"]) != TYPE_ARRAY:
		return false
	var character: Dictionary = candidate["character"]
	for key in ["name", "archetype_id", "species_id", "species_name", "size", "speed", "background_id", "background_name", "class_id", "class_name", "attack_ability", "attack_bonus", "damage_die", "hp", "max_hp", "position", "level", "dex", "str", "con", "int", "wis", "cha", "proficiency_bonus", "skills", "masteries", "equipment"]:
		if not character.has(key):
			return false
	for key in ["name", "archetype_id", "species_id", "species_name", "size", "background_id", "background_name", "class_id", "class_name", "attack_ability"]:
		if typeof(character[key]) != TYPE_STRING:
			return false
	if character["size"] not in ["Small", "Medium"] or character["attack_ability"] not in ["str", "dex", "con", "int", "wis", "cha"]:
		return false
	if typeof(character["speed"]) not in [TYPE_INT, TYPE_FLOAT] or character["speed"] <= 0 or typeof(character["attack_bonus"]) not in [TYPE_INT, TYPE_FLOAT] or typeof(character["damage_die"]) not in [TYPE_INT, TYPE_FLOAT] or character["damage_die"] <= 0:
		return false
	if typeof(character["skills"]) != TYPE_ARRAY or typeof(character["masteries"]) != TYPE_ARRAY or typeof(character["equipment"]) != TYPE_DICTIONARY:
		return false
	for mastery in character["masteries"]:
		if typeof(mastery) != TYPE_STRING:
			return false
	for key in ["weapon", "armor", "shield"]:
		if not character["equipment"].has(key):
			return false
	if typeof(character["equipment"]["weapon"]) != TYPE_STRING or typeof(character["equipment"]["armor"]) != TYPE_STRING or typeof(character["equipment"]["shield"]) != TYPE_BOOL:
		return false
	if not _is_whole_number(character.get("gold")) or character["gold"] < 0 or typeof(character.get("mount")) != TYPE_DICTIONARY:
		return false
	if typeof(character["mount"].get("id")) != TYPE_STRING or typeof(character["mount"].get("speed_bonus")) not in [TYPE_INT, TYPE_FLOAT] or character["mount"]["speed_bonus"] < 0:
		return false
	for skill in character["skills"]:
		if typeof(skill) != TYPE_STRING:
			return false
	var position: Variant = character["position"]
	if typeof(position) != TYPE_ARRAY or position.size() != 2:
		return false
	for key in ["hp", "max_hp", "level", "dex", "str", "con", "int", "wis", "cha", "proficiency_bonus"]:
		if typeof(character[key]) not in [TYPE_INT, TYPE_FLOAT]:
			return false
	for coordinate in position:
		if typeof(coordinate) not in [TYPE_INT, TYPE_FLOAT]:
			return false
		if coordinate < 0 or coordinate >= 9:
			return false
	if position[1] >= 8:
		return false
	if character["max_hp"] <= 0 or character["hp"] < 0 or character["hp"] > character["max_hp"]:
		return false
	if typeof(candidate["place"]) != TYPE_STRING or candidate["place"] not in ["ruins", "archive", "causeway", "beacon"]:
		return false
	var travel: Variant = candidate["travel"]
	if typeof(travel) != TYPE_DICTIONARY:
		return false
	for key in ["seed", "coordinate", "selected_coordinate", "pace", "world_minutes", "hours_today", "exhaustion", "fatigue_checks", "clock_playing", "time_scale", "visited_hexes", "hex_encounters", "selected_poi", "poi_entered"]:
		if not travel.has(key): return false
	if not _is_whole_number(travel["seed"]) or typeof(travel["coordinate"]) != TYPE_ARRAY or travel["coordinate"].size() != 2 or typeof(travel["selected_coordinate"]) != TYPE_ARRAY or travel["selected_coordinate"].size() != 2:
		return false
	if typeof(travel["pace"]) != TYPE_STRING or travel["pace"] not in ["cautious", "normal", "forced"]:
		return false
	if typeof(travel["world_minutes"]) not in [TYPE_INT, TYPE_FLOAT] or travel["world_minutes"] < 0 or typeof(travel["hours_today"]) not in [TYPE_INT, TYPE_FLOAT] or travel["hours_today"] < 0:
		return false
	if not _is_whole_number(travel["exhaustion"]) or travel["exhaustion"] < 0 or not _is_whole_number(travel["fatigue_checks"]) or travel["fatigue_checks"] < 0:
		return false
	if typeof(travel["clock_playing"]) != TYPE_BOOL or not _is_whole_number(travel["time_scale"]) or int(travel["time_scale"]) not in [1, 2, 4, 8] or typeof(travel["visited_hexes"]) != TYPE_ARRAY or typeof(travel["hex_encounters"]) != TYPE_DICTIONARY or typeof(travel["selected_poi"]) != TYPE_STRING or typeof(travel["poi_entered"]) != TYPE_STRING:
		return false
	for coordinate_set in [travel["coordinate"], travel["selected_coordinate"]]:
		for coordinate in coordinate_set:
			if not _is_whole_number(coordinate): return false
		var hex_q := int(coordinate_set[0])
		var hex_r := int(coordinate_set[1])
		if maxi(maxi(absi(hex_q), absi(hex_r)), absi(hex_q + hex_r)) > 3: return false
	for hex_id in travel["visited_hexes"]:
		if typeof(hex_id) != TYPE_STRING: return false
	if typeof(candidate["quest_complete"]) != TYPE_BOOL or typeof(candidate["quest_stage"]) not in [TYPE_INT, TYPE_FLOAT]:
		return false
	if candidate["quest_stage"] < 0 or candidate["quest_stage"] > 3:
		return false
	if typeof(candidate["active_quest"]) != TYPE_STRING or typeof(candidate["quests"]) != TYPE_DICTIONARY:
		return false
	if typeof(candidate["reputation"]) != TYPE_DICTIONARY or typeof(candidate["relationships"]) != TYPE_DICTIONARY or typeof(candidate["regions"]) != TYPE_DICTIONARY:
		return false
	if typeof(candidate["visited_regions"]) != TYPE_ARRAY or typeof(candidate["encounters"]) != TYPE_DICTIONARY:
		return false
	for quest_id in candidate["quests"]:
		if typeof(candidate["quests"][quest_id]) != TYPE_STRING or candidate["quests"][quest_id] not in ["locked", "available", "active", "completed", "failed"]:
			return false
	if not candidate["active_quest"].is_empty() and not candidate["quests"].has(candidate["active_quest"]):
		return false
	for faction_id in candidate["reputation"]:
		if typeof(candidate["reputation"][faction_id]) not in [TYPE_INT, TYPE_FLOAT]:
			return false
	for npc_id in candidate["relationships"]:
		if typeof(candidate["relationships"][npc_id]) not in [TYPE_INT, TYPE_FLOAT]:
			return false
	for region_id in candidate["regions"]:
		if typeof(candidate["regions"][region_id]) != TYPE_BOOL:
			return false
	for region_id in candidate["visited_regions"]:
		if typeof(region_id) != TYPE_STRING or not candidate["regions"].has(region_id):
			return false
	for region_id in candidate["encounters"]:
		var encounter_state: Variant = candidate["encounters"][region_id]
		if typeof(encounter_state) != TYPE_DICTIONARY or typeof(encounter_state.get("resolved")) != TYPE_BOOL or typeof(encounter_state.get("roll")) not in [TYPE_INT, TYPE_FLOAT]:
			return false
	if typeof(candidate["combat"]) != TYPE_DICTIONARY:
		return false
	var world: Dictionary = candidate["world"]
	for key in ["gate_open", "guard_defeated", "persuasion_attempted", "chest_searched", "watcher_bypassed", "watcher_defeated", "scholar_met", "ledger_revealed", "ledger_found", "ally_recruited"]:
		if not world.has(key) or typeof(world[key]) != TYPE_BOOL:
			return false
	if typeof(world.get("poi_outcomes")) != TYPE_DICTIONARY:
		return false
	for poi_id in world["poi_outcomes"]:
		if typeof(poi_id) != TYPE_STRING or typeof(world["poi_outcomes"][poi_id]) != TYPE_DICTIONARY:
			return false
		for interaction_id in world["poi_outcomes"][poi_id]:
			var outcome: Variant = world["poi_outcomes"][poi_id][interaction_id]
			if typeof(interaction_id) != TYPE_STRING or typeof(outcome) != TYPE_DICTIONARY or typeof(outcome.get("success")) != TYPE_BOOL or typeof(outcome.get("text")) != TYPE_STRING:
				return false
	for key in ["guard_state"]:
		if not world.has(key) or typeof(world[key]) != TYPE_STRING or world[key] not in ["hostile", "alerted", "neutral", "defeated"]:
			return false
	if not world.has("guard_hp") or typeof(world["guard_hp"]) not in [TYPE_INT, TYPE_FLOAT] or world["guard_hp"] < 0:
		return false
	for item in candidate["inventory"]:
		if typeof(item) != TYPE_DICTIONARY:
			return false
		for key in ["id", "name", "kind", "quantity"]:
			if not item.has(key):
				return false
		if typeof(item["id"]) != TYPE_STRING or typeof(item["name"]) != TYPE_STRING or item["kind"] not in ["consumable", "shield", "quest", "material"]:
			return false
		if typeof(item["quantity"]) not in [TYPE_INT, TYPE_FLOAT] or item["quantity"] < 1:
			return false
	for name in candidate["party"]:
		if typeof(name) != TYPE_STRING:
			return false
	for entry in candidate["journal"]:
		if typeof(entry) != TYPE_STRING:
			return false
	var combat: Dictionary = candidate["combat"]
	if not combat.has("active") or typeof(combat["active"]) != TYPE_BOOL or typeof(combat.get("ally_action_used")) != TYPE_BOOL:
		return false
	for key in ["enemy_grappled", "dodging", "helping", "disengaging", "enemy_reaction_used", "readying", "hidden"]:
		if combat.has(key) and typeof(combat[key]) != TYPE_BOOL:
			return false
	if combat.has("enemy_grapple_escape_dc") and not _is_whole_number(combat["enemy_grapple_escape_dc"]):
		return false
	if combat.get("enemy_grappled", false) and (not _is_whole_number(combat.get("enemy_grapple_escape_dc")) or combat["enemy_grapple_escape_dc"] < 8):
		return false
	if combat["active"]:
		for key in ["enemy_id", "enemy_position", "enemy_hp", "player_initiative", "enemy_initiative", "player_turn", "round", "movement_left", "action_used", "enemy_prone"]:
			if not combat.has(key):
				return false
		if combat["enemy_id"] not in ["guard", "watcher", "raider", "slinger"] or typeof(combat["enemy_position"]) != TYPE_ARRAY or combat["enemy_position"].size() != 2:
			return false
		for key in ["enemy_hp", "player_initiative", "enemy_initiative", "round", "movement_left"]:
			if typeof(combat[key]) not in [TYPE_INT, TYPE_FLOAT]:
				return false
		for coordinate in combat["enemy_position"]:
			if typeof(coordinate) not in [TYPE_INT, TYPE_FLOAT]:
				return false
		if typeof(combat["player_turn"]) != TYPE_BOOL or typeof(combat["action_used"]) != TYPE_BOOL or typeof(combat["enemy_prone"]) != TYPE_BOOL:
			return false
		if combat.has("turn_order"):
			if typeof(combat.get("turn_order")) != TYPE_ARRAY or combat["turn_order"].is_empty() or not _is_whole_number(combat.get("turn_index")) or combat["turn_index"] < 0 or combat["turn_index"] >= combat["turn_order"].size():
				return false
			if combat.get("active_turn") not in ["player", "ally", "enemy"] or combat["active_turn"] != combat["turn_order"][combat["turn_index"]]:
				return false
			if combat["player_turn"] != (combat["active_turn"] == "player") or typeof(combat.get("ally_turn")) != TYPE_BOOL or combat["ally_turn"] != (combat["active_turn"] == "ally"):
				return false
			if typeof(combat.get("ally_movement_left")) not in [TYPE_INT, TYPE_FLOAT] or typeof(combat.get("ally_hp")) not in [TYPE_INT, TYPE_FLOAT] or typeof(combat.get("ally_position")) != TYPE_ARRAY or combat["ally_position"].size() != 2:
				return false
	return true

func _normalize_state(candidate: Dictionary) -> Dictionary:
	var normalized := candidate.duplicate(true)
	var combat: Dictionary = normalized["combat"]
	if combat.get("active", false):
		combat["enemy_grappled"] = combat.get("enemy_grappled", false)
		combat["enemy_grapple_escape_dc"] = int(combat.get("enemy_grapple_escape_dc", 0))
		combat["dodging"] = combat.get("dodging", false)
		combat["helping"] = combat.get("helping", false)
		combat["disengaging"] = combat.get("disengaging", false)
		combat["enemy_reaction_used"] = combat.get("enemy_reaction_used", false)
		combat["readying"] = combat.get("readying", false)
		combat["hidden"] = combat.get("hidden", false)
		if typeof(combat.get("turn_order")) != TYPE_ARRAY:
			normalized["combat"] = _migrate_v3(normalized)["combat"]
			combat = normalized["combat"]
	var character: Dictionary = normalized["character"]
	for key in ["speed", "attack_bonus", "damage_die", "hp", "max_hp", "level", "dex", "str", "con", "int", "wis", "cha", "proficiency_bonus"]:
		character[key] = int(character[key])
	character["position"] = [int(character["position"][0]), int(character["position"][1])]
	normalized["quest_stage"] = int(normalized["quest_stage"])
	for item in normalized["inventory"]:
		item["quantity"] = int(item["quantity"])
	if normalized["world"].has("guard_hp"):
		normalized["world"]["guard_hp"] = int(normalized["world"]["guard_hp"])
	for key in ["enemy_hp", "player_initiative", "enemy_initiative", "round", "movement_left", "turn_index", "ally_movement_left", "ally_hp"]:
		if normalized["combat"].has(key):
			normalized["combat"][key] = int(normalized["combat"][key])
	if normalized["combat"].has("enemy_position"):
		normalized["combat"]["enemy_position"] = [int(normalized["combat"]["enemy_position"][0]), int(normalized["combat"]["enemy_position"][1])]
	if normalized["combat"].has("ally_position"):
		normalized["combat"]["ally_position"] = [int(normalized["combat"]["ally_position"][0]), int(normalized["combat"]["ally_position"][1])]
	for faction_id in normalized["reputation"]:
		normalized["reputation"][faction_id] = int(normalized["reputation"][faction_id])
	for npc_id in normalized["relationships"]:
		normalized["relationships"][npc_id] = int(normalized["relationships"][npc_id])
	for encounter_state in normalized["encounters"].values():
		encounter_state["roll"] = int(encounter_state["roll"])
	var travel: Dictionary = normalized["travel"]
	travel["seed"] = int(travel["seed"])
	travel["coordinate"] = [int(travel["coordinate"][0]), int(travel["coordinate"][1])]
	travel["selected_coordinate"] = [int(travel["selected_coordinate"][0]), int(travel["selected_coordinate"][1])]
	for key in ["exhaustion", "fatigue_checks", "time_scale"]:
		travel[key] = int(travel[key])
	for key in ["world_minutes", "hours_today"]:
		travel[key] = float(travel[key])
	var character_mount: Dictionary = normalized["character"]["mount"]
	character_mount["speed_bonus"] = float(character_mount["speed_bonus"])
	normalized["character"]["gold"] = int(normalized["character"]["gold"])
	return normalized

func _is_whole_number(value: Variant) -> bool:
	if typeof(value) not in [TYPE_INT, TYPE_FLOAT]:
		return false
	var numeric_value := float(value)
	return is_finite(numeric_value) and floorf(numeric_value) == numeric_value
