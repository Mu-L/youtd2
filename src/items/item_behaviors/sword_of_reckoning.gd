extends ItemBehavior


var holy_wrath_bt: BuffType


func get_ability_description() -> String:
	var undead_string: String = CreepCategory.convert_to_colored_string(CreepCategory.enm.UNDEAD)
	
	var text: String = ""

	text += "[color=GOLD]Holy Wrath - Aura[/color]\n"
	text += "Grants 12%% bonus damage against %s to all towers within 200 range.\n" % undead_string
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+0.24% damage\n"

	return text


func item_init():
	holy_wrath_bt = BuffType.create_aura_effect_type("holy_wrath_bt", true, self)
	holy_wrath_bt.set_buff_icon("res://resources/icons/generic_icons/mighty_force.tres")
	holy_wrath_bt.set_buff_tooltip("Holy Wrath\nIncreases damage dealt to Undead.")
	var mod: Modifier = Modifier.new()
	mod.add_modification(Modification.Type.MOD_DMG_TO_UNDEAD, 0.12, 0.0024)
	holy_wrath_bt.set_buff_modifier(mod)

	var aura: AuraType = AuraType.new()
	aura.aura_range = 200
	aura.target_type = TargetType.new(TargetType.TOWERS)
	aura.target_self = true
	aura.level = 0
	aura.level_add = 1
	aura.aura_effect = holy_wrath_bt
	item.add_aura(aura)
