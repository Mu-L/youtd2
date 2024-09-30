extends TowerBehavior


var will_positive_bt: BuffType
var will_negative_bt: BuffType
var withering_bt: BuffType


func get_ability_info_list() -> Array[AbilityInfo]:
	var list: Array[AbilityInfo] = []
	
	var insatiable: AbilityInfo = AbilityInfo.new()
	insatiable.name = "Insatiable Hunger"
	insatiable.icon = "res://resources/icons/helmets/helmet_07.tres"
	insatiable.description_short = "Deals additional attack damage to hit creeps based on missing mana and replenishes mana when attacking.\n"
	insatiable.description_full = "Deals 0.25% additional attack damage to hit creeps for each mana point the Death Knight is currently missing and replenishes 1% of his maximum mana. He replenishes 5% of his maximum mana for each unit he kills.\n" \
	+ " \n" \
	+ "[color=ORANGE]Level Bonus:[/color]\n" \
	+ "+0.01% damage per mana point\n"
	list.append(insatiable)

	var withering: AbilityInfo = AbilityInfo.new()
	withering.name = "Withering Presence"
	withering.icon = "res://resources/icons/tower_icons/lesser_skeletal_mage.tres"
	withering.description_short = "Chance to steal health of nearby creeps.\n"
	withering.description_full = "Whenever a unit comes in 900 range of the Death Knight, it has a 15% chance to have its health regeneration reduced by 50% and to lose 5% of its current health every second for 4 seconds. Units affected by this spell grant 50% less experience and bounty on death.\n" \
	+ " \n" \
	+ "[color=ORANGE]Level Bonus:[/color]\n" \
	+ "+0.4% chance\n" \
	+ "+1% health regen reduction\n" \
	+ "-1% experience and bounty reduction\n"
	withering.radius = 900
	withering.target_type = TargetType.new(TargetType.CREEPS)
	list.append(withering)

	return list


func load_triggers(triggers: BuffType):
	triggers.add_event_on_damage(on_damage)
	triggers.add_event_on_kill(on_kill)
	triggers.add_event_on_unit_comes_in_range(on_unit_in_range, 900, TargetType.new(TargetType.CREEPS))


func load_specials(modifier: Modifier):
	modifier.add_modification(Modification.Type.MOD_MANA, 0.0, 2.0)


func tower_init():
	will_positive_bt = BuffType.new("will_positive_bt", 5, 0, true, self)
	var will_positive_bt_mod: Modifier = Modifier.new()
	will_positive_bt_mod.add_modification(Modification.Type.MOD_DAMAGE_BASE_PERC, 0.0, 0.002)
	will_positive_bt.set_buff_modifier(will_positive_bt_mod)
	will_positive_bt.set_buff_icon("res://resources/icons/generic_icons/alien_skull.tres")
	will_positive_bt.set_buff_tooltip("Will of the Undying\nIncreases attack damage.")

	will_negative_bt = BuffType.new("will_negative_bt", 5, 0, false, self)
	var will_negative_bt_mod: Modifier = Modifier.new()
	will_negative_bt_mod.add_modification(Modification.Type.MOD_DAMAGE_BASE_PERC, 0.0, -0.002)
	will_negative_bt.set_buff_modifier(will_negative_bt_mod)
	will_negative_bt.set_buff_icon("res://resources/icons/generic_icons/pisces.tres")
	will_negative_bt.set_buff_tooltip("Will of the Undying\nReduces attack damage.")

	withering_bt = BuffType.new("withering_bt", 4, 0, false, self)
	var withering_bt_mod: Modifier = Modifier.new()
	withering_bt_mod.add_modification(Modification.Type.MOD_HP_REGEN_PERC, -0.5, -0.1)
	withering_bt_mod.add_modification(Modification.Type.MOD_EXP_GRANTED, -0.5, 0.01)
	withering_bt_mod.add_modification(Modification.Type.MOD_BOUNTY_GRANTED, -0.5, 0.01)
	withering_bt.set_buff_modifier(withering_bt_mod)
	withering_bt.set_buff_icon("res://resources/icons/generic_icons/ghost.tres")
	withering_bt.set_buff_tooltip("Withering Presence\nReduces health regeneration and periodically steals health.")
	withering_bt.add_periodic_event(withering_bt_periodic, 1.0)


func create_autocasts() -> Array[Autocast]:
	var autocast: Autocast = Autocast.make()

	autocast.title = "Will of the Undying"
	autocast.icon = "res://resources/icons/undead/skull_01.tres"
	autocast.description_short = "The death knight empowers himself by draining the power of nearby towers.\n"
	autocast.description = "The Death Knight decreases the base attack damage of all towers in 200 range by 10% and loses 50% of his remaining mana to increase his base damage by 15% for each tower affected for 5 seconds. Only towers that cost at least 1300 gold are affected by this spell.\n" \
	+ " \n" \
	+ "[color=ORANGE]Level Bonus:[/color]\n" \
	+ "+0.2% damage absorbed\n"
	autocast.caster_art = "res://src/effects/howl_caster.tscn"
	autocast.target_art = ""
	autocast.autocast_type = Autocast.Type.AC_TYPE_OFFENSIVE_IMMEDIATE
	autocast.num_buffs_before_idle = 0
	autocast.cast_range = 900
	autocast.auto_range = 900
	autocast.cooldown = 10
	autocast.mana_cost = 50
	autocast.target_self = false
	autocast.is_extended = false
	autocast.buff_type = null
	autocast.buff_target_type = null
	autocast.handler = on_autocast

	return [autocast]


func on_damage(event: Event):
	var level: int = tower.get_level()
	var mana: float = tower.get_mana()
	var max_mana: float = tower.get_overall_mana()
	var mana_gain: float = max_mana * 0.01
	var damage_bonus_from_mana: float = event.damage * (max_mana - mana) * (0.025 + 0.001 * level)

	tower.add_mana(mana_gain)
	event.damage += damage_bonus_from_mana


func on_kill(_event: Event):
	var max_mana: float = tower.get_overall_mana()
	var mana_gain: float = max_mana * 0.05

	tower.add_mana(mana_gain)


func on_unit_in_range(event: Event):
	var target: Unit = event.get_target()
	var level: int = tower.get_level()
	var withering_presence_chance: float = 0.15 + 0.004 * level

	if !tower.calc_chance(withering_presence_chance):
		return

	CombatLog.log_ability(tower, target, "Withering Presence")

	withering_bt.apply(tower, target, level)


func on_autocast(_event: Event):
	var level: int = tower.get_level()
	var it: Iterate = Iterate.over_units_in_range_of_caster(tower, TargetType.new(TargetType.TOWERS), 200)
	var mana: float = tower.get_mana()
	var tower_count: int = 0

	tower.set_mana(mana / 2)

	while true:
		var next: Unit = it.next()

		if next == null:
			break

		if next == tower || next.get_gold_cost() < 1300:
			continue

		tower_count += 1

		will_negative_bt.apply(tower, next, 50 + level)

	if tower_count > 0:
		will_positive_bt.apply(tower, tower, (75 + level) * tower_count)

	if tower_count == 0:
		CombatLog.log_ability(tower, null, "Will of the Undying failed because nearby towers are cheap")


func withering_bt_periodic(event: Event):
	var buff: Buff = event.get_buff()
	var buffed_unit: Unit = buff.get_buffed_unit()
	var hp: float = buffed_unit.get_health()
	var hp_loss: float = hp * 0.05

	buffed_unit.set_health(hp - hp_loss)
