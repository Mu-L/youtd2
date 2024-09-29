extends TowerBehavior


func get_tier_stats() -> Dictionary:
	return {
		1: {lightning_dmg = 100, lightning_dmg_add = 5},
		2: {lightning_dmg = 300, lightning_dmg_add = 15},
		3: {lightning_dmg = 750, lightning_dmg_add = 37.5},
		4: {lightning_dmg = 1875, lightning_dmg_add = 93.75},
		5: {lightning_dmg = 3750, lightning_dmg_add = 187.5},
	}


func get_ability_info_list() -> Array[AbilityInfo]:
	var lightning_dmg: String = Utils.format_float(_stats.lightning_dmg, 2)
	var lightning_dmg_add: String = Utils.format_float(_stats.lightning_dmg_add, 2)
	var energy_string: String = AttackType.convert_to_colored_string(AttackType.enm.ENERGY)

	var list: Array[AbilityInfo] = []
	
	var ability: AbilityInfo = AbilityInfo.new()
	ability.name = "Lightning Strike"
	ability.icon = "res://resources/icons/electricity/lightning_glowing.tres"
	ability.description_short = "Whenever this tower's attack does not bounce it shoots down a delayed lightning bolt onto the target. The Lightning bolt deals %s damage.\n" % energy_string
	ability.description_full = "Whenever this tower's attack does not bounce it shoots down a delayed lightning bolt onto the target. The lightning bolt deals %s %s damage.\n" % [lightning_dmg, energy_string] \
	+ " \n" \
	+ "[color=ORANGE]Level Bonus:[/color]\n" \
	+ "+%s damage" % lightning_dmg_add
	list.append(ability)

	return list


func load_triggers(triggers_buff_type: BuffType):
	triggers_buff_type.add_event_on_damage(on_damage)


func load_specials(_modifier: Modifier):
	tower.set_attack_style_bounce(2, 0.0)


func on_create(_preceding_tower: Tower):
	tower.user_int = 0
	

func on_damage(event: Event):
	var creep: Unit = event.get_target()

	if event.is_main_target() == true:
		tower.user_int = 1
	else:
		tower.user_int = 0

	await Utils.create_timer(0.4, self).timeout

	if tower.user_int == 1 && Utils.unit_is_valid(creep):
		CombatLog.log_ability(tower, creep, "Lightning Strike")

		Effect.create_simple_at_unit("res://src/effects/monsoon_bolt.tscn", creep)
		tower.do_attack_damage(creep, _stats.lightning_dmg + (_stats.lightning_dmg_add * tower.get_level()), tower.calc_attack_multicrit(0.0, 0.0, 0.0))
