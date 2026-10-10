extends Control

signal hex_selected(coordinate: Vector2i)

const HexRegion = preload("res://scripts/hex_region.gd")
const HEX_RADIUS := 25.0
const BIOME_COLORS := {
	"grassland": Color("66834d"),
	"forest": Color("3e684f"),
	"dense_forest": Color("2e503d"),
	"paved_road": Color("8a8170"),
	"dirt_road": Color("9b8158"),
	"hill": Color("887b55"),
	"mountain": Color("777b78"),
	"volcano": Color("a4543f"),
	"swamp": Color("66765b"),
	"coast": Color("598577"),
	"river": Color("4e879b"),
	"ocean": Color("315d75"),
	"lake": Color("40758c"),
	"snow": Color("b2b9ae")
}

var region: HexRegion
var tiles: Array[Dictionary] = []
var biomes: Dictionary = {}
var points: Dictionary = {}
var current_hex := Vector2i.ZERO
var visited: Array = []
var selected_hex := Vector2i.ZERO

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	custom_minimum_size = Vector2(520, 420)

func configure(content: Dictionary, seed_value: int, coordinate: Vector2i, visited_hexes: Array, selected_coordinate: Vector2i = Vector2i(99, 99)) -> void:
	region = HexRegion.new(content, seed_value)
	tiles = region.generate()
	biomes = content["biomes"]
	points = content["points_of_interest"]
	current_hex = coordinate
	selected_hex = coordinate if selected_coordinate == Vector2i(99, 99) else selected_coordinate
	visited = visited_hexes.duplicate()
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("182126"))
	if region == null: return
	for tile in tiles:
		var coordinate := Vector2i(tile["q"], tile["r"])
		var center := _hex_center(coordinate)
		var hex := _hex_polygon(center)
		var discovered: bool = tile["revealed"] or _hex_id(coordinate) in visited
		var color: Color = BIOME_COLORS.get(tile["biome"], Color("51675c")) if discovered else Color("293338")
		if not region.can_enter(tile): color = Color("294b62") if discovered else Color("252f34")
		draw_colored_polygon(hex, color)
		draw_polyline(PackedVector2Array([hex[0], hex[1], hex[2], hex[3], hex[4], hex[5], hex[0]]), Color("8d997e") if discovered else Color("384448"), 1.0, true)
		if not discovered:
			_draw_centered("?", center, Color("aab3a8"), 13)
		elif not tile["poi"].is_empty():
			var poi: Dictionary = points[tile["poi"]]
			_draw_centered(poi["name"].substr(0, 1), center, Color("f0d187"), 13)
		if coordinate == current_hex:
			draw_arc(center, HEX_RADIUS * 0.66, 0.0, TAU, 6, Color("f2cf78"), 2.5, true)
		elif coordinate == selected_hex:
			draw_arc(center, HEX_RADIUS * 0.76, 0.0, TAU, 6, Color("b4d0a5"), 1.5, true)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var closest := Vector2i(99, 99)
		var closest_distance := INF
		for tile in tiles:
			var coordinate := Vector2i(tile["q"], tile["r"])
			var distance: float = _hex_center(coordinate).distance_to(event.position)
			if distance < closest_distance:
				closest = coordinate
				closest_distance = distance
		if closest_distance <= HEX_RADIUS:
			selected_hex = closest
			hex_selected.emit(closest)
			queue_redraw()

func _hex_center(coordinate: Vector2i) -> Vector2:
	var horizontal := HEX_RADIUS * 1.5 * coordinate.x
	var vertical := HEX_RADIUS * sqrt(3.0) * (coordinate.y + coordinate.x / 2.0)
	return size / 2.0 + Vector2(horizontal, vertical)

func _hex_polygon(center: Vector2) -> PackedVector2Array:
	var polygon := PackedVector2Array()
	for corner in range(6):
		var angle := deg_to_rad(60.0 * corner)
		polygon.append(center + Vector2(HEX_RADIUS * cos(angle), HEX_RADIUS * sin(angle)))
	return polygon

func _hex_id(coordinate: Vector2i) -> String:
	return "%d,%d" % [coordinate.x, coordinate.y]

func _draw_centered(text: String, center: Vector2, color: Color, font_size: int) -> void:
	var text_size := ThemeDB.fallback_font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	draw_string(ThemeDB.fallback_font, center - Vector2(text_size.x / 2.0, -font_size / 3.0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)