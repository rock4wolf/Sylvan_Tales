extends SubViewportContainer

signal roll_finished(value: int)

const PHI := 1.618034
const VERTICES := [
	Vector3(-1, PHI, 0), Vector3(1, PHI, 0), Vector3(-1, -PHI, 0), Vector3(1, -PHI, 0),
	Vector3(0, -1, PHI), Vector3(0, 1, PHI), Vector3(0, -1, -PHI), Vector3(0, 1, -PHI),
	Vector3(PHI, 0, -1), Vector3(PHI, 0, 1), Vector3(-PHI, 0, -1), Vector3(-PHI, 0, 1)
]
const FACES := [
	[0, 11, 5], [0, 5, 1], [0, 1, 7], [0, 7, 10], [0, 10, 11],
	[1, 5, 9], [5, 11, 4], [11, 10, 2], [10, 7, 6], [7, 1, 8],
	[3, 9, 4], [3, 4, 2], [3, 2, 6], [3, 6, 8], [3, 8, 9],
	[4, 9, 5], [2, 4, 11], [6, 2, 10], [8, 6, 7], [9, 8, 1]
]
const FACE_COLORS := [Color("548b82"), Color("47786f"), Color("60968c"), Color("3e7069")]

var die_body: Node3D
var face_normals: Array[Vector3] = []
var values_by_face: Array[int] = []

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
	var key_light := DirectionalLight3D.new()
	key_light.rotation_degrees = Vector3(-48, -28, 0)
	key_light.light_energy = 1.5
	world.add_child(key_light)
	var fill_light := OmniLight3D.new()
	fill_light.position = Vector3(-2, 2, 2)
	fill_light.light_energy = 0.7
	world.add_child(fill_light)
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

func _build_die() -> void:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var mesh_material := StandardMaterial3D.new()
	mesh_material.vertex_color_use_as_albedo = true
	mesh_material.roughness = 0.34
	var edge_material := StandardMaterial3D.new()
	edge_material.albedo_color = Color("e8dfc8")
	var edges := ImmediateMesh.new()
	edges.surface_begin(Mesh.PRIMITIVE_LINES, edge_material)
	var face_numbering := _number_faces()
	for face_index in range(FACES.size()):
		var indices: Array = FACES[face_index]
		var a: Vector3 = VERTICES[indices[0]]
		var b: Vector3 = VERTICES[indices[1]]
		var c: Vector3 = VERTICES[indices[2]]
		var normal := (b - a).cross(c - a).normalized()
		if normal.dot(a) < 0:
			var swap := b
			b = c
			c = swap
			normal = -normal
		face_normals.append(normal)
		var shade: Color = FACE_COLORS[face_index % FACE_COLORS.size()]
		for point in [a, b, c]:
			surface.set_normal(normal)
			surface.set_color(shade)
			surface.add_vertex(point.normalized() * 0.95)
		for pair in [[a, b], [b, c], [c, a]]:
			edges.surface_add_vertex(pair[0].normalized() * 0.956)
			edges.surface_add_vertex(pair[1].normalized() * 0.956)
		var label := Label3D.new()
		label.text = str(face_numbering[face_index])
		label.font_size = 48
		label.pixel_size = 0.004
		label.modulate = Color("fff0c8")
		label.outline_size = 8
		label.outline_modulate = Color("263233")
		label.billboard = BaseMaterial3D.BILLBOARD_DISABLED
		var center := (a + b + c).normalized() * 0.79
		label.position = center
		die_body.add_child(label)
		label.look_at(center + normal, (b - a).normalized())
	edges.surface_end()
	var die_mesh := MeshInstance3D.new()
	die_mesh.mesh = surface.commit()
	die_mesh.material_override = mesh_material
	die_body.add_child(die_mesh)
	var edge_mesh := MeshInstance3D.new()
	edge_mesh.mesh = edges
	die_body.add_child(edge_mesh)
	values_by_face = face_numbering

func roll_to(value: int) -> void:
	var target_rotation := target_rotation_for_value(value)
	die_body.rotation = Vector3(randf_range(-PI, PI), randf_range(-PI, PI), randf_range(-PI, PI))
	die_body.position = Vector3(randf_range(-0.3, 0.3), 1.4, randf_range(-0.3, 0.3))
	var target_basis := Basis.from_euler(target_rotation)
	var lowest_point := 0.0
	for vertex in VERTICES:
		lowest_point = minf(lowest_point, (target_basis * vertex.normalized() * 0.95).y)
	var resting_position := Vector3(0, -lowest_point, 0)
	var spinning_rotation := target_rotation + Vector3(TAU * 2.0, TAU * 3.0, TAU * 2.0)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(die_body, "rotation", spinning_rotation, 0.75).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(die_body, "position", resting_position, 0.75).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	tween.chain().tween_property(die_body, "rotation", target_rotation, 0.24).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.chain().tween_callback(func(): roll_finished.emit(value))

static func face_values() -> Array[int]:
	return _number_faces()

static func target_rotation_for_value(value: int) -> Vector3:
	return Quaternion(face_normal_for_value(value), Vector3.UP).get_euler()

static func face_normal_for_value(value: int) -> Vector3:
	var normals: Array[Vector3] = []
	for face in FACES:
		var a: Vector3 = VERTICES[face[0]]
		var b: Vector3 = VERTICES[face[1]]
		var c: Vector3 = VERTICES[face[2]]
		var normal := (b - a).cross(c - a).normalized()
		if normal.dot(a) < 0: normal = -normal
		normals.append(normal)
	var face_index: int = _number_faces().find(clampi(value, 1, 20))
	return normals[face_index]

static func _number_faces() -> Array[int]:
	var normals: Array[Vector3] = []
	for face in FACES:
		var a: Vector3 = VERTICES[face[0]]
		var b: Vector3 = VERTICES[face[1]]
		var c: Vector3 = VERTICES[face[2]]
		var normal := (b - a).cross(c - a).normalized()
		if normal.dot(a) < 0: normal = -normal
		normals.append(normal)
	var values: Array[int] = []
	values.resize(FACES.size())
	var next_value := 1
	for face_index in range(normals.size()):
		if values[face_index] != 0: continue
		var opposite_index := 0
		for candidate in range(normals.size()):
			if normals[face_index].dot(normals[candidate]) < -0.999:
				opposite_index = candidate
				break
		values[face_index] = next_value
		values[opposite_index] = 21 - next_value
		next_value += 1
	return values
