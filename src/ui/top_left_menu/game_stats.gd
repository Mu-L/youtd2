class_name GameStats extends VBoxContainer


@export var _settings_label: RichTextLabel

@export var _builder_label: Label

@export var _stats_label: RichTextLabel


#########################
###     Built-in      ###
#########################

func _ready():
	var wave_count: int = Globals.get_wave_count()
	var game_mode: GameMode.enm = Globals.get_game_mode()
	var difficulty: Difficulty.enm = Globals.get_difficulty()
	var team_mode: TeamMode.enm = Globals.get_team_mode()
	var match_config_string: String = MatchConfig.convert_configs_to_string(wave_count, game_mode, difficulty, team_mode)

	_settings_label.text = match_config_string


func _process(_delta: float):
	var player_stats_text: String = _get_player_stats_text()
	var your_best_towers_text: String = _get_your_best_towers_text()
	var overall_best_towers_text: String = _get_overall_best_towers_text()

	_stats_label.clear()
	_stats_label.append_text(player_stats_text)
	_stats_label.append_text(" \n")
	_stats_label.append_text("[color=GOLD]%s[/color]\n" % tr("GAME_STATS_YOUR_BEST_TOWERS"))
	_stats_label.append_text(your_best_towers_text)
	
	if Globals.get_player_mode() == PlayerMode.enm.MULTIPLAYER:
		_stats_label.append_text("\n")
		_stats_label.append_text("[color=GOLD]%s[/color]\n" % tr("GAME_STATS_OVERALL_BEST_TOWERS"))
		_stats_label.append_text(overall_best_towers_text)


#########################
###       Public      ###
#########################

func connect_to_local_player(local_player: Player):
	local_player.selected_builder.connect(_on_local_player_selected_builder)


func _get_player_stats_text() -> String:
	var player_list: Array[Player] = PlayerManager.get_player_list()

	var text: String = ""

	text += "[table=7]"
	text += "[cell][color=GOLD]%s[/color][/cell][cell][color=GOLD]%s[/color][/cell][cell][color=GOLD]%s[/color][/cell][cell][color=GOLD]%s[/color][/cell][cell][color=GOLD]%s[/color][/cell][cell][color=GOLD]%s[/color][/cell][cell][color=GOLD]%s[/color][/cell]" % [tr("GAME_STATS_COLUMN_NAME"), tr("GAME_STATS_COLUMN_TEAM"), tr("GAME_STATS_COLUMN_SCORE"), tr("GAME_STATS_COLUMN_LIVES"), tr("GAME_STATS_COLUMN_LEVEL"), tr("GAME_STATS_COLUMN_TOTAL_DAMAGE"), tr("GAME_STATS_COLUMN_GOLD")]

	player_list.sort_custom(
		func(a, b) -> bool:
			var id_a: int = a.get_id()
			var id_b: int = b.get_id()
			
			return id_a < id_b
	)

	for player in player_list:
		var player_name: String = player.get_player_name_with_color()

		var team: Team = player.get_team()
		var team_id: int = team.get_id()
		var team_string: String = "%s %d" % [tr("GAME_STATS_COLUMN_TEAM"), team_id]

		var score: float = player.get_score()
		var score_string: String = TowerDetails.int_format(floori(score))

		var lives_string: String = player.get_team().get_lives_string()

		var wave_level: float = player.get_team().get_level()
		var wave_level_string: String = str(wave_level)

		var total_damage: float = player.get_total_damage()
		var total_damage_string: String = TowerDetails.int_format(total_damage)

		var gold: int = floori(player.get_gold())
		var gold_string: String = TowerDetails.int_format(gold)
		
		text += "[cell]%s[/cell][cell]%s[/cell][cell]%s[/cell][cell]%s[/cell][cell]%s[/cell][cell]%s[/cell][cell]%s[/cell]" % [player_name, team_string, score_string, lives_string, wave_level_string, total_damage_string, gold_string]

	text += "[/table]\n"

	return text


func _get_your_best_towers_text() -> String:
	var tower_list: Array[Tower] = Utils.get_tower_list()
	
	tower_list = tower_list.filter(
		func(tower: Tower) -> bool:
			var player_match: bool = tower.belongs_to_local_player()

			return player_match
	)
	
	var text: String = _get_tower_stats_text_generic(tower_list)
	
	return text


func _get_overall_best_towers_text() -> String:
	var tower_list: Array[Tower] = Utils.get_tower_list()
	var text: String = _get_tower_stats_text_generic(tower_list)
	
	return text


