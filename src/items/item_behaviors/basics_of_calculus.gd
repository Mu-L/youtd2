extends ItemBehavior


func get_autocast_description() -> String:
	var text: String = ""

	text += "Grants a tower 1 experience.\n"
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+0.04 experience\n"

	return text


func item_init():
	var autocast: Autocast = Autocast.make()
	autocast.title = "Learn"
	autocast.description_long = get_autocast_description()
	autocast.description_short = get_autocast_description()
	autocast.icon = "res://resources/icons/hud/gold.tres"
	autocast.caster_art = ""
	autocast.target_art = "res://src/effects/spell_alim.tscn"
	autocast.num_buffs_before_idle = 0
	autocast.autocast_type = Autocast.Type.AC_TYPE_ALWAYS_BUFF
	autocast.target_self = true
	autocast.cooldown = 15
	autocast.is_extended = false
	autocast.mana_cost = 0
	autocast.buff_type = null
	autocast.buff_target_type = TargetType.new(TargetType.TOWERS)
	autocast.cast_range = 200
	autocast.auto_range = 200
	autocast.handler = on_autocast
	item.set_autocast(autocast)


func on_autocast(event: Event):
	event.get_target().add_exp(1.0 + item.get_carrier().get_level() * 0.04)
