class_name Buff
extends Node2D


# Buff stores buff parameters and applies them to target
# while it is active.


var user_int: int = 0
var user_int2: int = 0
var user_int3: int = 0
var user_real: float = 0.0
var user_real2: float = 0.0
var user_real3: float = 0.0

var _caster: Unit
var _target: Unit
var _modifier: Modifier = Modifier.new()
var _level: int
var _time: float
var _friendly: bool
var _buff_type_name: String
var _stacking_group: String
var _timer: ManualTimer
# Map of Event.Type -> list of EventHandler's
var event_handler_map: Dictionary = {}
var _original_duration: float = 0.0
var _tooltip_text: String
var _buff_icon: String
var _buff_icon_color: Color
var _purgable: bool = true
var _cleanup_done: bool = false
var _periodic_timer_map: Dictionary = {}
var _is_hidden: bool
var _special_effect_id: int = 0
var _displayed_stacks: int = 0
# NOTE: these values are defined if the buff type was
# created inside a TowerBehavior script.
var _is_owned_by_tower: bool = false
var _tower_family: int = -1
var _tower_tier: int = -1


#########################
###     Built-in      ###
#########################

func _ready():
	_timer = ManualTimer.new()
	add_child(_timer)
	_timer.timeout.connect(_on_timer_timeout)
	
	if _time > 0.0:
		var buff_duration_mod: float = _caster.get_prop_buff_duration()
		var debuff_duration_mod: float = _target.get_prop_debuff_duration()

		var total_time: float = _time * buff_duration_mod

		if !_friendly:
			total_time *= debuff_duration_mod

		_timer.start(total_time)
		_original_duration = total_time
	else:
		_original_duration = _time

	_target.death.connect(_on_target_death)
	_target.kill.connect(_on_target_kill)
	_target.level_up.connect(_on_target_level_up)
	_target.attack.connect(_on_target_attack)
	_target.attacked.connect(_on_target_attacked)
	_target.dealt_damage.connect(_on_target_dealt_damage)
	_target.damaged.connect(_on_target_damaged)
	_target.spell_casted.connect(_on_target_spell_casted)
	_target.spell_targeted.connect(_on_target_spell_targeted)

	_target.tree_exited.connect(_on_target_tree_exited)
	_caster.tree_exited.connect(_on_caster_tree_exited)

	var create_event: Event = _make_buff_event(_target)
	_call_event_handler_list(Event.Type.CREATE, create_event)

	CombatLog.log_buff_apply(_caster, _target, self)


#########################
###       Public      ###
#########################

func get_is_owned_by_tower() -> bool:
	return _is_owned_by_tower


func get_tower_family() -> int:
	return _tower_family


func get_tower_tier() -> int:
	return _tower_tier


# NOTE: this is visual only, stack logic has to be
# implemented separately
func set_displayed_stacks(value: int):
	_displayed_stacks = value


func get_displayed_stacks() -> int:
	return _displayed_stacks


# NOTE: do not change remaining duration if original
# duration is negative because that means that the buff is
# permanent. Setting the duration would cause the buff to
# expire.
# NOTE: buff.refreshDuration() in JASS
func refresh_duration():
	if _original_duration < 0:
		return

	set_remaining_duration(_original_duration)


# NOTE: buff.removeBuff() in JASS
func remove_buff():
	if _cleanup_done:
		return

	var cleanup_event: Event = _make_buff_event(_target)
	_call_event_handler_list(Event.Type.CLEANUP, cleanup_event)

	if _special_effect_id != 0:
		Effect.destroy_effect(_special_effect_id)

	_target._remove_buff_internal(self)

	if is_inside_tree():
		_target.remove_child(self)
	queue_free()


# NOTE: buff.purgeBuff() in JASS
func purge_buff():
	var purge_event: Event = _make_buff_event(null)
	_call_event_handler_list(Event.Type.PURGE, purge_event)

	remove_buff()


func get_periodic_timers() -> Dictionary:
	return _periodic_timer_map.duplicate()


# Inherits periodic timers from a previous instance of this
# buff. Used by items to preserve timers of items when they
# are removed from towers.
func inherit_periodic_timers(inherited_timers: Dictionary):
	for handler in _periodic_timer_map.keys():
		if !inherited_timers.has(handler):
			continue
		
