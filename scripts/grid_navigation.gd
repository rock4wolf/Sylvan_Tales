extends RefCounted

static func cover_bonus(place: String, cell: Vector2i) -> int:
	var cover_by_place := {
		"ruins": [Vector2i(4, 4), Vector2i(6, 5)],
		"archive": [Vector2i(4, 4)],
		"causeway": [Vector2i(2, 4), Vector2i(6, 4)],
		"beacon": [Vector2i(2, 4), Vector2i(6, 5)]
	}
	return 2 if cell in cover_by_place.get(place, []) else 0

static func is_heavily_obscured(place: String, cell: Vector2i) -> bool:
	return cell in {"causeway": [Vector2i(2, 5)], "beacon": [Vector2i(1, 4)]}.get(place, [])

static func find_path(start: Vector2i, target: Vector2i, max_steps: int, walkable: Callable) -> Array[Vector2i]:
	var queue: Array[Vector2i] = [start]
	var previous: Dictionary = {start: start}
	var index := 0
	while index < queue.size():
		var current := queue[index]
		index += 1
		if current == target: break
		for direction in [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]:
			var next: Vector2i = current + direction
			if previous.has(next) or not walkable.call(next, start): continue
			previous[next] = current
			queue.append(next)
	if not previous.has(target): return []
	var path: Array[Vector2i] = []
	var step := target
	while step != start:
		path.push_front(step)
		step = previous[step]
	if path.size() > max_steps: return []
	return path

static func find_path_to_adjacent(start: Vector2i, target: Vector2i, max_steps: int, walkable: Callable) -> Array[Vector2i]:
	var best_path: Array[Vector2i] = []
	for offset in [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]:
		var candidate := find_path(start, target + offset, max_steps, walkable)
		if not candidate.is_empty() and (best_path.is_empty() or candidate.size() < best_path.size()):
			best_path = candidate
	return best_path

static func has_line_of_sight(start: Vector2i, target: Vector2i, blocks_sight: Callable) -> bool:
	var delta := target - start
	var steps: int = maxi(absi(delta.x), absi(delta.y))
	if steps <= 1: return true
	for step in range(1, steps):
		var cell := start + Vector2i(roundi(float(delta.x * step) / steps), roundi(float(delta.y * step) / steps))
		if blocks_sight.call(cell): return false
	return true
