extends Node


func get_research_text(element: Element.enm, player: Player) -> String:
	var text: String = ""
	
	var current_element_level = player.get_element_level(element)
	var reached_max_level: bool = current_element_level == Constants.MAX_ELEMENT_LEVEL
	if reached_max_level:
		return "Can't research any further."

	var element_string: String = Element.convert_to_colored_string(element)
	var flavor_text: String = Element.get_flavor_text(element)
	var main_attack_types: String = Element.get_main_attack_types(element)
	var research_level: String = get_research_level_label(element, player)
	var cost: int = player.get_research_cost(element)
	var can_afford: bool = player.can_afford_research(element)
	var cost_string: String = get_colored_requirement_number(cost, can_afford)

	text += "Research %s level %s\n" % [element_string, research_level]
	text += "[img=32x32]res://resources/icons/hud/knowledge_tome.tres[/img] %s\n" % cost_string

	match Globals.get_game_mode():
		GameMode.enm.BUILD: text += "Research next element level to unlock new towers of this element and to unlock upgrades for existing towers.\n"
		GameMode.enm.RANDOM_WITH_UPGRADES: text += "Research next element level to unlock new towers of this element and to upgrade existing towers to higher tiers.\n"
		GameMode.enm.TOTALLY_RANDOM: text += "Research next element level to unlock new towers of this element.\n"

	text += " \n"
	text += "[color=LIGHTBLUE]%s[/color]\n" % flavor_text
	text += " \n"
	text += "[color=GOLD]Main attack types:[/color] %s\n" % main_attack_types

	return text


func get_research_level_label(element: Element.enm, player: Player) -> String:
	var text: String = ""
	
	var current_element_level = player.get_element_level(element)
	var max_element_level = Constants.MAX_ELEMENT_LEVEL
	if current_element_level >= max_element_level:
		text += " [color=GOLD]MAX[/color] "
	else:
		text += "[color=GOLD]%s[/color]" % [current_element_level + 1]
	
	return text

func get_creep_info(creep: Creep) -> String:
	var text: String = ""

	var health_string_colored: String = _get_creep_health_string(creep)
	var mana: int = floor(creep.get_mana())
	var overall_mana: int = floor(creep.get_overall_mana())

	text += "[color=YELLOW]Health:[/color] %s\n" % [health_string_colored]
	if overall_mana > 0:
		text += "[color=YELLOW]Mana:[/color] [color=CORNFLOWER_BLUE]%d/%d[/color]\n" % [mana, overall_mana]

	var category: CreepCategory.enm = creep.get_category() as CreepCategory.enm
	var category_string: String = CreepCategory.convert_to_colored_string(category)
	var creep_size: CreepSize.enm = creep.get_size()
	var creep_size_string: String = CreepSize.convert_to_colored_string(creep_size)
	var armor_type: ArmorType.enm = creep.get_armor_type()
	var armor_type_string: String = ArmorType.convert_to_colored_string(armor_type)
	var armor: float = creep.get_base_armor()
	var armor_string: String = Utils.format_float(armor, 2)
	var armor_bonus: float = creep.get_overall_armor_bonus()
	
	var armor_bonus_string: String
	if armor_bonus > 0:
		armor_bonus_string = "+%s" % Utils.format_float(armor_bonus, 2)
	elif armor_bonus < 0:
		armor_bonus_string = "%s" % Utils.format_float(armor_bonus, 2)
	else:
		armor_bonus_string = ""

	text += "[color=YELLOW]Race:[/color] %s\n" % category_string
	text += "[color=YELLOW]Size:[/color] %s\n" % creep_size_string
	text += "[color=YELLOW]Armor type:[/color] %s\n" % armor_type_string
	text += "[color=YELLOW]Armor:[/color] [color=GOLD]%s[/color] %s\n" % [armor_string, armor_bonus_string]
	
	return text


