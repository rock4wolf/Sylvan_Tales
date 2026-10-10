extends Control

const CampaignState = preload("res://scripts/campaign_state.gd")
const GameRules = preload("res://scripts/game_rules.gd")
const IsoBoard = preload("res://scripts/iso_board.gd")
const ContentRegistry = preload("res://scripts/content_registry.gd")
const PoiInteractionService = preload("res://scripts/poi_interaction_service.gd")
const HexRegion = preload("res://scripts/hex_region.gd")
const HexMap = preload("res://scripts/hex_map.gd")
const DebugEventLog = preload("res://scripts/debug_event_log.gd")
const GridNavigation = preload("res://scripts/grid_navigation.gd")
const D20_ROLL_SCENE = preload("res://scenes/ui/d20_roll_view.tscn")
const DAMAGE_DIE_VIEW_SCENE = preload("res://scenes/ui/damage_die_view.tscn")
const POI_VIEW_SCENE = preload("res://scenes/ui/poi_view.tscn")

const INK := Color("172126")
const PANEL := Color("253238")
const LINE := Color("42534e")
const PAPER := Color("e8dfc8")
const MUTED := Color("a8b1a1")
const MINT := Color("83c69a")
const GOLD := Color("e3b85f")
const RUST := Color("ce765b")
const WATCHER_PASSIVE_PERCEPTION := 13
const DEBUG_LOG_PATH := "user://debug_events.jsonl"

var campaign = CampaignState.new()
var rules = GameRules.new()
var content_registry = ContentRegistry.new()
var poi_interaction_service = PoiInteractionService.new()
var current_tab := "story"
var selected_id := ""
var feedback := ""
var board: Control
var hex_region
var hex_map: Control
var detail_panel: VBoxContainer
var pending_roll: Dictionary = {}
var pending_roll_action := Callable()
var pending_roll_completion := Callable()
var last_roll_result: Dictionary = {}
var last_roll_description := ""
var die_roll_animating := false
var animate_manual_dice := true
var world_clock_label: Label
var debug_log_path := DEBUG_LOG_PATH

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	animate_manual_dice = DisplayServer.get_name() != "headless"
	var content_result: Dictionary = content_registry.load_content()
	if not content_result["ok"]:
		feedback = "Contenido inválido: " + "; ".join(content_result["errors"])
	_show_main_menu()

func _process(delta: float) -> void:
	if campaign.data.is_empty(): return
	var travel: Dictionary = campaign.data["travel"]
	if not travel["clock_playing"]: return
	travel["world_minutes"] += delta * travel["time_scale"]
	if is_instance_valid(world_clock_label):
		world_clock_label.text = "Hora %s · marcha %.1f/8 h · agotamiento %d" % [_format_world_time(), travel["hours_today"], travel["exhaustion"]]

func _unhandled_key_input(event: InputEvent) -> void:
	if not pending_roll.is_empty() or not event is InputEventKey or not event.pressed or event.echo or board == null or not is_instance_valid(board):
		return
	var direction := Vector2i.ZERO
	match event.keycode:
		KEY_W, KEY_UP: direction = Vector2i.UP
		KEY_D, KEY_RIGHT: direction = Vector2i.RIGHT
		KEY_S, KEY_DOWN: direction = Vector2i.DOWN
		KEY_A, KEY_LEFT: direction = Vector2i.LEFT
	if direction != Vector2i.ZERO:
		if current_tab == "world_map":
			_on_hex_selected(_travel_coordinate() + direction)
		else:
			_on_cell_clicked((_ally_position() if campaign.data["combat"].get("ally_turn", false) else _player_position()) + direction)

func _show_main_menu() -> void:
	_clear_screen()
	var background := ColorRect.new()
	background.color = INK
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var layout := VBoxContainer.new()
	layout.custom_minimum_size.x = 440
	layout.add_theme_constant_override("separation", 14)
	center.add_child(layout)
	var eyebrow := _label("UNA AVENTURA ISOMÉTRICA", 13, GOLD, true)
	eyebrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	layout.add_child(eyebrow)
	var title := _label("ARCHIVO\nDE CENIZA", 42, PAPER, true)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	layout.add_child(title)
	var subtitle := _label("Las ruinas guardan una señal que alguien quiso borrar.", 15, MUTED)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	layout.add_child(subtitle)
	var new_game_button := _button("Nueva expedición", _show_character_creation, MINT)
	new_game_button.disabled = content_registry.content.is_empty()
	layout.add_child(new_game_button)
	var resume := _button("Continuar partida", _continue_game, PAPER)
	resume.disabled = content_registry.content.is_empty() or not FileAccess.file_exists("user://phase_one_save.json")
	layout.add_child(resume)
	if not feedback.is_empty():
		var error_label := _label(feedback, 13, RUST)
		error_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		layout.add_child(error_label)

func _show_character_creation() -> void:
	_clear_screen()
	var background := ColorRect.new()
	background.color = INK
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var panel := _panel(PANEL)
	panel.custom_minimum_size.x = 500
	center.add_child(panel)
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 10)
	panel.add_child(layout)
	layout.add_child(_label("PREPARA TU EXPEDICIÓN", 13, GOLD, true))
	layout.add_child(_label("Una ficha. Un camino propio.", 27, PAPER, true))
	layout.add_child(_label("Nivel 1 · competencia +2 · equipo inicial", 14, MUTED))
	var species_picker := _content_picker("species")
	var background_picker := _content_picker("backgrounds")
	var class_picker := _content_picker("classes")
	layout.add_child(species_picker)
	layout.add_child(background_picker)
	layout.add_child(class_picker)
	var character_summary := _label("", 12, MINT)
	layout.add_child(character_summary)
	var update_summary := func() -> void:
		var species_id: String = str(species_picker.get_item_metadata(species_picker.selected))
		var background_id: String = str(background_picker.get_item_metadata(background_picker.selected))
		var class_id: String = str(class_picker.get_item_metadata(class_picker.selected))
		var species: Dictionary = content_registry.content["species"][species_id]
		var heritage: Dictionary = content_registry.content["backgrounds"][background_id]
		var class_definition: Dictionary = content_registry.content["classes"][class_id]
		var archetype: Dictionary = content_registry.content["archetypes"][class_definition["base_archetype"]]
		var abilities: Dictionary = archetype["abilities"]
		var skills: Array = archetype["skills"].duplicate()
		for skill in heritage["skills"]:
			if skill not in skills: skills.append(skill)
		character_summary.text = "%s · %s · %s\n%d PV · %d pies · FUE %d · DES %d · CON %d\nINT %d · SAB %d · CAR %d\nCompetencias: %s" % [species["name"], heritage["name"], class_definition["name"], archetype["hp"], species["speed"], abilities["str"], abilities["dex"], abilities["con"], abilities["int"], abilities["wis"], abilities["cha"], ", ".join(skills)]
	var selection_changed := func(_index: int): update_summary.call()
	species_picker.item_selected.connect(selection_changed)
	background_picker.item_selected.connect(selection_changed)
	class_picker.item_selected.connect(selection_changed)
	update_summary.call()
	var name_input := LineEdit.new()
	name_input.placeholder_text = "Nombre del personaje"
	name_input.custom_minimum_size.y = 42
	name_input.add_theme_color_override("font_color", PAPER)
	name_input.add_theme_stylebox_override("normal", _stylebox(Color("1d292e"), LINE, 1, 3))
	layout.add_child(name_input)
	layout.add_child(_button("Entrar en las ruinas", func():
		var species_id: String = str(species_picker.get_item_metadata(species_picker.selected))
		var background_id: String = str(background_picker.get_item_metadata(background_picker.selected))
		var class_id: String = str(class_picker.get_item_metadata(class_picker.selected))
		var class_definition: Dictionary = content_registry.content["classes"][class_id]
		var archetype_id: String = class_definition["base_archetype"]
		campaign.start_new(name_input.text, archetype_id, content_registry.content["archetypes"][archetype_id], species_id, content_registry.content["species"][species_id], background_id, content_registry.content["backgrounds"][background_id], class_id, class_definition)
		current_tab = "story"
		selected_id = ""
		feedback = ""
		_show_world()
	, MINT))
	layout.add_child(_button("Volver", _show_main_menu, MUTED))

func _content_picker(section: String) -> OptionButton:
	var picker := OptionButton.new()
	picker.custom_minimum_size.y = 38
	for identifier in content_registry.content[section]:
		picker.add_item(content_registry.content[section][identifier]["name"])
		picker.set_item_metadata(picker.item_count - 1, identifier)
	return picker

func _continue_game() -> void:
	var result: Dictionary = campaign.load_game()
	if not result["ok"]:
		feedback = result["error"]
		_show_main_menu()
		return
	current_tab = "story"
	feedback = ""
	_show_world()

func _show_world() -> void:
	_clear_screen()
	var outer := MarginContainer.new()
	outer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	outer.add_theme_constant_override("margin_left", 20)
	outer.add_theme_constant_override("margin_top", 14)
	outer.add_theme_constant_override("margin_right", 20)
	outer.add_theme_constant_override("margin_bottom", 14)
	add_child(outer)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 10)
	outer.add_child(root)
	var top := HBoxContainer.new()
	top.custom_minimum_size.y = 44
	root.add_child(top)
	var region_name: String = content_registry.content["regions"].get(campaign.data["place"], {}).get("name", "Archivo de ceniza")
	var title := _label("ARCHIVO DE CENIZA · " + region_name.to_upper(), 17, PAPER, true)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(title)
	var save_button := _button("Guardar", _save_game, MINT)
	save_button.disabled = not pending_roll.is_empty()
	top.add_child(save_button)
	var menu_button := _button("Menú", _show_main_menu, MUTED)
	menu_button.disabled = not pending_roll.is_empty()
	top.add_child(menu_button)
	var body := HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 12)
	root.add_child(body)
	var board_frame := _panel(Color("1d292e"))
	board_frame.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(board_frame)
	if current_tab == "world_map":
		var travel: Dictionary = campaign.data["travel"]
		hex_region = HexRegion.new(content_registry.content, travel["seed"])
		hex_map = HexMap.new()
		hex_map.configure(content_registry.content, travel["seed"], _travel_coordinate(), travel["visited_hexes"], _selected_coordinate())
		hex_map.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hex_map.size_flags_vertical = Control.SIZE_EXPAND_FILL
		board = hex_map
		board_frame.add_child(hex_map)
		hex_map.hex_selected.connect(_on_hex_selected)
	else:
		board = IsoBoard.new()
		board.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		board.size_flags_vertical = Control.SIZE_EXPAND_FILL
		board.set_board(campaign.data["place"], _player_position(), _board_state())
		board_frame.add_child(board)
		board.cell_clicked.connect(_on_cell_clicked)
	var side := _panel(PANEL)
	side.custom_minimum_size.x = 300
	body.add_child(side)
	var side_layout := VBoxContainer.new()
	side_layout.add_theme_constant_override("separation", 8)
	side.add_child(side_layout)
	var tabs := HBoxContainer.new()
	for tab in ["story", "world_map", "character", "inventory", "journal"]:
		var caption: String = {"story": "Escena", "world_map": "Mundo", "character": "Ficha", "inventory": "Bolsa", "journal": "Misión"}[tab]
		var button := _button(caption, func():
			current_tab = tab
			_show_world()
		, GOLD if current_tab == tab else MUTED)
		button.custom_minimum_size.y = 34
		button.disabled = not pending_roll.is_empty()
		tabs.add_child(button)
	side_layout.add_child(tabs)
	var side_scroll := ScrollContainer.new()
	side_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	side_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	side_layout.add_child(side_scroll)
	detail_panel = VBoxContainer.new()
	detail_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	detail_panel.add_theme_constant_override("separation", 8)
	side_scroll.add_child(detail_panel)
	_render_side()

