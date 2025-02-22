extends ItemBehavior


var charitable_bt: BuffType


func load_modifier(modifier: Modifier):
	modifier.add_modification(Modification.Type.MOD_DAMAGE_ADD_PERC, -0.20, 0.0)
	modifier.add_modification(Modification.Type.MOD_SPELL_DAMAGE_DEALT, -0.20, 0.0)


func item_init():
	charitable_bt = BuffType.create_aura_effect_type("charitable_bt", true, self)
	charitable_bt.set_buff_icon("res://resources/icons/generic_icons/shiny_omega.tres")
	charitable_bt.set_buff_tooltip(tr("FCP1"))
	var mod: Modifier = Modifier.new()
	mod.add_modification(Modification.Type.MOD_TRIGGER_CHANCES, 0.02, 0.004)
	mod.add_modification(Modification.Type.MOD_MANA_PERC, 0.02, 0.004)
	mod.add_modification(Modification.Type.MOD_SPELL_DAMAGE_DEALT, 0.02, 0.004)
	charitable_bt.set_buff_modifier(mod)

	var aura_type: AuraType = AuraType.new()
	aura_type.aura_range = 300
	aura_type.target_type = TargetType.new(TargetType.TOWERS)
	aura_type.target_self = true
	aura_type.level = 0
	aura_type.level_add = 1
	aura_type.aura_effect = charitable_bt
	item.add_aura(aura_type)
