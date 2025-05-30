class_name Creep
extends Unit


signal moved(delta)


const HEIGHT_TWEEN_FAST_FORWARD_DELTA: float = 100.0

# NOTE: need to limit size of selection visual so that creep
# selection visual doesn't clip into floor2 tiles.
const MAX_SELECTION_VISUAL_SIZE: float = 120.0

const slow_run_animations: Array[String] = ["slow_run_E", "slow_run_S", "slow_run_W", "slow_run_N"]
const fly_animations: Array[String] = ["fly_E", "fly_SE", "fly_S", "fly_SW", "fly_W", "fly_NW", "fly_N", "fly_NE"]
const death_animations: Array[String] = ["death_E", "death_S", "death_W", "death_N"]


var _path: Path2D
var _size: CreepSize.enm
var _category: CreepCategory.enm
var _armor_type: ArmorType.enm
var _current_path_index: int = 0
var _facing_angle: float = 0.0
var _spawn_level: int
var _special_list: Array[int] = []
var _target_height: float = 0.0
var _height_change_speed: float = 0.0
var _portal_damage_multiplier: float = 1.0


# NOTE: need to use @onready for these variables instead of
# @export because export vars cause null errors in HTML5
# build, for some reason.
@onready var _visual = $Visual
@onready var _sprite: AnimatedSprite2D = $Visual/SpriteParent/Sprite
@onready var _health_bar = $Visual/HealthBar
@onready var _selection_area: Area2D = $Visual/SelectionArea
@onready var _sprite_parent: Node2D = $Visual/SpriteParent


#########################
###     Built-in      ###
#########################

func _ready():
	super()

	GroupManager.add("creeps", self, get_uid())
	
	var max_health = get_overall_health()
	_health_bar.set_max(max_health)
	_health_bar.set_min(0.0)
	_health_bar.set_value(max_health)
	health_changed.connect(_on_health_changed)

	if _size == CreepSize.enm.AIR:
		var air_creep_z: float = 2 * Constants.TILE_SIZE_WC3
		set_z(air_creep_z)
		_target_height = air_creep_z
	
	_setup_selection_signals(_selection_area)
	
	_set_visual_node(_visual)
	var outline_thickness: float = _get_outline_thickness()
	_setup_unit_sprite(_sprite, _sprite_parent, outline_thickness)

	var animation_for_dimensions: String
	if _size == CreepSize.enm.AIR:
		animation_for_dimensions = fly_animations[0]
	else:
		animation_for_dimensions = slow_run_animations[0]

	var sprite_dimensions: Vector2 = Utils.get_animated_sprite_dimensions(_sprite, animation_for_dimensions)
	_set_unit_dimensions(sprite_dimensions)

	var selection_size: float = min(sprite_dimensions.x, MAX_SELECTION_VISUAL_SIZE)
	_set_selection_size(selection_size)

	death.connect(_on_death)


func update(delta: float):
	super.update(delta)
	
	if !is_stunned():
		_move(delta)

#	NOTE: need to also play animation for outline, so it
#	matches sprite
	var creep_animation: String = _get_creep_animation()
	_sprite.play(creep_animation)
	var selection_outline: Node2D = get_selection_outline()
	selection_outline.play(creep_animation)

	var creep_move_speed: float = get_current_movespeed()
	var move_speed_ratio: float = creep_move_speed / Constants.DEFAULT_MOVE_SPEED
	_sprite.set_speed_scale(move_speed_ratio)
	selection_outline.set_speed_scale(move_speed_ratio)

	var current_z: float = get_z()

	if current_z != _target_height:
		var height_change: float = _height_change_speed * delta

		var new_z: float
		if current_z < _target_height:
			new_z = max(_target_height, current_z + height_change)
		else:
			new_z = min(_target_height, current_z - height_change)

		set_z(new_z)

	z_index = _calculate_current_z_index()


#########################
###       Public      ###
#########################

# NOTE: should be called once when creating the creep
func set_properties(path: Path2D, player: Player, size: CreepSize.enm, armor_type: ArmorType.enm, race, health: float, armor: float, level: int):
	set_player(player)
	_path = path
	_size = size
	_armor_type = armor_type
	_category = race
	set_base_health(health)
	set_health(health)
	set_base_armor(armor)
	_spawn_level = level


