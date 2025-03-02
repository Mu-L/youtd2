extends ItemBehavior


var grace_bt: BuffType


func item_init():
	grace_bt = BuffType.create_aura_effect_type("grace_bt", true, self)
	grace_bt.set_buff_icon("res://resources/icons/generic_icons/angel_wings.tres")
	grace_bt.set_buff_tooltip(tr("I4A3"))
	var mod: Modifier = Modifier.new()
	mod.add_modification(Modification.Type.MOD_EXP_RECEIVED, 0.1, 0.004)
	grace_bt.set_buff_modifier(mod)

	var aura: AuraType = AuraType.new()
	aura.target_type = TargetType.new(TargetType.TOWERS)
	aura.aura_effect = grace_bt
	aura.target_self = true
	aura.level = 0
	aura.level_add = 1
	aura.aura_range = 150

	item.add_aura(aura)
