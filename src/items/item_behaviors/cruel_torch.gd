extends ItemBehavior


var flames_bt: BuffType


func get_ability_description() -> String:
	var text: String = ""

	text += "[color=GOLD]Flames of Fury - Aura[/color]\n"
	text += "Increases crit chance of towers in 300 range by 3.5%.\n"
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+0.08% chance\n"

	return text


func item_init():
	flames_bt = BuffType.create_aura_effect_type("flames_bt", true, self)
	flames_bt.set_buff_icon("res://resources/icons/generic_icons/mighty_force.tres")
	flames_bt.set_buff_tooltip("Flames of Fury\nIncreases critical chance.")
	var mod: Modifier = Modifier.new()
	mod.add_modification(Modification.Type.MOD_ATK_CRIT_CHANCE, 0.035, 0.0008)
	flames_bt.set_buff_modifier(mod)

	var aura: AuraType = AuraType.new()
	aura.aura_range = 300
	aura.target_type = TargetType.new(TargetType.TOWERS)
	aura.target_self = true
	aura.level = 0
	aura.level_add = 1
	aura.aura_effect = flames_bt
	item.add_aura(aura)
