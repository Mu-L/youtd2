extends ItemBehavior


var aura_bt: BuffType


func load_triggers(triggers: BuffType):
	triggers.add_event_on_attack(on_attack)
	triggers.add_event_on_kill(on_kill)


func item_init():
	aura_bt = BuffType.create_aura_effect_type("aura_bt", true, self)
	aura_bt.set_buff_icon("res://resources/icons/generic_icons/rolling_energy.tres")
	aura_bt.set_buff_tooltip(tr("2UJE"))
	var mod: Modifier = Modifier.new() 
	mod.add_modification(ModificationType.enm.MOD_MANA_REGEN_PERC, 0.075, 0.0) 
	aura_bt.set_buff_modifier(mod)


func on_attack(_event: Event):
	item.user_int = item.user_int + 1

	if item.user_int == 3:
		item.get_carrier().add_mana_perc(0.01)
		item.user_int = 0


func on_pickup():
	item.user_int = 0


func on_kill(_event: Event):
	var tower: Tower = item.get_carrier()
	Effect.create_scaled("res://src/effects/replenish_mana.tscn", tower.get_position_wc3(), 0.0, 1)

