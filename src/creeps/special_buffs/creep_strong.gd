class_name CreepStrong extends BuffType


func _init(parent: Node):
	super("creep_strong", 0, 0, true, parent)
	var modifier: Modifier = Modifier.new()
	modifier.add_modification(ModificationType.enm.MOD_EXP_GRANTED, 0.50, 0.0)
	modifier.add_modification(ModificationType.enm.MOD_BOUNTY_GRANTED, 0.25, 0.0)
	set_buff_modifier(modifier)
