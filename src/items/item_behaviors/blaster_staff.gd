extends ItemBehavior


var staff_pt: ProjectileType


func load_triggers(triggers: BuffType):
	triggers.add_periodic_event(periodic, 1.0)


# NOTE: Collision() in original script
func staff_pt_on_hit(P: Projectile, targ: Unit):
	if targ == null:
		return

	P.get_caster().do_spell_damage(targ, 60.00, P.get_caster().calc_spell_crit_no_bonus()) 


func item_init():
	staff_pt = ProjectileType.create("path_to_projectile_sprite", 4.00, 1400.00, self)
	staff_pt.enable_homing(staff_pt_on_hit, 0.0)


func periodic(_event: Event):
	var U: Unit = item.get_carrier()
	var I: Iterate = Iterate.over_units_in_range_of_unit(U, TargetType.new(TargetType.CREEPS), U, 1000.0)
	var T: Unit = I.next()

	if T != null:
		Projectile.create_from_unit_to_unit(staff_pt, U, 1.00, U.calc_spell_crit_no_bonus(), U, T, true, false, false)
