class_name TowerStashMenu extends PanelContainer


enum FilterType {
	RARITY,
	ELEMENT
}


const BUTTON_SIZE: Vector2 = Vector2(120, 120)
const COLUMN_COUNT: int = 4
const ROW_COUNT: int = 5


@export var _background_grid: GridContainer
@export var _tower_grid: GridContainer
@export var _rarity_filter: RarityFilter
@export var _element_filter: ElementsContainer

var _button_list: Array[TowerButton] = []
var _prev_tower_list: Array = []
var _filter_type: FilterType = FilterType.RARITY


#########################
###     Built-in      ###
#########################

# NOTE: in Build mode, use element filter for tower stash
# because in Build mode all towers are visible from the
# start and filtering by rarity would show too many towers.
# 
# In random modes, it's better to filter by rarity because
# players typically research only 2-3 elements and a small
# amount of towers is randomly distributed after each wave.
func _ready():
	if Globals.get_game_mode() == GameMode.enm.BUILD:
		_filter_type = TowerStashMenu.FilterType.ELEMENT
	else:
		_filter_type = TowerStashMenu.FilterType.RARITY

	_rarity_filter.visible = _filter_type == FilterType.RARITY
	_element_filter.visible = _filter_type == FilterType.ELEMENT
	
	_update_button_visibility()


#########################
###       Public      ###
#########################

func connect_to_local_player(local_player: Player):
	local_player.element_level_changed.connect(_on_element_level_changed)
	_on_element_level_changed()

	var local_team: Team = local_player.get_team()
	local_team.level_changed.connect(_on_wave_level_changed)
	_on_wave_level_changed()

	var tower_stash: TowerStash = local_player.get_tower_stash()
	tower_stash.changed.connect(_on_tower_stash_changed)

	
#########################
###      Private      ###
#########################

func _add_tower_button(tower_id: int, index: int):
	var tower_button: TowerButton = TowerButton.make()
	_button_list.append(tower_button)
	_tower_grid.add_child(tower_button)
	_tower_grid.move_child(tower_button, index)
	tower_button.pressed.connect(_on_tower_button_pressed.bind(tower_id))

	tower_button.set_tower_id(tower_id)
	tower_button.set_locked(true)

	if Globals.get_game_mode() == GameMode.enm.TOTALLY_RANDOM:
		tower_button.set_tier_visible(true)


func _unlock_tower_buttons_if_possible():
	for button in _button_list:
		if !button.disabled:
			continue

		var tower_id: int = button.get_tower_id()
		var local_player: Player = PlayerManager.get_local_player()
		var can_build_tower: bool = TowerProperties.requirements_are_satisfied(tower_id, local_player)

		if can_build_tower:
			button.set_locked(false)


func _update_button_visibility():
	var selected_rarity_list: Array[Rarity.enm] = _rarity_filter.get_filter()
	var selected_element: Element.enm = _element_filter.get_element()
	
	for tower_button in _button_list:
		var tower_id: int = tower_button.get_tower_id()
		var rarity: Rarity.enm = TowerProperties.get_rarity(tower_id)
		var element: Element.enm = TowerProperties.get_element(tower_id)
		
		var filter_match: bool
		match _filter_type:
			FilterType.RARITY: filter_match = selected_rarity_list.has(rarity)
			FilterType.ELEMENT: filter_match = selected_element == element
		
		tower_button.visible = filter_match
		
	var visible_tower_count: int = 0
	for tower_button in _button_list:
		if tower_button.visible:
			visible_tower_count += 1
	
	var current_background_count: int = _background_grid.get_child_count()
	var min_background_count: int = ROW_COUNT * COLUMN_COUNT
	var expected_background_count: int = ceili(visible_tower_count / float(COLUMN_COUNT)) * COLUMN_COUNT
	expected_background_count = max(expected_background_count, min_background_count)
	
	var need_more_background: bool = expected_background_count > current_background_count
	
	if need_more_background:
		while _background_grid.get_child_count() < expected_background_count:
			var background_button: EmptyUnitButton = _make_background_button()
			_background_grid.add_child(background_button)
	
	var background_button_list: Array = _background_grid.get_children()
	for background_button in background_button_list:
		background_button.visible = background_button.get_index() < expected_background_count


func _make_background_button() -> EmptyUnitButton:
	var button: Button = EmptyUnitButton.make()
	button.custom_minimum_size = BUTTON_SIZE
	
	return button

#########################
###     Callbacks     ###
#########################

func _on_tower_stash_changed():
	var local_player: Player = PlayerManager.get_local_player()
	var tower_stash: TowerStash = local_player.get_tower_stash()
	var tower_map: Dictionary = tower_stash.get_towers()
	var tower_list: Array = tower_map.keys()

	tower_list.sort_custom(
		func(a, b) -> bool:
			var rarity_a: Rarity.enm = TowerProperties.get_rarity(a)
			var rarity_b: Rarity.enm = TowerProperties.get_rarity(b)
			var cost_a: int = TowerProperties.get_cost(a)
			var cost_b: int = TowerProperties.get_cost(b)
			
			if rarity_a == rarity_b:
				return cost_a < cost_b
			else:
				return rarity_a < rarity_b
	)

# 	Remove buttons for towers which were removed from stash
	var removed_button_list: Array[TowerButton] = []

	for button in _button_list:
		var tower_id: int = button.get_tower_id()
		var tower_was_removed: bool = !tower_map.has(tower_id)

		if tower_was_removed:
			removed_button_list.append(button)

	for button in removed_button_list:
		_tower_grid.remove_child(button)
		button.queue_free()
		_button_list.erase(button)

# 	Add buttons for towers which were added to stash
#	NOTE: preserve order
	for i in range(0, tower_list.size()):
		var tower_id: int = tower_list[i]
		var tower_was_added: bool = !_prev_tower_list.has(tower_id)
		
		if tower_was_added:
			_add_tower_button(tower_id, i)
	
	_prev_tower_list = tower_list.duplicate()

# 	Update tower counts
	for button in _button_list:
		var tower_id: int = button.get_tower_id()
		var tower_count: int = tower_map[tower_id]
		button.set_count(tower_count)

	_unlock_tower_buttons_if_possible()
	_update_button_visibility()


func _on_close_button_pressed():
	hide()


func _on_tower_button_pressed(tower_id: int):
	EventBus.player_requested_to_build_tower.emit(tower_id)


func _on_rarity_filter_container_filter_changed():
	_update_button_visibility()


func _on_element_filter_element_changed():
	_update_button_visibility()


func _on_element_level_changed():
	_unlock_tower_buttons_if_possible()


func _on_wave_level_changed():
	_unlock_tower_buttons_if_possible()