func get_tower_info_short(tower: Tower) -> String:
	var text: String = ""
	
	var tower_id: int = tower.get_id()

	var element: Element.enm = TowerProperties.get_element(tower_id)
	var element_string: String = Element.convert_to_colored_string(element)
	var dps: int = floori(TowerProperties.get_dps(tower_id))
	var attack_enabled: bool = TowerProperties.get_attack_enabled(tower_id)
	var attack_type: AttackType.enm = TowerProperties.get_attack_type(tower_id)
	var attack_type_string: String = AttackType.convert_to_colored_string(attack_type)
	var attack_range: int = floor(TowerProperties.get_range(tower_id))
	var damage_string: String = _get_tower_damage_string(tower)
	var mana: int = floori(tower.get_mana())
	var overall_mana: int = floori(tower.get_overall_mana())

	text += "[color=YELLOW]Element:[/color] %s\n" % element_string
	if attack_enabled:
		text += "[color=YELLOW]Attack type:[/color] %s\n" % [attack_type_string]
		text += "[color=YELLOW]Attack:[/color] [color=GOLD]%d[/color] DPS, [color=GOLD]%d[/color] range\n" % [dps, attack_range]
		text += "[color=YELLOW]Damage:[/color] %s\n" % [damage_string]

	if overall_mana != 0:
		text += "[color=YELLOW]Mana:[/color] [color=CORNFLOWER_BLUE]%d/%d[/color]\n" % [mana, overall_mana]

	return text


# NOTE: calling this function causes a lag spike so it
# should not be used during runtime in production builds.
# Lag spike happens because we need to create a temporary
# tower instance to get all the information needed for the
# tooltip. We work around that by using SaveTooltipsTool to
# run this function for all towers and save results to file.
# Then we load that file and use tooltips from the file.
# 
# NOTE: this generated part of the tooltip doesn't include
# text which needs to dynamically change color. That is, the
# requirements text and gold, tome and food costs. These
# parts are prepended in
# get_generated_tower_tooltip_with_tower_requirements().
func generate_tower_tooltip(tower_id: int, player: Player) -> String:
	var text: String = ""
	
	var description: String = TowerProperties.get_description(tower_id)
	var author: String = TowerProperties.get_author(tower_id)
	var element: Element.enm = TowerProperties.get_element(tower_id)
	var element_string: String = Element.convert_to_colored_string(element)
	var dps: int = floori(TowerProperties.get_dps(tower_id))
	var attack_enabled: bool = TowerProperties.get_attack_enabled(tower_id)
	var attack_type: AttackType.enm = TowerProperties.get_attack_type(tower_id)
	var attack_type_string: String = AttackType.convert_to_colored_string(attack_type)
	var attack_range: int = floor(TowerProperties.get_range(tower_id))
	var mana: int = floor(TowerProperties.get_mana(tower_id))
	var mana_regen: int = floor(TowerProperties.get_mana_regen(tower_id))

# 	NOTE: creating a tower instance just to get the tooltip
# 	text is weird, but the alternatives are worse. Need to
# 	add tower to tree so that tower is fully initialized and
# 	has all of the info needed for tooltip.
	var tower: Tower = Tower.make(tower_id, player)
	player.add_child(tower)
	tower.queue_free()

	var abilities_text: String = RichTexts.get_abilities_text_short(tower)

	text += "[color=LIGHT_BLUE]%s[/color]\n" % description
	text += "[color=YELLOW]Author:[/color] %s\n" % author
	text += "[color=YELLOW]Element:[/color] %s\n" % element_string
	if attack_enabled:
		text += "[color=YELLOW]Attack:[/color] [color=GOLD]%d[/color] DPS, %s, [color=GOLD]%d[/color] range\n" % [dps, attack_type_string, attack_range]

	if mana > 0:
		text += "[color=YELLOW]Mana:[/color] [color=CORNFLOWER_BLUE]%d[/color] ([color=CORNFLOWER_BLUE]+%d[/color]/sec)\n" % [mana, mana_regen]

	if !abilities_text.is_empty():
		text += " \n"
		text += abilities_text

	for aura in tower.get_aura_types():
		if aura.is_hidden:
			continue

		var aura_text: String = get_aura_text_short(aura)
		text += " \n"
		text += aura_text

	for autocast in tower.get_autocast_list():
		var autocast_text: String = get_autocast_text_short(autocast)
		text += " \n"
		text += autocast_text

	return text


