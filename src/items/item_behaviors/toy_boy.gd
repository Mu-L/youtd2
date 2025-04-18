extends ItemBehavior


var playtime_bt: BuffType


func load_triggers(triggers: BuffType):
	triggers.add_periodic_event(periodic, 10)


func item_init():
	playtime_bt = BuffType.new("playtime_bt", 2.0, 0, false, self)
	playtime_bt.set_buff_icon("res://resources/icons/generic_icons/pokecog.tres")
	playtime_bt.set_buff_tooltip(tr("QYT7"))
	var mod: Modifier = Modifier.new()
	mod.add_modification(ModificationType.enm.MOD_ATTACKSPEED, -0.5, 0.0)
	playtime_bt.set_buff_modifier(mod)


func periodic(_event: Event):
	CombatLog.log_item_ability(item, null, "Play with me!")
	playtime_bt.apply(item.get_carrier(), item.get_carrier(), 1)
