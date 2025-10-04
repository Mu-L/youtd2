extends Node


enum CsvProperty {
	ID,
	NAME_ENGLISH,
	TOOLTIP,
	ICON,
}

enum Id {
	ADVANCED_FORTUNE,
	ELEMENT_MASTERY,
	SWIFTNESS_MASTERY,
	COMBAT_MASTERY,
	MASTERY_OF_PAIN,
	ADVANCED_SORCERY,
	MASTERY_OF_MAGIC,
	MASTERY_OF_LOGISTICS,
	LOOT_MASTERY,
	ADVANCED_WISDOM,
	PILLAGE_MASTERY,
	FORTIFIED_WILL,
	INNER_FOCUS,
	BOND_OF_UNITY,
	FOUNDATION_OF_KNOWLEDGE,
	DEADLY_STRIKES,
	FORTUNES_FAVOR,
	CHALLENGE_CONQUEROR,
	MASTER_OF_DESTRUCTION,
	ADVANCED_OPTICS,
	ELEMENTAL_OVERLOAD,
	PINNACLE_OF_POWER,
	ADVANCED_SYNERGY,
	THE_PATH_OF_ASCENSION,
}

const _plus_mode_upgrade_list: Array[WisdomUpgradeProperties.Id] = [
	Id.PILLAGE_MASTERY,
	Id.FORTIFIED_WILL,
	Id.INNER_FOCUS,
	Id.BOND_OF_UNITY,
	Id.FOUNDATION_OF_KNOWLEDGE,
	Id.DEADLY_STRIKES,
	Id.FORTUNES_FAVOR,
	Id.CHALLENGE_CONQUEROR,
	Id.MASTER_OF_DESTRUCTION,
	Id.ADVANCED_OPTICS,
	Id.ELEMENTAL_OVERLOAD,
	Id.PINNACLE_OF_POWER,
	Id.ADVANCED_SYNERGY,
	Id.THE_PATH_OF_ASCENSION,
]


const PROPERTIES_PATH = "res://data/wisdom_upgrades.csv"

var _properties: Dictionary = {}


#########################
###     Built-in      ###
#########################

func _ready():
	UtilsStatic.load_csv_properties(PROPERTIES_PATH, _properties, CsvProperty.ID)

#	Check paths
	var id_list: Array = WisdomUpgradeProperties.get_id_list()
	for id in id_list:
		var icon_path: String = WisdomUpgradeProperties.get_icon_path(id)
		var icon_path_is_valid: bool = ResourceLoader.exists(icon_path)

		if !icon_path_is_valid:
			push_error("Invalid wisdom upgrade icon path: %s" % icon_path)


#########################
###       Public      ###
#########################

func get_id_list() -> Array:
	return _properties.keys()


func get_tooltip(tower_id: int) -> String:
	var tooltip_text_id: String = _get_property(tower_id, CsvProperty.TOOLTIP)
	var tooltip: String = tr(tooltip_text_id)

	return tooltip


func get_icon_path(tower_id: int) -> String:
	var icon_path: String = _get_property(tower_id, CsvProperty.ICON)

	return icon_path


func get_plus_mode_upgrade_list() -> Array[WisdomUpgradeProperties.Id]:
	return _plus_mode_upgrade_list.duplicate()


#########################
###      Private      ###
#########################

func _get_property(tower_id: int, csv_property: CsvProperty) -> String:
	if !_properties.has(tower_id):
		push_error("No properties for tower: ", tower_id)

		return ""
	
	var properties: Dictionary = _properties[tower_id]
	var value: String = properties[csv_property]

	return value