# NOTE: TowerProperties.get_generated_tooltip returns cached tooltips
# with no dynamic info such as colored wave/research requirements text. This
# function combines cached tower description with such dynamic information
# from get_tower_requirements_text.
func get_tower_text(tower_id: int, player: Player) -> String:
	var generated_tooltip_text = TowerProperties.get_generated_tooltip(tower_id)
	var requirements_text = get_tower_requirements_text(tower_id, player)
	var display_name: String = TowerProperties.get_display_name(tower_id)
	var gold_cost: int = TowerProperties.get_cost(tower_id)
	var tome_cost: int = TowerProperties.get_tome_cost(tower_id)
	var food_cost: int = TowerProperties.get_food_cost(tower_id)
	var gold_cost_ok: bool = player.enough_gold_for_tower(tower_id)
	var tome_cost_ok: bool = player.enough_tomes_for_tower(tower_id)
	var food_cost_ok: bool = player.enough_food_for_tower(tower_id)
	var gold_cost_string: String = get_colored_requirement_number(gold_cost, gold_cost_ok)
	var tome_cost_string: String = get_colored_requirement_number(tome_cost, tome_cost_ok)
	var food_cost_string: String = get_colored_requirement_number(food_cost, food_cost_ok)
	
	var text = ""
	
	if !requirements_text.is_empty():
		text += "%s\n" % requirements_text
		text += " \n"

	text += "[b]%s[/b]\n" % display_name

	if tome_cost != 0:
		text += "[img=32x32]res://resources/icons/hud/gold.tres[/img] %s [img=32x32]res://resources/icons/hud/knowledge_tome.tres[/img] %s [img=32x32]res://resources/icons/hud/tower_food.tres[/img] [color=GOLD]%s[/color]\n" % [gold_cost_string, tome_cost_string, food_cost_string]
	else:
		text += "[img=32x32]res://resources/icons/hud/gold.tres[/img] %s [img=32x32]res://resources/icons/hud/tower_food.tres[/img] [color=GOLD]%s[/color]\n" % [gold_cost_string, food_cost_string]
	
	text += generated_tooltip_text
	
	return text
	

func get_tower_requirements_text(tower_id: int, player: Player) -> String:
	var text: String = ""

	var requirements_are_satisfied: bool = TowerProperties.requirements_are_satisfied(tower_id, player)

	if requirements_are_satisfied:
		return ""

	var required_wave_level: int = TowerProperties.get_required_wave_level(tower_id)
	var wave_level_ok: bool = TowerProperties.wave_level_foo(tower_id, player)
	var wave_level_string: String = get_colored_requirement_number(required_wave_level, wave_level_ok)

	var required_element_level: int = TowerProperties.get_required_element_level(tower_id)
	var element_level_ok: bool = TowerProperties.element_level_foo(tower_id, player)
	var element_level_string: String = get_colored_requirement_number(required_element_level, element_level_ok)

	var element: Element.enm = TowerProperties.get_element(tower_id)
	var element_string: String = Element.convert_to_string(element)

	text += "[color=GOLD][b]Requirements[/b][/color]\n"
	text += "Wave level: %s\n" % wave_level_string
	text += "%s research level: %s\n" % [element_string.capitalize(), element_level_string]
	
	return text


func get_item_text(item: Item) -> String:
	var text: String = ""

	var item_id: int = item.get_id()
	var display_name: String = ItemProperties.get_display_name(item_id)
	var rarity: Rarity.enm = ItemProperties.get_rarity(item_id)
	var rarity_color: Color = Rarity.get_color(rarity)
	var display_name_colored: String = Utils.get_colored_string(display_name, rarity_color)
	var description: String = ItemProperties.get_description(item_id)
	var author: String = ItemProperties.get_author(item_id)
	var is_oil: bool = ItemProperties.get_is_oil(item_id)
	var is_consumable: bool = ItemProperties.is_consumable(item_id)
	var is_disabled: bool = Item.disabled_item_list.has(item_id)

	var specials_text: String = item.get_specials_tooltip_text()
	specials_text = add_color_to_numbers(specials_text)
	var extra_text: String = item.get_ability_description()
	extra_text = add_color_to_numbers(extra_text)

	text += "[b]%s[/b]\n" % display_name_colored
	text += "[color=LIGHT_BLUE]%s[/color]\n" % description
	text += "[color=YELLOW]Author:[/color] %s\n" % author

	if !specials_text.is_empty():
		text += " \n[color=YELLOW]Effects:[/color]\n"
		text += "%s\n" % specials_text

	if !extra_text.is_empty():
		text += " \n%s\n" % extra_text

	var autocast: Autocast = item.get_autocast()

	if autocast != null:
		var autocast_text: String = get_autocast_text(autocast)
		text += " \n"
		text += autocast_text

		var item_is_on_tower: bool = item.get_carrier() != null
		var can_use_auto_mode: bool = autocast.can_use_auto_mode()

		if item_is_on_tower:
			text += " \n"
			if can_use_auto_mode:
				text += "[color=YELLOW]Shift Right Click to toggle automatic casting.[/color]\n"
			text += "[color=YELLOW]Right Click to use item.[/color]\n"

	if is_consumable:
		text += " \n[color=ORANGE]Right Click to use item. Item is consumed after use.[/color]"

	if is_oil:
		text += " \n[color=ORANGE]Use oil on a tower to alter it permanently. The effects stay when the tower is transformed or upgraded![/color]"

	if is_disabled:
		text += " \n[color=RED]THIS ITEM IS DISABLED[/color]"

	return text


