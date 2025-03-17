extends TowerBehavior


func get_tier_stats() -> Dictionary:
	return {
		1: {target_count_max = 2, dmg_to_undead_add = 0.004, dmg_to_magic_add = 0.004},
		2: {target_count_max = 2, dmg_to_undead_add = 0.004, dmg_to_magic_add = 0.005},
		3: {target_count_max = 3, dmg_to_undead_add = 0.005, dmg_to_magic_add = 0.006},
		4: {target_count_max = 3, dmg_to_undead_add = 0.005, dmg_to_magic_add = 0.007},
		5: {target_count_max = 4, dmg_to_undead_add = 0.006, dmg_to_magic_add = 0.008},
	}


func load_specials_DELETEME(modifier: Modifier):
	tower.set_target_count_DELETEME(_stats.target_count_max)

	modifier.add_modification(Modification.Type.MOD_DMG_TO_UNDEAD, -0.20, _stats.dmg_to_undead_add)
	modifier.add_modification(Modification.Type.MOD_DMG_TO_MAGIC, 0.20, _stats.dmg_to_magic_add)
