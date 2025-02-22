class_name SeekersOil extends ItemBehavior


# NOTE: this range is a hand-picked value which hits 3x3
# grid of towers around the main tower or 4+3+4 towers built
# in honeycomb pattern.
# 
# Distance to tower 2 tiles away = 128 * 2 = 256
# -RANGE_CHECK_BONUS_FOR_TOWERS(72) to account for Iterate
# adding it during range checking.
# 256 - 72 = 184
# and then additional -4 so that the oil doesn't hit tower 2
# tiles away but hits a tower on the edge of honeycomb
# pattern.
static var SEEKER_OIL_RANGE: float = 2 * Constants.TILE_SIZE_WC3 - Constants.RANGE_CHECK_BONUS_FOR_TOWERS - 4
const SEEKER_OIL_ID: int = 1018


func load_modifier(modifier: Modifier):
	modifier.add_modification(Modification.Type.MOD_ITEM_CHANCE_ON_KILL, 0.02, 0.0008)
	modifier.add_modification(Modification.Type.MOD_ITEM_QUALITY_ON_KILL, 0.02, 0.0008)


func on_pickup():
	SeekersOil.seeker_oil_on_pickup(item, SEEKER_OIL_ID)


static func seeker_oil_on_pickup(original_oil: Item, oil_id: int):
# 	NOTE: hackfix alert! The _is_oil_and_was_applied_already
# 	flag is used to know when we are transferring oils from
# 	one tower to another, either when towers get upgraded or
# 	transformed. In such cases, we do not do the aoe effect
# 	of seeker oil again - we only transfer the oil from old
# 	tower to new tower.
	if original_oil._is_oil_and_was_applied_already:
		return

	var is_original_oil: bool = original_oil.user_int == 0

	if !is_original_oil:
		return

	var carrier: Tower = original_oil.get_carrier()

	var towers_in_range: Iterate = Iterate.over_units_in_range_of_caster(carrier, TargetType.new(TargetType.TOWERS), SEEKER_OIL_RANGE)

	while towers_in_range.count() > 0:
		var neighbor: Tower = towers_in_range.next()

		if neighbor == carrier:
			continue

		var oil_for_neighbor: Item = Item.create(original_oil.get_player(), oil_id, carrier.get_position_wc3())

#		NOTE: set user_int to 1 to mark this oil to stop recursion
		oil_for_neighbor.user_int = 1

		oil_for_neighbor.pickup(neighbor)