#		Remove existing timer
		var existing_timer: ManualTimer = _periodic_timer_map[handler]
		remove_child(existing_timer)
		existing_timer.queue_free()
		existing_timer.timeout.disconnect(_on_periodic_event_timer_timeout)

#		Replace with inherited timer
		var inherited_timer: ManualTimer = inherited_timers[handler]
		_periodic_timer_map[handler] = inherited_timer
		inherited_timer.timeout.connect(_on_periodic_event_timer_timeout.bind(handler, inherited_timer))
		inherited_timer.reparent(self)


#########################
###      Private      ###
#########################

func _add_event_handler(event_type: Event.Type, handler: Callable):
	if !event_handler_map.has(event_type):
		event_handler_map[event_type] = []

	event_handler_map[event_type].append(handler)


func _add_periodic_event(handler: Callable, period: float):
	var timer: ManualTimer = ManualTimer.new()
	timer.wait_time = period
	timer.one_shot = false
	timer.autostart = true
	_periodic_timer_map[handler] = timer
	timer.timeout.connect(_on_periodic_event_timer_timeout.bind(handler, timer))
	add_child(timer)


func _add_event_handler_unit_comes_in_range(handler: Callable, radius: float, target_type: TargetType):
	var buff_range_area: BuffRangeArea = BuffRangeArea.make(radius, target_type, handler, self)
	add_child(buff_range_area)

	buff_range_area.unit_came_in_range.connect(_on_unit_came_in_range)


func _call_event_handler_list(event_type: Event.Type, event: Event):
	if !_can_call_event_handlers():
		return

#	NOTE: we need to set the _cleanup_done flag in this
#	precise place.
#   - It has to be set after we call
#     _can_call_event_handlers() because
#     _can_call_event_handlers returns false if this flag is
#     set.
#	- It also has to be set before we call event handlers so
#	  that cleanup handler gets called once but then doesn't
#	  recurse into another cleanup handler. (yes, some
#	  cleanup handlers can trigger another cleanup event).
	if event_type == Event.Type.CLEANUP:
		_cleanup_done = true

	if !event_handler_map.has(event_type):
		return

	event._buff = self

	var handler_list: Array = event_handler_map[event_type]

	for handler in handler_list:
		handler.call(event)


# Convenience function to make an event with "_buff" variable set to self
func _make_buff_event(target_arg: Unit) -> Event:
	var event: Event = Event.new(target_arg)
	event._buff = self

	return event


func _refresh_by_new_buff():
	refresh_duration()

#	NOTE: refresh event is triggered only when refresh
#	is caused by an application of buff with same level.
#	Not triggered when refresh_duration() is called for
#	other reasons.
	_emit_refresh_event()



# NOTE: aura buffs need to emit EXPIRE event when they are
# removed from units, according to youtd engine docs. Some
# tower scripts rely on this behavior.
func _remove_as_aura():
	var expire_event: Event = _make_buff_event(_target)
	_call_event_handler_list(Event.Type.EXPIRE, expire_event)

	remove_buff()


func _emit_refresh_event():
	var refresh_event: Event = _make_buff_event(_target)
	_call_event_handler_list(Event.Type.REFRESH, refresh_event)


func _upgrade_by_new_buff(new_level: int):
	refresh_duration()
	
	set_level(new_level)

	var upgrade_event: Event = _make_buff_event(_target)
	_call_event_handler_list(Event.Type.UPGRADE, upgrade_event)


func _add_aura(aura_type: AuraType):
	var aura: Aura = aura_type.make(get_caster())
	add_child(aura)


# NOTE: when a buff is queued for deletion it means that the
# buff was removed from the target unit. If any other events
# are triggered in the same frame before the buff is
# deleted, the buff shouldn't respond to them.
func _can_call_event_handlers() -> bool:
	return !is_queued_for_deletion() && !_cleanup_done


func _change_giver_of_aura_effect(new_caster: Unit):
	var old_caster: Unit = _caster

	if old_caster == new_caster:
		return

	old_caster.tree_exited.disconnect(_on_caster_tree_exited)

	_caster = new_caster
	_caster.tree_exited.connect(_on_caster_tree_exited)


#########################
###     Callbacks     ###
#########################

func _on_unit_came_in_range(handler: Callable, unit: Unit):
	if !_can_call_event_handlers():
		return

	var range_event: Event = _make_buff_event(unit)

	handler.call(range_event)


