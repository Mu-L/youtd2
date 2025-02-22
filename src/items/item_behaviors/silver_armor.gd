extends ItemBehavior


func load_modifier(modifier: Modifier):
    modifier.add_modification(Modification.Type.MOD_ATTACKSPEED, 0.05, 0.0)
    modifier.add_modification(Modification.Type.MOD_DAMAGE_ADD_PERC, 0.10, 0.0)


func on_drop():
    var tower: Tower = item.get_carrier()

    tower.modify_property(Modification.Type.MOD_DAMAGE_ADD_PERC, -tower.get_gold_cost() * 0.0001)


func on_pickup():
    var tower: Tower = item.get_carrier()

    tower.modify_property(Modification.Type.MOD_DAMAGE_ADD_PERC, tower.get_gold_cost() * 0.0001)
