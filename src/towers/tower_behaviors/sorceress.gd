extends TowerBehavior


# NOTE: the way this tower works is that the player cycles
# through modifications and then applies/removes current
# modification from the missiles. Missiles can have a
# combination of multiple modifications, not just the
# currently selected one! The amount of applied
# modifications is limited by missile damage - it cannot go
# below 0.

# NOTE: [ORIGINAL_GAME_DEVIATION] Changed cd of autocasts to
# 0.25s because 0s cooldown is not supported by youtd2
# engine.


enum MissileMod {
	SLOW,
	SILENCE,
	REGEN,
	ARMOR,
	SPELL,
	AOE,

	COUNT,
}


class Data:
	var slow: int = 0 # +0.05 slow%
	var silence: int = 0 # +5.0s duration
	var regen: int = 0 # +0.05 regen%
	var armor: int = 0 # +1 armor%
	var spell: int = 0 # +0.06 vuln%
	var aoe: int = 150 # No percentage, integer value! Equals to radius of aoe
	var dmg: int = 100 # damage dealt by missile


const missile_mod_to_string: Dictionary = {
	MissileMod.SLOW: "Slow",
	MissileMod.SILENCE: "Silence",
	MissileMod.REGEN: "Health Regen",
	MissileMod.ARMOR: "Armor",
	MissileMod.SPELL: "Spell Vuln",
	MissileMod.AOE: "AoE",
}

var silence_bt: BuffType
var slow_bt: BuffType
var sunder_bt: BuffType
var spell_vuln_bt: BuffType
var cripple_bt: BuffType
var missile_pt: ProjectileType
var multiboard: MultiboardValues
var data: Data
var current_missile_mod: MissileMod


func load_triggers(triggers: BuffType):
	triggers.add_event_on_attack(on_attack)
	triggers.add_event_on_damage(on_damage)
	triggers.add_event_on_level_up(on_level_up)


func tower_init():
	tower.hide_attack_projectiles()

	silence_bt = CbSilence.new("sorceress_silence", 0, 0, false, self)

	missile_pt = ProjectileType.create_ranged("path_to_projectile_sprite", 1200, 1200, self)
	missile_pt.enable_collision(missile_pt_on_collision, 150, TargetType.new(TargetType.CREEPS), false)

	slow_bt = BuffType.new("slow_bt", 5, 0, false, self)
	var slow_bt_mod: Modifier = Modifier.new()
	slow_bt_mod.add_modification(Modification.Type.MOD_MOVESPEED, 0.0, -0.01)
	slow_bt.set_buff_modifier(slow_bt_mod)
	slow_bt.set_buff_icon("res://resources/icons/generic_icons/foot_trip.tres")
	slow_bt.set_buff_tooltip(tr("K7X4"))

	sunder_bt = BuffType.new("sunder_bt", 5, 0, false, self)
	var sunder_bt_mod: Modifier = Modifier.new()
	sunder_bt_mod.add_modification(Modification.Type.MOD_ARMOR_PERC, 0.0, -0.01)
	sunder_bt.set_buff_modifier(sunder_bt_mod)
	sunder_bt.set_buff_icon("res://resources/icons/generic_icons/open_wound.tres")
	sunder_bt.set_buff_tooltip(tr("SFT7"))

	spell_vuln_bt = BuffType.new("spell_vuln_bt", 5, 0, false, self)
	var spell_vuln_bt_mod: Modifier = Modifier.new()
	spell_vuln_bt_mod.add_modification(Modification.Type.MOD_SPELL_DAMAGE_RECEIVED, 0.0, 0.01)
	spell_vuln_bt.set_buff_modifier(spell_vuln_bt_mod)
	spell_vuln_bt.set_buff_icon("res://resources/icons/generic_icons/open_wound.tres")
	spell_vuln_bt.set_buff_tooltip(tr("UGC2"))

	cripple_bt = BuffType.new("cripple_bt", 5, 0, false, self)
	var cripple_bt_mod: Modifier = Modifier.new()
	cripple_bt_mod.add_modification(Modification.Type.MOD_HP_REGEN_PERC, 0.0, -0.01)
	cripple_bt.set_buff_modifier(cripple_bt_mod)
	cripple_bt.set_buff_icon("res://resources/icons/generic_icons/burning_meteor.tres")
	cripple_bt.set_buff_tooltip(tr("TYIV"))

	multiboard = MultiboardValues.new(8)
	multiboard.set_key(0, "Damage %")
	multiboard.set_key(1, "Mod")
	multiboard.set_key(2, "Slow")
	multiboard.set_key(3, "Silence")
	multiboard.set_key(4, "Health Regen")
	multiboard.set_key(5, "Armor")
	multiboard.set_key(6, "Spell Vuln")
	multiboard.set_key(7, "AoE")


func on_attack(event: Event):
	var target: Unit = event.get_target()
	var p: Projectile = Projectile.create_from_unit_to_unit(missile_pt, tower, 1.0, 1.0, tower, target, false, true, false)
	p.set_collision_parameters(data.aoe, TargetType.new(TargetType.CREEPS))
	p.set_z(60)


func on_damage(event: Event):
	event.damage = 0


func on_level_up(event: Event):
	var dmg_change: int
	if event.is_level_up():
		dmg_change = 2
	else:
		dmg_change = -2

	data.dmg += dmg_change


func on_create(_preceding_tower: Tower):
	data = Data.new()
	data.dmg += 2 * tower.get_level()
	current_missile_mod = MissileMod.SLOW


func on_autocast_choose(_event: Event):
	current_missile_mod = (current_missile_mod + 1) as MissileMod
	if current_missile_mod >= MissileMod.COUNT:
		current_missile_mod = 0 as MissileMod

	var floating_text: String = missile_mod_to_string[current_missile_mod]
	tower.get_player().display_small_floating_text(floating_text, tower, Color8(255, 255, 255), 40)


