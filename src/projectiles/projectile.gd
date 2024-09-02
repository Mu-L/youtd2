class_name Projectile
extends DummyUnit


# Projectile are moving objects which have an origin and can
# be setup to move towards a point or unit. The most common
# use case is to fire a projectile from a tower towards a
# creep to deal damage.

enum MoveType {
	NORMAL,
	INTERPOLATED,
}


const FALLBACK_PROJECTILE_VISUAL: String = "res://src/projectiles/projectile_visuals/default_projectile.tscn"
const PRINT_SPRITE_NOT_FOUND_ERROR: bool = false
const LIGHTNING_VISUAL_LIFETIME: float = 0.5
# NOTE: same value is used in original game. It roughly
# results in a position at the vertical center of
# towers/creeps.
const UNIT_Z_OFFSET: Vector3 = Vector3(0, 0, 60)

var _move_type: MoveType
var _target_unit: Unit = null
var _target_pos: Vector3 = Vector3.INF
var _interpolation_is_stopped: bool = false
var _interpolation_start: Vector3
var _interpolation_progress: float = 0
var _interpolation_z_arc_height: float = 0
var _bezier_is_enabled: bool = false
var _bezier_control_1: Vector3 = Vector3.ZERO
var _bezier_control_2: Vector3 = Vector3.ZERO
var _is_homing: bool = false
var _ignore_target_z: bool = false
var _homing_control_value: float
var _speed: float = 50
var _physics_z_speed: float = 0
var _acceleration: float = 0
var _rotation: float = 0
var _gravity: float
var _explode_on_hit: bool = true
var _explode_on_expiration: bool = true
var _initial_scale: Vector2
var _tower_crit_count: int = 0
var _tower_crit_ratio: float = 0.0
var _tower_bounce_visited_list: Array[Unit] = []
var _interpolation_finished_handler: Callable = Callable()
var _target_hit_handler: Callable = Callable()
var _periodic_handler: Callable = Callable()
var _impact_handler: Callable = Callable()
var _avert_destruct_requested: bool = false
var _initial_pos: Vector3
var _range: float = 0.0
var _direction: float = 0.0
var _collision_radius: float = 0.0
var _collision_target_type: TargetType = null
var _destroy_on_collision: bool = false
var _collision_handler: Callable = Callable()
var _expiration_handler: Callable = Callable()
var _collision_history: Array[Unit] = []
var _collision_enabled: bool = true
var _periodic_enabled: bool = true
var _physics_enabled: bool = true
var _periodic_timer: ManualTimer = null
var _spawn_time: float
var _visual_path: String
var _use_lightning_visual: bool

var user_int: int = 0
var user_int2: int = 0
var user_int3: int = 0
var user_real: float = 0.0
var user_real2: float = 0.0
var user_real3: float = 0.0


@export var _lifetime_timer: ManualTimer
@export var _visual_node: Node2D


#########################
###     Built-in      ###
#########################

func _ready():
	super()

	_initial_scale = scale
	_spawn_time = Utils.get_time()

	var visual_exists: bool = ResourceLoader.exists(_visual_path)
	if !visual_exists:
		if PRINT_SPRITE_NOT_FOUND_ERROR:
			print_debug("Failed to find sprite for projectile. Tried at path:", _visual_path)

		_visual_path = FALLBACK_PROJECTILE_VISUAL

	var visual_scene: PackedScene = load(_visual_path)
	var visual: Node2D = visual_scene.instantiate()
	_visual_node.add_child(visual)


#########################
###       Public      ###
#########################

func update(delta: float):
	if _target_unit != null:
		_target_pos = _target_unit.get_position_wc3() + UNIT_Z_OFFSET

	match _move_type:
		MoveType.NORMAL: _update_normal(delta)
		MoveType.INTERPOLATED: _update_interpolated(delta)


func set_position_wc3(value: Vector3):
	super(value)

	_visual_node.position.y = -value.z


func avert_destruction():
	_avert_destruct_requested = true


