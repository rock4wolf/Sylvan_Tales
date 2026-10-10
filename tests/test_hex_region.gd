extends SceneTree

const ContentRegistry = preload("res://scripts/content_registry.gd")
const HexRegion = preload("res://scripts/hex_region.gd")

func _initialize() -> void:
	var registry = ContentRegistry.new()
	assert(registry.load_content()["ok"])
	var first_region = HexRegion.new(registry.content, 77)
	var second_region = HexRegion.new(registry.content, 77)
	var tiles: Array[Dictionary] = first_region.generate()
	assert(tiles == second_region.generate())
	assert(tiles.size() == 37)
	for tile in tiles:
		assert(first_region.hex_distance(Vector2i.ZERO, Vector2i(tile["q"], tile["r"])) <= HexRegion.MAP_RADIUS)
	assert(first_region.distance_miles(Vector2i.ZERO, Vector2i(1, 0)) == 3.0)
	assert(first_region.distance_miles(Vector2i(-2, 2), Vector2i(1, -1)) == 9.0)

	var farm: Dictionary = first_region.tile_at(tiles, Vector2i.ZERO)
	assert(farm["poi"] == "farm")
	var road: Dictionary = first_region.tile_at(tiles, Vector2i(1, 0))
	assert(first_region.travel_hours(road, "normal") == 1.0)
	assert(first_region.travel_hours(road, "cautious") == 1.5)
	assert(is_equal_approx(first_region.travel_hours(road, "forced"), 0.75))
	var forest: Dictionary = road.duplicate(true)
	forest["biome"] = "dense_forest"
	assert(first_region.travel_hours(forest, "normal") == 2.0)
	var ocean: Dictionary = road.duplicate(true)
	ocean["biome"] = "ocean"
	assert(not first_region.can_enter(ocean))
	print("HexRegion checks passed")
	quit()
