extends SubViewportContainer

signal roll_finished(value: int)

const COLORS := [Color("548b82"), Color("47786f"), Color("60968c"), Color("3e7069")]
const EDGES := Color("e8dfc8")

@export var sides := 6
var die_body: Node3D
var face_normals: Array[Vector3] = []

func _ready() -> void:
	custom_minimum_size = Vector2(190, 150)
	stretch = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var viewport := SubViewport.new()
	viewport.size = Vector2i(380, 300)
	viewport.transparent_bg = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(viewport)
	var world := Node3D.new()
	viewport.add_child(world)
	var camera := Camera3D.new()
	camera.position = Vector3(0, 3.4, 5.2)
	world.add_child(camera)
	camera.look_at(Vector3.ZERO)
	camera.current = true
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-48, -28, 0)
	light.light_energy = 1.5
	world.add_child(light)
	var floor := MeshInstance3D.new()
	var floor_mesh := BoxMesh.new()
	floor_mesh.size = Vector3(3.2, 0.12, 3.2)
	floor.mesh = floor_mesh
	floor.position.y = -0.06
	var floor_material := StandardMaterial3D.new()
	floor_material.albedo_color = Color("273538")
	floor_material.roughness = 0.9
	floor.material_override = floor_material
	world.add_child(floor)
	die_body = Node3D.new()
	die_body.position.y = 1.5
	world.add_child(die_body)
	_build_die()
	var caption := Label.new()
	caption.text = "D%d" % sides
	caption.position = Vector2(8, 4)
	caption.add_theme_color_override("font_color", Color("fff0c8"))
	caption.add_theme_font_size_override("font_size", 14)
	add_child(caption)

func _build_die() -> void:
	var shape := _shape(sides)
	var vertices: Array = shape["vertices"]
	var faces: Array = shape["faces"]
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.roughness = 0.34
	var edge_material := StandardMaterial3D.new()
	edge_material.albedo_color = EDGES
	var edges := ImmediateMesh.new()
	edges.surface_begin(Mesh.PRIMITIVE_LINES, edge_material)
	for face_index in range(faces.size()):
		var points: Array[Vector3] = []
		for vertex_index in faces[face_index]: points.append(vertices[vertex_index])
		var normal := (points[1] - points[0]).cross(points[2] - points[0]).normalized()
		if normal.dot(points[0]) < 0:
			points.reverse()
			normal = -normal
		face_normals.append(normal)
		for index in range(1, points.size() - 1):
			for point in [points[0], points[index], points[index + 1]]:
				surface.set_normal(normal)
				surface.set_color(COLORS[face_index % COLORS.size()])
				surface.add_vertex(point * 0.85)
		for index in range(points.size()):
			edges.surface_add_vertex(points[index] * 0.86)
			edges.surface_add_vertex(points[(index + 1) % points.size()] * 0.86)
		var center := Vector3.ZERO
		for point in points: center += point
		center = center / points.size() * 0.72
		var label := Label3D.new()
		label.text = str(face_index + 1)
		label.font_size = 48
		label.pixel_size = 0.004
		label.modulate = Color("fff0c8")
		label.outline_size = 8
		label.outline_modulate = Color("263233")
		label.billboard = BaseMaterial3D.BILLBOARD_DISABLED
		label.position = center
		die_body.add_child(label)
		label.look_at(center + normal, (points[1] - points[0]).normalized())
	edges.surface_end()
	var die_mesh := MeshInstance3D.new()
	die_mesh.mesh = surface.commit()
	die_mesh.material_override = material
	die_body.add_child(die_mesh)
	var edge_mesh := MeshInstance3D.new()
	edge_mesh.mesh = edges
	die_body.add_child(edge_mesh)

