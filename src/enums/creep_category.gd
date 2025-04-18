class_name CreepCategory extends Node

enum enm {
	UNDEAD,
	MAGIC,
	NATURE,
	ORC,
	HUMANOID,
	CHALLENGE,
}


static var _ordered_list: Array[CreepCategory.enm] = [
	CreepCategory.enm.UNDEAD,
	CreepCategory.enm.MAGIC,
	CreepCategory.enm.NATURE,
	CreepCategory.enm.ORC,
	CreepCategory.enm.HUMANOID,
	CreepCategory.enm.CHALLENGE,
]

static var _string_map: Dictionary = {
	CreepCategory.enm.UNDEAD: "undead",
	CreepCategory.enm.MAGIC: "magic",
	CreepCategory.enm.NATURE: "nature",
	CreepCategory.enm.ORC: "orc",
	CreepCategory.enm.HUMANOID: "humanoid",
	CreepCategory.enm.CHALLENGE: "challenge",
}

static var _color_map: Dictionary = {
	CreepCategory.enm.UNDEAD: Color.MEDIUM_PURPLE,
	CreepCategory.enm.MAGIC: Color.CORNFLOWER_BLUE,
	CreepCategory.enm.NATURE: Color.LIME_GREEN,
	CreepCategory.enm.ORC: Color.DARK_SEA_GREEN,
	CreepCategory.enm.HUMANOID: Color.TAN,
	CreepCategory.enm.CHALLENGE: Color.GOLD,
}


static func get_list() -> Array[CreepCategory.enm]:
	return _ordered_list


static func from_string(string: String) -> CreepCategory.enm:
	var key = _string_map.find_key(string)
	
	if key != null:
		return key
	else:
		push_error("Invalid string: \"%s\". Possible values: %s" % [string, _string_map.values()])

		return CreepCategory.enm.UNDEAD


static func convert_to_string(type: CreepCategory.enm) -> String:
	return _string_map[type]


static func get_display_string(type: CreepCategory.enm) -> String:
	var string: String
	match type:
		CreepCategory.enm.UNDEAD: string = Utils.tr("RACE_UNDEAD")
		CreepCategory.enm.MAGIC: string = Utils.tr("RACE_MAGICAL")
		CreepCategory.enm.NATURE: string = Utils.tr("RACE_NATURE")
		CreepCategory.enm.ORC: string = Utils.tr("RACE_ORC")
		CreepCategory.enm.HUMANOID: string = Utils.tr("RACE_HUMANOID")
		CreepCategory.enm.CHALLENGE: string = Utils.tr("RACE_CHALLENGE")
	
	return string


static func get_color(type: CreepCategory.enm) -> Color:
	var color: Color = _color_map[type]

	return color


static func convert_to_colored_string(type: CreepCategory.enm) -> String:
	var string: String = get_display_string(type)
	var color: Color = _color_map[type]
	var out: String = Utils.get_colored_string(string, color)

	return out


static func convert_to_mod_dmg_type(category: CreepCategory.enm) -> ModificationType.enm:
	const creep_category_to_mod_map: Dictionary = {
		CreepCategory.enm.UNDEAD: ModificationType.enm.MOD_DMG_TO_MASS,
		CreepCategory.enm.MAGIC: ModificationType.enm.MOD_DMG_TO_MAGIC,
		CreepCategory.enm.NATURE: ModificationType.enm.MOD_DMG_TO_NATURE,
		CreepCategory.enm.ORC: ModificationType.enm.MOD_DMG_TO_ORC,
		CreepCategory.enm.HUMANOID: ModificationType.enm.MOD_DMG_TO_HUMANOID,
		CreepCategory.enm.CHALLENGE: ModificationType.enm.MOD_DMG_TO_CHALLENGE,
	}

	var mod_type: ModificationType.enm = creep_category_to_mod_map[category]

	return mod_type
