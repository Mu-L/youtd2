class_name ActionBuildTower


static func make(tower_id_arg: int, position_arg: Vector2) -> Action:
	var action: Action = Action.new({
		Action.Field.TYPE: Action.Type.BUILD_TOWER,
		Action.Field.TOWER_ID: tower_id_arg,
		Action.Field.POSITION: position_arg,
		})

	return action


# TODO: build tower action looks very bad with the delay.
# Need to add a temporary animation like a cloud of dust,
# while the tower "builds".
static func execute(action: Dictionary, player: Player, build_space: BuildSpace):
	var tower_id: int = action[Action.Field.TOWER_ID]
	var mouse_pos: Vector2 = action[Action.Field.POSITION]

	var verify_ok: bool = ActionBuildTower.verify(player, build_space, tower_id, mouse_pos)

	if !verify_ok:
		return

	player.add_food_for_tower(tower_id)
	
	var build_cost: float = TowerProperties.get_cost(tower_id)
	player.spend_gold(build_cost)
	
	var tomes_cost: int = TowerProperties.get_tome_cost(tower_id)
	player.spend_tomes(tomes_cost)

	player.disable_rolling()

	var tower_stash: TowerStash = player.get_tower_stash()
	tower_stash.spend_tower(tower_id)

	var new_tower: Tower = Tower.make(tower_id, player)

#	NOTE: need to add tile height to position because towers
#	are built at ground floor
	var build_position_canvas: Vector2 = VectorUtils.snap_canvas_pos_to_buildable_pos(mouse_pos)
	build_position_canvas.y += Constants.TILE_SIZE.y
	var build_position: Vector2 = VectorUtils.canvas_to_wc3_2d(build_position_canvas)
	new_tower.set_position_wc3_2d(build_position)
	
	Utils.add_object_to_world(new_tower)

	build_space.set_occupied_by_tower(new_tower, true)

	EventBus.built_a_tower.emit()


static func verify(player: Player, build_space: BuildSpace, tower_id: int, mouse_pos: Vector2) -> bool:
	var enough_resources: bool = BuildTower.enough_resources_for_tower(tower_id, player)

	if !enough_resources:
		BuildTower.add_error_about_building_tower(tower_id, player)

		return false

	var tower_stash: TowerStash = player.get_tower_stash()
	var tower_exists_in_stash: bool = tower_stash.has_tower(tower_id)
	if !tower_exists_in_stash:
		Messages.add_error(player, "You don't have this tower")

		return false

	var can_build: bool = build_space.can_build_at_pos(mouse_pos)

	if !can_build:
		Messages.add_error(player, "Can't build here")

		return false

	return true
