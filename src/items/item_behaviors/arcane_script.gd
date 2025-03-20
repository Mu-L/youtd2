extends ItemBehavior


func load_triggers(triggers: BuffType):
	triggers.add_event_on_spell_casted(on_spell_cast)


func on_spell_cast(event: Event):
	var cd: float = event.get_autocast_type().get_cooldown()

	if !event.get_autocast_type().is_item_autocast():
		item.get_carrier().add_exp(0.2 * cd)
		item.get_carrier().get_player().give_gold(0.5 * cd, item.get_carrier(), false, true)
