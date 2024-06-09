extends TowerBehavior


var aura_bt: BuffType


func get_tier_stats() -> Dictionary:
	return {
		1: {aura_range = 800, mod_armor = 10, mod_armor_add = 0.3, vuln = 0.10, vuln_add = 0.003},
		2: {aura_range = 1100, mod_armor = 15, mod_armor_add = 0.5, vuln = 0.15, vuln_add = 0.005},
	}


func load_specials(_modifier: Modifier):
	tower.set_attack_style_splash({
		50: 1.0,
		350: 0.4,
		})


func tower_init():
	aura_bt = BuffType.create_aura_effect_type("aura_bt", false, self)
	var mod: Modifier = Modifier.new()
	mod.add_modification(Modification.Type.MOD_ARMOR, -_stats.mod_armor, -_stats.mod_armor_add)
	mod.add_modification(Modification.Type.MOD_DMG_FROM_ASTRAL, _stats.vuln, _stats.vuln_add)
	mod.add_modification(Modification.Type.MOD_DMG_FROM_NATURE, _stats.vuln, _stats.vuln_add)
	mod.add_modification(Modification.Type.MOD_DMG_FROM_FIRE, _stats.vuln, _stats.vuln_add)
	mod.add_modification(Modification.Type.MOD_DMG_FROM_IRON, _stats.vuln, _stats.vuln_add)
	aura_bt.set_buff_modifier(mod)
	aura_bt.set_buff_icon("res://resources/icons/generic_icons/angel_wings.tres")
	aura_bt.set_buff_tooltip("Sunshine Aura\nReduces armor and increases damage taken from Astral, Fire, Iron and Nature towers.")


func get_aura_types() -> Array[AuraType]:
	var aura: AuraType = AuraType.new()

	var mod_armor: String = Utils.format_float(_stats.mod_armor, 2)
	var mod_armor_add: String = Utils.format_float(_stats.mod_armor_add, 2)
	var vuln: String = Utils.format_percent(_stats.vuln, 2)
	var vuln_add: String = Utils.format_percent(_stats.vuln_add, 2)

	var astral_string: String = Element.convert_to_colored_string(Element.enm.ASTRAL)
	var fire_string: String = Element.convert_to_colored_string(Element.enm.FIRE)
	var iron_string: String = Element.convert_to_colored_string(Element.enm.IRON)
	var nature_string: String = Element.convert_to_colored_string(Element.enm.NATURE)

	aura.name = "Sunshine"
	aura.icon = "res://resources/icons/staves/wand_glowing.tres"
	aura.description_short = "Reduces the armor of creeps in range and makes them more vulnerable to damage from %s, %s, %s and %s towers.\n" % [astral_string, fire_string, iron_string, nature_string]
	aura.description_full = "Reduces the armor of creeps in %d range by %s and increases the vulnerability to damage from %s, %s, %s and %s towers by %s.\n" % [_stats.aura_range, mod_armor, astral_string, fire_string, iron_string, nature_string, vuln] \
	+ " \n" \
	+ "[color=ORANGE]Level Bonus:[/color]\n" \
	+ "+%s armor reduction\n" % mod_armor_add \
	+ "+%s vulnerability\n" % vuln_add

	aura.aura_range = _stats.aura_range
	aura.target_type = TargetType.new(TargetType.CREEPS)
	aura.target_self = false
	aura.level = 0
	aura.level_add = 1
	aura.aura_effect = aura_bt
	return [aura]
