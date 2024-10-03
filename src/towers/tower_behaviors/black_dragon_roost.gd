extends TowerBehavior


# NOTE: [ORIGINAL_GAME_BUG] Original script appears to be
# completely broken? It uses addEventOnDamage() which means
# that the handler will be called when creep *deals damage*
# and that's clearly not what's supposed to happen. Fixed it
# by switching to addEventOnDamaged()/add_event_on_damaged()
# so that the handler which increases damage taken by creep
# is called when creep takes damage.

# NOTE: the trigger chance for Fear the Dark ability appears
# to have been changed often. Used 20% which is the value on
# youtd.best and appears to be the most recent.


var fear_dark_bt: BuffType


func get_ability_info_list() -> Array[AbilityInfo]:
	var list: Array[AbilityInfo] = []
	
	var ability: AbilityInfo = AbilityInfo.new()
	ability.name = "Fear the Dark"
	ability.icon = "res://resources/icons/undead/skull_06.tres"
	ability.description_short = "Chance to debuff hit creeps, increasing damage received from all sources.\n"
	ability.description_full = "20% chance to debuff hit creeps for 7 seconds. Debuffed creeps take 30% more damage (from all sources). Each creep in 500 range decreases the effect by 25%, creeps with this buff don't count. The effect on bosses is 50% weaker.\n" \
	+ " \n" \
	+ "[color=ORANGE]Level Bonus:[/color]\n" \
	+ "+0.4% chance\n" \
	+ "+0.28 seconds duration\n" \
	+ "1.2% more damage taken\n"
	list.append(ability)

	return list


func load_triggers(triggers: BuffType):
	triggers.add_event_on_damage(on_damage)


func tower_init():
	fear_dark_bt = BuffType.new("fear_dark_bt", 5, 0.1, false, self)
	fear_dark_bt.set_buff_icon("res://resources/icons/generic_icons/ghost.tres")
	fear_dark_bt.set_buff_tooltip("Fear the Dark\nIncreases damage taken.")
	fear_dark_bt.add_event_on_create(fear_dark_bt_on_create)
	fear_dark_bt.add_event_on_cleanup(fear_dark_bt_on_cleanup)
	fear_dark_bt.add_event_on_damaged(fear_dark_bt_on_damaged)
	var mod: Modifier = Modifier.new()
	mod.add_modification(Modification.Type.MOD_MOVESPEED, -0.5, 0.0)
	mod.add_modification(Modification.Type.MOD_HP_REGEN_PERC, -0.5, -0.01)
	mod.add_modification(Modification.Type.MOD_ARMOR_PERC, 0.5, -0.008)
	mod.add_modification(Modification.Type.MOD_ITEM_QUALITY_ON_DEATH, 0.25, 0.01)
	fear_dark_bt.set_buff_modifier(mod)


func on_damage(event: Event):
	var chance: float = 0.20 + 0.004 * tower.get_level()

	if !tower.calc_chance(chance):
		return

	CombatLog.log_ability(tower, event.get_target(), "Fear the Dark")

	fear_dark_bt.apply(tower, event.get_target(), tower.get_level())


# NOTE: startA() in original script
func fear_dark_bt_on_create(event: Event):
	var buff: Buff = event.get_buff()
	var unit: Unit = buff.get_buffed_unit()
	unit.set_sprite_color(Color8(125, 125, 125, 255))


# NOTE: clean() in original script
func fear_dark_bt_on_cleanup(event: Event):
	var buff: Buff = event.get_buff()
	var unit: Unit = buff.get_buffed_unit()
	unit.set_sprite_color(Color8(255, 255, 255, 255))


# NOTE: dmg() in original script
func fear_dark_bt_on_damaged(event: Event):
	var buff: Buff = event.get_buff()
	var caster: Tower = buff.get_caster()
	var target: Unit = buff.get_buffed_unit()
	var it: Iterate = Iterate.over_units_in_range_of_unit(caster, TargetType.new(TargetType.CREEPS), target, 500)

	var damage_increase: float = 0.30 + 0.012 * caster.get_level()
	if target.get_size() >= CreepSize.enm.BOSS:
		damage_increase *= 0.5

	while true:
		var creep: Unit = it.next()
		if creep == null:
			break

		if creep.get_buff_of_type(fear_dark_bt) != null:
			damage_increase *= 0.75

	event.damage *= (1.0 + damage_increase)
