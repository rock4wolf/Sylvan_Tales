extends RefCounted

const MAP_RADIUS := 3
const MILES_PER_HEX := 3.0
const PACE_SPEEDS := {"cautious": 2.0, "normal": 3.0, "forced": 4.0}

var content: Dictionary
var rng := RandomNumberGenerator.new()

func _init(content_data: Dictionary, seed_value: int) -> void:
	content = content_data
	rng.seed = seed_value

func generate() -> Array[Dictionary]:
	var tiles: Array[Dictionary] = []
	var biome_ids: Array = content["biomes"].keys()
	for q in range(-MAP_RADIUS, MAP_RADIUS + 1):
		for r in range(-MAP_RADIUS, MAP_RADIUS + 1):
			if _hex_distance(Vector2i.ZERO, Vector2i(q, r)) > MAP_RADIUS:
				continue
			var biome_id: String = biome_ids[rng.randi_range(0, biome_ids.size() - 1)]
			var point_id := _point_of_interest_at(Vector2i(q, r))
			if Vector2i(q, r) == Vector2i.ZERO:
				biome_id = "grassland"
			elif Vector2i(q, r) in [Vector2i(1, 0), Vector2i(2, -1), Vector2i(3, -1)]:
				biome_id = "paved_road"
			elif not point_id.is_empty():
				biome_id = "dirt_road"
			var biome: Dictionary = content["biomes"][biome_id]
			tiles.append({
				"q": q,
				"r": r,
				"biome": biome_id,
				"poi": point_id,
				"revealed": _hex_distance(Vector2i.ZERO, Vector2i(q, r)) <= 1
			})
	return tiles

func tile_at(tiles: Array, coordinate: Vector2i) -> Dictionary:
	for tile in tiles:
		if tile["q"] == coordinate.x and tile["r"] == coordinate.y:
			return tile
	return {}

func distance_miles(first: Vector2i, second: Vector2i) -> float:
	return _hex_distance(first, second) * MILES_PER_HEX

func can_enter(tile: Dictionary) -> bool:
	return not tile.is_empty() and not content["biomes"][tile["biome"]]["water"]

func travel_hours(tile: Dictionary, pace: String, mount_bonus: float = 0.0) -> float:
	if tile.is_empty() or pace not in PACE_SPEEDS:
		return INF
	var biome: Dictionary = content["biomes"][tile["biome"]]
	var speed: float = PACE_SPEEDS[pace] + mount_bonus
	if biome["difficult"]:
		speed *= 0.5
	return MILES_PER_HEX / speed

func hex_distance(first: Vector2i, second: Vector2i) -> int:
	return _hex_distance(first, second)

func _hex_distance(first: Vector2i, second: Vector2i) -> int:
	return int((absi(first.x - second.x) + absi(first.y - second.y) + absi(first.x + first.y - second.x - second.y)) / 2)

func _point_of_interest_at(coordinate: Vector2i) -> String:
	return {
		Vector2i.ZERO: "farm",
		Vector2i(1, 0): "stable",
		Vector2i(2, -1): "village",
		Vector2i(-2, 1): "town",
		Vector2i(0, 3): "city",
		Vector2i(-3, 0): "mine",
		Vector2i(1, 2): "cemetery",
		Vector2i(-2, -1): "burrow",
		Vector2i(3, -2): "inn",
		Vector2i(2, 2): "dungeon",
		Vector2i(-1, -3): "castle"
	}.get(coordinate, "")
