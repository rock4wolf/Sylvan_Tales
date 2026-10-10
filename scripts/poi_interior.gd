extends VBoxContainer

signal conversation_requested(dialogue_id: String)

const GOLD := Color("e3b85f")
const MUTED := Color("a8b1a1")
const PAPER := Color("e8dfc8")

func configure(interior: Dictionary, npcs: Dictionary, factions: Dictionary, relationships: Dictionary, quests: Dictionary, quest_states: Dictionary, dialogues: Dictionary, outcomes: Dictionary) -> void:
	add_theme_constant_override("separation", 5)
	if not interior.get("buildings", []).is_empty():
		_add_heading("EDIFICIOS")
		for building in interior["buildings"]:
			_add_entry(str(building["name"]), str(building["description"]))
	if not interior.get("npcs", []).is_empty():
		_add_heading("PERSONAS")
		for npc_id in interior["npcs"]:
			var npc: Dictionary = npcs[npc_id]
			var faction: Dictionary = factions[npc["faction"]]
			_add_entry(npc["name"], "%s · relación %+d" % [faction["name"], int(relationships.get(npc_id, 0))])
	if not interior.get("quests", []).is_empty():
		_add_heading("MISIONES EN ESTE LUGAR")
		for quest_id in interior["quests"]:
			_add_entry(quests[quest_id]["name"], str(quest_states.get(quest_id, "locked")).capitalize())
	if not interior.get("conversations", []).is_empty():
		_add_heading("HABLAR")
		for conversation in interior["conversations"]:
			var dialogue_id: String = conversation["id"]
			var npc: Dictionary = npcs[conversation["npc"]]
			if outcomes.has(dialogue_id):
				_add_entry(npc["name"], str(outcomes[dialogue_id]["text"]))
				_add_button("%s · resuelto" % conversation["label"], func(): pass, true)
			elif dialogues.has(dialogue_id):
				_add_button("%s · %s" % [conversation["label"], npc["name"]], conversation_requested.emit.bind(dialogue_id))

func _add_heading(text: String) -> void:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 12)
	label.add_theme_color_override("font_color", GOLD)
	add_child(label)

func _add_entry(title_text: String, detail_text: String) -> void:
	var label := Label.new()
	label.text = "%s · %s" % [title_text, detail_text]
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", 12)
	label.add_theme_color_override("font_color", PAPER if not detail_text.is_empty() else MUTED)
	add_child(label)

func _add_button(caption: String, callback: Callable, disabled := false) -> void:
	var button := Button.new()
	button.text = caption
	button.disabled = disabled
	button.pressed.connect(callback)
	add_child(button)