# Adds gold color to all ints and floats in the text.
# NOTE: cases like these need to be colored:
# "15%"
# "3s"
# "x0.04" (for crit damage)
# "+x0.04"
func add_color_to_numbers(text: String) -> String:
	var colored_text: String = text

	var index: int = 0
	var tag_open: String = "[color=GOLD]"
	var tag_close: String = "[/color]"
	var tag_is_opened: bool = false
	var inside_existing_tag: bool = false

	while index < colored_text.length():
		var c: String = colored_text[index]
		var string_before_c: String = colored_text.substr(0, index)

		if !inside_existing_tag && string_before_c.ends_with("[color="):
			inside_existing_tag = true

		var next: String
		if index + 1 < colored_text.length():
			next = colored_text[index + 1]
		else:
			next = ""

		if inside_existing_tag:
#			NOTE: color tags can contain numbers, for
#			example: [color=1e90ffff]foo[/color]. In such
#			cases, we do not color these numbers because
#			that would break the existing color tag.
			if string_before_c.ends_with("[/color]"):
				inside_existing_tag = false
		elif tag_is_opened:
			var c_is_valid_part_of_number: bool = c.is_valid_int() || c == "%" || c == "s" || c == "x"

			if c == ".":
				var dot_is_part_of_float: bool = next.is_valid_int()
				if !dot_is_part_of_float:
					colored_text = colored_text.insert(index, tag_close)
					index += tag_close.length()
					tag_is_opened = false
			elif !c_is_valid_part_of_number:
				colored_text = colored_text.insert(index, tag_close)
				index += tag_close.length()
				tag_is_opened = false
		else:
			var c_is_valid_start_of_number: bool = c.is_valid_int() || ((c == "+" || c == "-" || c == "x") && (next.is_valid_int() || next == "x"))

			if c_is_valid_start_of_number:
				colored_text = colored_text.insert(index, tag_open)
				index += tag_open.length()
				tag_is_opened = true

		index += 1

	if tag_is_opened:
		colored_text = colored_text.insert(index, tag_close)

	return colored_text


func get_colored_requirement_number(value: int, requirement_satisfied: bool) -> String:
	var color: Color
	if requirement_satisfied:
		color = Color.GOLD
	else:
		color = Color.ORANGE_RED

	var string: String = "[color=%s]%d[/color]" % [color.to_html(), value]

	return string


func get_abilities_text(tower: Tower) -> String:
	var ability_info_list: Array[AbilityInfo] = tower.get_ability_info_list()
	var ability_text_list: Array[String] = []

	for ability_info in ability_info_list:
		var description: String = ability_info.description_full
		description = RichTexts.add_color_to_numbers(description)
		var ability_text: String = "[color=GOLD]%s[/color]\n \n%s" % [ability_info.name, description]

		ability_text_list.append(ability_text)

	var abilities_text: String = " \n".join(ability_text_list)

	return abilities_text


func get_abilities_text_short(tower: Tower) -> String:
	var ability_info_list: Array[AbilityInfo] = tower.get_ability_info_list()
	var ability_text_list: Array[String] = []

	for ability_info in ability_info_list:
		var description: String = ability_info.description_short

		if description.is_empty():
			continue

		description = RichTexts.add_color_to_numbers(description)
		var ability_text: String = "[color=GOLD]%s[/color]\n%s" % [ability_info.name, description]

		ability_text_list.append(ability_text)

	var abilities_text: String = " \n".join(ability_text_list)

	return abilities_text


