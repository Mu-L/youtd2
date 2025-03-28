extends ItemBehavior


# NOTE: original script saves item reference in buff's
# user_int. We don't need to save it because ItemBehavior
# has access to item reference.

var backpack_bt: BuffType
var multiboard: MultiboardValues


func on_autocast(_event: Event):
	var tower: Unit = item.get_carrier()
	backpack_bt.apply_only_timed(tower, tower, 1000)


func item_init():
	backpack_bt = BuffType.new("backpack_bt", 0, 0, true, self)
	backpack_bt.set_buff_icon("res://resources/icons/generic_icons/pokecog.tres")
	backpack_bt.set_buff_tooltip(tr("XNNT"))
	backpack_bt.add_event_on_kill(backpack_bt_on_kill)
	
	multiboard = MultiboardValues.new(1)
	var items_backpacked_label: String = tr("DRQK")
	multiboard.set_key(0, items_backpacked_label)


# NOTE: backpackKill() in original script
func backpack_bt_on_kill(event: Event):
	var B: Buff = event.get_buff()
	var tower: Tower = B.get_buffed_unit()
	var creep: Creep = event.get_target()

	creep.drop_item(tower, false)
	tower.get_player().display_small_floating_text("Backpacked!", tower, Color8(255, 165, 0), 30)
	item.user_int = item.user_int + 1
	B.remove_buff()


func on_create():
#	Total items found
	item.user_int = 0


func on_tower_details() -> MultiboardValues:
	var items_backpacked_text: String = Utils.format_float(item.user_int, 0)
	multiboard.set_value(0, items_backpacked_text)

	return multiboard