func _render_side() -> void:
	match current_tab:
		"world_map":
			_render_world_map()
		"character":
			var character: Dictionary = campaign.data["character"]
			detail_panel.add_child(_label(character["name"], 23, PAPER, true))
			detail_panel.add_child(_label("%s · nivel 1 · PV %d/%d · CA %d" % [content_registry.content["archetypes"].get(character["archetype_id"], {}).get("name", "Aventurera"), character["hp"], character["max_hp"], _armor_class()], 13, MINT))
			detail_panel.add_child(_label("FUE %d   DES %d   CON %d\nINT %d   SAB %d   CAR %d" % [character["str"], character["dex"], character["con"], character["int"], character["wis"], character["cha"]], 15, PAPER))
			detail_panel.add_child(_label(", ".join(character["skills"]), 13, MUTED))
			detail_panel.add_child(_label("Maestría: Topple · %s" % character["equipment"]["weapon"], 13, GOLD))
			detail_panel.add_child(_label("Percepción pasiva: %d" % _passive_perception(), 13, MUTED))
		"inventory":
			detail_panel.add_child(_label("EQUIPO", 12, GOLD, true))
			var equipment: Dictionary = campaign.data["character"]["equipment"]
			detail_panel.add_child(_label("%s · %s · CA %d" % [equipment["weapon"], equipment["armor"], _armor_class()], 14, PAPER))
			for item in campaign.data["inventory"]:
				var row := VBoxContainer.new()
				row.add_child(_label("%s × %d" % [item["name"], item["quantity"]], 14, PAPER, true))
				var actions := HBoxContainer.new()
				if item["kind"] == "consumable":
					actions.add_child(_button("Usar", func(): _use_item(item["id"]), MINT))
				elif item["kind"] == "shield":
					actions.add_child(_button("Equipar", func(): _equip_shield(item["id"]), MINT))
				if item["kind"] != "quest":
					actions.add_child(_button("Descartar", func(): _discard_item(item["id"]), RUST))
				row.add_child(actions)
				detail_panel.add_child(row)
		"journal":
			detail_panel.add_child(_label("DIARIO DE EXPEDICIÓN", 17, PAPER, true))
			for quest_id in content_registry.content["quests"]:
				var quest_state: String = campaign.data["quests"].get(quest_id, "locked")
				var quest_name: String = content_registry.content["quests"][quest_id]["name"]
				detail_panel.add_child(_label("%s · %s" % [quest_name, quest_state.capitalize()], 13, MINT if quest_state == "completed" else GOLD if quest_state == "active" else MUTED))
			detail_panel.add_child(_label("Regiones conocidas", 11, GOLD, true))
			for region_id in campaign.data["regions"]:
				var region_name: String = content_registry.content["regions"].get(region_id, {}).get("name", "Ruinas")
				detail_panel.add_child(_label("%s · %s" % [region_name, "abierta" if campaign.data["regions"][region_id] else "bloqueada"], 12, MUTED))
			detail_panel.add_child(_label("REPUTACIÓN", 11, GOLD, true))
			for faction_id in content_registry.content["factions"]:
				var faction: Dictionary = content_registry.content["factions"][faction_id]
				detail_panel.add_child(_label("%s · %d" % [faction["name"], campaign.data["reputation"].get(faction_id, 0)], 12, PAPER))
			var entries: Array = campaign.data["journal"].duplicate()
			entries.reverse()
			for entry in entries:
				detail_panel.add_child(_label("· " + str(entry), 12, MUTED))
		"world_map":
			_render_world_map()
		_:
			_render_story()

func _render_world_map() -> void:
	var travel: Dictionary = campaign.data["travel"]
	var coordinate: Vector2i = _travel_coordinate()
	var tile: Dictionary = hex_region.tile_at(hex_map.tiles, hex_map.selected_hex)
	world_clock_label = _label("", 12, MUTED)
	detail_panel.add_child(world_clock_label)
	world_clock_label.text = "Hora %s · marcha %.1f/8 h · agotamiento %d" % [_format_world_time(), travel["hours_today"], travel["exhaustion"]]
	detail_panel.add_child(_label("Posición %d,%d · escala 3 mi por hex" % [coordinate.x, coordinate.y], 12, PAPER))
	var pace_row := HBoxContainer.new()
	for pace_id in ["cautious", "normal", "forced"]:
		var caption: String = {"cautious": "Cauto", "normal": "Normal", "forced": "Forzado"}[pace_id]
		var pace_button := _button(caption, func(): _set_travel_pace(pace_id), GOLD if travel["pace"] == pace_id else MUTED)
		pace_button.custom_minimum_size.y = 32
		pace_row.add_child(pace_button)
	detail_panel.add_child(pace_row)
	var clock_row := HBoxContainer.new()
	for speed in [0, 1, 2, 4, 8]:
		var caption := "Pausa" if speed == 0 else "Play" if speed == 1 else "×%d" % speed
		clock_row.add_child(_button(caption, func(): _set_clock_speed(speed), GOLD if (speed == 0 and not travel["clock_playing"]) or (speed > 0 and travel["clock_playing"] and travel["time_scale"] == speed) else MUTED))
	detail_panel.add_child(clock_row)
	if not travel["poi_entered"].is_empty():
		var entered_poi: Dictionary = content_registry.content["points_of_interest"].get(travel["poi_entered"], {})
		if not entered_poi.is_empty():
			_render_poi_view(travel["poi_entered"], true)
		return
	if tile.is_empty():
		detail_panel.add_child(_label("Selecciona un hexágono conocido.", 13, MUTED))
		return
	var biome: Dictionary = content_registry.content["biomes"][tile["biome"]]
	var selected_coordinate: Vector2i = hex_map.selected_hex
	var distance: float = hex_region.distance_miles(coordinate, selected_coordinate)
	detail_panel.add_child(_label("%s · %s · %s" % [biome["name"], "terreno difícil" if biome["difficult"] else "terreno normal", "agua" if biome["water"] else "tierra"], 14, PAPER, true))
	detail_panel.add_child(_label("%d,%d · %.0f millas" % [selected_coordinate.x, selected_coordinate.y, hex_region.distance_miles(Vector2i.ZERO, selected_coordinate)], 12, MUTED))
	if not tile["poi"].is_empty():
		var poi: Dictionary = content_registry.content["points_of_interest"][tile["poi"]]
		detail_panel.add_child(_label("Punto de interés: %s" % poi["name"], 13, GOLD))
		if selected_coordinate == coordinate:
			_render_poi_view(tile["poi"], false)
	elif tile["revealed"] or HexRegion.new(content_registry.content, travel["seed"]).hex_distance(coordinate, selected_coordinate) <= 1:
		detail_panel.add_child(_label("Zona explorada. Los eventos dependen del terreno y el ritmo de marcha.", 12, MUTED))
	if selected_coordinate != coordinate and hex_region.hex_distance(coordinate, selected_coordinate) == 1:
		var hours: float = hex_region.travel_hours(tile, travel["pace"], campaign.data["character"]["mount"]["speed_bonus"])
		if hex_region.can_enter(tile):
			detail_panel.add_child(_label("Viaje estimado: %.2f h" % hours, 12, PAPER))
			_add_action("Viajar al hexágono", _travel_to_hex, MINT)
		else:
			detail_panel.add_child(_label("No se puede cruzar agua sin una mecánica de transporte acuático.", 12, RUST))

func _render_poi_view(poi_id: String, entered: bool) -> void:
	var poi_view = POI_VIEW_SCENE.instantiate()
	var poi: Dictionary = content_registry.content["points_of_interest"][poi_id]
	var available_dialogues: Dictionary = {}
	for conversation in poi.get("interior", {}).get("conversations", []):
		if _dialogue_available(conversation["id"]):
			available_dialogues[conversation["id"]] = content_registry.content["dialogue"][conversation["id"]]
	poi_view.configure(
		poi,
		entered,
		content_registry.content["points_of_interest"][poi_id].get("services", []),
		content_registry.content["points_of_interest"][poi_id].get("interactions", []),
		campaign.data["world"].get("poi_outcomes", {}).get(poi_id, {}),
		content_registry.content["mounts"],
		campaign.data["character"]["mount"]["id"],
		campaign.data["character"]["gold"],
		content_registry.content["npcs"],
		content_registry.content["factions"],
		campaign.data["relationships"],
		content_registry.content["quests"],
		campaign.data["quests"],
		available_dialogues
	)
	poi_view.access_requested.connect(_enter_selected_poi)
	poi_view.leave_requested.connect(_leave_poi)
	poi_view.rest_requested.connect(_rest_in_inn)
	poi_view.mount_purchase_requested.connect(_buy_mount)
	poi_view.interaction_requested.connect(_resolve_poi_interaction)
	poi_view.conversation_requested.connect(_resolve_poi_conversation)
	detail_panel.add_child(poi_view)

func _resolve_poi_conversation(dialogue_id: String) -> void:
	var poi_id: String = campaign.data["travel"]["poi_entered"]
	var poi: Dictionary = content_registry.content["points_of_interest"].get(poi_id, {})
	var allowed := false
	for conversation in poi.get("interior", {}).get("conversations", []):
		if conversation["id"] == dialogue_id:
			allowed = true
			break
	var outcomes: Dictionary = campaign.data["world"].get("poi_outcomes", {}).get(poi_id, {})
	if not allowed or outcomes.has(dialogue_id) or not _dialogue_available(dialogue_id):
		return
	var dialogue: Dictionary = content_registry.content["dialogue"][dialogue_id]
	var text := poi_interaction_service.resolve_conversation(campaign.data, poi_id, dialogue_id, dialogue, content_registry.content["factions"])
	if text.is_empty(): return
	_record(text)
	feedback = text
	_show_world()

func _resolve_poi_interaction(interaction_id: String) -> void:
	var travel: Dictionary = campaign.data["travel"]
	var poi_id: String = travel["poi_entered"]
	var poi: Dictionary = content_registry.content["points_of_interest"].get(poi_id, {})
	var interactions: Array = poi.get("interactions", [])
	var interaction: Dictionary = {}
	for candidate in interactions:
		if candidate.get("id") == interaction_id:
			interaction = candidate
			break
	if interaction.is_empty() or campaign.data["world"].get("poi_outcomes", {}).get(poi_id, {}).has(interaction_id):
		return
	_request_skill_check(interaction["skill"], interaction["ability"], interaction["dc"], func(result: Dictionary):
		var succeeded: bool = result["success"]
		feedback = poi_interaction_service.resolve_skill_interaction(campaign.data, poi_id, interaction_id, interaction, succeeded, _format_check(result), content_registry.content["factions"])
		if feedback.is_empty(): return
		_record(feedback)
		current_tab = "world_map"
		_show_world()
	)

func _format_world_time() -> String:
	var total_minutes := int(campaign.data["travel"]["world_minutes"])
	return "%02d:%02d" % [posmod(total_minutes / 60, 24), posmod(total_minutes, 60)]

func _set_travel_pace(pace: String) -> void:
	campaign.data["travel"]["pace"] = pace
	_show_world()

func _set_clock_speed(speed: int) -> void:
	campaign.data["travel"]["clock_playing"] = speed > 0
	if speed > 0:
		campaign.data["travel"]["time_scale"] = speed
	_show_world()

func _travel_coordinate() -> Vector2i:
	var coordinate: Array = campaign.data["travel"]["coordinate"]
	return Vector2i(int(coordinate[0]), int(coordinate[1]))

func _selected_coordinate() -> Vector2i:
	var coordinate: Array = campaign.data["travel"]["selected_coordinate"]
	return Vector2i(int(coordinate[0]), int(coordinate[1]))

func _on_hex_selected(coordinate: Vector2i) -> void:
	var tile: Dictionary = hex_region.tile_at(hex_map.tiles, coordinate)
	if tile.is_empty(): return
	campaign.data["travel"]["selected_coordinate"] = [coordinate.x, coordinate.y]
	campaign.data["travel"]["selected_poi"] = tile["poi"]
	_show_world()

func _travel_to_hex() -> void:
	var travel: Dictionary = campaign.data["travel"]
	var origin := _travel_coordinate()
	var destination := _selected_coordinate()
	if hex_region.hex_distance(origin, destination) != 1: return
	var tile: Dictionary = hex_region.tile_at(hex_map.tiles, destination)
	if not hex_region.can_enter(tile):
		feedback = "El terreno acuático bloquea el paso."
		_show_world()
		return
	var mount_bonus: float = campaign.data["character"]["mount"]["speed_bonus"]
	var hours: float = hex_region.travel_hours(tile, travel["pace"], mount_bonus)
	var previous_hours: float = travel["hours_today"]
	travel["coordinate"] = [destination.x, destination.y]
	travel["hours_today"] = previous_hours + hours
	travel["world_minutes"] += hours * 60.0
	var hex_id := _hex_id(destination)
	if hex_id not in travel["visited_hexes"]:
		travel["visited_hexes"].append(hex_id)
	_record("Viajaste al hex %s · %.2f h · %s." % [hex_id, hours, content_registry.content["biomes"][tile["biome"]]["name"]])
	feedback = "Avance: %.2f h · hora %s." % [hours, _format_world_time()]
	var old_extra_hours := maxi(0, floori(previous_hours) - 8)
	var new_extra_hours := maxi(0, floori(travel["hours_today"]) - 8)
	var fatigue_checks: int = new_extra_hours - old_extra_hours
	if fatigue_checks > 0:
		_request_forced_march_check(destination, tile, fatigue_checks)
	else:
		_resolve_hex_encounter(destination, tile)
	_show_world()

func _request_forced_march_check(destination: Vector2i, tile: Dictionary, remaining_checks: int) -> void:
	if remaining_checks <= 0:
		_resolve_hex_encounter(destination, tile)
		_show_world()
		return
	var travel: Dictionary = campaign.data["travel"]
	var dc: int = 10 + travel["fatigue_checks"]
	var constitution_modifier: int = _modifier(campaign.data["character"]["con"])
	_request_roll("Marcha forzada · salvación de Constitución 1d20 %+d contra CD %d" % [constitution_modifier, dc], Callable(rules, "saving_throw").bind(constitution_modifier, dc), func(result: Dictionary):
		travel["fatigue_checks"] += 1
		if not result["success"]:
			travel["exhaustion"] = mini(10, travel["exhaustion"] + 1)
			feedback = "Fallaste la salvación: agotamiento %d. %s" % [travel["exhaustion"], _format_check(result)]
		else:
			feedback = "Resististe la marcha forzada. %s" % _format_check(result)
		_record(feedback)
		_request_forced_march_check(destination, tile, remaining_checks - 1)
	)