# NOTE: aimAtUnit() in JASS
func aim_at_unit(target_unit: Unit, targeted: bool, ignore_z: bool, expire_when_reached: bool):
	if targeted:
		set_homing_target(target_unit)
	else:
		set_homing_target(null)

	var target_pos: Vector3 = target_unit.get_position_wc3() + UNIT_Z_OFFSET
	_start_movement_normal(target_pos, ignore_z, expire_when_reached)


# NOTE: aimAtPoint() in JASS
func aim_at_point(target_pos: Vector3, ignore_z: bool, expire_when_reached: bool):
	_start_movement_normal(target_pos, ignore_z, expire_when_reached)


func stop_interpolation():
	_interpolation_is_stopped = true
	set_homing_target(null)
	_interpolation_progress = 0


func start_interpolation_to_point(target_pos: Vector3, z_arc: float):
	set_homing_target(null)
	_start_movement_interpolated(target_pos, z_arc)

	if _use_lightning_visual:
		_visual_node.hide()
		
		var lightning: InterpolatedSprite = InterpolatedSprite.create_from_point_to_point(InterpolatedSprite.LIGHTNING, get_position_wc3(), target_pos)
		_setup_lightning_visual(lightning)


func start_interpolation_to_unit(target_unit: Unit, z_arc: float, targeted: bool):
	if targeted:
		set_homing_target(target_unit)
	else:
		set_homing_target(null)

	var target_pos: Vector3 = target_unit.get_position_wc3() + UNIT_Z_OFFSET
	_start_movement_interpolated(target_pos, z_arc)

	if _use_lightning_visual:
		_visual_node.hide()

		var lightning: InterpolatedSprite = InterpolatedSprite.create_from_point_to_unit(InterpolatedSprite.LIGHTNING, get_position_wc3(), target_unit)
		_setup_lightning_visual(lightning)


func start_bezier_interpolation_to_point(target_pos: Vector3, z_arc: float, side_arc: float, steepness: float):
	set_homing_target(null)
	_start_movement_bezier_interpolated(target_pos, z_arc, side_arc, steepness)

	if _use_lightning_visual:
		_visual_node.hide()

		var lightning: InterpolatedSprite = InterpolatedSprite.create_from_point_to_point(InterpolatedSprite.LIGHTNING, get_position_wc3(), target_pos)
		_setup_lightning_visual(lightning)


func start_bezier_interpolation_to_unit(target_unit: Unit, z_arc: float, side_arc: float, steepness: float, targeted: bool):
	if targeted:
		set_homing_target(target_unit)
	else:
		set_homing_target(null)

	var target_pos: Vector3 = target_unit.get_position_wc3() + UNIT_Z_OFFSET
	_start_movement_bezier_interpolated(target_pos, z_arc, side_arc, steepness)

	if _use_lightning_visual:
		_visual_node.hide()

		var lightning: InterpolatedSprite = InterpolatedSprite.create_from_point_to_unit(InterpolatedSprite.LIGHTNING, get_position_wc3(), target_unit)
		_setup_lightning_visual(lightning)


# NOTE: disablePeriodic() in JASS
func disable_periodic():
	_periodic_enabled = false


# NOTE: enablePeriodic() in JASS
func enable_periodic(time: float):
	_periodic_enabled = true

	if _periodic_timer != null:
		_periodic_timer.wait_time = time


# NOTE: setCollisionParameters() in JASS
func set_collision_parameters(radius: float, target_type: TargetType):
	_collision_radius = radius
	_collision_target_type = target_type


#########################
###      Private      ###
#########################

func _setup_lightning_visual(lightning: InterpolatedSprite):
	var caster_element: Element.enm = _caster.get_element()
	var caster_element_color: Color = Element.get_color(caster_element)
	lightning.modulate = caster_element_color
	lightning.set_lifetime(LIGHTNING_VISUAL_LIFETIME)


