class_name TestGameData
extends SimTestSuite

## Cobertura de `scripts/data/game_data.gd`: nomes, valores, preços,
## `roll_fish` e as operações `can_afford`/`pay`.

func test_seed_name() -> void:
	assert_that(GameData.seed_name(Enums.Seed.TOMATO)).is_equal("Tomate")
	assert_that(GameData.seed_name(Enums.Seed.CORN)).is_equal("Milho")
	assert_that(GameData.seed_name(Enums.Seed.PUMPKIN)).is_equal("Abobora")
	assert_that(GameData.seed_name(Enums.Seed.WHEAT)).is_equal("Trigo")
	assert_that(GameData.seed_name(99)).is_equal("Semente")


func test_item_name() -> void:
	assert_that(GameData.item_name(Enums.Item.WOOD)).is_equal("Madeira")
	assert_that(GameData.item_name(Enums.Item.APPLE)).is_equal("Maca")
	assert_that(GameData.item_name(Enums.Item.SILVERFISH)).is_equal("Peixe Prateado")
	assert_that(GameData.item_name(99)).is_equal("?")


func test_item_value() -> void:
	assert_that(GameData.item_value(Enums.Item.PUMPKIN)).is_equal(12)
	assert_that(GameData.item_value(Enums.Item.WOOD)).is_equal(2)
	assert_that(GameData.item_value(Enums.Item.GRAYFISH)).is_equal(16)
	assert_that(GameData.item_value(999)).is_equal(0)


func test_roll_fish_siempre_valido() -> void:
	var lote := [Enums.Item.FISH, Enums.Item.GRAYFISH, Enums.Item.SILVERFISH]
	for i in range(200):
		assert_that(GameData.roll_fish()).is_in(lote)


func test_fish_difficulty() -> void:
	assert_that(GameData.fish_difficulty(Enums.Item.FISH)).is_equal_approx(0.35, 0.001)
	assert_that(GameData.fish_difficulty(Enums.Item.GRAYFISH)).is_equal_approx(0.55, 0.001)
	assert_that(GameData.fish_difficulty(Enums.Item.SILVERFISH)).is_equal_approx(0.8, 0.001)
	assert_that(GameData.fish_difficulty(999)).is_equal_approx(0.4, 0.001)


func test_hotbar_tiene_9_entradas() -> void:
	assert_that(GameData.hotbar.size()).is_equal(9)
	# 6 herramientas + 3 maquinas, en ese orden.
	for i in range(6):
		assert_that(GameData.hotbar[i]["kind"]).is_equal("tool")
	for i in range(6, 9):
		assert_that(GameData.hotbar[i]["kind"]).is_equal("machine")


func test_can_afford_y_pay() -> void:
	Inventory.items.clear()
	Inventory.add_item(Enums.Item.WOOD, 10)
	var coste := {Enums.Item.WOOD: 10}
	assert_that(GameData.can_afford(coste)).is_true()
	assert_that(GameData.pay(coste)).is_true()
	assert_that(Inventory.count(Enums.Item.WOOD)).is_equal(0)
	# Sin suficientes recursos -> falla y no toca el inventario.
	Inventory.add_item(Enums.Item.WOOD, 5)
	assert_that(GameData.can_afford({Enums.Item.WOOD: 6})).is_false()
	assert_that(GameData.pay({Enums.Item.WOOD: 6})).is_false()
	assert_that(Inventory.count(Enums.Item.WOOD)).is_equal(5)


func test_precios_de_maquinas() -> void:
	assert_that(int(GameData.machine_cost[Enums.Machine.SPRINKLER]["cost"][Enums.Item.WOOD])).is_equal(10)
	assert_that(int(GameData.machine_cost[Enums.Machine.SCARECROW]["cost"][Enums.Item.WOOD])).is_equal(8)
	assert_that(int(GameData.machine_cost[Enums.Machine.FISHER]["cost"][Enums.Item.WOOD])).is_equal(15)