func set_portal_damage_multiplier(value: float):
	_portal_damage_multiplier = value


# Returns score which will be granted by Creep.
# Note that this value depends on creep health.
# NOTE: this function is *mostly* correct. Some multipliers
# may still be missing.
func get_score(difficulty: Difficulty.enm, game_length: int, game_mode: GameMode.enm) -> float:
	const difficulty_multiplier_map: Dictionary = {
		Difficulty.enm.BEGINNER: 1.0,
		Difficulty.enm.EASY: 2.0,
		Difficulty.enm.MEDIUM: 3.0,
		Difficulty.enm.HARD: 4.0,
		Difficulty.enm.EXTREME: 5.0,
	}
	var difficulty_multiplier: float = difficulty_multiplier_map[difficulty]

	const length_multiplier_map: Dictionary = {
		Constants.WAVE_COUNT_TRIAL: 1.0,
		Constants.WAVE_COUNT_FULL: 1.0,
		Constants.WAVE_COUNT_NEVERENDING: 0.9,
	}
	var length_multiplier: float = length_multiplier_map[game_length]

	const game_mode_multiplier_map: Dictionary = {
		GameMode.enm.BUILD: 0.9,
		GameMode.enm.RANDOM_WITH_UPGRADES: 1.0,
		GameMode.enm.TOTALLY_RANDOM: 1.35,
	}
	var game_mode_multiplier: float = game_mode_multiplier_map[game_mode]

	var settings_multiplier: float = difficulty_multiplier * length_multiplier * game_mode_multiplier

	var damage_done: float = get_damage_done()
	var size_multiplier: float = CreepSize.get_score_multiplier(_size)
	var score: float = damage_done * (_spawn_level / 8 + 1) * settings_multiplier * size_multiplier
	
	return score


func get_damage_to_portal() -> float:
#	NOTE: final wave boss deals full damage to portal
	var wave_count: int = Globals.get_wave_count()
	var is_final_wave: bool = _spawn_level == wave_count

	if is_final_wave:
		return 100.0

	var size_is_challenge: bool = CreepSize.is_challenge(_size)

	if size_is_challenge:
		return 0

	var damage_done: float = get_damage_done()

	var type_multiplier: float = CreepSize.get_portal_damage_multiplier(_size)

	var damage_done_power: float
	if _size == CreepSize.enm.BOSS:
		damage_done_power = 4
	else:
		damage_done_power = 5

	var damage_reduction_from_hp_ratio: float = (1 - pow(damage_done, damage_done_power))
	var damage_to_portal: float = 2.5 * type_multiplier * damage_reduction_from_hp_ratio * _portal_damage_multiplier

	var player: Player = get_player()
	var team: Team = player.get_team()
	var team_size: int = team.get_players().size()

	damage_to_portal = Utils.divide_safe(damage_to_portal, team_size, damage_to_portal)

	return damage_to_portal


# Creep moves to a point on path, which is closest to given
# point.
func move_to_point(point: Vector2):
	var curve: Curve2D = _path.curve

	var min_distance: float = 10000.0
	var min_index: int = -1
	var min_position: Vector2 = Vector2.ZERO
	var prev: Vector2 = Utils.get_path_point_wc3(_path, 0)

	for i in range(1, curve.point_count):
		var curr: Vector2 = Utils.get_path_point_wc3(_path, i)
		var closest_point: Vector2 = Geometry2D.get_closest_point_to_segment(point, prev, curr)
		var distance: float = closest_point.distance_to(point)

		if distance < min_distance:
			min_distance = distance
			min_index = i
			min_position = closest_point

		prev = curr

	if min_index == -1:
		return
	
	set_position_wc3_2d(min_position)
	_current_path_index = min_index


# NOTE: creep.adjustHeight() in JASS
# NOTE: can't use tween here because it causes desync.
func adjust_height(height: float, speed: float):
#	NOTE: can't create tween's while node is outside tree.
#	If creep is outside tree then it's okay to do nothing
#	because creep is about to get deleted anyway.
	if !is_inside_tree():
		return

	var creep_is_air: bool = get_size() == CreepSize.enm.AIR

