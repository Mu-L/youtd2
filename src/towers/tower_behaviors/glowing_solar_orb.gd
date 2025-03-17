extends TowerBehavior


var armor_bt: BuffType


func get_tier_stats() -> Dictionary:
	return {
		1: {splash_125_damage = 0.45, splash_225_damage = 0.15, armor_decrease = 2},
		2: {splash_125_damage = 0.45, splash_225_damage = 0.20, armor_decrease = 3},
		3: {splash_125_damage = 0.50, splash_225_damage = 0.25, armor_decrease = 5},
		4: {splash_125_damage = 0.50, splash_225_damage = 0.30, armor_decrease = 7},
		5: {splash_125_damage = 0.55, splash_225_damage = 0.35, armor_decrease = 10},
	}


func get_ability_info_list_DELETEME() -> Array[AbilityInfo]:
	var armor_decrease: String = Utils.format_float(_stats.armor_decrease, 2)

	var list: Array[AbilityInfo] = []
	
	var ability: AbilityInfo = AbilityInfo.new()
	ability.name = "Afterglow"
	ability.icon = "res://resources/icons/gloves/heal.tres"
	ability.description_short = "Chance to melt armor of hit creeps.\n"
	ability.description_full = "5%% chance to reduce armor of hit creeps by %s for 5 seconds. This chance is doubled for bosses.\n" % armor_decrease \
	+ " \n" \
	+ "[color=ORANGE]Level Bonus:[/color]\n" \
	+ "+0.6% chance\n" \
	+ "+0.25 seconds duration\n"
	list.append(ability)

	return list


func load_triggers(triggers_buff_type: BuffType):
	triggers_buff_type.add_event_on_damage(on_damage)


func load_specials_DELETEME(modifier: Modifier):
	var splash_map: Dictionary = {
		125: _stats.splash_125_damage,
		225: _stats.splash_225_damage,
	}
	tower.set_attack_style_splash_DELETEME(splash_map)

	modifier.add_modification(Modification.Type.MOD_DMG_TO_UNDEAD, 0.15, 0.0)


func tower_init():
	var armor: Modifier = Modifier.new()
	armor.add_modification(Modification.Type.MOD_ARMOR, 0, -1)
	armor_bt = BuffType.new("armor_bt", 0, 0, false, self)
	armor_bt.set_buff_icon("res://resources/icons/generic_icons/semi_closed_eye.tres")
	armor_bt.set_buff_modifier(armor)

	armor_bt.set_buff_tooltip("Afterglow\nReduces armor.")


func on_damage(event: Event):
	var lvl: int = tower.get_level()
	var creep: Unit = event.get_target()
	var size_factor: float = 1.0

	if creep.get_size() == CreepSize.enm.BOSS:
		size_factor = 2.0

	if tower.calc_chance((0.05 + lvl * 0.006) * size_factor):
		CombatLog.log_ability(tower, creep, "Afterglow")
		
		armor_bt.apply_custom_timed(tower, creep, _stats.armor_decrease, 5 + lvl * 0.25)
