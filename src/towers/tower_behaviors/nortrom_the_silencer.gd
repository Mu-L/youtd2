extends TowerBehavior


var silence_bt: BuffType
var aura_bt: BuffType
var glaive_pt: ProjectileType

const AURA_RANGE: int = 350


func get_ability_info_list_DELETEME() -> Array[AbilityInfo]:
	var physical_string: String = AttackType.convert_to_colored_string(AttackType.enm.PHYSICAL)

	var list: Array[AbilityInfo] = []
	
	var glaive: AbilityInfo = AbilityInfo.new()
	glaive.name = "Glaives of Wisdom"
	glaive.icon = "res://resources/icons/hud/recipe_reassemble.tres"
	glaive.description_short = "Every attack an extra glaive is shot out at the cost of mana. The glaive deals %s damage.\n" % physical_string
	glaive.description_full = "Every attack an extra glaive is shot out at the cost of 40 mana. This glaive deals %s damage equal to Nortrom's attack damage and targets the creep with the least health in Nortrom's attack range.\n" % physical_string
	list.append(glaive)

	var last_word: AbilityInfo = AbilityInfo.new()
	last_word.name = "Last Word"
	last_word.icon = "res://resources/icons/shields/shield_skull.tres"
	last_word.description_short = "Whenever Nortrom hits a creep, he deals more damage if the creep is silenced.\n"
	last_word.description_full = "Whenever Nortrom hits a creep, he deals 20% more damage if the creep is silenced. This affects [color=GOLD]Glaives of Wisdom[/color] as well.\n" \
	+ " \n" \
	+ "[color=ORANGE]Level Bonus:[/color]\n" \
	+ "+3.2% damage\n"
	list.append(last_word)

	var curse: AbilityInfo = AbilityInfo.new()
	curse.name = "Curse of the Silent"
	curse.icon = "res://resources/icons/tower_variations/ash_geyser_purple.tres"
	curse.description_short = "Creeps in range of Nortrom are periodically silenced.\n"
	curse.description_full = "Every 7 seconds creeps within 800 range of Nortrom are silenced for 2 seconds.\n" \
	+ " \n" \
	+ "[color=ORANGE]Level Bonus:[/color]\n" \
	+ "+0.04 silence duration\n"
	curse.radius = 800
	curse.target_type = TargetType.new(TargetType.CREEPS)
	list.append(curse)

	return list


func load_triggers(triggers: BuffType):
	triggers.add_event_on_attack(on_attack)
	triggers.add_event_on_damage(on_damage)
	triggers.add_periodic_event(periodic, 7.0)


func tower_init():
	silence_bt = CbSilence.new("silence_bt", 0, 0, false, self)

	aura_bt = BuffType.create_aura_effect_type("aura_bt", true, self)
	aura_bt.set_buff_icon("res://resources/icons/generic_icons/aries.tres")
	aura_bt.add_event_on_attack(aura_bt_on_attack)
	aura_bt.set_buff_tooltip("Global Silence\nChance to silence creeps.")

	glaive_pt = ProjectileType.create_interpolate("path_to_projectile_sprite", 1000, self)
	glaive_pt.set_event_on_interpolation_finished(glaive_pt_on_hit)


func get_aura_types() -> Array[AuraType]:
	var aura: AuraType = AuraType.new()

	aura.name = "Global Silence"
	aura.icon = "res://resources/icons/tower_icons/tiny_storm_lantern.tres"
	aura.description_short = "Nearby towers have a small chance to silence creeps.\n"
	aura.description_full = "All towers within %d range of Nortrom have a 3%% attack speed adjusted chance to silence attacked creeps for 1 second. Duration is halved against bosses.\n" % AURA_RANGE \
	+ " \n" \
	+ "[color=ORANGE]Level Bonus:[/color]\n" \
	+ "+0.08% chance\n" \
	+ "+0.04 silence duration\n"

	aura.aura_range = AURA_RANGE
	aura.target_type = TargetType.new(TargetType.TOWERS)
	aura.target_self = true
	aura.level = 0
	aura.level_add = 1
	aura.aura_effect = aura_bt

	return [aura]


func on_attack(event: Event):
	var target: Unit = event.get_target()

	if tower.get_mana() < 40:
		return

	tower.subtract_mana(40, false)

	var it: Iterate = Iterate.over_units_in_range_of_caster(tower, TargetType.new(TargetType.CREEPS), 800)

	var lowest_health_creep: Unit = target

	while true:
		var next: Unit = it.next()

		if next == null:
			break

		if next.get_health() < target.get_health():
			lowest_health_creep = next

	var p: Projectile = Projectile.create_linear_interpolation_from_unit_to_unit(glaive_pt, tower, 1, 1, tower, lowest_health_creep, 0, true)
	p.set_projectile_scale(0.5)


func on_damage(event: Event):
	var target: Unit = event.get_target()
	var silenced_damage_multiplier: float = get_silenced_damage_multiplier()

	if target.is_silenced():
		event.damage *= silenced_damage_multiplier
		Effect.create_scaled("res://src/effects/spell_breaker_target.tscn", Vector3(target.get_x(), target.get_x(), 30), 0, 1)


func periodic(_event: Event):
	var it: Iterate = Iterate.over_units_in_range_of_caster(tower, TargetType.new(TargetType.CREEPS), 800)
	var duration: float = 2.0 + 0.04 * tower.get_level()

	CombatLog.log_ability(tower, null, "Curse of the Silent")

	while true:
		var next: Unit = it.next()

		if next == null:
			break

		silence_bt.apply_only_timed(tower, next, duration)


# NOTE: "glaive_hit()" in original script
func glaive_pt_on_hit(_p: Projectile, target: Unit):
	if target == null:
		return

	var damage: float = tower.get_current_attack_damage_with_bonus()
	var silenced_damage_multiplier: float = get_silenced_damage_multiplier()

	if target.is_silenced():
		damage *= silenced_damage_multiplier
		Effect.create_scaled("res://src/effects/spell_breaker_target.tscn", Vector3(target.get_x(), target.get_x(), 30), 0, 1)

	tower.do_attack_damage(target, damage, tower.calc_attack_multicrit_no_bonus())


# NOTE: "silence()" in original script
func aura_bt_on_attack(event: Event):
	var buff: Buff = event.get_buff()
	var buffed_unit: Unit = buff.get_buffed_unit()
	var target: Creep = event.get_target()
	var silence_chance: float = (0.03 + 0.0008 * tower.get_level()) * buffed_unit.get_base_attack_speed()

	if !tower.calc_chance(silence_chance):
		return

	var duration: float = 1.0 + 0.04 * tower.get_level()
	if target.get_size() == CreepSize.enm.BOSS:
		duration /= 2

	CombatLog.log_ability(buffed_unit, target, "Global Silence Effect")

	silence_bt.apply_only_timed(tower, target, duration)


func get_silenced_damage_multiplier() -> float:
	var multiplier: float = 1.2 + 0.032 * tower.get_level()

	return multiplier
