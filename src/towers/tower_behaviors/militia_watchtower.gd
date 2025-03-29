extends TowerBehavior


var axe_pt: ProjectileType


func get_tier_stats() -> Dictionary:
	return {
		1: {miss_chance_add = 0.01},
		2: {miss_chance_add = 0.011},
		3: {miss_chance_add = 0.011},
		4: {miss_chance_add = 0.012},
	}


func load_triggers(triggers: BuffType):
	triggers.add_event_on_damage(on_damage)
	triggers.add_event_on_attack(on_attack)


func axe_pt_hit(_p: Projectile, target: Unit):
	if target == null:
		return

	if tower.calc_bad_chance(0.33 - _stats.miss_chance_add * tower.get_level()):
		tower.get_player().display_floating_text_x(tr("FLOATING_TEXT_MISS"), tower, Color8(255, 0, 0, 255), 0.05, 0.0, 2.0)
	else:
		tower.do_attack_damage(target, tower.get_current_attack_damage_with_bonus(), tower.calc_attack_multicrit_no_bonus())


func tower_init():
	axe_pt = ProjectileType.create_interpolate("path_to_projectile_sprite", 800, self)
	axe_pt.set_event_on_interpolation_finished(axe_pt_hit)


func on_attack(event: Event):
	var attacks: int = 2
	var add: bool = false
	var maintarget: Unit = event.get_target()
	var target: Unit
	var it: Iterate = Iterate.over_units_in_range_of_unit(tower, TargetType.new(TargetType.CREEPS), maintarget, 450)
	var sidearc: float = 0.20
	var it_destroyed: bool = false

	if tower.get_level() >= 15:
		attacks = attacks + 1

	if tower.get_level() >= 25:
		attacks = attacks + 1

	while true:
#		Exit when all attacks are fired
		if attacks == 0:
			return

#		If the Iterate is not destroyed, get the next target
		if !it_destroyed:
			target = it.next()

#			If there are no more targets
			if target == null:
#				Iterate is destroyed (auto destroy)
				it_destroyed = true
#				target is the maintarget now
				target = maintarget

#		If there are no more units, shoot at the maintarget
#		(itDestroyed). If there are units then don't shoot
#		at the maintarget
		if it_destroyed || target != maintarget:
			Projectile.create_bezier_interpolation_from_unit_to_unit(axe_pt, tower, 0, 0, tower, target, 0, sidearc, 0, true).set_projectile_scale(0.40)
			attacks = attacks - 1
			sidearc = -sidearc

			if add:
				sidearc = sidearc + 0.020

			add = !add


func on_damage(event: Event):
	if tower.calc_bad_chance(0.33 - _stats.miss_chance_add * tower.get_level()):
		event.damage = 0
		tower.get_player().display_floating_text_x(tr("FLOATING_TEXT_MISS"), tower, Color8(255, 0, 0, 255), 0.05, 0.0, 2.0)


func on_create(_preceding_tower: Tower):
# 	Save the family member (1 = first member)
	tower.user_int = tower.get_tier()
# 	Used to save the buff (double linked list)
	tower.user_int2 = 0