func _update_normal(delta: float):
	if _collision_enabled:
		var destroyed_by_collision: bool = _collide_with_units()

		if destroyed_by_collision:
			return

	if _range > 0:
		var travel_vector: Vector2 = get_position_wc3_2d() - VectorUtils.vector3_to_vector2(_initial_pos)
		var current_travel_distance: float = travel_vector.length()
		var travel_complete: bool = current_travel_distance >= _range

		if travel_complete:
			_expire()

			return

	if _is_homing:
		_turn_towards_target(delta)
		
# 	Apply rotation
	var new_direction: float = _direction + _rotation
	set_direction(new_direction)

# 	Apply acceleration
	var new_speed: float = _speed + _acceleration * delta
	set_speed(new_speed)

#	Move forward, based on current direction
	var move_vector: Vector2 = (Vector2(1, 0) * _speed * delta).rotated(deg_to_rad(_direction))
	var new_position_2d: Vector2 = get_position_wc3_2d() + move_vector
	set_position_wc3_2d(new_position_2d)
	
#	Change z coordinate
#	NOTE: derive speed for changing z from angle of travel
#	vector. This way, target z will be reached roughly at
#	the same time as target x and y.
	var current_position: Vector3 = get_position_wc3()
	var target_pos_is_defined: bool = _target_pos != Vector3.INF
	var should_update_z_to_match_target_z: bool = target_pos_is_defined && !_ignore_target_z

	if _physics_enabled:
		_physics_z_speed = clampf(_physics_z_speed - _gravity, -Constants.PROJECTILE_SPEED_MAX, Constants.PROJECTILE_SPEED_MAX)

		var new_z: float = clampf(get_z() + _physics_z_speed, 0, 10000)
		set_z(new_z)

		var reached_ground: bool = new_z == 0

		if reached_ground:
			if _impact_handler.is_valid():
				_impact_handler.call(self)

			_cleanup()

			return
	elif should_update_z_to_match_target_z:
		var travel_vector: Vector3 = _target_pos - current_position
		var travel_vector_flat: Vector3 = Vector3(travel_vector.x, travel_vector.y, 0)
		var travel_angle_z: float = travel_vector.angle_to(travel_vector_flat)
		var z_speed: float = get_speed() * sin(travel_angle_z)
		var new_z: float = move_toward(get_z(), _target_pos.z, z_speed * delta)
		set_z(new_z)

	if _is_homing:
#		NOTE: contact distance prevents projectiles from
#		going past the target position during a tick and
#		rubber-banding.
# 
		var contact_distance: float = delta * _speed
		var target_pos_2d: Vector2 = VectorUtils.vector3_to_vector2(_target_pos)
		var reached_target = VectorUtils.in_range(target_pos_2d, get_position_wc3_2d(), contact_distance)

		if reached_target:
#			NOTE: finished handler will get called even if
#			target unit is dead and null. This is
#			intentional.
			if _target_hit_handler.is_valid():
				_target_hit_handler.call(self, _target_unit)

#			Handler can request projectile to not destroy
#			itself. In that case do no explosion or cleanup.
			if _avert_destruct_requested:
				_avert_destruct_requested = false

				return

			if _explode_on_hit:
				_do_explosion_visual()

			_cleanup()


func _update_interpolated(delta: float):
	if _collision_enabled:
		var destroyed_by_collision: bool = _collide_with_units()

		if destroyed_by_collision:
			return

	if _interpolation_is_stopped:
		return

	_interpolation_progress += _speed * delta

	var travel_vector: Vector3 = _target_pos - _interpolation_start
	var travel_vector_2d: Vector2 = VectorUtils.vector3_to_vector2(travel_vector)
	var travel_distance: float = travel_vector_2d.length()
	var progress_ratio: float = Utils.divide_safe(_interpolation_progress, travel_distance, 1.0)
	progress_ratio = clampf(progress_ratio, 0.0, 1.0)
	var old_position_2d: Vector2 = get_position_wc3_2d()
		
	var new_pos: Vector3
	if _bezier_is_enabled:
		new_pos = _interpolation_start.bezier_interpolate(_bezier_control_1, _bezier_control_2, _target_pos, progress_ratio)
	else:
		new_pos = _interpolation_start.lerp(_target_pos, progress_ratio)
		var z_arc_value: float = _interpolation_z_arc_height * progress_ratio * (1 - progress_ratio) * 4
		new_pos.z += z_arc_value

	set_position_wc3(new_pos)