func _resolve_hex_encounter(coordinate: Vector2i, tile: Dictionary) -> void:
	var travel: Dictionary = campaign.data["travel"]
	var key := _hex_id(coordinate)
	if travel["hex_encounters"].has(key): return
	var biome: Dictionary = content_registry.content["biomes"][tile["biome"]]
	var entries: Array = content_registry.content["encounters"][biome["encounter_table"]]
	var encounter: Dictionary = content_registry.roll_weighted(entries, rules.rng)
	var encounter_state := {"enemy": encounter["enemy"], "roll": encounter["roll"], "resolved": encounter["enemy"] == "none"}
	travel["hex_encounters"][key] = encounter_state
	if encounter["enemy"] == "none":
		_record("Hex %s · sin encuentro (tirada %d)." % [key, encounter["roll"]])
		feedback = "La zona está despejada. Tirada de encuentro: %d." % encounter["roll"]
		return
	var enemy: Dictionary = _enemy_definition(encounter["enemy"])
	if travel["pace"] == "cautious":
		var passive_perception := int(_passive_perception())
		_request_skill_check("Stealth", "dex", passive_perception, func(result: Dictionary):
			if result["success"]:
				travel["hex_encounters"][key]["resolved"] = true
				feedback = "Pasaste junto a la patrulla sin ser vista. %s" % _format_check(result)
				_record("Encuentro evitado en hex %s." % key)
				_show_world()
			else:
				_record("Te detectaron durante la marcha cautelosa en hex %s." % key)
				current_tab = "story"
				_start_combat(encounter["enemy"], true)
		)
		return
	var passive: int = _passive_perception() - (5 if travel["pace"] == "forced" else 0)
	var detection: Dictionary = rules.ability_check(int(enemy.get("stealth", 0)), passive)
	var ambush: bool = detection["success"]
	_record("Percepción %d · sigilo enemigo %s · %s." % [passive, _format_check(detection), "emboscada" if ambush else "detectado a tiempo"])
	current_tab = "story"
	_start_combat(encounter["enemy"], ambush)

func _buy_mount(mount_id: String) -> void:
	var mount: Dictionary = content_registry.content["mounts"].get(mount_id, {})
	var character: Dictionary = campaign.data["character"]
	if mount.is_empty() or character["gold"] < mount["price"] or not character["mount"]["id"].is_empty():
		feedback = "No puedes comprar esa montura."
		_show_world()
		return
	character["gold"] -= mount["price"]
	character["mount"] = {"id": mount_id, "speed_bonus": rules.rng.randf_range(mount["bonus_min"], mount["bonus_max"])}
	_record("Compraste %s en el establo." % mount["name"])
	feedback = "%s · +%.1f mph." % [mount["name"], character["mount"]["speed_bonus"]]
	_show_world()

func _rest_in_inn() -> void:
	var travel: Dictionary = campaign.data["travel"]
	travel["world_minutes"] += 480.0
	travel["hours_today"] = 0.0
	travel["fatigue_checks"] = 0
	travel["exhaustion"] = maxi(0, travel["exhaustion"] - 1)
	campaign.data["character"]["hp"] = campaign.data["character"]["max_hp"]
	_record("Descansaste 8 horas en la posada.")
	feedback = "Descanso completo · %s." % _format_world_time()
	_show_world()

func _enter_selected_poi() -> void:
	var poi_id: String = campaign.data["travel"]["selected_poi"]
	var poi: Dictionary = content_registry.content["points_of_interest"].get(poi_id, {})
	if poi.is_empty(): return
	campaign.data["travel"]["poi_entered"] = poi_id
	_record("Accediste a %s." % poi["name"])
	feedback = "%s · acceso directo desde la región." % poi["name"]
	_show_world()

func _leave_poi() -> void:
	campaign.data["travel"]["poi_entered"] = ""
	_record("Regresaste al mapa regional.")
	_show_world()

func _hex_id(coordinate: Vector2i) -> String:
	return "%d,%d" % [coordinate.x, coordinate.y]

