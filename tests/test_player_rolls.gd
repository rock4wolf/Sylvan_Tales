extends SceneTree

const Game = preload("res://scripts/game.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var game = Game.new()
	root.add_child(game)
	game.campaign.start_new("Dados")
	var consequences := {"applied": false}
	game._request_skill_check("Athletics", "str", 1, func(result: Dictionary):
		consequences["applied"] = result["success"]
	)
	assert(not consequences["applied"])
	assert(not game.pending_roll.is_empty())
	assert(game.pending_roll["description"].contains("1d20"))
	game._resolve_pending_roll()
	assert(consequences["applied"])
	assert(game.pending_roll.is_empty())
	assert(game.last_roll_result.has("rolls"))
	print("PlayerRoll checks passed")
	quit()