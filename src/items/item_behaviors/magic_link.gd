extends ItemBehavior


func get_autocast_description() -> String:
	var text: String = ""

	text += "Transfers a flat 30 experience from this tower to another one.\n"

	return text


func item_init():
	var autocast: Autocast = Autocast.make()
	autocast.title = "Transfer Experience"
	autocast.description_long = get_autocast_description()
	autocast.description_short = get_autocast_description()
	autocast.icon = "res://resources/icons/hud/gold.tres"
	autocast.caster_art = "res://src/effects/dispel_magic_target.tscn"
	autocast.target_art = ""
	autocast.num_buffs_before_idle = 1
	autocast.autocast_type = Autocast.Type.AC_TYPE_ALWAYS_BUFF
	autocast.target_self = false
	autocast.cooldown = 60
	autocast.is_extended = true
	autocast.mana_cost = 0
	autocast.buff_type = null
	autocast.buff_target_type = TargetType.new(TargetType.TOWERS)
	autocast.cast_range = 1200
	autocast.auto_range = 1200
	autocast.handler = on_autocast
	item.set_autocast(autocast)


func on_autocast(event: Event):
	event.get_target().add_exp_flat(item.get_carrier().remove_exp_flat(30))
