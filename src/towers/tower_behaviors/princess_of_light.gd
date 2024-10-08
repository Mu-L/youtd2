extends TowerBehavior


var extract_bt: BuffType
var channel_bt: BuffType


func get_tier_stats() -> Dictionary:
	return {
		1: {extract_exp = 1, extract_exp_add = 0.05, channel_exp = 1, channel_mod_dmg = 0.15, channel_buff_duration = 10},
		2: {extract_exp = 2, extract_exp_add = 0.10, channel_exp = 2, channel_mod_dmg = 0.20, channel_buff_duration = 12},
	}


const EXTRACT_CHANCE: float = 0.33
const EXTRACT_DURATION: float = 10.0
const EXTRACT_COUNT: int = 10
const EXTRACT_COUNT_ADD: int = 1
const CHANNEL_MOD_DMG_ADD: float = 0.005
const CHANNEL_BUFF_DURATION_ADD: float = 0.1
const CHANNEL_STACK_COUNT: int = 15



func get_ability_info_list() -> Array[AbilityInfo]:
	var channel_exp: String = Utils.format_float(_stats.channel_exp, 2)
	var channel_mod_dmg: String = Utils.format_percent(_stats.channel_mod_dmg, 2)
	var channel_mod_dmg_add: String = Utils.format_percent(CHANNEL_MOD_DMG_ADD, 2)
	var channel_buff_duration: String = Utils.format_float(_stats.channel_buff_duration, 2)
	var channel_buff_duration_add: String = Utils.format_float(CHANNEL_BUFF_DURATION_ADD, 2)
	var channel_stack_count: String = Utils.format_float(CHANNEL_STACK_COUNT, 2)

	var list: Array[AbilityInfo] = []
	
	var ability: AbilityInfo = AbilityInfo.new()
	ability.name = "Channel Energy"
	ability.icon = "res://resources/icons/gems/earring_05.tres"
	ability.description_short = "Whenever this tower is hit by a friendly spell, the caster of that spell will receive experience and this tower will gain bonus attack damage.\n"
	ability.description_full = "Whenever this tower is hit by a friendly spell, the caster of that spell will be granted %s experience and this tower will gain %s bonus attack damage for %s seconds. This effect stacks up to %s times, but new stacks will not refresh the duration of old ones.\n" % [channel_exp, channel_mod_dmg, channel_buff_duration, channel_stack_count] \
	+ " \n" \
	+ "[color=ORANGE]Level Bonus:[/color]\n" \
	+ "+%s attack damage\n" % channel_mod_dmg_add \
	+ "+%s seconds duration\n" % channel_buff_duration_add
	list.append(ability)

	return list


func load_triggers(triggers: BuffType):
	triggers.add_event_on_spell_targeted(on_spell_target)


func load_specials(modifier: Modifier):
	modifier.add_modification(Modification.Type.MOD_MANA, 0.0, 2.0)


func tower_init():
	extract_bt = BuffType.new("extract_bt", EXTRACT_DURATION, 0, false, self)
	extract_bt.add_event_on_damaged(extract_bt_on_damaged)
	extract_bt.set_buff_icon("res://resources/icons/generic_icons/gold_bar.tres")
	extract_bt.set_buff_tooltip("Extract Experience\nChance to grant extra experience on damage.")

	channel_bt = BuffType.new("channel_bt", -1, 0, true, self)
	var mod: Modifier = Modifier.new()
	mod.add_modification(Modification.Type.MOD_DAMAGE_ADD_PERC, 0.0, 0.001)
	channel_bt.set_buff_modifier(mod)
	channel_bt.set_buff_icon("res://resources/icons/generic_icons/aquarius.tres")
	channel_bt.set_buff_tooltip("Channel Energy\nIncreases attack damage.")