func roll_to(value: int, ordinal := 1, total := 1) -> void:
	var target_rotation := target_rotation_for_value(sides, value)
	die_body.rotation = Vector3(randf_range(-PI, PI), randf_range(-PI, PI), randf_range(-PI, PI))
	die_body.position = Vector3(randf_range(-0.3, 0.3), 1.4, randf_range(-0.3, 0.3))
	var target_basis := Basis.from_euler(target_rotation)
	var lowest_point := 0.0
	for vertex in _shape(sides)["vertices"]:
		lowest_point = minf(lowest_point, (target_basis * (vertex as Vector3).normalized() * 0.85).y)
	var resting_position := Vector3(0, -lowest_point, 0)
	var spinning_rotation := target_rotation + Vector3(TAU * 2.0, TAU * 3.0, TAU * 2.0)
	var caption: Label = get_child(1)
	caption.text = "D%d · %d/%d" % [sides, ordinal, total]
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(die_body, "rotation", spinning_rotation, 0.75).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(die_body, "position", resting_position, 0.75).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	tween.chain().tween_property(die_body, "rotation", target_rotation, 0.24).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.chain().tween_callback(func(): roll_finished.emit(value))

static func supported_sides() -> Array[int]:
	return [4, 6, 8, 10, 12]

static func face_values(die_sides: int) -> Array[int]:
	var values: Array[int] = []
	for value in range(1, die_sides + 1): values.append(value)
	return values

static func target_rotation_for_value(die_sides: int, value: int) -> Vector3:
	return Quaternion(face_normal_for_value(die_sides, value), Vector3.UP).get_euler()

static func face_normal_for_value(die_sides: int, value: int) -> Vector3:
	var shape := _shape(die_sides)
	var face_index := clampi(value, 1, die_sides) - 1
	var face: Array = shape["faces"][face_index]
	var vertices: Array = shape["vertices"]
	var a: Vector3 = vertices[face[0]]
	var b: Vector3 = vertices[face[1]]
	var c: Vector3 = vertices[face[2]]
	var normal := (b - a).cross(c - a).normalized()
	return -normal if normal.dot(a) < 0 else normal

static func _shape(die_sides: int) -> Dictionary:
	match die_sides:
		4:
			var tetra := [Vector3(1, 1, 1), Vector3(1, -1, -1), Vector3(-1, 1, -1), Vector3(-1, -1, 1)]
			return {"vertices": tetra, "faces": [[0, 1, 2], [0, 3, 1], [0, 2, 3], [1, 3, 2]]}
		6:
			var cube: Array[Vector3] = []
			for x in [-1.0, 1.0]:
				for y in [-1.0, 1.0]:
					for z in [-1.0, 1.0]: cube.append(Vector3(x, y, z))
			var cube_faces: Array = []
			for axis in range(3):
				for sign in [-1.0, 1.0]:
					var face: Array[int] = []
					for index in range(cube.size()):
						if cube[index][axis] == sign: face.append(index)
					cube_faces.append(face)
			return {"vertices": cube, "faces": cube_faces}
		8:
			var octa := [Vector3.RIGHT, Vector3.LEFT, Vector3.UP, Vector3.DOWN, Vector3.BACK, Vector3.FORWARD]
			var octa_faces: Array = []
			for x in [0, 1]:
				for y in [2, 3]:
					for z in [4, 5]: octa_faces.append([x, y, z])
			return {"vertices": octa, "faces": octa_faces}
		10, 12:
			var ring_size: int = die_sides / 2
			var bipyramid: Array[Vector3] = [Vector3.UP, Vector3.DOWN]
			for index in range(ring_size):
				var angle := TAU * index / ring_size
				bipyramid.append(Vector3(cos(angle), 0, sin(angle)))
			var bipyramid_faces: Array = []
			for index in range(ring_size):
				var current := 2 + index
				var next := 2 + (index + 1) % ring_size
				bipyramid_faces.append([0, current, next])
				bipyramid_faces.append([1, next, current])
			return {"vertices": bipyramid, "faces": bipyramid_faces}
	return {"vertices": [], "faces": []}
