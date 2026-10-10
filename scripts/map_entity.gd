extends Node2D

const ACTOR_TEXTURE = preload("res://assets/sprites/map_actor.svg")
const OBJECT_TEXTURE = preload("res://assets/sprites/map_object.svg")
const GATE_TEXTURE = preload("res://assets/sprites/map_gate.svg")

@export_enum("actor", "object", "gate") var kind := "actor"
@export var marker := ""
@export var tint := Color.WHITE

func _ready() -> void:
	var sprite: Sprite2D = $Sprite2D
	sprite.texture = {"actor": ACTOR_TEXTURE, "object": OBJECT_TEXTURE, "gate": GATE_TEXTURE}[kind]
	sprite.modulate = tint
	var label := Label.new()
	label.text = marker
	label.position = Vector2(-7, -8)
	label.size = Vector2(14, 16)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 10)
	label.add_theme_color_override("font_color", Color("172126"))
	add_child(label)
