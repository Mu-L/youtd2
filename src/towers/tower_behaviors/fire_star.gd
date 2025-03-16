extends TowerBehavior


# NOTE: [ORIGINAL_GAME_BUG] Fixed bug where Ignite stacks
# did not get increased damage because that was implemented
# in REFRESH callback, which never got called. REFRESH
# callback gets called if buff is applied with same level
# and less or lower power. Everytime Ignite is reapplied, it
# gets increased power, so therefore it always triggers
# UPGRADE instead of REFRESH.
# 
# Instead, multiplier is calculated right before it's needed.


var ignite_bt: BuffType
var firestar_pt: ProjectileType


func get_ability_info_list_DELETEME() -> Array[AbilityInfo]:
	var list: Array[AbilityInfo] = []
	
	var burn: AbilityInfo = AbilityInfo.new()
	burn.name = "Burn!"
	burn.icon = "res://resources/icons/fire/fire_bowl_02.tres"
	burn.description_short = "Ignites hit creeps, dealing attack damage over time and slowing the creep.\n"
	burn.description_full = "Ignites hit creeps, dealing attack damage every 2 seconds. Ignite damage is equal to this tower's current attack damage. Ignite slows movement speed by 5%, lasts 2.5 seconds and stacks. Each stack increases the damage by 5% and the slow by 1%.\n" \
	+ " \n" \
	+ "[color=ORANGE]Level Bonus:[/color]\n" \
	+ "+4% initial damage\n" \
	+ "+0.2% damage per stack\n"
	list.append(burn)

	var double_the_trouble: AbilityInfo = AbilityInfo.new()
	double_the_trouble.name = "Double the Trouble"
	double_the_trouble.icon = "res://resources/icons/cannons/cannon_05.tres"
	double_the_trouble.description_short = "Whenever this tower hits a creep, it has a chance to launch an additional projectile which deals the same damage as a normal attack.\n"
	double_the_trouble.description_full = "Whenever this tower hits a creep, it has a 12.5% chance to launch an additional projectile that deals the same damage as a normal attack.\n" \
	+ " \n" \
	+ "[color=ORANGE]Level Bonus:[/color]\n" \
	+ "+0.5% chance\n"
	list.append(double_the_trouble)

	return list


func load_triggers(triggers: BuffType):
	triggers.add_event_on_damage(on_damage)


func load_specials(_modifier: Modifier):
	tower.set_target_count(14)


func tower_init():
	ignite_bt = BuffType.new("ignite_bt", 2.5, 0, false, self)
	var ignite_bt_mod: Modifier = Modifier.new()
	ignite_bt_mod.add_modification(Modification.Type.MOD_MOVESPEED, -0.05, -0.01)
	ignite_bt.set_buff_modifier(ignite_bt_mod)
	ignite_bt.set_buff_icon("res://resources/icons/generic_icons/azul_flake.tres")
	ignite_bt.set_buff_tooltip("Ignite\nDeals damage over time and reduces movement speed.")
	ignite_bt.add_periodic_event(ignite_bt_periodic, 2.0)

	firestar_pt = ProjectileType.create("path_to_projectile_sprite", 7.0, 1000, self)
	firestar_pt.enable_homing(firestar_pt_on_hit, 0)


func on_damage(event: Event):
	var level: int = tower.get_level()
	var target: Unit = event.get_target()

	apply_ignite(target)

	var double_trouble_chance: float = 0.125 + 0.005 * level

	if !tower.calc_chance(double_trouble_chance):
		return

	CombatLog.log_ability(tower, target, "Double the Trouble")

	Projectile.create_from_unit_to_unit(firestar_pt, tower, 1.0, 1.0, tower, target, true, false, false)


func firestar_pt_on_hit(_p: Projectile, target: Unit):
	if target == null:
		return

	apply_ignite(target)

	tower.do_attack_damage(target, tower.get_current_attack_damage_with_bonus(), tower.calc_attack_multicrit_no_bonus())


func ignite_bt_periodic(event: Event):
	var buff: Buff = event.get_buff()
	var creep: Unit = buff.get_buffed_unit()
	var level: int = tower.get_level()

	var base_multiplier: float = 1.0 + 0.04 * level
	var damage_multiplier_per_stack: float = 0.05 + 0.002 * level
	var stack_count: int = buff.get_level()
	var damage_multiplier: float = base_multiplier + damage_multiplier_per_stack * stack_count

	tower.do_attack_damage(creep, tower.get_current_attack_damage_with_bonus() * damage_multiplier, tower.calc_attack_multicrit_no_bonus())


func apply_ignite(target: Unit):
	var buff: Buff = target.get_buff_of_type(ignite_bt)

	var active_stacks: int
	if buff != null:
		active_stacks = buff.get_level()
	else:
		active_stacks = 0

	var new_stacks: int = active_stacks + 1

	buff = ignite_bt.apply(tower, target, new_stacks)
	buff.set_displayed_stacks(new_stacks)
