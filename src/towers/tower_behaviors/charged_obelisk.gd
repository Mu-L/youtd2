extends TowerBehavior


var stun_bt: BuffType
var charge_bt: BuffType


func get_ability_info_list_DELETEME() -> Array[AbilityInfo]:
	var list: Array[AbilityInfo] = []
	
	var ability: AbilityInfo = AbilityInfo.new()
	ability.name = "Electric Field"
	ability.icon = "res://resources/icons/mechanical/mech_badge.tres"
	ability.description_short = "On attack, this tower shocks a random creep in range. This shock deals spell damage and stuns the creep.\n"
	ability.description_full = "On attack, this tower shocks a random creep in 1000 range. This shock deals 1000 spell damage and stuns for 0.2 seconds, the spell damage has 20% bonus chance to crit. The stun does not work on bosses!\n" \
	+ " \n" \
	+ "[color=ORANGE]Level Bonus:[/color]\n" \
	+ "+40 spell damage\n" \
	+ "+0.4% bonus crit chance\n"
	ability.radius = 1000
	ability.target_type = TargetType.new(TargetType.CREEPS)
	list.append(ability)

	return list


func load_triggers(triggers: BuffType):
	triggers.add_event_on_attack(on_attack)


func load_specials(modifier: Modifier):
	modifier.add_modification(Modification.Type.MOD_MANA_REGEN, 0.0, 0.04)


func tower_init():
	stun_bt = CbStun.new("charged_obelisk_stun", 0, 0, false, self)

	charge_bt = BuffType.new("charge_bt", 10, 0, true, self)
	var mod: Modifier = Modifier.new()
	mod.add_modification(Modification.Type.MOD_ATTACKSPEED, 0.25, 0.001)
	charge_bt.set_buff_modifier(mod)
	charge_bt.set_buff_icon("res://resources/icons/generic_icons/electric.tres")
	charge_bt.set_buff_tooltip("Charge\nIncreases attack speed.")
	charge_bt.add_periodic_event(charge_bt_periodic, 1.0)

	
func create_autocasts_DELETEME() -> Array[Autocast]:
	var autocast: Autocast = Autocast.make()
	
	autocast.title = "Charge"
	autocast.icon = "res://resources/icons/electricity/electricity_yellow.tres"
	autocast.description_short = "Applies a buff to target tower which increases attack speed.\n"
	autocast.description = "Applies a buff to target tower which lasts 10 seconds, it increases the attack speed of the tower by 25%. Every second this buff will grant an additional 5% bonus attack speed.\n" \
	+ " \n" \
	+ "[color=ORANGE]Level Bonus:[/color]\n" \
	+ "+0.6% base attack speed\n" \
	+ "+0.1% bonus attack speed\n"
	autocast.caster_art = ""
	autocast.target_art = ""
	autocast.autocast_type = Autocast.Type.AC_TYPE_OFFENSIVE_BUFF
	autocast.num_buffs_before_idle = 3
	autocast.cast_range = 1200
	autocast.auto_range = 1200
	autocast.cooldown = 5
	autocast.mana_cost = 20
	autocast.target_self = true
	autocast.is_extended = false
	autocast.buff_type = charge_bt
	autocast.buff_target_type = TargetType.new(TargetType.TOWERS)
	autocast.handler = on_autocast

	return [autocast]


func on_attack(_event: Event):
	var lvl: int = tower.get_level()
	var it: Iterate = Iterate.over_units_in_range_of_caster(tower, TargetType.new(TargetType.CREEPS), 1000)
	var random_creep: Unit = it.next_random()

	if random_creep == null:
		return

	tower.do_spell_damage(random_creep, 1000 + 40 * lvl, tower.calc_spell_crit(0.20 + 0.004 * lvl, 0))

	if random_creep.get_size() < CreepSize.enm.BOSS:
		stun_bt.apply_only_timed(tower, random_creep, 0.2)

	Effect.create_simple_at_unit("res://src/effects/monsoon_bolt.tscn", random_creep)


func on_autocast(event: Event):
	charge_bt.apply(tower, event.get_target(), tower.get_level() * 6)


func charge_bt_periodic(event: Event):
	var buff: Buff = event.get_buff()
	var caster: Tower = buff.get_caster()
	var target: Unit = buff.get_buffed_unit()
	var new_level: int = buff.get_level() + 50 + caster.get_level()
	var duration: float = buff.get_remaining_duration()

	buff = charge_bt.apply_custom_timed(caster, target, new_level, duration)
	buff.set_remaining_duration(duration)