func on_autocast_add(_event: Event):
	var dmg_before: int = data.dmg
	
	match current_missile_mod:
		MissileMod.SLOW:
			if data.dmg >= 20:
				data.slow += 8
				data.dmg -= 20
				tower.get_player().display_small_floating_text("+Slow", tower, Color8(255, 255, 255), 40)
		MissileMod.SILENCE: 
			if data.dmg >= 40:
				data.silence += 5
				data.dmg -= 40
				tower.get_player().display_small_floating_text("+Silence", tower, Color8(255, 255, 255), 40)
		MissileMod.REGEN: 
			if data.dmg >= 25:
				data.regen += 10
				data.dmg -= 25
				tower.get_player().display_small_floating_text("+Regen", tower, Color8(255, 255, 255), 40)
		MissileMod.ARMOR:
			if data.dmg >= 25:
				data.armor += 6
				data.dmg -= 25
				tower.get_player().display_small_floating_text("+Armor", tower, Color8(255, 255, 255), 40)
		MissileMod.SPELL:
			if data.dmg >= 25:
				data.spell += 12
				data.dmg -= 25
				tower.get_player().display_small_floating_text("+Spell Vuln", tower, Color8(255, 255, 255), 40)
		MissileMod.AOE:
			if data.dmg >= 15:
				data.aoe += 50
				data.dmg -= 15
				tower.get_player().display_small_floating_text("+AoE", tower, Color8(255, 255, 255), 40)

	var dmg_after: int = data.dmg
	var dmg_changed: bool = dmg_before != dmg_after

	if !dmg_changed:
		tower.get_player().display_small_floating_text("Not enough missile damage to apply modification!", tower, Color8(255, 0, 0), 40)


func on_autocast_remove(_event: Event):
	var dmg_before: int = data.dmg

	match current_missile_mod:
		MissileMod.SLOW:
			if data.slow >= 8:
				data.slow -= 8
				data.dmg += 20
				tower.get_player().display_small_floating_text("-Slow", tower, Color8(255, 255, 255), 40)
		MissileMod.SILENCE: 
			if data.silence >= 5:
				data.silence -= 5
				data.dmg += 40
				tower.get_player().display_small_floating_text("-Silence", tower, Color8(255, 255, 255), 40)
		MissileMod.REGEN: 
			if data.regen >= 10:
				data.regen -= 10
				data.dmg += 25
				tower.get_player().display_small_floating_text("-Regen", tower, Color8(255, 255, 255), 40)
		MissileMod.ARMOR:
			if data.armor >= 6:
				data.armor -= 6
				data.dmg += 25
				tower.get_player().display_small_floating_text("-Armor", tower, Color8(255, 255, 255), 40)
		MissileMod.SPELL:
			if data.spell >= 12:
				data.spell -= 12
				data.dmg += 25
				tower.get_player().display_small_floating_text("-Spell Vuln", tower, Color8(255, 255, 255), 40)
		MissileMod.AOE:
			if data.aoe > 150:
				data.aoe -= 50
				data.dmg += 15
				tower.get_player().display_small_floating_text("-AoE", tower, Color8(255, 255, 255), 40)

	var dmg_after: int = data.dmg
	var dmg_changed: bool = dmg_before != dmg_after

	if !dmg_changed:
		tower.get_player().display_small_floating_text("Can't decrease modification any further!", tower, Color8(255, 0, 0), 40)


# NOTE: original script does a weird thing with multiple
# calls to displayTimedText(). Seems like in original
# engine, the "onTowerDetails()" callback is called once
# when tower details menu is opened. So what happened was
# player opened details and then some extra text was printed
# to the screen.
# 
# In youtd2 engine onTowerDetails() is called repeatedly to
# keep TowerDetails up to date.
# 
# So I changed the script to display these stats in details.
func on_tower_details() -> MultiboardValues:
	var damage_string: String = Utils.format_percent(data.dmg / 100.0, 0)
	var modification_string: String = missile_mod_to_string[current_missile_mod]
	var slow_string: String = Utils.format_percent(data.slow / 100.0, 0)
	var silence_string: String = Utils.format_float(data.silence, 0) + " seconds"
	var regen_string: String = Utils.format_percent(data.regen / 100.0, 0)
	var armor_string: String = Utils.format_percent(data.armor / 100.0, 0)
	var spell_string: String = Utils.format_percent(data.spell / 100.0, 0)
	var aoe_string: String = Utils.format_float(data.aoe, 0)

	multiboard.set_value(0, damage_string)
	multiboard.set_value(1, modification_string)
	multiboard.set_value(2, slow_string)
	multiboard.set_value(3, silence_string)
	multiboard.set_value(4, regen_string)
	multiboard.set_value(5, armor_string)
	multiboard.set_value(6, spell_string)
	multiboard.set_value(7, aoe_string)
	
	return multiboard


# NOTE: "coll()" in original script
func missile_pt_on_collision(_p: Projectile, target: Unit):
	var silence_chance: float = 0.50

	if data.slow > 0:
		slow_bt.apply(tower, target, data.slow)

	if data.silence > 0:
		if tower.calc_chance(silence_chance):
			silence_bt.apply_only_timed(tower, target, data.silence)

	if data.regen > 0:
		cripple_bt.apply(tower, target, data.regen)

	if data.armor > 0:
		sunder_bt.apply(tower, target, data.armor)

	if data.spell:
		spell_vuln_bt.apply(tower, target, data.spell)

	if data.dmg > 0:
		var damage: float = tower.get_current_attack_damage_with_bonus() * data.dmg / 100.0
		tower.do_spell_damage(target, damage, tower.calc_spell_crit_no_bonus())
