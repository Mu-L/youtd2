extends TowerBehavior


# NOTE: [ORIGINAL_GAME_BUG] Fixed bug in original script
# where periodic() didn't multiply dmg_ratio_add value by
# tower level.


const EMBER_RADIUS: float = 300

var TARGET_TYPE_COMMON_TOWERS: TargetType = TargetType.new(TargetType.TOWERS + TargetType.RARITY_COMMON)
var ember_pt: ProjectileType


func get_tier_stats() -> Dictionary:
	return {
		1: {dmg_ratio = 0.08, dmg_ratio_add = 0.0016},
		2: {dmg_ratio = 0.10, dmg_ratio_add = 0.0020},
		3: {dmg_ratio = 0.12, dmg_ratio_add = 0.0048},
		4: {dmg_ratio = 0.16, dmg_ratio_add = 0.0064},
	}


func get_ability_info_list() -> Array[AbilityInfo]:
	var dmg_ratio: String = Utils.format_percent(_stats.dmg_ratio, 2)
	var dmg_ratio_add: String = Utils.format_percent(_stats.dmg_ratio_add, 2)
	var ember_radius: String = Utils.format_float(EMBER_RADIUS, 2)
	var elemental_string: String = AttackType.convert_to_colored_string(AttackType.enm.ELEMENTAL)

	var list: Array[AbilityInfo] = []
	
	var ability: AbilityInfo = AbilityInfo.new()
	ability.name = "Embers"
	ability.icon = "res://resources/icons/tower_icons/fiery_pebble.tres"
	ability.description_short = "Every second, causes nearby Common towers to launch embers at random creeps in the attack range of this tower.\n"
	ability.description_full = "Every second, causes Common towers in %s range to launch embers at random creeps in the attack range of this tower. Embers deal %s of the Common tower's attack damage as %s damage.\n" % [ember_radius, dmg_ratio, elemental_string] \
	+ " \n" \
	+ "Note that ember damage is dealt by this tower, not the Common tower.\n" \
	+ " \n" \
	+ "[color=ORANGE]Level Bonus:[/color]\n" \
	+ "+%s damage\n" % dmg_ratio_add \
	+ ""
	ability.radius = EMBER_RADIUS
	ability.target_type = TargetType.new(TargetType.TOWERS)
	list.append(ability)

	return list


func load_triggers(triggers: BuffType):
	triggers.add_periodic_event(periodic, 1.0)


func tower_init():
	ember_pt = ProjectileType.create_interpolate("res://src/projectiles/projectile_visuals/HeadhunterWEAPONSLeft.tscn", 650, self)
	ember_pt.set_event_on_interpolation_finished(ember_pt_on_hit)


func periodic(_event: Event):
	var towers_in_range: Iterate = Iterate.over_units_in_range_of_caster(tower, TARGET_TYPE_COMMON_TOWERS, EMBER_RADIUS)

	var common_tower: Unit = towers_in_range.next()

	if common_tower == null:
		return

#	NOTE: need to add RANGE_CHECK_BONUS_FOR_TOWERS to
#	account for tower radius, bit of a hack to get real
#	attack range. Iterate class only takes target radius into
#	consideration.
	var creeps_in_range: Iterate = Iterate.over_units_in_range_of_caster(common_tower, TargetType.new(TargetType.CREEPS), tower.get_range() + Constants.RANGE_CHECK_BONUS_FOR_TOWERS)

	var dmg_ratio: float = _stats.dmg_ratio + _stats.dmg_ratio_add * tower.get_level()

	while true:
		var target: Unit = creeps_in_range.next_random()

		if target == null:
			break

		# Need to change speed of ProjectileType before
		# creating projectile because cannot change
		# interpolated Projectile's speed after creation
		var ember_speed: float = Globals.synced_rng.randf_range(500, 750)
		ember_pt.set_speed(ember_speed)
		var p: Projectile = Projectile.create_bezier_interpolation_from_unit_to_unit(ember_pt, common_tower, 1, 1, common_tower, target, Globals.synced_rng.randf_range(0.0, 0.3), Globals.synced_rng.randf_range(-0.8, 0.8), Globals.synced_rng.randf_range(0.1, 0.4), true)
		p.set_color(Color.DARK_RED)

		var damage: float = common_tower.get_current_attack_damage_with_bonus() * dmg_ratio
		var crit: float = common_tower.calc_attack_multicrit_no_bonus()
		p.user_real = damage
		p.user_real2 = crit


# NOTE: interpolateFinished() in original script
func ember_pt_on_hit(p: Projectile, target: Unit):
	if target == null:
		return
	
	var damage: float = p.user_real
	var crit: float = p.user_real2

	tower.do_custom_attack_damage(target, damage, crit, AttackType.enm.ELEMENTAL)
