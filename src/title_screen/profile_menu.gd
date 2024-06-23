extends PanelContainer


signal close_pressed()


var _setup_error_list: Array[String] = []


@export var _name_edit: TextEdit
@export var _export_exp_menu: ExportExpMenu
@export var _import_exp_menu: ImportExpMenu
@export var _level_label: Label
@export var _exp_label: Label
@export var _exp_for_next_lvl_left_label: Label
@export var _exp_for_next_lvl_label: Label
@export var _wisdom_upgrade_menu: WisdomUpgradeMenu


#########################
###     Built-in      ###
#########################

func _ready():
	var player_name: String = Settings.get_setting(Settings.PLAYER_NAME)
	_name_edit.text = player_name
	
	var exp_password: String = Settings.get_setting(Settings.EXP_PASSWORD)
	var player_exp: int = ExperiencePassword.decode(exp_password)
	
	var player_exp_is_valid: bool = player_exp != -1
	if !player_exp_is_valid:
		_setup_error_list.append("Exp password loaded from settings is invalid. Defaulting to 0 experience.")
		
		player_exp = 0
	
	_load_player_exp(player_exp)


#########################
###      Private      ###
#########################

func _load_player_exp(player_exp: int):
	_exp_label.text = str(player_exp)

	var player_level: int = PlayerExperience.get_level_at_exp(player_exp)
	_level_label.text = str(player_level)
	
	var reached_max_level: bool = player_level == Constants.PLAYER_MAX_LEVEL
	
	_exp_for_next_lvl_left_label.visible = !reached_max_level
	_exp_for_next_lvl_label.visible = !reached_max_level
	
	if !reached_max_level:
		var next_lvl: int = player_level + 1
		var exp_for_next_lvl: int = PlayerExperience.get_exp_for_level(next_lvl)
		_exp_for_next_lvl_label.text = str(exp_for_next_lvl)


#########################
###     Callbacks     ###
#########################

func _on_name_edit_text_changed():
	var new_player_name: String = _name_edit.text
	Settings.set_setting(Settings.PLAYER_NAME, new_player_name)
	Settings.flush()


func _on_close_button_pressed():
	close_pressed.emit()


func _on_import_exp_button_pressed():
	_import_exp_menu.show()


func _on_export_exp_button_pressed():
	var exp_password: String = Settings.get_setting(Settings.EXP_PASSWORD)

#	NOTE: if password in settings is empty, generate a
#	password for 0 exp so that there's something to show in
#	export menu.
	if exp_password.is_empty():
		exp_password = ExperiencePassword.encode(0)

	_export_exp_menu.set_exp_password(exp_password)
	_export_exp_menu.show()


func _on_import_exp_menu_import_pressed():
	var exp_password: String = _import_exp_menu.get_exp_password()
	var player_exp: int = ExperiencePassword.decode(exp_password)

#	NOTE: treat empty password as invalid to prevent player
#	from accidentally resetting exp to 0.
	var player_level_is_valid: bool = player_exp != -1 && !exp_password.is_empty()
	if !player_level_is_valid:
		Utils.show_popup_message(self, "Error", "Experience password is invalid.\n")
		
		return
	
	Settings.set_setting(Settings.EXP_PASSWORD, exp_password)
	Settings.flush()

	var success_message: String = "Successfully imported experience password. You now have [color=GOLD]%d[/color] experience!" % player_exp
	Utils.show_popup_message(self, "Success", success_message)
	_load_player_exp(player_exp)

#	NOTE: need to update wisdom upgrades because they depend
#	on player exp
	_wisdom_upgrade_menu.load_wisdom_upgrades_from_settings()


func _on_visibility_changed():
	if visible:
		_wisdom_upgrade_menu.load_wisdom_upgrades_from_settings()
		
		if !_setup_error_list.is_empty():
			for error in _setup_error_list:
				Utils.show_popup_message(self, "Error", error)

			_setup_error_list.clear()
