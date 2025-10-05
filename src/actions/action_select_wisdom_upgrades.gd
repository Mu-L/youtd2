class_name ActionSelectWisdomUpgrades



# NOTE: wisdom_upgrades must be a map of
# {upgrade_id => boolean}
# where boolean is TRUE if upgrade_id is enabled
static func make(wisdom_upgrades: Dictionary) -> Action:
	var action: Action = Action.new({
		Action.Field.TYPE: Action.Type.SELECT_WISDOM_UPGRADES,
		Action.Field.WISDOM_UPGRADES: wisdom_upgrades,
		})

	return action


static func execute(action: Dictionary, player: Player):
	var wisdom_upgrades: Dictionary = action[Action.Field.WISDOM_UPGRADES]

	var builder_wisdom_multiplier: float = player.get_builder_wisdom_multiplier()
	var upgrades_wisdom_multiplier_bonus: float = Utils.get_wisdom_multiplier_bonus_from_upgrades(wisdom_upgrades)
	
	var wisdom_multiplier = builder_wisdom_multiplier + upgrades_wisdom_multiplier_bonus
	
	var wisdom_modifier: Modifier = ActionSelectWisdomUpgrades.generate_wisdom_upgrades_modifier(wisdom_upgrades, wisdom_multiplier)
	player.set_wisdom_modifier(wisdom_modifier)

	if wisdom_upgrades[WisdomUpgradeProperties.Id.ELEMENT_MASTERY]:
		var tomes_bonus: int = floori(40 * wisdom_multiplier)
		player.add_tomes(tomes_bonus)

	if wisdom_upgrades[WisdomUpgradeProperties.Id.MASTERY_OF_LOGISTICS]:
		var food_cap_bonus: int = floori(16 * wisdom_multiplier)
		player.modify_food_cap(food_cap_bonus)
		
	if wisdom_upgrades[WisdomUpgradeProperties.Id.BOND_OF_UNITY]:
		var lives_bonus: float = 20 * wisdom_multiplier
		player.get_team().modify_lives(lives_bonus)
	
	if wisdom_upgrades[WisdomUpgradeProperties.Id.FOUNDATION_OF_KNOWLEDGE]:
		var tower_bonus_exp: float = 30 * wisdom_multiplier
		player.set_tower_exp_bonus(tower_bonus_exp)
	
	if wisdom_upgrades[WisdomUpgradeProperties.Id.ADVANCED_OPTICS]:
		var bonus_attack_range: float = 25 * wisdom_multiplier
		player.set_attack_range_bonus(bonus_attack_range)

	# Unaffected by wisdom_multiplier
	if wisdom_upgrades[WisdomUpgradeProperties.Id.ELEMENTAL_OVERLOAD]:
		var max_element_level_bonus: int = 2
		player._max_element_level_bonus += max_element_level_bonus
	
	# Unaffected by wisdom_multiplier
	if wisdom_upgrades[WisdomUpgradeProperties.Id.PINNACLE_OF_POWER]:
		var max_tower_level_bonus: int = 2
		player._max_tower_level_bonus += max_tower_level_bonus


static func generate_wisdom_upgrades_modifier(wisdom_upgrades: Dictionary, wisdom_multiplier: float) -> Modifier:
	var modifier: Modifier = Modifier.new()

	var upgrade_to_mod_value_map: Dictionary = {
		WisdomUpgradeProperties.Id.ADVANCED_FORTUNE: {
			ModificationType.enm.MOD_TRIGGER_CHANCES: 0.10,
		},
		WisdomUpgradeProperties.Id.SWIFTNESS_MASTERY: {
			ModificationType.enm.MOD_ATTACKSPEED: 0.07,
		},
		WisdomUpgradeProperties.Id.COMBAT_MASTERY: {
			ModificationType.enm.MOD_DAMAGE_BASE_PERC: 0.08,
		},
		WisdomUpgradeProperties.Id.MASTERY_OF_PAIN: {
			ModificationType.enm.MOD_ATK_CRIT_CHANCE: 0.04,
			ModificationType.enm.MOD_SPELL_CRIT_CHANCE: 0.04,
		},
		WisdomUpgradeProperties.Id.ADVANCED_SORCERY: {
			ModificationType.enm.MOD_SPELL_DAMAGE_DEALT: 0.10,
		},
		WisdomUpgradeProperties.Id.MASTERY_OF_MAGIC: {
			ModificationType.enm.MOD_MANA_PERC: 0.20,
			ModificationType.enm.MOD_MANA_REGEN_PERC: 0.20,
		},
		WisdomUpgradeProperties.Id.LOOT_MASTERY: {
			ModificationType.enm.MOD_ITEM_CHANCE_ON_KILL: 0.12,
		},
		WisdomUpgradeProperties.Id.ADVANCED_WISDOM: {
			ModificationType.enm.MOD_EXP_RECEIVED: 0.20,
		},
		WisdomUpgradeProperties.Id.PILLAGE_MASTERY: {
			ModificationType.enm.MOD_BOUNTY_RECEIVED: 0.16,
		},
		WisdomUpgradeProperties.Id.FORTIFIED_WILL: {
			ModificationType.enm.MOD_DEBUFF_DURATION: -0.09,
		},
		WisdomUpgradeProperties.Id.INNER_FOCUS: {
			ModificationType.enm.MOD_BUFF_DURATION: 0.065,
		},
		WisdomUpgradeProperties.Id.DEADLY_STRIKES: {
			ModificationType.enm.MOD_ATK_CRIT_DAMAGE: 0.175,
			ModificationType.enm.MOD_SPELL_CRIT_DAMAGE: 0.175,
		},
		WisdomUpgradeProperties.Id.FORTUNES_FAVOR: {
			ModificationType.enm.MOD_ITEM_QUALITY_ON_KILL: 0.065,
		},
		WisdomUpgradeProperties.Id.CHALLENGE_CONQUEROR: {
			ModificationType.enm.MOD_DMG_TO_CHALLENGE: 0.1,
		},
		WisdomUpgradeProperties.Id.MASTER_OF_DESTRUCTION: {
			ModificationType.enm.MOD_DMG_TOTAL_MULTIPLIER: 0.025,
		},
	}
	
	for upgrade_id in wisdom_upgrades.keys():
		var upgrade_is_enabled: bool = wisdom_upgrades[upgrade_id] == true

		if !upgrade_is_enabled:
			continue

		var mod_values: Dictionary = upgrade_to_mod_value_map.get(upgrade_id, {})

		for mod_type in mod_values.keys():
			var mod_value: float = mod_values[mod_type]

			mod_value *= wisdom_multiplier

			modifier.add_modification(mod_type, mod_value, 0)

	return modifier
