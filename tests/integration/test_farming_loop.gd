#warning-ignore-all:unsafe_method_access,return_value_discarded

class_name TestFarmingLoop
extends SimTestSuite

## Teste de integração: fluxo completo de agricultura
## (arar → plantar → regar → novo dia → colher).

func test_fluxo_completo() -> void:
	var w: Node2D = boot_game()
	var cell := Vector2i(25, 25)
	# 0) Prepara terreno como DIRT (fallback tillable = false).
	w.call("set_terrain", cell, 2)
	# 1) Ara DIRT -> solo.
	w.call("use_tool", Enums.Tool.HOE, 0, cell)
	assert_that(int(w.call("terrain_at", cell))).is_equal(3)  # SOIL

	# 2) Planta tomate.
	Inventory.add_seed(Enums.Seed.TOMATO, 1)
	var antes_sementes := Inventory.seed_count(Enums.Seed.TOMATO)
	w.call("use_tool", Enums.Tool.SEED, Enums.Seed.TOMATO, cell)
	assert_that(bool(w.call("has_crop", cell))).is_true()
	assert_that(Inventory.seed_count(Enums.Seed.TOMATO)).is_equal(antes_sementes - 1)

	# 3) Rega e avança 2 dias (TOMATO grow_days=2).
	for i in range(4):
		w.call("use_tool", Enums.Tool.WATER, 0, cell)
		TimeManager.new_day.emit(TimeManager.day + i + 1)

	# 4) Colhe com enxada.
	var antes_tomate := Inventory.count(Enums.Item.TOMATO)
	w.call("use_tool", Enums.Tool.HOE, 0, cell)
	assert_that(Inventory.count(Enums.Item.TOMATO)).is_equal(antes_tomate + 1)
	assert_that(bool(w.call("has_crop", cell))).is_false()