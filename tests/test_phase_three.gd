extends SceneTree

const Game = preload("res://scripts/game.gd")
const IsoBoard = preload("res://scripts/iso_board.gd")
const CampaignState = preload("res://scripts/campaign_state.gd")
const GameRules = preload("res://scripts/game_rules.gd")
const GridNavigation = preload("res://scripts/grid_navigation.gd")
const D20RollView = preload("res://scripts/d20_roll_view.gd")
const DamageDieView = preload("res://scripts/damage_die_view.gd")
const TEST_LOG_PATH := "user://phase_three_debug_test.jsonl"
const TEST_SAVE_PATH := "user://phase_three_grapple_test.json"
const TEST_POI_SAVE_PATH := "user://phase_three_poi_test.json"

class RulesSpy:
	var attack_had_disadvantage := false
	var attack_had_advantage := false
	var escape_check_success := false
	var save_success := false
	var escape_dc := 0
	var attack_hit := false
	var damage_calls := 0
	var attack_modifier := 0
	var attack_target_ac := 0
	var damage_die_size := 0
	var damage_modifier := 0
	var saving_modifier := 0
	var attack_calls := 0

	func attack_roll(_modifier: int, armor_class: int, advantage := false, disadvantage := false) -> Dictionary:
		attack_calls += 1
		attack_modifier = _modifier
		attack_target_ac = armor_class
		attack_had_disadvantage = disadvantage
		attack_had_advantage = advantage
		return {"rolls": [12], "die": 12, "modifier": 0, "total": 20 if attack_hit else 12, "target": 14, "critical": false, "hit": attack_hit}

	func damage_roll(_count: int, die_size: int, modifier := 0, _critical := false) -> Dictionary:
		damage_calls += 1
		damage_die_size = die_size
		damage_modifier = modifier
		return {"rolls": [6], "modifier": 0, "total": 6, "die_sides": die_size}

	func saving_throw(_modifier: int, target: int, _proficiency_bonus := 0, _proficient := false, _advantage := false, _disadvantage := false) -> Dictionary:
		saving_modifier = _modifier
		return {"rolls": [8], "die": 8, "modifier": 0, "total": 8, "target": target, "success": save_success}

	func ability_check(_modifier: int, target: int, _proficiency_bonus := 0, _proficient := false, _advantage := false, _disadvantage := false) -> Dictionary:
		escape_dc = target
		return {"rolls": [12], "die": 12, "modifier": 0, "total": 12 if escape_check_success else 5, "target": target, "success": escape_check_success}

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var game = Game.new()
	game.debug_log_path = TEST_LOG_PATH
	root.add_child(game)
	game.campaign.start_new("Beta")
	game.campaign.data["character"]["hp"] = 100
	game.campaign.data["character"]["max_hp"] = 100
	game.campaign.data["combat"] = {
		"active": true, "enemy_id": "raider", "enemy_position": [4, 4], "enemy_hp": 10,
		"round": 1, "enemy_prone": false, "player_turn": true, "movement_left": 6,
		"action_used": false, "ally_action_used": false, "player_initiative": 10,
		"enemy_initiative": 2
	}
	var spy := RulesSpy.new()
	game.rules = spy
	game.campaign.data["character"]["equipment"]["shield"] = true
	game._grapple_enemy()
	assert(game.pending_roll.is_empty())
	game.campaign.data["character"]["equipment"]["shield"] = false
	game.campaign.data["character"]["position"] = [1, 1]
	game._grapple_enemy()
	assert(game.pending_roll.is_empty())
	game.campaign.data["character"]["position"] = [3, 3]
	game.content_registry.content["enemies"]["raider"]["size"] = "Huge"
	game._grapple_enemy()
	assert(game.pending_roll.is_empty())
	game.content_registry.content["enemies"]["raider"]["size"] = "Medium"
	game._grapple_enemy()
	game._resolve_pending_roll()
	assert(game.campaign.data["combat"]["enemy_grappled"])
	assert(game.campaign.data["combat"]["enemy_grapple_escape_dc"] == 12)
	game.campaign.data["combat"]["disengaging"] = true
	game.campaign.data["combat"]["enemy_reaction_used"] = true
	game.campaign.data["combat"]["readying"] = true
	game.campaign.data["combat"]["hidden"] = true
	assert(game.campaign.save_game(TEST_SAVE_PATH))
	var restored = CampaignState.new()
	var load_result: Dictionary = restored.load_game(TEST_SAVE_PATH)
	assert(load_result["ok"], str(load_result))
	assert(restored.data["combat"]["enemy_grappled"])
	assert(restored.data["combat"]["disengaging"])
	assert(restored.data["combat"]["enemy_reaction_used"])
	assert(restored.data["combat"]["readying"])
	assert(restored.data["combat"]["hidden"])
	var prior_active_save: Dictionary = game.campaign.data.duplicate(true)
	prior_active_save["combat"].erase("disengaging")
	prior_active_save["combat"].erase("enemy_reaction_used")
	prior_active_save["combat"].erase("readying")
	prior_active_save["combat"].erase("hidden")
	var old_save_file := FileAccess.open(TEST_SAVE_PATH, FileAccess.WRITE)
	old_save_file.store_string(JSON.stringify({"version": 2, "data": prior_active_save}))
	old_save_file.close()
	var migrated = CampaignState.new()
	assert(migrated.load_game(TEST_SAVE_PATH)["ok"])
	assert(not migrated.data["combat"]["disengaging"])
	assert(not migrated.data["combat"]["enemy_reaction_used"])
	assert(not migrated.data["combat"]["readying"])
	assert(not migrated.data["combat"]["hidden"])
	spy.escape_check_success = false
	game._end_player_turn()
	assert(game.campaign.data["combat"]["enemy_grappled"])
	assert(spy.escape_dc == 12)
	spy.escape_check_success = true
	game._end_player_turn()
	assert(not game.campaign.data["combat"]["enemy_grappled"])
	var previous_minutes: float = game.campaign.data["travel"]["world_minutes"]
	game._dodge()
	assert(game.campaign.data["combat"]["action_used"])
	assert(game.detail_panel.find_children("*", "ProgressBar", true, false).size() == 2)
	game._end_player_turn()
	assert(is_equal_approx(game.campaign.data["travel"]["world_minutes"] - previous_minutes, 0.1))
	assert(game.campaign.data["combat"]["round"] == 4)
	assert(spy.attack_had_disadvantage)
	assert(not game.campaign.data["combat"]["dodging"])
	game.campaign.data["party"].append("Mira")
	game.campaign.data["combat"]["action_used"] = false
	game.campaign.data["combat"]["ally_action_used"] = false
	game._help_companion()
	game._companion_attack()
	game._resolve_pending_roll()
	assert(spy.attack_had_advantage)
	game.campaign.data["character"]["class_id"] = "wizard"
	game.campaign.data["combat"]["player_turn"] = true
	game.campaign.data["combat"]["action_used"] = false
	game._cast_cantrip()
	assert(game.pending_roll["description"].contains("Rayo de fuego"))
	spy.attack_hit = true
	game._resolve_pending_roll()
	assert(spy.attack_had_disadvantage)
	assert(game.pending_roll["description"].contains("Daño de Rayo de fuego"))
	game._resolve_pending_roll()
	assert(game.campaign.data["combat"]["enemy_hp"] == 4)
	assert(spy.damage_calls == 1)
	game.campaign.data["character"]["class_id"] = "cleric"
	game.campaign.data["combat"]["player_turn"] = true
	game.campaign.data["combat"]["action_used"] = false
	game.campaign.data["combat"]["enemy_hp"] = 10
	spy.save_success = false
	game._cast_cantrip()
	assert(game.pending_roll["description"].contains("Llama sagrada"))
	game._resolve_pending_roll()
	assert(game.pending_roll["description"].contains("Daño de Llama sagrada"))
	game._resolve_pending_roll()
	assert(game.campaign.data["combat"]["enemy_hp"] == 4)
	spy.save_success = true
	game.campaign.data["combat"]["player_turn"] = true
	game.campaign.data["combat"]["action_used"] = false
	game.campaign.data["combat"]["enemy_hp"] = 10
	game._cast_cantrip()
	game._resolve_pending_roll()
	assert(game.pending_roll.is_empty())
	assert(game.campaign.data["combat"]["enemy_hp"] == 10)
	assert(game.campaign.data["combat"]["action_used"])
	game.campaign.data["combat"]["player_turn"] = true
	game.campaign.data["combat"]["action_used"] = false
	spy.escape_check_success = true
	game._study_enemy()
	assert(game.pending_roll["description"].contains("Investigation"))
	game._resolve_pending_roll()
	assert(game.campaign.data["combat"]["action_used"])
	assert(game.feedback.contains("Lucha de cerca"))
	game.campaign.data["combat"]["player_turn"] = true
	game.campaign.data["combat"]["action_used"] = false
	spy.escape_check_success = false
	game._study_enemy()
	game._resolve_pending_roll()
	assert(game.feedback.contains("No logras identificar"))
	game.campaign.data["combat"]["player_turn"] = true
	game.campaign.data["combat"]["action_used"] = false
	var character: Dictionary = game.campaign.data["character"]
	character["class_id"] = "cleric"
	character["attack_ability"] = "str"
	character["attack_bonus"] = 2
	character["damage_die"] = 6
	character["str"] = 14
	character["dex"] = 12
	character["equipment"]["weapon"] = "Maza"
	spy.attack_hit = true
	game._player_attack()
	assert(game.pending_roll["description"].contains("1d20 +2"))
	game._resolve_pending_roll()
	assert(game.pending_roll["description"].contains("1d6 +2"))
	assert(spy.attack_modifier == 2)
	game._resolve_pending_roll()
	assert(spy.damage_die_size == 6 and spy.damage_modifier == 2)
	spy.save_success = false
	game._resolve_player_damage({"hit": true, "critical": false, "die": 12, "rolls": [12], "modifier": 2, "total": 14, "target": 14}, {"total": 1, "rolls": [1], "modifier": 2}, true, 2, "")
	assert(spy.saving_modifier == 2)
	game.campaign.data["combat"]["enemy_reaction_used"] = false
	game.campaign.data["character"]["hp"] = 100
	game._on_cell_clicked(Vector2i(2, 3))
	assert(game.pending_roll["description"].contains("Ataque de oportunidad"))
	game._resolve_pending_roll()
	assert(game.pending_roll["description"].contains("Daño del ataque de oportunidad"))
	game._resolve_pending_roll()
	assert(game.campaign.data["character"]["hp"] == 94)
	assert(game.campaign.data["character"]["position"] == [2, 3])
	game.campaign.data["character"]["position"] = [3, 3]
	game.campaign.data["combat"]["player_turn"] = true
	game.campaign.data["combat"]["action_used"] = false
	game.campaign.data["combat"]["enemy_reaction_used"] = false
	game._disengage()
	game._on_cell_clicked(Vector2i(2, 3))
	assert(game.pending_roll.is_empty())
	assert(not game.campaign.data["combat"]["enemy_reaction_used"])
	assert(not game._has_line_of_sight(Vector2i(3, 3), Vector2i(7, 3)))

	var ready_game = Game.new()
	root.add_child(ready_game)
	ready_game.campaign.start_new("Preparada")
	ready_game.campaign.data["place"] = "beacon"
	ready_game.campaign.data["character"]["position"] = [1, 4]
	ready_game.campaign.data["character"]["hp"] = 100
	ready_game.campaign.data["character"]["max_hp"] = 100
	ready_game.campaign.data["combat"] = {"active": true, "enemy_id": "raider", "enemy_position": [7, 4], "enemy_hp": 10, "enemy_prone": false, "enemy_grappled": false, "enemy_grapple_escape_dc": 0, "enemy_reaction_used": false, "disengaging": false, "readying": false, "ally_action_used": false, "helping": false, "player_initiative": 10, "enemy_initiative": 2, "player_turn": true, "round": 1, "movement_left": 6, "action_used": false, "dodging": false}
	var ready_spy := RulesSpy.new()
	ready_spy.attack_hit = true
	ready_game.rules = ready_spy
	ready_game._ready_attack()
	assert(ready_game.campaign.data["combat"]["readying"])
	ready_game._end_player_turn()
	assert(ready_game.pending_roll["description"].contains("Ataque preparado"))
	ready_game._resolve_pending_roll()
	assert(ready_game.pending_roll["description"].contains("Daño del ataque preparado"))
	ready_game._resolve_pending_roll()
	assert(not ready_game.campaign.data["combat"]["readying"])
	assert(ready_game.campaign.data["combat"]["enemy_hp"] == 4)
	assert(ready_game.campaign.data["character"]["hp"] == 94)
	assert(ready_game.campaign.data["combat"]["round"] == 2)
	ready_game.campaign.data["combat"]["enemy_position"] = [7, 4]
	ready_game.campaign.data["combat"]["player_turn"] = true
	ready_game.campaign.data["combat"]["action_used"] = false
	ready_spy.attack_hit = false
	ready_game._ready_attack()
	ready_game._end_player_turn()
	assert(ready_game.pending_roll["description"].contains("Ataque preparado"))
	ready_game._resolve_pending_roll()
	assert(ready_game.pending_roll.is_empty())
	assert(ready_game.campaign.data["combat"]["round"] == 3)

	var hide_game = Game.new()
	root.add_child(hide_game)
	hide_game.campaign.start_new("Oculta")
	hide_game.campaign.data["character"]["position"] = [3, 4]
	hide_game.campaign.data["character"]["hp"] = 100
	hide_game.campaign.data["character"]["max_hp"] = 100
	hide_game.campaign.data["combat"] = {"active": true, "enemy_id": "raider", "enemy_position": [7, 4], "enemy_hp": 9, "enemy_prone": false, "enemy_grappled": false, "enemy_grapple_escape_dc": 0, "enemy_reaction_used": false, "disengaging": false, "readying": false, "hidden": false, "ally_action_used": false, "helping": false, "player_initiative": 10, "enemy_initiative": 2, "player_turn": true, "round": 1, "movement_left": 6, "action_used": false, "dodging": false}
	var hide_spy := RulesSpy.new()
	hide_game.rules = hide_spy
	assert(not hide_game._has_line_of_sight(Vector2i(3, 4), Vector2i(7, 4)))
	hide_spy.escape_check_success = false
	hide_game._hide_in_combat()
	assert(hide_game.pending_roll["description"].contains("Stealth"))
	hide_game._resolve_pending_roll()
	assert(not hide_game.campaign.data["combat"]["hidden"])
	hide_game.campaign.data["combat"]["player_turn"] = true
	hide_game.campaign.data["combat"]["action_used"] = false
	hide_spy.escape_check_success = true
	hide_game._hide_in_combat()
	hide_game._resolve_pending_roll()
	assert(hide_game.campaign.data["combat"]["hidden"])
	hide_game.campaign.data["combat"]["player_turn"] = true
	hide_game.campaign.data["combat"]["action_used"] = false
	hide_game.campaign.data["character"]["class_id"] = "wizard"
	hide_game._cast_cantrip()
	assert(hide_game.pending_roll.is_empty())
	assert(hide_game.feedback.contains("línea de visión"))
	hide_game.campaign.data["combat"]["player_turn"] = true
	hide_game.campaign.data["combat"]["action_used"] = true
	hide_game._end_player_turn()
	assert(hide_game.campaign.data["combat"]["hidden"])
	assert(hide_spy.attack_calls == 0)
	assert(hide_game.campaign.data["character"]["hp"] == 100)
	hide_game.campaign.data["combat"]["hidden"] = true
	hide_game.campaign.data["combat"]["player_turn"] = true
	hide_game.campaign.data["combat"]["action_used"] = false
	hide_game.campaign.data["combat"]["movement_left"] = 6
	hide_game._on_cell_clicked(Vector2i(4, 6))
	assert(not hide_game.campaign.data["combat"]["hidden"])
	hide_game.campaign.data["combat"]["hidden"] = true
	hide_game.campaign.data["combat"]["enemy_position"] = [5, 6]
	hide_game._enemy_turn()
	assert(not hide_game.campaign.data["combat"]["hidden"])
	assert(hide_spy.attack_calls == 1)
	assert(GridNavigation.cover_bonus("ruins", Vector2i(4, 4)) == 2)
	assert(GridNavigation.cover_bonus("ruins", Vector2i(5, 4)) == 0)
	hide_game.campaign.data["place"] = "ruins"
	hide_game.campaign.data["character"]["position"] = [4, 4]
	assert(hide_game._target_player_ac() == hide_game._armor_class() + 2)
	hide_game.campaign.data["character"]["position"] = [3, 4]
	hide_game.campaign.data["combat"]["enemy_position"] = [4, 4]
	assert(hide_game._target_enemy_ac() == hide_game._enemy_ac() + 2)
	hide_game.campaign.data["combat"]["player_turn"] = true
	hide_game.campaign.data["combat"]["action_used"] = false
	hide_game._player_attack()
	hide_game._resolve_pending_roll()
	assert(hide_spy.attack_target_ac == hide_game._enemy_ac() + 2)
	hide_game.campaign.data["character"]["position"] = [4, 4]
	hide_game.campaign.data["combat"]["enemy_position"] = [4, 3]
	hide_game.campaign.data["combat"]["player_turn"] = false
	hide_game.campaign.data["combat"]["hidden"] = false
	var covered_player_ac: int = hide_game._armor_class() + 2
	hide_game._enemy_turn()
	assert(hide_spy.attack_target_ac == covered_player_ac)

	var oversized_log := FileAccess.open(TEST_LOG_PATH, FileAccess.WRITE)
	oversized_log.store_string("x".repeat(1048577))
	oversized_log.close()
	game._record("beta log check")
	var log_file := FileAccess.open(TEST_LOG_PATH, FileAccess.READ)
	assert(log_file != null)
	var lines := log_file.get_as_text().strip_edges().split("\n")
	log_file.close()
	assert(JSON.parse_string(lines[lines.size() - 1])["event"] == "beta log check")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_LOG_PATH))

	var board = IsoBoard.new()
	root.add_child(board)
	board.set_board("ruins", Vector2i(3, 3), {"combat": {"active": false}})
	assert(board.get_node("Entities").get_child_count() == 6)
	assert(board.get_node("Entities").get_child(0).get_node("Sprite2D").texture != null)
	board.set_board("ruins", Vector2i(3, 3), {"combat": {"active": true, "enemy_position": [7, 2]}, "ally_recruited": true})
	var battle_markers: Array[String] = []
	for entity in board.get_node("Entities").get_children():
		if entity.marker in ["P", "M", "!"]:
			battle_markers.append(entity.marker)
	assert("P" in battle_markers and "M" in battle_markers and "!" in battle_markers)
	var walkable := func(cell: Vector2i, _start: Vector2i) -> bool: return cell != Vector2i(1, 0)
	var blocks_sight := func(cell: Vector2i) -> bool: return cell == Vector2i(1, 0)
	assert(GridNavigation.find_path(Vector2i.ZERO, Vector2i(2, 0), 4, walkable).size() == 4)
	assert(GridNavigation.find_path(Vector2i.ZERO, Vector2i(2, 0), 3, walkable).is_empty())
	assert(not GridNavigation.has_line_of_sight(Vector2i.ZERO, Vector2i(2, 0), blocks_sight))
	assert(GridNavigation.is_heavily_obscured("causeway", Vector2i(2, 5)))
	assert(not GridNavigation.is_heavily_obscured("causeway", Vector2i(2, 4)))
	var obscured_game = Game.new()
	root.add_child(obscured_game)
	obscured_game.campaign.start_new("Ocultación")
	obscured_game.campaign.data["place"] = "causeway"
	obscured_game.campaign.data["character"]["position"] = [2, 5]
	obscured_game.campaign.data["combat"] = {"active": true, "enemy_id": "raider", "enemy_position": [7, 5], "enemy_hp": 9, "enemy_prone": false, "enemy_grappled": false, "enemy_grapple_escape_dc": 0, "enemy_reaction_used": false, "disengaging": false, "readying": false, "hidden": false, "ally_action_used": false, "helping": false, "player_initiative": 10, "enemy_initiative": 2, "player_turn": true, "round": 1, "movement_left": 6, "action_used": false, "dodging": false}
	var obscured_spy := RulesSpy.new()
	obscured_spy.escape_check_success = true
	obscured_game.rules = obscured_spy
	assert(obscured_game._walkable(Vector2i(2, 5), Vector2i(1, 5)))
	assert(not obscured_game._has_line_of_sight(Vector2i(7, 5), Vector2i(2, 5)))
	obscured_game._hide_in_combat()
	obscured_game._resolve_pending_roll()
	assert(obscured_game.campaign.data["combat"]["hidden"])
	var d20_values: Array[int] = D20RollView.face_values()
	assert(d20_values.size() == 20)
	for value in range(1, 21):
		assert(value in d20_values)
		var settled_normal: Vector3 = Basis.from_euler(D20RollView.target_rotation_for_value(value)) * D20RollView.face_normal_for_value(value)
		assert(settled_normal.dot(Vector3.UP) > 0.999)
	for face_index in range(d20_values.size()):
		var opposite_face := d20_values.find(21 - d20_values[face_index])
		assert(opposite_face >= 0)
		assert(D20RollView.face_normal_for_value(d20_values[face_index]).dot(D20RollView.face_normal_for_value(d20_values[opposite_face])) < -0.999)
	var die_view = load("res://scenes/ui/d20_roll_view.tscn").instantiate()
	root.add_child(die_view)
	assert(die_view.find_children("*", "Label3D", true, false).size() == 20)
	var landed_values: Array[int] = []
	die_view.roll_finished.connect(func(value: int): landed_values.append(value))
	die_view.roll_to(20)
	await create_timer(1.1).timeout
	assert(landed_values == [20])
	die_view.queue_free()
	assert(DamageDieView.supported_sides() == [4, 6, 8, 10, 12])
	var animation_view
	for die_sides in DamageDieView.supported_sides():
		assert(DamageDieView.face_values(die_sides).size() == die_sides)
		for value in DamageDieView.face_values(die_sides):
			var normal: Vector3 = Basis.from_euler(DamageDieView.target_rotation_for_value(die_sides, value)) * DamageDieView.face_normal_for_value(die_sides, value)
			assert(normal.dot(Vector3.UP) > 0.999, "D%d face %d did not settle upward" % [die_sides, value])
		var shape_view = load("res://scenes/ui/damage_die_view.tscn").instantiate()
		shape_view.sides = die_sides
		root.add_child(shape_view)
		assert(shape_view.find_children("*", "Label3D", true, false).size() == die_sides)
		if die_sides != 10:
			shape_view.queue_free()
			continue
		animation_view = shape_view
	var damage_values: Array[int] = []
	animation_view.roll_finished.connect(func(value: int): damage_values.append(value))
	animation_view.roll_to(10)
	await create_timer(1.1).timeout
	assert(damage_values == [10])
	animation_view.queue_free()
	game.current_tab = "world_map"
	game.campaign.data["travel"]["coordinate"] = [1, 0]
	game.campaign.data["travel"]["selected_coordinate"] = [1, 0]
	game.campaign.data["travel"]["selected_poi"] = "stable"
	game._render_poi_view("stable", false)
	var access_view: Node = game.detail_panel.get_child(game.detail_panel.get_child_count() - 1)
	assert(access_view.name == "POIView")
	var access_buttons: Array = access_view.find_children("*", "Button", true, false)
	assert(access_buttons.any(func(button): return button.text.begins_with("Acceder a Establo")))
	access_buttons.filter(func(button): return button.text.begins_with("Acceder a Establo"))[0].pressed.emit()
	assert(game.campaign.data["travel"]["poi_entered"] == "stable")
	var entered_view: Node = game.detail_panel.find_child("POIView", true, false)
	assert(entered_view != null)
	assert(entered_view.find_children("*", "Label", true, false).any(func(label): return label.text.contains("Caballos")))
	assert(entered_view.find_children("*", "Button", true, false).any(func(button): return button.text.begins_with("Comprar")))
	game._leave_poi()
	assert(game.campaign.data["travel"]["poi_entered"].is_empty())
	game.campaign.data["travel"]["poi_entered"] = "inn"
	game._show_world()
	var inn_view: Node = game.detail_panel.find_child("POIView", true, false)
	assert(inn_view.find_children("*", "Button", true, false).any(func(button): return button.text.begins_with("Descansar en la posada")))
	game.campaign.data["travel"]["poi_entered"] = "farm"
	game._show_world()
	var farm_view: Node = game.detail_panel.find_child("POIView", true, false)
	var farm_interior: Node = farm_view.find_child("POIInterior", true, false)
	assert(farm_interior != null)
	var interior_labels: Array = farm_interior.find_children("*", "Label", true, false)
	assert(interior_labels.any(func(label): return label.text.contains("Granero")))
	assert(interior_labels.any(func(label): return label.text.contains("Iria, granjera")))
	assert(interior_labels.any(func(label): return label.text.contains("El registro sellado")))
	var conversation_button: Button = farm_interior.find_children("*", "Button", true, false).filter(func(button): return button.text.begins_with("Preguntar por la cosecha"))[0]
	conversation_button.pressed.emit()
	assert(game.campaign.data["relationships"]["farmer"] == 1)
	assert(game.campaign.data["reputation"]["wayfarers"] == 1)
	assert(game.campaign.data["world"]["poi_outcomes"]["farm"]["farmer_rumor"]["success"])
	assert(game.campaign.save_game(TEST_POI_SAVE_PATH))
	var restored_poi_campaign = CampaignState.new()
	assert(restored_poi_campaign.load_game(TEST_POI_SAVE_PATH)["ok"])
	assert(restored_poi_campaign.data["world"]["poi_outcomes"]["farm"]["farmer_rumor"]["text"] == game.campaign.data["world"]["poi_outcomes"]["farm"]["farmer_rumor"]["text"])
	assert(restored_poi_campaign.data["relationships"]["farmer"] == 1)
	game._resolve_poi_conversation("farmer_rumor")
	assert(game.campaign.data["relationships"]["farmer"] == 1)
	var resolved_farm: Node = game.detail_panel.find_child("POIInterior", true, false)
	assert(resolved_farm.find_children("*", "Button", true, false).any(func(button): return button.disabled and button.text.contains("resuelto")))
	var farm_actions: Array = farm_view.find_children("*", "Button", true, false)
	assert(farm_actions.any(func(button): return button.text == "Inspeccionar los campos"))
	game.rules = GameRules.new(901)
	farm_actions.filter(func(button): return button.text == "Inspeccionar los campos")[0].pressed.emit()
	assert(game.pending_roll["description"].contains("Nature"))
	game._resolve_pending_roll()
	assert(game.pending_roll.is_empty())
	assert(game.current_tab == "world_map")
	assert(game.feedback.contains("cosecha") or game.feedback.contains("marcas del suelo"))
	assert(game.campaign.data["journal"].back() == game.feedback)
	game.campaign.data["travel"]["poi_entered"] = "town"
	game.rules = spy
	spy.escape_check_success = true
	game._show_world()
	var town_view: Node = game.detail_panel.find_child("POIView", true, false)
	var market_button: Button = town_view.find_children("*", "Button", true, false).filter(func(button): return button.text == "Preguntar por rumores del mercado")[0]
	market_button.pressed.emit()
	assert(game.pending_roll["description"].contains("Persuasion"))
	game._resolve_pending_roll()
	assert(game.campaign.data["reputation"]["wayfarers"] == 2)
	assert(game.campaign.data["world"]["poi_outcomes"]["town"]["market_rumors"]["success"])
	assert(game.campaign.data["world"]["poi_outcomes"]["town"]["market_rumors"]["text"].contains("Aumenta +1 reputación"))
	game._resolve_poi_interaction("market_rumors")
	assert(game.pending_roll.is_empty())
	var resolved_town: Node = game.detail_panel.find_child("POIView", true, false)
	assert(resolved_town.find_children("*", "Button", true, false).any(func(button): return button.disabled and button.text.contains("resuelto")))
	var animated_game = Game.new()
	root.add_child(animated_game)
	animated_game.campaign.start_new("Tirada animada")
	animated_game.animate_manual_dice = true
	animated_game.rules = GameRules.new(19)
	var completed_values: Array[int] = []
	animated_game._request_roll("Prueba · 1d20", Callable(animated_game.rules, "initiative").bind(0), func(result: Dictionary): completed_values.append(result["die"]))
	assert(animated_game.pending_roll_action.is_valid())
	animated_game._resolve_pending_roll()
	assert(animated_game.die_roll_animating, "pending=%s description=%s" % [animated_game.pending_roll, animated_game.last_roll_description])
	assert(not animated_game.pending_roll.is_empty())
	await create_timer(1.1).timeout
	assert(not animated_game.die_roll_animating)
	assert(animated_game.pending_roll.is_empty())
	assert(completed_values == [animated_game.last_roll_result["die"]])
	var damage_totals: Array[int] = []
	animated_game._request_roll("Daño · 2d4 +1", Callable(animated_game.rules, "damage_roll").bind(2, 4, 1), func(result: Dictionary): damage_totals.append(result["total"]))
	animated_game._resolve_pending_roll()
	assert(animated_game.die_roll_animating)
	assert(damage_totals.is_empty())
	await create_timer(2.1).timeout
	assert(not animated_game.die_roll_animating)
	assert(damage_totals == [animated_game.last_roll_result["total"]])
	damage_totals.clear()
	animated_game._request_roll("Daño · 1d20", Callable(animated_game.rules, "damage_roll").bind(1, 20, 0), func(result: Dictionary): damage_totals.append(result["total"]))
	animated_game._resolve_pending_roll()
	assert(animated_game.die_roll_animating)
	await create_timer(1.1).timeout
	assert(damage_totals == [animated_game.last_roll_result["total"]])
	for suffix in ["", ".tmp", ".bak"]:
		var path: String = TEST_SAVE_PATH + suffix
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	print("Phase three checks passed")
	quit()
