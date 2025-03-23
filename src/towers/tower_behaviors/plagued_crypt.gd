extends TowerBehavior


var plague_bt: BuffType
var army_bt: BuffType
var multiboard: MultiboardValues


func load_triggers(triggers: BuffType):
	triggers.add_event_on_damage(on_damage)
	triggers.add_periodic_event(periodic, 3.0)


func tower_init():
	plague_bt = BuffType.new("plague_bt", 5.0, 0.2, false, self)
	plague_bt.set_buff_icon("res://resources/icons/generic_icons/alien_skull.tres")
	plague_bt.add_event_on_create(cedi_crypt_plague_on_create)
	plague_bt.add_event_on_upgrade(cedi_crypt_plague_on_upgrade)
	plague_bt.add_event_on_refresh(cedi_crypt_plague_on_refresh)
	plague_bt.add_periodic_event(cedi_crypt_plague_periodic_damage, 1.0)
#	NOTE: The period of periodic event starts out at 0.01
#	and then gets changed to real period via
#	enable_advanced(). It starts at 0.01 to change to real
#	period as quickly as possible.
	plague_bt.add_periodic_event(cedi_crypt_plague_periodic_spread, 0.01)
	plague_bt.set_buff_tooltip(tr("I2A2"))

	army_bt = BuffType.new("army_bt", -1, 0, true, self)
	var cedi_crypt_army_mod: Modifier = Modifier.new()
	cedi_crypt_army_mod.add_modification(Modification.Type.MOD_ATTACKSPEED, 0.0, 0.05)
	cedi_crypt_army_mod.add_modification(Modification.Type.MOD_DAMAGE_BASE_PERC, 0.0, 0.05)
	army_bt.set_buff_modifier(cedi_crypt_army_mod)
	army_bt.set_buff_icon("res://resources/icons/generic_icons/ghost.tres")
	army_bt.set_buff_tooltip(tr("HDAQ"))

	multiboard = MultiboardValues.new(2)
	var souls_extracted_label: String = tr("E8AJ")
	var infection_rate_label: String = tr("MIK6")
	multiboard.set_key(0, souls_extracted_label)
	multiboard.set_key(1, infection_rate_label)


func on_damage(event: Event):
	var target: Unit = event.get_target()
	var level: int = tower.get_level()
	plague_bt.apply(tower, target, level)


func on_tower_details():
	var army_buff: Buff = tower.get_buff_of_type(army_bt)
	var army_buff_level: int
	if army_buff != null:
		army_buff_level = army_buff.get_level()
	else:
		army_buff_level = 0
	var souls_extracted: String = str(army_buff_level)
	var plague_spread_time: float = get_plague_spread_time()
	var infection_rate: String = Utils.format_float(plague_spread_time, 2)

	multiboard.set_value(0, souls_extracted)
	multiboard.set_value(1, infection_rate)

	return multiboard


func periodic(_event: Event):
	var it: Iterate = Iterate.over_corpses_in_range(tower, Vector2(tower.get_x(), tower.get_y()), 1150)
	var corpse: Unit = it.next_corpse()

	if corpse == null:
		return

	Effect.add_special_effect("res://src/effects/raise_skeleton.tscn", Vector2(corpse.get_x(), corpse.get_y()))

	corpse.remove_from_game()

	var active_buff: Buff = tower.get_buff_of_type(army_bt)
	var new_buff_level: int
	if active_buff != null:
		new_buff_level = active_buff.get_level() + 1
	else:
		new_buff_level = 1
	
	var buff: Buff = army_bt.apply(tower, tower, new_buff_level)
	buff.set_displayed_stacks(buff.get_level())

	var stack_duration: float = (20.0 + 0.4 * tower.get_level()) * tower.get_prop_buff_duration()
	await Utils.create_manual_timer(stack_duration, self).timeout

#	NOTE: after sleep
	if !Utils.unit_is_valid(tower):
		return

	if !is_instance_valid(buff):
		return

	var reduced_buff_level: int = buff.get_level() - 1
	if reduced_buff_level > 0:
		buff.set_level(reduced_buff_level)
	else:
		buff.remove_buff()


# NOTE: onCreate() in original script
func cedi_crypt_plague_on_create(event: Event):
	var buff: Buff = event.get_buff()
	var damage_increase_multiplier: int = 0
	buff.user_int = damage_increase_multiplier
	var first_periodic_call: int = 0
	buff.user_int2 = first_periodic_call

	buff.set_displayed_stacks(buff.user_int + 1)


# NOTE: part of refresh() in original script
func cedi_crypt_plague_on_upgrade(event: Event):
	var buff: Buff = event.get_buff()
	increase_plague_stacks(buff)


# NOTE: part of refresh() in original script
func cedi_crypt_plague_on_refresh(event: Event):
	var buff: Buff = event.get_buff()
	increase_plague_stacks(buff)


# NOTE: part of refresh() in original script
func increase_plague_stacks(buff: Buff):
	var old_damage_increase_multiplier: int = buff.user_int
	var new_damage_increase_multiplier: int = old_damage_increase_multiplier + 1
	buff.user_int = new_damage_increase_multiplier

	buff.set_displayed_stacks(buff.user_int + 1)


# NOTE: periodicDamage() in original script
func cedi_crypt_plague_periodic_damage(event: Event):
	var buff: Buff = event.get_buff()
	var target: Unit = buff.get_buffed_unit()
	var level: int = tower.get_level()
	var damage_increase_multiplier: int = buff.user_int
	var damage: float = (750 + 30 * level) + (375 + 15 * level) * damage_increase_multiplier

	tower.do_spell_damage(target, damage, tower.calc_spell_crit_no_bonus())


# NOTE: script doesn't spread when user_int2 is 0 because
# that case happens 0.01s after buff is applied. Once we
# call enable_advanced() with real duration of around 1.5s,
# we will start doing real plague spreads.
# NOTE: periodicSpread() in original script
func cedi_crypt_plague_periodic_spread(event: Event):
	var plague_buff: Buff = event.get_buff()
	var target: Unit = plague_buff.get_buffed_unit()
	var level: int = tower.get_level()
	var first_periodic_call: int = plague_buff.user_int2

	if first_periodic_call == 1:
		var it: Iterate = Iterate.over_units_in_range_of_unit(tower, TargetType.new(TargetType.CREEPS), target, 250)
		
		while true:
			var next: Unit = it.next_random()

			if next == null:
				break

			if next != target:
				plague_bt.apply(tower, next, level)
				break
	else:
		var new_first_periodic_call: int = 1
		plague_buff.user_int2 = new_first_periodic_call

	var plague_spread_time: float = get_plague_spread_time()
	event.enable_advanced(plague_spread_time, false)


# NOTE: plague spread time gets smaller as the level of army
# buff increases
func get_plague_spread_time():
	var army_buff: Buff = tower.get_buff_of_type(army_bt)
	var army_buff_level: int
	if army_buff == null:
		army_buff_level = 0
	else:
		army_buff_level = army_buff.get_level()
	
	var plague_spread_time: float = 1.5 * pow(1.1, -army_buff_level)

	return plague_spread_time
