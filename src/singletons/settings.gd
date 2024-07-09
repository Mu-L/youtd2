extends Node


# Allows getting and setting persistent settings. Inteded to
# be used by settings which are editable by the player
# ingame. Settings are saved to a file on hard drive. Note
# that this is different from Config which doesn't persist
# changes. For example, on Windows the path would be:
# %appdata%/Roaming/Godot/...

signal changed()

const SETTINGS_PATH: String = "user://settings.save"

# List of setting names
const SHOW_ALL_DAMAGE_NUMBERS: String = "show_all_damage_numbers"
const ENABLE_SFX: String = "enable_sfx"
const MOUSE_SCROLL: String = "mouse_scroll"
const KEYBOARD_SCROLL: String = "keyboard_scroll"
const ENABLE_MOUSE_SCROLL: String = "enable_mouse_scroll"
const SHOW_COMBAT_LOG: String = "show_combat_log"
# NOTE: storing x and y separately instead of Vector2
# because Vector2 can't be deserialized from JSON
const COMBAT_LOG_X: String = "combat_log_x"
const COMBAT_LOG_Y: String = "combat_log_y"
const INTERFACE_SIZE: String = "interface_size"
const INTERFACE_SIZE_DICT: Dictionary = {
	"Small": 0.75,
	"Medium": 1.0,
	"Large": 1.25
}
const SHOW_TUTORIAL_ON_START: String = "show_tutorial_on_start"
const CACHED_GAME_DIFFICULTY: String = "CACHED_GAME_DIFFICULTY"
const CACHED_GAME_MODE: String = "CACHED_GAME_MODE"
const CACHED_GAME_LENGTH: String = "CACHED_GAME_LENGTH"
const PLAYER_NAME: String = "PLAYER_NAME"
const EXP_PASSWORD: String = "EXP_PASSWORD"
const WISDOM_UPGRADES_CACHED: String = "WISDOM_UPGRADES_CACHED"


var _cache: Dictionary = {}
var _default_value_map: Dictionary = {
	SHOW_ALL_DAMAGE_NUMBERS: false,
	ENABLE_SFX: true,
	MOUSE_SCROLL: 0.5,
	KEYBOARD_SCROLL: 0.5,
	ENABLE_MOUSE_SCROLL: false,
	SHOW_COMBAT_LOG: false,
	COMBAT_LOG_X: 20.0,
	COMBAT_LOG_Y: 600.0,
	INTERFACE_SIZE: "Medium",
	SHOW_TUTORIAL_ON_START: true,
	CACHED_GAME_DIFFICULTY: "beginner",
	CACHED_GAME_MODE: "random_with_upgrades",
#	NOTE: need to convert to float because JSON only
#	supports floats
	CACHED_GAME_LENGTH: Constants.WAVE_COUNT_TRIAL as float,
	PLAYER_NAME: "Player",
	EXP_PASSWORD: "",
	WISDOM_UPGRADES_CACHED: {},
}


#########################
###     Built-in      ###
#########################

func _ready():
	var settings_file: FileAccess = FileAccess.open(SETTINGS_PATH, FileAccess.READ)

	if settings_file != null and settings_file.get_length() > 0:
		var cache_string: String = settings_file.get_as_text()
		_cache = JSON.parse_string(cache_string) as Dictionary
		_validate_cache()
		
		print_verbose("Opened settings file at path:", settings_file.get_path_absolute())
	else:
		var open_error: Error = FileAccess.get_open_error()
		if open_error == Error.ERR_FILE_NOT_FOUND:
			print_verbose("No settings file found. Will create new one from scratch.")
		else:
			push_error("Failed to open settings file. Error:", error_string(open_error))

		_cache = _default_value_map

#		NOTE: call flush() to save default settings to file.
#		This will create settings file for the first time.
		flush()


#########################
###       Public      ###
#########################

func get_setting(setting: String) -> Variant:
	if !_default_value_map.has(setting):
		push_error("No such setting exists:" % setting)

		return null

	var default_value: Variant = _default_value_map[setting]
	var value: Variant = _cache.get(setting, default_value)

	return value


func get_bool_setting(setting: String) -> bool:
	var value: bool = get_setting(setting) as bool

	return value


func set_setting(setting: String, value: Variant):
	_cache[setting] = value


# Save all changes to file
func flush():
	var settings_file: FileAccess = FileAccess.open(SETTINGS_PATH, FileAccess.WRITE)
	var cache_string: String = JSON.stringify(_cache, "    ")
	settings_file.store_line(cache_string)

#	NOTE: need to update interface size here so that this
#	updates both in TitleScreen and GameScene
	var interface_size: float = Settings.get_interface_size()
	get_tree().root.content_scale_factor = interface_size
	
	changed.emit()


func get_interface_size() -> float:
	var interface_size_string: String = _cache[Settings.INTERFACE_SIZE]
	var interface_size: float = INTERFACE_SIZE_DICT[interface_size_string]

	return interface_size


# NOTE: need to convert keys to ints because JSON dicts
# forces keys to be strings.
func get_wisdom_upgrades() -> Dictionary:
	var upgrades_from_file: Dictionary = Settings.get_setting(Settings.WISDOM_UPGRADES_CACHED) as Dictionary
	
	var result: Dictionary = {}

	var upgrade_id_list: Array = WisdomUpgradeProperties.get_id_list()
	for upgrade_id in upgrade_id_list:
		if upgrades_from_file.has(upgrade_id):
			result[upgrade_id] = upgrades_from_file[upgrade_id]
		elif upgrades_from_file.has(str(upgrade_id)):
			result[upgrade_id] = upgrades_from_file[str(upgrade_id)]
		else:
			result[upgrade_id] = false

	return result


#########################
###      Private      ###
#########################

func _validate_cache():
	var cache_was_fixed: bool = false

	for _cache_key in _default_value_map.keys():
		if !_cache.has(_cache_key):
			push_error("Settings file doesn't have value for [%s]. Resetting it to default." % _cache_key)
			_cache[_cache_key] = _default_value_map[_cache_key]
			cache_was_fixed = true

#		Cache should have comparable types with the default map
		if typeof(_default_value_map[_cache_key]) != typeof(_cache[_cache_key]):
			push_error("Saved setting [%s] has incorrect type. Resetting it to default." % _cache_key)
			_cache[_cache_key] = _default_value_map[_cache_key]
			cache_was_fixed = true

#	NOTE: need to flush settings if cache was fixed to save
#	fixed settings to file
	if cache_was_fixed:
		flush()