#	NOTE: save direction so it can be accessed by users of
#	projectile via get_direction(). Note that unlike normal
#	projectiles, interpolated projectiles don't actually use
#	direction for movement logic.
	var new_pos_2d: Vector2 = get_position_wc3_2d()
	var move_vector: Vector2 = new_pos_2d - old_position_2d
	_direction = rad_to_deg(move_vector.angle())

	var reached_target: float = progress_ratio == 1.0

	if reached_target:
#		NOTE: need to set _interpolation_is_stopped flag to
#		true here so that we can detect if it got changed by
#		the "finished" handler
		_interpolation_is_stopped = true

#		NOTE: finished handler will get called even if
#		target unit is dead and null. This is intentional.
		if _interpolation_finished_handler.is_valid():
			_interpolation_finished_handler.call(self, _target_unit)

#		Handler can request projectile to not destroy
#		itself. In that case do no explosion or cleanup.
		if _avert_destruct_requested:
			_avert_destruct_requested = false

#			NOTE: only stop interpolation here if
#			_interpolation_is_stopped is still true. If it
#			is false, then it got changed by the code inside
#			"finished" handler, which happens when
#			"finished" handler starts a new interpolation
#			after averting destruction.
			if _interpolation_is_stopped:
				stop_interpolation()

			return

		if _explode_on_hit:
			_do_explosion_visual()

		_cleanup()


# Returns true if projectile expired because of a collision
func _collide_with_units() -> bool:
	var units_in_range: Array[Unit] = Utils.get_units_in_range(_collision_target_type, get_position_wc3_2d(), _collision_radius)

# 	Remove units that have already collided. This way, we
# 	collide only once per unit.
	for unit in _collision_history:
		if !Utils.unit_is_valid(unit):
			continue

		units_in_range.erase(unit)

	var collided_list: Array = units_in_range

	for unit in collided_list:
		if _collision_handler.is_valid():
			_collision_handler.call(self, unit)

		_collision_history.append(unit)

		if _destroy_on_collision:
			_cleanup()

			return true

	return false


# Homing behavior is implemented here. If target pos or
# target unit is defined, the projectile will turn to face
# towards it.
func _turn_towards_target(delta: float):
	var turn_instantly: float = _homing_control_value == 0
	var target_pos_2d: Vector2 = VectorUtils.vector3_to_vector2(_target_pos)
	var projectile_pos: Vector2 = get_position_wc3_2d()
	var desired_direction_vector: Vector2 = target_pos_2d - projectile_pos
	var desired_direction: float = rad_to_deg(desired_direction_vector.angle())

	if turn_instantly:
		set_direction(desired_direction)

		return

	var current_direction_vector: Vector2 = Vector2.from_angle(deg_to_rad(_direction))
	var direction_diff: float = rad_to_deg(current_direction_vector.angle_to(desired_direction_vector))
	var turn_amount: float = sign(direction_diff) * min(rad_to_deg(_homing_control_value) * delta, abs(direction_diff))
	var new_direction: float = _direction + turn_amount
	
	set_direction(new_direction)


func _expire():
	if _expiration_handler.is_valid():
		_expiration_handler.call(self)

	if _explode_on_expiration:
		_do_explosion_visual()

	_cleanup()


# NOTE: angle should be in degrees. Normalizes the angle to
# [-180, 180] range to match convention used by Vector2
# functions. For example, 220 would be converted to -140.
func _normalize_angle(angle: float) -> float:
	var normalized_angle: float
	if angle > 180:
		normalized_angle = angle - 360
	elif angle < -180:
		normalized_angle = angle + 360
	else:
		normalized_angle = angle

	return normalized_angle


