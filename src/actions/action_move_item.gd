class_name ActionMoveItem


static func make(item_uid_arg: int, src_item_container_uid_arg: int, dest_item_container_uid_arg: int, clicked_index: int = -1) -> Action:
	var action: Action = Action.new({
		Action.Field.TYPE: Action.Type.MOVE_ITEM,
		Action.Field.UID: item_uid_arg,
		Action.Field.SRC_ITEM_CONTAINER_UID: src_item_container_uid_arg,
		Action.Field.DEST_ITEM_CONTAINER_UID: dest_item_container_uid_arg,
		Action.Field.CLICKED_INDEX: clicked_index,
		})

	return action


static func execute(action: Dictionary, player: Player):
	var item_uid: int = action[Action.Field.UID]
	var src_item_container_uid: int = action[Action.Field.SRC_ITEM_CONTAINER_UID]
	var dest_item_container_uid: int = action[Action.Field.DEST_ITEM_CONTAINER_UID]
	var clicked_index: int = action[Action.Field.CLICKED_INDEX]

	var item: Item = GroupManager.get_by_uid("items", item_uid)
	var src_item_container: ItemContainer = GroupManager.get_by_uid("item_containers", src_item_container_uid)
	var dest_item_container: ItemContainer = GroupManager.get_by_uid("item_containers", dest_item_container_uid)

	var verify_ok: bool = ActionMoveItem.verify(player, item, src_item_container, dest_item_container, clicked_index)
	if !verify_ok:
		return

	src_item_container.remove_item(item)
	dest_item_container.add_item(item, clicked_index)


# Checks if currently moved item can't be placed into
# container because container belongs to tower and item is
# consumable. Also adds an error messages if needed.
# Returns true if can move.
static func verify(player: Player, item: Item, src_container: ItemContainer, dest_container: ItemContainer, clicked_index: int) -> bool:
	if item == null || src_container == null || dest_container == null:
		Utils.add_ui_error(player, Utils.tr("MESSAGE_FAIL_MOVE_ITEM"))
		
		return false

	var item_player_match: bool = item.get_player() == player
	if !item_player_match:
		Utils.add_ui_error(player, Utils.tr("MESSAGE_DONT_OWN_ITEM"))
		
		return false

	var container_player_match: bool = src_container.get_player() == player && dest_container.get_player() == player
	if !container_player_match:
		Utils.add_ui_error(player, Utils.tr("MESSAGE_DONT_OWN_TOWER"))
		
		return false

	var item_exists_in_src_container: bool = src_container.has(item)
	if !item_exists_in_src_container:
		Utils.add_ui_error(player, Utils.tr("MESSAGE_FAIL_MOVE_ITEM"))
		
		return false

	var capacity: int = dest_container.get_capacity()

	if clicked_index != -1 && clicked_index >= capacity:
		Utils.add_ui_error(player, Utils.tr("MESSAGE_INVALID_SLOT_INDEX"))

		return false

#	NOTE: need to call can_add_item() instead of
#	have_item_space() to handle case of adding oil to tower
	var dest_has_space: bool = dest_container.can_add_item(item)

	if !dest_has_space:
		Utils.add_ui_error(player, Utils.tr("MESSAGE_NO_SPACE_FOR_ITEM"))

		return false

	var trying_to_move_consumable_to_tower: bool = item.is_consumable() && dest_container is TowerItemContainer

	if trying_to_move_consumable_to_tower:
		Utils.add_ui_error(player, Utils.tr("MESSAGE_CANT_EQUIP_CONSUMABLES"))
		
		return false

	return true
