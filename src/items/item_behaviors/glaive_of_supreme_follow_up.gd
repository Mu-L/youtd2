extends ItemBehavior


# NOTE: original script uses buff.userInt as a flag so that
# attack() f-n does nothing the first time it is called and
# does something the second time it is called. This is to
# solve some issue which exists in original script engine.
# In current engine this is not needed and causes a bug
# where follow up attack to happen twice. So it was removed.


var followup_bt: BuffType


func get_ability_description() -> String:
	var text: String = ""

	text += "[color=GOLD]Follow Up[/color]\n"
	text += "Whenever this tower attacks, it has a 10% chance to gain 300% attack speed until next attack. The next attack will crit for sure but deals 50% less crit damage.\n"
	text += "\n"
	text += "[color=GOLD]Level Bonus:[/color]\n"
	text += "+0.4% chance\n"
	text += "+4% attack speed\n"
	text += "+1% crit damage\n"

	return text


func load_triggers(triggers: BuffType):
	triggers.add_event_on_attack(on_attack)


# NOTE: attack() in original
func followup_bt_on_attack(event: Event):
	var B: Buff = event.get_buff()
	var t: Tower = B.get_buffed_unit()

	t.add_modified_attack_crit(0.00, 0.5 + t.get_level() / 100.0)
	B.remove_buff()


func item_init():
	followup_bt = BuffType.new("followup_bt", 30, 0, true, self)
	followup_bt.set_buff_icon("res://resources/icons/generic_icons/hammer_drop.tres")
	followup_bt.set_buff_tooltip("Follow Up\nNext attack will be faster and will always be critical.")
	followup_bt.add_event_on_attack(followup_bt_on_attack)
	var mod: Modifier = Modifier.new()
	mod.add_modification(Modification.Type.MOD_ATTACKSPEED, 3.0, 0.04)
	followup_bt.set_buff_modifier(mod)


func on_attack(_event: Event):
	var tower: Tower = item.get_carrier()

	if !tower.calc_chance(0.1 + 0.004 * tower.get_level()):
		return

	CombatLog.log_item_ability(item, null, "Follow up")

	followup_bt.apply(item.get_carrier(), item.get_carrier(), item.get_carrier().get_level())