func _start_movement_normal(target_pos: Vector3, ignore_z: bool, expire_when_reached: bool):
	_target_pos = target_pos
	_ignore_target_z = ignore_z

	var target_pos_2d: Vector2 = VectorUtils.vector3_to_vector2(_target_pos)
	var from_pos_2d: Vector2 = get_position_wc3_2d()
	var angle_to_target_pos: float = from_pos_2d.angle_to_point(target_pos_2d)
	var initial_direction: float = rad_to_deg(angle_to_target_pos)
	set_direction(initial_direction)

	if expire_when_reached:
		var travel_vector: Vector2 = target_pos_2d - from_pos_2d
		var travel_distance: float = travel_vector.length()
		var time_until_reached: float = Utils.divide_safe(travel_distance, get_speed(), 1.0)
		set_remaining_lifetime(time_until_reached)


# NOTE: before this f-n is called, projectile must be added
# to world and have a valid position
func _start_movement_interpolated(target_pos: Vector3, z_arc: float):
	_target_pos = target_pos

	var from_pos: Vector3 = get_position_wc3()
	_interpolation_start = from_pos
	_interpolation_progress = 0
	_interpolation_is_stopped = false

	var travel_vector: Vector3 = _target_pos - from_pos
	var travel_distance: float = travel_vector.length()
	_interpolation_z_arc_height = travel_distance * z_arc


func _start_movement_bezier_interpolated(target_pos: Vector3, z_arc: float, side_arc: float, steepness: float):
	_target_pos = target_pos

	var from_pos: Vector3 = get_position_wc3()
	_interpolation_start = from_pos
	_interpolation_progress = 0
	_interpolation_is_stopped = false
	_bezier_is_enabled = true

	var travel_vector: Vector3 = _target_pos - from_pos
	var travel_distance: float = travel_vector.length()

	var dx: float = _target_pos.x - from_pos.x
	var dy: float = _target_pos.y - from_pos.y
	var dz: float = _target_pos.z - from_pos.z

	var control1_ratio: float = 0.5 - steepness
	_bezier_control_1.x = from_pos.x + control1_ratio * dx + side_arc * dy 
	_bezier_control_1.y = from_pos.y + control1_ratio * dy + side_arc * dx 
	_bezier_control_1.z = from_pos.z + control1_ratio * dz + z_arc * travel_distance 

	var control2_ratio: float = 0.5 + steepness
	_bezier_control_2.x = from_pos.x + control2_ratio * dx + side_arc * dy 
	_bezier_control_2.y = from_pos.y + control2_ratio * dy + side_arc * dx 
	_bezier_control_2.z = from_pos.z + control2_ratio * dz + z_arc * travel_distance 


func _do_explosion_visual():
	# NOTE: if projectile is hidden, also don't display
	# explosion visual
	if !visible:
		return

	var explosion = Preloads.explosion_scene.instantiate()
	var projectile_pos: Vector3 = get_position_wc3()
	var projectile_pos_canvas: Vector2 = VectorUtils.wc3_to_canvas(projectile_pos)
	explosion.position = projectile_pos_canvas
	Utils.add_object_to_world(explosion)


#########################
###     Callbacks     ###
#########################

func _on_periodic_timer_timeout():
	if !_periodic_enabled:
		return

	if _periodic_handler.is_valid():
		_periodic_handler.call(self)


func _on_target_tree_exited():
	if _target_unit == null:
		return

	_target_pos = _target_unit.get_position_wc3() + UNIT_Z_OFFSET
	_target_unit.tree_exited.disconnect(_on_target_tree_exited)
	_target_unit = null


func _on_projectile_type_tree_exited():
	_cleanup()


func _on_lifetime_timer_timeout():
	_expire()


#########################
### Setters / Getters ###
#########################

# NOTE: getHomingTarget() in JASS
func get_target() -> Unit:
	return _target_unit


# NOTE: projectile.setScale() in JASS
func set_projectile_scale(value: float):
	_visual_node.scale = Vector2.ONE * value


