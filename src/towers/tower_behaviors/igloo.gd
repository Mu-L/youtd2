extends TowerBehavior


var extreme_cold_bt: BuffType
var stun_bt: BuffType


func get_tier_stats() -> Dictionary:
	return {
		1: {stun_duration = 0.4, cold_damage = 700, cold_damage_add = 35, cold_slow = 0.20},
		2: {stun_duration = 0.8, cold_damage = 1500, cold_damage_add = 75, cold_slow = 0.25},
		3: {stun_duration = 1.2, cold_damage = 2800, cold_damage_add = 140, cold_slow = 0.30},
	}


const COLD_SLOW_ADD: float = 0.004
const COLD_SLOW_DURATION: float = 4
const COLD_RANGE: float = 900


func get_ability_info_list_DELETEME() -> Array[AbilityInfo]:
	var cold_range: String = Utils.format_float(COLD_RANGE, 2)
	var cold_damage: String = Utils.format_float(_stats.cold_damage, 2)
	var cold_damage_add: String = Utils.format_float(_stats.cold_damage_add, 2)
	var cold_slow: String = Utils.format_percent(_stats.cold_slow, 2)
	var cold_slow_add: String = Utils.format_percent(COLD_SLOW_ADD, 2)
	var cold_slow_duration: String = Utils.format_float(COLD_SLOW_DURATION, 2)
	var stun_duration: String = Utils.format_float(_stats.stun_duration, 2)

	var list: Array[AbilityInfo] = []
	
	var ability: AbilityInfo = AbilityInfo.new()
	ability.name = "Extreme Cold"
	ability.icon = "res://resources/icons/furniture/furniture.tres"
	ability.description_short = "Creeps that come in range of this tower will suffer spell damage and become slowed.\n"
	ability.description_full = "Creeps that come within %s AoE of this tower will be affected by extreme cold, suffering %s spell damage, and becoming slowed by %s for %s seconds. When the slow expires they will get stunned for %s seconds.\n" % [cold_range, cold_damage, cold_slow, cold_slow_duration, stun_duration] \
	+ " \n" \
	+ "[color=ORANGE]Level Bonus:[/color]\n" \
	+ "+%s damage \n" % cold_damage_add \
	+ "+%s slow\n" % cold_slow_add
	ability.radius = COLD_RANGE
	ability.target_type = TargetType.new(TargetType.CREEPS)
	list.append(ability)

	return list


func load_triggers(triggers: BuffType):
	triggers.add_event_on_unit_comes_in_range(on_unit_in_range, COLD_RANGE, TargetType.new(TargetType.CREEPS))


func load_specials_DELETEME(modifier: Modifier):
	modifier.add_modification(Modification.Type.MOD_DMG_TO_MASS, -0.50, 0.0)


func boekie_igloo_end(event: Event):
	var buff: Buff = event.get_buff()
	stun_bt.apply_only_timed(buff.get_caster(), buff.get_buffed_unit(), _stats.stun_duration)


func tower_init():
	var modifier: Modifier = Modifier.new()
	modifier.add_modification(Modification.Type.MOD_MOVESPEED, -_stats.cold_slow, -COLD_SLOW_ADD)
	extreme_cold_bt = BuffType.new("extreme_cold_bt", COLD_SLOW_DURATION, 0, false, self)
	extreme_cold_bt.set_buff_icon("res://resources/icons/generic_icons/foot_trip.tres")
	extreme_cold_bt.set_buff_modifier(modifier)
	extreme_cold_bt.add_event_on_expire(boekie_igloo_end)
	extreme_cold_bt.set_buff_tooltip("Extreme Cold\nReduces movement speed and stuns creep when the debuff expires.")

	stun_bt = CbStun.new("igloo_stun", 0, 0, false, self)


func on_unit_in_range(event: Event):
	var creep: Unit = event.get_target()
	var level: int = tower.get_level()
	var damage: float = _stats.cold_damage + _stats.cold_damage_add * level

	tower.do_spell_damage(creep, damage, tower.calc_spell_crit_no_bonus())
	extreme_cold_bt.apply(tower, creep, level)

	Effect.create_scaled("res://src/effects/frost_armor_damage.tscn", Vector3(creep.get_x(), creep.get_y(), 30), 0, 3)
