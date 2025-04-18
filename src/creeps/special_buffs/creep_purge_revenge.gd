class_name CreepPurgeRevenge extends BuffType


var slow_attack: BuffType


func _init(parent: Node):
	super("creep_purge_revenge", 0, 0, true, parent)

	add_event_on_damaged(on_damaged)

	slow_attack = BuffType.new("creep_slow_attack", 4.0, 0.0, false, self)
	var modifier: Modifier = Modifier.new()
	modifier.add_modification(ModificationType.enm.MOD_ATTACKSPEED, -1.5, 0.0)
	slow_attack.set_buff_modifier(modifier)
	slow_attack.set_buff_icon("res://resources/icons/generic_icons/animal_skull.tres")
	slow_attack.set_buff_icon_color(Color.DARK_RED)
	slow_attack.set_buff_tooltip(tr("N3BA"))
	slow_attack.set_special_effect("res://src/effects/purge_buff_target.tscn", 50, 1.0, Color(Color.GREEN, 0.75))


func on_damaged(event: Event):
	var buff: Buff = event.get_buff()
	var creep: Unit = buff.get_buffed_unit()
	var attacker: Unit = event.get_target()
	var creep_is_silenced: bool = creep.is_silenced()

	if creep_is_silenced:
		return

	if !creep.calc_chance(0.15):
		return

	for i in range(0, 2):
		attacker.purge_buff(true)
	
	slow_attack.apply(creep, attacker, 1)

	SFX.sfx_at_unit(SfxPaths.MAGIC_CONFUSE, attacker)
	