func get_tower_crit_count() -> int:
	return _tower_crit_count


func set_tower_crit_count(tower_crit_count: int):
	_tower_crit_count = tower_crit_count


func get_tower_crit_ratio() -> float:
	return _tower_crit_ratio


func set_tower_crit_ratio(tower_crit_ratio: float):
	_tower_crit_ratio = tower_crit_ratio


func get_tower_bounce_visited_list() -> Array[Unit]:
	return _tower_bounce_visited_list


# Returns current direction of projectile's movement. In
# degrees and from top down perspective.
# NOTE: projectile.direction in JASS
func get_direction() -> float:
	return _direction


# Sets direction of projectile. In degrees and top down
# perspective.
# NOTE: this f-n must be used instead of modifying the value
# directly. This is to ensure that direction is always
# normalized.
func set_direction(direction: float):
	_direction = _normalize_angle(direction)


func get_speed() -> float:
	return _speed


func set_speed(new_speed: float):
	_speed = clampf(new_speed, 0, Constants.PROJECTILE_SPEED_MAX)


func set_acceleration(new_acceleration: float):
	_acceleration = new_acceleration


# Changes the rate of change of projectile's rotation.
# This value is defined in degrees/tick, 30ticks/second.
func set_projectile_rotation(value: float):
	_rotation = value


func set_gravity(value: float):
	_gravity = value


# NOTE: if new target is null, then homing is disabled
func set_homing_target(new_target: Unit):
	var old_target: Unit = _target_unit

	if Utils.unit_is_valid(old_target) && old_target.tree_exited.is_connected(_on_target_tree_exited):
		old_target.tree_exited.disconnect(_on_target_tree_exited)

	if new_target != null:
#		NOTE: need to check that target is valid because
#		projectile may be launched towards a dead target.
#		For example if some other part of tower script
#		killed the target right before projectile was
#		created. In such cases, projectile will move to the
#		position where target was during death.
		if Utils.unit_is_valid(new_target):
			if !new_target.tree_exited.is_connected(_on_target_tree_exited):
				new_target.tree_exited.connect(_on_target_tree_exited)

			_target_unit = new_target
		else:
			_target_unit = null
			_target_pos = new_target.get_position_wc3() + UNIT_Z_OFFSET

		_is_homing = true
	else:
		_target_unit = null
		_target_pos = Vector3.ZERO
		_is_homing = false


# NOTE: setCollisionEnabled() in JASS
func set_collision_enabled(enabled: bool):
	_collision_enabled = enabled


func set_remaining_lifetime(new_lifetime: float):
	if is_inside_tree():
		_lifetime_timer.stop()
		_lifetime_timer.start(new_lifetime)
	else:
		_lifetime_timer.autostart = true
		_lifetime_timer.wait_time = new_lifetime


func set_color(color: Color):
	modulate = color


# Returns time in seconds passed since projectile spawned.
func get_age() -> float:
	var current_time: float = Utils.get_time()
	var age: float = current_time - _spawn_time

	return age


#########################
###       Static      ###
#########################

# NOTE: Projectile.createFromUnit() in JASS
static func create_from_unit(type: ProjectileType, caster: Unit, from: Unit, facing: float, damage_ratio: float, crit_ratio: float) -> Projectile:
	var pos: Vector3 = from.get_position_wc3() + UNIT_Z_OFFSET
	var projectile: Projectile = Projectile.create(type, caster, damage_ratio, crit_ratio, pos, facing)
	
	return projectile


# NOTE: Projectile.createFromPointToPoint() in JASS
static func create_from_point_to_point(type: ProjectileType, caster: Unit, damage_ratio: float, crit_ratio: float, from_pos: Vector3, target_pos: Vector3, ignore_target_z: bool, expire_when_reached: bool) -> Projectile:
	var projectile: Projectile = Projectile.create(type, caster, damage_ratio, crit_ratio, from_pos, 0)
	projectile.aim_at_point(target_pos, ignore_target_z, expire_when_reached)

	return projectile