func get_aura_text_short(aura_type: AuraType) -> String:
	var aura_name: String = aura_type.name
	var description: String = aura_type.description_short
	description = add_color_to_numbers(description)

	var text: String = ""
	text += "[color=GOLD]%s - Aura[/color]\n" % aura_name
	text += "%s" % description

	return text


func get_autocast_text(autocast: Autocast) -> String:
	var title: String = autocast.title
	var autocast_description: String = autocast.description
	autocast_description = add_color_to_numbers(autocast_description)
	var stats_text: String = get_autocast_stats_text(autocast)

	var text: String = ""
	text += "[color=GOLD]%s[/color]\n" % title
	text += " \n"
	text += "%s\n" % autocast_description
	text += "%s\n" % stats_text

	return text


func get_autocast_text_short(autocast: Autocast) -> String:
	var title: String = autocast.title
	var autocast_description_short: String = autocast.description_short
	autocast_description_short = add_color_to_numbers(autocast_description_short)
	var stats_text: String = get_autocast_stats_text(autocast)

	var text: String = ""
	text += "[color=GOLD]%s[/color]\n" % title
	text += "%s\n" % autocast_description_short
	text += "%s\n" % stats_text

	return text


func get_autocast_tooltip(autocast: Autocast) -> String:
	var text: String = ""

	text += RichTexts.get_autocast_text(autocast)
	text += " \n"

	if autocast.can_use_auto_mode():
		text += "[color=YELLOW]Right Click to toggle automatic casting on and off[/color]\n"
		text += " \n"

	text += "[color=YELLOW]Left Click to cast ability[/color]\n"

	return text


func get_autocast_stats_text(autocast: Autocast) -> String:
	var mana_cost: String = "Mana cost: %s" % str(autocast.mana_cost)
	var cast_range: String = "%s range" % str(autocast.cast_range)
	var autocast_cooldown: String = "%ss cooldown" % str(autocast.cooldown)

	var text: String = ""

	var stats_list: Array[String] = []
	if autocast.mana_cost > 0:
		stats_list.append(mana_cost)
	if autocast.cast_range > 0:
		stats_list.append(cast_range)
	if autocast.cooldown > 0:
		stats_list.append(autocast_cooldown)

	if !stats_list.is_empty():
		var stats_line: String = ", ".join(stats_list) + "\n";
		stats_line = add_color_to_numbers(stats_line)
		text += " \n"
		text += stats_line

	return text


# Returns tower damage in this format:
# "10-20 +3"
func _get_tower_damage_string(tower: Tower) -> String:
	var dmg_min_base: float = tower.get_damage_min()
	var dmg_max_base: float = tower.get_damage_max()

	var base_bonus_absolute: float = tower.get_base_damage_bonus()
	var base_bonus_percent: float = tower.get_base_damage_bonus_percent()

	var dmg_min: float = (dmg_min_base + base_bonus_absolute) * base_bonus_percent
	var dmg_max: float = (dmg_max_base + base_bonus_absolute) * base_bonus_percent
	var dmg_base: float = (dmg_min + dmg_max) / 2
	
	var damage_add_absolute: float = tower.get_damage_add()
	var damage_add_percent: float = tower.get_damage_add_percent()

	var dps_bonus: float = tower.get_dps_bonus()
	var attack_speed: float = tower.get_current_attack_speed()
	var dps_mod: float = dps_bonus * attack_speed

	var damage_total: float = (dmg_base + damage_add_absolute) * damage_add_percent + dps_mod

	var damage_add: int = roundi(damage_total - dmg_base)

	var damage_add_string: String
	if damage_add > 0:
		damage_add_string = " [color=GREEN]+%d[/color]" % damage_add
	elif damage_add < 0:
		damage_add_string = " [color=RED]%d[/color]" % damage_add
	else:
		damage_add_string = ""

	var string: String = "[color=GOLD]%d-%d[/color]%s" % [floori(dmg_min), floori(dmg_max), damage_add_string]

	return string


func _get_creep_health_string(creep: Creep) -> String:
	var health_color: Color
	var health_ratio: float = creep.get_health_ratio()
	if health_ratio > 0.3:
		health_color = Color.GREEN
	else:
		health_color = Color.RED

	var health: int = floor(creep.get_health())
	var overall_health: int = floor(creep.get_overall_health())
	var health_string: String = "%d/%d" % [health, overall_health]
	var health_string_colored: String = Utils.get_colored_string(health_string, health_color)

	return health_string_colored
