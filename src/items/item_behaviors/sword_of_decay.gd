extends ItemBehavior


var rot_bt: BuffType


func get_ability_description() -> String:
	var nature_string: String = CreepCategory.convert_to_colored_string(CreepCategory.enm.NATURE)

	var text: String = ""

	text += "[color=GOLD]Rot - Aura[/color]\n"
	text += "Grants 12%% bonus damage against %s to all towers within 200 range.\n" % nature_string
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+0.24% damage\n"

	return text


func item_init():
	rot_bt = BuffType.create_aura_effect_type("rot_bt", true, self)
	rot_bt.set_buff_icon("res://resources/icons/generic_icons/poison_gas.tres")
	rot_bt.set_buff_tooltip("Rot\nIncreases damage dealt to Nature.")
	var mod: Modifier = Modifier.new()
	mod.add_modification(Modification.Type.MOD_DMG_TO_NATURE, 0.12, 0.0024)
	rot_bt.set_buff_modifier(mod)

	var aura: AuraType = AuraType.new()
	aura.aura_range = 200
	aura.target_type = TargetType.new(TargetType.TOWERS)
	aura.target_self = true
	aura.level = 0
	aura.level_add = 1
	aura.aura_effect = rot_bt
	item.add_aura(aura)
