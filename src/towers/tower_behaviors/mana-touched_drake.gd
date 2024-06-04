extends TowerBehavior


var aura_bt: BuffType

const AURA_RANGE: int = 200


func get_tier_stats() -> Dictionary:
	return {
		1: {mana_regen_add = 1.0, aura_mana_cost = 7, aura_power = 50, aura_power_add = 4, aura_level = 200, damage_mana_multiplier = 8.0},
		2: {mana_regen_add = 2.4, aura_mana_cost = 14, aura_power = 75, aura_power_add = 6, aura_level = 300, damage_mana_multiplier = 9.5},
		3: {mana_regen_add = 4.2, aura_mana_cost = 24, aura_power = 100, aura_power_add = 8, aura_level = 400, damage_mana_multiplier = 11.0},
		4: {mana_regen_add = 6.4, aura_mana_cost = 35, aura_power = 125, aura_power_add = 10, aura_level = 500, damage_mana_multiplier = 12.5},
	}


func get_ability_info_list() -> Array[AbilityInfo]:
	var damage_mana_multiplier: String = Utils.format_float(_stats.damage_mana_multiplier, 2)
	var elemental_attack_type_string: String = AttackType.convert_to_colored_string(AttackType.enm.ELEMENTAL)

	var list: Array[AbilityInfo] = []
	
	var unstable_energies: AbilityInfo = AbilityInfo.new()
	unstable_energies.name = "Unstable Energies"
	unstable_energies.icon = "res://resources/icons/electricity/electricity_yellow.tres"
	unstable_energies.description_short = "Whenever this tower hits a creep, it has a chance to release a powerful energy blast at the cost of some mana, dealing %s damage.\n" % elemental_attack_type_string
	unstable_energies.description_full = "Whenever this tower hits a creep, it has a 28%% chance to release a powerful energy blast, dealing [color=GOLD][current mana x %s][/color] %s damage to the target, but consuming 75%% of its own current mana.\n" % [damage_mana_multiplier, elemental_attack_type_string] \
	+ " \n" \
	+ "[color=ORANGE]Level Bonus:[/color]\n" \
	+ "+0.48% chance\n" \
	+ "-1% current mana consumed\n"
	list.append(unstable_energies)

	return list


func load_triggers(triggers: BuffType):
	triggers.add_event_on_damage(on_damage)


func load_specials(modifier: Modifier):
	modifier.add_modification(Modification.Type.MOD_MANA_REGEN, 0, _stats.mana_regen_add)


func drake_aura_manaburn(event: Event):
	var b: Buff = event.get_buff()
	var buffed_tower: Unit = b.get_buffed_unit()
	var target: Unit = event.get_target()
	var caster: Unit = b.get_caster()
	var mana_drained: float
	var speed: float = buffed_tower.get_base_attack_speed() * 800 / buffed_tower.get_range()

	if target.get_mana() > 0 && caster.subtract_mana(caster.user_real * speed, false) > 0:
		mana_drained = target.subtract_mana(b.get_level() / 100.0 * speed, true)
		buffed_tower.do_spell_damage(target, mana_drained * b.get_power(), buffed_tower.calc_spell_crit_no_bonus())
		SFX.sfx_at_unit("DeathandDecayDamage.dml", target)


func tower_init():
	aura_bt = BuffType.create_aura_effect_type("aura_bt", true, self)
	aura_bt.set_buff_icon("res://resources/icons/generic_icons/moebius_trefoil.tres")
	aura_bt.add_event_on_attack(drake_aura_manaburn)
	aura_bt.set_buff_tooltip("Mana Distortion Field\nMana burns creeps on attack.")


func get_aura_types() -> Array[AuraType]:
	var aura: AuraType = AuraType.new()

	var buffed_tower_mana_burned: String = Utils.format_float(_stats.aura_level / 100.0, 2)
	var aura_mana_cost: String = Utils.format_float(_stats.aura_mana_cost, 2)
	var damage_per_mana_point: String = Utils.format_float(_stats.aura_power, 2)
	var damage_per_mana_point_add: String = Utils.format_float(_stats.aura_power_add, 2)

	aura.name = "Mana Distortion Field"
	aura.icon = "res://resources/icons/magic/magic_stone.tres"
	aura.description_short = "Whenever a nearby tower attacks, it burns mana from the main target and deals spell damage to it. The mana burn costs the Drake some mana.\n"
	aura.description_full = "Whenever a tower in %d range attacks, it burn %s mana from the main target. The mana burn costs the Drake %s mana. The mana burned and spent is attack speed and range adjusted and the buffed tower deals %s spell damage per mana point burned.\n" % [AURA_RANGE, buffed_tower_mana_burned, aura_mana_cost, damage_per_mana_point] \
	+ " \n" \
	+ "[color=ORANGE]Level Bonus:[/color]\n" \
	+ "+%s spell damage per mana point burned\n" % damage_per_mana_point_add

	aura.aura_range = AURA_RANGE
	aura.target_type = TargetType.new(TargetType.TOWERS)
	aura.target_self = false
	aura.level = _stats.aura_level
	aura.level_add = 0
	aura.power = _stats.aura_power
	aura.power_add = _stats.aura_power_add
	aura.aura_effect = aura_bt
	return [aura]


func on_damage(event: Event):
	if !tower.calc_chance(0.28 + 0.0048 * tower.get_level()):
		return

	CombatLog.log_ability(tower, event.get_target(), "Unstable Energies")

	tower.do_attack_damage(event.get_target(), _stats.damage_mana_multiplier * tower.get_mana(), tower.calc_attack_multicrit(0, 0, 0))
	tower.subtract_mana(tower.get_mana() * (0.75 - 0.01 * tower.get_level()), true)
	SFX.sfx_at_unit("AlmaTarget.dml", event.get_target())


func on_create(_preceding_tower: Tower):
	tower.user_real = _stats.aura_mana_cost
