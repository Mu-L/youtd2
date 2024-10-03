extends ItemBehavior


# NOTE: [ORIGINAL_GAME_DEVIATION] Renamed
# "Mini Furbolg"=>"Mini Forest Troll"


var rampage_bt: BuffType


func get_ability_description() -> String:
	var text: String = ""

	text += "[color=GOLD]Rampage[/color]\n"
	text += "Whenever the carrier attacks, it has a 14% attack speed adjusted chance to go into a [color=GOLD]Rampage[/color]. [color=GOLD]Rampage[/color] increases carrier's attack speed by 25%, multicrit count by 1, crit damage by x0.40 and crit chance by 5% for 4 seconds. Can't retrigger during while active.\n"
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+0.08 seconds duration\n"
	text += "+0.4% attack speed\n"

	return text


func load_triggers(triggers: BuffType):
	triggers.add_event_on_attack(on_attack)


func item_init():
	rampage_bt = BuffType.new("rampage_bt", 4, 0, true, self)
	rampage_bt.set_buff_icon("res://resources/icons/generic_icons/mighty_force.tres")
	rampage_bt.set_buff_tooltip("Rampage\nIncreases attack speed, multicrit, critical damage and critical chance.")
	var mod: Modifier = Modifier.new() 
	mod.add_modification(Modification.Type.MOD_MULTICRIT_COUNT, 1.00, 0.0) 
	mod.add_modification(Modification.Type.MOD_ATTACKSPEED, 0.25, 0.0) 
	mod.add_modification(Modification.Type.MOD_ATK_CRIT_CHANCE, 0.05, 0.0) 
	mod.add_modification(Modification.Type.MOD_ATK_CRIT_DAMAGE, 0.40, 0.0) 
	rampage_bt.set_buff_modifier(mod) 


func on_attack(_event: Event):
	var tower: Tower = item.get_carrier()

	if !(tower.get_buff_of_type(rampage_bt) != null) && tower.calc_chance(0.14 * tower.get_base_attack_speed()):
		CombatLog.log_item_ability(item, null, "Rampage")
		rampage_bt.apply(tower, tower, tower.get_level())