#	NOTE: shouldn't change height of air creeps - it would
#	look weird
	if creep_is_air:
		return
	
	_target_height += height
	_height_change_speed = speed


# NOTE: creep.dropItem() in JASS

func drop_item(caster: Tower, use_creep_player: bool):
	var random_item: int = ItemDropCalc.get_random_item(caster, self)

	if random_item == 0:
		return

	drop_item_by_id(caster, use_creep_player, random_item)

	EventBus.item_dropped.emit()


func drop_item_by_id(caster: Tower, use_creep_player: bool, item_id: int):
	var player_for_item: Player
	if use_creep_player:
		player_for_item = get_player()
	else:
		player_for_item = caster.get_player()

	var item_position: Vector3 = get_position_wc3()
	var item: Item = Item.create(player_for_item, item_id, item_position)

	var item_name: String = ItemProperties.get_display_name(item_id)
	var item_rarity: Rarity.enm = ItemProperties.get_rarity(item_id)
	var rarity_color: Color = Rarity.get_color(item_rarity)

	player_for_item.display_floating_text(item_name, self, rarity_color)

	var autooil_tower: Tower = player_for_item.get_autooil_tower(item_id)
	var autooil_exists_for_this_item: bool = autooil_tower != null
	if autooil_exists_for_this_item:
		item.pickup(autooil_tower)
		
		var oil_name: String = item.get_display_name()
		var tower_name: String = autooil_tower.get_display_name()
		Messages.add_normal(player_for_item, tr("MESSAGE_AUTOOIL_APPLY").format({OIL_NAME = oil_name, TOWER_NAME = tower_name}))

		return
	else:
		item.fly_to_stash(0.0)


#########################
###      Private      ###
#########################

# NOTE: see explanation of z_index setup in map.gd
func _calculate_current_z_index() -> int:
	if get_z() > 1.5 * Constants.TILE_SIZE_WC3:
		if get_size() == CreepSize.enm.AIR:
			return 21
		else:
			return 20
	else:
		return 10


func _move(delta):
	var path_is_over: bool = _current_path_index >= _path.get_curve().get_point_count()
	if path_is_over:
		_deal_damage_to_portal()
		remove_from_game()

		return

	var path_point_wc3: Vector2 = Utils.get_path_point_wc3(_path, _current_path_index)
	var move_delta: float = get_current_movespeed() * delta
	var old_position_2d: Vector2 = get_position_wc3_2d()
	var new_position_2d: Vector2 = old_position_2d.move_toward(path_point_wc3, move_delta)
	set_position_wc3_2d(new_position_2d)

	moved.emit(delta)
	
	var reached_path_point: bool = (new_position_2d == path_point_wc3)
	
	if reached_path_point:
		_current_path_index += 1

	var new_facing_angle: float = _get_current_movement_angle()
	set_unit_facing(new_facing_angle)


func _deal_damage_to_portal():
	var damage_to_portal = get_damage_to_portal()
	var damage_to_portal_string: String = Utils.format_percent(damage_to_portal / 100, 1)
	var damage_done: float = get_damage_done()
	var damage_done_string: String = Utils.format_percent(damage_done, 2)
	var creep_size: CreepSize.enm = get_size_including_challenge_sizes()
	var creep_size_string: String = CreepSize.get_display_string(creep_size)
	var creep_score: float = get_score(Globals.get_difficulty(), Globals.get_wave_count(), Globals.get_game_mode())

	var player: Player = get_player()
	
	if creep_size == CreepSize.enm.BOSS:
		Messages.add_normal(player, tr("MESSAGE_DAMAGE_TO_BOSS").format({DAMAGE = damage_done_string}))
	else:
		Messages.add_normal(player, tr("MESSAGE_FAILED_TO_KILL").format({CREEP_SIZE = creep_size_string.to_upper()}))

	if damage_to_portal > 0:
		Messages.add_normal(player, tr("MESSAGE_LOSE_LIVES").format({LOST_LIVES = damage_to_portal_string}))

