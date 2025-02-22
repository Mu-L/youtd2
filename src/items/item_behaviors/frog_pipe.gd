extends ItemBehavior

# NOTE: in original script, collision range was defined by
# calling setCollisionParameters. Removed that because it's
# not needed. Can define when set_collision_enabled() is
# called.

# NOTE: I modified the coloring of projectiles. Set initial
# color to blue and then when projectile starts homing make
# it bluer. Original script uses a green frog model which
# turns blueish later.


var frog_pt: ProjectileType


func load_triggers(triggers: BuffType):
	triggers.add_event_on_attack(on_attack)


# NOTE: deem_FrogAttack() in original script
func daem_frog_attack(tower: Tower, target: Unit, temp: int):
	var x: float = tower.get_x()
	var y: float = tower.get_y()

	var angle: float = rad_to_deg(atan2(target.get_y() - y, target.get_x() - x))

	var p: Projectile = Projectile.create(frog_pt, tower, 0, 0, Vector3(x + Globals.synced_rng.randi_range(-40, 40), y + Globals.synced_rng.randi_range(-40, 40), 5.0), angle + temp)
	p.set_color(Color8(100, 255, 100, 255))
	p.user_int = temp
	p.user_real = tower.get_current_attack_damage_with_bonus()
	p.user_real2 = tower.calc_attack_multicrit_no_bonus()


# NOTE: deem_FrogCollision() in original script
func frog_pt_on_hit(p: Projectile, target: Unit):
	if target == null:
		return

	var tower: Tower = p.get_caster()
	tower.do_attack_damage(target, p.user_real, p.user_real2)


func item_init():
	frog_pt = ProjectileType.create_ranged("path_to_projectile_sprite", 3700.0, 500.0, self)
	frog_pt.enable_collision(frog_pt_on_collision, 190, TargetType.new(TargetType.CREEPS), false)
	frog_pt.enable_homing(frog_pt_on_hit, 0)
	frog_pt.enable_periodic(frog_pt_periodic, 0.60)
	frog_pt.set_acceleration(-36)
	frog_pt.disable_explode_on_hit()


func on_attack(event: Event):
	var tower: Tower = item.get_carrier()
	var target: Unit = event.get_target()
	var frog_chance: float = 0.2

	if !tower.calc_chance(frog_chance):
		return

	if target.get_size() != CreepSize.enm.AIR:
		CombatLog.log_ability(tower, target, "Frog Piper")
		
		daem_frog_attack(item.get_carrier(), target, Globals.synced_rng.randi_range(-40, -20))
		daem_frog_attack(item.get_carrier(), target, Globals.synced_rng.randi_range(-20, -0))
		daem_frog_attack(item.get_carrier(), target, Globals.synced_rng.randi_range(0, 20))
		daem_frog_attack(item.get_carrier(), target, Globals.synced_rng.randi_range(20, 40))


# NOTE: deem_FrogHome() in original script
func frog_pt_on_collision(p: Projectile, target: Unit):
	if target.get_size() == CreepSize.enm.AIR:
		return

	p.set_speed(500)
	p.set_collision_enabled(false)
	p.set_homing_target(target)
	p.set_acceleration(8)
	p.set_color(Color8(100, 220, 150, 255))
	p.disable_periodic()
	p.set_remaining_lifetime(3.0)


# NOTE: deem_FrogPeriodic() in original script
func frog_pt_periodic(projectile: Projectile):
	projectile.user_int *= -1
	projectile.set_speed(500)
	projectile.set_direction(projectile.get_direction() + projectile.user_int)
