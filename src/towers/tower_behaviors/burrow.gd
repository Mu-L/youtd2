extends TowerBehavior


func get_tier_stats() -> Dictionary:
	return {
		1: {armor_ignored = 0.1, armor_ignored_add = 0.004},
		2: {armor_ignored = 0.2, armor_ignored_add = 0.008},
		3: {armor_ignored = 0.3, armor_ignored_add = 0.012},
		4: {armor_ignored = 0.4, armor_ignored_add = 0.016},
	}


func get_ability_info_list_DELETEME() -> Array[AbilityInfo]:
	var armor_ignored: String = Utils.format_percent(_stats.armor_ignored, 2)
	var armor_ignored_add: String = Utils.format_percent(_stats.armor_ignored_add, 2)

	var list: Array[AbilityInfo] = []
	
	var ability: AbilityInfo = AbilityInfo.new()
	ability.name = "Piercing Shot"
	ability.icon = "res://resources/icons/rockets/rocket_02.tres"
	ability.description_short = "A portion of this tower's attack damage ignores creep's armor.\n"
	ability.description_full = "%s of this tower's attack damage cannot be reduced by armor resistances.\n" % armor_ignored \
	+ " \n" \
	+ "[color=ORANGE]Level Bonus:[/color]\n" \
	+ "+%s damage ratio\n" % armor_ignored_add
	list.append(ability)

	return list


func load_triggers(triggers_buff_type: BuffType):
	triggers_buff_type.add_event_on_damage(on_damage)


func on_damage(event: Event):
	var cur_ratio: float = _stats.armor_ignored + _stats.armor_ignored_add * tower.get_level()
	var s_dmg: float = event.damage
	var damage_base: float = event.damage
	var target: Creep = event.get_target() as Creep
	var temp: float = AttackType.get_damage_against(AttackType.enm.PHYSICAL, target.get_armor_type())

#	ignoring armor type "resistance" not weakness :P
	if temp > 0.0 && temp < 1.0:
		damage_base = damage_base / temp

	temp = (1 - target.get_current_armor_damage_reduction())
	if temp > 0.0:
		damage_base = damage_base / temp

	if s_dmg < damage_base:
		event.damage = damage_base * cur_ratio + s_dmg * (1.0 - cur_ratio)

	# The engine calculates critical strike extra damage ***AFTER*** the onDamage event, so there is no need to care about it in this trigger.
