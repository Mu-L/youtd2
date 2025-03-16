extends TowerBehavior


var melt_bt: BuffType


func get_tier_stats() -> Dictionary:
	return {
		1: {mod_armor = 1, mod_armor_add = 0.04, periodic_mod_armor = 0.5, periodic_mod_armor_add = 0.02, melt_damage = 20, melt_damage_add = 0.8, periodic_melt_damage_increase = 20},
		2: {mod_armor = 2, mod_armor_add = 0.08, periodic_mod_armor = 1.0, periodic_mod_armor_add = 0.04, melt_damage = 40, melt_damage_add = 1.6, periodic_melt_damage_increase = 40},
	}

const AURA_RANGE: int = 900


func load_specials(modifier: Modifier):
	modifier.add_modification(Modification.Type.MOD_DMG_TO_MAGIC, -0.50, 0.0)
	modifier.add_modification(Modification.Type.MOD_DMG_TO_NATURE, 0.50, 0.01)


func tower_init():
	melt_bt = BuffType.create_aura_effect_type("melt_bt", false, self)
	melt_bt.add_event_on_create(melt_bt_on_create)
	melt_bt.add_periodic_event(melt_bt_on_periodic, 1.0)
	melt_bt.add_event_on_cleanup(melt_bt_on_cleanup)
	melt_bt.set_buff_icon("res://resources/icons/generic_icons/open_wound.tres")
	melt_bt.set_buff_tooltip("Melting\nDecreases armor and deals damage over time.")


func get_aura_types_DELETEME() -> Array[AuraType]:
	var aura: AuraType = AuraType.new()

	var mod_armor: String = Utils.format_float(_stats.mod_armor, 2)
	var mod_armor_add: String = Utils.format_float(_stats.mod_armor_add, 2)
	var periodic_mod_armor: String = Utils.format_float(_stats.periodic_mod_armor, 2)
	var periodic_mod_armor_add: String = Utils.format_float(_stats.periodic_mod_armor_add, 2)
	var melt_damage: String = Utils.format_float(_stats.melt_damage, 2)
	var melt_damage_add: String = Utils.format_float(_stats.melt_damage_add, 2)
	var periodic_melt_damage_increase: String = Utils.format_float(_stats.periodic_melt_damage_increase, 2)

	aura.name = "Melt"
	aura.icon = "res://resources/icons/tower_variations/mossy_acid_sprayer_red.tres"
	aura.description_short = "The enormous heat of the Caged Fire decreases armor of nearby creeps and deals spell damage.\n"
	aura.description_full = "The enormous heat of the Caged Fire decreases armor of all creeps in %d range by %s and deals %s spell damage. Each second creeps in %d range around the caged fire lose %s extra armor and the spell damage will increase by %s.\n" % [AURA_RANGE, mod_armor, melt_damage, AURA_RANGE, periodic_mod_armor, periodic_melt_damage_increase] \
	+ " \n" \
	+ "[color=ORANGE]Level Bonus:[/color]\n" \
	+ "+%s start armor reduction\n" % mod_armor_add \
	+ "+%s armor reduction\n" % periodic_mod_armor_add \
	+ "+%s spell damage\n" % melt_damage_add

	aura.aura_range = AURA_RANGE
	aura.target_type = TargetType.new(TargetType.CREEPS)
	aura.target_self = false
	aura.level = 0
	aura.level_add = 1
	aura.aura_effect = melt_bt
	
	return [aura]


func melt_bt_on_create(event: Event):
	var buff: Buff = event.get_buff()
	var caster: Unit = buff.get_caster()
	var target: Unit = buff.get_buffed_unit()
	var lvl: int = caster.get_level()
	var current_mod_armor: float = _stats.mod_armor + _stats.mod_armor_add * lvl
	var current_melt_damage: float = _stats.melt_damage + _stats.melt_damage_add * lvl
	buff.user_real = current_mod_armor
	buff.user_real2 = current_melt_damage
	target.modify_property(Modification.Type.MOD_ARMOR, -current_mod_armor)


func melt_bt_on_periodic(event: Event):
	var buff: Buff = event.get_buff()
	var caster: Unit = buff.get_caster()
	var target: Unit = buff.get_buffed_unit()
	var lvl: int = caster.get_level()
	var mod_armor_increase: float = _stats.periodic_mod_armor + _stats.periodic_mod_armor_add * lvl
	var melt_damage_increase: float = _stats.melt_damage + _stats.melt_damage_add * lvl
	var old_mod_armor: float = buff.user_real
	var current_mod_armor: float = buff.user_real + mod_armor_increase
	var current_melt_damage: float = buff.user_real2 + melt_damage_increase
	buff.user_real = current_mod_armor
	buff.user_real2 = current_melt_damage

	caster.do_spell_damage(target, current_melt_damage, caster.calc_spell_crit_no_bonus())
	target.modify_property(Modification.Type.MOD_ARMOR, old_mod_armor)
	target.modify_property(Modification.Type.MOD_ARMOR, -current_mod_armor)


func melt_bt_on_cleanup(event: Event):
	var buff: Buff = event.get_buff()
	var target: Unit = buff.get_buffed_unit()
	var current_mod_armor: float = buff.user_real
	target.modify_property(Modification.Type.MOD_ARMOR, current_mod_armor)