func _render_story() -> void:
	if not pending_roll.is_empty():
		detail_panel.add_child(_label(pending_roll["description"], 14, PAPER))
		if die_roll_animating:
			detail_panel.add_child(_label("Los dados ruedan y caen…", 14, GOLD, true))
		else:
			_add_action("Tirar los dados", _resolve_pending_roll, GOLD)
		return
	if not last_roll_result.is_empty():
		detail_panel.add_child(_label("ÚLTIMA TIRADA", 10, MUTED, true))
		var roll_row := HBoxContainer.new()
		var die_face := PanelContainer.new()
		die_face.custom_minimum_size = Vector2(52, 52)
		die_face.add_theme_stylebox_override("panel", _stylebox(GOLD, PAPER, 2, 7))
		var roll_values: Array = last_roll_result.get("rolls", [])
		var face_value: Variant = last_roll_result.get("die", roll_values[0] if not roll_values.is_empty() else "")
		var die_value := _label(str(face_value), 25, INK, true)
		die_value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		die_value.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		die_face.add_child(die_value)
		roll_row.add_child(die_face)
		roll_row.add_child(_label(last_roll_description + "\n" + _format_check(last_roll_result), 12, PAPER))
		detail_panel.add_child(roll_row)
		die_face.rotation_degrees = 12
		create_tween().tween_property(die_face, "rotation_degrees", 0.0, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	var combat: Dictionary = campaign.data["combat"]
	if combat.get("active", false):
		detail_panel.add_child(_label("COMBATE · RONDA %d" % combat["round"], 12, RUST, true))
		var enemy_definition: Dictionary = _enemy_definition(combat["enemy_id"])
		_add_health_bar("Tú", campaign.data["character"]["hp"], campaign.data["character"]["max_hp"], MINT)
		_add_health_bar(_enemy_name(combat["enemy_id"]), combat["enemy_hp"], enemy_definition["hp"], RUST)
		if combat["enemy_prone"]:
			detail_panel.add_child(_label("DERRIBADO · ataques cuerpo a cuerpo con ventaja", 13, GOLD, true))
		if combat.get("enemy_grappled", false):
			detail_panel.add_child(_label("AGARRADO · velocidad 0 · escape CD %d" % combat["enemy_grapple_escape_dc"], 13, GOLD, true))
		if combat.get("hidden", false):
			detail_panel.add_child(_label("OCULTO · el rival no tiene línea de visión", 13, MINT, true))
		if GridNavigation.cover_bonus(campaign.data["place"], _player_position()) > 0:
			detail_panel.add_child(_label("COBERTURA PARCIAL · +2 CA contra ataques", 13, GOLD, true))
		if GridNavigation.cover_bonus(campaign.data["place"], _enemy_position()) > 0:
			detail_panel.add_child(_label("El rival está en cobertura parcial · +2 CA", 13, GOLD, true))
		var initiative_text := "Iniciativa: tú %d" % combat["player_initiative"]
		if "Mira" in campaign.data["party"] and combat.has("ally_initiative"):
			initiative_text += " · Mira %d" % combat["ally_initiative"]
		initiative_text += " · rival %d" % combat["enemy_initiative"]
		detail_panel.add_child(_label(initiative_text, 13, MUTED))
		if "Mira" in campaign.data["party"] and combat.has("ally_hp"):
			_add_health_bar("Mira", combat["ally_hp"], 12, Color("6ab5a7"))
		detail_panel.add_child(_label("Velocidad 30 pies · 6 casillas; ataca desde una casilla adyacente.", 13, PAPER))
		if combat.get("ally_turn", false):
			detail_panel.add_child(_label("TURNO TÁCTICO DE MIRA · movimiento restante: %d" % combat["ally_movement_left"], 13, GOLD, true))
			if not combat["ally_action_used"]:
				_add_action("Atacar con Mira · +3", _companion_attack, MINT)
			_add_action("Terminar turno de Mira", _end_ally_turn, MUTED)
			return
		var player_can_act: bool = combat["player_turn"] and not combat["action_used"]
		if player_can_act:
			var character: Dictionary = campaign.data["character"]
			_add_action("Atacar con %s · %+d" % [character["equipment"]["weapon"], character["attack_bonus"]], _player_attack, RUST)
			_add_action("Estudiar rival · Investigación", _study_enemy, GOLD)
			if not combat.get("hidden", false) and not _has_line_of_sight(_enemy_position(), _player_position()):
				_add_action("Esconderse · Sigilo CD 15", _hide_in_combat, MINT)
			_add_action("Agarrar · salvación de FUE o DES", _grapple_enemy, GOLD)
			var character_class: Dictionary = content_registry.content["classes"].get(campaign.data["character"]["class_id"], {})
			if character_class.has("cantrip"):
				_add_action("Lanzar %s" % character_class["cantrip"]["name"], _cast_cantrip, MINT)
			if "Topple" in campaign.data["character"]["masteries"]:
				_add_action("Atacar y activar Topple", func(): _player_attack(true), GOLD)
			_add_action("Retirarse · evita ataques de oportunidad", _disengage, MUTED)
		if player_can_act and "Mira" in campaign.data["party"] and not combat["helping"]:
			_add_action("Ayudar a Mira · ventaja en su turno", _help_companion, GOLD)
		if combat["enemy_id"] == "guard" and not campaign.data["world"]["persuasion_attempted"] and _dialogue_available("persuade_guard") and player_can_act:
			_add_action("Hablar / Influenciar · Persuasión CD 13", _persuade_guard, GOLD)
		if _item_index("tonic") >= 0 and (not combat["active"] or player_can_act):
			_add_action("Usar tónico", func(): _use_item("tonic"), GOLD)
		if player_can_act:
			_add_action("Esquivar / Defenderse", _dodge, GOLD)
			if _chebyshev(_player_position(), _enemy_position()) > 1:
				_add_action("Preparar ataque · al acercarse el rival", _ready_attack, GOLD)
		if combat["player_turn"]:
			_add_action("Terminar turno", _end_player_turn, MUTED)
		return
	if campaign.data["character"]["hp"] <= 0:
		detail_panel.add_child(_label("INCONSCIENTE", 20, RUST, true))
		detail_panel.add_child(_label("Carga un guardado anterior para volver a la expedición.", 14, PAPER))
		_add_action("Cargar guardado", _continue_game, MINT)
		_add_action("Volver al menú", _show_main_menu, MUTED)
		return
	detail_panel.add_child(_label(_entity_name(selected_id).to_upper(), 12, GOLD, true))
	if selected_id.is_empty():
		if campaign.data["place"] == "causeway":
			detail_panel.add_child(_label("La ceniza cubre la calzada. Las marcas de Mira apuntan hacia un faro roto.", 14, PAPER))
			var encounter: Dictionary = campaign.data["encounters"]["causeway"]
			if not encounter["resolved"]:
				_add_action("Reconocer la calzada", func(): _trigger_encounter("causeway"), GOLD)
			if campaign.data["regions"]["beacon"]:
				_add_action("Viajar al faro quebrado", _travel_to_beacon, MINT)
		elif campaign.data["place"] == "beacon":
			detail_panel.add_child(_label("El faro está apagado; sus marcas coinciden con la ficha recuperada.", 14, PAPER))
			var beacon_encounter: Dictionary = campaign.data["encounters"]["beacon"]
			if not beacon_encounter["resolved"]:
				_add_action("Reconocer el faro", func(): _trigger_encounter("beacon"), GOLD)
			_add_action("Reparar la señal · Investigación CD 14", _restore_beacon, MINT)
		else:
			detail_panel.add_child(_label("Las huellas recientes cruzan las ruinas.\n\nClic en el suelo para moverte; selecciona figuras u objetos para interactuar.", 14, PAPER))
			_add_action("Avanzar con sigilo", _attempt_stealth, MINT)
	elif selected_id == "scholar":
		var mira_relation: int = campaign.data["relationships"].get("mira", 0)
		detail_panel.add_child(_label("Mira, cartógrafa de campo. Confianza: %d." % mira_relation, 14, PAPER))
		if campaign.data["quests"]["sealed_ledger"] == "completed" and campaign.data["place"] != "causeway" and _dialogue_available("share_route"):
			_add_action("Compartir la ruta · Cartógrafas +1", _travel_to_causeway, MINT)
		if campaign.data["quest_complete"] and campaign.data["party"].is_empty():
			_add_action("Invitar a Mira al grupo", _recruit_scholar, GOLD)
		elif campaign.data["quests"]["causeway_markers"] == "active":
			detail_panel.add_child(_label("Mira espera noticias de las marcas de la calzada.", 13, MUTED))
		if campaign.data["quests"]["sealed_ledger"] != "completed":
			_add_action("Hablar con Mira", _talk_to_scholar, MINT)
	elif selected_id == "guard":
		detail_panel.add_child(_label("El custodio bloquea el paso. Disposición: %s." % campaign.data["world"]["guard_state"], 14, PAPER))
		if campaign.data["world"]["guard_state"] in ["hostile", "alerted"]:
			if campaign.data["world"]["guard_state"] == "hostile":
				_add_action("Intentar persuadir · Persuasión CD 13", _persuade_guard, GOLD)
			_add_action("Iniciar combate", func(): _start_combat("guard", false), RUST)
		else:
			detail_panel.add_child(_label("El camino está despejado.", 13, MINT))
	elif selected_id == "gate":
		if campaign.data["world"]["gate_open"]:
			detail_panel.add_child(_label("El arco conduce a un archivo enterrado.", 14, PAPER))
			_add_action("Entrar al archivo", _enter_archive, MINT)
		else:
			detail_panel.add_child(_label("Una reja antigua bloquea el arco.", 14, PAPER))
			_add_action("Forzar la reja · Atletismo CD 13", _force_gate, GOLD)
	elif selected_id == "watcher":
		detail_panel.add_child(_label("Una silueta patrulla el corredor. Su percepción pasiva es %d." % WATCHER_PASSIVE_PERCEPTION, 14, PAPER))
		_add_action("Cruzar con sigilo", _attempt_stealth, MINT)
	elif selected_id == "cache":
		detail_panel.add_child(_label("La tierra junto al muro está removida. Una prueba de Investigación podría revelar el escondite.", 14, PAPER))
		_add_action("Investigar · CD 13", _search_cache, GOLD)
	elif selected_id == "desk":
		detail_panel.add_child(_label("Los mapas cubren un escritorio. Una ranura oculta corta la madera.", 14, PAPER))
		_add_action("Buscar el mecanismo · CD 12", _search_ledger, GOLD)
	elif selected_id == "door":
		detail_panel.add_child(_label("El corredor vuelve al umbral de las ruinas.", 14, PAPER))
		_add_action("Volver a las ruinas", _leave_archive, MINT)
	elif selected_id == "marker":
		detail_panel.add_child(_label("Tres cortes en la piedra indican que la patrulla cambió su ruta tras el derrumbe.", 14, PAPER))
		if campaign.data["quests"]["causeway_markers"] == "active":
			_add_action("Investigar las marcas · CD 13", _search_markers, GOLD)
	elif selected_id == "beacon":
		detail_panel.add_child(_label("El faro quebrado conserva una caja de señales bajo la base.", 14, PAPER))
		_add_action("Intentar restaurar la señal · CD 14", _restore_beacon, MINT)
	elif selected_id == "beacon_path":
		detail_panel.add_child(_label("El sendero al faro está abierto.", 14, PAPER))
		_add_action("Viajar al faro", _travel_to_beacon, MINT)
	elif selected_id == "enemy":
		detail_panel.add_child(_label("Enemigo · PV %d" % campaign.data["combat"]["enemy_hp"], 14, PAPER))
		_add_action("Atacar", _player_attack, RUST)
	else:
		detail_panel.add_child(_label("PV %d/%d · CA %d" % [campaign.data["character"]["hp"], campaign.data["character"]["max_hp"], _armor_class()], 13, MUTED))
	if not feedback.is_empty():
		detail_panel.add_child(_label(feedback, 13, GOLD))

func _on_cell_clicked(cell: Vector2i) -> void:
	if not pending_roll.is_empty(): return
	var combat: Dictionary = campaign.data["combat"]
	if combat.get("active", false):
		if cell == _enemy_position():
			selected_id = "enemy"
		elif combat.get("ally_turn", false):
			var path := _find_ally_path(_ally_position(), cell, combat["ally_movement_left"])
			if not path.is_empty():
				var leaves_enemy_reach := false
				var previous_position := _ally_position()
				for step in path:
					if _chebyshev(previous_position, _enemy_position()) <= 1 and _chebyshev(step, _enemy_position()) > 1:
						leaves_enemy_reach = true
						break
					previous_position = step
				if leaves_enemy_reach and not combat.get("disengaging", false) and not combat.get("enemy_reaction_used", false):
					combat["enemy_reaction_used"] = true
					_request_roll("Ataque de oportunidad contra Mira · 1d20 +%d contra CA %d" % [_enemy_attack_bonus(), _target_ally_ac()], Callable(rules, "attack_roll").bind(_enemy_attack_bonus(), _target_ally_ac()), Callable(self, "_resolve_opportunity_attack").bind(path, "ally"))
					return
				_complete_combat_movement(path, "ally")
		elif combat["player_turn"]:
			var path := _find_path(_player_position(), cell, combat["movement_left"])
			if not path.is_empty():
				var leaves_enemy_reach := false
				var previous_position := _player_position()
				for step in path:
					if _chebyshev(previous_position, _enemy_position()) <= 1 and _chebyshev(step, _enemy_position()) > 1:
						leaves_enemy_reach = true
						break
					previous_position = step
				if leaves_enemy_reach and not combat.get("disengaging", false) and not combat.get("enemy_reaction_used", false):
					combat["enemy_reaction_used"] = true
					_request_roll("Ataque de oportunidad de %s · 1d20 +%d contra CA %d" % [_enemy_name(combat["enemy_id"]), _enemy_attack_bonus(), _target_player_ac()], Callable(rules, "attack_roll").bind(_enemy_attack_bonus(), _target_player_ac()), Callable(self, "_resolve_opportunity_attack").bind(path, "player"))
					return
				_complete_combat_movement(path)
		current_tab = "story"
		_show_world()
		return
	selected_id = _entity_at(cell)
	if not selected_id.is_empty() and _chebyshev(_player_position(), cell) > 1:
		var approach := _find_path_to_adjacent(_player_position(), cell, 4)
		if not approach.is_empty():
			campaign.data["character"]["position"] = [approach[-1].x, approach[-1].y]
			feedback = "Te acercas %d casillas." % approach.size()
		else:
			feedback = "No hay una ruta hasta ese objetivo."
		selected_id = ""
		current_tab = "story"
		_show_world()
		return
	if selected_id.is_empty():
		var path := _find_path(_player_position(), cell, 4)
		if not path.is_empty():
			campaign.data["character"]["position"] = [path[-1].x, path[-1].y]
			feedback = "Te desplazas %d casillas." % path.size()
	current_tab = "story"
	_show_world()

func _entity_at(cell: Vector2i) -> String:
	if campaign.data["combat"].get("active", false) and cell == _enemy_position(): return "enemy"
	if campaign.data["place"] == "ruins":
		if cell == Vector2i(1, 2): return "scholar"
		if cell == Vector2i(4, 2) and not campaign.data["world"].get("watcher_bypassed", false) and not campaign.data["world"].get("watcher_defeated", false): return "watcher"
		if cell == Vector2i(2, 6) and not campaign.data["world"]["chest_searched"]: return "cache"
		if cell == Vector2i(6, 3): return "gate"
		if cell == Vector2i(7, 4) and not campaign.data["world"]["guard_defeated"]: return "guard"
	elif campaign.data["place"] == "archive":
		if cell == Vector2i(6, 3): return "desk"
		if cell == Vector2i(2, 5): return "door"
	elif campaign.data["place"] == "causeway":
		if cell == Vector2i(4, 2) and campaign.data["quests"]["causeway_markers"] == "active": return "marker"
		if cell == Vector2i(7, 5) and campaign.data["regions"].get("beacon", false): return "beacon_path"
	elif campaign.data["place"] == "beacon":
		if cell in [Vector2i(6, 3), Vector2i(6, 4)]: return "beacon"
	return ""

func _find_path(start: Vector2i, target: Vector2i, max_steps: int) -> Array[Vector2i]:
	return GridNavigation.find_path(start, target, max_steps, Callable(self, "_walkable"))

func _find_path_to_adjacent(start: Vector2i, target: Vector2i, max_steps: int) -> Array[Vector2i]:
	return GridNavigation.find_path_to_adjacent(start, target, max_steps, Callable(self, "_walkable"))

func _find_ally_path(start: Vector2i, target: Vector2i, max_steps: int) -> Array[Vector2i]:
	return GridNavigation.find_path(start, target, max_steps, func(cell: Vector2i, origin: Vector2i) -> bool:
		return _walkable(cell, origin) and cell != _player_position() and cell != _enemy_position()
	)

func _walkable(cell: Vector2i, start: Vector2i) -> bool:
	if cell.x < 0 or cell.x >= 9 or cell.y < 0 or cell.y >= 8: return false
	if campaign.data["place"] == "ruins":
		if cell in [Vector2i(5, 3), Vector2i(5, 4), Vector2i(4, 5)]: return false
		if cell == Vector2i(6, 3) and not campaign.data["world"]["gate_open"]: return false
		for actor in [Vector2i(1, 2), Vector2i(4, 2), Vector2i(7, 4)]:
			if cell == actor and cell != start: return false
	elif campaign.data["place"] == "archive":
		if cell in [Vector2i(3, 2), Vector2i(3, 3), Vector2i(4, 3), Vector2i(5, 5)]: return false
	elif campaign.data["place"] == "causeway":
		if cell in [Vector2i(3, 3), Vector2i(4, 3), Vector2i(5, 4)]: return false
	elif campaign.data["place"] == "beacon":
		if cell in [Vector2i(3, 2), Vector2i(4, 2), Vector2i(3, 3), Vector2i(5, 5)]: return false
	return true

func _talk_to_scholar() -> void:
	campaign.data["world"]["scholar_met"] = true
	if campaign.data["quest_stage"] == 0:
		campaign.data["quest_stage"] = 1
		campaign.data["quests"]["sealed_ledger"] = "active"
		_record("Mira pidió recuperar el registro sellado bajo las ruinas.")
		feedback = "Las notas de Mira señalan un archivo tras la reja."
	else:
		feedback = "Mira espera junto al camino, lista para acompañarte."
	_show_world()

func _persuade_guard() -> void:
	if not _dialogue_available("persuade_guard"):
		feedback = "La relación con los custodios impide negociar ahora."
		_show_world()
		return
	_request_skill_check("Persuasion", "cha", 13, Callable(self, "_resolve_guard_persuasion"))

func _resolve_guard_persuasion(result: Dictionary) -> void:
	campaign.data["world"]["persuasion_attempted"] = true
	var combat: Dictionary = campaign.data["combat"]
	if result["success"]:
		campaign.data["world"]["guard_state"] = "neutral"
		campaign.data["world"]["gate_open"] = true
		combat["active"] = false
		_apply_dialogue_effects("persuade_guard")
		_record("El custodio aceptó dejarte pasar.")
		feedback = "Persuasión: %s. La reja se abre." % _format_check(result)
	else:
		campaign.data["world"]["guard_state"] = "alerted"
		if combat.get("active", false):
			combat["action_used"] = true
		_change_score("relationships", "guard", -1, -3, 3)
		var limits: Dictionary = content_registry.content["factions"]["wardens"]
		_change_score("reputation", "wardens", -1, limits["minimum"], limits["maximum"])
		feedback = "Persuasión: %s. El custodio ya no aceptará otra oferta." % _format_check(result)
	_show_world()

func _dialogue_available(dialogue_id: String) -> bool:
	var definition: Dictionary = content_registry.content["dialogue"].get(dialogue_id, {})
	if definition.is_empty(): return false
	var required_quest: String = definition.get("requires_quest", "")
	if not required_quest.is_empty() and campaign.data["quests"].get(required_quest) != "completed": return false
	for faction_id in definition.get("requires_min_reputation", {}):
		if campaign.data["reputation"].get(faction_id, 0) < definition["requires_min_reputation"][faction_id]: return false
	return true

func _apply_dialogue_effects(dialogue_id: String) -> void:
	var definition: Dictionary = content_registry.content["dialogue"][dialogue_id]
	for npc_id in definition.get("relationship_delta", {}):
		_change_score("relationships", npc_id, definition["relationship_delta"][npc_id], -3, 3)
	for faction_id in definition.get("reputation_delta", {}):
		var limits: Dictionary = content_registry.content["factions"].get(faction_id, {"minimum": -3, "maximum": 3})
		_change_score("reputation", faction_id, definition["reputation_delta"][faction_id], limits["minimum"], limits["maximum"])

func _change_score(section: String, key: String, delta: int, minimum: int, maximum: int) -> void:
	var values: Dictionary = campaign.data[section]
	values[key] = clampi(values.get(key, 0) + delta, minimum, maximum)

func _force_gate() -> void:
	_request_skill_check("Athletics", "str", 13, Callable(self, "_resolve_force_gate"))

func _resolve_force_gate(result: Dictionary) -> void:
	if result["success"]:
		campaign.data["world"]["gate_open"] = true
		_record("Forzaste la reja y abriste una ruta al archivo.")
		feedback = "Atletismo: %s. La reja cede." % _format_check(result)
	else:
		feedback = "Atletismo: %s. La reja resiste; puedes hablar con el custodio." % _format_check(result)
	_show_world()

func _enter_archive() -> void:
	if not campaign.data["world"]["gate_open"]: return
	campaign.data["place"] = "archive"
	campaign.data["character"]["position"] = [2, 4]
	campaign.data["regions"]["archive"] = true
	if "archive" not in campaign.data["visited_regions"]:
		campaign.data["visited_regions"].append("archive")
	_record("Entraste al archivo enterrado.")
	feedback = "El archivo conserva el polvo de una década."
	_show_world()

func _travel_to_causeway() -> void:
	if not _dialogue_available("share_route"): return
	_apply_dialogue_effects("share_route")
	campaign.data["regions"]["causeway"] = true
	campaign.data["place"] = "causeway"
	campaign.data["character"]["position"] = [1, 4]
	if "causeway" not in campaign.data["visited_regions"]:
		campaign.data["visited_regions"].append("causeway")
	_record("Mira compartió la ruta a la calzada de ceniza.")
	feedback = "Reputación de las Cartógrafas: %d." % campaign.data["reputation"]["wayfarers"]
	_show_world()

func _travel_to_beacon() -> void:
	if not campaign.data["regions"].get("beacon", false): return
	campaign.data["place"] = "beacon"
	campaign.data["character"]["position"] = [1, 4]
	if "beacon" not in campaign.data["visited_regions"]:
		campaign.data["visited_regions"].append("beacon")
	_record("Llegaste al faro quebrado.")
	feedback = "La torre aún conserva una caja de señales intacta."
	_show_world()

func _trigger_encounter(region_id: String) -> void:
	if not campaign.data["regions"].get(region_id, false): return
	var encounter_state: Dictionary = campaign.data["encounters"].get(region_id, {})
	if encounter_state.is_empty() or encounter_state["resolved"]: return
	var region: Dictionary = content_registry.content["regions"][region_id]
	var entries: Array = content_registry.content["encounters"][region["encounter_table"]]
	var result: Dictionary = content_registry.roll_weighted(entries, rules.rng)
	encounter_state["resolved"] = true
	encounter_state["roll"] = result["roll"]
	_record("Encuentro %s · tirada %d." % [region["name"], result["roll"]])
	if result["enemy"] == "none":
		feedback = "La ruta está despejada por ahora."
		_show_world()
		return
	feedback = "Una patrulla bloquea la ruta."
	_start_combat(result["enemy"], false)

func _search_markers() -> void:
	if campaign.data["place"] != "causeway" or campaign.data["quests"]["causeway_markers"] != "active": return
	_request_skill_check("Investigation", "int", 13, Callable(self, "_resolve_search_markers"))

func _resolve_search_markers(result: Dictionary) -> void:
	if result["success"]:
		campaign.data["quests"]["causeway_markers"] = "completed"
		campaign.data["quests"]["restore_beacon"] = "active"
		campaign.data["active_quest"] = "restore_beacon"
		campaign.data["regions"]["beacon"] = true
		_add_item("trail_token", "Ficha de la calzada", "quest")
		_record("Las marcas revelaron la ruta al faro quebrado.")
		feedback = "Investigación %s: el faro aparece en el mapa." % _format_check(result)
	else:
		feedback = "Investigación %s: no logras leer las marcas." % _format_check(result)
	_show_world()

func _restore_beacon() -> void:
	if campaign.data["place"] != "beacon" or campaign.data["quests"]["restore_beacon"] != "active": return
	_request_skill_check("Investigation", "int", 14, Callable(self, "_resolve_restore_beacon"))

func _resolve_restore_beacon(result: Dictionary) -> void:
	if result["success"]:
		campaign.data["quests"]["restore_beacon"] = "completed"
		campaign.data["active_quest"] = ""
		campaign.data["quest_stage"] = 3
		var limits: Dictionary = content_registry.content["factions"]["wayfarers"]
		_change_score("reputation", "wayfarers", 1, limits["minimum"], limits["maximum"])
		_change_score("relationships", "mira", 1, -3, 3)
		_add_item("tonic", "Tónico de campo", "consumable")
		_record("Restauraste la señal del faro; la ruta es visible desde las ruinas.")
		feedback = "Investigación %s: la señal vuelve a encenderse." % _format_check(result)
	else:
		feedback = "Investigación %s: el mecanismo sigue atascado." % _format_check(result)
	_show_world()

func _attempt_stealth() -> void:
	if campaign.data["world"].get("watcher_bypassed", false) or campaign.data["world"].get("watcher_defeated", false):
		feedback = "El corredor ya está despejado."
		_show_world()
		return
	var passive_perception := WATCHER_PASSIVE_PERCEPTION
	_request_skill_check("Stealth", "dex", passive_perception, func(result: Dictionary): _resolve_stealth(result, passive_perception))

func _resolve_stealth(result: Dictionary, passive_perception: int) -> void:
	if result["success"]:
		campaign.data["world"]["watcher_bypassed"] = true
		_record("Superaste al vigía sin alertarlo.")
		feedback = "Sigilo %s contra Percepción pasiva %d: éxito." % [_format_check(result), passive_perception]
		_show_world()
	else:
		feedback = "Sigilo %s contra Percepción pasiva %d: te detectaron." % [_format_check(result), passive_perception]
		_record("El vigía detectó movimiento entre las ruinas.")
		_start_combat("watcher", true)

func _search_cache() -> void:
	_request_skill_check("Investigation", "int", 13, Callable(self, "_resolve_search_cache"))

func _resolve_search_cache(result: Dictionary) -> void:
	campaign.data["world"]["chest_searched"] = true
	if result["success"]:
		_add_item("tonic", "Tónico de campo", "consumable")
		_record("Investigación reveló un tónico oculto entre las piedras.")
		feedback = "Investigación %s: encuentras un tónico." % _format_check(result)
	else:
		feedback = "Investigación %s: no había nada útil." % _format_check(result)
	_show_world()

func _search_ledger() -> void:
	_request_skill_check("Investigation", "int", 12, Callable(self, "_resolve_search_ledger"))

func _resolve_search_ledger(result: Dictionary) -> void:
	if result["success"]:
		campaign.data["world"]["ledger_found"] = true
		campaign.data["quest_complete"] = true
		campaign.data["quest_stage"] = 2
		campaign.data["quests"]["sealed_ledger"] = "completed"
		campaign.data["quests"]["causeway_markers"] = "active"
		campaign.data["active_quest"] = "causeway_markers"
		campaign.data["regions"]["causeway"] = true
		_add_item("sealed_ledger", "Registro sellado", "quest")
		_record("Descubriste y recuperaste el registro sellado.")
		_record("Nueva misión: sigue las marcas hacia la calzada de ceniza.")
		feedback = "Investigación %s: encuentras el registro." % _format_check(result)
	else:
		feedback = "Investigación %s: no encuentras el mecanismo; puedes intentarlo de nuevo." % _format_check(result)
	_show_world()

func _recruit_scholar() -> void:
	if not campaign.data["quest_complete"] or not campaign.data["party"].is_empty(): return
	campaign.data["party"].append("Mira")
	campaign.data["world"]["ally_recruited"] = true
	_record("Mira se unió al grupo tras recuperar el registro.")
	feedback = "Mira se incorpora a la expedición."
	_show_world()

func _leave_archive() -> void:
	campaign.data["place"] = "ruins"
	campaign.data["character"]["position"] = [6, 3]
	feedback = "Regresas al umbral de las ruinas."
	_record("Saliste del archivo enterrado.")
	_show_world()

func _start_combat(enemy_id: String, ambush: bool) -> void:
	var character: Dictionary = campaign.data["character"]
	var enemy_definition: Dictionary = _enemy_definition(enemy_id)
	var initiative_modifier: int = _modifier(character["dex"])
	_request_roll("Iniciativa · 1d20 %+d%s" % [initiative_modifier, " · desventaja por sorpresa" if ambush else ""], Callable(rules, "initiative").bind(initiative_modifier, false, false), func(player_roll: Dictionary):
		if "Mira" in campaign.data["party"]:
			_request_roll("Iniciativa de Mira · 1d20 +2", Callable(rules, "initiative").bind(2, false, false), func(ally_roll: Dictionary):
				_begin_combat(enemy_id, ambush, player_roll, enemy_definition, ally_roll)
			)
		else:
			_begin_combat(enemy_id, ambush, player_roll, enemy_definition)
	)

func _begin_combat(enemy_id: String, ambush: bool, player_roll: Dictionary, enemy_definition: Dictionary, ally_roll: Dictionary = {}) -> void:
	var character: Dictionary = campaign.data["character"]
	var dexterity_modifier: int = _modifier(enemy_definition["dex"])
	var enemy_roll: Dictionary = rules.initiative(dexterity_modifier, false, ambush)
	var enemy_position := Vector2i(4, 2) if enemy_id == "watcher" else Vector2i(7, 4) if enemy_id == "guard" else Vector2i(7, 5) if enemy_id == "slinger" else Vector2i(7, 2)
	var has_ally: bool = "Mira" in campaign.data["party"]
	var ally_initiative: int = ally_roll.get("total", 0)
	var turn_order: Array[String] = ["player", "enemy"]
	if enemy_roll["total"] > player_roll["total"]:
		turn_order = ["enemy", "player"]
	var initial_ally_position := _initial_ally_position(_player_position(), enemy_position)
	campaign.data["combat"] = {
		"active": true,
		"enemy_id": enemy_id,
		"enemy_position": [enemy_position.x, enemy_position.y],
		"enemy_hp": campaign.data["world"]["guard_hp"] if enemy_id == "guard" else enemy_definition["hp"],
		"enemy_prone": false,
		"enemy_grappled": false,
		"enemy_grapple_escape_dc": 0,
		"enemy_reaction_used": false,
		"disengaging": false,
		"readying": false,
		"hidden": false,
		"ally_action_used": false,
		"ally_turn": false,
		"ally_hp": 12,
		"ally_movement_left": 6,
		"ally_position": [initial_ally_position.x, initial_ally_position.y],
		"helping": false,
		"player_initiative": player_roll["total"],
		"ally_initiative": ally_initiative,
		"enemy_initiative": enemy_roll["total"],
		"player_initiative_rolls": player_roll["rolls"],
		"ally_initiative_rolls": ally_roll.get("rolls", []),
		"enemy_initiative_rolls": enemy_roll["rolls"],
		"turn_order": turn_order,
		"turn_index": 0,
		"active_turn": turn_order[0],
		"player_turn": turn_order[0] == "player",
		"round": 1,
		"movement_left": 6,
		"action_used": false,
		"dodging": false
	}
	_record("Combate contra %s%s." % [_enemy_name(enemy_id), " con sorpresa" if ambush else ""])
	_record("Iniciativa · tú %s; rival %s%s." % [_format_check(player_roll), _format_check(enemy_roll), " (desventaja por sorpresa)" if ambush else ""])
	feedback = "Iniciativa %s contra %s." % [_format_check(player_roll), _format_check(enemy_roll)]
	if campaign.data["combat"]["active_turn"] == "enemy":
		_enemy_turn()
	_show_world()

func _initial_ally_position(player_position: Vector2i, enemy_position: Vector2i) -> Vector2i:
	for offset in [Vector2i.UP, Vector2i.LEFT, Vector2i.DOWN, Vector2i.RIGHT]:
		var candidate: Vector2i = player_position + offset
		if candidate != enemy_position and _walkable(candidate, candidate):
			return candidate
	return player_position

func _player_attack(use_topple: bool = false) -> void:
	var combat: Dictionary = campaign.data["combat"]
	if not combat.get("active", false) or not combat["player_turn"] or combat["action_used"]: return
	if _chebyshev(_player_position(), _enemy_position()) > 1:
		feedback = "Objetivo fuera de alcance; muévete hasta una casilla adyacente."
		_show_world()
		return
	if not _has_line_of_sight(_player_position(), _enemy_position()):
		feedback = "No puedes atacar a través de la cobertura."
		_show_world()
		return
	var adjacent := _chebyshev(_player_position(), _enemy_position()) <= 1
	var character: Dictionary = campaign.data["character"]
	var advantage: bool = combat["enemy_prone"] and adjacent
	var disadvantage := false
	var description := "Ataque · 1d20 %+d contra CA %d" % [character["attack_bonus"], _target_enemy_ac()]
	if advantage: description += " · ventaja"
	_request_roll(description, Callable(rules, "attack_roll").bind(character["attack_bonus"], _target_enemy_ac(), advantage, disadvantage), func(attack: Dictionary):
		_resolve_player_attack(attack, use_topple, character)
	)

func _study_enemy() -> void:
	var combat: Dictionary = campaign.data["combat"]
	if not combat.get("active", false) or not combat["player_turn"] or combat["action_used"]:
		return
	var enemy: Dictionary = _enemy_definition(combat["enemy_id"])
	combat["action_used"] = true
	_request_skill_check("Investigation", "int", enemy["study_dc"], func(result: Dictionary):
		if result["success"]:
			feedback = "Estudio superado: %s" % enemy["study_clue"]
		else:
			feedback = "No logras identificar una táctica útil (%s)." % _format_check(result)
		_record(feedback)
		_show_world()
	)

func _hide_in_combat() -> void:
	var combat: Dictionary = campaign.data["combat"]
	if not combat.get("active", false) or not combat["player_turn"] or combat["action_used"] or combat.get("hidden", false):
		return
	if _has_line_of_sight(_enemy_position(), _player_position()):
		feedback = "Necesitas cobertura total o terreno que oculte por completo para esconderte."
		_show_world()
		return
	combat["action_used"] = true
	_request_skill_check("Stealth", "dex", 15, func(result: Dictionary):
		combat["hidden"] = result["success"]
		var hiding_place := "la vegetación" if GridNavigation.is_heavily_obscured(campaign.data["place"], _player_position()) else "la cobertura"
		feedback = "Te escondes entre %s (%s)." % [hiding_place, _format_check(result)] if result["success"] else "No consigues ocultarte (%s)." % _format_check(result)
		_record(feedback)
		_show_world()
	)

func _grapple_enemy() -> void:
	var combat: Dictionary = campaign.data["combat"]
	if not combat.get("active", false) or not combat["player_turn"] or combat["action_used"] or combat.get("enemy_grappled", false):
		return
	if campaign.data["character"]["equipment"]["shield"]:
		feedback = "Guarda el broquel para dejar una mano libre."
		_show_world()
		return
	var sizes := ["Tiny", "Small", "Medium", "Large", "Huge", "Gargantuan"]
	var player_size: int = sizes.find(campaign.data["character"]["size"])
	var enemy_size: int = sizes.find(_enemy_definition(combat["enemy_id"]).get("size", "Medium"))
	if enemy_size > player_size + 1:
		feedback = "El objetivo es demasiado grande para agarrarlo."
		_show_world()
		return
	if _chebyshev(_player_position(), _enemy_position()) > 1:
		feedback = "Debes estar junto al objetivo para agarrarlo."
		_show_world()
		return
	var character: Dictionary = campaign.data["character"]
	var escape_dc: int = 8 + _modifier(character["str"]) + character["proficiency_bonus"]
	var enemy: Dictionary = _enemy_definition(combat["enemy_id"])
	var enemy_modifier := maxi(_modifier(enemy.get("str", 10)), _modifier(enemy.get("dex", 10)))
	_request_roll("Agarrar · salvación del rival 1d20 %+d contra CD %d" % [enemy_modifier, escape_dc], Callable(rules, "saving_throw").bind(enemy_modifier, escape_dc), func(result: Dictionary):
		_resolve_grapple(result, escape_dc)
	)

func _cast_cantrip() -> void:
	var combat: Dictionary = campaign.data["combat"]
	if not combat.get("active", false) or not combat["player_turn"] or combat["action_used"]:
		return
	var character: Dictionary = campaign.data["character"]
	var character_class: Dictionary = content_registry.content["classes"].get(character["class_id"], {})
	if not character_class.has("cantrip"):
		return
	var cantrip: Dictionary = character_class["cantrip"]
	var target_distance: int = _chebyshev(_player_position(), _enemy_position()) * 5
	if target_distance > cantrip["range_ft"]:
		feedback = "El objetivo está fuera del alcance de %s." % cantrip["name"]
		_show_world()
		return
	if not _has_line_of_sight(_player_position(), _enemy_position()):
		feedback = "El terreno bloquea la línea de visión del objetivo."
		_show_world()
		return
	var enemy: Dictionary = _enemy_definition(combat["enemy_id"])
	if cantrip["kind"] == "save":
		var save_modifier := _modifier(enemy.get(cantrip["save_ability"], 10))
		var save_dc: int = 8 + _modifier(character[cantrip["ability"]]) + character["proficiency_bonus"]
		_request_roll("%s · salvación de %s · 1d20 %+d contra CD %d" % [cantrip["name"], cantrip["save_ability"].to_upper(), save_modifier, save_dc], Callable(rules, "saving_throw").bind(save_modifier, save_dc), Callable(self, "_resolve_cantrip_save").bind(cantrip))
		return
	var spell_attack_bonus: int = _modifier(character[cantrip["ability"]]) + character["proficiency_bonus"]
	var adjacent := target_distance <= 5
	var advantage: bool = combat["enemy_prone"] and adjacent
	var disadvantage := adjacent
	_request_roll("%s · 1d20 %+d contra CA %d%s" % [cantrip["name"], spell_attack_bonus, _target_enemy_ac(), " · desventaja por objetivo adyacente" if disadvantage else ""], Callable(rules, "attack_roll").bind(spell_attack_bonus, _target_enemy_ac(), advantage, disadvantage), Callable(self, "_resolve_cantrip_attack").bind(cantrip))

func _resolve_cantrip_save(result: Dictionary, cantrip: Dictionary) -> void:
	campaign.data["combat"]["action_used"] = true
	if result["success"]:
		feedback = "%s resiste %s (%s)." % [_enemy_name(campaign.data["combat"]["enemy_id"]), cantrip["name"], _format_check(result)]
		_record(feedback)
		_show_world()
		return
	_request_roll("Daño de %s · 1d%d" % [cantrip["name"], cantrip["damage_die"]], Callable(rules, "damage_roll").bind(1, cantrip["damage_die"], 0), Callable(self, "_resolve_cantrip_damage").bind(cantrip))

func _resolve_cantrip_attack(attack: Dictionary, cantrip: Dictionary) -> void:
	campaign.data["combat"]["action_used"] = true
	_resolve_attack_situation(attack, func(special_message: String):
		if not attack["hit"]:
			feedback = special_message + "%s falla (%s contra CA %d)." % [cantrip["name"], _format_check(attack), _target_enemy_ac()]
			_record(feedback)
			_show_world()
			return
		_request_roll(special_message + "Daño de %s · %s" % [cantrip["name"], "%dd%d" % [2 if attack["critical"] else 1, cantrip["damage_die"]]], Callable(rules, "damage_roll").bind(1, cantrip["damage_die"], 0, attack["critical"]), Callable(self, "_resolve_cantrip_damage").bind(cantrip))
	)

func _resolve_cantrip_damage(damage: Dictionary, cantrip: Dictionary) -> void:
	var combat: Dictionary = campaign.data["combat"]
	combat["enemy_hp"] = maxi(0, combat["enemy_hp"] - damage["total"])
	feedback = "%s impacta: daño %s; rival PV %d." % [cantrip["name"], _format_check(damage), combat["enemy_hp"]]
	_record(feedback)
	if combat["enemy_hp"] == 0:
		_defeat_enemy()
	_show_world()

func _resolve_attack_situation(attack: Dictionary, completion: Callable) -> void:
	if attack["die"] not in [1, 20]:
		completion.call("")
		return
	var situation := "Pifia" if attack["die"] == 1 else "Crítico"
	_request_roll("Situación especial · %s · 1d6" % situation, Callable(rules, "special_situation"), func(special: Dictionary):
		var message := ""
		if special["die"] == 1 and attack["die"] == 1:
			campaign.data["combat"]["movement_left"] = 0
			message = "Pifia: pierdes el movimiento restante. "
		elif special["die"] == 6 and attack["die"] == 20:
			campaign.data["combat"]["movement_left"] = mini(6, campaign.data["combat"]["movement_left"] + 1)
			message = "Crítico: ganas un paso adicional. "
		completion.call(message)
	)

func _has_line_of_sight(start: Vector2i, target: Vector2i) -> bool:
	if GridNavigation.is_heavily_obscured(campaign.data["place"], start) or GridNavigation.is_heavily_obscured(campaign.data["place"], target):
		return false
	return GridNavigation.has_line_of_sight(start, target, Callable(self, "_blocks_sight"))

func _blocks_sight(cell: Vector2i) -> bool:
	if campaign.data["place"] == "ruins":
		return cell in [Vector2i(5, 3), Vector2i(5, 4), Vector2i(4, 5)] or (cell == Vector2i(6, 3) and not campaign.data["world"]["gate_open"])
	if campaign.data["place"] == "archive":
		return cell in [Vector2i(3, 2), Vector2i(3, 3), Vector2i(4, 3), Vector2i(5, 5)]
	if campaign.data["place"] == "causeway":
		return cell in [Vector2i(3, 3), Vector2i(4, 3), Vector2i(5, 4)]
	return cell in [Vector2i(3, 2), Vector2i(4, 2), Vector2i(3, 3), Vector2i(5, 5)]

func _resolve_grapple(result: Dictionary, escape_dc: int) -> void:
	var combat: Dictionary = campaign.data["combat"]
	combat["action_used"] = true
	if result["success"]:
		feedback = "%s resiste el agarre (%s contra CD %d)." % [_enemy_name(combat["enemy_id"]), _format_check(result), escape_dc]
	else:
		combat["enemy_grappled"] = true
		combat["enemy_grapple_escape_dc"] = escape_dc
		feedback = "%s queda agarrado; puede usar su acción para escapar (CD %d)." % [_enemy_name(combat["enemy_id"]), escape_dc]
	_record(feedback)
	_show_world()

func _resolve_player_attack(attack: Dictionary, use_topple: bool, character: Dictionary) -> void:
	campaign.data["combat"]["action_used"] = true
	_resolve_attack_situation(attack, func(message: String):
		_continue_player_attack(attack, use_topple, character, message)
	)

func _continue_player_attack(attack: Dictionary, use_topple: bool, character: Dictionary, special_message: String) -> void:
	if attack["hit"]:
		var ability_modifier: int = _modifier(character[character["attack_ability"]])
		var damage_dice := 2 if attack["critical"] else 1
		var formula := "%dd%d %+d" % [damage_dice, character["damage_die"], ability_modifier]
		_request_roll(special_message + "Daño · " + formula, Callable(rules, "damage_roll").bind(1, character["damage_die"], ability_modifier, attack["critical"]), func(damage: Dictionary):
			_resolve_player_damage(attack, damage, use_topple, ability_modifier, special_message)
		)
	else:
		feedback = special_message + "Fallo %s contra CA %d." % [_format_check(attack), _target_enemy_ac()]
		_record(feedback)
		_show_world()

func _resolve_player_damage(attack: Dictionary, damage: Dictionary, use_topple: bool, ability_modifier: int, special_message: String) -> void:
	var combat: Dictionary = campaign.data["combat"]
	combat["enemy_hp"] = maxi(0, combat["enemy_hp"] - damage["total"])
	feedback = special_message + "Impacto %s contra CA %d; daño %s%s." % [_format_check(attack), _target_enemy_ac(), _format_check(damage), " crítico" if attack["critical"] else ""]
	if combat["enemy_hp"] == 0:
		_record(feedback)
		_defeat_enemy()
		_show_world()
		return
	if use_topple and "Topple" in campaign.data["character"]["masteries"]:
		var save_dc: int = 8 + ability_modifier + campaign.data["character"]["proficiency_bonus"]
		var saving_throw: Dictionary = rules.saving_throw(_modifier(_enemy_definition(combat["enemy_id"])["con"]), save_dc)
		if not saving_throw["success"]:
			combat["enemy_prone"] = true
			feedback += " Topple CD %d: %s; objetivo derribado." % [save_dc, _format_check(saving_throw)]
		else:
			feedback += " Topple CD %d: %s; resiste." % [save_dc, _format_check(saving_throw)]
	_record(feedback)
	_show_world()

func _end_player_turn() -> void:
	var combat: Dictionary = campaign.data["combat"]
	if not combat.get("active", false) or not combat["player_turn"]: return
	combat["player_turn"] = false
	combat["active_turn"] = "enemy"
	if combat.has("turn_order") and typeof(combat["turn_order"]) == TYPE_ARRAY:
		combat["turn_index"] = combat["turn_order"].find("enemy")
	_enemy_turn(true)
	_show_world()

func _end_ally_turn() -> void:
	var combat: Dictionary = campaign.data["combat"]
	if not combat.get("active", false) or not combat.get("ally_turn", false): return
	combat["ally_turn"] = false
	combat["active_turn"] = "enemy"
	if combat.has("turn_order") and typeof(combat["turn_order"]) == TYPE_ARRAY:
		combat["turn_index"] = combat["turn_order"].find("enemy")
	_enemy_turn(true)
	_show_world()

func _advance_turn() -> void:
	var combat: Dictionary = campaign.data["combat"]
	if not combat.get("active", false): return
	var turn_order: Array = combat.get("turn_order", ["player", "enemy"])
	var current_index: int = int(combat.get("turn_index", 0))
	var next_index: int = (current_index + 1) % turn_order.size()
	if next_index == 0:
		campaign.data["travel"]["world_minutes"] += 0.1
		combat["round"] += 1
		combat["enemy_reaction_used"] = false
	combat["turn_index"] = next_index
	var next_turn: String = str(turn_order[next_index])
	combat["active_turn"] = next_turn
	combat["player_turn"] = (next_turn == "player")
	combat["ally_turn"] = (next_turn == "ally")
	if next_turn == "player":
		combat["movement_left"] = 6
		combat["action_used"] = false
		combat["dodging"] = false
		combat["helping"] = false
		combat["disengaging"] = false
		combat["readying"] = false
	elif next_turn == "ally":
		combat["ally_movement_left"] = 6
		combat["ally_action_used"] = false
	elif next_turn == "enemy":
		_enemy_turn(false)

func _dodge() -> void:
	var combat: Dictionary = campaign.data["combat"]
	if not combat.get("active", false) or not combat["player_turn"] or combat["action_used"]:
		return
	combat["dodging"] = true
	combat["action_used"] = true
	feedback = "Te preparas para esquivar; los ataques enemigos tendrán desventaja este turno."
	_record(feedback)
	_show_world()

func _help_companion() -> void:
	var combat: Dictionary = campaign.data["combat"]
	if not combat.get("active", false) or not combat["player_turn"] or combat["action_used"] or campaign.data["party"].is_empty() or combat["ally_action_used"]:
		return
	combat["helping"] = true
	combat["action_used"] = true
	feedback = "Preparas una apertura para que Mira ataque con ventaja."
	_record(feedback)
	_show_world()

func _companion_attack() -> void:
	var combat: Dictionary = campaign.data["combat"]
	if not combat.get("active", false) or (not combat["player_turn"] and not combat.get("ally_turn", false)) or campaign.data["party"].is_empty() or combat["ally_action_used"]:
		return
	var attacker_pos: Vector2i = _ally_position() if combat.get("ally_turn", false) else _player_position()
	if _chebyshev(attacker_pos, _enemy_position()) > 1:
		feedback = "Mira no alcanza al objetivo; acércate para que pueda ayudar."
		_show_world()
		return
	var advantage: bool = combat["enemy_prone"] or combat.get("helping", false)
	combat["helping"] = false
	_request_roll("Ataque de Mira · 1d20 +3 contra CA %d%s" % [_target_enemy_ac(), " · ventaja" if advantage else ""], Callable(rules, "attack_roll").bind(3, _target_enemy_ac(), advantage), Callable(self, "_resolve_companion_attack"))

func _resolve_companion_attack(attack: Dictionary) -> void:
	var combat: Dictionary = campaign.data["combat"]
	combat["ally_action_used"] = true
	if attack["hit"]:
		_request_roll("Daño de Mira · %dd6 +1" % (2 if attack["critical"] else 1), Callable(rules, "damage_roll").bind(1, 6, 1, attack["critical"]), func(damage: Dictionary):
			_resolve_companion_damage(attack, damage)
		)
	else:
		feedback = "Mira falla: %s contra CA %d." % [_format_check(attack), _target_enemy_ac()]
		_record(feedback)
		_show_world()

func _resolve_companion_damage(attack: Dictionary, damage: Dictionary) -> void:
	var combat: Dictionary = campaign.data["combat"]
	combat["enemy_hp"] = maxi(0, combat["enemy_hp"] - damage["total"])
	feedback = "Mira impacta: %s contra CA %d, daño %s." % [_format_check(attack), _target_enemy_ac(), _format_check(damage)]
	_record(feedback)
	if combat["enemy_hp"] == 0: _defeat_enemy()
	_show_world()

func _enemy_turn(advance_round: bool = false) -> void:
	var combat: Dictionary = campaign.data["combat"]
	if not combat.get("active", false): return
	var enemy_definition: Dictionary = _enemy_definition(combat["enemy_id"])
	if combat.get("enemy_grappled", false):
		var escape_modifier := maxi(_modifier(enemy_definition.get("str", 10)), _modifier(enemy_definition.get("dex", 10)))
		var escape: Dictionary = rules.ability_check(escape_modifier, combat["enemy_grapple_escape_dc"])
		if escape["success"]:
			combat["enemy_grappled"] = false
			feedback = "%s se libera del agarre (%s)." % [_enemy_name(combat["enemy_id"]), _format_check(escape)]
		else:
			feedback = "%s no logra escapar (%s)." % [_enemy_name(combat["enemy_id"]), _format_check(escape)]
		_record(feedback)
		_finish_enemy_turn(combat, advance_round)
		return
	var skirmisher: bool = enemy_definition["behavior"] == "skirmisher"
	var enemy_position := _enemy_position()
	var player_position := _player_position()
	var starting_distance := _chebyshev(enemy_position, player_position)
	var hidden_revealed: bool = combat.get("hidden", false) and _has_line_of_sight(enemy_position, player_position)
	var movement_budget := 6
	if combat["enemy_prone"]:
		combat["enemy_prone"] = false
		movement_budget = 3
		feedback = "%s se pone de pie y gasta la mitad de su movimiento." % _enemy_name(combat["enemy_id"])
	for index in range(movement_budget):
		var current_distance := _chebyshev(enemy_position, player_position)
		if (not skirmisher and current_distance <= 1) or (skirmisher and current_distance >= 2 and current_distance <= enemy_definition["range"]): break
		var best := enemy_position
		var best_distance := current_distance
		for direction in [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]:
			var next: Vector2i = enemy_position + direction
			if next == player_position or not _walkable(next, enemy_position): continue
			var distance := _chebyshev(next, player_position)
			if (skirmisher and current_distance < 2 and distance > best_distance) or ((not skirmisher or current_distance > enemy_definition["range"]) and distance < best_distance):
				best = next
				best_distance = distance
		if best == enemy_position: break
		enemy_position = best
		hidden_revealed = hidden_revealed or (combat.get("hidden", false) and _has_line_of_sight(enemy_position, player_position))
	combat["enemy_position"] = [enemy_position.x, enemy_position.y]
	if hidden_revealed:
		combat["hidden"] = false
		feedback = "El rival te descubre al recuperar la línea de visión."
		_record(feedback)
	if combat.get("readying", false) and starting_distance > 1 and _chebyshev(enemy_position, player_position) <= 1:
		combat["readying"] = false
		var character: Dictionary = campaign.data["character"]
		_request_roll("Ataque preparado · 1d20 %+d contra CA %d" % [character["attack_bonus"], _target_enemy_ac()], Callable(rules, "attack_roll").bind(character["attack_bonus"], _target_enemy_ac()), Callable(self, "_resolve_ready_attack").bind(advance_round))
		return
	_resolve_enemy_action(advance_round)

func _resolve_ready_attack(attack: Dictionary, advance_round: bool) -> void:
	_resolve_attack_situation(attack, func(special_message: String):
		if not attack["hit"]:
			feedback = special_message + "Falla el ataque preparado (%s)." % _format_check(attack)
			_record(feedback)
			_resolve_enemy_action(advance_round)
			return
		var character: Dictionary = campaign.data["character"]
		var ability_modifier: int = _modifier(character[character["attack_ability"]])
		_request_roll(special_message + "Daño del ataque preparado · 1d%d %+d" % [character["damage_die"], ability_modifier], Callable(rules, "damage_roll").bind(1, character["damage_die"], ability_modifier, attack["critical"]), func(damage: Dictionary):
			var combat: Dictionary = campaign.data["combat"]
			combat["enemy_hp"] = maxi(0, combat["enemy_hp"] - damage["total"])
			feedback = "Ataque preparado: daño %s." % _format_check(damage)
			_record(feedback)
			if combat["enemy_hp"] == 0:
				_defeat_enemy()
				_show_world()
			else:
				_resolve_enemy_action(advance_round)
		)
	)

func _resolve_enemy_action(advance_round: bool) -> void:
	var combat: Dictionary = campaign.data["combat"]
	if not combat.get("active", false): return
	if combat.get("hidden", false):
		feedback = "%s busca tu rastro, pero la cobertura impide que te vea." % _enemy_name(combat["enemy_id"])
		_record(feedback)
		_finish_enemy_turn(combat, advance_round)
		return
	var enemy_definition: Dictionary = _enemy_definition(combat["enemy_id"])
	var skirmisher: bool = enemy_definition["behavior"] == "skirmisher"
	var enemy_position := _enemy_position()
	var player_position := _player_position()
	if _chebyshev(enemy_position, player_position) <= enemy_definition["range"]:
		var attack: Dictionary = rules.attack_roll(_enemy_attack_bonus(), _target_player_ac(), false, combat.get("dodging", false) or (skirmisher and _chebyshev(enemy_position, player_position) <= 1))
		if attack["hit"]:
			var damage: Dictionary = rules.damage_roll(1, enemy_definition["damage_die"], 1)
			campaign.data["character"]["hp"] = maxi(0, campaign.data["character"]["hp"] - damage["total"])
			feedback = "%s impacta por %s PV (%s)." % [_enemy_name(combat["enemy_id"]), _format_check(damage), _format_check(attack)]
		else:
			feedback = "%s falla (%s)." % [_enemy_name(combat["enemy_id"]), _format_check(attack)]
		_record(feedback)
		if campaign.data["character"]["hp"] == 0:
			combat["active"] = false
			feedback = "Has quedado inconsciente. Carga una partida guardada para continuar."
			_finish_enemy_turn(combat, advance_round)
			return
	_finish_enemy_turn(combat, advance_round)

func _finish_enemy_turn(combat: Dictionary, advance_round: bool) -> void:
	if advance_round:
		campaign.data["travel"]["world_minutes"] += 0.1
		combat["round"] += 1
	if not combat.get("active", false):
		return
	combat["active_turn"] = "player"
	if combat.has("turn_order") and typeof(combat["turn_order"]) == TYPE_ARRAY:
		combat["turn_index"] = combat["turn_order"].find("player")
	combat["player_turn"] = true
	combat["ally_turn"] = false
	combat["movement_left"] = 6
	combat["action_used"] = false
	combat["ally_action_used"] = false
	combat["dodging"] = false
	combat["helping"] = false
	combat["disengaging"] = false
	combat["enemy_reaction_used"] = false
	combat["readying"] = false

func _disengage() -> void:
	var combat: Dictionary = campaign.data["combat"]
	if not combat.get("active", false) or not combat["player_turn"] or combat["action_used"]:
		return
	combat["disengaging"] = true
	combat["action_used"] = true
	feedback = "Te retiras con cuidado; el movimiento de este turno no provoca ataques de oportunidad."
	_record(feedback)
	_show_world()

func _ready_attack() -> void:
	var combat: Dictionary = campaign.data["combat"]
	if not combat.get("active", false) or not combat["player_turn"] or combat["action_used"] or _chebyshev(_player_position(), _enemy_position()) <= 1:
		return
	combat["readying"] = true
	combat["action_used"] = true
	feedback = "Preparas un ataque cuerpo a cuerpo para cuando el rival se acerque."
	_record(feedback)
	_show_world()

func _resolve_opportunity_attack(attack: Dictionary, path: Array[Vector2i], target_tag: String = "player") -> void:
	if attack["hit"]:
		var enemy_dmg_die: int = _enemy_definition(campaign.data["combat"]["enemy_id"])["damage_die"]
		var dice_count := 2 if attack["critical"] else 1
		var description := "Daño del ataque de oportunidad contra Mira · %dd%d +1" % [dice_count, enemy_dmg_die] if target_tag == "ally" else "Daño del ataque de oportunidad · %dd%d +1" % [dice_count, enemy_dmg_die]
		_request_roll(description, Callable(rules, "damage_roll").bind(1, enemy_dmg_die, 1, attack["critical"]), Callable(self, "_resolve_opportunity_damage").bind(path, target_tag))
	else:
		feedback = "%s falla el ataque de oportunidad (%s)." % [_enemy_name(campaign.data["combat"]["enemy_id"]), _format_check(attack)]
		_record(feedback)
		_complete_combat_movement(path, target_tag)

func _resolve_opportunity_damage(damage: Dictionary, path: Array[Vector2i], target_tag: String = "player") -> void:
	if target_tag == "ally":
		var combat: Dictionary = campaign.data["combat"]
		combat["ally_hp"] = maxi(0, combat["ally_hp"] - damage["total"])
		feedback = "El ataque de oportunidad inflige %d PV a Mira." % damage["total"]
		_record(feedback)
		if combat["ally_hp"] == 0:
			feedback += " Mira cae inconsciente."
			_record(feedback)
		_complete_combat_movement(path, "ally")
		return
	var character: Dictionary = campaign.data["character"]
	character["hp"] = maxi(0, character["hp"] - damage["total"])
	feedback = "El ataque de oportunidad inflige %d PV." % damage["total"]
	_record(feedback)
	if character["hp"] == 0:
		campaign.data["combat"]["active"] = false
		feedback = "Has quedado inconsciente. Carga una partida guardada para continuar."
		_show_world()
		return
	_complete_combat_movement(path, "player")

func _complete_combat_movement(path: Array[Vector2i], mover: String = "player") -> void:
	if path.is_empty():
		return
	var combat: Dictionary = campaign.data["combat"]
	if mover == "ally":
		combat["ally_position"] = [path[-1].x, path[-1].y]
		combat["ally_movement_left"] -= path.size()
		feedback = "Mira se mueve %d casillas." % path.size()
		_show_world()
		return
	var hidden_revealed := false
	if combat.get("hidden", false):
		for step in path:
			if _has_line_of_sight(_enemy_position(), step):
				hidden_revealed = true
				break
	campaign.data["character"]["position"] = [path[-1].x, path[-1].y]
	combat["movement_left"] -= path.size()
	feedback = "Movimiento: %d casillas." % path.size()
	if hidden_revealed:
		combat["hidden"] = false
		feedback += " El rival recupera la línea de visión y te descubre."
	if combat.get("enemy_grappled", false) and _chebyshev(_player_position(), _enemy_position()) > 1:
		combat["enemy_grappled"] = false
		feedback += " El objetivo queda fuera de tu alcance y se libera."
	_show_world()

func _defeat_enemy() -> void:
	var enemy_id: String = campaign.data["combat"]["enemy_id"]
	if enemy_id == "guard":
		campaign.data["world"]["guard_hp"] = 0
		campaign.data["world"]["guard_defeated"] = true
		campaign.data["world"]["guard_state"] = "defeated"
		campaign.data["world"]["gate_open"] = true
	elif enemy_id == "watcher":
		campaign.data["world"]["watcher_defeated"] = true
		campaign.data["world"]["watcher_bypassed"] = true
	campaign.data["combat"]["active"] = false
	_record("%s fue derrotado." % _enemy_name(enemy_id))
	var enemy_definition: Dictionary = _enemy_definition(enemy_id)
	var loot_table: Array = content_registry.content["loot_tables"][enemy_definition["loot_table"]]
	var loot: Dictionary = content_registry.roll_weighted(loot_table, rules.rng)
	var item_definition: Dictionary = content_registry.content["items"][loot["item"]]
	for index in range(loot["quantity"]):
		_add_item(loot["item"], item_definition["name"], item_definition["kind"])
	_record("Botín: %s × %d." % [item_definition["name"], loot["quantity"]])

func _enemy_name(enemy_id: String) -> String:
	return str(_enemy_definition(enemy_id).get("name", enemy_id))

func _enemy_ac() -> int:
	return int(_enemy_definition(campaign.data["combat"]["enemy_id"])["ac"])

func _target_player_ac() -> int:
	return _armor_class() + GridNavigation.cover_bonus(campaign.data["place"], _player_position())

func _target_enemy_ac() -> int:
	return _enemy_ac() + GridNavigation.cover_bonus(campaign.data["place"], _enemy_position())

func _ally_position() -> Vector2i:
	var combat: Dictionary = campaign.data.get("combat", {})
	if combat.get("active", false) and combat.has("ally_position") and typeof(combat["ally_position"]) == TYPE_ARRAY and combat["ally_position"].size() == 2:
		return Vector2i(int(combat["ally_position"][0]), int(combat["ally_position"][1]))
	return Vector2i(2, 3)

func _target_ally_ac() -> int:
	return 13 + GridNavigation.cover_bonus(campaign.data["place"], _ally_position())

func _enemy_attack_bonus() -> int:
	return int(_enemy_definition(campaign.data["combat"]["enemy_id"])["attack_bonus"])

func _enemy_definition(enemy_id: String) -> Dictionary:
	return content_registry.content["enemies"].get(enemy_id, content_registry.content["enemies"]["guard"])

func _chebyshev(first: Vector2i, second: Vector2i) -> int:
	return maxi(absi(first.x - second.x), absi(first.y - second.y))

func _add_action(text: String, action: Callable, accent: Color) -> void:
	detail_panel.add_child(_button(text, action, accent))

func _skill_check(skill: String, ability: String, target: int) -> Dictionary:
	var character: Dictionary = campaign.data["character"]
	var result: Dictionary = rules.ability_check(_modifier(character[ability]), target, character["proficiency_bonus"], skill in character["skills"])
	_record("Tirada · %s: %s contra CD %d." % [skill, _format_check(result), target])
	return result

func _request_roll(description: String, roll_action: Callable, completion: Callable) -> void:
	if not pending_roll.is_empty():
		return
	pending_roll = {"description": description}
	pending_roll_action = roll_action
	pending_roll_completion = completion
	last_roll_description = description
	current_tab = "story"
	_show_world()

func _resolve_pending_roll() -> void:
	if pending_roll.is_empty() or not pending_roll_action.is_valid() or die_roll_animating:
		return
	var result: Dictionary = pending_roll_action.call()
	if animate_manual_dice and result.has("die") and last_roll_description.contains("d20"):
		die_roll_animating = true
		for child in detail_panel.get_children():
			if child is Button:
				child.disabled = true
		var die_view = D20_ROLL_SCENE.instantiate()
		detail_panel.add_child(die_view)
		die_view.roll_finished.connect(func(_value: int): _finish_pending_roll(result))
		die_view.roll_to(result["die"])
		return
	if animate_manual_dice and result.has("die_sides") and (last_roll_description.contains("Daño") or last_roll_description.contains("Curación")) and result["die_sides"] in [4, 6, 8, 10, 12, 20]:
		die_roll_animating = true
		for child in detail_panel.get_children():
			if child is Button:
				child.disabled = true
		var die_view = D20_ROLL_SCENE.instantiate() if result["die_sides"] == 20 else DAMAGE_DIE_VIEW_SCENE.instantiate()
		if result["die_sides"] != 20:
			die_view.sides = result["die_sides"]
		detail_panel.add_child(die_view)
		_animate_damage_die(die_view, result, 0)
		return
	_finish_pending_roll(result)

func _animate_damage_die(die_view: Control, result: Dictionary, index: int) -> void:
	var values: Array = result["rolls"]
	die_view.roll_finished.connect(func(_value: int):
		if index + 1 < values.size():
			_animate_damage_die(die_view, result, index + 1)
		else:
			die_view.queue_free()
			_finish_pending_roll(result)
	, CONNECT_ONE_SHOT)
	if result["die_sides"] == 20:
		die_view.roll_to(values[index])
	else:
		die_view.roll_to(values[index], index + 1, values.size())

func _finish_pending_roll(result: Dictionary) -> void:
	var completion := pending_roll_completion
	pending_roll.clear()
	pending_roll_action = Callable()
	pending_roll_completion = Callable()
	die_roll_animating = false
	last_roll_result = result.duplicate(true)
	_record("Dados · %s." % _format_check(result))
	if result.get("die", 0) == 1 and not result.has("hit"):
		feedback = "El dado rodó hasta el borde de la mesa: una pifia memorable. " + _format_check(result)
	elif result.get("die", 0) == 20 and not result.has("hit"):
		feedback = "El dado rebotó y quedó en veinte: un momento digno de leyenda. " + _format_check(result)
	if completion.is_valid():
		completion.call(result)
	else:
		_show_world()

func _request_skill_check(skill: String, ability: String, target: int, completion: Callable) -> void:
	var character: Dictionary = campaign.data["character"]
	var proficient: bool = skill in character["skills"]
	var modifier: int = _modifier(character[ability]) + (character["proficiency_bonus"] if proficient else 0)
	var formula := "1d20 %+d contra CD %d · %s" % [modifier, target, skill]
	var roller := Callable(rules, "ability_check").bind(_modifier(character[ability]), target, character["proficiency_bonus"], proficient)
	_request_roll(formula, roller, func(result: Dictionary):
		_record("Tirada · %s: %s contra CD %d." % [skill, _format_check(result), target])
		completion.call(result)
	)

func _format_check(result: Dictionary) -> String:
	var rolls: Array = result["rolls"]
	var dice_parts: Array[String] = []
	for roll in rolls:
		dice_parts.append(str(roll))
	var dice := "+".join(dice_parts) if not result.has("die") else str(rolls[0])
	if result.has("die") and rolls.size() > 1:
		dice += "/%s → %d" % [rolls[1], result["die"]]
	return "%s %+d = %d" % [dice, result["modifier"], result["total"]]

func _modifier(score: int) -> int:
	return floori(float(score - 10) / 2.0)

func _armor_class() -> int:
	var character: Dictionary = campaign.data["character"]
	return 11 + _modifier(character["dex"]) + (2 if character["equipment"]["shield"] else 0)

func _passive_perception() -> int:
	var character: Dictionary = campaign.data["character"]
	var proficiency: int = character["proficiency_bonus"] if "Perception" in character["skills"] else 0
	return 10 + _modifier(character["wis"]) + proficiency

func _equip_shield(item_id: String) -> void:
	if campaign.data["combat"].get("active", false):
		feedback = "No puedes cambiar el equipo durante el combate."
		_show_world()
		return
	var index := _item_index(item_id)
	if index < 0: return
	campaign.data["inventory"].remove_at(index)
	campaign.data["character"]["equipment"]["shield"] = true
	campaign.data["equipment_item"] = item_id
	feedback = "Broquel equipado · CA %d." % _armor_class()
	_show_world()

func _use_item(item_id: String) -> void:
	var combat: Dictionary = campaign.data["combat"]
	if combat.get("active", false) and (not combat["player_turn"] or combat["action_used"]):
		feedback = "Ya no tienes una acción disponible este turno."
		_show_world()
		return
	var index := _item_index(item_id)
	if index < 0 or campaign.data["inventory"][index]["kind"] != "consumable": return
	_request_roll("Curación · 2d4 +2", Callable(rules, "damage_roll").bind(2, 4, 2), func(healing: Dictionary):
		_apply_consumable(item_id, healing)
	)

func _apply_consumable(item_id: String, healing: Dictionary) -> void:
	var index := _item_index(item_id)
	if index < 0: return
	var character: Dictionary = campaign.data["character"]
	var previous_hp: int = character["hp"]
	character["hp"] = mini(character["max_hp"], character["hp"] + healing["total"])
	campaign.data["inventory"][index]["quantity"] -= 1
	if campaign.data["inventory"][index]["quantity"] <= 0:
		campaign.data["inventory"].remove_at(index)
	feedback = "Tónico: recuperas %d PV (%d → %d)." % [character["hp"] - previous_hp, previous_hp, character["hp"]]
	_record(feedback)
	if campaign.data["combat"].get("active", false):
		campaign.data["combat"]["action_used"] = true
		campaign.data["combat"]["player_turn"] = false
		_enemy_turn(true)
	_show_world()

func _discard_item(item_id: String) -> void:
	var index := _item_index(item_id)
	if index < 0: return
	if campaign.data["inventory"][index]["kind"] == "quest":
		feedback = "Los objetos de misión no se pueden descartar."
		_show_world()
		return
	var item: Dictionary = campaign.data["inventory"].pop_at(index)
	feedback = "%s descartado." % item["name"]
	_record(feedback)
	_show_world()

func _item_index(item_id: String) -> int:
	for index in range(campaign.data["inventory"].size()):
		if campaign.data["inventory"][index]["id"] == item_id: return index
	return -1

func _add_item(item_id: String, item_name: String, kind: String) -> void:
	var index := _item_index(item_id)
	if index >= 0:
		campaign.data["inventory"][index]["quantity"] += 1
	else:
		campaign.data["inventory"].append({"id": item_id, "name": item_name, "kind": kind, "quantity": 1})

func _board_state() -> Dictionary:
	var world: Dictionary = campaign.data["world"].duplicate(true)
	world["combat"] = campaign.data["combat"].duplicate(true)
	world["ally_recruited"] = "Mira" in campaign.data["party"]
	world["causeway_markers_found"] = campaign.data["quests"].get("causeway_markers") == "completed"
	world["beacon_unlocked"] = campaign.data["regions"].get("beacon", false)
	return world

func _record(message: String) -> void:
	campaign.data["journal"].append(message)
	DebugEventLog.append_event(debug_log_path, message)

func _entity_name(entity_id: String) -> String:
	return {"scholar": "Mira, cartógrafa", "guard": "Custodio del umbral", "gate": "Reja del umbral", "watcher": "Vigía del corredor"}.get(entity_id, "Exploración")

func _save_game() -> void:
	feedback = "Partida guardada." if campaign.save_game() else "No se pudo guardar."
	_show_world()

func _player_position() -> Vector2i:
	var position_values: Array = campaign.data["character"]["position"]
	return Vector2i(int(position_values[0]), int(position_values[1]))

func _enemy_position() -> Vector2i:
	var position_values: Array = campaign.data["combat"]["enemy_position"]
	return Vector2i(int(position_values[0]), int(position_values[1]))

func _label(text: String, font_size: int, color: Color, _bold: bool = false) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return label

func _add_health_bar(name: String, current: int, maximum: int, tint: Color) -> void:
	var row := VBoxContainer.new()
	row.add_child(_label("%s · PV %d/%d" % [name, current, maximum], 13, PAPER, true))
	var bar := ProgressBar.new()
	bar.min_value = 0
	bar.max_value = maximum
	bar.value = current
	bar.show_percentage = false
	bar.custom_minimum_size.y = 12
	bar.add_theme_stylebox_override("background", _stylebox(Color("172126"), LINE, 1, 3))
	bar.add_theme_stylebox_override("fill", _stylebox(tint, tint, 0, 3))
	row.add_child(bar)
	detail_panel.add_child(row)

func _button(text: String, action: Callable, accent: Color) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size.y = 38
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.add_theme_font_size_override("font_size", 13)
	button.add_theme_color_override("font_color", PAPER)
	button.add_theme_color_override("font_hover_color", accent)
	button.add_theme_stylebox_override("normal", _stylebox(Color("303f43"), LINE, 1, 2))
	button.add_theme_stylebox_override("hover", _stylebox(Color("3a4b4d"), accent, 1, 2))
	button.add_theme_stylebox_override("pressed", _stylebox(Color("1e292d"), accent, 1, 2))
	button.add_theme_stylebox_override("focus", _stylebox(Color("303f43"), GOLD, 2, 2))
	button.pressed.connect(action)
	return button

func _panel(color: Color) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _stylebox(color, LINE, 1, 3))
	panel.add_theme_constant_override("margin_left", 12)
	panel.add_theme_constant_override("margin_top", 12)
	panel.add_theme_constant_override("margin_right", 12)
	panel.add_theme_constant_override("margin_bottom", 12)
	return panel

func _stylebox(color: Color, border: Color, width: int, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = border
	style.set_border_width_all(width)
	style.set_corner_radius_all(radius)
	return style

func _clear_screen() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
