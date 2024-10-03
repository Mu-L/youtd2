extends TowerBehavior


# NOTE: The original script uses time_level_add value to
# change duration of entangle based on tower tier. Don't
# need to do this in youtd2, can directly define different
# durations.


var entangle_bt: BuffType


func get_tier_stats() -> Dictionary:
	return {
		1: {entangle_duration = 1.50, base_entangle_dps = 120},
		2: {entangle_duration = 2.25, base_entangle_dps = 660},
		3: {entangle_duration = 3.00, base_entangle_dps = 1800},
		4: {entangle_duration = 3.75, base_entangle_dps = 4300},
	}


func get_ability_info_list() -> Array[AbilityInfo]:
	var entangle_duration: String = Utils.format_float(_stats.entangle_duration, 2)
	var base_entangle_dps: String = Utils.format_float(_stats.base_entangle_dps, 2)
	var base_entangle_dps_add: String = Utils.format_float(_stats.base_entangle_dps / 20.0, 2)

	var list: Array[AbilityInfo] = []
	
	var ability: AbilityInfo = AbilityInfo.new()
	ability.name = "Entangle"
	ability.icon = "res://resources/icons/plants/branch_01.tres"
	ability.description_short = "Chance to entangle hit creeps. Entangled creeps are immobile and suffer spell damage over time. Cannot entangle air or boss units.\n"
	ability.description_full = "12.5%% chance to entangle hit creeps for %s seconds. Entangled creeps are immobile and suffer %s spell damage per second. Cannot entangle air or boss units.\n" % [entangle_duration, base_entangle_dps] \
	+ " \n" \
	+ "[color=ORANGE]Level Bonus:[/color]\n" \
	+ "+0.2% chance to entangle\n" \
	+ "+%s spell damage per second" % base_entangle_dps_add
	list.append(ability)

	return list


func load_triggers(triggers_buff_type: BuffType):
	triggers_buff_type.add_event_on_damage(on_damage)


func tower_init():
	entangle_bt = CbStun.new("entangle_bt", _stats.entangle_duration, 0.75, false, self)
	entangle_bt.set_buff_icon("res://resources/icons/generic_icons/atomic_slashes.tres")
	entangle_bt.add_periodic_event(entangle_bt_damage, 1.0)


func on_create(_preceding_tower: Tower):
	#	base entangle dps
	tower.user_int = _stats.base_entangle_dps


func on_damage(event: Event):
	if !tower.calc_chance(0.125 + tower.get_level() * 0.002):
		return

	var target: Creep = event.get_target()

	if target.get_size() < CreepSize.enm.BOSS && target.get_size() != CreepSize.enm.AIR:
		CombatLog.log_ability(tower, target, "Entangle")
		
		entangle_bt.apply(tower, target, 0)

#		NOTE: not sure what reorder() does. Tower script
#		works correctly without this.
#		target.reorder()


func entangle_bt_damage(event: Event):
	var buff: Buff = event.get_buff()

	var t = buff.get_caster()
	var c: Creep = buff.get_buffed_unit()
	t.do_spell_damage(c, t.user_int + t.user_int * t.get_level() / 20, t.calc_spell_crit_no_bonus())
