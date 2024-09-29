extends ItemBehavior


func get_ability_description() -> String:
	var text: String = ""

	text += "[color=GOLD]Vampiric Absorption[/color]\n"
	text += "The skull's carrier restores 7% of its maximum mana whenever it kills a creep.\n"

	return text


func load_triggers(triggers: BuffType):
	triggers.add_event_on_kill(on_kill)


func on_kill(_event: Event):
	var tower: Tower = item.get_carrier()
	tower.add_mana_perc(0.07)
	var effect: int = Effect.create_simple_at_unit("res://src/effects/replenish_mana.tscn", tower)
	Effect.set_color(effect, Color.RED)
