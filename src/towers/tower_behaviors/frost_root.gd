extends TowerBehavior


func get_tier_stats() -> Dictionary:
	return {
		1: {damage = 25, damage_add = 1},
		2: {damage = 125, damage_add = 5},
		3: {damage = 375, damage_add = 15},
		4: {damage = 750, damage_add = 30},
		5: {damage = 1500, damage_add = 60},
		6: {damage = 2500, damage_add = 100},
	}


func get_ability_info_list() -> Array[AbilityInfo]:
	var damage: String = Utils.format_float(_stats.damage, 2)
	var damage_add: String = Utils.format_float(_stats.damage_add, 2)

	var list: Array[AbilityInfo] = []
	
	var ability: AbilityInfo = AbilityInfo.new()
	ability.name = "Frozen Thorn"
	ability.icon = "res://resources/icons/trinkets/claw_03.tres"
	ability.description_short = "Chance to deal additional spell damage to hit creeps.\n"
	ability.description_full = "15%% chance to deal %s additional spell damage to hit creeps.\n" % damage \
	+ " \n" \
	+ "[color=ORANGE]Level Bonus:[/color]\n" \
	+ "+%s spell damage\n" % damage_add
	list.append(ability)

	return list


func load_triggers(triggers_buff_type: BuffType):
	triggers_buff_type.add_event_on_damage(on_damage)


func on_damage(event: Event):
	if event.is_main_target() && tower.calc_chance(0.15) && !event.get_target().is_immune():
		CombatLog.log_ability(tower, event.get_target(), "Frozen Thorn")

		SFX.sfx_at_unit(SfxPaths.POW, event.get_target())
		tower.do_spell_damage(event.get_target(), _stats.damage + _stats.damage_add * tower.get_level(), tower.calc_spell_crit_no_bonus())
