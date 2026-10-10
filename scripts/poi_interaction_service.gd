extends RefCounted

func resolve_skill_interaction(state: Dictionary, poi_id: String, interaction_id: String, interaction: Dictionary, succeeded: bool, check_text: String, factions: Dictionary) -> String:
	var outcomes := _poi_outcomes(state, poi_id)
	if outcomes.has(interaction_id):
		return ""
	var text: String = interaction["success"] if succeeded else interaction["failure"]
	if succeeded:
		text += _apply_reputation(state, interaction.get("success_effect", {}), factions)
	text += " · %s" % check_text
	_store_outcome(state, poi_id, interaction_id, succeeded, text, outcomes)
	return text

func resolve_conversation(state: Dictionary, poi_id: String, dialogue_id: String, dialogue: Dictionary, factions: Dictionary) -> String:
	var outcomes := _poi_outcomes(state, poi_id)
	if outcomes.has(dialogue_id):
		return ""
	for npc_id in dialogue.get("relationship_delta", {}):
		var relationships: Dictionary = state["relationships"]
		relationships[npc_id] = clampi(int(relationships.get(npc_id, 0)) + int(dialogue["relationship_delta"][npc_id]), -3, 3)
	for faction_id in dialogue.get("reputation_delta", {}):
		var faction: Dictionary = factions[faction_id]
		var reputation: Dictionary = state["reputation"]
		reputation[faction_id] = clampi(int(reputation.get(faction_id, 0)) + int(dialogue["reputation_delta"][faction_id]), int(faction["minimum"]), int(faction["maximum"]))
	var text: String = dialogue["text"]
	_store_outcome(state, poi_id, dialogue_id, true, text, outcomes)
	return text

func _apply_reputation(state: Dictionary, effect: Dictionary, factions: Dictionary) -> String:
	if effect.is_empty():
		return ""
	var faction_id: String = effect["faction"]
	var faction: Dictionary = factions[faction_id]
	var reputation: Dictionary = state["reputation"]
	var previous: int = int(reputation.get(faction_id, 0))
	var current := clampi(previous + int(effect["amount"]), int(faction["minimum"]), int(faction["maximum"]))
	reputation[faction_id] = current
	var change := current - previous
	return " %s reputación con %s." % ["Aumenta %+d" % change, faction["name"]] if change != 0 else " Tu reputación con %s ya está al límite." % faction["name"]

func _poi_outcomes(state: Dictionary, poi_id: String) -> Dictionary:
	var world: Dictionary = state["world"]
	var outcomes: Dictionary = world.get("poi_outcomes", {}).get(poi_id, {})
	return outcomes

func _store_outcome(state: Dictionary, poi_id: String, action_id: String, succeeded: bool, text: String, outcomes: Dictionary) -> void:
	var world: Dictionary = state["world"]
	var all_outcomes: Dictionary = world.get("poi_outcomes", {})
	outcomes[action_id] = {"success": succeeded, "text": text}
	all_outcomes[poi_id] = outcomes
	world["poi_outcomes"] = all_outcomes
	state["world"] = world
