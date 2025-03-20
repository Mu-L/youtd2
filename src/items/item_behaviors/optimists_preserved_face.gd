extends ItemBehavior


func load_triggers(triggers: BuffType):
	triggers.add_event_on_damage(on_damage)


func on_damage(event: Event):
	var target: Unit = event.get_target()
	var health_ratio: float = target.get_health() / target.get_overall_health()
	event.damage = event.damage * (1.75 - (1.25 * (1 - health_ratio)))
