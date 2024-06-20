extends ItemBehavior


var grenade_pt: ProjectileType


func get_ability_description() -> String:
	var undead_string: String = CreepCategory.convert_to_colored_string(CreepCategory.enm.UNDEAD)

	var text: String = ""

	text += "[color=GOLD]Big Badaboom[/color]\n"
	text += "Whenever the carrier hits the main target, it has a 15%% chance to launch a holy missile which deals 75%% of the damage the last attack dealt as spell damage in 400 AoE around the main target. Deals 50%% more damage against %s.\n" % undead_string
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+1% damage\n"

	return text


func load_triggers(triggers: BuffType):
	triggers.add_event_on_damage(on_damage)


# NOTE: hit() in original script
func grenade_pt_on_hit(P: Projectile, U: Unit):
	if U == null:
		return

	var e: int
	var C: Tower = P.get_caster()

	C.do_spell_damage_aoe_unit(U, 400, P.user_real, C.calc_spell_crit_no_bonus(), 0)
	e = Effect.create_scaled("FaerieDragonMissile.mdl", Vector3(U.get_x(), U.get_y(), 8), 0, 5)
	Effect.set_lifetime(e, 0.01)


func item_init():
	grenade_pt = ProjectileType.create("GoldBottleMissile.mdl", 50.0, 1000.0, self)
	grenade_pt.enable_homing(grenade_pt_on_hit, 0.0)


func on_damage(event: Event):
	var tower: Tower = item.get_carrier()
	var chance: float = 0.15
	var r: float = event.damage * (0.75 + 0.01 * tower.get_level())
	var P: Projectile
	var target: Creep = event.get_target()

	if !tower.calc_chance(chance):
		return

	if event.is_main_target():
		CombatLog.log_item_ability(item, null, "Big Badaboom")
		
		if target.get_category() == CreepCategory.enm.UNDEAD:
			r = r * 1.5

		P = Projectile.create_from_unit_to_unit(grenade_pt, tower, 1.0, tower.calc_spell_crit_no_bonus(), tower, event.get_target(), true, false, false)
		P.user_real = r
