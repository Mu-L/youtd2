extends TowerBehavior


var toxic_bt: BuffType


# NOTE: vapor damage stat is multiplied by 10 and divided by
# 10 later, idk why.
func get_tier_stats() -> Dictionary:
	return {
		1: {vapor_damage = 2000, vapor_damage_add = 80},
		2: {vapor_damage = 6000, vapor_damage_add = 240},
		3: {vapor_damage = 12000, vapor_damage_add = 480},
		4: {vapor_damage = 22000, vapor_damage_add = 880},
	}


func get_ability_info_list_DELETEME() -> Array[AbilityInfo]:
	var vapor_damage: String = Utils.format_float(_stats.vapor_damage / 10, 2)
	var vapor_damage_add: String = Utils.format_float(_stats.vapor_damage_add / 10, 2)

	var list: Array[AbilityInfo] = []
	
	var ability: AbilityInfo = AbilityInfo.new()
	ability.name = "Toxic Vapor"
	ability.icon = "res://resources/icons/mechanical/factory_fumes.tres"
	ability.description_short = "On attack, this tower has a chance to apply a debuff to the main target, dealing spell damage over time.\n"
	ability.description_full = "On attack, this tower has a 30%% chance to apply a debuff to the the main target that deals %s spell damage per second. Lasts for 10 seconds.\n" % vapor_damage \
	+ " \n" \
	+ "[color=ORANGE]Level Bonus:[/color]\n" \
	+ "+%s spell damage per second\n" % vapor_damage_add
	list.append(ability)

	return list


func load_triggers(triggers: BuffType):
	triggers.add_event_on_attack(on_attack)


func load_specials_DELETEME(modifier: Modifier):
	modifier.add_modification(Modification.Type.MOD_DMG_TO_UNDEAD, -0.60, 0.0)
	modifier.add_modification(Modification.Type.MOD_DMG_TO_NATURE, 0.60, 0.02)


func D1000_Toxic_Damage(event: Event):
	var b: Buff = event.get_buff()
	b.get_caster().do_spell_damage(b.get_buffed_unit(), b.get_level() / 10, b.get_caster().calc_spell_crit_no_bonus())


func tower_init():
	toxic_bt = BuffType.new("toxic_bt", 10, 0, false, self)
	toxic_bt.set_buff_icon("res://resources/icons/generic_icons/ghost.tres")
	toxic_bt.add_periodic_event(D1000_Toxic_Damage, 1)
	toxic_bt.set_buff_tooltip("Toxic Vapor\nDeals damage over time.")


func on_attack(event: Event):
	if !tower.calc_chance(0.3):
		return

	CombatLog.log_ability(tower, event.get_target(), "Toxic Vapor")

	toxic_bt.apply(tower, event.get_target(), int(tower.get_level() * _stats.vapor_damage_add + _stats.vapor_damage))