#	NOTE: creeps still give partial score if they are not
#	killed. Ratio depends on creep health.
	if creep_score > 0:
		player.add_score(creep_score)

	var team: Team = player.get_team()

	team.modify_lives(-damage_to_portal)
	team.play_portal_damage_sfx()

	var effect: int = Effect.create_simple_at_unit("res://src/effects/silence_area.tscn", self)
	Effect.set_color(effect, Color8(90, 180, 250))
	Effect.set_scale(effect, 1.5)

	EventBus.portal_received_damage.emit()


# Returns current movement angle, top down and in degrees
func _get_current_movement_angle() -> float:
	var path_curve: Curve2D = _path.get_curve()

	if _current_path_index >= path_curve.point_count:
		return _facing_angle

	var next_point: Vector2 = Utils.get_path_point_wc3(_path, _current_path_index)
	var facing_vector: Vector2 = next_point - get_position_wc3_2d()
	var facing_angle_radians: float = facing_vector.angle()
	var facing_angle_degrees: float = rad_to_deg(facing_angle_radians)

	return facing_angle_degrees


func _get_creep_animation() -> String:
	var animation_list: Array[String]
	
	if get_size() == CreepSize.enm.AIR:
		animation_list = fly_animations
	else:
		animation_list = slow_run_animations

	var animation: String = _get_animation_based_on_facing_angle(animation_list)

	return animation


func _get_death_animation() -> String:
	var animation: String = _get_animation_based_on_facing_angle(death_animations)

	return animation


func _get_animation_based_on_facing_angle(animation_order: Array[String]) -> String:
# 	NOTE: convert facing angle to animation index by
# 	breaking down the 360 degree space into sections. 4 for
# 	ground units and 8 for air units. Then we figure out
# 	which section does the facing angle belong to. The index
# 	of that section will be equal to the animation index.
	var facing_angle_top_down: float = _facing_angle
	var facing_angle_isometric: float = facing_angle_top_down - 45
	var section_count: int = animation_order.size()
	var section_angle: float = 360.0 / section_count
	var animation_index: int = roundi(facing_angle_isometric / section_angle)

	if animation_index >= animation_order.size():
		print_debug("animation_index out of bounds = ", animation_index)
		animation_index = 0

	var animation: String = animation_order[animation_index]

	return animation


# NOTE: different thickness is used for different sizes to
# account for differences in sprite scale.
func _get_outline_thickness() -> float:
	match get_size():
		CreepSize.enm.MASS: return 4.5
		CreepSize.enm.NORMAL: return 3.8
		CreepSize.enm.AIR: return 3.0
		CreepSize.enm.CHAMPION: return 2.8
		CreepSize.enm.BOSS: return 2.0
		CreepSize.enm.CHALLENGE_MASS: return 4.5
		CreepSize.enm.CHALLENGE_BOSS: return 2.0

	return 10.0


#########################
###     Callbacks     ###
#########################

func _on_health_changed():
	var health_ratio: float = get_health_ratio()
	_health_bar.ratio = health_ratio


func _on_death(_event: Event):
	var creep_score: float = get_score(Globals.get_difficulty(), Globals.get_wave_count(), Globals.get_game_mode())

	if creep_score > 0:
		var player: Player = get_player()
		player.add_score(creep_score)

# 	Death visual
	var effect_id: int = Effect.create_simple_at_unit("res://src/effects/death_explode.tscn", self)
	var effect_scale: float = max(_sprite_dimensions.x, _sprite_dimensions.y) / Constants.DEATH_EXPLODE_EFFECT_SIZE
	Effect.set_scale(effect_id, effect_scale)

# 	Add corpse object
	if _size != CreepSize.enm.AIR:
		var death_animation: String = _get_death_animation()
		var corpse: CreepCorpse = CreepCorpse.make(self, _sprite, death_animation)
		var corpse_pos: Vector3 = Vector3(get_x(), get_y(), 0)
		corpse.set_position_wc3(corpse_pos)
		Utils.add_object_to_world(corpse)

		var blood_pool: Node2D = Preloads.blood_pool_scene.instantiate()
		blood_pool.position = position
		Utils.add_object_to_world(blood_pool)


#########################
### Setters / Getters ###
#########################

