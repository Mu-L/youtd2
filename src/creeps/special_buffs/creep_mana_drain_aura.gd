class_name CreepManaDrainAura extends BuffType


var slow_aura_effect: BuffType


func _init(parent: Node):
	super("creep_mana_drain_aura", 0, 0, true, parent)

	slow_aura_effect = BuffType.create_aura_effect_type("creep_slow_aura_effect", false, self)
	var modifier: Modifier = Modifier.new()
	modifier.add_modification(Modification.Type.MOD_MANA_REGEN_PERC, -2.0, 0.0)
	slow_aura_effect.set_buff_modifier(modifier)
	slow_aura_effect.set_buff_tooltip("Drain Gang\nDrains mana and reduces mana regeneration.")

	var aura: AuraType = AuraType.new()
	aura.level = 0
	aura.level_add = 0
	aura.target_type = TargetType.new(TargetType.TOWERS)
	aura.aura_effect = slow_aura_effect
	aura.target_self = false
	aura.aura_range = 1200

	add_aura(aura)
