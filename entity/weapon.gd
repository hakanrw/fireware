extends "./throwable.gd"

func interact(by):
	var item = Utils.get_shop_controller().get_weapon_with_id(variant)
	
	if NetworkController.is_server():
		if by.weapons[item.type] != -1: 
			by.network_player.rpc("throw_weapon", by.weapons[item.type], true)
	
		by.network_player.rpc("equip_weapon", variant, true)
		by.network_player.rpc_id(1, "set_weapon_info", variant, properties["weapon_info"])
		by.network_player.rpc_id(int(by.name), "set_weapon_info", variant, properties["weapon_info"])
		NetworkController.rpc("remove_entity", get_id())
