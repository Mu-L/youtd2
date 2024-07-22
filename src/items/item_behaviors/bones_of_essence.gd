extends ItemBehavior


func get_ability_description() -> String:
	var sif_string: String = ArmorType.convert_to_colored_string(ArmorType.enm.SIF)

	var text: String = ""

	text += "[color=GOLD]Bones of Essence[/color]\n"
	text += "Increases attack damage against creeps with %s armor by 25%%.\n" % sif_string

	return text


func load_triggers(triggers: BuffType):
	triggers.add_event_on_damage(on_damage)


func on_damage(event: Event):
	var target: Creep = event.get_target()

	if target.get_armor_type() == ArmorType.enm.SIF:
		event.damage = event.damage * 1.25
		SFX.sfx_on_unit(SfxPaths.TOWER_ATTACK_MAP[Element.enm.DARKNESS], target, Unit.BodyPart.CHEST)