func _on_timer_timeout():
	if _original_duration < 0:
		push_error("A permanent buff expired! This should never happen - something must be wrong. Ignoring expiry.")

		return

	var expire_event: Event = _make_buff_event(_target)
	_call_event_handler_list(Event.Type.EXPIRE, expire_event)

	remove_buff()


func _on_target_death(death_event: Event):
	death_event._buff = self
	_call_event_handler_list(Event.Type.DEATH, death_event)
	
	remove_buff()


# Explanation of all of the cases where buff needs to be
# removed due to a "tree_exited" signal:
# 
# 1. Buff needs to be removed when buff's target exits the
#    tree. Target is gone => buff is invalid.
# 
# 2. Buff needs to be removed when buff's caster exits the
#    tree. Caster is gone => event handlers are invalid =>
#    buff is invalid.
#
# 3. Buff needs to be removed when buff's BuffType exits the
#    tree. This case is necessary to correctly handle buffs
#    created by items. BuffType is gone => item is gone =>
#    event handlers are invalid => buff is invalid.


func _on_target_tree_exited():
	remove_buff()


func _on_caster_tree_exited():
	remove_buff()


func _on_buff_type_tree_exited():
	remove_buff()


func _on_target_kill(event: Event):
	event._buff = self
	_call_event_handler_list(Event.Type.KILL, event)


func _on_target_level_up(level_increased: bool):
	var event: Event = _make_buff_event(_target)
	event._is_level_up = level_increased
	_call_event_handler_list(Event.Type.LEVEL_UP, event)


func _on_target_attack(event: Event):
	event._buff = self
	_call_event_handler_list(Event.Type.ATTACK, event)


func _on_target_attacked(event: Event):
	event._buff = self
	_call_event_handler_list(Event.Type.ATTACKED, event)


func _on_target_dealt_damage(event: Event):
	event._buff = self
	_call_event_handler_list(Event.Type.DAMAGE, event)


func _on_target_damaged(event: Event):
	event._buff = self
	_call_event_handler_list(Event.Type.DAMAGED, event)


func _on_target_spell_casted(event: Event):
	event._buff = self
	_call_event_handler_list(Event.Type.SPELL_CAST, event)


func _on_target_spell_targeted(event: Event):
	event._buff = self
	_call_event_handler_list(Event.Type.SPELL_TARGET, event)


func _on_periodic_event_timer_timeout(handler: Callable, timer: ManualTimer):
	if !_can_call_event_handlers():
		return

	var periodic_event: Event = _make_buff_event(_target)
	periodic_event._timer = timer
	handler.call(periodic_event)


#########################
### Setters / Getters ###
#########################

func is_friendly() -> bool:
	return _friendly


# NOTE: buff.setRemainingDuration() in JASS
func set_remaining_duration(duration: float):
	if _timer != null:
		_timer.start(duration)


# NOTE: buff.getRemainingDuration() in JASS
func get_remaining_duration() -> float:
	var remaining_duration: float = _timer.get_time_left()

	return remaining_duration


func get_original_duration() -> float:
	return _original_duration


# NOTE: buff.isPurgable() in JASS
func is_purgable() -> bool:
	return _purgable


func set_is_purgable(value: bool):
	_purgable = value


func get_buff_icon() -> String:
	return _buff_icon


func get_buff_icon_color() -> Color:
	return _buff_icon_color


# NOTE: if no tooltip text is defined, return type name to
# at least make it possible to identify the buff
func get_tooltip_text() -> String:
	if !_tooltip_text.is_empty():
		return _tooltip_text
	else:
		return _buff_type_name


func get_modifier() -> Modifier:
	return _modifier


# NOTE: buff.setLevel() in JASS
func set_level(level: int):
	var old_level: int = _level
	_level = level
	_target.change_modifier_level(get_modifier(), old_level, level)


# Level is used to compare this buff with another buff of
# same type that is active on target and determine which
# buff is stronger. Stronger buff will end up remaining
# active on the target.
# NOTE: buff.getLevel() in JASS
func get_level() -> int:
	return _level


func get_buff_type_name() -> String:
	return _buff_type_name


func get_stacking_group() -> String:
	return _stacking_group


# NOTE: buff.getCaster() in JASS
func get_caster() -> Unit:
	return _caster


# NOTE: buff.getBuffedUnit() in JASS
func get_buffed_unit() -> Unit:
	return _target


func is_hidden() -> bool:
	return _is_hidden
