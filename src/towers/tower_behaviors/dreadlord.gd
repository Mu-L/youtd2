extends TowerBehavior


# NOTE: original script sets level of buff to 1 for some
# reason, so the effect doesn't scale with tower level.
# Fixed it.

# NOTE: original script uses "frenzy" spell as a visual
# effect. Didn't implement that. Can implement using an
# Effect.

var awakening_bt: BuffType
var multiboard: MultiboardValues


func get_ability_info_list() -> Array[AbilityInfo]:
	var list: Array[AbilityInfo] = []
	
	var dreadlord_slash: AbilityInfo = AbilityInfo.new()
	dreadlord_slash.name = "Dreadlord Slash"
	dreadlord_slash.icon = "res://resources/icons/daggers/dagger_07.tres"
	dreadlord_slash.description_short = "Deals additional spell damage to hit creeps at the cost of some mana.\n"
	dreadlord_slash.description_full = "Deals additional spell damage to hit creeps. The damage is equal to tower's max mana and costs 80 mana on each attack.\n" \
	+ " \n" \
	+ "[color=ORANGE]Level Bonus:[/color]\n" \
	+ "+4% spell damage\n"
	list.append(dreadlord_slash)

	var bloodsucker: AbilityInfo = AbilityInfo.new()
	bloodsucker.name = "Bloodsucker"
	bloodsucker.icon = "res://resources/icons/gems/gem_07.tres"
	bloodsucker.description_short = "Dreadlord gains extra power with every kill.\n"
	bloodsucker.description_full = "The Dreadlord is hungry. For every kill he gains 0.5% attack speed and 10 maximum mana. The mana bonus caps at 2000. Both bonuses are permanent.\n"
	list.append(bloodsucker)

	return list


func load_triggers(triggers: BuffType):
	triggers.add_event_on_damage(on_damage)
	triggers.add_event_on_kill(on_kill)


func load_specials(modifier: Modifier):
	modifier.add_modification(Modification.Type.MOD_MANA_PERC, 0.0, 0.05)
	modifier.add_modification(Modification.Type.MOD_MANA_REGEN_PERC, 0.0, 0.05)


func tower_init():
	awakening_bt = BuffType.new("awakening_bt", 10, 0, true, self)
	var mod: Modifier = Modifier.new()
	mod.add_modification(Modification.Type.MOD_ATTACKSPEED, 0.5, 0.02)
	mod.add_modification(Modification.Type.MOD_MANA_REGEN, 20, 0.8)
	awakening_bt.set_buff_modifier(mod)
	awakening_bt.set_buff_icon("res://resources/icons/generic_icons/burning_dot.tres")
	awakening_bt.set_buff_tooltip("Dreadlord's Awakening\nIncreases attack speed and mana regen.")

	multiboard = MultiboardValues.new(2)
	multiboard.set_key(0, "Attack speed Bonus")
	multiboard.set_key(1, "Mana Bonus")

func create_autocasts() -> Array[Autocast]:
	var autocast: Autocast = Autocast.make()

	autocast.title = "Dreadlord's Awakening"
	autocast.icon = "res://resources/icons/undead/skull_03.tres"
	autocast.description_short = "When activated, Dreadlord empowers himself with darkness.\n"
	autocast.description = "When activated, Dreadlord empowers himself with darkness for 10 seconds, increasing own attack speed by 50% and mana regeneration by 20 per second.\n" \
	+ " \n" \
	+ "[color=ORANGE]Level Bonus:[/color]\n" \
	+ "+2% attack speed\n" \
	+ "+0.8 mana per second\n"
	autocast.caster_art = ""
	autocast.target_art = ""
	autocast.autocast_type = Autocast.Type.AC_TYPE_OFFENSIVE_IMMEDIATE
	autocast.num_buffs_before_idle = 0
	autocast.cast_range = 0
	autocast.auto_range = 900
	autocast.cooldown = 80
	autocast.mana_cost = 0
	autocast.target_self = true
	autocast.is_extended = false
	autocast.buff_type = null
	autocast.buff_target_type = null
	autocast.handler = on_autocast

	return [autocast]


func on_damage(event: Event):
	var creep: Unit = event.get_target()
	var damage: float = (1 + 0.04 * tower.get_level()) * tower.get_overall_mana()
	var mana: float = tower.get_mana()

	if mana >= 80:
		tower.do_spell_damage(creep, damage, tower.calc_spell_crit_no_bonus())
		tower.subtract_mana(80, 0)
		Effect.create_scaled("res://src/effects/devour.tscn", Vector3(creep.get_x(), creep.get_y(), 30), 0, 2)


func on_kill(_event: Event):
	tower.modify_property(Modification.Type.MOD_ATTACKSPEED, 0.005)
	tower.user_real2 += 0.005

	if tower.user_real <= 2:
		tower.user_real += 0.01
		tower.modify_property(Modification.Type.MOD_MANA, 10)


func on_tower_details() -> MultiboardValues:
	var attack_speed_bonus: String = Utils.format_percent(tower.user_real2, 1)
	var mana_bonus: String = str(int(tower.user_real * 1000))
	multiboard.set_value(0, attack_speed_bonus)
	multiboard.set_value(1, mana_bonus)
	
	return multiboard


func on_autocast(_event: Event):
	awakening_bt.apply(tower, tower, tower.get_level())