# NOTE: creep.getBaseBountyValue() in JASS
func get_base_bounty_value() -> float:
	var creep_size: CreepSize.enm = get_size_including_challenge_sizes()
	var gold_multiplier: float = CreepSize.get_gold_multiplier(creep_size)
	var spawn_level: int = get_spawn_level()
	var bounty: float = gold_multiplier * (spawn_level / 8 + 1)

	return bounty


func get_log_name() -> String:
	var size_name: String = CreepSize.get_display_string(_size)
	var log_name: String = "%s-%d" % [size_name, get_uid()]

	return log_name


# NOTE: creeps are always considered to be in combat for the
# purposes of their autocasts.
func is_in_combat() -> bool:
	return true


func get_current_movespeed() -> float:
	var base: float = get_base_movespeed()
	var mod: float = get_prop_move_speed()
	var mod_absolute: float = get_prop_move_speed_absolute()
	var unclamped: float = (base + mod_absolute) * mod
	var move_speed: float = clampf(unclamped, Constants.MOVE_SPEED_MIN, Constants.MOVE_SPEED_MAX)

	return move_speed


# Sets unit facing to an angle with respect to the positive
# X axis, in degrees.
# NOTE: angle is top down
# 
# NOTE: SetUnitFacing() in JASS
func set_unit_facing(angle: float):
# 	NOTE: limit facing angle to (0, 360) range
	_facing_angle = int(angle + 360) % 360

	var animation: String = _get_creep_animation()
	if animation != "":
		_sprite.play(animation)
		var selection_outline: Node2D = get_selection_outline()
		selection_outline.play(animation)


# NOTE: angle is top down
# NOTE: GetUnitFacing() in JASS
func get_unit_facing() -> float:
	return _facing_angle

# NOTE: this special function forces CHALLENGE_MASS and
# CHALLENGE_BOSS to be treated as MASS and BOSS creeps. Use
# get_size_including_challenge_sizes() to get the "real"
# creep size.
func get_size() -> CreepSize.enm:
	if _size == CreepSize.enm.CHALLENGE_MASS:
		return CreepSize.enm.MASS
	elif _size == CreepSize.enm.CHALLENGE_BOSS:
		return CreepSize.enm.BOSS
	else:
		return _size

func get_size_including_challenge_sizes() -> CreepSize.enm:
	return _size

# NOTE: unit.getCategory() in JASS
func get_category() -> CreepCategory.enm:
	return _category

func get_armor_type() -> ArmorType.enm:
	return _armor_type

func get_display_name() -> String:
	return tr("CREEP_GENERIC_NAME")


func get_move_path() -> Path2D:
	return _path


func get_spawn_level() -> int:
	return _spawn_level


func get_special_list() -> Array[int]:
	return _special_list


func set_special_list(special_list: Array[int]):
	_special_list = special_list


func get_ability_button_data_list() -> Array[AbilityButton.Data]:
	var list: Array[AbilityButton.Data] = []

	var armor_type: ArmorType.enm = get_armor_type()
	var armor_type_name: String = ArmorType.get_display_string(armor_type)
	var armor_type_name_colored: String = ArmorType.convert_to_colored_string(armor_type)
	var armor_type_damage_taken: String = ArmorType.get_rich_text_for_damage_taken(armor_type)
	var armor_type_description: String = tr("CREEP_ARMOR_ABILITY_DESCRIPTION").format({ARMOR_TYPE = armor_type_name_colored, DAMAGE_FROM_TEXT = armor_type_damage_taken})
	var armor_type_ability: AbilityButton.Data = AbilityButton.Data.new()
	armor_type_ability.ability_name = tr("CREEP_ARMOR_ABILITY_TITLE").format({ARMOR_TYPE = armor_type_name})
	armor_type_ability.icon = "res://resources/icons/shields/shield_green.tres"
	armor_type_ability.description_long = armor_type_description
	list.append(armor_type_ability)

	for special in _special_list:
		var special_name: String = WaveSpecialProperties.get_special_name(special)
		var special_description: String = WaveSpecialProperties.get_description(special)
		var special_icon: String = WaveSpecialProperties.get_icon_path(special)

		var ability: AbilityButton.Data = AbilityButton.Data.new()
		ability.ability_name = special_name
		ability.icon = special_icon
		ability.description_long = special_description
		list.append(ability)

	return list