# NOTE: Projectile.createFromUnitToPoint() in JASS
static func create_from_unit_to_point(type: ProjectileType, caster: Unit, damage_ratio: float, crit_ratio: float, from_unit: Unit, target_pos: Vector3, ignore_target_z: bool, expire_when_reached: bool) -> Projectile:
	var from_pos: Vector3 = from_unit.get_position_wc3() + UNIT_Z_OFFSET
	var projectile: Projectile = Projectile.create(type, caster, damage_ratio, crit_ratio, from_pos, 0)
	projectile.aim_at_point(target_pos, ignore_target_z, expire_when_reached)

	return projectile


# NOTE: Projectile.createFromPointToUnit() in JASS
static func create_from_point_to_unit(type: ProjectileType, caster: Unit, damage_ratio: float, crit_ratio: float, from_pos: Vector3, target_unit: Unit, targeted: bool, ignore_target_z: bool, expire_when_reached: bool) -> Projectile:
	var projectile: Projectile = Projectile.create(type, caster, damage_ratio, crit_ratio, from_pos, 0)
	projectile.aim_at_unit(target_unit, targeted, ignore_target_z, expire_when_reached)

	return projectile


# NOTE: Projectile.createFromUnitToUnit() in JASS
static func create_from_unit_to_unit(type: ProjectileType, caster: Unit, damage_ratio: float, crit_ratio: float, from_unit: Unit, target_unit: Unit, targeted: bool, ignore_target_z: bool, expire_when_reached: bool) -> Projectile:
	var from_pos: Vector3 = from_unit.get_position_wc3() + UNIT_Z_OFFSET
	var projectile: Projectile = Projectile.create(type, caster, damage_ratio, crit_ratio, from_pos, 0)
	projectile.aim_at_unit(target_unit, targeted, ignore_target_z, expire_when_reached)

	return projectile


# NOTE: Projectile.createLinearInterpolationFromPointToPoint() in JASS
static func create_linear_interpolation_from_point_to_point(type: ProjectileType, caster: Unit, damage_ratio: float, crit_ratio: float, from_pos: Vector3, target_pos: Vector3, z_arc: float) -> Projectile:
	var projectile: Projectile = Projectile.create(type, caster, damage_ratio, crit_ratio, from_pos, 0)
	projectile.start_interpolation_to_point(target_pos, z_arc)

	return projectile


# NOTE: Projectile.createLinearInterpolationFromPointToUnit() in JASS
static func create_linear_interpolation_from_point_to_unit(type: ProjectileType, caster: Unit, damage_ratio: float, crit_ratio: float, from_pos: Vector3, target_unit: Unit, z_arc: float, targeted: bool) -> Projectile:
	var projectile: Projectile = Projectile.create(type, caster, damage_ratio, crit_ratio, from_pos, 0)
	projectile.start_interpolation_to_unit(target_unit, z_arc, targeted)

	return projectile


# NOTE: Projectile.createLinearInterpolationFromUnitToPoint() in JASS
static func create_linear_interpolation_from_unit_to_point(type: ProjectileType, caster: Unit, damage_ratio: float, crit_ratio: float, from_unit: Unit, target_pos: Vector3, z_arc: float) -> Projectile:
	var from_pos: Vector3 = from_unit.get_position_wc3() + UNIT_Z_OFFSET
	var projectile: Projectile = Projectile.create(type, caster, damage_ratio, crit_ratio, from_pos, 0)
	projectile.start_interpolation_to_point(target_pos, z_arc)

	return projectile


# NOTE: Projectile.createLinearInterpolationFromUnitToUnit() in JASS
static func create_linear_interpolation_from_unit_to_unit(type: ProjectileType, caster: Unit, damage_ratio: float, crit_ratio: float, from_unit: Unit, target_unit: Unit, z_arc: float, targeted: bool) -> Projectile:
	var from_pos: Vector3 = from_unit.get_position_wc3() + UNIT_Z_OFFSET
	var projectile: Projectile = Projectile.create(type, caster, damage_ratio, crit_ratio, from_pos, 0)
	projectile.start_interpolation_to_unit(target_unit, z_arc, targeted)

	return projectile


