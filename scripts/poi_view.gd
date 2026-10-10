extends VBoxContainer

signal access_requested
signal leave_requested
signal rest_requested
signal mount_purchase_requested(mount_id: String)
signal interaction_requested(interaction_id: String)
signal conversation_requested(dialogue_id: String)

const PAPER := Color("e8dfc8")
const MUTED := Color("a8b1a1")
const MINT := Color("83c69a")
const GOLD := Color("e3b85f")
const POI_INTERIOR_SCENE := preload("res://scenes/ui/poi_interior.tscn")

func configure(poi: Dictionary, entered: bool, services: Array, interactions: Array, outcomes: Dictionary, mounts: Dictionary, mount_id: String, gold: int, npcs: Dictionary = {}, factions: Dictionary = {}, relationships: Dictionary = {}, quests: Dictionary = {}, quest_states: Dictionary = {}, available_dialogues: Dictionary = {}) -> void:
	for child in get_children():
		child.queue_free()
	add_theme_constant_override("separation", 8)
	var title := Label.new()
	title.text = str(poi.get("name", "Lugar")).to_upper()
	title.add_theme_font_size_override("font_size", 17)
	title.add_theme_color_override("font_color", GOLD)
	add_child(title)
	var description := Label.new()
	description.text = str(poi.get("description", ""))
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description.add_theme_font_size_override("font_size", 14)
	description.add_theme_color_override("font_color", PAPER)
	add_child(description)
	if not entered:
		_add_button("Acceder a %s" % poi.get("name", "este lugar"), access_requested.emit, MINT)
		return
	var interior: Dictionary = poi.get("interior", {})
	if not interior.is_empty():
		var interior_view = POI_INTERIOR_SCENE.instantiate()
		interior_view.configure(interior, npcs, factions, relationships, quests, quest_states, available_dialogues, outcomes)
		interior_view.conversation_requested.connect(conversation_requested.emit)
		add_child(interior_view)
	for interaction in interactions:
		var outcome: Dictionary = outcomes.get(interaction["id"], {})
		if outcome.is_empty():
			_add_button(interaction["label"], interaction_requested.emit.bind(interaction["id"]), GOLD)
		else:
			add_child(_label(str(outcome["text"]), MINT if outcome["success"] else MUTED))
			var resolved := Button.new()
			resolved.text = "%s · resuelto" % interaction["label"]
			resolved.disabled = true
			add_child(resolved)
	if "mounts" in services:
		if not mount_id.is_empty():
			add_child(_label("Montura equipada: %s" % mounts.get(mount_id, {}).get("name", mount_id), MINT))
		else:
			add_child(_label("Oro: %d · elige una montura" % gold, MUTED))
			for id in mounts:
				var mount: Dictionary = mounts[id]
				var buy := Button.new()
				buy.text = "Comprar %s · %d po" % [mount["name"], mount["price"]]
				buy.disabled = gold < int(mount["price"])
				buy.pressed.connect(mount_purchase_requested.emit.bind(str(id)))
				add_child(buy)
	if "long_rest" in services:
		_add_button("Descansar en la posada · 8 h", rest_requested.emit, MINT)
	if services.is_empty() and interactions.is_empty():
		add_child(_label("No hay actividades configuradas para este lugar todavía.", MUTED))
	_add_button("Regresar al mapa regional", leave_requested.emit, MUTED)

func _label(text: String, tint: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", 12)
	label.add_theme_color_override("font_color", tint)
	return label

func _add_button(caption: String, callback: Callable, tint: Color) -> void:
	var button := Button.new()
	button.text = caption
	button.pressed.connect(callback)
	button.add_theme_color_override("font_color", tint)
	add_child(button)
