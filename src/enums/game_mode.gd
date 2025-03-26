class_name GameMode extends Node


enum enm {
	BUILD,
	RANDOM_WITH_UPGRADES,
	TOTALLY_RANDOM,
}


static var _string_map: Dictionary = {
	GameMode.enm.BUILD: "build",
	GameMode.enm.RANDOM_WITH_UPGRADES: "random_with_upgrades",
	GameMode.enm.TOTALLY_RANDOM: "totally_random",
}

static var _sell_ratio_map: Dictionary = {
	GameMode.enm.BUILD: 0.5,
	GameMode.enm.RANDOM_WITH_UPGRADES: 0.75,
	GameMode.enm.TOTALLY_RANDOM: 0.75,
}


static func convert_to_string(type: GameMode.enm):
	return _string_map[type]


static func convert_to_display_string(type: GameMode.enm):
	var string: String
	match type:
		GameMode.enm.BUILD: string = Utils.tr("GAME_MODE_BUILD")
		GameMode.enm.RANDOM_WITH_UPGRADES: string = Utils.tr("GAME_MODE_RANDOM_WITH_UPGRADES")
		GameMode.enm.TOTALLY_RANDOM: string = Utils.tr("GAME_MODE_TOTALLY_RANDOM")
	
	return string


static func convert_to_long_display_string(type: GameMode.enm):
	var string: String
	match type:
		GameMode.enm.BUILD: string = Utils.tr("GAME_MODE_LONG_BUILD")
		GameMode.enm.RANDOM_WITH_UPGRADES: string = Utils.tr("GAME_MODE_LONG_RANDOM_WITH_UPGRADES")
		GameMode.enm.TOTALLY_RANDOM: string = Utils.tr("GAME_MODE_LONG_TOTALLY_RANDOM")
	
	return string


static func from_string(string: String) -> GameMode.enm:
	var key = _string_map.find_key(string)
	
	if key != null:
		return key
	else:
		push_error("Invalid string: \"%s\". Possible values: %s" % [string, _string_map.values()])

		return GameMode.enm.BUILD


static func get_sell_ratio(game_mode: GameMode.enm) -> float:
	return _sell_ratio_map[game_mode]
