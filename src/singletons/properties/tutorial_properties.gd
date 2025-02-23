extends Node


enum TutorialId {
	INTRO_FOR_RANDOM_MODE = 0,
	INTRO_FOR_BUILD_MODE,
	RESEARCH_ELEMENTS,
	ROLL_TOWERS,
	TOWER_STASH,
	BUILD_TOWER,
	RESOURCES,
	TOWER_INFO,
	ITEMS,
	TOWER_LEVELS,
	PORTAL_DAMAGE,
	WAVE_1_FINISHED,
	CHALLENGE_WAVE,
	UPGRADING,
	TRANSFORMING,
	
	COUNT,
}

enum CsvProperty {
	TITLE_ENGLISH,
	TITLE,
	TEXT,
}

const PROPERTIES_PATH = "res://data/hints/tutorial.csv"

var _properties: Dictionary = {}


#########################
###     Built-in      ###
#########################

func _ready():
	UtilsStatic.load_csv_properties_with_automatic_ids(PROPERTIES_PATH, _properties)
	
	for id in range(1, TutorialId.COUNT):
		var id_exists: bool = _properties.has(id)
		
		if !id_exists:
			push_error("Missing tutorial with id %s" % id)


#########################
###       Public      ###
#########################

func get_title(id: int) -> String:
	var title_text_id: String = _get_property(id, CsvProperty.TITLE)
	var title: String = tr(title_text_id)
	
	return title


func get_text(id: int) -> String:
	var text_text_id: String = _get_property(id, CsvProperty.TEXT)
	var text: String = tr(text_text_id)
	
	return text


#########################
###      Private      ###
#########################

func _get_property(id: int, property: CsvProperty) -> String:
	if !_properties.has(id):
		push_error("No properties for id: ", id)

		return ""

	var map: Dictionary = _properties[id]
	var property_value: String = map[property]

	return property_value
