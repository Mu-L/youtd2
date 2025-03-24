class_name CbSilence
extends BuffType

# NOTE: globally available cb_silence in JASS


# NOTE: BuffType.createDuplicate(cb_silence...) in JASS
func _init(type: String, time_base: float, time_level_add: float,friendly: bool, parent: Node):
	super(type, time_base, time_level_add, friendly, parent)
	add_event_on_create(on_create)
	add_event_on_cleanup(_on_cleanup)

	set_buff_icon("res://resources/icons/generic_icons/beard.tres")
	set_buff_tooltip(tr("TCH4"))


func on_create(event: Event):
	var buff: Buff = event.get_buff()
	var target = buff.get_buffed_unit()

	target.add_silence()


func _on_cleanup(event: Event):
	var buff: Buff = event.get_buff()
	var target = buff.get_buffed_unit()

	target.remove_silence()