func _get_tower_stats_text_generic(tower_list: Array[Tower]) -> String:
	var most_damage_tower: Tower = _get_most_total_damage_tower(tower_list)
	var most_damage_tower_name: String = _get_colored_name_for_tower(most_damage_tower)
	var most_damage_value: String = ""
	if most_damage_tower != null:
		var most_damage: float = most_damage_tower.get_total_damage()
		most_damage_value = TowerDetails.int_format(most_damage)

	var tower_with_best_hit: Tower = _get_best_hit_tower(tower_list)
	var best_hit_tower_name: String = _get_colored_name_for_tower(tower_with_best_hit)
	var best_hit_value: String = ""
	if tower_with_best_hit != null:
		var best_hit: float = tower_with_best_hit.get_best_hit()
		best_hit_value = TowerDetails.int_format(best_hit)

	var most_exp_tower: Tower = _get_most_exp_tower(tower_list)
	var most_exp_tower_name: String = _get_colored_name_for_tower(most_exp_tower)
	var most_exp_value: String = ""
	if most_exp_tower != null:
		var most_exp: float = most_exp_tower.get_exp()
		most_exp_value = TowerDetails.int_format(most_exp)

	var most_kills_tower: Tower = _get_most_kills_tower(tower_list)
	var most_kills_tower_name: String = _get_colored_name_for_tower(most_kills_tower)
	var most_kills_value: String = ""
	if most_kills_tower != null:
		var most_kills: float = most_kills_tower.get_kills()
		most_kills_value = TowerDetails.int_format(most_kills)
	
	var text: String = ""
	text += "[table=3]"
	text += "[cell]%s[/cell][cell]%s[/cell][cell]%s[/cell]" % [tr("GAME_STATS_MOST_DAMAGE"), most_damage_tower_name, most_damage_value]
	text += "[cell]%s[/cell][cell]%s[/cell]\t\t[cell]%s[/cell]" % [tr("GAME_STATS_BEST_HIT"), best_hit_tower_name, best_hit_value]
	text += "[cell]%s[/cell][cell]%s[/cell]\t\t[cell]%s[/cell]" % [tr("GAME_STATS_MOST_EXP"), most_exp_tower_name, most_exp_value]
	text += "[cell]%s[/cell][cell]%s[/cell]\t\t[cell]%s[/cell]" % [tr("GAME_STATS_MOST_KILLS"), most_kills_tower_name, most_kills_value]
	text += "[/table]"

	return text


#########################
###      Private      ###
#########################

func _get_most_total_damage_tower(tower_list: Array[Tower]) -> Tower:
	var best_tower: Tower = _get_best_tower_by_criteria(tower_list,
		func(a: Tower, b: Tower) -> bool:
			return a.get_total_damage() > b.get_total_damage()
			)

	return best_tower


func _get_best_hit_tower(tower_list: Array[Tower]) -> Tower:
	var best_tower: Tower = _get_best_tower_by_criteria(tower_list,
		func(a: Tower, b: Tower) -> bool:
			return a.get_best_hit() > b.get_best_hit()
			)

	return best_tower


func _get_most_exp_tower(tower_list: Array[Tower]) -> Tower:
	var best_tower: Tower = _get_best_tower_by_criteria(tower_list,
		func(a: Tower, b: Tower) -> bool:
			return a.get_exp() > b.get_exp()
			)

	return best_tower


func _get_most_kills_tower(tower_list: Array[Tower]) -> Tower:
	var best_tower: Tower = _get_best_tower_by_criteria(tower_list,
		func(a: Tower, b: Tower) -> bool:
			return a.get_kills() > b.get_kills()
			)

	return best_tower


func _get_best_tower_by_criteria(tower_list: Array[Tower], criteria_callable: Callable) -> Tower:
	var best_tower: Tower = null

	for tower in tower_list:
		if best_tower == null:
			best_tower = tower
			continue

		var this_tower_is_better: bool = criteria_callable.call(tower, best_tower)

		if this_tower_is_better:
			best_tower = tower

	return best_tower


func _get_colored_name_for_tower(tower: Tower) -> String:
	if tower == null:
		return ""

	var tower_name: String = tower.get_display_name()
	var element: Element.enm = tower.get_element()
	var element_color: Color = Element.get_color(element)
	var colored_name: String = Utils.get_colored_string(tower_name, element_color)

	return colored_name


#########################
###     Callbacks     ###
#########################

func _on_local_player_selected_builder():
	var local_player: Player = PlayerManager.get_local_player()
	var builder: Builder = local_player.get_builder()
	var builder_id: int = builder.get_id()
	var builder_name: String = BuilderProperties.get_display_name(builder_id)
	var builder_description: String = BuilderProperties.get_description(builder_id)
	
	_builder_label.text = builder_name
	_builder_label.tooltip_text = builder_description
