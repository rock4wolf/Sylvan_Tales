extends SceneTree

const ContentRegistry = preload("res://scripts/content_registry.gd")

func _initialize() -> void:
	var registry = ContentRegistry.new()
	var result: Dictionary = registry.load_content()
	if not result["ok"]:
		for error in result["errors"]:
			push_error(str(error))
		quit(1)
		return
	var content: Dictionary = registry.content
	print("Contenido válido · %d especies · %d trasfondos · %d clases · %d biomas · %d enemigos" % [content["species"].size(), content["backgrounds"].size(), content["classes"].size(), content["biomes"].size(), content["enemies"].size()])
	quit()