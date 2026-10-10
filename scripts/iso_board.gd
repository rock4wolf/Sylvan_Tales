extends Control

signal cell_clicked(cell: Vector2i)

const TILE_WIDTH := 58.0
const TILE_HEIGHT := 30.0
const MAP_WIDTH := 9
const MAP_HEIGHT := 8
const GridNavigation = preload("res://scripts/grid_navigation.gd")
const MAP_ENTITY_SCENE = preload("res://scenes/entities/map_entity.tscn")

var place := "ruins"
var player_position := Vector2i(2, 4)
var selected_cell := Vector2i(-1, -1)
var world_state: Dictionary = {}
var entity_layer: Node2D

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	custom_minimum_size = Vector2(700, 500)
	entity_layer = Node2D.new()
	entity_layer.name = "Entities"
	add_child(entity_layer)
	_sync_map_entities()

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and is_instance_valid(entity_layer):
		_sync_map_entities()

func set_board(new_place: String, new_position: Vector2i, new_world_state: Dictionary) -> void:
	place = new_place
	player_position = new_position
	world_state = new_world_state
	_sync_map_entities()
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("182126"))
	for y in range(MAP_HEIGHT):
		for x in range(MAP_WIDTH):
			var cell := Vector2i(x, y)
			var center := _cell_center(cell)
			var diamond := PackedVector2Array([
				center + Vector2(0, -TILE_HEIGHT / 2),
				center + Vector2(TILE_WIDTH / 2, 0),
				center + Vector2(0, TILE_HEIGHT / 2),
				center + Vector2(-TILE_WIDTH / 2, 0)
			])
			var tile_color := Color("31483e") if (x + y) % 2 == 0 else Color("385044")
			if _is_blocked(cell):
				tile_color = Color("3d4541")
			draw_colored_polygon(diamond, tile_color)
			draw_polyline(PackedVector2Array([diamond[0], diamond[1], diamond[2], diamond[3], diamond[0]]), Color("6b7968"), 1.0, true)
			if GridNavigation.cover_bonus(place, cell) > 0:
				var cover_mark := PackedVector2Array([center + Vector2(-TILE_WIDTH * 0.28, TILE_HEIGHT * 0.28), center + Vector2(TILE_WIDTH * 0.28, TILE_HEIGHT * 0.28), center + Vector2(TILE_WIDTH * 0.28, -TILE_HEIGHT * 0.28)])
				draw_colored_polygon(cover_mark, Color("c7a65a", 0.8))
			if GridNavigation.is_heavily_obscured(place, cell):
				draw_circle(center + Vector2(-6, 1), 5, Color("7caf61"))
				draw_circle(center + Vector2(1, -3), 6, Color("5f9254"))
				draw_circle(center + Vector2(7, 2), 5, Color("8db46c"))

	if selected_cell.x >= 0:
		var selected_center := _cell_center(selected_cell)
		draw_arc(selected_center, 20.0, 0.0, TAU, 4, Color("f2cf78"), 2.0, true)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var cell := _screen_to_cell(event.position)
		if _inside_map(cell):
			selected_cell = cell
			cell_clicked.emit(cell)
			queue_redraw()

func _cell_center(cell: Vector2i) -> Vector2:
	var origin := Vector2(size.x * 0.50, 40.0)
	return origin + Vector2((cell.x - cell.y) * TILE_WIDTH / 2.0, (cell.x + cell.y) * TILE_HEIGHT / 2.0)

func _screen_to_cell(point: Vector2) -> Vector2i:
	var origin := Vector2(size.x * 0.50, 40.0)
	var local := point - origin
	var grid_x := local.x / TILE_WIDTH + local.y / TILE_HEIGHT
	var grid_y := local.y / TILE_HEIGHT - local.x / TILE_WIDTH
	return Vector2i(roundi(grid_x), roundi(grid_y))

func _inside_map(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.x < MAP_WIDTH and cell.y >= 0 and cell.y < MAP_HEIGHT

func _is_blocked(cell: Vector2i) -> bool:
	if place == "archive":
		return cell in [Vector2i(3, 2), Vector2i(3, 3), Vector2i(4, 3), Vector2i(5, 5)]
	if place == "causeway":
		return cell in [Vector2i(3, 3), Vector2i(4, 3), Vector2i(5, 4)]
	if place == "beacon":
		return cell in [Vector2i(3, 2), Vector2i(4, 2), Vector2i(3, 3), Vector2i(5, 5)]
	return cell in [Vector2i(5, 3), Vector2i(5, 4), Vector2i(4, 5)] or (cell == Vector2i(6, 3) and not world_state.get("gate_open", false))

func _sync_map_entities() -> void:
	if not is_instance_valid(entity_layer):
		return
	for child in entity_layer.get_children():
		child.free()
	if place == "ruins":
		_add_entity(Vector2i(1, 2), "actor", "E", Color("6ab5a7"))
		var combat: Dictionary = world_state.get("combat", {})
		if not combat.get("active", false) and not world_state.get("watcher_bypassed", false) and not world_state.get("watcher_defeated", false):
			_add_entity(Vector2i(4, 2), "actor", "!", Color("d9a745"))
		if not world_state.get("chest_searched", false):
			_add_entity(Vector2i(2, 6), "object", "C", Color("e2b558"))
		_add_entity(Vector2i(6, 3), "gate", "G", Color("79c48f") if world_state.get("gate_open", false) else Color("bd7757"))
		if not combat.get("active", false):
			if not world_state.get("guard_defeated", false) and world_state.get("guard_state", "hostile") not in ["neutral", "defeated"]:
				_add_entity(Vector2i(7, 4), "actor", "!", Color("c86854"))
			elif not world_state.get("guard_defeated", false):
				_add_entity(Vector2i(7, 4), "actor", "G", Color("6ab5a7"))
	elif place == "archive":
		_add_entity(Vector2i(6, 3), "object", "D", Color("e2b558"))
		_add_entity(Vector2i(2, 5), "object", "S", Color("839a94"))
	elif place == "causeway":
		if not world_state.get("causeway_markers_found", false):
			_add_entity(Vector2i(4, 2), "object", "M", Color("d9a745"))
		if world_state.get("beacon_unlocked", false):
			_add_entity(Vector2i(7, 5), "object", "B", Color("79c48f"))
	else:
		_add_entity(Vector2i(6, 3), "object", "F", Color("e2b558"))
		_add_entity(Vector2i(6, 4), "actor", "!", Color("d9a745"))
	var combat_state: Dictionary = world_state.get("combat", {})
	if combat_state.get("active", false):
		var enemy_position: Array = combat_state["enemy_position"]
		var enemy_tint := Color("b991c4") if combat_state.get("enemy_grappled", false) else Color("c86854")
		_add_entity(Vector2i(int(enemy_position[0]), int(enemy_position[1])), "actor", "!", enemy_tint)
	if world_state.get("ally_recruited", false):
		_add_entity(Vector2i(2, 3), "actor", "M", Color("6ab5a7"))
	_add_entity(player_position, "actor", "P", Color("79c48f"))

func _add_entity(cell: Vector2i, kind: String, marker: String, tint: Color) -> void:
	var entity = MAP_ENTITY_SCENE.instantiate()
	entity.kind = kind
	entity.marker = marker
	entity.tint = tint
	entity.position = _cell_center(cell) + Vector2(0, -5 if kind == "actor" else 0)
	entity_layer.add_child(entity)
