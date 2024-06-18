class_name CreepDart extends BuffType


# TODO: original game implemented darting by making the
# creep "jump" forward along the path instantly. For now,
# this special is implemented as a speedup instead.


var creep_darting: BuffType
var creep_tired: BuffType


func _init(parent: Node):
	super("creep_dart", 0, 0, true, parent)

	add_event_on_damaged(on_damaged)

	var modifier: Modifier = Modifier.new()
	modifier.add_modification(Modification.Type.MOD_MOVESPEED, -0.60, 0.0)
	set_buff_modifier(modifier)

	creep_darting = BuffType.new("creep_darting", 2.0, 0, false, self
		)
	var darting_modifier: Modifier = Modifier.new()
	darting_modifier.add_modification(Modification.Type.MOD_MOVESPEED, 3.00, 0.0)
	creep_darting.set_buff_modifier(darting_modifier)
	creep_darting.set_buff_icon("res://resources/icons/generic_icons/fire_dash.tres")
	creep_darting.set_buff_icon_color(Color.LIGHT_BLUE)
	creep_darting.set_buff_tooltip("Darting\nIncreases movement speed.")
	creep_darting.add_event_on_cleanup(on_darting_cleanup)

	creep_tired = BuffType.new("creep_tired", 4.0, 0, false, self
		)
	creep_tired.set_buff_icon("res://resources/icons/generic_icons/animal_skull.tres")
	creep_tired.set_buff_icon_color(Color.LIGHT_BLUE)
	creep_tired.set_buff_tooltip("Tired\nCan't dart for some time.")


func on_damaged(event: Event):
	var buff: Buff = event.get_buff()
	var creep: Unit = buff.get_buffed_unit()

	if !creep.calc_chance(0.05):
		return

	var active_darting: Buff = creep.get_buff_of_type(creep_darting)
	var active_tired: Buff = creep.get_buff_of_type(creep_tired)

	if active_darting == null && active_tired == null:
		creep_darting.apply(creep, creep, 0)



func on_darting_cleanup(event: Event):
	var buff: Buff = event.get_buff()
	var creep: Unit = buff.get_buffed_unit()

	creep_tired.apply(creep, creep, 0)
