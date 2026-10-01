#warning-ignore-all:unsafe_method_access,return_value_discarded

class_name TestWorldSerialization
extends SimTestSuite

## Cobertura de `scripts/world.gd`: to_dict / from_dict roundtrip.

func test_roundtrip_terreno() -> void:
	var w: Node2D = boot_game()
	var cell := Vector2i(25, 25)
	w.call("set_terrain", cell, 3)  # SOIL
	var salvo: Dictionary = w.call("to_dict")
	# Muda o terreno.
	w.call("set_terrain", cell, 0)
	assert_that(int(w.call("terrain_at", cell))).is_equal(0)
	# Restaura.
	w.call("from_dict", salvo)
	assert_that(int(w.call("terrain_at", cell))).is_equal(3)


func test_roundtrip_props() -> void:
	var w: Node2D = boot_game()
	# Limpa entidades demo para controle total.
	w.call("_clear_entities")
	w.call("_clear_decor")
	var cell := Vector2i(25, 25)
	w.call("set_terrain", cell, 0)
	w.call("_spawn_tree", cell)
	var salvo: Dictionary = w.call("to_dict")
	assert_that(salvo["props"].size()).is_greater(0)
	# Limpa e restaura.
	w.call("_clear_entities")
	w.call("from_dict", salvo)
	var restaurado: Dictionary = w.call("to_dict")
	assert_that(restaurado["props"].size()).is_equal(salvo["props"].size())


func test_roundtrip_crops() -> void:
	var w: Node2D = boot_game()
	w.call("_clear_entities")
	w.call("_clear_decor")
	var cell := Vector2i(25, 25)
	w.call("set_terrain", cell, 3)
	Inventory.add_seed(Enums.Seed.WHEAT, 1)
	w.call("use_tool", Enums.Tool.SEED, Enums.Seed.WHEAT, cell)
	w.call("use_tool", Enums.Tool.WATER, 0, cell)
	var salvo: Dictionary = w.call("to_dict")
	w.call("_clear_entities")
	w.call("from_dict", salvo)
	var restaurado: Dictionary = w.call("to_dict")
	for cd in restaurado["crops"]:
		if cd["cell"] == [25, 25]:
			assert_that(int(cd["seed"])).is_equal(Enums.Seed.WHEAT)
			assert_that(bool(cd["watered"])).is_true()
			return
	assert_that(false).is_true()  # crop não encontrada


func test_roundtrip_maquinas() -> void:
	var w: Node2D = boot_game()
	w.call("_clear_entities")
	w.call("_clear_decor")
	var cell := Vector2i(25, 24)
	w.call("set_terrain", cell, 0)
	Inventory.add_item(Enums.Item.WOOD, 20)
	w.call("place_machine", Enums.Machine.SPRINKLER, cell)
	var salvo: Dictionary = w.call("to_dict")
	w.call("_clear_entities")
	w.call("from_dict", salvo)
	var restaurado: Dictionary = w.call("to_dict")
	assert_that(restaurado["machines"].size()).is_equal(1)