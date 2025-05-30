extends ItemBehavior


# NOTE: [ORIGINAL_GAME_DEVIATION] original script
# implemented miss effect via "attack" event. Not sure how
# that's supposed to work because setting event.damage to 0
# in attack event should have no effect. At least it has no
# effect in the godot engine, so I changed to this script to
# use "damage" event. Maybe it does work in JASS engine that
# way, need to test this item in original game and change
# how attack event is handled in godot engine if needed.


func load_triggers(triggers: BuffType):
	triggers.add_event_on_damage(on_damage)


func on_damage(event: Event):
	var tower: Unit = item.get_carrier()

	if !tower.calc_chance(0.90):
		CombatLog.log_item_ability(item, null, "Miss")

		event.damage = 0
		var miss_text: String = tr("FLOATING_TEXT_MISS")
		tower.get_player().display_floating_text_x(miss_text, tower, Color8(255, 0, 0, 255), 0.05, 0.0, 2.0)
