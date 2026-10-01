#warning-ignore-all:unsafe_method_access,return_value_discarded

class_name TestWorldMachines
extends SimTestSuite

## Cobertura de `scripts/world.gd`: colocação de máquinas (aspersor,
## espantalho, pescador).

func test_place_machine_com_madeira() -> void:
	var w: Node2D = boot_game()
	var cell := Vector2i(25, 24)
	Inventory.add_item(Enums.Item.WOOD, 20)
	var antes := Inventory.count(Enums.Item.WOOD)
	var ok: bool = w.call("place_machine", Enums.Machine.SPRINKLER, cell)
	assert_that(ok).is_true()
	assert_that(Inventory.count(Enums.Item.WOOD)).is_equal(antes - 10)


func test_place_machine_sem_madeira() -> void:
	var w: Node2D = boot_game()
	var cell := Vector2i(25, 24)
	Inventory.items.clear()
	var ok: bool = w.call("place_machine", Enums.Machine.SPRINKLER, cell)
	assert_that(ok).is_false()


func test_place_machine_celula_ocupada() -> void:
	var w: Node2D = boot_game()
	var cell := Vector2i(25, 24)
	Inventory.add_item(Enums.Item.WOOD, 30)
	w.call("place_machine", Enums.Machine.SPRINKLER, cell)
	var ok: bool = w.call("place_machine", Enums.Machine.SCARECROW, cell)
	assert_that(ok).is_false()


func test_place_machine_na_agua() -> void:
	var w: Node2D = boot_game()
	var cell := Vector2i(10, 7)  # água
	Inventory.add_item(Enums.Item.WOOD, 30)
	var ok: bool = w.call("place_machine", Enums.Machine.SPRINKLER, cell)
	assert_that(ok).is_false()


func test_place_machine_tipos() -> void:
	var w: Node2D = boot_game()
	Inventory.add_item(Enums.Item.WOOD, 50)
	assert_that(bool(w.call("place_machine", Enums.Machine.SPRINKLER, Vector2i(26, 24)))).is_true()
	assert_that(bool(w.call("place_machine", Enums.Machine.SCARECROW, Vector2i(27, 24)))).is_true()
	assert_that(bool(w.call("place_machine", Enums.Machine.FISHER, Vector2i(28, 24)))).is_true()