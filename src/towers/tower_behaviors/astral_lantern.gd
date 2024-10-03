extends TowerBehavior


# NOTE: [ORIGINAL_GAME_DEVIATION] Commented out sections
# relevant to invisibility because invisible waves are not
# implemented.


# func get_tier_stats() -> Dictionary:
# 	return {
# 		1: {damage_base = 0.15, damage_add = 0.006},
# 		2: {damage_base = 0.20, damage_add = 0.008},
# 		3: {damage_base = 0.25, damage_add = 0.010},
# 		4: {damage_base = 0.30, damage_add = 0.012},
# 	}


# func get_ability_description() -> String:
# 	var damage_base: String = Utils.format_percent(_stats.damage_base, 2)
# 	var damage_add: String = Utils.format_percent(_stats.damage_add, 2)

# 	var text: String = ""

# 	text += "[color=GOLD]Light in the Dark[/color]\n"
# 	text += "Deals %s additional damage to invisible creeps.\n" % damage_base
# 	text += " \n"
# 	text += "[color=ORANGE]Level Bonus:[/color]\n"
# 	text += "+%s damage" % damage_add

# 	return text


# func get_ability_description_short() -> String:
# 	var text: String = ""

# 	text += "[color=GOLD]Light in the Dark[/color]\n"
# 	text += "Deals additional damage to invisible creeps."

# 	return text


# func load_triggers(triggers_buff_type: BuffType):
# 	triggers_buff_type.add_event_on_damage(on_damage)


# func on_damage(event: Event):
# 	if event.get_target().is_invisible():
# 		event.damage = event.damage * (_stats.damage_base + tower.get_level() * _stats.damage_add)