func create_autocasts() -> Array[Autocast]:
	var autocast: Autocast = Autocast.make()

	var extract_chance: String = Utils.format_percent(EXTRACT_CHANCE, 2)
	var extract_exp: String = Utils.format_float(_stats.extract_exp, 2)
	var extract_exp_add: String = Utils.format_float(_stats.extract_exp_add, 2)
	var extract_duration: String = Utils.format_float(EXTRACT_DURATION, 2)
	var extract_count: String = Utils.format_float(EXTRACT_COUNT, 2)
	var extract_count_add: String = Utils.format_float(EXTRACT_COUNT_ADD, 2)

	autocast.title = "Extract Experience"
	autocast.icon = "res://resources/icons/fire/fire_in_cup.tres"
	autocast.description_short = "Applies a debuff on a creep. Towers that damage this creep have a chance to extract extra experience.\n"
	autocast.description = "Applies a debuff on a creep. Towers that damage this creep have a %s chance to extract %s experience. Lasts %s seconds or until %s extractions occur.\n" % [extract_chance, extract_exp, extract_duration, extract_count] \
	+ " \n" \
	+ "[color=ORANGE]Level Bonus:[/color]\n" \
	+ "+%s experience\n" % extract_exp_add \
	+ "+%s extraction\n" % extract_count_add
	autocast.caster_art = ""
	autocast.target_art = ""
	autocast.autocast_type = Autocast.Type.AC_TYPE_OFFENSIVE_BUFF
	autocast.num_buffs_before_idle = 3
	autocast.cast_range = 1000
	autocast.auto_range = 1000
	autocast.cooldown = 5
	autocast.mana_cost = 20
	autocast.target_self = false
	autocast.is_extended = false
	autocast.buff_type = extract_bt
	autocast.buff_target_type = TargetType.new(TargetType.CREEPS)
	autocast.handler = on_autocast

	return [autocast]


func on_spell_target(event: Event):
	var caster: Unit = event.get_target()
	var buff: Buff = tower.get_buff_of_type(channel_bt)
	var tower_level: int = tower.get_level()
	var buff_level: int = int((_stats.channel_mod_dmg + CHANNEL_MOD_DMG_ADD * tower_level) * 1000)
	var stack_duration: float = _stats.channel_buff_duration + CHANNEL_BUFF_DURATION_ADD * tower_level

	if !caster is Tower:
		return

	caster.add_exp(1)

	if buff == null:
		buff = channel_bt.apply(tower, tower, buff_level)
		buff.user_int = 1
		buff.set_displayed_stacks(1)
	else:
		var reached_max_stacks: bool = buff.user_int >= CHANNEL_STACK_COUNT
		if reached_max_stacks:
			return

		buff.user_int += 1
		buff.set_level(buff.get_level() + buff_level)
		buff.set_displayed_stacks(buff.user_int)

	await Utils.create_timer(stack_duration, self).timeout

	if Utils.unit_is_valid(tower):
		buff = tower.get_buff_of_type(channel_bt)

		if buff == null:
			return

		if buff.user_int <= 1:
			buff.remove_buff()
		else:
			buff.user_int -= 1
			buff.set_level(buff.get_level() - buff_level)
			buff.set_displayed_stacks(buff.user_int)


func on_autocast(event: Event):
	var level: int = tower.get_level()
	var buff: Buff = extract_bt.apply(tower, event.get_target(), level)
	var extraction_count: int = EXTRACT_COUNT + EXTRACT_COUNT_ADD * level
	buff.user_int = extraction_count


func extract_bt_on_damaged(event: Event):
	var buff: Buff = event.get_buff()
	var exp_gain: float = _stats.extract_exp + buff.get_level() * _stats.extract_exp_add
	var extract_count: int = buff.user_int

	if !tower.calc_chance(EXTRACT_CHANCE):
		return

	CombatLog.log_ability(tower, event.get_target(), "Extract Experience")

	if extract_count > 0:
		event.get_target().add_exp(exp_gain)
		buff.user_int -= 1
	else:
		buff.remove_buff()