# NOTE: Projectile.createBezierInterpolationFromUnitToUnit() in JASS
static func create_bezier_interpolation_from_unit_to_unit(type: ProjectileType, caster: Unit, damage_ratio: float, crit_ratio: float, from_unit: Unit, target_unit: Unit, z_arc: float, side_arc: float, steepness: float, targeted: bool) -> Projectile:
	var from_pos: Vector3 = from_unit.get_position_wc3() + UNIT_Z_OFFSET
	var projectile: Projectile = Projectile.create(type, caster, damage_ratio, crit_ratio, from_pos, 0)
	projectile.start_bezier_interpolation_to_unit(target_unit, z_arc, side_arc, steepness, targeted)

	return projectile


# NOTE: Projectile.createBezierInterpolationFromUnitToPoint() in JASS
static func create_bezier_interpolation_from_unit_to_point(type: ProjectileType, caster: Unit, damage_ratio: float, crit_ratio: float, from_unit: Unit, target_pos: Vector3, z_arc: float, side_arc: float, steepness: float) -> Projectile:
	var from_pos: Vector3 = from_unit.get_position_wc3() + UNIT_Z_OFFSET
	var projectile: Projectile = Projectile.create(type, caster, damage_ratio, crit_ratio, from_pos, 0)
	projectile.start_bezier_interpolation_to_point(target_pos, z_arc, side_arc, steepness)

	return projectile


# NOTE: Projectile.create() in JASS
static func create(type: ProjectileType, caster: Unit, damage_ratio: float, crit_ratio: float, initial_pos: Vector3, facing: float) -> Projectile:
	var projectile: Projectile = Preloads.projectile_scene.instantiate()

	projectile.set_speed(type._speed)
	projectile._acceleration = type._acceleration
	projectile._rotation = type._start_rotation
	projectile._gravity = type._gravity
	projectile._physics_z_speed = type._initial_z_speed
	projectile._physics_enabled = type._physics_enabled
	projectile._explode_on_hit = type._explode_on_hit
	projectile._explode_on_expiration = type._explode_on_expiration
	projectile._move_type = type._move_type
	projectile._homing_control_value = type._homing_control_value

	projectile._cleanup_handler = type._cleanup_handler
	projectile._interpolation_finished_handler = type._interpolation_finished_handler
	projectile._target_hit_handler = type._target_hit_handler
	projectile._collision_handler = type._collision_handler
	projectile._expiration_handler = type._expiration_handler
	projectile._impact_handler = type._impact_handler
	projectile._range = type._range
	projectile._collision_radius = type._collision_radius
	projectile._collision_target_type = type._collision_target_type
	projectile._destroy_on_collision = type._destroy_on_collision
	projectile._damage_bonus_to_size_map = type._damage_bonus_to_size_map
	projectile._use_lightning_visual = type._use_lightning_visual

	var periodic_handler_is_defined: bool = type._periodic_handler.is_valid() && type._periodic_handler_period > 0
	if periodic_handler_is_defined:
		projectile._periodic_handler = type._periodic_handler
		var timer: ManualTimer = ManualTimer.new()
		projectile._periodic_timer = timer
		timer.wait_time = type._periodic_handler_period
		timer.autostart = true
		timer.timeout.connect(projectile._on_periodic_timer_timeout)
		projectile.add_child(timer)

	projectile._damage_ratio = damage_ratio
	projectile._crit_ratio = crit_ratio
	projectile._caster = caster
	projectile.set_position_wc3(initial_pos)
	projectile._initial_pos = initial_pos
	projectile._visual_path = type._visual_path

	projectile.set_direction(facing)

	if type._lifetime > 0:
		projectile.set_remaining_lifetime(type._lifetime)

	type.tree_exited.connect(projectile._on_projectile_type_tree_exited)

	Utils.add_object_to_world(projectile)

	return projectile
