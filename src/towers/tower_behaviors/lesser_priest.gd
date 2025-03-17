extends TowerBehavior


func get_tier_stats() -> Dictionary:
	return {
		1: {smite_damage = 10, smite_damage_add = 18, armor_reduce = -0.6, armor_reduce_boss = -0.2},
		2: {smite_damage = 35, smite_damage_add = 63, armor_reduce = -0.9, armor_reduce_boss = -0.3},
		3: {smite_damage = 90, smite_damage_add = 162, armor_reduce = -1.2, armor_reduce_boss = -0.4},
		4: {smite_damage = 190, smite_damage_add = 342, armor_reduce = -1.5, armor_reduce_boss = -0.5},
		5: {smite_damage = 380, smite_damage_add = 648, armor_reduce = -1.8, armor_reduce_boss = -0.6},
	}


func load_triggers(triggers_buff_type: BuffType):
	triggers_buff_type.add_event_on_damage(on_damage)


func on_damage(event: Event):
	if !tower.calc_chance(0.05 + tower.get_level() * 0.02):
		return

	var creep: Unit = event.get_target()
	var level: int = tower.get_level()

	CombatLog.log_ability(tower, creep, "Smite")

	tower.do_spell_damage(creep, _stats.smite_damage + (level * _stats.smite_damage_add), tower.calc_spell_crit_no_bonus())
	Effect.create_simple_at_unit("res://src/effects/holy_bolt.tscn", creep)

	if level == 25:
		if creep.get_size() < CreepSize.enm.BOSS:
			creep.modify_property(Modification.Type.MOD_ARMOR, _stats.armor_reduce)
		else:
			creep.modify_property(Modification.Type.MOD_ARMOR, _stats.armor_reduce_boss)
