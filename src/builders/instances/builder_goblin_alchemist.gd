extends Builder


func apply_to_player(player: Player):
	player.modify_income_rate(0.15)
	player.modify_interest_rate(0.02)


func _get_tower_modifier() -> Modifier:
	var mod: Modifier = Modifier.new()
	mod.add_modification(ModificationType.enm.MOD_BOUNTY_RECEIVED, 0.20, 0.0)
	mod.add_modification(ModificationType.enm.MOD_ITEM_QUALITY_ON_KILL, 0.35, 0.02)

	mod.add_modification(ModificationType.enm.MOD_BUFF_DURATION, -0.35, 0.0)
	mod.add_modification(ModificationType.enm.MOD_DEBUFF_DURATION, 0.25, 0.0)
	mod.add_modification(ModificationType.enm.MOD_ATTACKSPEED, -0.15, 0.0)

	return mod
